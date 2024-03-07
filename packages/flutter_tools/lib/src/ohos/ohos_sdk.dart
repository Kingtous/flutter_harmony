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
import '../globals.dart' as globals;

// OpenHarmony SDK
const String kOhosHome = 'OHOS_HOME';
const String kOhosSdkRoot = 'OHOS_SDK_HOME';
// HarmonyOS SDK
const String kHmosHome = 'HOS_SDK_HOME';

// for api11 developer preview
Map<int, String> sdkVersionMap = <int, String>{};

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
        initSdkVersionMap(ohosHomeDir);

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

  // int sdkVersionMap
  static void initSdkVersionMap(String sdkPath) {
    final Directory directory = globals.fs.directory(sdkPath);
    if (!directory.existsSync()) {
      throwToolExit('Unable to locate an Harmony SDK.');
    }
    for (FileSystemEntity element in directory.listSync()) {
      if (element is Directory) {
        Directory dir = globals.fs.directory(element).childDirectory('toolchains');
        if (dir.existsSync()) {
          sdkVersionMap.addAll({int.parse(element.basename): element.basename});
        }
      }
    }
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
          .join(sdkPath, sdkVersionMap[api]!, 'base', 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    // if hdc not found, find it in previous version
    for (final int folder in sdkVersionMap.keys) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, folder.toString(), 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
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
      for (final int folder in sdkVersionMap.keys) {
        final Directory directory =
            globals.fs.directory(globals.fs.path.join(sdkPath, folder.toString()));
        if (directory.existsSync()) {
          list.add(folder.toString());
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
       for (final int folder in sdkVersionMap.keys) {
         final Directory directory =
         globals.fs.directory(globals.fs.path.join(sdkPath, folder.toString()));
         if (directory.existsSync()) {
           list.add(folder.toString());
         }
       }
     }
     return list;
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
        initSdkVersionMap(hmosHomeDir);

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

  // int sdkVersionMap
  static void initSdkVersionMap(String sdkPath) {
    final Directory directory = globals.fs.directory(sdkPath);
    if (!directory.existsSync()) {
      throwToolExit('Unable to locate an Harmony SDK.');
    }
    for (FileSystemEntity element in directory.listSync()) {
      if (element is Directory) {
        // read apiVersion from sdk-pkg.json
        File sdkPkgJson = globals.fs.directory(element).childFile('sdk-pkg.json');
        if (sdkPkgJson.existsSync()) {
          dynamic sdk_pkg = JSON5.parse(sdkPkgJson.readAsStringSync());
          sdkVersionMap.addAll({int.parse(sdk_pkg['data']['apiVersion'] as String): element.basename});
        }
      }
    }
  }

  static String? getHdcPath(String sdkPath) {
    final bool isWindows = globals.platform.isWindows;
    // find it in api11 developer preview folder
    for (final int api in sdkVersionMap.keys) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, sdkVersionMap[api]!, 'base', 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    // if hdc not found, find it in previous version
    for (final int folder in sdkVersionMap.keys) {
      final File file = globals.fs.file(globals.fs.path
          .join(sdkPath, folder.toString(), 'toolchains', isWindows ? 'hdc.exe' : 'hdc'));
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }


  //harmonyOsSdk，包含目录hmscore和openharmony
  static bool validSdkDirectory(String hmosHomeDir) {
    return validApi10SdkDirectory(hmosHomeDir) ||
        validApi11SdkDirectory(hmosHomeDir);
  }

  static bool validApi10SdkDirectory(String hmosHomeDir) {
    final Directory directory = globals.fs.directory(hmosHomeDir);
    return directory.childDirectory('hmscore').existsSync() &&
        directory.childDirectory('openharmony').existsSync();
  }

  static bool validApi11SdkDirectory(String hmosHomeDir) {
    final Directory directory = globals.fs.directory(hmosHomeDir);
    if (!directory.childDirectory('licenses').existsSync()) {
      return false;
    }
    for (String sdkName in sdkVersionMap.values) {
      Directory sdkDir = globals.fs.directory(
          globals.fs.path.join(hmosHomeDir, sdkName));
      if (!sdkDir.existsSync()) {
        return false;
      }
    }
    return true;
  }
}