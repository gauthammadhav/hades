"""Command implementation for 'hades init' - Generates a .hades.yaml manifest."""

from pathlib import Path
from typing import Optional
import typer
import yaml
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

from hades.cli.formatters import print_hades_banner
from hades.resolver.manifest import generate_preset_manifest

console = Console()


def init_command(
    preset: str = typer.Option(
        "esp32",
        "--preset",
        "-p",
        help="Target hardware preset: 'esp32', 'stm32', 'pico', 'arduino', or 'kernel'.",
    ),
    name: Optional[str] = typer.Option(
        None,
        "--name",
        "-n",
        help="Project name (defaults to current directory name).",
    ),
    output_dir: Optional[Path] = typer.Option(
        None,
        "--output",
        "-o",
        help="Destination directory for .hades.yaml.",
    ),
    force: bool = typer.Option(
        False,
        "--force",
        "-f",
        help="Overwrite existing .hades.yaml manifest if present.",
    ),
):
    """Initialize a .hades.yaml project manifest to resolve generic bridges."""
    print_hades_banner()
    dest_dir = (output_dir or Path.cwd()).resolve()
    dest_dir.mkdir(parents=True, exist_ok=True)
    target_file = dest_dir / ".hades.yaml"

    if target_file.exists() and not force:
        console.print(
            Panel(
                f"[yellow]A manifest already exists at:[/yellow] {target_file}\n"
                "[dim]Use '--force' to overwrite.[/dim]",
                title="Manifest Exists",
                border_style="yellow",
            )
        )
        return

    project_name = name or dest_dir.name
    manifest = generate_preset_manifest(preset=preset, project_name=project_name)
    manifest_yaml = yaml.dump(manifest.model_dump(mode="json"), sort_keys=False, default_flow_style=False)

    try:
        with open(target_file, "w", encoding="utf-8") as f:
            f.write("# HADES Workspace Manifest\n")
            f.write("# Defines target microcontroller board, SDK, and isolation parameters.\n\n")
            f.write(manifest_yaml)

        syntax = Syntax(manifest_yaml, "yaml", theme="monokai", line_numbers=True)
        console.print(
            Panel(
                syntax,
                title=f"[bold green]Created {target_file.name} (Preset: {preset})[/bold green]",
                subtitle=f"Location: {target_file}",
                border_style="green",
            )
        )
        console.print(
            "[bold cyan]✓ Ready![/bold cyan] HADES Two-Stage Discovery will now resolve generic UART bridges "
            f"(e.g. CP2102, CH340) directly to [bold]{manifest.target.board}[/bold] using this manifest."
        )
    except Exception as e:
        console.print(f"[bold red]Failed to write manifest:[/bold red] {e}")
        raise typer.Exit(code=1)

