from flask import request, jsonify

def extract_keywords():
    # 키워드 추출 로직 추가
    data = request.get_json()
    text = data.get('text')
    keywords = ['111', '222']  # 예시
    return jsonify({'keywords': keywords})
