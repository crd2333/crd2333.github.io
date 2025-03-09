---
order: 2
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

#counter(heading).update(1)

= Instructions——Language of the Computer

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
    #fig("/public/assets/Courses/CO/img-2024-03-18-08-35-48.png", width: 60%)
- Memory Operands
  - 优势：可以存更多数据、可以存更复杂更灵活的数据结构
  - 需要 load / store 跟 register 交互
  - Memory is byte addressed: Each address identifies an 8-bit byte
  - 大端与小端（相对主流），RISC-V is Little endian
    #fig("/public/assets/Courses/CO/img-2024-03-18-08-39-19.png", width: 84%)
  - Memory Alignment
    #fig("/public/assets/Courses/CO/img-2024-03-18-08-53-14.png", width: 80%)
    - 不过 RISC-V 没有对齐的要求
- Constant or Immediate Operand
  - 对于常数或立即数，如果放在 memory 中，每次都要 load，效率低，为此定义了立即数指令，如 addi
    $ "addi" "x22", "x22", 4 med med \/\/ "x22"= "x22" + 4 $
  - #redt[Design Principle 3]：Make the common case fast

== Signed and Unsigned Numbers
- 略

== Representing Instructions in the Computer
- 从汇编指令到机器码(machine code)
  #fig("/public/assets/Courses/CO/img-2024-03-18-09-18-59.png")
  - 上面这种例子是 R-format
  #fig("/public/assets/Courses/CO/img-2024-03-18-09-20-46.png", width: 60%)
- #redt[Design Principle 4]: Good design demands good compromises（好的设计需要折中）
- 对于立即数，可以看到 R-format 只有 5 位来表示，范围太小了，因此定义了 I-format，范围变为 $+- 2^11$
  #fig("/public/assets/Courses/CO/img-2024-03-18-09-25-07.png", width: 60%)
- 对 store 操作有 S-format，把不需要的目标寄存器 rd 空出来给立即数，这里图片有错，应为$"imm"[11:5]$, #redt[$5"bits"$]
  #fig("/public/assets/Courses/CO/img-2024-03-18-09-28-18.png", width: 70%)
- 归纳：
  #fig("/public/assets/Courses/CO/img-2024-03-18-09-34-46.png")
- Stored-program

#wrap-content(fig("/public/assets/Courses/CO/img-2024-03-20-10-13-14.png", width: 48%))[
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
#fig("/public/assets/Courses/CO/img-2024-03-20-10-42-08.png", width: 59%)
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
#fig("/public/assets/Courses/CO/img-2024-03-20-11-13-01.png", width:60%)

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
#fig("/public/assets/Courses/CO/img-2024-03-20-12-08-58.png")

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
#fig("/public/assets/Courses/CO/img-2024-03-27-10-24-35.png", width: 80%)
- Branch Addressing（分支指令跳转）
  - SB-Format(B-format)
    - 在相对当前指令 $+-2^12$ bits 的范围内跳转
#fig("/public/assets/Courses/CO/img-2024-03-27-10-33-24.png", width: 80%)
- branch 跳转在循环中常用，因为循环体一般不会写太大。而函数调用这种需要更大的跳转范围:
- Jump Addressing（无条件跳转）
  - UJ-Format(J-format)
    - 20-bit immediate, 12-bit offset
    - 在相对当前指令 $+-2^20$ bits 的范围内跳转
    - 如果 beq(B-format)不够，化为 bne+jal；如果还不够，用 lui+ jalr
#fig("/public/assets/Courses/CO/img-2024-03-27-10-38-41.png", width: 80%)
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
#fig("/public/assets/Courses/CO/img-2024-03-27-11-00-51.png", width: 80%)
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
#fig("/public/assets/Courses/CO/img-2024-03-27-11-30-00.png")
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
#fig("/public/assets/Courses/CO/img-2024-04-01-08-20-00.png", width: 89%)
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



