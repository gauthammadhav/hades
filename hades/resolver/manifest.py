"""Manifest loader and validator for HADES workspace configuration."""

from pathlib import Path
from typing import Optional, Tuple
import yaml
from pydantic import ValidationError

from hades.models.manifest import (
    HadesManifest,
    HardwareConfig,
    IsolationConfig,
    ProjectConfig,
    TargetConfig,
)


MANIFEST_FILENAMES = [".hades.yaml", "hades.yaml", ".hades.yml", "hades.yml"]


def find_manifest_path(start_dir: Optional[Path] = None) -> Optional[Path]:
    """Search for a .hades.yaml manifest starting from start_dir and walking up the tree."""
    current = (start_dir or Path.cwd()).resolve()
    
    # Check current directory and ancestors
    for parent in [current] + list(current.parents):
        for name in MANIFEST_FILENAMES:
            candidate = parent / name
            if candidate.is_file():
                return candidate
    return None


def load_manifest(manifest_path: Optional[Path] = None, workspace_dir: Optional[Path] = None) -> Tuple[Optional[HadesManifest], Optional[str]]:
    """
    Load and validate a .hades.yaml manifest.
    
    Returns:
        (manifest, None) if successful.
        (None, error_message) if invalid or not found.
    """
    target_path = manifest_path or find_manifest_path(workspace_dir)
    if not target_path or not target_path.exists():
        return None, "No .hades.yaml manifest found in workspace."

    try:
        with open(target_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
            
        if not isinstance(data, dict):
            return None, f"Manifest at {target_path} is empty or not a valid YAML dictionary."

        manifest = HadesManifest.model_validate(data)
        return manifest, None
    except yaml.YAMLError as e:
        return None, f"YAML parsing error in {target_path}: {e}"
    except ValidationError as e:
        return None, f"Schema validation error in {target_path}:\n{e}"
    except Exception as e:
        return None, f"Failed to read {target_path}: {e}"


def generate_preset_manifest(preset: str, project_name: str = "embedded-firmware") -> HadesManifest:
    """Generate a preset HadesManifest for popular embedded platforms."""
    preset = preset.lower()
    
    if "esp32" in preset:
        return HadesManifest(
            project=ProjectConfig(name=project_name, version="0.1.0", description="ESP32 firmware project"),
            target=TargetConfig(
                board="esp32-devkit-v1",
                chip="ESP32",
                arch="xtensa-esp32",
                sdk="esp-idf",
                sdk_version="5.1",
            ),
            hardware=HardwareConfig(
                interface="uart",
                baud_rate=115200,
                bridge_hint="cp2102",
                kernel_module_required=False,
            ),
            isolation=IsolationConfig(
                preferred_mode="container",
                ephemeral=True,
            ),
        )
    elif "stm32" in preset:
        return HadesManifest(
            project=ProjectConfig(name=project_name, version="0.1.0", description="STM32 firmware project"),
            target=TargetConfig(
                board="nucleo-f401re",
                chip="STM32F401RE",
                arch="arm-none-eabi",
                sdk="stm32cube",
                sdk_version="latest",
            ),
            hardware=HardwareConfig(
                interface="swd",
                baud_rate=115200,
                kernel_module_required=False,
            ),
            isolation=IsolationConfig(
                preferred_mode="container",
                ephemeral=True,
            ),
        )
    elif "pico" in preset or "rp2040" in preset:
        return HadesManifest(
            project=ProjectConfig(name=project_name, version="0.1.0", description="Raspberry Pi Pico project"),
            target=TargetConfig(
                board="raspberry-pi-pico",
                chip="RP2040",
                arch="arm-none-eabi",
                sdk="pico-sdk",
                sdk_version="1.5.1",
            ),
            hardware=HardwareConfig(
                interface="usb-native",
                baud_rate=115200,
                kernel_module_required=False,
            ),
            isolation=IsolationConfig(
                preferred_mode="container",
                ephemeral=True,
            ),
        )
    elif "kernel" in preset or "vm" in preset:
        return HadesManifest(
            project=ProjectConfig(name=project_name, version="0.1.0", description="Custom Linux driver/kernel testbed"),
            target=TargetConfig(
                board="custom-kernel-peripheral",
                chip="Custom-ASIC",
                arch="x86_64",
                sdk="linux-headers-generic",
            ),
            hardware=HardwareConfig(
                interface="usb-raw",
                baud_rate=115200,
                kernel_module_required=True,  # Triggers QEMU VM
            ),
            isolation=IsolationConfig(
                preferred_mode="vm",
                ephemeral=True,
            ),
        )
    else:
        # Default generic Arduino / Embedded
        return HadesManifest(
            project=ProjectConfig(name=project_name, version="0.1.0", description="Generic embedded development project"),
            target=TargetConfig(
                board="arduino-uno-r3",
                chip="ATmega328P",
                arch="avr",
                sdk="arduino-cli",
            ),
            hardware=HardwareConfig(
                interface="uart",
                baud_rate=115200,
                bridge_hint="ch340",
                kernel_module_required=False,
            ),
            isolation=IsolationConfig(
                preferred_mode="container",
                ephemeral=True,
            ),
        )

