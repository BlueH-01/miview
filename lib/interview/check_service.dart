import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;

class CheckService {
  late FaceDetector _faceDetector;

  CheckService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
      ),
    );
  }

  /// 프레임 추출
  Future<String> extractFrames(String videoUrl) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String outputPath = "${tempDir.path}/frames";
    await Directory(outputPath).create(recursive: true);

    final command = '-i $videoUrl -vf fps=1 $outputPath/frame_%03d.png';
    await FFmpegKit.execute(command);

    return outputPath;
  }

  /// 프레임 분석
  Future<List<Map<String, dynamic>>> analyzeFrames(String framesPath) async {
    final Directory framesDir = Directory(framesPath);
    if (!framesDir.existsSync()) {
      throw Exception("Failed to extract frames.");
    }

    final frameFiles = framesDir.listSync().where((file) => file.path.endsWith('.png'));
    final List<Map<String, dynamic>> detectedFrames = [];

    for (var frame in frameFiles) {
      final image = InputImage.fromFilePath(frame.path);
      final faces = await _faceDetector.processImage(image);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final smileProb = face.smilingProbability ?? 0.0;
        final emotion = smileProb > 0.5 ? "Happy" : "Neutral";

        final leftEye = face.landmarks[FaceLandmarkType.leftEye];
        final rightEye = face.landmarks[FaceLandmarkType.rightEye];
        final gazeStatus = (leftEye != null && rightEye != null && leftEye.position.y < rightEye.position.y)
            ? "Looking Away"
            : "Focused";

        detectedFrames.add({
          "frame": frame.path.split("_").last.split(".").first,
          "emotion": emotion,
          "gaze": gazeStatus,
        });
      }
    }

    return detectedFrames;
  }

  /// 분석 결과를 Flask API에 전송
  Future<String> sendToFlaskAPI(List<Map<String, dynamic>> detectedFrames) async {
    const String flaskEndpoint = "http://192.168.200.104:5000/analyze-speech";

    final requestData = {"frames": detectedFrames};

    try {
      final response = await http.post(
        Uri.parse(flaskEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData["feedback"] ?? "No feedback provided.";
      } else {
        throw Exception("Flask API Error: ${response.body}");
      }
    } catch (e) {
      throw Exception("An error occurred while sending data to Flask API: $e");
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
