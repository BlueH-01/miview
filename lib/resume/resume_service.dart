import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../firebase/firesbase_init.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // JSON 변환을 위해 추가
import 'package:http/http.dart' as http; // HTTP 요청을 위해 추가
import '../firebase/file_upload.dart';

class ResumeService {
  List<PlatformFile> resumes = [];
  final FileUploadService _fileUploadService = FileUploadService(); //fileupload 인스턴스 생성
  final FirebaseStorage _storage = FirebaseInit().storage;
  final FirebaseFirestore _firestore = FirebaseInit().firestore; //firebase관련 인스턴스생성
 
  // PDF 파일 선택
  Future<PlatformFile?> pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      print("Selected file: ${result.files.first.name}");
      return result.files.first;
    }
    print("No file selected or file picker was cancelled.");
    return null;
  }
  
 Future<void> uploadPDF(PlatformFile file, String userId) async {
  _fileUploadService.uploadResume(file, userId);
}


  // 유저의 이력서 목록 가져오기
  Stream<List<PlatformFile>> getUserResumes(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('resumes')
        .orderBy('uploadTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        String filePath = doc['filePath']; // Firestore에 저장된 파일 경로
        String fileName = doc['fileName'];
        String resumeId = doc.id;
        String downloadURL = doc['downloadURL'];

        // Firebase Storage에서 파일의 다운로드 URL 가져오기
        return PlatformFile(
          identifier: resumeId,
          name: fileName,
          path: downloadURL, // 다운로드 URL을 path로 사용
          size: 0, // 필요 시 파일 크기를 포함시킬 수 있습니다.
        );
      }).toList();
    });
  }
}
