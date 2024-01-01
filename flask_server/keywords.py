from flask import request, jsonify
import extractor

def extract_keywords():
    try:
        # JSON 형식의 데이터를 요청에서 가져옴
        data = request.get_json()
        text = data.get('text', '')

        # 텍스트에서 공백과 개행 문자를 제거
        text = text.replace('\n', '').replace('\t', '').replace('\r', '')

        # KeyBERT를 사용하여 키워드를 추출
        keywords = extractor.reorder_with_keybert(text, num_keywords=12)
        chart = extractor.create_bubble_chart(keywords)  # 차트 생성 함수 호출

        # 추출한 키워드와 차트 이미지를 함께 JSON 응답으로 반환
        return jsonify({'keywords': keywords, 'chart': chart})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

