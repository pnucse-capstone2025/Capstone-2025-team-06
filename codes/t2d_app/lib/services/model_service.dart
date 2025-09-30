import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// Change this if your server isn't local:
const String baseUrl = "http://127.0.0.1:8000";

Future<Map<String, dynamic>> predictTabular(String modelId, Map<String, dynamic> features) async {
  final payload = {
    "model_id": modelId,
    "context": {"user_id": "demo", "patient_id": "TEST"},
    "features": features
  };
  final res = await http.post(
    Uri.parse("$baseUrl/predict/tabular"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
  if (res.statusCode != 200) {
    throw Exception("Tabular prediction failed: ${res.body}");
  }
  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> predictImage(String modelId, Uint8List bytes, String filename) async {
  final req = http.MultipartRequest("POST", Uri.parse("$baseUrl/predict/image?model_id=$modelId"));
  req.files.add(http.MultipartFile.fromBytes("file", bytes, filename: filename));
  final streamed = await req.send();
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode != 200) {
    throw Exception("Image prediction failed: ${response.body}");
  }
  return jsonDecode(response.body);
}
