import requests
import xml.etree.ElementTree as ET

def call_kocw_api(key, category_type, category_id, start_date, end_date, start_num, end_num, verb):
    base_url = "http://www.kocw.net/home/api/handler.do"
    params = {
        "key": key,
        "category_type": category_type,
        "category_id": category_id,
        "from": start_date,
        "to": end_date,
        "start_num": start_num,
        "end_num": end_num,
        "verb": verb,
        # "course_id": course_id
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:
        return parse_xml(response.content)
    else:
        return None

def parse_xml(xml_data):
    root = ET.fromstring(xml_data)
    courses = []
    for course in root.findall('.//list_item'):
        course_data = {child.tag: child.text for child in course}
        courses.append(course_data)
    return courses

def filter_courses(courses, search_term):
    # 데이터 필터링 로직
    filtered_courses = []
    for course in courses:
        if ('course_title' in course and search_term.lower() in course['course_title'].lower()) or \
           ('course_description' in course and search_term.lower() in course['course_description'].lower()) or \
           ('course_keyword' in course and search_term.lower() in course['course_keyword'].lower()) or \
           ('lecturer' in course and search_term.lower() in course['lecturer'].lower()):
            filtered_courses.append(course)
    return filtered_courses