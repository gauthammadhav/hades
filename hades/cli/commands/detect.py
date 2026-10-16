"""Command implementation for 'hades detect' (and alias 'hades scan')."""

import json
from pathlib import Path
from typing import Optional
import typer
from rich.console import Console

from hades.cli.formatters import print_hades_banner, render_devices_table
from hades.discovery.simulation import get_simulated_devices
from hades.discovery.udev_scanner import scan_usb_devices
from hades.resolver.manifest import load_manifest

console = Console()


def detect_command(
    workspace: Optional[Path] = typer.Option(
        None,
        "--workspace",
        "-w",
        help="Path to workspace directory containing .hades.yaml manifest.",
    ),
    all_devices: bool = typer.Option(
        False,
        "--all",
        "-a",
        help="Include host root hubs and internal system peripherals.",
    ),
    json_output: bool = typer.Option(
        False,
        "--json",
        "-j",
        help="Output raw JSON array of discovered devices (for API/UI consumption).",
    ),
    simulate: Optional[str] = typer.Option(
        None,
        "--simulate",
        "-s",
        help="Simulate detection of a hardware preset (e.g. 'esp32-native', 'esp32-cp2102-ambiguous', 'esp32-cp2102-resolved', 'stlink-v2', 'rp2040-pico', 'custom-kernel-device').",
    ),
):
    """Scan and classify connected USB hardware, TTY endpoints, and resolve profiles."""
    # 1. Load workspace manifest if available
    manifest, manifest_err = load_manifest(workspace_dir=workspace)

    # 2. Collect devices (either simulated or real via pyudev)
    if simulate:
        devices = get_simulated_devices(simulate, manifest=manifest)
    else:
        try:
            devices = scan_usb_devices(manifest=manifest, include_all=all_devices)
        except Exception as e:
            console.print(f"[bold red]Hardware scan error:[/bold red] {e}")
            raise typer.Exit(code=1)

    # 3. Output results
    if json_output:
        # Output clean JSON for Member 4's FastAPI / Flutter integration
        data = [dev.model_dump(mode="json") for dev in devices]
        print(json.dumps(data, indent=2))
    else:
        print_hades_banner()
        render_devices_table(
            devices=devices,
            manifest=manifest,
            workspace_path=str(workspace or Path.cwd()),
        )

