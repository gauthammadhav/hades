"""Main CLI entrypoint for HADES."""

from typing import Optional
import typer
from hades import __version__
from hades.cli.commands.detect import detect_command
from hades.cli.commands.init import init_command
from hades.cli.commands.watch import watch_command
from hades.cli.commands.sandbox import down_command, list_command, shell_command, up_command

app = typer.Typer(
    name="hades",
    help="HADES: Hardware-Aware Development Sandbox - Discovery & Orchestration CLI",
    add_completion=False,
)

# Register primary commands
app.command(name="detect", help="Scan and identify connected USB hardware and serial ports.")(detect_command)
app.command(name="scan", help="Alias for 'detect' - scan connected hardware.")(detect_command)
app.command(name="watch", help="Listen live for USB plug, unplug, and reset events via kernel netlink.")(watch_command)
app.command(name="init", help="Create a .hades.yaml workspace manifest for target hardware.")(init_command)
app.command(name="up", help="Resolve and launch a workspace sandbox.")(up_command)
app.command(name="shell", help="Open a shell in an active sandbox.")(shell_command)
app.command(name="list", help="List active sandboxes and mapped hardware.")(list_command)
app.command(name="down", help="Terminate a sandbox and audit cleanup.")(down_command)


def version_callback(value: bool):
    if value:
        typer.echo(f"HADES CLI version {__version__}")
        raise typer.Exit()


@app.callback()
def main(
    version: Optional[bool] = typer.Option(
        None,
        "--version",
        "-v",
        help="Show HADES version and exit.",
        callback=version_callback,
        is_eager=True,
    ),
):
    """HADES - Hardware-Aware Development Sandbox CLI."""
    pass


if __name__ == "__main__":
    app()
