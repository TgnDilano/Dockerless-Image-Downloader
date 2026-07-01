import 'dart:convert';
import 'package:crypto/crypto.dart';

String computeLayerId(String? parentId, String layerDigest) {
  final input = '${parentId ?? ''}\n$layerDigest';
  final bytes = utf8.encode(input);
  return 'sha256:${sha256.convert(bytes).toString()}';
}
