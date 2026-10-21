enum Stage {
  deviceDetected(1, 'Detected', 'DEVICE_DETECTED'),
  requirementsResolved(2, 'Resolved', 'REQUIREMENTS_RESOLVED'),
  policyEvaluated(3, 'Policy', 'POLICY_EVALUATED'),
  sandboxProvisioned(4, 'Provisioned', 'SANDBOX_PROVISIONED'),
  sessionActive(5, 'Active', 'SESSION_ACTIVE'),
  teardownVerified(6, 'Teardown', 'TEARDOWN_VERIFIED');

  const Stage(this.number, this.shortLabel, this.rawName);

  final int number;
  final String shortLabel;
  final String rawName;

  String getDisplayLabel({required bool isBlocked}) {
    if (this == Stage.policyEvaluated && isBlocked) {
      return 'Blocked';
    }
    return shortLabel;
  }

  String getDetailTitle({required bool isBlocked}) {
    if (this == Stage.policyEvaluated && isBlocked) {
      return 'Blocked';
    }
    switch (this) {
      case Stage.deviceDetected:
        return 'Device detected';
      case Stage.requirementsResolved:
        return 'Requirements resolved';
      case Stage.policyEvaluated:
        return 'Policy evaluated';
      case Stage.sandboxProvisioned:
        return 'Sandbox provisioned';
      case Stage.sessionActive:
        return 'Session active';
      case Stage.teardownVerified:
        return 'Teardown verified';
    }
  }

  String getHeroStatusText({required bool isBlocked}) {
    if (isBlocked && this == Stage.policyEvaluated) {
      return 'Blocked by policy';
    }
    return getDetailTitle(isBlocked: isBlocked);
  }
}
