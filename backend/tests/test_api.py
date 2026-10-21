"""Unit and integration tests for HADES API endpoints."""

from fastapi.testclient import TestClient
import pytest

from hades.api.app import app
from hades.discovery.simulation import get_simulated_devices

client = TestClient(app)


def test_api_health():
    res = client.get("/v1/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert "subsystems" in data


def test_api_list_devices_simulated():
    res = client.get("/v1/devices?simulate=esp32-native")
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["vendor_id"] == "303a"
    assert data[0]["product_id"] == "1001"
    assert data[0]["port_topology"] == "1-2.1"
    assert data[0]["resolution_stage"] == "stage_1_passive"


def test_api_list_devices_ambiguous_bridge(tmp_path):
    res = client.get(f"/v1/devices?simulate=esp32-cp2102-ambiguous&workspace={tmp_path}")
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 1
    assert data[0]["vendor_id"] == "10c4"
    assert data[0]["product_id"] == "ea60"
    assert data[0]["resolution_stage"] == "stage_2_ambiguous"


def test_api_resolve_device(tmp_path):
    # Test resolving ambiguous CP2102 against an esp32 manifest
    from hades.resolver.manifest import generate_preset_manifest, save_manifest

    manifest = generate_preset_manifest("esp32", "test-project")
    manifest_path = tmp_path / ".hades.yaml"
    save_manifest(manifest, manifest_path)

    devices = get_simulated_devices("esp32-cp2102-ambiguous")
    req_body = {
        "device": devices[0].model_dump(mode="json"),
        "workspace": str(tmp_path),
    }

    res = client.post("/v1/devices/resolve", json=req_body)
    assert res.status_code == 200
    resolved = res.json()
    assert resolved["resolution_stage"] == "stage_2_manifest"
    assert resolved["target_board"] == "esp32-devkit-v1"
    assert resolved["target_chip"] == "ESP32"


def test_api_manifest_workflow(tmp_path):
    # 1. Initially no manifest
    res = client.get(f"/v1/manifest?workspace={tmp_path}")
    assert res.status_code == 200
    assert res.json()["valid"] is False

    # 2. Init manifest
    init_res = client.post(
        "/v1/manifest/init",
        json={"preset": "stm32", "workspace": str(tmp_path), "name": "demo-stm32"},
    )
    assert init_res.status_code == 200
    assert init_res.json()["success"] is True

    # 3. Read manifest again
    res2 = client.get(f"/v1/manifest?workspace={tmp_path}")
    assert res2.status_code == 200
    assert res2.json()["valid"] is True
    assert res2.json()["manifest"]["project"]["name"] == "demo-stm32"


def test_api_session_lifecycle(tmp_path):
    # 1. Create session with simulated ESP32 device
    devices = get_simulated_devices("esp32-native")
    create_body = {
        "workspace": str(tmp_path),
        "device": devices[0].model_dump(mode="json"),
    }
    create_res = client.post("/v1/sessions", json=create_body)
    assert create_res.status_code == 200
    session_data = create_res.json()
    session_id = session_data["id"]
    assert session_data["isolation"] == "container"
    assert session_data["state"] == "running"

    # 2. List sessions
    list_res = client.get("/v1/sessions")
    assert list_res.status_code == 200
    sessions = list_res.json()
    assert any(s["id"] == session_id for s in sessions)

    # 3. Get session by ID
    get_res = client.get(f"/v1/sessions/{session_id}")
    assert get_res.status_code == 200
    assert get_res.json()["id"] == session_id

    # 4. Check initial audit records
    audit_res = client.get(f"/v1/sessions/{session_id}/audit")
    assert audit_res.status_code == 200
    records = audit_res.json()
    assert len(records) >= 2
    events = [r["event"] for r in records]
    assert "policy_decision" in events
    assert "session_started" in events

    # 5. Teardown session
    del_res = client.delete(f"/v1/sessions/{session_id}")
    assert del_res.status_code == 200
    teardown_data = del_res.json()
    assert teardown_data["status"] == "stopped"
    assert teardown_data["pollution"] == "0%"

    # 6. Verify cleanup audit recorded
    audit_after = client.get(f"/v1/sessions/{session_id}/audit").json()
    events_after = [r["event"] for r in audit_after]
    assert "cleanup_audit" in events_after


def test_api_unauthorized_device_rejection():
    # Simulate unauthorized HID or rejected device
    from hades.models.device import (
        DeviceClassification,
        DiscoveredDevice,
        IsolationRecommendation,
    )

    unauthorized_device = DiscoveredDevice(
        device_id="usb:0951:1666:1-3",
        vendor_id="0951",
        product_id="1666",
        vendor_name="Kingston",
        product_name="DataTraveler HID/Storage",
        bus_num=1,
        dev_num=3,
        port_topology="1-3",
        sys_path="/sys/devices/1-3",
        sys_name="1-3",
        classification=DeviceClassification.UNAUTHORIZED,
        isolation_recommendation=IsolationRecommendation.REJECT_POLICY,
    )

    create_body = {
        "device": unauthorized_device.model_dump(mode="json"),
    }
    res = client.post("/v1/sessions", json=create_body)
    assert res.status_code == 403
    assert "rejected by least-privilege security policy" in res.json()["detail"]


def test_api_websocket_ping_pong():
    with client.websocket_connect("/v1/ws/*") as websocket:
        websocket.send_text("ping")
        data = websocket.receive_text()
        assert data == "pong"
