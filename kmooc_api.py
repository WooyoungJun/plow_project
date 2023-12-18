import requests

def get_kmooc_courses(keyword):
    # K-MOOC API 키
    service_key = "hgZLcXYGW%2BV162eJNAgEpQfM4QeoW8Hqyjx1B%2FiUXuIORmyrq68teftqf9OBWASMCBSXMhQW7Yuk398mef1K3g%3D%3D"  
    page = 1
    response = requests.get(f"http://apis.data.go.kr/B552881/kmooc?ServiceKey={service_key}&page={page}")
    data = response.json()

    kmooc_courses = []
    for course in data['results']:
        course_title = course.get('name', '').lower()
        course_description = course.get('short_description', '').lower()
        
        # title과 description에 keyword를 찾아서 강좌정보 반환
        # 제공되는 모든 정보는 일단 다 반환하도록 하였음
        if keyword.lower() in course_title or keyword.lower() in course_description:
            kmooc_courses.append({
                'course_url': course.get('blocks_url', ''),
                'effort': course.get('effort', ''),
                'end_date': course.get('End', ''),
                'enrollment_start': course.get('enrollment_start', ''),
                'enrollment_end': course.get('enrollment_end', ''),
                'course_id': course.get('id', ''),
                'course_image': course.get('course_image', ''),
                'course_title': course_title,
                'course_number': course.get('Number', ''),
                'provider': course.get('Org', ''),
                'short_description': course_description,
                'start_date': course.get('start', ''),
                'start_display': course.get('start_display', ''),
                'start_type': course.get('start_type', ''),
                'pacing': course.get('Pacing', ''),
                'mobile_available': course.get('mobile_available', ''),
                'hidden': course.get('hidden', '')
            })

    return kmooc_courses
