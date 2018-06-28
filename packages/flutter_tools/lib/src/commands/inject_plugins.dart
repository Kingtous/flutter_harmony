// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../plugins.dart';
import '../runner/flutter_command.dart';

class InjectPluginsCommand extends FlutterCommand {
  InjectPluginsCommand({ this.hidden = false }) {
    requiresPubspecYaml();
  }

  @override
  final String name = 'inject-plugins';

  @override
  final String description = 'Re-generates the GeneratedPluginRegistrants.';

  @override
  final bool hidden;

  @override
  Future<Null> runCommand() async {
    injectPlugins();
    final bool result = hasPlugins();
    if (result) {
      printStatus('GeneratedPluginRegistrants successfully written.');
    } else {
      printStatus('This project does not use plugins, no GeneratedPluginRegistrants have been created.');
    }
  }
}
