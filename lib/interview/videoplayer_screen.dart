import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late FaceDetector _faceDetector;
  String _status = "Processing video...";
  List<Map<String, dynamic>> _detectedFrames = [];
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
      ),
    );
  }

  void _initializeVideoPlayer() {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          _processVideo();
        }).catchError((error) {
          setState(() {
            _status = "Failed to initialize video player.";
          });
        });
    } catch (e) {
      setState(() {
        _status = "An error occurred during initialization.";
      });
    }
  }

  Future<void> _processVideo() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = "${tempDir.path}/frames";

      await _extractFrames(widget.videoUrl, outputPath);

      final framesDir = Directory(outputPath);
      if (!framesDir.existsSync()) {
        setState(() {
          _status = "Failed to extract frames.";
        });
        return;
      }

      final frameFiles = framesDir.listSync().where((file) => file.path.endsWith('.png'));

      for (var frame in frameFiles) {
        final image = InputImage.fromFilePath(frame.path);
        final faces = await _faceDetector.processImage(image);

        if (faces.isNotEmpty) {
          final face = faces.first;

          final smileProb = face.smilingProbability ?? 0.0;
          final emotion = smileProb > 0.5 ? "Happy" : "Neutral";

          final leftEye = face.landmarks[FaceLandmarkType.leftEye];
          final rightEye = face.landmarks[FaceLandmarkType.rightEye];
          String gazeStatus = "Unknown";
          if (leftEye != null && rightEye != null) {
            gazeStatus = leftEye.position.y < rightEye.position.y
                ? "Looking Away"
                : "Focused";
          }

          _detectedFrames.add({
            "frame": frame.path.split("_").last.split(".").first,
            "emotion": emotion,
            "gaze": gazeStatus,
          });
        }
      }

      setState(() {
        //_status = "Processing completed. Faces detected in ${_detectedFrames.length} frames.";
      });

      if (_detectedFrames.isNotEmpty) {
        await _sendToSpeakAPI();
      } else {
        setState(() {
          _status = "No faces detected in the video.";
        });
      }
    } catch (e) {
      setState(() {
        _status = "An error occurred during video processing.";
      });
    }
  }

  Future<void> _extractFrames(String videoPath, String outputPath) async {
    await Directory(outputPath).create(recursive: true);
    final command = '-i $videoPath -vf fps=1 $outputPath/frame_%03d.png';
    await FFmpegKit.execute(command);
  }

  Future<void> _sendToSpeakAPI() async {
    const String flaskEndpoint = "http://223.194.139.51:5000/analyze-speech";

    final requestData = {
      "frames": _detectedFrames.map((frame) {
        return {
          "frame": frame["frame"],
          "emotion": frame["emotion"],
          "gaze": frame["gaze"],
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(flaskEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final feedback = responseData["feedback"];
        setState(() {
          _status = feedback;
        });
      } else {
        setState(() {
          _status = "Flask API Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _status = "An error occurred while sending data to Flask API.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          const SizedBox(height: 10),
          Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100.0), // 양옆과 위아래 여백 추가
    child: SingleChildScrollView(
      child: Text(
        _status,
        softWrap: true, // 단어를 자동으로 줄바꿈
        textAlign: TextAlign.justify, // 텍스트 정렬
        style: const TextStyle(
          fontSize: 18, // 폰트 크기 (조금 줄임)
          color: Colors.black, // 텍스트 색상
          height: 1.6, // 줄 간격 조절
        ),
      ),
    ),
  ),
),

          Column(
            children: [
              VideoProgressIndicator(_controller, allowScrubbing: true),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: () {
                      _controller.seekTo(Duration.zero);
                      _controller.play();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
