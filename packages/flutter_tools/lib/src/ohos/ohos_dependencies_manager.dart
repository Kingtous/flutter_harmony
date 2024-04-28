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

import 'package:json5/json5.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';

enum DependenceType {
  normal,
  dev; //deprecated

  static String getConfigKey(DependenceType dependenceType) {
    return dependenceType == DependenceType.normal
        ? 'dependencies'
        : 'devDependencies';
  }
}

class OhosDependence {
  ///"@ohos/flutter_ohos": "file:../har/flutter.har"
  OhosDependence(this.moduleName, this.modulePath, this.dependenceType);

  ///@ohos/flutter_ohos
  String moduleName;

  ///file:../har/flutter.har
  String modulePath;

  DependenceType dependenceType;
}

/// 检查ohos plugin依赖，如果不在oh-package.json5 dependencies中，添加进去
Future<void> checkOhosPluginsDependencies(FlutterProject flutterProject) async {
  final List<OhosPlugin> pluginList = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .map((Plugin p) => p.platforms[OhosPlugin.kConfigKey]! as OhosPlugin)
      .toList();

  if (pluginList.isEmpty) {
    globals.printStatus(
        'OhosDependenciesManager: it no need to add plugins dependencies.');
    return;
  }

  /// 查询所有的normal依赖
  final List<OhosDependence> list = getOhosDependenciesListFromPackageFile(
      flutterProject.ohos.flutterModulePackageFile,
      dependenceType: DependenceType.normal);
  final List<String> hasInstallPlugin =
      list.map((OhosDependence e) => e.moduleName).toList();
  final List<OhosDependence> uninstallPlugins = pluginList
      .where((OhosPlugin element) => !hasInstallPlugin.contains(element.name))
      .map((OhosPlugin element) => transform(element, DependenceType.normal))
      .toList();
  final List<String> deprecatedDependencies = pluginList
      .where((OhosPlugin e) => hasInstallPlugin.contains('@ohos/${e.name}'))
      .map((OhosPlugin e) => '@ohos/${e.name}')
      .toList();
  if (deprecatedDependencies.isNotEmpty) {
    globals.printStatus(
        'OhosDependenciesManager: ${deprecatedDependencies.length} deprecated plugin dependencies has removed.');
    await removeDependencies(flutterProject, deprecatedDependencies);
  }
  if (uninstallPlugins.isEmpty) {
    globals.printStatus(
        'OhosDependenciesManager: all plugins dependencies has installed.');
    return;
  }
  await addDependencies(flutterProject, uninstallPlugins);
  globals.printStatus(
      'OhosDependenciesManager: ${uninstallPlugins.length} new plugins has installed.');
}

OhosDependence transform(OhosPlugin ohosPlugin, DependenceType dependenceType) {
  return OhosDependence(ohosPlugin.name, './har/${ohosPlugin.name}.har', dependenceType);
}

/// 解析dependence列表，dependenceType为空时，返回normal和dev的合集。
List<OhosDependence> getOhosDependenciesListFromPackageFile(File ohPackageFile,
    {DependenceType? dependenceType}) {
  final dynamic config = parsePakcageConfig(ohPackageFile);
  final List<OhosDependence> list = List<OhosDependence>.empty(growable: true);
  if (dependenceType == DependenceType.normal || dependenceType == null) {
    list.addAll(parseDependenciesFromType(config, DependenceType.normal));
  }
  return list;
}

List<OhosDependence> parseDependenciesFromType(
    dynamic config, DependenceType dependenceType) {
  final String configKey = DependenceType.getConfigKey(dependenceType);
  final List<OhosDependence> list = List<OhosDependence>.empty(growable: true);
  if (config[configKey] == null) {
    return list;
  }
  final Map<String, dynamic> dependencies =
      config[configKey] as Map<String, dynamic>;
  for (final String symbol in dependencies.keys) {
    final String moduleName = symbol;
    final String modulePath = dependencies[symbol] as String;
    list.add(OhosDependence(moduleName, modulePath, dependenceType));
  }
  return list;
}

/// 新增依赖到oh-package.json5文件中
Future<void> addDependencies(
    FlutterProject flutterProject, List<OhosDependence> list) async {
  final dynamic config =
      parsePakcageConfig(flutterProject.ohos.flutterModulePackageFile);
  final Map<String, dynamic> dependencies =
      config['dependencies'] as Map<String, dynamic>;

  for (final OhosDependence dependence in list) {
    dependencies[dependence.moduleName] =
        'file:./har/${dependence.moduleName}.har';
  }
  final String configNew = JSON5.stringify(config, space: 2);
  flutterProject.ohos.flutterModulePackageFile
      .writeAsStringSync(configNew, flush: true);
}

/// 从 oh-package.json5文件中移除依赖
Future<void> removeDependencies(
    FlutterProject flutterProject, List<String> list) async {
  final dynamic config =
      parsePakcageConfig(flutterProject.ohos.flutterModulePackageFile);
  final Map<String, dynamic> dependencies =
      config['dependencies'] as Map<String, dynamic>;

  // ignore: prefer_foreach
  for (final String name in list) {
    dependencies.remove(name);
  }
  final String configNew = JSON5.stringify(config, space: 2);
  flutterProject.ohos.flutterModulePackageFile
      .writeAsStringSync(configNew, flush: true);
}

dynamic parsePakcageConfig(File ohPackageFile) {
  if (!ohPackageFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($ohPackageFile) exist ?');
  }
  final String packageConfig = ohPackageFile.readAsStringSync();
  return JSON5.parse(packageConfig);
}
