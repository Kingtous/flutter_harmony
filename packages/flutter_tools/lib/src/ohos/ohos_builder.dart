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

import '../base/context.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../project.dart';

/// The builder in the current context.
OhosBuilder? get ohosBuilder {
  return context.get<OhosBuilder>();
}

abstract class OhosBuilder {
  const OhosBuilder();

  /// build hap
  Future<void> buildHap(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger});

  /// build har
  Future<void> buildHar(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger});

  /// build app
  Future<void> buildApp(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger});

  /// build hsp
  Future<void> buildHsp(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger});
}
