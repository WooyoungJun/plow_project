from flask import Flask
from kocw_api import get_kocw_courses
from summary import generate_summary
from keywords import extract_keywords
from textextract import text_processing

app = Flask(__name__)

# url 맞춰주기 : /모듈
app.add_url_rule('/text-processing', 'text_processing', text_processing, methods=['POST'])
app.add_url_rule('/extract-keywords', 'extract_keywords', extract_keywords, methods=['POST'])
app.add_url_rule('/search', 'get_kocw_courses', get_kocw_courses, methods=['GET'])
app.add_url_rule('/generate-summary', 'generate_summary', generate_summary, methods=['POST'])

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0') 
