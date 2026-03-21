import 'dart:async';

import 'package:beltech/core/di/update_providers.dart';
import 'package:beltech/core/ota/patch_notes_registry.dart';
import 'package:beltech/core/ota/patch_ready_info.dart';
import 'package:beltech/core/ota/shorebird_patch_service.dart';
import 'package:beltech/core/ota/shorebird_providers.dart';
import 'package:beltech/core/update/presentation/app_update_dialog.dart';
import 'package:beltech/core/update/presentation/patch_ready_dialog.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalUpdateHost extends ConsumerStatefulWidget {
  const GlobalUpdateHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<GlobalUpdateHost> createState() => _GlobalUpdateHostState();
}

class _GlobalUpdateHostState extends ConsumerState<GlobalUpdateHost>
    with WidgetsBindingObserver {
  bool _checkedBinaryUpdate = false;
  bool _patchDialogOpen = false;
  int? _dismissedPatchForSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runStartupChecks());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkShorebirdPatch(includeDelayedCheck: false));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _runStartupChecks() async {
    await _checkForBinaryUpdate();
    await _checkShorebirdPatch(includeDelayedCheck: true);
  }

  Future<void> _checkForBinaryUpdate() async {
    if (_checkedBinaryUpdate || !mounted) {
      return;
    }
    _checkedBinaryUpdate = true;
    final service = ref.read(appUpdateServiceProvider);
    final update = await service.fetchAvailableUpdate();
    if (!mounted || update == null) {
      return;
    }
    await showAppDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) => AppUpdateDialog(update: update, service: service),
    );
  }

  Future<void> _checkShorebirdPatch({required bool includeDelayedCheck}) async {
    if (!mounted) {
      return;
    }

    final service = ref.read(shorebirdPatchServiceProvider);
    try {
      final available = await service.isShorebirdAvailable();
      if (!available || !mounted) {
        return;
      }

      final immediateInfo = await _pendingPatchInfo(service);
      if (!mounted) {
        return;
      }
      if (immediateInfo != null) {
        await _showPatchDialogIfNeeded(immediateInfo);
        return;
      }

      if (!includeDelayedCheck) {
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 8));
      if (!mounted) {
        return;
      }

      final delayedInfo = await _pendingPatchInfo(service);
      if (!mounted || delayedInfo == null) {
        return;
      }
      await _showPatchDialogIfNeeded(delayedInfo);
    } catch (_) {
      return;
    }
  }

  Future<PatchReadyInfo?> _pendingPatchInfo(
    ShorebirdPatchService service,
  ) async {
    final currentPatchNumber = await service.currentPatch();
    final nextPatchNumber = await service.nextPatch();
    if (nextPatchNumber == null || nextPatchNumber == currentPatchNumber) {
      return null;
    }
    return patchReadyInfoFor(
      currentPatchNumber: currentPatchNumber,
      nextPatchNumber: nextPatchNumber,
    );
  }

  Future<void> _showPatchDialogIfNeeded(PatchReadyInfo info) async {
    if (!mounted ||
        _patchDialogOpen ||
        _dismissedPatchForSession == info.nextPatchNumber) {
      return;
    }

    _patchDialogOpen = true;
    await showAppDialog<void>(
      context: context,
      builder: (_) => PatchReadyDialog(
        info: info,
        onDismiss: () {
          _dismissedPatchForSession = info.nextPatchNumber;
          Navigator.of(context, rootNavigator: true).maybePop();
        },
      ),
    );
    _patchDialogOpen = false;
  }
}
