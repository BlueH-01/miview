import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/speech/v1.dart' as speech;

class AnswerService {
  final String _credentialsPath = 'assets/service_account.json';

  /// 동영상에서 오디오 추출
  Future<String?> extractAudio(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // 고유 파일 이름 생성 (타임스탬프 기반)
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final audioPath = '${tempDir.path}/audio_$uniqueId.wav';

      // 임시 디렉터리 정리
      _cleanTemporaryDirectory(tempDir);

      // FFmpeg로 오디오 추출 및 포맷 변환
      await FFmpegKit.execute(
          '-i $videoUrl -vn -acodec pcm_s16le -ar 16000 -ac 1 $audioPath');

      final audioFile = File(audioPath);
      if (audioFile.existsSync()) {
        return audioPath;
      } else {
        throw Exception("오디오 추출 실패");
      }
    } catch (e) {
      print('오디오 추출 오류: $e');
      return null;
    }
  }

  /// 임시 디렉터리 정리
  void _cleanTemporaryDirectory(Directory tempDir) {
    if (tempDir.existsSync()) {
      tempDir.listSync().forEach((file) {
        if (file is File) {
          file.deleteSync(); // 기존 파일 삭제
        }
      });
    }
  }

  /// Google Cloud 인증 생성
  Future<AutoRefreshingAuthClient?> _getGoogleAuthClient() async {
    try {
      // JSON 키 파일 로드
      final credentials = await rootBundle.loadString(_credentialsPath);
      final serviceAccount = jsonDecode(credentials);
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);

      // 인증 클라이언트 생성
      return await clientViaServiceAccount(
          accountCredentials, [speech.SpeechApi.cloudPlatformScope]);
    } catch (e) {
      print("Google Auth 오류: $e");
      return null;
    }
  }

  /// Google Speech-to-Text API 호출
  Future<String> transcribeAudio(String audioPath) async {
    final authClient = await _getGoogleAuthClient();
    if (authClient == null) {
      throw Exception("Google Auth 클라이언트 생성 실패");
    }

    try {
      // 오디오 파일 읽기
      final audioBytes = File(audioPath).readAsBytesSync();
      final audioBase64 = base64Encode(audioBytes);

      // API 요청 설정
      final request = speech.RecognizeRequest(
        config: speech.RecognitionConfig(
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode: 'ko-KR', // 한국어 설정
        ),
        audio: speech.RecognitionAudio(
          content: audioBase64,
        ),
      );

      // API 호출
      final speechApi = speech.SpeechApi(authClient);
      final response = await speechApi.speech.recognize(request);

      // 변환된 텍스트 추출
      final transcript = response.results
              ?.map((result) => result.alternatives?.first.transcript)
              .join(' ') ??
          '텍스트 변환 실패';

      return transcript;
    } catch (e) {
      print('Speech-to-Text 오류: $e');
      return '텍스트 변환 중 오류 발생';
    } finally {
      authClient.close();
    }
  }

  /// 동영상 분석 프로세스 실행
  Future<String> processVideo(String videoUrl) async {
    try {
      // 1. 동영상에서 오디오 추출
      final audioPath = await extractAudio(videoUrl);
      if (audioPath == null) throw Exception("오디오 추출 실패");

      // 2. 오디오를 텍스트로 변환
      final transcript = await transcribeAudio(audioPath);

      // 3. 임시 파일 삭제
      await cleanUpTemporaryFiles(audioPath);

      // 4. 결과 반환
      return transcript;
    } catch (e) {
      print("동영상 분석 오류: $e");
      return "오류 발생: 분석을 완료할 수 없습니다.";
    }
  }

  /// 임시 파일 삭제
  Future<void> cleanUpTemporaryFiles(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      print('임시 파일 삭제 완료: $filePath');
    }
  }
}
