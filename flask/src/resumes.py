#이력서 분석 코드(분석 및 주요 키워드 추출)
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
import requests
import tempfile
import os
import openai
import logging
from dotenv import load_dotenv

# .env 파일에서 환경 변수 로드
load_dotenv()

app = Flask(__name__)

# 로깅 설정
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# OpenAI API 키 설정
openai.api_key = os.getenv('OPENAI_API_KEY')

def extract_text(pdf_url):
    """PDF URL을 받아 텍스트를 추출하는 함수"""
    try:
        # PDF 파일 다운로드
        response = requests.get(pdf_url)
        response.raise_for_status()

        # 임시 파일에 PDF 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            temp_file.write(response.content)
            temp_file_path = temp_file.name

        # PDF 파일에서 텍스트 추출
        text = ""
        reader = PdfReader(temp_file_path)
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + ' '

        # 임시 파일 삭제
        os.remove(temp_file_path)
        return text.strip()

    except requests.exceptions.RequestException as e:
        logger.error(f"Error downloading PDF: {e}")
        return None
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {e}")
        return None

import re

def create_questions(text):
    """OpenAI API를 이용해 이력서 텍스트에서 질문 생성 및 주제 추출"""
    try:
        # OpenAI에게 요청할 메시지 생성
        messages = [
            {"role": "system", "content": "당신은 개발자 면접을 보는 AI 면접관입니다. 이력서를 분석하여 면접에 필요한 질문을 만들어 주세요."},
            {"role": "user", "content": f"여기에 개발자의 이력서가 있습니다.:\n\n{text}\n\n이력서를 분석하여, 주요 카테고리 5개를 추출하고, 각 카테고리에 대한 질문을 '주제: 질문' 형식으로 한 줄로 만들어 주세요. 예시: '기술 스택: 어떤 기술을 사용하여 프로젝트를 해결했나요?'"}
        ]

        # OpenAI API 호출
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=messages,
            max_tokens=900,  # 필요한 경우 더 늘려서 질문 수를 조절
            temperature=0.7
        )

        # 응답에서 질문 및 주제 추출
        generated_text = response['choices'][0]['message']['content']
        
        # 정규 표현식을 사용하여 "주제: 질문" 형식으로 파싱
        pattern = r'(.*?):\s*(.*)'  # 주제와 질문을 구분
        matches = re.findall(pattern, generated_text)

        questions = {}
        for i, (topic, question) in enumerate(matches, 1):
            # 불필요한 따옴표 제거
            topic = topic.strip().replace("'", "")  # 작은 따옴표 제거
            questions[f'q{i}'] = {
                'topic': topic.strip(),
                'question': question.strip()
            }

        return questions

    except Exception as e:
        logger.error(f"Error generating questions: {e}")
        return {}
