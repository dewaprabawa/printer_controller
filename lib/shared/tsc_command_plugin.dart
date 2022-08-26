import 'dart:typed_data';

import 'package:flutter/services.dart';

class TscCommandPlugin {
  static const _channel = const MethodChannel('com.klopos/tsc_command');

  static Future<Uint8List?> getRawBytes(
      List<String> printList, int width, int height) async {
    Map<String, dynamic> params = {
      'list': printList,
      'width': width,
      'height': height,
    };
    final Uint8List rawBytes =
        await _channel.invokeMethod('mapToLabel', params);
    return rawBytes;
  }
}
