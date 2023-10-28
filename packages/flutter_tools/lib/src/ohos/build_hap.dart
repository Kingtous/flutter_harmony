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
import '../convert.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'application_package.dart';

/// if this constant set true , must config platform environment PUB_HOSTED_URL and FLUTTER_STORAGE_BASE_URL
const bool NEED_PUB_CN = true;

const String OHOS_DTA_FILE_NAME = 'icudtl.dat';

const String FLUTTER_ASSETS_PATH = 'flutter_assets';

const String FLUTTER_ENGINE_SO = 'libflutter.so';

const String APP_SO_ORIGIN = 'app.so';

const String APP_SO = 'libapp.so';

const String HAR_FILE_NAME = 'flutter_embedding.har';

const String HVIGORW_FILE = 'hvigorw';

final bool isWindows = globals.platform.isWindows;

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
  } else if (buildInfo.isProfile) {
    // eg:ohos_aot_bundle_profile_ohos-arm64
    targetName = 'ohos_aot_bundle_profile_${getNameForTargetPlatform(targetPlatform)}';
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



  final String desAppSoPath = getAppSoPath(ohosRootPath, targetPlatform);
  if (buildInfo.isRelease || buildInfo.isProfile) {
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

  final OhosProject ohosProject = flutterProject.ohos;
  final OhosBuildData ohosBuildData =
      OhosBuildData.parseOhosBuildData(ohosProject, logger);
  final int apiVersion = ohosBuildData.apiVersion;

  // delete directory ohos/entry/oh_modules
  final Directory ohModulesFile = ohosProject.ohModules;
  if (ohModulesFile.existsSync()) {
    ohModulesFile.deleteSync(recursive: true);
  }
  //copy har
  final String suffix = '${buildInfo.isDebug ? 'debug' : 
    buildInfo.isProfile ? 'profile' : 'release'}.$apiVersion';
  final String originHarPath =
      globals.fs.path.join(ohosRootPath, 'har', '$HAR_FILE_NAME.$suffix');
  final String desHarPath =
      globals.fs.path.join(ohosRootPath, 'har', HAR_FILE_NAME);
  final File originHarFile = localFileSystem.file(originHarPath);
  originHarFile.copySync(desHarPath);

    //copy ohos engine so
  if (isWindows) {
    final String originEnginePath =
      globals.fs.path.join(ohosRootPath, 'har', '$FLUTTER_ENGINE_SO.$suffix');
    final String desEnginePath =
      globals.fs.path.join(ohosRootPath, 'entry/libs/arm64-v8a', FLUTTER_ENGINE_SO);
    final File flutterEngineSoFile = localFileSystem.file(originEnginePath);
    flutterEngineSoFile.copySync(desEnginePath);
  } else {
    final String? flutterEngineSoPath =
      globals.artifacts?.getArtifactPath(Artifact.flutterEngineSo);
    if (flutterEngineSoPath == null) {
      throwToolExit("flutter engine runtime  file 'libflutter.so' no found");
    }
    logger?.printStatus("flutterEngineSoPath:" + flutterEngineSoPath.toString());
    final File flutterEngineSoFile = localFileSystem.file(flutterEngineSoPath);
    
    final String enginCopyDes = getEngineSoPath(ohosRootPath, targetPlatform);
    final Directory directory = localFileSystem.file(enginCopyDes).parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    flutterEngineSoFile.copySync(enginCopyDes);
  }

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
  final int errorCode = await assembleHap(
      processManager: globals.processManager,
      ohosRootPath: ohosRootPath,
      hvigorwPath: hvigorwPath,
      logger: logger);
  if (errorCode != 0) {
    throwToolExit('assembleHap error! please check log.');
  }

  /// signer hap , this part should throw to ide
  final String signToolHome = Platform.environment['SIGN_TOOL_HOME'] ?? '';
  if (signToolHome == '') {
    throwToolExit("can't find environment SIGN_TOOL_HOME");
  }

  final String unsignedFile = globals.fs.path.join(ohosRootPath,
      'entry/build/default/outputs/default', 'entry-default-unsigned.hap');

  /// 进行签名
  final String signedFile = await signHap(localFileSystem, unsignedFile,
      signToolHome, logger, ohosBuildData.appInfo.bundleName);

  /// 拷贝已签名文件到构建目录
  final String desSignedFile = globals.fs.path.join(ohosRootPath,
      'entry/build/default/outputs/default', 'entry-default-signed.hap');
  final File signedHap = localFileSystem.file(signedFile);
  signedHap.copySync(desSignedFile);

  return;
}

/// 签名
Future<String> signHap(LocalFileSystem localFileSystem, String unsignedFile,
    String signToolHome, Logger? logger, String bundleName) async {
  const String PROFILE_TEMPLATE = 'profile_tmp_template.json';
  const String PROFILE_TARGET = 'profile_tmp.json';
  const String BUNDLE_NAME_KEY = '{{ohosId}}';
  logger?.printWarning("ohosId bundleName: $bundleName");
  //修改HarmonyAppProvision配置文件
  final String provisionTemplatePath =
      globals.fs.path.join(signToolHome, PROFILE_TEMPLATE);
  final File provisionTemplateFile =
      localFileSystem.file(provisionTemplatePath);
  if (!provisionTemplateFile.existsSync()) {
    throwToolExit(
        '$PROFILE_TEMPLATE is not found,Please refer to the readme to create the file.');
  }
  final String provisionTargetPath =
      globals.fs.path.join(signToolHome, PROFILE_TARGET);
  final File provisionTargetFile = localFileSystem.file(provisionTargetPath);
  if (provisionTargetFile.existsSync()) {
    provisionTargetFile.deleteSync();
  }
  replaceKey(
      provisionTemplateFile, provisionTargetFile, BUNDLE_NAME_KEY, bundleName);

  //拷贝待签名文件
  final String desFilePath =
      globals.fs.path.join(signToolHome, 'app1-unsigned.hap');
  final File unsignedHap = localFileSystem.file(unsignedFile);
  final File desFile = localFileSystem.file(desFilePath);
  if (desFile.existsSync()) {
    desFile.deleteSync();
  }
  unsignedHap.copySync(desFilePath);

  //执行create_appcert_sign_profile时，result需要是初始状态，所以备份和管理result
  final Directory result =
      localFileSystem.directory(globals.fs.path.join(signToolHome, 'result'));
  if (!result.existsSync()) {
    throwToolExit('请还原autosign/result目录到初始状态');
  }
  final Directory resultBackup = localFileSystem
      .directory(globals.fs.path.join(signToolHome, 'result.bak'));
  //如果result.bak不存在，代表是第一次构建，拷贝result.bak。 以后每一次result，都从result.bak还原
  if (!resultBackup.existsSync()) {
    copyDirectory(result, resultBackup);
  } else {
    result.deleteSync(recursive: true);
    copyDirectory(resultBackup, result);
  }

  final String signtool =
      globals.fs.path.join(signToolHome, isWindows ?
	 'create_appcert_sign_profile.bat' : 'create_appcert_sign_profile.sh');
  final List<String> command = <String>[signtool];
  await invokeCmd(
      command: command,
      workDirectory: signToolHome,
      processManager: globals.processManager,
      logger: logger);

  final String signtool2 = globals.fs.path.join(signToolHome, isWindows ? 
	'sign_hap.bat' : 'sign_hap.sh');
  final List<String> command2 = <String>[signtool2];
  await invokeCmd(
      command: command2,
      workDirectory: signToolHome,
      processManager: globals.processManager,
      logger: logger);
  final String signedFile =
      globals.fs.path.join(signToolHome, 'result', 'app1-signed.hap');
  return signedFile;
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
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
    if (line.contains('error')) {
      throwToolExit('command {$command} invoke error!:$line');
    } else {
      logger?.printStatus(line);
    }
  });
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    logger?.printStatus('$cmd invoke success.');
  } else {
    logger?.printError('$cmd invoke error.');
  }
  return;
}

/// ohpm should init first
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

/// 根据来源，替换关键字，输出target文件
void replaceKey(File file, File target, String key, String value) {
  String content = file.readAsStringSync();
  content = content.replaceAll(key, value);
  target.writeAsStringSync(content);
}

Future<int> assembleHap(
    {required ProcessManager processManager,
    required String ohosRootPath,
    required String hvigorwPath,
    Logger? logger}) async {
  /// todo change to hvigrow.bat on windows host
  final List<String> command = <String>[
    hvigorwPath,
    'clean',
    'assembleHap',
    '--no-daemon',
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
  return exitCode;
}
