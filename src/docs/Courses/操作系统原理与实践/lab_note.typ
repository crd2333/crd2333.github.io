// ---
// draft: false
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "实验笔记",
  lang: "zh",
)

= lab1
== RISCV 汇编
- 汇编文件的后缀是 `.s` 或 `.S`，所不同的是 `.S` 中可以加入预处理命令（`#include`, `#define` 等）。
- 参考
  + #link("https://lgl88911.github.io/2021/02/28/RISC-V%E6%B1%87%E7%BC%96%E5%BF%AB%E9%80%9F%E5%85%A5%E9%97%A8/")[RISC-V汇编快速入门]
  + #link("https://mp.weixin.qq.com/s/jyI-SSm_5Gg-KQyjKsIj5Q")[RISC-V嵌入式开发入门篇2：RISC-V汇编语言程序设计（上）]
  + 非常复杂的教科书 #link("https://www.bookstack.cn/read/linux-insides-zh/Booting-linux-bootstrap-1.md")[Linux 内核揭秘（中文版）]
  + Cargo 编写 OS 指南（可作参考） #link("https://rcore-os.cn/rCore-Tutorial-deploy/docs/lab-0/guide/part-7.html")[rCore-Tutorial V3]

- 一些常见的写法已经很熟悉，这里不再赘述，比如这种
  ```
  start:
    bnez  x1, dummy
    beq   x0, x0, pass_0
    li    x31, 0
    auipc x30, 0
    j     dummy
  ```
- 关注一下之前没见过的命令
  - `la rd symbol`，load absolute address，对非位置无关码(non-PIC)和位置无关码(PIC)有不同解释，相当于 `auipc+addi` 或 `auipc+l{d|w}`
  - `j offset`，调用一个函数，相当于 `jal x0, offset`，不指望回来的那种
  - `tail offset`，相当于 `auipc x6 xxx + jalr x0, xxx(x6)`，不指望回来的那种，`j offset` 的高级版
  - `call offset`，调用一个函数，相当于 `auipc x1 xxx + jalr x1, xxx(x1)`，`jal ra, offset` 的高级版
  - `ret`，从函数调用返回，相当于 `jalr x0, 0(x1)`
  - 参考 #link("https://github.com/riscv-non-isa/riscv-asm-manual/blob/main/src/asm-manual.adoc#a-listing-of-standard-risc-v-pseudoinstructions")[riscv-asm-manual\#pseudoinstructions]

- 关注一下伪操作
  - `.section` 用于定义段
  - `.globl` 用于定义全局变量
  - `.extern` 用于引用外部变量
  - `.align` 用于对齐
  - 参考 #link("https://github.com/riscv-non-isa/riscv-asm-manual/blob/main/src/asm-manual.adoc#pseudo-ops")[riscv-asm-manual\#pseudo-ops]


== 链接脚本
- 链接脚本的后缀是 `.ld` 或 `.lds`。
- 参考
  + #link("https://zhuanlan.zhihu.com/p/504742628")[ld - 链接脚本学习笔记与实践过程]
  + #link("https://blog.csdn.net/Lazy_Linux/article/details/139460752")[GNU ld 链接脚本（Linker Script）简介]
  + #link("https://www.cnblogs.com/jianhua1992/p/16852784.html")[链接脚本(Linker Scripts)语法和规则解析（翻译自官方手册）]

- 首先需要知道程序编译的四个步骤
  + 预处理，将 `#include` 等预处理命令替换为实际内容
  + 编译，将 C 代码编译为汇编代码（同时会进行优化等）
  + 汇编，将汇编代码编译为机器码
  + 链接，将多个目标文件链接为一个可执行文件
  #fig("/public/assets/Courses/OS/2024-09-22-22-48-43.png")

- 链接脚本描述了连接器如何将这些输入 `*.o` 文件映射为一个输出文件 `xxx(.exe)/(.out)` ，更具体来说：
  - 链接脚本中的输入和输出文件均为*目标文件*(Object File)，其最常见的格式为 `ELF` 文件格式，输出文件也叫*可执行文件*。每个输入文件包含一系列*属性不同*的 Input Section，输出文件中则包含一系列 Output Section
  - 链接脚本的首要任务就是要指导如何将多个输入文件中的多个 Input Section 映射到输出文件的 Output Section 中，并完成输出文件及各个节区的属性（包括存储布局、section 对齐、属性等）设置等
  - 再通俗一点：链接脚本决定了一个可执行程序的各个段的存储位置，相当于要给程序中的数据和变量进行分类，并确定每一类的存放位置
- 在使用 `ld` 的时候，通过 `-T` 选项，可以使用自己写的链接脚本完成链接过程，否则会使用默认的链接脚本。如实验中的 `lab1/arch/riscv/Makefile` 中可以看到 `-T` 选项
- 一段程序往往包含了变量、常量、数据、代码逻辑，他们属于不同的段：
  + `.bss` 段：一个全局变量，没有被初始化或者被初始化为 $0$。
  + `.data` 段：一个全局变量，非 const 类型，已被初始化（初始值必须是非 $0$ 值）
  + `.rodata` 段：read only data，如字符串常量、const 修饰的变量都会被保存到该段
  + `.text` 段：程序代码段，更进一步讲是存放处理器的机器指令。函数代码逻辑都会保存到该段
  - 实际涉及的段远不止这四个，这里只是列举了我们所熟知的段

= lab2
== 关于 timer
- 有点不理解 timer 的工作原理
- 看了 #link("https://wangzhou.github.io/riscv-timer%E7%9A%84%E5%9F%BA%E6%9C%AC%E9%80%BB%E8%BE%91/")[这篇文章] 更不理解了
- 现在理解了


== 关于中断
- 参考 #link("https://blog.csdn.net/zzy980511/article/details/130642258")[RISC-V架构中的异常与中断详解]


= lab3
== 页表寻址 —— sv39
#let LEVELS = math.text("LEVELS")
#let pte = math.text("pte")
#let satp = math.text("satp")
#let ppn = math.text("ppn")
#let VA = math.text("VA")
#let PA = math.text("PA")
#let vpn = math.text("vpn")
#let offset = math.text("offset")
#note(caption: "Virtual Address Translation Process(sv39)")[
  - 首先翻译一遍（部分异常处理简化）
    + 让 $a$ 代表 $satp\.ppn$ $times 2^12$(PA)，让 $i=2$
    + 让 $pte$ 代表 PTE 在 $a+VA\.vpn[i]times 8$（PA 加上 PT 中偏移量）地址的值
    + 如果 $pte\.v=0$，或者 $pte\.r=0$ 且 $pte\.w=1$，或者 reserved bits 被设置，抛出 page-fault 异常
    + 否则，这个 PTE 是 valid 的。如果 $pte\.r=1$ 或 $pte\.x=1$，跳到第 $5$ 步；否则，这个 PTE 指向下一级页表，令 $i=i-1$。如果 $i < 0$，抛出 page-fault 异常；否则，令 $a=pte\.ppn times 2^12$，跳到第 $2$ 步
    + 此时说明 PTE 是 leaf 节点。检查权限是否要抛出 page-fault 异常
    + 如果 $i>0$ 并且 $pte\.ppn[i-1:0]!=0$，这是一个 misaligned superpage，抛出 page-fault 异常
    + （可以先不管这一步）如果 $pte\.a=0$，或者如果是存储操作并且 $pte\.d=0$（可以先不管这一步）
      - Svade extension 和一些检查，略
      - 自动执行以下步骤
        + 把 $pte$ 跟 PTE 在 $a+VA\.vpn[i] times 8$（PA 加上 PT 中偏移量）地址的值比较
        + 如果值相等，设置 $pte\.a=1$，并且如果是存储操作，设置 $pte\.d=1$
        + 如果值不等，回到第 $2$ 步
    + translation success，物理地址如下
      - $PA\.offset = VA\.offset$
      - 如果 $i>0$，触发 super page 机制，$PA\.ppn[i-1:0] = VA\.vpn[i-1:0]$
      - $PA\.ppn[2:i] = pte\.ppn[2:i]$
  - 现在完整走一遍成功的三级页表的过程
    + $a=satp\.ppn$ $times 2^12, i=2$，在第一级页表中找 $a+VA\.vpn[i]times 8$ 的值，取出记为 $pte$
    + $a=pte\.ppn times 2^12, i=1$，在第二级页表中找 $a+VA\.vpn[i]times 8$ 的值，取出记为 $pte$
    + $a=pte\.ppn times 2^12, i=0$，在第三级页表中找 $a+VA\.vpn[i]times 8$ 的值，取出记为 $pte$
    + $PA = {pte\.ppn,VA\.offset}$
]