"""Command implementation for 'hades watch' - Live udev event stream."""

from datetime import datetime
from pathlib import Path
from typing import Optional
import typer
from rich.console import Console
from rich.panel import Panel

from hades.cli.formatters import (
    format_isolation_badge,
    format_stage_badge,
    print_hades_banner,
)
from hades.discovery.monitor import DeviceMonitor
from hades.resolver.manifest import load_manifest

console = Console()


def watch_command(
    workspace: Optional[Path] = typer.Option(
        None,
        "--workspace",
        "-w",
        help="Path to workspace directory containing .hades.yaml manifest.",
    ),
):
    """Monitor hardware plug, unplug, and reset events in real-time."""
    print_hades_banner()
    manifest, _ = load_manifest(workspace_dir=workspace)

    console.print(
        Panel(
            "[bold cyan]Hardware Event Monitor Started[/bold cyan]\n"
            "Listening for USB plug, unplug, and microcontroller reset events via kernel netlink...\n"
            "[dim]Press Ctrl+C to terminate.[/dim]",
            border_style="cyan",
        )
    )

    try:
        monitor = DeviceMonitor(manifest=manifest)
        for event in monitor.listen():
            now_str = datetime.now().strftime("%H:%M:%S")
            dev = event.device

            if event.action == "re-enumerated":
                # Gap B: USB reset during flashing
                console.print(
                    Panel(
                        f"[bold yellow]⟳ USB Re-Enumeration Event [{now_str}][/bold yellow]\n"
                        f"[bold white]Physical Port Path:[/bold white] [magenta]{dev.port_topology}[/magenta]\n"
                        f"[bold white]Device Node Reset:[/bold white] Dev {event.previous_dev_num:03d} -> [bold green]Dev {dev.dev_num:03d}[/bold green] ({dev.dev_node})\n"
                        f"[bold white]Hardware:[/bold white] {dev.product_name} ({dev.vendor_id}:{dev.product_id})\n"
                        f"[bold white]Serial Node:[/bold white] {', '.join(dev.tty_nodes) or 'None'}\n\n"
                        f"[dim italic]Broker Impact: Physical port topology preserved. Dynamic cgroup permissions updated without container restart.[/dim italic]",
                        title="[bold yellow]Gap B: Re-Enumeration Handled[/bold yellow]",
                        border_style="yellow",
                    )
                )

            elif event.action == "add":
                stage_badge = format_stage_badge(dev.resolution_stage)
                iso_badge = format_isolation_badge(dev.isolation_recommendation, dev.kernel_module_required)
                board_desc = dev.target_board or dev.product_name

                console.print(
                    Panel(
                        f"[bold green]+ Hardware Connected [{now_str}][/bold green]\n"
                        f"[bold white]Board / Device:[/bold white] {board_desc}\n"
                        f"[bold white]VID:PID:[/bold white] [cyan]{dev.vendor_id}:{dev.product_id}[/cyan] ({dev.vendor_name})\n"
                        f"[bold white]Physical Port:[/bold white] [magenta]{dev.port_topology}[/magenta] [dim](Bus {dev.bus_num:03d}, Dev {dev.dev_num:03d})[/dim]\n"
                        f"[bold white]TTY Node:[/bold white] [yellow]{', '.join(dev.tty_nodes) or 'No TTY endpoint'}[/yellow]\n"
                        f"[bold white]Resolution:[/bold white] {stage_badge.markup}\n"
                        f"[bold white]Sandbox Mode:[/bold white] {iso_badge.markup}\n"
                        f"[dim]{dev.resolution_notes}[/dim]",
                        title="[bold green]Device Plugged In[/bold green]",
                        border_style="green",
                    )
                )

            elif event.action == "remove":
                console.print(
                    Panel(
                        f"[bold red]- Hardware Disconnected [{now_str}][/bold red]\n"
                        f"[bold white]Device:[/bold white] {dev.product_name} ({dev.vendor_id}:{dev.product_id})\n"
                        f"[bold white]Physical Port:[/bold white] [magenta]{dev.port_topology}[/magenta]\n"
                        f"[dim]Hardware broker releasing device permissions and tearing down ephemeral links.[/dim]",
                        title="[bold red]Device Removed[/bold red]",
                        border_style="red",
                    )
                )

    except KeyboardInterrupt:
        console.print("\n[yellow]Hardware monitor stopped by user.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Monitor error:[/bold red] {e}")
        raise typer.Exit(code=1)

