import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((e) {
        print("Error playing video: $e");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Center(
          child: _controller.value.isInitialized
              ? Column(
                  children: [
                    // 동영상 위치를 상단으로 고정
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    if (_showControls)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: Colors.deepPurple,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stop, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _controller.pause();
                                      _controller.seekTo(Duration.zero);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
