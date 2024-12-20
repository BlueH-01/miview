from flask import Flask, request, jsonify
import openai
import os
import logging
import requests
from src.resumes import extract_text, create_questions

# OpenAI API 키 설정
openai.api_key = os.getenv('OPENAI_API_KEY')

# 로깅 설정
logging.basicConfig(level=logging.DEBUG)  # 로그 레벨을 DEBUG로 설정
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 이력서 분석 코드
@app.route('/generate-questions', methods=['POST'])
def generate_questions():
    """PDF URL을 받아 텍스트를 추출하고 OpenAI를 통해 질문 생성"""
    data = request.json
    pdf_url = data.get('pdf_url')

    logger.debug(f"Received request with PDF URL: {pdf_url}")

    if not pdf_url:
        return jsonify({'error': 'PDF URL is required'}), 400

    try:
        # 1. PDF 다운로드 및 텍스트 추출
        text = extract_text(pdf_url)
        print(text)
        if not text:
            return jsonify({'error': 'Failed to extract text from PDF'}), 500
        
        # 2. OpenAI API를 통한 질문 생성
        questions = create_questions(text)
        print(questions)
        # 3. 결과 JSON으로 반환
        return jsonify({'questions': questions})

    except requests.exceptions.RequestException as e:
        logger.error(f"Error downloading PDF: {e}")
        return jsonify({'error': 'Failed to download PDF'}), 500
    except Exception as e:
        logger.error(f"Error processing PDF: {e}")
        return jsonify({'error': 'Failed to analyze PDF'}), 500

#시선처리
@app.route('/analyze-speech', methods=['POST'])
def analyze_speech():
    """면접자의 표정 및 시선 데이터를 받아 부드럽고 조언하는 방식으로 피드백 생성"""
    try:
        data = request.json
        logger.debug(f"Received data: {data}")  # 수신된 요청 데이터 출력

        frames = data.get('frames', [])

        if not frames:
            logger.error("No frames data provided")
            return jsonify({'error': 'No frames data provided'}), 400

        # 부드럽고 조언하는 말투로 작성된 프롬프트 생성
        prompt = "다음 데이터를 바탕으로 면접자의 시선과 표정 상태에 대해 부드럽고 조언하는 말투로 피드백을 작성해주세요. 면접자가 개선할 수 있는 부분이 있다면 따뜻한 조언을 덧붙여주세요.\n"
        for frame in frames:
            prompt += f"프레임 {frame['frame']}: 감정: {frame['emotion']}, 시선: {frame['gaze']}\n"

        logger.debug(f"Generated prompt: {prompt}")

        # OpenAI API 호출 (부드러운 피드백 요청)
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # OpenAI 모델
            messages=[{"role": "user", "content": prompt}],
            max_tokens=900,  # 한국어는 상대적으로 더 많은 토큰을 사용할 수 있음
            temperature=0.7,
        )

        feedback = response['choices'][0]['message']['content']
        logger.debug(f"Generated feedback: {feedback}")

        return jsonify({'feedback': feedback})

    except Exception as e:
        logger.error(f"Error: {e}")
        return jsonify({'error': str(e)}), 500
    
@app.route('/analyze-answer', methods=['POST'])
def analyze_answer():
    """
    질문과 답변 데이터를 받아 OpenAI API를 통해 답변의 품질을 평가하고 피드백을 반환
    """
    try:
        # 요청 데이터 확인
        data = request.json
        logger.debug(f"Received data for analyze-answer: {data}")

        question = data.get('question', '')
        answer = data.get('answer', '')

        if not question or not answer:
            return jsonify({'error': 'Both question and answer are required'}), 400

        # OpenAI 프롬프트 생성
        prompt = (
            f"질문: {question}\n"
            f"답변: {answer}\n"
            "당신은 면접을 대비하는 새내기들을 위해 모의 면접을 담당하는 면접관입니다. 잘한 부분과 못한 부분은 솔직하게 말하고 답변의 품질을 평가하고 개선할 점을 포함한 피드백을 제공해주세요. 질문에 대해 이상한 답변일 경우 잘못된 답변이라고 말을 확실하게 해주세요"
        )

        logger.debug(f"Generated prompt: {prompt}")

        # OpenAI API 호출
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "system", "content": "당신은 전문적인 평가자입니다."},
                      {"role": "user", "content": prompt}],
            max_tokens=900,
            temperature=0.7,
        )

        # OpenAI 응답 데이터
        feedback = response['choices'][0]['message']['content']
        logger.debug(f"Generated feedback: {feedback}")

        # 결과 반환
        return jsonify({'feedback': feedback})

    except Exception as e:
        logger.error(f"Error in analyze-answer: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)  # debug=True 추가로 디버그 모드 활성화
