# 작성자 : 장다은 (최근수정 : 240102)
# summary 모듈 : 추출 텍스트를 불러와서 KoBART모델로 summary
# 모델 출처 : https://github.com/seujung/KoBART-summarization
'''
[requirements]
torch==2.0.1
transformers==4.32.1
tokenizers==0.13.3
lightning==2.0.8
streamlit==1.26.0
wandb==0.15.9
'''
from flask import request, jsonify
import torch
from transformers import PreTrainedTokenizerFast, BartForConditionalGeneration

# 모델과 토크나이저 불러오기
tokenizer = PreTrainedTokenizerFast.from_pretrained('digit82/kobart-summarization')
model = BartForConditionalGeneration.from_pretrained('digit82/kobart-summarization')

def generate_summary():
    data = request.get_json()
    text = data.get('text')

    # 텍스트 토큰화 및 요약 수행
    inputs = tokenizer(text, return_tensors='pt', max_length=512, truncation=True)
    summary_ids = model.generate(inputs['input_ids'], max_length=150, min_length=40, length_penalty=2.0, num_beams=4, early_stopping=True)
    summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)

    return jsonify({'summary': summary})