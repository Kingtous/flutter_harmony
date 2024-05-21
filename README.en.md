Flutter SDK repository
==============

Original warehouse source: https://github.com/flutter/flutter

## Warehouse description
This repository is a compatible extension of Flutter SDK for the OpenHarmony platform, and can support IDE or terminal use of Flutter Tools instructions to compile and build OpenHarmony applications.

## Environment dependencies

* development system

   Flutter Tools commands are currently supported on Linux, Mac and Windows.

* Environment configuration

    **Please give priority to downloading the supporting development tools from [Hongmeng Kit List](https://developer.harmonyos.com/deveco-developer-suite/enabling/kit?currentPage=1&pageSize=100). Downloads from other channels are not currently supported. Kit**
    *The following environment variable configuration is for Unix-like systems (Linux, Mac). You can directly refer to the configuration below. For environment variable configuration under Windows, please set it in ‘Edit System Environment Variables’*

   1. Download OpenHarmony SDK and configure environment variables
   * API12, deveco-studio-5.0.0.300, command-line-tools-xxx.zip
   * The directory structure after decompression is as follows
      ```
      /command-line-tools
      ├── bin
      ├── codelinter
      ├── hstack
      ├── hvigor
      ├── ohpm
      ├── sdk/HarmonyOS-NEXT-DB1/openharmony
         ├── ets
         ├── js
         ├── native
         ├── previewer
         └── toolchains
      └── tool
      ```

    * Configure environment variables

       ```
       export HOS_SDK_HOME=/home/<user>/ohos/command-line-tool/sdk
       export PATH=/home/<user>/ohos/command-line-tools/bin:$PATH
       ```

   2. Download the current warehouse code `git clone https://gitee.com/openharmony-sig/flutter_flutter.git` through the code tool, and configure the environment

      ```
      export PATH=<flutter_flutter path>/bin:$PATH

      # Flutter pub domestic mirror
      export PUB_HOSTED_URL=https://pub.flutter-io.cn
      export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
      ```

    3. The application build relies on [Flutter Engine](https://github.com/flutter/engine) to build products: `ohos_debug_unopt_arm64` and `ohos_release_arm64`. Please add: `--local-engine= in the Flutter Tools command running parameters. --local-engine=src/out/<engine product directory\>`. Can be downloaded at this path [Compiled product](https://docs.qq.com/sheet/DUnljRVBYUWZKZEtF?tab=BB08J2)

       For the configuration of all the above environment variables (for environment variable configuration under Windows, please set it in 'Edit System Environment Variables'), you can refer to the following example (please replace user and specific code path with the actual path):

       ```
       # Domestic mirror
       export PUB_HOSTED_URL=https://pub.flutter-io.cn
       export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

       # The flutter_flutter directory pulled from Gitee
       export PATH=/home/<user>/ohos/flutter_flutter/bin:$PATH

       # HarmonyOS SDK
       export HOS_SDK_HOME=/home/<user>/ohos/command-line-tools/sdk
       export PATH=/home/<user>/ohos/command-line-tools/bin:$PATH

       # nodejs
       export NODE_HOME=/home/<user>/ohos/command-line-tools/tool/node
       export PATH=$NODE_HOME/bin:$PATH
       ```

## Build steps

1. Run `flutter doctor -v` to check whether the environment variable configuration is correct. **Futter** and **OpenHarmony** should both be ok. If the two prompts indicate that the environment is missing, just follow the prompts to fill in the corresponding environment.

2. Create the project and compile the command. The compiled product is under \<projectName\>/ohos/entry/build/default/outputs/default/entry-default-signed.hap.

    ```
    # Create project
    flutter create --platforms ohos <projectName>

    # Enter the project root directory to compile
    # Example: flutter build hap [--target-platform ohos-arm64] --local-engine=<DIR>/src/out/ohos_release_arm64 --release
   flutter build hap --local-engine=/home/user/engine_make/src/out/ohos_release_arm64 --release
    ```

3. After discovering the ohos device through the `flutter devices` command, use `hdc -t <deviceId> install <hap file path>` to install it.

4. You can also directly use the following command to run:
```
    # Example: flutter run --local-engine=<DIR>/src/out/ohos_debug_unopt_arm64
   flutter run --local-engine=/home/user/engine_make/src/out/ohos_debug_unopt_arm64 --debug
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