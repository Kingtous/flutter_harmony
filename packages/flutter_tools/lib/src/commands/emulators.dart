// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../doctor.dart';
import '../emulator.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class EmulatorsCommand extends FlutterCommand {
  EmulatorsCommand() {
    argParser.addOption('launch',
        help: 'The full or partial ID of the emulator to launch.');
  }

  @override
  final String name = 'emulators';

  @override
  final String description = 'List and launch available emulators.';

  @override
  Future<Null> runCommand() async {
    if (doctor.workflows.every((Workflow w) => !w.canListEmulators)) {
      throwToolExit(
          'Unable to find any emulator sources. Please ensure you have some\n'
          'Android AVD images ' + (platform.isMacOS ? 'or an iOS Simulator ' : '')
          + 'available.',
          exitCode: 1);
    }

    if (argResults.wasParsed('launch')) {
      await _launchEmulator(argResults['launch']);
    } else {
      final String searchText =
          argResults.rest != null && argResults.rest.isNotEmpty
              ? argResults.rest.first
              : null;
      await _listEmulators(searchText);
    }
  }

  Future<Null> _launchEmulator(String id) async {
    final List<Emulator> emulators =
        await emulatorManager.getEmulatorsMatching(id).toList();

    if (emulators.isEmpty) {
      printStatus("No emulator found that matches '$id'.");
    } else if (emulators.length > 1) {
      printStatus("More than one emulator matches '$id':\n");
      Emulator.printEmulators(emulators);
    } else {
      emulators.first.launch();
    }
  }

  Future<Null> _listEmulators(String searchText) async {
    final List<Emulator> emulators =
        searchText == null
        ? await emulatorManager.getAllAvailableEmulators().toList()
        : await emulatorManager.getEmulatorsMatching(searchText).toList();

    if (emulators.isEmpty) {
      printStatus('No emulators available.\n\n'
          // TODO(dantup): Change these when we support creation
          // 'You may need to create images using "flutter emulators --create"\n'
          'You may need to create one using Android Studio '
          'or visit https://flutter.io/setup/ for troubleshooting tips.');
    } else {
      printStatus(
          '${emulators.length} available ${pluralize('emulator', emulators.length)}:\n');
      Emulator.printEmulators(emulators);
    }
  }
}
