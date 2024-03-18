# plow_project - SWeetme 프로젝트 소개

사용자가 손으로 쓴 노트를 업로드하면, 시스템은 해당 노트를 인식하여 디지털 텍스트로 변환합니다. 변환된 내용을 바탕으로, 시스템은 해당 내용이 속한 과목을 파악하고, 관련된 학습 자료나 논문을 추천합니다. 또한, 사용자들이 각 카테고리 별로 의견을 나누고 토론할 수 있는 커뮤니티 공간을 제공합니다.

개발 기간: 2023.11 - 2023.12(약 6주)

# 프로젝트 목표

학생들이 보다 효율적인 학습을 할 수 있도록 돕는 것을 큰 목표로 하고 있습니다. 학습자 스스로가 적극적으로 학습 내용을 공유하고, 다른 학생들과 지식을 나누며, 함께 성장할 수 있는 환경을 조성하는 것이 목적입니다.

# 지원 기능

- 사용자는 자신의 손글씨 노트를 업로드하여 디지털 텍스트로 변환할 수 있습니다.
- 시스템은 공부한 내용을 요약 해주고, 주제(키워드)를 추출해서 정리해줍니다.
- 시스템은 변환된 텍스트를 분석하여 해당 내용에 대한 추가 학습 자료를 추천합니다.
- 사용자들은 커뮤니티에서 질문, 토론, 정보 공유를 할 수 있습니다.
- 유사한 과목을 공부하는 사용자와 친구 사이를 맺을 수 있습니다. 친구 게시판을 통해 친구들의 게시글만 확인할 수 있습니다.
- 사용자는 자신의 노트를 편집하여 플랫폼에 공유함으로써 크레딧을 얻을 수 있으며, 사용처는 아직 미구현상태입니다.


# 사용 스택

## 전우영
- 손글씨 인식
    - google_mlkit_text_recognition: 테서렉트 모델과 비교할 모델(대조군)
- 커뮤니티 플랫폼 개발
    - 프론트엔드(flutter): 기본적인 UI 구현, 페이지네이션 & 무한스크롤 구현 
    - 백엔드(firebase, firestore): 사용자 데이터, 노트, 커뮤니티 게시물 관리
    - 회원가입, 로그인, 로그아웃 기능 구현
    - 친구 추가 및 삭제, 관리 기능 구현
- 이미지 업로드 및 확장자 변환 기능(Flutter Plugin 활용)
  - image_picker: jpg, jpeg, png 업로드 기능 
  - file_picker: pdf 업로드 기능 
  - syncfusion_flutter_pdfviewer & pdf_render & image: pdf to png 변환 기능
- 크레딧 기능 구현
- 일일 퀘스트 기능 구현
- AWS EC2에 Apache 웹 서버 + Flask 웹 어플리케이션 백엔드 통합 -  OCR(테서렉트 모델), 텍스트 요약 모델(KoBART), 키워드 추출 모델(KeyBERT) 구동

### 설계 주안점
- 초기 기획단계에서 사용자 필기 업로드 서비스 특성 상 모바일 유저 사용자가 많을 것이라 예상했고, Android + IOS 사용자 모두 동일한 사용자 경험을 제공하기 위해 크로스 플랫폼 프레임워크를 사용하기로 결정했음. 
- Google에서 공식적으로 지원하는 언어(Dart)를 사용하는 Flutter 프레임워크를 선택 함 - 빠르게 개발을 시작할 수 있는 쉬운 언어이면서 다양한 라이브러리(플러그인)를 지원하기 때문에
- 사용자 회원가입, 로그인, 로그아웃 기능과 게시글을 관리하는  커뮤니티 플랫폼을 개발할 때 사용할 백엔드 프레임워크는 Firebase + Firestore를 선택함 - Google이 직접 서비스하는 백엔드 클라우드 서비스이므로 연동하기 쉽고, 참고할 만한 레퍼런스 코드가 많기 때문에.
- 게시글에 이미지를 업로드할 경우 현재 시간과 랜덤 문자열을 생성 후 Google Cloud Storage에 업로드 함. 게시글을 문서로 저장할 때 해당 이미지의 상대 경로(Storage)를 함께 저장하고, 읽어올 때는 해당 상대 경로로 접근해 이미지 바이트를 읽어옴.
- 문서 고유 ID 생성 시 동시성 문제를 해결하기 위해 Firestore의 transaction을 사용함. 동일한 문서에 동시 접근 시, 해당 트랜잭션을 다시 시도하기 때문에 일관된 최신 데이터를 보장함.
- Firebase의 Firestore는 NoSQL을 지원하고, 복잡한 쿼리를 지원하지 않아서 페이지네이션과 무한스크롤을 구현하기 어려웠음. 그래서 문서를 연결 리스트처럼 만들어서 해결함. 구체적인 방법은 아래와 같음.

  1. 문서별로 고유 숫자 ID 생성(1부터 시작하고 문서 생성시 1 증가 후 새로운 문서에 할당, 가장 최근 문서를 삭제할 경우에만 1 감소)
  2. 각 문서마다 이전 문서 고유 ID와 다음 문서 고유 ID를 저장.
  3. 문서 생성 시, 가장 최근 문서와 연결
  4. 문서 삭제 시, 이전 문서와 다음 문서를 연결
  5. 전체 게시판의 경우 페이지네이션 구현 -> 각 페이지의 시작 고유 ID를 저장. 해당 고유 ID 문서부터 일정 개수 읽어오기
  6. 친구 게시판의 경우 무한스크롤 구현 -> 가장 마지막에 가져온 고유 ID를 기억하고, 아래로 스크롤 할 경우 해당 ID 문서부터 일정 개수 추가로 읽어오기



## 박찬진 & 장다은
- 손글씨 인식
  - Tesseract OCR(20210811), PyMuPDF
    [tesseract-ocr-w64-setup-v5.0.0-alpha.20210811.exe 다운로드 링크](https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-v5.0.0-alpha.20210811.exe)
    - OpenCV: 이미지 전처리 (노이즈 제거) / 글자 영역 감지
- 콘텐츠 분석 및 추천 시스템
    - lightFM 등 추천시스템 알고리즘 활용
    - NLTK 등 tokenizer: 토큰화, 형태소 분석, 의미 분석
    - TensorFlow, Scikit-learn: 적절한 학습 자료 추천하는 모델 구축
    - 백엔드에 KOCW API 연결
- 백엔드 개발
    - RESTful 방식을 이용한 REST API 방식

## 구민영
- 크레딧 기능 구현
- 일일 퀘스트 기능 구현



# 바로가기
[프로젝트 기획안 소개](https://github.com/WooyoungJun/plow_project/blob/master/Plow_%EA%B8%B0%ED%9A%8D%EC%95%88%EB%B0%9C%ED%91%9C.pdf)


[사용자 필기 기반 학습 서비스 발표자료](https://github.com/WooyoungJun/plow_project/blob/master/1%ED%8C%80%20Plow_%EC%82%AC%EC%9A%A9%EC%9E%90%20%ED%95%84%EA%B8%B0%20%EA%B8%B0%EB%B0%98%20%ED%95%99%EC%8A%B5%20%EC%84%9C%EB%B9%84%EC%8A%A4_%EB%B0%9C%ED%91%9C%EC%9E%90%EB%A3%8C_%EC%B5%9C%EC%A2%85.pdf)