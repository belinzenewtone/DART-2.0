import 'dart:io';

import 'package:dart_2_0/core/update/domain/update_install_progress.dart';
import 'package:ota_update/ota_update.dart';

Stream<UpdateInstallProgress> installApkUpdate(String url) async* {
  if (!Platform.isAndroid) {
    yield const UpdateInstallProgress(
      state: UpdateInstallState.unsupported,
      message: 'APK in-app update is supported on Android only.',
    );
    return;
  }

  yield const UpdateInstallProgress(state: UpdateInstallState.starting);

  try {
    await for (final dynamic event in OtaUpdate().execute(url)) {
      final status = event.status.toString().toLowerCase();
      final value = event.value?.toString();

      if (status.contains('downloading')) {
        final parsed = double.tryParse(value ?? '');
        yield UpdateInstallProgress(
          state: UpdateInstallState.downloading,
          percent: parsed == null ? null : parsed.clamp(0, 100) / 100,
          message: value,
        );
        continue;
      }
      if (status.contains('installing')) {
        yield UpdateInstallProgress(
          state: UpdateInstallState.installing,
          message: value,
        );
        continue;
      }
      if (status.contains('installed') || status.contains('success')) {
        yield const UpdateInstallProgress(state: UpdateInstallState.completed);
        continue;
      }
      if (status.contains('error') || status.contains('permission')) {
        yield UpdateInstallProgress(
          state: UpdateInstallState.failed,
          message: value ?? 'Update failed',
        );
      }
    }
  } catch (error) {
    yield UpdateInstallProgress(
      state: UpdateInstallState.failed,
      message: error.toString(),
    );
  }
}
