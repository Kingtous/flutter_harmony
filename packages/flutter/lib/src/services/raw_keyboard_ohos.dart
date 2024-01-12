/*
* Copyright (c) 2024 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import 'keyboard_maps.g.dart';
import 'raw_keyboard.dart';

/// key对象
class KeyObj {
  /// 构造
  KeyObj(this.code, this.pressedTime, this.deviceId);

  /// 按键码
  int code;

  /// 按键按下时间
  int pressedTime;

  /// 设备id
  int deviceId;
}

/// 从map转换成一个keyObj
KeyObj transformKey(Map<String, Object?> map) {
  return KeyObj(map['code'] as int? ?? 0, map['pressedTime'] as int? ?? 0,
      map['deviceId'] as int? ?? 0);
}

/// 从message转换出一个RawKeyEventDataOhos对象
RawKeyEventDataOhos transformMessage(Map<String, Object?> message) {
  final Map<String, Object?> keyObjMap =
      message['key'] as Map<String, Object?>? ??
          {'code': 0, 'pressedTime': 0, 'deviceId': 0};
  final KeyObj keyObj = transformKey(keyObjMap);
  final List<Map<String, Object?>> keysMap =
      message['keys'] as List<Map<String, Object?>>? ??
          List<Map<String, Object?>>.empty();
  final List<KeyObj> keys =
      keysMap.map((Map<String, Object?> e) => transformKey(e)).toList();
  return RawKeyEventDataOhos(
    keyObj,
    keys,
    action: message['action'] as int? ?? 0,
    unicodeChar: message['unicodeChar'] as int? ?? 0,
    ctrlKey: message['ctrlKey'] as bool? ?? false,
    altKey: message['altKey'] as bool? ?? false,
    shiftKey: message['shiftKey'] as bool? ?? false,
    logoKey: message['logoKey'] as bool? ?? false,
    fnKey: message['fnKey'] as bool? ?? false,
    capsLock: message['capsLock'] as bool? ?? false,
    numLock: message['numLock'] as bool? ?? false,
    scrollLock: message['scrollLock'] as bool? ?? false,
  );
}

/// RawKeyEventData for OpenHarmony platform
class RawKeyEventDataOhos extends RawKeyEventData {
  /// Constructor
  RawKeyEventDataOhos(
    this.key,
    this.keys, {
    this.action = 0,
    this.unicodeChar = 0,
    this.ctrlKey = false,
    this.altKey = false,
    this.shiftKey = false,
    this.logoKey = false,
    this.fnKey = false,
    this.capsLock = false,
    this.numLock = false,
    this.scrollLock = false,
  });

  /// 按键动作 0按键取消，1按键按下，2按键抬起
  int action;

  /// 当前上报的按键
  KeyObj key;

  /// 按键对应的uniCode字符
  int unicodeChar;

  /// 当前处于按下状态的按键列表
  List<KeyObj> keys;

  /// 当前ctrlKey是否处于按下状态 ture表示处于按下状态，false表示处于抬起状态。
  bool ctrlKey;

  /// 	当前altKey是否处于按下状态 ture表示处于按下状态，false表示处于抬起状态。
  bool altKey;

  /// 当前shiftKey是否处于按下状态 ture表示处于按下状态，false表示处于抬起状态。
  bool shiftKey;

  ///当前logoKey是否处于按下状态 ture表示处于按下状态，false表示处于抬起状态。
  bool logoKey;

  /// 当前fnKey是否处于按下状态 ture表示处于按下状态，false表示处于抬起状态。
  bool fnKey;

  /// 当前capsLock是否处于激活状态 ture表示处于激活状态，false表示处于未激活状态。
  bool capsLock;

  /// 当前numLock是否处于激活状态 ture表示处于激活状态，false表示处于未激活状态。
  bool numLock;

  /// 当前scrollLock是否处于激活状态 ture表示处于激活状态，false表示处于未激活状态。
  bool scrollLock;

  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    /// todo 根据key值判断修饰键方向
    return KeyboardSide.all;
  }

  @override
  bool isModifierPressed(ModifierKey key,
      {KeyboardSide side = KeyboardSide.any}) {
    return ctrlKey |
        altKey |
        shiftKey |
        logoKey |
        fnKey |
        capsLock |
        numLock |
        scrollLock;
  }

  @override
  String get keyLabel =>
      unicodeChar == 0 ? '' : String.fromCharCode(unicodeChar);

  @override
  LogicalKeyboardKey get logicalKey {
    if (kOhosToLogicalKey.containsKey(key.code)) {
      return kOhosToLogicalKey[key.code]!;
    }
    return LogicalKeyboardKey(key.code | LogicalKeyboardKey.ohosPlane);
  }

  @override
  PhysicalKeyboardKey get physicalKey {
    if (kOhosToPhysicalKey.containsKey(key.code)) {
      return kOhosToPhysicalKey[key.code]!;
    }
    return PhysicalKeyboardKey(key.code + LogicalKeyboardKey.ohosPlane);
  }
}
