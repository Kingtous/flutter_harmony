// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

void main(FutureOr<void> testMain()) async {
  await runZoned<dynamic>(testMain, zoneValues: <Type, String>{
    String: '/test_config',
  });
}
