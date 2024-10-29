---
order: 1
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

= Computer Abstractions and Technology
== 计算机的发展历史
- 最早的电子计算机
- 计算机的迭代：Generation 1(1946-1957)、Generation 2(1958-1964)、Generation 3(1965-1970)、Generation 4(1971-?)
- 电子计算机 Generation 5
  - 主导技术
    - 处理器(Processors)：大规模生产
    - Memroy: SRAM, DRAM
    - Compilers
  - RISC(reduced instruction set computer) 处理器与 CISC(complex instruction set computer) 处理器

#info(caption: "Contents of Chapter 1")[
1.1 Introduction \
1.2 Below Your Program \
1.3 Computer Organization and Hardware System \
1.4 Integrated Circuits \
1.5 Real Stuff: Manufacturing Pentium Chips \
1.6 History of Computer Development
]

== Introduction
- Progress in computer technology
  - Moore's Law 为基础：芯片设计流程长，以摩尔定律为指导
- 一些偏科普的概念

== Eight Great Ideas
1. Design for Moore's Law
2. Use Abstraction to Simplify Design，以此帮助复杂系统的设计
  - 软硬件之间的 Instruction Set Architecture(ISA)
3. Make the Common Case Fast
4. Performance via Parallelism，并行
5. Performance via Pipelining，流水线
6. Performance via Prediction，预测
7. Hierarchy of Memories，内存层次结构
  - Registers, Cache, Memory, Disk, Tape
8. Dependability via Redundancy，用一定的冗余来保证可靠性

== Below Your Program
- 一种简化视角
#fig("/public/assets/Courses/计组/img-2024-02-28-11-29-52.png", width: 40%)
- 计算机语言
  - 机器语言：二进制编码
  - 汇编语言：符号化的机器语言
  - 高层次编程语言
    - 更接近 natural language
    - 可移植，独立于硬件
    - 用编译器(Complier)翻译成汇编语言，再由汇编器(Assembler)翻译成机器语言

== Computer Organization and Hardware System
- 计算机的可分解性
#fig("/public/assets/Courses/计组/img-2024-02-28-11-43-13.png", width: 59%)
- Display
  - CRT(raster Cathode Ray Tube) display，不怎么用了
  - LCD(Liquid Crystal Display) display
  - The display principle
    - Hardware support for graphics -- raster refresh buffer(frame buffer) to store bit map
    - Goal of bit map -- to faithfully represent what is on the screen
#fig("/public/assets/Courses/计组/img-2024-02-28-11-54-09.png", width: 70%)
- Motherboard（主板）：主板以及硬件附加在其上
- CPU
- Memory
- Networks

== Integrated Circuits
- Cost
#fig("/public/assets/Courses/计组/img-2024-02-28-11-58-17.png", width: 70%)

== Performance
- Response Time and Throughput
  - Response Time（响应时间）：字面意思，一个 task 多久响应
  - Throughput（吞吐量）：单位时间内完成的 task 数量
  - 用更快的处理器，影响 response time；用更多的处理器，影响 throughput
  - 我们只关注单核，因此更关注 response time
- Relative Performance
=== Measuring Execution Time
- Elapsed Time：总响应时间，包括所有方面如 I/O, OS overhead, idle time
- CPU Time(Execution time)：CPU 执行时间，再细可以分成 user CPU time 和 system CPU time
#fig("/public/assets/Courses/计组/img-2024-02-28-12-07-05.png", width: 70%)
  - Clock rate, or Clock frequency
  - 计算例
#fig("/public/assets/Courses/计组/img-2024-02-28-12-10-22.png", width: 70%)
- Instruction Count and CPI：以上假定每个指令均只用一个时钟周期，下面考虑更复杂的情况
  - CPI(Cycles Per Instruction)：每条指令的平均时钟周期数
#fig("/public/assets/Courses/计组/img-2024-02-28-12-16-32.png", width: 70%)
#fig("/public/assets/Courses/计组/img-2024-03-04-08-14-23.png", width: 70%)
  - 计算例
    - Same ISA(Instruction Set Architecture)，指的是 Instruction Count 相同
#fig("/public/assets/Courses/计组/img-2024-03-04-08-03-38.png", width: 70%)
  - 三个因素实际上是互相影响的，最终用 CPU Time 来衡量性能好坏
- CPI in more details
#fig("/public/assets/Courses/计组/img-2024-03-04-08-08-53.png", width: 65%)
  - 计算例
#fig("/public/assets/Courses/计组/img-2024-03-04-08-09-29.png", width: 70%)

== Incredible performance improvement
- CPU 单核性能过去提升迅速，现在增速放缓，three walls
- Power Wall：功耗限制，散热问题
$
"Power" = "Capacitance" times "Voltage"^2 times "Frequency"
$
  - 从公式中可以看出，降低电压是有效的降低功耗的方法，但不能一味往下降
- Memory Wall：内存速度增长远远慢于处理器速度增长
  - 这也是 Cache 为什么被提出
- ILP Wall：指令级并行性，指令流水线、乱序执行、超标量处理器等技术的局限性。
  - ILP(Instruction Level Parallelism) $=>$ TLP(Thread Level Parallelism) + DLP(Data Level Parallelism). 指令集并行到头了，考虑线程级和数据级

== Multiprocessors
- 通过多核来提高性能，需要显性的并行编程
- SPEC CPU Benchmark
  - 一个同时衡量 performance 和 power 的公式
$
"Overall Performance per Watt" = (sum_(i=0)^(10)"ssj_ops"_i) / (sum_(i=0)^(10)"Power"_i)
$
- 陷阱: Amdahl’s Law
$
T_"improved" = T_"unaffected" + T_"affected" / "improvement factor"
$
  - Make the common case fast
  - fastest case 也有瓶颈
- Fallacy: Low Power at Idle
- 陷阱: MIPS as a Performance Metric
  - MIPS(Million Instructions Per Second)
#fig("/public/assets/Courses/计组/img-2024-03-04-08-45-03.png", width: 70%)

