from flask import Flask, request, jsonify
import cv2
import mediapipe as mp
import numpy as np
from fer import FER
import base64
import io

app = Flask(__name__)

# Mediapipe 초기화
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh()

# 감정 분석 모델 초기화
detector = FER()

@app.route('/analyze', methods=['POST'])
def analyze_video_frame():
    # 클라이언트에서 받은 base64 인코딩된 이미지 데이터
    data = request.get_json()
    image_data = data['image']  # base64 인코딩된 이미지 데이터

    # Base64 디코딩
    img_bytes = base64.b64decode(image_data)
    img_array = np.frombuffer(img_bytes, dtype=np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    # 얼굴 분석
    results = face_mesh.process(frame)
    gaze_status = "Not Detected"
    if results.multi_face_landmarks:
        gaze_status = "Focused"  # 간단한 예시로 "Focused"로 설정 (시선 추적 알고리즘 추가 가능)

    # 감정 분석
    emotion, score = detector.top_emotion(frame)

    # 결과 반환
    return jsonify({
        'emotion': emotion,
        'gazeStatus': gaze_status
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
