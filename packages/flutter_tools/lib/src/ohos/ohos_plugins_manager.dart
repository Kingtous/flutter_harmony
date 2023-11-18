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

import '../base/common.dart';
import '../base/file_system.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import 'hvigor.dart';

/// 检查plugins的har是否需要更新
Future<void> checkPluginsHarUpdate(
  FlutterProject flutterProject,
) async {
  final List<OhosPlugin> list = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .map((Plugin p) => p.platforms[OhosPlugin.kConfigKey]! as OhosPlugin)
      .toList();
  if (list.isEmpty) {
    globals.printStatus('ohosPluginsManager: no need to install ohos plugins');
    return;
  }

  ///检查当前工程下har文件夹下已生成的har文件
  final List<String> harFiles = getProjectHarList(flutterProject);

  final List<OhosPlugin> toBeGenerateHarList = list
      .where((OhosPlugin plugin) => !harFiles.contains('${plugin.name}.har'))
      .toList();
  if (toBeGenerateHarList.isEmpty) {
    globals.printStatus(
        'ohosPluginsManager: no need to update ohos plugins har file');
    return;
  }

  /// 每一个待生成的har工程，执行assembleHar
  final List<String> harPaths =
      await Future.wait(toBeGenerateHarList.map((OhosPlugin element) async {
    final String path = await pluginsHarGenerate(
        globals.fs.path.join(element.pluginPath, 'ohos'), element.name);
    return path;
  }).toList());

  /// 拷贝所有har到project下har
  for (final String path in harPaths) {
    final File originFile = globals.fs.file(path);
    final String descPath = globals.fs.path.join(
        flutterProject.ohos.ohosRoot.childDirectory('har').path,
        originFile.basename);
    originFile.copySync(descPath);
  }
  if (toBeGenerateHarList.isEmpty) {
    globals.printStatus(
        'ohosPluginsManager: ohos plugins har files update success!');
  }
}

List<String> getProjectHarList(FlutterProject flutterProject) {
  final Directory directory =
      flutterProject.ohos.ohosRoot.childDirectory('har');
  if (directory.existsSync()) {
    return directory
        .listSync()
        .map((FileSystemEntity file) => file.path)
        .toList();
  } else {
    directory.createSync();
    return List<String>.empty();
  }
}

Future<String> pluginsHarGenerate(String pluginPath, String pluginName) async {
  final String hvigorwPath = getHvigorwPath(pluginPath, checkMod: true);
  final int errorCode0 = await assembleHar(
      processManager: globals.processManager,
      workPath: pluginPath,
      moduleName: 'ohos',
      hvigorwPath: hvigorwPath,
      logger: globals.logger);
  if (errorCode0 != 0) {
    throwToolExit(
        'ohosPluginsManager: pluginPath:$pluginPath, assembleHar error! please check log.');
  }
  final String originHarPath = getHarPath(pluginPath, 'ohos.har');
  final File originHarFile = globals.fs.file(originHarPath);
  final String newHarPath = getHarPath(pluginPath, '$pluginName.har');
  originHarFile.renameSync(newHarPath);
  return newHarPath;
}

String getHarPath(String pluginPath, String fileName) {
  return globals.fs.path.join(
      pluginPath, 'ohos', 'build', 'default', 'outputs', 'default', fileName);
}
