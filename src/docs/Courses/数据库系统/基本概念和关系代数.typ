---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#info()[
  1. 在 #link("https://github.com/Zhang-Each/CourseNoteOfZJUSE/tree/master/DBS%E6%95%B0%E6%8D%AE%E5%BA%93%E7%B3%BB%E7%BB%9F")[Zhang Each's GitHub repo] 前辈笔记的基础上重写
  2. 加入了 #link("https://note.hobbitqia.cc/DB")[hobbitqia 的笔记] 的内容和自己上课的理解
]

#let null = math.op("null")
#let Unknown = math.op("Unknown")

= 第一部分：基本概念和关系代数
== 课程绪论
- 数据库系统的概念
  - 数据库(Database)是某一机构的相关数据的集合，由数据库管理系统 DBMS(Database Management System)来管理
- 数据库系统的应用
- 从 University Database 的例子来看
  - 数据库的数据结构有很多，这门课主要用*关系型*数据库，以*表格*的形式呈现
  - 操作：插入、查询、链接等
- 数据库系统的 Purpose
  - 从 file system 到 database system，解决了
    1. 数据冗余与不一致
    2. 数据孤立、数据孤岛（多文件与多格式）
    3. 存取数据困难
  - 完整性(integrity)问题：约束条件从隐藏在代码中变为显示的声明
  - 原子性(atomicity)问题：事件不可分割，要么做完要么不做。解决掉电等情况导致的数据不一致
  - 并发访问(concurrent access)异常
  - 安全性问题：认证(authentication)、权限(priviledge)、审计(audit)——对权利大的人进行监控
- 数据库系统的特点
  - data persistence, convenience in accessing data, ...
- 数据模型
  - 如何描述？Data(数据)、Data relationships(联系)、Data semantics(语义)、Data constraints(约束)
  - *Relational model*(关系模型，这门课的重点)
    - 提出者：Edgar F. Codd，获 1981 年图灵奖
    - 用 columns / Attributes 与 rows / Tuples 来描述
  - *Object-based* data models: Object-oriented(面向对象数据模型)、Object-relational(对象-关系模型模型)
  - *Semistructured* data model(半结构化数据模型)，XML 是一种专门描述这种模型的语言
  - Other older models: Network model(网状模型)、Hierarchical model(层次模型)
  - *Entity-Relationship* model(实体-联系模型)，跟上面的模型不是对等的关系，主要是用于描述数据库
- View of Data
  - 用三级抽象来看待数据库，view level、logical level、physical level，三级抽象之间相对独立
    - view level: view schema，用户看到的数据视图
    - logical level: logical schema，数据库的逻辑结构
    - physical level: physical schema，数据库的物理结构
  - 好处：隐藏复杂度、增强适应变化的能力
- Data Independence
  - 逻辑数据独立性：改变逻辑模式不影响应用程序
  - 物理数据独立性：改变物理存储结构不影响应用程序
- Database Languages
  - 数据定义语言 DDL(Data Definition Language)：定义数据库的逻辑结构
  - 数据操纵语言 DML(Data Manipulation Language)：查询、插入、删除、更新
  - SQL Query Language
  - Application Program Interface(API)，应用层面
- DDL
  - C 语言的定义实际上是用二进制来表示，而数据的定义还是用数据：metadata（元数据，i.e., data about data）
  - DDL 编译器产生数据字典(data dictionary)，存储在数据库中
- DML
  - DML 也被称为 query language
    - SQL 是最广泛使用的 query language
  - 两种语言类型：procedural(过程式)、declarative(nonprocedural，陈述式，非过程式)
    - DML 是 declarative 的
- SQL Query Language
  - 举一个例子
- Database Access from Application Program
  - SQL 和用户实际使用之间还隔了一层交互，这些交互是用 *host language*（宿主语言）写的
  - 通常我们用两种方式
    1. API(Application program interface) (e.g. ODBC/JDBC)
    2. 支持 embedded SQL 的语言插件
- 数据库设计
  - 实体联系模型
  - 规范化理论
- 数据库引擎(Database Engine)
  - 学术一点的叫法是 database system，可以被分为: storage manager, query processor, transaction（事务） management
- History
  - 图灵奖得主：Charles W. Bachman, Edgar F. Codd, Jim Gray, Michael Stonebraker

== 关系型数据库 Relational Database

=== 关系型数据的一些基本特点
- 关系型数据库是一系列*表的集合*
- 一张表是一个基本单位
- 表中的一行表示一条关系

== 基本概念和结构
- A relation $r$ is a subset of $D_1 times D_2 times dots times D_n$，一条 relation 就是其中的一种 $m$ 个 $n$ 元*元组(tuple)* 的集合（注意这里的表述，relation 中的一个元素，即表中的一行，才是一个元组）
- attribute 属性，指表中的*列名*
  - attribution type 属性的类型
  - attribute value 属性值，某个属性在某条 relation 中的值
    - 关系型数据库中的属性值必须要是 atomic 的，即不可分割的
    - domain：属性值的值域，null 是所有属性的 domain 中都有的元素，但是 null 值的处理是一个问题
- Relation Schema 关系模式
  - $R=(A_1, A_2, dots, A_n)$ 是一种关系模式，其中 $A_i$ 是一系列属性，关系模式是对关系的一种*抽象*
  - $r(R)$ 表示关系模式 $R$ 中的一种关系，table 表示了这个关系当前的值(关系实例)
    - 不过经常用相同的名字命名关系模式和关系
    - 每个关系 $r$ 中的元素 $t$ 被称为 tuple，是 table 中的一行
  - 关系是*无序*的，关系中行和列的顺序是 irrelevant 的
- Database Schema
  - Database Schema 是数据库的逻辑模式
  - Database instance 是数据库的实例(snapshot)

== Keys键
- 超键(super key)：能够*唯一标识*每个可能 $r(R)$ 的某一元组的属性集，即对于每一条关系而言超键的值是唯一的
  - 超键可以是多个属性的组合
  - 如果 $A$ 是关系 $R $的一个超键，那么 $(A, B)$ 也是关系 $R$ 的一个超键，即超键的“唯一标识”各个元组是可以有冗余信息的
- 候选键(candidate key)：*不含多余属性*(minimal)的超键
  - 如果 $K$ 是 $R$ 的一个超键，而任何 $K$ 的真子集不是 $R$ 的一个超键，那么 $K$ 就是 $R$ 的一个候选键
- 主键(primary key)：
  - 数据库管理员*从候选键中指定*的元组标识，不能是 $null$ 值
- 外键(foreign key)：用来描述两个表之间的关系
  - 如果关系模式 $R_1$ 中的一个属性是另一个关系模式 $R_2$ 中的一个*主键*，那么这个属性就是 $R_1$ 的一个外键
    - 关系 $r_1$ 引用的主键必须在关系 $r_2$ 中出现。
- Referential integrity (参照完整性)
  - 类似于外键限制，但不局限于主键。
  - 外键与参照完整性的例子
#fig("/public/assets/Courses/DB/img-2024-03-05-22-34-29.png", width: 90%)

== Relational algebra 关系代数
=== 基本运算
- *选择(select)*：$sigma_p (r)={t mid(|)t in r and p(t) }$，筛选出所有满足条件 $p(t)$ 的元素 $t$
  - 这里 $p(t)$ 称为*谓词*
- *投影(project)*：$Pi_(A_1, A_2, dots, A_k)(r)$
  - 运算的结果是原来的关系 $r$ 中各列只保留属性 $A_1, A_2, dots, A_k$ 后的关系
  - 会*自动去掉重复*的元素，因为可能投影的时候舍弃的属性是可以标识关系唯一性的属性
- *并(union)*：$r union s={t mid(|) t in r or t in s}$
  - 两个关系的属性个数必须相同
  - 各属性的 domain 必须是可以比较大小的(compatible)
  #fig("/public/assets/Courses/DB/img-2024-06-10-21-43-21.png",width: 50%)
- *集合差(set difference)*：$r-s={t mid(|) t in r and t in.not s}$
  - 各属性的 domain 必须是可以比较大小的(compatible)
- *笛卡尔积(cartesian-Piuct)*：$r times s={t q | t in r and q in s}$
  - 两个关系如果相交，则需要加上关系名作为前缀区分；进一步地，如果关系名重复（比如 $"self" times "self"$），则需要利用重命名操作
  - 笛卡尔积运算的结果关系中元组的个数应该是 $r, s$ 的个数之乘积
- *重命名(renaming)*：$rho_X (E)$
  - 将 $E$ 重命名为 $x$, 让一个关系拥有多个别名，同时 $X$ 可以写为 $X(A_1, A_2, dots, A_n)$ 表示对属性也进行重命名
  - 类似于 C++ 中的引用

=== 扩展运算: 可以用前面的六种基本运算得到
- *交(intersection)*：$r inter s={t mid(|) t in r and t in s}=r-(r-s)$
- *自然连接(natual-Join)*：$r join s$
  - 两个关系中同名属性在自然连接的时候当作*同一个属性*来处理
  - 相当于是对笛卡尔积的扩展，允许两个关系有同名属性，并且同名属性的值相同才会保留（先 $times$ 再 select）
    - 如果两个关系交集为空，则等同于*笛卡尔积*（没有等于全真）
  - *条件链接(Theta join)*：满足某种条件的合并：$r join_theta s=sigma_theta (r times s)$
    - 虽然写在自然连接这部分，但感觉与其说它是自然连接的变种，不如说它和自然连接一样都是笛卡尔积的扩展，只是方向不一样。
    - Theta join 需要首先满足笛卡尔积的条件，然后再选取满足 $theta$ 的行
- *外部连接(outer-Join)*，分为左外连接，右外连接，全外连接
  - 用于应对一些*信息缺失*的情况(有 null 值)
  - 左外连接 $join.l$
    - 右边的表取全部值按照关系和左边连接，左边不存在时为空值
    - $r join.l s=(r join s) union (r- Pi_R (r join s) times {(null, dots, null)})$
  - 右外连接 $join.r$
    - 左边的表取全部值按照关系和右边连接，右边不存在时为空值
    - $r join.r s=(r join s) union {(null, dots, null)} times (s-(Pi_S (r join s))$
  - 全外连接(full outer join) 左右全上，不存在对应的就写成空值
$
r join.l.r s = (r join s) union \
(r-Pi_R (r join s) times {(null, dots, null)}) union \
({(null, dots, null)} times (s-(Pi_S (r join s)))
$
- *半连接(semijoin)*：$r ⋉_theta s=Pi_R (r join_theta s)$
  - 保留 $r$ 中能够和 $s$ 中的元素条件连接的元素，相当于做个筛选（不取 $r_2$ 的自然连接）
- *除法(division)*：$r div s={t mid(|) t in Pi_(R-S)(r) and forall u in s (t u in r)}$
  - 如果$R=(A_1, A_2, dots, A_m, B_1, dots, B_n) and S=(B_1, dots, B_n)$ 则有$R- S=(A_1, A_2, dots, A_m)$
  #fig("/public/assets/Courses/DB/img-2024-06-10-21-17-43.png",width:50%)
- *声明操作(assignment)*，类似于变量命名，用 $arrow.l$ 可以把一个关系代数操作进行命名
- *聚合操作(aggregation operations)*
  - 基本形式：$attach(cal(G), bl: G_1\, G_2\, dots\, G_n, br: F_1(A_1)\, dots\, F_n(A_n))(E)$
  - $G$ 是聚合的标准，对于关系中所有 $G$ 值相同的元素进行聚合，$F()$ 是聚合的运算函数
  - 常见的有 SUM / MAX / MIN / AVG / COUNT
  #fig("/public/assets/Courses/DB/img-2024-06-10-21-18-27.png",width:50%)

#v(0.5em)

- *Multiset* 关系代数
  - 关系代数中，我们要求关系要是一个严格的集合。但实际数据库中并不是，而是一个多重集，允许有重复元素存在。
  - 因为一些操作的中间结果会带来重复元素，要保持集合特性开销很大，因此实际操作中不会去重。

== SQL and Relational Algebra
- ```sql select A1, A2, ... An from r_1, r_2, ... rm where P``` 等价于 $Pi_(A_1, A_2, dots, A_k)(sigma_p (r_1 times r_2 times dots times r_m))$
- ```sql select A1, A2, sum(A3) from r_1, r_2, ... rm where P group by A1, A2``` 等价于 $attach(cal(G), bl: (A_1, A_2), br: "sum"(A_3))(r_1 times r_2 times dots times r_m)$
  - 这里按 $A_1, A_2$ 分组，那么结果的表中会有 $A_1, A_2, "sum"(A_3)$ 三列（分组依据+分组后的聚合结果），这里我们需要的就是这三列，所以分组即可。但是假设我们只需要 $A_1, "sum"(A_3)$，那么最后还需要投影。

