---
order: 2
---

# FDS 易错题解析
## Hw 1
- Q: The Fibonacci number sequence {$F_N$} is defined as: $F_0 = 0$, $F_1 = 1$, $F_N = F_{N − 1} + F_{N − 2}, N=2, 3, ...$ The space complexity of the function which calculates $F_N$ recursively is: A. $O(logN)$; B. $O(N)$; C. $O(F_N)$; D. $O(N!)$
- A: B, O(N)。因为算完了可以扔
<br>

- Q: For the following piece of code， the lowest upper bound of the time complexity is $O(N^3)$.
    ```c
    if (A > B){
        for (i=0; i<N*2; i++)
            for (j=N*N; j>i; j--)
                C += A;
    }
    else {
        for (i=0; i<N*N/100; i++)
            for (j=N; j>i; j--)
                for (k=0; k<N*3; k++)
                    C += B;
    }
    ```
- A: T. 注意审题，不要被坑
<br>


## Hw 2


## Hw 3
- Q: Push 5 characters ooops onto a stack. In how many different ways that we can pop these characters and still obtain ooops
- A: 5. 第一个就是 o1 push 进去后，分两个情况，要么此时 pop，要么此时 push，然后依次讨论就行了（p 和 s 肯定是 o 们都 pop 完了，然后依次先 push 后 pop 的，所以只需要考虑 o1o2o3）。
<br>


## Hw 4
- Q: There exists a binary tree with 2016 nodes in total, and with 16 nodes having only one child.
- A: 假设没有孩子的结点（叶结点）个数为 n₀，只有一个孩子的结点（度为 1 的结点）个数为 n₁，有两个孩子的结点（度为2的结点）个数为 n₂。则 n₀ + n₁ + n₂=2016
∵n₀ = n₂ + 1（二叉树的性质：叶结点个数等于度为 2 的结点个数加 1）
∴n₀ + n₁ + n₂ = 2016 ⇨ n₂ + 1 + 16 + n₂ = 2016 ⇨ 2n₂ = 1999
<br>

- Q: Given a tree of degree 3. Suppose that there are 3 nodes of degree 2 and 2 nodes of degree 3. Then the number of leaf nodes must be _____.
- A: nodes = 3 * 2 + 2 * 3 + leaves * 0 + 1(node) = 13. Also nodes = 3 + 2 + leaves
前者是用每个节点的孩子数量（度数）计算总和，所以需要加上根节点；后者是用不同度数的节点直接相加
<br>


## Hw 5
- Q: Among the following binary trees, which one can possibly be the decision tree (the external nodes are excluded) for binary search?
- A: 不是很懂这个决策树什么意思，但是可以用判定折半查找二叉树的方法来做。
也就是默认中序遍历按序填上数字，然后判断是否出现向上向下取整的矛盾
参考：[下列二叉树中，可能成为折半查找判定树（不含外部结点）的是（）-CSDN博客](https://blog.csdn.net/qq_41754065/article/details/106590844)
<br>


## Hw 6
- Q: In a max-heap with n (>1) elements, the array index of the minimum key may be __.
- Answer:
    A:1
    Wrong: it’s the largest
    B:$\lfloor n/2 \rfloor-1$
    Wrong: $2*(\lfloor n/2 \rfloor -1)<n$, it has a left child
    C:$\lfloor n/2 \rfloor$
    Wrong: It has a left child
    D:$\lfloor n/2 \rfloor+2$
    Correct: it doesn’t have any child
<br>

- The inorder traversal sequence of any min-heap must be in sorted order.
- A：F. 注意是 min-heap 而不是 binary search tree
<br>


## Hw 7


## Hw 8
- Q: If graph $G$ is NOT connected and has 35 edges, then it must have at least ____ vertices.
- A: 10. 要用最少的节点达到最多的边，考虑均匀分成两个完全子图，$a=n/2, b=n-a, a(a-1)/2 + b(b-1)/2 >= 35$
<br>

- Q: A graph with 90 vertices and 20 edges must have at least __ connected component(s).
- A: 70. 让连通图最少，也就是要利用好边尽可能相连。一个 20 条边的生成树加上 69 个孤立点。
<br>

- Q: A graph with 50 vertices and 17 edges must have at most ____ connected component(s).
- A: 44. 让连通图最多，也就是要浪费掉边，让某一个联通分量尽可能成为完全子图。注意这里的 graph 可以包括环
<br>

- Q: Given an undirected graph G with 16 edges, where 3 vertices are of degree 4, 4 vertices are of degree 3, and all the other vertices are of degrees less than 3. Then G must have at least __ vertices.
- A: $16*2 = 4*3 + 3*4 + 2*n_2 + n_1$, to make $n_2 + n_1$ least, $n_2 = 4$, total vertices = 11. An example is below:
![Alt text](assets/image1.png){width=50%}
<br>


## 期中复习
- Q: The time comlexity of Selection Sort will be the same no matter we store the elements in an array or a linked list.
- A: True. 选择排序的时间复杂度只和比较次数有关，和数组链表实现无关，记着
<br>

- Q: Given a binary search tree with its postorder traversal sequence {5, 7, 12, 10, 20, 19, 31, 21, 15}. If 15 is deleted from the tree, which one of the following statements is FALSE?
- A: 二叉搜索树的建树方法（后序），最后一个点为 root，比它小的按顺序排在它左边为其左子树（递归），比它大的按顺序排在它的右边为其右子树（递归）。前序同理
<br>

- Q: The array representation of the disjoint sets is given by { 3, 3, -5, 2, 1, -3, -1, 6, 6 }. Keep in mind that the elements are numbered from 1 to 9. After invoking Union(Find(4), Find(8)) with union-by-size and path compression, how many elements will be changed in the resulting array?
- A: 注意路径压缩是在 find 里做的，并且只对 find 里经过的节点做
<br>

- Q: In a DAG, if for any pair of distinct vertices V​i​​  and V​j​​ , there is a path either from V​i​​  to V​j​​  or rom V​j​​  to V​i​​ , then the DAG must have a unique topological sequence.
- A: True. 字面意思，记着
<br>

- Q: Suppose that an array of size $m$ is used to store a circular queue. If the head pointer `front` and the current size variable `size` are used to represent the range of the queue instead of `front` and `rear`, then the maximum capacity of this queue can be:
- A: $m$.

    !!! note
        1. 当使用 `front` 和 `rear` 来表示队列的范围时，队列的最大容量将是 `m-1`。这是因为我们需要保留一个位置来判断队列是空还是满。如果 `front` 和 `rear` 相等，表示队列为空；如果 `front` 在 `rear` 后面一个位置，表示队列满。因此，在这种实现中，我们无法使用数组中的所有 `m` 个空间。所以最大容量是 `m-1`。
        2. 当使用 `front` 和 `size` 来表示队列的范围时，队列的最大容量将是 `m`。`head` 指向队列的开始位置，而 `size` 存储当前队列的大小。因此，`size` 等于 0 表示队列为空，`size` 等于 `m` 表示队列已满。
<br>

- Q: In-order traversal of a binary tree can be done iteratively. Given the stack operation sequence as the following:
push(1), push(2), push(3), pop(), push(4), pop(), pop(), push(5), pop(), pop(), push(6), pop()
Which one of the following statements is TRUE?
  1. 6 is the root
  2. 3 and 5 are siblings
  3. 2 is the parent of 4
  4. None of the above
  5. 6 is the root
  6. 2 is the parent of 4
  7. 2 and 6 are siblings
  8. None of the above
- A: 2、7
主要难点在于如何从这个抽象的 stack 操作中理解树的形状
    ```
        1
       / \
      2   6
     / \
    3   5
     \
      4
    ```
<br>

- Q: There are more NULL pointers than the actual pointers in the linked representation of any binary tree.
- A: True. 二叉树中，每个节点有两个指针：左孩子和右孩子。对于有 $n$ 个节点的二叉树，有 $n-1$ 个父-子连接（边），因此有 $n-1$ 个非空指针。从总共 $2n$ 个指针中减去 $n-1$ 个非空指针，得到 $n+1$ 个空指针
<br>

- Q: A tri-diagonal matrix is a square matrix with nonzero elements only on the diagonal and slots horizontally or vertically adjacent the diagonal, as shown in the figure. Given a tri-diagonal matrix (三对角矩阵) M of order 100. Compress the matrix by storing its tri-diagonal entries mi,j (1 ≤ i ≤ 100，1 ≤ j ≤ 100) row by row into a one dimensional array N with indices starting from 0. Then the index of m30,30 in N is:
- A: $2*(i-1)+j-1$. 没懂，这个计算怎么来的
<br>

- Q: If there are less than 20 inversions in an integer array, then Insertion Sort will be the best method among Quick Sort, Heap Sort and Insertion Sort
- A: True. 数组长度越大，快排效果越好，这里逆序对少，可以简单理解为数组长度小，所以插入排序更好
<br>

- Q: For the quicksort implementation with the left pointer stops at an element with the same key as the pivot during the partitioning, but the right pointer does not stop in a similar case, what is the running time when all keys are equal?
- A: $O(n^2)$. If the quicksort algorithm is implemented such that the left pointer stops at an element equal to the pivot, but the right pointer doesn't stop for an element equal to the pivot, then the worst-case scenario would be when all keys are equal.
In this case, the pivot would never divide the array into two relatively equal halves. Instead, the pivot would only remove itself, leading to the very uneven Ugandan partitions of size 0 and n-1. This, in turn, leads to a highly unbalanced recursive partitioning process.
Therefore, the time complexity for this scenario would be O(n²), with 'n' being the number of elements in the array.
<br>

- Q: Suppose that an array of size $m$ is used to store a circular queue. If the front position is $front$ and the current size is $size$, then the rear element must be at:
- A: $(front+size-1)\mod m$，循环队列的性质，记住
<br>

- Q: Partial order is a precedence relation which is both transitive and irreflexive.
- A: True. 注意这里和离散的定义不同，离散里是自反，这里是反自反。反自反：$\forall x , \text{ there isn't } R(x, x)$
<br>

Q: A directed acyclic gragh must be a tree.
A: False. 我的理解是左边这个，不过大佬们的理解是右边这个
    ![Alt text](assets/image3.png){width=50%}
<br>


## Hw 9
- Q: Let P be the shortest path from S to T. If the weight of every edge in the graph is incremented by 2, P will still be the shortest path from S to T.
- A: False. 考虑 P 是一条很长但是每条边权重都很小的路径，然后存在一条很短但是每条边权重都很大的路径，那么这两条路加的权重不一样，所以不一定是最短路径了
<br>

## Hw 11
- Q: Apply DFS to a directed acyclic graph, and output the vertex before the end of each recursion. The output sequence will be: A.unsorted; B.topologically sorted; C.reversely topologically sorted; D.None of the above
- A: reversely topologically sorted. 因为返回的时候说明那个点没有出边了，所以是拓扑排序的逆序

## Hw 13
- Q: During the sorting, processing every element which is not yet at its final position is called a "run". Which of the following cannot be the result after the second run of quicksort?
    A. 5, 2, 16, 12, **28**, 60, 32, **72**
    B. **2**, 16, 5, 28, 12, 60, 32, **72**
    C. **2**, 12, 16, 5, **28**, **32**, 72, 60
    D. 5, 2, **12**, 28, 16, **32**, 72, 60
- A: 注意快排的特性是，pivot 左边的都比它小，右边的都比它大；也就是说，pivot 一定会被排到它最终的位置上；更进一步，$n$ 次有效（非空）的快排至少会有 $n$ 个元素到达最终位置。
对于这种题型，需要把最终数据排出来，比较每个选项有哪几个元素到达了最终位置，这里标在了上面的选项中。运行 two runs，也就是第一轮对整体快排，第二轮对第一轮的 pivot 左边部分快排，对 pivot 右边部分快排。考虑只有两个最终项的选项，一定是第一轮快排选到了最值，使得第二轮中有一次快排无效。这样来看，$D$ 选项没有选到最值，且只有两个最终项，是不可能的

- Q: Among the following sorting methods, which ones will be slowed down if we store the elements in a linked structure instead of a sequential structure?
    1. Insertion sort; 2. Selection Sort; 3. Bubble sort; 4. Shell sort; 5. Heap sort
    A.1 and 2 only
    B.2 and 3 only
    C.3 and 4 only
    D.4 and 5 only
- A: 如果在链表中存储数据，变慢的操作是：访问第n个元素，变快的是插入。不过这里更多的考虑是访问是否连续。4、5 都是跳跃访问的，因此会大幅减速

## Hw 14
- Q: Suppose that the range of a hash table is [0, 18], and the hash function is H(Key)=Key % 17. If linear probing is used to resolve collisions, then after inserting { 16, 32, 14, 34, 48 } one by one into the hash table, the index of 48 is:
    A. 14; B.0; C.17; D.1
- A: 注意线性探测法是可以塞到哈希函数不涉及的位置的，选 C

## 期末复习
- Q: The node sequence from left to right at a same level could be 1 4 3 2 5, in a binary search tree?
- A: 不能，二叉查找树同一层一定升序(?)
<br>

- Q: To obtain an ascending sequence, which of the following sorting methods gives {16, 17, 20, 7, 8, 10, 28, 5, 3} after 2 runs?
- A.bubble sort; B.insertion sort; C.selection sort; D.merge sort
- A: B.