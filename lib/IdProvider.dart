import 'package:flutter/material.dart';

class Idprovider with ChangeNotifier {
  String? _resumeId;
  String? _interviewId;

  String? get resumeId => _resumeId;
  String? get interviewId => _interviewId;

  void setResumeId(String resumeId) {
    _resumeId = resumeId;
    notifyListeners(); // 상태가 변경되었음을 알림
  }

  void setInterviewId(String interviewId) {
    _interviewId = interviewId;
    notifyListeners(); // 상태가 변경되었음을 알림
  }

  void clearIds() {
    _resumeId = null;
    _interviewId = null;
    notifyListeners(); // 상태 초기화 시 알림
  }
}
