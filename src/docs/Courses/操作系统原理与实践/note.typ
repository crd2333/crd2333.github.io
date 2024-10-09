#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "操作系统原理与实践",
  lang: "zh",
)

- 感觉 #link("https://note.hobbitqia.cc/OS/")[大 Q 老师的笔记] 比较好，自己随便记记算了

= Introduction
- 复习计组的东西
- UNIX family tree
  - NUIX, BSD, Solaris, Linux...
  - Ubuntu = Linux Core + GNU
- Kernel 的工作是抽象封装和资源管理
- 对 OS 的一个最常见误区是“一个 running program”，事实上 OS 在启动后一般是闲置的，并且要求内存占用小
  - It's code that resides in memory and is ready to be executed at any moment
  - It can be executed on behalf of a job(or process in modern terms, a process is a running job)
- 为了实现 APP $->$ OS $->$ HardWare 的层级，需要把访问硬件的指令分类(privileged / unprivileged)，即至少支持两个 Mode
  - arm64 有 4 个 Mode，RISC-V 有 3 个 Mode（有一个没抄完因此叫 reserved）
  #grid2(
    fig("/public/assets/Courses/OS/2024-09-24-13-33-05.png"),
    fig("/public/assets/Courses/OS/2024-09-24-13-33-26.png")
  )
- OS Event
  - 分为 interrupt 和 exception(traps)
- When a user program needs to do something privileged, it calls a *system call*. A system call is a special kind of *trap*
  #fig("/public/assets/Courses/OS/2024-09-24-13-35-18.png")
- Timers
  - OS 必须有时间的概念来公平地分配资源给各个进程
  - 为此需要 timer，通过 privileged instructions 实现，定期自增计时器
- Main OS Services
  + Process Management
    - process 是执行中的 program
    - OS 负责：进程的创建、删除、挂起、恢复、同步、通信、死锁处理
  + Memory Management
    - Memory management 决定哪些东西在内存中，kernel *always* in memory
    - OS 负责：跟踪、移入移出、分配释放 memory
    - OS 不负责：memory caching, cache coherency(by hardware)
  + Storage Management
  + I/O Management
  + Protection and Security

= OS Structures
- 操作系统的定义
  - 狭义上来说，只有与硬件资源直接沟通的内核才叫 OS
  - 但这样 Android（底层是 linux）、鸿蒙等就不算了，因此从广义上来说，一些运行在 user mode 上的 system services 也算 OS（比如，GUI、batch、command line）

== System Calls and Services
  #fig("/public/assets/Courses/OS/2024-09-24-16-04-00.png", width: 70%)
- system call 是 kernel 提供给 user 的 API，做 privileged 的操作
- system call 非常常见，只是我们可能意识不到
  - 比如 C 语言的 `printf` 就是一个 `write` system call 的 wrapper
- 从 high level 的角度看
  #fig("/public/assets/Courses/OS/2024-09-24-14-25-18.png", width: 70%)
- system call number
  - System-call interface maintains a table(actually an array) —— system call table
  - 每种 system call 关联着一个数字，给一个数字，就去调用对应的 system call
- linux 上有一个叫 `strace` 的命令，可以展示一个命令调用了多少 system call；类似地，`time` 命令可以展示一个命令的执行时间，包含 real, user, sys
- system call 在 windows 和 unix 上的设计完全不一样
- system services
  - OS 自带的、不需要用户自己安装的、运行在 user mode 的服务
  - File manipulation, Status information sometimes stored in a file, Programming language support, Program loading and execution, Communications, Background services, Application programs

== Linkers and Loaders
- Linkers and Loaders
  - Linker: 把多个 object files link 起来，生成一个可执行文件
  - Loader: 把可执行文件 load 到内存中，准备执行
  - Linker 和 Loader 之间的区别在于：Linker 是在 compile time，Loader 是在 run time
- ELF binary basics
  - ELF: Executable and Linkable Format
  - `.text`: code, `.rodata`: initialized read-only data, `.data`: initialized data, `.bss`: block started by symbol
- Linking
  - Static linking
    - 把所有需要的代码都 link 到一个 large binary 中，移植性好
  - Dynamic linking
    - 重用 libraries 来减少 binary 的大小
    - 谁来解析？loader will resolve lib calls
- running a binary
  #fig("/public/assets/Courses/OS/2024-09-24-16-07-49.png")
  - Who setups ELF file mapping? Kernel, or to be more specific --- exec syscall
  - Who setups stack and heap? Kernel, or to be more specific --- exec syscall
  - Who setups libraries? loader, ld-xxx
- Running statically-linked ELF
  - Where to start? `_start`, `_start` is executed after evecve system call，并且这是运行在 user mode 的
  - `_start` 里面调用 `_libc_start_main`，这个函数会调用 `main` 函数并设置参数
  #fig("/public/assets/Courses/OS/2024-09-25-16-38-09.png", width:70%)
- Running dynamically-linked ELF
  - 在源码的 `load_elf_binary` 里，会有个 `if (elf_interpreter)`，如果是则为 dynamical，然后去调 interpreter
  - 它做了什么呢？比方说 main 里面调了 `printf`，实际上用的是 `puts`，那这个地址在哪呢（如果没设置好的话就会 segmentation fault）？这就是 loader 的工作
  #fig("/public/assets/Courses/OS/2024-09-25-16-44-28.png")

== Operating System Design
- Why Applications are Operating System Specific
  - Each operating system provides its own unique system calls
  - 但是 Apps can be multi-operating system
  - *Application Binary Interface (ABI)* 是 API 在 architecture 上的实现，定义一个 binary code 的不同部分如何在某个 architecture 上与某个 OS 交互
- Operating System Design and Implementation
  - User goals and System goals 是不同的，用户追求方便、易学、可靠、安全、快速，系统追求设计、维护、灵活、可靠、高效
  - Important principle to separate
    + Policy: *What* will be done?
    + Mechanism: *How* to do it?
    - 将这二者分开允许更改 policy 而不需要更改 mechanism
    - 比如在 scheduling 中，policy 维护一个列表决定哪些进程先执行；mechanism 不管那么多，哪个任务在前就运行哪个
- Operating System Structure
  - 总体来说有 $4$ 种设计思路
    + Simple structure – MS-DOS
    + Monolithic – Unix, Linux
    + Layered – an abstraction
    + Microkernel – Mach，
  #grid(
    columns: 2,
    fig("/public/assets/Courses/OS/2024-09-25-17-20-23.png"),
    fig("/public/assets/Courses/OS/2024-09-25-17-20-42.png"),
    fig("/public/assets/Courses/OS/2024-09-25-17-19-34.png", width: 50%),
    fig("/public/assets/Courses/OS/2024-09-25-17-19-43.png")
  )
- Modules
  - Many modern operating systems implement loadable kernel modules (LKMs)
  - 面向对象；每个核心组件独立；每个部分都通过接口与其他部分交流；每个部分可以根据需要在内核中加载
  - 总体来说，类似于 layers 但更灵活
- Hybrid Systems
  - 实际上大多数现代 OS 都不是纯粹的上述 $4$ 种设计
- System Boot
  - 当系统上电后，从固定的内存位置开始执行；OS 必须对 hardware available，以便硬件可以启动它
    - 一小段代码 —— 存储在 ROM 或 EEPROM 中的 bootstrap loader, BIOS 会定位内核，将其加载到内存中，并启动它
    - 有时是两步过程，固定位置的 boot block 由 ROM 代码加载，从磁盘加载 bootstrap
    - 现代系统用 Unified Extensible Firmware Interface(UEFI)取代 BIOS
  - Common bootstrap loader, GRUB 允许从多个磁盘、版本和内核选项中选择内核
  - 内核加载后，系统开始运行
  - 引导加载程序经常允许各种引导状态，例如单用户模式

= Processes
== Process concept
- Process memory layout
  - 一般来说 stack 会比 heap 快得多，因为大多数时候里 cache 里
  - 当 stack meets heap 时，会发生著名的 stack overflow（常见于错误递归的情况）
  #fig("/public/assets/Courses/OS/2024-10-08-13-40-04.png", width: 80%)
- Stack Frame (Activation Record)
  - 栈帧，每次调用新函数的时候，`sp` 指向新的位置，`fp` 指向原本 `sp` 的位置，它们之间的空间就是这个函数的内存布局
    - 这里讲课用的是 arm64 的寄存器规定
  #fig("/public/assets/Courses/OS/2024-10-08-13-54-25.png", width: 80%)
- Process Control Block (PCB)
  - 一个进程的所有信息都在 PCB 里，linux 里面叫 `task_struct`
  - 会有一个链表把所有 PCB 串起来
  - 一般至少有以下信息：
    + Process state: running, waiting, etc
    + Program counter: location of instruction to next execute
    + CPU registers: contents of all process-centric registers
    + CPU scheduling information: priorities, scheduling queue pointers
    + Memory-management information: memory allocated to the process
    + Accounting information: CPU used, clock time elapsed since start, time limits
    + I/O status information: I/O devices allocated to process,list of open files

== Process State
- 要记住这张图
  #fig("/public/assets/Courses/OS/2024-10-08-14-05-49.png", width: 80%)
- 下面我们先讲 new 和 terminated，然后再讲 running, ready, waiting

=== 进程创建(new)
- 进程创建就像一棵树，每个 process 拥有唯一 `pid` 和指向它的父节点的 `ppid`
- 名字带 `d` 的表示它是一个 daemon 进程（守护进程），不会与 user 交互，默默地在后台跑
  #fig("/public/assets/Courses/OS/2024-10-08-14-43-53.png", width: 80%)
- 父进程在创建子进程时，他可以选择等待子进程结束，也可以不等待；子进程可以是父进程的 `fork()`，也可以是新的程序
  - `fork()`
  - `create_process()` in Windows
  - `fork()` + `exec()`: 简洁（参数少）、分工、联系（父进程与子进程），但比较复杂、性能差、不安全
- 一个经典考点是对 `fork()` 的理解
  ```c
  int main () {
      fork();
      if (fork()) {
          fork();
      }
      fork();
  }
  ```
- `exec*()` family
  - `ls` 的例子
  #fig("/public/assets/Courses/OS/2024-10-08-14-50-55.png", width: 80%)

=== 进程结束(terminated)
- 像上图那样，parent 需要等待 child 结束
  - `wait()` 等待所有的 child process 结束
  - `waitpid()` 等待指定 child process 结束
  - 但对于非正常结束的进程，需要用 `signal` 来处理
- signal
  - *signal* 是一个 asynchronous event，程序必须以某种形式对它做出反应，可以把它想象成 software interrupt
  - `signal()` 允许程序指定如何处理 signal
    ```c
    signal(SIGINT, SIG_IGN);    // ignore signal
    signal(SIGINT, SIG_DFL);    // set behavior to default
    signal(SIGINT, my_handler); // customize behavior
        // handler is as:void my_handler(int sig){...}
    ```
- zombie
  - 当 child 进程结束了，parent 却还没结束，这个 child 就成了 *zombie*
  - 直到 OS collect garbage 或者 parent 处理
  - parent 进程可以调用 `wait()` 或 `waitpid()` 来获取它的 exit code 并回收
  - 比如：当 parent 陷入无限循环，而且没有设置 handler 时，child `exit()`，却没有被处理，它就成了 zombie
- orphan
  - 当 parent 进程结束了，child 却还没结束，这个 child 就成了 *orphan*
  - 它会被 `init` 进程(or `systemd`, `pid` = 1)收养(`adopted`)

=== Process Scheduling
- Process scheduler 维护两个 queue
  + Ready queue: 进程已经准备好了，等待 CPU
  + Wait queue: 进程等待某个事件发生


