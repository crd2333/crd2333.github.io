---
order: 4
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "高级数据结构与算法分析",
  lang: "zh",
)

#let Q(body1, body2) = [
  #question(body1)
  #note(caption: "Answer", body2)
]

= 高级数据结构与算法分析易错题

== HW 1

#question()[
  For the result of accessing the keys 3, 9, 1, 5 in order in the splay tree in the following figure, which one of the following statements is FALSE?
]
#note(caption: "Answer")[
  逆天选择模拟 splay，没什么好说的，选项也不放了，锻炼快速模拟能力
  #grid(
    columns: (auto, auto),
    fig("/public/assets/Courses/ADS/易错题/img-2024-02-28-22-11-23.png", width: 80%),
    fig("/public/assets/Courses/ADS/易错题/img-2024-02-28-22-10-48.png", width: 50%),
  )
]

#question()[Consider the following buffer management problem. Initially the buffer size (the number of blocks) is one. Each block can accommodate exactly one item. As soon as a new item arrives, check if there is an available block. If yes, put the item into the block, induced a cost of one. Otherwise, the buffer size is doubled, and then the item is able to put into. Moreover, the old items have to be moved into the new buffer so it costs $k+1$ to make this insertion, where k is the number of old items. Clearly, if there are $N$ items, the worst-case cost for one insertion can be $Omega(N)$. To show that the average cost is $O(1)$, let us turn to the amortized analysis. To simplify the problem, assume that the buffer is full after all the $N$ items are placed. Which of the following potential functions works?
/ A.: The number of items currently in the buffer.
/ B.: The opposite number of items currently in the buffer.
/ C.: The number of available blocks currently in the buffer.
/ D.: The opposite number of available blocks in the buffer
]
#note(caption: "Answer")[
  选 D，不会。感觉是 AD 二选一，A 为什么不行？
]

== HW 2

#question()[
  Insert 3, 1, 4, 5, 9, 2, 6, 8, 7, 0 into an initially empty 2-3 tree (with splitting). Which one of the following statements is FALSE?
]
#note(caption: "Answer")[
  模拟插入，最后画出来可能长这样
  #fig("/public/assets/Courses/ADS/易错题/img-2024-03-12-23-11-31.png", width: 50%)
]

#question()[
  Which of the following statements concerning a B+ tree of order M is TRUE? \
  A. the root always has between 2 and M children\
  ...
]

#note(caption: "Answer")[
  注意定义，root 要么是叶子，要么才是 2 到 M 个孩子。
]

== HW 3
#question()[
  When evaluating the performance of data retrieval, it is important to measure the relevancy of the answer set. (T/F)
]
#note(caption: "Answer")[
  F. 召回率和整个答案集的相关性无关，这题挺唬人的，乍一看还真是那么回事。
]

== HW 4

#question()[
  The result of inserting keys $1$ to $2^k- 1$ for any $k>4$ in order into an initially empty skew heap is always a full binary tree.
]

#note(caption: "Answer", breakable: false)[
  不是很懂为什么要 $k > 4$，在我看来好像 $k ge 2$ 就都成立了，对 $k=4$ 画出的图如下：
  #syntree("[1 [3 [7 15 11] [5 13 9]] [2 [6 14 10] [4 12 8]]]")
  （可以背一下规律，节省时间）
]

== HW 7
#question()[
  Which one of the following is the lowest upper bound of $T(N)$. $T(N)$ for the following recursion $T(N) = 2T(sqrt(N)) + log N$?
]

#note(caption: "Answer")[
  答案是 $O(log N log log N)$。注意到函数并非典型形式，所以要先换元 $m = log N$，得到 $T(2^m) = 2T(2^(m/2)) + m$。再设 $G(m)=T(2^m)$，则有 $G(m)=2G(m\/2)+m$（也就是对变量换个元，再对函数换个元）\
  由主定理(1)知 $G(m)=O(m log m)$，所以 $T(N)=O(log N log log N)$
]

== HW 9
#question()[
  Let $S$ be the set of activities in Activity Selection Problem. Then the earliest finish activity $a_m$ must be included in all the maximum-size subset of mutually compatible activities of $S$.
]
#note(caption: "Answer")[
  F. 注意，这个近似解一定在某一个最优解中，但不一定在所有最优解中。
]

== HW 10
#question()[
  All NP problems are decidable.
]
#note(caption: "Answer")[
  T.
]

== HW 11
#question()[
  To approximate a maximum spanning tree $T$ of an undirected graph $G=(V,E)$ with distinct edge weights  $w(u,v)$ on each edge $(u,v) in E$, let's denote the set of maximum-weight edges incident on each vertex by $S$.  Also let $w(E')=sum_{(u,v) in E'} w(u,v)$ for any edge set $E'$.  Which of the following statements is TRUE?
  - A. $S=T$ for any graph $G$
  - B. $S != T$ for any graph $G$
  - C. $w(T) >= w(S)\/2$ for any graph $G$
  - D. None of the above
]
#note(caption: "Note")[
  意思是，对每个顶点选它的最大边，这样选出来的结果不一定是最大生成树，甚至不一定联通，但足够近似。A 和 B 选项看起来互斥，实际上可以分别构造出反例。
  #fig("/public/assets/Courses/ADS/易错题/img-2024-05-10-19-20-37.png", width: 50%)
  对 C 选项，由于。不会
]

== HW 12
#Q(
  [
    Greedy method is a special case of local search.
  ],
  [
    F. 贪心可以大概定义为每一步根据启发信息的最优来决策。而局部搜索则是从一个初始解中通过局部扰动，从而探索新解的可能。一种常见的局部搜索是"k交换"局部搜索。通过交换解中的某些结果，从而测试这种扰动是否能获得更优的解。
  ]
)

#Q(
  [A bipartite graph $G$ is one whose vertex set can be partitioned into two sets $A$ and $B$, such that each edge in the graph goes between a vertex in $A$ and a vertex in $B$.  Matching $M$ in $G$ is a set of edges that have no end points in common.  Maximum Bipartite Matching Problem finds a matching with the greatest number of edges (over all matching).\
  Consider the following Gradient Ascent Algorithm:
  ```
    As long as there is an edge whose endpoints are unmatched, add it to the current matching. When there is no longer such an edge, terminate with a locally optimal matching.
  ```
  Let $M_1$ and $M_2$ be matchings in a bipartite graph $G$.  Which of the following statements is true?
  - A. This gradient ascent algorithm never returns the maximum matching.
  - B. Suppose that $|M_1|>2|M_2|$. Then there must be an edge $e$ in $M_1$ such that $M_2 union {e}$ is a matching in $G$.
  - C. Any locally optimal matching returned by the gradient ascent algorithm in a bipartite graph $G$ is at most half as large as a maximum matching in $G$.
  - D. All of the above
  ],
  [
    不会。
  ]
)

== HW15
#Q(
  [
    If only one tape drive is available to perform the external sorting, then the tape access time for any algorithm will be $Omega(N^2)$.
  ],
  [
    答案是 T。不懂，跟数据库的理论有点不一样？而且为什么 $Omega(N^2)$ 没有考虑内存大小 $M$(或者说合并路数 $k$)？
  ]
)


= 复习

== Chap 1
- 记高度为 $h$ 的 AVL-tree 最少有 $h_i$ 个节点，那么有 $h_i = h_(i-1) + h_(i-2) + 1$，$h_(-1) = 0, h_0 = 1$。例如，给定 $h = 6$，那么 $h_6 = 33$。

