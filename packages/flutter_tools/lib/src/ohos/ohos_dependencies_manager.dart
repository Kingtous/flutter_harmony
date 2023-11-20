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

class OhosDependence {
  ///"@ohos/flutter_ohos": "file:../har/flutter_embedding.har"
  OhosDependence(this.moduleName, this.baseModuleName, this.modulePath);

  ///@ohos/flutter_ohos
  String moduleName;

  ///file:../har/flutter_embedding.har
  String modulePath;

  ///flutter_ohos
  String baseModuleName;
}

/// 检查ohosPlugins的依赖
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

  final List<OhosDependence> list =
      await getOhosDependenciesList(flutterProject);
  final List<String> hasInstallPlugin =
      list.map((OhosDependence e) => e.baseModuleName).toList();
  final List<OhosDependence> uninstallPlugins = pluginList
      .where((OhosPlugin element) => !hasInstallPlugin.contains(element.name))
      .map((OhosPlugin element) => transform(element))
      .toList();
  if (uninstallPlugins.isEmpty) {
    globals.printStatus(
        'OhosDependenciesManager: all plugins dependencies has installed.');
    return;
  }
  await addDependencies(flutterProject, uninstallPlugins);
  globals.printStatus(
      'OhosDependenciesManager: ${uninstallPlugins.length} new plugins has installed.');
}

OhosDependence transform(OhosPlugin ohosPlugin) {
  return OhosDependence('@ohos/${ohosPlugin.name}', ohosPlugin.name,
      '../har/${ohosPlugin.name}.har');
}

/// 从entry/oh-package.json5解析出所有依赖
Future<List<OhosDependence>> getOhosDependenciesList(
    FlutterProject flutterProject) async {
  final dynamic obj = parsePakcageConfig(flutterProject);
  final Map<String, dynamic> dependencies =
      obj['dependencies'] as Map<String, dynamic>;

  final List<OhosDependence> list = List<OhosDependence>.empty(growable: true);
  for (final String symbol in dependencies.keys) {
    final String moduleName = symbol;
    final String modulePath = dependencies[symbol] as String;
    final String baseModuleName = moduleName.split('/')[1];
    list.add(OhosDependence(moduleName, baseModuleName, modulePath));
  }
  return list;
}

/// 新增依赖到oh-package.json5文件中
Future<void> addDependencies(
    FlutterProject flutterProject, List<OhosDependence> list) async {
  final dynamic obj = parsePakcageConfig(flutterProject);

  final Map<String, dynamic> dependencies =
      obj['dependencies'] as Map<String, dynamic>;

  for (final OhosDependence dependence in list) {
    dependencies[dependence.moduleName] =
        'file:../har/${dependence.baseModuleName}.har';
  }
  final String configNew = JSON5.stringify(obj, space: 2);
  flutterProject.ohos.mainModulePackageFile
      .writeAsStringSync(configNew, flush: true);
}

dynamic parsePakcageConfig(FlutterProject flutterProject) {
  final File packageFile = flutterProject.ohos.mainModulePackageFile;
  final String packageConfig = packageFile.readAsStringSync();
  return JSON5.parse(packageConfig);
}
