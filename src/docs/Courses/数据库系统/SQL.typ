---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#let null = math.op("null")
#let Unknown = math.op("Unknown")

#counter(heading).update(1)

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
- 例子 union($union$)、intersect($inter$)、except($-$)
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

