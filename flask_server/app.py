from flask import Flask, request, jsonify
import networkx as nx
from keybert import KeyBERT
from konlpy.tag import Komoran
from itertools import combinations
import requests
import xml.etree.ElementTree as ET
from transformers import PreTrainedTokenizerFast, BartForConditionalGeneration

# 모델과 토크나이저 불러오기 : 전역변수로 불러와 서버 실행 시 한번만 로드
tokenizer = PreTrainedTokenizerFast.from_pretrained('digit82/kobart-summarization')

app = Flask(__name__)

# Textrank 알고리즘 class로 구현
class TextRank:
    def __init__(self, window_size=2):
        self.window_size = window_size
        self.komoran = Komoran()
        self.d = 0.85  # Damping coefficient

    # 유의미한 키워드 추출을 위한 POS 태그 필터링
    def _preprocess_keywords(self, text):
        return [word for word, tag in self.komoran.pos(text) if tag in ('NNG', 'NNP', 'NNB', 'NNM', 'NR', 'NP', 'XR')]

    def _create_graph_keywords(self, words):
        graph = nx.Graph()
        for i in range(len(words) - self.window_size):
            window = words[i: i + self.window_size]
            for pair in combinations(window, 2):
                if graph.has_edge(pair[0], pair[1]):
                    graph[pair[0]][pair[1]]['weight'] += 1
                else:
                    graph.add_edge(pair[0], pair[1], weight=1)
        return graph

    def analyze_keywords(self, text):
        words = self._preprocess_keywords(text)
        graph = self._create_graph_keywords(words)
        scores = nx.pagerank(graph, self.d)
        return sorted(scores.items(), key=lambda x: x[1], reverse=True)

def reorder_with_keybert(text, num_keywords=12):
    keywords = extract_with_textrank(text)
    doc = " ".join(keywords)
    keybert_keywords = model_keywords.extract_keywords(doc, top_n=num_keywords)
    return keybert_keywords
    
# TextRank를 사용하여 텍스트에서 키워드 추출
def extract_with_textrank(text, window_size=2, num_keywords=25):
    tr = TextRank(window_size)
    scores = tr.analyze_keywords(text)
    keywords = [item[0] for item in scores[:num_keywords]]
    return keywords

model_keywords = KeyBERT("distilbert-base-nli-mean-tokens")
# keybert를 사용하여 키워드 순위 재정렬
@app.route('/extract-keywords', methods=['POST'])
def extract_keywords():
    try:
        # JSON 형식의 데이터를 요청에서 가져옴
        data = request.get_json()
        text = data.get('text', '')

        # 텍스트에서 공백과 개행 문자를 제거
        text = text.replace('\n', '').replace('\t', '').replace('\r', '')

        # KeyBERT를 사용하여 키워드를 추출
        keywords = reorder_with_keybert(text, num_keywords=12)


        # UTF-8로 인코딩된 JSON 응답
        response_data = jsonify(keywords)
        response_data.headers['Content-Type'] = 'application/json; charset=utf-8'

        return response_data

    except Exception as e:
        return str(e), 500

model_summarize = BartForConditionalGeneration.from_pretrained('digit82/kobart-summarization')
@app.route('/generate-summary', methods=['POST'])
def summary_route():
    data = request.get_json()
    text = data.get('text', '')  # 텍스트 데이터 가져오기
    keywords = data.get('keywords', '')  # 키워드 가져오기

    summary = generate_summary(text, keywords) # summary.py의 generate_summary함수 불러오기
    return summary
    # return text

def generate_summary(text, keywords=''):
    # 키워드를 강조하기 위해 텍스트에 추가
    emphasized_text = text + ' ' + ' '.join(['[{}]'.format(keyword) for keyword in keywords.split()])

    # 텍스트 토큰화 및 요약 수행
    inputs = tokenizer(emphasized_text, return_tensors='pt', max_length=512, truncation=True)
    # 요약 : KoBART 자체에서는 문장 단위로 요약문을 생성하는 모듈/라이브러리/함수등이 없음
    # 대신 min_length와 max_length로 최소 최대 문자 길이를 지정한 후, 범위 내에서 early_stopping=True 를 설정하면 완결된 문장으로 끝내는 것을 기대할 수 있음
    summary_ids = model_summarize.generate(inputs['input_ids'], max_length=500, min_length=40, length_penalty=2.0, num_beams=4, early_stopping=True)
    summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)

    # UTF-8로 인코딩된 JSON 응답
    response_data = jsonify(summary)
    response_data.headers['Content-Type'] = 'application/json; charset=utf-8'

    return response_data

@app.route('/search', methods=['POST'])
def get_kocw_courses():
    keyword = request.args.get('keyword', '')
    key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce" 
    category_type = "t"
    category_id = "1"
    start_date = "20170101"
    end_date = "20231201"
    start_num = 1
    end_num = 100
    verb = "list_item"
    
    courses = call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb)
    
    if keyword:
        courses = filter_courses(courses, keyword)
    
    # UTF-8로 인코딩된 JSON 응답
    response_data = jsonify(courses)
    response_data.headers['Content-Type'] = 'application/json; charset=utf-8'

    return response_data

def call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb):
    base_url = "http://www.kocw.net/home/api/handler.do"
    params = {
        "key": key,
        "category_type": category_type,
        "category_id": category_id,
        "from": start_date,
        "to": end_date,
        "start_num": start_num,
        "end_num": end_num,
        "verb": verb,
        # "course_id": course_id
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:
        return parse_xml(response.content)
    else:
        return None

def parse_xml(xml_data):
    root = ET.fromstring(xml_data)
    courses = []
    for course in root.findall('.//list_item'):
        course_data = {child.tag: child.text for child in course}
        courses.append(course_data)
    return courses

def filter_courses(courses, search_term):
    # 데이터 필터링 로직
    filtered_courses = []
    for course in courses:
        if ('course_title' in course and search_term.lower() in course['course_title'].lower()) or \
           ('course_description' in course and search_term.lower() in course['course_description'].lower()) or \
           ('course_keyword' in course and search_term.lower() in course['course_keyword'].lower()) or \
           ('lecturer' in course and search_term.lower() in course['lecturer'].lower()):
            filtered_courses.append(course)
    return filtered_courses

if __name__ == '__main__':
    app.run(debug=True) 