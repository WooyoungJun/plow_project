# font path 조정 필요
# font path 조정 필요
# model -> parameter로 변경

from keybert import KeyBERT
import networkx as nx
from konlpy.tag import Komoran
from itertools import combinations
import numpy as np
import base64
# 버블차트 구현에 필요
import matplotlib.pyplot as plt
from io import BytesIO


# Textrank 알고리즘 class로 구현
class TextRank:
    def __init__(self, window_size=2):
        # 윈도우 크기 설정
        self.window_size = window_size
        # 형태소 분석을 위한 Koroman 초기화
        self.komoran = Komoran()
        # 감쇠 계수 설정
        self.d = 0.85  # 일반적인 설정값

    # 유의미한 키워드 추출을 위한 POS 태그 필터링
    def _preprocess_keywords(self, text):
        return [word for word, tag in self.komoran.pos(text) if tag in ('NNG', 'NNP', 'NNB', 'NNM', 'NR', 'NP', 'XR')]

    def _create_graph_keywords(self, words):
        #그래프 생성
        graph = nx.Graph()
        # 윈도우 크기만큼 단어 조합 생성 및 그래프 구축
        for i in range(len(words) - self.window_size):
            window = words[i: i + self.window_size]
            for pair in combinations(window, 2):
                if graph.has_edge(pair[0], pair[1]):
                    graph[pair[0]][pair[1]]['weight'] += 1
                else:
                    graph.add_edge(pair[0], pair[1], weight=1)
        return graph

    def analyze_keywords(self, text):
        # 텍스트 전처리를 통한 단어 추출
        words = self._preprocess_keywords(text)
        # 그래프 생성
        graph = self._create_graph_keywords(words)
        # TextRank 알고리즘을 통한 단어 점수 계산
        scores = nx.pagerank(graph, self.d)
        return sorted(scores.items(), key=lambda x: x[1], reverse=True)

# TextRank를 사용하여 텍스트에서 키워드 추출
def extract_with_textrank(text, window_size=2, num_keywords=25):
    tr = TextRank(window_size)
    scores = tr.analyze_keywords(text)
    keywords = [item[0] for item in scores[:num_keywords]]
    return keywords

# keybert를 사용하여 키워드 순위 재정렬
def reorder_with_keybert(text, model, num_keywords=12):
    # TextRank를 사용하여 초기 키워드 추출
    keywords = extract_with_textrank(text)
    # 추출된 키워드를 문장으로 변환
    doc = " ".join(keywords)
    # KeyBERT 모델을 사용하여 키워드 순서 재정렬
    # model = KeyBERT("distilbert-base-nli-mean-tokens")
    keybert_keywords = model.extract_keywords(doc, top_n=num_keywords)
    return keybert_keywords


# 분리 가능한 부분입니다.
# 버블차트 제작 관련 class
class BubbleChart:
    def __init__(self, area, bubble_spacing=0):
        # 입력된 area를 배열로 변환하고 반지름 계산
        area = np.asarray(area)
        r = np.sqrt(area / np.pi)

        self.bubble_spacing = bubble_spacing
        self.bubbles = np.ones((len(area), 4))
        self.bubbles[:, 2] = r
        self.bubbles[:, 3] = area
        self.maxstep = 2 * self.bubbles[:, 2].max() + self.bubble_spacing
        self.step_dist = self.maxstep / 2

        # 버블 초기 위치 설정
        length = np.ceil(np.sqrt(len(self.bubbles)))
        grid = np.arange(length) * self.maxstep
        gx, gy = np.meshgrid(grid, grid)
        self.bubbles[:, 0] = gx.flatten()[:len(self.bubbles)]
        self.bubbles[:, 1] = gy.flatten()[:len(self.bubbles)]

        self.com = self.center_of_mass()
        
    # 버블들의 weight를 고려해 중심점 계산
    def center_of_mass(self):
        return np.average(self.bubbles[:, :2], axis=0, weights=self.bubbles[:, 3])
        
    # 버블과 다른 버블 간의 중심 거리 계산
    def center_distance(self, bubble, bubbles):
        return np.hypot(bubble[0] - bubbles[:, 0],
                        bubble[1] - bubbles[:, 1])
        
    # 버블과 다른 버블 간의 외곽 거리 계산
    def outline_distance(self, bubble, bubbles):
        center_distance = self.center_distance(bubble, bubbles)
        return center_distance - bubble[2] - \
            bubbles[:, 2] - self.bubble_spacing
        
    # 충돌 여부 확인
    def check_collisions(self, bubble, bubbles):
        distance = self.outline_distance(bubble, bubbles)
        return len(distance[distance < 0])
        
    # 충돌하는 버블 인덱스 반환
    def collides_with(self, bubble, bubbles):
        distance = self.outline_distance(bubble, bubbles)
        return np.argmin(distance, keepdims=True)
        
    # 버블들을 압축해서 중심으로 이동
    def collapse(self, n_iterations=50):
        for _i in range(n_iterations):
            moves = 0
            for i in range(len(self.bubbles)):
                rest_bub = np.delete(self.bubbles, i, 0)
                # 중심으로 직접 이동 시도
                # 중심점까지의 방향벡터 계산
                dir_vec = self.com - self.bubbles[i, :2]
                # 단위벡터로 변환
                dir_vec = dir_vec / np.sqrt(dir_vec.dot(dir_vec))
                # 새로운 버블 위치 반환
                new_point = self.bubbles[i, :2] + dir_vec * self.step_dist
                new_bubble = np.append(new_point, self.bubbles[i, 2:4])

                # 충돌 확인 후 이동
                if not self.check_collisions(new_bubble, rest_bub):
                    self.bubbles[i, :] = new_bubble
                    self.com = self.center_of_mass()
                    moves += 1
                else:
                    # 충돌 시 충돌하는 버블을 피해서 이동 시도
                    for colliding in self.collides_with(new_bubble, rest_bub):
                        # 방향 벡터 계산
                        dir_vec = rest_bub[colliding, :2] - self.bubbles[i, :2]
                        dir_vec = dir_vec / np.sqrt(dir_vec.dot(dir_vec))
                        # 직교 벡터 계산
                        orth = np.array([dir_vec[1], -dir_vec[0]])
                        # 가야할 방향 테스트
                        new_point1 = (self.bubbles[i, :2] + orth *
                                      self.step_dist)
                        new_point2 = (self.bubbles[i, :2] - orth *
                                      self.step_dist)
                        dist1 = self.center_distance(
                            self.com, np.array([new_point1]))
                        dist2 = self.center_distance(
                            self.com, np.array([new_point2]))
                        new_point = new_point1 if dist1 < dist2 else new_point2
                        new_bubble = np.append(new_point, self.bubbles[i, 2:4])
                        # 충돌하지 않는 경우 새 버블 생성
                        if not self.check_collisions(new_bubble, rest_bub):
                            self.bubbles[i, :] = new_bubble
                            self.com = self.center_of_mass()

            if moves / len(self.bubbles) < 0.1:
                self.step_dist = self.step_dist / 2

    # 버블 차트 그리기
    def plot(self, ax, labels, colors):
        for i in range(len(self.bubbles)):
            circ = plt.Circle(
                self.bubbles[i, :2], self.bubbles[i, 2], color=colors[i])
            ax.add_patch(circ)
            ax.text(*self.bubbles[i, :2], labels[i],
                    horizontalalignment='center', verticalalignment='center')
            
from matplotlib import font_manager, rc
# font path 조정 필요
# font_path = "./Fonts/NanumGothic-Regular.ttf"
# font = font_manager.FontProperties(fname=font_path).get_name()

rc('font', family=font)
def create_bubble_chart(keywords):
    words, scores = zip(*keywords)
    # 파란색 계열 색깔
    colors = ['#D3D3D3', '#A9A9A9', '#808080', '#778899', '#708090', '#2F4F4F', '#C0C0C0', '#B0C4DE', '#B0E0E6', '#ADD8E6'] * 2
    bubble_chart = BubbleChart(area=scores, bubble_spacing=0.04)
    bubble_chart.collapse()

    ax = plt.subplots(subplot_kw=dict(aspect="equal"))
    bubble_chart.plot(ax, words, colors[:len(words)])
    ax.axis("off")
    ax.relim()
    ax.autoscale_view()
    # 이미지를 BytesIO 객체에 저장
    buffer = BytesIO()
    plt.savefig(buffer, format="png")
    buffer.seek(0)
    # Flutter에 게시할 수 있도록 base64 형태로 변환
    chart_base64 = base64.b64encode(buffer.read()).decode("utf-8")
    
    return chart_base64

