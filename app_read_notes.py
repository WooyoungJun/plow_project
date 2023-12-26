import os
from flask import Flask,render_template,redirect,url_for,request, Blueprint, send_from_directory, flash
from datetime import datetime
from werkzeug.utils import secure_filename
#import our OCR function
import cv2
import pytesseract

# 이미지 저장 폴더 경로
UPLOAD_FOLDER = './image/'
default_name = "read_notes"
default_dir = f"./{default_name}"
default_templates = f"./templates/"
app_read_notes = Blueprint(f"app_{default_name}", __name__, url_prefix=f"/SWeetMe/{default_name}")

#allow files of a specific type
ALLOWED_EXTENSIONS = set(['png','jpg','jpeg', 'pdf'])
app = Flask(__name__)
#app.config['DEBUG']=True

# function to check the file extension
def allowed_file(filename):
	return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
			
# route and function to handle the home page
@app_read_notes.route("/", methods=["GET", "POST"])
def read_notes_index():
	return render_template(f"index_{default_name}.html")

@app_read_notes.route("/upload", methods=["GET", "POST"])
def upload():
	if request.method == 'POST':
		if 'file' not in request.files:
			return render_template('upload.html', msg='No file selected')
		file = request.files['file']
		# if no file is selected
		if file.filename == '':
			return render_template('upload.html', msg='No file selected')
		if file and allowed_file(file.filename):
			filename = secure_filename(file.filename)
			file_path = os.path.join(UPLOAD_FOLDER, filename)
			file.save(file_path)
			
			image = cv2.imread(file_path)
			extracted_text = pytesseract.image_to_string(image, lang='kor+eng', config='--psm 4 --oem 3 -c preserve_interword_spaces=1')

			return render_template('upload.html', msg='Successfully processed', extracted_text=extracted_text, img_src=UPLOAD_FOLDER+file.filename)
	elif request.method == 'GET':
		return render_template('upload.html')

@app_read_notes.route('/upload/download_txt', methods=['POST'])
def download_txt():
	download_dir = default_dir + "/download_txt"
	if not os.path.exists(download_dir):
		os.makedirs(download_dir)
	
	extracted_text = request.form.get('extracted_text')
	if extracted_text:
		current_time = datetime.now().strftime("%m%d_%H%M%S")
		file_name = f"extracted_text_{current_time}.txt"
		file_path = os.path.join(download_dir, file_name)

		with open(file_path, 'w', encoding='utf-8') as file:
			file.write(extracted_text)

		return send_from_directory(directory=download_dir, path=file_name, as_attachment=True)
	else:
		return 'No text to save', 400
		
if __name__ == "__main__":
	app.run(debug=True)
