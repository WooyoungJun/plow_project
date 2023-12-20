import requests

def get_kmooc_courses(keyword):
    service_key = "hgZLcXYGW%2BV162eJNAgEpQfM4QeoW8Hqyjx1B%2FiUXuIORmyrq68teftqf9OBWASMCBSXMhQW7Yuk398mef1K3g%3D%3D"
    page = 1
    org = "FUNMOOC"  # 기관 번호
    mobile = 1       # 모바일 표시 여부

    try:
        response = requests.get(f"http://apis.data.go.kr/B552881/kmooc/courseList?ServiceKey={service_key}&page={page}&org={org}&mobile={mobile}")
        print("Response from KMOOC API:", response.text)

        # 응답 상태 코드 확인
        if response.status_code != 200:
            print(f"Error: {response.status_code}, {response.text}")
            return []

        # JSON 데이터 파싱
        data = response.json()

        kmooc_courses = []
        for course in data['results']:
            course_title = course.get('name', '').lower()
            course_description = course.get('short_description', '').lower()
            keyword_lower = keyword.lower()

            # title과 description에 keyword를 찾아서 강좌정보 반환
            if keyword.lower() in course_title or keyword.lower() in course_description:
                kmooc_courses.append({
                    # 기존에 정의된 필드들
                    'course_url': course.get('blocks_url', ''),
                    # 'effort': course.get('effort', ''),
                    # 'end_date': course.get('End', ''),
                    # 'enrollment_start': course.get('enrollment_start', ''),
                    # 'enrollment_end': course.get('enrollment_end', ''),
                    # 'course_id': course.get('id', ''),
                    'course_image': course.get('course_image', ''),
                    'course_title': course_title,
                    # 'course_number': course.get('Number', ''),
                    # 'provider': course.get('Org', ''),
                    'short_description': course_description,
                    # 'start_date': course.get('start', ''),
                    # 'start_display': course.get('start_display', ''),
                    # 'start_type': course.get('start_type', ''),
                    # 'pacing': course.get('Pacing', ''),
                    # 'mobile_available': course.get('mobile_available', ''),
                    # 'hidden': course.get('hidden', '')
                })

        return kmooc_courses

    except requests.exceptions.RequestException as e:
        print(f"Request error: {e}")
        return []

    except ValueError as e:
        print(f"JSON decoding error: {e}, Response: {response.text}")
        return []
