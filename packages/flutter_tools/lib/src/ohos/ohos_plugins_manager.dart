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

/// 检查 ohos plugin 依赖
Future<void> checkOhosPluginsDependencies(FlutterProject flutterProject) async {
  final List<Plugin> plugins = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .toList();
  final File packageFile = flutterProject.ohos.flutterModulePackageFile;
  if (!packageFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($packageFile) exist ?');
  }
  final String packageConfig = packageFile.readAsStringSync();
  final Map<String, dynamic> config = JSON5.parse(packageConfig) as Map<String, dynamic>;
  final Map<String, dynamic> dependencies = config['dependencies'] as Map<String, dynamic>;
  for (final Plugin plugin in plugins) {
    dependencies[plugin.name] = 'file:../har/${plugin.name}.har';
  }
  final String configNew = JSON5.stringify(config, space: 2);
  packageFile.writeAsStringSync(configNew, flush: true);
}

/// 添加到工程级 build-profile.json5 的 modules 中
Future<void> addPluginsModules(FlutterProject flutterProject) async {
  final List<Plugin> plugins = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .toList();
  if (plugins.isEmpty) {
    return;
  }
  final File buildProfileFile = flutterProject.ohos.getBuildProfileFile();
  if (!buildProfileFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($buildProfileFile) exist ?');
  }
  final String packageConfig = buildProfileFile.readAsStringSync();
  final Map<String, dynamic> buildProfile = JSON5.parse(packageConfig) as Map<String, dynamic>;
  final List<Map<dynamic, dynamic>> modules = (buildProfile['modules'] as List<dynamic>).cast();
  final Map<String, dynamic> modulesMap = Map<String, dynamic>.fromEntries(modules.map((e) => MapEntry(e['name'] as String, e)));
  for (final Plugin plugin in plugins) {
    if (modulesMap.containsKey(plugin.name)) {
      continue;
    }
    modules.add(<String, dynamic>{
      'name': plugin.name,
      'srcPath': globals.fs.path.join(plugin.path, OhosPlugin.kConfigKey),
      'targets': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'default',
          'applyToProducts': <dynamic>[
            'default'
          ]
        }
      ],
    });
  }
  final String buildProfileNew = JSON5.stringify(buildProfile, space: 2);
  buildProfileFile.writeAsStringSync(buildProfileNew, flush: true);
}


/// 添加到工程级 build-profile.json5 的 modules 中
Future<void> removePluginsModules(FlutterProject flutterProject) async {
  final List<Plugin> plugins = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .toList();
  if (plugins.isEmpty) {
    return;
  }
  final Map<String, Plugin> pluginsMap = Map<String, Plugin>.fromEntries(
    plugins.map((Plugin e) => MapEntry<String, Plugin>(e.name, e))
  );
  final File buildProfileFile = flutterProject.ohos.getBuildProfileFile();
  if (!buildProfileFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($buildProfileFile) exist ?');
  }
  final String packageConfig = buildProfileFile.readAsStringSync();
  final Map<String, dynamic> buildProfile = JSON5.parse(packageConfig) as Map<String, dynamic>;
  final List<Map<dynamic, dynamic>> modules = (buildProfile['modules'] as List<dynamic>).cast();
  final List<Map<dynamic, dynamic>> newModules = <Map<dynamic, dynamic>>[];

  for (final Map<dynamic, dynamic> module in modules) {
    if (pluginsMap.containsKey(module['name'])) {
      continue;
    } else {
      newModules.add(module);
    }
  }
  buildProfile['modules'] = newModules;
  final String buildProfileNew = JSON5.stringify(buildProfile, space: 2);
  buildProfileFile.writeAsStringSync(buildProfileNew, flush: true);
}

/// 添加到工程级 oh-package.json5 的 overrides 中
Future<void> addPluginsOverrides(FlutterProject flutterProject) async {
  final List<Plugin> plugins = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .toList();
  if (plugins.isEmpty) {
    return;
  }
  final File packageFile = flutterProject.ohos.ohosRoot.childFile('oh-package.json5');
  if (!packageFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($packageFile) exist ?');
  }
  final String packageConfig = packageFile.readAsStringSync();
  final Map<String, dynamic> config = JSON5.parse(packageConfig) as Map<String, dynamic>;
  final Map<String, dynamic> overrides = config['overrides'] as Map<String, dynamic>? ?? <String, dynamic>{};

  for (final Plugin plugin in plugins) {
    overrides[plugin.name] = globals.fs.path.join(plugin.path, OhosPlugin.kConfigKey);
  }
  final String configNew = JSON5.stringify(config, space: 2);
  packageFile.writeAsStringSync(configNew, flush: true);
}

/// 从 工程级 oh-package.json5 的 overrides 中去除
Future<void> removePluginsOverrides(FlutterProject flutterProject) async {
  final List<Plugin> plugins = (await findPlugins(flutterProject))
      .where((Plugin p) => p.platforms.containsKey(OhosPlugin.kConfigKey))
      .toList();
  if (plugins.isEmpty) {
    return;
  }
  final File packageFile = flutterProject.ohos.ohosRoot.childFile('oh-package.json5');;
  if (!packageFile.existsSync()) {
    throwToolExit('check if oh-package.json5 file:($packageFile) exist ?');
  }
  final String packageConfig = packageFile.readAsStringSync();
  final Map<String, dynamic> config = JSON5.parse(packageConfig) as Map<String, dynamic>;
  final Map<String, dynamic> overrides = config['overrides'] as Map<String, dynamic>? ?? <String, dynamic>{};
  if (overrides.isEmpty) {
    return;
  }
  for (final Plugin plugin in plugins) {
    overrides.remove(plugin.name);
  }
  final String configNew = JSON5.stringify(config, space: 2);
  packageFile.writeAsStringSync(configNew, flush: true);
}
