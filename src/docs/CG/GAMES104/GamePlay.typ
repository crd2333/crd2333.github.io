---
order: 7
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
#counter(heading).update(14)

= 游戏引擎的玩法系统基础
- Challenges in GamePlay
  + 玩法系统要和 Animation, Effect, UI, Audio, Interface Devices 等多个系统共同协作，因此岗位涉及面非常广泛（杂学）
  + 游戏类型多样化，即使是同一个游戏也有很多玩法（扩展性），网游在这一方面更新、堆料更甚
  + 玩法系统的迭代极快，比引擎渲染等系统快得多，往往在设计总监提出需求后，马上就要出 demo，一两个月内就要迭代一个版本

== Event Mechanism 事件机制
GameObject 需要相互交互，这种机制如果都用 ifelse 写死实现，未免太过复杂，一般都用 Event / Message Mechanism 实现。

- *Publish-subscribe Pattern 发布-订阅模式*
  - 不同的发布者 (publishers) 发送不同类型的事件给事件调度者 (event dispatcher)
  - event dispatcher 把事件告诉对应的订阅者 (subscribers)，做出相应的动作 (callback)，注意订阅者不知道发布者是谁
  - 该模式的三个关键点为：Event Definition, Callback Registration, Event Dispatching
- *Event Definition*
  - Event Type + Event Argument
  - Event 可以使用基类继承出不同的类型，但还是那个问题，策划需求千变万化，因此需要支持 editable 并且 可视化在 editor 中（回忆 Code Rendering 的做法）
  - 但不断加入新的事件类型都会导致引擎重新编译，这时常见的做法有
    + 将新事件新编译成的 C++ 代码做成 DLL，runtime 注入到系统中（UE 的做法）
    + 上层采用 C\# 语言，方便动态挂接和扩展
    + 用脚本语言如 lua
- *Callback Registration*
  - 说是回调其实就是触发 (invoke)，概念本身很好理解。但在游戏引擎中，回调函数的注册和触发有一个时间差，在这段时间发生的意外（如订阅者被销毁）可能导致奇奇怪怪的行为 —— 回调函数的安全性跟对象的生命周期强相关
  - 可以用 C++ 类似智能指针的技术解决
    + 强引用：订阅者在有事件注册时不能销毁。可能导致系统内存越来越大，一般较少使用
    + 弱引用：在执行回调函数前，判断订阅者是否存在，若不存在则注销回调函数，比较简单高效，一般用得更多
    - 二者都非常重要，需要灵活使用
- *Event Dispatching*
  - Trivial Dispatching: 把所有的消息从头到尾扫一遍，依次遍历所有 GO 看是否有相应函数，但不管是时间还是空间的复杂度都过高
  - Immediate Dispatching
    - 事件发生时打断父函数的执行，马上触发回调函数，但有这些问题：
      + Deep well of callbacks: 比如炸弹的连环爆炸，产生极深的调用栈
      + Blocked by function: 一个事件引发了一系列事件，其中有某个耗时极高，后面的都被堵塞，导致突然掉帧
      + Difficult for parallelization: 顺序触发导致相互之间有依赖关系，难以并行
  - Event Queue Dispatching
    - 把事件存储到 Queue 中，下一帧统一处理；同时未来跨进程、跨网络处理的需要，将事件序列化到一个 Event Buffer 中，用的时候再反序列化（涉及反射）
    - 具体实现
      + 使用环形队列组织的 Ring Buffer 管理内存。不仅只用申请一次并反复重用；而且当 head 和 tail 重合（队列满，一般说明出 bug 了）时，可以直接截断从而只错误几帧数据而不会直接崩溃
      + 使用 Batching 分批管理，用单独的 dispatcher 和 buffer。对 locality 更友好，且 debug 也更方便
    - 问题
      + Timeline not determined
        - 比如先动画后物理等消息执行的顺序无法保证，所以为了保持鲁棒性，需要做非常精细的处理，同时也是 bug 高发地（对程序员尚且如此，设计师更是难以理解）
        - 因此允许部分 event 依旧是 hardcode 或密集处理的，还需要引擎支持 PreTick, ImmediateTick, PostTick 操作
      + one-frame delays
        - 设计上天然导致了至少一帧的误差，及时性差（比如战斗打击感，第一帧受击，第二帧扣血并积累异常值，第三帧才触发爆血特效，几帧的差异那些动作天尊触手怪们是能感受出来的）
        - 因此在需要及时性的地方，可能需要一些 hardcode 专门处理
  - Event 系统中是否需要考虑 Priority？一般来说如果事件系统的正确性依赖于顺序，会导致 Publish-subscribe Pattern 两边的耦合性过强，另外也不方便并行化执行，因此尽量不要为事件预设优先级

== Game Logic and Scripting Languages 游戏逻辑与脚本系统
- 早期游戏逻辑可以直接写死在 c++ 里，而且效率可能更高，但这样不可持续，因为
  + 每次对游戏逻辑进行修改都要重新编译
  + 遇到错误代码时，很容易导致程序崩溃
  + 已发布游戏遇到 bug 时，难以进行热更新（打一个补丁就解决）
  + 玩法基本由设计师负责，他们不会写代码
- *Scripting Languages 脚本语言*
  - 工作机制：先被编译为 bytecode，再到虚拟机上运行
  - 优点
    + 可以快速迭代
    + 好学易上手，即使是策划也能将一些玩法用脚本实现
    + 热更新方便（热更新的本质就是用替换指针为新的实现，当然若函数中用到全局变量需要重置）
    + 运行在虚拟机沙盒上，可以自己 crash（立马重启脚本重新接入）而不会导致引擎 crash，更稳定
  - 缺点
    + 慢，但可以用 Just In Time (JIT) 优化，一边解释一边编译（一般会认为这种方式肯定比不过静态编译，但实际上 JIT 可以知道代码执行的路径，做得好甚至能比静态编译更快）
    + 弱类型语言在反射时不方便，可能需要看结果推测类型，效率低
  - 游戏引擎中比较受欢迎的脚本语言有 Lua, JavaScript 等，Lua 可能是最流行的（魔兽世界一己之力带火其在网游中的应用）。还有一些好像不算脚本语言但也是虚拟机运行且有很多库、使用方便的编程语言如 C\#， Python 也有一定应用
- *脚本语言的 GO 管理*
  - 脚本语言和引擎之间最难的问题就是对象生命周期的管理，到底是由引擎管理还是由脚本管理？
  - 引擎管理
    - 需要引擎对生命周期管理更严谨，否则内存泄露产生严重后果（尤其是 Cpp 写的），脚本访问对象时需要判断是否存在
    - 但是当玩法越发复杂时（比如突然创建出几个对象），在脚本中创建更方便而不是一定要到引擎里绕一圈
  - 脚本管理
    - 将 GO 的生命周期完全交给脚本负责，脚本创建 Garbage Collection (GC) 机制自动管理
    - 省事但慢，甚至吃掉 $10%$ 时间
  - 各有利弊，一般大型单机都是引擎直接管理，而玩法复杂的比如 MMORPG 一般用脚本管理
- *Architectures for Scripting System 脚本语言的架构*
  + 引擎包脚本：以引擎为主体控制 tick 的 flow，把某段特定处理写成脚本来调用
  + 脚本包引擎：主要玩法写脚本里，把引擎当成 SDK 库提供各种服务（现在用的少）

== Visual Scripting 可视化脚本
UE 的蓝图，Unity 的 Visual Scripting, Shader Graph 都是可视化脚本，这种形式对艺术家友好、符合他们的直觉，并且可视化更不容易产生错误（debug 非常方便）。

- Program Language 的概念与 BluePrint 的对应：
  + Variable: 每个变量有自己的 type 和 scope，在可视化脚本中用不同颜色的 pins 来指示类型，颜色相同才能用 wires 相连
  + Statement and Expression: 用专门的 expression nodes 和 statement nodes
  + Control Flow: 用 execution pins 和 execution wires 表示控制流
  + Function: 把一整个 Graph 打包成一个 node
  + Class: blueprint 本身就是一个类
- 可视化脚本的问题
  - 可视化脚本很难合并，会丧失语义且效率低下
  - 画 graph 的人之外很难理解（非线性网状的弊端），可读性差
- 可视化脚本就是脚本
  - 鉴于之前提到的问题，很多团队前期用可视化脚本，成熟后会翻译为代码

== Gameplay 中的 3C
3C 系统，Character, Control, Camera，是游戏体验的核心。要了解什么是 3C 系统，《双人成行》可以作为最好的案例。

- *Character*
  - 移动：在之前所讲的动画混合之外，真正实现起来要考虑非常多的细节打磨（障碍、上下坡、起步、停下、滑行、滑冰、飞行……）
  - 与环境互动：雪地系统、音效、粒子等等
  - 真实物理互动：既要考虑人为控制又要考虑物理输入，一般用状态机控制各种状态，总之是大量的 animation script / graph 与 logic script / graph 结合的结果
- *Control*
  - 输入设备控制：鼠标键盘、手柄、方向盘、VR 设备等，甚至是手势识别、脑机接口
  - 操作优化：自动吸附、辅助瞄准、调整相机
  - Feedback: 振动或力反馈，键鼠 RGB 勉强也算
  - 按键组合：Context Awareness（同一输入在不同情景下效果不同）, Chord（同一时间的输入给予唯一行为）, Key Sequences（考虑历史输入打出组合）
- *Camera*
  - 相机并不只是完全固定在角色身后，而是随着角色跑动、走动等状态变化，相机远近大小焦距都跟着变化；有时又要放开相机的控制
  - Spring Arm: 当靠近墙时，保证相机不穿墙（有时又想要穿墙但降低透明度）
  - 相机效果：抖动、滤镜、各种后处理
  - 视角变化：第一第三人称切换、武器不同变化、载具不同变化，变化过程还需要插值
  - Subjective Feelings: 综合运用这些效果实现身临其境感、电影感，Camera 系统是一个性价比非常高的系统

= 游戏引擎的玩法系统：基础 AI
== Navigation 寻路系统
- 导航的基本思路
  + Map Representation
  + Path Finding
  + Path Smoothing

=== Map Representation
- *Walkable Area*
  - 让 AI 知道哪些部分可以通过，要考虑物理碰撞和走、跳、攀爬、载具等多种情况
  - 其表达方式有 Waypoint Network, Grid, Navigation Mesh, Sparse Voxel Octree 等。每种方式都有其优缺点，经常使用多种方式结合
- *Waypoint Network*
  - 早期游戏引擎使用很多，如同地铁一样，通过设置关键点、walkable area 的边界点以及算法插值出的中间点形成网状结构
  - 非常类似与地铁，寻路时有限找到最近的点，之后沿着路网抵达目标
  - 优点是好实现、效率高，缺点是不方便动态更新以及对 walkable area 的利用效率低（总走路中间）
- *Grid*
  - 对地图上的每个三角都转化成小网格，类似光栅化
  - 优点是便于动态更新、好实现、方便 debug，缺点是精确度取决于分辨率（过细还容易降低寻路算法性能）、存储空间浪费、难以表达三维地图
- *Navigation Mesh (NavMesh)*
  - 把 walkable area 用 convex polygon 或 triangle 表达出来，相对 Waypoint Network 的点线表达变成面的表达，并且解决 grid 难以表达三维层叠结构的问题
    - polygon 比 triangle 好处在于避免拉出细长的三角形，利用效率更高
    - 但要求每个 polygon 是 convex 的，否则进出同一个 polygon 可能会走出 walkable area；另一个好处在于每两个 convex polygon 之间的边 (Portal) 是唯一的
  - 优点是支持 3D、精确、快速、灵活、动态，因此是现代游戏引擎最普遍的方法；缺点是生成算法复杂，并且只能表达贴地寻路而无法表达飞行等情况
  - *NavMesh 的生成*
    - NavMesh 的生成其实比较困难，早期会让设计师手动拉出来，但现在基本是用开源库如 Recast 自动生成，之后再细调
    - 另外 Generation 不能继承之前的和设计师手调的结果，有任何更新都要重新做，也是一个很大的缺陷
    + Voxelize 成体素网格，然后标记出 walkable 的体素（通过坡度等计算）
    + 用 edge detection 方法找到离边缘最近的 edge voxel，得到 distance field
    + 找到局部的距离边缘最远的 voxel，使用洪水算法 (Watershed Algorithm) 向外扩散，类似之前讲过的 Voronoi 算法，得到对空间的划分
      - 这里实际上还有很多的细节，比如不允许 2D view 上 region overlapping，同一个 region 蔓延到自身底下时要截断等。这里不做过多展开
      - 2, 3 这两步合称为 Region Segmentation
    + 再通过进一步处理（比如连通区域变为凸多边形之类，比较复杂），就生成我们想要的 NavMesh
  - *Advanced Features*
    - Polygon Flag: 通过打标签的方式标记不同地形，从而可以控制寻路的优先级与可通过性、控制走上去的生效和粒子效果
    - Tile: 前面说了 NavMesh 的生成对动态变化不友好，可以通过地图分块的方式缓解这一问题。当然这里还有一些细节比如 tileSize 的考量、不同 tile 内生成的 NavMesh 要连接对齐等
    - Off-mesh Link: 允许建立手动的连接点，比如梯子攀爬（坡度过高会被 NavMesh 认为不可通过）、钩锁滑行等
- *Sparse Voxel Octree*
  - 把空间划分为八叉树体素，相当于把 grid 3D 化并做了八叉树优化，但存储消耗大的缺点依旧存在，另外它虽然生成比较方便但寻路比较麻烦。主要用于航天航空游戏

=== Path Finding
- 以上无论哪种方式都可以把几何元素的重心作为节点，生成边和权重，从而转化为在 graph 上的（近似）最短路径问题
- *经典算法*
  - Depth-First Search，时间换空间；Breadth-First Search，空间换时间
  - 但这两种方式都开销巨大，并且不能计算加权最短路径
- *Dijkstra Algorithm*
  - 可以解决有权图中最短路径问题，具体过程从略
  - 但游戏很多时候不需要最优而是近似即可（甚至最优反而不真实），因此一个启发式算法更符合直觉，引入 A-Star 算法
- *A-Star Algorithm*
  - 在 Dijkstra 的基础上，加入了启发式函数 (Heuristic Function)，即对每个节点除了从起点到此的准确代价外，再计算一个估计值（到目标的距离），从而加速搜索
    $ f(n) = g(n) + h(n) $
    - $h(n)$ 的选取比较讲究，要满足一些性质等等，一般越高越快收敛，越低越容易继续找到最短路径，这里从略
  - A\* on NavMesh
    - NavMesh 的 $g(n)$ 如何计算？如果直接把每个 polygon 的 centers 或 vertices 相连，可能会高估代价，采用 hybrid 方法又会导致过多 nodes。一般用 portal 的中心是一个比较好的 balance
    - NavMesh 的 $h(n)$ 如何计算？直接用粗暴的直线相连（取了个高大上的欧拉距离的名字）
  - A\* 的效率远远超过经典准确算法，而且游戏里有障碍物的情况其实不多，粗暴的启发式算法也能达到很好的效果

=== Path Smoothing
不管是 Waypoint Network, Grid 还是 NavMesh，直接得到的路径都是 zigzag 的，充满不必要的转弯，因此我们需要平滑化处理。对 NavMesh 可以使用 "String Pulling" – Funnel Algorithm

- *Funnel Algorithm 烟囱算法*
  - 实际上已经非常类似于人走路时对道路的感知，比较难以用语言描述，不如看图，以 2D 为例（推广到 3D 会更复杂）
  + 从起始点，把当前 polygon 的两端作为视野，看向下一个 polygon，如果被视野覆盖就看向下一个 polygon 并更新视野（以新的 polygon 的两端为视野）
  + 直到某个 polygon 被部分遮挡时，左边被挡就沿左视野走，右边被挡就沿右视野走，直到到达被卡视野的 polygon 的端点，重复进行上述过程
  + 如果迭代过程中发现终点就在视野里就直接走向终点
  #fig("/public/assets/CG/GAMES104/2025-04-06-12-47-40.png", width: 80%)
  #fig("/public/assets/CG/GAMES104/2025-04-06-12-47-51.png", width: 55%)

== Steering 转向系统
寻路系统以点、线为考量做出相对合理的路径规划，但对实际物体如载具，需要考虑它们本身的体积和不同的移动能力（油门、刹车、转向、加速度）等，需要对动作进一步调整以显得 Reasonable。

早期游戏中特别对载具相关的 NPC，它可能寻路系统严格遵守了 walkable area，但因为加入了更符合物理实际的 Steering 系统而走到了没有规划过的区域（寻路失效），如果物理模拟 tick 的步长再大那么一点，可能就卡在那一区域来回转动、抖动，进而被玩家玩弄。

- *Steering Behaviors*
  - Seek / Flee
    - 追踪移动目标或逃离目标，速度与加速度的调整，可能还会绕着目标震荡
    - 输入自身位置与目标位置，输出加速度
    - Seek / Flee Variations: Pursue, Wander, Path Following, Flow Filed Following
  - Velocity Match
    - 速度匹配，启动时的加速与快到达目标时的减速，在数学上需要一定处理，特别是对弧线时、双方共同运动时更复杂
    - 一般来说每个 tick 假设对方匀速运动算出自身的加速度而不用完全掌握对方信息（真实世界也是如此），也能算出不错的结果
    - 输入自身速度与目标速度以及匹配时间，输出加速度
  - Align
    - 朝向匹配，要考虑角速度、角加速度，如 NPC 看向主角、群体朝向同一方向等
    - 输入自身朝向与目标朝向，输出角加速度

== Crowd Simulation 群体模拟
现代 AI 经常要处理群体情况，比如城市中的人群、四散的动物……群体模拟需要做到：避免碰撞、成群的来回移动 (Swarming)、编队运动 (motion in formation)。

- *群体模拟模型*
  - 图形学大牛 Reynolds（他也是 Steering 系统的开山鼻祖）提出的 Boids 模型将 Crowd Simulation Models 分为三类
    + Microscopic: 微观方法，自底向上地定义每一个体的行为，合起来组成群体行为
    + Macroscopic: 宏观方法，定义群体宏观的运动趋势，所有个体按照该趋势移动
    + Mesoscopic: hybrid 方法，将群体分组，既有宏观的趋势也有微观的个体行为
- *Microscopic 微观方法*
  - 基于规则的模型，用简单规则控制每个个体的运动
    - 分离 (Separation)：避开自己的所有“邻居”（斥力）
    - 凝聚性 (Cohesion)：朝向群体的“质心”移动
    - 一致性 (Alignment)：和邻近的对象朝向同一个方向移动
  - 简单易实现，但不适合模拟复杂行为规则，且在宏观上不可控、不受人影响
- *Macroscopic 宏观方法*
  - 人群的运动暗含某种规则，不会像鱼群那样撞到就让开，随机找方向走，如同无头苍蝇。这种就很适合用宏观方法模拟
  - 从宏观的角度模拟人群的运动，用势能场、流体力学控制运动，不会考虑个体间的交互和环境对个体的作用
  - 把区域划分成 zone graph，让人沿着 lane 行走，既要避免 lane 之间的频繁切换，又要在十字路口允许分叉
- *Mesoscopic 方法*
  - 结合了微观和宏观的方法，群体分为很多小组，每组分别运动
  - 既指定了宏观的目标位置，又让个体以微观规则调整行为，最典型的应用就是 RTS 游戏里的单位移动
- *Collision Avoidance 避免碰撞*
  - 相比群体同时寻路 (Path Finding, Path Smoothing) 的巨大开销，给一个大体目标然后用避免碰撞的方式来调整行为是一个更廉价的选择，下面两种方法成为引擎的标配
  - Force-based Models 基于力的模型
    - 使用距离场给障碍物增加一个反向力
    - 好处是可以被拓展去模拟更慌乱的人群的行为；坏处是类似于物理模拟，模拟的步长应该足够小
  - Velocity-based models 速度障碍法
    #fig("/public/assets/CG/GAMES104/2025-04-06-14-30-34.png", width: 80%)
    - Velocity Obstacle (VO)：其它方向走来的物体在速度域上形成障碍，如果判断产生碰撞就需要调整速度比如靠左避让
    - Reciprocal Velocity Obstacle (RVO)：在 VO 的基础上考虑相互性（假设对方采取相同的决策行为）
    - Optimal Reciprocal Collision Avoidance (ORCA)：当参与的对象不止两个时，$A, B$ 之间的避让可能又会影响到 $C$。数学上非常复杂，“空间上的所有速度在一段时间内形成速度空间上呈羽毛球状的锥形区，用闵可夫斯基求和并求一个对所有对象公平的子节点”，听不懂
    - 总之这类算法虽然确实可以找到理论最优且优雅的解，但写起来非常复杂，处理不好会导致计算复杂度很高，在易实现这方面不如基于力的模型

== Sensing 感知
- 对世界、环境的感知是人类和 AI 决策的依据，分为内部和外部信息
  - Internal Information
    - 智能体自己的信息，如位置、血量、护甲、buff 等，可以自由方便地获取（之前讲的脚本系统，很方便获取一系列属性）
  - External Information
    - Static Spatial Information: 如 Navigation Data、战术地图 Tactical Map、可交互物体 Smart Object、掩体点 Cover Point 等
    - Dynamic Spatial Information
      - 如因子图 Influence Map（热力图，有很多维度，比如动态更新的危险系数）、动态寻路数据 Marks on Navigation Data、视野 Sight Area
      - 以及最重要的 GameObjects 数据，包括 ID、互相的可见性、威胁度、上一次感知时的所用的方法和所处的位置……

总之，这些都非常类似人类对世界的感知（并不是上帝视角），有视觉、听觉并随距离衰减，有活动范围、视野等，但如果感知太多会影响性能，因此一般会取舍几个，并范围内共享信息。

实际上讲到这里很多部分已经超出引擎的职责范围，而更多是由游戏开发组自己设计的，引擎需要做的是提供开放的接口、定义感知的精度，把自主权开放给上层。

== Classic Decision Making Algorithms 经典决策算法
决策算法是 AI 的核心，上述的寻路、转向、感知等都只是决策算法的基础。

- 决策算法一般分为
  + *Finite State Machine (FSM) 有限状态机*
  + *Behavior Tree 行为树*（AI 最核心的体系）
  + Hierarchical Tasks Network 层次任务网络
  + Goal Oriented Action Planning 目标驱动的行为计划系统
  + Monte Carlo Tree Search 蒙特卡洛搜索树
  + Deep Learning 深度学习
  - 前两种是 forward planning，后四种是 backward planning，之后再讲

=== Finite State Machine 有限状态机
- 根据某些条件 (Condition) 转换 (Transition) 一个状态 (State) 到其他状态
- 好处：容易执行、容易理解，对简单例子应对起来非常快（比如吃豆人的状态机可以用 $3$ 个 state 和 $6$ 个 transition 表达）
- 坏处：可维护性差，特别是添加和移动状态；重用性差，不能被应用于其他项目或角色；可扩展性差，很难去修改复杂的案例
- 改进：Hierarchical 有限状态机 (HFSM)
  - 把状态机分为很多层或模块，每层状态机之间有相互的接口，内部复杂度可控
  - 好处是增加可读性，部分解决上述问题；但坏处是会造成一定的性能下降，难以跳模块，反应速度也会下降
- 属于古老的方法

=== Behavior Tree 行为树
状态机是对人类行为的抽象，但人类真实思考不是像状态机那样一团乱麻、跳来跳去，也不完全是列出 $1, 2, 3$ 的条件支撑做出最后的决策，而是以一个树状的结构，通过一个个分支抵达最终的抉择（Behavior Tree 的祖宗是决策树 Decision Tree）。

- *Execution Nodes 执行节点*
  - 分为 Condition Node 和 Action Node
  - 前者感知自我或环境状态，立马执行完返回 true / false；后者有一定执行过程，返回 success / failure / running
  - PreCondition: 把 Condition Node 和 Action Node, Control Node 结合从而简化行为树（语法糖）
- *Control Nodes 控制节点*
  - Sequencer Node 顺序执行：从左到右顺序遍历子节点，直到某个节点失败或所有节点成功
  - Selector Node 条件执行：根据条件和优先级尝试所有子节点，一旦某个子节点满足条件，立马执行该行为
  - Parallel Node 并行执行：一个智能体同时进行多个行为
  - Decorator Node 装饰节点：起修饰作用，例如循环执行、执行一次、计时器、定时等（语法糖 again）
#fig("/public/assets/CG/GAMES104/2025-04-06-15-21-22.png", width: 80%)
- *Tick a Behavior Tree*
  - 状态机只需要每次 tick 检查当前 state 所有 transition 的 condition，而行为树要考虑的就多了
  + 每一 tick 更新都要从根节点开始判断，否则可能一些行为的更新不够及时
  + 对于根节点开始导致的效率问题，可以做一定优化，比如修改为从上一帧节点继续，但设置一些 event 激活某些子树或重置到根节点；或者像 UE 那样做 State Tree
  + 同时在 running 的动作可能不止一个，只要符合行为树的规范即可
  + 行为之间要有优先级
- *Blackboard*
  - 用于记录行为状态 (memory)，把数据与逻辑分离，在行为树的不同分支能够交换信息
- *行为树的优点*
  + 模块化、层级组织（每个子树可以被看作是一个模块）
  + 可读性高，用 $5$ 类节点就把智能体甚至人类的行为模拟出来
  + 容易维护，并且修改只会影响树的一部分
  + 反应快，每个 tick 会快速的根据环境来改变行为
  + 容易 Debug，每个 tick 都是一个完整的决策
- *行为树的缺点*
  + 如果不优化，每个 tick 都从根节点触发，会造成更大的开销
  + 反应性越好，条件越多，每帧的花销也越大
  + 机械式地执行动作，没有 high level goal $->$ AI Planning

= 游戏引擎的玩法系统：高级 AI
== Hierarchical Tasks Network 层次任务网络
HTN 经典且应用广泛，它 Make a Plan Like Human，从任务或目标出发，把目标分为几个步骤，步骤内可以包含不同选项，并根据自身状态选择合适的行为一次完成步骤，完全类似人的思考过程。

- *HTN Framework*
  - World State：取名不好，AI 对世界的主观认知而不是客观描述，反馈到 Planner
  - Sensors：即 Perception，传感器、感知器，从游戏中抓取状态
  - HTN Domain：层次化树状 tasks
  - Planner：从 World State 和 HTN Domain 生成计划
  - Plan Runner：执行计划，更新 World State，当然可能不会一帆风顺而需要 RePlan
- *HTN Task Types*
  - Primitive Task 基本任务
    - 表示一个具体的动作，每个 primitive task 都有 Precondition (world state properties)、Action、Effects (modify properties) 三要素
    - Precondition 用于读取状态，Action 作用于客观真实世界，Effects 更新状态（只有对 World State 有影响才写到这里）
  - Compound Task 复合任务
    - 由很多 method 构成，每个 method 有自己的 Precondition，其内部可以是 Primitive Task 或者 Compound Task
    - methods 按照一定的优先级组织起来，执行时按照优先级选择，全部执行完毕返回 true（类似于结合了行为树的 selector 和 Sequencer）
  #fig("/public/assets/CG/GAMES104/2025-04-06-16-49-54.png", width: 80%)
- *Planning*
  + 从 root task 开始检查 precondition，选择一个满足条件的 compound task
  + 对这个当前指向的 compound task，展开进行以下操作
    + 先把 world state 拷贝一份，然后检查 precondition
    + 如果满足，就假设这个 task 里的 action 全部可以执行成功，并把其 effect 修改到拷贝的 world state 里
      - 这里假设全部完成实际上是带着目的的预测，跟人类对未来的假想非常像，这里就跟 BT 展现出不同
      - 同时这些 action 可能持续时间很长而环境会发生变化，但没关系也假设成功，后续 Replan 会解决这一问题
    + 如果不满足，就层层返回 false，去选择下一个 task
  + 重复第二步直到没有 task 为止
- *Run Plan*
  - 最终，Plan 输出遍历过程中经历的一串 Primitive Task，交给 Plan Runner 执行
  - 如果发现 Plan 得好好的但执行失败了，就需要 Replan
- *Replan*
  - 需要 Replan 的情况
    + 当前没有 plan
    + 当前的 plan 执行失败或成功执行完成
    + Sensor 感应到 World State 发生变化
- *总结*
  - 优点
    + HTN 类似于对 BT 的 high level 包装简化，同时其 hierarchical 的设计更符合人的直觉；
    + 它输出的 plan 带有目的和 long-term effect
    + 在同 case 下它一般比 BT 更快
  - 缺点
    + 由于用户行为不可预测，因此 task 很容易失败，特别是在高度不确定性的环境里，如果 HTN 链路做太长很容易震荡
    + world state 与 effect 的设计是一个挑战，比如设计师可能忘记设置某个条件、效果，需要程序这边做一些静态检查

== Goal Oriented Action Planning 目标驱动的行为计划系统
GOAP 这一方法更加自动化，比前述方法一般会更适合动态环境。

- *GOAP Structure*
  - GOAP 的整体结构与 HTN 非常相似，Sensor, World State 的定义相同；Domain 被替换为 Goal Set 和 Action Set；输出的 Planning 是一系列 Action，比起在 HTN 中称为 “计划” 这里更应称为 “规划”
  - *Goal Set 目标集合*
    - 在 HTN 中，“目标” 这一概念其实没有显式定义（设计师写在注释里），而是由几个 task 组成；而 GOAP 中的目标有严格数学定义
      - 把目标定量地表达出来而不是隐含在 tree 结构里，是 GOAP 的一个核心不同
    - Goal 有 Precondition, Priority, States 三个属性，States 集合就是用来描述目标的，一般用几个 bool 值表示
  - *Action Set 行为集合*
    - 每个 Action 类似之前的 Primitive Task，在 Precondition, Action, Effect 之外又加了 Cost 属性
    - GOAP 中没有树状结构把所有动作串在一起，要用 Cost 来选 Action。Cost 是由开发者定义的代价权重，用于排序优先级
- *Backward Planning*
  - GOAP 在规划时会从目标 Backward 推导需要执行的动作，是一种类似人类的思考方式
  + 在以优先级排序的 Goal Set 中选取一个 Precondition 满足的目标，下面尝试达成它的 State
  + 筛选目前 World State 中没有满足的，放入 Unsatisfied States Stack
  + 从 State Stack 的栈顶开始，找到 Effect 能够满足它的 Action，把这一 State 移除，并把 Action 加入 Plan Stack
  + 如果这一 Action 的 Precondition 也不满足，就加入 Unsatisfied States Stack（为了满足某个 State 而执行的动作又产生新的需求）
  + 重复上述过程，直到 Unsatisfied States Stack 为空，Plan Stack 中的动作就是最终的计划
  - GOAP 中除了令 Unsatisfied State Stack 为空即能够达成目标之外，另一个核心的点在于如何选择最小 Cost 路径达成目标
  - 这包括如何选择 Goal、如何选择 Action，可以转化为路径规划问题，用代价图求解
- *Build States-Action-Cost Graph*
  - 有向图的 Node 是 States 的组合；Directed Edge 是各种 Action 以及其 Cost，要求 Precondition 满足其出发节点的 State
  - 要从起点（Goal 的 States）到达终点（当前 World State），这样整个规划问题就等价于有向图上的最短路问题
    - 也就是从终点出发倒推模拟回当前状态（实际上我觉得这种图的理解比刚才 Stack 的理解更直观）
  - 构建 Graph 后，可以用 A\* 算法求解，用不满足 State 的个数作为启发式函数。另外，A\* 不能保证最优的特点又恰恰可以引入随机性、真实性
- *总结*
  - 优点
    + 比起 HTN 更加动态灵活
    + 更够解耦 AI 的目标与行为：无论是 FSM, BT, HTN，它们达成目标的行为都是通过一个拓扑结构锁死的，而 GOAP 在给定目标后随机出的结构有时令人类都非常惊讶
    + HTN 容易导致 Precondition / Effect 不匹配的错误，导致死锁，而 GOAP 中智能体的行为不是由设计师预设的
  - 缺点
    + 比 BT, FSM, HTN 都慢（HTN 最快）
    + 如果真正把决策交给 GOAP，需要对 World State 和 Action Precondition / Effect 做出精细的定量表达

== Monte Carlo Tree Search 蒙特卡洛搜索树
后面的蒙特卡洛树搜索和深度学习都跟机器学习领域的 AI 强相关，也算是我个人的老本行了，就记得简单一点。

- MCTS
  - Iteration Steps: Selection, Expansion, Simulation, Backpropagation。
  - Selection
    - 选择可能性没有穷尽的 node (expandable node)
    - exploration & exploitation $->$ UCB
  - Expansion
    - 扩展 node，添加子节点
  - Simulation
    - （多次）随机模拟游戏，直到结束
  - Backpropagation
    - 反向传播，更新 node 的值
  - Choose the Best Move
    - Max child、Robust Child（鲁棒性一定程度上已经反映了 $Q/N$）、Max-Robust Child、Secure Child（LCB，UCB 翻版）
- 总结
  - 优点：表现更多样化（有随机数），AI 全自动决策，适合搜索空间巨大的决策问题
  - 缺点：计算复杂度大所以难以用在实时游戏中，并且复杂游戏中也难以准确定量定义状态和行为
  - MCTS 适合回合制、行动数值反馈明显的游戏

== Machine Learning 机器学习
- Machine Learning 四种类型
  - Supervised Learning, Unsupervised Learning, Semi-supervised Learning, *Reinforcement Learning*（游戏中最重要）
- Markov Decision Process (MDP) 马尔可夫决策过程
  - State, Reward, Action, *Policy*
- Build Advanced Game AI
  + State (Observation)
  + Action
  + Reward
  + NN Design
  + Training Strategy
- 在控制一些宏观行为的时候可以使用神经网络，在控制细节行为的时候可以用设计师配置的行为树等等（什么你说很有钱？那没事了）