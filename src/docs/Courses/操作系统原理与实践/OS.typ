#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "操作系统原理与实践",
  lang: "zh",
)

#info()[
  - 感觉 #link("https://note.hobbitqia.cc/OS/")[hobbitqia 的笔记] 比较好
  - 还有 #link("https://note.isshikih.top/cour_note/D3QD_OperatingSystem/")[修佬的笔记]，虽然老师不一样
]

#note(caption: "Mid-Term Review")[
  - 梳理整个脉络和大致内容
    + Computer architecture
      - 计算机模型，内存布局与解释，CPU 是什么
    + OS overview
      - OS is resource *abstractor* and *allocator*, and is a *control* program
      - OS Event: interrupt and exception，特别地讲了 system call
    + OS structures
      - Kernel, and System services
      - Syscall 的具体实现、如何使用、种类
      - Linkers and Loaders
      - OS design
    + Processes
      - Process 是什么，包含了什么
      - Process state
        - create: fork, exec
        - terminate: wait and signal, zombie and orphan
        - ready, running, waiting: context switch，并引出 scheduling
      - 进程作为隔离单元，如何交互，引出 IPC
      - IPC 很笨重，引出更 natural 的 thread
    + Scheduling
      - 调度算法，甘特图与计算
    + Thread
      - 定义、内存布局、优劣
      - user thread 和 kernel thread，以及涉及到它们的 context switch
    + Synchronization
      - Race Condition
      - Synchronization tools: spinlock, semaphore
      - Synchronization 解决具体问题
      - Synchronization 设计得不好就会导致 deadlock
    + DeadLock
      - 死锁四个条件
      - 死锁的四个解决方法：prevention, avoidance, detection, recovery
]

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

= Structures
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
#grid(
  columns: 2,
  [
    - ELF binary basics
      - ELF: Executable and Linkable Format
      - `.text`: code, `.rodata`: initialized read-only data, `.data`: initialized data, `.bss`: block started by symbol
    - Linking
      - Static linking
        - 把所有需要的代码都 link 到一个 large binary 中，移植性好
      - Dynamic linking
        - 重用 libraries 来减少 binary 的大小
        - 谁来解析？loader will resolve lib calls
  ],
  fig("/public/assets/Courses/OS/2024-10-30-17-13-17.png", width: 50%)
)
- running a binary
  #fig("/public/assets/Courses/OS/2024-09-24-16-07-49.png")
  - Who setups ELF file mapping? Kernel, or to be more specific --- exec syscall
  - Who setups stack and heap? Kernel, or to be more specific --- exec syscall
  - Who setups libraries? loader, ld-xxx
- Running statically-linked ELF
  - Where to start? `_start`(entry point address, or elf_entry), `_start` is executed after evecve system call，并且这是运行在 user mode 的
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
  #fig("/public/assets/Courses/OS/2024-10-30-17-25-36.png", width: 60%)
  - 这里的 context 指的就是 registers，因为它们只有一份，所以需要保存
  - context switch 一定得是在 Kernel Mode，即 privileged，因为它涉及到系统资源、能改 pc
  + 如果 switch 发生在 kernel mode，就跟实验 2 里做的一样。在 `cpu_switch_to` 把 context 存到相应 PCB 里
  #fig("/public/assets/Courses/OS/2024-10-30-17-32-21.png", width: 80%)
  + 如果 switch 发生在 user mode，还牵涉到 per-thread kernel stack，更确切地说是 pt_regs(user context been saved)。在 `kernel_entry` 时把 context 存到 `pt_regs`，切换到 kernel stack，然后在 `kernel_exit` 时恢复
  #fig("/public/assets/Courses/OS/2024-10-09-17-44-58.png", width: 80%)
  - 这里可以思考一下 user stack 和 kernel stack 有什么不同？1. user space 的栈空间无限，而 kernel space 有限；2. kernel space 在栈开始的地方多了个 `pt_regs`（kernel stack 里面有两个 pc，context 里面的是 kernel 的 pc，`pt_regs` 里面的是 user 的 pc）
  #fig("/public/assets/Courses/OS/2024-10-30-17-37-34.png", width: 50%)
  - 思考 `fork()` 为什么能返回两个值(Return new_pid to parent and zero to child)？
    - 其实是有两套 user space context
    + 对 parent process，`fork()` 就是一个 syscall，返回值存在 `pt_regs` 里
    + 对 child process，其实也是通过 `pt_regs`，手动把它设为 $0$
  - When does child process start to run and from where?
    - When forked, child is READY $->$ context switch to RUN
    - After context switch, run from `ret_to_fork`
    - `ret_from_fork` $->$ `ret_to_user` $->$ `kernel_exit` who restores the `pt_regs`
- Code through，Linux 进程相关代码的发展史

== Inter-Process Communications(IPCs)
- 与之对应的 intra-process 表示进程内部
- 前面我们把进程介绍为独立的单元，互相之间只有 switch，保护得太好了。但实际上进程之间因为 Information sharing, Computation speedup, Modularity, Convenience 等原因需要进行通信
- Multiprocess Architecture example – Chrome Browser
  - 谷歌浏览器实际上是 3 中多线程 —— Browser, Render, Plugin，分别负责用户交互、渲染、插件
- Models of IPC
  + *Shared memory*
  + *Message passing*
  + Signal
  + Pipe
  + Client-Server Communication: Socket, RPCs, Java RMI
  #fig("/public/assets/Courses/OS/2024-10-16-16-38-32.png", width: 50%)
- Message-passing
  + 高开销，每次操作都要 syscall
  + 有时对用户来说很麻烦，因为代码中到处都是send/recv操作
  + 相对来说 OS 上容易实现
- Shared memory
  + 低开销，只需要初始化时少量的 syscall；对交换大量数据很有用
  + 对用户来说更方便，因为我们习惯于简单地从RAM读/写
  + 相对来说 OS 上更难实现
- 进程需要建立共享内存区域
  - 每个进程创建自己共享内存段，然后其它进程可以将其 attach 到自己的地址空间
    - 注意，这与多线程的核心内存保护理念背道而驰
  - 进程通过读/写共享内存区域进行通信，他们自己负责“不踩到对方的脚趾”，操作系统根本不参与
  - e.g. POSIX Shared Memory
  - 存在问题：不安全。任何人拿到 share_id 都可以把共享内存 attach 到自己进程上，可以观察到其他进程的数据、甚至做 DOS 攻击
  - 而且很 cubersome，会发生各种 error 需要处理，现在使用不多

=== Message Passing
- Two fundamental operations:
  - send: to send a message (i.e., some bytes)
  - recv: to receive a message
- If processes P and Q wish to communicate they
  - establish a communication “link” between them
  - This “link” is an abstraction that can be implemented in many ways (even with shared memory!!)
  - place calls to send() and recv()
  - optionally shutdown the communication “link”
- Implementation of communication link
  - Physical:
    + Shared memory
    + Hardware bus
    + Network
  - Logical:
    + Direct or indirect
      - Direct: 一个链接与且只与一对通信进程相关联，一共需要 $C_n^2$
      - Indirect: 有一个 mailbox，发信息相当于发给一个 mailbox。如果有多个进程，我们需要确定是由哪个进程接收信息
    + Synchronous or asynchronous
      - Synchronous: 发信息时，如果接收者没收到信息，就堵塞着不走；收信息时，如果发送者没有发送信息，就堵塞着不走
      - Asynchronous: Non-blocking is considered asynchronous
      - 异步效率更高，同步时效性更高。
        - Automatic or explicit buffering
    + Automatic or explicit buffering
      - Zero capacity - no messages are queued on a link. Sender must wait for receiver
      - Bounded capacity - finite length of n messages. Sender must wait if link full.X
      - Unbounded capacity - infinite length. Sender never waits

=== Signals
- 略

=== Pipes
- 充当允许两个进程通信的管道
- 问题：
  - 沟通是单向的还是双向的？
  - In the case of two-way communication, is it half or full-duplex?
  - 通信过程之间必须存在关系（即父子关系）吗？
  - 这些管道可以通过 network 使用吗？
- Ordinary pipes —— 不能从创建它的进程外部访问。通常，父进程创建一个管道，并使用它与它创建的子进程进行通信
  - 没有名字，只能通过 `fork()` 来传播
  - Producer writes to one end (the *write-end* of the pipe)
  - Consumer reads from the other end (the *read-end* of the pipe)
  #fig("/public/assets/Courses/OS/2024-10-16-17-05-47.png", width: 50%)
  - 注意 fd[0] 是 read-end，fd[1] 是 write-end（对于双方都是）
  - Windows calls these anonymous pipes
- Named pipes —— 可以在没有父子关系的情况下访问
  - 可以把名字通过网络/文件传播，这样就能交互。（可以使用 mkfifo 创建 named pipes）
- UNIX Pipes
  - In UNIX, a pipe is mono-directional. 要实现两个方向一定需要两个 pipe
  - e.g. `ls | grep foo`，创建了两个进程，一个 `ls` 一个 `grep`，`ls` writes on the write-end and `grep` reads on the read-end

=== Client-Server Communication
- 广义上的 IPC，因为是跑在两个物理机器上的交互。
  - Sockets
  - RPCs: 所有的交互都是和 stub 通信，stub 会和远端的 server 通信。存在网络问题，如丢包
  - Java RMI: RPC in Java
- 略

= Threads
== Thread Concept
- 回顾，process = code(text) section + data section + pc + registers + stack + heap
- How can we make a process faster?
  - Multiple execution units with a process
  #fig("/public/assets/Courses/OS/2024-10-16-19-42-10.png", width: 80%)
- Thread's definition: a basic unit of execution within a process
  - 当我们提出 thread 概念后，不分线程的单个进程就视为 single threaded process
  #fig("/public/assets/Courses/OS/2024-10-16-19-42-26.png", width: 60%)
  - 每个 thread 有：
    + thread ID
    + program counter
    + register set
    + Stack
  - 与同一个 process 的 threads 共享：
    + code section
    + data section
    + the heap (dynamically allocated memory)
    + open files and signals
- Advantages of Threads
  - Economy
    - Creating a thread is cheap: 如果已经有了一个线程，创建新的线程只需要给它分配一个栈。code, data, heap 都已经在内存里分配好了
    - Context switching between threads is cheap: no need to cache flush
  - Resource sharing
    - Threads naturally share memory
    - Having concurrent activities in the same address space is very powerful
  - Responsiveness
    - 如在 web server 中，一个线程在等待 I/O，当有请求来时就再分配一个线程去处理。（进程也可以，但是代价更大）
  - Scalability
    - multi-core machine
- Drawbacks of Threads
  - Weak isolation between threads: 如果有一个线程挂了，那么整个进程都会出错
  - Threads may be more memory-constrained than processes: threads 受限于 process 的空间，但在 64-bit 架构上不再是问题（？）
- Typical challenges of multi-threaded programming
  + Deal with data dependency and synchronization
  + Dividing activities among threads
  + Balancing load among threads
  + Split data among threads
  + Testing and debugging

#example1[
  - 在引入 thread 后，可以思考一下现在的 context switch 和 schedling 是怎么做的
]

== User Threads vs. Kernel Threads
- User Space 支持 threads 设计，Kernel Space 不一定，但大多数现代 OS 都支持
- Many-to-One Mode
  - 好处是在于易于实现，kernel 不用管你上层怎么干的
  - 缺点：内核只有一个线程，无法发挥 multi-core 的优势；一旦一个线程被阻塞，其他线程也会被阻塞
  #fig("/public/assets/Courses/OS/2024-10-22-13-35-06.png", width: 30%)
- One-to-One Mode
  - 优点是消除了 Many-to-One 的两个毛病，但缺点是创建开销大（但现代硬件相对不那么值钱了）
  - 把线程的管理变得很简单，现在 Linux，Windows 都是这种模型
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-09.png", width: 50%)
- Many-to-Many Model
  - $m$ to $n$ 线程，折中上面两者的优缺点。但是实现复杂
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-25.png", width: 30%)
- Two-Level Model
  - 大多数时候 many to many，但对特别重要的那种用 one to one #h(1fr)
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-34.png", width: 40%)

== Thread Libraries
- In C/C++: pthreads and Win32 threads
  - POSIX standard (IEEE 1003.1c) API for thread creation and synchronization
  - e.g. `pthread_create`, `pthread_join`, `pthread_exit`
- In C/C++: OpenMP
  - OpenMP is a set of compiler directives and an API for C, C++, and Fortran
  - Provides support for parallel programming in shared-memory environment
  - `#pragma omp parallel`，使用之后编译器会为我们切分出若干个并行块，创造出对应的线程，最后使用 join 把线程合并
- In Java: Java Threads
  - Old versions of the JVM used Green Threads, but now provides native thread，前者不再 available
  - In modern JVMs, application threads are mapped to kernel thread
  #fig("/public/assets/Courses/OS/2024-10-22-13-48-48.png")

== Threading Issues
- 线程的加入让进程的操作变得更复杂
- Semantics of `fork()` and `exec()` system calls
  - 如果一个 thread 调用了 `fork()`，可能发生两种情况
    + 创建了一个 process，只包含一个 thread(which called `fork()`)
    + 创建了一个 process，复制了所有 threads
  - Some OSes provide both options, In Linux the first option above is used（因为大部分时候 `fork()` 之后会接 `exec()`，抹掉所有的数据，因此直接复制调用线程就可以了）
  - If one calls `exec()` after `fork()`, all threads are "wiped out" anyway
- Signal handling
  - 我们之前谈论过  signals for processes，但对于 multi-threaded programs 会发生什么？有多重可能(Synchronous and asynchronous)
    + Deliver the signal to the thread to which the signal applies
    + Deliver the signal to every thread in the process
    + Deliver the signal to certain threads in the process
    + Assign a specific thread to receive all signals
  - Most UNIX versions: 一个 thread 可以指定它接受哪些 signal、拒绝哪些 signal
  - 在 Linux，比较复杂，接口都开放给用户，摆烂，程序员自己去理解吧
- Thread cancellation of target thread
  - 把一个线程的工作取消掉，如何保证取消后不影响系统的稳定性
    - Asynchronous cancellation: 立即终止。
    - Deferred cancellation: 线程会自己进行周期性检查，如果取消掉不会影响系统的稳定性，就把自己取消掉
    - 前者 may lead to an inconsistent state or to a synchronization problem，后者不会但是它的 code 写得不好看（时不时要问 "should I die?"）
- Thread-local storage
- Thread Scheduling

== windows thread & linux thread
- windows，不是很重要
- In Linux
  - The `clone()` syscall is used to create a thread or a proces
  - `clone` 有一个参数 `CLONE_VM`，如果不设置那么类似于 fork，每个线程都有自己的内存空间；如果设置了那么线程跑在同一地址空间上
  - TCB 用来存储线程的信息，Linux 并不区分 PCB 和 TCB，都是用 task_struct 来表示
  - A process is
    - either a single thread + an address space, PID is thread ID
    - or multiple threads + an address space, PID is the leading thread ID
  #grid2(
    fig("/public/assets/Courses/OS/2024-10-22-14-17-36.png"),
    fig("/public/assets/Courses/OS/2024-10-22-14-29-29.png")
  )
  - PID 如果和 LWP 相同，说明是 single-threaded process。如果不相同，说明进程有多个线程，此时进程的 PID 是主线程的 LWP
  - `task_struct` 内，`mm_struct`（与内存管理相关的信息，如页表）, `files` 指向同一个结构体，这样就实现了共享内存。而 `task_thread`, `pid`, `stack`, `comm` 等不共享
  - 通过 `thread_group` 链表将这些线程串联起来
- User thread to kernel thread mapping
  #grid(
    columns: (70%, 30%),
    [
      - One task in Linux
        - Same task_struct(PCB) means same thread, also viewed as 1:1 mapping。每个 User thread 对应一个 Kernel thread（类似于它的小号）
          - 另外，思考如果是 Many-to-one，怎么实现？答案是保证返回时 Kernel Space stack 干干净净给下一个用。这个设计其实延续到 1:1 mapping 了
          - One user thread maps to one kernel thread. But actually, they are the same thread
      - User Space 和 Kernel Space 执行的代码不同
        - User code, user space stack; Kernel code, kernel space stack
    ],
    fig("/public/assets/Courses/OS/2024-10-22-14-45-05.png")
  )

#info(caption: [Takeaway])[
  - Thread is the basic execution unit
    - Has its own registers, pc, stack
  - Thread vs Process
    - What is shared and what is not
  - Pros and cons of threa
]

= Scheduling
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

== Scheduling Algorithms
+ First-Come, First-Served Scheduling(FCFS)
+ Shortest-Job-First Scheduling(SJF)
+ Round-Robin Scheduling(RR)
+ Priority Scheduling
+ Multilevel Queue Scheduling
+ Multilevel Feedback Queue Scheduling
- 一般用 *Waiting Time*, *Turnaround Time* 来比较，要学会画 Gantt 图和计算（多个 examples）
- FCFS: 字面意思理解
- SJF
  - 分两种，Preemptive 和 Non-preemptive
  - 基本上就是 ADS 里讲的那种，被证明是 optimal 的
  - 但在执行进程前，无法得知 burst time（只能预测），所以该算法只存在于理论与比较
- RR
  - 每个进程都有一个时间片(quantum)，时间片用完了就换下一个
  - 优点是简单，缺点是可能会有很多 context switch
  - 时间片的大小是一个 trade-off，太小会导致频繁的 context switch，太大会导致总 dispatch latency 不可接受
- Priority
  - 一个 Problem 是 *Starvation*，即低优先级的进程永远得不到 CPU
  - 可以用 *priority aging* 来解决，把时间也算到优先级里
  - Priority 可以与 RR 结合
- Multilevel Queue Scheduling
  #fig("/public/assets/Courses/OS/2024-10-16-16-26-11.png", width: 60%)
- Multilevel Feedback Queue Scheduling
  - 根据反馈来调整队列，比如给一个 quantum，如果你用完了，把你往下降（优先级降低），降到最后就完全不看 priority 而是 FCFS
  #fig("/public/assets/Courses/OS/2024-10-15-14-55-52.png", width: 60%)
- 怎么样算是 Good Scheduling Algorithm
  - Few *analytical/theoretical* results are available
  - *Simulation* is often used
  - *Implementation* is key

== Thread Scheduling
- process-contention scope (PCS)
  - 每个进程分到时间片一样，然后进程内部再对线程进行调度
- system-contention scope (SCS)
  - 所有线程进行调度
- 现在主流 CPU 都是以 *thread* 为粒度进行调度的

== Multiple-Processor Scheduling
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
  + linux 0.11 源码
    - Implemented with an array (no queue yet)
    - Round-Robin + Priority，体现了 aging 思想
    - 思考各在何处体现
    - 不足之处：$O(N)$ 的效率，priority 修改的响应性不好
  + linux 1.2，引入 circular queue
  + linux 2.2，引入 Scheduling classes 和 Priorities within classes
  + linux 2.4
  + linux 2.6
    - 实现了 $O(1)$ 的调度
    - 不好的点在于 policy, mechanism 没有分开，且依赖于 `bsfl` 指令
  - 后来引入了 Completely Fair Scheduler(CFS)，用 Red-Black Tree 来实现，也有争议

= Synchronization
- Processes/threads can execute concurrently
- Concurrent access to shared data may result in data inconsistency

== Race Condition
- 多个进程并行地写数据，结果取决于写的先后顺序，这就是 Race Condition
  - 比如课件中的 counter++ 例子
  - 又比如，如果不加保护，两个进程同时 `fork()`，子进程可能拿到一样的 pid
- critical section
  - 修改共同变量的区域称为 critical section；共同区域之前叫 entry section，之后叫 exit section
  ```
  while (true) {
      [entry section]
        critical section
      [exit section]
        remainder section
  }
  ```
- 怎么实现呢？
  - Single-core system: preventing interrupts
  - Multiple-processor: preventing interrupts are not feasible (depending on if kernel is preemptive or non-preemptive)
    - Preemptive – allows preemption of process when running in kernel mode
    - Non-preemptive – runs until exits kernel mode, blocks, or voluntarily yields CPU
- Solution to Critical-Section: Three Requirements
  - Mutual Exclusion（互斥访问）
    -在同一时刻，最多只有一个线程可以执行临界区
  - Progress（空闲让进）
    - 当没有线程在执行临界区代码时，必须在申请进入临界区的线程中选择一个线程，允许其执行临界区代码，保证程序执行的进展
  - Bounded waiting（有限等待）
    - 当一个进程申请进入临界区后，必须在有限的时间内获得许可并进入临界区，不能无限等待（阻止 starvation）

== Peterson’s Solution
- Peterson’s solution solves two-processes/threads synchronization (Only works for two processes case)
  - It assumes that LOAD and STORE are atomic
    - atomic: execution cannot be interrupted
  - Two processes share two variables
    - boolean flag[2]: whether a process is ready to enter the critical section
    - int turn: whose turn it is to enter the critical section
#fig("/public/assets/Courses/OS/2024-10-22-16-22-15.png", width: 70%)
- 验证三个条件
  - Mutual exclusion
    #grid(
      columns: 2,
      column-gutter: 3em,
      [
        - P0 enters CS (flag[1]=false or turn=0), there are 3 cases
          + flag[1]=false #h(3em) $->$ P1 is out CS
          + flag[1]=true, turn=1 $->$ P0 is looping, contradicts
          + flag[1]=true, turn=0 $->$ P1 is looping
      ],
      [
        - P1 enters CS (flag[0]=false or turn=1), there are 3 cases
          + flag[0]=false #h(3em) $->$ P0 is out CS
          + flag[0]=true, turn=0 $->$ P1 is looping, contradicts
          + flag[0]=true, turn=1 $->$ P0 is looping
      ]
    )
  - Process requirement
  #fig("/public/assets/Courses/OS/2024-10-22-16-18-17.png", width: 60%)
  - Bounded waiting
    - Whether P0 enters CS depends on P1; Whether P1 enters CS depends on P0; P0 will enter CS after one limited entry P1
- 但是 Peterson's Solution 在现代机器上完全不现实
  + Only works for two processes case
  + It assumes that LOAD and STORE are atomic
  + Instruction reorder: 指令会乱序执行

== Hardware Support for Synchronization
- 既然软件上实现有困难，那就硬件上解决。Many systems provide hardware support for critical section code
- Uniprocessors: disable interrupts，当前运行的代码将不会被抢占
  - generally too inefficient on multiprocessor systems
- Solutions:
  - Memory barriers
  - Hardware instructions
    - test-and-set: either test memory word and set value
    - compare-and-swap: compare and swap contents of two memory words
  - Atomic variables

=== \*Memory Barriers
- 知道就可以了，不做要求

=== Hardware Instructions
- 特殊的硬件指令，允许我们测试和修改单词的内容，或者原子地交换两个单词的内容（不可中断）
- Test-and-Set Instruction
  - 定义如下，看起来是由多条指令实现的，但在硬件上保证 atomically
  ```c
  bool test_set(bool *target) {
    bool rv = *target;
    *target = TRUE;
    return rv:
  }
  ```
  - lock with Test-and-Set
  ```c
  bool lock = FALSE
  do {
      while (test_set(&lock)); // busy wait
      /* critical section */
      lock = FALSE;
      /* remainder section */
  } while (TRUE);
  ```
  - mutual exclusion & progress: 显然满足
  - bounded-waiting : 不一定，改造一下使它满足
  ```c
  do {
      waiting[i] = TRUE;
      while (waiting[i] && test_and_set(&lock));
      waiting[i] = FALSE;
      /* critical section */
      j = (i + 1) % n;
      while ((j != i) && !waiting[j])
          j = (j + 1) % n;
      if (j == i)
          lock = FALSE;
      else
          waiting[j] = FALSE;
      /* remainder section */
  } while (TRUE);
  ```
- Compare-and-Swap Instruction
  - 定义如下，期望是 atomically，仅当 `*value==expected` 时，将变量值设置为传递的参数 `new_value` 的值，然后返回旧值
  ```c
  bool compare_and_swap(bool *value, bool expected, bool new_value) {
    bool temp = *value;
    if (*value == expected)
        *value = new_value;
    return temp;
  }
  ```
  - Shared integer lock initialized to 0
  ```c
  while (true)
  {
      while (compare_and_swap(&lock, 0, 1) != 0); /* do nothing */
      critical section
      lock = 0;
      remainder section
  }
  ```
  - intel x86 中实现了 `cmpxchg`，就是这个指令；ARM64 使用下面这种方式实现
  #tblm[
    | thread 1 | thread 2 | thread 3 | local monitor状态 |
    | --- | --- | --- | --- |
    |  |  |  | Open Access |
    | LDXR |  |  | Exclusive Access |
    | 1 | LDXR |  | Exclusive Access |
    |  | Modify |  | Exclusive Access |
    |  | STXR |  | Open Access |
    |  | ? | LDXR | Exclusive Access |
    |  |  | Modify | Exclusive Access |
    | Modify |  |  | Exclusive Access |
    | STXR |  |  | Open Access (No Failure?) |
    |  |  | STXR |  |
  ]

=== Atomic Variables
- One tool is an atomic variable that provides atomic (uninterruptible) updates on basic data types such as integers and booleans.
- The increment() function can be implemented as follows:
  ```c
  void increment(atomic_int *v) {
      int temp;
      do {
          temp = *v;
      } while (temp != (compare_and_swap(v,temp,temp+1)));
  }
  ```

== Mutex Lock
- Mutex Locks 支持 `acquire()`（获得这个锁）和 `release()`（释放这个锁）。它们是原子的
- This solution requires busy waiting, This lock therefore called a spinlock
  ```c
  bool locked = false;
  acquire() {
      while (compare_and_swap(&locked, false, true)); // busy waiting
  }
  release() {
      locked = false;
  }
  ```
- 问题：如果一个进程拿到锁之后，时间片内没做完，切换到另一个进程，该进程有时间片但是拿不到锁，一直 spin，浪费 CPU 时间
- 解决：利用 Semaphore，即线程拿不到锁的时候，就不要在 ready queue 了，yield $->$ moving from running to sleeping

== Semaphore
- Implementation with waiting queue
  ```c
  wait(semaphore *S) {
      S->value--;
      if (S->value < 0) {
          add this process to S->list;
          block(); // 把当前的进程 sleep，放到 waiting queue 里面
      }
  }
  signal(semaphore *S) {
      S->value++;
      if (S->value <= 0) { // 队列里面有人在睡觉
          remove a proc.P from S->list;
          wakeup(P); // 从 waiting queue 里面拿出一个进程，放到 ready queue 里面
      }
  }
  ```
  - 利用 Semaphore
    - 现在 critical section 不再是 busy waiting 了
    - 但注意 wait, signal 是需要 atomic 的，所以我们需要用 mutex lock 来保护这两个操作，这里还是 busy waiting 的
    ```c
    Semaphore sem; // initialized to 1
    do {
        wait(sem);    // busy waiting
        critical section // No busy waiting on critical section now
        signal(sem);  // busy waiting
        remainder section
    } while (TRUE); // while loop but not busy waiting
    ```
- 比较 mutex or spinlock $<=>$ Semaphore
  - Mutex or spinlock
    - Pros: no blocking
    - Cons: Waste CPU on looping
    - Good for short critical section
  - Semaphore
    - Pros: no looping
    - Cons: context switch is time-consuming(?)
    - Good for long critical section
  - Linux 里面往往前者用得多，因为一般只是拿来短暂地保护某个变量
- Semaphore in practice (an example)
  #fig("/public/assets/Courses/OS/2024-10-23-17-08-33.png")
  - `m->flag` 指的就是前面的 `value`
  - 一个常见的 bug 是，把 $21$ 和 $22$ 行的顺序搞反了，会导致持锁 sleep

== Synchronization Problems
- Deadlock and Starvation
  - Deadlock 发生意味着 Starvation 发生，但 Starvation 不一定因为 Deadlock
- Priority Inversion: a higher priority process is indirectly preempted by a lower priority task
  - 低优先级任务拿到了锁，但因为低优先级而一直得不到 CPU，因此永远无法完成而释放锁；高优先级一直等待锁
  - Solution: priority inheritance
    - 短暂地把正在等待的进程 $P_H$ 的高优先级赋给持有锁的进程 $P_L$

== Linux Synchronization
- 2.6 以前的版本的 kernel 中通过禁用中断来实现一些短的 critical section；2.6 及之后的版本的 kernel 是抢占式的
- Linux 提供：
  + Atomic integers
  + Spinlocks
  + Semaphores
    - 在 `linux/include/linux/semaphore.h` 中，`down()` 是 `lock`（如果要进入 sleep，它会先释放锁再睡眠，唤醒之后会立刻重新获得锁），`up()` 是 `unlock`
  + Reader-writer locks

== POSIX Synchronization
- POSIX 是啥？Portable Operating System Interface，开放给 user space 的 synchronization
- POSIX API provides
  + mutex locks
  + Semaphores
  + condition variables
    - 跟 semaphore 的本质区别在于它支持 `broadcast`，或者说 wakeup all

== Synchronization Examples
- 接下来我们来看如何用 semaphore 来解决一些经典问题

=== Bounded-Buffer Problem
- Two processes, the producer and the consumer share n buffers
  - producer 生产数据并放到 buffer；当 buffer 满的时候，生产者不能再放数据，应该 sleep
  - the consumer consumes data by removing it from the buffer. 当 buffer 空的时候，消费者不能再取数据，应该 sleep
- Solution
  - $n$ buffers, each can hold one item
  - semaphore *mutex* initialized to the value $1$
  - semaphore *full-slots* initialized to the value $0$
  - semaphore *empty-slots* initialized to the value $N$
- The producer precess
  ```c
  do {
      // produce an item
      wait(empty-slots); // empty-slots 减一，如果拿不到就 sleep 了
      wait(mutex); // wait for the buffer to be available
      // add the item to the buffer
      signal(mutex); // signal that the buffer is available
      signal(full-slots); // signal that the buffer is full
  } while (TRUE);
  ```
  - `wait(empty-slots)` 和 `wait(mutex)` 不能调换，否则导致“带着锁睡觉”
  - `wait(empty-slots)` 和 `signal(full-slots)` 也不能调换，否则。。。。
- The Consumer process
  ```c
  ```
- 注意 `full-slots`, `empty-slots` 是多值 semaphore，而 `mutex` 是 binary semaphore
  - 既然 `mutex` 是二值的，那为什么不能用 spin lock 来设计它而要用 semaphore 呢？
  - 这是因为我们不确定中间 "add the item to the buffer" 的长短，因此把这块 critical section 用 semaphore 来保护，减少 busy waiting
  - 考试中也是这样，都默认用 semaphore 来解决，不用考虑 spin lock
  - 这种设计可以出两个题，以后面的 Readers-writers problem 为例，思考：
    + RA reading data 的时候，会进程切换到 WA 吗？
    + WA 卡住了 RA, RB, RC（先后），会先切换到 RB, RC 而不是 RA 吗？
    - 答案是都不会，因为它们此时在各自 semaphore 的 waiting queue 里面，并不在 ready queue 里面

=== Readers-writers problem
- A data set is shared among a number of concurrent processes
  - readers: only read the data set; they do not perform any updates
  - writers: can both read and write
  - 多个 reader 可以共享，即同时读；但只能有一个 write 访问数据（写和读也不共享）
- Solution
  - semaphore *mutex* initialized to $1$
  - semaphore *write* initialized to $1$
  - integer *readcount* initialized to $0$
- The writer process
  ```c
  do {
    wait(write);
    // write the shared data
    signal(write);
  }
  ```
- The readers process
  ```c
  do {
      wait(mutex);
      readcount++;
      if (readcount == 1) // 如果是第一个 reader
          wait(write);    // 就把 write 锁住
      signal(mutex)
      reading data // 这里 readers 之间不会卡住
      wait(mutex);
      readcount--;
      if (readcount == 0) // 如果是 last reader
          signal(write);  // 就把 write 释放掉
      signal(mutex);
  } while(TRUE);
  ```
  - mutex 用来保护 readcount，这里如果 count 是 1，就获得 write 的锁来保护这个 read
  - 假设 writer 拿到了锁，来了 3 个 reader，那么第一个会 sleep 在 `write` 上，剩下 2 个 reader 会 sleep 在 `mutex` 上
- Variations of readers-writers problem
  - 现在这种写法是 Reader first：如果有 reader holds data，writer 永远拿不到锁，要等所有的 reader 结束。比如 RA, WA, RB，那么 WA 会一直等 RB 结束
  - Writer first：如果 write ready 了，他就会尽可能早地进行写操作。如果有 reader hold data，那么需要等待 ready writer 结束后再读
- 这种题型的几个难度级别
  + 最难的是 definition 不告诉你
  + 接着是告诉你 definition，只写代码
  + 再接着是代码画行，减少可能性
  + 再接着是行里面写部分（程序填空）
  + 最简单的是所有都写了，只问问题让你解释

=== Dining-philosophers problem
- 哲学家就餐
  - 五个哲学家，五根筷子，每个哲学家只会 thinking 和 eating，但是他们需要用筷子
  - 每次只能拿一根筷子，但是要拿到两只筷子才能吃饭
  - 能够检验一个 sync primitives 的 multi-resource synchronization
- Naive solution
  - semaphore *chopstick[5]* initialized to $1$
  ```c
  do {
    wait(chopstick[i]);
    wait(chopstick[(i+1)%5]);
    eat
    signal(chopstick[i]);
    signal(chopstick[(i+1)%5]);
    think
  } while (TRUE);
  ```
  - 每个人都先拿自己左边的筷子，再准备拿右边的筷子，会导致卡死 (deadlock)
- Solution (an asymmetrical solution)
  - 奇数哲学家先拿左边，偶数哲学家先拿右边
  ```c
  do {
    if (i % 2 == 0) { // even, right first
        wait(chopstick[i]);
        wait(chopstick[(i+1)%5]);
    } else {          // odd, left first
        wait(chopstick[(i+1)%5]);
        wait(chopstick[i]);
    }
    eat
    signal(chopstick[i]);
    signal(chopstick[(i+1)%5]);
    think
  } while (TRUE);
  ```

= Deadlocks
== System Model of deadlock
- 前面 Synchronization 设计得不好就会导致 Deadlocks
- Deadlock: a set of blocked processes each holding a resource and waiting to acquire a resource held by another process in the set
  - 一个最简单的例子
  #align(center, grid2(
    grid2(
      columns: 2,
      column-gutter: 8pt,
      row-gutter: 6pt,
      [$P_1$],[$P_2$],
      [wait(A)], [wait(B)],
      [wait(B)], [wait(A)]
    ),
    fig("/public/assets/Courses/OS/2024-10-29-15-30-55.png", width: 50%)
  ))
  - Note: most OSes do not prevent or deal with deadlocks. 如果发生了死锁，就把它们 kill 掉

#info[
  - Deadlock problem
  - System model
  - Handling deadlocks
    + deadlock prevention
    + deadlock avoidance
    + deadlock detection
    + deadlock recovery
]

- *Deadlock 发生的四个条件*
  - *Mutual exclusion*: 互斥，资源在一个时间只能被一个进程使用
  - *Hold and wait*: 已经有了一些资源，同时想要更多资源
  - *No preemption*: 已经获得的资源不能被抢占，只能由自己释放
  - *Circular wait*

== Resource-Allocation Graph
- Two types of nodes
  - Process node $P = {P_1, P_2, ..., P_n}$
  - Resource node $R = {R_1, R_2, ..., R_m}$
- Two types of edges
  - Request edge: $P_i -> R_j$ 进程需要这个资源
  - Assignment edge: $R_j -> P_i$ 资源已经分配给这个进程

#note[
  - If graph contains no cycles $=>$ no deadlock
  - If graph contains a cycle
    - if only one instance per resource type $=>$ deadlock
    - if several instances per resource type $=>$ possibility of deadlock
]

== Handle Deadlocks
- Ensure that the system will never enter a deadlock state
  - *Prevention*
  - *Avoidance*
- Allow the system to enter a deadlock state and then recover - database
  - *Deadlock detection* and *recovery*
- Ignore the problem and pretend deadlocks never occur in the system - most OSes

=== Deadlock Prevention
- 打破死锁四个的任意一个条件
- How to prevent mutual exclusion
  - sharable 的可以，non-sharable 的没办法
- How to prevent hold and wait
  - 申请资源时不能有其他资源，要一次性申请所有需要的资源；只有所有资源都释放了才能再次申请
  - 利用率低，而且可能有进程永远拿不到所有需要的资源，而无法开始
- How to prevent no preemption
  - 可以抢，但不实用
- How to handle circular wait
  - 给锁一个优先级排序，取锁的时候要求从高往低取锁。
  - require that each process requests resources in an increasing order
  - Many OS adopt this strategy，因为它很简单

=== Deadlock Avoidance
- 用一些算法，在分配资源之前，先判断是否会死锁，如果会死锁就不分配
- Avoidance 基本都需要进程 request 多少资源的 extra information，这其实是 inpractical 的
- Safe State
  - 系统中所有进程的序列 $<P_1, P_2, ..., P_m>$
  - 满足序列里的每一个进程都可以被满足（利用空闲的资源和之前的进程释放的资源）

#note[
  #grid(
    columns: 2,
    column-gutter: 12pt,
    [
      - If a system is in safe state $=>$ no deadlocks
      - If a system is in unsafe state $=>$ possibility of deadlock
      - Deadlock avoidance $=>$ ensure a system never enters an unsafe state
    ],
    image("/public/assets/Courses/OS/2024-10-30-16-19-23.png", width: 40%)
  )
]

- Deadlock Avoidance Algorithms
  - Single instance of each resource type $=>$ use resource-allocation graph
    - 新增一种 edge: claim edge $P_i -> R_j$，表示进程想要这个资源，但还没 request
    - [ ]
  - Multiple instances of a resource type $=>$ use the banker’s algorithm
    - 通过四个矩阵刻画一个时间内各个进程对各种资源的持有和需求情况
      - available: 当前还没有被分配的空闲资源
      - max: 进程所需要的总资源（计算中没啥用）
      - allocation: 已经分配的资源
      - need: 还需要分配多少资源
    - 选取一个 need（的每一项都对应地）小于 available（的对应项）的进程，其运行完后会将 allocation 释放回 available，以此类推

=== Deadlock Detection
- 允许系统进入死锁，但是 Detect 并 Recover 它
- Single Instance Resources
  - 使用 wait-for graph，有环就有 deadlock
  - 有一个 $n^2$ 的算法检测环
- Multiple Instance Resources
  - 类似银行家算法，使用 allocation, request, available 三个矩阵，对每种序列进行计算
  - 如果找不到任何安全序列，则说明系统处于死锁状态

=== Deadlock Recovery
- 最暴力的方法，Terminate deadlocked processes
- Options I: 把所有死锁着的进程杀掉，或者每次杀掉一个进程直到死锁环被破坏
  - 选择哪个进程来 kill 是个问题
    + priority of the process
    + how long process has computed, and how much longer to completion
    + resources the process has used
    + resources process needs to complete
    + how many processes will need to be terminated
    + is process interactive or batch?
- Options II: Resource preemption
  - Select a victim
  - Rollback
  - Starvation
    - How could you ensure that the resources do not preempt from the same process?

#note(caption: "Takeaways")[
  - Deadlock occurs in which condition?
  - Four conditions for deadlock
  - Deadlock can be modeled via resource-allocation graph
  - Deadlock can be prevented by breaking one of the four conditions
  - Deadlock can be avoided by using the banker’s algorithm
  - A deadlock detection algorithm
  - Deadlock recover
]

= Main Memory
- 从这里开始跨入 OS 内存管理的新纪元
- 背景
  - 程序必须被（从磁盘）拿到内存并放置在进程中才能运行
  - *Main memory* and *registers* are only storage that CPU can access directly，其中 rigister access 只用 one CPU clock (or less)，而 main memory 需要 stall
  - Protection of memory is required to ensure correct operation

== Partition evolution
- In the beginning
  - 最开始我们把一个程序加载到物理内存里，只能执行一个 job，如果 job 比物理内存还大就要分治 divide and conquer，需要 partition
  - 后来我们有多个进程要同时进行，也是使用 partition 的方法，不同的分区执行不同的进程
- Partition requirements
  - *Protection* – keep processes from smashing each other
  - *Fast execution* – memory accesses can’t be slowed by protection mechanisms
  - *Fast context switch* – can’t take forever to setup mapping of addresses
- Physical Memory
  - 问题
    + 不能挪，否则需要更新大量的指针
    + 内存空隙，运行到后期巨量碎片无法使用
  - 从而提出（初版的）Logical Memory，由我们自己定义的地址形式。具体翻译为物理地址由硬件实现
- Logical Memory v1
  - *offset within a partition*
  - Base and Limit registers
    - *Base* added to all addresses
    - *Limit* checked on all memory references 每次访问时检查是否超过了 Limit，如果是就说明越界了
    - Loaded by OS at each *context switch*
    - 每个进程有自己的 base 和 limit 寄存器，每次进程切换时，OS 都会将 base 和 limit 寄存器的值更新为当前进程的值（线程不需要，因为线程是共享的地址空间）
    #grid2(
      fig("/public/assets/Courses/OS/2024-11-05-14-38-15.png", width: 70%),
      fig("/public/assets/Courses/OS/2024-11-05-14-42-54.png")
    )
  - Advantages
    + Built-in protection provided by Limit: No physical protection per page or block
    + Fast execution: Addition and limit check 的实现可以挪到硬件上
    + Fast context switch: Need only change base and limit registers
    + No relocation of program addresses at load time: All addresses relative to zero
    + Partition can be suspended and moved at any time
      - Process is unaware of change. 修改 base 即可移动进程，进程是意识不到的。
      - Expensive for large processes. 移动进程需要改 base，还要把旧的内容全部改到新的位置，耗时
  - 接下来我们思考应该问题，partition 应该多大？

== Memory Allocation Strategies
- Fixed partitions
  - 所有 partition 的 size 是固定的，易于实现
  - 但是要切多大？
    - 如果切的太小，可能有大进程无法加载进来（只能 divide and conquer）
    - 如果切的太大，会有*内部碎片*
- Variable partitions
  - 长度不一致，按需划分。即要给一个进程分配空间时，我们找到比他大的最小的 partition，然后把他放进去
  - 有 3 种分配方法
    + first-fit: allocate from the first block that is big enough
    + best-fit: allocate from the smallest block that is big enough
    + worst-fit: allocate from the largest hole
    - 考一个选择题
  - Problem – *外部碎片 External Fragmentation*: Variable partitions 可以避免内部碎片，但无论如何总是有外部碎片，在 partition 之外的空闲空间太小，无法被任何进程使用，此时我们需要碎片整理
  - 亦或者，我们可以用 Segmentation 机制来把进程分到多个 section

== Segmentation
- 从这里开始，section, or partition, or segmentation 都是一个概念
- 一个程序分成 text、data、stack 等多个区域，每个区域就用一个 partition 来代表它
- Logical Address v2
  - *`<segment-number, offset>`* segment-number 表示属于第几组，offset 表示 segment 内的偏移量
  #fig("/public/assets/Courses/OS/2024-11-05-15-13-12.png", width: 70%)
  - 每个进程有自己的 *Segment register table（段表）*，通过 limit 实现 variable partitions
    #tbl(columns:3,[base],[limit],[权限],[base],[limit],[权限],[...],[...],[...])
    - 可以看到它额外实现了权限控制（但是跟之后的 paging 机制比，这个权限控制很不细粒度）
- 然而 Segmentation 并没有完全解决外部碎片的问题
  - 我们之后将会利用 fixed partitions 的办法来解决 —— Paging

== Address Binding & Memory-Management Unit
- 到这里我们先做个总结
- 在程序的不同阶段，地址有不同的表现方式：
  - source code addresses are usually symbolic. (e.g., variable name)
  - compiler binds symbols to relocatable addresses. (e.g., “14 bytes from beginning of this module”)
  - linker (or loader) binds relocatable addresses to absolute addresses.
- Logical v.s. Physical Address
  - Logical address – generated by the CPU; also referred to as virtual address.
    - CPU 看不到物理地址，只用逻辑地址，需要经过特定的部件转化为物理地址。
  - Physical address – address seen by the memory unit.
    - 内存单元只能理解物理地址，它是无法改变的。
  - 物理地址对应物理地址空间(Physical Address Space)，逻辑地址对应“逻辑地址空间”(Logical Address Space)，实际上并不存在，而是由一个映射所定义
- MMU
  - 我们之前说要把逻辑地址到物理地址的转换放到硬件上实现，从而不影响速度，这就是 MMU(Memory-Management Unit)
  #grid2(
    fig("/public/assets/Courses/OS/2024-11-05-15-29-00.png"),
    fig("/public/assets/Courses/OS/2024-11-05-15-29-05.png")
  )

#note(caption: [takeaway])[
  - Partition evolution
  - Memory partition-fixed and variable
    - first,best,worst fit
    - fragmentation: internal / external
  - Segmentation
    - Logical address vs physical address
  - MMU:address translation protection
]

== Paging
- Fixed 和 Variable 划分都是物理连续的分配，Paging 是把所有内存都变成不连续的，这样空闲的内存不管在哪，都可以分配给进程，避免了外部碎片
- Basic methods
  - Divide *physical* address into fixed-sized blocks called *frames*（物理帧号）
    - Keep track of all free frames.
  - Divide *logical* address into blocks of same size called *pages*（虚拟页号）
  - 页和帧是一样大的，Size is power of 2, usually 4KB
  - 为了跑一个 $N$ pages 的程序，需要找到 $N$ 个 free 的 frames 把程序加载上去
  - 把 $N$ 个帧映射到 $N$ 个页，这个存储帧到页的映射的数据结构叫*页表 page table*
- Paging has no *external fragmentation*, but *internal fragmentation*
  - 那为什么我们要从 variable partition 又回到 fixed partition 呢？因为此时内部碎片问题不严重（一个进程被拆成多个 page，只有最后的页才会有碎片），比之前的 partition 要小很多
    - worst case: 1 frame - 1 byte; average internal fragmentation: 1 / 2 frame size
  - page(frame) size
    - 页如果小，碎片少，但是映射更多，页表需要更大的空间
    - 反之页如果大，碎片多但映射更少，页表较小
    - 现在页逐渐变大，因为内存变得 cheap，一点碎片不影响

=== Page Table
- Page table: Stores the logical page to physical frame mapping
- Frame table: 一个 Bitmap，标记哪些 frame 是空闲的
- 页表不存页号（页号用作索引），只存物理帧号
#fig("/public/assets/Courses/OS/2024-11-05-15-41-57.png", width: 60%)
- Logical Address v3 #h(1fr)
  #fig("/public/assets/Courses/OS/2024-11-05-15-44-39.png", width: 40%)
  - 和之前 Segmentation 机制的 Logical Address 很像，区别在于 fixed partition 和 variable partition
  - *page number (p)*
    - used as an index into a page table
    - page table entry contains the corresponding physical frame number
  - *page offset (d)*
    - offset within the page/frame
    - combined with frame number to get the physical address
- MMU 的变化
  - 首先把 p 拿出来，到页表里读出读出物理帧号，随后和 d 拼接起来就得到了物理地址
  #fig("/public/assets/Courses/OS/2024-11-05-15-48-45.png", width: 60%)

=== Paging Hardware
- 现在我们思考怎么实现页表
- Simple Idea
  - 早期想法：a set of dedicated registers
  - 优势是非常快，但是缺点是寄存器数量有限，无法存储多的页表（如 $32$ bit 地址，$20$ 位作为物理页号，需要 $2^20$ 个页）
- Alternative Way
  - 存储在 main memory 里
  - *page-table base register (PTBR)* 指向页表的起始地址
    - RISC-V 上叫 SATP
    - ARM 上叫 TTBR
    - x86 上叫 CR3
  - *page-table length register (PTLR)* indicates the size of the page table
- 这样每次数据/指令访问需要两次内存访问，第一次把页表读出来，第二次再根据页表去读数据，显然变慢了，如何解决？遇事不决加 cache！如果 hit 了就只用一次内存访问
- TLB (translation look-aside buffer) caches the address translation
  - TLB hit: if page number is in the TLB, no need to access the page table.
  - TLB miss: if page number is not in the TLB, need to replace one TLB entry
    - 在 MIPS 上 TLB miss 是由 OS 处理的，但是在 RISC-V 上是由硬件处理的
  - TLB usually use a fast-lookup hardware cache called associative memory
    - Associative memory: memory that supports parallel search
    - Associative memory is not addressed by “addresses”, but contents
      - If `page#` is in associative memory’s key, return `frame#` (value) directly
  - 与页表不同的是，TLB 里存储的既有 page number 又有 frame number，通过比较 page number 来找到对应的 frame number（相当于全相联的 cache）
  - TLB is usually small, 64 to 1024 entries. TLB 数量有限，为了覆盖更大的区域，我们也想要把页变得更大。
- 每个进程有自己的页表，所以我们 context switch 时也要切换页表，要把 TLB 清空(TLB must be consistent with page table)
  - Option I: Flush TLB at every context switch, or,
  - Option II: Tag TLB entries with address-space identifier (ASID) that uniquely identifies a process. 通用的全局 entries 不刷掉，把进程独有的 entries 刷掉
- More on TLB Entries
  - Instruction micro TLB
  - Data micro TLB
  - Main TLB
    - A 4-way, set-associative, 1024 entry cache which stores VA to PA mappings for 4KB, 16KB, and 64KB page sizes.
    - A 2-way, set-associative, 128 entry cache which stores VA to PA mappings for 1MB, 2MB, 16MB, 32MB, 512MB, and 1GB block sizes.
- More on TLB Match Process
  - 不要求掌握
- 现在 MMU 的变化
  #fig("/public/assets/Courses/OS/2024-11-06-16-36-25.png",width: 60%)
- Effective Access Time（要会算）
  #fig("/public/assets/Courses/OS/2024-11-06-16-39-17.png",width: 70%)
- 题外话：Segmatation 和 Paging 两个机制其实是差不多时间(1961 and 1962)发明的，后者更优越但硬件上实现更难，所以更晚被广泛使用

=== Page with Memory Protection and Sharing
- Memory Protection
  - 到目前为止，页表里放了物理帧号。我们可以以页为粒度放上保护的一些权限（如可读、写、执行），这样就可以实现内存保护
    - Each page table entry has a present (aka. valid) bit
      - present: the page has a valid physical frame, thus can be accessed
    - Each page table entry contains some protection bits.
      - 任何违反内存保护的行为导致 kernel 陷入 trap
  - XN: protecting code
    - 把内存分为 code 和 data 区，只有 code 区可以执行。e.g. Intel: XD(execute disable), AMD: EVP (enhanced virus protection), ARM: XN (execute never)
  - PXN: Privileged Execute Never
    - A Permission fault is generated if the processor is executing at EL1(kernel) and attempts to execute an instruction fetched from the corresponding memory region when this PXN bit is 1 (usually user space memory). e.g. Intel: SMEP
  #fig("/public/assets/Courses/OS/2024-11-06-16-45-02.png", width: 60%)
- Page Sharing
  - Paging allows to share memory between processes
    - shared memory can be used for inter-process communication
    - shared libraries
  - 同一程序的多个进程可以使用同一份代码，只要这份代码是 reentrant code（or non-self-modifying code:never changes between execution）
  #fig("/public/assets/Courses/OS/2024-11-06-16-56-43.png",width: 50%)

=== Structure of Page Table
- *重要*！！！Page Table 需要物理地址连续(*physically contiguous*)，因为它是由 MMU 去管的，MMU 不知道 logical address 这件事
- 如果只有一级的页表，那么页表所占用的内存将大到不可接受
  - e.g. 32-bit logical address space and 4KB page size. page table would have 1 million entries $(2^32/2^12)$. If each entry is 4 bytes -> 4 MB of memory for page table alone
  - 我们需要有方法压缩页表
    - 考虑到 Logical addresses have holes
    - Break up the logical address space into multiple-level(Hierarchical) of page tables. e.g. two-level page table
    - First-level page table contains the `frame#` for second-level page tables.
  #fig("/public/assets/Courses/OS/2024-11-06-17-12-01.png", width: 60%)
- 最极端的例子($32$ bit, $4$ bytes for each entry)
  #fig("/public/assets/Courses/OS/2024-11-06-17-19-59.png", width: 60%)
  - 页表为什么可以省内存？如果次级页表对应的页都没有被使用，就不需要分配这个页表
    - 关于页表的空间节省计算，可以参考 #link("https://rcore-os.cn/rCore-Tutorial-Book-v3/chapter4/3sv39-implementation-1.html#id6")[rCore-Tutorial-Book]
  - 最坏情况下，如果只访问第一个页和最后一页，那么只用一级页表需要 $1K$ 个页用来放页表（这个页表有 $2^20$ 个条目），但是对于二级页表就只需要 $3$ 个页表（$1$ 个一级和 $2$ 个二级页表），即 $3$ 个页来放页表。内存占用 $4M -> 12K$
- Logical Address v4
  - `<PGD, PTE, offset>`
    - 多级页表每一级的命名规则是，固定最小的是 PTE，最大的是 PGD；如果是更多级页表，PTE 之上是 PMD，再之上是 PUD，再上已经没有名字了所以取了个 P4D
  - a page directory number (1st level page table), a page table number (2nd level page table), and a page offset
  #fig("/public/assets/Courses/OS/2024-11-06-17-22-03.png", width: 60%)
  - 一个比较生草的问题是页表里以及 PTBR 存的是 logical address 还是 physical address，答案肯定是后者，因为我们本来就是在做 LA $->$ PA 的转译，要还是 LA 就“鸡生蛋蛋生鸡”了
  - 另外这里经常出 *page size* 和 *entry size* 变化后的分区大小问题
    - 如果 page size 变大，offset 需要变大，Page Table 能容纳的 entries 也变多；如果 entry size 变大……
- 例如，$64$ bit 下，每个页表 entry size 变为 $8B$，一个页可以放 $2^12\/2^3=512$ entries
  - $64$ bit 能索引的地址太大了，一般都用不完
    - AMD-64 supports $48$ bits; ARM64 supports $39$ bits, $48$ bits
    - 对 $39=9+9+9+12$ bits，有 $3$ 级页表，能索引$1$ GB
    - 对 $48=9+9+9+9+12$ bits，有 $4$ 级页表，能索引$512$ GB
    - 对 $57=9+9+9+9+9+12$ bits，有 $5$ 级页表，已经能索引$128$ PB 了
  #tbl(
    columns: 7,
    [#h(8pt)],[9],[9],[9],[9],[9],[12],
  )

=== Other Page Tables
- 下面我们介绍其它 Page Table
- Hashed Page Tables
  - 在地址空间足够大且分布足够稀疏的时候有奇效（因为如果地址空间太大，用 $5$ 级页表最坏情况下要做足足 $5$ 次访存）
  - In hashed page table, virtual `page#` is hashed into a `frame#`
  - 哈希页表的每一个条目除了 page number 和 frame number 以外，还有一个指向有同一哈希值的下一个页表项的指针。这个结构与一般的哈希表是一致的
  #fig("/public/assets/Courses/OS/2024-11-12-14-40-23.png", width: 60%)
- Inverted Page Tables
  - 动机：LA 一般远大于 PA，造成需要 index 的项很多，inverted page table 的想法是去索引 physical frame 而不是 logical pages；另外一个不太重要的原因是，历史上由于 linux 发展较慢，$32 bits$ 只能支持 $4GB$，比 $8GB$ 内存要小
  - 每个 physical frame 对应一个 entry $-->$ 整个 Page Table 占用的内存是固定的！每个 entry 储存 pid 和 page number（对比之前 hierarchical page table 存 frame number，而且它不存 pid 因为每个进程独享自己的 page table），也就是说，Inverted page tables 索引 PA 而不是 LA
  - 现在寻址时，为了 translate LA 到 PA，找到对应有这个 page number 的 entry，不能像原版 page table 那样把 frame number 当做 index 直接找了，必须遍历整个页表找到对应的 pid 和 page number，其在页表中所处的位置即为 frame number
    - 这可以用 TLB 来加速，但是 TLB miss 时代价是很大的
  - 而且这样不能共享内存，因为一个物理帧只能映射到一个页（除非你把每个 entry 做成一个链表进去，也是一种实现）；对比原版 page table，shared memory 只需要两个进程的 page table 指向同一个物理帧号即可
  #fig("/public/assets/Courses/OS/2024-11-12-14-35-28.png", width: 60%)

== Swapping
- 我们前面说 Paging 机制对内存消耗还是比较大的，假如物理内存用完了，能不能把一部分进程放到磁盘上呢？
  - swap out: 用 disk 备份内存，就把 frame 的值交换到 disk 上，然后把 frame 释放出来
  - swap in: 当进程要执行的时候，再把 frame 从 disk 读回来。换回来时不需要相同的物理地址，但是逻辑地址要是一样的
  - 显然这个过程是很慢的，因此当进程在 swap 的时候，会被丢到硬盘的 waiting queue 里
  #fig("/public/assets/Courses/OS/2024-11-12-14-42-26.png", width: 60%)
- Swapping with Paging
  - 为了减轻负担，我们并不是把整个进程塞到 disk，而是部分 page
  - 这样，我们在 load 进程的 disk 部分的同时，进程还在 main memory 的部分可以先执行
    - 换句话说，paging 机制让我们拥有了 partially excuting 一个进程的能力
  #fig("/public/assets/Courses/OS/2024-11-12-14-42-38.png", width: 60%)

== Example: Intel 32- and 64-bit Architectures
- Intel IA-32 支持 Segmentation 和 Paging
- Intel 32 bit 提出 Physical Address Extension(PAE) 来支持 $4GB$ 以上寻址
- 这部分感觉应该不用太详细了解

#note(caption: "Takeaway")[
  - Partition evolution
  - Contiguous allocation
    - Fixed, variable
      - first, best, worst fit
      - fragmentation: internal/ external
    - Segmentation
      - Logical address v.s. physical address
  - Fragmentation
    - Internal， external
  - MMU: address translation + protection
  - Paging
    - Page table
      - Hierarchical, hashed page table, inverted
      - Two-level, three-level, four-level
      - For 32 bits and 64 bits architectures
]
#note(caption: "Page table quiz（看看考试是怎么考的）")[
  - In $32 bit$ architecture, $4KB$ page
  + for 1-level page table, how large is the whole page table?
    - $4KB$
  + for 2-level page table, how large is the whole page table?
    + How large for the 1st level PGT?
      - $4KB$
    + How large for the 2nd level PGT?
      - $1K times 4KB = 4MB$
  + Why can 2-level PGT save memory?
    - 允许内存不连续 + 可以按需取用（如果次级页表对应的页没有被使用就不需要分配）
  + 2-level page table walk example
    + Page table base register holds `0x0061,9000`
    + Virtual address is `0xf201,5202` #h(1fr)
      #tbl(columns:3,[PGD$(10)$],[PTE$(10)$],[offset$(12)$],[968],[21],[514])
      - 在 PTBR 中提取 PGD 的地址，然后加上 index 取 PTE 地址……
    + Page table base register holds `0x1051,4000`
    + Virtual address is `0x2190,7010` #h(1fr)
      #tbl(columns:3,[PGD$(10)$],[PTE$(10)$],[offset$(12)$],[134],[263],[16])
      - 在 PTBR 中提取 PGD 的地址，然后加上 index 取 PTE 地址……
      - 题外话：$4KB + 32 bits$ 真的是绝配，对别的 page size、bits 架构就不是这样，如下
  - How about page size is $64KB$
    + What is the virtual address format for 32-bit?  #h(1fr)
      #tbl(columns:3,[PGD],[PTE],[offset],[2],[14],[16])
    + What is the virtual address format for 64-bit?
      - for $39 bit$ VA —— 只能支持两级页表
      #tbl(columns:4,[PGD],[PMD],[PTE],[offset],[],[10],[13],[16])
      - for $48 bit$ VA —— 可以支持三级页表
      #tbl(columns:4,[PGD],[PMD],[PTE],[offset],[6],[13],[13],[16])
  - 以及要学会画 page table walk 的图和过程
]

= Virtual Memory
== Introduction
- Background: 代码需要在内存中执行，但很少需要或同时使用整个程序
  - unused code: error handling code, unusual routines
  - unused data: large data structures
- *partially-loaded*（在 Swapping 部分已经提到这种思想）
  - 我们可以把还没用到的 code 和 data 延迟加载到内存里，用到时再加载
  - 另一个好处是，program size 可以不受 physical memory size 的限制
- 为了实现部分加载，我们有一个虚拟内存（在这门课里和逻辑地址是等价的）的概念，主要靠 Paging 来实现
  - 需要注意的是虚拟地址只是范围，并不能真正的存储数据，数据只能存在物理空间里
#grid(
  columns: 2,
  [
    #fig("/public/assets/Courses/OS/2024-11-13-16-25-55.png")
    - 这样，右图的 stack 就处在连续的虚拟地址下，但它们经页表映射后的帧并不连续，而且不一定都在内存中
  ],
  fig("/public/assets/courses/os/2024-11-19-14-27-31.png", width:50%)
)

== Demand Paging
- *Demand paging*: 一般 OS 采用的方法是，当页被需要的时候(when it is demanded)才被移进来(page in)，demand 的意思是 access(read/write)
  - if page is invalid (error) $-->$ abort the operation
  - if page is valid but not in physical memory $-->$ bring it to physical memory
    - 这就叫 *page fault*
  - 优劣：no unnecessary I/O, less memory needed, slower response, more apps. 简而言之，用时间换取空间
- 三个核心问题
  - Demand paging 和 page fault 的关系？
    - 前者是利用后者实现的
  - What causes page fault？
    - User space program accesses an address
  - Which hardware issues page fault and Who handles page fault?
    - MMU & OS 后面详细展开
- Demand paging 需要硬件支持：
  + page table entries with valid / invalid bit
  + backing storage (usually disks)
  + instruction restart
- 另外这里我们可以思考 Segmentation 能不能实现 demand paging 机制？其实是不太行的，因为它的粒度太大了，就算实现了效果也不好

== Page Fault
- 比如，C 语言调用 `malloc` 的时候，采用的就是 lazy allocation 策略
  - VMA 是 Virtual Memory Area，malloc 调用 `brk()` 只是增大了 VMA 的大小（修改 vm_end），但是并没有真正的分配内存
    - VMA 这个数据结构类似于 OS 的“账本”
  - 只有当我们真正访问这个地址的时候，会触发 page fault，然后找一个空闲帧真正分配内存，并做了映射
  - 那有没有直接 allocate 的呢？`kmalloc` 会直接分配虚拟连续、物理连续的内存，`vmalloc` 会直接分配虚拟连续、物理不连续的内存
  #fig("/public/assets/Courses/OS/2024-11-13-16-35-45.png",width:70%)
- *MMU issues page fault*，走到页表最低层的时候发现对应的条目的 valid bit 不为 $1$，说明并没有映射，就触发了 page fault
  - $v$ (valid) $->$ frame mapped, $i$ (invalid) $->$ frame not mapped
- *OS handles page fault* (Linux implementation)
  - Page Fault 出现有两种情况（检测是真的 fault 还是只是空头支票没兑现）
    + 一种是地址本身超过了 VMA 的范围，或者落在 Heap 内但权限不对，这种情况操作系统会杀死进程；
      - 为了判断地址是否落在 VMA 里，Linux 使用了红黑树来加速查找
    + 否则，这个时候 OS 就会分配一个 free frame，然后把这个页映射到这个帧上。但这个时候也分两种情况：
      + *Major*: 这个 page 属于 file-backed(e.g. Data, Text)，它不在内存里面，这时需要先从磁盘读取这个 page，然后映射
      + *Minor*: 这个 page 属于 anonymous(e.g. BSS, Heap, Stack)，它本身就在内存里，这时只需要直接映射即可
  #fig("/public/assets/Courses/OS/2024-11-13-16-44-38.png",width:80%)
  - 具体来说就是
    + MMU 先去 access 这个地址，发现 valid bit 是 $i$，issue page fault
    + OS handle page fault，检查之后发现是合法的，分两种情况
      + Major page fault: 把这个页从磁盘读到内存，然后 reset 页表对应的 valid bit $i --> v$
      + Minor page fault: 找一个 free frame 映射到它，省了 $3,4$ 两步，然后 reset 页表对应的 valid bit $i --> v$
    + 这样之后，重新执行一遍指令，MMU 再重新走一遍这个过程，去 access 这个地址，去 TLB 里找就 miss 了（又一个 fault），这时候把它从页表搬到 TLB 里
    #fig("/public/assets/Courses/OS/2024-11-13-16-54-40.png",width:60%)
    - 这个过程里图中 $4$ 最耗时间，因为要读磁盘。如果跟 schedling 结合，此时会把该进程 sleep，丢到 disk 的 waiting queue 里。等 disk 做完了，触发一个 interrupt，然后 OS 会把这个进程移到 ready queue 里
- How to Get Free Frame
  - OS 为内存维护一个 free-frame list
  - Page fault 发生时，OS 从 free list 里拿一个空闲帧进行分配
  - 为了防止信息泄露，在分配时把帧的所有位都置 $0$ (zero-fill-on-demand)
  - 没有空闲的帧怎么办？之后讲 (page replacement)
- Page Fault with swapper
  - 还是说 page replacement 的 case，要把页换进来(swap in)和换出去(swap out)
  - Lazy swapper: 懒惰执行 swap in，只有需要的时候才真正 swap in
    - the swapper that deals with pages is also called a pager.
  - Pre-Paging: pre-page all or some of pages a process will need, before they are referenced.
    - 空间换时间，减少 page fault 的次数（主要是想少掉 major 的），但是如果 pre page 来的没被用就浪费了

#note(caption: [Stages in Demand Paging – Worse Case])[
  + Trap to the operating system.
  + Save the user registers and process state. (pt_regs)
  + Determine that the interrupt was a page fault.
    - Check that the page reference was legal and determine the location of the page on the disk.
  + Find a free frame
  + Determine the location of the page on the disk, issue a read from the disk to the free frame
    + Wait in a queue for this device until the read request is serviced.
    + Wait for the device seek and/or latency time.
    + Begin the transfer of the page to a free frame.
  + While waiting, allocate the CPU to other process.
  + Receive an interrupt from the disk I/O subsystem. (I/O completed)
    + Determine that the interrupt was from the disk.
    + Mark page fault process ready.
  + Handle page fault: wait for the CPU to be allocated to this process again.
    + Save registers and process state for other process.
    + Context switch to page fault process.
  + Correct the page table and other tables to show page is now in memory.
  + Return to user: restore the user registers, process state, and new page table, and then resume the interrupted instruction.
  - 其实跟之前总结得差不太多，只是再结合 context switch
  #fig("/public/assets/Courses/OS/2024-11-13-17-25-11.png",width:70%)
]

== Demand Paging Optimizations
- 先来分析一下 demand paging 的 overhead
  - page fault rate: $0 =< p =< 1$
  - Effective Access Time(EAT):
    $ (1-p) times "memory access" + p times ("page fault overhead" + "swap page out" + "swap page in" + "instruction restart overhead") $
  #fig("/public/assets/Courses/OS/2024-11-13-17-36-32.png",width:60%)
  - 真实场景下，确实可以让减速比 $=< 10%$，因为有 program locality，而且也不是每个 page fault 都是 major
- Discard
  - 仍旧从 disk 读取(page in)，但是对于部分只是拿来读的数据（比如 Code），我们不需要把它写回 disk（写了也是白写），而是直接丢弃，下次直接从 disk 读取（少一次 I/O）
  - 但下列情况还是需要写回
    - Pages not associated with a file (like stack and heap) – anonymous memory
    - Pages modified in memory but not yet written back to the file system
- Copy-on-Write (COW)
  - 我们之前讲 `fork()` 的时候说过，child 从 parent 完全复制，这是很耗时的
  - 我们可以让 child 跟 parent 使用 shared pages，只有当父进程或子进程修改了页的内容时，才会真正为修改的页分配内存（copy 并修改）
  - `vfork` syscall optimizes the case that child calls `exec` immediately after `fork`
  #fig("/public/assets/Courses/OS/2024-11-13-17-45-30.png", width: 60%)

== Page Replacement
- 没有空闲的物理帧时应该怎么办呢？
  - 我们可以交换出去一整个进程从而释放它的所有帧；
  - 更常见地，我们找到一个当前不在使用的帧，并释放它
  - （听起来像是 frame replacement？但其实 frame 一直在那里，只是 page 变了
- Page replacement: find some page in memory but not really in use, and page it out
  - 与物理地址无关 #h(1fr)
  #fig("/public/assets/Courses/OS/2024-11-13-17-48-23.png", width: 60%)

=== Page Replacement Mechanism
- Page Fault Handler (with Page Replacement) 为了 page in 一个 page，需要
  + find the location of the desired page on disk
  + find a free frame:
    + if there is a free frame, use it
    + if there is none, use a page replacement policy to pick a victim frame, write victim frame to disk if dirty
  + bring the desired page into the free frame; update the page tables
  + restart the instruction that caused the trap.
  - 一次 page fault 可能发生 2 次 page I/O，一次 out（可能要把脏页写回）一次 in
  #fig("/public/assets/courses/os/2024-11-19-14-44-37.png",width:50%)

=== Page Replacement Algorithms
- 就像 Scheduling 一样，这里我们也需要对 page 研究算法好坏
  - 之后我们也可以思考一下这跟 scheduling 有什么异同
  - 如何评价？用一串 memory reference string，每个数字都是一个页号，给出物理页的数量，看有多少个 page faults（考试必考）
- 比如
  - FIFO, optimal, LRU, LFU, MFU
  - 下面我们考虑 $7,0,1,2,0,3,0,4,2,3,0,3,0,3,2,1,2,0,1,7,0,1$ 这一串数字
- *First-In-First-Out Algorithm (FIFO)*
  - 替换第一个加载进来的 page
  - $15$ page faults with $3$ frames
  - Belady's Anomaly: For FIFO, 增多 frames 不一定减少 page faults
- *Optimal Algorithm*
  - 如果知道后续页号，替换未来最长时间里不会被用的 Page
  - $9$ page faults with $3$ frames
  - 最优算法，但无法预测未来什么时候会访问这些页，用来评价其它算法的好坏
- *Least Recently Used Algorithm (LRU)*
  - 属于 Time-based 方法，替换最近最少被用的
  - $12$ page faults with $3$ frames
  - 如何实现？基本上有两种方法
    - counter-based，存时间戳，在每次访问时查找最小的页并更新时间戳
    - stack-based，每次访问一个页的时候把它移到栈顶
    - 但这两种方法其实开销都很大，我们有近似的办法，在 PTE 中加了一个 *reference bit*
      - 一开始都设置成 $0$
      - 硬件实现：如果一个 page 被访问，就设置成 $1$
      - 替换时选择 reference bit = 0 (if one exists)
      - 当所有位都设为 $1$ 的时候就只能随机选一个，而且我们无法知道他们的访问顺序
  - LRU 的改进
    - *Additional-Reference-Bits Algorithm*
      - 直觉上，只要我们多设几个 bits，就可以追踪它们的访问顺序。设置 $8$ 个 Bits
      -在一个 time interval (100ms) 之内，对每个 page，refernce bits 每个时刻都右移一位，低位抛弃，高位如果被使用就设成 $1$，否则为 $0$
      - 所以只要比较大小就可以确定该替换哪个
    - *Second-chance algorithm*
      - 给第二次机会，对一个将要被 replaced page，如果它的
        - Reference bit = $0$，那么替换它
        - Reference bit = $1$，把它设置成 $0$，但留在 memory 内，下一次又选到它了才真正换掉它
    - *Enhanced Second-Chance Algorithm*
      - 用 *reference bit* and *modify bit* (if available) 更进一步表征 page 的状态
      - Take ordered pair (reference, modify):
        - $(0, 0)$ neither recently used not modified – best page to replace.
        - $(0, 1)$ not recently used but modified – not quite as good, must write out before replacement
        - $(1, 0)$ recently used but clean – probably will be used again soon
        - $(1, 1)$ recently used and modified – probably will be used again soon and need to write out before replacement
      - 一般是找 $(0,0)$ 的来替换
- *Counting-based Page Replacement*
  - *Least Frequently Used (LFU)* replaces page with the smallest counter
  - *Most Frequently Used (MFU)* replaces page with the largest counter
  - 一般是 LFU 好一些

== 琐碎概念
- Page-Buffering Algorithms
  - 但一般来说我们不会等到 frame 要去替换了才去行动，而是
  - 维持一个空闲帧的池子，当需要的时候直接从池子里取一个即可。系统不繁忙的时候，预先把一些 victime frame 释放掉（写回到磁盘，这样帧可以加到 free list 里）
  - Possibly
    - keep list of modified pages
    - keep free frame contents intact and note what is in them - a kind of cache
  - *double buffering*: 内存密集型任务可能会导致这个问题，User 和 OS 都缓存了同一份内容，导致一个文件占用了两个帧，浪费了 memory 的空间
- Allocation of Frames
  - 每个进程都至少需要一定数量的 frames，那么我们该如何分配？
    - Equal allocation
    - Proportional allocation - Allocate according to the size of process
    - Linux 其实两个都不是，它是 demand paging
  - 当帧不够用的时候，我们需要替换，分两种
    - Global replacement 可以抢其它线程的帧
      - 其中一种实现是 Reclaiming Pages：如果 free list 里的帧数低于阈值，就根据 OOM score aggressively Kill some processes。这个策略希望保证这里有充足的自由内存来满足新的需求
      #fig("/public/assets/courses/os/2024-11-19-15-34-24.png",width:50%)
    - Local replacement 只能从自己的帧里选择替换
- Non-Uniform Memory Access
  - 不同 CPU 距离不同的内存的距离不同，因此访问时间也不同
  #fig("/public/assets/courses/os/2024-11-19-15-37-44.png",width:40%)

== Thrashing
- 如果我们的进程一直在换进换出页，那么 CPU 使用率反而会降低。进程越多，可能发生一个进程的页刚加载进来又被另一个进程换出去，最后大部分进程都在 sleep
  #fig("/public/assets/courses/os/2024-11-19-15-40-04.png",width:40%)
- 为什么会这样呢？
  - demand paging 之所以起效就是因为 *locality*
  - 所以当进程过多，total size of locality > total memory size，自然就发生了 thrashing
- 如何解决 thrashing
  - Option I: 使用 local page replacement
  - Option II: 根据进程的需要分配 locality，使用*工作集模型 (working set model)*来描述
    #fig("/public/assets/courses/os/2024-11-20-16-27-26.png",width:50%)
    - 每当进程到了一个新的 locality，page fault rate 就会变高
    #fig("/public/assets/courses/os/2024-11-20-16-22-35.png",width:40%)
    - working set model 描述得很好但不好计算，很自然地我们会想，用 page fault rate 来间接反映 working set。如果太低，说明给资源太多；反之给的资源太少
    - 怎么实现？跟 LRU 很像

== Other Considerations
- Prepaging
  - page fault 时，除了被 fault 的 page，其他相邻的页也一起加载
- Page Size
  + Fragmentation $->$ small page size
  + Page table size $->$ large page size
  + Resolution $->$ small page size
  + I/O overhead $->$ large page size
  + Number of page faults $->$ large page size
  + Locality $->$ small page size
  + TLB size and effectiveness $->$ large page size
  + On average, growing over time
- TLB Reach
  - TLB 总共可以索引到的大小，不考虑 TLB 也分级，可以简单计算为
  - $ "TLB reach" = ("TLB size") $times$ ("page size") $
- Program Structure
  - 程序结构也会影响 page fault，最经典的就是二维数组行主序和列主序访问的例子
- I/O interlock: 把页面锁住，这样就不会被换出去。

== Memory management in Linux
- page fault 是针对 user space 的，kernel 分配的内存不会发生 page fault（否则会嵌套）
- 一个进程有自己的 `mm_struct`，所有线程共享同一个页表，内核空间有自己的页表 `swapper_pg_dir`。 这里的 `pgd` 存的是虚拟地址，但当加载到 `satp` 里时会转为物理地址
- Linux Buddy System
  - 从物理连续的段上分配内存；每次分配内存大小是 2 的幂次方，例如请求是 11KB，则分配 16KB
  - 当分配时，从物理段上切分出对应的大小（每次切分都是平分）；当释放时，会*合并(coalesce)*相邻的块形成更大的块供之后使用
  - 优劣
    - advantage: 可以迅速组装成大内存（释放后即可合并）
    - disadvantage: internal fragmentation 比如请求是 11KB 但分配 16KB
- Slab Allocation
  - Buddy System 管理整页的大内存，但我们需要更细粒度（小于一个 page）的分配。另一方面，随着进程越来越大，即使是 `task_struct` 也变得很大，我们需要有高效管理它们的办法
  - 当要分配很多 `task_struct`，如何迅速分配？
    - 我们把多个连续的页面放到一起，将 objects 统一分配到这些页面上
    - 比如 `task_struct` 有 $3KB$，但 page 是 $4KB$，最好的办法就是找最小公倍数，用 $3$ 个 page 放 $4$ 个 `task_struct`
  - 进一步，我们不想每次一个 field 一个 field 地 initial，而是一次加载好多个，把它作为一个 pool 来用，另外也能充当 cache 的作用
  - 优点：no fragmentation, fast memory allocation

#note(caption: "Takeaway")[
  - Page fault
    - Valid virtual address, invalid physical address
  - Page replacement
    - FIFO, Optimal, LRU, 2nd chance
  - Thrashing and working set
  - Buddy system and slab
]
