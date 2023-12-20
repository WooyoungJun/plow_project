from flask import Flask, render_template, request, jsonify
from app_read_notes import app_read_notes
import kocw_api
import kmooc_api

app = Flask(__name__)
app.register_blueprint(app_read_notes)

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/SWeetMe/search', methods=['GET'])
def search():
    keyword = request.args.get('keyword')
    if not keyword:
        return render_template('search_results.html', message='검색어를 입력해주세요.')

    # API 호출
    kocw_courses = kocw_api.get_kocw_courses(keyword)  # kocw
    kmooc_courses = kmooc_api.get_kmooc_courses(keyword)  # kmooc
    
    # 로그 출력
    print("KOCW Courses:", kocw_courses)
    print("KMOOC Courses:", kmooc_courses)

    return render_template('search_results.html', kocw_courses=kocw_courses, kmooc_courses=kmooc_courses)

if __name__ == '__main__':
    app.run(debug=True)
