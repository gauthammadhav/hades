"""Unit tests for the HADES Typer CLI commands."""

import json
from typer.testing import CliRunner
from hades.cli.main import app

runner = CliRunner()


def test_hades_version():
    result = runner.invoke(app, ["--version"])
    assert result.exit_code == 0
    assert "HADES CLI version" in result.stdout


def test_hades_detect_help():
    result = runner.invoke(app, ["detect", "--help"])
    assert result.exit_code == 0
    assert "Scan and identify connected USB hardware" in result.stdout


def test_hades_detect_simulate_esp32_native():
    result = runner.invoke(app, ["detect", "--simulate", "esp32-native"])
    assert result.exit_code == 0
    assert "ESP32-S3" in result.stdout
    assert "303a:1001" in result.stdout
    assert "Stage-1" in result.stdout


def test_hades_detect_simulate_json():
    result = runner.invoke(app, ["detect", "--simulate", "esp32-native", "--json"])
    assert result.exit_code == 0
    data = json.loads(result.stdout)
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["vendor_id"] == "303a"
    assert data[0]["product_id"] == "1001"
    assert data[0]["port_topology"] == "1-2.1"
    assert data[0]["resolution_stage"] == "stage_1_passive"


def test_hades_detect_simulate_ambiguous_bridge(tmp_path):
    # Running detect against empty temp workspace without manifest
    result = runner.invoke(app, ["detect", "--simulate", "esp32-cp2102-ambiguous", "-w", str(tmp_path)])
    assert result.exit_code == 0
    assert "Ambiguous" in result.stdout
    assert "Gap A Notice" in result.stdout


def test_hades_init_generates_manifest(tmp_path):
    result = runner.invoke(app, ["init", "--preset", "stm32", "--output", str(tmp_path), "--name", "my-stm32-proj"])
    assert result.exit_code == 0
    manifest_file = tmp_path / ".hades.yaml"
    assert manifest_file.exists()
    content = manifest_file.read_text()
    assert "stm32" in content
    assert "my-stm32-proj" in content


def test_hades_init_nested_dir_and_force(tmp_path):
    nested = tmp_path / "subdir" / "nested"
    result = runner.invoke(app, ["init", "--preset", "pico", "--output", str(nested), "--name", "pico-project"])
    assert result.exit_code == 0
    manifest_file = nested / ".hades.yaml"
    assert manifest_file.exists()

    # Re-run without --force
    res_no_force = runner.invoke(app, ["init", "--preset", "pico", "--output", str(nested)])
    assert "A manifest already exists" in res_no_force.stdout

    # Re-run with --force
    res_force = runner.invoke(app, ["init", "--preset", "esp32", "--output", str(nested), "--force"])
    assert res_force.exit_code == 0
    assert "esp32" in manifest_file.read_text()
