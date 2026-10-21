import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class PoliciesView extends StatelessWidget {
  const PoliciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Security & Isolation Policies',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hardware-level access control, isolation boundaries, and driver verification',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.chipMintBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shield_rounded, size: 14, color: AppColors.ok),
                  SizedBox(width: 6),
                  Text(
                    'Enforcing Strict Sandbox',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Two Column Bento
        SizedBox(
          height: 480,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Policy Rules List
              Expanded(
                flex: 55,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
                    boxShadow: AppTheme.softShadow,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Active Rule Matrix',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '4 Rules Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView(
                          children: const [
                            _PolicyRuleItem(
                              title: 'Serial / Communication (CDC-ACM 0x02)',
                              action: 'ALLOW → DOCKER CONTAINER',
                              reason: 'Standard ttyACM character device with no host root escalation',
                              actionColor: AppColors.info,
                              actionBg: AppColors.chipBlueBg,
                              icon: Icons.check_circle_rounded,
                            ),
                            Divider(color: AppColors.border, height: 16),
                            _PolicyRuleItem(
                              title: 'Proprietary Kernel Driver (Vendor 0xFF)',
                              action: 'ISOLATE → QEMU/KVM VM',
                              reason: 'Third-party .ko driver must execute in guest kernel only',
                              actionColor: AppColors.vmPurple,
                              actionBg: AppColors.chipPurpleBg,
                              icon: Icons.security_rounded,
                            ),
                            Divider(color: AppColors.border, height: 16),
                            _PolicyRuleItem(
                              title: 'Human Interface Devices (HID 0x03)',
                              action: 'DENY → ACCESS BLOCKED',
                              reason: 'BadUSB & Rubber Ducky keystroke injection protection',
                              actionColor: AppColors.danger,
                              actionBg: AppColors.chipRedBg,
                              icon: Icons.block_rounded,
                            ),
                            Divider(color: AppColors.border, height: 16),
                            _PolicyRuleItem(
                              title: 'Mass Storage Controller (0x08)',
                              action: 'DENY → ACCESS BLOCKED',
                              reason: 'Prevents untrusted USB mass-storage file execution',
                              actionColor: AppColors.danger,
                              actionBg: AppColors.chipRedBg,
                              icon: Icons.block_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right: .hades.yaml Manifest Preview
              Expanded(
                flex: 45,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    boxShadow: AppTheme.softShadow,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.code_rounded, size: 16, color: AppColors.logAudit),
                              SizedBox(width: 8),
                              Text(
                                '.hades.yaml Policy Manifest',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.heroPillBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'v1.0.4',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.1), width: 1),
                          ),
                          child: const SingleChildScrollView(
                            child: Text(
                              'schema_version: "1.0"\n'
                              'policy:\n'
                              '  enforce: strict\n'
                              '  host_pollution_limit: 0%\n'
                              'rules:\n'
                              '  - match:\n'
                              '      class: "0x02" # CDC-ACM\n'
                              '    decision: "DOCKER_CONTAINER"\n'
                              '    broker: "cgroup allow, unprivileged"\n'
                              '\n'
                              '  - match:\n'
                              '      class: "0xFF" # Vendor specific\n'
                              '    decision: "QEMU_KVM_VM"\n'
                              '    broker: "libvirt hostdev hotplug"\n'
                              '\n'
                              '  - match:\n'
                              '      class: ["0x03", "0x08"]\n'
                              '    decision: "BLOCK"\n'
                              '    reason: "HID/storage not approved"',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.45,
                                color: AppColors.logNormal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicyRuleItem extends StatelessWidget {
  final String title;
  final String action;
  final String reason;
  final Color actionColor;
  final Color actionBg;
  final IconData icon;

  const _PolicyRuleItem({
    required this.title,
    required this.action,
    required this.reason,
    required this.actionColor,
    required this.actionBg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: actionBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: actionBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: actionColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
