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

import 'dart:io' as io;

import 'package:json5/json5.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import 'application_package.dart';
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

  if (!flutterProject.directory.childFile('.flutter-plugins').existsSync()) {
    throwToolExit('please run "flutter pub get" in project first.');
  }

  ///检查当前工程下har文件夹下已生成的har文件
  final List<String> harFiles = getProjectHarList(flutterProject);

  final List<OhosPlugin> toBeGenerateHarList = list
      .where((OhosPlugin plugin) =>
          !hasContainsStr(harFiles, '${plugin.name}.har'))
      .toList();
  if (toBeGenerateHarList.isEmpty) {
    globals.printStatus(
        'ohosPluginsManager: no need to update ohos plugins har file');
    return;
  }

  /// 每一个待生成的har工程，执行assembleHar
  final List<String> harPaths =
      await Future.wait(toBeGenerateHarList.map((OhosPlugin element) async {
    final String pluginOhosPath = getOhosProjectPath(element.pluginPath);
    final ModuleInfo moduleInfo = ModuleInfo.getModuleInfo(pluginOhosPath);
    final String path = await pluginsHarGenerate(
        pluginOhosPath, element.name, moduleInfo.mainModuleName);
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
  globals.printStatus(
      'ohosPluginsManager: ohos plugins har files update success!');
}

bool hasContainsStr(List<String> list, String name) {
  for (final String element in list) {
    if (element.contains(name)) {
      return true;
    }
  }
  return false;
}

List<String> getProjectHarList(FlutterProject flutterProject) {
  final Directory directory =
      flutterProject.ohos.ohosRoot.childDirectory('har');
  if (directory.existsSync()) {
    return directory
        .listSync()
        .where((FileSystemEntity element) =>
            io.FileSystemEntity.isFileSync(element.path))
        .map((FileSystemEntity file) => file.path)
        .toList();
  } else {
    directory.createSync();
    return List<String>.empty();
  }
}

Future<String> pluginsHarGenerate(
    String ohosPath, String pluginName, String moduleName) async {
  final String modulePath = globals.fs.path.join(ohosPath, moduleName);
  await ohpmInstall(
      processManager: globals.processManager,
      entryPath: modulePath,
      logger: globals.logger);
  final String hvigorwPath = getHvigorwPath(ohosPath, checkMod: true);
  final int errorCode0 = await assembleHar(
      processManager: globals.processManager,
      workPath: ohosPath,
      moduleName: moduleName,
      hvigorwPath: hvigorwPath,
      logger: globals.logger);
  if (errorCode0 != 0) {
    throwToolExit(
        'ohosPluginsManager: ohosProjectPath:$ohosPath, assembleHar error! please check log.');
  }
  return getHarPath(ohosPath, pluginName, moduleName);
}

/// 插件中ohos目录
String getOhosProjectPath(String pluginPath) {
  final Directory pluginPathDirectory = globals.fs.directory(pluginPath);
  final Directory ohosProject = pluginPathDirectory.childDirectory('ohos');
  if (!ohosProject.existsSync() ||
      !ohosProject.childFile('oh-package.json5').existsSync()) {
    throwToolExit('can not found ohos project on pluginPath: $pluginPath');
  }
  return ohosProject.path;
}

String getHarPath(String pluginPath, String pluginName, String moduleName) {
  final String harPath = globals.fs.path.join(pluginPath, moduleName, 'build',
      'default', 'outputs', 'default', '$moduleName.har');
  final File harFile = globals.fs.file(harPath);
  if (!harFile.existsSync()) {
    throwToolExit('har file has not found. harPath: $harPath');
  }
  if (pluginName == moduleName) {
    return harPath;
  } else {
    /// 如果module名和插件名不一致，需要更新har为插件名har
    final String renamePath = globals.fs.path.join(pluginPath, moduleName,
        'build', 'default', 'outputs', 'default', '$pluginName.har');
    harFile.renameSync(renamePath);
    return renamePath;
  }
}
