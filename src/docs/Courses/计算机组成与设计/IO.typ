---
order: 6
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

#counter(heading).update(5)

= Storage, Network and other I/O Topics
#info()[
  + Introduction
  + Disk Storage and Dependability
  + Networks (Skim)
  + Buses and Other Connections between Processors Memory, and I/O Devices
  + Interfacing I/O Devices to the Memory, Processor, and Operating System
  + I/O Performance Measures: Examples from Disk and File Systems
  + Designing an I/O system
  + Real Stuff: A Typical Desktop I/O System
]
== Introduction
- I/O 设计需要考虑可扩展性、可恢复性、性能
- 评估 I/O 设备的性能往往十分困难
- 其性能取决于
  + connection between devices and the system
  + the memory hierarchy
  + the operating system
  - 从另一个角度来看
    + Throughput（吞吐量）
    + Response time（响应时间）
- Three characteristics
  - Behavior: input, output, storage
  - Partner: human, machine
  - Data rate

== Disk Storage and Dependability
- 分为软盘(floppy disks)和硬盘(hard disks)
- Dependability Measures
  - MTTF(Mean Time To Failure): 平均无故障时间
    - 一个例子，如果有 100000 个硬盘，$"MTTF" approx 114"年"$，一年有 $1/144 times 100000 approx 876$ 个硬盘坏掉。也就是说，单看某一个硬盘坏掉的概率很低，但是很多硬盘坏掉其中几个是很常见的
  - MTTR(Mean Time To Repair): 平均修复时间
  - MTBF(Mean Time Between Failure) = MTTF + MTTR: 平均故障间隔时间
  - Availability = MTTF / (MTTF + MTTR) = MTTF / MTBF: 可用性
- Improve MTTF
  + Fault avoidance
  + Fault tolerance
  + Fault forecasting
- The Hamming SEC Code
  - 没懂，不考
- 磁盘的设计：使用小磁盘组成阵列以降低成本，但降低可靠性
  - 比如用 $N$ 个盘组成一个大盘，MTTF 降低了 $N$ 倍
  - 使用冗余信息来提高可靠性(RAID: Redundant Arrays of Inexpensive Disks)，有 $7$ 个 level
    - 这里很多图片，看 PPT 吧
  - 一些论断
    + RAID systems rely on redundancy to achieve high availability.
    + RAID 1(mirroring)has the highest check disk overhead.
    + For small writes,RAID 3(bit-interleaved parity)has the worst throughput.
    + For large writes,RAID 3,4,and 5 have the same throughput.

== Networks
- skipped

== Buses and Other Connections between Processors Memory, and I/O Devices
- 包括两种线路：控制线路和数据线路
- 总线事务：input, output
  - `output` operation
  #fig("/public/assets/Courses/计组/img-2024-05-27-09-25-21.png")
  - `input` operation
  #fig("/public/assets/Courses/计组/img-2024-05-27-09-25-51.png")
- Types of buses:
  - processor-memory (short, high speed, custom design)
  - backplane (high speed, often standardized, e.g. PCI)
  - I/O (lengthy, different devices, standardized, e.g. SCSI)
  - 在最开始，Backplane bus 不仅控制 Processor 和 Memory，还要支持不同的 I/O 设备
    #fig("/public/assets/Courses/计组/img-2024-05-27-09-29-53.png")
  - ...
    #fig("/public/assets/Courses/计组/img-2024-05-27-09-30-18.png")
  - ...
    #fig("/public/assets/Courses/计组/img-2024-05-27-09-30-39.png")
- Synchronous vs. Asynchronous
  - Synchronization buses 使用同步时钟和同步协议，快且小但是需要不同设备工作速度一致，并且不适合长距离(clock skew)
  - Asynchronous buses 使用 handshake 协议
- Handshaking protocol，握手协议
  - ReadReq，读请求
  - DataRdy，数据准备好
  - Ack(acknowledge)，接受信息的那一方给确认信号
  - 一共七个步骤如下，红色线是接受方，黑色线是 memory
    #fig("/public/assets/Courses/计组/img-2024-05-29-10-08-35.png")
  - 使用 FSM 实现握手协议
  #fig("/public/assets/Courses/计组/img-2024-05-29-10-13-36.png")
- Obtaining Access to the Bus
  - 一般都是多个设备共享一条总线进行数据通信，其中如果多个设备同时发送接收数据的话，从而产生总线竞争，会导致通信冲突导致通信失败，所以在总线上要引入一个仲裁机制(Bus Arbitration)来决定什么时间谁来占用总线的通信
  - 部分仲裁机制需要有一个 bus master 来控制总线的访问权，不然会产生混乱
  - processor is always a bus master
  - 从 buses 中细分出 bus request lines
- Bus Arbitration
  - 常见四种仲裁机制，主要考量两点：bus priority、fairness
  + daisy chain arbitration: 菊花链，阻塞式级联（不是很公平）
    - 有一种*计数器*的改进，起始查询的位置不固定
  + centralized, parallel arbitration (requires an arbiter), e.g. PCI
  + self selection, e.g. NuBus used in Macintosh（不需要 master，每个设备根据自己的优先级自行选择）
  + collision detection, e.g. Ethernet（如果碰撞了就都收回，过段时间再尝试）
- Bus Standards
  - SCSI, PCI, IPI, USB, HDMI

== Interfacing I/O Devices to the Memory, Processor, and Operating System
- I/O 系统的三个特征
  - shared by multiple programs using the processor.
  - often use interrupts to communicate information about I/O operations.
  - The low-level control of I/O devices is complex
- Three types of communication are required:
  - OS 需要能对 I/O 设备发送控制信息
  - I/O 设备需要能向 OS 回应
  - Data must be transferred between memory and an I/O device
- Giving Commands to I/O Devices，两种方法来 address
  - memory-mapped I/O，I/O 的地址与 memory 的地址统一（相当于把 memory 划一部分给 I/O），于是 lw, sw 等指令就可以直接访问 I/O 端口
  - special I/O instructions，通过特殊的指令来访问 I/O 端口
  - I/O 设备需要有命令端口、数据端口，命令寄存器、数据寄存器
- I/O system data transfer control mode
  - Polling：processor 定期查看 status bit 来确定是否到下个 I/O 操作的时刻
  - interrupt：用的最多，I/O 有需求的时候给 CPU 一个中断，CPU 处理完之后就可以去做自己的事情
  #fig("/public/assets/Courses/计组/img-2024-05-29-10-56-39.png")
  - DMA(direct memory access)：适合高速的数据传输设备，需要三步
    + processor 启动 DMA
    + DMA 负责传输
    + DMA 做完之后请求 processor 中断，让其进行检查
  #fig("/public/assets/Courses/计组/img-2024-05-29-11-00-19.png")
  - compare:
    + polling：需要 processor 不停查看是否需要传输，浪费了 processor time，只适用于查询率较低的 I/O 设备
    + Interrupt：只在执行和检查的时候占用 processor time
    + DMA：执行时也不需要 processor 的控制

== I/O Performance Measures: Examples from Disk and File Systems
- 性能测量很复杂，一般就是运行几个基准程序来测量
  - Supercomputer I/O Benchmarks
  - Transaction Processing I/O Benchmarks
  - File System I/O Benchmarks: MakeDir, Copy, ScanDir, ReadAll, Make
- Performance analysis of Synchronous versus Asynchronous buses
  - Synchronization
  #fig("/public/assets/Courses/计组/img-2024-05-29-11-14-28.png")
  - Asynchronous
    - 主要是说阶段 2,3,4 可以和 memory access time overlap
    - 只快 20% 是因为（？）
  #fig("/public/assets/Courses/计组/img-2024-05-29-11-14-58.png")
  - Increasing the Bus Bandwidth 的计算
  - polling, interrupt, DMA 的计算

== Designing an I/O system
- to be continued
