Flutter SDK 仓库
==============

原始仓来源：https://github.com/flutter/flutter

## 仓库说明：
本仓库是基于flutter sdk对于OpenHarmony的兼容拓展，可支持使用flutter tools指令编译和构建OpenHarmony应用程序。

## 构建说明：

* 构建环境：
目前flutter tools指令仅支持linux下使用

* 构建依赖：
依赖[flutter engine](https://github.com/flutter/engine)构建产物，请在flutter tools指令运行参数中添加：--local-engine=\<engine产物目录\>

* 构建步骤：
1. 请先下载[Command Line Tools for OpenHarmony](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli)；

2. 在Command Line Tools下载目录中，找到sdkmanager， 参考[ohsdkmgr使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3) 下载OpenHarmony sdk。
（PS:api 10需要从[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component)下载ohos-full-sdk）
 配置OpenHarmony sdk路径到环境变量OHOS_SDK_HOME，例如:~/.bashrc新增配置export OHOS_SDK_HOME=\<sdk路径\>（路径的根目录下，包含9或者10命名api文件夹）；
 把某个openharmony api文件夹的toolchains目录，配置成HDC_HOME环境变量，并配置到PATH中；

3. 在Command Line Tools下载目录中，ohpm文件夹路径配置成环境变量OHPM_HOME，例如：export OHPM_HOME=\<父路径\>/oh-command-line-tools/ohpm，参照指导文档：[ohpm使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3)，执行ohpm/bin/init命令安装ohpm；

4. 配置签名工具环境变量SIGN_TOOL_HOME,例如：export SIGN_TOOL_HOME=\<developtools_hapsigner目录\>/autosign，下载地址：https://gitee.com/openharmony/developtools_hapsigner

签名工具还需进行下列配置：
  * 参照developtools_hapsigner的readme，编译得到 hap-sign-tool.jar ，确保其在目录下：./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar
  * 编辑autosign.config和createAppCertAndProfile.config，修改值：sign.profile.inFile=profile_tmp.json
  * 进入autosign文件夹，执行命令chmod 777 *.sh，并且新增profile_tmp_template.json文件，编辑如下：
  ```json
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

5. 如果/home/\<user\>/目录下，还未创建.npmrc配置，构建hap时可能报错：Error: The hvigor depends on the npmrc file. Configure the npmrc file first.
请在用户目录/home/\<user\>/下创建文件.npmrc，编辑内容如下：
```
registry=https://repo.huaweicloud.com/repository/npm/
@ohos:registry=https://repo.harmonyos.com/npm/
```
该配置也可参考[官方文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config-0000001052902427-V3)

6. 配置\<当前项目目录\>/bin，到环境变量PATH，确保which flutter能找到\<flutter sdk\>/bin/flutter位置；

上述所有环境变量的配置，可参考下面的实例（其中user和具体代码路径请替换成实际路径）：
```
#flutter env start ===>

# 国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

export OHOS_SDK_HOME=/home/<user>/code/sdk/ohos-sdk
export OHPM_HOME=/home/<user>/code/openharmony/oh-command-line-tools/ohpm
export SIGN_TOOL_HOME=/home/<user>/code/openharmony/developtools_hapsigner/autosign
export HDC_HOME=/home/<user>/code/sdk/ohos-sdk/10/toolchains

export FLUTTER_HOME=/home/<user>/code/flutter/gitlab/flutter
export PATH=$PATH:$FLUTTER_HOME/bin:$HDC_HOME

#flutter env end <===
```

7. 运行flutter docker，检查环境变量配置是否都正确；

8. 打开vscode，安装好flutter插件，如果flutter sdk配置正确，可发现OpenHarmony连接设备，可在vscode上运行和调试应用。


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
| install | 应用安装 | flutter install -d \<deviceId\> \<hap文件路径\>                                                   |
| assemble | 资源打包 | flutter assemble                                                  |
| build | 测试应用构建 | flutter build hap --target-platform ohos-arm64 --debug --local-engine=\<兼容ohos的debug engine产物路径\>         |
| build | 正式应用构建 | flutter build hap --target-platform ohos-arm64 --release --local-engine=\<兼容ohos的release engine产物路径\>         |
| run | 应用运行 | flutter run --local-engine=\<兼容ohos的engine产物路径\>                  |
| attach | 调试模式 | flutter attach                                                    |
