---
order: 1
---
## 1. 算法分析基础
### 1.1. algorithm 的定义
- program 的定义：用编程语言写的，不需要是有限的（如 operation system）
  - 以选择排序为例讲解了什么是 program
- 算法复杂度：本课更关注时间复杂度
  - 假设：instructuons are excuted sequentially; each instructsion is **simple**, and takes exactly **one time unit**; infinite memory
  - 最好、最坏
- 计算数的计算，`return` 要算一次，`if`、`while` 等判断算一次
- 斐波那契的算法复杂度分析与优化
  - [斐波那契数列的三种算法以及复杂度_斐波那契数列复杂度-CSDN 博客](https://blog.csdn.net/MallowFlower/article/details/78858553)
  - [通过斐波那契数列探讨时间复杂度和空间复杂度_斐波那契数列时间复杂度-CSDN 博客](https://blog.csdn.net/Suyebiubiu/article/details/107878061)
    - 这里注意一下一个错误，空间复杂度只看树的高度，因为同一时间只算一条路，到达叶节点了就删除空间然后重新走，所以最多就走 N - 1 条路

### 1.2. 算法比较（最大连续子串和）
- 朴素遍历法
- 略优化版
- Divide and Conquer: 分而治之法
- one-line 算法，O(n) 且更适用复杂情况

***
## 2. Lists, Stacks, and Queues
- ADT: Data type = ${Objects} \cup {Operations}$
### 2.1. Lists
- 定义，很基本，不赘述
- 操作：
  - Find the length
  - Print
  - Make empty
  - **Find**
  - **Insert**：在第 k 项后插入
  - **Delete**
  - Find next
  - Find previous
- 几种实现 Lists 的方式
  - Simple Array implementation of Lists
    - 需要实现定义 $MaxSize$
    - `Find_Kth` 的时间复杂度为 $O(1)$
        > 注：这里我认为描述不够精准。应该是：数组支持随机访问，给定下标找到对应元素的时间复杂度为 $O(1)$；但对查找而言，比如对有序数组用二分查找，其时间复杂度为 $O(\log n)$
    - `Insert` 和 `Deletion` 牵涉到大量数据的移动
  - Linked Lists
    - `insert` 和 `delete` 的具体操作
    - 拓展：Doubly Linked Circular Lists
    - 应用：多项式的表示，用数组表示过于稀疏
    - 拓展 Multilists
  - Cursor Implementation of Linked Lists (no pointer)
    - 在一些语言中没有 pointer 的概念，因此需要用 cursor 的形式模拟 pointer
      - 具体方法就是用数组的 index 代替数组的地址，也就是数组的每一项是个包含 `element` 和 `next` 的结构体，`next` 不为指针而为数组下标。当 `next` 为 $0$ 就等同于 `NULL`
    - 为了模拟 `malloc` 和 `free`，我们的做法是保持一个 freelist(CursorSpace)。每次 `malloc` 把 `CursorSpace[0]` 后紧跟的第一个位置取出；每次 `free` 把这个元素插入回到 `CursorSpace[0]` 后
    - 在一个 CursorSpace 里可以定义多个链表，为方便起见，采用带 header 链表

    !!! note
        由于没有 pointer 那样复杂的内存管理机制，通常 cursor 实现的链表要**更快**

### 2.2. Stack
- stack 是一种后进先出的 list，它有下面这些操作
  - isEmpty
  - CreateStack
  - DisposeStack
  - MakeEmpty
  - **Push**
  - **Top**
  - **Pop**
- 实现：push、top、pop，链表写法与数组写法
- 应用
  - 用 stack 的特性检查括号 (parenthesis, brackets, braces) 的匹配
  - 用 stack 计算逆波兰式
  - infix to postfix
    - operationStack 与 treeStack
    - 需要注意左括号只在遇到右括号时弹出，且其优先级在栈内是最低，而在栈外是最高；次幂的优先级也有特殊情况（左结合与右结合）
  - stack in function calls

### 2.3. Queue
- queue 是一种先进先出的 list，它包含以下操作
  - isEmpty
  - CreateQueue
  - DisposeQueue
  - MakeEmpty
  - **Enqueue**(有时仍叫 push)
  - **Front**
  - **Dequeue**(有时仍叫 pop)
- 用数组实现 queue
- 循环队列，规定 $rear == front$ 时是空队列，$(rear+1)~\%~ maxsize == front$ 时是满队列，避免额外设置 flag

***
## 3. Tree
### 3.1. Trees
- 树的基本概念
  - 从略

!!! note 几个需要注意的点
    - 深度：从根节点到某个节点的唯一路径的长度（上往下数），从 0 开始
    - 高度：从某个节点到叶节点的最长路径的长度（下往上数），从 0 开始
    - 这两个概念对某个特定节点来说不同，对树来说相同，并且 $Height(node) + Depth(node) = Height(tree) = Depth(tree)$
    - 节点的层数：就是节点的深度 (?)，但注意 $k$ levels 和 level $k$ 的问法
    - 树的度数与图的度数不同，是其孩子的个数，不包含其父亲

- 树的表示：
  1. 线性表示（类似 scheme），缺点是查找繁琐，理解困难
  2. Linked List，缺点是最大孩子数量未知，设为较大值后又会有很多时候置为 NULL，空间浪费
  3. FirstChild-NextSibling 表示，实际上使用的是二叉树的结构（左：第一个子节点；右：下一个兄弟节点），缺点是不唯一（因为孩子之间谁是第一位没有确定）

### 3.2. 二叉树
- 二叉树是每个节点最多有两个孩子的树
- 应用例子：表达式树
  - 如何构建：中序 $\to$ 后序 (stack)，而后从后缀表达式构建
- 遍历：**前序**(preorder，先根)、**中序**(inorder，中根)、**后序**(postorder，后根)、**层序**(levelorder)
  - 前序，先访问根节点，再递归每个子节点
  - 后序，先递归访问每个子节点，再访问根节点
  - 层序，其实就是层主序利用类似 FirstChild-NextSibling 的结构，需要用到 queue 来实现
    ```c
    void levelorder(tree_ptr tree) {
        enqueue(tree);
        while (queue is not empty) {
            visit(T = dequeue());
            for (each child C of T)
                enqueue(C);
        }
    }
    ```
  - 中序遍历的 recursive 版本（没什么好说的，递归左子树，再根节点，再右子树）和 iterative 版本（利用 stack，将处理的起点从根节点转到左下角）
    ```c
    void iter_inorder(tree_ptr tree) {
        Stack S = create_stack();
        for ( ; ; ) {
            for (; tree; tree = tree->left)
                push(S, tree);
            tree = top(S); pop(S);
            if (!tree)
                break;
            visit(tree->element);
            tree = tree->right;
        }
    }
    ```
- 拓展：从“先根 + 中根”或“中根 + 后根”或“中根 + 优先级规则”或“前根/后根 + 二叉搜索”可以唯一确定一棵二叉树（**但“先根 + 后根”不行**）
  - 前两者常用作考题，第三者在 autograd 中实践，第四者只能应用于数字、字符等有序的情况
- 例子：文件系统目录缩进、文件系统大小计算

!!! note
    在普通的 tree 中，子节点的顺序无关紧要，但在 binary tree 中，左儿子和右儿子是不同的

### 3.3. 线索二叉树 (ThreadedTree)
  - 分别以前序、中序、后序遍历的形式利用闲置的空指针，也因此分成三种线索二叉树
  - 课上讲的是中序线索二叉树，满足三个规则
    1. 如果一个节点的左儿子为空，那么它的左指针指向它的中序遍历前驱节点
    2. 如果一个节点的右儿子为空，那么它的右指针指向它的中序遍历后继节点
    3. 线索二叉树需要有一个 head node，其左指针指向根节点，右指针指向自己

!!! info
    ![](/public/assets/Courses/FDS/FDS笔记/img-2024-01-15-22-28-24.png)
    ![](/public/assets/Courses/FDS/易错题/image2.png)
    左图所示的二叉树转化成（中序）线索二叉树如右图所示（遍历顺序已标注）
    有如下的 ADT
    ```c
    typedef struct ThreadedTreeNode *PtrToThreadedNode;
    typedef struct PtrToThreadedNode ThreadedTree;
    typedef struct ThreadedTreeNode {
        int LeftThread; /* if it is TRUE, then Left */
        ThreadedTree Left; /* is a thread, not a child ptr */
        ElementType Element;
        int  RightThread; /* if it is TRUE, then Right */
        ThreadedTree Right; /* is a thread, not a child ptr */
    }
    ```
    拓展：化为线索二叉树后，就可以利用它的性质更直观地实现遍历。同样，将处理的起点从根节点转到左下角，此时不再需要 stack 的辅助
    ```c
    ThreadedTree First(ThreadedTree p) // 中序序列下第一个结点访问算法
    {
        while (p->LeftThread == 0)
            p = p->Left; // 最左下结点（不一定是叶子结点）
        return p;
    }
    ThreadedTree Next(ThreadedTree p) // 中序序列下后继结点访问算法
    {
        if(p->RightThread == 0)
            return  First(p->Right);
        else
            return p->Right; // RightThread == 1，直接返回后继节点
    }
    void Inorder(ThreadedTree root)
    {
        for(ThreadedTree p = First(root); p != NULL; p = Next(p))
            visit(p->Element); // 访问结点
    }
    ```


### 3.4. 拓展：普通树转二叉树
- 可以参考 [普通树转二叉树](https://blog.csdn.net/forever_dreams/article/details/81032861) 与 [普通树转二叉树的遍历性质](https://blog.csdn.net/best_LY/article/details/121346561)
- 左儿子、右兄弟（每个点的左儿子是它的第一个儿子，右儿子是它从左往右数的第一个兄弟）
- T 的 preorder = BT 的 preorder, T 的 postorder = BT 的 inorder

### 3.5. 拓展：二叉树的计算
- 第 i 层节点数最多为 $2^{i-1}, i \ge 1$，高度（深度）为 h 的二叉树最多有 $2^h-1$ 个节点
- 对于任何非空二叉树都有 $n_0=n_2+1$，其中 $n_i$ 表示度为 i 的节点数，$i=0,1,2$

    !!! note proof
        记所有节点数为 $n$，则 $n = n_0 + n_1 + n_2$。再令 $B$ 表示二叉树的边数，则 $B = n - 1$，同时又有 $B = n_1 + 2n_2$。联立可得 $n_0 = n_2 + 1$。

### 3.6. 拓展：完美、完全、完美二叉树
- 参考 [完美二叉树、完全二叉树、完满二叉树](https://www.cnblogs.com/idorax/p/6441043.html)
- 完美二叉树 (又称满二叉树，Perfect binary tree)：所有叶子节点都在最底层，每个非叶子节点都有两个子节点
- 完全二叉树 (Complete binary tree)：所有叶子节点都在最底下两层（所有叶节点都位于相邻的两个层上），最后一层的叶子节点都靠左排列，并且除了最后一层，其他层的节点个数都要达到最大
- 完满二叉树 (Full binary tree, Strictly binary tree)：所有非叶子节点都有两个子节点

### 3.7. 二叉树搜索树 (binary search tree)
- 定义：
  - 每个节点有一个关键字，是各不相同的整数
  - 如果左子树非空，那么左子树所有关键字的值必须小于当前节点的关键字
  - 如果右子树非空，那么右子树所有关键字的值必须大于当前节点的关键字
  - 左子树和右子树仍是二叉查找树
- 二叉树搜索树具有以下操作
  - MakeEmpty
  - **Find**：有递归版本和循环版本，直接记后者，检测是否为空树，如果找到就直接返回，如果比当前节点小就往左走，如果比当前节点大就往右走，直到找到或者走到空节点
    ```c
    Position Find(ElementType X, SearchTree T)
    {
        while (T) { /* iterative version of Find */
            if (X == T->Element)
                return T; /* found */
            if (X < T->Element)
                T = T->Left; /*move down along left path */
            else
                T = T-> Right; /* move down along right path */
        } /* end while-loop */
        return NULL; /* not found */
    }
    ```
    - 时间复杂度为 $O(d)$
  - FindMin / FindMax：先检测是否为空树，然后一直往左/右走即可（递归），以 FindMax 为例
    ```c
    Position FindMax(SearchTree T)
    {
        if (T)
            while (T->Right)
                T = T->Right;   /* keep moving to find right most */
        return T;  /* return NULL or the right most */
    }
    ```
    - 时间复杂度为 $O(d)$
  - Insert：首先判断是否为空树，如果是就直接插入；否则就用查找的思路，如果比当前节点小就往左走，如果比当前节点大就往右走，直到找到或者走到空节点，找到的话就什么也不做或者更新，走到空节点的话就插入（只有在走到空树的时候才会插入）
    - 其关键就在于这个空树插入，把所有情况化为这种情况
    ```c
    SearchTree Insert(ElementType X, SearchTree T)
    {
        if (T == NULL) { /* Create and return a one-node tree */
            T = malloc(sizeof(struct TreeNode));
            if (T == NULL)
                FatalError("Out of space!!!");
            else {
                T->Element = X;
                T->Left = T->Right = NULL;
            }
        }  /* End creating a one-node tree */
        else {/* If there is a tree */
            if (X < T->Element)
                T->Left = Insert(X, T->Left);
            else if (X > T->Element)
                T->Right = Insert(X, T->Right);
            /* If X is in the tree already; we'll do nothing */
        }
        return T;   /* Do not forget this line!! */
    }
    ```
    - 时间复杂度为 $O(d)$
  - Delete：递归查找到需要删除的节点，接下来分 2 个孩子和 0、1 个孩子两种情况
    - 0、1 个孩子的情况很简单，把非空的那个孩子（或者两个都是空）替换当前节点就行
    - 2 个孩子的情况较复杂，一般的删除策略是用其**右子树中最小元**（或者左子树中的最大元，利用上面已经实现的 `FindMax()` 或 `FindMin()` ）代替该节点的数据**并递归地删除**那个节点。
    ```c
    SearchTree Delete(ElementType X, SearchTree T)
    {
        Position TmpCell;
        if (T == NULL)
            Error("Element not found");
        else if (X < T->Element) /* Go left */
            T->Left = Delete(X, T->Left);
        else if (X > T->Element) /* Go right */
            T->Right = Delete(X, T->Right);
        else /* Found element to be deleted */
        if (T->Left && T->Right) { /* Two children */
            TmpCell = FindMin(T->Right); /* Replace with smallest in right subtree */
            T->Element = TmpCell->Element;
            T->Right = Delete(T->Element, T->Right); /* Now delete the tmpcell element */
        } /* End if */
        else { /* One or zero child */
            TmpCell = T;
            if (T->Left == NULL) /* This also handles 0 child */
                T = T->Right;
            else  if (T->Right == NULL)
                T = T->Left;
            free(TmpCell);
        }  /* End else 1 or 0 child */
        return  T;
    ```
    - 时间复杂度为 $O(d)$

    !!! note 懒惰删除
        上述删除方法有效但比较繁琐，另外有一种叫做**懒惰删除**的操作，给二叉树的节点结构再加一个 flag 值，重写所有函数只访问 flag 为 true 的节点，删除的时候只把 flag 置为 false 而不对树的结构做改变。同时，如果被删除的节点后续又被插入回来，只需改变 flag
  - Retrieve（检索，给 Position 返回 Element）

### 3.8. 平均情形分析与拓展
- 二叉搜索树的高度取决于插入的顺序，有可能退化为链表，这样的话查找的时间复杂度就变成了 $O(n)$，所以我们需要对二叉树进行平衡

    !!! example
        插入顺序：4, 2, 1, 3, 6, 5, 7 $~~~~~~~~~~~~~~~~$ 插入顺序：1, 2, 3, 4, 5, 6, 7
        ![](/public/assets/Courses/FDS/FDS笔记/img-2024-01-16-10-14-46.png) $~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$ ![](/public/assets/Courses/FDS/FDS笔记/img-2024-01-16-10-15-23.png)
- 拓展：AVL(Adelson-Velskii and Landis) 树，参考 [数据结构与算法分析学习笔记 (二)--AVL 树的算法思路整理](https://www.cnblogs.com/heqile/archive/2011/11/28/2265713.html)（md 难得一比 ~~，零基础枯了~~，目前应该不用掌握具体操作）

***
## 4. Heap & Priority queue
- 在讲 Heap（堆）之前，我们先来了解 priority_queue（优先队列）

### 4.1. Priority queue
- 对象：一个有限的有序集，其实就是带排序的队列
- 操作：
  - 初始化 `PriorityQueue Initialize(int MaxElements);`
  - **插入** `void Insert(ElementType X, PriorityQueue H);`
  - **删除最小的元素** `ElementType DeleteMin(PriorityQueue H);`
  - 寻找最小的元素 `ElementType FindMin(PriorityQueue H);`
- 哨兵 (sentinel)：第零个元素不存储数据，只是用来方便计算

#### 4.1.1. 几种 ADT 的比较
- 为了实现优先队列，我们来比较几种 ADT 的插入与删除操作的复杂度
  - 数组 (Array)：
    - 插入元素到末尾 $\Theta(1)$
    - 找到最大/最小元素 $\Theta(n)$, 删除元素移动数组 $O(n)$
  - 链表 (Linked List)：
    - 插入元素到链表开头 $\Theta(1)$
    - 找到最大/最小元素 $\Theta(n)$, 删除元素 $\Theta(1)$
  - 有序数组 (Ordered Array)：
    - 找到合适的位置 $O(n)$, 移动数组并插入元素 $O(n)$
    - 删除开头/末尾元素 $\Theta(1)$
  - 有序链表 (Ordered List)：
    - 找到合适的位置 $O(n)$, 插入元素 $\Theta(1)$
    - 删除开头/末尾元素 $\Theta(1)$
  - 二叉搜索树 (Binary Search Tree)：
    - 插入元素 $O(\log n)$
    - 删除元素 $O(\log n)$
- 前四种实现方式中，Linked List 最合适，因为优先队列的删除操作不会比插入操作多
- 而最后一种实现方式便是 heap 的雏形，将二叉搜索树的要求（递增、递减 priority）略作改变，要求父节点的值 $\ge$ or $\le$ 子节点的值（这也是一种 priority，称为 heap-order priority），就得到了 heap
  - 这也是为什么我们先讲优先队列，因为 heap 其实是 priority_queue 的一种 implementation，即：heap 本质就是 priority_queue
  - 有时我们直接将 heap 视为一种全新的 ADT

### 4.2. Binary Heap
- 定义：用数组的形式表示的完全二插树（有哨兵）：一个编号为 $i$ 的结点，其父亲结点编号为 $\lfloor i/2 \rfloor$，左儿子为 $2i$，右儿子为 $2i+1$（这种实现形式的优点在于访问父母孩子比较方便）
  - 如果每个节点的值都大于等于其子节点的值，称为最大堆；反之，最小堆。（注意：左右子树无要求！）
- 基本操作（以最小堆举例）：
  - Initialize
    ```c
    PriorityQueue Initialize(int MaxElements)
    {
        PriorityQueue H;
        if (MaxElements < MinPQSize)
            return Error("Priority queue size is too small");
        H = malloc(sizeof(struct HeapStruct));
        if (H == NULL)
            return FatalError("Out of space!!!");
        /* Allocate the array plus one extra for sentinel */
        H->Elements = malloc((MaxElements + 1) * sizeof(ElementType));
        if (H->Elements == NULL)
            return FatalError("Out of space!!!");
        H->Capacity = MaxElements;
        H->Size = 0;
        H->Elements[0] = MinData; /* set the sentinel */
        return H;
    }
    ```
  - **Insert**(percolate up，上浮操作)：堆的插入只能放在下一个空闲位置并调整，不要跟之前讲的二叉搜索树与之后要讲的并查集搞混了。用 for 循环不断将 $i$ 处节点用 $i/2$ 覆盖，直到 $i/2$ 处节点小于待插入节点（注意这里比较和交换的不是相同的东西，另外，这里我们说是交换但实际不用交换而用覆盖）
    ```c
    /* H->Element[0] is a sentinel */
    void Insert( ElementType X, PriorityQueue H)
    {
        int i;
        if (IsFull(H)) {
            Error("Priority queue is full");
            return;
        }
        for (i = ++H->Size; H->Elements[i / 2] > X; i /= 2)
            H->Elements[i] = H->Elements[i / 2];
        H->Elements[i] = X;
    }
    ```
  - **DeleteMin**(percolate down，下滤操作)：删除最小元后，在根节点产生一个空穴。同时堆少了一个元素，我们必须把堆最后一个元素 X 移动到堆的某个地方。从根节点的空穴开始我们将空穴的两个儿子中的较小者移入空穴（注意这里的边界检查），这样就把空穴往下推了一层；或者将 X 移入空穴（同样注意这里的比较）。
    ```c
    ElementType DeleteMin(PriorityQueue H)
    {
        int i, Child;
        ElementType MinElement, LastElement;
        if (IsEmpty(H)) {
            Error("Priority queue is empty");
            return H->Elements[0];
        }
        MinElement = H->Elements[1]; /* save the min element */
        LastElement = H->Elements[H->Size--]; /* take last and reset size */
        for (i = 1; i * 2 <= H->Size; i = Child) {  /* Find smaller child */
            Child = i * 2;
            if (Child != H->Size && H->Elements[Child+1] < H->Elements[Child])
                Child++;
            if (LastElement > H->Elements[Child]) /* Percolate one level */
                H->Elements[i] = H->Elements[Child];
            else
                break; /* find the proper position */
        }
        H->Elements[i] = LastElement;
        return MinElement;
    }
    ```
- 其它操作：
  - DecreaseKey(P, $\Delta$, H)：降低在位置 P 处的关键字的值。我们需要上滤操作对堆进行调整。
  - IncreaseKey(P, $\Delta$, H)：增加在位置 P 处的关键字的值。我们需要下滤操作对堆进行调整。
  - Delete(P, H)：删除堆中位置 P 上的节点。这个操作首先执行 DecreaseKey(P, $\infty$, H) 再执行 DeleteMin 即可。
  - BuildHeap(H)：读入 $N$ 个关键字放进空 H 中，可以使用 $N$ 个相继的 Insert 操作完成，复杂度为 $O(N\log N)$。
    也可以将 $N$ 个关键字以任意顺序一起放入树中构成一棵完全二叉树，从倒数第二层开始依次 percolate down. 可以证明后者只需要线性的时间复杂度就可以完成树的构建。

    !!! note
        完美二叉树中高度为 $i$ 的节点有 $2^i$ 个，所有节点的高度和为 $Sum=\sum_0^h 2^i(h-i)=2^{h+1}-1-(h+1)$，而 $h = \lfloor \log N \rfloor$
        因此 BuildHeap 的操作是线性级别的

- 拓展：d-heaps
  - $DeleteMin$ 操作会变慢，时间复杂度为 $O(d \log_d N)$
  - $*2$ or $/2$ is merely a bit shift, but $*d$ or $/d$ is not
  - When the priority queue is too large to fit entirely in main memory, a d-heap will become interesting(?)

***
## 5. Disjoint set
- 问题引入：Dynamic Equivalence Problem(等价类问题)
- 用名为 disjoint set(并查集) 的数据结构来解决
  - 结合 cursor implemented list 和 tree，一个 set 就是一棵树，其根节点为负数，指示 set 内的数量
  - 两种操作：find、union
    ```c
    void SetUnion (DisjSet S, SetType Rt1, SetType Rt2)
    {
        S[Rt2] = Rt1; // Rt2 points to Rt1, Rt1 is the root
    }
    SetType Find (ElementType X, DisjSet S)
    {
        for ( ; S[X] > 0; X = S[X]); // S[root] < 0
        return  X;
    }
    ```
  - 实际运用时往往组合：
    ```c
    /* Algorithm using union-find operations */
    {
        Initialize S[i] for i = 1, ..., 12;
        for (k = 1; k <= 9; k++)
        {
            /* for each pair i, j */
            if (Find(i) != Find(j))
                SetUnion(Find(i), Find(j));
        }
    }
    ```
- 实现
  - 用 tree 来表示，加快查询
  - 进一步优化，用数组来表示树，每个元素为其父节点，简化对父节点的查询
  - 进一步优化，**在 Find 操作时**，每个元素直接赋为其根节点，这种操作称为**路径压缩**(具体实现的话只需要在每次 find 返回的时候多一步赋值的操作)
    - 也就是，find 一遍之后再 find 就变快了（尽管这次变慢），find 够多后会变成一个高度为 1 的矮树
    - 但跟后面讲的 Smart Union Algorithm 中的 union by height 不完全兼容
    ```c
    SetType Find(ElementType X, DisjSet S)
    {
        ElementType root, trail, lead;
        for (root = X; S[root] > 0; root = S[root]); /* find the root */
        for (trail = X; trail != root; trail = lead) {
            lead = S[trail];
            S[trail] = root;
        }  /* collapsing */
        return root;
    }
    ```
- **Smart Union Algorithm**
  - 按大小合并：始终将小的树合并到大的树上。size 的记录直接利用根节点的值，表示为 `-size`
    - 设 $T$ 是按大小合并的 $N$ 个节点的树。可以用归纳法证明，$height \le \lfloor \log N \rfloor + 1$
    - 因此对于 $N$ 个 Union 进行 $M$ 个 `Find` 操作，所用时间为 $N+M\log_2N$
  - 按高度合并：始终将矮的树合并到高的树上
    - 路径压缩不完全与按高度求并兼容，因为路径压缩可以改变树的高度。此时，对于每棵树所存储的高度就变成了估计的高度，有时称为秩 (rank)
- 按秩求并与路径压缩的算法复杂度分析，涉及 Ackerman 函数，略复杂，没看懂
- 按秩求并与按高度求并：本质上是一样的，但是又搞了个秩的概念，不是很懂这里什么意思

***
## 6. Graph
### 6.1. 基本概念
- G, E, V, directed, undirected, 度数等基本概念
- 限制：不考虑 self loop、multigraph
- complete graph, subgraph, component graph 等，都是离散里学过的概念，不赘述
- tree 是无向图的一种特殊情况 (conneted and acyclic)，而 list 又是 tree 的一种特殊情况，这种我们称之为退化
- DAG := directed acyclic graph

### 6.2. 具体实现
- 用二维数组 (adjacency matrix) 来表示图
  - 对无向图，可以砍掉一半的空间，但空间复杂度依然为 $O(V^2)$，不是很优秀，对非稠密图开销太大
- 用邻接表 (Adjacency list) 来表示图
  - 用链表来表示每个顶点的邻接点
  - 空间复杂度为 $O(V+E)$，更优秀
    ![](/public/assets/Courses/FDS/FDS笔记/img-2024-01-16-14-39-18.png)
- 现在我们考虑度数，对 adjacency matrix，只需整个求和即可。对 adjacency list，遍历一遍链表只能得到无向图的度数；对有向图，这样只能找到出度，需要增加一个列表来将边反向存入，或者使用邻接多重链表
- 用邻接多重链表 (Adjacency Multilist)，相对复杂一些

### 6.3. 图的应用之——Topological Sort
- AOV 网络：有向图中，用顶点表示活动，用弧表示活动之间的优先关系。deasible 的 AOV 网络一定是 DAG
- 前驱 (predecessor) 与后继 (successor) 的概念，直接前驱 (immediate predecessor) 与直接后继 (immediate successor) 的概念
- 拓扑排序的概念不再赘述，排序结果可能不是唯一的
- 课上给了两种版本，直接记优秀的那个
  - 删入度为 0 的节点并删除其出边，直到没有入度为 0 的节点；如果最终有删不完的情况，则说明有环 (unfeasilbe)，也就是——拓扑排序算法可以用来检测有向图是否有环
    ```c
    void Topsort(GraphG)
    {
        Queue Q;
        int Counter = 0;
        Vertex V, W;
        Q = CreateQueue(NumVertex); MakeEmpty(Q);
        for (each vertex V)
            if (Indegree[V] == 0)
                Enqueue(V, Q);
        while (!IsEmpty(Q)) {
            V = Dequeue(Q);
            TopNum[V] = ++Counter; /* assign next */
            for (each W adjacent from V)
                if (––Indegree[W] == 0)
                    Enqueue(W, Q);
        }  /* end-while */
        if (Counter != NumVertex)
            Error(“Graph has a cycle”);
        DisposeQueue(Q); /* free memory */
    }
    ```

### 6.4. 图的应用之——最短路径算法：单源最短路径
- 定义：给定有向图 $G=(V,E)$ 以及一个花费函数 $c(e), e \in E(G)$(无权图则 $c(e)$ 为常数)，从源点到终点的一条路径 $P$ 的长度定义为 $\sum_{e_i \in P} c(e_i)$，称为带权路径长
- 单源最短路径 (Single-Source Shortest-Path Problem)
  - 给定一个赋权图和一个特定顶点 $s$ 作为输入，找出从 $s$ 到中 $G$ 每一个其他顶点的最短带权路径。注意：如果这里有负环，那么最短路径定义为 0。
#### 6.4.1. 无权最短路径算法
- 采用 BFS(Breadth-First Search) 的方式，从 $s$ 出发寻找所有距离为 1 的顶点 (即与 $s$ 邻接) 随后寻找与 $s$ 距离为 2 的顶点，即与刚刚那些顶点邻接的顶点，以此类推。
    ```c
    void Unweighted(Table T)
    {   /* T is initialized with the source vertex S given */
        Queue Q;
        Vertex V, W;
        Q = CreateQueue(NumVertex); MakeEmpty(Q);
        Enqueue(S, Q); /* Enqueue the source vertex */
        while (!IsEmpty(Q)) {
            V = Dequeue(Q);
            T[V].Known = true; /* not really necessary */
            for (each W adjacent from V) {
                if (T[W].Dist == Infinity) {
                    T[W].Dist = T[V].Dist + 1;
                    T[W].Path = V;
                    Enqueue(W, Q);
                } /* end-if Dist == Infinity */
            }
        } /* end-while */
        DisposeQueue(Q); /* free memory */
    }
    ```
- 时间复杂度为 $O(V+E)$
#### 6.4.2. 有权最短路径算法
- 介绍一种名为 **Dijkstra** 的算法，不能处理负权边
- 可以参考这个 [Dijkstra 算法（附案例详解） - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/454373256)
    ```c
    void Dijkstra(Table T)
    {   /* T is initialized by Figure 9.30 on p.303 */
        Vertex  V, W;
        while (True) { /* O(|V|) */
            V = smallest unknown distance vertex;
            if (V == NotAVertex)
                break;
            T[V].Known = true;
            for (each W adjacent from V) {
                if (!T[W].Known) {
                    if (T[V].Dist + Cvw < T[W].Dist) {
                        Decrease(T[W].Dist to T[V].Dist + Cvw);
                        T[W].Path = V; // path is the last vertex
                    } /* end-if update W */
                }
            }
        } /* end-for( ; ; ) */
    }
    /* not work for edge with negative cost  */
    ```
- 主要耗时点在两个：一是找到最小的 unknown distance vertex，二是更新距离 `Decease()`
- 具体实现
  - 通过扫描整个表来找到 smallest unknown distance vertex
    - $O(|V|^2+|E|)$。（当图是稠密的时候，这种方法是好的）
  - 使用堆来记录距离并调用 `DeleteMin()` 来获取 $V$。对 `Decrease()`，调用 `DecreaseKey()` 来进行更新，这样我们需要记录 $d_i$ 的值在堆中的位置，当堆发生变化时我们也需要更新。
    - $O(|V|\log |V|+|E|\log |V|)=O(|E|\log |V|)$（当图是稀疏的时候，这种方法是好的）
  - 同样使用堆来记录距离并调用 `DeleteMin()` 来获取 $V$。而对 `Decrease()`，在每次更新后将 $w$ 和新值 $d_w$ 插入堆，这样堆中可能有同一顶点的多个代表。当删除最小值的时候需要检查这个点是不是已经知道的。
    - $T=O(|E|\log |V|)$ but requires $|E|$ DeleteMin with $|E|$ space
  - 其它实现方法：Pairing heap, Fibonacci heap

#### 6.4.3. 负权边的图
```c
void  WeightedNegative(Table T)
{   /* T is initialized by Figure 9.30 on p.303 */
    Queue Q;
    Vertex V, W;
    Q = CreateQueue(NumVertex);  MakeEmpty(Q);
    Enqueue(S, Q); /* Enqueue the source vertex */
    while (!IsEmpty(Q)) { /* each vertex can dequeue at most |V| times */
        V = Dequeue(Q);
        for (each W adjacent from V) {
            if (T[V].Dist + Cvw < T[W].Dist) {
                T[W].Dist = T[V].Dist + Cvw;
                T[W].Path = V;
                if (W is not already in Q)
                    Enqueue(W, Q);
            } /* end-if update */
        }
    } /* end-while */
    DisposeQueue(Q); /* free memory */
}
/* negative-cost cycle will cause indefinite loop */
```
- 这个算法名叫 SPFA 算法，是 Bellman-Ford 算法的一种优化
- negative-cost cycle: 从环上一点出发，沿着环走一圈回到原点，路径的总权值为负
- 每个顶点可以 `dequeue` 最多 $|V|$ 次（这个也可以作为终止算法的一个条件），$T=O(|V|\times|E|)$

#### 6.4.4. 无环图的最短路径算法
- 如果图是无圈的，我们以拓扑序选择节点来改进算法。当选择一个顶点后，按照拓扑顺序他没有从未知顶点发出的进入边，因此他的距离不可能再降低，算法得以一次完成。
  - $T=O(|V|+|E|)$ 而且不需要堆
- 应用：AOE (Activity On Edge) 网络
  - 定义：AOE 网络是一个有向无环图。
  - 其顶点包含三个值：序号，最早完成时间 (EC)，最迟完成时间 (LC)。
  - 边表示活动之间的优先关系，边上的权值表示活动所需的时间，同时可以算出每个边可以偷懒而不影响工程的时间 (Slack Time)。
  - AOE 网络中，只有一个源点和一个汇点，源点表示工程的开始，汇点表示工程的完成。AOE 网络中，每个活动只能由一个事件发出，每个事件只能发出一项活动。
  - Critical Path := path consisting entirely of zero-slack edges.

#### 6.4.5. 拓展
- project: 带回溯的次短路
- Eppstein Algorithm: K 短路算法，参考
  1. [K Shortest Paths 算法之 Eppstein algorithm_eppstein 算法-CSDN 博客](https://blog.csdn.net/weixin_41656968/article/details/131146073#)
  2. [K Shortest Path Routing - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/336140079)

#### 6.4.6. 最短路径算法：全对最短路径
- 全对最短路径问题 (All-Pairs Shortest Path Problem)
  - 应用 $|V|$ 次单源最短路径算法
  - 或者使用书上 ch.10 的 $O(N^3)$ 算法，对稠密矩阵效果更好

### 6.5. 图的应用之——网络流问题
- 参考 [总结｜最大流（网络流基础概念 + 三个算法） - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/80567318)
- 残差网络 (Residual Network)：从 $s(source)$ 到 $t(sink)$ 的图 $G$
- 求最大流 (Maximum Flow)：从 $s$ 到 $t$ 的最大流量，基本思想是：找残差图中从源点到汇点的一条简单路径，称为增广路（augmenting path）；增广路的流量为增广路上的最小边权，创建这样一条流量，更新残差图，直到找不到增广路为止
- 一个朴素实现是：
  1. 从 $s$ 到 $t$ 任找一条路径
  2. 将这条 path 的最短 edge 作为一个流量加到图 $G$ 中
  3. 更新图 $G$ 并且清除权值为 0 的边
  4. 重复 1-3 直到没有 $s$ 到 $t$ 的路径
- 然而问题是，这个算法依赖于路径的选择，有时会导致错误的结果，在离散数学中提到，可以通过“回流”(or `undo`) 的引入来解决这个问题
  - 具体实现是，将每条边的流量做一个反向图，初始化为 $0$。
    - 在把路上每一段的**容量减少** $\Delta$ 的同时，也把每一段上的**反方向的容量增加** $\Delta$。
    - 下一次查找时，允许从反向图中经过（也就是允许回流）
- 分析：
  - 如果用无权最短路算法 ($O(|V|+|E|)$) 来寻找路径，时间复杂度为 $T=O(f \cdot |E|)$，其中 $f$ 为最大流量
  - 如果不关心具体的权值而只选择最短的路径（用无权最短路算法），那么
  $$
  \begin{align*}
    T&=T_{argumentation}\cdot T_{findpath}\\
    &=O(|E|)\times O(|E|\cdot|V|)\\&
    =O(|E|^2\cdot |V|)
  \end{align*}
  $$
    - ~~不是，这跟上面那条区别在哪？~~
  - 如果用 Dijkstra 算法（调整为找最大）来寻找 increase 最大的路径，时间复杂度为
  $$
  \begin{align*}
  T&=T_{argumentation}\cdot T_{findpath}\\
  &=O(|E|\log cap_{max})\cdot O(|E|\log |V|)\\
  &=O(|E|^2\log |V|) ~~~~ \text{ if } cap_{max} \text{ is a small integer}
  \end{align*}
  $$

### 6.6. 图的应用之——最小生成树 (Minimum Spanning Tree)
- Definition: A spanning tree of a graph $G$ is a tree which consists of $V(G)$ and a subset of $E(G)$
  - 它的边数为 $|V(G)|-1$，且再加任意一条边就会形成环
  - 之所以叫最小，是因为我们希望这个树的权值和最小（如果是有权的话）
  - It is spanning because it covers every vertex.
  - 最小生成树存在当且仅当图 $G$ 是连通的
#### 6.6.1. 寻找最小生成树的算法
- Prim 算法
  - 非常类似于 Dijsktra 算法，但没有边的更新
  - 从一个顶点开始，每次选择一个与当前树相连的最小权值的边，直到所有顶点都被加入到树中
    ```c
    T = 最小权边
    for i = 1..n-2
        e = 与 T 中的点相连且加入 T 后不会形成环的最小权边
        将 e 加入 T
    T 即为最小生成树
    ```
- Kruskal 算法
    ```c
    void Kruskal ( Graph G )
    {
        T = {};
        while (T contains less than |V|-1 edges && E is not empty) {
            choose a least cost edge(v, w) from E; // DeleteMin
            delete(v, w) from E;
            if ((v, w) does not create a cycle in T)
                add (v, w) to T; // Union / Find
            else
                discard(v, w);
        }
        if (T contains fewer than |V|-1 edges)
            Error("No spanning tree") ;
    }
    ```
  - 从一个空树开始，每次选择一个最小权值的边，直到所有顶点都被加入到树中
  - 用并查集来实现，每次选择一条边，如果这条边的两个顶点不在同一个集合中，就将这条边加入到树中
  - 时间复杂度为 $O(|E|\log |E|)$

### 6.7. 图的应用之——深度优先搜索
- 从一个顶点开始，沿着一条路径直到不能再继续为止，然后回溯并且继续搜索
- 可以看成是广义的先根遍历
- 基本实现
    ```c
    void DFS (Vertex V)
    {
        visited[V] = true;
        for (each W adjacent to V)
            if (!visited[W])
                DFS(W);
    }
    ```
- 算法复杂度为 $O(|V|+|E|)$：每个顶点、每条边恰被访问一次
- DFS 的用处非常广泛，如
  - 利用 DFS 找 ListComponents
  ```c
      void ListComponents(Graph G)
      {
          for (each V in G)
              if (!visited[V]) {
                  DFS(V);
                  printf("\n");
              }
      }
  ```
  - 利用 DFS 找（无权）生成树，此时无所谓最小，随便找一个就行
    - 性质 1：**back edge**（没有被 DFS 采用的原图中的边，如果加入到生成树中就成了反向边）不能在子树与子树之间，只会在孩子与祖先之间
    - 性质 2：if $u$ is an ancestor of $v$ in a DFS tree, then $Num(u) < Num(v)$
  - 利用 DFS 找双联通分量，见下
  - 利用 DFS 找 Euler Circuit(tour)，见下

#### 6.7.1. Biconnected
- 一个顶点 $V$ 是 **articulation point**（关节点，or 割点，cut vertex），当且仅当 $G' = DeleteVertex(G, V)$ 有至少两个连通分量
- $G$ 称为 **biconnected graph**（双连通图），当且仅当 $G$ 是连通的且 $G$ 中没有 articulation point
- $G$ 的 **biconnected component** 是它的 maximal biconnected subgraph.

!!! note
    nodes 可以被 biconnected components 分享，但 edges 不行。因此 $E(G)$ 被 $G$ 的双联通图所分割
- 利用 DFS 生成树找双联通分量
  1. The root is an articulation point **iff** it has at least 2 children
  2. Any other vertex u is an articulation point **iff** ~~u has at least 1 child, and it is impossible to move down at least 1 step and then jump up to u’s ancestor.~~ i.e., u has at least $1$ child, and $Low(child) \ge Num(v)$
  - 引入概念 **LowNumber**($Low(u)$)：u 或 u 的子树中能够回溯到的最高祖先的 DFS 编号；以及 $Num(x)$：表示 x 第一次被访问的时间戳（DFS 时第几个被访问，从 0 开始）
    $$
    \begin{align*}
    LowNumber(u) = \min\{&Num(u),\\
                         &min\{LowNumber(v) | v \text{ is a child of } u\},\\
                         &min\{Num(v) | (u, v) \text{ is a back edge} \} \}
    \end{align*}
    $$
  - 称为 tarjan 算法

#### 6.7.2. Euler Circuit
- 无向图
  - **Euler curcuit** 存在当且仅当 $G$ 是连通的且每个顶点的度数都是偶数
  - **Euler tour(Euler Path)** 存在当且仅当 $G$ 是连通的且有且只有两个顶点的度数是奇数
- 有向图
  - 有**欧拉回路**当且仅当 G 是弱连通的且每个顶点的出度等于入度
  - 有**欧拉路径**当且仅当 G 是弱连通的且有且仅有一个顶点的出度比入度大 1，有且仅有一个顶点的入度比出度大 1，其余顶点的出度等于入度
- 考虑用 DFS 跑一遍，会得到很多个小环（每次回溯换一种颜色），似乎并不满足我们的需求，如图
  ![](/public/assets/Courses/FDS/FDS笔记/img-2023-12-05-09-01-05.png)
  - 但实际上，我们可以将这些环合并起来，比如：5-10-4-5；4-1-3-······-4，可以把第一条环中的 4 替换成第二条环……

!!! note
    - The path should be maintained as a linked list.
    - For each adjacency list, maintain a pointer to the last edge scanned.
    - $T = O(|E| + |V|)$

***
## 7. Sort
- Preliminaries（准备工作）
  - `void X_Sort(ElementType A[], int N)`
  1. N must be a legal integer
  2. Assume integer array for the sake of simplicity
  3. `>` and `<` operators exist and are the only operations allowed on the input data
  4. Consider internal sorting only（bonus 里涉及外部排序）

### 7.1. 一般分析
- 排序算法的一般属性
  1. in-place: 是否需要额外的空间
  2. stability: 是否稳定

#### 7.1.1. 稳定性
- 对于一个序列，如果存在两个**相等**的元素
  - 排序后它们的相对位置不变，则称这个排序算法是稳定的
  - 排序后它们的相对位置发生了变化，则称这个排序算法是不稳定的
- 稳定排序：冒泡、归并、插入、基数
- 不稳定排序：快排、希尔、堆排、选择

#### 7.1.2. 简单排序算法的下界
> 一个逆序是指数组中 $i<j$ 但 $A[i]>A[j]$ 的序偶 $(A[i]>A[j])$

交换不按原序排列的相邻元素会恰好消除一个逆序，因此插入排序的运行时间为 $O(I+N)$. 其中 $I$ 为原始数组中的逆序数，当逆序数较少时插入排序以线性时间运行。
> $N$ 个互异数的数组的平均逆序数为 $C_n^2/2=\frac{N(N-1)}{4}$
> 通过交换**相邻**元素进行排序的任何算法平均需要 $\Omega(N^2)$ 时间

!!! note 从插入排序到希尔排序
    思想：交换相邻元素只能消除一个逆序，因此我们倾向于交换距离较远的元素，这样可能一次消除多个逆序。这也就从插入排序引出了希尔排序。

#### 7.1.3. 排序算法的一般下界
> 只使用比较的任意排序算法最坏情形下都需要 $\Omega(N\log N)$ 次比较

!!! note proof
    使用决策树证明：共 $N!$ 种排序可能，因此决策二叉树有 $N!$ 片叶子，则树的深度至少为 $\log_2N!$，因此至少需要 $\log N!=\Omega(N\log N)$ 次比较。
- 这也就是说，只使用比较情况下，快速排序的时间复杂度已经是最优了

#### 7.1.4. 大型结构的排序
- 问题：交换两个大型的结构体可能是非常昂贵的
- 解法：加入对结构数组的 Index Table，交换 index 而不是直接交换结构体。最后返回的是 index table
- 当然如果想要真的排序数组的话，可以在最后根据 index table 对结构数组交换指针。注意到**每个排列都是由不相交的环构成**，所以可以直接交换指针，不会出现问题
- 最坏情况下有 $\lfloor N/2 \rfloor$ cycles 并且需要 $\lfloor 3N/2 \rfloor$ record moves。因此这最后的重排的时间复杂度为 $T=O(mN)$, where $m$ is the size of the structure.

### 7.2. Insert Sort（插入排序）
- in-place, stable
```c
void InsertionSort (ElementType A[], int N)
{
    int j, P;
    ElementType Tmp;
    for (P = 1; P < N; P++) {
        Tmp = A[P];  /* the next coming card */
        for (j = P; j > 0 && A[j - 1] > Tmp; j--)
            A[j] = A[j - 1];
            /* shift sorted cards to provide a position for the new coming card */
        A[j] = Tmp;  /* place the new card at the proper position */
    }  /* end for-P-loop */
}
```
- 分析
  - 最佳情况 - 输入数据是已经排好序的，那么运行时间为 $O(N)$
  - 最坏情况 - 输入数据是逆序的，那么运行时间为 $O(N^2)$

### 7.3. Shell Sort（希尔排序）
- in-place, unstable
- 基本思想：将数组分成若干个子序列，分别进行插入排序
  - 需要定义一个 increment sequence $h_1 < h_2 < \dots < h_t$，用来确定子序列在原始数组中的间隔，先按 $h_t$ 排序，再 $h_{t-1}$……以此类推
  - 关键点在于增量序列的选取
    1. 最初提出时选取 $h_t = \lfloor \frac{N}{2} \rfloor$, $h_{k} = \lfloor \frac{h_{k+1}}{2} \rfloor$
    2. Hibbard's increment sequence: $h_k = 2^k-1$，最坏情况下运行时间为 $O(N^{3/2})$，计算机模拟下的平均运行时间为 $O(N^{5/4})$
    3. Sedgewick's increment sequence: $h_k = 9 \times 4^k - 9 \times 2^k + 1$ or $h_k= 4^i - 2 \times 2^i + 1$，最坏情况下运行时间为 $O(N^{4/3})$，计算机模拟下的平均运行时间为 $O(N^{7/6})$

!!! note
    An $h_k$-sorted file that is then $h_{k-1}$-sorted remains $h_k$-sorted.

- 代码
    ```c
    void Shellsort(ElementType A[], int N)
    {
        int i, j, Increment;
        ElementType Tmp;
        for (Increment = N / 2; Increment > 0; Increment /= 2) {  /*h sequence */
            for (i = Increment; i < N; i++) { /* insertion sort */
                Tmp = A[i];
                for (j = i; j >= Increment; j -= Increment)
                    if (Tmp < A[j - Increment])
                        A[j] = A[j - Increment];
                    else
                        break;
                A[j] = Tmp;
            } /* end for-I and for-Increment loops */
        }
    }
    ```

### 7.4. Heap Sort（堆排序）
- in-place or out-place, unstable
- 两个算法
  - Algorithm1 (out-place): not good
    ```c
    void heapsort(ElementType H[], ElementType Tmp[], int N)
    {
        BuildHeap(H); /* BuildHeap */
        for (i = N - 1; i > 0; i--)
            Tmp[i] = DeleteMin(H); /* O(log N) */
        for (i = 0; i < N; i++)
            H[i] = Tmp[i]; /* O(1) */
    }
    ```
  - Algorithm2 (in-place)
    ```c
    void Heapsort(ElementType A[], int N)
    {
        int i;
        for (i = N / 2; i >= 0; i--) /* BuildHeap */
            PercDown(A, i, N);
        for (i = N - 1; i > 0; i--) {
            Swap(&A[0], &A[i]); /* DeleteMax */
            PercDown(A, 0, i);
        }
    }
    ```
  - 基本采取的是后面那个，所需的额外空间为 $O(1)$（for swap）
- 对 N 个互异项的随机排列进行堆排序，平均比较次数为 $2N\log N - O(N\log\log N)$

!!! note
    这里的堆我们是从 $0$ 开始计数（无哨兵），因此左儿子应该是 $2*i+1$
    尽管堆排序在平均时间复杂度上优于 Shell Sort，但在实际应用中往往使用 Sedgewick’s increment sequence 的 Shell Sort 更快，因为它没有常数项且在 $N$ 不够大的时候 $\log N$ 不比 $N^{1/6}$ 更小

### 7.5. Merge Sort（归并排序）
- out-place, stable
- 代码（三个函数）
    ```c
    /* function for users to call */
    void Mergesort(ElementType A[], int N)
    {
        ElementType *TmpArray = malloc(N * sizeof(ElementType)); /* need O(N) extra space */
        if (TmpArray != NULL) {
            MSort(A, TmpArray, 0, N - 1);
            free(TmpArray);
        }
        else
            FatalError("No space for tmp array!!!");
    }

    void MSort(ElementType A[], ElementType TmpArray[], int Left, int Right)
    {
        int Center;
        if (Left < Right) { /* if there are elements to be sorted */
            Center = (Left + Right) / 2;
            MSort(A, TmpArray, Left, Center);     /* T( N / 2 ) */
            MSort(A, TmpArray, Center + 1, Right);    /* T( N / 2 ) */
            Merge(A, TmpArray, Left, Center + 1, Right);  /* O( N ) */
        }
    }

    /* Lpos = start of left half, Rpos = start of right half */
    void Merge(ElementType A[], ElementType TmpArray[], int Lpos, int Rpos, int RightEnd)
    {
        int i, LeftEnd, NumElements, TmpPos;
        LeftEnd = Rpos - 1;
        TmpPos = Lpos;
        NumElements = RightEnd - Lpos + 1;
        while (Lpos <= LeftEnd && Rpos <= RightEnd) /* main loop */
            if (A[Lpos] <= A[Rpos])
                TmpArray[TmpPos++] = A[Lpos++];
            else
                TmpArray[TmpPos++] = A[Rpos++];
        while (Lpos <= LeftEnd) /* Copy rest of first half */
            TmpArray[TmpPos++] = A[Lpos++];
        while (Rpos <= RightEnd) /* Copy rest of second half */
            TmpArray[TmpPos++] = A[Rpos++];
        for (i = 0; i < NumElements; i++, RightEnd--)
            A[RightEnd] = TmpArray[RightEnd]; /* Copy TmpArray back */
    }
    ```

!!! note
    1. 需要注意的是，如果我们每次递归调用 Merge 都局部声明一个临时数组，那么任意时刻就会有 $\log N$ 个临时数组处于活动期，$S(N) = O(N\log N)$ ，这对于小内存的机器是致命的。注意到 Merge 只在每次递归调用的最后一行，因此任何时刻只需要一个临时数组活动，而且可以使用该临时数组的任意部分，这样节约了空间
    2. Merge Sort 需要线性外部内存，复制数组缓慢，因此不适合用于内部排序，但对于外部排序是有用的。
    3. Merge Sort 的另外好处是可以并行，并且支持链表排序
- 时间复杂度分析
    $$
    \begin{align*}
    T(1) &= 1\\
    T(N) &= 2T(N / 2) + O(N)\\
    &= 2^k T(N / 2^k) + k * O(N)\\
    &= N * T(1) + \log N * O(N)\\
    &= O(N + N \log N)\\
    \end{align*}
    $$
- Iterative Version —— 自下而上
    ![](/public/assets/Courses/FDS/FDS笔记/img-2023-12-12-09-03-53.png)
  - 具体代码略

### 7.6. Quick Sort（快速排序）
- in-place, unstable
- 快速排序被认为是已知的实践中最快的排序算法，它的平均时间复杂度为 $O(N\log N)$，最坏情况下为 $O(N^2)$
- 基本思路与流程与 mergesort 比较相像，只是少了合并的过程
  - 如果 $S$ 中的元素个数是 0 或者 1 则返回
  - 从 $S$ 中取任意元素为主元
  - 将 $S - \{v\}$ 分为两个不相交的集合，$S_1 = \{ x \in S - \{v\} | x\le v \}$, $S_2=\{ x \in S - \{v\} | x\ge v \}$
  - 返回 $quicksort(S_1), v, quicksort(S_2)$
- 关键在于主元 pivot 的选取
- 对小数组，插入排序比快速排序更快，设置一个截止范围 Cutoff(e.g. 10)。当 N 小于阈值的时候采用插入排序。这个 Cutoff 不是指对整个数组做判断，而是迭代调用到最后都转化为小数组，对这个小数组用插入排序。

!!! note
    pivot 左边的都比它小，右边的都比它大。也就是说，pivot 一定会被排到它最终的位置上；更进一步，$n$ 次有效（非空）的快排至少会有 $n$ 个元素到达最终位置

#### 7.6.1. 选取主元 pivot
- 错误的方法 $Pivot=A[0]$
这样如果输入是顺序或者反序的，那么每次划分所有元素全部落入$S_2$, 选取主元并没有带来任何帮助，完成排序需要 $O(N^2)$ 的时间。
- 安全做法 Pivot = random select from A[]
    但随机数的产生是昂贵的
- **三数中值分割法** Pivot = median(left, center, right)
一组 N 个数的中值是第 $\lceil N/2 \rceil$ 大的数，主元最好是选择中值，但这很难算出，而且会明显减慢排序的速度。因此我们可以使用左端、右端和中心位置上的三个元素的中值作为主元。
这样消除了错误方法中的最坏情形，减少了快速排序大概 5% 的运行时间。

#### 7.6.2. 划分策略 partition
- 有 **Lomuto** 和 **Hoare** 两种，这里直接用 Hoare（**双指针**）
- 首先我们将主元和最后一个元素交换，使得主元离开将要分割的数据段，随后 i 从第一个元素开始，j 从倒数第二个元素开始。（假设所有元素互异）
  - 当 i 在 j 的左边时，我们将 i 右移，移过那些小于主元的元素，并将 j 左移，移过那些大于主元的元素。
  - 当 i 和 j 停止时，i 指向一个大元素而 j 指向一个小元素，如果 i 在 j 的左边那么将这两个元素互换。
  - 重复上述过程，直到 i 和 j 彼此交错，停止交换
  - 将 i 和主元交换

- 对于那些等于主元的关键字，我们采用停止 i j 并交换的策略。因为若 i j 不停止，对于数组中所有关键字都相同的情况，我们需要有程序防止 i j 超出数组的界限。最后我们会把主元交换到 i 的最后位置上，也就是倒数第二个位置，这样我们又陷入了最坏情况（人话：宁可有很多 dummy swap，也要让 partition 比较均衡）

#### 7.6.3. 实现（伪代码）
```c
/* function for users to call*/
void  Quicksort(ElementType A[], int N)
{
    Qsort(A, 0, N - 1);
    /* A:   the array   */
    /* 0:   Left index  */
    /* N – 1: Right index   */
}
/* Return median of Left, Center, and Right */
/* Also order these and hide the pivot */
ElementType Median3(ElementType A[], int Left, int Right)
{
    int Center = ( Left + Right ) / 2;
    if (A[Left] > A[Center])
        Swap(&A[Left], &A[Center]);
    if (A[Left] > A[Right])
        Swap(&A[Left], &A[Right]);
    if (A[Center] > A[Right])
        Swap(&A[Center], &A[Right]);
    /* Invariant: A[Left] <= A[Center] <= A[Right] */
    Swap(&A[Center], &A[Right - 1]); /* Hide pivot */
    /* only need to sort A[ Left + 1 ] … A[ Right – 2 ] */
    return  A[Right - 1];  /* Return pivot */
}
void  Qsort(ElementType A[], int Left, int Right)
{
    int i, j;
    ElementType Pivot;
    if (Left + Cutoff <= Right)
    {
        /* if the sequence is not too short */
        Pivot = Median3(A, Left, Right);  /* select pivot */
        i = Left; j = Right – 1; /* Think: why not set Left+1 and Right-2? */
                                 /* Because below we use ++i instead of i++ */
        for( ; ; )
        {
            while (A[++i] < Pivot) {}  /* scan from left */
            while (A[––j] > Pivot) {}  /* scan from right */
            if (i < j)
                Swap(&A[i], &A[j]);  /* adjust partition */
            else
                break;  /* partition done */
        }
        Swap(&A[i], &A[Right - 1]); /* restore pivot */
        Qsort(A, Left, i - 1);      /* recursively sort left part */
        Qsort(A, i + 1, Right);     /* recursively sort right part */
    }  /* end if - the sequence is long */
    else /* do an insertion sort on the short subarray */
        InsertionSort(A + Left, Right - Left + 1);
}
```

#### 7.6.4. 复杂度分析
- $T(N)=T(i)+T(N-i-1)+cN$，即主元左侧子数组排序，主元右侧子数组排序，以及划分的线性时间（这里不考虑小数组转化成插入排序）
- The Worst Case
$$
T(N)=T(N-1)+cN \Rightarrow T(N)=O(N^2)
$$
- The Best Case
$$
T(N)=2T(N/2)+cN \Rightarrow T(N)=O(N\log N)
$$
- The Average Case
$$
T(N)=\frac{2}{N}\sum_{j=0}^{N-1}T(j)+cN \Rightarrow T(N)=O(N\log N)
$$
  - (Best 跟 Average 的区别在系数)

!!! question
    Q: Given a list of $N$ elements and an integer $k$. Find the kth largest element.
    A: 方法一：用堆排序，DeleteMin() $k$ 次；方法二（利用快速排序必定排好 pivot 的特性）：改造快速排序，每次划分后判断主元的位置，如果主元的位置大于 $k$，那么在左侧继续划分，否则在右侧继续划分（单侧快排）。

### 7.7. Bucket Sort（桶排序）
- out-place, stable
- 若数据分布在范围 $[0, M]$ 内，那么可以使用 $M+1$ 个桶 Count[M+1]，每个桶存放一个数据，读入到 $A_i$ 时其对应的 $Count$ 值加一，最后将桶中的数据按照编号顺序输出即可
- 由此可见，桶排序一般要求数据是整数，且分布范围较窄，最好还是分布均匀的
- 伪代码
    ```c
    {
        initialize count[];
        while (read in a student’s record)
            insert to list count[stdnt.grade];
        for (i=0; i<M; i++)
            if (count[i])
                output list count[i];
    }
    ```
- 时间复杂度为 $O(N+M)$，其中 $N$ 为数据个数，$M$ 为数据范围。可以看到，这是一个线性时间的排序算法，但是需要额外的空间 $O(M)$，且对数据要求比较高
- **计数排序**是**桶排序**的一种改版，每个桶只存储单一键值。事实上，上面讲的所谓“桶排序”其实就是计数排序，桶排序的一个桶应该是可以存储一个区间，然后内部再用任意排序算法的

### 7.8. Radix Sort（基数排序）
- out-place, stable
- **基数排序**可以看作是计数排序的优化，将较大的数据按位分解，实现以较少的桶完成排序

- 基数排序分为 MSD(Most Significant Digit first，最高有效位优先基数排序) 和 LSD(Least Significant Digit first，最低有效位优先基数排序) 两种
- 一般而言，后者的性能更好，这里只介绍后者，代码如下
    ```c
    void LSDRadixSort(ElementType A[], int N, int numDigits)
    {
        int i;
        ElementType B[MaxDigit]; // MaxDigit 个桶
        for (int D = 1; D <= numDigits; ++D) // 从低位到高位
        {
            for (i = 0; i < MaxDigit; i++) // 初始化桶
                B[i] = 0;
            for (i = 0; i < N; i++) // 统计每个桶中的记录数
                B[GetDigit(A[i], D)]++;
            for (i = 1; i < MaxDigit; i++) // 累加得到每个桶的最后位置
                B[i] += B[i - 1];
            for (i = N - 1; i >= 0; i--) // 将所有记录按桶的序号依次收集到 Tmp 中
                Tmp[--B[GetDigit(A[i], D)]] = A[i];
            for (i = 0; i < N; i++) // 复制回去
                A[i] = Tmp[i];
        }
    }
    ```
- 可并行性 (?)
- PPT 的例子没看懂
- 复杂度分析：时间复杂度为 $O(P(N+B))$，其中 $P$ 为位数，$B$ 为桶数，$N$ 为数据个数。可以看到，这是一个线性时间的排序算法，但是需要额外的空间 $O(N+B)$

### 7.9. Hash（散列，哈希）
#### 7.9.1. 哈希表
- 哈希表 (hash table, ht) 也称为散列表，是一种数据结构，它通过把关键字值映射到表中一个位置，来使得各个操作都变成 $O(1)$ 时间，这些操作包括：
  1. 查找关键字是否在表中
  2. 查询关键字
  3. 插入关键字
  4. 删除关键字
- 几个定义
  - 关键字也称为标识符 (identifier)
  - 一个位置是一个桶 (bucket)，一个桶可以有多个槽 (slot)。多个关键字对应同一个位置时，将不同关键字存在同一个位置的不同槽中
  - 对于标识符 $x$，定义一个哈希函数 $f(x)$ 表示 $x$ 在哈希表 ht[] 中的位置 (bucket)
  - 设哈希表 ht 的大小为 $b$（即 $f(x)$ 值域为 $[0,b−1]$），最多有 $s$ 个槽，则定义以下值：
    1. $T$ 表示 $x$ 可能的不同标识符 (or hash value) 个数，$T \le b$
    2. $n$ 表示 ht 中所有不同标识符 (or hash value) 的个数
    3. 标识符密度 (Identitifier density) 定义为 $n/T$
    4. 装载密度 (Loading density) 定义为 $λ=n/(sb)$
  - 当存在 $i_1 \neq i_2$，但 $f(i_1)=f(i_2)$ 的情况，则称为发生了碰撞（collision）
  - 当将一个新的标识符映射到一个满的桶时，则称为发生了溢出（overflow）
    - 当 s = 1 时，碰撞和溢出将同时发生

#### 7.9.2. 哈希函数
- $f$ 要满足的性质：
  - 容易计算，最小化冲突的数量
  - 应该是无偏见 (unbiased) 的，即 $\forall x, i$，我们有 $P(f(x)=i)=\frac{1}{b}$，这样的哈希函数称为均匀哈希函数。
  - TableSize 最好是一个素数，这样对随机输入，关键字的分布比较均匀
- 例如：
$$
f(x)=(\sum_{i=0}^{N-1} x[N-i-1]*32^i)~\%~TableSize~~~~~\text{/* if x is a string */}
$$
  - 这里用 32 是因为这是大于等于 27 的第一个 2 的幂次，于是可以用左移 5 次来实现（加速的小 trick）

#### 7.9.3. 分离链接
- 解决冲突的一种方法是分离链接 (separate chaining)，将哈希映射到同一个值的所有元素保存在一个列表（链表）中
- 分离链接法没有槽的概念，或者说可以认为是 $s=+\infty$
- 结构体定义
    ```c
    struct ListNode;
    typedef struct ListNode *List;
    struct HashTbl;
    typedef struct HashTbl *HashTable;
    struct ListNode {
        ElementType Element;
        List Next;
    };
    /* List *TheLists will be an array of lists, allocated later */
    /* The lists use headers(for simplicity), though this wastes space */
    struct HashTbl {
        int TableSize;
        List *TheLists;
    };
    ```
  - 形象化解释如图
    ![](/public/assets/Courses/FDS/FDS笔记/img-2023-12-26-09-56-21.png)

- 创建空表
    ```c
    HashTable InitializeTable(int TableSize)
    {
        HashTable H;
        int i;
        if (TableSize < MinTableSize) {
            Error("Table size too small");
            return NULL;
        }
        H = malloc(sizeof(struct HashTbl)); /* Allocate table */
        if (H == NULL)
            FatalError("Out of space!!!");
        H->TableSize = NextPrime(TableSize);  /* Better be prime */
        H->TheLists = malloc(sizeof(List) * H->TableSize);  /*Array of lists*/
        if (H->TheLists == NULL)
            FatalError("Out of space!!!");
        for(i = 0; i < H->TableSize; i++) {   /* Allocate list headers */
            H->TheLists[i] = malloc(sizeof(struct ListNode)); /* Slow! */
            if (H->TheLists[i] == NULL)
                FatalError("Out of space!!!");
            else
                H->TheLists[i]->Next = NULL;
        }
        return H;
    }
    ```
- 查询关键字
    ```c
    List Find(ElementType Key, HashTable H)
    {
        List L = H->TheLists[Hash(Key, H->TableSize)];  /* Hash function */
        List P = L->Next;
        while(P != NULL && P->Element != Key)  /* Able to compare different ADT */
            P = P->Next;
        return P;
    }
    ```
- 插入关键字
    ```c
    void Insert(ElementType Key, HashTable H)
    {
        List Pos, NewCell;
        List L;
        Pos = Find(Key, H);
        if (Pos == NULL) {   /* Key is not found, then insert */
            NewCell = malloc(sizeof(struct ListNode));
            if (NewCell == NULL)
                FatalError("Out of space!!!");
            else {
                L = H->TheLists[Hash(Key, H->TableSize)]; /* hash again, can be optimized */
                NewCell->Next = L->Next; /* insert to the front */
                NewCell->Element = Key;
                L->Next = NewCell;
            }
        }
    }
    ```
  - 关于上面的优化，我的想法是只要让 find 返回两个值就好了，一个是 bucket 的位置，一个是 bucket 中 slot 的位置（就是原本的 find 返回的东西）。只是这在 C 语言中似乎实现起来有些麻烦

#### 7.9.4. 开放地址
- 开放地址 (open addressing) 是另一种解决冲突的方法，当有冲突发生时，尝试选择其它单元，直到找到空的为止
- 开放地址法没有槽的概念，或者说可以认为 $s=1$
- 利用数组存储，可以想见，这是一种更加内存友好的方式。但是这种方式的缺点是，一方面，当装载密度 $\lambda$ 较大时，性能会急剧下降（找半天都没有空的）；另一方面，$\lambda < 0.5$ 时，认为有较高空间浪费
- 即有多个哈希函数 $h_0(x),h_1(x), \dots$，其中 $h_i(x)=(hash(x)+f(i)) ~ \% ~ TableSize$
  - 其中 $f(i)$ 为增量函数，有多种选取的方式
- 根据增量函数的定义我们可以分为线性探测和二次探测

##### 7.9.4.1. 线性探测 (Linear Probing)
- 增量函数 $f(i) = i$，即冲突了就往后一个一个找，直到找到空的为止
- 会导致聚集 (clustering)，即一旦发生了冲突，那么后面的元素都会聚集在一起，搜索次数会变得非常大
- 使用线性探测的探测次数
  1. 对于插入和不成功查找来说约为 $\frac{1}{2}( 1+\frac{1}{(1-\lambda)^2} )$ 次
  2. 对于成功的查找来说约为 $\frac{1}{2}( 1+\frac{1}{(1-\lambda)} )$ 次

##### 7.9.4.2. 二次探测 (Quadratic Probing)
- 增量函数为二次函数，一般为 $f(i)=i^2$
- 一个问题是可能会空着很多位置永远走不到利用不起来。可以由一个定理避免：

    !!! note Theorem
        - 如果使用平方探测，且表的大小是素数，且装载因子小于 0.5（至少有一半为空），那么一定能够找到一个空的位置
        - Proof：证明前 $\lfloor TableSize/2 \rfloor$ 的位置一定是不同的，利用同余理论即证。从而对于任意元素 $x$, 它有 $\lfloor TableSize/2 \rfloor + 1= \lceil TableSize/2 \rceil$ 个不同的位置可能放置这个元素
        - 更进一步的定理，如果这个素数有 $4k+3$ 的形式，那么增量函数 $f(i)=\pm i^2$ 可以探测整个 Table（不证明）
- 查找一个可以放置的位置
    ```c
    Position Find(ElementType Key, HashTable H)
    {
        Position CurrentPos = 0;
        int CollisionNum = Hash(Key, H->TableSize);
        while (H->TheCells[CurrentPos].Info != Empty && // Empty，后面会讲
               H->TheCells[CurrentPos].Element != Key) {
            CurrentPos += 2 * ++CollisionNum - 1; // CollisionNum 采用平方增量，小 trick
            if (CurrentPos >= H->TableSize) // 替代取模，小 trick
                CurrentPos -= H->TableSize;
        }
        return CurrentPos;
    }
    ```
  - 增量函数用 $f(i)=f(i-1)+2i-1$；取模操作直接用相减（证明：最多超一轮）
  - 注意：`return` 的值没有做是否为空的判断，调用 `Find` 的函数需要自己判断
- 插入元素
    ```c
    void Insert(ElementType Key, HashTable H)
    {
        Position Pos = Find(Key, H);
        if (H->TheCells[Pos].Info != Legitimate) { /* OK to insert here */
            H->TheCells[Pos].Info = Legitimate;
            H->TheCells[Pos].Element = Key; /* Probably need strcpy */
        }
    }
    ```
  - `Legitimate`（有效）涉及删除问题
    $$
    info = \left\{ \begin{array}{ll}
                    Empty & \textrm{empty cell} \\
                    Legitimate & \textrm{nonempty cell} \\
                    Deleted & \textrm{cell once occupied, now empty} \\
                   \end{array} \right.
    $$

!!! note
    - 如果有太多的 deletions，插入将会严重减慢
    - 平方探测解决了线性探测的聚团问题，但也不是说没有聚团问题，只是聚团的概率变小了，这称为 secondary clustering 问题，只在 $hash(x_1) = hash(x_2)$ 时才会发生

#### 7.9.5. 双哈希 (Double Hash)
- 更进一步地避免 secondary clustering 问题，可以使用双哈希（double hashing）的方法，即使用两个哈希函数 $h_1(x)$ 和 $h_2(x)$，冲突时的增量函数为 $f(i)=i*h_2(x)$
  1. 其中 $h_2(x)$ 不能为 0
  2. 且确保可以探测整个表
- 比如 $hash_2(x)=R-(x~\%~R)$，其中 $R$ 为小于表大小的素数，且 $R$ 与表大小互质

!!! note
    - 如果双哈希实现没有问题，模拟表明预期的探测数量几乎与 random 冲突解决策略相同
    - 实践中，平方探测的性能一般已经足够，且避免使用第二个哈希函数，可能更简单、更快

#### 7.9.6. 再哈希 (Rehashing)
- 跟双哈希是完全不同的两个概念，不要搞混
- 对于使用平方探测的开放地址散列法，如果表的元素过多甚至接近填满，那么操作的运行时间将开始消耗过长。这时就需要 rehashing
- 步骤如下
  1. 建立一个大约两倍大（一般是两倍值往上取最近质数）的表
  2. 扫描原始散列表
  3. 利用新的散列函数将元素映射到新的散列值，并插入
- 确切来说，这些条件下使用 rehashing
  1. 当表的装载因子 $\lambda$ 达到某个阈值时
  2. 当插入失败时
  3. 表快要填满一半就 rehashing
- 时间复杂度：$O(N)$，其中 $N$ 为元素个数
- 通常在重哈希之前应该有 $N/2$ 个插入，所以 $O(N)$ 重哈希只会给每个插入增加一个恒定的代价。
- 然而，在交互式系统中，不幸的用户的插入导致 rehashing，可能会看到速度减慢。

#### 7.9.7. 题外话
- 哈希在安全方面的应用
  - 哈希逆向：已知 $h(x)$，求 $x$
  - 哈希值与原始值的协方差越小越好，这样就不容易被破解

***

## 8. Bonus Hw:
- Queue Using Two Stacks, 简单，感觉像是拓展视野提示可以用两个 stack 实现 queue 用的
- Replacement Selection, 较难，涉及外部排序算法
### 8.1. 外部排序算法
- 整节内容可以参考 [一眨眼的功夫了解什么是外部排序算法 (biancheng.net)](http://data.biancheng.net/view/76.html)
- 外部排序的效率不再取决于内部排序的时间复杂度，而是访问外部的次数
#### 8.1.1. 多录平衡归并算法
- 归并的核心在于胜者树和败者树
#### 8.1.2. 置换选择排序算法
- 也用到了败者树