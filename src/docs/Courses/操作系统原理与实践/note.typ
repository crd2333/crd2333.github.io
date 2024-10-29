#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "操作系统原理与实践",
  lang: "zh",
)

#info()[
  - 感觉 #link("https://note.hobbitqia.cc/OS/")[hobbitqia 的笔记] 比较好，自己简单记记
  - 还有 #link("https://note.isshikih.top/cour_note/D3QD_OperatingSystem/")[修佬的笔记]，虽然老师不一样
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


= Inter-Process Communications(IPCs)
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

== Message Passing
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

== Signals
- 略

== Pipes
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

== Client-Server Communication
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

== User Threads vs. Kernel Threads
- User Space 支持 threads 设计，Kernel Space 不一定，但大多数现代 OS 都支持
- Many-to-One Mode
  - 好处是在于易于实现，kernel 不用管你上层怎么干的
  - 缺点：内核只有一个线程，无法发挥 multi-core 的优势；一旦一个线程被阻塞，其他线程也会被阻塞
  #fig("/public/assets/Courses/OS/2024-10-22-13-35-06.png", width: 50%)
- One-to-One Mode
  - 优点是消除了 Many-to-One 的两个毛病，但缺点是创建开销大（但现代硬件相对不那么值钱了）
  - 把线程的管理变得很简单，现在 Linux，Windows 都是这种模型
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-09.png", width: 50%)
- Many-to-Many Model
  - $m$ to $n$ 线程，折中上面两者的优缺点。但是实现复杂
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-25.png", width: 50%)
- Two-Level Model
  - 大多数时候 many to many，但对特别重要的那种用 one to one
  #fig("/public/assets/Courses/OS/2024-10-22-13-42-34.png", width: 50%)

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
- 线程的加入让进程的操作变得更复杂。
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
- 一般用 Waiting Time, Turnaround Time 来比较，要学会画 Gantt 图和计算（多个 examples）
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
  - 所有线程进行调度。
- 现在主流 CPU 都是以线程为粒度进行调度的

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

= Synchoronization
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

== Synchoronization Problems
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

== POSIX Synchoronization
- POSIX 是啥？Portable Operating System Interface，开放给 user space 的 synchronization
- POSIX API provides
  + mutex locks
  + Semaphores
  + condition variables
    - 跟 semaphore 的本质区别在于它支持 `broadcast`，或者说 wakeup all








