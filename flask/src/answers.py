from flask import Flask, request
import os
import subprocess
import speech_recognition as sr

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_video():
    if 'video' not in request.files:
        return 'No video file provided', 400
    
    video = request.files['video']
    video_path = os.path.join('/tmp', video.filename)
    video.save(video_path)

    # 오디오 추출
    audio_path = '/tmp/audio.wav'
    command = f"ffmpeg -i {video_path} -q:a 0 -map a {audio_path}"
    subprocess.call(command, shell=True)

    # 오디오를 텍스트로 변환
    recognizer = sr.Recognizer()
    with sr.AudioFile(audio_path) as source:
        audio = recognizer.record(source)
        try:
            text = recognizer.recognize_google(audio)
            return {'text': text}
        except sr.UnknownValueError:
            return 'Could not understand audio', 400
        except sr.RequestError as e:
            return f'Could not request results; {e}', 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
