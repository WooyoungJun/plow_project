import requests
from bs4 import BeautifulSoup

def get_kocw_courses(keyword):
    api_key = "be3f8bd12e40c4dd7f7e23de303e7cf43df75bab271950ce"
    response = requests.get(f"http://www.kocw.net/home/api/handler.do?key={api_key}&verb=list_item&service_type=openapi&from=20170101&to=20170201&start_num=1&end_num=100")
    xml_data = response.content
    print("Response from KOCW API:", response.text)

    soup = BeautifulSoup(xml_data, 'lxml')
    courses = soup.find_all('list_item')

    kocw_courses = []
    for course in courses:
        course_title = course.find('course_title').text.lower() if course.find('course_title') else ''
        course_description = course.find('course_description').text.lower() if course.find('course_description') else ''
        keyword_lower = keyword.lower()

        # 검색어가 제목, 설명, 키워드 중 하나라도 포함되어 있으면 강좌 정보를 추가
        if keyword_lower in course_title or keyword_lower in course_description:
            kocw_courses.append({
                # 'course_id': course.find('course_id').text if course.find('course_id') else '',
                'course_title': course_title,
                # 'lecturer': course.find('lecturer').text if course.find('lecturer') else '',
                # 'provider': course.find('provider').text if course.find('provider') else '',
                # 'term': course.find('term').text if course.find('term') else '',
                'course_url': course.find('course_url').text if course.find('course_url') else '',
                'course_description': course_description,
                'course_keyword': course.find('course_keyword').text if course.find('course_keyword') else '',
                # 'lecture_count': course.find('lecture_count').text if course.find('lecture_count') else '',
                # 'content_type': course.find('content_type').text if course.find('content_type') else '',
                # 'popular_score': course.find('popular_score').text if course.find('popular_score') else '',
                # 'view_count': course.find('view_count').text if course.find('view_count') else '',
                'thumbnail_url': course.find('thumbnail_url').text if course.find('thumbnail_url') else '',
                # 'created_date': course.find('created_date').text if course.find('created_date') else '',
                # 'updated_date': course.find('updated_date').text if course.find('updated_date') else ''
            })

    return kocw_courses
