from flask import Flask, request, jsonify
import logging
import requests
from src.resumes import extract_text,create_questions

app = Flask(__name__)

# 로깅 설정
logging.basicConfig(level=logging.DEBUG)  # 로그 레벨을 DEBUG로 설정
logger = logging.getLogger(__name__)

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

 
@app.route('/feedback-interviews', methods=['POST'])
def feedback_interviews():
    return


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
