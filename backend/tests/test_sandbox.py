"""Unit tests for sandbox session management and CLI commands."""

import subprocess
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from typer.testing import CliRunner

from hades.cli.main import app
from hades.cli.sandbox import SandboxSession, load_sessions, new_session, save_sessions

runner = CliRunner()


class TestSandboxRegistry:
    def test_load_sessions_missing_file(self, tmp_path):
        state_file = tmp_path / "sessions.json"
        assert load_sessions(state_file) == {}

    def test_save_and_load_sessions(self, tmp_path):
        state_file = tmp_path / "sessions.json"
        session = new_session(
            workspace="/tmp/test",
            target="esp32-devkit-v1",
            isolation="container",
            hardware=["usb:10c4:ea60:1-4"],
            runtime_id="container-123",
        )
        save_sessions({session.session_id: session}, state_path=state_file)
        loaded = load_sessions(state_file)
        assert session.session_id in loaded
        assert loaded[session.session_id].workspace == "/tmp/test"
        assert loaded[session.session_id].target == "esp32-devkit-v1"
        assert loaded[session.session_id].runtime_id == "container-123"

    def test_load_sessions_invalid_json(self, tmp_path):
        state_file = tmp_path / "sessions.json"
        state_file.write_text("invalid json", encoding="utf-8")
        with pytest.raises(RuntimeError):
            load_sessions(state_file)


class TestSandboxCommands:
    def test_list_command_empty(self, monkeypatch, tmp_path):
        state_file = tmp_path / "sessions.json"
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: {})
        result = runner.invoke(app, ["list"])
        assert result.exit_code == 0
        assert "Active HADES Sandboxes" in result.stdout

    def test_list_command_with_sessions(self, monkeypatch):
        sessions = {
            "abc123": SandboxSession(
                session_id="abc123",
                workspace="/workspace/esp32",
                target="esp32-devkit-v1",
                isolation="container",
                hardware=["usb:10c4:ea60:1-4"],
                runtime_id="cont-1",
            )
        }
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: sessions)
        result = runner.invoke(app, ["list"])
        assert result.exit_code == 0
        assert "abc123" in result.stdout
        assert "esp32" in result.stdout

    def test_up_command_missing_manifest(self, tmp_path):
        result = runner.invoke(app, ["up", "--dir", str(tmp_path)])
        assert result.exit_code == 1
        assert "Cannot start sandbox" in result.stdout

    def test_up_command_missing_runtime(self, monkeypatch):
        manifest_mock = MagicMock()
        manifest_mock.isolation.base_image = "hades/sandbox:latest"
        monkeypatch.setattr("hades.cli.commands.sandbox.load_manifest", lambda workspace_dir: (manifest_mock, None))
        monkeypatch.setattr("shutil.which", lambda prog: None)
        result = runner.invoke(app, ["up"])
        assert result.exit_code == 1
        assert "configure a Docker/Podman runtime" in result.stdout

    def test_up_command_missing_base_image(self, monkeypatch):
        manifest_mock = MagicMock()
        manifest_mock.isolation.base_image = None
        monkeypatch.setattr("hades.cli.commands.sandbox.load_manifest", lambda workspace_dir: (manifest_mock, None))
        monkeypatch.setattr("shutil.which", lambda prog: "/usr/bin/docker")
        result = runner.invoke(app, ["up"])
        assert result.exit_code == 1
        assert "configure isolation.base_image" in result.stdout

    def test_up_command_success(self, monkeypatch, tmp_path):
        manifest_mock = MagicMock()
        manifest_mock.target.board = "esp32-devkit-v1"
        manifest_mock.isolation.preferred_mode = "container"
        manifest_mock.isolation.base_image = "espressif/idf:v5.1"
        monkeypatch.setattr("hades.cli.commands.sandbox.load_manifest", lambda workspace_dir: (manifest_mock, None))
        monkeypatch.setattr("hades.cli.commands.sandbox.scan_usb_devices", lambda manifest: [])
        monkeypatch.setattr("shutil.which", lambda prog: "/usr/bin/docker")

        mock_sessions = {}
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: mock_sessions)
        monkeypatch.setattr("hades.cli.commands.sandbox.save_sessions", lambda s: mock_sessions.update(s))

        fake_proc = MagicMock()
        fake_proc.stdout = "runtime-container-id-xyz\n"
        monkeypatch.setattr("subprocess.run", lambda *args, **kwargs: fake_proc)

        result = runner.invoke(app, ["up", "--dir", str(tmp_path)])
        assert result.exit_code == 0
        assert "Sandbox started:" in result.stdout
        assert len(mock_sessions) == 1

    def test_shell_command_unknown_session(self, monkeypatch):
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: {})
        result = runner.invoke(app, ["shell", "nonexistent"])
        assert result.exit_code == 1
        assert "Unknown session" in result.stdout

    def test_shell_command_no_runtime_id(self, monkeypatch):
        sessions = {
            "sess1": SandboxSession(
                session_id="sess1",
                workspace="/ws",
                target="board",
                isolation="container",
                hardware=[],
                runtime_id=None,
            )
        }
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: sessions)
        result = runner.invoke(app, ["shell", "sess1"])
        assert result.exit_code == 1
        assert "No running runtime is recorded" in result.stdout

    def test_shell_command_missing_runtime_tool(self, monkeypatch):
        sessions = {
            "sess1": SandboxSession(
                session_id="sess1",
                workspace="/ws",
                target="board",
                isolation="container",
                hardware=[],
                runtime_id="cont-123",
            )
        }
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: sessions)
        monkeypatch.setattr("shutil.which", lambda prog: None)
        result = runner.invoke(app, ["shell", "sess1"])
        assert result.exit_code == 1
        assert "Docker or Podman is required" in result.stdout

    def test_shell_command_success(self, monkeypatch):
        sessions = {
            "sess1": SandboxSession(
                session_id="sess1",
                workspace="/ws",
                target="board",
                isolation="container",
                hardware=[],
                runtime_id="cont-123",
            )
        }
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: sessions)
        monkeypatch.setattr("shutil.which", lambda prog: "/usr/bin/docker")

        mock_run = MagicMock()
        mock_run.returncode = 0
        monkeypatch.setattr("subprocess.run", lambda *args, **kwargs: mock_run)

        result = runner.invoke(app, ["shell", "sess1"])
        assert result.exit_code == 0

    def test_down_command_unknown_session(self, monkeypatch):
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: {})
        result = runner.invoke(app, ["down", "nonexistent"])
        assert result.exit_code == 1
        assert "Unknown session" in result.stdout

    def test_down_command_success(self, monkeypatch):
        sessions = {
            "sess1": SandboxSession(
                session_id="sess1",
                workspace="/ws",
                target="board",
                isolation="container",
                hardware=["usb:1:1:1"],
                runtime_id="cont-123",
            )
        }
        monkeypatch.setattr("hades.cli.commands.sandbox.load_sessions", lambda: sessions)
        mock_saved = {}
        monkeypatch.setattr("hades.cli.commands.sandbox.save_sessions", lambda s: mock_saved.update(s))
        monkeypatch.setattr("shutil.which", lambda prog: "/usr/bin/docker")
        mock_run = MagicMock()
        monkeypatch.setattr("subprocess.run", lambda *args, **kwargs: mock_run)

        result = runner.invoke(app, ["down", "sess1"])
        assert result.exit_code == 0
        assert "Cleanup audit: sess1" in result.stdout
        assert "session registry" in result.stdout
        assert "hardware mappings" in result.stdout
        assert "sess1" not in mock_saved
