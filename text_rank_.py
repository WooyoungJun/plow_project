# TextRank 모듈
import networkx as nx
from konlpy.tag import Komoran
from collections import defaultdict
from itertools import combinations

class TextRank:
    def __init__(self, window_size=2):
        self.window_size = window_size
        self.komoran = Komoran()
        self.d = 0.85  # Damping coefficient

    def _preprocess(self, text):
        return [word for word, tag in self.komoran.pos(text) if tag in ('NNG', 'NNP', 'NNB', 'NNM', 'NR', 'NP', 'XR')]

    def _create_graph(self, words):
        graph = nx.Graph()
        for i in range(len(words) - self.window_size):
            window = words[i: i + self.window_size]
            for pair in combinations(window, 2):
                if graph.has_edge(pair[0], pair[1]):
                    graph[pair[0]][pair[1]]['weight'] += 1
                else:
                    graph.add_edge(pair[0], pair[1], weight=1)
        return graph

    def analyze(self, text):
        words = self._preprocess(text)
        graph = self._create_graph(words)
        scores = nx.pagerank(graph, self.d)
        return sorted(scores.items(), key=lambda x: x[1], reverse=True)

def extract_keywords(text, window_size=2, num_keywords=5):
    tr = TextRank(window_size)
    scores = tr.analyze(text)
    keywords = [(item[0], round(item[1], 4)) for item in scores[:num_keywords]]
    return keywords
