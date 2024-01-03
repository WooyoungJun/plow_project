from flask import request, jsonify
import firebase_admin
from firebase_admin import storage
import uuid
import extractor

def extract_keywords():
    try:
        # 이미 초기화된 Firebase 앱 가져오기
        app = firebase_admin.get_app()
        
        # Storage 클라이언트 생성
        client = storage.Client(app=app)
        bucket = client.get_bucket('gs://sweetmeproject.appspot.com')
        
        # JSON 형식의 데이터를 요청에서 가져옴
        data = request.get_json()
        text = data.get('text', '')

        # 텍스트에서 공백과 개행 문자를 제거
        text = text.replace('\n', '').replace('\t', '').replace('\r', '')

        # KeyBERT를 사용하여 키워드를 추출
        keywords = extractor.reorder_with_keybert(text, num_keywords=12)
        chart = extractor.create_bubble_chart(keywords)  # 차트 생성 함수 호출

        # Firebase Storage에 차트 이미지 업로드
        chart_filename = f'chart_{uuid.uuid4().hex}.png'
        chart_path = f'./uploads/chart/{chart_filename}'
        chart_blob = bucket.blob(chart_path)
        chart_blob.upload_from_string(chart, content_type='image/png')
        # url return
        chart_url = chart_blob.public_url

        # 추출한 키워드와 차트 url을 함께 JSON 응답으로 반환
        return jsonify({'keywords': keywords, 'chart_url': chart_url})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

