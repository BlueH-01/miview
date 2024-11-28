#이력서 분석 코드(분석 및 주요 키워드 추출)
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
import requests
import tempfile
import os
import openai
import logging
from dotenv import load_dotenv
import random
import re
from collections import Counter


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


import random
import re
from collections import Counter

def create_questions(text):
    """OpenAI API를 이용해 이력서 텍스트에서 질문 생성 및 주제 추출"""
    try:
        # OpenAI에게 요청할 메시지 생성
        messages = [
            {"role": "system", "content": "당신은 개발자 면접을 보는 AI 면접관입니다. 이력서를 분석하여 프로그래머의 전문 지식, 문제 해결 능력 및 기술적 사고를 기반으로 다양한 질문을 만들어 주세요."},
            {"role": "user", "content": f"여기에 개발자의 이력서가 있습니다.:\n\n{text}\n\n이력서를 분석하여, '기술 스택', '문제 해결 능력', '코드 품질', '디자인 패턴', '성능 최적화', '알고리즘 및 데이터 구조', '보안', 'DevOps 및 CI/CD', '팀워크', '커뮤니케이션 능력', '자기 개발 및 학습', '시간 관리', '기술 트렌드 및 업계 동향', 'AI 및 머신러닝', '클라우드 컴퓨팅', '네트워크 및 보안', '유저 경험 (UX/UI)', '상용 소프트웨어 개발', '데이터베이스 설계', '리더십 및 관리 경험', '모바일 애플리케이션 개발', '스크럼 및 애자일' 중에서 카테고리 5개를 추출하고, 각 카테고리에 대한 질문을 '주제: 질문' 형식으로 한 줄로 만들어 주세요."}
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
            # 숫자 제거: 주제에서 숫자와 공백을 제거
            topic = re.sub(r'^\d+\.\s*', '', topic).strip()  # 숫자와 공백 제거
            # 작은 따옴표 제거
            topic = topic.replace("'", "").strip()
            questions[f'q{i}'] = {
                'topic': topic,
                'question': question.strip()
            }

        # 이미 선택된 주제를 추적하여 중복 제거
        selected_topics = set()
        unique_questions = {}

        # 무작위로 5개의 질문을 선택
        while len(unique_questions) < 5:
            random_question = random.choice(list(questions.items()))
            topic = random_question[1]['topic']
            if topic not in selected_topics:
                selected_topics.add(topic)
                unique_questions[random_question[0]] = random_question[1]

        # 최종 선택된 질문 반환
        selected_questions = {f'q{i+1}': {'topic': question['topic'], 'question': question['question']} 
                              for i, (qkey, question) in enumerate(unique_questions.items())}

        return selected_questions

    except Exception as e:
        logger.error(f"Error generating questions: {e}")
        return {}
