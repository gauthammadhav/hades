import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum Runtime {
  docker,
  qemu,
  blocked;

  String get label {
    switch (this) {
      case Runtime.docker:
        return 'DOCKER_CONTAINER';
      case Runtime.qemu:
        return 'QEMU_KVM_VM';
      case Runtime.blocked:
        return 'BLOCKED';
    }
  }

  Color get dotColor {
    switch (this) {
      case Runtime.docker:
        return AppColors.info;
      case Runtime.qemu:
        return AppColors.vmPurple;
      case Runtime.blocked:
        return AppColors.danger;
    }
  }

  Color get chipBgColor {
    switch (this) {
      case Runtime.docker:
        return AppColors.chipBlueBg;
      case Runtime.qemu:
        return AppColors.chipPurpleBg;
      case Runtime.blocked:
        return AppColors.chipRedBg;
    }
  }

  Color get chipTextColor {
    switch (this) {
      case Runtime.docker:
        return AppColors.info;
      case Runtime.qemu:
        return AppColors.vmPurple;
      case Runtime.blocked:
        return AppColors.danger;
    }
  }

  bool get isBlocked => this == Runtime.blocked;
}
