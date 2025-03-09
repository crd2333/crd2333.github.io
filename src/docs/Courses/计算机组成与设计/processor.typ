---
order: 4
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

#counter(heading).update(3)

= The Processor: part 1

#info(caption: "Contents of Chapter 4")[
1. Introduction & Logic Design Conventions
2. Building a datapath
3. A Simple Implementation Scheme
4. Pipelining
]

== Introduction
- CPU performance factors
  - Instruction count: 由 ISA 和 compiler 决定，不太能优化
  - CPI and Cycle time: 由 CPU 硬件决定，需要我们优化
- 将介绍两种 RISC-V 实现：simplified version 和 Pipelined version
- 指令执行概述
  #block(fill: colors.gray, inset: 4pt)[
  - Fetch :
    - Take instructions from the instruction memory
    - Modify PC to point the next instruction
  - Instruction decoding & Read Operand:
    - Will be translated into machine control command
    - Reading Register Operands, whether or not to use
  - Executive Control:
    - Control the implementation of the corresponding ALU operation
  - Memory access:
    - Write or Read data from memory
    - Only ld/sd
  - Write results to register:
    - If it is R-type instructions, ALU results are written to rd
    - If it is I-type instructions, memory data are written to rd
  - Modify PC for branch instructions
  ]

  - 对每个指令，前两步是一样的
    - Fetch the instruction from the memory: 从 memory 中取指令
    - Decode and read the registers: 解码指令并读取寄存器
  - 接下来的步骤取决于 instruction class: Memory-reference, Arithmetic-logical, branches
    - Use ALU to calculate
      - Memory address for load/store
      - Arithmetic result
      - Branch comparison
    - 再后面就都不一样了
  - Overview
#fig("/public/assets/Courses/CO/img-2024-04-01-09-34-40.png")
- 各个部件
#fig("/public/assets/Courses/CO/img-2024-04-01-09-27-57.png")
- Rigister
  - 一个时钟周期内先写后读
  - Register Files--Built using D flip-flops
#fig("/public/assets/Courses/CO/img-2024-04-01-09-30-50.png")
- Immediate generation unit
  - 两个功能：输入指令产生立即数的逻辑、转移指令偏移量左移位（B和J type末尾添0，lui 左移 12 位）
#fig("/public/assets/Courses/CO/img-2024-04-01-09-35-15.png", width: 90%)
- 只考虑 I-type, S-type, B-type, J-type 指令的话，用 ImmSel (Immediate Select)控制
  - 为了 lui 需要再加一位
#tbl_white(
  columns: 5,
  fill: (x,y) => if y == 0 {rgb(51, 102, 204)} else if y == 7 {rgb(220, 229, 242)},
  [Instruction type],[Instruction opcode[6:0]],[Instruction operation],[sign-extend immediate],[ImmSel],
  table.cell(rowspan: 3)[I-type],[0000011],[Lw;lbu;lh;lb;lhu],table.cell(rowspan: 3)[sign-extend instr[31:20]],table.cell(rowspan: 3)[00],
  [0010011],[Addi;slti;sltiu;xori;ori;andi;],[1100111],[jalr],
  [S-type],[0100011],[Sw;sb;sh],[sign-extend instr[31:25],[11:7]],[01],
  [B-type],[1100011],[Beq;bne;blt;bge;bltu;bgeu],[sign-extend instr[31],[7],[30:25],[11:8],1'b0],[10],
  [J-type],[1101111],[jal],[sign-extend instr[31],[19:12],[20],[30:21],1'b0],[11],
  []
)
- 在先前的 CPU overview 中加入控制组件
#fig("/public/assets/Courses/CO/img-2024-04-03-10-14-10.png", width: 75%)
- 时钟控制方法
  - 每个周期内的操作通过 Combinational logic 完成（不能有多步操作）
  - 因此像是 Add 这种部件在一个周期内多次用到，就需要复制多个
  #fig("/public/assets/Courses/CO/img-2024-04-03-10-20-15.png")

== Building a datapath
- 对六种指令分别解释在上面 CPU overview 中的数据流转（还要加 jalr, lui, bne 等）
  #fig("/public/assets/Courses/CO/img-2024-04-03-11-19-52.png", width: 110%)
  - 思考不同指令在图中的流转路径

== A Simple Implementation Scheme
- Building Controller
  - There are $7+4$ signals
    #fig("/public/assets/Courses/CO/img-2024-04-03-11-24-57.png", width: 90%)
  - 根据下表中蓝色部分生成控制信号
#tbl_white(
  white_row: 2,
  columns: 8,
  fill: (x,y) => if y == 0 or y == 1  {rgb(0, 174, 239)} else if x >= 1 and x <= 5 {rgb(247, 150, 70)} else if  x == 6 {rgb(141, 179, 227)},
  [name], table.cell(colspan: 6)[Field], [Comments],
  [(Field Size)],[7bits],[5bits],[5bits],[3bits],[5bits],[7bits],[],
  [R-type],table.cell(fill: rgb(141, 179, 227))[funct7],[rs2],[rs1],table.cell(fill: rgb(141, 179, 227))[funct3],[rd],[opcode],[Arithmetic instruction format],
  [I-type], table.cell(colspan: 2)[imm[11:0]],[rs1],table.cell(fill: rgb(141, 179, 227))[funct3],[rd],[opcode],[Loads & Immediate arithmetic],
  [S-type],[imm[11:5]],[rs2],[rs1],table.cell(fill: rgb(141, 179, 227))[funct3],[imm[4:0]],[opcode],[Stores],
  [SB-type],[imm[12,10:5]],[rs2],[rs1],table.cell(fill: rgb(141, 179, 227))[funct3],[imm[4:1,11]],[opcode],[Conditional branch format],
  [UJ-type],table.cell(colspan: 4)[imm[20,10:1,11,19:12]],[rd],[opcode],[Unconditional jump format],
  [U-type],table.cell(colspan: 4)[imm[31:12]],[rd],[opcode],[Upper immediate format]
)
- ALU 控制：两步走
  + 首先根据 opcode 生成 ALUOp 和 七位控制信号
  + 然后根据 ALUOp 和 funct7 生成 ALU control(ALU oepartion)
#tbl(
  columns: 7,
  [opcode],[ALUop],[Operation],[Funct7],[funct3],[ALU function],[ALU control],
  [ld],[00],[load register],[XXXXXXX],[xxx],[add],[0010],
  [sd],[00],[store register],[XXXXXXX],[xxx],[add],[0010],
  [beq],[01],[branch on equal],[XXXXXXX],[xxx],[subtract],[0110],
  table.cell(rowspan: 5)[R-type],table.cell(rowspan: 5)[10],[add],[0#redt[0]00000],[#redt[000]],[add],[0010],
  [subtract],[0#redt[1]00000],[#redt[000]],[subtract],[0110],
  [AND],[0#redt[0]00000],[#redt[111]],[AND],[0000],
  [OR],[0#redt[0]00000],[#redt[110]],[OR],[0001],
  [SLT],[0#redt[0]00000],[#redt[010]],[Slt],[0111],
)
#fig("/public/assets/Courses/CO/img-2024-04-03-11-32-05.png")
- 为不同指令解释控制信号（画错了？实现不了 jalr 和 lui）
#fig("/public/assets/Courses/CO/img-2024-04-10-10-30-25.png")
- 性能分析
  - 分支指令的计算是并行的，不怎么耗时间
  - 假设 memory(200ps), ALU and adders(200ps), register file access(100ps)
  - 最耗时间的是 load 指令
#tbl(
  columns: 7,
  [Instr],[Instr fetch],[Register read],[ALU op],[Memory access],[Register write],[Total time],
  [ld],[200ps],[100ps],[200ps],[200ps],[100ps],[800ps],
  [sd],[200ps],[100ps],[200ps],[200ps],[],[700ps],
  [R-format],[200ps],[100ps],[200ps],[],[100ps],[600ps],
  [beq],[200ps],[100ps],[200ps],[],[],[500ps],
)
- 每个周期的时间取决于最慢的 800ps
- 两个解决方法
  + 多周期（instr fetch 一个周期，register read 周期……），这样每个周期时间可以很短
  + 流水线（同一周期多条指令并行计算其不同阶段）

== Exception
- CPU 的工作流改变有两种
  + 可预见的(bne/beq, jal , etc)
  + 不可预见的(Exception and Interruption)
  - Exception: Arises within the CPU (e.g. overflow, undefined opcode, syscall)
  - Interrupt: From an external I/O controller
  - 有的时候会把二者混起来
  - 异常不一定是不好的，它是 CPU 指令的异步补充
- 当发生异常的时候，CPU 应该做什么？
  + 保护 CPU 现场（发生异常的指令，异常的原因），进入异常
  + 处理中断事件
  + 退出异常，恢复正常操作
  - 有点像 `jal`，跳过去，做完后还要回来
- RISC-V 如何处理异常
  - 一组专门处理异常的 CSR 寄存器（Control status registers, 4K 个）
  - CSR instructions
- RISC-V Privileged
  - Each privilege level has a core set of privileged ISA extensions
#tbl(
  columns: 6,
  [Level],[Encoding],[Name],[Abbreviation],[Intended Usage],[Description],
  [0],[00],[User/Application],[U],[用户模式],[用户操作层面],
  [1],[01],[Supervisor],[S],[监督模式],[操作系统],
  [2],[10],[Reserved/Hypervisor],[H],[保留],[虚拟机相关],
  [3],[11],[Machine],[M],[机器模式],[最底层]
)
- 权限模式的组合
  - M 是必要的（处理异常）
  - 每种模式有自己的 ISA 扩展
#tbl(
  columns: 3,
  [Number of levels],[Supported Modes],[Intended Usage],
  [1],[M],[Simple embedded systems],
  [2],[M, U],[Secure embedded systems],
  [3],[M, S, U],[Systems running Unix-like operating systems],
)
- Control and Status Registers (CSRs)
  - 12 位 csr 对应 4K 个 CSR 寄存器，其最高一二位指定读写模式，最高三四位指定 privilege mode
#tbl(
  columns: 5,
  [csr],[rs1],[funct3],[rd],[opcode],
  [12bits],[5bits],[3bits],[5bits],[7bits],
)
#tbl_white(
  columns: 5,
  fill: (x,y) => if y == 0 {rgb(51, 102, 204)},
  [CSR],[Privilege],[Abbr.],[Name],[Description],
  [0x300],[MRW],[mstatus],[Machine STATUS register\ 机器模式状态寄存器],[MIE、MPIE域标记中断全局使能],
  [0x304],[MRW],[mie],[Machine Interrupt Enable register\ 机器模式中断使能寄存器],[控制不同类型中断的局部使能],
  [0x305],[MRW],[mtvec],[Machine trap‐handler base address\ 机器模式异常入口基地址寄存器],[进入异常服务程序基地址],
  [0x341],[MRW],[mepc],[Machine exception program counter\ 机器模式异常PC寄存器],[异常断点PC地址],
  [0x342],[MRW],[mcause],[Machine trap cause register\ 机器模式原因寄存器],[处理器异常原因],
  [0x343],[MRW],[mtval],[Machine Trap Value register\ 机器模式异常值寄存器],[处理器异常值地址或指令],
  [0x344],[MRW],[mip],[Machine interrupt pending\ 机器模式中断挂起寄存器],[处理器中断等待处理],
)
- mstatus
  - xIE 控制全局的中断使能
  - xPIE 表示从上层跳过来，原本的中断使能
  - xPP 表示从什么调过来
#fig("/public/assets/Courses/CO/img-2024-04-15-08-28-43.png",width:97%)
- mie/mip
  - 相比相比 status 是更细粒度的中断控制
  - xyIE 表示 x 模式下 y 类型的中断使能(E: exception)
  - xyIP 表示 x 模式下 y 类型是否有悬挂着的未处理中断(P: pending)
#fig("/public/assets/Courses/CO/img-2024-04-15-08-32-37.png",width:97%)
- mtvec
  - 分两种模式，direct 和 vectored，用低两位指示
  - 所有的 exception 使用 direct 模式；只有 interrupt 才会使用 vectored 模式
#fig("/public/assets/Courses/CO/img-2024-04-15-08-35-32.png",width:97%)
- mepc
  - 存储处理 exception 或 interrupt 完后的 PC 值
  - Exception 是 +0，需要回来前更改 mepc，否则会陷入循环；interrupt 是 +4
#fig("/public/assets/Courses/CO/img-2024-04-15-08-37-01.png",width:97%)
- mcause
  #fig("/public/assets/Courses/CO/img-2024-04-15-08-38-50.png")
  - 从这张图也可以看出 exception 和 interrupt 的区别
  #fig("/public/assets/Courses/CO/img-2024-04-24-20-20-40.png")
- 中断优先级
  - 优先级高的先处理，低的 pending 悬挂
  - External interrupt > Software interrupt > Timer interrupt
- CSR Instruction
#tbl(
  columns: 7,
  [Instruction],[csr(12)],[rs1(5)],[funt3(3)],[rd(5)],[opcode(7)],[Description],
  [CSRRW],[csr],[rs1],[001],[rd],[1110011],[read and write],
  [CSRRS],[csr],[rs1],[010],[rd],[1110011],[read and set],
  [CSRRC],[csr],[rs1],[011],[rd],[1110011],[read and clean],
  [CSRRWI],[csr],[zimm],[101],[rd],[1110011],[read and write imm],
  [CSRRSI],[csr],[zimm],[110],[rd],[1110011],[read and set imm],
  [CSRRCI],[csr],[zimm],[111],[rd],[1110011],[read and clean imm],
)
- Interrupts Instruction
  - MRET: m-return
#fig("/public/assets/Courses/CO/img-2024-04-15-09-02-29.png")
- 中断处理
  - RISC-V处理器检测到异常，开始进行异常处理：
    - 停止执行当前的程序流，转而从 CSR 寄存器 mtvec 定义的PC地址开始执行；
    - 更新机器模式异常原因寄存器：mcause
    - 更新机器模式中断使能寄存器：mie
    - 更新机器模式异常PC寄存器：mepc
    - 更新机器模式状态寄存器：mstatus
    - 更新机器模式异常值寄存器：mtval（以上更新均有硬件完成）
  - 异常程序处理完成后，需要从异常服务程序中退出，并返回主程序
    - RISCV 中定义了一组退出指令 MRET，SRET，和 URET
  - 机器模式下退出异常（MIRET）程序流转而从 csr 寄存器 mepc 定义的 pc 地址开始执行
  - 同时硬件更新 csr 寄存器机器模式状态寄存器 mstatus
    - 寄存器 MIE 域被更新为当前 MPIE 的值：mie $<-$ mpie
    - MPIE 域的值则更新为1：MPIE $<-$ 1


= The Processor: part 2
- 之前说到，一个时钟周期内包含：Instruction memory $->$ register file $->$ ALU $->$ data memory $->$ register file
  - 多数时候某些步骤空置且不符合"Making the common case fast"，采用流水线解决
#info()[
  - Pipelining
  - Why pipelining
    - Pipelined datapath
    - Pipelined control
    - Pipeline Hazards
  - Pipelining with Exceptions
]
== Pipeline overview
- RISC-V Pipeline: 5 stages
  + IF: Instruction fetch from memory
  + ID: Instruction decode & register read
  + EX: Execute operation or calculate address
  + MEM: Access data memory operand
  + WB: Write result back to register
  - 根据资源划分阶段
  - 流水线的加速比最大能达到*流水线的阶段数*，即 $5$ 倍（理想情况下）
    - 后面会说明，由于流水线之间有 overhead，所以不可能达到这个值，也说明并不是阶段数越多越好
  #fig("/public/assets/Courses/CO/img-2024-04-24-10-08-51.png")
  - 标蓝表示占用，半标蓝表示占用一半（读右，写左）
  #fig("/public/assets/Courses/CO/img-2024-04-24-10-28-46.png")
- Pipelined CPU DataPath
  - 用蓝线画出的叫做 hazard（冒险），导致数据依赖，会影响流水线的顺序执行
  - 显然是简化的，非所有指令；而且是有错的，比如 load、R-type 指令的写回还需要让 rd 也一起跟着流水线走（后面会改）
  #fig("/public/assets/Courses/CO/img-2024-04-24-10-21-46.png")
  - 需要 pipeline registers 来存储中间结果，寄存器需要足够宽才能存下所有信息
    - PC 也可以看作是一个流水线寄存器
  #fig("/public/assets/Courses/CO/img-2024-04-24-10-33-33.png")
- Pipeline的问题
  + Latency
  + Imbalance，如浮点计算所需的时间明显比一般指令长
  + Pipeline hazards
  + Overhead: register delay and clock skew
- Pipeline Diagram 的不同视图
  - 单个指令的数据流通
  - 多个指令的占用图
  - Pipelined 视图
- 控制信号的 pipeline
  - 把控制信号分类到各个阶段，跟随 pipeline registers 一起流动

== Hazard 处理
- hazards
  - structure hazard: 两个指令同时用到了同一个硬件资源，一般较好解决，不考虑
    - 假设 Instr_mem 和 Data_mem 是同一个硬件，那么就会有冲突
    - register file 也会有冲突，使用 double bump 技术，上升沿和下降沿各自控制读写
    #fig("/public/assets/Courses/CO/img-2024-04-24-11-28-24.png")
  - data hazard: 两个指令之间有数据依赖，需要等待前一条指令完成
    - 后面的 add 用到前面 add 的结果，需要等待（但是 IM 可以执行）
    #fig("/public/assets/Courses/CO/img-2024-04-24-11-35-50.png")
  - control hazard: branch 或 jump 指令
- 解决所有 hazard 的最简单方法就是 stall，即等待前一条指令完成
  - Control hazard:
    - Instruction in IF/ID or ID/EX or EX/MEM is a Branch or JMP
  - Data hazard:
    - RD of Instruction in EX/MEM == Rs1 or Rs2 of instruction in ID/EX
    - RD of Instruction in MEM/WB == Rs1 or Rs2 of instruction in ID/EX
- 如何产生 stall
  - 编译器层面添加 nop 指令
  - 硬件层面添加 detect unit，检测到 hazard 时，让指令可以继续流动，但是不 update registers
- 考虑 stall 的 pipeline 性能分析
  - ...
- 下面讨论更详细的 hazard 处理
=== structural hazard
  - Multiple accesses to memory
  -  Multiple accesses to the register file(double bump)
  - fully pipelined function unit
    #fig("/public/assets/Courses/CO/img-2024-04-24-12-06-30.png")
  - 实际情况下 structural hazard 往往不会被处理
    + To reduce cost
    + To reduce latency of the unit

=== Data Hazard
- 后一条指令用到前一条指令的结果
#fig("/public/assets/Courses/CO/img-2024-05-08-10-08-51.png")
- 使用 forwarding(also called bypassing) 来解决
  - 从 EX/MEM 前递
  #fig("/public/assets/Courses/CO/img-2024-05-08-10-11-13.png")
  - 从 MEM/WB 前递，仍需要一个 stall
  #fig("/public/assets/Courses/CO/img-2024-05-08-10-17-47.png")
- 下面是一个略复杂的例子
#grid(
  columns: (.7fr, 1fr),
  [
    #align(center, block(inset: 4pt, fill: colors.gray)[
      sub #bluet[x2],x1,x3 \
      and x12,#bluet[x2],x5 \
      or x13,x6,#bluet[x2] \
      add x14,#bluet[x2],#bluet[x2] \
      sd x15,100(#bluet[x2]) \
    ])
    - 蓝线往前指说明产生了 Data Hazard；同一层级可以用 double bump 解决；往后指不会产生 hazard
    - `and` 和 `or` 可以用 forwarding 解决，红线标出
  ],
  fig("/public/assets/Courses/CO/img-2024-05-08-10-25-08.png")
)
- Detecting the Need to Forward
  - Data hazards when
    $ cases(reverse: #true, "EX/MEM.RegisterRd = ID/EX.RegisterRs1",
      "EX/MEM.RegisterRd = ID/EX.RegisterRs2") #block[Fwd from \ EX/MEM \ pipeline reg] \
      cases(reverse: #true, "MEM/WB.RegisterRd = ID/EX.RegisterRs1",
      "MEM/WB.RegisterRd = ID/EX.RegisterRs2")  #block[Fwd from \ MEM/WB \ pipeline reg] $
  - But only if forwarding instruction will write to a register!
    -  EX/MEM.RegWrite, MEM/WB.RegWrite
  - And only if Rd for that instruction is not x0
    - EX/MEM.RegisterRd != 0, MEM/WB.RegisterRd != 0
  - 并且 EX/MEM 的优先级更高（考虑 Double Data Hazard 的情况）
    #align(center, block(inset: 4pt, fill: colors.gray)[
      add #bluet[x1],x1,x2 \
      add #bluet[x1],#bluet[x1],x3 \
      add x1,#bluet[x1],x4
    ])
- DataPath for forwarding 简图（没画 Imm_Gen 等）
#fig("/public/assets/Courses/CO/img-2024-05-08-10-43-05.png")
- Load-Use Dependency
  - Dependence between load and the following instructions
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-05-22.png")
  - 之前说到，一个 ALU 相关指令的前一条指令是 load 且恰好用到其寄存器时，需要 stall 一个周期，可以 Reorder code to avoid use of load result in the next instruction（编译器优化）
    #fig("/public/assets/Courses/CO/img-2024-05-08-10-58-19.png")
  - Load-use hazard when
    -  ID/EX.MemRead and
      - ID/EX.RegisterRd = IF/ID.RegisterRs1 or ID/EX.RegisterRd = IF/ID.RegisterRs2
  - The performance influence of load stall
    - 假设 $30%$ 的指令是 load，其中有一半紧跟着一条用到 load 的 result 的指令，且 hazard 导致 one single cycle delay
    - $"CPI" = 1+30% times 50% times 1=1.15$，性能降低 $15%$
- 以上考虑的是 ALU 相关 Data dependency 和 Load 指令 dependency，还有别的，比如 Store-use，不过类似
- How to Stall the Pipeline
  - 锁定 pipeline registers，让它们不被更改（相当于下个周期继续做这条指令）
  - 这个周期内用到的数据可以用 MUX 设为无效值（即这个周期随便做一做）
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-15-15.png")
- DataPath for Hazard-detection and reg-disable
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-18-16.png")

=== Control Hazards
- 控制指令依赖于先前的指令，比如 Branches
  - 中间的三条指令白做了，需要 flush 掉（流水线*冲掉*流水），相当于 $3$ 次 stall
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-23-34.png")
- 解决方法
  - stall，碰到 branch 就停 $3$ 拍，简单无脑但比较浪费
  - Static Prediction
    + Predict-untaken: treat every branch as not taken
    + Predict-taken: treat every branch as taken
  - Reducing Branch Delay
  - Dynamic Branch Prediction
- Solution: stall
  ```verilog
  if (Branch_ID=1 or Jump_ID=1) ||
     (Branch_IDEX 1 or Jump_IDEX 1) ||
     (Branch_EXMem=1 or Jump_EXMem 1)
    Control_Stall = 1;
  if (Control_Stall) begin
    NOP_IFID = 1;
  end else begin
    NOP_IFID = 10
  end
  ```
  - 假设 $30%$ 的指令是 branch，$"CPI" = 1+30% times 3 = 1.9$
- Predict-not-taken
  - $"Performance" = 1+ "br"% times "take"% times 3$
- Solution: Reducing Branch Delay
  - Move the Branch Computation Forward，用硬件换时间，在 IF/ID 阶段算 branch 结果
  - Target address adder & Register comparator
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-44-39.png")
  - 例子：
    - 当前周期为：\<old inst(not taken)\>, beq, sub, before\<1\>, before\<2\>
    - 下一个周期为：\<new inst(taken)\>, Bubble(nop), beq, sub, before\<1\>
  #fig("/public/assets/Courses/CO/img-2024-05-08-11-48-47.png")
  - 然而实际情况会更复杂，考虑 branch 指令跟前面指令的 data hazard
    + branch 是先前指令后的第二第三条，用 forwarding
      #fig("/public/assets/Courses/CO/img-2024-05-08-11-54-33.png")
    + branch 是先前 ALU 指令后紧跟的一条或 load 指令后的第二条，要 stall 一个周期
      #fig("/public/assets/Courses/CO/img-2024-05-08-11-57-23.png")
    + branch 是先前 load 指令后紧跟的一条，要 stall 两个周期
      #fig("/public/assets/Courses/CO/img-2024-05-08-11-58-06.png")
- More-Realistic Branch Prediction
  - Static branch prediction
    - Based on typical branch behavior; Example: loop and if-statement branches
  - Dynamic branch prediction
    - Hardware measures actual branch behavior; Assume future behavior will continue the trend
  - Predictors
    - 1 bit: 每次错了都改变结果，错误率较高（墙头草是这样的）
    - 2 bit: 错两次之后改变结果
      #fig("/public/assets/Courses/CO/img-2024-05-08-12-05-25.png")
  - 为实现时的简单起见，我们假定不跳转，即 predict-not-taken

== Pipelining with Exceptions
- 考虑指令 ```assembly add x1, x2, x1```，我们阻止 x1 被更改
  - 完成先前的指令，Flush *add* 指令和之后的指令
  - Set Cause and SEPC register values (triky，很困难)
  - Transfer control to handler，跟 mispredicted branch 类似
- Multiple Exceptions
  - 流水线可以同时发生多个异常，如何定位这些异常是哪条指令产生的？如何去处理这多个异常？
  - 如果可以确定异常产生的指令并一一处理，那么就称为 precise exception
  - 在更复杂的流水线中（多发射、乱序执行），precise exception 是一个很大的挑战

