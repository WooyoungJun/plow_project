from flask import Flask, render_template, request, jsonify
from app_read_notes import app_read_notes
import kocw_api
# import kmooc_api # kmooc 수정중

app = Flask(__name__)
app.register_blueprint(app_read_notes)

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/SWeetMe/search', methods=['GET', 'POST'])
def search():
    if request.method == 'POST':
        search_term = request.form['search_term']
        if not search_term:
            return "검색어를 입력하세요"

        # KOCW API 호출 설정
        key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce" 
        category_type = "t"
        category_id = "1"
        start_date = "20170101"
        end_date = "20231201"
        start_num = 1
        end_num = 1000
        verb = "list_item"

        # API 호출 및 필터링
        courses = kocw_api.call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb)
        filtered_courses = kocw_api.filter_courses(courses, search_term)

        return render_template('search_results.html', courses=filtered_courses, search_term=search_term)
    else:
        return render_template('search.html')
    
    # kmooc api 호출은 수정중

# flutter 전달
'''
@app.route('/getKocwCourses', methods=['GET'])
def get_kocw_courses():
    # KOCW API 호출을 위한 파라미터 설정
    key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce"
    category_type = "t"
    category_id = "1"
    start_date = "20220101"
    end_date = "20221231"
    start_num = 1
    end_num = 100
    verb = "list_item"

    # KOCW API 호출
    courses = kocw_api.call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb)

    # 결과를 JSON 형식으로 반환
    return jsonify(courses)
'''    
if __name__ == '__main__':
    app.run(debug=True)
