---
order: 4
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#let null = math.op("null")
#let Unknown = math.op("Unknown")

#counter(heading).update(3)

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
  - $n_r$: 表示关系 $r$ 中元组的数量(也就是关系 $r$ 的 size)
  - $b_r$: 包含 $r$ 中元组需要的 block 数量
  - $l_r$: 表示 $r$ 中一个元组的 size
  - $f_r$: block factor of $r$ 比如可以选取一个 block 能容纳的 $r$ 中元组的平均数量
  - $V(A, r)$: 关系 $r$ 中属性 $A$ 可能取到的不同的值的数量，$=>$ Histograms
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
  - 如果 $R inter S$ 为空，则自然连接的结果和笛卡尔积的结果相同
  - 如果非空，且 $R inter S$ 是 $R$ 的 key，则 $R,S$ 的自然连接结果中的元组个数不会超过 $n_s$
  - 如果 $R inter S$ 的结果是 $S$ 到 $R$ 的外键，则最后的元组数为 $n_s$，反之对称
  - 一般情况，$R inter S={A}$不是键，自然连接的结果 size 估计值为$(n_r times n_s)/(max(V(A,r),V(A,s)))$
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
