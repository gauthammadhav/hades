"""Deterministic selection of the sandbox target for a hardware profile."""

from dataclasses import dataclass
from enum import Enum


class PolicyTarget(str, Enum):
    QEMU_VM = "QEMU_VM"
    RESTRICTED_CONTAINER = "RESTRICTED_CONTAINER"
    CONTAINER_WITH_BROKER = "CONTAINER_WITH_BROKER"
    CONTAINER = "CONTAINER"


@dataclass(frozen=True)
class HardwareRequirements:
    kernel_driver_required: bool = False
    kernel_module_required: bool = False
    privileged_hw_access: bool = False
    usb_jtag_required: bool = False
    standard_serial_flashing: bool = False


@dataclass(frozen=True)
class PolicyDecision:
    target: PolicyTarget
    reason: str


def select_target(requirements: HardwareRequirements) -> PolicyDecision:
    """Apply the policy tree in precedence order."""
    if requirements.kernel_driver_required or requirements.kernel_module_required:
        return PolicyDecision(PolicyTarget.QEMU_VM, "host kernel isolation required")
    if requirements.privileged_hw_access:
        return PolicyDecision(PolicyTarget.RESTRICTED_CONTAINER, "privileged hardware access required")
    if requirements.usb_jtag_required or requirements.standard_serial_flashing:
        return PolicyDecision(PolicyTarget.CONTAINER_WITH_BROKER, "dynamic hardware brokering required")
    return PolicyDecision(PolicyTarget.CONTAINER, "no elevated hardware access required")
