---
order: 9
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

#let QA(..args) = note(caption: [QA], ..args)
#counter(heading).update(19)

= 面向数据编程与任务系统
== Parallel Programming 并行编程
- *Basics of Parallel Programming*
  + 摩尔定律的终结
  + 多核
  + 进程和线程
  + 多任务类型：Preemptive / Non-Preemptive
  + Thread Context Switch $->$ expensive
  + Embarrassingly Parallel Problem v.s. Non-embarrassingly Parallel Problem
    - 前者是理想情况，任务之间没有依赖关系，互不影响，容易并行化，最简单的例子就是蒙特卡洛采样，丢到多个线程各自执行；后者是真实情况下经常出现的情形，任务之间有各种 dependency
  + Data Race in Parallel Programming
    - Blocking Algorithm - Locking Primitives，都是操作系统里的基本概念
      - Issues with Locks: Deadlock Caused by Thread Crash, Priority Inversion
    - Lock-free Programming - Atomic Operations
      - Lock Free vs. Wait Free: 后者对整个系统做到 $100%$ 利用几乎难以达到，但对某个具体数据结构的完全利用还是有相应解法的
  + Compiler Reordering Optimizations
    - 编译器指令重排优化了性能，但存在打乱并行编程执行顺序的风险，硬件上的乱序执行也会导致类似问题
    - Cpp11 允许显式禁止编译器重排，但代价是性能下降
    - 程序开发一般有 debug 版本和 release 版本，debug 版本下基本可以认为执行顺序是严格的，release 版本下则不一定
- *Parallel Framework of Game Engine*
  - *Fixed Multi-thread*
    - 最简单的解法，把游戏引擎的各个模块分到不同的线程中去，e.g. Render, Simulation, Logic etc.
    - 1. 进程之间产生木桶效应，最慢的进程决定整体性能；2. 并且很难通过把一个模块拆分的方式解决，因为会出现 data racing 问题，且没有利用好 locality；3. 再者，每个模块的负载是动态变化而无法预先定义的，而用动态分配的方式会产生更多的 bug；4. 最后，玩家所用设备的芯片数五花八门，除非对每种数量预设都做过优化，否则部分核心直接闲置
  - *Thread Fork-Join*
    - 将引擎中一致性高、计算量大的任务（如动画运算、物理模拟）fork 出多个子任务，分发到预先定义的 work thread 中去执行，最后再将结果汇总
    - 显而易见这种 pattern 也会有许多核的闲置，但一般比 fixed 方法好，且鲁棒性更强，是 Unity, UE 等引擎的做法
    - 以 UE 为例，它显式地区分了 Named Thread (Game, Render, RHI, Audio, Stats...) 以及一系列 Worker Thread
  - *Task graph*
    - 把任务总结成有向无环图，节点表示任务，边表示依赖关系；把这个图丢给芯片，自动根据 dependency 决定执行顺序与并行化
    - dependency 的定义可以很淳朴，不断往每个 task 的 prerequest list 中 add 即可；问题在于，很多任务无法简单地划分，而且在运行过程中又可能产生新的任务、新的依赖，而这些在早期的 Task Graph 这样一个静态结构里没有相应的表述

== Job System 任务系统
- *Coroutine 协程*
  - 一个轻量级的执行上下文，允许在执行过程中 yield 出去，并在之后的某个时刻 resume 回来（被 invoke）
  - 跟 Thread 概念比较，它的切换由程序员控制，不需要 kernel switch 的开销，始终在同一个 thread 中执行
  - 两种 Coroutine
    - Stackful Coroutine: 拥有独立的 runtime stack，yield 后再回来能够恢复上下文，跟函数调用非常类似
    - Stackless Coroutine: 没有独立的 stack，切换成本更低，但对使用者而言更复杂（需要程序员自己显式保存需要恢复的数据）；并且只有 top-level routine 可以 yield，subroutine without stack 不知道返回地址而不能 yield
    - 两种方式无所谓高下，需要根据具体情况选择
  - 另外还有一个难点在于 Coroutine 在部分操作系统、编程语言中没有原生支持或支持机制各不相同
- *Fiber-based Job System*（可以参考 #link("https://zhuanlan.zhihu.com/p/594559971")[Fiber-based Job System 开发日志1]）
  - Fiber 也是一个轻量级的执行上下文，它跟 Coroutine 一样，也不需要 kernel switch 的开销，非常类似于 User Space Thread（某种程度上更像）。但不同在于，它的调度交由用户自定义的 scheduler 来完成，而不是像 Coroutine 那样 yield 来 resume 回去
    - 个人总结：Fiber 比 Thread 更灵活、轻量，比 Coroutine 更具系统性
    - 并且，对比这种通过调度方式分配和 Thread Fork-Join 方式分配，显然设定一个 scheduler 时时刻刻把空闲填满的方式更高效
  - Fiber-based Job System 中，Thread 是执行单元，跟 Logic Core 构成 1:1 关系以减少 context switch 开销；每个 Fiber 都属于一个 Thread，一个 Thread 可以有多个 Fibers 但同时只能执行一个，它们之间的协作是 cooperative 而非线程那样 preemptive 的
  - 通过创建 jobs 而不是线程来实现多任务处理（jobs 之间可以设置 dependency, priority），然后塞到 Fiber 中（类似于一个 pool），job 在执行过程中可以像 Coroutine 那样 yield 出去
  #fig("/public/assets/CG/GAMES104/2025-04-12-15-50-15.png", width: 50%)
  - *Job Scheduler*
    - Schedule Model
      - LIFO / FIFO Mode
      - 一般是 Last in First Out 更好，因为在多数情况下，job 执行过程中产生新的 job 和 dependency (tree like)，这些新的任务应该被优先解决
    - Job Dependency: job 产生新的依赖后 yield 出去，移到 waiting queue 中，由 scheduler 调度何时重启
    - Job Stealing: jobs 的执行时间难以预测准确，当某一 work thread 空闲，scheduler 从其他 work thread 中 steal jobs 分配给它
  - *总结*
    - 优点
      + 容易实现任务的调度和依赖关系处理
      + 每个 job stack 相互独立
      + 避免了频繁的 context switch
      + 充分利用了芯片，基本不会有太多空闲（随着未来芯片核数的增加，Fiber-based Job System 很有可能成为主流）
    - 缺点
      + Cpp 不支持原生 Fiber，且在不同操作系统上的实现不同，需要实现者对并行编程非常熟悉（一般是会让团队里基础最扎实、思维最缜密的成员负责搭建基座，其它成员只负责上层的脚本）
      + 且这种涉及到内存的底层实现系统非常难以 debug

== Data-Oriented Programming (DOP)
- *Programming Paradigms*
  - 存在各种各样的编程范式，不同编程语言又不局限于某一种范式
  - 游戏引擎这样复杂的系统往往需要几种的结合
  #fig("/public/assets/CG/GAMES104/2025-04-12-16-28-44.png", width: 80%)
  - 早期编程使用 Procedural Oriented Programming (POP) 就足够，后来随着复杂度增加，Object-Oriented Programming (OOP) 成为主流
- *Problems of OOP*
  + Where to Put Codes: 一个最简单的攻击逻辑，放在 Attacker 类里还是 Vectim 类里？存在二义性，不同程序员有不同的写法
  + Method Scattering in Inheritance Tree: 难以在深度继承树中找到方法的实现（甚至有时候还是组合实现的），并且同样存在二义性
  + Messy Based Class: Base Class 过于杂乱，包含很多不需要的功能
  + Performance: 内存分散不符合 locality，加上 virtual functions 问题更甚
  + Testability: 为了测试某一个功能要把整个对象创建出来，不符合 unit test 的原则
- *Data-Oriented Programming (DOP)*
  - 一些概念引入
    - Processor-Memory Performance Gap，直接导致 DOP 思想的产生
    - The Evolution of Memory - Cache & Principle of Locality
    - SIMD
    - LRU & its Approximation (Random Replace)
    - Cache Line & Cache Hit / Miss
  - DOP 的几个原则
    + Data is all we have 一切都是数据
    + Instructions are data too 指令也是数据
    + Keep both code and data small and process in bursts when you can 尽量保持代码和数据在 cache 中临近（内存中可以分开）
- *Performance-Sensitive Programming 性能敏感编程*
  - Reducing Order Dependency: 减少顺序依赖，例如变量一旦初始化后尽量不修改，从而允许更多 part 能够并行
  - False Sharing in Cache Line: 确保高频更新的变量对其 thread 保持局部（减少两个线程的交集），避免两个 threads 同时读写某一 cache line（cache contension，为了保持一致性需要 sync 到内存再重新读到 cache）
  - Branch prediction: 分支预测一旦出错，开销会很大。为了尽量避免 mis-prediction，会把用作判断的数组排个序来减少分支切换次数，或是干脆分到不同的容器里执行来砍掉分支判断 (Existential Processing)
- *Performance-Sensitive Data Arrangements 性能敏感数据组织*
  - Array of Structure vs. Structure of Array
  - SOA 效率更高，例如 vertices 的存储，它把 positions, normals, colors 等分开共同存储

== Entity Component System (ECS)
过去基于 OOP 的 Component-based Design，患有 OOP 的一系列毛病；而 ECS 则是 DOP 的一种实现方式，实际上就是之前讲过的概念的集合。

- *ECS 组成*
  - Entity: 实体，通常就是一个指向一组 componet 的 ID
  - Component: 组件，不同于 Component-based Design，ECS 中的 component 仅是一段数据，没有任何逻辑行为
  - System: 系统，包含一组逻辑行为，对 component 进行读写，逻辑相对简单方便并行化
  - 即把过去离散的 GO 全部打散，把数据和逻辑分开，数据按照 SOA 的方式整合存储为 Component，逻辑通过 System 来处理，只保留 Entity ID 作为索引
- *Unity ECS*
  - 采用 Unity Data-Oriented Tech Stack (DOTS)，分为三个组成部分
    + Entity Component System (ECS): 提供 DOP framework
    + C\# Job System: 提供简单的产生 multithreaded code 的方式
    + Burst Compiler: 自定义编译器，绕开 C\# 运行在虚拟机上的低效限制，直接产生快速的 native code
  - Unity ECS
    - Archetype: 对 Entities 的分组，即 type of GO
    - Data Layout: 每种 archetype 的 components 打包在一起，构成 chunks (with fixed size, e.g. 16KB)
      - 这样能够提供比单纯的所有 components 放在一起更细粒度的管理。比如是把所有 GO（包括角色、载具、道具）的 tranform 全堆在一起，还是把所有角色的、所有载具的、所有道具的 tranform 分开再存在一起？显然后者更好
    #fig("/public/assets/CG/GAMES104/2025-04-12-18-46-36.png", width: 70%)
    - System: 逻辑相对简单，拿到不同的 component 做某种运算
  - Unity C\# Job System
    - 允许用户以简单方式编写 multithreaded code，编写各种 jobs 且可以设置 dependency
    - jobs 需要 native containers 来存储数据、输出结果（绕开 C\# 虚拟机的限制，变为裸指针分配的与内存一一对应的一段空间），也因此需要做 safety check，需要 manully dispose（又回到老老实实写 Cpp 的感觉，也算是一开始使用 C\# 带来的恶果吧）
    - Safety System 提供越界、死锁、数据竞争等检查（jobs 操作的都是 copy of data，消除数据竞争问题）
  - Unity Burst Compiler
    - High-Performance C\# (HPC\#) 让用户以 C\#-like 的语法写 Cpp-like 代码，并编译成高效的 native code（很伟大的工作）
    - 摈弃了大多数的 standard library，不再允许 allocations, reflection, the garbage collection and virtual calls
- *Unreal Mass Framework —— MassEntity*
  - Entity: 跟 Unity 的 Entity 一样，都是一个 ID
  - Component
    - 跟 Unity 一样有 Archetype，由 fragments 和 tags 组成，fragments 就是数据，tags 是一系列用于过滤不必要处理的 bool 值
    - fragment 这个名字取得就比 Unity 好，既跟传统的 component 做出区分，又表示内存中一小块碎片、数据
  - System
    - UE 里叫 Processors，这个名字也起得比较切贴，用于处理数据
    - 提供两大核心功能 `ConfigureQueries()` and `Execute()`
  - Fragment Query
    - Processor 初始化完成后运行 `ConfigureQueries()`，筛选满足 System 要求的 Entities 的 Archetype，拿到所需的 fragments
    - 缓存筛选后的 Archetype 以加速未来执行
  - Execute
    - Query 后拿到的是 fragments 的引用（而不是真的搬过来，因为也是按照 trunk 存储、处理），Execute 时将相应 fragments chunk 搬运并执行相应操作

然而游戏是个很复杂、很 dependent 的系统，很难把所有逻辑按 ECS 架构组织，这可能也是为什么 ECS 在现今还未成为主流（有 “好看不好用” 的评价）。做游戏引擎千万不要有执念，关键是在什么场合把什么技术用对。

- Everything You Need Know About Performance（对着这张图进行优化）
  #fig("/public/assets/CG/GAMES104/2025-04-12-19-47-59.png", width: 90%)

= 动态全局光照和 Lumen
先讲了一堆 GI 的内容，这部分可以转战 Games202（具体笔记补充在那边）。

Lumen 是 UE5 的一个动态全局光照系统，真的是非常伟大的工作。对搞引擎的人来讲，把一个如此复杂的系统整合在一起，并成为一整个游戏系统的核心 feature，其难度是非常大的。

- 三句话讲 Lumen
  + Ray Traces are slow! 虽然硬件在不断发展（近年来越发趋缓)，但 ray trace 的速度依然是个问题，尤其是在非 N 卡上，往往只能达到 $approx 1$ spp，而 GI 需要上百。Lumen 希望能达到任意硬件下的 fast ray tracing（当然如果硬件支持也可以去调用）
  + Sampling is hard! 虽然 temporal / spacial 的 filtering 技术不断发展，但效果依旧有限
  + Low-res filtered scene space probes lit full pixels: 不逐像素做间接光采样，使用紧贴表面的稀疏探针做采样，然后插值获得像素的间接光照，再结合屏幕空间光追补充一些高频细节
- 话虽如此，Lumen 的复杂度不是短短三句话能概括的，且很容易陷入具体算法而看不清整体结构，这里把 Lumen 分为四个阶段
  + Fast Ray Trace in Any Hardware
  + Radiance Injection and Caching
  + Build a lot of Probes with Different Kinds
  + Shading Full Pixels with Screen Space Probes

== Phase 1: Fast Ray Trace in Any Hardware
- Signed Distance Field (SDF)
  - SDF 基础就不赘述，这里表达一个思想：SDF 很有可能成为现代渲染引擎的基础数学表达
  - SDF 构成空间形体的对偶表达，有时候对偶的函数呈现的会更加清晰，而且展现出很多更好的数学属性；并且 SDF 是连续的表达，更进一步它是可微的（神经网络嗅着味就来了x）；另外，SDF 的导数就是法向
  - 反观传统的 mesh，它不仅点是离散的，三角形面之间也没有关系（irregular，需要手动用 index buffer 关联），很多时候还需要做 adjacency information 冗余信息才能进行各种几何处理
- Ray / Cone Tracing with SDF
  - 参考 GAMES202: SDF for ray marching $->$ safe distance; SDF for cone tracing $->$ safe angle
- Per Mesh SDF
  - 对每个 mesh 做局部的 SDF 来存储，多个 instance 可以复用，进而合成整个场景
    - 合成涉及到大量数学变换（如果 scale 变换是等比的会相对简单一些），这里不展开
  - 由于后面会对场景进行点采样，对于特别细的 mesh，若小于场景最小 voxel 之间的距离，需要进行 expand（可能导致 over occlusion，但起码比 light leaking 好）
  - Sparse Mesh SDF: 把 SDF 分成 bricks，绝对值大于某个阈值时就不存储，虽然 ray marching 的步子没法那么大了，但能节省存储
  - Mesh SDF LoD: SDF 是 uniform 的，很容易做 LoD，这里做三层 mip
  #grid(
    columns: (24%, 38%, 38%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-18-52-08.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-18-47-25.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-00-03.png")
  )
- Global SDF
  - 合成为整个场景的低精度 SDF 表达（两个难点，一是数学上如何变换，二是如何更新）
  - 因为是 uniform 表达，所以很容易做成 clipmap，如图所示，每个小格子图上看起来差不多大，但实际上越远代表越大的空间
  - 通过 global SDF 快速找到粗略交点，再根据周边的 per mesh SDF 精细化，能够不依赖于硬件 Ray Tracing 的情况下比传统 AABB, Ray interact with Triangle 求交快得多

== Phase 2: Radiance Injection and Caching
当我们从光的视角照亮整个世界，其实无论从相机角度能否看见，都有可能对最终的屏幕像素产生影响，都是 GI 的贡献者。因此 GI 一般需要做光照的注入（photon mapping 的思想，光子如何固化场景中），如通过 RSM, Probes, Volume 等。RSM 只能做一次 bouncing，而各种 Probes 采集、Volume 传播的方法则五花八门。Lumen 则是采取了一个比较耳目一新的做法 —— Mesh Cards。

- *Mesh Cards*
  - Pass 1: 以 AABB 的方式存储每个 instance 从 $6$ 个方向看去的快照
    - 根据相机距离做 LoD，分配 mesh card 的精度
  - Pass 2: 整合到整个场景的 *Surface Cache* 里，并且做纹理压缩
    - 总共大小固定为 $4096 times 4096$，再细分为 $128 times 128$ 的 pages，随着相机移动需要 swap in/out
  #grid(
    columns: (23%, 52%, 25%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-19-35-48.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-24-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-30-48.png")
  )
- *Voxelization*
  - 对场景建立 SDF 表达 (per-mesh, global)，再建立 mesh card 表达还不够，还要再做 voxelization (clipmap)。Voxelization 表达可以用作时序上 GI 注入的媒介，也可以为直接光照时远处的物体提供光照值（适配 Global SDF）
  - 构建 $4$ level clipmaps of $64 times 64 times 64$ voxels，存储 $6$ 个面的 radiance，存到 3D texture 中
  - Voxel Visibility Buffer
    - 不是直接存储 radiance，而是存储每个 Voxel 在每个方向上 SDF trace 到的信息，存在所谓 Voxel Visibility Buffer 中
    - 与我们熟知的 V-Buffer 不同，它存储的是 Hit Object ID 以及归一化的 Hit Distance，这样后续 Inject Lighting 时就能快速找到对应的 surface cache 进行采样
  - Short Ray Cast 构建
    - 对 clipmap 再划分为 $16 times 16 times 16$ 个 tile（每个包含 $$4 times 4 times 4$$ 个 voxel），一个 wavefront/warp 处理一个 tile，tile 内从每个 voxel 边上随机采样一条（或多条）ray，每一条 ray 创建一个 thread 对一个 Mesh SDF 求交，结果只取求交距离最短的 hit
    - 每个 tile 包含的物体不会太多，因此每根 ray 只会与极少量 mesh 求交，而且是通过 SDF 进行，运算效率非常高
  - Clipmap 的更新
    - 更新 radiance 以及 voxel visibility buffer
    - 跟 VXGI 一样，只需要更新少量“脏”的 voxel 即可（而且每帧只会更新一个 level），具体而言是用 Scrolling Visibility Buffer 方法
    #tbl(
      columns: 5,
      [Clipmap update frequency rules], [Clipmap0], [Clipmap1], [Clipmap2], [Clipmap3],
      [Start_Frame], [0], [1], [3], [7],
      [Update_interval], [2], [4], [8], [8],
    )
  - 这个 Voxel Lighiting 模块跟后面要讲的 Screen Probe 很容易混淆，可以简单区分为：前者是存储我被照的有多亮，且每个面只存一个亮度；而后者负责照亮其它物体，存储的是光场分布
  - 从更 high level 的角度思考，Lumen 又搞 mesh car 又搞 voxel lighting，看起来很复杂，但借此构建了 uniform, regular 的表达，使得无论是积分、卷积、采样都会变得更简单
  #q[注：不过悲惨的是，这个 Voxel Lighting 的模块似乎在 UE5.1 被砍了。。。]
  #grid(
    columns: (18%, 60%, 22%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-21-47-16.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-56-16.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-22-13-52.png"),
  )
- *“Freeze” lighting on Surface Cache*
  - 光源打出光在场景中如何 multi-bounce？最终如何将 radiance 留在 surface cache 中？又如何考虑每个 pixel 是否在阴影中？
  - #strike[把大象装进冰箱] 把光照固化分为三步
    + 计算 Surface Cache 的直接光照
    + 假设已经有了 final lighting，把 final lighting 转化到 voxelization 中
    + 这样可以把上一帧 Voxelization 表达的全局光照视作这一帧的间接光照，和第一步的直接光照加在一起
      - 这种每次只算一次 bouncing，但随着时间积累变成多次 bouncing 的做法，跟 DDGI 如出一辙
  + Direct Lighting
    - 从每个光源用 SDF Ray Tracing 快速得到 shadow map，以此计算直接光照并相加
    - Tile-Based Rendering: 把 $128 times 128$ 的 page 再细分为 $8 times 8$ 个 tile，每个 tile 选取前 $8$ 个影响它的光源（控制复杂度）
    - 对于比较近的物体，用 Per-Mesh SDF Ray Tracing 方法即可找到 Surface Cache 进行更新；对于较远物体，得用 global SDF 不然太慢，但 global SDF 没法给出 per mesh information，只有 hit position, normal，但可以从 voxel lighting 中获取一个亮度
  + Inject Lighting into Clipmap
    - 每个 voxel 根据 hit information 知道从 Surface Cache 的哪个位置采样上一帧的 final lighting，得到一个 radiance
  + Indirect Lighting
    - 从 voxel 表达传递光照信息到 surface cache 中，首先将 surface cache 划分为 $8 times 8$ tile，放置 $2 times 2$ probes，每个 probe 在半球上采样 $16$ 条 ray
      - $16$ 正好就是每个 probe 覆盖的 $4 times 4$ texels，另外还需要对 probe placement, ray directions 做 Jitter
    - 对 probe radiance altas 做 spacial filtering，插值采用转化为 SH 的方式
  - 随后将光照组合即可，同时也顺带解决了 emissive 物体的问题
  #fig("/public/assets/CG/GAMES104/2025-04-20-22-57-13.png")
  - Surface Cache 的光照更新也会有一个 budget，$1024 times 1024$ for direct lighting, $512 times 512$ for indirect lighting，且根据优先级选择 priority
    - Priority = LastUsed - LastUpdated，通过 bucket sort 维护 priority queue
- 还有很多复杂的细节没有展开讲，比如
  + terrain 显然没法用 mesh card 表达
  + 场景中有半透明的 participate media 怎么办？
  + clipmap 具体怎么存、移动时怎么更新

== Phase 3: Build a lot of Probes with Different Kinds
虽然我们有了 Surface Cache / Voxel Lighting 的 radiance 表达，但它们还无法直接应用于屏幕像素的 shading。作为对 Render Equation 的求解，我们需要得到每个像素在半球面各个方向的 radiance，一般来说会用 probe 来做。

probe 的放置是个讲究活，最自然的想法就是在空间中均匀洒 probe，从 surface cache, voxel lighting 中采样光照。但一般来说这样的表达没法跟场景的精细几何相匹配（哪怕做了近大远小的 clipmap 也是一样），会“看上去很平”，这是预先生成的 distribution 共有的问题。而 Lumen 则很大胆，直接*在 screen space 中做 probe*。

- *Screen Probe* 可以分为 $5$ 步流程
  + 确定 screen probe 在屏幕空间的位置
  + 每个 probe 以生成位置为中心向外发射射线去获得颜色
  + 获取到颜色后先在 probe 与 probe 之间做时序滤波和空间滤波，再通过球面谐波函数压缩成 SH 存储
  + 根据最终得到的 probe 信息去插值出每个 pixel 的颜色
  + 再整个屏幕空间做时序滤波
  - 这里 Phase 3 我们仅会涉及前两步
- *Screen Probe Placement*
  - Uniform Placement
    - 屏幕空间最粗暴的做法自然是为每个 pixel 做一个 probe 收集光照，但过于粗暴而无法接受
    - 鉴于 indirect light 的低频性，Lumen 默认每 $16 times 16$ 个 pixel 一个 Screen Probe，贴着物体表面放置
  - Adaptive Placement
    - 对于高频细节（几何差异较大的表面）使用 Hierarchical Refinement 来自适应地放置更高分辨率的 Uniform Probes
    - 先放置覆盖 $16 times 16$ 像素的 probe，如果存在插值失败的像素则自适应地放 $8 times 8$ 像素 probe，还失败再放 $4 times 4$ 像素 probe
      - 插值失败与否通过 plane distance weight 判断，每个 pixel 及其法向定义一个平面，采样点到平面的距离决定权重，低于阈值则需要细分
      - 这种先粗后细、自适应划分的思路非常值得学习，回忆 RSM 降采样并在几何变化剧烈区域重采样的做法，已经暗含这个思想
      - 如下图所示，暗红色为原始分辨率 probe，黄色为细分的 probe（$8 times 8$ / $4 times 4$，发生在几何变化较大的地方）
    - 新生成 probe 的 depth, normal 等信息写在和 uniform probe 同一张 texture 上（利用方形纹理的边角料区域）
  - Jitter
    - 基于时序超分思想，每一帧生成的 probe 都会有不同的 placement, direction 的抖动
    - 在同等分辨率（间距）的 probe 下近似得到更小间距 probe 的效果，结果更平滑
    #grid(
      columns: (30%, 65%),
      column-gutter: 2em,
      fig("/public/assets/CG/GAMES104/2025-04-21-21-53-10.png"),
      [
        #fig("/public/assets/CG/GAMES104/2025-04-21-22-15-33.png")
      ]
    )
    #fig("/public/assets/CG/GAMES104/2025-04-21-22-15-13.png", width: 80%)
- *Screen Probe Ray Tracing*
  - 每个 probe 的光照信息存储在 $8 times 8$ 的空间内，记录 radiance 和 hit distance，其方向在 world space directions 中均匀采样，通过 Octahedron mapping 存储（同 DDGI）
  - 每个 probe 只发射 $64$ 根射线 (fixed budget)，但为了加速收敛速度需要做*重要性采样*
  - 换句话说，分布方向均匀但采样方向不均匀，初学时极易混淆。怎么理解呢？后面会为每个 pixel 算出 pdf，以 $4$ 个为一组，如果每组最大的 pdf 小于某个阈值，就能减少发射次数。但完全不发射也是不对的，所以用 mipmap 方式四合一，在降一级的 mipmap 上发射一根光线，多出来的 $3$ 次机会让给其它 pixel with large pdf 用以细化，在升一级的 mipmap 上发射 $4$ 根光线（但仍存成一格）
  #grid(
    columns: (54%, 46%),
    fig("/public/assets/CG/GAMES104/2025-04-21-00-02-20.png"),
    [
      #fig("/public/assets/CG/GAMES104/2025-04-21-23-21-01.png")
      #fig("/public/assets/CG/GAMES104/2025-04-22-10-58-11.png")
    ]
  )
- *Importance Sampling*
  #grid(
    columns: (70%, 30%),
    column-gutter: 4pt,
    [
      - 重要性采样的目的是使得分母的 $P_k$ 分布尽可能跟分子的分布相似，Lumen 采用了将分子拆开来分别做重要性采样而后卷积的 hack。虽然把方程强行拆开，但仍能大幅加快收敛速度
      $ lim_(N -> infty) 1/N sum_(k=1)^N frac(ybox(fill: #true, L_i (I)) rbox(fill: #true, f_s (I->v) cos(th_I)), P_k) $
    ],
    fig("/public/assets/CG/GAMES104/2025-04-21-23-37-43.png")
  )
  - *BRDF 重要性采样*
    - BRDF 和 normal 共同决定了光照信息在哪些方向收集更有效，Lumen 计算间接光的过程不考虑材质信息，BRDF 默认为常数 $1$，问题归结于 normal 的分布
    - 最直接的想法是找到 screen probe 所在材质的 normal，沿着该方向做 cosine lobe，但这其实并不合理，因为一个 probe 包含 $16 times 16$ 个 pixel，可能覆盖从远到近几何变化剧烈的多个物体，法向变化非常高频
    - 为此我们在采样中再套一层采样，如右上图所示，每个 probe 在 $32 times 32$ 区域内采样 $64$ 次附近 pixel，通过深度、法向判断是否共面 (plane distance)，若有效则把 normal 转化为 SH，最后求均值
  - *Lighting 重要性采样*
    #grid(
      columns: (90%, 10%),
      column-gutter: 2em,
      [
        - 这部分要解决的就是光源位置问题，比如室内场景最头疼的问题就是窗户在哪（光照从户外以窗户为次级光源传入）
        - Lumen 采样时序上信息继承的做法，通过上一帧的光照信息得知哪里相对亮
        - 具体而言
          + 根据相机变化和当前帧 probe 的深度、位置以及 jitter 偏移重建出上一帧 probe 的深度、位置
          + Spatial Filtering: 与附近的 neighbor probes 计算权重与插值
            - $3 times 3$ kernel 覆盖 $48 times 48$ pixels
            - Lumen 忽略了 normal 而只考虑 depth weight
          + Gather Radiance from neighbors: 找到 probe 对应的颜色乘以权重再累加得到最后的 radiance
            - 需要考虑两种 error
              + Angle error: 角度偏差过大不可接受，否则会导致 local shadowing
              + Hit distance error: hit 距离差距过大不可接受，否则会导致 lighting leaking
            - #bluet[蓝]：neighbor ray，#greent[绿]：自身打出去的 ray，跟 neighbor ray 相近可接受，#redt[红]：自身打出去的 ray，不可接受
          + 如果 neighbor probes 被遮挡则考虑 world space probes（后面细讲）
        #grid(
          columns: (50%, 50%),
          column-gutter: 4pt,
          fig("/public/assets/CG/GAMES104/2025-04-21-23-29-03.png", width: 90%),
          fig("/public/assets/CG/GAMES104/2025-04-21-23-29-14.png", width: 90%)
        )
      ],
      fig("/public/assets/CG/GAMES104/2025-04-22-12-04-56.png")
    )
- *World Space Probes and Ray Connecting*
  - 虽然已经有 Screen Space Probes (SSP)，为什么还要有 World Space Probes (WSP) 呢？
    + 对于需要采样较远的 case， ray tracing 的效率下降
    + 距离增长后小而亮的特征带来的 noise 也会增大
    + 这种 distant lighting 变化比较缓慢，提供了 cache 的机会（尤其是对静态场景，与之对比，SSP 每帧都要变化）
  - 为此在 world space 以 clipmap 的方式放置 probes，存储各个方向的 radiance（比 screen space 更密，确保各个方向都能 handle），这样 SSP 的采样不用跑很远，就能借 WSP 的光
  - 哪些 WSP 需要更新？
    + 首先，像 VXGI 那样，每帧随相机移动时只有边缘部分需要更新
    + 其次，对于所有 WSPs，只有场景变化、光源变化时才有更新需求
    + 最后，如果一片空间内没有物体、不在 screen space 下的 WSP 没有必要采样（包裹了 SSP 的 WSP 会被标记为 marked，只有 markded 的 WSP 才有采样需求）
  #fig("/public/assets/CG/GAMES104/2025-04-21-23-51-40.png", width: 90%)
  - Ray Connecting
    - 每个 SSP 被 WSP 的 voxel 包裹，只会采样对角线距离的两倍之内 (interpolation footprint + skipped distance) 的光照，一旦出了这个距离就选择借 WSP 的光
    - 同样 WSP 也只会采样对角线距离之外 (beyond interpolation footprint) 的光照，避免重复采样
    - 显然，这个 footprint 的大小跟 WSP 所处的 clipmap level 有关，也就是 SSP 借光行为的阈值距离是自适应而非写死的
  - Artifact
    - 借光时跳过遮挡物，进而导致 light leaking
    - 解决方法是 “对光线施加偏转”，SSP ray 与 footprint 的交点与要从它身上借光的 WSP 连线得到一个新的角度，使用这个偏转了一定角度的光照 (hack)
  #fig("/public/assets/CG/GAMES104/2025-04-22-10-12-40.png", width: 90%)
- How to do ray tracing
  - 以上说了那么多，实际上还没有涉及 ray tracing 到底怎么做，包括 screen space, world space（这里 GAMES104 没有详细讨论）
  - Screen Space Ray Tracing
    - 主要使用 SSGI 的方法 (SSR)，还涉及 temporal 信息的利用
  - World Space Ray Tracing
    - Lumen 作为一个算法体系，混合了多种 trace 方法
      - 左图表示每个区域所使用的 trace 方法，右图是各种 trace 方法的优先级（优先使用限制大但准确的方法）
      #grid(
        columns: (57%, 43%),
        column-gutter: 4pt,
        fig("/public/assets/CG/GAMES104/2025-04-22-22-37-34.png"),
        fig("/public/assets/CG/GAMES104/2025-04-22-22-37-22.png")
      )

== Phase 4: Shading Full Pixels with Screen Space Probes
以上我们做了那么多工作 (mesh card, voxel lighting, world space probes)，一切的根本目的都是为了产生表达足够有效的、紧贴表面的 screen space probes。

- 回忆之前说 Screen Probe 可以分为 $5$ 步流程
  + 确定 screen probe 在屏幕空间的位置
  + 每个 probe 以生成位置为中心向外发射射线去获得颜色
  + 获取到颜色后先在 probe 与 probe 之间做时序滤波和空间滤波，再通过球面谐波函数压缩成 SH 存储
  + 根据最终得到的 probe 信息去插值出每个 pixel 的颜色
  + 再整个屏幕空间做时序滤波
  - 前两步已经完成，现在只剩最后三步！当然到了这里实际上已经比较简单了，课程在此几乎一笔带过
- *Convert to SH*
  - 虽然我们做了 Important Sampling，但实际上 Indirect Lighting 还是很不稳定
  - 把这些光投影到 SH 上面去，SH 本身便起到低通滤波的作用，用它来做 shading 看上去就柔和许多

== Overall, Performance and Result
- 不同 Tracing Methods 的对比 (Cost v.s. Accuracy)
  - HZB: Hi-Z Buffer, HW: Hardware Ray Tracing
  #fig("/public/assets/CG/GAMES104/2025-04-22-22-35-55.png", width: 50%)

Lumen 受限于硬件做了很多妥协，未来十年随着硬件发展，real-time GI 会变得更加成熟也可能更加简洁。但不管如何，Lumen 作为如此复杂的算法体系，算是把 GI 做到实时、泛用的真正开山鼻祖，奠定了未来十年游戏引擎渲染的标杆与基础，是这一系列伟大征程的开端。

#QA([在硬件光追飞速发展的今天，Lumen 仍然开发了距离场和软件光追，那么对于当下的引擎开发来说，是否距离场和软件光追也是必须的？], [一方面，随着硬件发展触及摩尔定律的瓶颈，未来几年的硬件性能可能让 SSP 能翻一个数量级，但对 GI 来说其实没有本质改变，所以 Lumen 所使用的 SDF 和软件光追算法是非常有意义的；另一方面，Lumen 自己也在利用硬件光追的发展，在硬件支持的情况下能否利用其简化部分计算。总之对这个问题老师持 Open-minded 态度。])

= GPU 驱动的几何管线 Nanite
先讲了一堆 GPU-Driven Rendering Pipeline 的内容，这部分放到之前渲染 part 中的渲染管线处。这里着重记《刺客信条大革命》和 Nanite 的做法。

== GPU Driven Pipeline in Assassins Creed
《刺客信条大革命》着眼于城市环境，有着大量的 architecture, seamless interiors, crowds... 这样繁多且精细的几何，在传统 Pipeline 里只能全部 load 起来，一个个 instance 地绘制（只能做一些基本、低效的 culling），很显然会有巨量 overdraw，问题的核心就在于如何高效地实现各种 culling。

- *Mesh Cluster Rendering*
  - 《刺客信条大革命》是最早的 cluster-based rendering 实践，其思想非常简单，把完整的 instance 划分为多个 cluster，从而允许用它们各自的 bounding 做更细粒度的 culling (usually by compute shader)。其最大的好处在于，避免了仅仅看到一个角就要把整个精细的 instance 都 load, draw 的 case
  - 这需要
    + 固定的 cluster 拓扑结构 (e.g. $64$ triangles in Assassin Creed / $128$ triangles in Nanite)
    + split & rearrange meshes 来满足固定的拓扑结构（可能需要插入一些 degenerate triangle）
    + 在 vertex shader 中手动 fetch vertices
- *GPU-Driven Pipeline*
  - Overview
    - CPU 端做一些简单的 culling，GPU 端做通过更复杂的 culling 筛选出可见的 instance 的可见的 cluster 的可见的 triangles
    - 最后全部 packing 成一个超大的 index buffer，从而可以通过 single-/multi- indirect draw 来达到 draw scene 的效果
    - 这种做各类细化 culling 后把结果打到一个大 buffer 中，随后发出 indirect draw call 的做法，初看之下会很费，但逐渐变成下一代 rendering pipeline 的标准解法之一
  #grid(
    columns: (55%, 44%),
    column-gutter: 4pt,
    [
      + Works on CPU side
        - 执行 coarse view-dependent frustum culling / quad tree culling
          - 具体做法可以参考 #link("https://www.pinwheelstud.io/post/frustum-culling-in-unity-csharp")[Unity frustum culling - How to do it in multi-threaded C\# with Jobs System], #link("https://www.pinwheelstud.io/post/how-to-do-cell-based-culling-using-quadtree-in-unity-c-part-1")[How to do cell based culling using quadtree in Unity C\# - Part 1]
        - 合并 drawcalls for non-instanced data (e.g. material, renderstate, ... persistent for static instances)，然后更新 per instance data (e.g. transform, LOD factor, ...)
          - 这里可以看到，Assassin Creed 的 LoD 还是基于传统方法，这跟后面的 Nanite 有本质不同
    ],
    fig("/public/assets/CG/GAMES104/2025-04-23-23-43-54.png"),
  )
  #grid(
    columns: (31%, 30.7%, 38.3%),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-05-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-03.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-26.png")
  )
  #grid(
    columns: (31.5%, 34.25%, 34.25%),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-42.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-07-02.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-07-24.png")
  )
  2. GPU Initial State
    - instance stream 包含了 GPU-buffer 中 per instance 的数据，比如 transform / instance bounds 等
  + GPU Instance Culling
    - GPU 做 instance 的 frustum culling / occlusion culling，后者单开一 part 细讲
  + Cluster Chunk Expansion
    - 把所有的 instances 细分为 clusters，但又 $64$ 个为一组合成 chunks。原因是每个 instance 展开的 cluster 数量方差太大 $(1 \~ 1000)$，直接展开会造成 wavefront / warp 计算资源不均，而这样组合之后能一次性发出一批工作
    - 这跟后面 Nanite 把 cluster 合成 group 的思路有异曲同工之妙
  + GPU Cluster Culling
    - 使用 instance 的 transform 和每个 cluster 的 bounding box 做 frustum / occlusion culling
    - backface culling by codec triangle visibility in cube
      - 每个 cluster 有 $64$ 个 triangle，用 $6 times 64$ 个 bit 来表达每个 triangle 在 $6$ 个方向上的可见性（预烘焙 cluster 的朝向 mask）
    - 通过 culling 的 cluster 会导出 index compact job，其中包含 triangle mask 和 r/w offsets，这些 offset 根据关联的 instance primitive 使用 atomic 操作生成
  + Index Buffer Compaction
    - 预先准备一个大的 Index buffer $(8MB)$，并行地把 visible triangles index 复制到其中（依赖 compute shader 并行但原子的 append 操作）
    - 一次场景渲染可能没法完全存进一个 buffer，所以 Index Buffer Compaction (ExcuteIndirect) 和 Multi-Draw (DrawIndexInstancedIndirect) 是交替进行的
    - 小细节：每个 wavefront 处理一个 cluster，每个线程处理一个三角形，它们之间相互独立。根据之前传递的 triangle mask 和 i/o offsets，每个线程计算输出正确的写入位置，锁死绘制顺序 (deterministic)，防止因为 Z-Buffer 的精度问题导致 Z-Fighting
  + Multi-Draw
    - 最后每个 batch 一个 multi-draw，渲染数据
- *Occlusion Culling for Camera*
  - 主相机的遮挡剔除，其思想是在 Pre-Z Pass 尽可能以低的成本生成 Hi-Z Buffer
  - 《刺客信条大革命》的 GPU-Driven Rendering Pipelines 论文里的做法
    + 一方面，利用美术标记启发式算法找到那些又大离相机又近的 $300$ 个 occluder，downsample 到 $512 times 256$ 的分辨率上。但会有一些选择错误 (large moving objects) 或未通过 alpha-test 的 occluder 需要被 reject，产生 holes
    + 另一方面，借用时序信息，把上一帧的 (Hi-)Z Buffer reproject 到当前帧。但是当相机移动速度过快，也会产生 holes
    - 两种方法结合起来，互相补洞，达到比较好的效果，当然极端情况也会出问题
  - 后来又有另外一个被育碧收购的团队提出了 Two-Phase Occlusion Culling 的改进
    + $first$ phase: 使用上一帧的 Hi-Z 对当前帧的 objects & clusters 做 cull，得到保守但已经筛掉很多的估计
    + $second$ phase: 用生成新的 Hi-Z 再去测一遍 $first$ phase 中当前帧没有通过的 objects & clusters，一些新的物体又可见了
    - 第一阶段的结果可能会产生很多 holes，在第二阶段一定会被填上（因此能确保结果是正确的，大不了少剔除一些）
  #grid(
    columns: (35%, 65%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-25-12-17-04.png", width: 80%),
    fig("/public/assets/CG/GAMES104/2025-04-25-12-18-59.png", width: 80%)
  )
- *Occlusion Culling for Shadow*
  - 游戏中 shadow map 的渲染往往能占到近五分之一的时间开销
    + 它只和几何复杂度有关，意味着材质上的简化对其没有任何效果
    + shadow map 的精度需要跟主视角下几何精度一致（往往通过 cascaded 达成），否则会出现各种 artifacts
    + cascaded shadow map 的覆盖范围可能是方圆几平方公里的整个场景，如果不做任何优化非常要命
  - 为此 shadow map 也需要做 culling，其基本思想跟 camera culling 一致，同样可以针对光源的移动、场景的移动复用时序信息剔除。但针对 shadow，如果利用上 camera 的深度信息可以避免更多 case
    - 毕竟本身 shadow map 就是在跟相机深度做比较，这也是很自然的思路。例如右上图中#redt[红色方块]，在光源视角下深度最浅，无论如何都不会被剔除，但因其在 camera 下不可见，也能被剔除
  - 基本思想是，对每个 cascade，产生 $64 times 64$ pixels 的 camera depth reprojection 信息，与上一帧的 shadow depth reprojection 信息相结合，再产生 Hi-Z Buffer 做 GPU Culling
  - Camera Depth Reprojection
    - 对相机深度如何重投影回光空间做个解释：将相机的深度图均分为等大的 tile ($16 times 16$ pixels)，每个 tile 选择最近的深度作为 $z$ 值，结合 tile 四角顶点的 $x, y$ 坐标得到相机空间下的四个顶点。每四个顶点跟在相机近平面的映射点相连，得到一个个 #yellowt[yellow cube / frustum]
    - 在 light view 下渲染这些锥体，记录其最远距离（图中的#greent[绿色块]），任何比它们还远的物体都被剔除
  - 这两部分的 culling (camera / shadow) 可以参考 #link("https://zhuanlan.zhihu.com/p/416731287")[Hierarchical Z-Buffer Occlusion Culling 到底该怎么做？]
- *Visibility Buffer*
  - 这部分的基础介绍放在之前的渲染管线 part

== Virtual Geometry - Nanite
Nanite 是 UE 跟 Lumen 并列的另一个重要技术，主要用于处理复杂的几何体。它的核心思想如标题所言就是 Virtual Geometry，把几何体的细节信息存储在一个虚拟的几何表示中，允许我们在渲染时动态地加载和卸载这些细节信息，从而实现高效的渲染。

我们的梦想是把 Geometry 做成跟 Virtual Texture 一样，在没有额外开销的情况下 (Poly count, Draw calls, Memory...) 使用任意精度的几何，达到 filmic quality 的效果。但现实是，Geometry 不仅仅是 virtual texture 那样的 memory management 问题，它的 detail 直接影响 rendering cost；另外，mesh 的表达是 irregular 且不连续的，不能像 texture 那样做 filtering。

=== Geometry Representation
- Choice of Geometry Representation
  - *Voxel*
    - Spatially uniform 的表达，但想要达到高精度对存储要求非常高（即使用 octree 优化），而且一旦上了 octree 就会使得 filtering 变得复杂（丢了原本的优势）
    - 并且对 artist 工作管线的颠覆也限制了它的使用
  - *Subdivision Surface*
    - 硬件上猛推的技术，如 geometry shader, mesh shader 等，能够有效地产生精细的几何
    - 但在定义上，它只是 amplification，而不能化简；而且有时候会产生过多的 triangles
  - *Maps-based Method*
    - 诸如 displacement map 等的方法能够在 coarse mesh 上增加很多几何，尤其对于已经均匀采样过的 organic surfaces 表现良好，但难以表达 hard surface。另外，从一个已有的精细几何生成 displacement map 也还是需要一定运算的
    - 但这一块还是有一定 debate 的，NVIDIA 还是在猛推 Micro-Mesh 的做法，基于 GPU 自动（用 displacement map 等技术）把几何加密，还可以做 ray tracing。目前这仍然是一个还未决出胜负的领域
  - *Point Clouds*
    - 基于 splatting 的点云绘制方法可能还有大量 overdraw，如何 aplly uv texture 也是一个大问题。以及点云需要 hole filling
    - By the way，感觉这些也是现在 3DGS 方法的硬伤之一，以前我还对这方向挺有信心的来着（
  - 最终 Nanite 选择了 triangle 这一最成熟的表达方式

几何的划分可以无限增加，但我们希望最终绘制的三角形数量不要无限爆炸，而这是合理的，因为屏幕像素数有限。换句话说，我们希望用屏幕精度决定 geometry caching 的精度，这也是 Nanite 最核心的思想。

- *Nanite Triangle Cluster*
  - 与 Assassin's Creed 类似，Nanite 把 mesh 划分为 cluster，大小是 $128$ triangles
  - 不同点在于，Nanite 可以在每个 instance 内自适应地进行 view-dependent LoD 切换（而不是每个 instance 固定 LoD level），在相同的 view 下几乎只用 $1\/30$ 的开销就能达到每个 pixel 都有一个 triangle 的精度
  #grid(
    columns: (29%, 71%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-09-07.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-11-52.png")
  )
- *Naïve Solution - Cluster LoD Hierarchy*
  - 用一个树状结构建立 cluster hierarchy，每个 parent 是其 children 的简化版本。还可以跟 streaming 相结合，一开始只加载 core geometry，需要时加载更精细的 cluster (just like virtual texture)
  - 每次简化能算出 perceptual difference 或者叫 error，根据 error 选择 view dependent cut
  - 但是简化无法保证 water-tight，会形成 cracks。这类问题最基本的方案是 lock boundaries，但会导致锁住的边永远过于精细，不仅面片简化的效果不好 (number beyond $128$ within a cluster)，而且这种 frequency change 会导致 artifacts
  #grid(
    columns: (25%, 19%, 20%, 28%),
    column-gutter: 6pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-15-35.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-26.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-09.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-42.png")
  )
- *Nanite Solution - Cluster Group*
  - 将 cluster 组合成 group，例如 $16$ 个 cluster 为一组，以 group 为单位进行 LoD 切换（强制 group 内的所有 cluster 采用同个 LoD）。这样的好处在于粒度更粗，只会锁 group 的边，而 inner clusters 可以自由简化（换句话说，锁住的边占比减小了）
  - 而更大的好处在于，经过简化后的 group 可以打散之后重新 group，这样*新生成的 group 的 boundry 跟原来的 boundry 可以是错开的*，从而将锁边导致的局部过密影响分散开来（想想看，这是不是跟采样时加 jitter 的思路很像？）
  - 从图中也可以看到：
    + group 内简化一次后，又重新 split 为 $128$ (simplified) triangles，得到全新的 cluster 划分。而*这些 cluster 所对应的子节点并不由其父节点独享*，形成 DAG 结构 (not tree)
    + 当新 cluster 重新组合为 group 时，能够越过原来的 boundary，形成新的 boundary
    - 这样形成了乱中有序的结构，低层级到更高层级的连接可能是 multiple-to-multiple 的关系，但又只会跟简化后有关联的 cluster 进行连接 (localized)
  #grid(
    columns: (40%, 49%, 11.5%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-35-52.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-38-53.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-36-52.png")
  )
  - 以 Bunny 为例，这样的 DAG 划分与维护能够避免局部过密，形成非常自然的简化
    #grid(
      columns: (50%, 50%),
      column-gutter: 2em,
      fig("/public/assets/CG/GAMES104/2025-04-26-11-21-04.png"),
      fig("/public/assets/CG/GAMES104/2025-04-26-11-20-14.png")
    )

=== Runtime LoD Selection
通过以上的 cluster group 划分，最终会形成只有一个根节点的 tree-like DAG 结构，现在问题转化为如何在运行时选择 LoD。

每个 node 和其所对应的更细的 LoD level 代表 two submeshes with same boundary。选择的依据是 screen-space error，计算简化前后投影到屏幕上的 distance and angle distortion，DAG 中的每个 node 都会有一个 error 值。

- *LOD Selection in Parallel*
  - group 的划分已经比 cluster 更快，但在这样精细的结构下依然复杂。一个 group 内的所有 cluster 选取相同 LoD，如何实现这一点？直接 traverse 或依赖 communication 都会很慢，因此我们的想法是把整个 DAG 拍平成 array，对每个 cluster 孤立地、并行地处理 (*Isolated LoD Selection* for each cluster group)
    - 实际上是以 cluster group 为执行单位，但会对每个 cluster 分别做处理
  - error 的设计需要满足 deterministic (same input $=>$ same output)，否则仅仅只是因为并行提交的顺序不同就会导致 LoD 选择不一致，产生 Z-Fighting 等问题
    - 最基本的要求便是 error 必须是单调的 (monotonic): $"parent view error" >= "child view error"$
    - 需要仔细实现使得 runtime correction 也是单调的
    - 源自于 child level 中相同 cluster 的两个 cluster，即使分属于不同 group ，也要保证它们的 error 相同（如下图橘色和紫色节点）
  - 具体而言，每个节点只需要额外记录 $"parent view error"$，然后用这两个准则决定绘制 / 剔除
    ```
    Render: ParentError > threshold && ClusterError <= threshold
    Cull: ParentError <= threshold || ClusterError > threshold
    ```
    - 换句话说，我只决定自己需要需要绘制。若我被剔除，是否需要绘制子节点的决策与我无关（但因为 error 的设计最终一定会有子节点补上）
  #grid(
    columns: (45%, 54%),
    column-gutter: 8pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-15-16-00.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-15-21-06.png")
  )
- *BVH Acceleration*
  - 虽然拍平成 array 能有效提升并行度，但毕竟 cluster groups 还是太多，为此构建 BVH 结构进行加速（通过另外构建的 BVH 结构避免 array 中大量的无效遍历）。这一点在原作者的 presentation 中一笔带过，但实际上有将近 $20$ 倍的加速
  - 每个节点存储子节点 $"ParentError"$ 的最大值，internal node 存储 $4$ 个 children nodes（尽可能构建张度为 $4$ 的平衡树），leaf node 存储 cluster group 的 list
  #q[评论区：严格来说，BVH 中叶节点挂的也并不是 ClusterGroup，而是 Group 分成的Part，这里讲成 ClusterGroup 也更容易理解，Part 这种算是实现上的细节。切分的目的是为了 Page Streaming，如果有 ClusterGroup 跨页了就会切]
  - Hierarchical Culling & Persistent Threads
    - 原作者大谈特谈的 part，但感觉相比 BVH 构建本身只能算是实现上的 trick
    - 如果用传统 BVH 的遍历方法，每次 dispatch 把当前 level 扫一遍产生新的子节点，丢到下一次 dispatch 中去。但是 level 之间形成 Wait for idle 关系，且 level 较深的 dispatch 变为 empty，总之就是非常慢
    - 于是采用类似 job system 的方式，把 working threads 固定下来，用 multi-producer multi-consumer (MPMC) 的结构，任何时候产生的子节点直接 append 到 job-queue 的后方，而 threads 不断从前方 pop 任务执行（实际上是一个非常简单的数据结构，但依赖于 GPU compute shader 的发展，实现 shared pool, atomic lock）

=== Nanite Rasterization
Nanite 自定义了一套 rasterization 方法，来应对当几何精细到近乎等同于像素情况下新的挑战。

- *Nanite V-Buffer Layout*
  - Nanite 的 Visibility Buffer 为一张 `R32G32_UINT` 的贴图，人为把 depth 写在最高位（需要 `InterlockedMax` 操作确保原子性），手动实现 (software) Z-Test
  - 个人理解这里 Z-Test 的意思是说，并非单开一个 pass 做 Pre-Z pass，而是把它融入到了软光栅化器中
  #csvtbl(```
  32, 25, 7
  Depth, Visible cluster index, Triangle index
  ```)
- *Weakness of Hardware Rasterization —— Quad Overdraw*
  - Quad Overdraw 的问题来自 GPU 硬件的处理：GPU 以 $2 times 2$ 的最小粒度进行像素处理（以便能够通过 uv 计算出 mipmap 等级，i.e. `ddx`, `ddy`），即使只有其中一个像素需要着色，也要将整个 $2 times 2$ block 调度为活跃线程并执行片元着色
  - 在最坏情形下，$4$ 个像素分属于 $4$ 个三角形，Forward 为每个像素运行材质采样和光照计算 $4$ 次；Deferred 为每个像素运行材质采样 $4$ 次、光照计算 $1$ 次；而 Visibility 的材质采样和光照计算为每个像素均只运行 $1$ 次，因为可以在重计算 barycentrics (screen space) 时算出 mip-level。对于 Nanite，这种 “最坏” 情况非常普遍
  - V-Buffer 原论文并没有这一点，众多讲解 V-Buffer 的文章也没有提到，应该是后来才被发现的妙用？可以参考这篇博客 #link("http://filmicworlds.com/blog/visibility-buffer-rendering-with-material-graphs/")[Visibility Buffer Rendering with Material Graphs] 或者它的译文 #link("https://www.piccoloengine.com/topic/310642")[Nanite核心基础- Visibility Buffer Rendering（翻译）]
- *Weakness of Hardware Rasterization —— Scanline*
  - 回忆硬件光栅化，会采用 scanline 算法，逐行扫描将三角形细化为一个个像素（以及各个属性的插值），实际中还会把屏幕划分为 $4 times 4$ 的 tile 进行加速 (separate to $4 times 4$ micro tiles, output $2 times 2$ pixel quads)
  - 但是面对 Nanite 这种几何精细到近乎等同于像素的情况，基于扫描线算法的光栅化就变得非常低效，加上前面说的 Quad Overdraw 的问题就更费
  #grid(
    columns: (31%, 17%, 52%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-24-22-31-49.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-23-06-49.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-23-06-07.png")

  )
- *Software Rasterization*
    - 为此 Nanite 提出了自己的 Software Rasterization 方法，与 Hardware Rasterization 配合使用，右上图中，#bluet[蓝]为 SW、#redt[红]为 HW
    - Nanite 以 cluster 为粒度进行 software / hardware 的选择，由于 Nanite 知道 cluster 的边、面积等信息，可以算出所占 pixels 数量，当大于 $18$ 时采用硬件光栅化，否则采用软件光栅化。具体做法是，通过 compute shader 的通用计算能力，自行插值出每个像素的信息、重建 `ddx` `ddy` 信息、自行实现 Z-Test……
  - 当然 NVIDIA, AMD 看到这种趋势肯定会坐不住的，未来把这种操纵搬到硬件上原生支持几乎是板上钉钉 (NVIDIA Micro-Mesh?)
    - 这也体现出一种发展范式：软件灵活探索新的想法，之后硬件再进行固化

当然，Nanite 作为基于 visibility buffer 的实现，最后还是先渲染到 G-Buffer，跟传统 Deferred Rendering 结合。毕竟 Nanite 虽然精细，但还是有很多限制，比如不支持带有骨骼动画、材质中包含顶点变换或者 Mask 的模型（目前大部分 mesh 还是基于传统 pipeline 的）。

- *Imposters for Tiny Instances*
  - 传统 LoD 的经典做法，在现代高级几何管线中还是有实战用处（虽然也随时有可能被替换为更新的技术）。
  - 模糊方向量化，在 atlas 上存储 $12 times 12$ view directions，用 octahedral map 做映射
  - 每个方向使用 $12 times 12$ pixels 表达，同样使用 octahedral map 做映射，存储 $8 bit$ Depth, $8 bit$ TriangleID
  - 从 instance culling pass 直接画到 G-Buffer，不经过复杂的 Nanite 管线

- *Rasterizer Overdraw*
  - 不使用 per triangle culling，也不使用 hardware Hi-Z culling pixels
  - 使用基于上一帧的 software HZB，剔除 clusters 而不是 pixels，其分辨率取决于 cluster screen size
  - 依然会有大量 overdraws，来自：
    - Large clusters
    - Overlapping clusters
    - Aggregates（小三角形堆叠到同一像素）
    - Fast motion
  - Overdraw 对不同大小的 triangle 的影响不同
    - Small triangles: Vertex transform and triangle setup bound
    - Medium triangles: Pixel coverage test bound
    - Large triangles: Atomic bound

=== Nanite Deferred Material
前面介绍过 Visibility Buffer 的原理，在着色计算阶段的一种实现是维护一个全局材质表（存储材质参数以及相关贴图的索引），根据每个像素的 MaterialID 找到对应材质并解析，利用 Virtual Texture 等方案获取对应数据。对于简单的材质系统这是可行的，但是 UE 包含了一套极其复杂的材质系统，每种材质有不同的 Shading Model，同种 Shading Model 下各个材质参数还可以通过材质编辑器进行复杂的连线计算……简单来说，Nanite 想要支持完全由 artist 创建的 fragment shader。

为了保证每种材质的 shader code 仍然能基于材质编辑器动态生成，每种材质的 fragment shader 至少要执行一次，这样复杂的材质系统显然无法用上述方案实现。Nanite 的材质 shader 是在 Screen Space 执行的，以此将可见性计算和材质参数计算解耦，这也是 Deferred Material 名字的由来。

- *Material Classify*
  - Nanite 为每种材质赋予一个唯一的 material depth，每个材质都用一个 full screen quad 去绘制，深度检测函数采用 “等于通过”
  - 早期 Nanite 就是这么做的，看起来很费但实际上只会对真正耗时的着色进行屏幕像素数量次，大部分的绘制被深度检测跳过。但是当场景中的材质动辄成千上万，其带宽压力 (so unnecessary drawing instructions) 还是很大
  - 想要避免全屏渲染，很自然的思路就是引入 *tile-based* 方案，从而可以用 compute shader 扫一遍产生 Material Tile Remap Table
    - 根据屏幕分辨率决定 tile 数量，每 $32$ 个 tile 打包成一组，`MaterialRemapCount` 表示组的数量
    - 每个 tile 内用每个 bit 来记录 material 的存在性，每个 material 可以在绘制时跳过不包含它的 tile
    #tbl(
      columns: 7,
      bdiagbox[Tile Group][Material Slot],[0],[1],[2],[3],[...],[`MaterialRemapCount` - 1],
      [0],[\<32 bits\>],[],[],[],[],[],
      [1],[],[],[],[],[],[],
      [...],[],[],[],[],[],[],
      [`MaterialSlotCount` - 1],[],[],[],[],[],[]
    )
  - future work: 跟 virtual texture 结合，进一步减少材质的带宽压力

=== Nanite Shadows
Lumen 在做 GI 主要处理的是低频的间接光照，所以可以用 low-res 的 screen space probe 作为光照的代理；但 Nanite 作为一个精细几何的表达，其阴影将会十分高频（阴影比光照高频，这也是为什么 UE 里让二者协同工作）。

并且，Nanite 作为如此复杂的几何表达，硬件上的 Ray Trace 是无法处理的，因此我们还是诉诸于传统而广泛的 Cascaded Shadow Map，看能否将其一步步改造为 Nanite 所用方法。

- *Cascaded Shadow Map*
  - 试图通过远近分辨率的调整来控制 shadow map 中一个 texel 对应光空间区域的大小 (vie dependent sampling)
  - 属于相对 coarse 的 LoD 控制，如果想要达到较高的阴影质量需要显著的存储开销
  #grid(
    columns: (30%, 68%),
    column-gutter: 2em,
    fig("/public/assets/CG/GAMES104/2025-04-26-19-46-24.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-19-45-55.png")
  )
- *Sample Distribution Shadow Maps*
  - CSM 实际上很多地方是无效的（尤其是远处的区域），浪费大量的 resolution，Sample Distribution Shadow Maps 试图通过分析屏幕像素深度的范围，提供更佳的覆盖
  - 当我们这样想的时候，实际上也揭示了 shadow map 的本质：*根据相机视空间的精度去采样光空间*。shadow map 的 alias 也正是因为*相机空间对几何的采样跟几何在光空间对光的可见性采样频率不同*；shadow map 需要加 bias 也正是因为这个采样很不准确，需要加上一点容错
  - 不过，Sample Distribution Shadow Maps对于 LoD 的控制依旧比较粗糙
- *Virtual Shadow Map*
  - 在这些思想基础上更进一步，是对采样问题的本质解决（非常 elegant，很有可能是取代 CSM 的未来主流方案）
  - 把相机视空间划分为 clipmaps，每个 clipmap 划分一块 shadow map
    - 但 shadow map 的精度不是根据 world space 的大小决定，而是根据在 view space 占据像素数量决定，同样完成了根据相机视空间大小分配精度的目的
    - 并且 clipmap 的很大一个好处在于，一旦构建完毕，当光不变、相机移动时，只有部分区域需要更新（尤其对于不动的主光而言非常高效）
  - Nanite 为每一个光源分配了 $16k times 16k$ 的 virtual shadow map，不同的 light type 有不同的划分
  #grid(
    columns: (50%, 50%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-20-01-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-20-01-58.png")
  )
  - tile 划分？Shadow Page Table and Physical Pages Pool？这里感觉完全没讲清楚，以后再来看吧

=== Streaming and Compression
#grid(
  columns: (60%, 35%),
  column-gutter: 2em,
  [
    这部分又是原作者大谈特谈的部分，但王希老师认为实际上是比较自然的细节。

    当我们构建好几何表示和 BVH 结构后，根据 page 的划分和类似 virtual texture 一样随用随加载的方式就很自然了，从而可以构建开放世界的 streaming。

    另外 Nanite 这样精细的几何表达必然开销很大，那么进行压缩也是非常自然的。包括使用定点数等方法 (quantization)，以及对于 Disk Representation 使用 LZ decompression 等等非常多的细节。
  ],
  fig("/public/assets/CG/GAMES104/2025-04-26-20-04-34.png")
)

- 额外参考资料
  + #link("https://zhuanlan.zhihu.com/p/382687738")[UE5渲染技术简介：Nanite篇]