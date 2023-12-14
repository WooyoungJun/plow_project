from flask import Flask, render_template
from app_read_notes import app_read_notes

app = Flask(__name__)
app.register_blueprint(app_read_notes)

@app.route('/')
def home():
    return render_template('home.html')

if __name__ == '__main__':
    app.run(debug=True)
