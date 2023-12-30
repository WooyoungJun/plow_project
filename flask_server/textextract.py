from flask import request, jsonify

def text_processing():
    # 텍스트 추출 로직
    data = request.get_json()
    extracted_text = data.get('text')
    return jsonify({'processed_text': extracted_text})
