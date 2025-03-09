#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "操作系统原理与实践",
  lang: "zh",
)

#info()[
  - 感觉 #link("https://note.hobbitqia.cc/OS/")[hobbitqia 的笔记] 比较好
  - 还有 #link("https://note.isshikih.top/cour_note/D3QD_OperatingSystem/")[修佬的笔记]，虽然老师不一样，具体内容上也有一定差别
]

#note()[
  - 这一部分主要就是一些琐碎概念，稍微重要点的就是文件系统了
]

#counter(heading).update(9)

= Mass-Storage
- *Magnetic disks* 提供了计算机系统大量的存储空间(secondary storage)，一般来说 hard disk 最主要
- Disk Structure
  - 可见 #link("https://crd2333.github.io/note/Courses/%E6%95%B0%E6%8D%AE%E5%BA%93%E7%B3%BB%E7%BB%9F/%E6%95%B0%E6%8D%AE%E5%BA%93%E8%AE%BE%E8%AE%A1%E7%90%86%E8%AE%BA/")[DB 笔记]
  - Logical block 是传输的最小单位，它们被顺序映射到磁盘的扇区，$0$ 扇区是最外面的第一个磁道的第一个扇区，然后逐层往内
  #fig("/public/assets/Courses/OS/2025-01-05-20-53-40.png", width: 30%)
- Performance
  - *Positioning time(寻道时间)*：也叫 (random-)*access time*，把磁头移动到正确的 sector 上，包含 seek time 和 rotational latency
    - *Seek time*：磁头移动到目标 cylinder，一般在 $3ms wave 12ms$
    - *Rotational latency*：等待目标 sector 旋转到磁头下，基于 spindle speed：$1\/"rpm" * 60$，$"average latency"=1/2*"latency"$
  - *Transfer rate*：数据传输时间，理论上 $6gb\/sec$; 实际上大约 $1gb\/sec$
  - *Disk bandwidth*：数据带宽，传递的总字节数除以服务请求到传递结束的总时间
  - 总之就是很慢，但读数据本身不算太慢，慢的是 seek 和 rotation，我们要尽量减少

== Disk Scheduling
- 磁盘调度
  - 磁盘 I/O 处理请求来自 OS, system/user processes 等，提供 I/O mode, disk & memory addr, number of sectors
  - idle 的磁盘可以立即处理，否则需要在 OS 维护的 per disk or device queue 里等待
  - 优化磁盘调度算法来更好地选择接下来服务哪个待处理磁盘请求，以减少 access time
    - 主要是 seek time，Rotational latency 对 OS 而言太难计算
- 以前 OS 会负责队列的管理、磁头的调度
  - 现在由 firmware 负责 (controllers built into the storage devices)
  - 只需提供 lba(logical block address)

=== Scheduling Algorithms
- 同样的，我们来衡量几种 scheduling algorithms
  + FCFS
  + SSTF
  + SCAN, C-SCAN
  + LOOK, C-LOOK
  - 我们使用 $\"98, 183, 37, 122, 14, 124, 65, 67\" ([0, 199])$, and initial head position $53$ 作为例子
  - 注意这里说的是柱面（cyclinder，包含若干等距离的 track），只有不在同一柱面的才需要 seek，同一柱面不同 track 不需要动磁头，不同 sector 仅靠转动即可
- FCFS(First Come First Serve)
  - Total head movements of $640$ cylinders
  - Advantage: 每个请求都有公平机会，没有无限推迟
  - Disadvantages: 最简单的方法，根本没有进行优化
- SSTF(Shortest Seek Time First)
  - 类似 SJF，选择离现在 head position 最近的 request。但是 SSTF 不一定最好(optimal)。可能发生 starvation
  - Total head movements of $236$ cylinders
  - Advantages: 平均响应时间减少，吞吐量增加
  - Disadvantages: 需要预先计算 seek time 的开销，可能存在 starvation，且存在 high variance（偏爱某些请求）
- SCAN
  - 也叫 elevator 电梯算法（先到一楼把沿途的人都接上，再往高楼走），先扫到一头，再往另一头扫，如果遇到服务就处理
  - Advantages: 响应时间比较平均（低方差），高吞吐量
  - Disadvantages: 如果刚好错过电梯，就要等电梯触底再上来，等待时间很长（平均可能少，但最差可能很长）
  - 改进：C-SCAN(Circular-SCAN) 实现更均匀的等待时间，只做单向的扫，到达一端时立刻回到开头（返回时不服务），随后从底往上扫，这样最多只用等待一圈
  - 另外明显有一个优化点，即 LOOK
- LOOK / C-LOOK
  - 在 SCAN / C-SCAN 的基础上，只走到一端最后一个任务而不走到尽头
  - 实际上分别是 SCAN / C-SCAN 的一种版本
  - Advantage:
    - 防止不必要地遍历到磁盘末尾而产生的额外延迟

#note(caption: "Selecting Disk-Scheduling Algorithm")[
  - 依赖于请求的类型和数量，而请求本身又依赖于文件分配策略和元信息布局。文件系统如果注重空间局部性，能够提供更好性能提升
  - 磁盘调度算法应该模块化，可以随时更换自由选择
  - SSTF 一般来说比较好
  - 如果 I/O 比较少，FCFS 和 SSTF 即可。如果是大型服务器或数据库（高负荷 IO），一般使用 C-LOOK。如果是 SSD（不用 seek），一般使用 FCFS
]

== Other Storage Devices
- *Nonvolatile Memory Devices*
  - 但其实上面讲了这么多，都有点过时了，因为现在有了固态硬盘(solid-state disks, SSD)
  - 与磁盘相比，寿命短，容量小，速度快（Bus 慢，需要直接连到 PCIE 上）
  - 没有磁头不需要转，因此不存在 seek time 和 rotational latency，所以一般用 FCFS
- *Magnetic Tape 磁带*
  - 容量很大很便宜
  - 但是很慢。因为需要倒带，一般都做顺序访问而不是随机访问。现在主要用来做备份

== Disk Management & Attachment
- 使用这些介质（磁盘、固态硬盘、磁带）保存文件之前，需要先格式化
  - Physical formatting: 将磁盘划分为扇区才能进行读写
  - Logical formatting: 创建文件系统，存储元数据。然后为了提升效率将块集中到一起成为簇 cluster
- Boot block initializes system
  - 一般 bootstrap 存在 ROM 里
  - 系统启动顺序：
    + ROM 中的代码 (simple bootstrap)
    + boot block 里的代码 (full bootstrap) 也就是 boot loader 如 Grub LILO
    + 然后是整个 OS 内核
- swap space management
  - 用于 DRAM 不够存下所有进程时部分移到二级存储上
- 磁盘可以以这些方式附加到计算机上：
  - host-attached storage
    - hard disk, RAID arrays, CD, DVD, tape...
    - 通过 I/O bus 直接插到主机上
  - network-attached storage
    - 通过网络连接
  - storage area network
    - 做成一个阵列，通过局域网连接
- 都不是很重要

== RAID
- 动机
  - HDDs 越来越小和便宜，但还是很容易坏
  - 如果一个系统可以拥有大量磁盘，那么就能改善数据的读写速率（因为可以并行）和可靠性（使用冗余来降低出现错误的期望）
  - 这样的磁盘组织技术称为*磁盘冗余阵列(Redundant Arrays of Independent Disk, RAID)*技术
- 几个关键概念
  - Data Mirroring: 其实就是数据有多个备份
  - Data Striping: 把数据分成多个部分，分别存储在不同的磁盘上
  - Error-Code Correcting (ECC) - Parity Bits: 通过奇偶校验位来检测和纠正错误
- RAID 0
  - 根据固定的 striped size 把数据分散在不同的磁盘，没有做任何 redundancy
  - Improves performance, but not reliability
  - e.g. 5 files of various sizes, 4 disks
  #fig("/public/assets/Courses/OS/2024-12-03-14-34-00.png",width:30%)
- RAID 1
  - 也被称为 mirroring，存在一个主磁盘，一个备份磁盘。主磁盘写入数据后，备份磁盘进行完全拷贝
  - A little improves performance（可以从两个读）, but too expensive
  - e.g. 5 files of various sizes, 4 disks
  #fig("/public/assets/Courses/OS/2024-12-03-14-35-48.png",width:30%)
- RAID 2
  - stripes data at the bit-level; uses Hamming code(4bit data + 3bit parity) for error correction
  - 没有被实际应用，因为粒度太小，现在无法单独读出来一个比特，至少读出一个字节
  #fig("/public/assets/Courses/OS/2024-12-03-14-37-07.png",width:30%)
- RAID 3
  - Bit-interleaved parity: 纠错码单独存在一个盘里
- RAID 4, 5, 6
  - RAID 4: Basically like RAID 3, but interleaving it with strips (blocks)
    - Block-interleaved parity，纠错码单独存在一个盘里，且用块来做 strip
  - RAID 5: Like RAID 4, but parity is spread all over the disks as opposed to having just one parity disk
    - parity bit 被分散地存到了不同的磁盘里。相比于 RAID 4，每个盘的读写比较均衡
  - RAID 6: extends RAID 5 by adding an additional parity block
    - 又加了一个 parity bit，也是分散存储（P+Q 冗余，差错纠正码）
  #fig("/public/assets/Courses/OS/2024-12-03-14-42-45.png",width:40%)
- 注意：RAID 只能 detect/recover from disk failures，但无法 prevent/detect data corruption
  - 只能检测磁盘失效，并不知道哪个文件失效
- ZFS adds checksums to all FS data and metadata
  - 这样可以检验磁盘是否写错

#note(caption: "Takeaway")[
  - Disk structure
  - *Disk scheduling*
    - FCFS, SSTF, SCAN, C-SCAN, LOOK, C-LOOK
  - RAID 0-6
]

= I/O Systems
- I/O 设备是 OS 的一个 major 组成部分，比下面左图画的大得多
  #grid2(
    fig("/public/assets/Courses/OS/2024-12-03-14-48-07.png"),
    fig("/public/assets/Courses/OS/2024-12-03-14-48-12.png")
  )
- Common concepts: signals from I/O devices interface with computer
  - bus: 部件之间的互联（包括 CPU）
  - port: 设备的连接点
  - controller: 控制设备的部件
- direct I/O instructions & memory-mapped I/O
  - CISC 包含 dedicated I/O instructions，如 x86 的 `in` 和 `out`
  - 而 RISC 把 I/O instructions 存在 memory 里，即 memory-mapped I/O

== I/O access
- I/O access can use *polling or interrupts*
  - 本章最大的重点就在这
  - Polling 轮询: CPU 不断地主动询问 I/O 设备是否 ready
    - 需要 busy wait，如果 device 很快那么轮询是合理的，否则会很低效
  - Interrupts 中断: I/O 设备准备好后发出中断信号，CPU 响应
    - 当线/进程 $T_1$ 需要等待 device 时，被加入到 device 的 waiting queue 上，然后 scheduling 到别的线/进程 $T_2$ 继续工作（跟 polling 相比，这时它没在 sleep 而在做别的工作）
    - 收到 interrupt 后，$T_1$ 被加回到 ready queue 上
    - interrupt 这里也会有一个 interrupt table
    #fig("/public/assets/Courses/OS/2024-12-03-15-17-13.png",width:50%)
    - 所以如果中断发生的频率很高，那么上下文切换会浪费很多 CPU 时间
- DMA(Direct Memory Access)
  - 对于大量 I/O 的设备，为了减少 CPU 的负担，我们可以让 I/O 设备直接访问内存，而不需要 CPU 介入
  - 于是就把权限下放到 device driver, drive controller, DMA controller, memory controller, bus controller
    - 所有 driver 在 CPU 上跑，controller 在设备上跑
  #fig("/public/assets/Courses/OS/2024-12-03-15-29-14.png",width:70%)

== Application I/O Interface
- IO 系统调用把设备行为封装成通用类
  - Linux 中设备能以 *files* 的形式访问；最底层为 `ioctl`
- 设备驱动层对 kernel 隐藏了 I/O controllers 之间的差异，做了一层抽象（统一接口）
  #fig("/public/assets/Courses/OS/2024-12-03-15-40-43.png",width:60%)
- Devices vary in many dimensions
  #tbl(
    columns:3,
    [aspect],[variation],[example],
    [data-transfer mode],[block, character],[disk, terminal],
    [access method],[sequential, random],[modem, CD-ROM],
    [transfer schedule],[synchronous, asynchronous],[tape, keyboard],
    [sharing],[dedicated, shared],[tape, keyboard],
    [device speed],[latency, seek time, transfer rate, delay between operations],
    [I/O direction],[read-only, write-only, read-write],[CD-ROM, graphics controller, disk],
  )

== Kernel I/O Subsystem
- 相当于是在 I/O 侧又做了一遍 OS 那套东西
  - I/O scheduling
  - Buffering - store data in memory while transferring between devices.
  - Caching: hold a copy of data for fast access.
  - Spooling: A spool is a buffer that holds the output (device’s input) if device can serve only one request at a time.
  - Device reservation: provides exclusive access to a device.
  - Error handling

== Between Kernel and I/O
- I/O Protection
  - 需要 privilege，OS 去执行 I/O 操作(via syscalls)
  - Kernel Data Structures
    - Kernel keeps state info for I/O components
    - Some OS uses message passing to implement I/O (e.g. Windows)
    #fig("/public/assets/Courses/OS/2024-12-04-16-26-37.png",width:40%)
      - 所有东西都被抽象成 file，后面我们会讲
- I/O Requests to Hardware
  #fig("/public/assets/Courses/OS/2024-12-04-16-25-53.png",width:60%)
- 总之，这里如果细细展开的话也会很复杂（kernel 和 I/O 的数据结构与交互等），但不是重点

== Performance
- I/O 是计算机系统中的 major 部分，因此也极大影响了 performance
- Improve Performance
  - Reduce number of context switches
  - Reduce data copying
  - Use smarter hardware devices, such as reducing interrupts by using large transfers, smart controllers, polling
  - Use DMA
  - Balance CPU, memory, bus, and I/O performance for highest throughput
  - Move user-mode processes / daemons to kernel threads

#note(caption: "Takeaway")[
  - IO hardware
  - IO access
    - *polling, interrupt*
  - Device types
  - Application I/O Interface
  - Kernel IO subsystem
]
- 注：Mass Storage 和 I/O Systems 两节不算特别重要，把 Takeaway 里的内容看一看就差不多了

= File System Interface
== File concept
- 现在我们有了大规模存储介质和 I/O 的概念，但是如何使用？OS 将这一切*抽象*成*文件系统*
  - Abstraction
    - CPU is abstracted to #underline[Process]
    - Memory is abstracted to #underline[Address Space]
    - Storage is abstracted to #underline[File System]
      - file $->$ track / sector
  - 核心问题
    - How to use file system?
      - How to use file?
      - How to use directory?
    - How to implement file system?
      - How to implement file?
      - How to implement directory?
- File is *a contiguous logical space* for storing information
  - e.g. database, audio, video, web pages...
  - 有不同类型的 files
    - data: character, binary, and application-specific
    - program
    - special one: proc file system，也就是 linux `/proc` 目录下的那些数字文件夹，使用 file-system interface 来检索系统信息
- File Attributes
  - Name – only information kept in human-readable form
  - Identifier – unique tag (number) identifies file within file system
  - Type – needed for systems that support different types
  - Location – pointer to file location on device
  - Size – current file size
  - Protection – controls who can do reading, writing, executing
  - Time, date, and user identification – data for protection, security, and usage monitoring
  - ...
  - 这些信息是目录结构 (directory structure) 的一部分，保存在 `FCB` 数据结构里（联系 process 的元信息存在 `PCB` 里），也存在磁盘上。可能有其他属性，例如 checksum，这些会存到 extended file attributes 里
  - linux 上使用 `stat`(statistic) 系统调用可以获取这些信息
- File Operations
  - *create*: 需在文件系统中找到空间，并分配一个目录条目
  - *open*: 大多数操作首先需要打开文件，open 返回用于其它操作的 handler
    - 一些管理打开文件所需要的信息：
      + open-file table: tracks open files
      + file pointer：每个进程跟踪该文件上次读写位置
      + file-open count：跟踪文件打开和关闭，计数为 $0$ 时从 table 中删去
      + disk location of file：用于定位磁盘上文件位置
      + 访问权限：访问模式信息
    - 一些文件系统提供 lock 机制
      - 两种锁: shared and exclusive lock
      - 两种锁机制:
        + mandatory lock: 一旦进程获取了独占锁，操作系统就阻止任何其他进程访问对应文件
        + advisory lock: 进程可以自己得知锁的状态然后决定要不要坚持访问
  - *read/write*: 需要维护一个指针
  - *seek*: 重定位当前文件指针
  - *close*
  - *delete*
  - *truncate*: 把文件的所有 content 清空，但保留 metadata
- File Types
  - 识别不同的文件类型一般通过：
    - as part of the file names(file extension): 例如规定只有扩展名是 `.com`, `.exe`, `.sh` 的文件才能执行
    - magic number of the file
      - 在文件开始部分放一些 magic number 来表明文件类型
      - 例如 `7f454c46` 是 ASCII 字符，表示 ELF 文件格式
- File Structure
  - 一个文件可以有不同的结构，由 OS 或 program 指定
    - No structure: a stream of bytes or words (e.g. linux dumps)
    - Simple record structure: Lines of records, fixed length, variable length (e.g. database)
    - Complex structures: formatted document, relocatable load file
- Access Methods
  - Sequential access
    - 一组元素按 predetermined 顺序进行访问访问，比如用 tape 实现的文件系统
  - Direct access
    - 能以（大概）均等的时间跳到任意的位置访问，也称为随机访问
    - 在直接访问的方法之上，还有可能提供索引，即先在索引中得知所需访问的内容在哪里，然后去访问。也有可能使用多层索引表

== Directory structure
*Partitions*
  - 一开始只有文件，但文件想重名怎么办？把它们 subdivided into *partitions*
    - partitions also known as *minidisks, slices*
  - 一个文件系统可以有多个 disk，一个 disk 可以有多个 partition，一个 partition 又可以有自己的文件系统（称为 volume）
  - disk or partition can be used raw(without a file system)，即 partition 也可以不对应一个文件系统，数据库这种应用更偏好这一形式
- *Directory*
  - 是一组节点，包含所有文件的信息
  - 可以把 directory 当成特殊的 file，其内容是 file 的集合
  #fig("/public/assets/Courses/OS/2024-12-04-17-09-17.png",width:50%)
  - Operations Performed on Directory: Create / delete a file, list a directory, search for a file, traverse the file system
  - target: 要能快速定位文件 (efficient)；要便于用户使用、便于按一些属性聚合 (Naming)
- Directories implementation
  #grid(
    columns: 2,
    fig("/public/assets/Courses/OS/2024-12-04-17-15-36.png",width:80%),
    fig("/public/assets/Courses/OS/2024-12-04-17-15-43.png",width:80%),
    fig("/public/assets/Courses/OS/2024-12-04-17-16-05.png",width:80%),
    fig("/public/assets/Courses/OS/2024-12-04-17-16-12.png",width:80%),
    fig("/public/assets/Courses/OS/2024-12-04-17-26-41.png",width:80%)
  )
  + *Single-Level Directory*
    - 所有文件包含在同一目录中，存在重名和分组问题
  + *Two-Level Directory*
    - master 文件目录 (MFD) 下为每个用户分出单独的 directory (UFD)，不同用户可以有同名文件
    - 搜索效率高，但是没有分组能力
  + *Tree-Structured Directories*
    - 将目录二级目录拓展即可
    - 文件使用路径名访问 (path name, absolute or relative)
    - efficient in searching, can group files, convenient naming；但不能 share 一个文件（多个指针指向同一个文件），因为这样就会形成一个图而不是树
  + *Acyclic-Graph Directories*
    - 允许使用 *aliasing* 链接到 directory entry / files (no longer a tree)
    - Dangling pointer problem
      - 删除一个文件后指向该文件的其他链接成为悬垂指针 (dangling pointers)
      - solution: 保存引用（指针）数，文件被删除时引用数减一，减到 $0$ 时才真正删除
    - 但不允许向目录链接，否则会形成环
  + *General Graph Directory*
    - 更进一步，允许目录中有环
    - garbage collection: 如果没有外界目录指向一个环，那么就把这个环都回收了
    - 每次设置一个新链接时都使用执行环检测算法

== Others
- File System Mounting
  - 文件系统在访问前必须挂载
  - 将文件系统安装到系统中，通常形成一个 single name space。挂载的位置称为 mount point，挂载后该点上的旧目录不可见
- File Sharing
  - shared 文件需要有一定的保护，规定 User IDs, Group IDs 允许某些用户、某些组的用户访问
  - remote file sharing: 在分布式系统里，文件可以通过网络共享
    - NFS for UNIX, CIFS for windows
- Protection
  - 文件的所有者/创建者应该能控制文件可以被谁访问，能被做什么
    - 访问类型：read/write/append, execute, delete, list
  - Access Control List (ACL)
    - 给每个文件和目录维护一个 ACL，定义三种 users(owner,group,other) 和三种 access(R,W,X)
    - linux 上使用 `getfacl`, `setfacl`, `chmod`, `chgrp` 命令查看
    - 优点是可以提供细粒度的控制
    - 缺点是如何构建这个列表，以及如何将这个列表存在目录里

#note(caption: "Takeaway")[
  - File system
  - File operations
    -  Create, open, read/write, close
  - File type
  - File structure
  - File access
  - Directory structure
    - Single level, two-level, tree, acyclic-graph, general graph
  - Protection
    - ACL
]

= File System Implementation
- 存在多种文件系统且可以同时共存
  - Linux: ext2/3/4, reiser FS/4, btrfs
  - Windows: FAT, FAT32, NTFS
- 文件系统储存在二级存储（磁盘）上
  - 文件系统通常是*分层实现*

== Layered File System
#wrap-content(
  align: right,
  column-gutter: 2em,
  fig("/public/assets/Courses/OS/2024-12-04-17-45-28.png",height:25em)
)[
  - OS 对文件系统做这样的层次化封装，主要是为了通过接口来隔离不同层，降低每一层的复杂度和冗余性，但是增加开销、降低性能
    - Logical file system
      - 管理必要的元数据而不包括实际内容，存储目录结构和 FCB
      - 从上方输入操作文件路径，输出给下方操作的逻辑块
    - File-organization module
      - 把输入逻辑块号映射到输出物理块号，同时也管理空闲空间
    - Basic file system
      - 分配维护各种 buffer，用于缓存文件系统、目录和数据块，提高性能
      - 输入输出不变，均为物理块号
      - "block I/O subsystem" in Linux
    - I/O Control
      - 由 device drivers 和 interrupt handlers 组成
      - 将上层读写物理块号的指令转换为 low-level, hardware-specific 的指令，向设备控制器的内存写入以执行磁盘读和写操作
      - 同时也可以响应相关中断
  ]

== File System Data Structures
- On-disk structures
  - 可持久化的 (persisitant)
  - An optional *boot control block*
    - 每个卷的引导控制块，包括从该卷引导操作系统所需的信息
  - A *volume control block*
    - 每个卷的卷控制块，包括卷的详细信息如总块数、空闲块数目和位置、空闲 FCB 数目和位置
  - A *directory*
    - 包含文件名与对应的 FCB 指针
  - A *per-file File Control Block (FCB)*
- In-memory structures
  - 易失的 (volatile)
  - A *mount table* with one entry per mounted volume
  - A *directory cache* 用于快速路径翻译 (performance)
  - A *global(system-wide) open-file table*
    - 记录所有被加载到内存中的 FCB
  - A *per-process open-file table*
    - 指向 system-wide open-file table 中的项
  - 各种 *buffers* 持有传输中的磁盘块 (performance)
- File Control Block
  - FCB 之于文件系统就像 PCB 之于进程，是非常重要的
  - 在 UNIX 中，FCB 被称为 inode；在 NTFS 中，每个 FCB 是一个叫 master file table 的结构的一行
  - 左图为典型的 FCB 结构所包含的信息
  - 右图为 `ext2_inode` 的结构，前面的是 metadata，后面存有数据块的指针
  #grid2(
    fig("/public/assets/Courses/OS/2024-12-10-14-22-22.png",width:60%),
    fig("/public/assets/Courses/OS/2024-12-10-14-22-30.png")
  )

== File Creation & Open & Close
- *File Creation*
  - 逻辑文件系统为这个新的文件分配一个新的 FCB（与文件一对一映射），随后把它放到一个目录里，将对应的 directory 读到内存，并用 filename 和 FCB 更新 directory
- *File Open*
  - 系统调用 `open()` 将文件名传给 logical file system，后者搜索 *system-wide(global) open-file table* 以确定该文件是否正在被其他进程使用
    - 如果有，则直接在当前进程的 per-process open-file table 中新建一个 entry，指向 system-wide open-file table 中的对应项即可，并且 increment the *open count*
    - 否则，需要在 directory 中找到这个 file name，将其 FCB 从磁盘加载到内存中，并将其放在 system-wide open-file table 中。然后，在当前进程的 per-process open-file table 中新建一个 entry，指向 system-wide open-file table 中的对应项
    - 这里的 index 就是 file descriptor
  #fig("/public/assets/Courses/OS/2024-12-10-14-28-23.png",width:50%)
- *File Close*
  - 至于关闭，就是 Open 的逆过程
  - per-process open-file table 中对应 entry 将被删除，system-wide open-file table 中的 counter 将被 $-1$
  - 如果该 counter 清零，则更新的 metadata 将被写回磁盘上的 directory structure 中，system-wide open-file table 的对应 entry 将被删除
- 在 Unix(UFS) 里面 System-Wide Open-File Table 会放设备、网络，所以我们的设备也是用文件来表示的，读写文件相当于读写设备

#note(caption: "我们现在学过几种 Table？")[
  + Segment Table
  + Page Table
    + Hierarchical Page Table
    + Hashed Page Table
    + Inverted Page Table
  + Syscall Table
  + File Table
  - 思考：每个 table 长什么样（包含什么）？它们的 number 代表什么含义？
]

== Virtual File Systems
- 操作系统可以同时支持多种类型的文件系统
  - e.g. FAT32, NTFS, Ext2/3/4
  - but how？
    - 一个叫 David Wheeler 说过: All problems in computer science can be solved by another level of indirection#strike[, except for the problem of too many layers of indirection]
    - 也就是分层抽象，我们加一层 virtual file system (VFS)
  #fig("/public/assets/Courses/OS/2024-12-10-14-34-36.png",width:50%)
- VFS provides an *object-oriented way* of implementing file systems
  - 操作系统为 FS 定义一套 common interface，所有 FSes 都需要实现它们
  - Syscall 基于 common interface 实现
- VFS Implementation
  - e.g. `write` syscall $->$ `vfs_write` $->$ indirect call $->$ `ext4_file_write_iter`
  #fig("/public/assets/Courses/OS/2024-12-10-14-43-43.png",width:70%)
  - 在创建这个文件的时候，`file->f_op` 就被设为对应的函数表的地址（`f_op` 是指针）
  - 在需要调用某个函数时，去对应 FS 函数表的约定位置找到函数指针就可以访问了。这和 C++ 中多态的虚函数表是类似的
  - `struct file` 里存了文件的 `file_operations`，但没有存文件的 type，因为我们知道操作对应 fs 的文件，就不需要知道文件的类型了

== Directory Implementation
- 在 Linux 上，Directory 就是一个 special file，存储 file name 到 inode 的映射
  - L: Directory == File; W: Directory != File
  - Linux 这样的优点是接口相同，不用额外设计一套；缺点是容易搞混。这跟 Process V.S. Thread 类似，windows 把它们分开，而 linux 都用 `task_struct` 描述
- 我们这里讲的是 linux 实现
  - 它的数据块有自己的名字（目录项 `dir_entry`），每一个目录项有一个 inode 号、目录项长度、名字长度
    - 目录项 $4$ 对齐是为了重用，比如删除了 `a` 又创建 `bb`，可以直接重用
    - 之所以要存“目录项长度”，是为了加速搜索，典型的用空间换时间
  #fig("/public/assets/Courses/OS/2024-12-10-14-51-24.png",width:70%)
  - e.g. `/home/stu/a, bb, ccc, test`，对 `/home/stu` 这个目录的数据块：
    - How many entries? $4$ 个
    - What's the structure? 比如对 `a` 这个目录项，inode 号占 $4$ 个 bytes，目录项长度占 $2$ 个 bytes，长度为 $9=4+2+2+1 -> 12$（$4$ 对齐），文件名长度占 $2$ 个 bytes，长度为 $1$，文件名为 `a` 占 $1$ 个 byte
    - How to open `a`? 先去 `/` 对应的数据块里找 `home` 的文件名，拿出这个目录项的 inode；然后去 inode 指向的数据块里继续……
- 遍历
  - 最简单的实现方式是 linear list，即维护 `dir_entry[]`，这种方案的缺点是查找文件很费时
  - 使用有序数据结构（有序表、平衡树、B+ 树等）能够优化这一问题
  - 或者给线性表加上 hash table，根据文件名得到哈希值并得到指针，尤其有利于那种经常访问小碎片文件的情况
- 创建
  - Consider directory and FCB
  - 先分配一个新的 inode，然后找到当前目录的 inode，在其指向的数据块里加上一个目录项

== Disk Block Allocation
- Files need to be allocated with disk blocks to store data，这里介绍 3 种不同的 policy

=== Allocation Policies
#grid(
  columns: (70%, 30%),
  [
    - *Contiguous Allocation*
      - 每个文件在磁盘上占有一组连续的块
      - 需要考虑如何找到空闲空间: Best Fit, First Fit, .etc
      - 优点是顺序访问很快，同时目录只需要维护文件的起始 block 及其长度；
      - 缺点跟之前类似，会带来 external（但不同的是，这里磁盘通常够大，我们可能不在意这个问题）；另外难以处理文件增大的情况，需要重新分配空间（这是数组的问题，那就自然引出 linked list）
    - *Linked Allocation*
      - 每个文件都是磁盘块的链表
      - 优点：允许块分布在磁盘任何地方，只需维护下一个块的地址，没有外部碎片
      - 缺点是定位某个块需要遍历链表，需要很多 IO；且可靠性较差，某个块的指针坏掉导致后面的块均无法访问；且这种实现方式不支持 random access
    - *Indexed Allocation*
      - 把每个文件的所有指针放在一起，组成索引块，指向其数据块
      - 优点是这样可以支持 random access
      - 缺点是 reliability 不好，如果 index 块坏了，文件就访问不到了；并且浪费空间（需要一个块做 index）
      - 需要一个方法分配 index block 的大小（太大会浪费，太小那么指向的空间小）。我们可以把 index block 链接起来，用多级索引
    - *Multi-level Indexed Allocation*
      - 把索引块链接起来，用多级索引，但保留部分低级索引 (trade-off)，direct block 最快，indirect blocks 需要更高的 seek time
      - 我们之前说的 inode 实际上就是这里的 index block
      - 需要会算它在不同 Block Size 下能 index 的大小
      #fig("/public/assets/Courses/OS/2024-12-10-15-23-17.png",width:50%)
    - 比较
      + Contiguous 对 sequential and random 友好
      + Linked 对 sequential 友好，但 random 不友好
      + Indexed (combined) 比较复杂，每个块访存需要多次 seek，使用 cluster (a set of contiguous blocks) 可以增加吞吐量，降低开销
  ],
  [
    #fig("/public/assets/Courses/OS/2024-12-10-15-15-40.png")
    #fig("/public/assets/Courses/OS/2024-12-10-15-29-27.png")
    #fig("/public/assets/Courses/OS/2024-12-10-15-29-14.png")
  ],
  )

=== Free-Space Management
#wrap-content(
  align: right,
  [
    #fig("/public/assets/Courses/OS/2024-12-10-15-48-44.png",width:80%)
  ],
  [
    - *Bitmap*
      - 每一个 block 都用一个比特记录分配状态
      - 容易找到连续的空闲空间，但是占用额外空间（要会算）
      #fig("/public/assets/Courses/OS/2024-12-10-15-30-36.png",width:50%)
      - Clutster 优化：每 $4$ 个 block 用一个 bit 表示，能稍微少一些
    - *Linked Free Space*
      - 用链表连接所有空闲块
      - 好处是不会浪费空间
      - 缺点是不能快速找到连续的空闲空间，效率低；以及 reliability 不好，断一个后续都无法访问
  ]
)
- *Group*
  - 使用索引来分组空闲块，将 $n-1$ 个空闲块地址存储在第一个空闲块中，加上指向下一个索引块的指针
  - 分配多个空闲块无需再遍历链表，相当于 bitmap 和 linked 的结合
- *Counting*
  - 维护连续空闲块的链表，链表的每个结点是首块指针和连续块的数量

== File System Performance and Reliability
- 为了改善性能
  - Keeping data and metadata *close together*
  - Use *cache*
  - *asynchronous writes*，写到 buffer/cache 里，然后异步写到磁盘
  - *Free-behind and read-ahead*: 清除 buffer 中之前的 page，read-ahead 把后面的块也读到 buffer 里
  - 一个异常现象 —— *Reads slower than write*，这是因为 read 通常是对新文件，而 write 可以直接写到 cache 里
  - *Page Cache*
    - memory-mapped IO 用 page cache，而 FS 为 disk IO 使用 buffer cache
    - 统一的 buffer cache 使用相同的 page cache 来避免 double caching
- Recovery
  - 一致性检查：将目录结构数据与磁盘数据块比较，并纠正发现的不一致
  - Backup：将磁盘数据备份到另一个设备。然后从该设备恢复
  - Log Structured File Systems
    - 记录文件系统的更新称为事务，写到日志里
    - 事务一旦写入日志就是 commit 了，否则文件系统就还没更新

#takeaway[
  - File system layers
  - File system implementation
    - On-disk structure, in-memory structure
    - *inode*
  - File `creation()`, `open()`
  - *VFS*
  - Directory Implementation
  - *Allocation Methods*
    - Contiguous, linked, indexed
  - Free-Space Management
]

== File System Implementation --- In Practice
- Two key Abstraction
  - *File*
    - A linear array of bytes
    - External name (visible to user) must be symbolic
    - Internal name (low-level names): inode number in UNIX
  - *Directory*
    - translation from external name to internal name
    - 每个 entry 要么存储 pointer to file，要么是其它 directory
- File Descriptor
  - 每个进程有自己的 file descriptor table，file descriptor 是其中的索引
  - 每个 file descriptor entry 包含一个 file object（即一个打开的文件），指向一个 inode
  - 简单来说，就是一个用来索引已打开文件的数字
  #fig("/public/assets/Courses/OS/2024-12-11-20-37-18.png",width:40%)
- Getting information about files
  - linux 的 file information 存储在 `struct stat` 中
  - 通过同名 `stat` 命令进行查看
- Link (hard V.S. soft)
  - 当我们在 `remove` or `delete` 一个文件时，如果用 `strace` 会发现它使用的是 `unlinkat` 系统调用
  - 一个文件可能被多个目录以多个名字引用，这就是 link，有 hard 和 soft 两种
  - A *hard link* is a *directory entry* that associates with a file
    - 比如 `.` 是 directory 本身的 hard link，`..` 是 parent directory 的 hard link
    - ```sh ln file link``` 创建一个 hard link，实际上在 directory 的数据块里面加了一个 inode 一样但 file name 不一样的目录项
      - 这个 `link` 可以跟 `file` 一样被执行
      - 因此 `rm file` 时，只是删除了一个目录项，由于 hard link 的存在，文件并不会真正删除而只是计数减一
  - A *soft link* is a *file* containing *the path name of another file*
    - soft link 也叫 symbolic link or symlink
    - ```sh ln -s file link``` 创建一个 soft link，它的 inode 跟 `file` 不同，作为一个文件存储了 `file` 的路径
      - 因此 `rm file` 时，soft link 还存在但会失效，对它进行操作会报 `No such file or directory` 错误
  - soft link 能指向 directories，但是 hard link 不行；soft link 能够 cross filesystem boundaries（因为不是靠 inode 访问而是靠 path name）；两种 link 比起来，hard link 更经济但没 soft link 灵活
- 实际的 File System Organization 例子
  - 需要存储 data block, inode, bitmap, superblock
  - data block 最大，给它分配 $56$
  - 假设每个 inode 占 $256 bytes$，$4KB$ 可以放 $16$ 个 inode，那么 $5$ blocks 即可 hold $80>64$ 个 inode
  - 剩下三个 block，一个放 bitmap for free inodes，一个放 bitmap for data region，一个放 superblock
  - 要 read No. 32 inode，去找 $20KB$ 对应的块
  #grid2(
    column-gutter: 4pt,
    fig("/public/assets/Courses/OS/2024-12-11-20-33-13.png"),
    fig("/public/assets/Courses/OS/2024-12-11-20-33-31.png")
  )
- 一个实际的例子 read or write `/foo/bar`，尝试说出每一步是在 read/write 哪一部分的什么数据
  #grid2(
    column-gutter: 4pt,
    fig("/public/assets/Courses/OS/2024-12-11-20-35-04.png"),
    fig("/public/assets/Courses/OS/2024-12-11-20-35-20.png")
  )

#takeaway[
  - File Descriptor
  - Link (hard and soft)
  - File System Organization
]

= Security and Protection
== Security evaluation criteria
- Trusted Computer System Evaluation Criteria(TCSEC)
  - 当前的 OS 如 windows, linux, mac 都是 C2 级别
  - 更高的是 B1, B2, B3, A1，目前没有达到的（Multics 尝试 B2 但失败了）
- ITSEC, CC, GB17859，其它几个标准

== Common concepts
- 可信基(Trusted Computing Base)
  - 为实现计算机系统安全保护的所有安全保护机制的集合，即为了做操作你需要信任的部分（比如输密码时相信键盘、程序、操作系统、CPU 等），包括软件、硬件和固件（硬件上的软件）
  - TCB in layered systems，上层依赖于下层
    #tbl(
      [Application], [Operating system], [BIOS], [Hardware/Architecture]
    )
- 攻击面(Attacking Surface)
  - 一个组件被其他组件攻击的所有方法的集合，可能来自上层、同层和底层
  - 可信基属于攻击面的一部分，比如 OS 的 Attacking Surface 包括 BIOS 和 Hardware/Architecture
- 防御纵深(Defense in-depth)
  - 为系统设置多道防线，为防御增加冗余，以进一步提高攻击难度
  - 例如，不仅仅依赖于密码，还可以加上双因素认证

== Protection - Access Control
- Authentication 认证
  - 证明用户的身份
  - 进程与用户之间如何绑定？
    - 每个进程的 PCB/cred 中均包含了 uid 字段
    - 每个进程都来自于父进程，继承了父进程的 uid
    - 用户在登录后运行的第一个进程(shell)，初始化 uid 字段
    - 在 Windows 下，窗口管理器会扮演类似 shell 的角色
- Authorization 授权
  - 决定用户能做什么
  - 如何实现？使用 Access Control Matrix (Access Control Lists, ACL)
    #tbl(
      columns: 4,
      [], [Alice], [Bob], [Carl],
      [/etc], [Read], [Read], [Read, Write],
      [/homes], [Read, Write], [Read, Write], [Read, write],
      [/usr], [None], [None], [None]
    )
  - 用户过多或文件过多时，matrix 大到不可接受。将用户（人）与角色解耦的访问控制方法: Role-Based Access Control
  - POSIX 的文件权限：分成 owner, group, other 三类，每类有 read, write, execute 三种权限
    - 即 `rwxrwxrwx`
  - 最小特权级原则：setuid 机制
    - 问题：passwd 命令如何工作？用户有权限使用 passwd 命令修改自己的密码，但保存在 `/etc/shadow` 中，用户无权访问（本质上是以文件为单位的权限管理粒度过粗）
    - 解决方法：运行 passwd 时使用 root 身份（RBAC 的思想）。在 passwd 的 inode 中增加一个 SUID 位，使得用户仅在执行该程序时才会被提权，执行完后恢复，从而将进程提权的时间降至最小
    - setuid 在 Linux 下通常用于以 root 身份运行，拥有的权限远超过必要（必要权限：读写 `/etc/passwd` 文件中的某一行；实际权限：访问整个 `/etc/passwd` 文件，且（短暂地）拥有 root 用户的权限），具有安全隐患
  - 权限控制的另一种思路 —— Capability
    - 提供细粒度控制进程的权限（初衷：解决 root 用户权限过高的问题）
    - 基本的思想是把 root 的能力拆分，分为几十个小的能力，称为 capability
    - 预先由内核定义，而不允许用户进程自定义。不允许传递，而是在创建进程的时候，与该进程相绑定，每个进程可以拥有一组能力
    - 理想美好，但实际上使用混乱
- Auditing 审计
  - 用来记录用户的操作，以便追踪和审查
- Reference monitor
  - 是实现访问控制的一种方式，主体必须通过 reference 的方式间接访问对象，Reference monitor 位于主体和对象之间进行检查
  #fig("/public/assets/Courses/OS/2024-12-24-15-21-07.png", width: 50%)
  - 引用监视器机制必须保证其不可被绕过(Non-bypassable)，即设计者必须充分考虑应用访问对象的所有可能路径，并保证所有路径都必须通过引用才能进行
  - Linux 中，应用必须通过文件描述符来访问文件，而无法直接访问磁盘上的数据或通过 inode 号来访问文件数据。文件系统此时就是引用监视器，文件描述符就是引用

== Security
- Attacks and defenses
  - Evolution
    + Code injection attack
    + Code reuse attack
    + Non-control-data attack
  #fig("/public/assets/Courses/OS/2024-12-24-15-26-09.png", width: 80%)
- 代码注入攻击
  + 通过内核漏洞：篡改已有代码、注入新的代码、或者跳到用户代码
    - 内核代码注入防护：硬件支持杜绝注入、通过内核页表设置相应保护位
  + 通过内核页表来实现攻击：篡改页表去掉保护，进而篡改代码
    - 通过隔离环境保护内核页表，避免内核漏洞影响
    - 硬件支持可信执行环境
    - 实现了纵深防御
- 代码重用攻击
  - 不能注入新代码了，但可以重用已有代码(Existing code snippet, called gadget)，比如改变控制流把 gadget 串起来
    - Return-oriented programming (ROP)：通过修改栈上的返回地址，使程序跳转到已有的代码片段，从而实现攻击
    - Jump-oriented programming (JOP)：通过修改函数指针，泄露 SP
  - 防护：保护返回地址、保护函数指针（相应的硬件支持）
- 非控制数据攻击
  - 控制数据被保护后，攻击者提出非控制数据攻击，修改返回地址和函数指针以外的数据
  - 种类繁杂，难以实行统一有效保护。目前主流操作系统均*缺乏*对数据攻击的有效防护
- 总结
  #fig("/public/assets/Courses/OS/2024-12-24-15-49-51.png",width: 80%)

#takeaway[
  - Security evaluation criteria
    - TCSEC, ITSEC, CC, GB17859
  - Common concepts
    - Trusted computing base
    - Attack surface
    - Defense in-depth
  - Access Control
  - Attacks and defenses
]