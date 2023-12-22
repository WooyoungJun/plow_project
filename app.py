from flask import Flask, render_template, request, jsonify
from app_read_notes import app_read_notes
import kocw_api
# import kmooc_api # kmooc 수정중
from text_rank import text_rank # text_rank 모듈

app = Flask(__name__)
app.register_blueprint(app_read_notes)

@app.route('/')
def home():
    return render_template('home.html')

# @app.route('/SWeetMe/search', methods=['GET', 'POST'])
# def search():
#     if request.method == 'POST':
#         search_term = request.form['search_term']
#         if not search_term:
#             return "검색어를 입력하세요"

#         # KOCW API 호출 설정
#         key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce" 
#         category_type = "t"
#         category_id = "1"
#         start_date = "20170101" # 추후 로직 수정 예정
#         end_date = "20231201" # 추후 로직 수정 예정
#         start_num = 1
#         end_num = 1000
#         verb = "list_item"

#         # API 호출 및 필터링
#         courses = kocw_api.call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb)
#         filtered_courses = kocw_api.filter_courses(courses, search_term)

#         return render_template('search_results.html', courses=filtered_courses, search_term=search_term)
#     else:
#         return render_template('search.html')
    
    # kmooc api 호출은 수정중

# flutter 전달
# kocw 검색어 호출only
# @app.route('/SWeetMe/search', methods=['GET'])
# def get_kocw_courses():
#     # Retrieve the search keyword from query parameters
#     keyword = request.args.get('keyword', '')  # Default to empty string if not provided

#     # KOCW API 호출을 위한 파라미터 설정
#     key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce"
#     category_type = "t"
#     category_id = "1"
#     start_date = "201720101"
#     end_date = "20231201"
#     start_num = 1
#     end_num = 100
#     verb = "list_item"

#     # KOCW API 호출
#     courses = kocw_api.call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb)

#     # 필터링: 검색어가 포함된 강의만 선택
#     if keyword:
#         filtered_courses = [course for course in courses if keyword.lower() in course.get('course_title', '').lower()]
#     else:
#         filtered_courses = courses

#     # 결과를 JSON 형식으로 반환
#     return jsonify(filtered_courses)

# 요약문 출력, 검색어 api 호출 같이
@app.route('/SWeetMe/search', methods=['GET'])
def search_page():
    # 검색어 받기
    keyword = request.args.get('keyword', 'be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce')

    # KOCW API 호출 및 필터링
    courses = kocw_api.call_kocw_api('')
    filtered_courses = [course for course in courses if keyword.lower() in course.get('course_title', '').lower()]

    # 텍스트 파일 읽기 및 요약
    with open('텍스트파일 불러들어오는경로/file.txt', 'r') as file: # 텍스트파일 불러들이기
        text = file.read()
    summary = text_rank(text)[:3]  # 상위 3개 요약문 추출

    # 결과 반환
    #return render_template('search.html', courses=filtered_courses, summary=summary, keyword=keyword)
    return jsonify({"summary": summary}) # json형태로 반환, key값=summary, value값=추출된 요약문
  
if __name__ == '__main__':
    app.run(debug=True)
