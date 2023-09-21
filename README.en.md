Flutter SDK repository
==============

Original warehouse source: https://github.com/flutter/flutter

## Warehouse description:
This warehouse is based on the compatible extension of flutter sdk for OpenHarmony, and can support the use of flutter tools instructions to compile and build OpenHarmony applications.

## Build instructions:

* Build environment:
Currently, the flutter tools command only supports use under Linux.

* Build dependencies:
To build products relying on [flutter engine](https://github.com/flutter/engine), please add: --local-engine=\<engine product directory\> to the running parameters of the flutter tools command.

*Building steps:
1. Please download [Command Line Tools for OpenHarmony](https://developer.harmonyos.com/cn/develop/deveco-studio#download_cli) first;

2. In the Command Line Tools download directory, find sdkmanager, refer to [ohsdkmgr usage guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohsdkmgr- 0000001545647965-V3) Download OpenHarmony sdk.
(PS: API 10 needs to download ohos-full-sdk from [Daily Build](http://ci.openharmony.cn/workbench/cicd/dailybuild/detail/component))
  Configure the OpenHarmony sdk path to the environment variable OHOS_SDK_HOME, for example: ~/.bashrc Add a new configuration export OHOS_SDK_HOME=\<sdk path\> (the root directory of the path contains 9 or 10 named api folders);

3. In the Command Line Tools download directory, configure the ohpm folder path as the environment variable OHPM_HOME, for example: export OHPM_HOME=\<parent path\>/oh-command-line-tools/ohpm, refer to the guidance document: [ohpm usage guide ](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/ide-command-line-ohpm-0000001490235312-V3), execute the ohpm/bin/init command to install ohpm;

4. Configure the signature tool environment variable SIGN_TOOL_HOME, for example: export SIGN_TOOL_HOME=\<developtools_hapsigner directory\>/autosign, download address: https://gitee.com/openharmony/developtools_hapsigner

The signing tool also requires the following configuration:
   * Refer to the readme of developtools_hapsigner, compile to get hap-sign-tool.jar, and make sure it is in the directory: ./hapsigntool/hap_sign_tool/build/libs/hap-sign-tool.jar
   * Enter the autosign folder, execute the command chmod 777 *.sh, and add the profile_tmp_template.json file, edit it as follows:
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
   * Edit autosign.config and createAppCertAndProfile.config, modify the value: sign.profile.inFile=profile_tmp.json

5. Configure \<current project directory\>/bin, go to the environment variable PATH, and ensure which flutter can find the \<flutter sdk\>/bin/flutter location;

6. Run flutter docker and check whether the environment variables are configured correctly;

7. Open vscode and install the flutter plug-in. If the flutter sdk is configured correctly, you can find the OpenHarmony connection device and run and debug the application on vscode.



## Compatible command list developed by OpenHarmony:
| Command name | Command description | Instructions for use |
| ------- | ------- |--------------------------------------------------------------------|
| doctor | environment detection | flutter doctor |
| config | environment configuration | flutter config --\<key\> \<value\> |
| create | Create a new project | flutter create --platforms ohos,android --org \<org\> \<appName\> |
| devices | Connected device discovery | flutter devices |
| install | application installation | flutter install |
| assemble | resource packaging | flutter assemble |
| build | Application build | flutter build hap --target-platform ohos-arm --debug true --local-engine=\<ohos-compatible engine product path\> |
| run | application run | flutter run --local-engine=\<ohos-compatible engine product path\> |
| attach | debug mode | flutter attach |