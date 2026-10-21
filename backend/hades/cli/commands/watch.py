"""Command implementation for ``hades watch``."""

import asyncio
from datetime import datetime
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.panel import Panel

from hades.cli.formatters import print_hades_banner
from hades.discovery.udev_watcher import UdevWatcher

console = Console()


async def _watch_events(workspace: Optional[Path]) -> None:
    watcher = UdevWatcher(workspace=workspace)
    async for event in watcher.events():
        timestamp = datetime.now().strftime("%H:%M:%S")
        if event.device is None:
            console.print(f"[yellow]{event.action} event [{timestamp}][/yellow]")
            continue
        device = event.device
        label = device.target_board or device.product_name
        details = f"{device.vendor_id}:{device.product_id} {device.port_topology}"
        if device.tty_nodes:
            details += f" ({', '.join(device.tty_nodes)})"
        style = "green" if event.action == "add" else "yellow"
        console.print(f"[{style}]{event.action}: {label} {details} [{timestamp}][/{style}]")


def watch_command(
    workspace: Optional[Path] = typer.Option(
        None,
        "--workspace",
        "-w",
        help="Path to workspace directory containing .hades.yaml manifest.",
    ),
):
    """Monitor USB and TTY cold-plug, add, remove, and change events."""
    print_hades_banner()
    console.print(
        Panel(
            "[bold cyan]Hardware Event Monitor Started[/bold cyan]\n"
            "Listening for USB and TTY events via kernel netlink...\n"
            "[dim]Press Ctrl+C to terminate.[/dim]",
            border_style="cyan",
        )
    )
    try:
        asyncio.run(_watch_events(workspace))
    except KeyboardInterrupt:
        console.print("\n[yellow]Hardware monitor stopped by user.[/yellow]")
    except (OSError, ValueError) as exc:
        console.print(f"[bold red]Monitor error:[/bold red] {exc}")
        raise typer.Exit(code=1) from exc
