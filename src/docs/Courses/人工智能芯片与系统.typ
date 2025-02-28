#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "人工智能芯片与系统",
  lang: "zh",
)

#let flop = math.text("FLOP")
#let flops = math.text("FLOP/s")

= 人工智能芯片与系统

== Chapter 1
第一节课主要讨论一些基本常识、为什么要学芯片与系统，以及简单的课程梗概。

== Chapter 2
=== 三个定律
#theorem(title: [Amdahl's Law])[
  Amdahl's Law
]

#theorem(title: [Roofline Model])[
  Roofline Model 是一条折线，用于指示应用性能 bound 是受限与 compute / memory，并给出了模型在计算平台上所能达到理论计算性能上限公式
  $
  "Attainable" flops = min("peak" flops, "AI" * "peak" GB\/s) \
  "AI" ("Arithmetic Intensity") = frac("Peak" flops, "Peak" GB\/s) \
  $
  - 横轴计算强度 (AI) 为算力与带宽的比值（单位内存交换到底用于进行多少次浮点运算）；纵轴理论性能 (Attainable flops) 为在计算平台上所能达到的每秒浮点运算次数（理论值）
  - 计算瓶颈区域 Compute-Bound
    - 不管模型的计算强度 $I$ 有多大，它的理论性能 $P$ 最大只能等于计算平台的算力
  - 带宽瓶颈区域 Memory-Bound
    - 模型理论性能 $P$ 的大小完全由计算平台的带宽上限（房檐的斜率）以及模型自身的计算强度 $I $ 所决定
]
- 可以参考 #link("https://zhuanlan.zhihu.com/p/34204282")[Roofline Model 与深度学习模型的性能分析]

#theorem(title: [Little's Law])[
  Buffer Size = Throughput \* Latency: $ L = la * W $
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
  - Reorder Buffer



