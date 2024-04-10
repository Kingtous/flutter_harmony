/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import '../build_info.dart';
import '../globals.dart' as globals;
import '../ohos/ohos_builder.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildHarCommand extends BuildSubCommand {
  BuildHarCommand({required super.logger, bool verboseHelp = false})
      : super(verboseHelp: verboseHelp) {
    const String defaultTargetPlatform = 'ohos-arm64';
    usesTargetOption();
    addDartObfuscationOption();
    addSplitDebugInfoOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    argParser.addOption(
      'target-platform',
      defaultsTo: defaultTargetPlatform,
      allowed: <String>['ohos-arm64', 'ohos-arm', 'ohos-x86'],
      help: 'The target platform for which the app is compiled.',
    );
    addBuildModeFlags(verboseHelp: verboseHelp);
  }

  @override
  final String description = 'Build an Ohos har file from your app.\n\n';

  @override
  String get name => 'har';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    final TargetPlatform targetPlatform =
        getTargetPlatformForName(stringArgDeprecated('target-platform')!);
    await ohosBuilder?.buildHar(
      FlutterProject.current(),
      buildInfo,
      targetPlatform: targetPlatform,
      logger: globals.logger,
      target: targetFile,
    );
    return FlutterCommandResult.success();
  }
}
