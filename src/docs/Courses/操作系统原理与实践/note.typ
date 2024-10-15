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
  - `exec()` 会把 process 的那一块内存清空，然后把新的程序加载进去
    - 如果新的程序内存要求比原本的大，会“往下扩”（其实是虚拟内存机制）
  - 可以传递：
    + path for the executable
    + command-line arguments to be passed to the executable
    + possibly a set of environment variables
  - `ls` 的例子（可以 `strace` 用 syscall 查看进程创建的情况，但是不会显示 `fork`）
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
  - 当 child 进程 terminate 了，这个 child 就成了 *zombie*
  - 直到 OS collect garbage 或者 parent 调用 OS 来处理
  - parent 进程可以调用 `wait()` 或 `waitpid()` 来获取它的 exit code 并回收
    - 为什么一定要 OS 回收？因为 child 进程可以回收基本所有东西，但维度 PCB 没有办法 deallocate
    - 为什么不立即回收？因为 zombie 不会实际消耗 CPU 资源，而只是略微占用一点内存
  - 比如：当 parent 陷入无限循环，而且没有设置 handler 时，child `exit()`，却没有被处理，它就成了 zombie
- orphan
  - 当 parent 进程 die 了，child 却还没结束，这个 child 就成了 *orphan*
  - 它会被 `init` 进程(or `systemd`, `pid` = 1)收养(`adopted`)

=== Process Switching
- Process scheduler 维护两种 queue
  + Ready queue: 进程已经准备好了，等待 CPU（多少个 CPU 就有多少个）
  + Wait queue: 进程等待某个事件发生，有多种类型每种一个
  #fig("/public/assets/Courses/OS/2024-10-09-16-43-44.png", width: 80%)
  - queue 的数据结构跟 ADS 里面有所不同，ADS 里面往往做成 node，包含实际数据；而 OS 这边为了通用性往往就是一个包含 `prev, next` 俩指针的结构，搬到哪都能用
- Context Switch
  - 这里的 context 指的就是 registers，因为它们只有一份，所以需要保存
  - context switch 一定得是在 Kernel Mode，即 privileged，因为它涉及到系统资源、能改 pc
  + 如果 switch 发生在 kernel mode，就跟实验 2 里做的一样。在 `cpu_switch_to` 把 context 存到相应 PCB 里
  + 如果 switch 发生在 user mode，还牵涉到 per-thread kernel stack，更确切地说是 pt_regs(user context been saved)。在 `kernel_entry` 时把 context 存到 pt_regs，切换到 kernel stack，然后在 `kernel_exit` 时恢复
    #fig("/public/assets/Courses/OS/2024-10-09-17-44-58.png")
  - 思考 `fork()` 为什么能返回两个值(Return new_pid to parent and zero to child)？
    - 其实是有“两套东西”
    + 对 parent process，`fork()` 就是一个 syscall，返回值存在 pt_regs 里
    + 对 child process，其实也是通过 pt_regs，手动把它设为 $0$
  - When does child process start to run and from where?
    - When forked, child is READY $->$ context switch to RUN
    - After context switch, run from `ret_to_fork`
    - `ret_from_fork` $->$ `ret_to_user` $->$ `kernel_exit` who restores the pt_regs
- Code through，Linux 进程相关代码的发展史

=== CPU Scheduling
- Definition
  - 决定 processes/threads 谁用？用多久？
  - CPU Scheduling 对系统 performance and productivity 有很大影响
  - The *policy* is the scheduling strategy，怎么选择下一个要执行的进程
  - The *mechanism* is the dispatcher，怎样快速地切换到下一个进程
- CPU-I/O Burst Cycle
  - I/O-bound process: 主要是等 I/O。大部分的操作都是 I/O-bound 的
  - CPU-bound process: 主要是等 CPU
- CPU scheduler 有两种类型
  + Non-preemptive: 一个进程想跑多久就多久
  + Preemptive: 当一个进程被另一个进程抢占时，被抢占的进程会被放回 ready queue
  #note()[
    + A process goes from RUNNING to WAITING
      - e.g. waiting for I/O to complete
    + A process goes from RUNNING to READY
      - e.g. when an interrupt occurs (such as a timer going off)
    + A process goes from WAITING to READY
      - e.g. an I/O operation has completed
    + A process goes from RUNNING to TERMINATED
    + A process goes from NEW to READY
    + A process goes from READY to WAITING
    - 在非抢占式的情况中，只有第二种情况不会发生。在抢占式的情况中，所有的情况都会发生
    - Preemptive scheduling is good, since the OS remains in control, but is complex
  ]
- Dispatch latency
  - time it takes for the dispatcher to stop one process and start another to run，这段时间是不做实际工作的
- Scheduling Objectives(Criteria)
  + maximize CPU Utilization, Throughput, Turnaround time
  + minimize Waiting time, Response time
  - 一些目标相互冲突，e.g. 频繁的 context switches 有助于 Response time，但会降低 Throughput

=== Scheduling Algorithms
+ First-Come, First-Served Scheduling(FCFS)
+ Shortest-Job-First Scheduling(SJF)
+ Round-Robin Scheduling(RR)
+ Priority Scheduling
+ Multilevel Queue Scheduling
+ Multilevel Feedback Queue Scheduling
- 一般用 Waiting Time, Turnaround Time 来比较，要学会画 Gantt 图和计算（多个 examples）
- FCFS: 字面意思理解
- SJF
  - 分两种，Preemptive 和 Non-preemptive
  - 基本上就是 ADS 里讲的那种，被证明是 optimal 的
  - 但在执行进程前，无法得知 burst time（只能预测），所以只存在于理论与比较
- RR
  - 每个进程都有一个时间片(quantum)，时间片用完了就换下一个
  - 优点是简单，缺点是可能会有很多 context switch
  - 时间片的大小是一个 trade-off，太小会导致频繁的 context switch，太大会导致总 dispatch latency 不可接受
- Priority
  - 一个 Problem 是 *Starvation*，即低优先级的进程永远得不到 CPU
  - 可以用 *priority aging* 来解决，把时间也算到优先级里
  - Priority 可以与 RR 结合
- Multilevel Queue Scheduling
- Multilevel Feedback Queue Scheduling
  - 根据反馈来调整队列，比如给一个 quantum，如果你用完了，把你往下降
  #fig("/public/assets/Courses/OS/2024-10-15-14-55-52.png", width: 70%)
- 怎么样算是 Good Scheduling Algorithm
  - Few *analytical/theoretical* results are available
  - *Simulation* is often used
  - *Implementation* is key

=== Multiple-Processor Scheduling
- Multithreaded Multicore System
  #fig("/public/assets/Courses/OS/2024-10-15-15-15-14.png", width: 40%)
  - 现在大部分是 (b) 架构
  #fig("/public/assets/Courses/OS/2024-10-15-15-15-56.png", width: 40%)
  - CPU 中计算单元很快，但是内存访问是很慢的，需要 stall。为了利用这段 stall 的时间，我们就多用一个 thread，在这个 thread stall 时执行另一个 thread （hyperthreading，属于硬件线程，由硬件来调度，不同于 OS 里的 thread）
- Multiple-Processor Scheduling
  - Load Balancing
    - Load balancing attempts to keep workload evenly distributed
    - Push migration – periodic task checks load on each processor, and if found pushes task from overloaded CPU to other CPUs
      - core 上工作太多，要推给其他的 core
    - Pull migration – idle processors pulls waiting task from busy processor
      - core 上工作太少，就从其他的 core 上拉一些任务过来
  - Processor Affinity: 有的进程我们想要在一个 core 上跑
    - Soft affinity – the operating system attempts to keep a thread running on the same processor, but no guarantees
    - Hard affinity – allows a process to specify a set of processors it may run on
- Linux Scheduling
  - Nice command: 数越小，优先级越高
    - `ps -e -o uid,pid,ppid,pri,ni,cmd`
  - linux 0.11 源码
    - Implemented with an array (no queue yet)
    - Round-Robin + Priority，体现了 aging 思想
    - 思考各在何处体现
    - 不足之处：$O(N)$ 的效率，priority 修改的响应性不好
  - linux-xxx，略
  - linux 2.6
    - 实现了 $O(1)$ 的调度
    - 不好的点在于 policy, mechanism 没有分开，且依赖于 `bsfl` 指令
  - 后来引入了 Completely Fair Scheduler(CFS)，用 Red-Black Tree 来实现

= Inter-Process Communications(IPCs)
- 与之对应的 intra-process 表示进程内部
- 前面我们把进程介绍为独立的单元，互相之间只有 switch，但实际上进程之间因为 Information sharing, Computation speedup, Modularity, Convenience 等原因需要进行通信
