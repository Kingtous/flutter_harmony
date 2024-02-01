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

import '../base/file_system.dart';
import '../globals.dart' as globals;

// OpenHarmony SDK
const String kOhosHome = 'OHOS_HOME';
const String kOhosSdkRoot = 'OHOS_SDK_HOME';
// HarmonyOS SDK
const String kHmosHome = 'HOS_SDK_HOME';

const List<String> supportSdkVersion = <String>['10', '11', '9'];
// for api11 developer preview
const Map<int, String> sdkVersionMap = {11: 'HarmonyOS-NEXT-DP1', 10: 'HarmonyOS-NEXT-DP0'};

abstract class HarmonySdk {
  // name
  String get name;
  // sdk path
  String get sdkPath;
  // hdc path
  String? get hdcPath;
  // available api list
  List<String> get apiAvailable;
  // is valid sdk
  bool get isValidDirectory;

  static HarmonySdk? locateHarmonySdk() {
    final OhosSdk? ohosSdk = OhosSdk.localOhosSdk();
    final HmosSdk? hmosSdk = HmosSdk.localHmosSdk();
    if (ohosSdk != null) {
      return ohosSdk;
    } else if (hmosSdk != null) {
      return hmosSdk;
    } else {
      return null;
    }
  }
}

class OhosSdk implements HarmonySdk {
  OhosSdk(this._sdkDir);

  final Directory _sdkDir;

  @override
  String get name => 'OpenHarmonySDK';

  @override
  String get sdkPath => _sdkDir.path;

  @override
  String? get hdcPath => getHdcPath(_sdkDir.path);

  @override
  List<String> get apiAvailable => getAvailableApi();

  @override
  bool get isValidDirectory => validSdkDirectory(_sdkDir.path);

  static OhosSdk? localOhosSdk() {
    String? findOhosHomeDir() {
      String? ohosHomeDir;
      if (globals.config.containsKey('ohos-sdk')) {
        ohosHomeDir = globals.config.getValue('ohos-sdk') as String?;
      } else if (globals.platform.environment.containsKey(kOhosHome)) {
        ohosHomeDir = globals.platform.environment[kOhosHome];
      } else if (globals.platform.environment.containsKey(kOhosSdkRoot)) {
        ohosHomeDir = globals.platform.environment[kOhosSdkRoot];
      }

      if (ohosHomeDir != null) {
        if (validSdkDirectory(ohosHomeDir)) {
          return ohosHomeDir;
        }
        if (validSdkDirectory(globals.fs.path.join(ohosHomeDir, 'sdk'))) {
          return globals.fs.path.join(ohosHomeDir, 'sdk');
        }
      }
      return null;
    }

    final String? ohosHomeDir = findOhosHomeDir();
    if (ohosHomeDir == null) {
      // No dice.
      globals.printTrace('Unable to locate an Ohos SDK.');
      return null;
    }

    return OhosSdk(globals.fs.directory(ohosHomeDir));
  }

  static bool validSdkDirectory(String dir) {
    return hdcExists(dir);
  }

  static bool hdcExists(String dir) {
    return getHdcPath(dir) != null;
  }

  static String? getHdcPath(String sdkPath) {
    final bool isWindows = globals.platform.isWindows;
    // find it in api11 developer preview folder
    for (final int api in sdkVersionMap.keys) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, sdkVersionMap[api], 'base', 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    // if hdc not found, find it in previous version
    for (final String folder in supportSdkVersion) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, folder, 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }

  List<String> getAvailableApi() {
    final List<String> list = <String>[];
     // for api11 developer preview
    for (final int api in sdkVersionMap.keys) {
      final Directory directory =
          globals.fs.directory(globals.fs.path.join(sdkPath, sdkVersionMap[api]));
      if (directory.existsSync()) {
        list.add(sdkVersionMap[api]!);
      }
    }
    // if not found, find it in previous version
    if (list.isEmpty) {
      for (final String folder in supportSdkVersion) {
        final Directory directory =
            globals.fs.directory(globals.fs.path.join(sdkPath, folder));
        if (directory.existsSync()) {
          list.add(folder);
        }
      }
    }
    return list;
  }

}

class HmosSdk implements HarmonySdk {
  HmosSdk(this._sdkDir);

  final Directory _sdkDir;

  @override
  String get name => 'HarmonyOSSDK';

  @override
  String? get hdcPath => getHdcPath(_sdkDir.path);

  @override
  String get sdkPath => _sdkDir.path;

  @override
  List<String> get apiAvailable => getAvailableApi();

  @override
  bool get isValidDirectory => validSdkDirectory(sdkPath);

   List<String> getAvailableApi() {
    File file = globals.fs.file(globals.fs.path.join(sdkPath, 'base'));
    return <String>[
      file.path,
    ];
  }

  static HmosSdk? localHmosSdk() {
    String? findHmosHomeDir() {
      String? hmosHomeDir;
      if (globals.config.containsKey('hmos-sdk')) {
        hmosHomeDir = globals.config.getValue('hmos-sdk') as String?;
      } else if (globals.platform.environment.containsKey(kHmosHome)) {
        hmosHomeDir = globals.platform.environment[kHmosHome];
      }

      if (hmosHomeDir != null) {
        if (validSdkDirectory(hmosHomeDir)) {
          return hmosHomeDir;
        }
      }
      return null;
    }

    final String? hmosHomeDir = findHmosHomeDir();
    if (hmosHomeDir == null) {
      // No dice.
      globals.printTrace('Unable to locate an Hmos SDK.');
      return null;
    }

    return HmosSdk(globals.fs.directory(hmosHomeDir));
  }

  static String? getHdcPath(String sdkPath) {
    final bool isWindows = globals.platform.isWindows;
    // find it in api11 developer preview folder
    for (final int api in sdkVersionMap.keys) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, sdkVersionMap[api], 'base', 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    // if hdc not found, find it in previous version
    for (final String folder in supportSdkVersion) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, folder, 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }


  //harmonyOsSdk，包含目录hmscore和openharmony
  static bool validSdkDirectory(String hmosHomeDir) {
    final Directory directory = globals.fs.directory(hmosHomeDir);
    return (directory.childDirectory('hmscore').existsSync() &&
        directory.childDirectory('openharmony').existsSync()) ||
        // for api11 developer preview
        (directory.childDirectory('HarmonyOS-NEXT-DP1').existsSync() && 
        directory.childDirectory('licenses').existsSync());
  }
}

/// help user to sign hap file
class SignTool {
  SignTool(this.signToolHome);

  static const String SIGN_TOOL_HOME_KEY = 'SIGN_TOOL_HOME';

  static const String SIGN_TOOL_CONFIG_KEY = 'signTool-home';

  static SignTool? local() {
    String? signToolHome;
    if (globals.config.containsKey(SIGN_TOOL_CONFIG_KEY)) {
      signToolHome = globals.config.getValue(SIGN_TOOL_CONFIG_KEY) as String?;
    } else if (globals.platform.environment.containsKey(SIGN_TOOL_HOME_KEY)) {
      signToolHome = globals.platform.environment[SIGN_TOOL_HOME_KEY];
    }
    if (signToolHome != null) {
      return SignTool(signToolHome);
    } else {
      return null;
    }
  }

  final String signToolHome;

  bool validJar() {
    // _signToolHome: ~/sdk/developtools_hapsigner/autosign
    // ~/sdk/developtools_hapsigner/hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar
    final File hapSignToolJar = globals.fs
        .directory(signToolHome)
        .parent
        .childDirectory('hapsigntool')
        .childDirectory('hap_sign_tool')
        .childDirectory('build')
        .childDirectory('libs')
        .childFile('hap-sign-tool.jar');
    return hapSignToolJar.existsSync();
  }
}

/// OpenHarmony package manager tool
class Ohpm {
  Ohpm(this._ohpmHome);

  static const String OHPM_HOME = 'OHPM_HOME';

  static const String OHPM_CONFIG_KEY = 'ohpm-home';

  static Ohpm? local() {
    String? ohpmHome;
    if (globals.config.containsKey(OHPM_CONFIG_KEY)) {
      ohpmHome = globals.config.getValue(OHPM_CONFIG_KEY) as String?;
    } else if (globals.platform.environment.containsKey(OHPM_HOME)) {
      ohpmHome = globals.platform.environment[OHPM_HOME];
    }
    if (ohpmHome != null) {
      return Ohpm(ohpmHome);
    } else {
      return null;
    }
  }

  final String _ohpmHome;

  String? getOhpmBinPath() {
    final bool isWindows = globals.platform.isWindows;
    final File ohpm = globals.fs
        .directory(_ohpmHome)
        .childDirectory('bin')
        .childFile(isWindows ? 'ohpm.bat' : 'ohpm');
    return ohpm.existsSync() ? ohpm.path : null;
  }
}
