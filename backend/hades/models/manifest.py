"""Pydantic schema definitions for .hades.yaml workspace project manifests."""

from typing import Optional
from pydantic import BaseModel, Field


class ProjectConfig(BaseModel):
    """Metadata describing the user's firmware project."""
    name: str = Field(default="firmware-project", description="Project name")
    version: str = Field(default="0.1.0", description="Semantic version string")
    description: Optional[str] = Field(default=None, description="Optional project summary")


class TargetConfig(BaseModel):
    """Target hardware and embedded toolchain specifications."""
    board: str = Field(description="Target board model e.g. 'esp32-devkit-v1', 'stm32f4-discovery', 'pico'")
    chip: Optional[str] = Field(default=None, description="Chip architecture or model e.g. 'ESP32', 'STM32F407VG', 'RP2040'")
    arch: Optional[str] = Field(default=None, description="Target architecture e.g. 'xtensa-esp32', 'arm-none-eabi', 'riscv32'")
    sdk: Optional[str] = Field(default=None, description="Embedded SDK e.g. 'esp-idf', 'zephyr', 'pico-sdk', 'arduino'")
    sdk_version: Optional[str] = Field(default=None, description="Specific SDK or toolchain version")


class HardwareConfig(BaseModel):
    """Hardware interface and isolation configuration parameters."""
    interface: str = Field(default="uart", description="Primary connection interface: 'uart', 'jtag', 'swd', 'usb-native'")
    baud_rate: int = Field(default=115200, description="Serial baud rate for flashing and monitor")
    bridge_hint: Optional[str] = Field(default=None, description="Hint for generic UART bridge e.g. 'cp2102', 'ch340', 'ftdi'")
    kernel_module_required: bool = Field(default=False, description="Set True if device requires a non-standard host kernel module")
    kernel_driver_required: bool = Field(default=False, description="Set True when a host kernel driver must be isolated")
    privileged_hw_access: bool = Field(default=False, description="Set True when direct privileged hardware access is required")
    usb_jtag_required: bool = Field(default=False, description="Set True when USB JTAG access is required")
    standard_serial_flashing: bool = Field(default=False, description="Set True for standard serial flashing")
    usb_vendor_id: Optional[str] = Field(default=None, description="Optional 4-digit hex USB VID constraint")
    usb_product_id: Optional[str] = Field(default=None, description="Optional 4-digit hex USB PID constraint")


class IsolationConfig(BaseModel):
    """Sandbox environment specifications."""
    preferred_mode: str = Field(default="container", description="'container' or 'vm'")
    ephemeral: bool = Field(default=True, description="Whether to wipe session overlay state on teardown")
    base_image: Optional[str] = Field(default=None, description="Custom base OCI image or QEMU cloud image")


class HadesManifest(BaseModel):
    """Root configuration model representing a workspace .hades.yaml file."""
    version: str = Field(default="1.0", description="Manifest format version")
    project: ProjectConfig = Field(default_factory=ProjectConfig)
    target: TargetConfig
    hardware: HardwareConfig = Field(default_factory=HardwareConfig)
    isolation: IsolationConfig = Field(default_factory=IsolationConfig)
