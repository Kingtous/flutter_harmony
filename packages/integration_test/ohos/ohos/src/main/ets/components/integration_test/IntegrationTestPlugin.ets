/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
 
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import UIAbility from '@ohos.app.ability.UIAbility';
import MethodChannel, { MethodCallHandler, MethodResult} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { FlutterDeviceScreenshot } from './FlutterDeviceScreenshot';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG = "IntegrationTestPlugin"

export default class IntegrationTestPlugin implements MethodCallHandler, FlutterPlugin, AbilityAware {
  private static CHANNEL: string = "plugins.flutter.io/integration_test";
  private methodChannel: MethodChannel | null = null;
  private flutterAbility: UIAbility | null = null;
  private static testResultsSetter: Set<Map<String, String>>;

  getUniqueClassName(): string {
    return 'IntegrationTestPlugin';
  }

  private methodCall: MethodCallHandler = {
    onMethodCall(call: MethodCall, result: MethodResult) {
      Log.w(TAG, 'flutter onMethodCall: 11 ' + JSON.stringify(call));
      switch (call.method) {
        case "allTestsFinished":
          IntegrationTestPlugin.testResultsSetter.add(call.argument("results"));
          result.success(null);
          return;
        case "captureScreenshot":
        case "convertFlutterSurfaceToImage":
        case "revertFlutterImage":
        default:
          result.notImplemented();
      }
    }
  };

  private attachedToEngine( unusedApplicationContext: Context,  messenger: BinaryMessenger): void {
    Log.w(TAG, 'flutter IntegrationTestPlugin attachedToEngine');
    this.methodChannel = new MethodChannel(messenger, IntegrationTestPlugin.CHANNEL);
    this.methodChannel.setMethodCallHandler(this.methodCall);
  }

  onAttachedToEngine(binding: FlutterPluginBinding) {
    this.attachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  onMethodCall(call: MethodCall, result: MethodResult) {
    Log.w(TAG, 'flutter onMethodCall:' + JSON.stringify(call));
    switch (call.method) {
      case "allTestsFinished":
        IntegrationTestPlugin.testResultsSetter.add(call.argument("results"));
        result.success(null);
        return;
      case "convertFlutterSurfaceToImage":
      case "revertFlutterImage":
      case "captureScreenshot":
      default:
        result.notImplemented();
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding) {
    Log.w(TAG, 'flutter IntegrationTestPlugin onDetachedFromEngine');
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    Log.w(TAG, 'flutter IntegrationTestPlugin onAttachedToAbility');
    this.flutterAbility = binding.getAbility();
  }

  onDetachedFromAbility() {
    Log.w(TAG, 'flutter IntegrationTestPlugin onDetachedFromAbility');
    this.flutterAbility = null;
  }
}