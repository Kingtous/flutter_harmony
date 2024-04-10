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
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/user_messages.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'ohos_sdk.dart';

const String OHOS_ENTRY_DEFAULT = 'entry';
const int OHOS_SDK_INT_DEFAULT = 11;

/// An application package created from an already built Ohos HAP.
class OhosHap extends ApplicationPackage implements PrebuiltApplicationPackage {
  OhosHap({
    required super.id,
    required this.applicationPackage,
    required this.ohosBuildData,
  })  : assert(applicationPackage != null),
        assert(ohosBuildData != null);

  @override
  final FileSystemEntity applicationPackage;

  OhosBuildData ohosBuildData;

  @override
  String? get name => applicationPackage.basename;

  /// Creates a new OhosHap based on the information in the Ohos build-profile.
  static Future<OhosHap?> fromOhosProject(
    OhosProject ohosProject, {
    required HarmonySdk? ohosSdk,
    required ProcessManager processManager,
    required UserMessages userMessages,
    required ProcessUtils processUtils,
    required Logger logger,
    required FileSystem fileSystem,
    BuildInfo? buildInfo,
  }) async {
    /// parse the build data
    final OhosBuildData ohosBuildData =
        OhosBuildData.parseOhosBuildData(ohosProject, logger);
    final String bundleName = ohosBuildData.appInfo!.bundleName;
    return OhosHap(
        id: bundleName,
        applicationPackage: ohosProject.getSignedHapFile(),
        ohosBuildData: ohosBuildData);
  }

  static Future<OhosHap?> fromHap(
    File hap, {
    required HarmonySdk ohosSdk,
    required ProcessManager processManager,
    required UserMessages userMessages,
    required Logger logger,
    required ProcessUtils processUtils,
  }) async {
    // TODO(xc)  parse build data from hap file
    return null;
  }
}

/// OpenHarmony的构建信息
class OhosBuildData {
  OhosBuildData(this.appInfo, this.modeInfo, this.apiVersion);

  late AppInfo? appInfo;
  late ModuleInfo modeInfo;
  late int apiVersion;

  bool get hasEntryModule => false;

  static OhosBuildData parseOhosBuildData(
      OhosProject ohosProject, Logger? logger) {
    late AppInfo appInfo;
    late ModuleInfo moduleInfo;
    late int apiVersion;
    try {
      final File appJson = ohosProject.getAppJsonFile();
      if (appJson.existsSync()) {
        final String json = appJson.readAsStringSync();
        final dynamic obj = JSON5.parse(json);
        appInfo = AppInfo.getAppInfo(obj);
      } else {
        appInfo = AppInfo('', 0, '');
      }
      moduleInfo = ModuleInfo.getModuleInfo(ohosProject.ohosRoot.path);
      apiVersion = getApiVersion(ohosProject.getBuildProfileFile());
    } on Exception catch (err) {
      throwToolExit('parse ohos project build data exception! $err');
    }
    return OhosBuildData(appInfo, moduleInfo, apiVersion);
  }
}

int getApiVersion(File buildProfile) {
  if (!buildProfile.existsSync()) {
    return OHOS_SDK_INT_DEFAULT;
  }
  final String buildProfileConfig = buildProfile.readAsStringSync();
  final dynamic obj = JSON5.parse(buildProfileConfig);
  dynamic sdkObj = obj['app']['compileSdkVersion'];
  sdkObj ??= obj['app']['products'][0]['compileSdkVersion'];
  if (sdkObj is int) {
    return sdkObj;
  } else if (sdkObj is String && sdkObj != null) { // 4.1.0(11)
    String? str = RegExp(r'\(\d+\)').stringMatch(sdkObj);
    if (str != null) {
      str = str.substring(1, str.length - 1);
      return int.parse(str);
    }
  }
  return OHOS_SDK_INT_DEFAULT;
}

List<String> getModuleListName(String ohosProjectPath) {
  final Directory pluginPathDirectory = globals.fs.directory(ohosProjectPath);
  final File buildProfileFile =
      pluginPathDirectory.childFile('build-profile.json5');
  if (!pluginPathDirectory.existsSync() || !buildProfileFile.existsSync()) {
    return List<String>.empty();
  }

  final List<String> moduleNames = List<String>.empty(growable: true);
  try {
    final dynamic moduleConfig =
        JSON5.parse(buildProfileFile.readAsStringSync());
    final List<dynamic> modules = moduleConfig['modules'] as List<dynamic>;
    for (dynamic d in modules) {
      moduleNames.add(d['name'] as String);
    }
  } on Exception catch (e) {
    throwToolExit(
        'parse build-profile.json5 error! path: ${buildProfileFile.path} ,error: ${e.toString()}');
  }
  return moduleNames;
}

class AppInfo {
  AppInfo(this.bundleName, this.versionCode, this.versionName);

  late String bundleName;
  late int versionCode;
  late String versionName;

  static AppInfo getAppInfo(dynamic app) {
    final String bundleName = app['app']['bundleName'] as String;
    final int versionCode = app['app']['versionCode'] as int;
    final String versionName = app['app']['versionName'] as String;
    return AppInfo(bundleName, versionCode, versionName);
  }
}

class ModuleInfo {
  ModuleInfo(this.moduleList);

  List<OhosModule> moduleList;

  bool get hasEntryModule =>
      moduleList.any((OhosModule element) => element.isEntry);

  OhosModule? get entryModule => hasEntryModule
      ? moduleList.firstWhere((OhosModule element) => element.isEntry)
      : null;

  String? get mainElement => entryModule?.mainElement;

  /// 获取主要的module名，如果存在entry，返回entry类型的module，否则返回第一个module
  String get mainModuleName =>
      entryModule?.moduleName ??
      (moduleList.isNotEmpty ? moduleList.first.moduleName : OHOS_ENTRY_DEFAULT);

  static ModuleInfo getModuleInfo(String ohosProjectPath) {
    final List<OhosModule> moduleList =
        OhosModule.fromOhosPath(ohosProjectPath);
    return ModuleInfo(moduleList);
  }
}

enum OhosModuleType {
  entry,
  har,
  shared,
  unknown;

  static OhosModuleType fromName(String name) {
    return OhosModuleType.values.firstWhere(
        (OhosModuleType element) => element.name == name,
        orElse: () => OhosModuleType.unknown);
  }
}

class OhosModule {
  OhosModule(this.moduleName, this.isEntry, this.mainElement, this.type);

  String moduleName;
  bool isEntry;
  String? mainElement;
  OhosModuleType type;

  static List<OhosModule> fromOhosPath(String ohosProjectPath) {
    final List<String> moduleNames = getModuleListName(ohosProjectPath);
    final List<OhosModule> list = List<OhosModule>.empty(growable: true);
    for (final String moduleName in moduleNames) {
      final OhosModule ohosModule =
          _fromModulePath(ohosProjectPath, moduleName);
      list.add(ohosModule);
    }
    return list;
  }

  static OhosModule _fromModulePath(String ohosProjectPath, String moduleName) {
    final String moduleJsonPath = globals.fs.path
        .join(ohosProjectPath, moduleName, 'src', 'main', 'module.json5');
    final File moduleJsonFile = globals.fs.file(moduleJsonPath);
    if (!moduleJsonFile.existsSync()) {
      throwToolExit('can not found module.json5 at $moduleJsonPath .');
    }
    try {
      final dynamic moduleJson = JSON5.parse(moduleJsonFile.readAsStringSync());
      final dynamic module = moduleJson['module'];
      final String type = module['type'] as String;
      final bool isEntry = type == OhosModuleType.entry.name;

      return OhosModule(
          moduleName,
          isEntry,
          isEntry ? module['mainElement'] as String : null,
          OhosModuleType.fromName(type));
    } on Exception catch (e) {
      throwToolExit('parse module.json5 error , $moduleJsonPath . error: $e');
    }
  }
}
