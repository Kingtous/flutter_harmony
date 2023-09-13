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
1. 配置OpenHarmony sdk路径到环境变量OHOS_SDK_HOME，
请先下载：[Command Line Tools for OpenHarmony](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli)，然后参考[ohsdkmgr使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3) 下载OpenHarmony sdk。
（PS:api 10需要从[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component)下载ohos-full-sdk）

2. 配置OHPM路径到环境变量OHPM_HOME，下载地址：[Command Line Tools for OpenHarmony](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli)，指导文档：[ohpm使用指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3)

3. 配置签名工具,key为SIGN_TOOL_HOME,下载地址：https://gitee.com/openharmony/developtools_hapsigner

签名工具配置流程：
  * 按照readme.md，编译得到 hap-sign-tool.jar ，确保其在目录下：./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar
  * 进入autosign文件夹，新增profile_tmp.json文件，编辑如下：
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
  其中ohosId替换为待调试应用id（下一个pr将会修改为自动替换）;
编辑autosign.config和createAppCertAndProfile.config，编辑值：sign.profile.inFile=profile_tmp.json

  * 配置环境变量SIGN_TOOL_HOME，值为\<developtools_hapsigner目录\>/autosign

4. 配置\<当前项目目录\>/bin，到环境变量PATH，确保which flutter能找到\<flutter sdk\>/bin/flutter位置；

5. 运行flutter docker，检查环境变量配置是否都正确；

6. 打开vscode，安装好flutter插件，如果flutter sdk配置正确，可发现OpenHarmony连接设备，可在vscode上运行和调试应用。



## 已兼容OpenHarmony开发的指令列表：
| 指令名称 | 指令描述 | 使用说明 |
| ------- | ------- | ------- | 
| doctor | 环境检测 | flutter doctor |    
| config | 环境配置 | flutter config --\<key\> \<value\> |
| create | 创建新项目 | flutter create --platforms ohos,android --org \<org\> \<appName\> |
| devices | 已连接设备查找 | flutter devices |
| install | 应用安装 | flutter install |
| assemble | 资源打包 | flutter assemble |
| build | 应用构建 | flutter build hap --target-platform ohos-arm --debug true |
| run | 应用运行 | flutter run |
| attach | 调试模式 | flutter attach |
