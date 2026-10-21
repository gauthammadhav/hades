"""Sandbox lifecycle commands."""

import shutil
import subprocess
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.table import Table

from hades.cli.sandbox import load_sessions, new_session, save_sessions
from hades.discovery.udev_scanner import scan_usb_devices
from hades.resolver.manifest import load_manifest

console = Console()


def up_command(
    directory: Path = typer.Option(Path("."), "--dir", help="Workspace directory containing .hades.yaml."),
):
    """Resolve hardware and launch a configured sandbox runtime."""
    workspace = directory.resolve()
    manifest, error = load_manifest(workspace_dir=workspace)
    if error or manifest is None:
        console.print(f"[red]Cannot start sandbox:[/red] {error}")
        raise typer.Exit(code=1)

    devices = scan_usb_devices(manifest=manifest)
    runtime = shutil.which("docker") or shutil.which("podman")
    image = manifest.isolation.base_image
    if runtime is None or not image:
        missing = "a Docker/Podman runtime" if runtime is None else "isolation.base_image"
        console.print(
            f"[red]Sandbox not launched:[/red] configure {missing} before running 'hades up'."
        )
        raise typer.Exit(code=1)

    session = new_session(
        workspace=str(workspace),
        target=manifest.target.board,
        isolation=manifest.isolation.preferred_mode,
        hardware=[device.device_id for device in devices],
    )
    try:
        result = subprocess.run(
            [runtime, "run", "--detach", "--name", f"hades-{session.session_id}", image],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        console.print(f"[red]Sandbox runtime failed:[/red] {exc.stderr.strip() or exc}")
        raise typer.Exit(code=1) from exc
    session.runtime_id = result.stdout.strip()
    sessions = load_sessions()
    sessions[session.session_id] = session
    save_sessions(sessions)
    console.print(f"[green]Sandbox started:[/green] {session.session_id}")


def shell_command(session_id: str):
    """Open an interactive shell in an active sandbox."""
    sessions = load_sessions()
    session = sessions.get(session_id)
    if session is None:
        console.print(f"[red]Unknown session:[/red] {session_id}")
        raise typer.Exit(code=1)
    if not session.runtime_id:
        console.print("[red]No running runtime is recorded for that session.[/red]")
        raise typer.Exit(code=1)
    runtime = shutil.which("docker") or shutil.which("podman")
    if runtime is None:
        console.print("[red]Docker or Podman is required for shell access.[/red]")
        raise typer.Exit(code=1)
    result = subprocess.run([runtime, "exec", "-it", session.runtime_id, "bash"], check=False)
    raise typer.Exit(code=result.returncode)


def list_command():
    """Show active sandbox sessions and mapped hardware."""
    sessions = load_sessions()
    table = Table(title="Active HADES Sandboxes")
    table.add_column("Session")
    table.add_column("Isolation")
    table.add_column("Workspace")
    table.add_column("Mapped hardware")
    for session in sessions.values():
        table.add_row(session.session_id, session.isolation, session.workspace, ", ".join(session.hardware) or "none")
    console.print(table)


def down_command(session_id: str):
    """Terminate a sandbox session and show its cleanup audit."""
    sessions = load_sessions()
    session = sessions.pop(session_id, None)
    if session is None:
        console.print(f"[red]Unknown session:[/red] {session_id}")
        raise typer.Exit(code=1)
    if session.runtime_id:
        runtime = shutil.which("docker") or shutil.which("podman")
        if runtime is not None:
            subprocess.run([runtime, "rm", "--force", session.runtime_id], check=False, capture_output=True)
    save_sessions(sessions)
    table = Table(title=f"Cleanup audit: {session_id}")
    table.add_column("Resource")
    table.add_column("Action")
    table.add_row("session registry", "removed")
    table.add_row("hardware mappings", f"released ({len(session.hardware)})")
    console.print(table)
