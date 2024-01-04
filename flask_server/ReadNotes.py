import cv2, pytesseract
import numpy as np
from PIL import Image
from Preprocess import preprocess

def read_img(image_data):
    try:
        image = np.array(Image.open(image_data))
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        preprocess(image)  # 이미지 전처리
        text = pytesseract.image_to_string(image, lang='kor+eng', config='--psm 6 --oem 3 -c preserve_interword_spaces=1')
        return text
    except Exception as e:
        print(f"Error processing image: {e}")
        return ""

def download_from_firebase(file_path):
    client = storage.Client()
    bucket = client.get.bucket('sweetmeproject.appspot.com')
    blob = bucket.blob(file_path)
    binary_data = blob.download_as_bytes()
    return binary_data

def ReadNotes(file_stream):
    try:
        file_data = download_from_firebase(file_path)
        return read_img(file_stream)

    except Exception as e:
        print(f"Error processing file: {e}")
        return ""