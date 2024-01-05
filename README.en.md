闲鱼鸿蒙适配分支版本：


Flutter SDK repository
==============

Original warehouse source: https://github.com/flutter/flutter

## Warehouse description
This repository is a compatible extension of Flutter SDK for the OpenHarmony platform, and can support IDE or terminal use of Flutter Tools instructions to compile and build OpenHarmony applications.

## Environment dependencies

* development system

   Flutter Tools commands are currently supported on Linux, Mac and Windows.

* Environment configuration

    **For the following environment variable configuration, you can directly refer to the configuration under Unix-like systems (Linux, Mac). For environment variable configuration under Windows, please set it in ‘Edit System Environment Variables’**

   1. Download [ohpm command line tool](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli), and configure the environment variables ohpm and sdkmanager. After the download is completed, execute `bin/init in the ohpm directory `Initialize ohpm. Refer to the guidance document: [ohpm usage guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3).

      ```
      export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
      export PATH=$PATH:$OHPM_HOME/bin:$OHPM_HOME/sdkmanager/bin
      ```

   2. Download OpenHarmony SDK and configure environment variables
   * API9 SDK download: Please refer to [ohsdkmgr usage guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3) Use the command to download SDK below API9;
   *API10 SDK needs to be downloaded from [Daily Build](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component) (download `ohos-full-sdk` for Linux and Windows, please download `mac for Mac -sdk-full` or `mac-sdk-m1-full`), please keep the SDK directory structure as follows after decompression:
  
       ```
       /SDK
       ├── 10
       │ └── ets
       │ └── js
       │ └── native
       │ └── previewer
       │ └── toolchains
       ├── 9
       ...
       ```

    * Configure environment variables

       ```
       export OHOS_SDK_HOME=/home/<user>/env/sdk
       export HDC_HOME=/home/<user>/env/sdk/10/toolchains
       export PATH=$PATH:$HDC_HOME

       # Configure HarmonyOS SDK
       export HOS_SDK_HOME=<HarmonyOS SDK Path>
       ```

   3. Download the current warehouse code `git clone https://gitee.com/openharmony-sig/flutter_flutter.git` through the code tool, and configure the environment

      ```
      export PATH=<flutter_flutter path>/bin:$PATH

      # Flutter pub domestic mirror
      export PUB_HOSTED_URL=https://pub.flutter-io.cn
      export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
      ```

   4. Signature
    
    You can sign the application using either of the following two methods.

    (1) Signing with `Deveco Studio`

    - Open the ohos directory of the project using Deveco Studio.
    - Click on File > Project Structure > Project > Signing Configs. Check the Automatically generate signature option, wait for the automatic signing process to complete, and then click OK.
    - Review the configuration information in build-profile.json5. Add the certificate information generated from the automatic signing process to the configuration.
    
    (2) Signing with signing tool

    - Download [Signature Tool](https://gitee.com/openharmony/developtools_hapsigner) and configure   theenvironment variable SIGN_TOOL_HOME.
      ```
      export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign
      ```
    - Execute the gradle command to compile and obtain hap-sign-tool.jar. Make sure it is in thedirectory: ./  hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar. (gradle version recommended 7.x)
      ```
      gradle build
      ```
    - Edit the `autosign.config` and `createAppCertAndProfile.config` files in the autosign directory andmodify   their values:
      ```
      sign.profile.inFile=profile_tmp.json
      ```
    - In the autosign directory (the command `chmod 777 *.sh` must be executed first in linux and   macenvironments, and there is no need to execute this command in Windows environment), add   the`profile_tmp_template.json` file and edit it as follows:
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
              "distribution-certificate": "-----BEGIN CERTIFICATE-----\nMIICSTCCA  +gAwIBAgIFAJV7uNUwCgYIKoZIzj0EAwIwYzELMAkGA1UEBhMCQ04x\nFDASBgNVBAoMC09wZW5IYXJtb255MRkwFwYDVQLDBB  PcGVuSGFybW9ueS   BUZWTZMBcGA1UECwwQT3Blbkhhcm1vbnkgVGVhbTEoMCYGA1UEAwwf\nT3Blbkhhcm1vbnkgQXBwbGljYXRpb24gUmVsZWFzZT  ZMBMGByqGSM49AgEGCCqG\nSM49AwEHA0IABAW8pFu7tHGUuWtddD5wvazc1qN8t s9UPZH4pecbb/  bSFWKh7X7R\neTVaRrCTSSdovI1dhoV5GjuFsKW+jT2TwSjazBpMB0GA1UdDgQWBBScyywAaAMj\nI7HcuIS42lvZx0L  +zAJBgNVHRMEAjAAMA4GA1UdDwEB/  wQEAwIHgDATBgNVHSUE\nDDAKBggrBgEFBQcDAzAYBgwrBgEEAY9bAoJ4AQMECDAGAgEBCgEAMAoGCCqGSM49\nBAMCA2gAMGU  CFfNidGo6uK6KGTzT1T5bY1NCHTH3P3muy5X1xudOgxWoOqIbnk\ntmQYB78dxWEHLQIxANfApAlXAD/  0hnyNC8RDzfLOPEeay6jU9FXJj3AoR90rwZpR\noN9sYD6Oks4VGRw6yQ==\n-----END CERTIFICATE-----\n",
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

    5. The application build relies on [Flutter Engine](https://github.com/flutter/engine) to build products: `ohos_debug_unopt_arm64` and `ohos_release_arm64`. Please add: `--local-engine= in the Flutter Tools command running parameters. \<engine product directory\>`

       For the configuration of all the above environment variables (for environment variable configuration under Windows, please set it in 'Edit System Environment Variables'), you can refer to the following example (please replace user and specific code path with the actual path):

       ```
       #flutter env start ===>

       # Domestic mirror
       export PUB_HOSTED_URL=https://pub.flutter-io.cn
       export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

       # The flutter_flutter directory pulled from Gitee
       export FLUTTER_HOME=/home/<user>/ohos/flutter_flutter
       export PATH=$PATH:$FLUTTER_HOME/bin

       # Unzip the ohpm subdirectory after commandline/ohcommandline-tools-mac-2.1.3.6.zip in the DevEco Studio installation package
       export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm
       export PATH=$PATH:$OHPM_HOME/bin

       # Unzip the sdkmanager subdirectory after commandline/ohcommandline-tools-xxx.zip in the DevEco Studio installation package
       export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH

       # HarmonyOS SDK, unzip the directory after sdk/X86SDK.zip or M1SDK.zip in the DevEco Studio installation package. There are three direct subdirectories under HOS_SDK_HOME: openharmony, hmscore, and licenses
       export HOS_SDK_HOME=/home/<user>/ohos/sdk

       # OpenHarmony SDK, unzip the openharmony subdirectory after sdk/X86SDK.zip or M1SDK.zip in the DevEco Studio installation package
       export OHOS_SDK_HOME=/home/<user>/ohos/sdk/openharmony

       # HDC Home, 10/toolchains subdirectory under the OHOS_SDK_HOME directory
       export HDC_HOME=/home/<user>/ohos/sdk/openharmony/10/toolchains
       export PATH=$PATH:$HDC_HOME

       # Signature tool
       export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign

       # grade
       export PATH=/home/<user>/env/gradle-7.3/bin:$PATH

       #nodejs
       export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
       export PATH=$NODE_HOME/bin:$PATH

       #flutter env end <===
       ```

## Build steps

1. Run `flutter doctor -v` to check whether the environment variable configuration is correct. **Futter** and **OpenHarmony** should both be ok. If the two prompts indicate that the environment is missing, just follow the prompts to fill in the corresponding environment.

2. Create the project and compile the command. The compiled product is under \<projectName\>/ohos/entry/build/default/outputs/default/entry-default-signed.hap.

    ```
    # Create project
    flutter create --platforms ohos <projectName>

    # Enter the project root directory to compile
    # Example: flutter build hap --target-platform ohos-arm64 --local-engine-src-path=/home/user/code/flutter/engine_make/src --local-engine=ohos_release_arm64
    flutter build hap --target-platform ohos-arm64 --local-engine-src-path=<flutter_engine src path> --local-engine=ohos_release_arm64
    ```

3. After discovering the ohos device through the `flutter devices` command, use `hdc -t <deviceId> install <hap file path>` to install it.

4. You can also directly use the following command to run:
```
    # Example: flutter run --local-engine=/home/user/code/flutter/engine_make/src/out/ohos_debug_unopt_arm64
    flutter run --local-engine=<flutter_engine out path>
```


## Compatible command list developed by OpenHarmony

| Command name | Command description | Instructions for use                                                              |
| ------- | ------- |-------------------------------------------------------------------|
| doctor | environment detection | flutter doctor                                                    |
| config | environment configuration | flutter config --\<key\> \<value\>                                |
| create | Create a new project | flutter create --platforms ohos,android,ios --org \<org\> \<appName\> |
| create | Create module template | flutter create -t module \<module_name\> |
| create | Create plugin template | flutter create -t plugin --platforms ohos,android,ios \<plugin_name\> |
| create | Create plugin_ffi template | flutter create -t plugin_ffi --platforms ohos,android,ios \<plugin_name\> |
| devices | Connected device discovery | flutter devices                                                   |
| install | application installation | flutter install -t \<deviceId\> \<hap file path\>                                                   |
| assemble | resource packaging | flutter assemble                                                  |
| build | Test application build | flutter build hap --target-platform ohos-arm64 --debug --local-engine=\<debug engine product path compatible with ohos\>         |
| build | Formal application build | flutter build hap --target-platform ohos-arm64 --release --local-engine=\<ohos-compatible release engine product path\>         |
| run | application run | flutter run --local-engine=\<ohos-compatible engine product path\>                  |
| attach | debug mode | flutter attach                                                    |
| screenshot | screenshot | flutter screenshot                                                 |

Attachment: [Flutter third-party library adaptation plan](https://docs.qq.com/sheet/DVVJDWWt1V09zUFN2)

## Common Problem

1. Recommended version of OpenHarmony SDK: `4.0.10.3`, which can be downloaded around August 20 when it is built daily. If there are problems related to the SDK version during the compilation process, you can try to replace this version of the SDK.

2. If an error message appears: `The SDK license agreement is not accepted`, please execute the following command and compile again:

    ```
    ./ohsdkmgr install ets:9 js:9 native:9 previewer:9 toolchains:9 --sdk-directory='/home/xc/code/sdk/ohos-sdk/' --accept-license
    ```

3. After switching between debug and release compilation modes, an error may be reported during operation. You can try deleting the oh_modules cache file and recompiling.

4. If `flutter docker -v` prompts that ohpm cannot be found, but the environment variables are detected correctly, please ensure that you have executed the `ohpm/bin/init` command to install ohpm and check again.

5. If you encounter the error Unsupported class file major version 61 when compiling the signature tool, it means that the current JDK version does not support it. Please lower the Java SDK version and try again.

6. If you are using the Beta version of DevEco Studio and encounter the error "must have required property 'compatibleSdkVersion', location: demo/ohos/build-profile.json5:17:11" when compiling the project, please refer to "DevEco Studio" Modify the hvigor/hvigor-config.json5 file in the '6 Creating Projects and Running Hello World' [Configuration Plug-in] chapter in "Environment Configuration Guide.docx".

7. If you are prompted with an installation error: `fail to verify pkcs7 file`, please execute the command

    ```
    hdc shell param set persist.bms.ohCert.verify true
    ```
8. Linux virtual machine cannot directly discover OpenHarmony devices through hdc

    Solution: In the Windows host, open the hdc server. The specific instructions are as follows:
    ```
    hdc kill
    hdc -s serverIP:8710 -m
    ```
    Configure environment variables in linux:
    ```
    HDC_SERVER=<serverIP>
    HDC_SERVER_PORT=8710
    ```

    After the configuration is completed, the flutter sdk can complete the device connection through the hdc server. You can also refer to [official guidance](https://docs.openharmony.cn/pages/v4.0/zh-cn/device-dev/subsystems/subsys-toolchain -hdc-guide.md/#hdc-client%E5%A6%82%E4%BD%95%E8%BF%9C%E7%A8%8B%E8%AE%BF%E9%97%AEhdc-server) .

9. An error occurred when building the Hap task: Error: The hvigor depends on the npmrc file. Configure the npmrc file first.


    Please create the file `.npmrc` in the user directory `~`. For this configuration, please refer to [DevEco Studio official documentation](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config -0000001052902427-V3), the edited content is as follows:

    ```
    registry=https://repo.huaweicloud.com/repository/npm/
    @ohos:registry=https://repo.harmonyos.com/npm/
    ```