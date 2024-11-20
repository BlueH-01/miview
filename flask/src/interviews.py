#인터뷰 클래스 선언
#인터뷰 객체들로 이루어진 총피드백

class InterviewItem: #주제,질문,답변,피드백 을 속성으로 갖는 인터뷰아이템 클래스
    def __init__(self, topic, question, answer=None, feedback=None):
        self.topic = topic
        self.question = question
        self.answer = answer if answer is not None else ""
        self.feedback = feedback if feedback is not None else ""

    def __repr__(self):
        return f"InterviewItem(topic={self.topic}, question={self.question}, answer={self.answer}, feedback={self.feedback})"


class Interview:
    def __init__(self, resume_id):
        self.resume_id = resume_id
        self.interview_items = []  # InterviewItem 객체들을 저장하는 리스트

    def add_interview_item(self, topic, question, answer=None, feedback=None):
        interview_item = InterviewItem(topic, question, answer, feedback)
        self.interview_items.append(interview_item)

    def get_interview_data(self):
        """전체 인터뷰 데이터를 반환하는 메서드"""
        return [vars(item) for item in self.interview_items]

    def __repr__(self):
        return f"Interview(resume_id={self.resume_id}, interview_items={self.interview_items})"


# 사용 예시
interview = Interview(resume_id="12345")
interview.add_interview_item("Technical Skills", "What programming languages do you know?", "Python, Java", "Good understanding of Python.")
interview.add_interview_item("Project Experience", "Tell me about your last project.", "Developed an AI app.", "Great project scope.")

print(interview.get_interview_data())


