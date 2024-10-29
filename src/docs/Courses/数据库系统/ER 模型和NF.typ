---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#let null = math.op("null")
#let Unknown = math.op("Unknown")

#counter(heading).update(2)

= 第三部分：ER 模型和 Normal Form
== E-R模型
- 软件工程中，设计一个系统的时候，其步骤一般为：\ requirement specification $=>$ *conceptual-design* $=>$ logical-design $=>$ physical-design
  - 其在数据库设计中的对应为：\ user requirement specification $=>$ *E-R diagram* $=>$ logical schema $=>$ physical schema
- E-R模型由 enitites(实体)和 relations among entities(关系)组成

=== Entity set 实体集
#wrap-content(
  align: right,
  fig("/public/assets/Courses/DB/img-2024-04-01-14-23-25.png", width: 45%),
)[
  - 一个实体是一个独特的 object，并且 distinguishable from other objects，拥有一系列 attributes
  - 同一类实体共享相同的 attributes，实体集就是由同类型的实体组成的集合
  - 表示方法：长方形代表实体集合；属性写在长方形中，*primary key用下划线*标注
  - 实体集中对于属性的定义和之前的几乎一样
    - 实体集中属性定义可以存在组合与继承的关系（Composite,有点像细化的感觉）
    - 多值(Multivalued)属性，可以拆分出一个表
  - 一个复杂的例子如右图 #figure(none) <attr>
]

=== Relationship set 关系集
- 一个 relationship 是几个实体之间的联系，关系集就是同类关系之间构成的集合
- 一个 relationship 至少需要两个及以上的实体，一个关系集至少和两个实体集有关联（即 degree 至少为 $2$）
  - relationship 可以带有属性，带有 $N$ 个属性的关系可以看做是 $N+"degree"$ 元组
  - 一个关系集所关联的实体集的个数称为 *degree*，其中以二元关系集为主（且任何一个多元关系都可以转化为二元关系）
- Roles: 关系集不一定得是不同的两个实体集之间，同一个实体集中的某一个 label 在关系中作为不同的 *role*

=== E-R model constraints 约束
- mapping cardinalities *映射基数*
  - 二元关系中映射基数只有四种：#redt[一对一，一对多，多对一，多对多]
#grid(
  columns: (auto, auto),
  gutter: 2pt,
  [#figure(image("/public/assets/Courses/DB/img-2024-04-01-19-03-03.png"), caption: "一对一") <map-card>],
  [#figure(image("/public/assets/Courses/DB/img-2024-04-01-19-03-20.png"), caption: "一对多")],
  [#figure(image("/public/assets/Courses/DB/img-2024-04-01-19-03-34.png", width: 90%), caption: "多对一")],
  [#figure(image("/public/assets/Courses/DB/img-2024-04-01-19-03-47.png", width: 110%), caption: "多对多")],
)
- E-R模型中表示映射关系：箭头表示有且只有一，直线表示多
  - 还有一种数字表示法，应该不做要求
  - 多对多关系实现代价比一对多要高，因为多对多中的关系需要一个新的表来存储
  - 三元（或更高）关系中：*箭头只能出现一次*，否则会出现*二义性*
    - 下面的例子表示，每个学生的每个 project 只能有一位老师指导（学生可以开展多个 project，每个 project 可以有多个学生参与，导师可以指导多个学生、多个 project）
  #fig("/public/assets/Courses/DB/img-2024-04-01-19-13-33.png", width: 70%)
  - 但是上面的映射基数是对参与关系的实体而言，但不一定每个实体都参与
- 参与度约束
  - total participation：若一个实体集全部参与到关系中，要用*双线*
  - partical participation：部分参与
- key约束：
  - 对 entity set 而言，和以往定义基本一样，即足够区分
  - 对 relationship set 而言：
    - 关系集 $R$ 关联了实体集 $E_1, E_2, dots, E_n$，那么$R$ 的 primary key 应该是 $E_1, E_2, dots, E_n$ 各自 primary key 的 *Union*；如果关系集带有属性 $a_1, a_2, dots, a_m$，则属性也应该被加到 primary key 里（？）
    - 上面这个说法是一般情况下（均视为多对多），实际上 primary key 的选取还要考虑到映射基数，比如@map-card[图]中，四种情况的 primary key 为：
    #tbl(
      columns: 2,
      [either one],
      [{student_id}],
      [{instructor_id}],
      [{instructor_id, student_id}])
- 弱实体集weak entity set：一些实体集的属性不足以形成主键，就是弱实体集，与之相对的是强实体集
  - 用于表示一些关系中的依赖性，弱实体集需要和强实体集关联才有意义
  - 经常出现在一对多的关系中，在E-R图中需要用*虚线*标注（判别器）
  - 例子：primary key for $"section" - {"course_id", "sec_id", "semester", "year"}$
  #fig("/public/assets/Courses/DB/img-2024-04-01-14-33-25.png", width: 65%)
  - 注意到，如果我们将 $"course_id"$ 也写进 $"section"$，它就能变成 strong entity set，但是造成了 redundant attribute
- Redundant Attributes（冗余属性）
  - 一般来说，不允许冗余信息，即——拥有相同属性的两个实体集，这个属性应该在某一边被删掉，然后用关系集来表示，比如下图 $"student"$ 中的 $"dept_name"$
  #fig("/public/assets/Courses/DB/img-2024-04-01-20-10-34.png", width: 60%)
  - 但是回到 SQL，我们往往又会把这个冗余写回去，然后用一个 foreign key 表示联系
- E-R Diagram for a University Enterprise（一个复杂的例子）
#fig("/public/assets/Courses/DB/img-2024-04-01-14-03-21.png", width: 70%)

=== Reduction to Relational Schemas
- 从 E-R 模型归约（转化）到 relational schemas
- weak entity set 的转化，依赖属性拿过来，加上虚线属性一起变为 primary key
#fig("/public/assets/Courses/DB/img-2024-04-01-15-18-30.png", width: 60%)
- many-to-many relationship set 的转化
#fig("/public/assets/Courses/DB/img-2024-04-01-15-19-42.png", width: 60%)
- Many-to-one and one-to-many relationship set 的转化
  - 有两种方式，关系集独立或归到 many 的那一边
  #fig("/public/assets/Courses/DB/img-2024-04-01-14-54-41.png", width: 60%)
  - 一般来说下面那种好一些，但也不绝对，比如，当 instructor 成为多元关系或非常复杂的时候……
- one-to-one relationship set 的转化
  - 两边中的任意一边可以被选为“many” side(extra attribute can be added to either one)
  - 当 participation is partial，没有参与关系的置为 null
- Composite and Multivalued Attributes（如 @attr）
  - Composite Attributes
    - Creating a separate attribute for each component attribute（展开，flatten）
    - 丢失了部分信息（属性间的继承关系）
  - Multivalued Attributes
    - A multivalued attribute $M$ of an entity $E$ is represented by separate schemas $E, M$（原表的主键和多值属性）
    - 增添了一个新表，略冗余
  - 从这里也可以看出关系数据库的局限性，后面我们会介绍关系数据库的面向对象拓展—— inherit 和仅在这提了一嘴的 method（如 `age()`）
  - Special Case of Multivalued Attributes:
    - 实体集除了主键外只有一个属性，且这个属性是多值的。按照之前的规则，这个多值需要被拆分出去，留下只有一个属性的实体集，思考这种情况下原实体集是否有保留的必要？
    #fig("/public/assets/Courses/DB/img-2024-04-01-15-10-43.png", width: 60%)

=== Design Issues
- Common Mistakes in E-R Diagrams
  - 属性冗余
  - 关系集中的同一条关系有多个实例
- Use of entity sets $v.s.$ attributes & Use of entity sets $v.s.$ relationship sets
  - 把 relationship set 或其属性实体化成 entity set 增强了表达能力
- Placement of relationship attributes
  - relationship set 之所以要设置 attributes 是有原因的，同样的 attribute 放在 entity set 和 relationship set 中表达不同的含义
- Binary Vs. Non-Binary Relationships & Converting Non-Binary Relationships to Binary Form
  - 有时 n-ary 更清楚，有时 2-ary 更适合，具体情况具体分析
  - n-ary 到 2-ary 的转化：
  #fig("/public/assets/Courses/DB/img-2024-04-01-21-00-28.png")

=== Extended ER Features
- 吸收面向对象的思想: Specialization / Generalization
- 可以参照 “第四章*面向对象数据库*” 体会更多 DB 吸收的 OOP 特性
- 吸收面向对象的思想: Specialization / Generalization
- Generalization 泛化
  - 自底向上的设计过程
  - 从下往上，下层的内容合成上层的内容
- Specialization 特殊化
  - 自顶向下的设计过程
  - Attribute inheritance: overlapping, disjoint
  - Completeness constraint（完全性约束）: total, partial
  - 画图的方式就是从上往下画，Entity 的内容逐渐细分，然后考虑如何继承上一阶的 attribute
  #fig("/public/assets/Courses/DB/img-2024-04-01-15-42-03.png", width: 60%)
- Representing Specialization via Schemas（三种方式）
  + 把 higher-level 的 primary key 拿过来，和本地的 attributes 组成 schema
    #tbl(
      stroke: none,
      columns: 2,
      align: left,
      [schema],
      table.vline(),
      [attributes],
      table.hline(),
      [person],
      [ID, name, street, city],
      [student],
      [ID, tot_credits],
      [employee],
      [ID, salary],
    )
  + 把 higher-level 整个拿过来，和本地的 attributes 组成 schema
    #tbl(
      stroke: none,
      columns: 2,
      align: left,
      [schema],
      table.vline(),
      [attributes],
      table.hline(),
      [person],
      [ID, name, street, city],
      [student],
      [ID, name, street, city, tot_credits],
      [employee],
      [ID, name, street, city, salary],
    )
  + 用单个 schema 表示所有 entity sets，新加一个 attribute 用以标识
    #tbl(
      stroke: none,
      columns: 2,
      align: left,
      [schema],
      table.vline(),
      [attributes],
      table.hline(),
      [person],
      [ID, name, street, city, #redt[person_type], tot_cred, salary],
    )

=== UML
- 参见 “第四部分*半结构数据*”

== 关系数据库设计
=== 数据库设计的目标
- When reduce to relational schemas, there are several pitfalls
+ Information repetition (信息重复)
+ Insertion anomalies (插入异常)
+ Update difficulty (更新困难)
- 我们通过各种范式(normal form)来实现好的设计方式
  - 一般来说我们希望将大的关系模式分解
- Normal Forms(NF)的演进: 1NF $->$ 2NF $->$ 3NF $->$ *BCNF(3NF)* $->$ 4NF
  - 我们将会重点讨论 *BCNF*和 *3NF*
- Our theory is based on:
  - functional dependencies
  - multivalued dependencies

=== Decomposition
- 分解(decomposition)分为 lossy-join decomposition & lossless-join decomposition
  - Lossy Decomposition 有损分解：不能用分解后的几个关系重建原本的关系
#definition(title: "Lossless join 无损分解的定义")[
  - R 被分解为 (R_1, R_2) 并且$R=R_1 union R_2$
  - 对于任何关系模式 R 上的关系 r 有 $r=Pi_(R_1)(r) join Pi_(R_2)(r)$
  - 同时，lossless join 要求下列至少一项成立（至少有一项在 $R_1 sect R_2$ 的闭包中）
  $
  R_1 sect R_2 -> R_1 "(共同属性决定R1)"\
  R_1 sect R_2 -> R_2 "(共同属性决定R2)"
  $
]
- 注意 $r subset Pi_(R_1)(r) join Pi_(R_2)(r)$ 是有损分解（看起来信息变多了，实际上反而引入不确定性）

=== Functional dependency 函数依赖
#definition(title: [函数依赖的定义])[
  - 对关系模式 $R$，如果 $alpha subset R, beta subset R$，则函数依赖 $alpha  -> beta$ 定义在 $R$ 上，当且仅当：
    - 如果对于 $R$ 的任意关系 $r(R)$，当其中的任意两个元组 $t_1$ 和 $t_2$，如果他们的 $alpha$ 属性值相同可以推出他们的 $ beta$ 属性值也相同（函数的 x 定了，那么 y 也就定了）
  - 如果某个属性集 $A$ 可以*决定*另一个属性集 $B$ 的值，就称$A -> B$ 是一个函数依赖
]
- 函数依赖和键的关系：函数依赖实际上是键的概念的一种泛化（推广）
  - K是关系模式R的*超键*(super key)当且仅当 $K -> R$
  - K 是R上的*候选主键*(candidate key)当且仅当 $K -> R$ 并且不存在 $alpha subset.neq K,  alpha -> R$
- 平凡(trivial)的函数依赖：$alpha -> beta "and" beta subset.eq alpha$，它并不包含有用的信息，一般来说我们在讨论函数依赖时可以默认不考虑这种情形

=== 闭包
#definition(title: "Closure（闭包）")[
  - 函数依赖 $F$ 的闭包，原始的函数依赖集合 $F$ 可以推出的所有函数依赖关系的集合就是*$F$ 的闭包*，用 $F^+$ 表示
    - 例如，$A -> B, B -> C, "then" A -> C$，它们都包含在 $F^+$ 中，此外还有 $A B -> B "(平凡)", A B -> C "等"$
  - 属性集的闭包
    - 闭包中所有函数依赖于 $alpha$ 的属性集构成的集合，即若 $(alpha -> beta) in F^+$，则 $ beta in alpha^+$
]
- 函数依赖的性质
  + reflexity（自反律）：$alpha$ 的子集一定关于$alpha$函数依赖
  + augmentation（增补律）：如果$alpha -> beta$ 则有$ lambda alpha ->  lambda beta$
  + transitivity（传递律）：如果$a -> beta and beta -> gamma$ 则有$a -> gamma$
  - 这三条构成函数依赖的公理系统，确保其 sound（正确有效） and complete（完备）
  + union（合并）：如果$alpha -> beta and alpha -> gamma$ 则有$alpha -> beta gamma$
  + decomposition（分解）：如果$alpha -> beta gamma$ 则有$alpha -> beta and alpha -> gamma$
  + pseudotransitivity（伪传递）：如果$alpha -> beta and beta gamma -> delta$ 则有$alpha gamma -> delta$
  - 这三条是由前三条推导出来的 additional rules
- 计算闭包的方法
  - 两种闭包的计算差不多是一回事
  - 根据初始的函数依赖关系集合 $F$ 和函数依赖的性质，计算出所有的函数依赖构成闭包（纸面公式推导）
  - 通过特定算法推导（机器）
  - 对人类而言，画个*有向图*表示属性之间的关系，通过图写出所有的函数依赖是最快的
- 属性集闭包的作用
  - 测试是否为超键：如果 $alpha$ 的闭包包含了所有属性$(alpha^+ -> R)$，则 $alpha$ 就是超键
  - 测试函数依赖存在性：为了验证 $alpha -> beta$ 是否存在，只需要验证 $beta$ 是否在 $alpha$ 的闭包中
  - 计算 $F^+$：通过每个属性的闭包可以得到整个关系模式的闭包
=== Canonical Cover 正则覆盖
- 为了定义正则覆盖，首先定义无关属性
#definition(title: "Extraneous Attributes（无关属性）")[
  - 定义：对于函数依赖集合F中的一个函数依赖$alpha -> beta$
    - $alpha$ 中的属性 $A$ 是多余的，如果 $F$ 逻辑上可以推出$(F- {alpha -> beta}) union {(alpha-A) -> beta}$
    - $beta$ 中的属性 $B$ 是多余的，如果$(F-{alpha -> beta}) union {alpha -> (beta-B) }$ 逻辑上可以推出 $F$
      - 更强的函数逻辑上可以推导出更弱的函数
]
- 判断$alpha -> beta$中的一个属性是不是多余的（理论上）
  - 测试 $alpha$ 中的属性 $A$ 是否为多余的
    - 计算$(alpha-A)^+$，检查结果中是否包含 $beta$，如果有就说明 $A$ 是多余的
  - 测试 $beta$ 中的属性 $B$ 是否为多余的
    - 只用$(F- { alpha -> beta }) union { alpha ->( beta-B)}$中有的依赖关系计算$alpha^+$，如果结果包含 B，就说明 B 是多余的
#definition(title: "Canonical Cover（正则覆盖）")[
  - 跟闭包相对，正则覆盖（最小覆盖）是等价的最小的函数依赖集合（也就是没有冗余，和 $F$ 等价可以推导出 $F^+$ 的关系集合），记作 $F_c$
  - 最小覆盖$F_c$的定义
    - 和 $F$ 可以互相从逻辑上推导，并且最小覆盖中没有多余的信息
    - 最小覆盖中的每个函数依赖中左边的内容都是 unique 的
]
- 如何计算最小覆盖（理论上）
  - 先令 $F_c = F$
  - 用 Union rule 将 $F_c$ 中所有满足$alpha -> beta_1  and  alpha -> beta_2$的函数依赖替换为$alpha -> beta_1 beta_2$
  - 找到 $F_c$ 中的一个函数依赖去掉里面重复的属性
  - 重复 2，3 两个步骤直到 $F_c$ 不再变化
- 而实际上，对人类而言，判断属性多余和计算最小覆盖都可以像之前那样画一个有向图来快速解决

=== BCNF
#definition(title: "BCNF(Boyee-Codd Normal Form)")[
  - BC范式的条件是：闭包$F^+$中的所有函数依赖$alpha  -> beta$ 至少满足下面的一条
    - $alpha -> beta$ 是平凡的(也就是β是α的子集)
    - $alpha$ 是关系模式R的一个*超键*，即$alpha  -> R$
  - 换句话说，如果一个函数依赖是非平凡的，那么它左边的属性集一定是个 key
]
- 如何验证 BCNF：
  - 检测一个非平凡的函数依赖 $alpha -> beta$ 是否违背了 BCNF 的原则
    - 计算 $alpha$ 的属性闭包
    - 如果这个属性闭包包含了所有的元素，那么 $alpha$ 就是一个*超键*
    - 如果 $alpha$ 不是超键而这个函数依赖又不平凡，就打破了 BCNF 的原则
  - 简化的检测方法：
    - 只需要看关系模式 $R$ 和已经给定的函数依赖集合*F中的各个函数依赖*是否满足 BCNF 的原则
      - 不需要检查 F 闭包中所有的函数独立
    - 可以证明如果 F 中没有违背 BCNF 原则的函数依赖，那么 F 的闭包中也没有
    - 这个方法不能用于检测 R 的分解
- BCNF 分解
#algo(caption: "BCNF的分解算法伪代码")[
  ```typ
  result={$R$};
  done=false;
  compute $F^+$ by $F$
  while (!done) do
      if exist $R_i$ in result that is not a BCNF
      then begin
          let $alpha -> beta$ be a non-trivial function dependency holds on $R_i$ such that $a->R_i in.not F^+$ and $(alpha and beta)$=$emptyset$;
          $"result"=("result"-R_i) union (R_i-beta) union (alpha,beta)$;
          end
      else
          done=true
      end
  end
  ```
]
- 例如下图中，$A->B$ 满足 BCNF 但 $B->C D$ 不满足
  #fig("/public/assets/Courses/DB/img-2024-06-17-11-43-46.png",width:75%)
- 当我们对关系模式 $R$ 进行分解的时候，我们的目标是
  - 没有冗余，每个关系都是一个 BCNF
  - 无损分解
  - 可能会想要：独立性保护
- Denpendency preservation 独立性保护，把 R 和 F 的闭包按照关系的对应进行划分
  - 用 $F_i$ 表示只包含在 $R_i$ 中出现的元素的函数依赖构成的集合
  - 我们希望的结果是 $(F_1 union F_2 union dots union F_n)^+=F^+$，也就是——重视每一条函数依赖
  - 上述 BCNF 分解算法保证无损性，但是不保证独立性保护，为此放宽限制使用 3NF
    - BCNF 一定是 3NF
=== Third normal form 第三范式
#definition(title: "第三范式的定义")[对于函数依赖的闭包$F^+$中的所有函数依赖$alpha -> beta$ 下面三条至少满足一条
  - $alpha -> beta$ 是平凡的
  - $alpha$是关系模式 $R$ 的超键
  - \* $beta - alpha$ 中的每一个属性 $A$ 都包含在 $R$ 的一个候选主键(candidate key)中
]
- 3NF有冗余，某些情况需要设置一些空值
- 3NF的判定
  - 不需要判断闭包中的所有函数依赖，只需要对已有的 F 中的所有函数依赖进行判断
  - 用闭包可以检查 $alpha -> beta$ 中的 $alpha$ 是不是超键
  - 如果不是，就需要检查 $beta$ 中的每一个属性包含在R的候选键中
- 3NF decomposition algorithm
  - 简单来说就是先算 $F_c$作为分解，然后加入 candidate key，最后可选地删除冗余
#algo(caption: "3NF的分解算法伪代码")[
  ```typ
  Let $F_c$ be a canonical cover for $F$;
  $i$ = 0;
  for each functional dependency $alpha -> beta$ in $F_c$ do
      $i = i + 1$; $R_i = alpha beta$
  end
  if none of the schemas $R_j, 1 =< j =< i$ contains a candidate key for $R$
  then
      $i = i + 1$;
      $R_i$ = any candidate key for $R$;
  end
  repeat #comment[Optionally, remove redundant relations]
      if any schema $R_j$ is contained in another schema $R_k$
      then /* delete $R_j$ */
          $R_j = R_i$; $i=i-1$;
      end
  end
  until no more $R_j$ s can be deleted
  return ($R_1, R_2, ..., R_i$)
  ```
]

- ER modeling and Normal Forms
  - 一个例子
  #fig("/public/assets/Courses/DB/img-2024-04-08-20-19-08.png", width: 70%)
  - 由此也可以得到之前说的三元关系需要转化成三个表的结论
- 思考，是否 schemas in BCNF or 3NF 已经足够好了？考虑下面的例子
  $ "inst_info"(underline("ID"), underline("child_name"), underline("phone")) $
  - 它是一个 BCNF，但是当我们为某个 ID 插入一个 phone_number 时，需要多一个 child_name 的信息(Insertion anomalies)
  - 这引出 *multivalued dependencies* 和 *fourth normal form*
=== Multivalued denpendency
#definition(title: "Multivalued dependency")[
  - 对关系模式 $R$，如果 $alpha subset R, beta subset R$，则函数依赖 $alpha ->-> beta$ 定义在 $R$ 上，当且仅当它们满足表格所显示关系
  #tbl(
    columns: 4,
    stroke: none,
    table.hline(start: 1),
    table.vline(start: 1),
    [],
    table.vline(),
    [$alpha$],
    table.vline(),
    [$beta$],
    table.vline(),
    [$R-alpha-beta$],
    table.vline(),
    table.hline(),
    [$t_1$],
    [$a_1$],
    [$beta_1$],
    [$gamma_1$],
    [$t_2$],
    [$a_1$],
    [$beta_2$],
    [$gamma_2$],
    table.hline(),
    [$t_3$],
    [$a_1$],
    [$beta_1$],
    [$gamma_2$],
    [$t_4$],
    [$a_1$],
    [$beta_2$],
    [$gamma_1$],
    table.hline(),
  )
]
- 两个性质
  + 考虑仅含三属性的集合 $a, b, c$，$a->->b <=> a->->c$
  + If $a -> b$, then $a ->-> b$（称函数依赖是多值依赖的特殊形式）
- 类似之前函数依赖的 $F$，我们定义 $D$ 表示多值依赖集，定义 $D^+$ 表示所有 $D$ 逻辑蕴含的*函数依赖*和*多值依赖*
- 类似 BCNF，定义 *Fourth Normal Form* 为
  - 每个 $alpha ->-> beta$ 是平凡的($beta subset.eq alpha$ or $alpha union beta = R$)；或者 $alpha$ 是超键
  - 4NF 是 BCNF 的窄化，它一定会是 BCNF（？）
  - 4NF 分解算法和 BCNF 分解算法几乎一模一样，不赘述
- 一个例子
#fig("/public/assets/Courses/DB/img-2024-04-15-14-58-13.png")
- Denormalization for Performance：有时候我们需要引入冗余，来保持性能。
  #fig("/public/assets/Courses/DB/img-2024-04-08-21-44-45.png", width: 80%)
- 简单做个归纳（其中 1NF 和 2NF 课上没有强调）
  - 这四者是层层递进，层层归属的关系）
#tbl(
  columns: 2,
  [1NF],
  [消除多值属性],
  [2NF],
  [非主属性完全函数依赖于候选键（候选键决定 $R$）],
  [3NF],
  [消除非主属性对候选键的*传递*函数依赖（候选键*直接*决定 $R$）],
  [BCNF],
  [消除主属性对候选键的*传递*函数依赖和*部分*函数依赖],
  [4NF],
  [消除非平凡且非函数依赖的多值依赖],
)

