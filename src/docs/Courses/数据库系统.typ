#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#info()[
  1. Rearranged based on #link("https://github.com/Zhang-Each/CourseNoteOfZJUSE/tree/master/DBS%E6%95%B0%E6%8D%AE%E5%BA%93%E7%B3%BB%E7%BB%9F")[Zhang Each's GitHub repository]
  2. 加入了#link("https://note.hobbitqia.cc/DB")[大 Q 老师笔记]的内容和自己上课的理解
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
    1. API(Application program interface) (e.g., ODBC/JDBC)
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
- *交(intersection)*：$r sect s={t mid(|) t in r and t in s}=r-(r-s)$
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

= 第二部分：SQL

== Introduction to SQL
- *SQL：结构化查询语言*，分为 DDL, DML, DCL 几种类型，用的比较多的标准是 SQL-92
- *非过程式，声明式*的语言

=== SQL 创建，更新，删除
- *DDL(Data Definition Language)* 允许确定这些关系：*schema* for each relation、*domain* of values、integrity constraints、other information such as indices, Security and authorization, physical storage structure.
- SQL 支持的数据类型
  - char(n), varchar(n), int, smallint, numeric(p,d), null-value, date, time, timestamp
  - char, varchar 分别是字符串和可变字符串；numeric(p,d) 是精度为 p，小数点后 d 位的科学计数法数字
  - *Built-in* Data Types: date, time, timestamp, interval
  - 所有的数据类型都支持 null 作为属性值，可以在定义的时候声明一个属性的值 not null
- 创建数据表 create table
  - 创建表的语法
```sql
create table table_name(
    variable_name1 type_name1,
    variable_name2 type_name2,
    (integrity-contraints)
    ...,)
```
- 例如：
```sql
create table instructor (
    ID        char(5),
    name      varchar(20) not null,
    dept_name varchar(20),
    salary    numeric(8,2),
    primary key (ID),
    foreign key (dept_name) references department);
```
- `integrity-contraint` 完整性约束：可以指定 *primary key*, *foreign key xxx references yyy, not null*
  - foreign key detail: `foreign key (dept_name) references department)`，后面再加 `on delete cascade |set null |restrict |set default` 或 `on update cascade |set null |restrict |set default`。

- 删除数据表 `drop table` 或 `delete from table`，前者是整个 schema 都删了，后者只是删除所有行
- 更新数据表的栏目 `alter table`
  - `alter table R add A D` 添加一条新属性，其中 $A$ 是属性名，$D$ 是 $A$ 的 domain，其中的 relations 默认填充 null
  - `alter table R drop A` 删除 $A$ 属性

=== SQL查询

- 事实上的最重要 SQL 语句，考试考的一般都是查询语句

==== select 语句
- SQL 查询的基本形式：select 语句
```sql
select A1, A2, sum(A3)
from R_1, r_2, ..., rm
where P
group by A1, A2
```
- 上述查询等价于 $attach(cal(G), bl: A_1\, A_2, br: "sum"(A_3)) (sigma_p (r_1 times r_2 times dots times r_m))$
- SQL查询的结果是一个关系
- ```sql select * from xxx``` 表示获取*所有属性*，事实上我怀疑 \* 是正则表达式，表示可能有的所有内容，从后面的内容来看，select 语句确实是支持正则表达式
- SQL 中的*保留字*对于*大小写不敏感*
- 去除重复：```sql select distinct```，对应的保留所有就是 ```sql select all```
- select子句中的表达式支持基本的*四则运算*(加减乘除)，比如
```sql
select ID, name, salary / 2
from instructor;
```
- 重命名操作，可以通过 ```sql old_name as new_name``` 进行重命名；后面 from 子句也可以用 as 重命名
  - 关键字 `as` 是可选的，```sql instructor as T ≡ instructor T```。特别地，在 oracle 中 must be omitted

==== where 子句
- 支持 `and or not` 等*逻辑运算*
- 支持 `between and` 来*查询范围*（实际上可以用一个 and 和两个条件代替）
- 支持*元组比较*：```sql where (instructor.ID, dept_name) = (teaches.ID, "Biology");```
- 字符串支持*正则表达式*匹配，用`like regrex`的方式可以进行属性值的正则表达式匹配
  - 正则表达式的用法没怎么讲
```sql
select name
from teacher
where name like '%hihci%';
```

==== from 子句：
- from 可以选择多个表，此时会先将这些表进行*笛卡尔积*的运算（也可以显式指定为 *natural join* 等），再进行 select
- 元组变量：可以从多个表中 select 满足一定条件的几个不同属性值的元组
```sql
select instructor.name as teacher-name, course.title as course-title
from instructor, teaches, course
where instructor.ID = teaches.ID and
    teaches.course_id = course.course_id and
    instructor.dept_name = 'Art';
```
- Natural Join 的例子
  ```
  course(course_id,title, dept_name, credits)
  teaches(ID, course_id, sec_id,semester, year)
  instructor(ID,name, dept_name, salary)
  ```
  - 注意到 dept_name 在 course 和 instructor 中可能有细微的不同。
  - 下面第一个为 Incorrect version (makes `course.dept_name = instructor.dept_name`)
```sql
select name, title # incorrect
from instructor natural join teaches natural join course;

select name, title # correct
from instructor natural join teaches, course
where teaches.course_id = course.course_id;

select name, title # correct
from (instructor natural join teaches）join course using(course_id);

select name, title # correct
from instructor，teaches, course
where instructor.ID=teaches.ID and teaches.course_id =course.course_id;
```
==== Order by 子句与 Limit 子句
- Order by 将输出的结果排序
  - ```sql order by attribute_name (desc)```，默认是升序，可以加上 desc 来表示降序
  - 可以对 multiple attributes 排序，主序、次序、$dots$
- `limit offset, row_count`，offset 不指定则默认为 0
- List names of instructors whose salary is among top 3
```sql
select name
from instructor
order by salary desc
limit 3； # limit 0,3
```

==== Duplicate 多重集
- 略过

==== 集合操作：
- 可以用 `union/intersect/except` 等集合运算来*连接两条不同的查询*
- 和查询不同，集合操作默认会自动去重，加 `all` 表示多重集
- 例子 union($union$)、intersect($sect$)、except($-$)
```sql
# Find courses that ran in Fall 2009 but not in Spring 2010
(select course_id from section where sem = "Fall" and year = 2009)
except
(select course_id from section where sem = "Spring" and year = 2010)
```

==== Null values 空值
- 属性值可以为 null，当然也可以在定义数据表的时候规定哪些元素不能为空
- 任何牵涉到 null 的算数表达式结果都为 null，如 $5 + null$ returns $null$
- 与 null 的比较操作会返回一个特殊的值 —— Unknown
- Unknown 和 true / false 之间的运算，根据逻辑操作是 AND、AND、NOT 来判断结果

==== 聚合操作(Aggregate Functions)：
- 支持的操作有 avg / min / max / sum / count，获取的是表中的统计量，如
```sql
select dept_name, avg(salary) as avg_salary
from instructor
group by dept_name;
```
#fig("/public/assets/Courses/DB/img-2024-03-11-14-56-08.png")
- 在 selelct 子句中，aggregate functions 外的属性#redt[必须出现在 group by 子句中]（因为聚合操作本质是根据聚合函数外的属性进行分组，然后统计聚合函数中的属性的值）
- 事实上SQL语句的聚合操作和关系代数中的聚合运算是完全对应的，关系代数中的聚合运算表达式 $attach(cal(G), bl: G_1\, G_2\, dots\, G_n, br: F_1(A_1)\, dots\, F_n(A_n)) (E)$ 对应的 SQL 语句是
```sql
select G1, G2, ..., Gn, F1(A1), ..., Fn(An)
from E
group by G1, G2, ..., Gn;
```
- *having 子句*：聚合操作的 SQL 语句书写可以在末尾用 `having xxx` 来表示一些需要聚合操作来获得的条件（这个条件甚至能带算数表达式），比如
  ```sql
  select dept_name, count (*) as cnt
  from instructor
  where salary >= 100000
  group by dept_name
  having count (*) > 10
  order by cnt;
  ```
  - 注意，having 和 where 的区别在于分组前后进行的筛选，因此常在 having 中使用聚合函数
  - from 表中，先 where 筛选，再 group by 分组，再 having 组筛选，select 某些属性，最后 order by 排序并 limit 输出
- null values 和 aggregates
  - 比如，sum 忽略 null 值；count 不统计 null 值

==== Nested Subquery 嵌套查询
- 例子引入：
  ```sql
  select distinct course_id
  from section
  where semester = "Fall" and year= 2009 and
      course_id in (select course_id
                    from section
                    where semester = "Spring" and year= 2010);
  ```
  - 这里老师提了一嘴，distinct 只能在最外围 select 中使用
- 对于查询
  ```sql
  select A1, A2, ..., An
  from r_1, r_2, ..., r_n
  where P
  ```
  - 其中的 A，r，P 都可以被替换为一个*子查询*
- scalar 子查询：用于单个值作为查询结果的时候
  - 如果返回多个值会报 runtime error，可以考虑下面的集合关系
```sql
select dept_name
from department
where budget = (select max(budget) from department)
```

===== 集合关系：
- `in/not in + subquery` 用来判断否些属性是否属于特定的集合中
```sql
  select distinct course_id
  from section
  where semester = "Fall" and year= 2009 and
                    course_id in (select course_id
                                  from section
                                  where semester = "Spring" and year= 2010);
```
- `some/any + subquery` 用于判断集合中是否存在满足条件的元组，用来判断存在性
```sql
select name
from instructor
where salary > some (select salary
                     from instructor
                     where dept_name = "Biology");
```
- `all + subquery` 可以用来筛选最值
```sql
select name
from instructor
where salary > all (select salary
                    from instructor
                    where dept_name = "Biology");
```
- `exists + subquery` 不为空时返回
```sql
# another way of “Find all courses in both Fall 2009 and Spring 2010”
select course_id
from section as S
where semester = "Fall" and year= 2009 and
                  exists (select *
                          from section as T
                          where semester = "Spring" and year= 2010
                          and S.course_id= T.course_id);
```
- `not exists + subquery` 为空时返回
  - 感觉更加常用，注意到 $X – Y = emptyset <=> X subset Y$
```sql
# Find all students who have taken all courses offered in the Biology department
select distinct S.ID, S.name
from student as S
where not exists ((select course_id  # 所有生物课
                  from course
                  where dept_name = "Biology")
                  except
                  (select T.course_id  # 某个学生上过的所有课
                  from takes as T
                  where S.ID = T.ID));
# Note: Cannot write this query using = all and its variants
# why?
```
- `unique` 判断是否唯一
  - 注意，空集也为 true，如果要判断存在且唯一，需要额外处理
```sql
# Find all courses that were offered at most once in 2009
select T.course_id
from course as T
where unique (select R.course_id
              from section as R
              where T.course_id= R.course_id
              and R.year = 2009);
# if exactly once, use the below
select T.course_id
from course as T
where unique (select R.course_id
              from section as R
              where T.course_id= R.course_id
              and R.year = 2009)
      and exists (select R.course_id
                  from section as R
                  where T.course_id= R.course_id
                  and R.year = 2009);
# Or another solution:
and course_id in (select course_id
                  from section
                  where year = 2009) ;
```

==== with 子句
- 对子查询定义一个变量名，可以在之后调用
  - 多个临时子查询用逗号分隔（写在一个 with 中）
```sql
with max_budget (value) as
    (select max(budget)
    from department)
select dept_name
from department, max_budget
where department.budget = max_budget.value;
```

=== SQL插入，删除，更新
- 删除：```sql delete from table_name where xxxxxx```
  - where 可以嵌入子查询，先子查询，再删除，也就是说下面这种情况不会边删边计算
```sql
delete from instructor
where salary< (select avg(salary) from instructor);
```
- 插入: ```sql insert into table_name values();```
  - 也可以指定 table 的列名，这种情况下，不一定要输入所有的列值，缺省的使用默认值或 null
  - 批量插入：可以用 select 查询子句得到的结果作为 values，此时可同时插入多条结果
  - 同样，先子查询，再插入，不会边插边查询
- 更新：`update table_name set xxx where xxxxx`
  ```sql
  update instructor
      set salary = salary * 1.03
      where salary > 100000;
  update instructor
      set salary = salary * 1.05
      where salary <= 100000;
  ```
  - The order is important, so can be done better using the case statement (when updating multiply)
  - case 子句：用于分类讨论
```sql
update instructor
    set salary = case
                      when salary <= 100000 then salary * 1.05
                      else salary * 1.03
                  end
```
== Intermediate SQL
=== Join 链接关系
#fig("/public/assets/Courses/DB/img-2024-03-18-13-41-44.png")
=== SQL 类型
- User-Defined Types: ```sql create type Dollars as numeric (12,2) final```
- Domains
  - `create domain new_name + data type`(比如 char(20))
  - Domain 与 User-Defined Types类似，但可以设置约束条件，比如下面这一段 domain 定义表示 degree_level 只能在这三个中进行选择
```sql
create domain degree_level varvhar(10)
constraint degree_level_test
check(value in ('Bacheors', 'Masters', 'Doctorate'));
```
- Large-Object Types 大对象类型，分为 blob(二进制大对象)和 clob(文本大对象)两种，当查询需要返回大对象类型的时候，取而代之的是一个代表大对象的指针

=== Integrity 完整性控制
==== 单个关系上的约束
- 主键 primary key, foreign key, *unique*, not null, check(P)
- check 子句：写在数据表的定义中，check(P) 检查某个属性是否为特定的一些值
  - ```sql check (semester in ("Fall", "Winter", "Spring", "Summer")```
  - ```sql check (time_slot_id in (select time_slot_id from time_slot))```，Complex Check Clauses，并没有被大多数 database 支持(alternative: triggers)
- Domain constraints 值域的约束
  - 在 domain 的定义中加入 check
  - 语法 ```sql create domain domain_name constraints check_name check(P)```
- *Referential Integrity* 引用完整性
  - 被引用表中主键和外键的关系
  - 其实 PPT 里这一段讲了半天就是在说要在定义表的时候定义主键和外键进行约束
- Integrity Constraint Violation During Transactions
  - 有时插入语句在执行时用到了之后才会知道的信息，这时候可以选择将其置为 $null$ 或置为空
  - 更好的方法是，只在事务结束的时候检查完整性约束
- Cascading action
  - on update
  - on delete

==== 对于整个数据库的约束
- Assertions：对于数据库中需要满足的关系的一种*预先判断*
  - `create assertion <assertion-name> check <predicate>` 下面是一段例子
```sql
create assertion credits_constaint check
(not exists(
    select *
    from student S
    where total_cred <> (
        select sum(credits)
        from takes nature join course
        where takes.ID = S.ID and grade is not null and grade <> 'F')
    )
)
```
- 可以想见这玩意儿的开销非常大，属于是乌托邦设想，因此 Mysql 不支持 assertions(alternative: triggers)

=== SQL view 视图
- 视图：一种*只显示数据表中部分属性值*的机制
  - 不会在数据库中重新定义一张新的表，而是隐藏了一些数据（定义了一张虚表）
  - 好处：隐藏数据，提高安全性；简化查询，提高效率
  - 创建视图的定义语句：```sql create view xxx as (query expression)```
    - xxx 是视图的名称，内容是从某个 table 中 select 出的
```sql
create view departments_total_salary(dept_name, total_salary) as
select dept_name, sum(salary)
from instructor
group by dept_name;
```
- 可以用 view 的信息定义新的 view
- view 如何起效？将 view 的定义嵌入到 SQL 语句中，再进行查询优化
- 可以通过 view 对实际的表进行更新、删除（像是从窗户向房子里扔石子）
  - 没有给定的值设置为 $null$
  - updatable views 条件：
    1. 创建时只使用了一张表的数据
    2. 插入的值要包含 primary key
    3. 创建时没有进行 distinct、表达式和聚合操作
    4. 没有出现的属性允许设置为 $null$
- \*Materializing a view: ```sql create materialized view xxx as (query expression)```
  - 物化 view 加快查询速度，但是会增加存储开销和*维护开销*，故一般用于不怎么修改但是频繁查询的数据表
- \*View and Logical Data Indepencence
  - 比如，将 $S(a, b, c)$ 拆分为 $S_1(a, b)$, $S_2(a, c)$，原本的 $S$ 用 view 实现，这样减小了表的大小，又不会干扰 API

=== index 索引
- 在对应的表和属性中建立索引，加快查询的速度
  - 索引的内部实现有很多，最常见的是创建 B+ 树
  - 是涉及到物理层面的一条语句
- 语法 `create index index_name on table_name(attribute)`
- 写了 index 后，查询语法上跟原先相同，但是内部实现有所不同

=== Transactions 事务
- SQL 中的每一条指令，包括(insert, delete, update, select)都是一个事务
- Transactions begin *implicitly*, ended by *commit work* or *rollback work*
- In MySQL, there is ```sql SET AUTOCOMMIT = 0```
- In SQL1999, there is ```sql begin transaction ... end```
  - Not supported on most databases
- 实际使用中需要考虑事务边界的问题，十分复杂

==== ACID Properties
- *Atomicity* 原子性：事务中的所有操作要么全部执行，要么全部不执行
- *Consistency* 一致性：事务执行前后，数据库的状态应该是一致的
- *Isolation* 隔离性：事务的执行不应该受到其他事务的干扰
- *Durability* 持久性：事务执行后，对数据库的改变应该是持久的

=== Authorization 授权
- 数据库中的四种权限 read,insert,update,delete
- Security specification in SQL 安全规范
  - grant 赋予权限
    - `grant <privilege list> on <relation name or view name> to <user list>`
    - `<user list>` 可以是用户名，也可以是 public(允许所有有效用户拥有这项权限)，也可以是后面的 role
    - 例如 ```sql grant update (budget) on department to U1, U2```
  - revoke 权力回收
    - ```sql revoke <privilege list> on <relation/view name> from <user list> [restrict|cascade]``` 从用户中回收权力
  - role 语句：允许一类用户持有相同的权限
    - ```sql create role role_name```
    - Roles can be granted to users, as well as to other roles, for example
      - ```sql grant teaching_assistant to instructor;``` Instructor 将会继承 teaching_assistant 的所有权限
- Authorization on *Views*
- *References Privilege* to create foreign key
- transfer of privileges
  - ```sql grant select on department to Amit with grant option```;
  - ```sql revoke select on department from Amit, Satoshi cascade```;
  - ```sql revoke select on department from Amit, Satoshi restrict```;
  - ```sql revoke grant option for select on department from Amit```

== Advanced SQL

=== Accessing SQL From a Programming Language
- 有两种方法从通用高级编程语言访问 SQL
  - API：通过 API 调用 SQL 语句
  - Embedded SQL：在编程语言中嵌入 SQL 语句
- 缩写解释
  - JDBC 是 Java Database Connectivity，是 Java 语言的 API
  - ODBC 是 Open Database Connectivity，是 C、Cpp、C\# 等语言的 API
  - Embedded SQL in C
  - SQLJ - embedded SQL in Java
  - JPA(Java Persistence API) - OR mapping of Java
==== Database and Java
- JDBC Code
```java
// Update to database
try {
  stmt.executeUpdate(
  "insert into instructor values("77987", "Kim", "Physics", 98000)");
} catch (SQLException sqle) {
  System.out.println("Could not insert tuple. " + sqle);
}
// Execute query and fetch and print results
ResultSet rset = stmt.executeQuery(
                "select dept_name, avg (salary)
                from instructor
                group by dept_name");
while (rset.next()) {
  System.out.println(rset.getString("dept_name") + " " + rset.getFloat(2));
}
```
- 一些细节
  - Getting result fields: ```java rset.getString("dept_name") and rset.getString(1)```
  - Dealing with Null values: ```java int a = rset.getInt("a");
if (rset.wasNull()) Systems.out.println("Got null value");```
- Prepared Statement
  - 一次性的语法分析、检查、优化
- SQL Injection(SQL 注入)
  - 一种攻击方式
  - 所以最好用 prepare 的方式
- Metadata Features
  - 得到 Metadata 信息
- Transaction Control in JDBC
==== Database and C
- ODBC Code
```c
int ODBCexample()
{
  RETCODE error;
  HENV env; /* environment */
  HDBC conn; /* database connection */
  SQLAllocEnv(&env);
  SQLAllocConnect(env, &conn);
  SQLConnect(conn, "db.yale.edu", SQL_NTS, "avi", SQL_NTS, "avipasswd",
             SQL_NTS);
  {... Do actual work ...}
  SQLDisconnect(conn);
  SQLFreeConnect(conn);
  SQLFreeEnv(env);
}
```
- 使用 `SQLExecDirect` 直接执行 SQL 语句，返回结果使用 `SQLFetch()` 来得到，`SQLBindCol()` 来绑定结果
```c
char deptname[80];
float salary;
int lenOut1, lenOut2;
HSTMT stmt;
char * sqlquery = "select dept_name, sum (salary)
                  from instructor
                  group by dept_name";
SQLAllocStmt(conn, &stmt);
error = SQLExecDirect(stmt, sqlquery, SQL_NTS);
if (error == SQL_SUCCESS) {
    SQLBindCol(stmt, 1, SQL_C_CHAR, deptname , 80, &lenOut1);
    SQLBindCol(stmt, 2, SQL_C_FLOAT, &salary, 0 , &lenOut2);
    while (SQLFetch(stmt) == SQL_SUCCESS) {
        printf(" %s %g\n", deptname, salary);
    }
}
SQLFreeStmt(stmt, SQL_DROP);
```
- ODBC 的 Prepare
  - To prepare a statement: ```c SQLPrepare(stmt, <SQL String>);```
  - To bind parameters: ```c SQLBindParameter(stmt, <parameter#>, ... type information and value omitted for simplicity..)```
  - To execute the statement: ```c SQLExecute(stmt);```
- More ODBC Features
  - Matadata Features
  - Transaction Control
==== Embedded SQL
- SQLJ: embedded SQL in Java
```java
#sql iterator deptInfoIter ( String dept name, int avgSal);
deptInfoIter iter = null;
#sql iter = {select dept_name, avg(salary) as avgSal from instructor
             group by dept name};
while (iter.next()) {
    String deptName = iter.dept_name();
    int avgSal = iter.avgSal();
    System.out.println(deptName + " " + avgSal);
}
iter.close();
```
- SQLCA: embedded SQL in C
```c
main() { // insert without cursor
    EXEC SQL INCLUDE SQLCA; //声明段开始
    EXEC SQL BEGIN DECLARE SECTION;
    char account_no [11]; //host variables(宿主变量)声明
    char branch_name [16];
    int balance;
    EXEC SQL END DECLARE SECTION;//声明段结束
    EXEC SQL CONNECT TO bank_db USER Adam Using Eve;
    scanf("%s %s %d", account_no, branch_name, balance);
    EXEC SQL insert into account
        values(:account_no, :branch_name, :balance);
    If (SQLCA.sqlcode != 0)
        printf("Error!\n");
    else
        printf("Success!\n");
}
main() { // select single record without cursor
    EXEC SQL INCLUDE SQLCA; //声明段开始
    EXEC SQL BEGIN DECLARE SECTION;
    char account_no [11]; //host variables(宿主变量)声明
    int balance;
    EXEC SQL END DECLARE SECTION; //声明段结束
    EXEC SQL CONNECT TO bank_db USER Adam Using Eve;
    scanf("%s", account_no);
    EXEC SQL select balance into :balance
             from account
             where account_number = :account_no;
    If (SQLCA sqlcode != 0)
        printf("Error!\n");
    else
        printf("balance=%d\n", balance);
}
// Embedded SQL with cursor (select multiple records)
main() {
    EXEC SQL INCLUDE SQLCA;
    EXEC SQL BEGIN DECLARE SECTION;
    char customer_name[21];
    char account_no [11];
    int balance;
    EXEC SQL END DECLARE SECTION;
    EXEC SQL CONNECT TO bank_db USER Adam Using Eve;
    EXEC SQL DECLARE account_cursor CURSOR for // 与之前不同的地方
        select account_number, balance
        from depositor natural join account
        where depositor.customer_name = : customer_name;
    scanf (“%s”, customer_name);
    EXEC SQL open account_cursor;
    for (; ;) {
        EXEC SQL fetch account_cursor into :account_no, :balance;
        if (SQLCA.sqlcode!=0)
            break;
        printf( “%s %d \ n”, account_no, balance);
    }
    EXEC SQL close account_cursor;
}
```
- Dynamic SQL in Embedded SQL
  - Allows programs to construct and submit SQL queries at run time.

=== Functions and Procedures
- SQL 提供#redt[module]语言，允许定义函数和过程(functions and procedures)，包括 if-then-else，while，for，loop 等
  - 二者的区别在于 procedures 没有返回值
- 这些 function, procedures 被存储在 database 中，通过 `call` 来调用，它们可以用 SQL 的 procedural component 定义，也可以用外部编程语言 Java, C, or C++ 等
- 例如（这句话我在 MySQL 里跑不太对，要加 READS SQL DATA）
```sql
create function dept_count(dept_name varchar(20))
returns integer
# READS SQL DATA
begin
  declare d_count integer;
  select count (*) into d_count
  from instructor
  where instructor.dept_name = dept_name;
  return d_count;
end
```
- 返回值 table 函数
```sql
create function instructors_of (dept_name char(20))
returns table (ID varchar(5),
              name varchar(20),
              dept_name varchar(20),
              salary numeric(8,2))
```
- Procedural Constructs
  - while, repeat
  - if-then-else
  - for
- 一个复杂的例子
#fig("/public/assets/Courses/DB/img-2024-03-25-14-52-40.png")
- External Language Functions/Procedures and Security

=== \*Triggers 触发器
- Trigger触发器：在修改了数据库时会自动执行的一些语句
- Trigger - ECA rule
  1. E: Event(insert, delete, update)
  2. C: Condition
  3. A: Action
- trigger event 触发事件
  - insert/delete/update 等操作都可以触发设置好的 trigger
  - 触发的时间点可以是 before 和 after，触发器的语法如下
```sql
create trigger trigger_name before/after trigger_event of table_name
    on attribute
    referencing xxx
    for each row
when xxxx
begin
  xxxx(SQL operation)
end
```
- 例子：大额交易记录表 ```sql account_log(account, amount, datetime)```
```sql
create trigger account_trigger after update of account on balance
    referencing new row as nrow
    referencing old row as orow
    for each row
when nrow.balance - orow.balance > =200000 or
    orow.balance - nrow.balance >=50000
begin
    insert into account_log values (nrow.account-number,
        nrow.balance-orow.balance , current_time())
end
```
- Statement Level Triggers（语句级的 trigger）
  - 除了为每个受影响的行设置 trigger，还可以为受事务影响的整个表设置 trigger
```sql
create trigger grade_trigger after update of takes on grade
referencing new table as new_table
for each statement
when exists(select avg(grade)
            from new_table
            group by course_id, sec_id, semester, year
            having avg(grade)< 60)
begin
  rollback
end
```
- When Not To Use Triggers
  - Triggers 曾被用于的这些任务
    - maintaining summary data，但现在可以用#redt[materialized view]来更好地实现
    - 通过记录对特殊关系的更改（称为更改或增量关系）并将更改应用于副本来复制数据库，但现在 Databases provide built-in support for replication
  - Encapsulation facilities can be used instead of triggers in many cases
  - Risks of unintended execution of triggers

=== \*\*Recursive Queries 递归查询
- 通过递归查找所有预修课
```sql
with recursive rec_prereq(course_id, prereq_id) as (
    select course_id, prereq_id
    from prereq
  union
    select rec_prereq.course_id, prereq.prereq_id,
    from rec_prereq, prereq
    where rec_prereq.prereq_id = prereq.course_id)
select *
from rec_prereq;
```
- Recursive views make it possible to write queries, such as transitive closure queries, that cannot be written without recursion or iteration.
  - 如果没有 recursive，则必须用外部编程语言实现

=== \*\*Advanced Aggregation Features 高级聚合特性
- 后面都没讲了

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
- 可以参照 @OOP 体会更多 DB 吸收的 OOP 特性
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
- 参见 @semi-structure

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

= 第四部分: 数据库设计理论
== 复杂数据类型
=== 面向对象数据库 <OOP>
- 在关系数据库中融入面向对象的思想
  - Build an #redt[object-oriented database(OODB)] that *natively supports* object-oriented data and direct access from programming language
  - Build an #redt[object-relational database(ORDB)], adding object-oriented features to a relational database
  - Automatically convert data between programming language model and relational model; data conversion specified by object-relational mapping(ORM)
- 为了让 SQL 支持复杂类型，引入的扩展
  + *Collection types*(Nested relations are an example of collection types)
  + *Structured types*(Nested record structures like composite attributes)
  + *Inheritance*
  + *Object orientation*(Including object identifiers and references)
  + *Large object types*(BLOB, CLOB)
- 我们的叙述主要基于 SQL1999，它的标准尚未被完全实现，但很多特性已经在某些商业数据库中广泛应用
- User-defined types and Table types
```sql
create type Person
    (ID varchar(20) primary key,
    name varchar(20),
    address varchar(20))
    ref from(ID);
create table people of Person;

create type interest as table (
    topic varchar(20),
    degree_of_interest int);
create table users (
    ID varchar(20),
    name varchar(20),
    interests interest); -- Table 作为 type
```
- Array and Multiset Types
```sql
create type Publisher as
    (name varchar(20),
    branch varchar(20))
create type Book as
    (title varchar(20),
    author-array varchar(20) array [10],
    pub-date date,
    publisher Publisher,
    keyword-set varchar(20) multiset)
create table books of Book
```

- Type and Table Inheritance
```sql
create type Student under Person (degree varchar(20));
create type Teacher under Person (salary integer);
```
- Reference Types
```sql
create type Person
    (ID varchar(20) primary key,
    name varchar(20),
    address varchar(20))
    ref from(ID);
create table people of Person;
create type Department (
    dept_name varchar(20),
    head ref(Person) scope people);
create table departments of Department
insert into departments values ('CS', '12345')
-- Using references in path expressions
select head->name, head->address from departments;
```
- Object-Relational Mapping
  - Object-relational mapping(ORM) systems allow
    + Specification of mapping between programming language objects and database tuples
    + Automatic creation of database tuples upon creation of objects
    + Automatic update/delete of database tuples when objects are update/deleted
    + Interface to retrieve objects satisfying specified onditions
      - Tuples in database are queried, and object created from the tuples
  - 大概意思就是在高级编程语言的 objects 和数据库 tuples 之间建立一一映射（比如如果是 Java，就是在 JDBC 之上再套一层抽象）
  - An example: #redt[Hibernate] ORM for Java
    ```java
    @Entity public class Student {
        @Id String ID;
        String name;
        String department;
        int tot_cred;
    }

    // creates a Student object and saves it to the database
    Session session = getSessionFactory().openSession();
    Transaction txn = session.beginTransaction();
    Student stud = new Student("12328", "John Smith", "Comp. Sci.", 0);
    session.save(stud);
    txn.commit();
    session.close();
    ```
  - `@Entity` 表示映射到数据库中某一关系；默认的关系名和属性名可以用 `@Table` 和 `@Column` 覆盖；`@Id` 表示主键

=== 半结构数据 <semi-structure>
- 半结构化数据便利了数据的交换（应用之间、前后端之间）
- XML: Extensible Markup Language
  - 例如
  ```XML
  <bookstore>
      <book category="COOKING" ISBN="100-10-00">
          <title lang="en">Everyday Italian</title>
          <author>Giada De Laurentiis</author>
          <year>2005</year>
          <price>30.00</price>
      </book>
      <book category="CHILDREN" ISBN="10000-100-199">
          <title lang="en">Harry Potter</title>
          <author>J K. Rowling</author>
          <year>2005</year>
          <price>29.99</price>
          <publisher>ABC</publisher>
          <edition>5</edition>
      </book>
      <book category="WEB" ISBN="10000-10-09">
          <title lang="en">XQuery Kick Start</title>
          <author>James McGovern</author>
          <author>Per Bothner</author>
          <year>2003</year>
          <price>49.99</price>
      </book>
  </bookstore>
  ```
  - XML 可以单独作为一种数据形式，用 Tree model 存储，用 DTD 定义，用 XPath 表达式查询
- JSON: JavaScript Object Notation

=== RDF & Textual Data & Spatial Data
- 略

== 物理存储系统
- 存储介质可以分为：volatile storage（易失存储）, non-volatile storage（非易失存储）
- 存储的结构 storage hierarchy
  - primary 主存储器
    - 快而易失，常见的有主存(main memory)和 cache
    - cache 的存取效率最高，但是 costly，主存访问快但是对于数据库而言空间太小
  - secondary 二级存储器
    - 不容易丢失，访问较快，又叫在线存储
    - 常见的是闪存和磁盘(and SSD)
  - tertiary 三级存储器
    - 不容易丢失，访问慢，但是容量大而 cheap，离线存储
    - 磁带，光存储器
  - 总体的存储架构：cache--主存--闪存--磁盘--光盘--磁带
#fig("/public/assets/Courses/DB/img-2024-04-25-14-36-17.png")

=== 磁盘 Magnetic Disks
- 组成结构
#wrap-content(
  fig("/public/assets/Courses/DB/img-2024-04-22-13-42-25.png"),
  [
    - read-write head 读写头
      - 和磁盘表面靠得很近
      - 用于读写磁盘中的文件信息
    - tracks 磁道, 由磁盘表面划分，每个硬盘大概有 50k 到 100k 个磁道
      - sectors 扇区，由磁道划分而成
        - 扇区是数据读写的最小单位
        - 每个扇区的大小是 512 bytes，每个磁道有 500$wave$1000 个扇区
    - 磁盘控制器:计算机系统和磁盘之间的接口
    - Disk subsystem 磁盘子系统：由 disk controller 操纵若干个磁盘组成的字系统
  ],
)
- 磁盘的性能评价标准
  - access time（访问时间），包括：
    - seek time（寻道时间）：读写头的 arm 正确找到 track 的时间，平均的 seek time 是最坏情况的一半
    - rotational latency（旋转延迟）：旋转造成的延迟，平均时间是最坏的一半
  - data-transfer rate（数据传输率）：数据从磁盘读写的速度
  - Disk block：logical unit for storage allocation and retrieval，通常在 4k$wave$16k bytes 之间
  - 顺序访问模式(Sequential access pattern)与随机访问模式(Random access pattern)，尽量用顺序访问替换随机访问。
  - I/O operations per second（IOPS ，每秒 I/O 操作数）
  - MTTF（mean time to failure，平均故障时间）：出现 failure 之前的平均运行时间
- 磁盘访问的优化
  - buffering：in-memory buffer to cache disk blocks
    - block: 一个磁道中的若干连续扇区组成的序列
  - read-ahead：数据预取
  - disk-arm-scheduling：磁盘控制器层面的算法优化
  - file organization：通过按照访问数据的方式来组织 block 优化访问时间
  - Nonvolatile write buffers（非易失性写缓存）
    - 把要写的数据先写到一个快速的非易失的缓存里，如 NVM. 这时上面的程序可以继续执行了, NVM 再择机将数据写回到磁盘。
  - Log disk（日志磁盘）
=== Flash Storage
- NAND flash
  - requires page-at-a-time read (page: 512 bytes to 4 KB)，顺序读写和随机读写差不多
  - 写了数据如果要再写需要把之前的擦掉，像黑板
- SSD(Solid State Disk)
  - 使用标准的面向块的磁盘接口，但在内部将数据存储在多个*闪存*设备上
  - 一个 block 在经过许多次 erase 后将会*磨损*
  #tbl(
    columns: 3,
    fill: blue.lighten(70%),
    [],
    [Magnetic Disk],
    [Solid State Disk],
    [Retrieve a page],
    [5-10 milliseconds],
    [20-100 microseconds],
    [Random access],
    [Random 50 to 200 IOPS],
    [reads: 10,000 IOPS writes: 40,000 IOPS],
    [Data transfer rate],
    [200M],
    [500M(SATA), 3G(NVMe)],
    [Power consumption],
    [higher],
    [lower],
    [Update mode],
    [in place],
    [erase $->$ rewrite],
    [Realiability],
    [MTTF : 500,000 to 1,200,000 hours],
    [erase blocks: 100,000 to 1,000,000 erases],
  )
  - 将 logical page *Remapping* 到 physical page addresses，避免等待 erase 的时间消耗
    - 这通过 *Flash translation table*(also stored in a label field of flash pag) 来记录
    - 同时负责 wear leveling(磨损均衡)：跨物理块均匀分布写操作
- 比较
#tbl(
  columns: 5,
  fill: blue.lighten(70%),
  [],
  [DRAM],
  [NVM],
  [SSD],
  [HDD],
  [Read Latency],
  [1x],
  [2-4x],
  [500x],
  [105x],
  [Write Latency],
  [1x],
  [2-8x],
  [5000x],
  [105x],
  [Persistence],
  [No],
  [Yes],
  [Yes],
  [Yes],
  [Byte-Addressable],
  [Yes],
  [Yes],
  [No],
  [No],
  [Endurance],
  [Yes],
  [No],
  [No],
  [Yes],
)

=== File organization 文件组织
- 数据库存储在一系列的文件中，每个文件是一系列的 records，每条 record 包含一系列的 fields
  - 每个文件被划分为固定长度的 block，block 是数据存取/存储空间分配的基本单位
  - 一个 block 有多条记录，在传统的数据库中，我们作以下假设：
    - 记录的长度不能超过 block
    - 每条记录一定都是完整的
- Fixed-Length Records 定长记录
  - Store record $i$ starting from byte $n dot (i – 1)$, where $n$ is the size of each record.
  - 三种 delete 方式：
    + 顺序移动，低效
    + 用最后一条覆盖
    + Free List，用链表的形式来存储 free records
#fig("/public/assets/Courses/DB/img-2024-04-22-15-07-07.png")
- Variable-length records 变长记录
  - 典型的变长记录
    - 属性按照顺序存储
    - 变长记录由两部分组成：用 offset+length 的形式指示变长信息以及本身就是定长属性的定长段，以及存储实际信息的变长段
    - 空值用 null-value bitmap 存储
  - 例如：这里位置 12 放的 65000 是定长的 salary，位置 20 放的 0000, 表示前面四个属性均是非空的, 1 表示空。（放在前面也可以，只要在一个固定位置能找到即可）前提：每一个记录都是被放在一起的。（有按列存储的方式）
#fig("/public/assets/Courses/DB/img-2024-04-22-14-54-07.png")
- 变长记录如何安置到 block 中？*slotted page* 结构
  - slotted page header 包含
    + 记录的总数
    + block 中的 free space 的末尾
    + 每条记录所在的位置和大小
  - 删除的两种策略：
    + 顺序移动，低效
    + 打个标记，等后面如果需要分配内存但不够用时，再一次性重整之前的空间。
#fig("/public/assets/Courses/DB/img-2024-04-22-14-54-57.png")
- 文件中记录的组织方式
  - heap
  - sequential
  - multitable clustering file organization
  - B+ tree
  - hashing
- Heap File Organization
  - 记录可以被放置在文件中任何 free space，通常它们一旦申请了就不会移动
  - 找到空闲空间十分重要，使用 *Free-space map*
    - 维护一个空闲块的地图，记录这个块的空闲程度。
    - multi-level free-space map
#fig("/public/assets/Courses/DB/img-2024-04-22-15-13-09.png")
- Sequential File Organization
  - 适用于需要对整个文件进行顺序处理的应用程序
  - 文件中的记录按搜索键(*search-key*)排序
  - Deletion – use pointer chains
  - Insertion – locate the position where the record is to be inserted
    - 逻辑上联系，物理上分开到新的 block 中，不然需要频繁地移动
    - 一段时间后进行物理重组(*reorganize*)，否则就失去了顺序性、局部性的意义
#fig("/public/assets/Courses/DB/img-2024-04-22-15-16-16.png")
- Multitable Clustering File Organization
  - 把相关信息存放在一起组成 clusters
  - 这样，对经常链接的两个表 $"department" join "instructor"$ 比较高效；但对单独查询某个信息就不太好
#fig("/public/assets/Courses/DB/img-2024-04-22-15-23-17.png")
- Table Partitioning
  - 一个表太大，对于并行访问可能引发冲突，也不利于数据的存储，并且每个操作的开销过大，于是我们可以把表分开
  - 事实上，我们可以用不同的切分方式实施多次，并且存在不同的存储介质上，比如把热点数据放在 SSD 上，把冷数据放在 magnetic disk 上
- Data Dictionary Storage
  - 数据字典、或称系统目录，存储 metadata，比如
    + Information about relations
    + User and accounting information, including passwords
    + Statistical and descriptive data
    + Physical file organization information
    + Information about indices

=== 存储缓冲区的管理
- block 是存储空间申请和数据转移的基本单位
- 通过将数据放到主存中来提高访问效率
  - buffer manager：用于管理缓冲区中的内存分配
    - 当需要从磁盘读取 block 的时候，数据库会调用 buffer mananger 的功能
    - 如果 block 已经在 buffer 中了，就直接返回这个 block 的地址
    - 如果不在，则 buffer manager 会动态分配 buffer 中的内存给block，并且可能会覆盖别的 block，然后将磁盘中 block 中的内容写入 buffer 中
  - 涉及到 buffer 的替换算法 LRU strategy（最近最少策略） 即替换掉最近使用频率最低的 block
    - 用链表来表示访问次序
    #fig("/public/assets/Courses/DB/img-2024-04-22-15-44-06.png")
  - pinned block: 内存中的不允许写回磁盘的 block，表示正在处理事务或者处于恢复阶段（正在访问这一块，那么这一块不能被替换出去）
    - keep a `pin_count`，buffer block 只有在 `pin_count` 为 0 时才能被替换
  - Shared and exclusive locks on buffer
    - 当 page 在 move/reorganize 的时候，需要防止内容读取，同时要确保同一时刻只有一个 move/reorganize 操作
    - readers get *shared lock*; updating to a block requires *exclusive lock*
    - Locking rules:
      + 同一时刻只有一个进程能得到排他锁
      + shared lock 和 exclusive lock 不能同时存在
      + shared lock 可以同时赋予多个进程

#wrap-content(
  fig("/public/assets/Courses/DB/img-2024-04-22-18-30-34.png"),
  [
    - Clock
      - LRU 算法的近似替代
      - 当某页被访问时，设其访问位为 1。当需要淘汰一个页面时，只需检查页的访问位
      - 如果是 0，就选择该页换出；如果是 1，则将它置为 0，暂不换出，继续检查下一个页面，若第一轮扫描中所有页面都是 1，则将这些页面的访问位依次置为 0 后，再进行第二轮扫描
  ],
)
```
When replacement necessary:
    do for each block in cycle {
        if (reference_bit == 1)
            set reference_bit = 0;
        else if (reference_bit == 0)
            choose this block for replacement;
    } until a page is chosen;
```

=== Column-Oriented Storage
- 列存储 (Column-Oriented Storage) 是将关系的每个属性单独存储的方式。
- 列存储的优点有：
  + 如果只有一部分属性被访问，可以减少 I/O 次数
  + 可以提高 CPU 缓存性能
  + 可以提高压缩效率
  + 可以在现代 CPU 架构上实现向量处理
- 列存储的缺点有：
  + 从列存储中重建元组的代价较高
  + 元组的删除和更新代价较高
  + 解压缩代价较高
  + 列存储在决策支持系统中比行存储更有效，而在事务处理中，传统的行存储更受欢迎。一些数据库支持同时使用两种存储方式，称为混合行列存储(Hybrid Row/Column Stores)

== 索引
- 数据库系统中引入索引机制，用于加快查询和访问需要的数据
- search key 通过一个属性值查找一系列属性值，用于文件中查询
- Index file 索引文件包含一系列的 search key 和 pointer（两者的组合被称为 index entry）
  #tbl(
    columns: 2,
    [search key],
    [pointer],
  )
  - 查询方式是通过 search key 在 index file 中查询 data 的地址(pointer)，然后再从 data file 中查询数据
  - 两种 search key 的排序方式：ordered index，hash index
- 索引的不同指标
  - 查询有两种（Point query 和 Range query）
  - Access time, Insertion time, Deletion time, Space overhead
- Ordered indices 顺序索引：index entry 按照 search key 的值来进行排列
  - Primary index 主索引（Also called clustering index，聚集索引）
    - 主索引和数据内的顺序是一样的。点查和范围查都是比较高效的。
    - search key 往往是 primary key，但不一定；如果 key 不是一个主键，那可能会对应多个记录，后面辅助索引也是一样。
  #fig("/public/assets/Courses/DB/img-2024-04-29-13-43-51.png")
  - Secondary index 辅助索引(Also called non-clustering index)
    - 不要跟多级索引搞混，仍是一级，但 search key 值的排序不同于 file 内数据的顺序
  #fig("/public/assets/Courses/DB/img-2024-04-29-13-43-32.png")
- 索引的不同方式
  - Dense index 密集的索引：每一条记录都有对应的索引
  - Sparse index 稀疏的索引：查询时从 pointer 指向记录开始顺序查找；需要的空间和插入删除新索引的开销较小，但是比密集的索引要慢
  #grid(
    columns: 2,
    fig("/public/assets/Courses/DB/img-2024-04-29-13-42-29.png", width: 85%),
    fig("/public/assets/Courses/DB/img-2024-04-29-13-42-45.png"),
  )
  - Multilevel index 多级索引，如对索引文件本身再建立一次索引
    - 分为 outer index 和 inner index

=== B+ 树索引
- B+ 树文件索引
  - 通过 B+ 树的索引方式来寻找文件中数据的地址，B+ 树的定义和 ADS 中的 B+ 树类似，
    - 树的非叶节点由指向儿子的指针和充当路标的 search-key 相间组合而成
    - 两个 search-key 之间的指针指向的数据的值在这两个 search-key 之间
    - note：下面这张图实际上用的是 secondary index，只是没画出来（一旦出现同名而 ID 分开的情况，这张图就寄了）
  #fig("/public/assets/Courses/DB/img-2024-04-29-13-50-04.png")
  - B+ 树上的查询的时间复杂度是 $log N$ 级别，$N$ 是 search key 的总个数
    - 查询的路径长度：不会超过 $ceil(log_(n/2) K/2) + 1$，其中 $K$ 是 B+ 树中的索引的个数（即规模 $N$）
    - B+ 树的一个节点的大小和一个磁盘区块一样大(往往是 4KB)，而 $n$ 的规模一般在 $100$ 左右（矮胖）
- B+ 树的查询，支持 point query, range query 和整体的 scanning
- B+ 树的更新：插入和删除
  - 插入的算法：先找到该插入的位置直接插入，如果当前的节点数量超过了阶数 $M$ 则拆成两个部分，并向上更新索引
  - 删除的算法: 直接把要删除的节点删除，然后把没有索引 key 的非叶节点删除，从旁边找一个叶节点来合并出新的非叶节点
    - internal node 实际上不一定要删除某一项（也就是说存在 internal 节点中的某个值不在 leaf node 中的情况）
- B+ 树的相关计算
  - 高度的估计（似乎是从 $1$ 开始算）：
    - B+ 树高度最小的情况：所有的叶节点都满，此时的 $h = ceil(log_N M)$
    - 最大的情况，所有的叶节点都半满，此时的 $h= ceil(log_[N/2] M/2)+1$
  - size 大小的估计：也是两种极端情况
  - 给定高度，计算能表示的 record 数量最多最少是多少
  #fig("/public/assets/Courses/DB/img-2024-04-29-14-25-39.png")
  - 给定 size，计算高度，或更精细地计算每层节点数
  #fig("/public/assets/Courses/DB/img-2024-04-29-14-34-17.png")
=== B+ trees issues
- B+ 树文件组织
  - 叶子节点不再放索引项，放记录本身。
    - 可以改变半满的要求以提高空间利用率。
  #fig("/public/assets/Courses/DB/img-2024-04-29-14-46-58.png")
- Record relocation and secondary indices
  - 考虑记录的 *move*，所有 secondary index 都要更新
  - solution: 后面讲的 non-unique search keys 或者改造 secondary B+ tree index，将“索引+pointer”变为“索引+primary key”（添加了继续从 primary key 查询到实际地址的开销）
- Variable length strings as keys
  - solution: #strike[用魔法打败魔法]，使用动态 fanout，即不再以指针数量作为节点切分的标准，而是以空间使用率(space utilization as criterion for splitting)
- Prefix compression
  - 对 internal node，可以仅保留足够区分 entries 的前缀，以节省空间
  - 对 leaf node，可以共享前缀
- Multiple-Key Access
  - 对频繁出现的多个属性的查询，可以用组合属性建立 B+ 树
  - B+ 树算法是一模一样的，只是比较函数发生变化
- Non-unique Search Keys
  - B+ 树叶子节点不直接指向磁盘里的某个数据，而是指向一个块
  - 或者，可以在索引上加上一个属性成为 multiple-key，使它对应的记录唯一
    - 对原本的索引查找，可以视为加上范围查找，如 ${a_i=v} -> {(v,-infty) "to" (v,infty)}$

=== Bulk Loading and Bottom-Up Build
- 如果我们一次性插入很多数据，有两种策略
+ Efficient alternative 1: 插入前先排序
  - 局部性较好，减少 I/O
+ Efficient alternative 2: 自底向上构建
  - 如果是初始化 bulk load
  + 首先排序
  + 随后从最底层开始，layer by layer 地创建 B+ 树，写入磁盘的过程可以同时进行
  #fig("/public/assets/Courses/DB/img-2024-04-29-15-08-06.png")
  - 如果是对已有 B+ 树 bulk load
  + 遍历已有 B+ 树的叶子层，将其和新数据 merge sort，然后重新 layer by layer 地构建 B+ 树
  #fig("/public/assets/Courses/DB/img-2024-04-29-15-15-22.png")

=== Indexing in Main Memory and Flash
- In Memory: 尽管快于 disk/flash，但仍慢于 cache
  - 对一个拥有大 node 的 B+ tree，可能会造成许多 cache misses
    - 数据结构或算法是否能够利用 cache 特性被称为 cache-aware or cache-conscious
  - 考虑到 disk access，每个 node 的大小依然应该是 $4K$
  - 但在 node 中查询，无论用顺序查找还是二分之类，都没有充分利用 cache，此时的解决方法是 node 内，再用一个树形结构拆散成 $64B$，也就是节点内再细分成一棵树（而不是用数组存储）
  #fig("/public/assets/Courses/DB/img-2024-04-29-19-30-51.png")
- In Flash: 需要先 erase 才能 write，同时擦的次数是有限制的
  - 最好的方法是从底构建，然后顺序写入
  - 使用 LSM tree

=== Write Optimized Indices
- Performance of B+-trees can be poor for *write-intensive*（写密集型） workloads
==== Log Structured Merge (LSM) Tree
#grid(
  columns: 2,
  [
    - consider only inserts/queries for now
    - 原始版本（插入）
      - 记录首先插入到 in-memory tree($L_0$ tree)中
      - 当 $L_0$ tree 满时，将其移动到 disk，构建或合并到 $L_1$ tree（使用 bottom-up build）
      - 以此类推
    - 好处
      - Inserts are done using only *sequential I/O* operations
      - *Leaves are full*, avoiding space wastage
      - Reduced number of I/O operations per record inserted as compared to normal B+ tree(up to some size)
    - 坏处
      - Queries have to search multiple trees
      - Entire content of each level copied multiple times（一定的空间浪费）
    - 变体: Stepped-merge index
      - 磁盘上每层有 $k$ 棵树，当 $k$ 个索引处于同一层时，使用 $k$ 路 merge 合并它们并得到一棵层数 +1 的树
      - 相比原始版本减少 write cost，但使得 query 变得 even more expensive
      - point query 的优化——bloom filter（布隆过滤器）
      - 每棵树对应一个 bloom filter，用于判断某个 key 是否可能在这棵树中（1 不一定在，0 一定不在）
    - LSM trees 最初作为 disk-based indices 被引入，但对减少 flash-based indices 的擦除也很有帮助
  ],
  [
    #fig("/public/assets/Courses/DB/img-2024-04-29-19-35-47.png")
    #v(5em)
    #fig("/public/assets/Courses/DB/img-2024-04-29-19-45-44.png")
    #fig("/public/assets/Courses/DB/img-2024-04-29-20-05-31.png")
  ],
)

==== Buffer Tree
- B+ tree 的每个 internal node 中把一定位留空作为 buffer
- 插入时先存储在 buffer 中，等到一定量后批量移动到下一个 level 的 node
- 相应地，减少了每个记录的 I/O 次数

==== bitmap indices
- Bitmap indices are a special type of index designed for efficient querying on multiple keys
- 特别适用于这种情况：记录数目固定，但想要加快查询速度的情况，并且待查询的属性的*取值数量较少*
- 对于多属性查询，使用按位*与*、*或*即可很方便地得到结果
- bitmap 的所需空间相比 original relation size 要小得多
- 在计算机中打包成 word(32 or 64) 进行计算
#fig("/public/assets/Courses/DB/img-2024-04-29-20-16-48.png")

=== 总结：存储结构和B+树的计算
- 记录的存储：
  - 数据库的记录在 block 中存储，一个 block 中有大量的记录存储，有线性存储的，也有使用 B+ 树索引的
  - 线性存储的记录：
    - 假设一条记录的长度为 $L$，block 的大小为 $B$，那么一条记录中最多有$ floor(B/L)$ 条记录
    - 如果一共有 $N$ 条记录，一个 block 中有 $M$ 条记录，那么一共需要$ceil(N/M)$ 个 block，而 $M=floor(B/L)$
  - B+ 树索引 block 的计算，假设 block 的大小为 $B$，指针的大小是 $a$，被索引的属性值大小是 $b$
    - 要注意指针节点比属性值多一个，所以一个块上的扇出率 $n$(fan-out rate)是$ floor((B-a)/(a+b))+1$
    - $n$ 也就是这个 B+ 树的阶数，然后根据公式来估算 B+ 树的高度，其中 $M$ 应该是作为索引的值可以取到的个数

== 查询处理 QueryProcess
#quote[印象中这一部分的作业题以套公式算为主]
- 查询处理的基本步骤
  - Parsing and translation 解析和翻译
  - Optimization 优化
    - 一种 SQL 查询可能对应了多种等价的关系代数表达式
    - 估计每种方式的 cost，选择最节约的方式进行查询
  #fig("/public/assets/Courses/DB/img-2024-05-06-13-39-00.png")
  - Evaluation 评估
    - 更细化地指定每个操作使用的算法，指定各个操作如何协调
  #fig("/public/assets/Courses/DB/img-2024-05-06-13-39-43.png")
- Query cost 的计算
  - 主要的 cost 来源：disk access
    - seek（磁盘读写头寻道）
    - block read
    - block written，且 write 的 cost 要大于 read
    - 为简单起见，read 和 write 合在一起作为 block transfer，并且忽略 CPU cost（为简单起见），忽略最后一次写回磁盘的开销（因为 pipeline）
  - cost 计算的方式：在 $B$ 个 blocks 中查询 $S$ 次所消耗的时间$= B times t_T+S times t_S$，其中$t_T$ 表示一次 block transfer 的时间，$t_S$ 表示一次 seek 的时间
    - cost依赖于主存中*缓冲区的大小*：更多的内存可以减少 disk access
    - 通常考虑最坏的情况：只提供最少的内存来完成查询工作

=== select 的 cost 估计
- Algorithm1:线性搜索，查询每个 block 判断是否满足查询条件
  - 只用 seek 一次（假定数据页都放在一起）
  - 最坏情况：$"Cost" = b_r times t_T + t_s$，其中$b_r$ 是关系 r 中*存储了记录的block的数量*
  - 如果通过键来搜索，在找到的时候就停止，则平均情况：$"Cost" = (b_r\/2) times t_T + t_s$
- Index scan--使用索引进行搜索
  - Algorithm2: primary index, equality on key，使用 B+ 树搜索一条记录
    - $"cost" = (h_i+1) times(t_T+t_S)$ --- $h_i$ 是索引的高度（从 $1$ 开始）
  - Algorithm3: primary index, equality on non-key，使用 B+ 树搜索多条记录
    - 想要的结果会存储在连续的block中(因为有主索引)
    - $"cost" =h_i (t_T + t_S) + t_S + t_T * b$ 其中$ b$ 表示包含匹配记录的 block 总数
  - Algorithm4：Secondary index, equality on key
    -  $"cost" = (h_i + 1)  times (t_T + t_S)$
  - Algorithm4'：Secondary index, equality on non-key
    - 检索了$n$ 条记录，不一定在同一个 block 上面，设共分布在 $m$ 个 block 上
    - $"cost" = (h_i + m + n) times (t_T + t_S)$ 有时候会非常耗时
  - Algorithm5：comparison
    - `<` 直接扫描
    - `>` 使用 primary index: $"cost" =h_i (t_T + t_S) + t_S + t_T * b$ 与 Algorithm3 一样
- Algorithm6 $wave$ Algorithm9，涉及比较和复杂操作，没有具体的公式（可能比较难算了）

=== sort 的 cost 估计
- Sort：*external* *sort-merge* 类似于 ads 里面的外部归并排序
  - 基本步骤如下（$M$ 表示 memory 能包含几个 block，$b_r$ 表示 block 的数量）
    - create sorted runs，创建归并段，即对 blocks 分段排序，显然分段大小受制于 $M$
    - merge the runs，将这些段进行 $k$ 路归并，可能需要进行多次
    - 下图中，假设一个字母加一个数字就是一个块（每个块包含 $1$ 个记录，$b_r=12$），$M=3$，那么有 $ceil(b_r\/M)=4$ 个总的归并段，$"passes"=2$，每次 pass 处理 $M-1=2$ 个归并段，每个归并段同时处理 $1$ 个 block($b_b=1$)
  #fig("/public/assets/Courses/DB/img-2024-05-06-20-12-04.png")
  - 思考为什么明明看起来是相邻的块依然要 seek？
#grid(
  columns: 2,
  gutter: 1em,
  align(horizon, fig("/public/assets/Courses/DB/img-2024-05-06-20-19-23.png")),
  [
    - Simple version
      - runs 总数 $ceil(b_r\/M)$
      - merge pass 总数 $ceil(log_(M-1)(b_r\/M))$
      - 如果归并段 $N$ 小于内存页 $M$，该次 pass 能一下子处理完，使用 $N$ blocks 作 buffer 处理数据，$1$ block 作输出（满了就写回并清空）
        - 否则，该次 pass 分多次处理，用 $M-1$ 个 block 作 buffer（在 simple version 下，每次处理 $M-1$ 个归并段），$1$ 个 block 作输出
      - Cost of Block Transfer
        - During run generation 为 $2 b_r$；每次 pass 过程中的 disk access 数量也为 $2 b_r$，因为每个块都需要被读取和写回
        - 忽略最后一次写回的 $b_r$，外部排序中总的 disk access 次数 $ (2ceil(log_(M-1)(b_r\/M))+1)b_r $
      - Cost of Seek
        - During run generation 为 $2ceil(b_r\/M)$，也就是两倍归并段的总数；每次 pass 过程中的 disk access 数量为 $2b_r$
        - 忽略最后一次写回的 $b_r$，外部排序中总的 seek 次数 $ 2 ceil(b_r\/M) + b_r (2ceil(log_(M-1)(b_r\/M))-1) $
  ],
  align(horizon, fig("/public/assets/Courses/DB/img-2024-05-06-20-31-39.png")),
  [
    - Advanced version
      - 每个归并段同时只处理一个 block 导致在合并的时候太多次的 seek，考虑每个归并段同时处理 $b_b$ 个 blocks，这样在 merge 阶段，每个归并段内的多个块是写在一起的，只用一次 seek 就可以查到 $b_b$ 个 block
      - read/write $b_b$ blocks at a time; can merge $floor(M\/b_b) - 1$ runs at a time
      - runs 总数 $ceil(b_r\/M)$; merge pass 总数 $ceil(log_(floor(M\/b_b) - 1)(b_r\/M))$
      - Cost of Block Transfer
        - During run generation 为 $2 b_r$；每次 pass 过程中的 disk access 数量也为 $2 b_r$
        - 外部排序中总的 disk access 次数 $ (2ceil(log_(floor(M\/b_b) - 1)(b_r\/M))+1)b_r $
      - Cost of Seek
        - During run generation 为 $2ceil(b_r\/M)$；每次 pass 过程中的 disk access 数量为 $2ceil(b_r\/b_b)$
        - 外部排序中总的 seek 次数 $ 2 ceil(b_r\/M) + floor(b_r\/b_b) (2ceil(log_(floor(M\/b_b) - 1)(b_r\/M))-1) $
  ]
)

=== Join 的 cost 估计
- 这里都没有考虑写出去的消耗（考试的时候可能变通），join 后给 pipeline 后的其它步骤用
- nested-loop join
  - 计算theta-join表达式：$r join_theta s$ 算法的伪代码如下
  - $r$ 指外层循环，$s$ 指内层循环
    ```
    for each tuple tr in r do begin
        for each tuple ts in s do begin
            test pair (tr,ts) to see if they satisfy the join condition
            if they do, add tr • ts to the result
        end
    end
    ```
  - block transfer次数: $n_r times b_s+b_r$
  - seeks的次数 $n_r+b_r$
- block nested-loop join $r join_theta s$
  ```
  for each block Br of r do begin
      for each block Bs of s do begin
          for each tuple tr in Br  do begin
              for each tuple ts in Bs do begin
                  Check if (tr,ts) satisfy the join condition
                  if they do, add tr • ts to the result.
              end
          end
      end
  end
  ```
  - 两个内存循环在内存中进行，忽略不计
  - 最坏情况的 cost: block transfer --- $b_r times b_s+b_r$; seeks --- $2b_r$
    - 从这里也可以看出，大的关系应该放在内层循环
  - 最好情况的 cost: block transfers --- $b_r+b_s$; seeks --- $2$（内存空间足够大，一次全读进来，挺扯的。。。）
  - 优化：使用$M-2$个 block 容纳外层（$M$是内存可以容纳的block数量），此时
    - block transfer次数=$ceil(b_r/(M-2)) times b_s+b_r$
    - seek次数= $2ceil((b_r)/(M-2))$
- Index nested-loop join（在有索引的时候）
  - 索引一定程度上可以代替 file scan，内层关系使用 index
  - 在最糟情况下，内存只能容纳外关系的一个 block（其实应该至少还得容纳内关系的一个 block），对其中的每一条记录，用索引查找 $s$
  - $"cost"=b_r (t_T+t_s)+c times n_r$ 其中 $c$ 表示遍历索引和找到所有匹配的 $s$ 中的 tuple 所消耗的时间，可以用*一次s上的单个selection来估计s的值*
- Merge-Join（如果两个关系是有序的，或者权衡利弊排序后再用这个方法）
  - 只能在natural-join和equal-join中使用
  - 也是会有微型的两重循环（两边多个可以连接的时候）
  - 也可以像 merge sort 一样同时处理多个 block
  - block transfer的次数=$b_r+b_s$，seek的次数=$ceil(b_r/r_b)+ceil(b_s/s_b) ~(r_b+s_b=M)$ （最值计算，柯西不等式）
- hybrid merge-join：一个关系有序，另一个关系在连接属性上拥有 secondary index（B+ 树索引）
  - 先把排序关系和未排序关系 B+ 树的叶子做 merge（后者树上叶子的 key attr 是有序的，因此可以做 merge，这里可以理解为 merge 上指针）
    - transfer 和 seek 的代价参照 Merge-Join
  - 随后，先按照指针指向的地址排个序（而不是直接按地址寻找内容拼接，因为更小）
    - 假设生成的 address 都在内存中，那么不涉及磁盘代价
  - 按照地址寻找内容，替换指针，拼接成结果
    - 设指针落在 $n$ 个 block 上，transfer 和 seek 的代价都是 $n$
- Hash join：使用hash函数进行join
  - hash join 的想法来自于一个直觉：我们是否可以把要 join 的属性按近似程度分门别类，这样只用比较同一类的属性就可以了，大大减少了比较的次数
  - 哈希函数 $bold(h())$ 把 join 属性映射到 {0, 1, ..., $n_h$}，$r_i$ 只需和 $s_i$ 比较，无需考虑其它任何不在 $s_i$ 中的 partition
  - 我们设小的关系为 $s$，称作 build input，大的关系为 $r$，称作 probe input（注意这里大小关系跟前面反一反）
  - 流程为
    + partition build input(s)，用哈希函数 $h()$，并且为每个 partition 预留一个 block 作为 buffer
    + partition probe input(r)，用哈希函数 $h()$
    + 链接 $r_i$ 和 $s_i$ $(0 =< i < n_h)$，方法是为每个 $s_i$ 创建一个不同与之前的 in-memory 哈希函数 $h_i ()$，再 one by one 地从磁盘中读取 $r_i$；然后对每个 tuple $t_r$，利用 $h_i ()$ 快速确定是否有与之对应的 $t_s$，链接起来写到输出 buffer
  #fig("/public/assets/Courses/DB/img-2024-06-18-14-02-59.png",width:50%)
  - 需要满足 $ceil(b_s \/ M) + 1 < n_h < M - 1$
    - 后者的要求来自于*分块时*需要 $n_h$ 个缓冲块，如果不够那分都分不了；前者的要求来自 $s$ 根据 $h()$ *分块后*能够放进内存（$+1$ 留给 buffer）
    - 如果不满足怎么办？多按照右边的限制多次哈希，直到满足左边的限制，即使用 Recursive partitioning
    - 一般最后一级的哈希函数是 $n_h = ceil(b_s \/ M)*f$，$f$ 为修正因子
    - 不需要递归切分时，近似来说就是 $M > sqrt(b_s)$（*重要*）
  - cost of hash-join
    - If recursive partitioning not needed
      - block transfer: $3(b_r+b_s)+4n_h$
          - partition: 读 $b_r+b_s$ blocks，写 $(b_r+b_s)+2n_h$ blocks
          - join: 读 $(b_r+b_s)+2n_h$，不考虑写
          - $n_h$ 是额外加的可能超出 buffer 大小的情况
      - seeks: $2(ceil(b_r/b_b)+ceil(b_s/b_b)) + 2n_h$
        - $b_b$ 怎么算？$b_b$ 个 input buffer 加上 $n_h times b_b$ 个 output buffer，合一起等于 $M$
        - $b_b=floor(M\/(n_h+1))$（应该是这样算）
    - If recursive partitioning needed
      - 需要 $ceil(log_(floor(M\/b_b)-1) (b_s\/M))$ 轮 partition
      -  partition $=2(b_r+b_s) ceil(log_(floor(M\/b_b)-1)(b_s\/M))+b_r+b_s$
      -  seek $=2(ceil(b_r\/b_b)+ceil(b_s\/b_b))ceil(log_(floor(M\/b_b)-1)(b_s\/M))$
    - 如果所有东西都能放进主存里，则$n_h=0$ 并且不需要 partition（只需 in-memory 的哈希操作），即 cost $=b_r+b_s$
- 其它操作：Aggregation, Set Operations, Outer Join
  - Set Operation 用 hash join 的思想举一反三
- Evaluation of Expression 表达式求值
  - *Materialization* 实体化
    - 依次进行表达式的计算，构建前缀树递归进行
  - Pipelining 流水线，同时评估多个操作
    - evaluate several operations simultaneously , passing the results of one operation on to the next.

#note[
  做题时的几个注意点：
  + external merge sort 的 seek 次数是两倍归并段的总数，读一次写一次，虽然我感觉读和写不用分开（磁盘头停在原地不就好了？）。。。
  + ……
]

== 查询优化 Query Optimization
- 两种查询优化的办法
  - 找到等价的查询效率最高的关系代数表达式
  - 指定详细的策略来处理查询

=== 等价关系代数表达式
- Equivalent Expressions 等价的关系代数表达式
  - *evaluation plan*：类似于算术表达式的前缀树，表示了每步操作进行的过程
  - Cost-based optimization，基于 cost 的优化
    - 基本步骤
      - 用运算法则找到逻辑上等价的表达式
      - 注释结果表达式来获得查询计划
      - 选择cost最低的表达式
    - cost 的估算基于
      - 统计信息量的大小，比如 tuples 的数量，一个属性不同取值的个数
      - 中间结果的数量，用于复杂表达式的优化
      - 算法的消耗
    - 通过 `explain <query>` 可以查看到底被处理成了什么样

==== *等价表达式的规则*
+ 合取选择和选两次等价：$sigma_(theta_1 and theta_2)(E)= sigma_theta_1( sigma_theta_2(E))$
+ 选择两次的顺序可以交换；$sigma_theta_1(sigma_theta_2(E))= sigma_theta_2( sigma_theta_1(E))$
+ 嵌套的投影只需要看最外层的：$Pi_L_1(Pi_L_2(dots(E)))= Pi_L_1(E)$
+ 选择和笛卡尔积可以变成 theta join：$sigma_theta (E_1 times E_2)=E_1 join_theta E_2$
  - 两步 theta join 可以合并：$sigma_theta_1(E_1 join_theta_2 E_2)=E_1 join_(theta_1 and theta_2)E_2$
+ Theta-join 和自然连接可以改变顺序：$E_1 join_theta E_2=E_2 join_theta E_1$
+ 自然连接满足结合律：$(E_1 join E_2) join E_3=E_1 join (E_2 join E_3)$
  - Theta-join 的结合规则：$(E_1 join_theta_1 E_2) join_(theta_2 and theta_3) E_3=E_1 join_(theta_1 and theta_3) (E_2 join_theta_2 E_3)$，这里 $theta_2$ 只牵涉到 $E_2, E_3$ 中的属性
+ 选择操作和 Theta-join 的混合运算
  - 当$ theta_1$ 中的属性都只出现在E1中的时候：$ sigma_theta_1(E_1 join_theta_2 E_2)= sigma_theta_1 (E_1) join_theta_2 E_2$
  - 当$ theta_1, theta_2$ 分别只包含E1,E2中的属性时：$ sigma_(theta_1 and theta_2)(E_1 join_theta E_2)= sigma_theta_1(E_1) join sigma_theta_2(E_2)$
+ 投影操作和 Theta-join 的混合运算
  - 当 $theta$ 只包含$L_1 or L_2$ 中的属性的时候：$ Pi_(L_1 or L_2)(E_1 join_theta E_2)=(Pi_L_1(E_1)) join_theta (Pi_L_2 (E_2))$
  - 当 ?
9. & 10. 集合运算中的交运算和并运算满足交换律和结合律
11. 选择操作中有集合的运算时满足分配律(比如进行差运算再选择等价于分别选择再差运算)
12. 投影操作中有并运算时满足分配律
- ...... 很琐碎，应该不用掌握
- Join的顺序优化：当有若干张表需要join的时候，*先从join后数据量最小的开始*，后面还有一种基于动态规划的方法

- 可以通过共享相同的子表达式来减少表达式转化时的空间消耗，通过动态规划来减少时间消耗

=== cost 的估计
- 忽略 IO 的每个操作的估计
- 基本的变量定义
  - $n_r$ 表示关系 $r$ 中元组的数量(也就是关系 $r$ 的 size)
  - $b_r$ 包含 $r$ 中元组需要的 block 数量
  - $l_r$ $~~r$ 中一个元组的 size
  - $f_r$ block factor of $r$ 比如可以选取一个 block 能容纳的 $r$ 中元组的平均数量
  - $V(A, r)$ 关系 $r$ 中属性 $A$ 可能取到的不同的值的数量，$=>$ Histograms
  - 当关系 $r$ 中的元组都存储在一个文件中的时候 $b_r= ceil(n_r \/ f_r)$
- 选择的估计
  - 单属性选择
    - 从 $r$ 中选择 $A$ 属性 $=x$ 的$"size" = n_r / V(A,r)$
    - 选择 $A$ 属性小于 $x$ 的 size
      - $"size"=0$ if $x < min(A,r)$
      - $"size"=n_r times (x-min(A,r)) / (max(A,r)-min(A,r))$
      - 如果缺少统计信息，我们假定 $"size"= n_r/2$
      - 选择 $A$ 属性大于 $x$，和上面的表达式是对称的
  - complex selection 多重选择
    - 假设$s_i$是满足条件$ theta_i$的元组的个数，假设*独立分布*
    - conjunction $"size"=n_r times (s_1 times s_2 times … times s_n)/n_r^n$
    - disjunction $"size"=n_r times (1-(1- s_1/n_r) times dots times (1- s_n /n_r))$
    - negation $"size"=n_r-"size"(sigma_theta (r))$
- join 的估计
  - 笛卡尔积的情况下，关系 $R,S$ 的 join 最终元组的个数为 $n_r times n_s$
  - 如果 $R sect S$ 为空，则自然连接的结果和笛卡尔积的结果相同
  - 如果非空，且 $R sect S$ 是 $R$ 的 key，则 $R,S$ 的自然连接结果中的元组个数不会超过 $n_s$
  - 如果 $R sect S$ 的结果是 $S$ 到 $R$ 的外键，则最后的元组数为 $n_s$，反之对称
  - 一般情况，$R sect S={A}$不是键，自然连接的结果 size 估计值为$(n_r times n_s)/(max(V(A,r),V(A,s)))$
- 其他操作的估计
  - 投影（合并）的 $"size"=V(A,r)$
  - 聚合操作的 $"size"=V(A,r)$
  - 集合操作：*并*估计为相加，*交*估计为取最小，*差*估计为取前者
  - 外部连接（上界估计）：
    - 左外连接的 $"size" =  "自然连接的size" + r "的size"$
    - 右外连接的 $"size" =  "自然连接的size" + s "的size"$
    - 全连接的 $"size" =  "自然连接的size" + r "的size" + s "的size"$
- 不同值（distinct）个数的估计
  - 选择，估计 $V(A, sigma_theta (r))$
    - 如果 $theta$ 强制要求接受一个值或一组值……
    - 如果能算出中选率：$V(A, sigma_theta (r))=V(A,r) times "中选率"$
    - 否则，$V(A, sigma_theta (r))=min(V(A,r), n_(sigma_theta (r)))$
  - join 的估计，$V(A, r join s)$
    - 如果 $A$ 的所有取值都来自 $r$，那么 $V(A,r join s)=min(V(A,r), n_(r join s))$
    - 否则，如果 $A$ 包含 $r$ 中的 $A_1$ 和 $s$ 中的 $A_2$，$ V(A, r join s) = min(V(A_1,r) * V(A_2-A_1,s), V(A_1-A_2,r) * V(A_2,s), n_(r join s)) $
- 基于 cost 的 join 顺序优化
  - $n$ 个关系进行自然连接有$(2n-2)!/(n-1)!$种不同的join顺序
  - 找到最合适的 join-tree 的办法：递归地尝试，动态规划+局部搜索的办法，时间复杂度 $O(n^3)$，空间复杂度 $O(2^n)$
  - Left Deep Join Trees 左倾树，当结合方式只考虑左倾树的时候，找到最优解的时间复杂度是 $O(n 2^n)$，$2^n$
- *Heuristic Optimization* 启发式优化
  - 尽早进行 selection
  - 尽早进行 projection
  - 选择最严格的 selection 和 operations 操作（选出来的比例越少越好）
- 用于查询优化的结构
  - pipelined evaluation plan
  - optimization cost budget
  - plan catching

=== Additional Optimization Techniques\*\*
- Nested Subqueries
- Materialized Views
- 略

= 第五部分：事务处理
- 这一部分感觉和操作系统关系比较密切
== 事务和并发控制
=== 基本的概念
- 事务的概念
  - 事务时程序执行的基本单位，会引起一些数据项的更新，需要解决的两个问题：
    - 数据库系统的硬件问题和系统崩溃导致的失败
    - 多事务的并行执行
  - 事务开始和结束的时候数据库都必须是 consistent 的
  - 事务的四个性质 ACID：
    - 事务的原子性 *Atomicity*
      - 事务中的所有步骤只能完全执行(commit)或者回滚(rollback)
    - 事务的一致性 *Consistency*
      - 单独执行事务可以保持数据库的一致性
    - 事务的隔离性 *Isolation*
      - 事务在并行执行的时候不能感知到其他事务正在执行，执行中间结果对于其他并发执行的事务是隐藏的
    - 事务的持久性 *Durability*
      - 更新之后哪怕软硬件出了问题，更新的数据也必须存在
- 一个简单的事务模型，只包含 read, write 两个操作
  #fig("/public/assets/Courses/DB/img-2024-05-20-13-35-30.png")
- 事务的状态
  - active 初始状态，执行中的事务都处于这个状态
  - partially committed 在最后一句指令被执行之后
  - failed 在发现执行失败之后
  - aborted 回滚结束，会选择是*重新执行事务*还是结束
  - committed 事务被完整的执行
#diagram(
  node((0,0), [active]),
  edge(),
  node((1,-0.5), [partially committed]),
  edge(),
  node((2,-0.5), [committed]),
  edge((0,0),(1,0.5)),
  node((1,0.5), [failed]),
  edge(),
  node((2,0.5), [aborted]),
  edge((1,-0.5),(1,0.5)),
)

=== 事务的并发执行
- 并发执行的*好处*，可以提高运行的效率，减少平均执行时间
- 并发执行的*异常*，丢失修改(Lost Update)，读脏数据(Dirty Read)，不可重复读(Unrepeatable Read)，幽灵问题(Phantom Problem)
- 并发控制处理机制：让并发的事务独立进行，控制并发事务之间的交流
- Schedules 调度
  - 一系列用于指定并发事务的执行顺序的指令
    - 需要包含事务中的所有指令，需要保证单个事务中的指令的相对顺序（常识）
  - 事务的最后一步
    - 成功执行，最后一步是 commit instruction；执行失败，最后一步是 abort instruction
  - serial schedule 串行调度：一个事务调度完成之后再进行下一个
  - equivalent schedule 等价调度：改变处理的顺序但是和原来等价
- *Serializability*可串行化
  - 基本假设：事务不会破坏数据库的一致性，只考虑读写两种操作

==== 冲突可串行化调度 conflict serializable schedules
- 两个事务是冲突的，当它们含有*冲突的操作*：
  + 来自两个不同的事务
  + 对同一个对象操作
  + 两个 operations 至少有一个是 write 操作
- 冲突等价(*conflict equivalent*)：两个调度可以通过改变一些不冲突指令来转换
- 冲突可串行化：当且仅当一个调度$S$可以和一个串行调度等价
- *Precedence graph* 前驱图
  - 图中的顶点是各个事务，当事务$T_i, T_j$ 的某两个操作冲突并且 $T_i$ 先访问出现冲突的数据的时候，就画一条边$T_i -> T_j$
  - 一个调度是*冲突可串行化*的当且仅当前驱图是*无环图*
  - 对于无环图，可以使用*拓扑排序*获得一个合适的执行顺序
#fig("/public/assets/Courses/DB/img-2024-05-20-14-36-37.png")

==== 视图可串行化调度 view serializability schedules
- 事务之间读到和写回的数据是一样的（对数据）
  - 由事务 $T$ 最先读到的数据依旧是 $T$ 最先读到
  - 事务 $T'$ 产生的数据由事务 $T$ 最先读到，则依旧是 $T$ 最先读到
  - 由事务 $T$ 最后写回的数据依旧是 $T$ 最后写回
#fig("/public/assets/Courses/DB/img-2024-05-20-14-44-19.png")
- 冲突可串行化的调度一定是视图可串行化的，反之不一定
  - 比如下图，与 $T_27 -> T_28 -> T_29$ 视图等价，但是不冲突等价
#fig("/public/assets/Courses/DB/img-2024-05-20-14-48-03.png")
- 其判定似乎不要求(?)，也是画一个前驱图

#v(1em)
- 此外还有其它评价方式的 serializability（不是三好学生、五好学生，也可以是好学生）

==== 可恢复调度 Recoverable Schedules
  - 如果一个事务 $T_1$ 要读取某一部分数据，而 $T_2$ 要写入同一部分的数据，则 $T_1$ 必须在 $T_2$ commit 之前就 commit，否则就会造成 dirty read
  - 如下图，如果 $T_8$ fails，$T_9$ 读到的数据将 inconsistent
  #fig("/public/assets/Courses/DB/img-2024-05-20-15-09-24.png")
- *Cascading Rollbacks* 级联回滚
  - 单个事务的 fail 造成了一系列的事务回滚
  - 如下图，如果 $T_10$ fails，$T_11, T_12$ 必须也要 roll back
  #fig("/public/assets/Courses/DB/img-2024-05-20-15-08-29.png")
- *Cascadeless Schedules* 避免级联回滚的调度
  - 对于每一组事务 $a$ 和 $b$ 并且 $b$ 需要读入一个 $a$ 写入的数据，那么 $a$ 必须在 $b$ 的读操作开始之前 commit
  - *Cascadeless Schedules* 属于可恢复的调度的一种
- Transaction Isolation Levels
  - 有时候我们会放低要求来换取性能(trade-off)
#tbl(
  columns: 7,
  [事务\ 隔离级别],[描述],[脏读],[不可\ 重复读],[丢失\ 修改],[幻读],[锁持续时间],
  [Read\ Uncommitted],[一个事务会读到另一个*未提交*事务修改过的数据。],[是],[是],[是],[是],[当前事务],
  [Read\ Committed],[如果数据被另一个事务修改，只有它提交后才能读取],[否],[是],[是],[是],[当前事务],
  [Repeatable\ Read],[如果数据被另一个事务修改，只有它提交后才能读取；且该事务读过某条记录后，在提交之前，其它事务均不能够改动或删除当前事务已读取的数据。],[否],[否],[否],[是],[该事务\ 提交前],
  [Serializable],[可重复读仅仅是说，不可以改动和删除，但没说不能再往这个范围内插入数据。即引入范围锁],[否],[否],[否],[否],[该事务\ 提交前]
)
- 这个 Serializable 可串行化隔离级别似乎和冲突可串行化、视图可串行化等不是一回事。

=== Concurrency Control 并发控制
- 有三种并发控制协议
  + Lock-Based Protocols
  + \* Timestamp-Based Protocols
  + \* Validation-Based Protocols

==== Lock-Based Protocols 基于锁的协议
- lock 是一种控制并发访问同一数据项的机制，分为两种 lock mode
  + exclusive(X)：表示数据项可以读和写，用 lock-X 表示
  + shared(S)：表示数据项只能读，用 lock-S 表示
- 两个事务的冲突矩阵：
  #tbl(
    columns: 3,
    [],[S],[X],
    [S],[true],[false],
    [X],[false],[false]
  )
  - 如果请求的锁与其他事务对这个数据项已有的锁不冲突，那么可以给该事务批准该锁
  - 对于一个数据项，可以有任意多的事务持有 S 锁，但是如果有一个事务持有 X 锁，其他的事务都不可以持有这个数据项的锁
  - 如果一个锁没有被批准，就会产生一个请求事务，等到所有冲突的锁被 release 之后再申请
- 锁协议中的特殊情况
  - dead lock 死锁：两个事务中的锁互相等待造成事务无法执行，比如事务 $2$ 的锁需要事务 $1$ 先 release，但是事务 $1$ 的 release 步骤在事务 $2$ 的申请锁后面，就会造成事务 $1,2$ 的死锁
  - Starvation 饥荒：一个事务在等一个数据项的Xlock，一群别的事务在等他release，造成饥荒
==== Two-Parse Locking Protocol 两阶段锁协议
- 两个阶段 growing 和 shrinking，growing 只接受锁而不释放，shrinking 反之。简单来说，就是：*每个事务放锁后就不再加锁*
#fig("/public/assets/Courses/DB/img-2024-05-27-13-28-47.png")
- 二阶段锁协议确保冲突可串行化的调度（思考其证明），并且按照每个事务的 lock point 排序就是一个合法的串行调度
- 无法确保可恢复（可能级联回滚），为此添加扩展（并且也无法避免死锁问题）
  - *strict two-phase locking*
    - 每个事务都要保持所有的exclusive锁直到该事务结束
    - 为了解决级联回滚的问题
  - *Rigorous two-phase locking*
    - 所有的锁必须保持到事务commit或者abort
- 两阶段锁协议是可串行化的充分但非必要条件
  - 如，按照右图每个事务的 lock point 判断，不是可串行调度，但实际上是可串行的
  #grid(columns: 2, fig("/public/assets/Courses/DB/img-2024-05-27-13-46-36.png"), fig("/public/assets/Courses/DB/img-2024-05-27-13-51-20.png"))
==== 锁的实现与转换
- Lock Conversions锁转换：提供了一种将S锁升级为X锁的机制
  - 两个阶段
    - 第一个阶段可以设置 S 和 X 锁，也可以升级 S 锁
    - 第二个阶段可以释放 S 和 X 锁，也可以降级 X 锁
    - 所有的锁在事务 commit 或者 abort 之后再被释放
  - 事务不需要显式调用锁的请求，比如 read 和 write 的执行过程如下
  ```c
  // read operation
  if Ti has a lock on D
    then read(D)
  else
    begin
      if necessary wait until no other transaction has a lock-X on D
        grant Ti a lock-S on D;
      read(D)
    end
  ```
  ```c
  // write operation
  if Ti has a lock-X on D
    then write(D)
  else
    begin
      if necessary wait until no other trans. has any lock on D,
        if Ti has a lock-S on D
          then upgrade lock on D  to lock-X
        else
          grant Ti a lock-X on D
          write(D)
    end;
  ```
- 锁的实现：Lock Manager 可以被作为一个独立的进程来接收事务发出的锁和解锁请求
  - Lock Manager 会回复申请锁的请求，发出请求的事务会等待请求被回复再继续处理
  - lock manager 维护一个内存中的数据结构 lock-table 来记录已经发出的批准
  #grid(columns: (1fr, 0.7fr),
    [
      - Lock table 是一个 *in-memory 的 hash 表*
      - 通过被上锁的数据项作为索引，蓝框代表上锁，而白框表示在等待
      - 新的上锁请求被放在队列的末端，并且在和其他锁兼容的时候会被授权上锁
      - 解锁的请求会删除之前对应的上锁请求，并且检查后面的请求是否可以被授权
      - 如果一个事务 aborts 了，所有该事务的请求都会被删除
      - lock-manager 会维护一个记录每个事务上锁情况的表来提高操作的效率
    ],
    fig("/public/assets/Courses/DB/img-2024-05-27-14-07-16.png")
  )
==== Deadlock prevention protocols 死锁保护协议
- 死锁保护协议，保证系统不会困于死锁
- 两阶段封锁协议无法避免死锁
  #fig("/public/assets/Courses/DB/img-2024-05-27-14-12-00.png",width: 50%)
- Deadlock Handling，一种想法是预防死锁，一种想法是死锁发生后检测并处理
  - *Deadlock Prevention* 死锁预防
    - predeclaration 执行之前先检查会不会出现死锁，保证一个事务开始执行之前对涉及到的所有的数据项都上锁（要么不锁，要么一下全锁上）
    - graph-based protocol：使用偏序来确定数据项上锁的顺序。例如，上图中我们规定先 $X$ 后 $Y$，那么事务 $T_2$ 就必须先申请 $X$ 的锁（后 $Y$ 的锁）而无法开始，从而避免死锁。
      - 一个例子是 Tree-Protocol，它完全不同于两阶段锁协议，只使用 exclusive locks；任何时候都可以释放锁；任何数据项只能被上锁解锁一次；非 first lock 的加锁要求其祖先已经被锁上
        - Advantages: 确保冲突可串行化；避免死锁；并且相对两阶段锁协议释放锁更早
        - Disadvantages: 不确保可恢复性；可能会比需要的申请了更多的锁
  - *Timeout-Based Schemes* 超时机制
    - 只等待一段时间，过了时间就直接回滚（直接视为失败）；容易实现，但是会导致starvation
  - *Deadlock Detection* 死锁检测
    - wait-for 图: 所有的事务表示图中的节点，如果事务 $i$ 需要 $j$ 释放一个 data item，则图中画一条 $i$ 到 $j$ 的有向边，如果图中有环，说明系统存在死锁（跟前驱图很相似）
    - lock manager 定期生成一个 wait-for 图来检测。选择其中一个事务(victim)杀掉（释放它的所有锁并回滚）以解决死锁
  - *Deadlock Recovery* 死锁恢复
    - total rollback 将事务 abort 之后重启
    - partial rollback 不直接 abort 而是仅回滚到能解除死锁的状态
- 同一个事务经常发生死锁会导致starvation，因此避免starvation的过程中cost要考虑回滚的次数

==== Multiple Granularity 多粒度
- 数据项具有不同的大小，并定义数据粒度的层次结构，其中小粒度嵌套在大粒度中。我们可以对不同粒度的数据项加锁解锁。
- 可以用树形结构来表示
#fig("/public/assets/Courses/DB/img-2024-05-27-15-09-02.png")
- 锁的粒度 (level in tree where locking is done)
  - fine granularity(lower in tree)细粒度，高并发，高开销
  - coarse granularity(higher in tree)粗粒度，低并发，低开销
  - 高至整个DB，低至区域，文件和记录（甚至对一个谓词，对一个值）
- 扩展的Lock Modes
  - *intention-shared* (IS): 想要对更低层加 S 锁
  - *intention-exclusive* (IX): 想要对更低层加 X 锁
  - *shared and intention-exclusive* (SIX): 对这一层加 S 锁，想要对更低层加 X 锁（比如对整个表加共享锁，对其中某一行加排它锁）
  - 冲突矩阵如下
#let tbl_false = [#text(fill: red, "false")]
  #tbl(columns: 6,
    fill: (x,y) => if y == 0 or x == 0  {rgb(202, 237, 250)},
    [],[IS],[IX],[S],[SIX],[X],
    [IS],[true],[true],[true],[true],tbl_false,
    [IX],[true],[true],tbl_false,tbl_false,tbl_false,
    [S],[true],tbl_false,[true],tbl_false,tbl_false,
    [SIX],[true],tbl_false,tbl_false,tbl_false,tbl_false,
    [X],tbl_false,tbl_false,tbl_false,tbl_false,tbl_false,
  )
==== Insert and Delete Operations
- handling phantom phenomenon
- Index Locking Protocol 来防止幻读
- Next-Key Locking 来防止幻读
- 略

==== Multiversion Concurrency Control Schemes（不考）
- 有点引入时间戳的感觉（？）
- 多版本并发控制
- 多版本的两阶段封锁协议
- 略

=== \* Validation-Based Protocols 验证协议
- sjl 老师讨论区题目，不要求掌握
- 基于验证的协议，属于 Optimistic Concurrency Control，适用于读多写少的情况
- 每个事务 $T_i$ 被分为 $2$ 或 $3$ 个阶段和三个时间点：
  - $"ReadTS"(T_i)$ 时间点，标志事务 $T_i$ 开始
  1. Read Phase 读阶段：事务 $T_i$ 读取所有的数据项并存在本地变量；同时也执行写操作，但只写在本地
  - $"ValidationTS"(T_i)$ 时间点，标志事务 $T_i$ 结束读阶段并进入验证阶段
  2. Validation Phase 验证阶段：事务 $T_i$ 根据所有 $"ValidationTS"(T_j)$ 小于 $"ValidationTS"(T_i)$ 的事务进行合法性测试
  3. Write Phase 写阶段：事务 $T_i$ 把本地写好的数据复制到数据库中。只读事务可跳过
  - $"FinishTS"(T_i)$ 时间点，标志事务 $T_i$ 结束
- 具体而言，$T_i$ validation test 通过，需要对上述每个 $T_j$ 满足以下两个条件之一
  - $"FinishTS"(T_j) < "StartTS"(T_i)$，这很显然不会发生冲突
  - $"StartTS"(T_i) > "FinishTS"(T_j) < "ValidationTS"(T_i)$，并且 $T_j$ 的写操作与 $T_i$ 的读操作不相交
- 基于锁和时间戳的并发控制是悲观的，因为它们探测到冲突时总是让事务等待或回滚，即使它们可能是冲突可串行化的（优先假设冲突）；而基于验证的并发控制总是让事务先执行，等到验证后发现会冲突才回滚（优先假设不冲突）

#v(1em)
- 总结
#tbl(
  columns: 4,
  table.cell(rowspan: 2)[协议],table.cell(colspan: 3)[是否能避免问题（空着为不知道）],
  [冲突可串行],[可恢复性],[死锁],
  [2PL],[可],[否],[否],
  [Strict 2PL],[可],[可],[否],
  [Rigorous 2PL],[可],[可],[否],
  [Graph-based Protocol],[],[],[可],
  [Tree-Protocol],[可],[否],[可],
)

== Recovery System 事务恢复
- 故障的分类
  - Transaction failure 事务错误：包含逻辑错误和系统错误，死锁属于后者
  - System crash 系统崩溃导致的故障(磁盘没出事)
  - Disk failure 磁盘中的问题导致磁盘存储被销毁
  #fig("/public/assets/Courses/DB/img-2024-06-03-13-29-21.png")
- 存储结构
  - Volatile storage 易失存储
  - Nonvolatile storage 非易失存储
  - Stable storage 稳定存储，实际上并不存在，但可以用 multiple copies 近似实现
- 恢复算法
  + 在普通事务处理中要保证有足够的信息保证可以从故障中恢复（恢复准备）
  + 在故障发生之后要保持数据库的 consistency，事务的 atomicity 和 durability
  - 恢复算法需要满足 idempotent 幂等性，即如果恢复过程中又故障了，或者恢复恢复过程中的故障……最终的结果都是一样的
// - Data Access 数据访问回顾
//   - 物理block是磁盘上的区分
//   - 缓冲block是在主存中的block
//   - 磁盘和主存之间的数据移动依赖input和output操作
//   - 每个事务$T_i$ 在内存中有自己的work-area，并且拷贝了一份该事务要用到的全部数据
//   - 事务通过read和write操作把数据在自己的工作区域和buffer blocks区间之间进行传递
- 如何在事务failure的情况下仍然保证原子性
  - 先把数据存储在磁盘上，而不是直接存到数据库中
  - 然后在提交点对数据库进行修改，如果发生错误就立马回滚
    - 但这个方法效率太低了，事实上没有被采用

=== log-based Recovery 基于日志的恢复
- 日志(log)被存储在 stable storage 中，包含一系列的日志记录
  - 事务开始 `<T start>`
  - 写操作之前之前的日志记录 `<Ti,X,V1,V2>`，X 是写的位置，V1，V2 分别是写之前和之后的 X 处的值
  - 事务结束的时候写入 `<Ti commit>`
  - $T_i$ 需要 undone，当 log 包含 `<Ti start>` 而不包含 `<Ti commit>` or `Ti abort`
  #fig("/public/assets/Courses/DB/img-2024-06-03-13-47-38.png")
- 更新事务导致的不一致性
  - 新的数据在提交的时候不一定是安全的：错误发生时难以保护改变后的值不变
  - 旧的数据在提交之前不一定是安全的：在 commit 之前发生错误将无法回滚到原来的值
  - 对于更新事务的两条规则
    - commit rule：新的数据在 commit 之前必须被写在*非易失性*的存储器中
    - logging rule：旧的值在新的写入之前需要被写在日志里
  - 日志中写入 commit 的时候视为一个事务被提交了，但此时 buffer 中可能还在进行 write 操作，因为 log 的写入先于操作
- 两种思路：
  - *deferred database modification* 延迟数据库更新：先把所有的更新写在日志里，在写入 commit 之后再开始写入数据库
    - 假设事务是串行执行的
    - 事务开始的时候要写入`<Ti start>`
    -  *write*(*X*) 操作对应的日志是 `<Ti, X, V>` ，V表示X新的值
    - 事务 partially commits 的时候需要写入 commit
    - 然后根据日志来实际执行一些 write 的操作
      - 当错误发生时，当且仅当日志中 start 和 commit 都有的时候，事务需要 redo
  - *immediate database modification* 直接修改数据库
    - 先要写好日志记录，假设日志记录直接 output 到稳定的存储中
    - block 的输出可以发生在任何时间点，包括事务 commit 前和 commit 后，block 输出的顺序和 write 的顺序不一定相同
    - 恢复的过程中有两种操作
      - undo：撤回，将事务$T_i$ 中已经更新的值变回原本的值
        - undo 的条件：日志中包含这个事务的 start 而不包含 commit，即事务进行到一半中断了
      - redo：从事务 $T_i$ 的第一步开始重新做，将所有值设定为新的值
        - redo 的条件：日志中包含这个事务的 start 和 commit
      - 两种操作都需要 *idempotent* —— 也就是操作执行多次和执行一次的效果相同
  - 我们采用第二种
- 并行控制和恢复
  - 所有事务共用一个日志和 disk buffer
  - 基本的假设（由锁机制实现）
    - 如果一个事务改变了某个数据项，其他的事务直到这个事务 commit 或者 abort 之前都不能改变这个数据项的值
    - 没有 commite 的事务引起的更新不能被其他事务更新
  - 日志中不同事务的日志可能会相交
- check point
  - 通过定期执行 checkpoint 操作来完成简化的恢复
    1. 将内存中的记录都写到 stable storage 中（先写日志原则）
    2. 将所有更改过的 block 写入磁盘中（脏页面写入，保证这之前的事务都写入）
    3. 写入日志记录< *checkpoint* $L...$> ，其中 L 是在 checkpoint 时依然处于进行状态的事务
  - 通过checkpoint，在日志处理的时候就不需要处理所有的日志，只需要关注异常时正在活跃的事务，恢复的步骤如下
    - 从日志的末尾向前扫描，直到发现最近的checkpoint记录
    - 只有L中记录的，或者在L之后发生的事务需要redo或者undo
    - checkpoint之前的记录已经生效并保存在了稳定的存储中
  - 日志中更早的部分*或许需要*undo，但一定不需要redo
    - 继续向前扫描直到发现一个事务的start日志
    - 最早的start之前的日志不需要进行恢复操作，并且可以清除
  - 单个事务回滚时的基本操作
    - 从后往前扫描，当发现记录 $<T_i,X_i,V_1,V_2>$ 的时候
    - 将 X 的值修改为原本的值
    - 在日志的末尾写入记录 $<T_i,X_i,V_1>$
    - 发现 start 记录的时候，停止扫描并在日志中写入 abort 记录
- 普通恢复算法
  - 从后往前找到第一个 checkpoint 记录，然后开始 redo
  - redo 需要先找到最后一个 check point 并且设置 undo-list
    1. 从 checkpoint 开始往下读
    2. 当发现修改值的记录的时候，redo 一次将 X 设置为新的值
    3. 当发现 start 的时候将这个事务加入 undo-list
    4. 当发现 commit 或者 abort 的时候将对应的事务从 undo-list 中移除
  - undo
    1. 从日志的末尾开始往回读
    2. 当发现记录 $<T_i, X_j, V_1, V_2>$ 并且 Ti 在 undo-list 中的时候，进行一次回滚
    3. 当发现 Ti start 并且 Ti 在 undo-list 中的时候，写入 abort 日志并且从undo-list 中移除 Ti
    4. 当 undo-list 空了的时候停止 undo
  - 在下面这个图中 $T_1,T_3$ ignored，$T_2$ 需要 redo，$T_4$ undo
  #fig("/public/assets/Courses/DB/img-2024-06-03-14-00-21.png")
- log record buffering 缓冲日志记录
  - 日志记录一开始在主存的缓冲区中，当日志在 block 中满了的时候或者进行了 log force 操作(上面提到的 checkpoint)时写入稳定的存储中
  - 需要遵守的规则
    - 写入稳定存储中的时候日志记录按照原本的顺序写入
      - 在 commit 记录被写入稳定存储的时候，$T_i$ 才算进入 commit 状态
    - WAL(write-ahead logging)规则：在数据 block 写入数据库之前，必须先把日志写入稳定的存储中
    - group commit 策略
    #fig("/public/assets/Courses/DB/img-2024-06-03-14-17-12.png")
  - 中间有几页先留着慢慢学习，这几页看起来不太像考试内容，buffer 这一部分应该了解就好
- Fuzzy Checkpoint 策略
  - 为了避免 checkpoint 时 I/O 过于密集，可以采用 fuzzy checkpoint 策略
  + Temporarily stop all updates by transactions
  + Write a <*checkpoint* *L*> log record and force log to stable storage
  + Note list M of modified buffer blocks
  + Now permit transactions to proceed with their actions
  + Output to disk all modified buffer blocks in list M
    - blocks should not be updated while being output
    - Follow WAL: all log records pertaining to a block must be output before the block is output
  + Store a pointer to the *checkpoint* record in a fixed position *last_checkpoint* on disk
    - Check point 现在是一个过程，而不是一个点，但仍需要一个点来记录，也就是 disk 中的 last_checkpoint
  #fig("/public/assets/Courses/DB/img-2024-06-03-14-25-47.png")

=== Recovery with Early Lock Release and Logical Undo Operations
- 逻辑 Undo，比如 `A+=10` 已经被执行了，而且过了一段时间（没有办法 physical undo 了），之后又要 undo 这个操作怎么办？
  - 只需采用 logical undo，再执行一个 `A-=10` 即可
  - 注意 logical undo 并不适用于所有情况，比如不满足交换律的操作
  - 这种方法允许提早释放 lock，不一定要在 commit 或 abort 时释放
  - 如果发生了 abort(normal process)
  #fig("/public/assets/Courses/DB/img-2024-06-03-14-48-20.png")
  - 如果发生了 crash
    - 这里的 checkpoint 不是 fuzzy 的（为了简单）
  #fig("/public/assets/Courses/DB/img-2024-06-03-14-56-51.png")

=== ARIES Recovery Algorithm —— Aries 恢复算法
- 这部分考试常考，但上课讲得又快又不清楚
- 这篇文章写得挺好，但似乎有点超出我们的要求 #link("https://blog.csdn.net/yanglingwell/article/details/131484407")[万字长文解析最常见的数据库恢复算法: ARIES - CSDN博客]

==== 和普通恢复算法的区别
- ARIES is a state-of-the-art
- 使用 LSN(log sequence number)来标注日志
  - 把 LSN 存到每个 page 来标注哪些日志对应的操作已经被写到 disk 中
- physiologically redo（使用物理逻辑日志的 redo）
- 使用脏页表(dirty page table) 来避免不必要的 redo
- fuzzy checkpoint 机制
- ARIES supports *partial rollback*

==== ARIES 中的数据结构
- Log sequence number (LSN)
  - 用于标识*每一条日志记录*，需要是线性增长的
  - 其实是一个 offset，方便从文件的起点开始访问
- Page LSN 每个 Page 的 LSN
  - 是每一页中对该页*起作用的最后一条*日志记录的 LSN 编号
  - 在 update page 时：申请 X-lock，写入日志，更新 page（包括把 Page LSN 更新为日志的 LSN），释放 X-lock
  - 在 flush page（写入磁盘）时：首先申请 S-lock（避免写操作申请 X-lock？）
  -  在 recovery 的 undo 阶段，LSN 值不超过 PageLSN 的日志记录将*不会在该页上执行*，因为其动作已经在该页上了
  - 可以避免重复的 redo $=>$ idempotence
- log record 日志记录
  - 每一条日志记录包含自己的 LSN 和*同一个事务中前一步操作*的 LSN —— PreLSN
  - CLR(compensation log record)：补偿事务记录，在恢复期间不需要 undo，是 redo-only 的日志记录
    - 它起到的作用类似于之前恢复算法中的 operation-abort
    - 有一个 UndoNextLSN 区域用于记录下一个（更早,往前搜索）的需要 undo 的记录
    - 如果当前日志不是 CLR 日志，则下一个待 UNDO 的日志为当前日志的 PrevLSN；如果当前日志是 CLR 日志，则下一个待 UNDO 的日志为当前日志的 UndoNxtLSN（这将跳过中间已经被 UNDO 的日志）。
    - 【似乎是这样】如下图，我们先 undo 日志 4，这时需要写 CLR 4'，将其 UndoNextLSN 指向 3（即为 4 的 PrevLSN）；假如这个时候掉电了，我们就需要 redo 这个 CLR 4'（相当于 undo 4），它指向的 3 则是需要接着 undo 的日志（也要继续生成 CLR 3'）
    #fig("/public/assets/Courses/DB/img-2024-06-03-17-09-49.png")
#quote()[
#tab 每个日志记录都有一个唯一标识该记录的日志顺序号（LSN）。LSN：由一个文件号以及在该文件中的偏移量组成。

每一页也维护一个叫页日志顺序号（PageLSN）的标识。每当一个更新操作发生在某页上时，该操作将其日志记录的LSN存储在该页的PageLSN域中。在恢复的撤销阶段，LSN值小于或等于PageLSN值的日志记录将不在该页上执行，因为它的动作已经在该页上了。

每个日志记录包含同一事务的前一日志记录的LSN，放在PrevLSN中，使得一个事务可以由后向前提取，而不必读整个日志。事务回滚中会产生一些特殊的redo-only的日志，称为补偿日志记录（Compensation Log Record, CLR)。CLR中还有额外的（？）称为UndoNextLSN的字段，记录下一个需要undo的日志的LSN。
]
- Dirty Page Table 脏页表
  - 存储在缓冲区的，记录已经被更新过的 page 的表
  - 每个 page 包含
    - PageLSN
    - RecLSN(recover LSN)
      - 所有操作该 page 的 log record，如果 LSN 小于它说明已经*被写入磁盘中*了
      - 当 page 被插入脏页表的时候，*初始化为当前的 PageLSN*
      - 会被记录在 checkpoint 中，用于减少 redo 的次数
  - 只要该 page 被写入磁盘，就从脏页表中移除该页
- checkpoint处的日志记录
  - 包含：DirtyPageTable 和 active transactions table
  - 对每一个活跃的事务，记录了 LastLSN，即这个事务在日志中写下的*最后一条记录*
  - 在 checkpoint 的时间点，脏页的信息还没写入磁盘(fuzzy)
- 一个示例图如下，当发生掉电的时候，三个 table 得数据都会丢失，但 log 和 disk 不会
#fig("/public/assets/Courses/DB/img-2024-06-03-15-32-56.png")
#hline()
- ARIES 算法在正常情况下的执行操作和回滚操作（和恢复中的 redo 一样），没讲

==== ARIES 算法的恢复操作
- 分为三个阶段：Analysis 阶段，redo 阶段和 undo 阶段
  - 分析阶段需要得到 undo-list, RedoLSN，以及 crash 时哪些 page 是 dirty 的
  - redo 阶段从 RedoLSN 开始，RecLSN and PageLSNs 用于避免不必要的 redo
  #fig("/public/assets/Courses/DB/img-2024-06-03-15-39-09.png")
  - 或者另一张网上的图
  #fig("/public/assets/Courses/DB/img-2024-06-03-21-01-10.png", width: 70%)
- 分析阶段：
  - 从*最后一条完整的checkpoint日志记录*开始
    + 从 checkpoint 读取脏页表的信息
    + 设置 RedoLSN = min RecLSN in DirtyPageTable，如果脏页表是空的就设置为checkpoint 的 LSN
    + 设置 undo-list 为 checkpoint 中记录的事务，以及读取每个事务最后记录的 LSN
  - 从 checkpoint 开始正向扫描
    - 如果发现了不在 undo-list 中的记录就写入 undo-list
    - 当发现一条*更新记录*的时候，如果这一页*不在脏页表*中，用该记录的 LSN 作为 RecLSN 写入脏页表中（以后的 RedoLSN = min(xxx) 会更大）；如果它在脏页表中，就更新 PageLSN 为更大值
    - 如果发现了标志事务*结束*的日志记录(commit, abort) 就从 undo-list 中*移除*这个事务
    - 持续更新 undo-list 中的每一个事务的最后一条记录 LSN
  - 分析结束之后
    - RedoLSN 决定了从哪里开始 redo
    - DirtyPageTable 中每个 page 的 RecLSN 用于减少 redo
    - 所有 undo-list 中的事务都需要回滚（现在这个 undo-list 实际上就是程序正常执行情况下的，亦即 redo 做完之后的 ATT），同时我们记录了这些事务的最后记录，也即第一个需要 undo 的记录
- Redo 阶段
  - 从 RedoLSN 开始*正向扫描*日志，当发现更新记录的时候
    + 如果这一页不在脏页表中；或者这一条记录的 LSN 小于 DPT 中的 RecLSN 就忽略这一条（已经写入磁盘）
    + 否则从磁盘中读取这一页，如果磁盘中得到的这一页的 PageLSN 比这一条记录的 LSN 小，就 redo，否则也忽略这一条记录
  #quote(caption: " * 为什么某个 Page 的 PageLSN 可能会不小于它在 DPT 的 RecLSN？")[
    因为 PageLSN 记录的是实际 flush 到 Page 的 LSN， 而 RecLSN 记录的是 Checkpoint 恢复的 Dirty Page 信息。由于 Page Flush 和 Checkpoint 的 Flush 完全并行，互不影响，因此可能存在 Checkpoint Flush 之后，再次执行了 Page Flush ，导致恢复的 Checkpoint Dirty Page 信息延迟于实际 Page Flush 的信息。因此实际的 PageLSN 不小于 DPT 的 RecLSN
  ]
- Undo 阶段
  - 从日志末尾向前搜索，undo 所有 undo-list 中有的事务
    - 通过如下操作实现优化，跳过不必要的记录：
      + 用分析阶段“每个事务最后一条记录的 LSN”来找到“每个事务下一个需要 undo 的 LSN”，每次从这些 LSN 里选择一个最大的，把它 undo 掉
      + 在 undo 一条记录之后，如果是 start 日志，把它从 undo-list 删掉；否则更新该事务下一个将要 undo 的 LSN
        - 对于普通的记录，设置为 PrevLSN
        - 对于 CLR 记录，设置为 UndoNextLSN
- 一个例子（注意是反过来的）
  #fig("/public/assets/Courses/DB/img-2024-06-03-19-26-33.png")
- Aries 算法的其他特性
  - Recovery Independence 恢复的独立性
  - Savepoints 存档点
  - Fine-grained locking 细粒度的锁
  - Recovery optimizations 恢复的优化

#v(1em)
- check：
  - [ ] 普通恢复算法
  - [ ] 逻辑恢复算法
  - [ ] ARIES 恢复算法