#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "人工智能芯片与系统",
  lang: "zh",
)

#let flop = math.text("FLOP")
#let flops = math.text("FLOP/s")

= 人工智能芯片与系统

== Chapter 1: Introduction
第一节课主要讨论一些基本常识、为什么要学芯片与系统，以及简单的课程梗概。第二节课开始正式讨论一些广泛应用的定律。

=== 三个定律
#theorem(title: [Amdahl's Law])[
  - $f$: 程序的并行可分性
  - $N$: 处理器的数量
  $ "SpeedUp" = frac(1, 1-f + f/N) $
]
- Amdahl's Law 指出串行的瓶颈：最大速度为 $1/(1-f)$，由并行度所限制，任你处理器再多也没用
- 不过，Parallel portion ($f$) 往往并不是完美并行
  + Synchronization overhead (e.g., updates to shared data)
  + Load imbalance overhead (imperfect parallelization)
  + Resource sharing overhead (contention among N processors)

#theorem(title: [Roofline Model])[
  Roofline Model 是一条折线，用于指示应用性能 bound 是受限与 compute / memory，并给出了模型在计算平台上所能达到理论计算性能上限公式
  $
  "Attainable" flops = min("peak" flops, "AI" * "peak" GB\/s) \
  "AI" ("Arithmetic Intensity") = frac("Peak" flops, "Peak" GB\/s)
  $
]
#grid(
  columns: (60%, 40%),
  [
    - 横轴计算强度 (AI) 为算力与带宽的比值（单位内存交换到底用于进行多少次浮点运算）；纵轴理论性能 (Attainable flops) 为在计算平台上所能达到的每秒浮点运算次数（理论值）
    - 计算瓶颈区域 Compute-Bound
      - 不管模型的计算强度 $I$ 有多大，它的理论性能 $P$ 最大只能等于计算平台的算力
    - 带宽瓶颈区域 Memory-Bound
      - 模型理论性能 $P$ 的大小完全由计算平台的带宽上限（房檐的斜率）以及模型自身的计算强度 $I $ 所决定
    - 可以参考 #link("https://zhuanlan.zhihu.com/p/34204282")[Roofline Model 与深度学习模型的性能分析]
  ],
  fig("/public/assets/Courses/CHIP/2025-03-08-23-07-24.png")
)

#theorem(title: [Little's Law])[
  $
  "Buffer Size" = "Throughput" * "Latency" \
  L = la * W
  $
]
- 用一个银行柜台的例子来解释
  - Arrival rate (Throughput): $1$ person per min
  - Serve time (Latency): $6$ min per person
  - 需要多少个柜台，才能使得顾客不需要等待？$6$ 个

=== 体系结构快速回顾
- 冯诺依曼架构
  - 两个关键特性：Stored Program, Sequential instruction processing（可以乱序执行，但发射和结束必须顺序）
  - Processing Unit (PU)，由 ALU 和 temporary storage 组成
    - Arithmetic Logic Unit (ALU)
    - Fast temporary storage: Registers
  - Control Unit
- Instruction Set Architecture (ISA)
  - 指令是计算机语言中的*词*，指令集是计算机语言中的*字典*
  - ISA 是软件与硬件之间的 interface
  - ISA 指定了三个组成部分
    + Memory Organization
    + Rigister Set
      - Application Binary Interface (ABI) 是 ISA 的一个子集，interface between two binary program modules
    + Instruction Set
      - Opcode & Operands
      - Addressing Modes
      - Data Types
- Instruction Cycle
  - IF, ID, EXE, MEM, WB
- Single-Cycle CPU & Multi-Cycle CPU
- Pipeline CPU
  - Pipeline Hazard: Structural, Data, Control...
    - Data Hazard: RAW, WAR, WAW
    - 基本上的解决方法：只在最后一个阶段且按程序顺序写回、stall、forwarding
  - Reorder Buffer

== Chapter 2: Pipelining, Reorder Buffer
Pipeline 不再赘述。

=== Reorder Buffer (ROB)
- 为了什么？
  + For false dependencies
  + For exception and interrupt
  + For multi-cycle execute
- 核心思想：乱序完成指令，但在将结果写入体系结构状态 (commit) 之前重新排序
  + When instruction is decoded, it reserves the next-sequential entry in the ROB
  + When instruction completes out-of-order, it writes result into ROB entry
  + When instruction oldest in ROB and it has completed without exceptions, its result writes to reg. file or memory (In order of commitment)
- Reorder buffer 类似临时工，没编制
  - 出问题就怪临时工
- ROB 需要
  + correctly reorder instructions back into the program order
  + update the architectural state with the instruction's result(s), if instruction can retire without any issues
  + handle an exception/interrupt precisely, if an exception/interrupt needs to be handled before retiring the instruction
  + use valid bits to keep track of readiness of the result(s) and find out if the instruction has completed execution
- 跟 Roofline Model 的关系：Roofline Model 中的算力只跟计算单元有关（理论意义，跟 ROB 无关）
- 如果一个后来的指令需要 ROB 中的值怎么办？
  - 一个选择是 stall the operation $->$ stall the pipeline。但更好的选择是直接从 ROB 里读值
  - Idea: Use indirection
    + 先访问 rigister file
      - 如果 rigister not valid，它存着 ROB entry 的 ID（把 rigister 映射到 ROB entry）
    + 然后访问 ROB
- Reorder Buffer: For False Dependencies
  - 指令之间的依赖关系可能并不是真的，因为同一个寄存器可能指向完全无关的值，根源在于 rigister ID 的稀缺
  - ROB 消除了这种 false dependency，因为它相当于提供了庞大的寄存器
  - The register ID is renamed to the reorder buffer entry that will hold the register’s value
    - Register ID $$ ROB entry ID
    - Architectural register ID → Physical register ID
    - After renaming, ROB entry ID used to refer to the register

== Chapter 3: Tomasula
- In-order Dispatch 的问题
  - 在顺序分派和精确执行的情况下，排在后面的指令即使没有冲突，也会被前面发生冲突的指令卡住
  - 这引导我们提出乱序分派 out-of-order dispatch
- Reservation Station (RS): Out-of-order Execution
  - Key idea of reservation station: Move the dependent instructions out of the way of independent ones
  #fig("/public/assets/Courses/CHIP/2025-03-11-18-39-35.png", width: 60%)
- Recall Register Renaming
  - RS 中也像 ROB 里一样做重命名
    - Destination rigister ID $->$ RS entry
- Tomasulo's Algorithm
  - 古老而经典的算法，其在现代 CPU 中的地位如同反向传播之于深度学习
  - 下图为 Modern Pipeline 的示意图（如同骆驼的两个驼峰），RS 左侧和 ROB 右侧必须是 In-order（冯诺依曼架构决定），这中间则可以玩花活
    #fig("/public/assets/Courses/CHIP/2025-03-11-18-40-45.png", width: 60%)
  - 三大组件
    + Register rename table
    + Reservation station
    + Common data bus (CDB)
  - 算法流程又臭又长，建议是直接看 PPT 具体例子
- 哪一步可能会成为 critical path？
  - 显然是 tag broadcast $->$ value capture $->$ instruction wake up
  - 解决方法也很简单粗暴，一个周期解决不了，那就多周期实现 (break down critical path)。代价无非是 RS 的效果没有那么好了，但比起没有 RS 还是值得的
- 回看 OoO Execution 的关键
  + 把 rigister 的 consumer 和 producer 给 *Link* 起来
  + 把指令 *buffer* 起来，直到 source operands 准备好
  +  通过 *tag* 来追踪指令的 source values 是否准备好
  + 当所有 source values 准备好时，分派指令到功能单元 (FU)
- *总结*：对于现代的 OoO Execution with Precise Exceptions，大多数处理器都有
  - *Reorder buffer* to support in-order retirement of instructions
  - 一个 *Rigister File* 来存储所有 rigisters
    - 包括 speculative and architectural rigisters
    - INT 和 FP 仍然是分开的
  - 两个 *Rigister Maps*
    - Future/frontend register map $->$ used for renaming
    - Architectural register map $->$ used for maintaining precise state
- Approaches to Dependence Detection
  - Scoreboarding 啥的，好像不是重点

== Chapter 4: Superscalar, Cores, SIMD
=== Superscalar 超标量
- 超标量位于整个系统领域的何处？
  #fig("/public/assets/Courses/CHIP/2025-03-14-10-18-18.png", width: 95%)
- Idea: Fetch, decode, execute, retire 一个周期多条指令。即 $N"-wide"$ superscalar $->$ $N$ instructions per cycle
  - 问题：需要添加硬件资源，同时硬件需要对 concurrently-fetched instructions 执行依赖检查
  - 注意，超标量和顺序乱序是正交的概念（可以同时用），因此可以有四种组合
    $ ["in-order", "out-of-order"] times ["scalar", "superscalar"] $
  - Superscalar 对 Roofline Model 的影响
    - Roofline 的理论算力主要取决于 EXE 阶段的计算单元多少
    - Superscalar 只影响算力的实际利用率，但对理论算力没有影响，因此不会抬高 Roofline 的水平线
- Pros and Cons
  - Advantage: 更高的吞吐量 (higher IPC)
  - Disadvantage:
    - 依赖检查更复杂（比如，$2"-wide"$ 寄存器重命名的复杂度基本上变为 $4$ 倍；且可能让 critical path 更长）
    - 需要更多硬件资源

=== Vector Insn
- Flynn's Taxonomy of Computers 弗林分类法
  - SISD: Single Instruction Single Data，单指令单数据，我们以前学的
  - SIMD: Single Instruction Multiple Data，单指令多数据 (Array processor, Vector processor)
  - MISD: Multiple Instruction Single Data，多指令单数据
  - MIMD: Multiple Instruction Multiple Data
    #grid2(
      fig("/public/assets/Courses/CHIP/2025-03-14-10-52-45.png", width: 70%),
      fig("/public/assets/Courses/CHIP/2025-03-14-10-53-07.png", width: 70%),
      fig("/public/assets/Courses/CHIP/2025-03-14-10-53-40.png", width: 70%),
      fig("/public/assets/Courses/CHIP/2025-03-14-10-53-21.png", width: 70%)
    )
- *SIMD*
  - 回忆 Amdahl's Law，并行能够提升其上限
  - Vector Processor Limitations
    - 向量化的执行也需要向量化的内存访问（不然不匹配），因此 Memory (bandwidth) 很容易变成瓶颈
    - 尤其是在：1. compute/memory operation balance is not maintained; 2. data is not mapped appropriately to memory banks
  - 硬件上需要什么变化？
    - Register file(s):
      - 原本是 The 32-element, *32-bit* register file has 2 read ports and 1 write port
      - 现在是 The 32-element, *128-bit* register file has 2 read ports and 1 write port
      - General purpose register file 变为 Vector register file
    - Data memory:
      - 原本是 If WE is 1, it writes 32-bit data WD into memory location at 32-bit address A
      - 现在是 If WE1 = 1, writes 128-bit data WD1 to A1 address
    - Memory:
      - 原本是 array of storage locations indexed by an address
      - 现在是 Multiple bank design
  - SIMD 对 Roofline Modl 的影响
    - SIMD 对 EXE 阶段的算力有影响，理论算力提高，因此会抬高 Roofline 的水平线

=== MultiThreading
- 注意：这里的线程和 OS 的线程不是一个概念，这里是硬件上的
- Idea: 硬件具有多个线程上下文（PC + 寄存器）。CPU 每周期切换到不同线程中取指令，同一时刻流水线中没有来自同个线程的指令
  - 会影响 Roofline Model 吗？
    - 执行单元不变，对 Roofline Model 的横线没有影响
- Pros and Cons
  - Advantage
    + 不需要额外的线程内的 data dependencies 的逻辑，避免了可能存在的 bubbles
    + 也不需要分支预测逻辑
    + 容忍 control and data dependency latencies（通过多线程来 overlap 这些 latency）
  - Disadvantage
    + 额外的硬件复杂度（需要额外的保存线程上下文的逻辑、选择线程的逻辑）
    + 降低了单个线程的性能（对同个线程而言，one instruction fetched every $N$ cycles）
    + 线程在 caches and memory 中的资源竞争
    + Some dependency checking logic between threads remains (load/store)
    + 需要有足够多的线程数（大于整个 pipeline 的阶段数），否则没法 overlap latencies

=== Multi-core
- Idea: 在一个芯片上放多个 CPU core
  - Moore's Law: 每 $18$ 个月，芯片上 transistors 数量翻倍（虽然现在有点失效了）
  - 会影响 Roofline Model 吗？当然会，计算单元多了
- 跟 Bigger, more powerful 的单核 CPU 相比
  - 单核性能更好当然对程序员、编译器更有利
  - 但是单核太难设计了；且许多乱序执行结构使功耗提高，引起 Power hungry；且目前性能回报受益递减；且对于 memory-bound 的应用性能提升有限
- Pros and Cons
  - Advantage
    + 更简单的内核 $->$ 更节能，复杂性更低，设计和复制更简单，频率更高（电线更短，结构更小）
    + 在多程序工作负载上提高系统吞吐量 $->$ 减少上下文切换
    + 在并行应用上提高系统吞吐量
  - Disadvantage
    + 需要有并行的任务、线程才能提高性能 (require parallel programming)
    + 资源共享会降低单线程性能，且共享硬件资源需要管理
    + 针脚数量 (number of pins) 随着需求增加限制了数据供给
- Multi-Core Evolution (An Early History)
  - 略

= Chapter 5: Memory Overview, Organization, Technology
- Memory 的功能就是 store 和 load (Programmer's View)
  - [] 图
- 理想的计算架构，其中 Data Supply 也就是 memory 部分是目前包括 LLM 等应用中最困难的
  - [] 图（三个组成的那张）
  - 观察 ideal memory 的四个特性，它们实际上是互相冲突的
    + Bigger is slower: Bigger $->$ Takes longer to determine the location
    + Faster is more expensive: 回顾存储技术 SRAM v.s. DRAM v.s. SSD v.s. Disk v.s. Tape
    + Higher bandwidth is more expensive: Need more banks, more ports, more channels, higher frequency or faster technology
  - 几种存储设备的比较
    - [ ] 图（三个金字塔）
  - FF v.s. SRAM v.s. DRAM v.s. SSD (Flash Memory)

== SRAM
- Goal:Efficiently store large amounts of data
  - A memory array (stores data)
  - Address selection logic (selects one row of the array)
  - Readout circuitry (reads data out)
  - *Advantage*: random access still keeps high performance
  - *Disadvantage*: low capacity (\~ MBs)
- Memory Array:
  - memory array with $N$ address bits and $M$ data bits
    - *Depth*: number of rows $2^N$ (number of words)
    - *Width*: number of columns $M$ (size of a word)
    - *Array Size*: depth $times$ width = $2^N times M$
    - [ ] 图 51
  - Bitline:Storage nodes in one column connected to one bitline
  - Wordline:Address decoder activates only ONE wordline, content of one line of storage available at output
- SRAM Bit（SRAM 基本单元）
  - [ ] 图
- Memory Banking
  - Memory 被分为 banks，它们可以被独立访问，并且共享 address 和 data buses (to minimize pin cost)
  - 可以承受 $N$ 个并发访问，如果这 $N$ 个访问发往不同的 banks
  - [ ] 图
- SRAM Access
  #grid(
    columns: 2,
    column-gutter: 4pt,
    fig("/public/assets/Courses/CHIP/2025-03-21-10-55-25.png"),
    fig("/public/assets/Courses/CHIP/2025-03-21-10-56-01.png")
  )
  - Read Sequence
    + address decode
    + drive row select
    + selected bit-cells drive bitlines (entire row is read together)
    + differential sensing and column select (data is ready)
    + precharge all bitlines (for next read or write)
    - 其中 access latency 主要由 steps $2, 3$ 决定；cycling time 主要由 steps $2, 3, 5$ 决定
      $ &"steps" 2 prop 2^m \ &"steps" 3, 5 prop 2^n $

== DRAM (HBM, DDR)
- Motivation and Goals
  - Application Perspective
  - Performance Perspective
  - Reliability Perspective
  - 总之又是重复了很久 memory 的重要性，略
  - 目前 memory optimization 的方向在于 size (capacity) 和 bandwidth，对 latency 需求不大
- DRAM (dynamic random access memory)
  - 使用电压来指示存储数据 (charged $-> 1$, discharged $-> 0$)
  - 需要周期性地 refresh (read and rewrite) 来保持数据，因为 capacitor leaks through the RC path，DRAM 会随着时间失去电压
- Building Larger Memories
  - Idea: 把 memory 分成更小的 arrays 并且把它们连接到 input / output buses
  - Large memories are hierarchical array structures
  - DRAM Subsystem Organization: Channel $->$ DIMM（内存条） $->$ Rank（内存条正反面） $->$ Chip $->$ Bank $->$ Row / Column
  - 这段看 PPT 的图会比较好理解
- Address Bits of Memory
  - SRAM 的寻址比较简单
  - DRAM 需要给出 channel, bank, row, column，导致地址复杂的同时性能也下降
- Digging Deeper: DRAM Bank Operation —— Row Buffer
  - 类似于给 DRAM 的 bank 做了 row 层级的 cache，也有 hit / miss 的概念
    - Page Hit: 最快的时候，指定 column 直接从 row buffer 里面取
    - Page Close: 第一次激活的时候，里面没有有意义数据，直接覆盖
    - Page Miss: 需要先写回该 row，再读取所需 row
  - 这就是 $"Sequential Speed" > "Random Speed"$ 的本质原因
- DRAM Refresh
  - 由 memory controller 负责，程序员只需要考虑 load / store 就行了
  - 副作用
    + *Energy consumption*: Each refresh consumes energy
    + *Performance degradation*: DRAM rank/bank unavailable while refreshed
    + *QoS / predictability impact*: (Long) pause times during refresh
    + Refresh rate limits DRAM capacity scaling

== SSD
- Advantage: Large memory size, e.g. 16TB per SSD
- Disadvantage: Low throughput, high latency, hard to use
- [ ] 图227
- 老师的经验之谈：现在用 SSD 的大存储来代替显存，虽然频率差一点但现在也是有可以做的地方的，只要账面实力一算，优化好让两边性能能够 overlap 就行

= Chapter 6: Graphics Processing Units
没怎么听。




