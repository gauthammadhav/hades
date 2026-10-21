"""Unit tests for HADES Hardware Discovery, Topology Tracking, and Two-Stage Resolution."""

import pytest
from pathlib import Path

from hades.discovery.topology import extract_port_topology, is_same_physical_port
from hades.models.device import (
    DeviceClassification,
    IsolationRecommendation,
    ResolutionStage,
)
from hades.models.manifest import (
    HadesManifest,
    HardwareConfig,
    IsolationConfig,
    ProjectConfig,
    TargetConfig,
)
from hades.resolver.database import lookup_hardware
from hades.resolver.manifest import generate_preset_manifest, load_manifest
from hades.resolver.two_stage import TwoStageResolver


class TestTopologyExtraction:
    """Tests for physical USB port topology extraction (Gap B)."""

    def test_direct_port_string(self):
        assert extract_port_topology("1-4", "/devices/.../usb1/1-4") == "1-4"
        assert extract_port_topology("1-2.1", "/devices/.../usb1/1-2/1-2.1") == "1-2.1"
        assert extract_port_topology("3-3", "/devices/.../usb3/3-3") == "3-3"

    def test_root_hub(self):
        assert extract_port_topology("usb1", "/devices/.../usb1") == "usb1"

    def test_nested_interface_path(self):
        # Even when sys_name is an interface like 1-2.1:1.0, topology is 1-2.1
        res = extract_port_topology("1-2.1:1.0", "/devices/pci0000:00/.../usb1/1-2/1-2.1/1-2.1:1.0")
        assert res == "1-2.1"

    def test_port_matching_across_resets(self):
        # Simulates microcontroller resetting into bootloader on same physical port
        port_before_reset = "1-2.1"
        port_after_reset = "1-2.1"
        assert is_same_physical_port(port_before_reset, port_after_reset) is True


class TestStage1PassiveMatching:
    """Tests for native USB microcontrollers and debug probes (Gap A Stage 1)."""

    def setup_method(self):
        self.resolver = TwoStageResolver(manifest=None)

    def test_esp32_s3_native_usb(self):
        # Espressif native USB-JTAG/Serial: 303a:1001
        device = self.resolver.resolve(
            vendor_id="303a",
            product_id="1001",
            vendor_name="Espressif Systems",
            product_name="USB JTAG/serial debug unit",
            bus_num=1,
            dev_num=4,
            port_topology="1-2.1",
            sys_path="/sys/devices/.../1-2.1",
            sys_name="1-2.1",
            tty_nodes=["/dev/ttyACM0"],
        )
        assert device.resolution_stage == ResolutionStage.STAGE_1_PASSIVE
        assert device.classification == DeviceClassification.NATIVE_MCU
        assert device.target_chip == "ESP32-S3"
        assert device.recommended_sdk == "esp-idf"
        assert device.isolation_recommendation == IsolationRecommendation.CONTAINER_BROKER

    def test_rp2040_raspberry_pi_pico(self):
        # Raspberry Pi Pico: 2e8a:0003
        device = self.resolver.resolve(
            vendor_id="2e8a",
            product_id="0003",
            vendor_name="Raspberry Pi",
            product_name="Pico",
            bus_num=1,
            dev_num=7,
            port_topology="1-4",
            sys_path="/sys/devices/.../1-4",
            sys_name="1-4",
            tty_nodes=["/dev/ttyACM1"],
        )
        assert device.resolution_stage == ResolutionStage.STAGE_1_PASSIVE
        assert device.classification == DeviceClassification.NATIVE_MCU
        assert device.target_chip == "RP2040"
        assert device.recommended_sdk == "pico-sdk"

    def test_stlink_v2_debugger(self):
        # ST-LINK/V2 SWD debugger: 0483:3748
        device = self.resolver.resolve(
            vendor_id="0483",
            product_id="3748",
            vendor_name="STMicroelectronics",
            product_name="ST-LINK/V2",
            bus_num=3,
            dev_num=2,
            port_topology="3-1",
            sys_path="/sys/devices/.../3-1",
            sys_name="3-1",
        )
        assert device.resolution_stage == ResolutionStage.STAGE_1_PASSIVE
        assert device.classification == DeviceClassification.DEBUG_PROBE
        assert device.recommended_sdk == "stm32cube-tools"


class TestStage2GenericBridges:
    """Tests for Generic USB-to-UART bridges with and without manifest (Gap A Stage 2)."""

    def test_cp2102_without_manifest_is_ambiguous(self):
        # Silicon Labs CP2102: 10c4:ea60 without manifest
        resolver = TwoStageResolver(manifest=None)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102 USB to UART",
            bus_num=1,
            dev_num=5,
            port_topology="1-4",
            sys_path="/sys/devices/.../1-4",
            sys_name="1-4",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.classification == DeviceClassification.GENERIC_UART_BRIDGE
        assert device.resolution_stage == ResolutionStage.STAGE_2_AMBIGUOUS
        assert "Ambiguous" in device.target_board

    def test_cp2102_with_manifest_resolves_to_esp32(self):
        # CP2102 with .hades.yaml manifest specifying esp32
        manifest = generate_preset_manifest("esp32", "test-project")
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102 USB to UART",
            bus_num=1,
            dev_num=5,
            port_topology="1-4",
            sys_path="/sys/devices/.../1-4",
            sys_name="1-4",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.classification == DeviceClassification.GENERIC_UART_BRIDGE
        assert device.resolution_stage == ResolutionStage.STAGE_2_MANIFEST
        assert device.target_board == "esp32-devkit-v1"
        assert device.target_chip == "ESP32"
        assert device.recommended_sdk == "esp-idf"

    def test_ch340_with_manifest_resolves_to_arduino(self):
        # WCH CH340: 1a86:7523
        manifest = generate_preset_manifest("arduino", "arduino-project")
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="1a86",
            product_id="7523",
            vendor_name="QinHeng Electronics",
            product_name="CH340",
            bus_num=1,
            dev_num=6,
            port_topology="1-3",
            sys_path="/sys/devices/.../1-3",
            sys_name="1-3",
            tty_nodes=["/dev/ttyUSB1"],
        )
        assert device.resolution_stage == ResolutionStage.STAGE_2_MANIFEST
        assert device.target_board == "arduino-uno-r3"
        assert device.recommended_sdk == "arduino-cli"


class TestIsolationPolicyRecommendations:
    """Tests for Policy and Isolation selection (Container vs VM)."""

    def test_standard_serial_selects_container(self):
        manifest = generate_preset_manifest("esp32")
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102",
            bus_num=1,
            dev_num=5,
            port_topology="1-4",
            sys_path="/sys/devices/.../1-4",
            sys_name="1-4",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.isolation_recommendation == IsolationRecommendation.CONTAINER_BROKER

    def test_kernel_module_required_elevates_to_qemu_vm(self):
        # When kernel_module_required: true, Container is rejected, VM is chosen
        manifest = generate_preset_manifest("kernel")
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102",
            bus_num=2,
            dev_num=8,
            port_topology="2-1",
            sys_path="/sys/devices/.../2-1",
            sys_name="2-1",
            tty_nodes=["/dev/ttyUSB1"],
        )
        assert device.isolation_recommendation == IsolationRecommendation.QEMU_VM
        assert device.kernel_module_required is True

