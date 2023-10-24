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
import '../project.dart';
import 'ohos_sdk.dart';

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
    required OhosSdk? ohosSdk,
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
    final String bundleName = ohosBuildData.appInfo.bundleName;
    return OhosHap(
        id: bundleName,
        applicationPackage: ohosProject.getSignedHapFile(),
        ohosBuildData: ohosBuildData);
  }

  static Future<OhosHap?> fromHap(
    File hap, {
    required OhosSdk ohosSdk,
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

  late AppInfo appInfo;
  late ModuleInfo modeInfo;
  late int apiVersion;

  static OhosBuildData parseOhosBuildData(
      OhosProject ohosProject, Logger? logger) {
    late AppInfo appInfo;
    late ModuleInfo moduleInfo;
    late int apiVersion;
    try {
      final File appJson = ohosProject.getAppJsonFile();
      final String json = appJson.readAsStringSync();
      final dynamic obj = JSON5.parse(json);
      appInfo = AppInfo.getAppInfo(obj);
      final File moduleJson = ohosProject.getModuleJsonFile();
      final String moduleStr = moduleJson.readAsStringSync();
      final dynamic module = JSON5.parse(moduleStr);
      moduleInfo = ModuleInfo.getModuleInfo(module);
      apiVersion = getApiVersion(ohosProject.getBuildProfileFile());
    } on Exception catch (err) {
      throwToolExit('parse ohos project build data exception! $err');
    }
    return OhosBuildData(appInfo, moduleInfo, apiVersion);
  }
}

int getApiVersion(File buildProfile) {
  final String buildProfileConfig = buildProfile.readAsStringSync();
  final dynamic obj = JSON5.parse(buildProfileConfig);
  String verStr = obj['app']['products'][0]['compatibleSdkVersion'] as String;
  RegExp exp = new RegExp(r'\d{2}');
  return int.parse(exp.stringMatch(verStr) as String);
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
  ModuleInfo(this.mainElement);

  late String mainElement;

  static ModuleInfo getModuleInfo(dynamic module) {
    final String mainElement = module['module']['mainElement'] as String;
    return ModuleInfo(mainElement);
  }
}
