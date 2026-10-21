"""Unit tests for HADES hardware isolation policy engine."""

import pytest

from hades.models.manifest import HadesManifest, HardwareConfig, IsolationConfig, ProjectConfig, TargetConfig
from hades.policy.engine import HardwareRequirements, PolicyDecision, PolicyTarget, select_target
from hades.resolver.two_stage import TwoStageResolver
from hades.models.device import IsolationRecommendation


class TestPolicyEngine:
    def test_default_requirements_selects_container(self):
        req = HardwareRequirements()
        decision = select_target(req)
        assert decision.target == PolicyTarget.CONTAINER
        assert "no elevated hardware access" in decision.reason

    def test_kernel_driver_required_selects_vm(self):
        req = HardwareRequirements(kernel_driver_required=True)
        decision = select_target(req)
        assert decision.target == PolicyTarget.QEMU_VM
        assert "kernel isolation" in decision.reason

    def test_kernel_module_required_selects_vm(self):
        req = HardwareRequirements(kernel_module_required=True)
        decision = select_target(req)
        assert decision.target == PolicyTarget.QEMU_VM
        assert "kernel isolation" in decision.reason

    def test_privileged_hw_access_selects_restricted_container(self):
        req = HardwareRequirements(privileged_hw_access=True)
        decision = select_target(req)
        assert decision.target == PolicyTarget.RESTRICTED_CONTAINER
        assert "privileged hardware access" in decision.reason

    def test_usb_jtag_required_selects_broker(self):
        req = HardwareRequirements(usb_jtag_required=True)
        decision = select_target(req)
        assert decision.target == PolicyTarget.CONTAINER_WITH_BROKER
        assert "dynamic hardware brokering" in decision.reason

    def test_standard_serial_flashing_selects_broker(self):
        req = HardwareRequirements(standard_serial_flashing=True)
        decision = select_target(req)
        assert decision.target == PolicyTarget.CONTAINER_WITH_BROKER
        assert "dynamic hardware brokering" in decision.reason

    def test_precedence_kernel_over_privileged_and_jtag(self):
        req = HardwareRequirements(
            kernel_driver_required=True,
            privileged_hw_access=True,
            usb_jtag_required=True,
        )
        decision = select_target(req)
        assert decision.target == PolicyTarget.QEMU_VM

    def test_precedence_privileged_over_jtag(self):
        req = HardwareRequirements(
            privileged_hw_access=True,
            usb_jtag_required=True,
        )
        decision = select_target(req)
        assert decision.target == PolicyTarget.RESTRICTED_CONTAINER


class TestResolverPolicyIntegration:
    def test_manifest_with_kernel_driver_requires_vm(self):
        manifest = HadesManifest(
            project=ProjectConfig(name="driver-test"),
            target=TargetConfig(board="custom-pcb", chip="ASIC"),
            hardware=HardwareConfig(kernel_driver_required=True),
        )
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102",
            bus_num=1,
            dev_num=2,
            port_topology="1-1",
            sys_path="/sys/devices/1-1",
            sys_name="1-1",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.isolation_recommendation == IsolationRecommendation.QEMU_VM
        assert device.kernel_driver_required is True

    def test_manifest_with_privileged_hw_access(self):
        manifest = HadesManifest(
            project=ProjectConfig(name="priv-test"),
            target=TargetConfig(board="custom-pcb", chip="FPGA"),
            hardware=HardwareConfig(privileged_hw_access=True),
        )
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102",
            bus_num=1,
            dev_num=2,
            port_topology="1-1",
            sys_path="/sys/devices/1-1",
            sys_name="1-1",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.privileged_hw_access is True
        assert device.isolation_recommendation == IsolationRecommendation.CONTAINER_BROKER

    def test_manifest_preferred_mode_vm_elevation(self):
        manifest = HadesManifest(
            project=ProjectConfig(name="vm-pref"),
            target=TargetConfig(board="esp32-devkit-v1", chip="ESP32"),
            hardware=HardwareConfig(interface="uart"),
            isolation=IsolationConfig(preferred_mode="vm"),
        )
        resolver = TwoStageResolver(manifest=manifest)
        device = resolver.resolve(
            vendor_id="10c4",
            product_id="ea60",
            vendor_name="Silicon Labs",
            product_name="CP2102",
            bus_num=1,
            dev_num=2,
            port_topology="1-1",
            sys_path="/sys/devices/1-1",
            sys_name="1-1",
            tty_nodes=["/dev/ttyUSB0"],
        )
        assert device.isolation_recommendation == IsolationRecommendation.QEMU_VM
        assert device.kernel_module_required is True
