#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "TCS",
  lang: "zh",
)

#info()[
  - 简单梳理，不适合用来学习。可以参考 #link("https://note.tonycrane.cc/cs/tcs/toc/")[TonyCrane 的笔记]
]

#let generate = $attach(=>, br:G, tr: \*)$
#let yield = $attach(|-, br: M)$
#let yields = $attach(|-, tr: \*, br: M)$
#let tri = $gt.tri #h(0pt)$
#let em = $union.sq #h(0pt)$
#let DFA = math.text("DFA")
#let NFA = math.text("NFA")
#let REX = math.text("REX")
#let CFG = math.text("CFG")
#let CNF = math.text("CNF")
#let PDA = math.text("PDA")
#let TM = math.text("TM")
#let DTM = math.text("DTM")
#let NTM = math.text("NTM")
#let CF = math.text("CF")
#let REC = math.text("REC")
#let EQ = math.text("EQ")
#let SOME = math.text("SOME")
#let ALL = math.text("ALL")
#let NotALL = math.text("NotALL")
#let INF = math.text("INF")
#let MIN = math.text("MIN")
#let DTIME = math.text("DTIME")
#let NP = $N#h(-2pt)P$
#let poly = math.text("poly")
#let SAT = math.text("SAT")
#let NPC = $N#h(-2pt)P#h(-1pt)C$
#let Clique = math.text("Clique")
#let VC = math.text("VC")

= Language, FA 与 REX
- 给定一个 Decision Problem $P$，可以转化为 language $L = {"encodings of yes-instance of" P}$，判断 if encoding $w in L$
- 语言的定义：字母表、字符串、语言
  - alphabet: *finite* set of symbols
  - string: finite sequence of symbols from alphabet
  - language: set of strings over alphabet
  - 字符串与语言的操作: concatenation, exponentiation, reversal
    - 注意：$emptyset = {} != {e}, A dot {e} = A, A^0 = {e}, A^* = A^0 union A^+, A compose emptyset = emptyset$
- DFA
  $ M = (K, Si, de, s, F) $
  - Configuration
  - DFA 与 Language
    - 一个 DFA $M$ 接受一个 Language，记为 $L(M)$；反过来，一个 $L$ 可能不被 DFA 接受(not regular)，也可能被多个接受
- NFA
  $ M = (K, Si, De, s, F) $
  - Configuration
  - 理解方式：NFA 可以猜测该往哪里转移，且总能猜对
  - Simple NFA: 没有 transition 到 $s$，$F={f}$ 为单集合
- DFA 与 NFA 的关系：完全等价
  - 如何转化 NFA $M=(K, Si, De, s, F) -->$ DFA $M = (K, Si, de, s, F)$
  - $K'=2^K, s'=E(s), F'={Q in K'|Q inter F != emptyset}$
  - $de: forall Q in K', forall a in Si$
    $ de(Q,a) = union_(q in Q){union_(p:(q,a,p) in De) E(p)} $
    - 翻译成人话：对状态集合中的每个元素 $q$，它能通过 $a$ 到的所有状态 $p$，$p$ 的 e-transition 集合。外层 union 才是真 union，内层 union 是从 $K-> 2^K$，即幂集要考虑完整
    - 另外注意考虑 $M$ 中没画出来的 transition 和 $emptyset$
- 正则语言：有自动机可以接受的语言
  - 正则闭包：Union, Intersect, Concatenation, Star（思考用 FA 的证明）
  - 证明*是*：DFA, NFA, REX, Closure property
  - 证明*否*：Pumping Theorem, Closure property + 反证
  #theorem(title: "Pumping Theorem")[
    对 regular language，存在 $p >= 1$，$s.t. forall w in L ~(abs(w) > p)$，满足 $w = x y z$，且
    #grid3(
      columns: (1fr, 1fr, 1fr),
      [(1): $x y^i z in L ~(i >= 0)$], [(2): $abs(y) > 0$], [(3): $abs(x y) =< p$]
    )

    证明（$p$ 为 DFA 状态数，用抽屉原理）和运用
  ]
- REX
  - 用 REX 表示*所有* regular language
    - 思考证明，主要是任意 regular language 到 REX 的方向。思路，regular language 都有对应 NFA 接受它，简化成 Simple NFA，动态规划去边（掌握运算过程）
      - 简化为 $K={q_1,q_2,...,q_n}, s=q_(n-1),F={q_n}$
      - $L_(ij)^k$ 表示从 $q_i -> q_j$ 的路径表示的语言（其对应 REX 为 $R_(ij)^k$），且中间状态（不包含首尾）下表不大于 $k$
      - 目标 $R_((n-1)n)^(n-2)$，起始 $R_(i i)^0, R_(ij)^0$，递推关系 $ R_(ij)^k = R_(ij)^(k-1) union R_(i k)^(k-1) (R_(k k)^(k-1)) R_(k j)^(k-1) $
  - 特别注意 $emptyset <-> L(emptyset) = {} = emptyset, ~~~~ emptyset^* <-> L(emptyset^*)={e}$
- 总结
  - $DFA <==> NFA <==> REX$

= CFG
- CFG 上下文无关语言
  - notation $G=(V,Si,S,R)$，a *finite* set of symbols, set of terminals, start symbol, set of rules
    - non-terminals: $V-Si$ or $V \\ Si$
  - $G$ generates a string $w$: $S #generate w$;~ $G$ generates $L(G) = {w in Si^*|G "generates" w}$
- PDA: Pushdown Finite Automata
  - notation $P=(K,Si,Ga,De,s,F)$，其中多了个 $Ga$ 表示栈中符号集合，$De$ 变成 $(K times (Si union {e}) times Ga^*) times (K times Ga^*)$ 的子集
  - Configuration
  - PDA 接受字符串，要求起始和末尾是空栈，其它和 NFA 相同
  - Simple PDA: $F={f}$ 为单集合，每个 transition 要么 pop 要么 push 一个字符
- CFG 和 PDA
  - CFG $->$ PDA: 根据 CFG 在 stack 中猜测性地产生 string，将生成的内容和输入比较，如果匹配则接受（实际上二者同时）
  - PDA $->$ Simple PDA $->$ CFG，有点麻烦先不看
  - PDA 往往更 affordable
- CFL
  - RL 一定是 CFL
  - CFL 闭包，Union, Concatenation, Star，但这里 Intersect 和 Complementary 不再成立（掌握前者的反例和后者的证明）
  #theorem(title: "Pumping Theorem")[
    对 CFL，存在 $p >= 1$，$s.t. forall w in L ~(abs(w) > p)$，满足 $w = u v x y z$，且
    #grid3(
      columns: (1fr, 1fr, 1fr),
      [(1): $u v^i x y^i z in L ~(i >= 0)$], [(2): $abs(v)+abs(y)>0$], [(3): $abs(v x y) =< p$]
    )

    了解如何证明：考虑节点最少的能生成 $w$ 的 parse tree，non-terminals 只有 $abs(V-Si)$ 个，令 $p$ 为节点最大 fanout 的 $abs(V-Si)+1$ 次方，对树的高度形成限制……

    掌握如何运用
  ]

= Turing Machine
== 图灵机定义
- TM 定义为一个纸带和能够进行单元格左右移动、符号读写的读写头
  - 特殊符号 $tri, em$ 分别表示纸带无法覆盖的最左侧和空格子
  - notation $M=(K,Si,de,s,H)$。相比 DFA 把 $F$ 改成了 $H={y,n} subset K$ 为停机状态，$de$ 变成
    $ overbrace(K-H,"非停机状态") times !!! underbrace(Si,"读写头读到符号") !!! -> overbrace(K,"次态") times \(underbrace({<-,->},"左右移动") union underbrace((Si - {tri}),"写入的符号")\) $
    - 需要满足 $forall q in K, de(q,tri)=(p,->)$ for some $p$（最左了只能往右）
  - Configuration 很复杂，基本上记为 $(q, tri em a underline(b) a)$ 就好
  - diagram 我们这一届没讲
  - $M$ accepts / rejects if $(s,tri underline(em) w) #yields (y\/n,tri u underline(a) w) $；但还有一种可能是 looping
- 判定与半判定，语言的分类
  $
  M #[*semidecide*] L "if" cases("accept if" w in L, "reject or looping if" w in.not L) \
  M #[*decide*] L "if" cases("accept if" w in L, "reject if" w in.not L)
  $
  - $M$ semidecide / recognize $L(M)$（存在且唯一），这个 $L$ 称为 recursively enumerable / recognizable
  - $M$ decide $L$（如果它一定会停机），这个 $L$ 称为 recursive / decidable
  - 掌握通过构建图灵机（自然语言形式）说明一个语言是 recursive 的方法，如 ${a^n b^n c^n | n >= 0}$

== 变种图灵机
  - multiple tapes 多带图灵机（构建大格子纸带）
- two-way infinite tape 无限纸带（用双带模拟）
- multiple head 多读写头图灵机（每次扫描所有头）
- 2-dimensional tape 二维纸带图灵机（反对角线映射成一维）
- random access 随机访问图灵机（多步移动拆成单步）
- non-deterministic 非确定图灵机
  - notation $M=(K,Si,De,s,H)$，其中 $De$ 变成 $((K-H) times Si) times (K times ((Si-{tri}) times {<-,->}))$（其实就是变成 relation）
  - semidecide
    $ M #[*semidecide*] L "if" cases(exists "some branches accept" w in L, "no branch accepts" w in.not L "(reject or looping)") $
  - decide
    $ M #[*decide*] L &"if" cases(exists "some branches accept" w in L, "every branch reject" w in.not L) ~~ "并且" \ & forall w, exist N "s.t."~ "every branch halts within" N "steps" (N "depends on" w,M) $
    - 第二条什么意思呢？
      - 考虑一个图灵机，每一步向右走或停机，任意分支能停机但是可以任意长，满足第一条但不满足第二条（*会停机*和*一定步数内停机*是两个不同的概念）
      - 从 DTM 模拟的角度考虑，就是说非确定产生的树高度小于 $N$
  - NTM 可以被 DTM 模拟
    - Proof Sketch: DTM 要做的是 BFS 搜索 NTM 生成树直到找到停机状态
    - 用 3-tape DTM 来模拟 NTM：
      + 第一条用来装输入 $tri em w$
      + 第二条用来模拟 NTM $N$（在树上向下走）
      + 第三条用来枚举“提示”，指导第二条纸带里面在树上怎么走
    - 步骤：
      + 每一轮开始时将第一条纸带 copy 到第二条纸带上
      + 更新第三条纸带，指挥第二条纸带模拟 NTM 的树时每一步该采用哪个转换
      + 第三条纸带内容都读取结束后，判定第二条纸带上模拟的位置是否停机
        - 如果停机则结束；没停机则开始新的一轮，采用不同的第三条纸带内容
== 编码
- Church-Turing Thesis: Turing Machine $<==>$ Intuition of Algorithm
  - 于是我们在描述算法的时候，就不需要写复杂的定义，直接 high level 地写 pseudo code 即可
- Encoding
  - 一个 finite set 可以被编码
  - 任何由 finite set 构成的 finite tuple 可以被编码
  - 类似地，一个图 $G=(V,E)$ 可以被编码，DFA, NFA, PDA, CFG, REX 都可以被编码，而图灵机本身 $M=(K,Si,De,s,H)$ 也可以被编码（难度就这么上来了）

= 语言的分类
- 引入图灵机后，我们就可以对所有语言进行分类了
  - Regular: DFA / NFA
  - Context-Free: CFG / PDA
  - Recursive: TM semidecide(enumerate)
  - Recursively Enumerable: TM decide(recognize)
- 这里我们先按下不表，首先看看如何证明一个语言是 recursive 的

== Decidable Problem 与 Recursive Language
- 所有 决策问题（判定问题） decidable problem 都可以转化为 "Given a string $w$, whether $w in {"encoding of yes-instance"}$"，后者就是一个 recursive language
  + 判定问题 $R_1$
    $ L = {\"G\"| G "is a connect graph"} $
    - 定义证明：选择一个 node 去 mark 它，然后不断 spread 到 neighbors 上
  + 判定问题 $R_2$ ($A_DFA$)
    $ A_DFA = {\"D\"\"w\"| D "is a DFA that accepts" w} $
    - 定义证明：在 $D$ 上跑 $w$，返回其结果
  + 判定问题 $R_3$ ($A_NFA$)
    $ A_NFA = {\"N\"\"w\"| N "is a NFA that accepts" w} $
    - $R_3 =< R_2$ 规约：利用 NFA 和 DFA 的等价性
  + 判定问题 $R_4$ ($A_REX$)
    $ A_REX = {\"R\"\"w\"| R "is a regular expression that generates" w} $
    - $R_4 =< R_3$ 规约：利用 REX 和 NFA 的等价性
  + 判定问题 $R_5$ ($E_DFA$)
    $ E_DFA = {\"D\"|D "is a DFA with" L(D) = emptyset} $
    - 定义证明：在 $D$ 的 state diagram 上跑 DFS，如果能到 $f in F$ 则接受，否则拒绝
  + 判定问题 $R_6$ ($EQ_DFA$)
    $ EQ_DFA = {\"D_1\"\"D_2\"|D_1,D_2 "are two DFAs with" L(D_1) = L(D_2)} $
    - $R_6 =< R_5$ 规约：利用对称差 $A plus.circle B = A union B - A inter B$，$A = B$ iff $A plus.circle B = emptyset$，然后用 $R_5$ 看看该语言的 DFA 的 state diagram 是不是真的为空
    - 现在回过头来看，这种利用对称差的方法，把两个输入的问题转化为单个，自己想肯定是想不出来的，好好体会一下
- 规约
  - $A =< B$，如果 $B$ yes，那么 $A$ 也 yes
  #diagram(
    node((-1,0),[$ A_NFA \ \"D\"\"w\" $], radius: 18pt),
    edge((-1,0), marks: "-|>", (1,0)),
    node((1,0),[$ A_DFA \ \"D\"\"w\" $], radius: 18pt),
  )
  - 只要满足以下两点即可规约
    + 建立 $\"D\"\"w\" in A_NFA$ iff $\"D\"\"w\" in A_DFA$ 的双射
    + 这个 function 是 computable 的
    - 注：规约这种东西，虽然我们要求双向 iff 条件，但对于问题本身还是单向的。$A =< B$ 代表 $A$ 的判定难度小于等于 $B$
  - 利用规约证明 Regular Language $subset$ recursive Language
    - $D$ is a DFA, $L(D) = {w | D "accepts" w}$
    - $w in L(D) <==> D "accepts" w <==> \"D\"\"w\" in A_DFA$
    - 于是从 $A_DFA$ is recursive 可以推出 $L(D)$ is recursive，进而得证
- 下面继续看一些判定问题
  7. 判定问题 $C_1$ ($A_CFG$)
    $ A_CFG = {\"G\"\"w\"| G "is a CFG that generates" w} $
    - 定义证明：把 $G$ 转化成 $G' in CNF$，它生成一个 $abs(w)=n$ 的串需要替换 $2n-1$ 次，进行 $abs(R)^(2n-1)$ 次枚举
  + 判定问题 $C_2$ ($A_PDA$)
    $ A_PDA = {\"P\"\"w\"| P "is a PDA that accepts" w} $
    - $C_2 =< C_1$ 规约：利用 PDA 和 CFG 的等价性
  + 判定问题 $C_3$ ($E_CFG$)
    $ E_CFG = {\"G\"|G "is a CFG with" L(G) = emptyset} $
    - 定义证明：从反向染色的角度思考 $w in L(G)$，首先把 terminals 和 $e$ 染色，然后对每个规则，如果右侧都被染色了，那么染色它的左侧，循环往复。最后如果 $S$ 没有被染色则接受

== 语言的分类与停机问题
- 语言的分类
  $ "Regular" ~~ subset.neq_1 ~~ "Context-Free" ~~ subset.neq_2 ~~ "Recursive" ~~ subset_3 ~~ "Recursively Enumerable(R.E.)" ~~ subset_4 ~~ "All Languages" $
  - 我们已经知道 $1$ 和 $2$ 是真包含，分别举例 ${a^n b^n|n>=0}, {a^n b^n c^n|n>=0}$
  - 现在我们想知道 $3$ 和 $4$ 的关系，事实上也是真包含（利用“停机问题的变种 —— 接受问题”来导出）
    - $3$: $A_TM = {\"M\"\"w\"|M "is a TM that accepts" w}$，以及后续非常多的举例
    - $4$: $A_d = {\"M\"|M "is a TM that does not accept" \"M\"}$ 以及 $overline(A_TM)$
- 引理 (existence of non R.E. languages)
  + 一个集合 $A$ 是 countable，当且仅当它是 *finite* 或存在*双射*(bijection) $f: A -> cN$，and uncountable otherwise
  + 条件可以加强到当且仅当*单射*(injection) $g: A -> cN$（以单射 $g(dot)$ 的升序排序 $A$，然后 $f(a)="rank of" a$ 即为双射）
  + 任何 countable 集合的 subset 也是 countable 的
  + 任何 languages 都是 countable 的（因为它是 $Si^*$ 的子集，而 $Si^*$ 可以根据其字母的权重和元素的长度进行排序而双射到 $cN$）
  + 图灵机的集合 ${M|M "is a" TM}$ 是 countable 的（因为它对应于一个 ${0,1}^*$ 上的 language ${\"M\"| M "is a" TM}$）
  + $Si$ 上所有 languages $L subset Si^*$ 的集合 $cL$ 是 uncountable 的（每个 $L$ 都可列，但它们合在一起的 $cL$ 不可列）
    - diagonalization 证明，反证法，$Si^*$ 和 $cL$ 都 countable，就以它们为长宽构建对角线上的反例
  - 根据 $5$ 和 $6$，我们知道每个 TM semidecide one and only one R.E. language，那么 R.E. 和 ALL Languages 之间一定有空缺，回答了上面 $4$ 处的包含关系问题
- 接受问题 ($A_TM$ and $A_d$) （也可以用停机问题 $H_TM$ and $H_d$ 来证明，像上一届那样）
  - $A_TM$: 所有 “图灵机接受字符串组合” 的集合；$A_d$: 所有不接受自己的编码的图灵机的集合
  - $A_TM$ 是 R.E. 的
    - 定义证明：构建 universal TM $U$ 来 semidecide $A_TM$，$U$ 接受 $\"M\"\"w\"$，返回其结果 (accept / reject / looping)
  - 但 $A_TM$ 不是 recursive 的，$A_d$ 不是 R.E. 的：
    - 两步证明，第一步假定 $A_d$ not recursive，把它规约到 $A_TM$；第二步用 diagonalization 证明确实 not recursive (even not R.E.)
      - 如果 $A_TM$ 是 recursive 的，那么 $A_d$ 也是。$exist M_1 "decide" A_TM$，那么构造 $M^*$，用 $M_1$ 检查 $M$ 是否接受 $\"M\"$，进而判定 $A_d$
      - $A_d$ 甚至不是 R.E. 的。反证法，$exist TM D "semidecide" A_d$，它对于任意输入 $\"M\"$，如果 $M$ accepts $\"M\"$ 将 rejects / looping，如果 $M$ rejects / looping $\"M\"$ 将 accept，那么对于 $\"D\"$ 本身就寄了
    #q[注：$A_TM$ 的 not recursive 证明也可以用自编码实现，见后]
  - 且 $overline(A_TM)$ 不是 R.E.，下述定理的直接推论：
    - 如果 $L, overline(L)$ 是 R.E. 的，那么 $L$ 是 recursive 的（并行跑，总是至少一个会停机，利用它来 accept / reject，排除了 looping 的情况）
    - 从而，任何一个 $L$ 如果是 not recursive but R.E. 的，那么其补集 $overline(L)$ 就是 not R.E. 的

== Rice's Theorem 和 Not Recursive Languages
- 重新审视*规约 (Reduction)* —— （逆否用法）
  - Formal definition:
    - $A,B$ are languages over some alphabet $Si$
    - A reduction from $A$ to $B$ (denoted as $A =< B$) is a *computable* function $f: Si^* -> Si^*$, ~s.t.
    $ forall w in Si^*, w in A iff f(w) in B $
  - If there is a reduction from $A$ to $B$ $A =< B$, then:
    + if $B$ is $P$, so is $A$
    + if $A$ is not $P$, neither is $B$
    - ($P$ is regular, context-free, recursive, recursively enumerable, etc.)
  - 例子：把*乘法*规约到*加法* $A =< B$
    + $B$ yes 则 $A$ yes: 如果 $M$ 可以做加法，那它一定可以做乘法（之前的用法）；
    + $A$ no 则 $B$ no: 反过来，如果 $M$ 不能做乘法，那它一定不能做加法！（如果能做加法，它就应该能做乘法）
- 考虑停机问题 $H_TM = {\"M\"\"w\"| M "is a TM halting on" w}$（跟之前的 $A_TM$ 比较）
  - $H_TM$ 是 not recursive 但 R.E. 的，跟 $A_TM$ 的一样，证明方法也一样（分别用对角化证明和 $U$ 模拟证明即可）
  - 这里用另一种方法，把 $A_TM$ 规约到它，如果 $A_TM$ 是 not recursive 的，那么 $H_TM$ 也是！
    - 怎么规约？$M "accepts" w iff M^* "halts on" w$，对同一输入 $x$，如果 $M$ accept 我也 accept，如果 $M$ reject 或 looping 我就 looping（不 reject）
    - 具体而言，假设 $H_TM$ 是 recursive 的，$exist M_H "decide" H_TM$，据此构建 $M_A$ 来 decide $A_TM$ 推出矛盾
    - 如何构建？对于输入 $\"M\"\"w\"$，$M_A$ 再根据 $M$ 和规约关系构建一个 $M^*$，然后再在 $M_H$ 上跑 $\"M^*\"\"w\"$，如果 $M_H$ accepts 了，那么 $M^*$ accepts $\"w\"$，根据规约就有 $M$ accepts $\"w\"$，那 $M_A$ 就返回 accept，否则返回 reject
    - 这里一共有 $4$ 个 TM，$M_A,M_H$ 是用来解问题的算法，对应 $A_TM, H_TM$；而 $M,M^*$ 虽然也是 TM，却是作为被判定的输入编码（但它们作为 TM 构建了 iff 关系）
    - *总结一下套路就是*：利用 $A$ 的 no 证明 $B$ 的 no，就是把 $A$ 规约到 $B$，然后反证假设 $B$ 是 recursive，根据由此得出的 $M_B$ 构建 $M_A$ 解决 $A$ 来推出矛盾，解决过程中用 $A$ 的输入 $\"M\"$ 根据规约构建 $B$ 的输入 $\"M^*\"$，然后在 $M_B$ 上跑 $M^*$，返回 $M_B$ 的结果
- 下面继续看一些不可判定问题
  + 不可判定问题 $E_TM$
    $ E_TM = {\"M\"|M "is a TM accepting" e} $
    - $A_TM =< L_1$ 规约：$M "accepts" w iff M^* "accepts" e$
    - 如果 $M$ accept $w$，我 accept 所有 inputs（包括 $e$），如果 $M$ reject $w$ 或 looping，我 reject 所有 inputs（也可以 looping，没有影响）
  + 不可判定问题 $SOME_TM$
    $ SOME_TM = {\"M\"|M "is a TM accepting some strings"} $
    - 跟 $E_TM$ 一模一样的规约
  + 不可判定问题 $ALL_TM$
    $ ALL_TM = {\"M\"|M "is a TM accepting all strings"} $
    - 跟 $E_TM$ 一模一样的规约
    - 另外，$1 wave 4$ 题把 accepting 换成 halts on 也是一样的做法（把用来规约的 $A_"XX"$ 换成 $H_"XX"$ 即可）
  + 不可判定问题 $EQ_TM$
    $ EQ_TM = {\"M_1\"\"M_2\"|M_1,M_2 "are two TMs accepting the same language"} $
    - $ALL_TM =< EQ_TM$ 规约：$M "accepts all strings" iff M^*, M_r "accepts same languages"$
    - 给 $ALL_TM$ 构建一个参照物 $M_r$，它接受所有输入（相当于是构建了 $ALL_TM$ 中的一个实例）
  + 不可判定问题 $R_TM$
    $ R_TM = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is regular"} $
    - $A_TM =< R_TM$ 规约：$M "accepts" w iff L(M^*) "is not regular"$
      - 这里跟之前不一样的地方在于，我们在规约时把 regular 与否反了一下，又绕了一层（本质上其实是在证 $overline(R)_TM$，因为假定 Recursive 所以没关系）
    - 如果 $M$ accept $w$，那么令 $L(M^*)=A_TM$（怎么做？用 $U$ semidecide $A_TM$，$L(U)=A_TM$），它都不 recursive 自然不 regular；如果 $M$ reject $w$ or looping，就令 $L(M^*)=emptyset$ 是 rugular 的
      - 从后面 Rice' Theorem 的证明过程来看，这里也不一定要用 $U$，也可以从 regular languages 随意拿一个 $A$ 出来，存在 TM $M_A$ semidecides $A$（有点大材小用，但为了不引入 TM 到 DFA 之间的规约，避免复杂性），然后令 $M "accepts" w iff L(M^*)=L(M_A)=A "is regular"$
  + 不可判定问题 $CF_TM$ ($CF_TM$)
    $ CF_TM = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is context-free"} $
    - 跟 $R_TM$ 一模一样的规约
  + 不可判定问题 $REC_TM$
    $ REC_TM = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is recursive"} $
    - 跟 $R_TM$ 一模一样的规约
- 上述判定问题的统一化 (Rice's Theorem)
  #theorem(title: "Rice's Theorem")[
    $ R(P) = {\"M\"|M "is a TM with" L(M) in cL, cL subset "all R.E. Languages and is non-empty with property" P } "is not recursive" $
    比如 $cL_1={L|e in L}, cL_2 = {L|L!=emptyset}, cL_3={L|Si^*=L}={Si^*}$，$L_4$ 不好说（？），$cL_5, cL_6, cL_7$ 分别是所有 regular languages 的集合、CF languages 的集合、 REC languages 的集合
  ]
  - 规约证明
    - 不妨令 $emptyset in.not cL$（否则令 $cL=overline(cL)$ 即可），从 $cL$ 中取出一个 $A$，存在 $M_A$ semidecide $A$
    - $A_TM =< R$ 规约：$M "accepts" w iff L(M^*)=L(M_A)=A in cL$，$M^*$ 对于 input $x$，如果 $M$ accepts $w$ 就返回 $M_A$ 跑 $x$ 的结果 $(L(M_A) in cL)$；如果 $M$ reject $w$ or looping 就 reject $(emptyset in.not cL)$
- 最后再举一个复杂点的例子，不可判定问题 $ALL_PDA$
  $ ALL_PDA = {\"P\"|P "is a PDA with" L(P)=Si^*} \
    NotALL_PDA = {\"P\"|P "is a PDA with" L(P)!=Si^*} $
  - 它跟前面复杂的点在于，前面都是用 TM 之间的规约，这里我们要先把 $NotALL_PDA$ 规约到 $ALL_PDA$（传递 undecidable 性），然后再用 $H_TM$ 规约到 $NotALL_PDA$ 来证明其 undecidable，而这是 TM 到 PDA 之间的构造，要求：$M "halts on" w iff L(P) != Si^*$
  - 为此，把 "computing history of TM that halts on $w$" 表示成一个 string：$tri em s w \# dots.c \# tri em a h v$ ($c1 \# c2 \# dots.c \# c_k$, $ci$ is a configuration)
  - $P$ 接受所有不满足上述形式的字符串，这包括三种情况：(1) 输入 $c1$ 不满足其形式；(2) 停机时 $c_k$ 不满足其形式；(3) $exist ci attach(cancel(|-), br:M) c_(i+1)$
  - 让 PDA 非确定性地判定以上三种情况，只要有一个不满足就接受，其中 (1), (2) 都好理解，对于 (3)
  $
  #text(size: 7pt,fill: blue)[#h(45em)这里有个小细节被略去，$c_(2i)$ 需要写成 $c_(2i)^R$ 才能让 PDA 顺序处理] \
  cases(
    ci &= ~ tri a_1 a_2 dots.c a_(j-1) #box([$a_j q a_(j+1)$],outset:(x: 2pt, y: 3pt),stroke: red) a_(j+2) dots.c a_n,
    c_(i+1) &= ~ tri a_1 a_2 dots.c a_(j-1) #box([~~~~~~~~~~],baseline: 1pt,outset: (x: 2pt, y: 2pt),stroke: red) a_(j+2) dots.c a_n,
    reverse: #true
  )
  #grid(
    rows: 2,
    row-gutter: 3pt,
    grid.cell(align: left)[对#redt[红框]外的部分，push and pop 可以验证 #bluet[#sym.arrow.t]],
    grid.cell(align: left)[~~ #redt[红框]内的部分，其规则是有限的，一一枚举]
  )
  $

#note(caption: "总结：DFA, PDA, TM 的判定问题")[
 #grid3(
  columns: (1fr, 1fr, 1fr),
  [$
  DFA, NFA, REX \
  cases(
    reverse: #true,
    A_DFA\,A_NFA\,&A_REX,
    &E_DFA,
    &EQ_DFA,
    &ALL_DFA,
    &INF_DFA
  )
  "decidable"
  $],
  [$
  PDA, CFG \
  cases(
    reverse: #true,
    A_PDA\,A_CFG,
    E_PDA\,E_CFG,
  )
  "decidable" \
  cases(
    reverse: #true,
    EQ_PDA,
    ALL_PDA
  )
  "undecidable"
  $],
  [$
  TM \
  cases(
    reverse: #true,
    &A_TM,
    &E_TM,
    &EQ_TM,
    &H_TM,
    R_TM\,CF_TM\,&REC_TM,
    &ALL_TM,
    &INF_TM
  )
  "undecidable"
  $],
 )
 - 从中我们可以看出，从 DFA 到 PDA 再到 TM，虽然模型的计算能力越来越强，但是其判定却越来越复杂，算是一种 trade-off 吧
]

== 自输出程序问题
- 考虑如何让图灵机输出自己，具体而言，就是在伪代码中获取自己的编码（这并不是一件 trivial 的事情，需要严格证明才能使用）
  ```
  M: on input w
    1. obtain its coding "M"
    2. ...
  ```
  - 做法是将 $M$ 分成 $A, B$ 两个部分，并利用 $q$ 函数解决循环定义
    ```
    A: on any input
      1. write "B" to the tape
      2. halt
    B: on input w
      1. compute q(w)
      2. write it to the tape and swap it with w
    ```
    - 其中 $q: Si^* -> Si^*$ such that $q(w)=\"M_w\"$，其中 $M_w$ 为打印 $w$ 的 TM，即 $q$ 通过输出反推 encoding，赋予我们解锁的能力（对这里的 $A, B$ 问题而言，$w=\"B\", q(w)=\"A\"$）
- 进一步引出
  #theorem(title: "Recursion Theorem")[
    - 给定任意 TM $T$，都能找到 TM $R$ 使得对于任意 string $w$，$R "on" w <==> T "on" \"R\"w$ \
    - 从而跑任意程序 $R$ 时如果用了自己的编码 $\"R\"$，那么实际是先有一个合乎常理的 $T "on" \"R\"w$，然后存在这样一个 $R$ 与之等价
    - 了解如何证明：把 $R$ 分解为三段 $A,B,T$ 的拼接，输入 $w$ 后，$A$ 在纸带上输出 $\"B\"\"T\"$，$B$ 在纸带上输出 $\"A\"$ 并把 $w\"B\"\"T\"\"A\"$ 重排成 $\"A\"\"B\"\"T\"w$ 即 $\"R\"w$
  ]
  - 由此我们可以更容易地判定 $A_TM$ is not recursive
    - 回忆之前的证法，是先用对角化证明 $A_d$ not recursive (not R.E)，进一步规约传递到 $A_TM$
    - 而现在，假设 $A_TM$ is recursive（存在 $M_A$ decides $A_TM$），我们可以直接构造出 $M^*$ 并在内部获取自己的编码，返回 $M_A$ 跑 $\"M^*\"w$ 的结果之逆（控制实际结果跟 $A_TM$ 的猜测相反），从而推出矛盾
    #q[更根本地说，这样把对角化的构造压缩到自编码中，使伪代码证明更加简洁]

== 证明系统
- 我们把 strings 视作 statement $x$ 和 proof $t$，判断证明是否正确，本质上还是个图灵机
  $ V(x,t) = cases(1\, ~~~~ &"if" t "is valid for" x, 0\, &"otherwise") $
- 令 $Im$ 为 set of true statements (actually a language)，它的 proof system 是一个图灵机，满足以下条件
  - *Effectiveness*
    $ "for" x,t in Si^*, ~ V "either accepts or rejects" (x,t) $
  - *Soundness*
    $ "for" x in.not Im, ~ V(x,y) = 0 ~ forall y "(i.e. unprovable)" $
  - *Completeness*
    $ "for" x in Im, exist y ~s.t.~ V(x,t) = 1 "(i.e. provable)" $
- 完备证明系统与递归可枚举的等价性
  #theorem[
    $ A "has a complete proof system" <==> A "is recursively enumerable" $
    - 掌握证明思路
      - $=>$：（枚举证明）如果 $x in A$，由完备性总有 $t$ 证明它，那总归有字符串 $\"(x, t)\"$ 被图灵机接受；否则不一定能停机
      - $<=#h(0em)$：从图灵机构建证明系统，输入 $(x,t)$，要求在 $t$ 步及以内停机才返回 $1$，否则直接返回 $0$，然后验证三个性质
  ]
  - 从该定理可以直接推论得到：存在一些语言 $Im$ 不存在 complete proof system
  - 我们之前已经知道 $overline(A_TM)$ 是 not R.E. 的，于是它不存在完备证明系统。但也可以忘掉之前结论用这里的方法来证明
- 于是从证明系统这里，我们又得到一种方法证明 $overline(A_TM)$ not R.E.
  - 如果它是 R.E 的，或者说如果它存在 complete proof system $V$。就构造 $R$，在过程中拿到自己的编码 $\"R\"$，然后*以升序不停枚举* $y in Si^*$，把 $(\"R\"x, y)$ 传入 $V$，直到其返回 $1$ 停止并接受 (weird)
  - $R "accepts" x <=> exist y st V(\"R\"x, y)=1 <=> \"R\"x in overline(A_TM)$ （接受当且仅当不接受，矛盾）

== 图灵机枚举字符串
- 给图灵机扩充一个功能，TM 从空状态开始执行，走到 output states 时输出纸带上的字符串，这样构成的集合构成 language $L$
  - 这样的 $L$ 称为图灵可枚举的 (turing enumerable)，$M$ enumerates $L$
- 图灵可枚举跟递归可枚举的关系
#theorem[
  $ A "is turing enumerable" <==> A "is recursively enumerable" $
  - 掌握证明思路（如果有限显然成立，考虑无限情况）
    - $=>$：$M$ 枚举 $A$，构造 $M'$ 半判定 $A$，对每个输入 $x$，字面意思直接枚举，如果 $x$ 等于某个被 $M$ 枚举的字符串 $w$ 就接受即可。不一定停机？没关系因为是证明 R.E.
    - $<=#h(0em)$：$M'$ 半判定 $A$，构造图灵机 $M$ 输出（打印）那些被接受的字符串，具体而言，$M$ 以升序遍历 $Si^*$ 中的 $s_j$，检查它是否被 $M'$ 接受，如果是则 output $s_j$
      - 但这里存在问题是 semidecide 不保证停机，为此引入分步跑策略（一维无穷结构二维化），保证每个串都被跑到但又不至于陷入 loop
        ```
        construct M:
          1. for i = 1, 2, 3, ... (steps in each round)
          2.   for j = 1, 2, 3, ... , i (in increasing order of Sigma^*)
          3.     run M' on s_j for i steps
          4.     if M' accepts s_j
          5.       output s_j
        ```
]
- 判定程序最简性（做不到）
  - 先定义程序最简性（编码更短的功能就变了）
    $ "A TM is minimal if": forall N, abs(\"N\") < abs(\"M\") => L(N) != L(M) $
  - 假设下述问题是 turing enumerable (R.E.) 的
    $ MIN_TM = {\"M\"|M "is minimal"} $
    - 那么对于其中的最简程序，我们可以借此（凭空）构造出 $R$ 比它们中某一个更简洁
      - 方法是直接拿到自己的编码 $\"R\"$（它的长度有限），然后枚举 $MIN_TM$ 直到找到 $\"B\"$ 比 $\"R\"$ 更长（因为长度有限总会结束）
      - 然后神奇的地方在于，可以直接让 $R$ 返回 $B$ 的结果，强行让 $R$ 与 $B$ 结果相同，而 $R$ 比 $B$ 更简洁，产生矛盾
      - 矛盾的根源点，个人认为在于：1. $R$ 可以很神奇地拿到自己的编码（但这在之前有定理做保证）；*2. $MIN_TM$ 是图灵可枚举的*

#note(caption: "个人总结：可（半）判定与不可（半）判定的技巧")[
  - 证明可判定(recursive)
    + 通过定义证明，构建 TM 来 decide 它（具体问题具体分析）
    + 通过定理证明，$A, overline(A)$ is R.E. $==>$ $A$ recursive
    + 通过规约证明，当前语言 $A =<$ 一个已知 recursive 语言（前面举了大量例子）
    + 降维打击，如果它是 regular / context-free，那它自然是 recursive 的
  - 证明可半判定(R.E.)
    + 通过定义证明，构建 TM 来 semidecide 它（$U$ 模拟或具体问题具体分析，或利用二维化技巧枚举）
    + 通过规约证明，当前语言 $A =<$ 一个已知 R.E. 语言
    + 降维打击，如果它 regular / context-free / recursive，那它自然是 R.E. 的
  - 证明不可判定(not recursive)
    + 通过规约证明，一个已知 not recursive 语言 $=<$ 当前语言 $A$（前面举了大量例子，包括最开始的 $A_TM$ 也是这么证的）
    + 降维打击，如果它是 not R.E.，那它自然不可能 recursive
    + 利用自编码，获取自己的编码然后自己打自己（如 $A_TM$ 的第二种证明技巧）
  - 证明不可半判定(not R.E.)
    + 对角化(diagonalization)技巧证明（如 $A_d$）
    + 通过规约证明，一个已知 not R.E. 语言 $=<$ 当前语言 $A$
    + 通过定理的逆否证明，$A, overline(A)$ is R.E. $==>$ $A$ is recursive 的反证（如 $overline(A_TM)$）
    + 利用完备证明系统和自编码，升序枚举 proof 直到得证并构造矛盾（如 $overline(A_TM)$）
    + 利用图灵可枚举和自编码，证明如果 R.E. 进而 enumerable 的情况下的反常结论（如程序最简性 $MIN_TM$）
]

= 复杂度理论
- decidable 问题之中，根据解决需要的时间空间复杂度，能将其分出复杂类来。这一部分将探讨复杂类的定义和关系
- 定义 $M$ 是一个在任意输入上停机的标准 DTM
  - $M$ 的 running time 是一个函数 $f: ! underbrace(NN, "input length") !! -> underbrace(NN, "#steps")$，$M$ 在任意长为 $n$ 的输入上运行的步数不超过 $f(n)$
- 定义复杂类
  $ DTIME(t(n)) = {L|L "can be decided by some standard DTM with running time" O(t(n))} $
  - 这里 $t$ 是 $n$ 的函数，比如多项式。另外这个定义依赖于计算模型
  - 比如 $A={0^k 1^k|k>=0}$
    - 在单带图灵机上，先扫一遍检查是否是一串 $0$ 一串 $1$ 的形式，然后每轮间隔着各删消掉一半 $0$ 和 $1$（需要 $log n$ 轮），最后检查是否为空，复杂度 $O(n log n)$
    - 在双带图灵机上，可以同时扫描两个串，在 $O(n)$ 内解决
  - 一般地，多带图灵机在 $t(n)$ 内停机的问题，单带图灵机最多用 $O(t^2(n))$ 时间解决
  - 更一般地，Cobham-Edmonds Thesis: Any "reasonable" and "general" deterministic model of computation is polynomially related
- 自然地，定义 $P$ 为所有可以在多项式时间内被确定性图灵机判定的语言的集合
  $ P = union_(k>=0) DTIME(n^k) $
  - 利用这个猜想，该复杂类囊括了所有确定模型多项式可解问题
- 自然地我们会关心有哪些问题在这个复杂类中
  #theorem[
    #align(center, [Every context-free language is in $P$])
    - 之前证过，用 CNF 的形式最多 $abs(R)^(2n-1)$ 条规则，枚举即可解决
    - 现在我们要加强这一结论，在多项式时间内解决，证明思路就是利用动态规划减少重复计算
      - 子问题定义为 $T[i][j]={A in V-Si|A =>^* ai a_(i+1) dots a_j}$
      - 递归步骤定义为
        $ T[i][j] = union_(k=i)^(j-1) {A|A->B C and B in T[i][k] and C in T[k+1][j]} $
  ]

== NP 复杂类
- 然后还有一些未知是否在 $P$ 内的问题，但知道在 $NP$ 内
- 定义 $NP$ 复杂类为可以在*多项式时间内*被*非确定性图灵机*判定的语言的集合
- SAT 问题：给一个布尔表达式，问是否存在一种变量的组合使整体值为真
  - SAT 可以被 NTM 在 Poly time 内解决（非确定性生成变量再验证即可）
- 定义 Poly-time Verified：给之前证明系统的 completeness 条件加上多项式时间限制（且是 DTM）
  $ "for" x in Im, exist y in Si^* "with" abs(y) =< poly(abs(x)) st V(x,t) = 1 "(i.e. provable)" $
  - 显然 SAT 对于验证而言是很容易的，属于 Poly-time Verified
  #theorem[
    #align(center, [$L$ is poly-time verified $<==>$ $L in NP$])
    - 证明思路
      - $=>$：构建 NTM decide $SAT$，直接非确定地产生限制长度的 proof $y$ 即可，然后在 $V$ 上跑返回结果（$y$ 不长则 $V$ 跑不久）
      - $<=#h(0em)$：如果存在 NTM decide $L$，那么就有多项式长度的分支可被接受，跟着这条分支跑验证图灵机 $V$ 即可
  ]
- 定义 NPC 为
  $ A in NPC cases(#cnum(1) A in NP, #cnum(2) forall B in NP\, B le_P A) $
  - 即 $A$ 是 $NP$ 问题中最难的那一类
- 我们想要知道 $P =^? NP$
  #theorem(title: "Cook Levin Theorem")[
    #align(center, [$P = NP <==> SAT in P$])
    - 或者说，$SAT in NPC$
    - 证明 $SAT in NPC$，好尼玛复杂不看了
  ]
- 多项式规约
  - A computable $f:  Si^* -> Si^*$，满足 $x in A iff f(x) in B$ 的基础上再提出: Given $x$, $f(x)$ can be computed in poly-time
  - 则称 $A le_P B$
  #theorem[
    #align(center, [$A le_P B "and" B in P ==> A in P$])
    - 即 $B$ 比 $A$ 困难
  ]
  #theorem[
    #align(center, [$A le_P B "and" A in NPC "and" B in NP ==> B in NPC$])
    - 即 $B$ 比 $A$ 困难但依旧在 $NP$ 范畴的情况下，$A$ 都已经是 NPC 了，那 $B$ 更是
  ] <conversion>

== NP, NPC 问题及其规约
- 下面就是一堆巨几把难想、很考验智商的问题定义和规约转化了，套路就一个 @conversion
  - $A in NP$ 基本上利用非确定猜测能力随便乱写就行
  - 主要就看想不想得到怎么规约 $NPC "instance" le_P A$
- 3-SAT 问题
  - 定义如字面意思，每个子句有且仅有三个变量（并且要求是不同的，不能是同一变量的正逆）
  - 规约：把 $SAT$ 的非三个变量的子句等价转化为三个变量的子句。注意这里的等价不是说对 $forall y$ 成立，而是 $exist y$ 成立（SAT 问题的可满足性没有变化即可）
- Clique 团问题
  - 团的定义其实就是强联通分量
    $ Clique={\"G\"\"k\"| G "has a clique with at least" k "nodes"} $
  - 子句数为 $m$ 的 $3SAT$ is satisfiable $<==>$ $G$ 拥有一个 clique，大小至少为 $m$
  - $3SAT le_P Clique$，对 $3SAT$ 的每个子句构建图 $G$ 中的一个组，组与组之间变量不冲突就连边。注意最多 $9m^2$ 条边，是多项式的
    - $=>$：直接选取那些取值为 $1$ 的变量（节点），每组选取一个。组与组之间连边因此强联通，冲突变量不可能同时为 $1$ 因此不会同时入选
    - $<=#h(0em)$：由于组内不相连，因此每组只会选一个，而且选取的节点之间不会有冲突（有冲突的选不了），因此把选取的赋值为 $1$ 即可
- Vertex Cover 顶点覆盖问题
  - 顶点覆盖即一个顶点子集，使得每条边至少有一个端点在这个子集中
  - 子句数为 $m$、变量数为 $n$ 的 $3SAT$ is satisfiable $<==>$ $G$ 拥有一个 vertex cover，大小至多为 $n+2m$
  - $3SAT le_P VC$，对 $3SAT$ 的每个子句构建图 $G$ 中的一个*三节点组（两两连接）*，每个变量构建正反#bluet[两个节点（两两连接）]，共 $2n+3m$ 个节点。然后#bluet[蓝节点]和*黑节点*之间若相等，连#redt[红边]
    - 这里一共有 $n+3m+3m$ 条边，是多项式的。另外这样一张图，#bluet[蓝节点]至少选一个，*黑节点*至少选两个，才能构成覆盖
    - $=>$：我们约定每个子句中为真的 literal，取对应#bluet[蓝节点]
    - $<=#h(0em)$：咕咕
- DOUBLE-SAT 问题
  $ {\"phi\" : phi "is a cnf formular that has at least two satisfying assignments"} $
  - 非常简单的规约，给 SAT 的问题实例加上一个新子句 $dots and (y or overline(y))$ 即可
- 支配集问题
  - 支配集的定义是
  $ {\"G\"\"k\"| G "has a dominating set with" k "nodes"} $
  - 咕咕