from flask import Flask, render_template, request, jsonify
from app_read_notes import app_read_notes
import kocw_api
import kmooc_api

app = Flask(__name__)
app.register_blueprint(app_read_notes)

@app.route('/')
def home():
    return render_template('home.html')

# api 연결 추가
@app.route('/search', methods=['GET'])
def search():
    keyword = request.args.get('keyword')
    if not keyword:
        return jsonify({'message': 'please enter your contents'})

    # api 호출
    kocw_courses = kocw_api.get_kocw_courses(keyword) # kocw
    kmooc_courses = kmooc_api.get_kmooc_courses(keyword)# kmooc
    # youtube

    return jsonify(kocw_courses)

if __name__ == '__main__':
    app.run(debug=True)
