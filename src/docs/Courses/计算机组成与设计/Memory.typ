---
order: 5
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机组成与设计",
  lang: "zh",
)

#let tbl_white(white_row: 1 , content_size: 9pt,..args) = align(center, block[
  #show table.cell: it => if it.y <= white_row - 1 {
    set text(fill: white, stroke: white)
    it
  } else {
    set text(size: content_size)
    it
  }
  #tbl(..args)
])

#counter(heading).update(4)


= Memory
#info(caption: "Contents of Chapter 5")[
  + Introduction
  + Memory Technology
  + The basics of Cache
  + Measuring and improving cache performance
  + Virtual Memory
]
== Introduction
- Locality
  - 时间局部性（大概$95%$），空间局部性（大概$80%$）
- Memory Hierarchy
  - 所有数据存储在 disk 上
  - copy recently used data to DRAM (main memory)
  - copy more recently used data to SRAM (cache)
- hit, hit time, miss, miss penalty 等指标
- 我们将讨论 cache(SRAM and DRAM) 和 virtual memory(DRAM and DISK)
#fig("/public/assets/Courses/计组/img-2024-05-13-09-20-54.png")

== Memory Technology
- SRAM technology
- DRAM technology
  - DDR, QDR（根据 data rate 分类）
  - Row buffer
  - DRAM banking
- Flash Storage
  - 种类：NAND, NOR
  - 读写损耗，remap 技术
- Disk storage
  - disk sectors and access
#fig("/public/assets/Courses/计组/img-2024-05-13-09-04-11.png")

== The basics of Cache
- 可以将 cache 内容分门别类（建立 map），这样，在 cache 中寻找数据的时间(hit time)就缩短了；但同时，如果这一类别的位置满了，需要替换（这又减小了 hit 的概率）；最后，还需要考虑写数据的操作，如果只更改 cache 中的数据而不改 main memory，会发生 inconsistency，否则，如果两个都改，速度会变慢。
- main issues
  + 数据怎么放
  + 找数据怎么找
  + cache 满了怎么替换
  + 写操作策略
- direct mapped
  - 内存的每个地址固定映射到 cache 的某个位置（可能跟其他地址共享）
  #fig("/public/assets/Courses/计组/img-2024-05-13-09-29-36.png")
  - 给定内存中的地址，根据映射直接可以知道它在 cache 中的位置，但还需要知道 tag 才能确定是否命中
    - 把内存中地址高位作为 tag
    - 还有 valid bit 来标识这个位置是否有数据
  - 块内偏移量不作为 block address 寻址的一部分，block address 包含 valid bit 和 tag
    - 下面的例子中，Cache 一共要存 16KB 的数据，每个块为 4 word，那么一共需要 $2^10$ 个 Cache 块，index bit 需要 10 bits
    - address 一共 64 bit，块内偏移量为 4 bit(4 word per block)，再减去 10 bits 的 index，剩下 50 bits 作为 tag
    - 一共 $2^10$ 个 Cache block，每个需要 128 存储数据，$50+1$ 存储 valid bit 和 tag
  #grid(columns: 2,
    fig("/public/assets/Courses/计组/img-2024-05-15-10-09-10.png"),
    fig("/public/assets/Courses/计组/img-2024-05-15-10-26-58.png")
  )
  - 缺失率与块大小的关系
    - 块太小，一次搬过来的数据太少，会导致更多的缺失
    - 块太大，搬来的数据不一定全都是有用的，可能就其中某一段有用，导致 cache 能容纳的块数就少，也会导致更多的缺失
    - 因此是一个 trade-off
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-05-29.png")
- Handling Cache reads hit and Misses
  - 对读操作，比较简单，当遇到 miss 时，需要 Control_Stall CPU
  - 对写操作，更复杂，对 hit 和 miss 各有两种策略
    - write hits
      + write-back: 写 cache，等到替换时再写 main memory (cause inconsistency)
        - keep track of dirty bit
      + write-through: 写 cache 同时写 main memory
        - 解决方法，先写到 buffer，但总归还是会慢（当然 write-back 也可以有 buffer）
    - write misses
      + write-allocate: 先读 cache，再写，write-back 一般会 allocate
      + no-write-allocate: 直接写 main memory
      - 是否 allocate 会影响后续的 miss rate
    #fig("/public/assets/Courses/计组/img-2024-05-15-11-00-29.png")
- Intrinsity FastMATH
  - 通过 address 找 cache 中数据的路线图，这里 address 细化到 byte（我们实验中 lhw, lb 就是细化到 byte）
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-18-28.png")
- Memory 组织方式的影响：wide memory(more words per block) and banks
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-25-17.png")
  - 原本的方式
    - $1$ 个 cycle 发送地址；$15$ 个 cycles 寻找到数据；$1$ 个 cycle 发送一个 word 数据
    - $17$ 的计算可以不看，是单个 word 的情况
    - $65$ 的计算，$1$ 发送地址，随后等待总线准备好 $1$ 个 block $4$ 个 word 的数据，一共 $4 times (15+1)$
    - 最后带宽为 $4$ 个 clock $1$ 个 word
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-31-11.png")
  - 使用宽 block 的方式
    - $1$ 个 block $4$ 个 word 的数据只用两次或一次查找
    #fig("/public/assets/Courses/计组/img-2024-05-15-11-31-25.png")
    - 但是这要求 BUS 和 Cache 的宽度与之相同，实际情况总线做不到太宽，我们可以用 bank 的方式来解决
  - 使用 bank 组织方式
    - 最好将同一块内的数据分散到不同的 bank，提高并行度
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-31-52.png")

== Measuring and improving cache performance
- 涉及很多公式运算，直接看 PPT
- Summary
  - 考虑 stalk 的诸多 CPU Time 计算
  - 即使 CPU 实现得更好（CPI 从 2 到 1），提高的性能并不会有一倍那样大的提升
  - 即使时钟频率快一倍，最后提高的性能因为 memory 而产生的 stall 也不会有一倍那样大的提升
  - Can’t neglect cache behavior when evaluating system performance
=== flexible replacement of blocks
- The disadvantage of a direct-mapped cache $=>$ set-associative, fully-associative（组相连、全相连）
  - 实际上三种相连方式就是一个 set 内 block 数量的极端和中间态
  - 之前是一个 cache 块对应多个 memory 块，现在是多个 cache 块对应多个 memory 块
  #fig("/public/assets/Courses/计组/img-2024-05-15-11-55-32.png")
- The basics of a set-associative cache
  - 简单看一下它的效果
  #grid(columns: 2,
    fig("/public/assets/Courses/计组/img-2024-05-15-12-02-35.png"),
    fig("/public/assets/Courses/计组/img-2024-05-15-12-03-22.png")
  )
  - 在 SPEC2000 指令数据集上测试结果显示，2 路组相连提升很多，再多下去并不明显
- set-associative 的查找方式
  - 每个 index 对应一个 set，每个 set 有多个 cache block
  #fig("/public/assets/Courses/计组/img-2024-05-30-15-32-28.png")
- 组相连 Cache 的计算
  - PPT 66 \~ 67
- Replacement Policy
  - Direct mapped，没有选择，只能替换
  - Set associative，在 set 内优先选择 non-valid entry，否则根据某种策略替换
    - LRU，Simple for 2-way, manageable for 4-way, too hard beyond that
      - 需要加一位 reference bit
    - Random，在 high-Associativity 时性能与 LRU 相当

=== Decreasing miss penalty with multilevel caches
- PPT 69 \~ 70，一个直观的增加 L-2 Cache 的效果的例子

=== Interactions with Advanced CPUs
- 使用 out-of-order CPUs，即使 miss 发生，也能继续乱序执行一些不需要 access main memory 的指令
- 其性能分析更加复杂，一般使用 simulations

=== Interactions with Software
- 程序的指令编排跟 CPU 性能也有关系
- 例子：排序算法、通用矩阵乘法
#hline()
- 总结，影响 cache 命中率的硬件因素主要有以下四点：
  - Cache 的容量。
  - Cache 与主存储器交换信息的单位量（cache line size）。
  - Cache 的组织方式
  - Cache 的替换算法
- 总结，影响总 CPI 的因素
  - Cache Size
  - Block Size
  - Associativity
  - multilevel caches
  - Main memory access time(use banking)
  - 指令种类、数量和顺序（软件）

== Dependable Memory Hierarchy
- Reliability: mean time to failure (MTTF)
- Service interruption: mean time to repair (MTTR)
- Mean time between failures: MTBF = MTTF + MTTR
- Availability = MTTF / (MTTF + MTTR)

== Virtual Machines
- Virtual Machine Monitor(VMM)

== Virtual Memory
- 把 main memory 当做 disk storage 的 "cache"
  - 之前的 "block" 现在叫 "page"
  - 之前的 "miss" 现在叫 "page fault"
- 主要有两个动机
  - 不同程序之间共享主存且进行保护，每个程序得到自己的虚拟地址空间
  - “扩展”主存的大小，减轻程序员为了适应主存大小分割程序的负担（现在没那么必要）
- 通过地址转换实现
  #fig("/public/assets/Courses/计组/img-2024-05-20-08-55-56.png")
- Page faults
  - huge miss penalty, thus pages should be fairly *large* (e.g. 4KB)
  - reducing page faults is important (*LRU* is worth the price)
  - can handle the faults *in software* instead of hardware
  - using write-through is too expensive so we use *write back*
- Page Tables（PT，页表）
  - 采用全相连策略（miss 的代价远大于在主存中查询的代价）
  #fig("/public/assets/Courses/计组/img-2024-05-20-09-10-58.png")
- 每当 OS 创建一个进程，就会创建一个页表，这个页表会被存储在主存中（但由于页表非常大，朴素实现肯定是无法接受的，有一些技术来减小，比如多级页表，不作要求）
- Making Address Translation Fast（TLB，快表）
  - 把页表的常用部分搬到 Cache 中，Translation Look-aside Buffer (TLB)
  #fig("/public/assets/Courses/计组/img-2024-06-01-13-22-21.png")
  - 有点像是为页表建立一个 cache
  - 快表 miss 后去页表中查找，有两次机会
  #fig("/public/assets/Courses/计组/img-2024-05-20-09-33-58.png")
  - 流程图
    - 发生 TLB miss exception 后，从 main memory 查找 PT 并 load 到 TLB 中，得到物理地址，之后跟 TLB hit 一样
  #fig("/public/assets/Courses/计组/img-2024-05-22-10-08-20.png")
- 三种数据结构的 miss 和 hit
#tbl_white(
  columns: 4,
  fill: (x,y) => if y == 0 {rgb(0, 144, 227)},
  [TLB],[PT],[Cache],[Possible? If so, under what circumstance?],
  [hit],[hit],[miss],[Possible, although the page table is never really checked if TLB hits.],
  [miss],[hit],[hit],[TLB misses, but entry found in page table;after retry, data is found in cache.],
  [miss],[hit],[miss],[TLB misses, but entry found in page table;after retry, data misses in cache.],
  [miss],[miss],[miss],[TLB misses and is followed by a page fault;after retry, data must miss in cache.],
  [hit],[miss],[miss],[Impossible: cannot have a translation in TLB if page is not present in memory.],
  [hit],[miss],[hit],[Impossible: cannot have a translation in TLB if page is not present in memory.],
  [miss],[miss],[hit],[Impossible: data cannot be allowed in cache if the page is not in memory.],
)
- Memory Protection
  - 不同进程可以共享它们的虚拟地址空间，但需要额外的位标记保护
  - 硬件上为 OS 的保护提供支持

== The Memory Hierarchy
- There are Four Questions for Memory Hierarchy Designers
  + Q1: Where can a block be placed in the upper level? (Block placement)
    - Fully Associative, Set Associative, Direct Mapped
  + Q2: How is a block found if it is in the upper level? (Block identification)
    - Tag/Block
  + Q3: Which block should be replaced on a miss? (Block replacement)
    - Random, LRU,FIFO
  + Q4: What happens on a write? (Write strategy)
    - Hit: Write Back or Write Through (with Write Buffer)
    - Miss: Write Allocate or No-Write Allocate
- 这里是做个复习
- 3C 模型（把 misses 分类）
  - Compulsory Misses（强制失效，冷启动失效）: 第一次访问 block 时的 miss
  - Capacity Misses（容量失效）: cache 太小导致把一个 block 替换后又要用到
  - Conflict Misses（冲突失效，碰撞失效）: non-fully mapped cache 中的 miss，多个 block 竞争同一个组导致的 miss
  - 三个失效的改善方法分别是：调整 block 大小（并非越高越好）、增加 cache 大小、增加组相连度（并非越高越好）

== 使用 FSM 实现简单的 Cache
- write back & write allocate
- 略

