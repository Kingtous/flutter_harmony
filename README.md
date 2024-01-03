Flutter SDK 仓库
==============

原始仓来源：https://github.com/flutter/flutter

## 仓库说明
本仓库是基于Flutter SDK对于OpenHarmony平台的兼容拓展，可支持IDE或者终端使用Flutter Tools指令编译和构建OpenHarmony应用程序。

## 环境依赖

* 开发系统

  Flutter Tools指令目前已支持在Linux、Mac和Windows下使用。

* 环境配置

   **下列环境变量配置，类Unix系统（Linux、Mac）下可直接参照配置，Windows下环境变量配置请在‘编辑系统环境变量’中设置**

  1. 下载[ohpm命令行工具](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli)，并配置环境变量ohpm与sdkmanager，下载完成后执行ohpm目录下`bin/init`初始化ohpm。参照指导文档：[ohpm使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3)。

     ```
     export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
     export PATH=$PATH:$OHPM_HOME/bin:$OHPM_HOME/sdkmanager/bin
     ```

  2. 下载OpenHarmony SDK并配置环境变量
  * API9 SDK下载：可参考[ohsdkmgr使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3) 使用命令下载API9以下SDK；
  * API10 SDK需要从[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component)下载（Linux和Windows下载`ohos-full-sdk`，Mac请下载`mac-sdk-full`或者`mac-sdk-m1-full`），解压后请保持SDK目录结构如下：
  
      ```
      /SDK
      ├── 10                                                  
      │   └── ets
      │   └── js
      │   └── native                                      
      │   └── previewer                     
      │   └── toolchains
      ├── 9
      ...
      ```

   * 配置环境变量

      ```
      export OHOS_SDK_HOME=/home/<user>/env/sdk
      export HDC_HOME=/home/<user>/env/sdk/10/toolchains
      export PATH=$PATH:$HDC_HOME

      # 配置HarmonyOS SDK
      export HOS_SDK_HOME=<HarmonyOS SDK Path>
      ```

  3. 通过代码工具下载当前仓库代码`git clone https://gitee.com/openharmony-sig/flutter_flutter.git`，并配置环境

     ```
     export PATH=<flutter_flutter path>/bin:$PATH

     # Flutter pub国内镜像
     export PUB_HOSTED_URL=https://pub.flutter-io.cn
     export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
     ```

  4. 配置签名
    
    你可以通过下面 2 种方式中任意一种对应用进行签名。
    
    (1) 使用 `Deveco Studio` 签名

    - 用 `Deveco Studio` 打开项目的 `ohos` 目录
    - 单击 `File > Project Structure > Project > Signing Configs` 界面勾选 `Automatically generate signature`，等待自动签名完成即可，单击 `OK`。
    - 查看 `build-profile.json5` 配置信息，配置信息中增加自动签名生成的证书信息。
    
    (2) 使用 [签名工具](https://gitee.com/openharmony/developtools_hapsigner) 签名

     - 下载[签名工具](https://gitee.com/openharmony/developtools_hapsigner)，并配置环境变量SIGN_TOOL_HOME。

       ```
       export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign
       ```

     - 执行gradle命令编译得到hap-sign-tool.jar，确保其在目录：./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar。(gradle版本推荐7.x)

       ```
       gradle build
       ```

     - 编辑autosign目录下`autosign.config`和`createAppCertAndProfile.config`文件，并修改其中值：

       ```
       sign.profile.inFile=profile_tmp.json
       ```

     - 在autosign目录下（ linux和mac环境下须先执行命令 `chmod 777 *.sh` ，Windows环境下无需执行此命令 ），新增`profile_tmp_template.json`文件，编辑如下：

       ```
       {
           "version-name": "2.0.0",
           "version-code": 2,
           "app-distribution-type": "os_integration",
           "uuid": "5027b99e-5f9e-465d-9508-a9e0134ffe18",
           "validity": {
               "not-before": 1594865258,
               "not-after": 1689473258
           },
           "type": "release",
           "bundle-info": {
               "developer-id": "OpenHarmony",
               "distribution-certificate": "-----BEGIN CERTIFICATE-----\nMIICSTCCAc+gAwIBAgIFAJV7uNUwCgYIKoZIzj0EAwIwYzELMAkGA1UEBhMCQ04x\nFDASBgNVBAoMC09wZW5IYXJtb255MRkwFwYDVQQLDBBPcGVuSGFybW9ueSBUZWFt\nMSMwIQYDVQQDDBpPcGVuSGFybW9ueSBBcHBsaWNhdGlvbiBDQTAeFw0yMjAxMjkw\nNTU0MTRaFw0yMzAxMjkwNTU0MTRaMGgxCzAJBgNVBAYTAkNOMRQwEgYDVQQKDAtP\ncGVuSGFybW9ueTEZMBcGA1UECwwQT3Blbkhhcm1vbnkgVGVhbTEoMCYGA1UEAwwf\nT3Blbkhhcm1vbnkgQXBwbGljYXRpb24gUmVsZWFzZTBZMBMGByqGSM49AgEGCCqG\nSM49AwEHA0IABAW8pFu7tHGUuWtddD5wvazc1qN8ts9UPZH4pecbb/bSFWKh7X7R\n/eTVaRrCTSSdovI1dhoV5GjuFsKW+jT2TwSjazBpMB0GA1UdDgQWBBScyywAaAMj\nI7HcuIS42lvZx0Lj+zAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE\nDDAKBggrBgEFBQcDAzAYBgwrBgEEAY9bAoJ4AQMECDAGAgEBCgEAMAoGCCqGSM49\nBAMCA2gAMGUCMFfNidGo6uK6KGT9zT1T5bY1NCHTH3P3muy5X1xudOgxWoOqIbnk\ntmQYB78dxWEHLQIxANfApAlXAD/0hnyNC8RDzfLOPEeay6jU9FXJj3AoR90rwZpR\noN9sYD6Oks4VGRw6yQ==\n-----END CERTIFICATE-----\n",
               "bundle-name": "{{ohosId}}",
               "apl": "normal",
               "app-feature": "hos_normal_app"
           },
           "acls": {
               "allowed-acls": [
                   ""
               ]
           },
           "permissions": {
               "restricted-permissions": []
           },
           "issuer": "pki_internal"
       }
       ```
    

   5. 应用构建依赖[Flutter Engine](https://github.com/flutter/engine)构建产物：`ohos_debug_unopt_arm64` 与 `ohos_release_arm64`，请在Flutter Tools指令运行参数中添加：`--local-engine=\<engine产物目录\>`

      上述所有环境变量的配置（Windows下环境变量配置请在‘编辑系统环境变量’中设置），可参考下面的示例（其中user和具体代码路径请替换成实际路径）：

      ```
      #flutter env start ===>

      # 国内镜像
      export PUB_HOSTED_URL=https://pub.flutter-io.cn
      export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

      # 从Gitee拉取下来的flutter_flutter目录
      export FLUTTER_HOME=/home/<user>/ohos/flutter_flutter
      export PATH=$PATH:$FLUTTER_HOME/bin

      # 解压DevEco Studio安装包中 commandline/ohcommandline-tools-mac-2.1.3.6.zip 之后 ohpm 子目录
      export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm
      export PATH=$PATH:$OHPM_HOME/bin

      # 解压DevEco Studio安装包中 commandline/ohcommandline-tools-xxx.zip 之后的 sdkmanager 子目录
      export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH

      # HarmonyOS SDK，解压DevEco Studio安装包中 sdk/X86SDK.zip 或 M1SDK.zip 之后的目录，HOS_SDK_HOME下有 openharmony、hmscore、licenses 三个直接子目录
      export HOS_SDK_HOME=/home/<user>/ohos/sdk

      # OpenHarmony SDK，解压DevEco Studio安装包中 sdk/X86SDK.zip 或 M1SDK.zip 之后的 openharmony 子目录
      export OHOS_SDK_HOME=/home/<user>/ohos/sdk/openharmony

      # HDC Home，OHOS_SDK_HOME目录下的 10/toolchains 子目录
      export HDC_HOME=/home/<user>/ohos/sdk/openharmony/10/toolchains
      export PATH=$PATH:$HDC_HOME

      # 签名工具
      export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign

      # grade
      export PATH=/home/<user>/env/gradle-7.3/bin:$PATH

      # nodejs
      export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
      export PATH=$NODE_HOME/bin:$PATH

      #flutter env end <===
      ```


## 构建步骤

1. 运行 `flutter doctor -v` 检查环境变量配置是否正确，**Futter**与**OpenHarmony**应都为ok标识，若两处提示缺少环境，按提示补上相应环境即可。

2. 创建工程与编译命令，编译产物在\<projectName\>/ohos/entry/build/default/outputs/default/entry-default-signed.hap下。

   ```
   # 创建工程
   flutter create --platforms ohos <projectName>

   # 进入工程根目录编译
   # 示例：flutter build hap --target-platform ohos-arm64 --local-engine-src-path=/home/user/code/flutter/engine_make/src --local-engine=ohos_release_arm64
   flutter build hap --target-platform ohos-arm64 --local-engine-src-path=<flutter_engine src path> --local-engine=ohos_release_arm64
   ```

3. 通过`flutter devices`指令发现ohos设备之后，使用 `hdc -t <deviceId> install <hap file path>`进行安装。

4. 也可直接使用下列指令运行：
```
   # 示例：flutter run --local-engine=/home/user/code/flutter/engine_make/src/out/ohos_debug_unopt_arm64
   flutter run --local-engine=<flutter_engine out path>
```


## 已兼容OpenHarmony开发的指令列表
| 指令名称 | 指令描述 | 使用说明                                                              |
| ------- | ------- |-------------------------------------------------------------------|
| doctor | 环境检测 | flutter doctor                                                    |
| config | 环境配置 | flutter config --\<key\> \<value\>                                |
| create | 创建新项目 | flutter create --platforms ohos,android,ios --org \<org\> \<appName\> |
| create | 创建module模板 | flutter create -t module \<module_name\> |
| create | 创建plugin模板 | flutter create -t plugin --platforms ohos,android,ios \<plugin_name\> |
| create | 创建plugin_ffi模板 | flutter create -t plugin_ffi --platforms ohos,android,ios \<plugin_name\> |
| devices | 已连接设备查找 | flutter devices                                                   |
| install | 应用安装 | flutter install -t \<deviceId\> \<hap文件路径\>                                                   |
| assemble | 资源打包 | flutter assemble                                                  |
| build | 测试应用构建 | flutter build hap --target-platform ohos-arm64 --debug --local-engine=\<兼容ohos的debug engine产物路径\>         |
| build | 正式应用构建 | flutter build hap --target-platform ohos-arm64 --release --local-engine=\<兼容ohos的release engine产物路径\>         |
| run | 应用运行 | flutter run --local-engine=\<兼容ohos的engine产物路径\>                  |
| attach | 调试模式 | flutter attach                                                    |
| screenshot | 截屏 | flutter screenshot                                                 |

附：[Flutter三方库适配计划](https://docs.qq.com/sheet/DVVJDWWt1V09zUFN2)


## 常见问题

1. OpenHarmony SDK版本推荐: `4.0.10.3`，可在每日构建的8月20号左右下载，若在编译过程中存在SDK版本相关问题，可尝试更换该版本SDK。

2. 若出现报错：`The SDK license agreement is not accepted`，参考执行以下命令后再次编译：

   ```
   ./ohsdkmgr install ets:9 js:9 native:9 previewer:9 toolchains:9 --sdk-directory='/home/xc/code/sdk/ohos-sdk/' --accept-license
   ```

3. 切换debug和release编译模式后，可能运行报错，可尝试删除oh_modules缓存文件，重新编译。

4. 如果`flutter docker -v`提示ohpm无法找到，但是检测环境变量无误，请确保已执行`ohpm/bin/init`命令安装ohpm后再次检查。

5. 若在编译签名工具时遇到错误Unsupported class file major version 61，说明当前JDK版本不支持，请降低Java SDK版本重试。

6. 如果你使用的是DevEco Studio的Beta版本，编译工程时遇到“must have required property 'compatibleSdkVersion', location: demo/ohos/build-profile.json5:17:11"错误，请参考《DevEco Studio环境配置指导.docx》中的‘6 创建工程和运行Hello World’【配置插件】章节修改 hvigor/hvigor-config.json5文件。

7. 若提示安装报错：`fail to verify pkcs7 file` 请执行指令

   ```
   hdc shell param set persist.bms.ohCert.verify true
   ```
8. linux虚拟机通过hdc无法直接发现OpenHarmony设备

   解决方案：在windows宿主机中，开启hdc server，具体指令如下：
   ```
   hdc kill
   hdc -s serverIP:8710 -m
   ```
   在linux中配置环境变量：
   ```
   HDC_SERVER=<serverIP>
   HDC_SERVER_PORT=8710
   ```

   配置完成后flutter sdk可以通过hdc server完成设备连接，也可参考[官方指导](https://docs.openharmony.cn/pages/v4.0/zh-cn/device-dev/subsystems/subsys-toolchain-hdc-guide.md/#hdc-client%E5%A6%82%E4%BD%95%E8%BF%9C%E7%A8%8B%E8%AE%BF%E9%97%AEhdc-server)。

9. 构建Hap任务时报错：Error: The hvigor depends on the npmrc file. Configure the npmrc file first.


   请在用户目录`~`下创建文件`.npmrc`，该配置也可参考[DevEco Studio官方文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config-0000001052902427-V3)，编辑内容如下：

   ```
   registry=https://repo.huaweicloud.com/repository/npm/
   @ohos:registry=https://repo.harmonyos.com/npm/
   ```