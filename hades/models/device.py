"""Device data models and classifications for HADES Discovery."""

from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class DeviceClassification(str, Enum):
    """Classification of USB devices according to HADES taxonomy."""
    NATIVE_MCU = "native_mcu"
    DEBUG_PROBE = "debug_probe"
    GENERIC_UART_BRIDGE = "generic_uart_bridge"
    HOST_HUB = "host_hub"
    PERIPHERAL = "peripheral"
    UNAUTHORIZED = "unauthorized"
    UNKNOWN = "unknown"


class ResolutionStage(str, Enum):
    """Stage in which the target board identity was resolved."""
    STAGE_1_PASSIVE = "stage_1_passive"         # Matched directly by VID:PID / USB descriptors
    STAGE_2_MANIFEST = "stage_2_manifest"       # Ambiguous bridge resolved by .hades.yaml manifest
    STAGE_2_AMBIGUOUS = "stage_2_ambiguous"     # Generic bridge needing target resolution
    SYSTEM_IGNORED = "system_ignored"           # Root hub or non-dev peripheral ignored by default


class IsolationRecommendation(str, Enum):
    """Recommended execution sandbox model for this hardware."""
    CONTAINER_BROKER = "container_broker"       # Container + Hardware Broker dynamic cgroup
    QEMU_VM = "qemu_vm"                         # QEMU/KVM VM with USB Passthrough (Kernel driver/raw bus)
    REJECT_POLICY = "reject_policy"             # Blocked under least-privilege security policy


class DiscoveredDevice(BaseModel):
    """Represents a discovered hardware device with topology and resolution details."""
    device_id: str = Field(description="Unique HADES device identifier e.g. usb:10c4:ea60:1-4")
    vendor_id: str = Field(description="4-digit lowercase hex USB Vendor ID")
    product_id: str = Field(description="4-digit lowercase hex USB Product ID")
    vendor_name: str = Field(default="Unknown", description="Reported manufacturer / vendor string")
    product_name: str = Field(default="Unknown", description="Reported product string")
    serial_number: Optional[str] = Field(default=None, description="Reported USB serial number descriptor")
    bus_num: int = Field(description="USB Bus Number")
    dev_num: int = Field(description="USB Device Number on the bus")
    port_topology: str = Field(description="Physical USB port path topology e.g. '1-2.1'")
    dev_node: Optional[str] = Field(default=None, description="Linux character device node e.g. /dev/bus/usb/001/004")
    sys_path: str = Field(description="Linux sysfs device path")
    sys_name: str = Field(description="Kernel sysfs name e.g. '1-4'")
    tty_nodes: List[str] = Field(default_factory=list, description="Associated serial character devices e.g. ['/dev/ttyUSB0']")
    
    classification: DeviceClassification = DeviceClassification.UNKNOWN
    target_board: Optional[str] = Field(default=None, description="Identified hardware board (e.g. ESP32-S3-DevKitC-1)")
    target_chip: Optional[str] = Field(default=None, description="Microcontroller or processor family (e.g. ESP32-S3, RP2040)")
    recommended_sdk: Optional[str] = Field(default=None, description="Default or detected SDK (e.g. esp-idf, pico-sdk, zephyr)")
    resolution_stage: ResolutionStage = ResolutionStage.STAGE_2_AMBIGUOUS
    isolation_recommendation: IsolationRecommendation = IsolationRecommendation.CONTAINER_BROKER
    resolution_notes: str = Field(default="", description="Human-readable explanation of how the device was identified")
    kernel_module_required: bool = Field(default=False, description="Flag indicating if a custom host kernel driver is required")
    usb_interfaces: List[str] = Field(default_factory=list, description="Reported USB interfaces / drivers")

