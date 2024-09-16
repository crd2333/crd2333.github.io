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

= Chapter 1: Computer Abstractions and Technology
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

= Chapter 2: Instructions——Language of the Computer

#info(caption: "Contents of Chapter 2")[
2.1 Introduction \
2.2 Operations of the Computer Hardware \
2.3 Operands of the Computer Hardware \
2.4 Representing Instructions in the Computer \
2.5 Logical Operation \
2.6 Instructions for Making Decisions \
2.7 Supporting Procedures in Computer Hardware \
2.8 Communicating with People \
2.9 MIPS Addressing for 32 Bit Immediates and Addresses \
2.10 Translanting and starting a Program \
2.11 \*How Compilers Optimize \
2.12 \*How Compilers Work \
2.13 A C Sort Example to Put It All together \
2.14 \*Implementing an Object-Oriented Language \
2.15 Arrays Versus Pointers \
2.16 Real Stuff: IA-32 Instructions \
2.17 Fallacies and Pitfalls \
2.18 Concluding Remarks \
2.19 Historical Perspective and Further Reading
]

== Introduction
- Instruction characteristics
  - 处理器的内存类型：
    - stack, accumulator, general purpose register(register-memory, register-register: load / store)
  - 指令中对 memory 的操作数
    - 三种类型: register-register, register-memory, memory-memory
  - Operations in the instruction Set
  - Type and Size of Operands
  - Representation in the Computer
  - Encoding
- 变量区分
  - 高级语言如 C 中有 int, char, float 等区分
  - 但在硬件上，直接用存储硬件的方式来区分：register, memory address(Displacement + Immediate), stack

== Operations of the Computer Hardware
- #redt[Design Principle 1]: *Simplicity favors regularity*（简单源自规整，指令包含3个操作数）
- 这里以 add 和 sub 为例

== Operands of the Computer Hardware
- Register Operands
  - 寄存器的位数：32 / 64
  - #redt[Design Principle 2]: *Smaller is faster*（越少越快，寄存器个数一般不超过32个，因为寄存器地址一般是定长 encode，太多会增大 encode 消耗）

#let register_tbl = tbl_white(
  content_size: 10pt,
  columns: 4,
  fill: (x,y) => if y == 0 {rgb(153, 153, 0)},
  [Name],[Register name],[Usage],[Preserved on calls],
  [x0],[0],[The constant value 0],[n.a.],
  [x1(ra)],[1],[Return address(link register)],[yes],
  [x2(sp)],[2],[Stack pointer],[yes],
  [x3(gp)],[3],[Global pointer],[yes],
  [x4(tp)],[4],[Thread pointer],[yes],
  [x5-x7 & x28-x31],[5-7, 28-31],[Temporary registers],[no],
  [x8-x9 & x18-x27],[8-9, 18-27],[Saved registers],[yes],
  [x10-x17],[10-17],[Arguments / Results],[no],
)

  #register_tbl
  - RISC-V operands
    #fig("/public/assets/Courses/计组/img-2024-03-18-08-35-48.png", width: 60%)
- Memory Operands
  - 优势：可以存更多数据、可以存更复杂更灵活的数据结构
  - 需要 load / store 跟 register 交互
  - Memory is byte addressed: Each address identifies an 8-bit byte
  - 大端与小端（相对主流），RISC-V is Little endian
    #fig("/public/assets/Courses/计组/img-2024-03-18-08-39-19.png", width: 84%)
  - Memory Alignment
    #fig("/public/assets/Courses/计组/img-2024-03-18-08-53-14.png", width: 80%)
    - 不过 RISC-V 没有对齐的要求
- Constant or Immediate Operand
  - 对于常数或立即数，如果放在 memory 中，每次都要 load，效率低，为此定义了立即数指令，如 addi
    $ "addi" "x22", "x22", 4 med med \/\/ "x22"= "x22" + 4 $
  - #redt[Design Principle 3]：Make the common case fast

== Signed and Unsigned Numbers
- 略

== Representing Instructions in the Computer
- 从汇编指令到机器码(machine code)
  #fig("/public/assets/Courses/计组/img-2024-03-18-09-18-59.png")
  - 上面这种例子是 R-format
  #fig("/public/assets/Courses/计组/img-2024-03-18-09-20-46.png", width: 60%)
- #redt[Design Principle 4]: Good design demands good compromises（好的设计需要折中）
- 对于立即数，可以看到 R-format 只有 5 位来表示，范围太小了，因此定义了 I-format，范围变为 $+- 2^11$
  #fig("/public/assets/Courses/计组/img-2024-03-18-09-25-07.png", width: 60%)
- 对 store 操作有 S-format，把不需要的目标寄存器 rd 空出来给立即数，这里图片有错，应为$"imm"[11:5]$, #redt[$5"bits"$]
  #fig("/public/assets/Courses/计组/img-2024-03-18-09-28-18.png", width: 70%)
- 归纳：
  #fig("/public/assets/Courses/计组/img-2024-03-18-09-34-46.png")
- Stored-program

#wrap-content(fig("/public/assets/Courses/计组/img-2024-03-20-10-13-14.png", width: 48%))[
- 当今计算机的两个 key principle
  - Instructions are represented as numbers
  - Programs can be stored in memory like numbers
- Instruction 和 program 都以数字形式存储在 memory 中，program 可以对 program 进行操作（也因此带来一定危险性）
- 二进制的兼容性允许在不同计算机上运行同一段程序
]

== Logical Operations
- 略

== Instructions for Making Decisions
- Branch instructions, 判断寄存器值是否相等，跳转到 L1 标号的指令
  1. (branch equal) beq register1, register2, L1
  2. (branch not equal) bne register1, register2, L1
  3. (branch less than) blt rs1, rs2, L1
  4. (branch greater or equal) bge rs1, rs2, L1
```c
if (i == j) f = g + h; else f = g – h;
```
```assembly
bne x22, x23, ELSE       // go to ELSE if i != j
add x19, x20, x21        // f = g + h ( skipped if i not equals j )
beq x0, x0, EXIT         // no-condition jump
ELSE: sub x19, x20, x21  // f = g - h ( skipped if i equals j )
EXIT:
```
- 如果没有 blt 和 bge，可以用这样的方式曲线救国
  - RISC-V 是有的，不过不一定有这种分拆的方式快
#fig("/public/assets/Courses/计组/img-2024-03-20-10-42-08.png", width: 59%)
- 界限检查的小 trick
  - `If (x20>=x11 | x20 < 0) goto IndexOutofBounds`
  - 用 `bgeu x20, x11, IndexOutofBounds`，当做无符号数处理（当 x11 为正数）
- case, switch: jump address table(use `jalr`)
```c
switch (k) {
  case 0 : f = i + j ; break ; /* k = 0 */
  case 1 : f = g + h ; break ; /* k = 1 */
  case 2 : f = g - h ; break ; /* k = 2 */
  case 3 : f = i - j ; break ; /* k = 3 */
}
```
#fig("/public/assets/Courses/计组/img-2024-03-20-11-13-01.png", width:60%)

== Supporting Procedures in Computer Hardware
- Procedure/function --- be used to structure programs
- Six steps
  1. Place Parameters where the procedure can access them(in registers x10 \~ x17)
  2. Transfer control to the procedure
  3. Acquire the storage resources needed for the procedure
  4. Perform the desired task
  5. Place the result value in a place where the calling program can access it
  6. Return control to the point of origin(address in x1)
- Procedure call（*调用*）: jump and link(jal)
  - ```assembly jal x1, ProcedureLabel``` 跳转到某一标号，并将当前地址存入 x1
- Procedure return（*返回*）: jump and link register(jalr)
  - ```assembly jalr x0, 0(x1)``` 跳转到 x1 中存储的地址，并将当前地址存入 x0（弃用）
- Stack（栈）：Ideal data structure for spilling registers
  - stack pointer(sp): x2
  - Push: sp= sp-8; Pop: sp = sp+8（因为栈是从上往下存）
- Register Usage
  - x5 – x7, x28 – x31: temporary registers
    - Not preserved by the callee，子程序想用这些寄存器可以直接覆盖
  - x8 – x9, x18 – x27: saved registers
    - If used, the callee saves and restores them，子程序需要先压栈再使用，用完恢复
- Leaf Procedures & Non-Leaf Procedures: 叶子程序不会调用其它程序
  - 对 Non-Leaf Procedures，如递归函数，return address, Any arguments and temporaries needed *after the call* 需要被压栈保存，在子程序结束后恢复（函数调用栈）
    - 一个误区，之前以为 temporaries 完全不用保护，实际上指的是子函数可以直接覆盖，父函数还是要保护一下它们的。设想调用子程序后还有操作（非尾递归），此时恢复 temporary 就很有必要
```c
long long fact (long long n) {
    if (n < 1) return 1;
    else return (n * fact(n - 1));
}
```
```assembly
fact: addi sp, sp, -16 // adjust stack for 2 items
      sd x1, 8(sp)     // save the return address
      sd x10, 0(sp)    // save the argument n
      addi x5, x10, -1 // x5 = n - 1
      bge x5, x0, L1   // if n >= 1, go to L1(else)
      addi x10, x0, 1  // return 1 if n <1
      addi sp, sp, 16  // Recover sp (Why not recover x1 and x10?)
      jalr x0, 0(x1)   // return to caller
L1: addi x10, x10, -1  // n >= 1: argument gets (n - 1)
    jal x1, fact       // call fact with (n - 1)
    add x6, x10, x0    // copy the return value（这里就是为什么返回值和参数能一起存）
    ld x10, 0(sp)      // restore argument n
    ld x1, 8(sp)       // restore the return address
    addi sp, sp, 16    // adjust stack pointer to pop 2 items
    mul x10, x10, x6   // return n*fact (n - 1)
    jalr x0, 0(x1)     // return to the caller
```
- 小测的例子，更清晰（x10 为参数，x11 为返回值）：
```C
int sum(int n) {
  if (n == 0) return 0;
  else return n + sum(n - 1);
}
```
```assembly
        addi x11, x0, 0      // 初始化
sum:    addi sp, sp, -8      // 保存之前的参数和返回值
        sw x1, 4(sp)
        sw x10, 0(sp)
        beq x10, x0, Return  // 如果 n = 0，直接返回，否则还要调用 sum(n-1)
        addi x10, x10, -1
        jal x1, sum
        lw x10, 0(sp)
        lw x1, 4(sp)
        add x11, x11, x10
Return: add sp, sp, 8
        jalr x0, 0(x1)
```

- Storage class of C variables: automatic（动态变量）, static（静态变量）
  - Procedure frame and frame pointer (x8 or fp)
    - The importance of fp，帧指针(frame pointer)跟 sp 指向同一块地方，不同之处在于 fp 相对固定，一般以 fp 作为基地址查找动态变量
    - automatic
  - Global pointer (x3 or gp)
    - static
- 内存布局
#fig("/public/assets/Courses/计组/img-2024-03-20-12-08-58.png")

== Communicating with People
- Byte-encoded character sets
  - ASCII, Latin-1
  - Unicode: 16-bit/32-bit character set
- Byte / Halfword / Word Operations
  - lb, lh, lw, sb, sh, sw: 8-bit, 16-bit, 32-bit
- String 表示
  - 三种方法
    1. 在第一位存放长度（如 Java）
    2. 变量伴随长度
    3. 用特殊字符结尾（如 C）

== RISC-V Addressing for Wide Immediate and Addresses
- 大多数情况下，12-bit 的立即数是够用的，但也存在例外
- lui (load upper immediate)指令 (belong to U-format)
  - lui: ```assembly lui rd, constant```，将 constant 的高 20 位放到 rd 中
  - 剩下的低 12 位用 addi 补充（注意符号，可能要用 addiu 或 or）
#fig("/public/assets/Courses/计组/img-2024-03-27-10-24-35.png", width: 80%)
- Branch Addressing（分支指令跳转）
  - SB-Format(B-format)
    - 在相对当前指令 $+-2^12$ bits 的范围内跳转
#fig("/public/assets/Courses/计组/img-2024-03-27-10-33-24.png", width: 80%)
- branch 跳转在循环中常用，因为循环体一般不会写太大。而函数调用这种需要更大的跳转范围:
- Jump Addressing（无条件跳转）
  - UJ-Format(J-format)
    - 20-bit immediate, 12-bit offset
    - 在相对当前指令 $+-2^20$ bits 的范围内跳转
    - 如果 beq(B-format)不够，化为 bne+jal；如果还不够，用 lui+ jalr
#fig("/public/assets/Courses/计组/img-2024-03-27-10-38-41.png", width: 80%)
- 例子：```C while (save[i]==k) i=i+1;``` in c
```assembly
Loop: slli x10, x22, 3  // temp reg x10 = 8 * i
      add x10, x10, x25 // x10 = address of save[i]
      ld x9, 0(x10)     // temp reg x9 = save[i]
      bne x9, x24, Exit // go to Exit if save[i] != k
      addi x22, x22, 1  // i = i + 1
      beq x0, x0, Loop  // go to Loop
Exit:
```
#fig("/public/assets/Courses/计组/img-2024-03-27-11-00-51.png", width: 80%)
- 反汇编，先看后 7 位确定 opcode，再 $dots$

== Parallelism and Instructions: Synchronization
- 考虑多进程之间的竞争，solutions:
  - synchronization: mutual exclusion、semaphore ...
  - atomic exchange or atomic swap (instructions in RISC-V: lr.d and sc.d)
- Load reserved: `lr.d rd,(rs1)`, Load from address in rs1 to rd
- Store conditional: `sc.d rd,(rs1),rs2`, Store from rs2 to address in rs1
  - 当 `rs1` 自从 lr.d 之后没有被改变过时，视为成功
  - 检查 rd 是 1 还是 0，来确定是否成功（成功返回0）
- 例子：atomic swap (to test/set lock variable) & lock
```assembly
// atomic swap
again: lr.d x10,(x20)
       sc.d x11,(x20),x23 // X11 = status
       bne x11,x0,again   // branch if store failed
       addi x23,x10,0     // X23 = loaded value
// lock
       addi x12,x0,1      // copy locked value
again: lr.d x10,(x20)     // read lock
       bne x10,x0,again   // check if it is 0 yet
       sc.d x11,(x20),x12 // attempt to store
       bne x11,x0,again   // branch if fails
// unlock
       sd x0,0(x20)       // free lock
```

== Translating and Starting a Program
#fig("/public/assets/Courses/计组/img-2024-03-27-11-30-00.png")
- Compiling & Assembling
- Obeject File & Linking Object Modules（静态）
- Loading a Program 的步骤
- Dynamic Linking
- Lazy Linkage
- Java Applications（解释型语言，跟 C 的方式不太一样）

== A C Sort Example To Put it All Together
- 直接看 PPT

== Arrays versus Pointers
- array 对 index 操作，然后乘8加到地址上，而 pointer 直接对地址操作
  - 例子（注意这里其实得在循环开始前做个判断，否则数组的第一个元素一定会被赋值）
#tbl(
  columns: (.9fr, 1fr),
[```C
clear1(int array[], int size) {
  int i;
  for (i = 0; i < size; i += 1)
  array[i] = 0;
}
```],
[
```c
clear2(int *array, int size) {
  int *p;
  for (p = &array[0]; p < &array[size];
  p = p + 1)
  *p = 0;
}
```],
[```assembly
li x5,0          // i = 0
loop1:
slli x6,x5,3     // x6 = i * 8
add x7,x10,x6    // x7 = address
                 // of array[i]
sd x0,0(x7)      // array[i] = 0
addi x5,x5,1     // i = i + 1
blt x5,x11,loop1 // if (i<size)
                 // go to loop1
```],
[```assembly
mv x5,x10        // p = address of array[0]
slli x6,x11,3    // x6 = size * 8
add x7,x10,x6    // x7 = address
                 // of array[size]
loop2:
sd x0,0(x5)      // Memory[p] = 0
addi x5,x5,8     // p = p + 8
bltu x5,x7,loop2 // if (p<&array[size])
                 // go to loop2
```]
)
- 比较
  - Array version requires shift to be inside loop，所以用指针会更好
  - 但实际上编译器会自动优化，所以程序员只需关注代码的可读性和安全性

== Real Stuff: MIPS Instructions
- MIPS: commercial predecessor to RISC-V
#fig("/public/assets/Courses/计组/img-2024-04-01-08-20-00.png", width: 89%)
- 大致相同的基本指令集，但 conditional branches 不同
  - For <, <=, >, >=
  - RISC-V: blt, bge, bltu, bgeu
  - MIPS: slt, sltu (set less than, result is 0 or 1)
  - Then use beq, bne to complete the branch
- Instruction Encoding（指令的写法类似，但编码不一样）

== Real Stuff: The Intel x86 ISA
- Evolution with backward compatibility
- Two operands per instruction
  - 每条指令都是两个操作数，不区分目标和源，并且支持很多（复杂指令集）
  - 指令长度也是可变的
#tbl(
  columns:2,
  [Source/dest operand],[Second source operand],
  [Register],[Register],
  [Register],[Immediate],
  [Register],[Memory],
  [Memory],[Register],
  [Memory],[Immediate]
)
- Memory addressing modes
  - $"Address"$ in $"register"$
  - $"Address" = "R"_"base" + "displacement"$
  - $"Address" = "R"_"base" + 2^"scale" times "R"_"index" ("scale" = 0, 1, 2, "or" 3)$
  - $"Address" = "R"_"base" + 2^"scale" times "R"_"index" + "displacement"$
- 把复杂指令 translate to 微操作(microoperations)

== Other RISC-V Instructions
- 回到 RISC-V
- Base integer instructions (RV64I)
  - ```assembly auipc rd, immed // rd = (imm << 12) + pc```
  - slt, sltu, slti, sltui: set less than
  - addw, subw, addiw: 对低32位操作
- 32-bit variant: RV32I: registers are 32-bits wide, 32-bit operations
- Instruction Set Extensions
  - M: integer multiply, divide, remainder
  - A: atomic memory operations
  - F: single-precision floating point
  - D: double-precision floating point
  - C: compressed instructions

== Fallacies and Pitfalls
- Fallacies
  - Powerful instruction $=>$ higher performance
  - assembly code $=>$ higher performance
- Pitfalls
  - Sequential words are not at sequential addresses(4! not 1)
  - Keeping a pointer to an automatic variable after procedure returns

== Summary
- Two principles of stored-program computers
  - Use instructions as numbers
  - Use alterable memory for programs
- Four design principles
  - Simplicity favors regularity
  - Smaller is faster
  - Good design demands good compromises
  - Make the common case fast
- 寄存器归纳
  #register_tbl
- 指令格式归纳
#tbl_white(
  white_row: 2,
  columns: 8,
  fill: (x,y) => if y == 0 or y == 1  {rgb(0, 174, 239)},
  [name], table.cell(colspan: 6)[Field], [Comments],
  [(Field Size)],[7bits],[5bits],[5bits],[3bits],[5bits],[7bits],[],
  [R-type],[funct7],[rs2],[rs1],[funct3],[rd],[opcode],[Arithmetic instruction format],
  [I-type], table.cell(colspan: 2)[imm[11:0]],[rs1],[funct3],[rd],[opcode],[Loads & Immediate arithmetic],
  [S-type],[imm[11:5]],[rs2],[rs1],[funct3],[imm[4:0]],[opcode],[Stores],
  [SB-type],[imm[12,10:5]],[rs2],[rs1],[funct3],[imm[4:1,11]],[opcode],[Conditional branch format],
  [UJ-type],table.cell(colspan: 4)[imm[20,10:1,11,19:12]],[rd],[opcode],[Unconditional jump format],
  [U-type],table.cell(colspan: 4)[imm[31:12]],[rd],[opcode],[Upper immediate format]
)
- 指令集编码归纳

#tbl_white(
  columns: 6,
  fill: (x,y) => if y == 0 {rgb(153, 204, 0)} else if x == 0 {rgb(222, 235, 203)},
  [Format],[Instruction],[Opcode],[Funct3],[Funct6/7],[Description],
  table.cell(rowspan: 10)[R-type],[add],[0110011],[000],[0000000],[addition],
  [sub],[0110011],[000],[0100000],[subtraction],
  [sll],[0110011],[001],[0000000],[shift left logical],
  [xor],[0110011],[100],[0000000],[xor],
  [srl],[0110011],[101],[0000000],[shift right logical],
  [sra],[0110011],[101],[0100000],[shift right arithmetic],
  [or],[0110011],[110],[0000000],[or],
  [and],[0110011],[111],[0000000],[and],
  [lr.d],[0110011],[011],[0001000],[load reserved],
  [sc.d],[0110011],[011],[0001100],[store conditional],
  table.cell(rowspan: 17)[I-type],[lb],[0000011],[000],[n.a.],[load byte],
  [lh],[0000011],[001],[n.a.],[load halfword],
  [lw],[0000011],[010],[n.a.],[load word],
  [ld],[0000011],[011],[n.a.],[load doubleword],
  [lbu],[0000011],[100],[n.a.],[load byte unsigned],
  [lhu],[0000011],[101],[n.a.],[load halfword unsigned],
  [lwu],[0000011],[110],[n.a.],[load word unsigned],
  [addi],[0010011],[000],[n.a.],[add immediate],
  [slli],[0010011],[001],[000000],[shift left logical immediate],
  [slti],[0010011],[010],[n.a.],[set less than immediate],
  [sltiu],[0010011],[011],[n.a.],[set less than immediate unsigned],
  [xori],[0010011],[100],[n.a.],[xor immediate],
  [srli],[0010011],[101],[000000],[shift right logical immediate],
  [srai],[0010011],[101],[010000],[shift right arithmetic immediate],
  [ori],[0010011],[110],[n.a.],[or immediate],
  [andi],[0010011],[111],[n.a.],[and immediate],
  [jalr],[1100111],[000],[n.a.],[jump and link register],
  table.cell(rowspan: 4)[S-type],[sb],[0100011],[000],[n.a.],[store byte],
  [sh],[0100011],[001],[n.a.],[store halfword],
  [sw],[0100011],[010],[n.a.],[store word],
  [sd],[0100011],[011],[n.a.],[store doubleword],
  table.cell(rowspan: 6)[SB-type],[beq],[1100011],[000],[n.a.],[branch equal],
  [bne],[1100011],[001],[n.a.],[branch not equal],
  [blt],[1100011],[100],[n.a.],[branch less than],
  [bge],[1100011],[101],[n.a.],[branch greater or equal],
  [bltu],[1100011],[110],[n.a.],[branch less than unsigned],
  [bgeu],[1100011],[111],[n.a.],[branch greater or equal unsigned],
  table.cell(rowspan: 2)[U-type],[lui],[0110111],[n.a.],[n.a.],[load upper immediate],
  [auipc],[0010111],[n.a.],[n.a.],[Add Upper Imm to PC],
  [UJ-type],[jal],[1101111],[n.a.],[n.a.],[jump and link],
)
- 指令集归纳

#tbl_white(
  content_size: 8pt,
  columns: 5,
  fill: (x,y) => if y == 0 {rgb(0, 173, 238)},
  [Category],[Instruction],[Example],[Meaning],[Comments],
  table.cell(rowspan: 3)[Arithmetic],[add],[```assembly add x5,x6,x7```],[x5=x6 + x7],[Add two source register operands],
  [subtract],[```assembly sub x5,x6,x7```],[x5=x6 - x7],[First source register subtracts second one],
  [add immediate],[```assembly addi x5,x6,20```],[x5=x6+20],[Used to add constants],
  table.cell(rowspan: 15)[Data transfer],[load doubleword],[```assembly ld x5, 40(x6)```],[x5=Memory[x6+40]],[doubleword from memory to register],
  [store doubleword],[```assembly sd x5, 40(x6)```],[Memory[x6+40]=x5],[doubleword from register to memory],
  [load word],[```assembly lw x5, 40(x6)```],[x5=Memory[x6+40]],[word from memory to register],
  [load word, unsigned],[```assembly lwu x5, 40(x6)```],[x5=Memory[x6+40]],[Unsigned word from memory to register],
  [store word],[```assembly sw x5, 40(x6)```],[Memory[x6+40]=x5],[word from register to memory],
  [load halfword],[```assembly lh x5, 40(x6)```],[x5=Memory[x6+40]],[Halfword from memory to register],
  [load halfword, unsigned],[```assembly lhu x5, 40(x6)```],[x5=Memory[x6+40]],[Unsigned halfword from memory to register],
  [store halfword],[```assembly sh x5, 40(x6)```],[Memory[x6+40]=x5],[halfword from register to memory],
  [load byte],[```assembly lb x5, 40(x6)```],[x5=Memory[x6+40]],[byte from memory to register],
  [load bite, unsigned],[```assembly lbu x5, 40(x6)```],[x5=Memory[x6+40]],[Unsigned byte from memory to register],
  [store byte],[```assembly sb x5, 40(x6)```],[Memory[x6+40]=x5],[byte from register to memory],
  [load reserved],[```assembly lr.d x5,(x6)```],[x5=Memory[x6]],[Load;1st half of atomic swap],
  [store conditional],[```assembly sc.d x7,x5,(x6)```],[Memory[x6]=x5; x7 = 0/1],[Store;2nd half of atomic swap],
  [load upper immediate],[```assembly lui x5,0x12345```],[x5=0x12345000],[Loads 20-bits constant shifted left 12 bits],
  [auipc],[```assembly auipc x5,0x12345```],[x5=0x12345000+PC],[Loads 20-bits constant shifted left 12 bits plus PC],
  table.cell(rowspan: 6)[Logical],[and],[```assembly and x5, x6, x7```],[x5=x6 & x7],[Arithmetic shift right by register],
  [inclusive or],[```assembly or x5,x6,x7```],[x5=x6 | x7],[Bit-by-bit OR],
  [exclusive or],[```assembly xor x5,x6,x7```],[x5=x6 ^ x7],[Bit-by-bit XOR],
  [and immediate],[```assembly andi x5,x6,20```],[x5=x6 & 20],[Bit-by-bit AND reg. with constant],
  [inclusive or immediate],[```assembly ori x5,x6,20```],[x5=x6 | 20],[Bit-by-bit OR reg. with constant],
  [exclusive or immediate],[```assembly xori x5,x6,20```],[X5=x6 ^ 20],[Bit-by-bit XOR reg. with constant],
  table.cell(rowspan: 6)[Shift],[shift left logical],[```assembly sll x5, x6, x7```],[x5=x6 << x7],[Shift left by register],
  [shift right logical],[```assembly srl x5, x6, x7```],[x5=x6 >> x7],[Shift right by register],
  [shift right arithmetic],[```assembly sra x5, x6, x7```],[x5=x6 >> x7],[Arithmetic shift right by register],
  [shift left logical immediate],[```assembly slli x5, x6, 3```],[x5=x6 << 3],[Shift left by immediate],
  [shift right logical immediate],[```assembly srli x5,x6,3```],[x5=x6 >> 3],[Shift right by immediate],
  [shift right arithmetic immediate],[```assembly srai x5,x6,3```],[x5=x6 >> 3],[Arithmetic shift right by immediate],
  table.cell(rowspan: 6)[Conditional branch],[branch if equal],[```assembly beq x5, x6, 100```],[if(x5 == x6) go to PC+100],[PC-relative branch if registers equal],
  [branch if not equal],[```assembly bne x5, x6, 100```],[if(x5 != x6) go to PC+100],[PC-relative branch if registers not equal],
  [branch if less than],[```assembly blt x5, x6, 100```],[if(x5 < x6) go to PC+100],[PC-relative branch if registers less],
  [branch if greater or equal],[```assembly bge x5, x6, 100```],[if(x5 >= x6) go to PC+100],[PC-relative branch if registers greater or equal],
  [branch if less, unsigned],[```assembly bltu x5, x6, 100```],[if(x5 >= x6) go to PC+100],[PC-relative branch if registers less, unsigned],
  [branch if greater or equal, unsigned],[```assembly bgeu x5, x6, 100```],[if(x5 >= x6) go to PC+100],[PC-relative branch if registers greater or equal, unsigned],
  table.cell(rowspan: 2)[Unconditional branch],[jump and link],[```assembly jal x1, 100```],[x1 = PC + 4; go to PC+100],[PC-relative procedure call],
  [jump and link register],[```assembly jalr x1, 100(x5)```],[x1 = PC + 4; go to x5+100],[procedure return; indirect call],
)



= Chapter 3: Arithmetic for Computer

#info(caption: "Contents of Chapter 3")[
3.1 Introduction \
3.2 Signed and Unsigned Numbers-Possible Representations \
3.3 Arithmetic--Addition & subtraction and ALU \
3.4 Multiplication \
3.5 Division \
3.6 Floating point numbers \
]

== Introduction
- Computer words are composed of bits
  - there are 32bits/word or 64bits/word in RISC-V
- Simplified to contain only in course
  - memory-reference instructions: *lw*(load word), *sw*(store word), *ld*(load doubleword), *lh*(load halfword), *lb*(load byte) etc.
  - arithmetic-logical instructions: *add*, *sub*, *and*, *or*, *xor*, *slt*（set less than，比较）
  - control flow instructions: *beq*(branch equal), *bne*(branch not equal), *jal*(jump and link)
- Generic Implementation
  - 用 *program counter(PC)*（也是 register 的一种） 来提供 instruction address
  - get instruction from memory
  - read registers
  - use the instruction to decide exactly what to do
- 所有指令实际上都用到了 ALU

== Signed and Unsigned Numbers Possible Representations
- Numbers: different occasions have different meanings
  - IP Address
  - Machine instructions
  - Values of Binary number :
    - Integer
      - unsigned: $1001_2=9_(10)$
      - signed: $1001_2= -1_(10)"（原码）," "or" -6 "（反码）," "or" -7_(10) "（补码）"$
    - Fixed Point Number
    - Floating Point Number
- 符号数：Sign Magnitude, One's Complement, Two's Complement, biased notation（移码，加一个最高位1的偏移量，常用于排序）
#fig("/public/assets/Courses/计组/img-2024-03-04-09-22-59.png", width: 70%)
- sign extension
  - lbu v.s. lb，lbu 会将高位补0，lb 会将高位补符号位

== Arithmetic
- overflow: $v = C_n xor C_(n-1)$
  - 溢出处理，把产生溢出的指令的地址存到 SEPC，由操作系统进行后续处理
- 多媒体数据的计算
  - 对音视频的向量数据进行并行运算：SIMD(single-instruction, multiple-data)
  - 饱和操作(Saturating operation)：当溢出时，结果为可以表示的最大值或最小值，而非二进制补码那样的取余
- Logical operations
  - Logical shift: right(srl), left(sll)，不管符号位，均补 0
  - Logical AND, OR, XOR
#wrap-content(
  align: right,
  fig("/public/assets/Courses/计组/img-2024-03-06-10-29-33.png", width: 106%)
)[
- Constructing an ALU
  - 两种方法
    1. 加减法器加上前置的处理（extended the adder，之前数逻的想法）
    2. 多个模块各司其职最后输出选择（Parallel redundant select，现在计组的想法）
  - 逐步构造：先做 1 bit，逐步扩展到想要的位数
- ALU 中的 comparison
  - 使用减法实现
  - 检测 most significant bit，送回到 ALU0
]
- Speed considerations
  - Carry look-ahead adder（超前进位加法器）
  - Carry skip adder
    - 回忆行波进位加法器，每一个 $P_i$ 实际上一步就都算出来了，只是要等链式结构的后续进位
    - Carry skip adder 就是提前把 $P_i$ 往前传，把每组 $P_i$ 提前算好
  - Carry select adder
    - 用成本（翻倍）换性能
    - 高 4 位和低 4 位同时算，高四位把进位为 $0 \/ 1$ 的都给提前算了，再根据低 4 位的结果进行 select

== Multiplication
- Multiplier V1: 用多次的左右移与加法实现
  - 左移被乘数 A，右移乘数 B
  - 以 64 bit 为例
#fig("/public/assets/Courses/计组/img-2024-03-06-10-41-48.png", width: 70%)
  - Big, slow, expensive!
- Multiplier V2
  - 不左移被乘数 A，而是右移结果，移出去的低位就是已经算完的结果；乘数 B 跟 V1 相同
#fig("/public/assets/Courses/计组/img-2024-03-06-10-54-00.png", width: 70%)
- Multiplier V3
  - 注意到结果和乘数 B 都是右移，可以把它们放在一起共同移动，降低空间消耗
#fig("/public/assets/Courses/计组/img-2024-03-06-10-59-16.png", width: 70%)
#fig("/public/assets/Courses/计组/img-2024-03-06-10-59-30.png", width: 70%)
- Signed multiplication
- 基本想法：把符号位提出来，然后用上述无符号方法计算，最后根据符号位进行处理
- 改进方法: Booth's Algorithm(Multiplication: V4)
  - 基本思想：把一连串（连续）的加法转换为一次加法和一次减法
#fig("/public/assets/Courses/计组/img-2024-03-06-11-05-12.png", width: 70%)
#fig("/public/assets/Courses/计组/img-2024-03-06-11-05-53.png", width: 70%)
  - 实际上对于没有那么多连续 1 的数据并没有加速太多，但好处在于一起处理了符号位
- Faster Multiplication
  - 循环展开，用成本换性能
#fig("/public/assets/Courses/计组/img-2024-03-06-11-18-37.png", width: 70%)
- RISC-V Multiplication
  - 64 位寄存器
  1. mul: 给出低 64 位的结果
  2. mulh: 给出高 64 位的结果（有符号）
  3. mulhu: 给出高 64 位的结果（无符号）
  4. mulhsu: 一个有符号一个无符号，给出高 64 位的结果
  - 用 mulh 来检测乘法的溢出，分有符号无符号情况（硬件无法判断溢出与否，软件自己多写一个 mulh 来判断）

== Division
- Division V1: 同乘法的思路，模拟实际除法
#fig("/public/assets/Courses/计组/img-2024-03-06-11-26-47.png", width: 35%)
  - 64 bit 除法示意图
#fig("/public/assets/Courses/计组/img-2024-03-06-11-27-01.png", width: 60%)
- Dicision V2: 相当于直接走了乘法的两步
  - Divisor 右移改成结果左移
  - 结果直接放在 Remainder 里
  - 上来先整体左移一次，最后结果的左半边还要右移一次回去
#fig("/public/assets/Courses/计组/img-2024-03-06-11-36-40.png", width: 65%)
  - 例子：0111/0010 (7/2)
#fig("/public/assets/Courses/计组/img-2024-03-06-11-39-00.png", width: 70%)
- 初始先左移一次，然后左移位数次，最后右移左半部分
- Signed division
  - 规定余数符号与被除数 A 保持一致，商的符号就是数学意义上的符号
- Faster Division
  - 无法提前预知够不够减，因此无法像乘法那样并行
- RISC-V Division
  - Instructions: div, divu 得到商，rem, remu 得到余数
  - 溢出处理由软件负责

== Floating Point
=== 浮点数的表示
- 需要类似科学计数法一样 normalized，即 $1.x x x x x x_2 times 2^(y y y y)$
- Representation: sign, fraction, exponent, more bits for fraction, more bits for exponent
- Floating Point Standard，由 IEEE Std 754-1980 定义
  - fraction，省掉一位；exponent，用移码表示
  - 比较，按次序，先比符号位，再比 exponent，最后比 fraction
    #fig("/public/assets/Courses/计组/img-2024-03-13-10-09-49.png")
- 单精度浮点数的表示范围（双精度类似）
  - Exponents $00000000$ and $11111111$ reserved
  - Smallest Value
    - Exponent: $00000001$ $=>$ Actual exponent: $1-127=-126$
    - fraction: $000 dots 000$ $=>$ significand $=1.0$
    - $+- 1.0 times 2^(-126) approx 1.2 times 10^(-38)$
  - Largest Value
    - Exponent: $11111110$ $=>$ Actual exponent: $254-127=127$
    - fraction: $111 dots 111$ $=>$ significand $approx 2$
    - $+- 2.0 times 2^(127) approx 3.4 times 10^(38)$
- 单精度浮点数的表示精度（双精度类似）
  - Single: $approx 2^(–23)$
  - Equivalent to $23 times log_10 2 approx 23 times 0.3 approx 7$ decimal digits of precision
- 非规格化的数字
  - 当 exponent 为全零（之前保留的），则表示非规格化数字，此时首位数字定义为 0，exponent 为 $1-"Bias"$
  - 当 exponent 为全一（之前保留的），也表示非规格化数字，分为 infinities 和 NaNs
#fig("/public/assets/Courses/计组/img-2024-03-13-10-34-50.png", width: 70%)
#fig("/public/assets/Courses/计组/img-2024-03-13-10-40-48.png", width: 75%)

=== 浮点数的计算
==== 加法
  1. Alignment（小的往大的方向看齐）
  2. The proper digits have to be added
  3. Addition of significands
  4. Normalization of the result
  5. Rounding
#fig("/public/assets/Courses/计组/img-2024-03-13-10-55-07.png")
- 在硬件中的实现
#fig("/public/assets/Courses/计组/img-2024-03-13-11-01-19.png")

==== 乘法与除法
- 乘法相对简单，只需要分开计算把 exponents 相加，fractions 相乘，最后规格化
#fig("/public/assets/Courses/计组/img-2024-03-13-11-12-50.png", width: 65%)
#fig("/public/assets/Courses/计组/img-2024-03-13-11-13-14.png", width: 65%)
- 除法类似，分开计算把 exponents 相减，fractions 相除，最后规格化

=== 浮点数计算讨论
- Associativity: $x + (y+z) != (x+y) + z$
  - 尤其是在大数小数相加时，比如 $x = -1.5_(10) times 10^38, y = 1.5_(10) times 10^38, z = 1.0$，此时前者结果为 $0.0$，后者结果为 $1.0$
- FP Instructions in RISC-V
  - 寄存器：浮点数和整数的寄存器分开，整数指令与浮点指令也分开，不能混用
    - $32$ 个浮点寄存器，这里 $f_0$ 没有必须为 0 的要求
    - flw, fld, fsw, fsd
  - 运算指令
#fig("/public/assets/Courses/计组/img-2024-03-13-11-24-42.png", width: 60%)

- PPT114 $~$ 117，讲解汇编语言

=== 浮点数精确计算
- IEEE Std 754 specifies additional rounding control
  - Three extra bits of precision (guard, round, sticky)
  - Choice of rounding modes
  - 允许程序员微调不同的数值计算行为
- Round modes
  - Round to $0$; Round to $+infty$; Round to $-infty$; Round to next even number (default)
    - 舍入到最近偶数指的是两边距离相同时
#fig("/public/assets/Courses/计组/img-2024-04-02-11-29-30.png", width: 60%)
- Guard and round
#fig("/public/assets/Courses/计组/img-2024-04-02-11-04-02.png", width: 60%)
- Sticky bit（粘滞位）：如果 round bit 的右侧有任何 nonzero 的数，则设为 1
#fig("/public/assets/Courses/计组/img-2024-03-13-12-03-55.png", width: 60%)

= Chapter 4: The Processor: part 1

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
#fig("/public/assets/Courses/计组/img-2024-04-01-09-34-40.png")
- 各个部件
#fig("/public/assets/Courses/计组/img-2024-04-01-09-27-57.png")
- Rigister
  - 一个时钟周期内先写后读
  - Register Files--Built using D flip-flops
#fig("/public/assets/Courses/计组/img-2024-04-01-09-30-50.png")
- Immediate generation unit
  - 两个功能：输入指令产生立即数的逻辑、转移指令偏移量左移位（B和J type末尾添0，lui 左移 12 位）
#fig("/public/assets/Courses/计组/img-2024-04-01-09-35-15.png", width: 90%)
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
#fig("/public/assets/Courses/计组/img-2024-04-03-10-14-10.png", width: 75%)
- 时钟控制方法
  - 每个周期内的操作通过 Combinational logic 完成（不能有多步操作）
  - 因此像是 Add 这种部件在一个周期内多次用到，就需要复制多个
  #fig("/public/assets/Courses/计组/img-2024-04-03-10-20-15.png")

== Building a datapath
- 对六种指令分别解释在上面 CPU overview 中的数据流转（还要加 jalr, lui, bne 等）
  #fig("/public/assets/Courses/计组/img-2024-04-03-11-19-52.png", width: 110%)
  - 思考不同指令在图中的流转路径

== A Simple Implementation Scheme
- Building Controller
  - There are $7+4$ signals
    #fig("/public/assets/Courses/计组/img-2024-04-03-11-24-57.png", width: 90%)
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
#fig("/public/assets/Courses/计组/img-2024-04-03-11-32-05.png")
- 为不同指令解释控制信号（画错了？实现不了 jalr 和 lui）
#fig("/public/assets/Courses/计组/img-2024-04-10-10-30-25.png")
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
  - Exception: Arises within the CPU (e.g., overflow, undefined opcode, syscall)
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
#fig("/public/assets/Courses/计组/img-2024-04-15-08-28-43.png",width:97%)
- mie/mip
  - 相比相比 status 是更细粒度的中断控制
  - xyIE 表示 x 模式下 y 类型的中断使能(E: exception)
  - xyIP 表示 x 模式下 y 类型是否有悬挂着的未处理中断(P: pending)
#fig("/public/assets/Courses/计组/img-2024-04-15-08-32-37.png",width:97%)
- mtvec
  - 分两种模式，direct 和 vectored，用低两位指示
  - 所有的 exception 使用 direct 模式；只有 interrupt 才会使用 vectored 模式
#fig("/public/assets/Courses/计组/img-2024-04-15-08-35-32.png",width:97%)
- mepc
  - 存储处理 exception 或 interrupt 完后的 PC 值
  - Exception 是 +0，需要回来前更改 mepc，否则会陷入循环；interrupt 是 +4
#fig("/public/assets/Courses/计组/img-2024-04-15-08-37-01.png",width:97%)
- mcause
  #fig("/public/assets/Courses/计组/img-2024-04-15-08-38-50.png")
  - 从这张图也可以看出 exception 和 interrupt 的区别
  #fig("/public/assets/Courses/计组/img-2024-04-24-20-20-40.png")
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
#fig("/public/assets/Courses/计组/img-2024-04-15-09-02-29.png")
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
= Chapter 4: The Processor: part 2
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
  #fig("/public/assets/Courses/计组/img-2024-04-24-10-08-51.png")
  - 标蓝表示占用，半标蓝表示占用一半（读右，写左）
  #fig("/public/assets/Courses/计组/img-2024-04-24-10-28-46.png")
- Pipelined CPU DataPath
  - 用蓝线画出的叫做 hazard（冒险），导致数据依赖，会影响流水线的顺序执行
  - 显然是简化的，非所有指令；而且是有错的，比如 load、R-type 指令的写回还需要让 rd 也一起跟着流水线走（后面会改）
  #fig("/public/assets/Courses/计组/img-2024-04-24-10-21-46.png")
  - 需要 pipeline registers 来存储中间结果，寄存器需要足够宽才能存下所有信息
    - PC 也可以看作是一个流水线寄存器
  #fig("/public/assets/Courses/计组/img-2024-04-24-10-33-33.png")
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
    #fig("/public/assets/Courses/计组/img-2024-04-24-11-28-24.png")
  - data hazard: 两个指令之间有数据依赖，需要等待前一条指令完成
    - 后面的 add 用到前面 add 的结果，需要等待（但是 IM 可以执行）
    #fig("/public/assets/Courses/计组/img-2024-04-24-11-35-50.png")
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
    #fig("/public/assets/Courses/计组/img-2024-04-24-12-06-30.png")
  - 实际情况下 structural hazard 往往不会被处理
    + To reduce cost
    + To reduce latency of the unit

=== Data Hazard
- 后一条指令用到前一条指令的结果
#fig("/public/assets/Courses/计组/img-2024-05-08-10-08-51.png")
- 使用 forwarding(also called bypassing) 来解决
  - 从 EX/MEM 前递
  #fig("/public/assets/Courses/计组/img-2024-05-08-10-11-13.png")
  - 从 MEM/WB 前递，仍需要一个 stall
  #fig("/public/assets/Courses/计组/img-2024-05-08-10-17-47.png")
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
  fig("/public/assets/Courses/计组/img-2024-05-08-10-25-08.png")
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
#fig("/public/assets/Courses/计组/img-2024-05-08-10-43-05.png")
- Load-Use Dependency
  - Dependence between load and the following instructions
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-05-22.png")
  - 之前说到，一个 ALU 相关指令的前一条指令是 load 且恰好用到其寄存器时，需要 stall 一个周期，可以 Reorder code to avoid use of load result in the next instruction（编译器优化）
    #fig("/public/assets/Courses/计组/img-2024-05-08-10-58-19.png")
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
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-15-15.png")
- DataPath for Hazard-detection and reg-disable
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-18-16.png")

=== Control Hazards
- 控制指令依赖于先前的指令，比如 Branches
  - 中间的三条指令白做了，需要 flush 掉（流水线*冲掉*流水），相当于 $3$ 次 stall
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-23-34.png")
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
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-44-39.png")
  - 例子：
    - 当前周期为：\<old inst(not taken)\>, beq, sub, before\<1\>, before\<2\>
    - 下一个周期为：\<new inst(taken)\>, Bubble(nop), beq, sub, before\<1\>
  #fig("/public/assets/Courses/计组/img-2024-05-08-11-48-47.png")
  - 然而实际情况会更复杂，考虑 branch 指令跟前面指令的 data hazard
    + branch 是先前指令后的第二第三条，用 forwarding
      #fig("/public/assets/Courses/计组/img-2024-05-08-11-54-33.png")
    + branch 是先前 ALU 指令后紧跟的一条或 load 指令后的第二条，要 stall 一个周期
      #fig("/public/assets/Courses/计组/img-2024-05-08-11-57-23.png")
    + branch 是先前 load 指令后紧跟的一条，要 stall 两个周期
      #fig("/public/assets/Courses/计组/img-2024-05-08-11-58-06.png")
- More-Realistic Branch Prediction
  - Static branch prediction
    - Based on typical branch behavior; Example: loop and if-statement branches
  - Dynamic branch prediction
    - Hardware measures actual branch behavior; Assume future behavior will continue the trend
  - Predictors
    - 1 bit: 每次错了都改变结果，错误率较高（墙头草是这样的）
    - 2 bit: 错两次之后改变结果
      #fig("/public/assets/Courses/计组/img-2024-05-08-12-05-25.png")
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

= Chapter 5: Memory
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
  - huge miss penalty, thus pages should be fairly *large* (e.g., 4KB)
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
  - backplane (high speed, often standardized, e.g., PCI)
  - I/O (lengthy, different devices, standardized, e.g., SCSI)
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
  + centralized, parallel arbitration (requires an arbiter), e.g., PCI
  + self selection, e.g., NuBus used in Macintosh（不需要 master，每个设备根据自己的优先级自行选择）
  + collision detection, e.g., Ethernet（如果碰撞了就都收回，过段时间再尝试）
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




