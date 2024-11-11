#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "机器学习",
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
= Language, FA 与 REX
- 语言的定义：字母表、字符串、语言 #h(1fr)
- DFA:
  $ M = (K, Si, de, s, F) $
  - Configuration
  - DFA 与 Language
    - 一个 DFA $M$ 接受一个 Language，记为 $L(M)$；反过来，一个 $L$ 可能不被 DFA 接受(not regular)，也可能被多个接受
- NFA:
  $ M = (K, Si, De, s, F) $
  - Configuration
  - 理解方式：NFA 可以猜测该往哪里转移，且总能猜对
  - Simple NFA: 没有 transition 到 $s$，$F={f}$ 为单集合
- DFA 与 NFA 的关系：完全等价
  - 如何转化 NFA $M=(K, Si, De, s, F) -->$ DFA $M = (K, Si, de, s, F)$ #h(1fr)
  - $K'=2^K, s'=E(s), F'={Q in K'|Q sect F != emptyset}$
  - $de: forall Q in K', forall a in Si$
    $ de(Q,a) = union_(q in Q) union_(p:(q,a,p) in De) E(p) $
    - 翻译成人话：对状态集合中的每个元素，它能通过 $a$ 到的所有状态的 e-transition 集合，然后再对每个元素集合，就是最终到达的新的状态集合（注意考虑 $M$ 中没画出来的 transition 和 $emptyset$）
- 正则语言：有自动机可以接受的语言
  - 正则闭包：Union, Intersect, Concatenation, Star（思考用 FA 的证明）
  - 证明*是*：DFA, NFA, REX, Closure property
  - 证明*否*：Pumping Theorem, Closure property + 反证
  - Pumping Theorem: 对 regular language，存在 $p >= 1$，$s.t. forall w in L ~(abs(w) > p)$，满足 $w = x y z$，且
    #grid3(
      columns: (1fr, 1fr, 1fr),
      [(1): $x y^i z in L ~(i >= 0)$], [(2): $abs(y) > 0$], [(3): $abs(x y) =< p$]
    )
    - 证明（$p$ 为 DFA 状态数，用抽屉原理）和运用
- REX
  - 用 REX 表示*所有* regular language
    - 思考证明，主要是任意 regular language 到 REX 的方向。思路，regular language 用 NFA 表示，简化成 Simple NFA，动态规划去边（掌握运算过程）
      - 简化为 $K={q_1,q_2,...,q_n}, s=q_(n-1),F={q_n}$
      - $L_(ij)^k$ 表示从 $q_i -> q_j$ 的路径表示的语言（其对应 REX 为 $R_(ij)^k$），且中间状态（不包含首尾）下表不大于 $k$
      - 目标 $R_((n-1)n)^(n-2)$，起始 $R_(i i)^0, R_(ij)^0$，递推关系 $ R_(ij)^k = R_(ij)^(k-1) union R_(i k)^(k-1) (R_(k k)^(k-1)) R_(k j)^(k-1) $
  - 特别注意 $emptyset <-> L(emptyset) = {} = emptyset, ~~~ emptyset^* <-> L(emptyset^*)={e}$
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
  - CFL 闭包，Union, Concatenation, Star，但这里 Intersect 和 Overline 不再成立（掌握前者的反例和后者的证明）
  - Pumping Theorem: 对 CFL，存在 $p >= 1$，$s.t. forall w in L ~(abs(w) > p)$，满足 $w = u v x y z$，且
    #grid3(
      columns: (1fr, 1fr, 1fr),
      [(1): $u v^i x y^i z in L ~(i >= 0)$], [(2): $abs(v)+abs(y)>0$], [(3): $abs(v x y) =< p$]
    )
    - 了解如何证明：考虑节点最少的能生成 $w$ 的 parse tree，non-terminals 只有 $abs(V-Si)$ 个，令 $p$ 为节点最大 fanout 的 $abs(V-Si)+1$ 次方，对树的高度形成限制……
    - 掌握如何运用

= Turing Machine
== 图灵机定义
- TM 定义为一个纸带和能够进行单元格左右移动、符号读写的读写头
  - 特殊符号 $tri, em$ 分别表示纸带无法覆盖的最左侧和空格子
  - notation $M=(K,Si,de,s,H)$。相比 DFA 把 $F$ 改成了 $H={y,n} subset K$ 为停机状态，$de$ 变成 #h(1fr)
    $ overbrace(K-H,"非停机状态") times underbrace(Si,"读写头读到符号") -> overbrace(K,"次态") times \(underbrace({<-,->},"左右移动") union underbrace((Si - {tri}),"写入的符号")\) $
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
  - 掌握构建图灵机说明一个语言是 recursive 的方法，如 ${a^n b^n c^n | n >= 0}$
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
    $ M #[*decide*] L &"if" cases(exists "some branches accept" w in L, "every branch reject" w in.not L) ~~"并且" \ & forall w, exist N "s.t."~ "every branch halts within" N "steps" (N "depends on" w,M) $
    - 第二条什么意思呢？考虑一个图灵机，每一步向右走或停机，满足第一条但不满足第二条（*会停机*和*一定步数内停机*是两个不同的概念）
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
  - 类似地，一个图 $G=(V,E)$ 可以被编码，DFA, NFA, PDA, CFG, REX 都可以被编码，而图灵机本身 $M=(K,Si,De,s,H)$ 也可以被编码

== Decidable Problem 与 Recursive Language
- 所有 决策问题（判定问题） decidable problem 都可以转化为 "Given a string $w$, whether $w in {"encoding of yes-instance"}$"，后者就是一个 recursive language
  + 判定问题 $R_1$ #h(1fr)
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
    - $R_6 =< R_5$ 规约：利用对称差 $A plus.circle B = A union B - A sect B$，$A = B$ iff $A plus.circle B = emptyset$
- 规约 #h(1fr)
  - $A =< B$，如果 $B$ yes，那么 $A$ 也 yes
  #diagram(
    node((-1,0),[$ A_NFA \ \"D\"\"w\" $]),
    edge((-1,0), marks: "-|>", (1,0)),
    node((1,0),[$ A_DFA \ \"D\"\"w\" $]),
  )
  - 只要满足以下两点即可规约
    + 建立 $\"D\"\"w\" in A_NFA$ iff $\"D\"\"w\" in A_DFA$ 的双射
    + 这个 function 是 computable 的
  - 注：规约这种东西，虽然我们要求双向 iff 条件，但好像对于问题本身还是单向的
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
- Regular $subset.neq_1$ Context-Free $subset.neq_2$ Recursive $subset_3$ Recursively Enumerable(R.E.) $subset_4$ All Languages
  - 我们已经知道 $1$ 和 $2$ 是真包含，分别举例 ${a^n b^n|n>=0}, {a^n b^n c^n|n>=0}$
  - 现在我们想知道 $3$ 和 $4$ 的关系，事实上也是真包含（利用“停机问题的变种 —— 接受问题”来导出）
  - $3$: $A_TM = {\"M\"\"w\"|M "is a TM that accepts" w}$
  - $4$: $A_d = {\"M\"|M "is a TM that does not accept" \"M\"}$ 以及 $overline(A_TM)$
- 引理
  + 一个集合 $A$ 是 countable，当且仅当它是 finite 或存在双射(bijection) $f: A -> cN$，and uncountable otherwise
  + 条件可以加强到单射(injection) $g: A -> cN$（用 $f(dot)$ 的升序排序 $A$，然后 $g(a)="rank of" a$）
  + 任何 countable 集合的 subset 也是 countable 的
  + 任何 languages 都是 countable 的（因为它是 $Si^*$ 的子集，而 $Si^*$ 可以根据其字母的权重和元素的长度进行排序而双射到 $cN$）
  + 图灵机的集合 ${M|M "is a" TM}$ 是 countable 的（因为它对应于一个编码后的 language）
  + $Si$ 上所有 languages $L subset Si^*$ 的集合 $cL$ 是 uncountable 的（diagonalization 证明，反证法，$Si^*$ 和 $cL$ 都 countable，就以它们为长宽构建对角线上的反例）
    - 根据 $5$ 和 $6$，我们知道每个 TM semidecide only one R.E. language，那么 R.E. 和 ALL Languages 之间一定有空缺
- 关于 $A_TM$ 和 $A_d$
  - $A_TM$: 所有图灵机接受字符串组合的集合；$A_d$: 所有不接受自己的编码的图灵机的集合
  - $A_TM$ 是 R.E. 的
    - 定义证明：构建 universal TM $U$ 来 semidecide $A_TM$，$U$ 接受 $\"M\"\"w\"$，返回其结果 (accept / reject / looping)
  - 但 $A_TM$ 不是 recursive 的，$A_d$ 不是 R.E. 的：
    - 分两部分证明，第一步是把 not recursive 的 $A_d$ 规约到 $A_TM$，第二步是用 diagonalization 确实不 recursive（甚至 not R.E.）
      - 如果 $A_TM$ 是 recursive 的，那么 $A_d$ 也是。$exist M_1 "decide" A_TM$，那么就能用 $M_1$ 来检查 $M$ 是否接受 $\"M\"$
      - $A_d$ 甚至不是 R.E. 的。反证法，$exist TM D "semidecide" A_d$，对于任意输入 $\"M\"$，如果 $M$ accepts $\"M\"$ 它将 rejects / looping，对于任意 $M$ rejects / looping $\"M\"$ 它将接受，那么对于 $\"D\"$ 本身就寄了
  - 且 $overline(A_TM)$ 不是 R.E.
    - 是该定理的直接推论：如果 $L, overline(L)$ 是 R.E. 的，那么 $L$ 是 recursive 的（并行跑，总是至少一个会停机，利用它来 accept / reject，排除了 looping 的情况）

== Rice's Theorem 和 Not Recursive Languages
- 逆否规约
  - 例子：把*乘法*规约到*加法* $A =< B$
    + $B$ yes 则 $A$ yes: 如果 $M$ 可以做加法，那它一定可以做乘法（之前的用法）；
    + $A$ no 则 $B$ no: 反过来，如果 $M$ 不能做乘法，那它一定不能做加法！（如果能做加法，它就应该能做乘法）
- 考虑停机问题 $H_TM = {\"M\"\"w\"| M "is a TM halting on" w}$（跟之前的 $A_TM$ 比较）
  - $H_TM$ 是 not recursive 但 R.E. 的，跟 $A_TM$ 的一样，证明方法也一样（分别用对角化证明和 $U$ 模拟证明即可）
  - 这里用另一种方法，把 $A_TM$ 规约到它，如果 $A_TM$ 是 not recursive 的，那么 $H_TM$ 也是！
    - 怎么规约？$M "accepts" w "iff" M^* "halts on" w$，对同一输入 $x$，如果 $M$ accept 我也 accept，如果 $M$ reject 或 looping 我就 looping（不 reject）
    - 具体而言，假设 $H_TM$ 是 recursive 的，$exist M_H "decide" H_TM$，据此构建 $M_A$ 来 decide $A_TM$ 推出矛盾
    - 如何构建？对于输入 $\"M\"\"w\"$，$M_A$ 再根据 $M$ 和规约关系构建一个 $M^*$，然后再在 $M_H$ 上跑 $\"M^*\"\"w\"$，如果 $M_H$ accepts 了，那么 $M^*$ accepts 了 $\"w\"$，根据规约就有 $M$ accepts 了 $\"w\"$，那 $M_A$ 就返回 accept，否则返回 reject
    - 这里一共有 $4$ 个 TM，$M_A,M_H$ 是用来解问题的算法，对应 $A_TM, H_TM$；而 $M,M^*$ 虽然也是 TM，却是作为被判定的输入编码（但它们作为 TM 构建了 iff 关系）
    - *总结一下套路就是*：利用 $A$ 的 no 证明 $B$ 的 no，就是把 $A$ 规约到 $B$，然后反证假设 $B$ 是 recursive，根据由此得出的 $M_B$ 构建 $M_A$ 解决 $A$ 来推出矛盾，解决过程中用 $A$ 的输入 $\"M\"$ 根据规约构建 $B$ 的输入 $\"M^*\"$，然后在 $M_B$ 上跑 $M^*$，返回 $M_B$ 的结果
- 下面继续看一些不可判定问题
  + 不可判定问题 $L_1$ #h(1fr)
    $ L_1 = {\"M\"|M "is a TM that accepts" e} $
    - $A_TM =< L_1$ 规约：$M "accepts" w "iff" M^* "accepts" e$
    - 如果 $M$ accept $w$，我 accept 所有 inputs（包括 $e$），如果 $M$ reject $w$ 或 looping，我 reject 所有 inputs（也可以 looping，没有影响）
  + 不可判定问题 $L_2$
    $ L_2 = {\"M\"|M "is a TM accepting all strings"} $
    - 跟 $L_1$ 一模一样的规约
  + 不可判定问题 $L_3$ ($EQ_TM$)
    $ L_3 = {\"M_1\"\"M_2\"|M_1,M_2 "are two TMs that accept the same language"} $
    - $L_2 =< L_3$ 规约：$M "accepts all strings" "iff" M^*, M_r "accepts same languages"$
    - 给 $L_3$ 构建一个参照物 $M_r$，它接受所有输入（相当于是构建了 $L_2$ 中的一个实例）
  + 不可判定问题 $E_1$ ($R_TM$)
    $ E_1 = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is regular"} $
    - $A_TM =< E_1$ 规约：$M "accepts" w "iff" L(M^*) "is not regular"$
    - 如果 $M$ accept $w$，那么令 $L(M^*)=A_TM$（怎么做？用 $U$ semidecide $A_TM$，$L(U)=A_TM$），它都不 recursive 自然不 regular；如果 $M$ reject $w$ or looping，就令 $L(M^*)=emptyset$ 是 rugular 的
  + 不可判定问题 $E_2$ ($CF_TM$)
    $ E_2 = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is context-free"} $
    - 跟 $E_1$ 一模一样的规约
  + 不可判定问题 $E_3$ ($REC_TM$)
    $ E_3 = {\"M\"|M "is a TM with" L(M)={w|M "accepts" w} "is recursive"} $
    - 跟 $E_1$ 一模一样的规约
- 上述判定问题的统一化 (Rice's Theorem)
  $ R(P) = {\"M\"|M "is a TM with" L(M) in cL, cL subset "all R.E. Languages and is non-empty with property" P } $
  - 比如 $cL_1={L|e in L}, cL_2={L|Si^*=L}={Si^*}$，$L_3$ 不好说（？），$cL_4, cL_5, cL_6$ 分别是所有 regular languages 的集合、CF languages 的集合、 REC languages 的集合
  - 规约证明
    - 不妨令 $emptyset in.not cL$（否则令 $cL=overline(cL)$ 即可），从 $cL$ 中取出一个 $A$，存在 $M_A$ semidecide $A$
    - $A_TM =< R$ 规约：$M "accepts" w "iff" L(M^*)=L(M_A)=A in cL$，$M^*$ 对于 input $x$，如果 $M$ accepts $w$ 就返回 $M_A$ 跑 $x$ 的结果 ~~~~ ($L(M_A) in cL$)；如果 $M$ reject $w$ or looping 就 reject ($emptyset in.not cL$)

#note(caption: "总结：可（半）判定与不可（半）判定的技巧")[
  - 证明可判定(recursive)
    + 通过定义证明，构建 TM 来 decide 它（具体问题具体分析）
    + 通过定理证明，$A, overline(A)$ is R.E. $==>$ $A$ recursive
    + 通过规约证明，当前语言 $A =<$ 一个已知 recursive 语言（前面举了大量例子）
  - 证明可半判定(R.E.)
    + 通过定义证明，构建 TM 来 semidecide 它（$U$ 模拟或具体问题具体分析）
    + 通过规约证明，当前语言 $A =<$ 一个已知 R.E. 语言
  - 证明不可判定(not recursive)
    + 通过规约证明，一个已知 not recursive 语言 $=<$ 当前语言 $A$（前面举了大量例子，包括最开始的 $A_TM$ 也是这么证的）
  - 证明不可半判定(not R.E.)
    + 对角化(diagonalization)技巧证明（如 $A_d$）
    + 通过规约证明，一个已知 not R.E. 语言 $=<$ 当前语言 $A$
    + 通过定理的逆否证明，$A, overline(A)$ is R.E. $==>$ $A$ recursive 的反证（如 $overline(A_TM)$）
]