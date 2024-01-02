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
        self.window_size = window_size
        self.komoran = Komoran()
        self.d = 0.85  # Damping coefficient

    # 유의미한 키워드 추출을 위한 POS 태그 필터링
    def _preprocess_keywords(self, text):
        return [word for word, tag in self.komoran.pos(text) if tag in ('NNG', 'NNP', 'NNB', 'NNM', 'NR', 'NP', 'XR')]

    def _create_graph_keywords(self, words):
        graph = nx.Graph()
        for i in range(len(words) - self.window_size):
            window = words[i: i + self.window_size]
            for pair in combinations(window, 2):
                if graph.has_edge(pair[0], pair[1]):
                    graph[pair[0]][pair[1]]['weight'] += 1
                else:
                    graph.add_edge(pair[0], pair[1], weight=1)
        return graph

    def analyze_keywords(self, text):
        words = self._preprocess_keywords(text)
        graph = self._create_graph_keywords(words)
        scores = nx.pagerank(graph, self.d)
        return sorted(scores.items(), key=lambda x: x[1], reverse=True)

# TextRank를 사용하여 텍스트에서 키워드 추출
def extract_with_textrank(text, window_size=2, num_keywords=25):
    tr = TextRank(window_size)
    scores = tr.analyze_keywords(text)
    keywords = [item[0] for item in scores[:num_keywords]]
    return keywords

# keybert를 사용하여 키워드 순위 재정렬
def reorder_with_keybert(text, num_keywords=12):
    keywords = extract_with_textrank(text)
    doc = " ".join(keywords)
    model = KeyBERT("distilbert-base-nli-mean-tokens")
    keybert_keywords = model.extract_keywords(doc, top_n=num_keywords)
    return keybert_keywords


# 분리 가능한 부분입니다.
# 버블차트 제작 관련 class
class BubbleChart:
    def __init__(self, area, bubble_spacing=0):
        area = np.asarray(area)
        r = np.sqrt(area / np.pi)

        self.bubble_spacing = bubble_spacing
        self.bubbles = np.ones((len(area), 4))
        self.bubbles[:, 2] = r
        self.bubbles[:, 3] = area
        self.maxstep = 2 * self.bubbles[:, 2].max() + self.bubble_spacing
        self.step_dist = self.maxstep / 2

        # calculate initial grid layout for bubbles
        length = np.ceil(np.sqrt(len(self.bubbles)))
        grid = np.arange(length) * self.maxstep
        gx, gy = np.meshgrid(grid, grid)
        self.bubbles[:, 0] = gx.flatten()[:len(self.bubbles)]
        self.bubbles[:, 1] = gy.flatten()[:len(self.bubbles)]

        self.com = self.center_of_mass()

    def center_of_mass(self):
        return np.average(
            self.bubbles[:, :2], axis=0, weights=self.bubbles[:, 3]
        )

    def center_distance(self, bubble, bubbles):
        return np.hypot(bubble[0] - bubbles[:, 0],
                        bubble[1] - bubbles[:, 1])

    def outline_distance(self, bubble, bubbles):
        center_distance = self.center_distance(bubble, bubbles)
        return center_distance - bubble[2] - \
            bubbles[:, 2] - self.bubble_spacing

    def check_collisions(self, bubble, bubbles):
        distance = self.outline_distance(bubble, bubbles)
        return len(distance[distance < 0])

    def collides_with(self, bubble, bubbles):
        distance = self.outline_distance(bubble, bubbles)
        return np.argmin(distance, keepdims=True)

    def collapse(self, n_iterations=50):
        for _i in range(n_iterations):
            moves = 0
            for i in range(len(self.bubbles)):
                rest_bub = np.delete(self.bubbles, i, 0)
                # try to move directly towards the center of mass
                # direction vector from bubble to the center of mass
                dir_vec = self.com - self.bubbles[i, :2]

                # shorten direction vector to have length of 1
                dir_vec = dir_vec / np.sqrt(dir_vec.dot(dir_vec))

                # calculate new bubble position
                new_point = self.bubbles[i, :2] + dir_vec * self.step_dist
                new_bubble = np.append(new_point, self.bubbles[i, 2:4])

                # check whether new bubble collides with other bubbles
                if not self.check_collisions(new_bubble, rest_bub):
                    self.bubbles[i, :] = new_bubble
                    self.com = self.center_of_mass()
                    moves += 1
                else:
                    # try to move around a bubble that you collide with
                    # find colliding bubble
                    for colliding in self.collides_with(new_bubble, rest_bub):
                        # calculate direction vector
                        dir_vec = rest_bub[colliding, :2] - self.bubbles[i, :2]
                        dir_vec = dir_vec / np.sqrt(dir_vec.dot(dir_vec))
                        # calculate orthogonal vector
                        orth = np.array([dir_vec[1], -dir_vec[0]])
                        # test which direction to go
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
                        if not self.check_collisions(new_bubble, rest_bub):
                            self.bubbles[i, :] = new_bubble
                            self.com = self.center_of_mass()

            if moves / len(self.bubbles) < 0.1:
                self.step_dist = self.step_dist / 2

    def plot(self, ax, labels, colors):
        for i in range(len(self.bubbles)):
            circ = plt.Circle(
                self.bubbles[i, :2], self.bubbles[i, 2], color=colors[i])
            ax.add_patch(circ)
            ax.text(*self.bubbles[i, :2], labels[i],
                    horizontalalignment='center', verticalalignment='center')
            
from matplotlib import font_manager, rc
# font path 조정 필요
font_path = "Font/NanumGothic-Regular.ttf"
font = font_manager.FontProperties(fname=font_path).get_name()

rc('font', family=font)
def create_bubble_chart(keywords):
    words, scores = zip(*keywords)
    # 파란색 계열 색깔
    colors = ['#D3D3D3', '#A9A9A9', '#808080', '#778899', '#708090', '#2F4F4F', '#C0C0C0', '#B0C4DE', '#B0E0E6', '#ADD8E6'] * 2
    bubble_chart = BubbleChart(area=scores, bubble_spacing=0.04)
    bubble_chart.collapse()

    fig, ax = plt.subplots(subplot_kw=dict(aspect="equal"))
    bubble_chart.plot(ax, words, colors[:len(words)])
    ax.axis("off")
    ax.relim()
    ax.autoscale_view()
    # 이미지를 BytesIO 객체에 저장
    buffer = BytesIO()
    plt.savefig(buffer, format="png")
    buffer.seek(0)
    # 웹에 게시할 수 있도록 base64 형태로 변환
    chart_base64 = base64.b64encode(buffer.read()).decode("utf-8")
    
    return chart_base64

