import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'firesbase_init.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileUploadService {
  // 싱글톤 인스턴스를 저장할 정적 변수
  static final FileUploadService _instance = FileUploadService._internal();

  // 공용 생성자를 private으로 설정
  factory FileUploadService() {
    return _instance;
  }

  // 내부 생성자
  FileUploadService._internal();
  final FirebaseFirestore _firestore = FirebaseInit().firestore;
  final FirebaseStorage _storage = FirebaseInit().storage;

  Future<void> uploadResume(PlatformFile file, String userId) async {
    try {
      // Firestore에 이력서 문서 추가
      DocumentReference resumeRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resumes')
          .add({
        'fileName': file.name,
        'uploadTime': FieldValue.serverTimestamp(),
      });

      String documentId = resumeRef.id; // Firestore에서 생성된 documentId

      // Storage에 저장할 경로에 documentId 사용
      String filePath = 'users/$userId/resumes/$documentId/${file.name}';
      Reference storageRef = _storage.ref().child(filePath);

      // 파일 바이트 가져오기
      List<int> fileBytes = await _getFileBytes(file);

      // Storage에 파일 업로드
      await storageRef.putData(Uint8List.fromList(fileBytes));

      // Storage에서 파일 URL 가져오기
      String downloadURL = await storageRef.getDownloadURL();

      // Firestore 문서 업데이트: 다운로드 URL 추가
      await resumeRef.update({
        'filePath': filePath,
        'downloadURL': downloadURL,
      });

      print("Resume uploaded successfully.");
    } catch (e) {
      print("Error uploading resume: $e");
    }
  }

  // PDF로부터 추출된 질문을 저장
  Future<void> uploadQuestions(Map<String, Map<String, String>> questions, String userId, String resumeId) async {
  try {
    // Firestore에 저장할 문서의 reference 가져오기
    DocumentReference questionDocRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('questions')
        .add({
      'resumeId': resumeId,
      'uploadTime': FieldValue.serverTimestamp(),
    });

    String questionDocId = questionDocRef.id; // 생성된 questionDocId

    // 1. 'topic' 컬렉션에 주제를 저장하고
    Map<String, dynamic> topicData = {
      'commentId': '', // 나중에 commentId를 업데이트할 예정
      'resumeId': resumeId,
    };

    // topic1~5 설정 (각 질문의 주제 저장)
    for (int i = 1; i <= 5; i++) {
      String? topic = questions['q$i']?['topic'];
      if (topic != null) {
        topicData['topic$i'] = topic; // 주제를 저장
      } else {
        topicData['topic$i'] = ''; // 기본값 설정
      }
    }

    DocumentReference topicDocRef = await questionDocRef.collection('topic').add(topicData);
    String topicId = topicDocRef.id; // 생성된 topicId

    // 2. 'comment' 컬렉션에 질문을 저장
    Map<String, dynamic> commentData = {
      'topicId': topicId,
      'resumeId': resumeId,
    };

    // question1~5 설정 (각 질문의 내용 저장)
    for (int i = 1; i <= 5; i++) {
      String? question = questions['q$i']?['question'];
      if (question != null) {
        commentData['question$i'] = question; // 질문을 저장
      } else {
        commentData['question$i'] = ''; // 기본값 설정
      }
    }

    DocumentReference commentDocRef = await questionDocRef.collection('comment').add(commentData);
    String commentId = commentDocRef.id; // 생성된 commentId

    // 3. 'topic' 문서에 'commentId' 필드 업데이트
    await topicDocRef.update({
      'commentId': commentId,
    });

    print("질문이 성공적으로 업로드되었습니다. 이력서 ID: $resumeId");
  } catch (e) {
    print("질문 업로드 중 오류 발생: $e");
  }
}

String _extractTopicFromQuestion(String question) {
  // 질문에서 주제를 추출하는 간단한 로직
  // 여기서는 질문의 첫 번째 몇 단어를 주제로 설정
  final topic = question.split(' ').take(3).join(' ');
  return topic;
}

  Future<List<int>> _getFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    } else {
      final selectedFile = File(file.path!);
      return await selectedFile.readAsBytes();
    }
  }

  Future<void> uploadInterview(PlatformFile file, String userId, String resumeId, String interviewId) async {
    // MP4 파일 업로드 구현
  }
}
