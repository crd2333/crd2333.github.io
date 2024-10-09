---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "高级数据结构与算法分析",
  lang: "zh",
)

= Lecture 1: AVL Trees, Splay Trees, and Amortized Analysis
- 看 wyy 讲义，这里不想补笔记了。
- 总结一下摊还分析：
  + 聚合分析：整体分析最差的情况为什么样
  + 核算法：调整*每个操作*的代价，使得总代价比原本大
  + 势能法：对*每一步操作*定义一个势能，使得最后总势能比原本大

= Lecture 2: Red-Black Trees and B+ Trees
#let sizeof = math.op("sizeof")
#let bh = math.op("bh")
#let Depth = math.op("Depth")

== Red-Black Trees
- Target: BST
#wrap-content(fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-04-11-04-52.png"))[
- 定义：
  1. 每个节点要么是*红的*，要么是*黑的*
  2. root 是*黑的*
  3. 每个 leaf 是*黑的*（哨兵是*黑的*，因为哨兵才是实际的叶子）
  4. 如果一个 node 是*红的*，那么它的两个子节点都是*黑的*
  5. 对于每个 node，从该 node 到其所有后代 leaf 的路径上，均包含相同数目的*黑色*节点]

- 定义 black-height(node) 为从 node（不含）到所有 leaf 的路径上的*黑色* node 的数目，记为 bh(node)
  - 引理（树高与节点个数的关系）：$h =< 2log_2 (N+1)$
  - 引理（黑高与节点个数的关系）：For any node $x$, $sizeof(x) ge 2^bh(x) - 1$ （全黑取等）
  - 引理（黑高与树高的关系）：$bh(x) ge h(x)/2$
- Insert
  - 插入一个节点，它应该是*红色*还是*黑色*？答案是红色，因为插入黑色很容易改变黑高，而插入红色只需要调整即可。我们将插入节点称为 $X$，其父亲节点为 $P$，父亲的父亲为 $G$，叔叔为 $U$。以下均考虑插在左边情况，右边情况对称。
    1. 最特殊的情况，如果 $X$ 刚好是 root，那么将其染黑即可
    2. 如果 $P$ 是*黑色*，那么不需要调整；接下来考虑 $P$ 为*红色*，那么 $G$ 一定是黑色，根据叔叔 $U$ 的颜色分情况讨论
    3. 如果 $U$ 是*红色*，爷爷把 $P$ 和 $U$ 的锅背了(case 1)，并且递归下去
    4. 如果 $U$ 是*黑色*，根据叔叔和侄子的关系再分类
    5. 如果 $U$ 跟 $X$ 是*近叔侄*关系(case 2)，那么做一个旋转，化为*远叔侄*关系(case 3)
    6. 如果 $U$ 跟 $X$ 是*远叔侄*关系(case 3)，撺掇 $P$ 夺取 $G$ 的颜色，并且篡位（旋转）
  - 可以使用迭代而非递归的方式实现
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-04-11-33-28.png", width: 80%)
- Delete
  - 类似普通二叉查找树的删除
    1. 如果是叶子节点，直接删具体怎么删，之后说
    2. 如果是单个孩子的节点，用唯一的孩子替换，但是*颜色不变*，即只替换键值（注意因为是 balanced，所以不会出现单分支多于两个节点的情况）
    3. 如果左右两边都有孩子，我们用*左子树的最大值*代替要删除的节点（颜色不变）
    - 也就是说，对于所有非 leaf 的删除，都可以保持颜色不变归结为删除 leaf，现在我们来考虑删除它之后如何保持红黑树的性质。以下均考虑删除左边情况，右边情况对称。
  - leaf 如果是*红色*，直接删除，只需要考虑删除黑色 leaf 的情况。从理解的角度考虑（代码上不用这么写），先补偿性地给自己加一个*黑色*，变为“很黑''，现在两边的黑高分别是 $x+1$ 和 $x$。
    - 而后，第一种想法是，两边一起甩锅给父亲，减轻压力，再删掉自己的*黑色*，最终两边都是 $x-1$；
    - 第二种想法是，直接删掉自己这边的“很黑''，为此，从兄弟那边抢一个*黑色*到自己这边，再给右边补偿染黑一个*红色*节点，最终两边都是 $x$。（哪里抢*黑色*呢？一般考虑兄弟的*黑色*旋转过来）
    1. 先考虑甩锅，需要看兄弟的颜色，如果是*红色*(case 1)则需要变出一个*黑色*的兄弟来(case 2)。具体操作是，让兄弟把父亲的*黑色*（父亲一定是*黑色*，否则与兄弟也为*红色*违背）抢过来，这样右边黑高了，于是进行左旋。注意到兄弟的孩子一定是*黑色*，这样的操作最后将*黑色*的侄子变成了兄弟，可以继续进行(case 2)
    2. 如果兄弟是*黑色*，配合甩锅也要看兄弟孩子的颜色是否有*红色*，如果没有，可以直接甩锅(case 2)，然后看是否递归。
    3. 如果兄弟的孩子有红色，变换策略，想办法从兄弟那边抢一个*黑色*，要看远侄子（插入和删除都是让远侄子变*红*）是*红色*还是*黑色*，如果远侄子是*黑色*(case 3)，那么由于已经过了 case 2，近侄子一定是*红色*，想办法把近侄子的*红色*转移到远侄子身上(case 4)
    4. 远侄子是*红色*，让兄弟篡位，通过左旋把兄弟（现在的父亲）变成自己人，把*红色*的远侄子染黑，最后删除自己。
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-04-12-08-19.png", width: 80%)
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-12-11-21-19.png", width: 80%)

== B+ Trees
- 类似的有 B- 树、B
- 定义 M 阶 B+ tree（也被称为 $ceil(M / 2)$-$"xxx"$-$M$ tree，如 4 阶又被称作 2-3-4 tree）：
  1. root 要么是叶子，要么有 $2 wave M$ 个#redt[孩子]
  2. 每个 nonleaf 节点（除了 root）有 $ceil(M / 2) wave M$ 个#redt[孩子]
  3. 每个 leaf 有同样的深度
  4. 每个非根的 leaf 有 $ceil(M / 2) wave M$ 个#redt[键值]
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-11-10-10-05.png", width: 80%)
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-14-13-39-08.png", width: 80%)
- #redt[思考为什么 root 的下限特别不一样？]因为分裂的时候，root 最多也就分裂成两个节点，因此下限是 2
- 插入
  - 根据键值排除一些路径
  - 兄弟之间的“互推''（小 trick，不一定要实现）
  - 分裂操作，可以看 PPT 的动画
    #algo(caption: "B+ tree insert")[
    ```
    Btree Insert (ElementType X, Btree T)
    {
        Search from root to leaf for X and find the proper leaf node;
        Insert X;
        while (this node has M+1 keys) {
            split it into 2 nodes with ⌈(M+1)/2⌉ and ⌊(M+1)/2⌋ keys, respectively;
            if (this node is the root)
                create a new root with two children;
            check its parent;
        }
    }
    ```
    ]
  - $T_("insert")(M,N) = O(ceil((M \/ log M) log N ))$
  - $T_("find")(M,N) = O(log N)$
  - $Depth(M,N) = O(ceil(log_(ceil(M \/ 2)) N))$
  - B+ 相对 AVL、Splay、Red-Black 的优势在于 IO 友好
- 删除
  - 跟 insert 对应
- 写代码时候发现的几个注意点
  - 更新 parent key 值的时候其实只用考虑相邻 parent，无需更新整个路径（一条路径上 key 值是互异的）

= Lecture 3: Inverted File Index

== 什么是倒排表
- 思考（引入）：搜索引擎查询 "Computer Science" 的时候，它如何从茫茫多的数据中找到相关的信息？
- solution1: Scan each page for the string "Computer Science"，时间复杂度是恐怖的
- solution2: Term-Document Incidence Matrix（稀疏矩阵）
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-11-10-53-19.png", width: 80%)
  - 局限性：对查询语句的位置信息不敏感、只找到文档而没找到文档内的位置信息、matrix 巨大
  - 优化：用邻接表记录，维护一个二分图
- solution3: Compact Version - Inverted File Index
  - 什么是 index，mechanism for locating a given term in a text.
  - *Inverted file* contains a list of pointers (e.g. the number of a page) to all occurrences of that term in the text.
  - 之所以叫倒排，是因为之前是 doc 里存 text，现在是从 text 索引 doc
    #fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-11-10-59-10.png", width:80%)
  - 存 frequency 的好处，取交集时从频率小的开始取
    #algo(caption: "倒排表伪代码实现")[
        ```
        while (read a document D) {
            while (read a term T in D) {
                if (Find(Dictionary, T) == false)
                    Insert( Dictionary, T );
                    Get T's posting list;
                    Insert a node to T's posting list;
                }
            }
        Write the inverted index to disk;
        ```
    ]
  - 需要考虑的问题：Token analyzer, Vocabulary scanner, Vocabulary insertor, Memory management
== 问题处理
- While reading a term
  - word stemming（词根处理）：词缀不重要，合并为词根
  - stop words（停用词）：像是 a, the, is 这种词，不需要索引
- Vocabulary scanner
  - solution1: Search trees(B- trees *(?)* , B+ trees, Tries *(?)*)
  - solution2: Hashing
- While not having enough memory
    #algo(caption: "倒排表考虑 memory")[
        ```c
        BlockCnt = 0;
        while (read a document D) {
            while (read a term T in D) {
                if (out of memory) {
                    Write BlockIndex[BlockCnt] to disk;
                    BlockCnt ++;
                    FreeMemory;
                }
                if (Find(Dictionary, T) == false)
                    Insert(Dictionary, T);
                Get T's posting list;
                Insert a node to T's posting list;
            }
        }
        for (i = 0; i < BlockCnt; i++)
            Merge(InvertedIndex, BlockIndex[i]);
        ```
    ]
- Distributed indexing
  - Solution 1: Term-partitioned index
  - Solution 2: Document-partitioned index
  - 比较两种方式的优劣，后者可以并行
- Dynamic indexing
  - 考虑文档被删除或更新的情况
  - 维护两个表，固定表大一些（只承受查询），动态表小一些（同时承受查询和爬虫更新），合并搜索结果
  - 实际删除太昂贵，一般是标记删除(lazy delete)，定期真正删除
- Compression
  - doc 内不存空格，而是标记断点
  - 当 doc 特别大的时候，不存位置信息（太大），而是存增量
- Thresholding
  - Document，只检索 top $x$ 个 rank 高的 docs
  - Query，对索引的单词进行频率排序
- 搜索引擎的评估
  - 建立索引的效率有多高(How fast does it index)
  - 检索的速度有多快(How fast does it search)
  - 理解 query 语言的程度有多高(Expressiveness of query language)
  - Data Retrieval（响应时间和索引空间）
  - Information Retrieval（回答集相关性）
- 相关性好坏的评估：往往是 Precision 和 Recall 的 trade-off
#tbl(
  columns: 3,
  [], [Relevant], [Irrelevant],
  [Retrieved], [$R_R$], [$I_R$],
  [Not Retrieved], [$R_N$], [$I_N$]
)
#align(center)[
$display("Precision" P = R_R / (R_R + I_R))$，返回的结果中有多少是正确的
]
#align(center)[
$display("Recall" R = R_R / (R_R + R_N))$，正确的结果实际被返回了多少
]

= Lecture 4: Leftist Heaps and Skew Heaps
== Leftist Heaps
- 左倾树，或左偏堆
  - order 性质: same as heap
  - 结构性质: binary tree，but unbalanced
- Target : Speed up merging in $O(N)$
- NPL（Null Path Length）：从一个节点到一个外部节点（没有两个儿子）的路径长度（对比红黑树的黑高，那个是统计节点个数，这个则是路径长度）
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-18-10-06-25.png")

#theorem()[
A leftist tree with r nodes on the right path must
have at least $2r - 1$ nodes \
（证明用归纳法）
]

#corollary()[
对于有 $N$ 个节点的左偏树，其右路径至多包含 $floor(log(N+1))$ 个节点\
这启示我们所有操作尽量对右路径上进行
]

- 下面来看 insert 和 merge（insert 可以被视为 merge），首先是递归方法
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-18-10-51-04.png", width: 65%)
  - 做题一般采用迭代方法，但是递归的代码记一下（程序填空）
  ```C
  PriorityQueue Merge( PriorityQueue H1, PriorityQueue H2 )
  {
    if (H1==NULL) return H2;
    if (H2==NULL) return H1;
    if (H1->Element > H2->Element)
        swap(H1, H2);  //swap H1 and H2
    if (H1->Left == NULL)
        H1->Left = H2;
    else {
        H1->Right = Merge(H1->Right, H2);
        if (H1->Left->Npl < H1->Right->Npl)
            SwapChildren(H1);  //swap the left child and right child of H1
        H1->NPl = H1->Right->Npl + 1;
    }
    return H1;
  }
  ```

- 然后是迭代方法
  1. 切样本（节点及其左子树为一个样本），有 $log N$ 个
  2. 选择最小根节点（用两个指针来维护）的样本接在右子树
  3. 从右路径最下开始，交换左右子树来维护 NPL
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-18-11-08-29.png", width: 65%)

== Skew Heaps
- Skew heaps 之于 heaps 就像 splay trees 之于 binary search trees
  - target: Any $M$ consecutive operations take at most $O(M log N)$ time.
- Skew heaps 的 merge 跟 leftist heaps 的 merge 几乎相同，只是少了一个 Npl 的维护与比较，不管三七二十一都要交换左右子树
  - 这里 PPT 说什么右路径中除了最大节点之外都交换，其实意思是，有左孩子无右孩子的情况下不交换，避免把优势情况葬送掉，自己画的时候注意一下就是了。
  - 跟 leftist heaps 的 merge 一样，skew heaps 的 merge 也有 递归和迭代 两种方法

#note(indent: false)[
1. Skew heaps have the advantage that no extra space is required to maintain path lengths and no tests are required to determine when to swap children. \
2. It is an open problem to determine precisely the expected right path length of both leftist and skew heaps.
]
- Skew heaps 的重点是 Amortized Analysis
- 思考势能函数的选择：
  - 一个好的势能函数应该有起有伏
  - 节点个数？有起无伏
  - 右路径上的节点个数？这就跟实际代价差不多，没有摊还的起伏了，而且也不太能算出来
  - 右子树中的节点个数？斜堆中不会有“只有右儿子没有左儿子''的情况（交换前，思考为什么），也就不会因为交换而减少
#definition()[
A node p is #redt[heavy] if the number of descendants of p's right subtree is at least half of the number of descendants of p, and #bluet[light] otherwise. Note that the number of descendants of a node includes the node itself.
]
- 选择 number of heavy nodes 作为势能函数进行摊还分析
  - 设 $l$、$h$
  - 实际代价 $H$ 是右路径的总长，也就是 $l + h$
  - 重节点一定会变成轻节点，轻节点不一定会变成重节点（两边相等），放缩为一定变为重节点的情况
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-18-11-56-37.png")

= Lecture 5: Binomial Queue
== Definition
- Binomial Queue 是由#redt[一组] heap-ordered trees 组成的(也即 forest)。每个 heap-ordered tree 是一个 binomial tree，每个记作 $B_k$
- $B_k$ 由两个 $B_(k-1)$ 组成，这里约定根节点小的那个作为根节点
  - 对 $"size"$ 做一个二项分解，对应到二进制的每一位，确定 $B_k$ 是否存在
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-30-16-22-02.png", width: 80%)
#corollary[$B_k$ consists of a root with $k$ children, which are $B_0,B_1,dots,B_(k-1)$. $B_k$ has exactly $2^k$ nodes. The number of nodes at depth $d$ is $display(vec(delim: "[",k, d))$.]
== Operations
- `FindMin`，最小值在其中一个根节点，最多 $ceil(log N)$ 个，因此 $T_p=O(log N)$
  - 我们可以记住并时刻更新最小值，这样就可以 $O(1)$ 找到最小值
- `Merge`，从低到高（保证二项队列按高度排列）合并，每个合并视为 $O(1)$，最多合并 $log N$ 次，因此 $T_p=O(log N)$
  - 思考三棵树（合并的两棵和进位上来的那棵）应该合并哪两棵？答案是其实没关系
  - 思考为什么每个合并只用 $O(1)$（跟后面子树内部排列有关）
  - 插入(insert)可以用 `Merge` 实现
    - `insert` 的 $H_2$ 只会有一个值，这是它与普通 `merge` 最大的不同
    - 向一个空二项队列插入 $N$ 个值的时间复杂度是 $O(N)$，故可以视作平均消耗 $O(1)$
- `DeleteMin`
  1. FindMin，找到最小值在 $B_k$ #h(14em) \/\* $O(log N)$ \*\/
  2. Remove $B_k$ from $H$，得到 $H'$ #h(12.7em) \/\* $O(1)$ \*\/
  3. Remove root from $B_k$，并且生成一个包含 $k$ 个树的 $H''$#h(1.5em) \/\* $O(log N)$ \*\/
  4. Merge $H'$ and $H''$#h(18em) \/\* $O(log N)$ \*\/
== Implementation
- 思考儿子如何存储：注意到每个节点的儿子数不唯一，用多叉树方式相当于用空间换时间，而 left-child-next-sibling 的方式对空间更友好
- 思考树内部子树的存储顺序（注意不是二项队列的存储顺序）：从大到小更好，减少 Merge 找到要插入节点的时间损耗
- 结构声明
```c
typedef struct BinNode *Position;
typedef struct Collection *BinQueue;
typedef struct BinNode *BinTree; /* missing from p.176 */
struct BinNode {
    ElementType Element;
    Position LeftChild;
    Position NextSibling;
};
struct Collection {
    int CurrentSize; /* total number of nodes */
    BinTree TheTrees[MaxTrees];
};
```
- 树的合并 $T_p = O(1)$
```c
BinTree CombineTrees(BinTree T1, BinTree T2) { // equal-sized T1 and T2
    if (T1->Element > T2->Element) // attach the larger to the smaller one
        return CombineTrees(T2, T1);
    // insert T2 to the front of the children list of T1
    T2->NextSibling = T1->LeftChild;
    T1->LeftChild = T2;
    return T1;
}
```
- 二项队列的合并 $T_p = O(log N)$
```c
BinQueue Merge(BinQueue H1, BinQueue H2) {
  BinTree T1, T2, Carry = NULL;
  int i, j;
  if (H1->CurrentSize + H2-> CurrentSize > Capacity) ErrorMessage();
  H1->CurrentSize += H2-> CurrentSize;
  for (i=0, j=1; j<= H1->CurrentSize; i++, j*=2) {
    T1 = H1->TheTrees[i]; T2 = H2->TheTrees[i]; /*current trees */
    switch(4*!!Carry + 2*!!T2 + !!T1) { // carry, T2, T1
      case 0: /* 000 */
      case 1: /* 001 */ break;
      case 2: /* 010 */ H1->TheTrees[i] = T2; H2->TheTrees[i] = NULL; break;
      case 4: /* 100 */ H1->TheTrees[i] = Carry; Carry = NULL; break;
      case 3: /* 011 */ Carry = CombineTrees(T1, T2);
                        H1->TheTrees[i] = H2->TheTrees[i] = NULL; break;
      case 5: /* 101 */ Carry = CombineTrees(T1, Carry);
                        H1->TheTrees[i] = NULL; break;
      case 6: /* 110 */ Carry = CombineTrees(T2, Carry);
                        H2->TheTrees[i] = NULL; break;
      case 7: /* 111 */ H1->TheTrees[i] = Carry;
                        Carry = CombineTrees(T1, T2);
                        H2->TheTrees[i] = NULL; break;
    } // end switch
  } // end for-loop
  return H1;
}
```
- DeleteMin $T_p = O(log N)$
```c
ElementType DeleteMin(BinQueue H) {
  BinQueue DeletedQueue;
  Position DeletedTree, OldRoot;
  ElementType MinItem = Infinity; // the minimum item to be returned
  int i, j, MinTree; // MinTree is the index of the tree with the minimum item
  if (IsEmpty(H)) {PrintErrorMessage(); return-Infinity;}
  MinItem = FindMin(H); // Step 1: find the minimum item
  DeletedTree = H->TheTrees[MinTree];
  H->TheTrees[MinTree] = NULL; // step 2: remove the MinTree from H => H'
  OldRoot = DeletedTree; // Step 3.1: remove the root
  DeletedTree = DeletedTree->LeftChild; free(OldRoot);
  DeletedQueue = Initialize(); // Step 3.2: create H''
  DeletedQueue->CurrentSize = (1 << MinTree) - 1; // 2^{MinTree} - 1
  for (j = MinTree - 1; j >= 0; j--) {
    DeletedQueue->TheTrees[j] = DeletedTree;
    DeletedTree = DeletedTree->NextSibling;
    DeletedQueue->TheTrees[j]->NextSibling = NULL;
  } // end for-j-loop
  H->CurrentSize -= DeletedQueue->CurrentSize + 1;
  H = Merge(H, DeletedQueue); // Step 4: merge H' and H''
  return MinItem;
}
```
== Analysis
- 分析连续 $N$ 次插入的复杂度
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-25-12-08-40.png", width: 80%)
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-03-25-12-12-56.png", width: 80%)

#figure(caption: "heap复杂度总结",
  tbl(
    columns: 5,
    [], [Binary Heap], [Leftist Heap], [Skew Heap], [Binomial Heap],
    [Insert], [$O(log n)$], [$O(log n)$], [$O(log n)$], [$O(1)$],
    [Merge], [$O(n)$], [$O(log n)$], [$O(log n)$], [$O(log n)$],
    [DeleteMin], [$O(log n)$], [$O(log n)$], [$O(log n)$], [$O(log n)$],
    [Delete], [$O(log n$)], [$O(log n)$], [], [$O(log n)$],
    [DecreaseKey], [$O(log n)$], [$O(log n)$], [],[$O(log n)$],
    [Initialize],[$O(1)$],[$O(1)$],[$O(log n)$],[$O(1)$],
  )
)

= 过渡回
- 从这里开始，由数据结构部分进入算法分析部分，均为定义+例子的结构，尝试整理
#info(caption: "算法分析部分目录及例子")[
- 不全是 PPT 上的例子（来自 wyy 讲义）
- 可能会有重合（同一问题可以被不同方法解决）
- Backtracking（回溯法）
  + 八皇后问题
  + The Turnpike Reconstruction Problem 加油站重建问题
  + 拼棍子问题（PPT 没有）
  + Tic-tac-toe 三子棋
- Divide and Conquer（分治法）
  + 最大子序列和问题
  + 归并排序与快速排序
  + 逆序对计数
  + Closest Points Problem 最近点对问题
  + 矩阵乘法（wyy 讲义）
- Dynamic Programming（动态规划）
  + 斐波那契数列和爬楼梯
  + 加权独立集合问题
  + 0-1 背包问题
  + 矩阵乘法计算复杂度估计
  + 钢条切割问题，完全平方数的和
  + 最长公共子序列，最长回文字符串
  + Optimal Binary Search Tree 最优带权二叉搜索树
  + AllPairs Shortest Path 单源最短路径和全源最短路径
  + Activity Selection Problem 活动选择问题（变体：加权活动选择问题）
  + 最小化工时调度问题变体
  + 旅行商问题
  + #link("https://www.cnblogs.com/kangkang-/p/13493001.html", text(fill: gray.darken(40%))[（树的）最小支配集，最小点覆盖，最大独立集])
- Greedy Algorithms
  + Activity Selection Problem 活动选择问题（变体：活动调度问题）
  + Huffman Codes 哈夫曼编码
  + 任务调度问题（变体：最小化最大延时）
  + fraction 背包问题
  + 稳定匹配问题（不会）
- NP-Completeness
  + P：最短路径问题、欧拉回路问题、2-CNF 可满足性问题
  + NP：带负边最短路径无环问题、哈密顿回路问题、3-CNF 可满足性问题
  + NPC：clique problem $<->$ Vertex cover problem，\ ~~~~~~~~~~ 哈密顿回路问题 $<->$ 旅行商问题
- Approximation
  + 最小化工时调度问题贪心近似
  + Approximate Bin Packing(Next fit, First fit, Best fit)
  + 0-1 背包问题的近似解
  + The K-center Problem
  + 旅行商问题的 2-近似
  + 顶点覆盖问题的贪心 2-近似
- Local Search
  + 顶点覆盖问题：Metropolis 算法与模拟退火思想
  + 旅行商问题 2-近似解的局部搜索改进
  + Hopfield Neural Networks 的稳定构型与最大割问题
- Random Algorithm
  + 雇佣问题(naive, randomized, randomized-K)
  + QuickSort 的随机化
- Parallel Algorithm
  + The Summation Problem
  + PrefixSums Problem
  + Merge Problem($->$ Rank Problem)
  + Maximum Funding（算法一、算法二、算法三、算法四）
- External Sorting
  + 斐波那契初始化
  + 多路合并与多相合并
  + 缓存并行处理
  + 替换选择
]
= Lecture 6: Backtracking
== 定义与原理
- 设想，任何问题都可以通过以下方法解决：
  - 1. 生成所有可能的解
  - 2. 检查每个解是否满足条件
  - 3. 选择最优解
  - 但这样的方法时间复杂度显然太高
- 回溯法（backtracking）是一种解决问题的方法，它是一种暴力搜索的方法，通过不断地试错，寻找问题的解。与枚举法相比，它的核心在于通过剪枝(pruning)来减少搜索空间
  - The basic idea is that suppose we have a partial solution $(x_1, dots , x_i)$ where each $x_k in S_k$ for $1 =< k =< i < n$. First we add $x_(i+1) in S_(i+1)$ and check if $(x_1, dots , x_i, x_(i+1))$ satisfies the constrains. If the answer is “yes” we continue to add the next $x$, else we delete $x_i$ and *backtrack* to the previous partial solution $(x_1, dots , x_(i-1))$.
== 例子
=== 八皇后问题
- Step 1: Construct a game tree
- Step 2: Perform a depth-first search (post-order traversal) to examine the paths
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-01-10-57-52.png")

=== 加油站重建问题
- 给定 $N(N-1)\/2$ 个 distances，重建 $N$ 个加油站的位置，假定 $x_1=0$
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-01-11-06-00.png")
```c
bool Reconstruct (DistType X[], DistSet D, int N, int left, int right){
    /* X[1]...X[left-1] and X[right+1]...X[N] are solved */
    bool Found = false;
    if (Is_Empty(D)) return true; /* solved */
    D_max = Find_Max(D);
    /* option 1：X[right] = D_max */
    /* check if |D_max-X[i]|∈ D is true for all X[i]'s that have been solved */
    bool OK = Check(D_max, N, left, right); /* pruning */
    if (OK) {/* add X[right] and update D */
        X[right] = D_max;
        for (i=1; i<left; i++) Delete(|X[right]-X[i]|, D);
        for (i=right+1; i<=N; i++) Delete(|X[right]-X[i]|, D);
        Found = Reconstruct(X, D, N, left, right-1);
        if (!Found) {/* if does not work, undo */
            for (i=1; i<left; i++) Insert(|X[right]-X[i]|, D);
            for (i=right+1; i<=N; i++) Insert(|X[right]-X[i]|, D);
        }
    }
    /* finish checking option 1 */
    if (!Found) {/* if option 1 does not work, option 2: X[left] = X[N]-D_maxk */
        OK = Check(X[N]-D_max, N, left, right);
        if (OK) {
            X[left] = X[N] – D_max;
            for (i=1; i<left; i++) Delete(|X[left]-X[i]|, D);
            for (i=right+1; i<=N; i++) Delete(|X[left]-X[i]|, D);
            Found = Reconstruct (X, D, N, left+1, right);
            if (!Found) {
                for (i=1; i<left; i++) Insert(|X[left]-X[i]|, D);
                for (i=right+1; i<=N; i++) Insert(|X[left]-X[i]|, D);
            }
        } /* finish checking option 2 */
    } /* finish checking all the options */
    return Found;
}
```
- Backtracking 的一个模板
```c
bool Backtracking(int i)
{
    Found = false;
    if (i > N) return true; /* solved with (x1, ..., xN) */
    for (each xi ∈ Si) {
        /* check if satisfies the restriction R */
        OK = Check((x1, ..., xi) , R); /* pruning */
        if (OK) {
            Count xi in;
            Found = Backtracking(i+1);
            if (!Found)
                Undo(i); /* recover to (x1, ..., xi-1) */
        }
        if (Found) break;
    }
    return Found;
}
```
- 考虑如何构建搜索树：
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-01-11-40-24.png")
  - 两颗同个问题的不同搜索树，上面的倾向于用值域较小的节点构建
  - 上面这个剪枝的效率更高；下面这个好像剪枝的概率更高（实际上一般认为相同）
  - 一般来说认为上面这个更好
=== 拼棍子问题
  - 给定 $N$ 个棍子，长度分别为 $L_1, L_2, dots, L_N$，尽可能拼出长度较小（也即数量更多）的*等长*棍子
  - 思路
    - 枚举长度，算出棍子的数量
    - 接下来用回溯法尝试是否可拼出这么多根
    - 从大到小尝试放入棍子而非从小到大，减少搜索空间（也就是上图的第一棵树）
=== 三子棋(Tic-tac-toe)
  - 与之前例子不同，这里要同时考虑两边对手的决策，即 Minimax strategy
  - 为了决策需要量化棋盘的状态，即评估函数
    - 这里的评估函数不用蒙特卡洛，而是简单的分别认为某一方不再下棋，自己有多少种获胜的可能，其差值作为评估函数
  - 一边最小化评估函数，一边最大化评估函数
  - 剪枝：$alpha-beta$ 剪枝
  - 略

= Lecture 7: Divide and Conquer
== 定义与原理
- #bluet[Divide]: 把问题分解成多个子问题
- #bluet[Conquer]: 用递归的方式解决每个子问题
- #bluet[Combine]: 把解合并起来
- 其时间复杂度可以这样计算
$ T(N) = a T(N\/b) + F(N) $
== 例子
1. The maximum subsequence sum: $O(N log N)$
2. Tree traversals: $O(N)$
3. Mergesort and quicksort: $O(N log N)$
=== Closest Points Problem
给定平面上 $N$ 个点，找到最近的点对。最 Naive 的想法是遍历两遍，复杂度为 $O(N^2)$。下面考虑 Divide and Conquer:

对 x 轴砍一刀，分成左右两边，分别找左右两边的最小边，然后需要找横跨切分轴的点对。考虑利用已有信息剪枝，只考虑距离切分轴 $d$ 内的点。同时，对每一个点，只需考虑纵轴上距离 $d$ 内的点。
```c
/* points are all in the strip and sorted by y coordinates */
/* so just scan the lower part strip */
for (i = 0; i < NumPointsInStrip; i++)
    for (j = i + 1; j < NumPointsInStrip; j++) {
        if (Dist_y(Pi, Pj) > delta)
            break;
        else if (Dist(Pi, Pj) < delta)
            delta = Dist(Pi, Pj);
    }
// 思考这个问题的代码如何编写
```
For any $p_i$, at most #redt[$7$] points are considered, i.e. the second for-loop is excuted at most 7 times.
== 详细计算时间复杂度
- Details to be ignored:
1. if (N / b) is an integer or not
2. always assume T( n ) = Θ( 1 ) for small n
- Three methods for solving recurrences:
1. Substitution method
2. Recursion-tree method
3. Master method
- *Substitution method*
  - Guess, then prove by induction
  - 一个重点（易错点）在于归纳时需要证明 #bluet[exact form]
  - 思考如何做足够好的猜测
- *Recursion-tree method*
  - 边算边猜；一般不用于严格证明，仅是猜测
  - 注意 $a^(log_b N)=N^(log_b a)$
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-08-11-21-55.png")
- *Master method*（主方法，也叫求偶法）
  - 并没有 cover 所有情况，而是以不同角度对三种典型情况直接给出答案
- 角度一：比较根节点和叶子节点的开销
  + 根节点开销小
  + 开销差不多
  + 根节点开销大
  $
  T(N) = cases(
    Theta(N^(log_b a)) &"if" f(N) = O(N^(log_b a - epsilon)),
    Theta(N^(log_b a) log N) &"if" f(N) = Theta(N^(log_b a)),
    Theta(f(N)) &"if" f(N) = Omega(N^(log_b a + epsilon)) "and" a f(N\/b) =< c f(N) (c < 1)
  )
  $
- 角度二：比较分治与合并的开销，是角度一的推论
  + 分治开销小
  + 开销差不多
  + 分治开销大
  $
  T(N) = cases(
    Theta(N^(log_b a)) &"if" a f(N\/b)=K f(N) (K > 1),
    Theta(f(N)log_b N) &"if" a f(N\/b)=f(N),
    Theta(f(N)) &"if" a f(N\/b)=kappa f(N) (kappa < 1),
  )
  $
  - 注意条件中要求 $=$ 而非数量级上的关系，本质上而言比较了 $N$ 的数量级而难以处理 $log N$，这引出下一个形式
- 角度三：比较任务的个数与任务的规模（较强的形式，涵盖了角度一）
  $ T(N) = a T(N\/b) + Theta(N^k log^p N) "where" a >= 1, b > 1, p >= 0 $
  $
  T(N) = cases(
    O(N^(log_b a)) &"if" a > b^k "（任务大于规模）",
    O(N^k log^(p+1) N) &"if" a = b^k "（任务等于规模）",
    O(N^k log^p N) &"if" a < b^k "（任务小于规模）"
  )
  $

= Dynamic Programming
- 递归算法的一个问题是，有些子问题会被重复计算，这就是动态规划的出发点
  - Solve sub-problems just once and save answers in a table
== 例子
=== 斐波那契数列
- 原始问题 $T(N) >= F(N)$
- 状态转移方程：$F(N) = F(N-1) + F(N-2)$
- 使用动态规划，而且只需存储*最近的两个值*，$T(N) >= O(N)$
```C
int Fibonacci(int N)
{
    int i, Last, NextToLast, Answer;
    if (N <= 1) return 1;
    Last = NextToLast = 1; /* F(0) = F(1) = 1 */
    for (i = 2; i <= N; i++) {
        Answer = Last + NextToLast; /* F(i) = F(i-1) + F(i-2) */
        NextToLast = Last; Last = Answer; /* update F(i-1) and F(i-2) */
    } /* end-for */
    return Answer;
}
```

=== Ordering Matrix Multiplications
$
M_(1 |10 times 20|) * M_(2 |20 times 50|) * M_(3 |50 times 1|) * M_(4 |1 times 100|)
$
- 方法一：$50 times 1 times 100 + 20 times 50 times 100 + 10 times 20 times 100 = 125,000$
$
M_(1 |10 times 20|) * (M_(2 |20 times 50|) * (M_(3 |50 times 1|) * M_(4 |1 times 100|)))
$
- 方法二：$20 times 50 times 1 + 10 times 20 times 1 + 10 times 1 times 100 = 2,200$
$
(M_(1 |10 times 20|) * (M_(2 |20 times 50|) * M_(3 |50 times 1|))) * M_(4 |1 times 100|)
$
- 思考有多少种计算方式，令 $b_n$ 为计算 $M_1 dot M_2 dots.c M_n$ 的不同方式，如何计算 $b_n$？
  - 令 $M_(i j) = M_i dots.c M_j$, then $M_(1 n) = M_1 dots.c M_n = M_(1 i) dot M_(i+1,n)$
  - 因为括号扩在中间的话，最终它还是归属到两边中的某一个
  - $=> b_n = sum_(i=1)^(n-1)b_i b_(n-i)$, where $n > 1$ and $b_1 = 1$
  - 由卡特兰数的性质 $b_n = O(4^n / (n sqrt(n)))$，这是不可接受的
- 用动态规划算法实现
  - 注意到原问题满足最优子结构性质，即最优解包含了子问题的最优解
  - 设 $M_(i j)$ 为 $r_(i-1) times r_i$ 的矩阵，$m_(i j)$ 为计算 $M_i dots.c M_j$ 的方式数，那么：
  - 这样状态数为 $n^2$（思考为什么），每个状态的复杂度为 $O(n)$，因此总复杂度为 $O(n^3)$
  $
  m_(i j) = cases(
    0 &"if" i = j,
    display(min_(i =< l < j))(m_(i l) + m_(l+1, j) + r_(i-1) r_l r_j) &"if" j < i
  )
  $
  - 其状态转移方程为 $F[i][j] = display(min_k) (F[i][k] + F[k+1][j] + r_(i-1) r_k r_j)$
  - 这是一种很自然的状态方程，但不适合代码实现。试想，我们要算 $1 wave 4$ 的乘积，其中会用到 $3 wave 4$，但此时 $3 wave 4$ 还没算出来（如果以 i j 作为循环的话）
  - 另外一种状态转移方程（第一维严格递增，同时显示出问题的规模），更适合代码实现
    - 计算 $K+1$ 个矩阵的乘积，最左边为 $i$（$k$ 即为原来的 $j-i$），$F[0][i]=0$
      $ F[K][i] = display(min_(l=0)^(K-1)) {F[l][i]+F[K-l-1][l+1] + r_(i-1) r_(l+i) r_(i+K)} $
    - 或者（即下面代码的实现）
      $ F[K][i] = display(min_(l=i)^(K+i-1)) {F[l-i][i] + F[K+i-l-1][l+1] + r_(i-1) r_l r_(i+K)} $
```c
/* r contains number of columns for each of the N matrices */
/* r[0] is the number of rows in matrix 1 */
/* Minimum number of multiplications is left in M[1][N] */
void OptMatrix(const long r[], int N, TwoDimArray M)
{
    int i, j, k, L;
    long ThisM;
    for (i = 1; i <= N; i++)
        M[i][i] = 0;
    for (k = 1; k < N; k++) /* k = j - i */
        for (i = 1; i <= N - k; i++) { /* For each position */
            j = i + k; M[i][j] = Infinity;
            for (L = i; L < j; L++) {
                ThisM = M[i][L] + M[L+1][j] + r[i-1] * r[L] * r[j];
                if (ThisM < M[i][j]) /* Update min */
                    M[i][j] = ThisM;
            } /* end for-L */
        } /* end for-Left */
}
```
=== Optimal Binary Search Tree
- 给定 $N$ 个词 $w_1 < w_2 < dots < w_N$，以及 $N$ 个概率 $p_0, p_1, dots, p_N$，构建一棵静态二叉搜索树，使得搜索的期望代价 $T(N) = display(sum_(i=1)^N p_i dot (1+d_i))$ 最小
- 确定一个根节点后，其左右子树就确定了（分治法的感觉来了）
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-15-11-12-55.png",width:93%)
  - 依旧是最优子结构问题（左子树与右子树独立）
  - 思考怎么把它变成非最优子结构问题，比如
    + 加一个约束，度数为 2 的节点不超过 $K$ 个
    + 相邻节点之间首字母的字典序不能超过 2
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-15-11-22-05.png")

=== 单源最短路径算法(Bellman_Ford)
- $D^k [s][v]$ 表示从 $s$ 到 $v$ 最多经过 $k$ 条边的最短路径
$
D^k [s][v] = min cases(
                    D^(k-1) [s][v],
                    display(min_((w,v)in E)) {D^(k-1)[s][w]+l_(w v)}
                  )
$
- 复杂度 $O(|V| dot |E|)$
  - 比较 Dijkstra 的 $O(|E| dot T_(d k) + |V| dot T_(e m))$

=== All-Pairs Shortest Path(Floyd-Warshell)
- 对所有点对 $(v_i, v_k)~~(i != j)$，找到最短路径
- 方法一，用 $|V|$ 次单源最短路径算法，复杂度 $O(|V|^3)$(works fast on sparse graph)
- 方法二，动态规划算法
  - $D^k [s][v]$ 表示从 $s$ 到 $v$ 只经过 $1,2,dots, k$ 这些内部顶点的最短路径
  $
  D^k [s][v] = min cases(
                      D^(k-1) [s][v],
                      D^(k-1)[s][k] + D^(k-1) [k][v],
                    )
  $
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-04-15-11-31-20.png")
  - 跳板的添加顺序不影响最后结果（思考为什么）
  - 复杂度 $O(N^3)$
```c
/* A[ ] contains the adjacency matrix with A[i][i] = 0 */
/* D[ ] contains the values of the shortest path */
/* N is the number of vertices */
/* A negative cycle exists iff D[i][i] < 0 */
void AllPairs(TwoDimArray A, TwoDimArray D, int N)
{
    int i, j, k;
    for (i = 0; i < N; i++) /* Initialize D */
        for (j = 0; j < N; j++)
            D[i][j] = A[i][j];
    for (k = 0; k < N; k++) /* add one vertex k into the path */
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
            if (D[i][k] + D[k][j] < D[i][j])
                /* Update shortest path */
                D[i][j] = D[i][k] + D[k][j];
}
```

=== Product Assembly

- 不想写了，写了也不如 wyy 的清晰，转战 wyy 讲义！
#hline()
- 总结，什么样的问题可以用动态规划？
  + 满足最优子结构——把子问题的最优解替换进原问题，看看会不会变差（是否会影响原问题的最优解）
  + 重叠子问题——不同问题调用同一子问题，它的最优解是否相同
- 代码技巧
  - 动态规划的 for 顺序很麻烦，可以用*记忆化搜索*的写法，看着是个搜索，但本质还是动态规划

= Greedy Algorithms
== 定义
- 优化问题：优化函数和约束条件
- 贪心方法：每一步都根据某种*贪心策略*选择最优局部解，这个解在之后不会被改变
- 什么时候用贪心比较好
  + 只有局部最优解等于全局最优解，贪心算法才 work
  + 但有时即使局部最优解只是全局最优解的近似，全局最优解的求解复杂度太高，就会采用贪心
- 贪心方法的证明：
  + 正确性（可行解）
  + 最优性
    + 贪心选择性质：根据贪心策略选出的解是否是最优解的一部分（选出的这个解跟其它解相比至少不会变差），即贪心选择总是安全的
    + 最优子结构：用贪心策略选择 $a_1$ 之后得到子问题 $S_1$，那么 $a_1$ 和子问题 $S_1$ 的最优解合并是否可以得到原问题的最优解
- 一般贪心方法背后都会有一个臃肿的动态规划方法
  - 在动态规划方法中，每个步骤都要进行一次选择，但选择通常依赖于子问题的解。但在贪心算法中，我们总是做出当时看来最佳的选择，然后求解剩下的唯一的子问题

== 例子
=== Activity Selection Problem
- $n$ 个活动在同一个场地举行，每个活动 $i$ 都有一个开始时间 $s_i$ 和结束时间 $f_i$，只有一个活动可以在同一时间举行（无 overlap），问最多能举行多少个活动
- dp 方法 1：
  - 记事件 $a_1, a_2, dots, a_n$，其中 $a_i wave a_j$ 记作 $S_(i j)$
  $ c_(i j)=cases(
    0 ~~~ &"if" S_(i j)=emptyset,
    max_() {c_(j k)+c_(k j)+1} ~~~ &"if" S_(i j)!=emptyset
  )  $
  - 冗余（计算顺序）
  - 思考如何 $O(N^2)$ 实现这个方法
- dp 方法 2（一维）：
  $ c_i = cases(
    1 ~~~ &"if" i = 1,
    max{c_(i-1), c_(k(i))+1} ~~~ &"if" i != 1,
  ) $
  - 其中 $c_i$ 表示从 $1$ 到 $i$ 个事件最多能选多少个，$c_(k(i))$ 表示选择了 $a_i$，去掉那些跟它不兼容的事件（结束时间迟于 $a_i$ 的开始时间）
- Greedy 方法：
  - Greedy Rule 1: 选择开始最早的，不太行
  - Greedy Rule 2: 选择时间间隔最短的，不太行
  - Greedy Rule 3: 选择冲突最少的，不太行
  - Greedy Rule 4: 选择结束时间最早的（释放最早），可以
  - 正确性证明
  - 复杂度: 本身只用 $O(N)$，受制于 $O(N log N)$ 的排序

=== Huffman Codes
- 定义不想写了
- 算法，用 min-heap 存储出现频率，用贪心策略选择最小的两个，合并成一个，直到只剩一个——$T = O(C log C)$

= NP-Completeness
- NPC 问题，回忆
  - Euler circuit problem，多项式时间可解
  - Hamilton circuit problem，目前多项式时间不可解
  - Single-source unweighted shortest-path problem，多项式时间可解
  - Single-source unweighted longest-path problem，目前多项式时间不可解
- 停机问题
- 确定性图灵机和非确定性图灵机
  - 非确定性图灵机：确保每一步都是对的
- P 问题：确定性图灵机能在多项式时间内解决的问题
- NP(Nondeterministic polynomial-time) 问题：非确定性图灵机能在多项式时间内解决的问题，或确定性图灵机能在多项式时间内验证解的问题
  - $"P" subset "NP"$, but $"P" subset.neq "NP"$？这一问题暂时无人能解答
- 把所有 $"NP"$ 问题能归约到的问题集合称为 $"NPH"$ 问题，它们不一定都属于 $"NP"$；如果它又属于 $"NP"$，则称为 $"NPC"$ 问题
- NP-Complete Problems(NPC)，是 NP 问题中最难的那一类，所有 NP 问题都可以归约为 NPC 问题
  - 证明 NPC 的步骤
    1. 证明为 NP 问题
    2. 证明多项式归约 $B attach(=<, br: p) A $
      1. 选取两个问题实例
      2. 证明 $A_Y -> B_Y$
      3. 证明 $A_N -> B_N <=> B_Y -> A_Y$
- Formal-language Theory
- 旅行商问题，简单来说可以这么理解：求图的最短哈密尔顿回路
  - 看不懂
- 弃坑，看 wyy 讲义
- 若只看是否多项式可解和是否可解
$"P" <- "NPC",~ "NPH",~ "NP" <- "undecidable"$

= Approximation
== 定义
- 对困难的问题，使用近似算法
#definition(title: "近似比")[
  对于优化问题，输入规模为 $n$，给定一个算法 $A$，其解为 $S_A$，最优解为 $S_O$，则 $A$ 的近似比为 $rho(n) = max{S_A/S_O, S_O/S_A}$，我们称 $A$ 是 $rho(n)-"approximation"$ 算法
]

- 近似方案(approximation scheme)的定义
  - 比如 $O(n^(2\/epsilon))$ 随着 $epsilon$ 的减少，时间复杂度呈指数级上升；对于这类对于特定的 $epsilon$，时间复杂度在多项式时间的算法我们称为 PTASpolynomial-time approximation scheme)
  - 而 $O((1\/epsilon)^2 n^3)$，这类算法和 $n$ 以及  $epsilon$ 都呈现多项式的关系，对于这类算法可以对近似比的要求更加严格。对于这类关于 $epsilon$ 和 $n$ 都呈多项式时间复杂度的算法我们称为 FPTAS(*fully* polynomial-time approximation scheme)

== 例子
=== Approximate Bin Packing
- 给定 $n$ 个物品，每个物品的大小 $s_i in (0,1)$，箱子的大小为 $1$，问最少需要多少个箱子
- Next Fit 近似法
  ```c
  void NextFit ()
  {
      read item1;
      while (read item2) {
          if (item2 can be packed in the same bin as item1)
              place item2 in the bin;
          else
              create a new bin for item2;
          item1 = item2;
      } /* end-while */
  }
  ```
#theorem()[
  Next Fit 算法的近似比为 $rho(n) = 2$，最优解为 $M$ 时，next fit 不会产生大于 $2M-1$ 的解
]

- First Fit 和 Best Fit 近似法
  ```c
  void FirstFit ()
  {
      while (read item) {
          scan for the first bin that is large enough for item;
          if (found)
              place item in that bin;
          else
              create a new bin for item;
      } /* end-while */
  }
  ```
  - Claim: The *first-fit* heuristic leaves at most one bin less than half full
  - 找第一个满足条件的箱子，可以用 $O(N log N)$ 实现；此外还有类似的 Best Fit 算法（优先恰好满的箱子），也是 $O(N log N)$
#theorem()[
  First Fit 算法对最优解为 $M$ 的问题，不会产生大于 $17(M-1)\/10$ 的解，即 $rho(n) = 1.7$，Best Fit 算法也为 $rho(n) = 1.7$（没有证明）
]

- 这三种近似方法都是 On-line Algorithms，只能看到当前的物品，不能看到后面的物品，并且不能改变之前的决策
  - 可以构造证明，在线算法解决 Bin Packing 问题，近似比为 $rho(n) = 5/3$
- Off-line Algorithms，离线算法
  - trouble maker: large items
  - Solution: 先排个序（降序），然后用 First(best) Fit 算法，近似比为 $rho(n) = 11/9$

== 背包问题
- fractional version: 可以切分
  - 可以用贪心算法得到最优解，把所有物品都切碎，然后按价值排序放入（相当于按性价比排序）
  - 一个性质是，只有一个物品会被切分放入，思考为什么
- 0-1 version(NP-hard)
  - 可以用动态规划方法解精确解
  - 如果我们仍旧用贪心方法求最大价值*或*最大性价比，那么近似比为 $rho(n) = 2$
#proof()[
  $
  cases(reverse: #true, p_max =< P_"opt" =< P_"frac",
  p_max =< P_"greedy",
  P_"frac" =< P_"greedy" + p_max) => P_"opt" \/ P_"greedy" =< 1 + p_"max" \/ P_"greedy" =< 2
  $
]
- 01 背包问题的基于价值的动态规划算法

== The K-center Problem
- 略

= Local Search
== 定义
- Solve problems approximately, aims at a local optimum
- #bluet[Local]
  - 在可行集中定义 neighborhood
  - 定义目标函数和找到 neighborhoods 中的最优解
- #bluet[Search]
  - 从一个初始解开始，不断改进，直到找到一个局部最优解
  - 局部最优解在无法继续改进时得到
- Neighbor Relation
  - $S wave S'$: $S'$ 可以由 $S$ 通过一次 *small modification* 得到，把 $S$ 的邻居集合称为 $N(S)$

== 例子
=== Vertex cover problem
- 给定无向图，找到它的最小顶点子集，使得每条边至少有一个端点在这个子集中（判定问题，是否存在 $|V'|=<K$；生成问题，得到最小顶点子集）
- 可行集 $cal(F)S$: 所有顶点的集合
- $"cost"(S)=|S|$
- $S wave S'$: 从 $S$ 中删除一个节点，使得 $S'$ 仍然是一个顶点覆盖
- search: 从 $S=V$ 开始，不断删除一个节点，直到不能再删除为止
- 改进(Metropolis Algorithm)，以一定概率允许增加节点
  - 模拟退火的思想
```C
SolutionType Metropolis()
{
    Define constants k and T;
    Start from a feasible solution S ∈ FS ;
    MinCost = cost(S);
    while (1) {
        S’ = Randomly chosen from N(S);
        CurrentCost = cost(S’);
        if (CurrentCost < MinCost) {
           MinCost = CurrentCost; S = S’;
        }
        else {
            With a probability , let S = S’;
            else break;
        }
    }
    return S;
}
```
=== Hopfield Neural Networks
- 给定带权（整数）无向图，为顶点分配两种状态，权重大于 0 表示这条边希望两个节点有不同状态，权重小于 0 表示希望两个节点有相同状态。权重的绝对值表示希望程度的大小。
#definition()[
- 对边：\ In a configuration $S$, edge $e = (u, v)$ is *good* if $w_e s_u s_v < 0 (w_e < 0 "iff" s_u = s_v)$; otherwise, it is *bad*.
- 对顶点 \ satisfied if 以它为顶点的边的分数和 $=< 0$
- 对整个图 \ stable if all nodes are satisfied
]
- 该问题只要求满足而不要求最优，因此不讨论局部最优和全局最优（在后面例子中讨论）
```c
ConfigType State_flipping()
{
    Start from an arbitrary configuration S;
    while (!IsStable(S)) {
        u = GetUnsatisfied(S);
        s_u = -s_u;
    }
    return S;
}
```
- 思考，这个算法是否一定会终止？
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-13-11-08-59.png")
- 复杂度：$O(w_"max" |E|)$，伪多项式时间算法

=== The Maximum Cut Problem
- 给定带权（正数）无向图，为顶点分配两种状态，使得链接不同顶点状态的边的权值之和最大 $ w(A,B):=sum_(u in A, v in B) w_(u v) $
  - 整个问题其实就是上个问题的特例（权重全为正）
- 优化函数：本来是 $max w(A,B)$，转化为上一个问题：好边的权重和（本质是一样的）
- 终止条件同 Hopfield Neural Networks 一样，且一定可以终止
- 可行集 $cal(F)S$: any partition $(A,B)$
- $S wave S'$: 交换一个顶点的状态
- 这是一个近似的局部最优解
  - 对 $A$ 中的某个特定点，如果把它划到 $B$，它的边权重和为 $sum_(v in A) w_(u v)$，由于是局部最优解，因此不变是最好的，有第一条式子
  - 遍历 $A$ 中的 $u$，式子左边对 $u$ 和 $v$ 分别遍历了一遍（比如 $e_(1 2)$ 被计算了两次），于是得到第二条式子，得到了点集 $A$ 内的边权和（可以理解为浪费了）与当前局部最优解之间的 $1\/2$ 关系
  - 由于 $A, B$ 地位是均等的，我们对 $B$ 也进行一次这样的操作
  - 显然最优解小于等于所有边权和，而这通过刚才的式子又能转化为 $2$ 倍的局部最优解
  - by the way，由 $w(A, B) =< w^*(A, B)$，可得到 $w^*(A, B)$ 大于等于总边权的一半
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-13-11-28-31.png")
- 虽然是近似算法，但复杂度依旧不是多项式时间
  - 考虑提前终止
    - 为什么我感觉这里应该是 $epsilon/(|V|) w(A,B)$？但是做题还是按 PPT 来
    - 思考第二个 claim 怎么证明（不等式 $(1+1/x)^x >= 2 ~~ (x>=1)$，取 $epsilon$ 使其满足要求，那么每 $n\/epsilon$ 次都至少提升两倍）
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-13-11-44-15.png")
  - 考虑每步找更好的邻居
    - 每一步多翻转一个点，要求这个点是当前已经翻转过的基础上再翻转一个点的最好的情况($O(N)$)，一直这样翻到 $(A, B)$ 倒置成 $(B, A)$。当然这样翻有可能会发现其中几步还不如原始版本。但没关系，我们选择这 $n-1$ 个邻居中最好的那个跳过去，并且在这 $n-1$ 个邻居都比原始版本差的情况下算法终止
    - 思考 K-L flip 跟原本有什么不同
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-13-11-54-15.png")

= Randomized Algorithms
- 定义略，没啥好说的

== 例子
=== The Hiring Problem
- 面试和聘用的代价分别为 $C_i$ 和 $C_h$，前者远小于后者，设共有 $N$ 个应聘者，$M$ 个受聘者
- 总代价为 $C = N C_i + M C_h$
- Naive solution：面试每个人，如果他比之前的都好，就聘用他
  ```c
  int Hiring (EventType C[], int N)
  { /* candidate 0 is a least-qualified dummy candidate */
      int Best = 0;
      int BestQ = the quality of candidate 0;
      for (i=1; i<=N; i++) {
          Qi = interview(i); /* Ci */
          if (Qi > BestQ) {
              BestQ = Qi;
              Best = i;
              hire(i); /* Ch */
          }
      }
      return Best;
  }
  ```
  - 存在情况 candidates come in increasing quality order，$O(N C_i + N C_h)$，即每个人都被雇佣
- 假设 candidates arrive in random order
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-20-10-23-09.png")
  - 实现上，只需要在开始时进行一个随机，比如，为每个人随机赋一个值，然后按这个值排序
- Online Hiring Algorithm – hire only once
  - 前 k 个人是练手的，无论怎么样都不会选；然后，只要碰到一个最好的，直接就选了，后面的都不看了
  ```c
  int OnlineHiring ( EventType C[ ], int N, int k )
  {
      int Best = N;
      int BestQ = -∞;
      for (i=1; i<=k; i++) {
          Qi = interview(i);
          if (Qi > BestQ) BestQ = Qi;
      }
      for (i=k+1; i<=N; i++) {
          Qi = interview(i);
          if (Qi > BestQ) {
              Best = i;
              break;
          }
      }
      return Best;
  }
  ```
  - 思考这个算法选出真正最好的应聘者的概率，先考虑第 $i$ 个应聘者是最好的可能性，这等价于两个事件
    + 最好的应聘者在位置 $i$
    + $k+1$ \~ $i-1$ 没有被雇佣，这等价于前 $i-1$ 个人中最好的在前 $k$ 个人当中
  - 于是 $Pr(S_i)=k/(N(i-1))$，$Pr(S)=k/N sum_(i=k)^(N-1) 1/i$
  - 因此能选到最好的人的概率是 $k/N ln(N/k) =< Pr[S] =< k/N ln((N-1)/(k-1))$，求导，选取 $k=ceil(N/e) "or" floor(N/e)$

=== Quicksort
- Quick sort 的分析那里，把子问题按照 $N(3/4)^(j+1) =< |S| =< N(3/4)^j$ 的规模分类
- Type j 的子问题最多有 $N \/ N(3/4)^(j+1)$ 那么多，每个都放缩到 $N(3/4)^j$ 的规模，于是这一种子问题的期望总代价为 $O(N)$
- 而总共有 $O(log_(4\/3) N)$ 类子问题，所以总代价为 $O(N log N)$

= Parallel Algorithms
- To resolve access conflicts
  - Exclusive-Read Exclusive-Write (EREW)
  - Concurrent-Read Exclusive-Write (CREW)
  - Concurrent-Read Concurrent-Write (CRCW)
    - Arbitrary rule
    - Priority rule (P with the smallest number)
    - Common rule (if all the processors are trying to write the same value)
- PRAM(Parallel Random Access Machine) 模型
- WD(Work-Depth) 模型
- Measuring the performance
  - Work load – total number of operations: $W(n)$
  - Worst-case running time: $T(n)$
  + $W(n)$ operations and $T(n)$ time
  + $P(n) = W(n)/T(n)$ processors and $T(n)$ time (on a PRAM)
  + $W(n)/p$ time using any number of $p =< W(n)/T(n)$ processors (on a PRAM)
  + $W(n)/p + T(n)$ time using any number of p processors (on a PRAM)
  - All asymptotically equivalent

== 例子
=== The summation problem
- 输入 $N$ 个数字，输出它们的和
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-10-15-31.png")
#algo(caption: "PRAM model")[
  ```typ
  for Pi , 1 ≤ i ≤ n pardo
      B(0, i) := A( i )
      for h = 1 to log n do
          if i ≤ n/2h
              B(h, i) := B(h-1, 2i-1) + B(h-1, 2i)
          else stay idle
      end for
      for i = 1: output B(log n, 1);
      for i > 1: stay idle
  end for
  ```
]
- WD presentation
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-10-29-47.png")
- $T(N)=log N, W(N)=N$

=== Prefix-Sums
- 利用 Balanced Binary Trees 并行
#fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-11-01-21.png")

=== merge
- 利用 Partitioning 并行
  - 先做简化，假设 $A, B$ 中对应元素都不同，$n=m$，且都是 $2$ 的次幂
- 先把 Merge 问题转化为 rank 问题
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-11-28-00.png")
- 再思考如何解决 rank 问题，三种方法
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-11-35-34.png")
  - 以及 Parallel Ranking
    - 思考四种 cases，为什么这样划分是成立的
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-11-41-49.png")

=== Maximum Funding
- 找到最大值的问题
- 串行算法 $T(n)=W(n)=O(N)$
- 并行算法一：这可以由把 The summation problem 中的 "+" 改为 "max"，故复杂度为 $T(n)=O(log n), W(n)=O(n)$
- 并行算法二：让它们两两比对
  - access conflicts 不用解决（因为都是写 $1$）
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-11-58-38.png")
- 并行算法三(Doubly-logarithmic Paradigm)：
  - 3.1: 先用 $sqrt(n)$ partition，子问题用串行方法，算出的子问题解用并行算法二。这种方法多套几次
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-12-05-12.png")
  - 3.2: 先用 $log log n$ partition，子问题用串行方法，$n\/h$ 个子问题用并行算法 3.1
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-12-11-36.png")
- 并行算法四(Random Sampling)：
  - 第一步，$n^(7\/8)$ 个处理器每个随机抽样放到内存中某个位置作为 $B$（可能重复），深度为 $O(1)$，总工作量为 $O(n^(7\/8))$
  - 第二步，把 $B$ 分为 $n^(3\/4)$ 个 $n^(1\/8)$ 块，使用并行算法二（两两比对）方法找到每个块的最大值，得到 $C$，深度为 $O(1)$，总工作量为 $O(n^(3\/4) dot (n^(1\/8))^2)=O(n)$
  - 第三步，把 $C$ 分为 $n^(1\/2)$ 个 $n^(1\/4)$ 块，使用并行算法二（两两比对）方法找到每个块的最大值，得到 $D$，深度为 $O(1)$，总工作量为 $O(n^(1\/2) dot (n^(1\/4))^2)=O(n)$
  - 第四步，对 $D$ 使用并行算法二（两两比对）方法找到最终的最大值，深度为 $O(1)$，总工作量为 $O((n^(1\/2))^2)=O(n)$
  - 第五步，以一定机制循环以上四步（所有的 $N$ 个元素和这个选出来的最大数 $M$ 比较，如果更大就丢到一个大小为 $n^(7\/8)$ 的数组中的随机位置。利用刚刚算法再来一遍）
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-12-20-47.png")
  #fig("/public/assets/Courses/ADS/ads笔记/img-2024-05-27-12-21-02.png")

= External Sorting
- 不记了
- 总结三个与数据库中外排的区别
  + 数据库中只有一个 tape，在 tape 中不断 seek
  + 数据库中考虑 $b_b$，即一个归并段内多个 block，但 ADS 没有明显地考虑（最后考虑 pipeline 时顺带作用）
  + 数据库中没有考虑 pipeline 的作用（即把 I/O 分散到计算的过程），因为数据库中认为 CPU 很快，压根就没算内部排序的时间