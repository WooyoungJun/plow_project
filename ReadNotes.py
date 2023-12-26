import cv2, pytesseract
import numpy as np
import fitz  # PyMuPDF
import os
import io
from PIL import Image
import requests
import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage
from Preprocess import preprocess  # 사용자 정의 전처리 함수

# Firebase 초기화
cred = credentials.Certificate('google-services.json')
firebase_admin.initialize_app(cred, {'storageBucket': 'gs://sweetmeproject.appspot.com'})

def download_from_firebase(file_path):
    client = storage.Client()
    bucket = client.get.bucket('sweetmeproject.appspot.com')
    blob = bucket.blob(file_path)
    binary_data = blob.download_as_bytes()
    return binary_data

def read_pdf_img(doc):
    try:
        result = ''
        for page in doc:
            img = page.get_pixmap()
            image_data = io.BytesIO(img.tobytes('jpg'))
            text = read_image(image_data)
            result += text
        return result
    except Exception as e:
        print(f"Error reading PDF image: {e}")
        return ""

def read_pdf(file_data):
    with fitz.open(stream=file_data, filetype='pdf') as doc:
        # PDF에서 텍스트 추출에 실패할 경우 이미지로 추출
        try:
            text = ''
            for page in doc:
                text += page.get_text()
            if not text:
                return read_pdf_img(doc)
            return text
        except Exception:
            return read_pdf_img(doc)

def read_image(image_data):
    image = np.array(Image.open(io.BytesIO(image_data)))
    preprocess(image)
    text = pytesseract.image_to_string(image, lang='kor+eng', config='--psm 6 --oem 3 -c preserve_interword_spaces=1')
    return text

def ReadNotes(file_path):
    file_data = download_from_firebase(file_path)
    if file_path.lower().endswith('.pdf'):
        return read_pdf(file_data)
    else:
        return read_image(file_data)

