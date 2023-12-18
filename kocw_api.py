import requests
from bs4 import BeautifulSoup

def get_kocw_courses(keyword):
    api_key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce"
    response = requests.get(f"http://www.kocw.net/home/api/handler.do?key={api_key}&verb=list_item&service_type=openapi&from=20170101&to=20170201&start_num=1&end_num=100")
    xml_data = response.content

    soup = BeautifulSoup(xml_data, 'lxml')
    courses = soup.find_all('list_item')

    # course_keyword와 매칭하여 강좌정보 반환
    # 제공되는 모든 정보는 일단 다 반환하도록 하였음
    kocw_courses = []
    for course in courses:
        course_keyword_element = course.find('course_keyword')
        if course_keyword_element and keyword.lower() in course_keyword_element.text.lower():
            kocw_courses.append({
                'course_id': course.find('course_id').text if course.find('course_id') else '',
                    'course_title': course.find('course_title').text if course.find('course_title') else '',
                    'lecturer': course.find('lecturer').text if course.find('lecturer') else '',
                    'provider': course.find('provider').text if course.find('provider') else '',
                    'term': course.find('term').text if course.find('term') else '',
                    'course_url': course.find('course_url').text if course.find('course_url') else '',
                    'course_description': course.find('course_description').text if course.find('course_description') else '',
                    'course_keyword': course_keyword_element.text,
                    'lecture_count': course.find('lecture_count').text if course.find('lecture_count') else '',
                    'content_type': course.find('content_type').text if course.find('content_type') else '',
                    'popular_score': course.find('popular_score').text if course.find('popular_score') else '',
                    'view_count': course.find('view_count').text if course.find('view_count') else '',
                    'thumbnail_url': course.find('thumbnail_url').text if course.find('thumbnail_url') else '',
                    'created_date': course.find('created_date').text if course.find('created_date') else '',
                    'updated_date': course.find('updated_date').text if course.find('updated_date') else ''
            })

    return kocw_courses