import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'check_service.dart'; // 시선 분석 서비스
import 'answer_service.dart'; // 대사 분석 서비스
import 'openai_service.dart'; // OpenAI 서비스 추가

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String question;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.question,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late CheckService _checkService;
  late AnswerService _answerService;
  late OpenAIService _openAIService;

  String _status = "시선 분석 중...";
  String _speechAnalysis = "대사 분석 중...";
  String _answerFeedback = "답변 분석 중...";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkService = CheckService();
    _answerService = AnswerService();
    _openAIService = OpenAIService();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _checkService.dispose();
    super.dispose();
  }

  /// 비디오 플레이어 초기화
  void _initializeVideoPlayer() {
  _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
    ..initialize().then((_) async {
      if (!mounted) return;
      setState(() {});
      _controller.play();

      print("Debug: Starting processVideo");
      await _processVideo();

      print("Debug: Starting analyzeSpeech");
      await _analyzeSpeech();

      print("Debug: Starting analyzeAnswer");
      await _analyzeAnswer();
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _status = "Failed to initialize video player: $error";
      });
    });
}


  /// 시선 분석 처리
  Future<void> _processVideo() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final framesPath = await _checkService.extractFrames(widget.videoUrl);
      final frames = await _checkService.analyzeFrames(framesPath);

      if (!mounted) return; // mounted 확인
      if (frames.isNotEmpty) {
        final feedback = await _checkService.sendToFlaskAPI(frames);
        if (!mounted) return; // mounted 확인
        setState(() {
          _status = feedback;
        });
      } else {
        if (!mounted) return; // mounted 확인
        setState(() {
          _status = "영상에서 얼굴을 인식할 수 없습니다.";
        });
      }
    } catch (e) {
      if (!mounted) return; // mounted 확인
      setState(() {
        _status = "시선 분석 중 오류 발생: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 대사 분석 처리
  Future<void> _analyzeSpeech() async {
    setState(() => _speechAnalysis = "대사 분석 중...");

    try {
      final transcript = await _answerService.processVideo(widget.videoUrl);
      if (!mounted) return; // mounted 확인
      setState(() {
        _speechAnalysis = transcript;
      });
    } catch (e) {
      if (!mounted) return; // mounted 확인
      setState(() {
        _speechAnalysis = "대사 분석 오류 발생: $e";
      });
    }
  }

  /// 답변 분석 처리
  Future<void> _analyzeAnswer() async {
    setState(() => _answerFeedback = "답변 분석 중...");

    try {
    // 디버그: 입력 데이터 출력
    print("Debug: Question passed to analyzeAnswer: ${widget.question}");
    print("Debug: Speech analysis result passed as Answer: $_speechAnalysis");

    final feedback = await _openAIService.evaluateAnswer(
      question: widget.question,
      answer: _speechAnalysis,
    );

    if (!mounted) return; // mounted 확인

    // 디버그: Flask 서버에서 반환된 피드백 확인
    print("Debug: Feedback received from Flask API: $feedback");

    setState(() {
      _answerFeedback = feedback;
    });
  } catch (e) {
    if (!mounted) return; // mounted 확인

    // 디버그: 에러 메시지 출력
    print("Debug: Error during answer analysis: $e");

    setState(() {
      _answerFeedback = "답변 분석 오류 발생: $e";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피드백'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade800,
      ),
      body: Column(
        children: [
          if (_controller.value.isInitialized)
            Expanded(
              flex: 3,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('분석 결과'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '1. 시선 분석 결과:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _status,
                                  style: const TextStyle(fontSize: 16, height: 1.6),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '2. 대사 분석 결과:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _speechAnalysis,
                                  style: const TextStyle(fontSize: 16, height: 1.6),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '3. 답변 분석 결과:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _answerFeedback,
                                  style: const TextStyle(fontSize: 16, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('닫기'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('분석 결과 보기'),
                ),
                const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }
}
