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

import 'dart:io';

import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/ohos.dart';
import '../cache.dart';
import '../compile.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'build_env.dart';
import '../convert.dart';

/// if this constant set true , must config platform environment PUB_HOSTED_URL and FLUTTER_STORAGE_BASE_URL
const bool NEED_PUB_CN = true;

const String OHOS_DTA_FILE_NAME = 'icudtl.dat';

const String FLUTTER_ASSETS_PATH = 'flutter_assets';

const String FLUTTER_ENGINE_SO = 'libflutter.so';

const String APP_SO_ORIGIN = 'app.so';

const String APP_SO = 'libapp.so';

const String HAR_FILE_NAME = 'flutter_embedding.har';

const String HVIGORW_FILE = 'hvigorw';

void checkPlatformEnvironment(String environment, Logger? logger) {
  final String? environmentConfig = Platform.environment[environment];
  if (environmentConfig == null) {
    throwToolExit(
        'error:current platform environment $environment have not set');
  } else {
    logger?.printStatus(
        'current platform environment $environment = $environmentConfig');
  }
}

void copyFlutterAssets(String orgPath, String desPath, Logger? logger) {
  logger?.printStatus('copy directory from $orgPath to $desPath');
  final LocalFileSystem localFileSystem = globals.localFileSystem;
  copyDirectory(
      localFileSystem.directory(orgPath), localFileSystem.directory(desPath));
}

/// eg:entry/src/main/resources/rawfile
String getProjectAssetsPath(String ohosRootPath) {
  return globals.fs.path.join(
      ohosRootPath, 'entry/src/main/resources/rawfile', FLUTTER_ASSETS_PATH);
}

/// eg:entry/src/main/resources/rawfile/flutter_assets/
String getDatPath(String ohosRootPath) {
  return globals.fs.path
      .join(getProjectAssetsPath(ohosRootPath), OHOS_DTA_FILE_NAME);
}

/// eg:entry/libs/arm64-v8a/libflutter.so
String getEngineSoPath(String ohosRootPath, TargetPlatform targetPlatform) {
  return globals.fs.path.join(
      getProjectArchPath(ohosRootPath, targetPlatform), FLUTTER_ENGINE_SO);
}

/// eg:entry/libs/arm64-v8a/libapp.so
String getAppSoPath(String ohosRootPath, TargetPlatform targetPlatform) {
  return globals.fs.path
      .join(getProjectArchPath(ohosRootPath, targetPlatform), APP_SO);
}

String getProjectArchPath(String ohosRootPath, TargetPlatform targetPlatform) {
  final String archPath = getArchPath(targetPlatform);
  return globals.fs.path.join(ohosRootPath, 'entry/libs', archPath);
}

String getArchPath(TargetPlatform targetPlatform) {
  final String targetPlatformName = getNameForTargetPlatform(targetPlatform);
  final OhosArch ohosArch = getOhosArchForName(targetPlatformName);
  return getNameForOhosArch(ohosArch);
}

/// /hvigorw  todo change the file to be hvigorw.bat on windows host
String getHvigorwPath(String ohosRootPath) {
  return globals.fs.path.join(ohosRootPath, HVIGORW_FILE);
}

String getEntryPath(String ohosRootPath) {
  return globals.fs.path.join(ohosRootPath, 'entry');
}

/// Builds the ohos project through the hvigorw.
Future<void> buildHap(FlutterProject flutterProject, BuildInfo buildInfo,
    {required String target,
    SizeAnalyzer? sizeAnalyzer,
    bool needCrossBuild = false,
    required TargetPlatform targetPlatform,
    String targetSysroot = '/',
    Logger? logger}) async {
  logger?.printStatus('start hap build...');
  /**
   * import the har in local path
   *
   * 1. excute flutter assemble
   * 2. copy flutter asset to ohos project
   * 3. excute hvigorw script (remember chmod xxx)
   * 4. finish
   */
  logger?.printStatus('check platform environment');
  if (NEED_PUB_CN) {
    checkPlatformEnvironment('PUB_HOSTED_URL', logger);
    checkPlatformEnvironment('FLUTTER_STORAGE_BASE_URL', logger);
  }
  checkPlatformEnvironment('OHPM_HOME', logger);
  // checkPlatformEnvironment('LOCAL_FLUTTER_ENGINE', logger);

  // BuildEnv buildEnv = BuildEnv(Platform.environment['OHPM_HOME']!,
  //     Platform.environment['LOCAL_FLUTTER_ENGINE']!);

  ///
  /// 1. OhosDebugApplicationTarget or OhosAotBundle
  /// 2. copyAssetsToProject
  /// 3. ./hvigorw clean assembleHap
  ///
  ///
  ///
  /// generate target name.
  late String targetName;
  if (buildInfo.isDebug) {
    targetName = 'debug_ohos_application';
  } else {
    // eg:ohos_aot_bundle_release_ohos-arm64
    targetName =
        'ohos_aot_bundle_release_${getNameForTargetPlatform(targetPlatform)}';
  }
  final List<Target> selectTarget =
      ohosTargets.where((Target e) => targetName == e.name).toList();
  if (selectTarget.isEmpty) {
    throwToolExit('do not found compare target.');
  } else if (selectTarget.length > 1) {
    throwToolExit('more than one target match.');
  }
  final Target target = selectTarget[0];

  final Status status =
      globals.logger.startProgress('Compiling $targetName for the Ohos...');
  String output = globals.fs.directory(getOhosBuildDirectory()).path;
  // If path is relative, make it absolute from flutter project.
  output = getAbsolutePath(flutterProject, output);
  try {
    final BuildResult result = await globals.buildSystem.build(
        target,
        Environment(
          projectDir: globals.fs.currentDirectory,
          outputDir: globals.fs.directory(output),
          buildDir: flutterProject.directory
              .childDirectory('.dart_tool')
              .childDirectory('flutter_build'),
          defines: <String, String>{
            kTargetPlatform: 'ohos',
            ...buildInfo.toBuildSystemEnvironment(),
          },
          artifacts: globals.artifacts!,
          fileSystem: globals.fs,
          logger: globals.logger,
          processManager: globals.processManager,
          platform: globals.platform,
          usage: globals.flutterUsage,
          cacheDir: globals.cache.getRoot(),
          engineVersion: globals.artifacts!.isLocalEngine
              ? null
              : globals.flutterVersion.engineRevision,
          flutterRootDir: globals.fs.directory(Cache.flutterRoot),
          generateDartPluginRegistry: true,
        ));
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError(
          'Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: measurement.fatal ? measurement.stackTrace : null,
        );
      }
      throwToolExit('Failed to compile application for the Ohos.');
    }
  } on Exception catch (err) {
    throwToolExit(err.toString());
  } finally {
    status.stop();
  }

  final String ohosRootPath =
      globals.fs.path.join(flutterProject.directory.path, 'ohos');

  // clean flutter assets
  final String desFlutterAssetsPath = getProjectAssetsPath(ohosRootPath);
  final Directory desAssets = globals.fs.directory(desFlutterAssetsPath);
  if (desAssets.existsSync()) {
    desAssets.deleteSync(recursive: true);
  }

  /// copy flutter assets
  logger?.printStatus('start copy flutter assets to project');
  copyFlutterAssets(globals.fs.path.join(output, FLUTTER_ASSETS_PATH),
      desFlutterAssetsPath, logger);

  // copy ohos font-family support
  final LocalFileSystem localFileSystem = globals.localFileSystem;
  final File ohosDta = localFileSystem
      .file(globals.fs.path.join(ohosRootPath, 'dta', OHOS_DTA_FILE_NAME));
  final String copyDes = getDatPath(ohosRootPath);
  ohosDta.copySync(copyDes);

  //copy ohos engine so
  final String? flutterEngineSoPath =
      globals.artifacts?.getArtifactPath(Artifact.flutterEngineSo);
  if (flutterEngineSoPath == null) {
    throwToolExit("flutter engine runtime  file 'libflutter.so' no found");
  }
  final File flutterEngineSoFile = localFileSystem.file(flutterEngineSoPath);
  final String enginCopyDes = getEngineSoPath(ohosRootPath, targetPlatform);
  final Directory directory = localFileSystem.file(enginCopyDes).parent;
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  flutterEngineSoFile.copySync(enginCopyDes);

  final String desAppSoPath = getAppSoPath(ohosRootPath, targetPlatform);
  if (buildInfo.isRelease) {
    // copy app.so
    final String appSoPath = globals.fs.path
        .join(output, getArchPath(targetPlatform), APP_SO_ORIGIN);
    final File appSoFile = localFileSystem.file(appSoPath);
    appSoFile.copySync(desAppSoPath);
  } else {
    final File appSo = globals.fs.file(desAppSoPath);
    if (appSo.existsSync()) {
      appSo.deleteSync();
    }
  }

  //copy har
  final String suffix = buildInfo.isDebug ? 'debug' : 'release';
  final String originHarPath =
      globals.fs.path.join(ohosRootPath, 'har', '$HAR_FILE_NAME.$suffix');
  final String desHarPath =
      globals.fs.path.join(ohosRootPath, 'har', HAR_FILE_NAME);
  final File originHarFile = localFileSystem.file(originHarPath);
  originHarFile.copySync(desHarPath);

  logger?.printStatus('copy flutter assets to project end');

  /// ohpm install
  final String ohpmHome = Platform.environment['OHPM_HOME']!;
  await ohpmInstall(
      processManager: globals.processManager,
      ohpmHome: ohpmHome,
      entryPath: getEntryPath(ohosRootPath),
      logger: logger);

  /// change hvigorw modle
  final OperatingSystemUtils operatingSystemUtils = globals.os;
  final String hvigorwPath = getHvigorwPath(ohosRootPath);
  final File file = localFileSystem.file(hvigorwPath);
  operatingSystemUtils.chmod(file, '755');

  /// last ,invoke hvigow task generate hap file.
  await assembleHap(
      processManager: globals.processManager,
      ohosRootPath: ohosRootPath,
      hvigorwPath: hvigorwPath,
      logger: logger);

  /// signer hap , this part should throw to ide
  String signToolHome = Platform.environment['SIGN_TOOL_HOME'] ??
      '/home/xc/sdk/developtools_hapsigner/autosign';

  // todo change bundleName
  final String unsignedFile = globals.fs.path.join(ohosRootPath,
      'entry/build/default/outputs/default', 'entry-default-unsigned.hap');
  final String desFile =
      globals.fs.path.join(signToolHome, 'app1-unsigned.hap');
  final File unsignedHap = localFileSystem.file(unsignedFile);
  unsignedHap.copySync(desFile);

  // first delete cache ,and copy backup
  Directory cache =
      localFileSystem.directory(globals.fs.path.join(signToolHome, 'result'));
  cache.deleteSync(recursive: true);
  Directory cacheBackup = localFileSystem
      .directory(globals.fs.path.join(signToolHome, 'result.bak'));
  copyDirectory(cacheBackup, cache);

  String signtool =
      globals.fs.path.join(signToolHome, 'create_appcert_sign_profile.sh');
  final List<String> command = <String>[signtool];
  await invokeCmd(
      command: command,
      workDirectory: signToolHome,
      processManager: globals.processManager,
      logger: logger);

  String signtool2 = globals.fs.path.join(signToolHome, 'sign_hap.sh');
  final List<String> command2 = <String>[signtool2];
  await invokeCmd(
      command: command2,
      workDirectory: signToolHome,
      processManager: globals.processManager,
      logger: logger);

  String signedFile =
      globals.fs.path.join(signToolHome, 'result', 'app1-signed.hap');
  String desSignedFile = globals.fs.path.join(ohosRootPath,
      'entry/build/default/outputs/default', 'entry-default-signed.hap');
  final File signedHap = localFileSystem.file(signedFile);
  signedHap.copySync(desSignedFile);

  return;
}

String getAbsolutePath(FlutterProject flutterProject, String path) {
  if (globals.fs.path.isRelative(path)) {
    return globals.fs.path.join(flutterProject.directory.path, path);
  }
  return path;
}

Future<void> invokeCmd(
    {required List<String> command,
    required String workDirectory,
    required ProcessManager processManager,
    Logger? logger}) async {
  final String cmd = command.join(' ');
  logger?.printTrace(cmd);
  final Process server =
      await processManager.start(command, workingDirectory: workDirectory);

  server.stderr.transform<String>(utf8.decoder).listen(logger?.printError);
  final StdoutHandler stdoutHandler =
      StdoutHandler(logger: logger!, fileSystem: globals.localFileSystem);
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stdoutHandler.handler);
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    logger.printStatus('$cmd invoke success.');
  } else {
    logger.printError('$cmd invoke error.');
  }
  return;
}

///TODO(xuchang) ohpm init first
Future<void> ohpmInstall(
    {required ProcessManager processManager,
    required String ohpmHome,
    required String entryPath,
    Logger? logger}) async {
  String ohpmPath = globals.fs.path.join(ohpmHome, 'bin', 'ohpm');
  final List<String> command = <String>[
    ohpmPath,
    'install',
  ];
  logger?.printTrace(command.join(' '));
  final Process server =
      await processManager.start(command, workingDirectory: entryPath);

  server.stderr.transform<String>(utf8.decoder).listen(logger?.printError);
  final StdoutHandler stdoutHandler =
      StdoutHandler(logger: logger!, fileSystem: globals.localFileSystem);
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stdoutHandler.handler);
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    logger.printStatus('ohpm install success.');
  } else {
    logger.printError('ohpm install error.');
  }
  return;
}

Future<void> assembleHap(
    {required ProcessManager processManager,
    required String ohosRootPath,
    required String hvigorwPath,
    Logger? logger}) async {
  /// todo change to hvigrow.bat on windows host
  final List<String> command = <String>[
    hvigorwPath,
    'clean',
    'assembleHap',
  ];

  logger?.printTrace(command.join(' '));
  final Process server =
      await processManager.start(command, workingDirectory: ohosRootPath);

  server.stderr.transform<String>(utf8.decoder).listen(logger?.printError);
  final StdoutHandler stdoutHandler =
      StdoutHandler(logger: logger!, fileSystem: globals.localFileSystem);
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stdoutHandler.handler);
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    logger.printStatus('assembleHap success.');
  } else {
    logger.printError('assembleHap error.');
  }
  return;
}
