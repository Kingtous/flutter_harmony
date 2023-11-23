Flutter SDK repository
==============

Original warehouse source: https://github.com/flutter/flutter

## Warehouse description:
This warehouse is based on the compatible extension of flutter sdk for OpenHarmony, and can support the use of flutter tools instructions to compile and build OpenHarmony applications.

## Build instructions:

* Build environment:
   The flutter tools command supports use on Linux/Mac/Windows.

* Build dependencies:
   Depend on [flutter engine](https://github.com/flutter/engine) to build products: `ohos_debug_unopt_arm64` and `ohos_release_arm64`, please add: `--local-engine=\<engine product in the running parameters of the flutter tools command Directory\>`

* Building steps:

   **For Windows environment, please set environment variables in Environment Variables Dialog**

   1. Download [command line tool](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli), and configure the environment variables ohpm and sdkmanager. After the download is complete, execute `ohpm/bin/init` to install ohpm. Refer to the guidance document: [ohpm usage guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3).

      ```
      export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
      export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH
      export PATH=$PATH:$OHPM_HOME/bin
      ```

   2. Download SDK and configure environment variables, please refer to [ohsdkmgr usage guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr-0000001545647965-V3 ) Use the command to download OpenHarmony sdk (below API9), AP10 needs to download ohos-full-sdk from [Daily Build](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component), please keep the sdk The directory structure is as follows. (To compile in mac environment, please download mac-sdk-full or mac-sdk-m1-full)

      ```
      export OHOS_SDK_HOME=/home/<user>/env/sdk
      export HDC_HOME=/home/<user>/env/sdk/10/toolchains
      export PATH=$PATH:$HDC_HOME
	  # for HarmonyOS sdk
      export HOS_SDK_HOME=/home/<user>/env/{HarmonyOS sdk}
      ```

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

   3. Configure Gradle: Download `gradle 7.1` and unzip it, configure it into environment variables:

      ```
      # grade
      export PATH=/home/<user>/env/gradle-7.1/bin:$PATH
      ```

   4. Download Flutter and configure the environment after the download is complete:

      ```
      git clone https://gitee.com/openharmony-sig/flutter_flutter.git

      export PATH=/home/<user>/ohos/flutter_flutter/bin:$PATH
      export PUB_HOSTED_URL=https://pub.flutter-io.cn
      export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
      ```

   5. The signature tool requires the following configuration:

      - Download [Signature Tool](https://gitee.com/openharmony/developtools_hapsigner) and configure the environment variable SIGN_TOOL_HOME.

        ```
        export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign
        ```

      - Execute the following command to compile hap-sign-tool.jar and make sure it is in the directory: ./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar.

        ```
        gradle build
        ```

      - Edit the `autosign.config` and `createAppCertAndProfile.config` files in the autosign directory and modify their values:

        ```
        sign.profile.inFile=profile_tmp.json
        ```

      - In the autosign directory, execute the command `chmod 777 *.sh`（There is no need to execute this command in Windows environment）, and add the `profile_tmp_template.json` file, edit it as follows:

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
                "distribution-certificate": "-----BEGIN CERTIFICATE-----\nMIICSTCCAc+gAwIBAgIFAJV7uNUwCgYIKoZIzj0EAwIwYzELMAkGA1UEBhMCQ04x\nFDASBgNVBAoMC09wZW5IYXJtb255MRkwFwYDVQQLDBBPcGVuSGFybW9 ueSBUZWFt\nMSMwIQYDVQQDDBpPcGVuSGFybW9ueSBBcHBsaWNhdGlvbiBDQTAeFw0yMjAxMjkw\nNTU0MTRaFw0yMzAxMjkwNTU0MTRaMGgxCzAJBgNVBAYTAkNOMRQwEgYDVQQKDAtP\ncGVuSGFyb W9ueTEZMBcGA1UECwwQT3Blbkhhcm1vbnkgVGVhbTEoMCYGA1UEAwwf\nT3Blbkhhcm1vbnkgQXBwbGljYXRpb24gUmVsZWFzZTBZMBMGByqGSM49AgEGCCqG\nSM49AwEHA0IABAW8pFu7tHGUuWtddD5wvaz c1qN8ts9UPZH4pecbb/bSFWKh7X7R\n/eTVaRrCTSSdovI1dhoV5GjuFsKW+jT2TwSjazBpMB0GA1UdDgQWBBScyywAaAMj\nI7HcuIS42lvZx0Lj+zAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDA TBgNVHSUE\ nDDAKBggrBgEFBQcDAzAYBgwrBgEEAY9bAoJ4AQMECDAGAgEBCgEAMAoGCCqGSM49\nBAMCA2gAMGUCMFfNidGo6uK6KGT9zT1T5bY1NCHTH3P3muy5X1xudOgxWoOqIbnk\ntmQYB78dxWEHLQIxANfApAlXAD /0hnyNC8RDzfLOPEeay6jU9FXJj3AoR90rwZpR\noN9sYD6Oks4VGRw6yQ==\n-----END CERTIFICATE-----\n",
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

   6. If the `.npmrc` configuration is not created in the `~/` directory, an error may be reported when building hap: Error: The hvigor depends on the npmrc file. Configure the npmrc file first. Please configure the npmrc file first in the user directory` Create the file `.npmrc` under ~/`. For this configuration, you can also refer to [Official Documentation](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config- 0000001052902427-V3), the edited content is as follows:

      ```
      registry=https://repo.huaweicloud.com/repository/npm/
      @ohos:registry=https://repo.harmonyos.com/npm/
      ```
   
   For the configuration of all the above environment variables, please refer to the following example (Please replace user and specific code path with the actual path. For Windows environment, please set environment variables in Environment Variables Dialog):

```
#flutter env start ===>

# Domestic mirror
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

#flutter
export FLUTTER_HOME=/home/<user>/code/flutter/gitlab/flutter
export PATH=$PATH:$FLUTTER_HOME/bin

export PATH=/home/<user>/ohos/flutter_flutter/bin:$PATH
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

#ohpm
export OHPM_HOME=/home/<user>/ohos/oh-command-line-tools/ohpm/
export PATH=$PATH:$OHPM_HOME/bin
#sdkmanager
export PATH=/home/<user>/ohos/oh-command-line-tools/sdkmanager/bin:$PATH

# sdk and hdc
export OHOS_SDK_HOME=/home/<user>/env/sdk
export HDC_HOME=/home/<user>/env/sdk/10/toolchains
export PATH=$PATH:$HDC_HOME
# for HarmonyOS sdk
export HOS_SDK_HOME=/home/<user>/env/{HarmonyOS sdk}

# Signature tool
export SIGN_TOOL_HOME=/home/<user>/ohos/developtools_hapsigner/autosign

# grade
export PATH=/home/<user>/env/gradle-7.1/bin:$PATH
#nodejs
export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
export PATH=$NODE_HOME/bin:$PATH

#flutter env end <===
```

- Construct

1. Run `flutter doctor -v` to check whether the environment variable configuration is correct. **Futter** and **Openharmony** should both be ok. If the two prompts indicate that the environment is missing, just follow the prompts to fill in the corresponding environment.

2. Create the project and compile the command. The compiled product is under flutter_demo/ohos/entry/build/default/outputs/default/entry-default-signed.hap.

    ```
    # Create project
    flutter create --platforms ohos flutter_demo
    # Enter the project root directory to compile
    flutter build hap --local-engine-src-path /home/<user>/ohos/engine/src --local-engine ohos_release_arm64
    ```

3. After flutter devices discover the ohos device, use `hdc -t <deviceId> install <hap file path>` to install it.

## About how to connect and debug OpenHarmony devices for Linux virtual machines under Windows

* Problem: Linux virtual machine cannot directly discover OpenHarmony devices through hdc
* Solution: In the Windows host, open the hdc server. The specific instructions are as follows:
```
hdc kill
hdc -s serverIP:8710 -m
```
Configure environment variables in linux:
```
HDC_SERVER=<serverIP>
HDC_SERVER_PORT=8710
```

After the configuration is completed, the flutter sdk can complete the device connection through the hdc server. You can also refer to [official guidance](https://docs.openharmony.cn/pages/v4.0/zh-cn/device-dev/subsystems/subsys-toolchain -hdc-guide.md/#hdc-client%E5%A6%82%E4%BD%95%E8%BF%9C%E7%A8%8B%E8%AE%BF%E9%97%AEhdc-server)

## Compatible command list developed by OpenHarmony:
| Command name | Command description | Instructions for use |
| ------- | ------- |---------------------------------- ----------------------------------|
| doctor | environment detection | flutter doctor |
| config | environment configuration | flutter config --\<key\> \<value\> |
| create | Create a new project | flutter create --platforms ohos,android --org \<org\> \<appName\> |
| devices | Connected device discovery | flutter devices |
| install | application installation | flutter install -t \<deviceId\> \<hap file path\> |
| assemble | resource packaging | flutter assemble |
| build | Test application build | flutter build hap --target-platform ohos-arm64 --debug --local-engine=\<debug engine product path compatible with ohos\> |
| build | Formal application build | flutter build hap --target-platform ohos-arm64 --release --local-engine=\<ohos-compatible release engine product path\> |
| run | application run | flutter run --local-engine=\<ohos-compatible engine product path\> |
| attach | debug mode | flutter attach |
| screenshot | catch screen | flutter screenshot                    |

Prompt: [Flutter third-party library adaptation plan](https://docs.qq.com/sheet/DVVJDWWt1V09zUFN2)

## common problem:

1. Recommended ohos sdk version: `4.0.10.3`, which can be downloaded around August 20 when it is built daily. If there are problems related to the SDK version during the compilation process, you can try to replace this version of the SDK.

2. If an error message appears: `The SDK license agreement is not accepted`, please execute the following command and compile again:

    ```
    ./ohsdkmgr install ets:9 js:9 native:9 previewer:9 toolchains:9 --sdk-directory='/home/xc/code/sdk/ohos-sdk/' --accept-license
    ```

3. After switching between debug and release compilation modes, an error may be reported during operation. You can try deleting the oh_modules cache file and recompiling.

4. If `flutter docker -v` prompts that ohpm cannot be found, but the environment variables are detected correctly, please ensure that you have executed the `ohpm/bin/init` command to install ohpm and check again.

5. If you encounter the error Unsupported class file major version 61 when compiling the signature tool, it means that the current JDK version does not support it. You can command to display all JDK versions in the current system and select the required version. Enter the number and confirm the selection to compile again.

    ```
    sudo update-alternatives --config java
    ```

6. If you are using the Beta version of DevEco Studio and encounter the error "must have required property 'compatibleSdkVersion', location: demo/ohos/build-profile.json5:17:11" when compiling the project, please refer to "DevEco Studio" Modify the hvigor/hvigor-config.json5 file in the '6 Creating Projects and Running Hello World' [Configuration Plug-in] chapter in "Environment Configuration Guide.docx".

7. If an installation error is prompted: `fail to verify pkcs7 file`, please execute 

   ```
   hdc shell param set persist.bms.ohCert.verify true
   ```