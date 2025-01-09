// ---
// draft: false
// ---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "实验笔记",
  lang: "zh",
)

#info()[
  - 实验过程中的一些笔记
]

#let LEVELS = math.text("LEVELS")
#let pte = math.text("pte")
#let satp = math.text("satp")
#let ppn = math.text("ppn")
#let VA = math.text("VA")
#let PA = math.text("PA")
#let vpn = math.text("vpn")
#let offset = math.text("offset")
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

= 一些速查表
== RISCV 基本寄存器
#tlt(
  columns: 4,
  [Register], [ABI Name], [Description], [Saver],
  [x0], [zero], [Hard-wired zero], [—],
  [x1], [ra], [Return address], [Caller],
  [x2], [sp], [Stack pointer], [Callee],
  [x3], [gp], [Global pointer], [—],
  [x4], [tp], [Thread pointer], [—],
  [x5–7], [t0–2], [Temporaries], [Caller],
  [x8], [s0/fp], [Saved register/frame pointer], [Callee],
  [x9], [s1], [Saved register], [Callee],
  [x10–11], [a0–1], [Function arguments/return values], [Caller],
  [x12–17], [a2–7], [Function arguments], [Caller],
  [x18–27], [s2–11], [Saved registers], [Callee],
  [x28–31], [t3–6], [Temporaries], [Caller]
)

== RISCV 特权级寄存器
- `sstatus` 寄存器
  #fig("/public/assets/Courses/OS/2024-11-17-13-33-32.png",width:80%)
  + `SPP`: 进入 S-Mode 之前处理器的特权级别，`sret` 时会用到它，$0$ 表示 U-Mode，$1$ 表示其它
  + `SIE`: S-Mode 下全局中断使能位，$1$ 表示开启，$0$ 表示关闭
  + `SPIE`: S-Mode 下全局中断使能位的 Previous 值，当 trap 时，硬件自动将 SIE 位放置到 SPIE 位上，并将 SIE 置为 $0$（硬件逻辑上默认不支持嵌套中断）；`sret` 时，硬件自动将 SPIE 位放置到 SIE 位上
  + `SUM`: 如果置 $1$，让 S 特权级下的程序在即使用户页 `PTE[U]` 置 $1$ 时也能访问

- `mcause` & `scause` 表（只记有用的）
  - `mie` & `sie` 中断使能寄存器，针对各种中断类型的使能位，具体就是查这个表，将需要的位设置为 1（最多有 `SXLEN-2` 个中断类型，每个 $1$ 位，实验以 $64 bits$ 为例）
  - `medeleg` & `mideleg` 委托寄存器，在 M-Mode 下配置寄存器使 S-Mode 下的某类 trap 被 S-Mode 下的 trap 处理函数自动接管，分别管理 exception 和 interrupt 的委派。具体也是查这个表
#fig("/public/assets/Courses/OS/2024-11-17-13-44-36.png",width:80%)
#tlt(
  columns: 3,
  [Interrupt],[Exception Code],[Description],
  [1],[1],[Supervisor Software Interrupt],
  [1],[3],[Machine Software Interrupt],
  [1],[5],[Supervisor Timer Interrupt],
  [1],[7],[Machine Timer Interrupt],
  [1],[9],[Supervisor External Interrupt],
  [1],[11],[Machine External Interrupt],
  [0],[0],[Instruction Address Misaligned],
  [0],[1],[Instruction Access Fault],
  [0],[2],[Illegal Instruction],
  [0],[3],[Breakpoint],
  [0],[4],[Load Address Misaligned],
  [0],[5],[Load Access Fault],
  [0],[6],[Store/AMO Address Misaligned],
  [0],[7],[Store/AMO Access Fault],
  [0],[8],[Environment Call from U-mode],
  [0],[9],[Environment Call from S-mode],
  [0],[11],[Environment Call from M-mode],
  [0],[12],[Instruction Page Fault],
  [0],[13],[Load Page Fault],
  [0],[15],[Store/AMO Page Fault]
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
  ```asm
      .text
      .align 2
      .globl main
  main:
      addi sp, sp, -16
      sw ra, 12(sp)
      lui a0, %hi(string1)
      addi a0, a0, %lo(string1)
      lui a1, %hi(string2)
      addi a1, a1, %lo(string2)
      call printf
      lw ra, 12(sp)
      addi sp, sp, 16
      li a0, 0
      ret

      .section .rodata
      .balign 4
  string1:
      .string "Hello, %s!\n"
  string2:
      .string "world"
  ```
  - `.section`, `.text`, `.rodata`, `.data`, `.bss` ...: 用于定义段
  - `.globl`, `.extern` 用于声明全局变量和外部变量
  - `.byte b1, b2, ..., bn`, `.half w1, w2, ..., wn`, `.word w1, w2, ..., wn`：存放一些字节、半字(16 bits)、字(32 bits)
  - `.align 2`, `.balign 4`：：对齐数据段到 $2^2$ 和 $4$ 字节
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
- 一段程序往往包含了变量、常量、数据、代码逻辑，它们属于不同的段：
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
#note(caption: "Virtual Address Translation Process(sv39)")[
  - 首先翻译一遍（部分异常处理简化）
    + 让 $a$ 代表 $satp\.ppn$ $times 2^12$(PA of page table)，让 $i=2$ (level of page table)
    + 让 $pte$ 代表 PTE 在 $a+VA\.vpn[i]times 8$（PA 加上 PT 中偏移量）地址的值
    + 如果 $pte\.v=0$，或者 $pte\.r=0$ 且 $pte\.w=1$，或者 reserved bits 被设置，抛出 page-fault 异常
    + 否则，这个 PTE 是 valid 的。如果 $pte\.r=1$ 或 $pte\.x=1$，跳到第 $5$ 步；否则，这个 PTE 指向下一级页表，令 $i=i-1$。如果 $i < 0$，抛出 page-fault 异常；否则，令 $a=pte\.ppn times 2^12$，跳到第 $2$ 步
    + 此时说明 PTE 是 leaf 节点。检查权限是否要抛出 page-fault 异常
    + 如果 $i>0$ 并且 $pte\.ppn[i-1:0]!=0$，这是一个 misaligned superpage，抛出 page-fault 异常
    + （可以先不管这一步）如果 $pte\.a=0$，或者如果是存储操作并且 $pte\.d=0$
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
  - 完整走一遍成功的触发暂时页表 gigapage 的过程
    + $a=satp\.ppn$ $times 2^12, i=2$，在第一级页表中找 $a+VA\.vpn[i]times 8$ 的值，取出记为 $pte$
    + 发现 $pte\.r=1$ 或 $pte\.x=1$，触发 gigapage
    + $PA = {pte\.ppn[2],VA\.vpn[1:0],VA\.offset}$
]

= lab4
== `thread_struct` 和 `task_struct` 的设置
- 修改 `task_init()` 中 `sstatus`
  + `SPP`: 设为 $0$，使得 sret 返回至 U-Mode
  + `SPIE`: 设置为 $1$，使 sret 之后开启中断
  + `SUM`: 设置为 $1$，使 S-Mode 可以访问 User 页面
- 修改 `task_init()` 中 `sscratch`
  #quote(caption: [什么是 `sscratch` (ref: #link("https://learningos.cn/rcore_step_by_step_webdoc/docs/Trap.html")[LearningOS-rCore-Trap])])[
    #tab 中断可能来自用户态（U-Mode），也可能来自内核态（S-Mode）。如果是用户态中断，那么此时的栈指针 sp 指向的是用户栈；如果是内核态中断，那么 sp 指向的是内核栈。现在我们希望把寄存器保存在内核栈上，这就要求有一个通用寄存器指向内核栈。对于内核态中断来说，直接使用 sp 就可以了，但对于用户态中断，我们需要在不破坏 32 个通用寄存器的情况下，切换 sp 到内核栈。

    解决问题的关键是要有一个可做交换操作的临时寄存器，这里就是 `sscratch` 。

    我们规定：当 CPU 处于 U-Mode 时，`sscratch` 保存内核栈地址；处于 S-Mode 时，`sscratch` 为 $0$。
  ]
  - 在我们的 lab 里面（个人理解）
    - 对于一个 U-Mode 线程，它的作用是充当 U-Mode 和一一对应的 S-Mode 跳板之间的桥梁，在 S-Mode 下存储 U-Mode 的 `sp`，在 U-Mode 下存储 S-Mode 的 `sp`
    - 而对于一个单纯的 S-Mode 线程，规定 `sscratch=0`

= Lab5
== `do_page_fault()` 拷贝逻辑
- 通过 `stval` 获得 bad_addr，`find_vma()` 查找是否有对应的 `vm_area_struct`。如果没有或者有但是权限不对就报错，否则它是一个 valid page fault
- 为此，申请一个 page，然后不论是 anonymous 还是 file-backed，都创建这个 page 的映射
- 而如果是 file-backed，还需要从 elf 文件中读取 segment 来填充它，这里的对齐情况比较复杂，如图
  #fig("/public/assets/Courses/OS/2024-12-16-00-35-01.png", width:90%)
  + case 1: `vm_start                  <= stval < PGROUNDUP(vm_start)`
  + case 2: `PGROUNDUP(vm_start)       <= stval < PGROUNDDOWN(vm_seperator)`
  + case 3: `PGROUNDDOWN(vm_seperator) <= stval < vm_seperator`
  + case 4: `vm_seperator              <= stval < PGROUNDUP(vm_seperator)`
  + case 5: `PGROUNDUP(vm_seperator)   <= stval < PGROUNDDOWN(vm_end)`
  + case 6: `PGROUNDDOWN(vm_end)       <= stval < vm_end`

== 进程返回逻辑
=== 父进程
- 父进程的逻辑相对简单，它的过程是：
  + 一开始在 U-Mode 运行时，其 `sp` 为用户态栈指针，`sscratch` 为内核态指针
  + 进入 `_traps`，检测到 `sscratch` 不为零，则交换 `sp` 和 `sscratch`，进入 S-Mode（也即：在 `do_fork` 中，`sp` 为内核栈指针，`sscratch` 为用户栈指针）
  + 从 `trap_handler` 返回后，在 `_traps` 的末尾把二者换回去，回到 U-Mode
- 父进程的 `task_struct` 并不关键，因为没有涉及进程切换。当它要切换的时候，会把那时候的 `ra, sp, s[12]` 等寄存器值更新到内核页的 `task_struct` 里

=== 子进程
- 每个内核页的低地址为 `task_struct`，高地址为内核栈（其中存储了 `pt_regs`）。我们把父进程内核页基地址记为 `F`，子进程创建的基地址记为 `C`，并从 `F ~ F + PGSIZE` 处拷贝内容。拷贝来的内容大多不用变，但部分涉及到地址的值有错位
- `do_fork` 函数的参数 `regs` 和返回值都是基于父进程的；而对子进程来说，它的返回值和信息都存在 `C ~ C + PGSIZE` 部分的 `task_struct` 和 `pt_regs` 里
#fig("/public/assets/Courses/OS/2024-12-16-00-33-08.png", width:90%)
- 基于这两个思想，`do_fork` 中子进程的几个乱七八糟的指针设置如下：
  - 设置子进程的 `task->thread.sp` 为子进程 `pt_regs` 的指针
    - `pt_regs` 的指针对父进程和子进程是不同的，但在页内的偏移量相同
    - 从而，设置为 `regs % PGSIZE + C` 即可，或者 `regs + C - F`
  - 设置子进程的 `task->thread.sscratch` 为用户栈指针
    - 父进程进入 `_traps` 时切换到 S-Mode，交换后，`sp` 为内核栈指针，`sscratch` 为用户栈指针，后者即为我们的目标
    - 这个东西没有被存到 `pt_regs`，#strike[当然也可以存进去，但我懒得改了，]这里直接在 `do_fork` 的时候用 `csr_read` 读取
  - 设置子进程的 `task->thread.ra` 为 `__ret_from_fork` 函数的地址
    - 借用父进程恢复 `pt_regs` 的过程
  - 修改子进程 `pt_regs` 的 `sp`，使其指向子进程的内核栈
    - 同样的道理，设置为原本的 `sp` 加上 `C - F`
  - 修改子进程 `pt_regs` 的 `a0`，使其 `do_fork` 返回值为 `0`
  - 修改子进程 `pt_regs` 的 `sepc` 并加四
    - 因为 syscall 那边写的 `sepc += 4` 是对父进程而言的，对子进程我们要额外处理，即在子进程的内核栈上加四
- 随后梳理切换到子进程的过程：
  + 子进程在 `__switch_to` 切换到它的时候起效，它的 `task_struct` 里的 `ra`, `sp`, `s[12]`, `sscratch` 等会被加载到寄存器里，然后 `ret` 到 `__ret_from_fork`，这时候它的 `sp` 为 `pt_regs` 指针，`sscratch` 为用户栈指针
  + 然后，子进程蹭了父进程的从 S-Mode 到 U-Mode 的恢复过程，恢复了拷贝来的 `pt_regs`。得益于前面的设置，它读取的是自己的 `pt_regs` 而不是父进程的
  + 接着，由于 `sscratch` 不为零，进行 `sp` 和 `sscratch` 的交换，此时 `sp` 为用户栈指针，`sscratch` 为内核栈指针，`sret` 回到加四过的 `sepc`，执行 U-Mode 代码
