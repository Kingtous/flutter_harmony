Flutter SDK 仓库
==============

原始仓来源：https://github.com/flutter/flutter

## 仓库说明：
本仓库是基于flutter sdk对于OpenHarmony的兼容拓展，可支持使用flutter tools指令编译和构建OpenHarmony应用程序。

## 构建说明：

* 构建环境：
  flutter tools指令支持Linux、Mac和Windows下使用。

* 构建依赖：
  依赖[flutter engine](https://github.com/flutter/engine)构建产物：`ohos_debug_unopt_arm64` 与 `ohos_release_arm64`，请在flutter tools指令运行参数中添加：`--local-engine=\<engine产物目录\>`

* 构建步骤：

   **Windows环境请通过编辑Windows下的“环境变量”页面设置环境变量**

  1. 下载[命令行工具](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli)，并配置环境变量ohpm与sdkmanager，下载完成后执行`ohpm/bin/init`安装ohpm。参照指导文档：[ohpm使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3)。

     ```
     export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
     export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH
     export PATH=$PATH:$OHPM_HOME/bin
     ```

  2. 下载sdk并配置环境变量，可参考[ohsdkmgr使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3) 使用命令下载OpenHarmony sdk（API9以下），AP10需要从[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component)下载ohos-full-sdk，请保持sdk目录结构如下。(mac环境编译，请下载mac-sdk-full或者mac-sdk-m1-full)

     ```
     export OHOS_SDK_HOME=/home/<user>/env/sdk
     export HDC_HOME=/home/<user>/env/sdk/10/toolchains
     export PATH=$PATH:$HDC_HOME

     # 配置HarmonyOS sdk
     export HOS_SDK_HOME=/home/<user>/env/{HarmonyOS sdk}
     ```

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

  3. 配置Gradle：下载 `gradle 7.1` 并解压，配置到环境变量中：

     ```
     # grade
     export PATH=/home/<user>/env/gradle-7.1/bin:$PATH
     ```

  4. 下载Flutter，下载完成后配置环境：

     ```
     git clone https://gitee.com/openharmony-sig/flutter_flutter.git

     export PATH=/home/<user>/ohos/flutter_flutter/bin:$PATH
     export PUB_HOSTED_URL=https://pub.flutter-io.cn
     export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
     ```

  5. 签名工具需进行下列配置：

     - 下载[签名工具](https://gitee.com/openharmony/developtools_hapsigner)，并配置环境变量SIGN_TOOL_HOME。

       ```
       export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign
       ```

     - 执行以下命令编译得到hap-sign-tool.jar，确保其在目录：./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar。

       ```
       gradle build
       ```

     - 编辑autosign目录下`autosign.config`和`createAppCertAndProfile.config`文件，并修改其中值：

       ```
       sign.profile.inFile=profile_tmp.json
       ```

     - 在autosign目录下，执行命令`chmod 777 *.sh` (Windows环境下无需执行此命令)，新增`profile_tmp_template.json`文件，编辑如下：

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

  6. 若`~/`目录下未创建`.npmrc`配置，构建hap时可能报错：Error: The hvigor depends on the npmrc file. Configure the npmrc file first，届时请在用户目录`~`下创建文件`.npmrc`，该配置也可参考[官方文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config-0000001052902427-V3)，编辑内容如下：

     ```
     registry=https://repo.huaweicloud.com/repository/npm/
     @ohos:registry=https://repo.harmonyos.com/npm/
     ```


上述所有环境变量的配置，可参考下面的示例（其中user和具体代码路径请替换成实际路径，Windows环境请通过编辑Windows下的“环境变量”页面配置环境变量）：

```
#flutter env start ===>

# 国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# flutter
export FLUTTER_HOME=/home/<user>/code/flutter/gitlab/flutter
export PATH=$PATH:$FLUTTER_HOME/bin

export PATH=/home/<user>/ohos/flutter_flutter/bin:$PATH
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# ohpm
export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
export PATH=$PATH:$OHPM_HOME/bin
# sdkmanager
export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH

# sdk与hdc
export OHOS_SDK_HOME=/home/<user>/env/sdk
export HDC_HOME=/home/<user>/env/sdk/10/toolchains
export PATH=$PATH:$HDC_HOME
# 配置HarmonyOS sdk
export HOS_SDK_HOME=/home/<user>/env/{HarmonyOS sdk}

# 签名工具
export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign

# grade
export PATH=/home/<user>/env/gradle-7.1/bin:$PATH
# nodejs
export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
export PATH=$NODE_HOME/bin:$PATH

#flutter env end <===
```

- 构建

1. 运行 `flutter doctor -v` 检查环境变量配置是否正确，**Futter**与**Openharmony**应都为ok标识，若两处提示缺少环境，按提示补上相应环境即可。

2. 创建工程与编译命令，编译产物在flutter_demo/ohos/entry/build/default/outputs/default/entry-default-signed.hap下。

   ```
   # 创建工程
   flutter create --platforms ohos flutter_demo
   # 进入工程根目录编译
   flutter build hap --local-engine-src-path /home/<user>/ohos/engine/src --local-engine ohos_release_arm64
   ```

3. flutter devices发现ohos设备之后，使用 `hdc -t <deviceId> install <hap file path>`进行安装。

## 关于windows下linux虚拟机如何连接和调试OpenHarmony设备

* 问题：linux虚拟机通过hdc无法直接发现OpenHarmony设备
* 解决方案：在windows宿主机中，开启hdc server，具体指令如下：
```
hdc kill
hdc -s serverIP:8710 -m
```
在linux中配置环境变量：
```
HDC_SERVER=<serverIP>
HDC_SERVER_PORT=8710
```

配置完成后flutter sdk可以通过hdc server完成设备连接，也可参考[官方指导](https://docs.openharmony.cn/pages/v4.0/zh-cn/device-dev/subsystems/subsys-toolchain-hdc-guide.md/#hdc-client%E5%A6%82%E4%BD%95%E8%BF%9C%E7%A8%8B%E8%AE%BF%E9%97%AEhdc-server)

## 已兼容OpenHarmony开发的指令列表：
| 指令名称 | 指令描述 | 使用说明                                                              |
| ------- | ------- |-------------------------------------------------------------------|
| doctor | 环境检测 | flutter doctor                                                    |
| config | 环境配置 | flutter config --\<key\> \<value\>                                |
| create | 创建新项目 | flutter create --platforms ohos,android --org \<org\> \<appName\> |
| devices | 已连接设备查找 | flutter devices                                                   |
| install | 应用安装 | flutter install -t \<deviceId\> \<hap文件路径\>                                                   |
| assemble | 资源打包 | flutter assemble                                                  |
| build | 测试应用构建 | flutter build hap --target-platform ohos-arm64 --debug --local-engine=\<兼容ohos的debug engine产物路径\>         |
| build | 正式应用构建 | flutter build hap --target-platform ohos-arm64 --release --local-engine=\<兼容ohos的release engine产物路径\>         |
| run | 应用运行 | flutter run --local-engine=\<兼容ohos的engine产物路径\>                  |
| attach | 调试模式 | flutter attach                                                    |
| screenshot | 截屏 | flutter screenshot                                                 |

## 常见问题：

1. ohos sdk版本推荐: `4.0.10.3`，可在每日构建的8月20号左右下载，若在编译过程中存在SDK版本相关问题，可尝试更换该版本SDK。

2. 若出现报错：`The SDK license agreement is not accepted`，参考执行以下命令后再次编译：

   ```
   ./ohsdkmgr install ets:9 js:9 native:9 previewer:9 toolchains:9 --sdk-directory='/home/xc/code/sdk/ohos-sdk/' --accept-license
   ```

3. 切换debug和release编译模式后，可能运行报错，可尝试删除oh_modules缓存文件，重新编译。

4. 如果`flutter docker -v`提示ohpm无法找到，但是检测环境变量无误，请确保已执行`ohpm/bin/init`命令安装ohpm后再次检查。

5. 若在编译签名工具时遇到错误Unsupported class file major version 61，说明当前JDK版本不支持，可以命令展示当前系统中所有JDK版本并选择所需版本，输入编号后确认选择再次编译。

   ```
   sudo update-alternatives --config java
   ```

6. 如果你使用的是DevEco Studio的Beta版本，编译工程时遇到“must have required property 'compatibleSdkVersion', location: demo/ohos/build-profile.json5:17:11"错误，请参考《DevEco Studio环境配置指导.docx》中的‘6 创建工程和运行Hello World’【配置插件】章节修改 hvigor/hvigor-config.json5文件。