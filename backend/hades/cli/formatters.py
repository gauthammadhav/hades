"""Rich console formatters, badges, and tables for the HADES CLI."""

from typing import List, Optional
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

from hades.models.device import (
    DeviceClassification,
    DiscoveredDevice,
    IsolationRecommendation,
    ResolutionStage,
)
from hades.models.manifest import HadesManifest

console = Console()


def print_hades_banner():
    """Print the stylized HADES system banner."""
    banner_text = Text()
    banner_text.append("HADES", style="bold red")
    banner_text.append(" :: ", style="bold white")
    banner_text.append("Hardware-Aware Development Sandbox", style="bold cyan")
    banner_text.append(" [Discovery Layer v0.1.0]", style="dim white")
    console.print(Panel(banner_text, border_style="red", expand=False))


def format_stage_badge(stage: ResolutionStage) -> Text:
    """Return a formatted Rich badge for the resolution stage."""
    if stage == ResolutionStage.STAGE_1_PASSIVE:
        return Text("✓ Stage-1", style="bold green")
    elif stage == ResolutionStage.STAGE_2_MANIFEST:
        return Text("✓ Stage-2", style="bold cyan")
    elif stage == ResolutionStage.STAGE_2_AMBIGUOUS:
        return Text("⚠ Ambiguous", style="bold yellow")
    else:
        return Text("○ System", style="dim")


def format_isolation_badge(isolation: IsolationRecommendation, kernel_required: bool) -> Text:
    """Return a formatted Rich badge for the isolation model."""
    if isolation == IsolationRecommendation.CONTAINER_BROKER:
        return Text("Container + Broker", style="green")
    elif isolation == IsolationRecommendation.QEMU_VM:
        suffix = "\n(Kernel Module)" if kernel_required else ""
        return Text(f"QEMU/KVM VM{suffix}", style="bold magenta")
    else:
        return Text("Policy Denied", style="dim red")


def render_devices_table(
    devices: List[DiscoveredDevice],
    manifest: Optional[HadesManifest] = None,
    workspace_path: Optional[str] = None,
):
    """Render a comprehensive Rich table of discovered hardware devices."""
    if not devices:
        console.print(
            Panel(
                "[yellow]No active embedded development hardware detected on USB bus.[/yellow]\n"
                "[dim]Plug in a microcontroller (ESP32, STM32, RP2040) or run with '--simulate esp32' to test demo profiles.[/dim]",
                title="Scan Results",
                border_style="yellow",
            )
        )
        return

    table = Table(
        title=f"Discovered Hardware Devices ({len(devices)} found)",
        border_style="blue",
        header_style="bold cyan",
        show_lines=True,
        expand=True,
    )

    table.add_column("Resolution Stage", justify="center", style="bold", min_width=12)
    table.add_column("Target Hardware / Board", style="bold white", min_width=16)
    table.add_column("VID:PID", justify="center", style="cyan", no_wrap=True, min_width=10)
    table.add_column("Port Topology", justify="center", style="magenta", min_width=12)
    table.add_column("Serial / TTY Node", style="yellow", min_width=12)
    table.add_column("Isolation Sandbox", style="green", min_width=14)
    table.add_column("Recommended Toolchain", style="blue", min_width=14)

    has_ambiguous_bridge = False

    for dev in devices:
        stage_badge = format_stage_badge(dev.resolution_stage)
        isolation_badge = format_isolation_badge(dev.isolation_recommendation, dev.kernel_module_required)

        # Hardware title
        board_display = dev.target_board or dev.product_name
        if dev.target_chip:
            board_display += f"\n[dim]Chip: {dev.target_chip}[/dim]"

        # Serial nodes
        tty_display = "\n".join(dev.tty_nodes) if dev.tty_nodes else "[dim]No TTY[/dim]"

        # Toolchain
        toolchain_display = dev.recommended_sdk or "[dim]N/A[/dim]"

        # Topology + Bus
        topo_display = f"{dev.port_topology}\n[dim]Bus {dev.bus_num:03d} Dev {dev.dev_num:03d}[/dim]"

        table.add_row(
            stage_badge,
            board_display,
            f"{dev.vendor_id}:{dev.product_id}",
            topo_display,
            tty_display,
            isolation_badge,
            toolchain_display,
        )

        if dev.resolution_stage == ResolutionStage.STAGE_2_AMBIGUOUS:
            has_ambiguous_bridge = True

    console.print(table)

    # If ambiguous bridge is detected, display callout explaining Gap A fix
    if has_ambiguous_bridge:
        console.print(
            Panel(
                "[bold yellow]Gap A Notice: Generic USB-to-UART Bridge Detected[/bold yellow]\n\n"
                "The connected device uses a generic bridge chip (e.g. CP2102, CH340, FTDI).\n"
                "HADES cannot determine the physical microcontroller board behind it from VID:PID descriptors alone.\n\n"
                "[bold white]How to resolve:[/bold white]\n"
                "1. Run [bold cyan]hades init --preset esp32[/bold cyan] in your project workspace to generate a [bold].hades.yaml[/bold] manifest.\n"
                "2. HADES Stage 2 resolver will automatically bind this bridge port to your target toolchain.",
                title="Resolution Required",
                border_style="yellow",
            )
        )
    elif manifest and manifest.target:
        console.print(
            Panel(
                f"[bold green]Workspace Manifest Active:[/bold green] Resolved against [cyan]{manifest.project.name}[/cyan] "
                f"targeting [bold]{manifest.target.board}[/bold] (SDK: {manifest.target.sdk})",
                border_style="green",
            )
        )

