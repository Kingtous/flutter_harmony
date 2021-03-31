// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'keyboard_key.dart';
import 'keyboard_maps.dart';
import 'raw_keyboard.dart';

/// Maps iOS specific string values of nonvisible keys to logical keys
///
/// See: https://developer.apple.com/documentation/uikit/uikeycommand/input_strings_for_special_keys?language=objc
const Map<String, LogicalKeyboardKey> _kIosToLogicalMap = <String, LogicalKeyboardKey>{
  'UIKeyInputEscape': LogicalKeyboardKey.escape,
  'UIKeyInputF1': LogicalKeyboardKey.f1,
  'UIKeyInputF2': LogicalKeyboardKey.f2,
  'UIKeyInputF3': LogicalKeyboardKey.f3,
  'UIKeyInputF4': LogicalKeyboardKey.f4,
  'UIKeyInputF5': LogicalKeyboardKey.f5,
  'UIKeyInputF6': LogicalKeyboardKey.f6,
  'UIKeyInputF7': LogicalKeyboardKey.f7,
  'UIKeyInputF8': LogicalKeyboardKey.f8,
  'UIKeyInputF9': LogicalKeyboardKey.f9,
  'UIKeyInputF10': LogicalKeyboardKey.f10,
  'UIKeyInputF11': LogicalKeyboardKey.f11,
  'UIKeyInputF12': LogicalKeyboardKey.f12,
  'UIKeyInputUpArrow': LogicalKeyboardKey.arrowUp,
  'UIKeyInputDownArrow': LogicalKeyboardKey.arrowDown,
  'UIKeyInputLeftArrow': LogicalKeyboardKey.arrowLeft,
  'UIKeyInputRightArrow': LogicalKeyboardKey.arrowRight,
  'UIKeyInputHome': LogicalKeyboardKey.home,
  'UIKeyInputEnd': LogicalKeyboardKey.enter,
  'UIKeyInputPageUp': LogicalKeyboardKey.pageUp,
  'UIKeyInputPageDown': LogicalKeyboardKey.pageDown,
};
/// Platform-specific key event data for iOS.
///
/// This object contains information about key events obtained from iOS'
/// `UIKey` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataIos extends RawKeyEventData {
  /// Creates a key event data structure specific for iOS.
  ///
  /// The [characters], [charactersIgnoringModifiers], and [modifiers], arguments
  /// must not be null.
  const RawKeyEventDataIos({
    this.characters = '',
    this.charactersIgnoringModifiers = '',
    this.keyCode = 0,
    this.modifiers = 0,
  }) : assert(characters != null),
       assert(charactersIgnoringModifiers != null),
       assert(keyCode != null),
       assert(modifiers != null);

  /// The Unicode characters associated with a key-up or key-down event.
  ///
  /// See also:
  ///
  ///  * [Apple's UIKey documentation](https://developer.apple.com/documentation/uikit/uikey/3526130-characters?language=objc)
  final String characters;

  /// The characters generated by a key event as if no modifier key (except for
  /// Shift) applies.
  ///
  /// See also:
  ///
  ///  * [Apple's UIKey documentation](https://developer.apple.com/documentation/uikit/uikey/3526131-charactersignoringmodifiers?language=objc)
  final String charactersIgnoringModifiers;

  /// The virtual key code for the keyboard key associated with a key event.
  ///
  /// See also:
  ///
  ///  * [Apple's UIKey documentation](https://developer.apple.com/documentation/uikit/uikey/3526132-keycode?language=objc)
  final int keyCode;

  /// A mask of the current modifiers using the values in Modifier Flags.
  ///
  /// See also:
  ///
  ///  * [Apple's UIKey documentation](https://developer.apple.com/documentation/uikit/uikey/3526133-modifierflags?language=objc)
  final int modifiers;

  @override
  String get keyLabel => charactersIgnoringModifiers;

  @override
  PhysicalKeyboardKey get physicalKey => kIosToPhysicalKey[keyCode] ?? PhysicalKeyboardKey.none;


  @override
  LogicalKeyboardKey get logicalKey {
    // Look to see if the keyCode is a printable number pad key, so that a
    // difference between regular keys (e.g. "=") and the number pad version
    // (e.g. the "=" on the number pad) can be determined.
    final LogicalKeyboardKey? numPadKey = kIosNumPadMap[keyCode];
    if (numPadKey != null) {
      return numPadKey;
    }

    // Look to see if the [keyLabel] is one we know about and have a mapping for.
    final LogicalKeyboardKey? newKey = _kIosToLogicalMap[keyLabel];
    if (newKey != null) {
      return newKey;
    }
    // If this key is printable, generate the LogicalKeyboardKey from its
    // Unicode value. Control keys such as ESC, CRTL, and SHIFT are not
    // printable. HOME, DEL, arrow keys, and function keys are considered
    // modifier function keys, which generate invalid Unicode scalar values.
    if (keyLabel.isNotEmpty &&
        !LogicalKeyboardKey.isControlCharacter(keyLabel)) {
      // Given that charactersIgnoringModifiers can contain a String of
      // arbitrary length, limit to a maximum of two Unicode scalar values. It
      // is unlikely that a keyboard would produce a code point bigger than 32
      // bits, but it is still worth defending against this case.
      assert(charactersIgnoringModifiers.length <= 2);
      int codeUnit = charactersIgnoringModifiers.codeUnitAt(0);
      if (charactersIgnoringModifiers.length == 2) {
        final int secondCode = charactersIgnoringModifiers.codeUnitAt(1);
        codeUnit = (codeUnit << 16) | secondCode;
      }

      final int keyId = LogicalKeyboardKey.unicodePlane | (codeUnit & LogicalKeyboardKey.valueMask);
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(
        keyId,
        keyLabel: keyLabel,
        debugName: kReleaseMode ? null : 'Key ${keyLabel.toUpperCase()}',
      );
    }

    // Control keys like "backspace" and movement keys like arrow keys don't
    // have a printable representation, but are present on the physical
    // keyboard. Since there is no logical keycode map for iOS (iOS uses the
    // keycode to reference physical keys), a LogicalKeyboardKey is created with
    // the physical key's HID usage and debugName. This avoids duplicating the
    // physical key map.
    if (physicalKey != PhysicalKeyboardKey.none) {
      final int keyId = physicalKey.usbHidUsage | LogicalKeyboardKey.hidPlane;
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(
        keyId,
        keyLabel: physicalKey.debugName ?? '',
        debugName: physicalKey.debugName,
      );
    }

    // This is a non-printable key that is unrecognized, so a new code is minted
    // with the autogenerated bit set.
    const int iosKeyIdPlane = 0x00400000000;

    return LogicalKeyboardKey(
      iosKeyIdPlane | keyCode | LogicalKeyboardKey.autogeneratedMask,
      debugName: kReleaseMode ? null : 'Unknown iOS key code $keyCode',
    );
  }

  bool _isLeftRightModifierPressed(KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (modifiers & anyMask == 0) {
      return false;
    }
    // If only the "anyMask" bit is set, then we respond true for requests of
    // whether either left or right is pressed. Handles the case where iOS
    // supplies just the "either" modifier flag, but not the left/right flag.
    // (e.g. modifierShift but not modifierLeftShift).
    final bool anyOnly = modifiers & (leftMask | rightMask | anyMask) == anyMask;
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.all:
        return modifiers & leftMask != 0 && modifiers & rightMask != 0 || anyOnly;
      case KeyboardSide.left:
        return modifiers & leftMask != 0 || anyOnly;
      case KeyboardSide.right:
        return modifiers & rightMask != 0 || anyOnly;
    }
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    final int independentModifier = modifiers & deviceIndependentMask;
    bool result;
    switch (key) {
      case ModifierKey.controlModifier:
        result = _isLeftRightModifierPressed(side, independentModifier & modifierControl, modifierLeftControl, modifierRightControl);
        break;
      case ModifierKey.shiftModifier:
        result = _isLeftRightModifierPressed(side, independentModifier & modifierShift, modifierLeftShift, modifierRightShift);
        break;
      case ModifierKey.altModifier:
        result = _isLeftRightModifierPressed(side, independentModifier & modifierOption, modifierLeftOption, modifierRightOption);
        break;
      case ModifierKey.metaModifier:
        result = _isLeftRightModifierPressed(side, independentModifier & modifierCommand, modifierLeftCommand, modifierRightCommand);
        break;
      case ModifierKey.capsLockModifier:
        result = independentModifier & modifierCapsLock != 0;
        break;
    // On iOS, the function modifier bit is set for any function key, like F1,
    // F2, etc., but the meaning of ModifierKey.modifierFunction in Flutter is
    // that of the Fn modifier key, so there's no good way to emulate that on
    // iOS.
      case ModifierKey.functionModifier:
      case ModifierKey.numLockModifier:
      case ModifierKey.symbolModifier:
      case ModifierKey.scrollLockModifier:
        // These modifier masks are not used in iOS keyboards.
        result = false;
        break;
    }
    assert(!result || getModifierSide(key) != null, "$runtimeType thinks that a modifier is pressed, but can't figure out what side it's on.");
    return result;
  }

  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    KeyboardSide? findSide(int anyMask, int leftMask, int rightMask) {
      final int combinedMask = leftMask | rightMask;
      final int combined = modifiers & combinedMask;
      if (combined == leftMask) {
        return KeyboardSide.left;
      } else if (combined == rightMask) {
        return KeyboardSide.right;
      } else if (combined == combinedMask || modifiers & (combinedMask | anyMask) == anyMask) {
        // Handles the case where iOS supplies just the "either" modifier
        // flag, but not the left/right flag. (e.g. modifierShift but not
        // modifierLeftShift), or if left and right flags are provided, but not
        // the "either" modifier flag.
        return KeyboardSide.all;
      }
      return null;
    }

    switch (key) {
      case ModifierKey.controlModifier:
        return findSide(modifierControl, modifierLeftControl, modifierRightControl);
      case ModifierKey.shiftModifier:
        return findSide(modifierShift, modifierLeftShift, modifierRightShift);
      case ModifierKey.altModifier:
        return findSide(modifierOption, modifierLeftOption, modifierRightOption);
      case ModifierKey.metaModifier:
        return findSide(modifierCommand, modifierLeftCommand, modifierRightCommand);
      case ModifierKey.capsLockModifier:
      case ModifierKey.numLockModifier:
      case ModifierKey.scrollLockModifier:
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        return KeyboardSide.all;
    }
  }

  // Modifier key masks. See Apple's UIKey documentation
  // https://developer.apple.com/documentation/uikit/uikeymodifierflags?language=objc
  // https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-86/IOHIDSystem/IOKit/hidsystem/IOLLEvent.h.auto.html

  /// This mask is used to check the [modifiers] field to test whether the CAPS
  /// LOCK modifier key is on.
  ///
  /// {@template flutter.services.RawKeyEventDataIos.modifierCapsLock}
  /// Use this value if you need to decode the [modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if
  /// a modifier is pressed.
  /// {@endtemplate}
  static const int modifierCapsLock = 0x10000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// SHIFT modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierShift = 0x20000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierLeftShift = 0x02;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierRightShift = 0x04;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierControl = 0x40000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierLeftControl = 0x01;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierRightControl = 0x2000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierOption = 0x80000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierLeftOption = 0x20;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierRightOption = 0x40;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierCommand = 0x100000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierLeftCommand = 0x08;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierRightCommand = 0x10;

  /// This mask is used to check the [modifiers] field to test whether any key in
  /// the numeric keypad is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierNumericPad = 0x200000;

  /// This mask is used to check the [modifiers] field to test whether the
  /// HELP modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierHelp = 0x400000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// FUNCTION modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataIos.modifierCapsLock}
  static const int modifierFunction = 0x800000;

  /// Used to retrieve only the device-independent modifier flags, allowing
  /// applications to mask off the device-dependent modifier flags, including
  /// event coalescing information.
  static const int deviceIndependentMask = 0xffff0000;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RawKeyEventDataIos')}(keyLabel: $keyLabel, keyCode: $keyCode, characters: $characters,'
        ' unmodifiedCharacters: $charactersIgnoringModifiers, modifiers: $modifiers, '
        'modifiers down: $modifiersPressed)';
  }
}
