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
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart' as base_platform;
import '../base/process.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/ohos.dart';
import '../cache.dart';
import '../compile.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'application_package.dart';
import 'hvigor_utils.dart';
import 'ohos_builder.dart';
import 'ohos_plugins_manager.dart';

/// if this constant set true , must config platform environment PUB_HOSTED_URL and FLUTTER_STORAGE_BASE_URL
const bool NEED_PUB_CN = true;

const String OHOS_DTA_FILE_NAME = 'icudtl.dat';

const String FLUTTER_ASSETS_PATH = 'flutter_assets';

const String FLUTTER_ENGINE_SO = 'libflutter.so';

const String VMSERVICE_SNAPSHOT_SO = 'libvmservice_snapshot.so';

const String APP_SO_ORIGIN = 'app.so';

const String APP_SO = 'libapp.so';

const String HAR_FILE_NAME = 'flutter_embedding.har';

final bool isWindows = globals.platform.isWindows;

String getHvigorwFile() => isWindows ? 'hvigorw.bat' : 'hvigorw';

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
String getProjectAssetsPath(String ohosRootPath, OhosProject ohosProject) {
  return globals.fs.path.join(ohosProject.flutterModuleDirectory.path,
      'src/main/resources/rawfile', FLUTTER_ASSETS_PATH);
}

/// eg:entry/src/main/resources/rawfile/flutter_assets/
String getDatPath(String ohosRootPath, OhosProject ohosProject) {
  return globals.fs.path.join(
      getProjectAssetsPath(ohosRootPath, ohosProject), OHOS_DTA_FILE_NAME);
}

/// eg:entry/libs/arm64-v8a/libflutter.so
String getEngineSoPath(String ohosRootPath, TargetPlatform targetPlatform,
    OhosProject ohosProject) {
  return globals.fs.path.join(
      getProjectArchPath(ohosRootPath, targetPlatform, ohosProject),
      FLUTTER_ENGINE_SO);
}

/// eg:entry/libs/arm64-v8a/libvmservice_snapshot.so
String getVmServiceSoDest(String ohosRootPath, TargetPlatform targetPlatform,
    OhosProject ohosProject) {
  return globals.fs.path.join(
      getProjectArchPath(ohosRootPath, targetPlatform, ohosProject),
      VMSERVICE_SNAPSHOT_SO);
}

/// eg:entry/libs/arm64-v8a/libapp.so
String getAppSoPath(String ohosRootPath, TargetPlatform targetPlatform,
    OhosProject ohosProject) {
  return globals.fs.path.join(
      getProjectArchPath(ohosRootPath, targetPlatform, ohosProject), APP_SO);
}

String getProjectArchPath(String ohosRootPath, TargetPlatform targetPlatform,
    OhosProject ohosProject) {
  final String archPath = getArchPath(targetPlatform);
  return globals.fs.path
      .join(ohosProject.flutterModuleDirectory.path, 'libs', archPath);
}

String getArchPath(TargetPlatform targetPlatform) {
  final String targetPlatformName = getNameForTargetPlatform(targetPlatform);
  final OhosArch ohosArch = getOhosArchForName(targetPlatformName);
  return getNameForOhosArch(ohosArch);
}

String getHvigorwPath(String ohosRootPath, {bool checkMod = false}) {
  final String hvigorwPath =
      globals.fs.path.join(ohosRootPath, getHvigorwFile());
  if (checkMod) {
    final OperatingSystemUtils operatingSystemUtils = globals.os;
    final File file = globals.localFileSystem.file(hvigorwPath);
    operatingSystemUtils.chmod(file, '755');
  }
  return hvigorwPath;
}

/// 签名
Future<void> signHap(LocalFileSystem localFileSystem, String unsignedFile,
    String signedOutFile, Logger? logger, String bundleName) async {
  const String PROFILE_TEMPLATE = 'profile_tmp_template.json';
  const String PROFILE_TARGET = 'profile_tmp.json';
  const String BUNDLE_NAME_KEY = '{{ohosId}}';
  final String signToolHome = Platform.environment['SIGN_TOOL_HOME'] ?? '';
  if (signToolHome == '') {
    throwToolExit("can't find environment SIGN_TOOL_HOME");
  }
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

  String projectHome = globals.fs.directory(getOhosBuildDirectory()).path;
  final Directory projectSignHistory = localFileSystem
      .directory(globals.fs.path.join(projectHome, 'signature'));

  bool isNeedCopySignHistory = true;
  // 如果result.bak不存在，代表是环境配置完成后第一次签名，拷贝result.bak。
  if (!resultBackup.existsSync()) {
    copyDirectory(result, resultBackup);
  } else if (!projectSignHistory.existsSync()) {
    // 如果projectSignHistory不存在，代表该工程从未进行过签名，此时从 result.bak 还原数据进行签名
    result.deleteSync(recursive: true);
    copyDirectory(resultBackup, result);
  } else {
    // 如果projectSignHistory存在，代表该工程之前进行过签名，此时拷贝历史签名数据进行签名
    isNeedCopySignHistory = false;
    copyDirectory(projectSignHistory, result);
  }

  if (isNeedCopySignHistory) {
    final List<String> cmdCreateCertAndProfile = <String>[];
    cmdCreateCertAndProfile.add('python3');
    cmdCreateCertAndProfile
        .add(globals.fs.path.join(signToolHome, 'autosign.py'));
    cmdCreateCertAndProfile.add('createAppCertAndProfile');

    await invokeCmd(
        command: cmdCreateCertAndProfile,
        workDirectory: signToolHome,
        processManager: globals.processManager,
        logger: logger);
    copyDirectory(result, projectSignHistory);    
  }

  final List<String> cmdSignHap = <String>[];
  if (isWindows) {
    cmdSignHap.add('py');
    cmdSignHap.add('-3');
  } else {
    cmdSignHap.add('python3');
  }
  cmdSignHap.add(globals.fs.path.join(signToolHome, 'autosign.py'));
  cmdSignHap.add('signHap');

  await invokeCmd(
      command: cmdSignHap,
      workDirectory: signToolHome,
      processManager: globals.processManager,
      logger: logger);
  final String signedFile =
      globals.fs.path.join(signToolHome, 'result', 'app1-signed.hap');
  // 拷贝到目标files
  final File signedHap = globals.localFileSystem.file(signedFile);
  signedHap.copySync(signedOutFile);
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
    required String entryPath,
    Logger? logger}) async {
  final String ohpmHome = Platform.environment['OHPM_HOME']!;
  final String ohpmPath = globals.fs.path.join(ohpmHome, 'bin', 'ohpm');
  final List<String> command = <String>[
    ohpmPath,
    'install',
  ];
  logger?.printTrace('invoke at:$entryPath ,command: ${command.join(' ')}');
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

///hvigorw任务
Future<int> hvigorwTask(List<String> taskCommand,
    {required ProcessManager processManager,
    required String workPath,
    required String hvigorwPath,
    Logger? logger}) async {
  final String taskStr = taskCommand.join(' ');
  logger?.printTrace('invoke hvigorw task: $taskStr');
  final Process server =
      await processManager.start(taskCommand, workingDirectory: workPath);
  server.stderr.transform<String>(utf8.decoder).listen(logger?.printError);
  final StdoutHandler stdoutHandler =
      StdoutHandler(logger: logger!, fileSystem: globals.localFileSystem);
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stdoutHandler.handler);
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    logger.printStatus('success! when invoke: $taskStr.');
  } else {
    logger.printError('error! when invoke: $taskStr ,exitCode = $exitCode. ');
  }
  return exitCode;
}

Future<int> assembleHap(
    {required ProcessManager processManager,
    required String ohosRootPath,
    required String hvigorwPath,
    Logger? logger}) async {
  final List<String> command = <String>[
    hvigorwPath,
    'clean',
    'assembleHap',
    '--no-daemon',
  ];
  return hvigorwTask(command,
      processManager: processManager,
      workPath: ohosRootPath,
      hvigorwPath: hvigorwPath,
      logger: logger);
}

Future<int> assembleHar(
    {required ProcessManager processManager,
    required String workPath,
    required String hvigorwPath,
    required String moduleName,
    Logger? logger}) async {
  final List<String> command = <String>[
    hvigorwPath,
    'clean',
    '--mode',
    'module',
    '-p',
    'module=$moduleName@default',
    '-p',
    'product=default',
    'assembleHar',
    '--no-daemon',
  ];
  return hvigorwTask(command,
      processManager: processManager,
      workPath: workPath,
      hvigorwPath: hvigorwPath,
      logger: logger);
}

/// 检查环境变量配置
void checkFlutterEnv(Logger? logger) {
  logger?.printStatus('check platform environment');
  if (NEED_PUB_CN) {
    checkPlatformEnvironment('PUB_HOSTED_URL', logger);
    checkPlatformEnvironment('FLUTTER_STORAGE_BASE_URL', logger);
  }
  checkPlatformEnvironment('OHPM_HOME', logger);
}

/// flutter构建
Future<String> flutterAssemble(FlutterProject flutterProject,
    BuildInfo buildInfo, TargetPlatform targetPlatform, String targetFile) async {
  late String targetName;
  if (buildInfo.isDebug) {
    targetName = 'debug_ohos_application';
  } else if (buildInfo.isProfile) {
    // eg:ohos_aot_bundle_profile_ohos-arm64
    targetName =
        'ohos_aot_bundle_profile_${getNameForTargetPlatform(targetPlatform)}';
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
            kTargetFile: targetFile,
            kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ohos),
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
    } else {
      return output;
    }
  } on Exception catch (err) {
    throwToolExit(err.toString());
  } finally {
    status.stop();
  }
}

/// 清理和拷贝flutter产物和资源
void cleanAndCopyFlutterAssest(
    OhosProject ohosProject,
    BuildInfo buildInfo,
    TargetPlatform targetPlatform,
    Logger? logger,
    String ohosRootPath,
    String output) {
  logger?.printStatus('copy flutter assets to project start');
  // clean flutter assets
  final String desFlutterAssetsPath =
      getProjectAssetsPath(ohosRootPath, ohosProject);
  final Directory desAssets = globals.fs.directory(desFlutterAssetsPath);
  if (desAssets.existsSync()) {
    desAssets.deleteSync(recursive: true);
  }

  /// copy flutter assets
  copyFlutterAssets(globals.fs.path.join(output, FLUTTER_ASSETS_PATH),
      desFlutterAssetsPath, logger);

  final String desAppSoPath =
      getAppSoPath(ohosRootPath, targetPlatform, ohosProject);
  if (buildInfo.isRelease || buildInfo.isProfile) {
    // copy app.so
    final String appSoPath = globals.fs.path
        .join(output, getArchPath(targetPlatform), APP_SO_ORIGIN);
    final File appSoFile = globals.localFileSystem.file(appSoPath);
    appSoFile.copySync(desAppSoPath);
  } else {
    final File appSo = globals.fs.file(desAppSoPath);
    if (appSo.existsSync()) {
      appSo.deleteSync();
    }
  }
  logger?.printStatus('copy flutter assets to project end');
}

/// 清理和拷贝flutter运行时
void cleanAndCopyFlutterRuntime(
    OhosProject ohosProject,
    BuildInfo buildInfo,
    TargetPlatform targetPlatform,
    Logger? logger,
    String ohosRootPath,
    OhosBuildData ohosBuildData) {
  logger?.printStatus('copy flutter runtime to project start');
  // copy ohos font-family support
  final File ohosDta = globals.localFileSystem.file(globals.fs.path.join(
      ohosProject.flutterRuntimeAssertOriginPath.path,
      'dta',
      OHOS_DTA_FILE_NAME));
  final String copyDes = getDatPath(ohosRootPath, ohosProject);
  ohosDta.copySync(copyDes);

  //copy har
  final String suffix = getEmbeddingHarFileSuffix(buildInfo, ohosBuildData);
  final String harPath =
      ohosProject.isModule ? 'har_product' : 'har/har_product';
  final String originHarPath = globals.fs.path.join(
      ohosProject.flutterRuntimeAssertOriginPath.path,
      harPath,
      '$HAR_FILE_NAME.$suffix');

  String desHarPath = '';
  if (ohosProject.isModule) {
    desHarPath = globals.fs.path
        .join(ohosProject.flutterModuleDirectory.path, 'har', HAR_FILE_NAME);
  } else {
    desHarPath = globals.fs.path.join(ohosRootPath, 'har', HAR_FILE_NAME);
  }
  ensureParentExists(desHarPath);
  final File originHarFile = globals.localFileSystem.file(originHarPath);
  if (!globals.localFileSystem.file(desHarPath).existsSync()) {
    originHarFile.copySync(desHarPath);
  }

  //copy ohos engine so
  final String? originEngineSoPath = isWindows
      ? globals.fs.path.join(ohosRootPath, 'har', 'har_product', '$FLUTTER_ENGINE_SO.$suffix')
      : globals.artifacts?.getArtifactPath(Artifact.flutterEngineSo);
  if (originEngineSoPath == null) {
    throwToolExit("flutter engine runtime  file 'libflutter.so' no found");
  }
  logger?.printStatus('flutterEngineSoPath: $originEngineSoPath');

  final String destEngineSoPath = getEngineSoPath(ohosRootPath, targetPlatform, ohosProject);
  ensureParentExists(destEngineSoPath);
  final File flutterEngineSoFile = globals.localFileSystem.file(originEngineSoPath);
  flutterEngineSoFile.copySync(destEngineSoPath);

  final String vmServiceSoDest = getVmServiceSoDest(ohosRootPath, targetPlatform, ohosProject);
  final File vmServiceSoDestFile = globals.localFileSystem.file(vmServiceSoDest);
  if (buildInfo.isProfile) {
    // copy libvmservice_snapshot.so
    final String vmserviceSoSrc = isWindows
        ? globals.fs.path.join(ohosRootPath, 'har', 'har_product', '$VMSERVICE_SNAPSHOT_SO.$suffix')
        : globals.fs.path.join(flutterEngineSoFile.parent.path,
            'gen/flutter/shell/vmservice/ohos/libs',
            VMSERVICE_SNAPSHOT_SO);
    final File vmserviceSoSrcFile = globals.localFileSystem.file(vmserviceSoSrc);
    vmserviceSoSrcFile.copySync(vmServiceSoDest);
  } else {
    if (vmServiceSoDestFile.existsSync()) {
      vmServiceSoDestFile.deleteSync();
    }
  }

  logger?.printStatus('copy flutter runtime to project end');
}

void ensureParentExists(String path) {
  final Directory directory = globals.localFileSystem.file(path).parent;
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
}

String getEmbeddingHarFileSuffix(
    BuildInfo buildInfo, OhosBuildData ohosBuildData) {
  final int apiVersion = ohosBuildData.apiVersion;
  return '${buildInfo.isDebug ? 'debug' : buildInfo.isProfile ? 'profile' : 'release'}.$apiVersion';
}

class OhosHvigorBuilder implements OhosBuilder {
  OhosHvigorBuilder({
    required Logger logger,
    required ProcessManager processManager,
    required FileSystem fileSystem,
    required Artifacts artifacts,
    required Usage usage,
    required HvigorUtils hvigorUtils,
    required base_platform.Platform platform,
  })  : _logger = logger,
        _fileSystem = fileSystem,
        _artifacts = artifacts,
        _usage = usage,
        _hvigorUtils = hvigorUtils,
        _fileSystemUtils =
            FileSystemUtils(fileSystem: fileSystem, platform: platform),
        _processUtils =
            ProcessUtils(logger: logger, processManager: processManager);

  final Logger _logger;
  final ProcessUtils _processUtils;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final Usage _usage;
  final HvigorUtils _hvigorUtils;
  final FileSystemUtils _fileSystemUtils;

  late OhosProject ohosProject;
  late String ohosRootPath;
  late OhosBuildData ohosBuildData;

  void parseData(FlutterProject flutterProject, Logger? logger) {
    ohosProject = flutterProject.ohos;
    ohosRootPath = ohosProject.ohosRoot.path;
    ohosBuildData = OhosBuildData.parseOhosBuildData(ohosProject, logger);
  }

  /// build hap
  @override
  Future<void> buildHap(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger}) async {
    logger?.printStatus('start hap build...');

    if (!flutterProject.ohos.ohosBuildData.modeInfo.hasEntryModule) {
      throwToolExit(
          "this ohos project don't have a entry module , can't build to a hap file.");
    }

    parseData(flutterProject, logger);

    /// 检查plugin的har构建
    await checkPluginsHarUpdate(flutterProject, buildInfo, ohosBuildData);

    await flutterBuildPre(flutterProject, buildInfo, target,
        targetPlatform: targetPlatform, logger: logger);

    if (ohosProject.isRunWithModuleHar) {
      final String hvigorwPath =
          getHvigorwPath(ohosProject.ephemeralDirectory.path, checkMod: true);
      final int errorCode0 = await assembleHar(
          processManager: globals.processManager,
          workPath: ohosProject.ephemeralDirectory.path,
          moduleName: ohosProject.flutterModuleName,
          hvigorwPath: hvigorwPath,
          logger: logger);
      if (errorCode0 != 0) {
        throwToolExit('assembleHar error! please check log.');
      }

      final File originHar = ohosProject.flutterModuleDirectory
          .childDirectory('build')
          .childDirectory('default')
          .childDirectory('outputs')
          .childDirectory('default')
          .childFile('${ohosProject.flutterModuleName}.har');
      if (!originHar.existsSync()) {
        throwToolExit('can not found module assemble har out file !');
      }
      final String desPath = globals.fs.path
          .join(ohosRootPath, 'har', '${ohosProject.flutterModuleName}.har');
      ensureParentExists(desPath);
      originHar.copySync(desPath);

      /// har文件拷贝后，需要重新install
      ohosProject.deleteOhModulesCache();
      await ohpmInstall(
          processManager: globals.processManager,
          entryPath: ohosProject.mainModuleDirectory.path,
          logger: logger);
    }
    final String hvigorwPath = getHvigorwPath(ohosRootPath, checkMod: true);

    /// invoke hvigow task generate hap file.
    final int errorCode1 = await assembleHap(
        processManager: globals.processManager,
        ohosRootPath: ohosRootPath,
        hvigorwPath: hvigorwPath,
        logger: logger);
    if (errorCode1 != 0) {
      throwToolExit('assembleHap error! please check log.');
    }

    final String unsignedFile = globals.fs.path.join(
        ohosRootPath,
        ohosProject.mainModuleName,
        'build/default/outputs/default',
        'entry-default-unsigned.hap');
    final String desSignedFile = globals.fs.path.join(
        ohosRootPath,
        ohosProject.mainModuleName,
        'build/default/outputs/default',
        'entry-default-signed.hap');

    await signHap(globals.localFileSystem, unsignedFile, desSignedFile, logger,
        ohosBuildData.appInfo!.bundleName);
  }

  Future<void> flutterBuildPre(
      FlutterProject flutterProject, BuildInfo buildInfo, String target,
      {required TargetPlatform targetPlatform, Logger? logger}) async {
    /**
     * 0. checkEnv
     * 1. excute flutter assemble
     * 2. copy flutter asset to flutter module
     * 3. copy flutter runtime
     * 4. ohpm install
     */
    checkFlutterEnv(logger);

    final String output =
        await flutterAssemble(flutterProject, buildInfo, targetPlatform, target);

    cleanAndCopyFlutterAssest(
        ohosProject, buildInfo, targetPlatform, logger, ohosRootPath, output);

    cleanAndCopyFlutterRuntime(ohosProject, buildInfo, targetPlatform, logger,
        ohosRootPath, ohosBuildData);

    // ohpm install at every module
    ohosProject.deleteOhModulesCache();
    if (flutterProject.ohos.isRunWithModuleHar) {
      await ohpmInstall(
          processManager: globals.processManager,
          entryPath: flutterProject.ohos.flutterModuleDirectory.path,
          logger: logger);
    } else {
      for (final Directory element in ohosProject.moduleDirectorys) {
        await ohpmInstall(
            processManager: globals.processManager,
            entryPath: element.path,
            logger: logger);
      }
    }
  }

  @override
  Future<void> buildHar(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger}) async {
    if (!flutterProject.isModule ||
        !flutterProject.ohos.flutterModuleDirectory.existsSync()) {
      throwToolExit('current project is not module or has not pub get');
    }
    parseData(flutterProject, logger);

    /// 检查plugin的har构建
    await checkPluginsHarUpdate(flutterProject, buildInfo, ohosBuildData);

    await flutterBuildPre(flutterProject, buildInfo, target,
        targetPlatform: targetPlatform, logger: logger);

    final String hvigorwPath = getHvigorwPath(ohosRootPath, checkMod: true);

    /// invoke hvigow task generate hap file.
    final int errorCode = await assembleHar(
        processManager: globals.processManager,
        workPath: flutterProject.ohos.ephemeralDirectory.path,
        hvigorwPath: hvigorwPath,
        moduleName: flutterProject.ohos.flutterModuleName,
        logger: logger);
    if (errorCode != 0) {
      throwToolExit('assembleHar error! please check log.');
    }
  }

  @override
  Future<void> buildHsp(FlutterProject flutterProject, BuildInfo buildInfo,
      {required String target,
      required TargetPlatform targetPlatform,
      Logger? logger}) {
    // TODO: implement buildHsp
    throw UnimplementedError();
  }
}
