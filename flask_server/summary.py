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

# 모델과 토크나이저 불러오기 : 전역변수로 불러와 서버 실행 시 한번만 로드
tokenizer = PreTrainedTokenizerFast.from_pretrained('digit82/kobart-summarization')
model = BartForConditionalGeneration.from_pretrained('digit82/kobart-summarization')

def generate_summary(text, keywords=''):
    # 키워드를 강조하기 위해 텍스트에 추가
    emphasized_text = text + ' ' + ' '.join(['[{}]'.format(keyword) for keyword in keywords.split()])

    # 텍스트 토큰화 및 요약 수행
    inputs = tokenizer(emphasized_text, return_tensors='pt', max_length=512, truncation=True)
    # 요약 : KoBART 자체에서는 문장 단위로 요약문을 생성하는 모듈/라이브러리/함수등이 없음
    # 대신 min_length와 max_length로 최소 최대 문자 길이를 지정한 후, 범위 내에서 early_stopping=True 를 설정하면 완결된 문장으로 끝내는 것을 기대할 수 있음
    summary_ids = model.generate(inputs['input_ids'], max_length=500, min_length=40, length_penalty=2.0, num_beams=4, early_stopping=True)
    summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)

    return summary