---
order: 3
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

#counter(heading).update(2)

= Arithmetic for Computer

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
#fig("/public/assets/Courses/CO/img-2024-03-04-09-22-59.png", width: 70%)
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
  fig("/public/assets/Courses/CO/img-2024-03-06-10-29-33.png", width: 106%)
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
#fig("/public/assets/Courses/CO/img-2024-03-06-10-41-48.png", width: 70%)
  - Big, slow, expensive!
- Multiplier V2
  - 不左移被乘数 A，而是右移结果，移出去的低位就是已经算完的结果；乘数 B 跟 V1 相同
#fig("/public/assets/Courses/CO/img-2024-03-06-10-54-00.png", width: 70%)
- Multiplier V3
  - 注意到结果和乘数 B 都是右移，可以把它们放在一起共同移动，降低空间消耗
#fig("/public/assets/Courses/CO/img-2024-03-06-10-59-16.png", width: 70%)
#fig("/public/assets/Courses/CO/img-2024-03-06-10-59-30.png", width: 70%)
- Signed multiplication
- 基本想法：把符号位提出来，然后用上述无符号方法计算，最后根据符号位进行处理
- 改进方法: Booth's Algorithm(Multiplication: V4)
  - 基本思想：把一连串（连续）的加法转换为一次加法和一次减法
#fig("/public/assets/Courses/CO/img-2024-03-06-11-05-12.png", width: 70%)
#fig("/public/assets/Courses/CO/img-2024-03-06-11-05-53.png", width: 70%)
  - 实际上对于没有那么多连续 1 的数据并没有加速太多，但好处在于一起处理了符号位
- Faster Multiplication
  - 循环展开，用成本换性能
#fig("/public/assets/Courses/CO/img-2024-03-06-11-18-37.png", width: 70%)
- RISC-V Multiplication
  - 64 位寄存器
  1. mul: 给出低 64 位的结果
  2. mulh: 给出高 64 位的结果（有符号）
  3. mulhu: 给出高 64 位的结果（无符号）
  4. mulhsu: 一个有符号一个无符号，给出高 64 位的结果
  - 用 mulh 来检测乘法的溢出，分有符号无符号情况（硬件无法判断溢出与否，软件自己多写一个 mulh 来判断）

== Division
- Division V1: 同乘法的思路，模拟实际除法
#fig("/public/assets/Courses/CO/img-2024-03-06-11-26-47.png", width: 35%)
  - 64 bit 除法示意图
#fig("/public/assets/Courses/CO/img-2024-03-06-11-27-01.png", width: 60%)
- Dicision V2: 相当于直接走了乘法的两步
  - Divisor 右移改成结果左移
  - 结果直接放在 Remainder 里
  - 上来先整体左移一次，最后结果的左半边还要右移一次回去
#fig("/public/assets/Courses/CO/img-2024-03-06-11-36-40.png", width: 65%)
  - 例子：0111/0010 (7/2)
#fig("/public/assets/Courses/CO/img-2024-03-06-11-39-00.png", width: 70%)
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
    #fig("/public/assets/Courses/CO/img-2024-03-13-10-09-49.png")
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
#fig("/public/assets/Courses/CO/img-2024-03-13-10-34-50.png", width: 70%)
#fig("/public/assets/Courses/CO/img-2024-03-13-10-40-48.png", width: 75%)

=== 浮点数的计算
==== 加法
  1. Alignment（小的往大的方向看齐）
  2. The proper digits have to be added
  3. Addition of significands
  4. Normalization of the result
  5. Rounding
#fig("/public/assets/Courses/CO/img-2024-03-13-10-55-07.png")
- 在硬件中的实现
#fig("/public/assets/Courses/CO/img-2024-03-13-11-01-19.png")

==== 乘法与除法
- 乘法相对简单，只需要分开计算把 exponents 相加，fractions 相乘，最后规格化
#fig("/public/assets/Courses/CO/img-2024-03-13-11-12-50.png", width: 65%)
#fig("/public/assets/Courses/CO/img-2024-03-13-11-13-14.png", width: 65%)
- 除法类似，分开计算把 exponents 相减，fractions 相除，最后规格化

=== 浮点数计算讨论
- Associativity: $x + (y+z) != (x+y) + z$
  - 尤其是在大数小数相加时，比如 $x = -1.5_(10) times 10^38, y = 1.5_(10) times 10^38, z = 1.0$，此时前者结果为 $0.0$，后者结果为 $1.0$
- FP Instructions in RISC-V
  - 寄存器：浮点数和整数的寄存器分开，整数指令与浮点指令也分开，不能混用
    - $32$ 个浮点寄存器，这里 $f_0$ 没有必须为 0 的要求
    - flw, fld, fsw, fsd
  - 运算指令
#fig("/public/assets/Courses/CO/img-2024-03-13-11-24-42.png", width: 60%)

- PPT114 $~$ 117，讲解汇编语言

=== 浮点数精确计算
- IEEE Std 754 specifies additional rounding control
  - Three extra bits of precision (guard, round, sticky)
  - Choice of rounding modes
  - 允许程序员微调不同的数值计算行为
- Round modes
  - Round to $0$; Round to $+infty$; Round to $-infty$; Round to next even number (default)
    - 舍入到最近偶数指的是两边距离相同时
#fig("/public/assets/Courses/CO/img-2024-04-02-11-29-30.png", width: 60%)
- Guard and round
#fig("/public/assets/Courses/CO/img-2024-04-02-11-04-02.png", width: 60%)
- Sticky bit（粘滞位）：如果 round bit 的右侧有任何 nonzero 的数，则设为 1
#fig("/public/assets/Courses/CO/img-2024-03-13-12-03-55.png", width: 60%)

