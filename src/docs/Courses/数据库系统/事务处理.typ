---
order: 5
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "数据库系统",
  lang: "zh",
)

#let null = math.op("null")
#let Unknown = math.op("Unknown")

#counter(heading).update(4)

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