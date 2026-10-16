"""Two-Stage Hardware Resolution Engine.

Implements Stage 1 (Passive USB Descriptor Matching) and
Stage 2 (Workspace Manifest + Probe Fallback for Generic UART Bridges).
"""

from typing import List, Optional
from hades.models.device import (
    DeviceClassification,
    DiscoveredDevice,
    IsolationRecommendation,
    ResolutionStage,
)
from hades.models.manifest import HadesManifest
from hades.resolver.database import lookup_hardware


class TwoStageResolver:
    """Orchestrates hardware classification and profile resolution."""

    def __init__(self, manifest: Optional[HadesManifest] = None):
        self.manifest = manifest

    def resolve(
        self,
        vendor_id: str,
        product_id: str,
        vendor_name: str,
        product_name: str,
        bus_num: int,
        dev_num: int,
        port_topology: str,
        sys_path: str,
        sys_name: str,
        dev_node: Optional[str] = None,
        serial_number: Optional[str] = None,
        tty_nodes: Optional[List[str]] = None,
        usb_interfaces: Optional[List[str]] = None,
    ) -> DiscoveredDevice:
        """Resolve a physical USB device through the two-stage pipeline."""
        v_id = vendor_id.lower().strip()
        p_id = product_id.lower().strip()
        ttys = tty_nodes or []
        interfaces = usb_interfaces or []
        device_id = f"usb:{v_id}:{p_id}:{port_topology}"

        # ---------------------------------------------------------------------
        # STAGE 1: Passive Hardware Database Lookup
        # ---------------------------------------------------------------------
        entry = lookup_hardware(v_id, p_id)

        if entry:
            classification = entry.classification
            isolation = entry.isolation
            kernel_req = entry.kernel_module_required

            # Stage 1A: Known Native Microcontroller or Debug Probe
            if classification in (DeviceClassification.NATIVE_MCU, DeviceClassification.DEBUG_PROBE):
                return DiscoveredDevice(
                    device_id=device_id,
                    vendor_id=v_id,
                    product_id=p_id,
                    vendor_name=vendor_name or entry.vendor_id,
                    product_name=product_name or entry.name,
                    serial_number=serial_number,
                    bus_num=bus_num,
                    dev_num=dev_num,
                    port_topology=port_topology,
                    dev_node=dev_node,
                    sys_path=sys_path,
                    sys_name=sys_name,
                    tty_nodes=ttys,
                    usb_interfaces=interfaces,
                    classification=classification,
                    target_board=entry.target_board,
                    target_chip=entry.target_chip,
                    recommended_sdk=entry.recommended_sdk,
                    resolution_stage=ResolutionStage.STAGE_1_PASSIVE,
                    isolation_recommendation=isolation,
                    kernel_module_required=kernel_req,
                    resolution_notes=(
                        f"Stage 1 Passive Match: Recognized as {entry.name} "
                        f"via native USB VID:PID ({entry.vid_pid}) and descriptors."
                    ),
                )

            # Stage 1B: Generic USB-to-UART Bridge (Gap A)
            elif classification == DeviceClassification.GENERIC_UART_BRIDGE:
                # Initiate Stage 2: Check project manifest
                if self.manifest and self.manifest.target:
                    target = self.manifest.target
                    hw_config = self.manifest.hardware
                    iso_config = self.manifest.isolation

                    # If manifest specifies kernel module or VM preference, elevate to VM
                    if hw_config.kernel_module_required or iso_config.preferred_mode == "vm":
                        final_isolation = IsolationRecommendation.QEMU_VM
                        final_kernel = True
                    else:
                        final_isolation = IsolationRecommendation.CONTAINER_BROKER
                        final_kernel = False

                    return DiscoveredDevice(
                        device_id=device_id,
                        vendor_id=v_id,
                        product_id=p_id,
                        vendor_name=vendor_name or "Generic UART Bridge",
                        product_name=product_name or entry.name,
                        serial_number=serial_number,
                        bus_num=bus_num,
                        dev_num=dev_num,
                        port_topology=port_topology,
                        dev_node=dev_node,
                        sys_path=sys_path,
                        sys_name=sys_name,
                        tty_nodes=ttys,
                        usb_interfaces=interfaces,
                        classification=DeviceClassification.GENERIC_UART_BRIDGE,
                        target_board=target.board,
                        target_chip=target.chip or "Resolved via Manifest",
                        recommended_sdk=target.sdk or "Custom Toolchain",
                        resolution_stage=ResolutionStage.STAGE_2_MANIFEST,
                        isolation_recommendation=final_isolation,
                        kernel_module_required=final_kernel,
                        resolution_notes=(
                            f"Stage 2 Manifest Match: Generic bridge {entry.name} ({entry.vid_pid}) "
                            f"mapped to target board '{target.board}' ({target.chip or 'Custom'}) "
                            f"using workspace .hades.yaml."
                        ),
                    )
                else:
                    # No manifest found: Flag as Ambiguous Bridge
                    return DiscoveredDevice(
                        device_id=device_id,
                        vendor_id=v_id,
                        product_id=p_id,
                        vendor_name=vendor_name or "Generic UART Bridge",
                        product_name=product_name or entry.name,
                        serial_number=serial_number,
                        bus_num=bus_num,
                        dev_num=dev_num,
                        port_topology=port_topology,
                        dev_node=dev_node,
                        sys_path=sys_path,
                        sys_name=sys_name,
                        tty_nodes=ttys,
                        usb_interfaces=interfaces,
                        classification=DeviceClassification.GENERIC_UART_BRIDGE,
                        target_board=f"Ambiguous ({entry.name})",
                        target_chip="Unknown (Behind Serial Bridge)",
                        recommended_sdk="None (Requires .hades.yaml manifest)",
                        resolution_stage=ResolutionStage.STAGE_2_AMBIGUOUS,
                        isolation_recommendation=IsolationRecommendation.CONTAINER_BROKER,
                        kernel_module_required=False,
                        resolution_notes=(
                            f"Generic UART bridge {entry.name} detected on port {port_topology}. "
                            f"VID:PID identifies the USB adapter chip, but the target board is ambiguous. "
                            f"Add a .hades.yaml manifest to your project to lock the profile."
                        ),
                    )

            # Stage 1C: System Root Hubs
            elif classification == DeviceClassification.HOST_HUB:
                return DiscoveredDevice(
                    device_id=device_id,
                    vendor_id=v_id,
                    product_id=p_id,
                    vendor_name=vendor_name or "Linux Foundation",
                    product_name=product_name or entry.name,
                    serial_number=serial_number,
                    bus_num=bus_num,
                    dev_num=dev_num,
                    port_topology=port_topology,
                    dev_node=dev_node,
                    sys_path=sys_path,
                    sys_name=sys_name,
                    tty_nodes=ttys,
                    usb_interfaces=interfaces,
                    classification=DeviceClassification.HOST_HUB,
                    resolution_stage=ResolutionStage.SYSTEM_IGNORED,
                    isolation_recommendation=IsolationRecommendation.REJECT_POLICY,
                    resolution_notes="Linux Host USB Root Hub controller (filtered).",
                )

        # ---------------------------------------------------------------------
        # Fallback for Unlisted Devices
        # ---------------------------------------------------------------------
        # Check if device has serial TTY endpoints (e.g. unknown serial adapter)
        if ttys:
            classif = DeviceClassification.GENERIC_UART_BRIDGE
            stage = ResolutionStage.STAGE_2_AMBIGUOUS
            notes = (
                f"Unlisted USB device with serial endpoints {ttys}. "
                f"Treated as generic serial hardware."
            )
        else:
            # Check vendor/product strings for standard peripheral keywords
            desc_combined = f"{vendor_name} {product_name}".lower()
            if any(k in desc_combined for k in ["cam", "video", "audio", "wireless", "bluetooth", "mouse", "keyboard"]):
                classif = DeviceClassification.PERIPHERAL
                stage = ResolutionStage.SYSTEM_IGNORED
                notes = "Standard host peripheral (audio/video/input/wireless)."
            else:
                classif = DeviceClassification.UNKNOWN
                stage = ResolutionStage.STAGE_2_AMBIGUOUS
                notes = f"Unrecognized USB device VID:PID {v_id}:{p_id}."

        return DiscoveredDevice(
            device_id=device_id,
            vendor_id=v_id,
            product_id=p_id,
            vendor_name=vendor_name or "Unknown Vendor",
            product_name=product_name or "Unknown Product",
            serial_number=serial_number,
            bus_num=bus_num,
            dev_num=dev_num,
            port_topology=port_topology,
            dev_node=dev_node,
            sys_path=sys_path,
            sys_name=sys_name,
            tty_nodes=ttys,
            usb_interfaces=interfaces,
            classification=classif,
            target_board=None,
            target_chip=None,
            recommended_sdk=None,
            resolution_stage=stage,
            isolation_recommendation=(
                IsolationRecommendation.CONTAINER_BROKER
                if ttys else IsolationRecommendation.REJECT_POLICY
            ),
            resolution_notes=notes,
        )

