---
order: 4
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
#let bXk = $bX^((k))$
#counter(heading).update(9)

= 游戏引擎中物理系统的基础理论和算法
- 物理系统对游戏引擎的重要性无需多言，这里另外推荐几篇文章
  + #link("https://www.zhihu.com/question/43616312")[为什么很少有游戏支持场景破坏？是因为技术问题吗？]
  + #link("https://www.bilibili.com/opus/573944313792790732")[如何创造《彩虹六号：围攻》的破坏系统？]

== 物理对象与形状
- *Actor 对象*
  - Actor 是游戏引擎物理对象的基本单元（注意跟角色动画的那个 actor 不是一个概念），一般分为以下四类
    + Static Actor 静态物体：不懂的物体，如地面、墙壁等
    + Dynamic Actor 动态物体：专指符合动力学原理的动态物体，可能受到力 / 扭矩 / 冲量的影响，如 NPC 等
    + Trigger Actor 触发器：与 GamePlay 高度相关的触发开关，如自动门、传送门等
    + Kinematic Actor 运动物体：专指不符合动力学原理的动态物体，根据游戏的需要由游戏逻辑控制，但反物理的表现经常出现 bug，因此需要谨慎使用
  - 分组能够很大程度上减少需要运算的数量，后面还会提到 sleeping 的概念，让一段时间不动的物体进入休眠状态
- *Actor Shape 对象形状*
  - 游戏中往往会用简单形状的物理对象来替代表达实际渲染的复杂物体，常见形状有：
    + Sphere 球：最简单的形状，适用于各种类球形物体
    + Capsule 胶囊：碰撞体积小且计算量小，适用于人形角色
    + Box 立方体：适用于各种建筑家具等
    + Convex Mesh 凸包：精细一点的物体比如岩石
    + Triangle Mesh 三角形网格：适用于精细一点的建筑等
    + Height Field 高度场：适用于地形，一般只会有一个
  - 用简单几何体模拟物理对象有两个原则：
    + 形状近似即可，不用完美贴合
    + 几何形状越简单越好（尽量避免 triangle mesh），数量越少越好

== 力与运动
- *一些物理概念*
  + 质量和密度 Mass and Density：往往取其一即可
  + 质心 Center of Mass：在做载具时很重要
  + 摩擦和恢复（弹性） Friction and Restitution
  + 力 Forces：有直接的拉力、重力、摩擦力，也有冲量 impulse
  + 牛顿定侓 Newton's Laws
  + 刚体动力学 Rigid Body Dynamics：在部分场景下非常重要，如台球游戏
- *欧拉法*
  - 显式欧拉法 Explicit (Forward) Euler's Method
    - 与积分直觉最接近的算法，下一时间的速度和位置都用上一时间的量计算
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t0) De t,
        x(t1) = x(t0) + v(t0) De t
      ) $
    - 用当前状态值去预估未来状态，$De t$ 并非无限小导致误差积累而能量不守恒（能量爆炸）
  - 隐式欧拉法 Implicit (Backward) Euler's Method
    - 用下一时间的速度和位置来计算当前时间的量
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t1) De t,
        x(t1) = x(t0) + v(t1) De t
      ) $
    - $De t$ 也并非无限小导致能量不守恒（能量衰减），但至少衰减是符合物理规律的（空气阻力、摩擦力等），因此在游戏中相对更容易接受
  - 半隐式欧拉法 Semi-Implicit Euler's Method
    - 结合前两种方法，新速度用旧的力去算，新位置用新速度算。暗含了力不随位置改变的假设（很危险的假设，在比如橡皮筋弹射的情形完全错误）
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t0) De t,
        x(t1) = x(t0) + v(t1) De t
      ) $
    - 它的优点是大部分时候稳定、计算简单有效、随着时间的推移能够保存能量；缺点是在做一些 $sin, cos$ 相关运动时，积分出的周期会比正确值长一点点，在相位上会有偏移差

== 碰撞检测
- 碰撞检测一般分为两个阶段
  + *Broad phase 初筛* —— 快速判断是否相交，过滤大部分物体，一般简化为 AABB (Axis-Aligned Bounding Box)，常用两种算法：
    + BVH Tree: 动态更新成本低，方法成熟
    + Sort and Sweep: 比 BVH 更快，先沿轴把每个静态物体的 AABB 边界大小值排序，再沿着每个轴逐个扫描，如果 minmax 没按顺序出现则有可能发生碰撞。静态物体排序好后可以只插入排序更新动态物体，因此效率高
  + *Narrow phase 细筛* —— 详细计算碰撞并给出信息（碰撞点、方向、深度等）
- *Narrow phase Methods*
  - Basic Shape Intersection Test: 对于球、胶囊体这样简单的形状，可以直接判断距离和半径大小来判定是否相交
  - Minkowski Difference-based Methods
    - 利用闵可夫斯基距离，将 “两个多边形是否相交” 问题转换为 “一个多边形是否过原点” 问题
    - GJK (Gilbert-Johnson-Keerthi) 算法
      - 可以参考这篇文章 #link("https://zhuanlan.zhihu.com/p/511164248")[碰撞检测算法之 GJK 算法]
      - 总之是类似牛顿迭代法，逐步往原点方向逼近的思想
    - SAT (Separating Axis Theorem) 算法
      - 2D 空间中，如果两个物体分离，肯定能找到一根轴把它们分隔开，不然就是相交。因此可以在两个多边形的边上进行穷举计算，把两个凸包的每条边当做分隔线试试，看另一个凸包的所有顶点是否在同侧
      - 推广到 3D 空间，则是穷举所有面，还需要额外穷举两个物体的边叉乘形成的面

== 碰撞解决
- 检测到碰撞后需要将碰撞物体分开，最简单的早期办法是直接加一个 Penalty Force，但有时会导致物体突然炸开
  #fig("/public/assets/CG/GAMES104/2025-04-01-11-17-55.png", width: 60%)
- 现代引擎比较流行的方法是把力学问题变成数学上的*约束问题*，利用拉格朗日力学对速度进行约束。解约束的常用办法有：
  + Sequential impulses 顺序推力
  + Semi-implicit integration 半隐式积分
  + Non-linear Gauss-Seidel Method: 现代物理引擎最常用，快速且对大部分情形稳定。给碰撞物体加个小冲量来影响速度，看此时是不是还碰撞（是否符合拉格朗日约束），不断重复直到误差可以接受或者迭代次数超过设定
  #fig("/public/assets/CG/GAMES104/2025-04-01-11-18-03.png", width: 60%)

== 杂项
- *场景请求 Scene Queries*
  - 游戏引擎中物理系统的一个重要组成部分，场景来 query 物理系统以获取一些信息
  - Raycast: 打出一条射线来判断是否与其他物体相交，有 $3$ 种返回情况
    + Multiple hits: 返回所有打中物体
    + Closest hit: 返回打中的最近的物体
    + Any hit: 打中就返回，不关心具体打中的信息（最快）
  - Sweep: 对 box, sphere, capsule and convex 等形状进行扫描判断
  - Overlap: 对 box, sphere, capsule and convex 等特定形状包围的区域查询是否有物体交叠
- *Efficiency*
  - Collision Group & Sleeping
- *Accuracy*
  - Continuous Collision Detection (CCD)
    - 物体快速运动时碰到一个比较薄的物体，如果在前后两帧都没有检测到，就穿出物体，也叫 Tunneling Problem
    - 最朴素的方法就是把物体做得厚一些，没办法的情况下使用 Time-of-Impact (TOI) 方法进行保守前进 (Conservative advancement)：物体在环境中先计算一个安全移动距离，在此范围内随便移动，但在靠近碰撞物体时，把碰撞检测计算频率增加
- *Determinism*
  - 物理引擎非常重要的难点，在不同帧率、硬件端侧、计算顺序、计算精度下结果都会大不一样。目前即使是商业物理引擎也难以做到在不同硬件上结果一直，需要大量处理来保持逻辑一致性
  - 对于 online 游戏，如果能做到 determinism，就不需要同步很多中间状态，只需同步输入即可

= 物理系统的高级应用
== Character Controller
- Character Controller 不同于普通的 Dynamic Actor，它其实是反物理的，与 Kinematic Actor 很像，比如：
  + 可控的刚体间交互，比如飞来物体可能无法撞飞我
  + 摩擦力假设为无穷大，可以站停在位置上
  + 几乎瞬时的加速、减速、转向，甚至可以传送（比如林克相比不死人、褪色者的性能简直强到离谱）
- 角色控制器的创建
  - 因此 Character Controller 一般用一个 Kinematic Actor 包起来即可
  - 人形角色可以用 Capsule, Box, Convex，其中 Capsule 是最常见的。
    - 很多游戏中会使用双层 capsule，内层用于碰撞计算，外层用作 “保护膜”，避免角色离其他东西太近。例如角色高速运动卡到墙里、或是相机近平面卡到墙后
- 角色与环境的交互
  + Sliding: 角色与墙发生碰撞时，不该停下来，而是沿着墙的切线滑动
  + Auto stepping: 游戏世界不全是连续的，遇到台阶时可能需要先往上抬一点再往前移动
  + Slope limit: 坡度过高时角色无法走上去而是往下滑，在支持攀岩的游戏中则是转化为攀爬
  + Volume update: 角色蹲起、趴下时，对应的碰撞体积也要修改，并且在更新之前要做 overlap 测试，避免动作切换时角色卡墙
  + Push Objects: 角色碰到 Dynamic Actor 时触发回调函数，根据角色的速度、质量等计算出冲量去推动物体
  + Moving Platform: 站在移动平台上时，通过 raycast 检测并在逻辑上把 controller 和平台绑定在一起（除非要进行更高标准精细计算），从而防止平台水平移动或角色跳跃时两者脱钩（没有惯性），或者平台上下移动而角色上下抽动
  - 总的来说，这一部分的实现并不困难但很细节，要想做得真实需要大量设计

== Ragdoll 布娃娃系统
- 为什么需要布娃娃系统？
  - 当角色死亡或昏迷时，其形体最好用物理模拟来表现，而不是纯用动画。举个栗子，当角色被刺杀并播放死亡动画后，应该顺着重力倒下，并且如果身在斜坡或悬崖应该掉下去（与环境互动）
  - 如果纯用动画，则工作量大且有些时候不自然。一般来说我们会将二者结合使用
- 布娃娃系统具体实现
  - 将原本人体的 skeleton 映射成 ragdoll 的 skeleton（也是一系列 joints），一般为了减少计算会减少至十几个，相互之间用 rigid body 连接
  - 需要对这些 joints 施加合适的 constraints，仔细调整 rigid bodies 的形状，形成合理的转变动作，一般由 TA 完成
  - 一般骨骼分为以下三种
    + Active joints: ragdoll 和原本骨骼共有，直接用原骨骼变化
    + Intermediate joints: ragdoll 新生成的中间骨骼，这一过程类似于不同骨骼类型的 retargeting，也需要进行等比缩放、插值等处理
    + Leaf joints: 不由 ragdoll 接管的在刚体尽头外未被覆盖的原骨骼，保持其动画设定跟着其父节点变化
- 混合动画和布娃娃系统
  - 一般在角色死亡后会进行从动画转到由 ragdoll 接管的过程，从而结合二者，需要考虑这个变化的边界和权值
  - 而更高级的做法是相互 blend 使用，把动画的状态作为物理系统的初始输入计算，把物理的盐酸结果叠加回动画（类似于在物理解算中支持骨骼蒙皮动画）

== Cloth Simulation 布料模拟
- *Animation-based Cloth Simulation*
  - 给布料添加骨骼，使用骨骼动画驱动布料顶点
  - 优点是廉价可控，移动端常用（提一嘴，《原神》这种卖角色的游戏在布料动画模拟上做得挺不错）；缺点是不够真实、和环境没有交互以及设计上受限
- *Rigid Body-based Cloth Simulation*
  - 同样给布料添加骨骼，但不由动画而是由物理引擎驱动（加约束并物理解算）
  - 优点是廉价有交互；缺点是效果一般，美术工作量大，不够鲁棒，且对物理引擎的性能要求相对高
- *Mesh-based Cloth Simulation*
  - Physical Mesh: 物理模拟所用的网格自然不会是 Render Mesh 那么精细，一般会稀疏很多，面数在十分之一左右。精细顶点的运动可以通过 barycentrics 插值得到
  - Cloth Simulation Constraints: 需要对移动范围做个约束（需要美术刷权重）。比如披风，越靠近肩膀范围越小，更符合物理实际，且可以减少穿模概率（不过这是目前游戏引擎都很难解决的问题）
  - Cloth Physical Material: 指定布料的硬度、切向韧性、褶皱程度等，可以结合渲染的材质达到更一致的效果
  - *Cloth Solver*
    - 使用弹簧质点系统建模每个顶点的受力
      $ arrow(F)_"net"^"vertex" (t) = M arrow(g) + arrow(F)_"wind" (t) + arrow(F)_"air_resistance" (t) + sum_("springs" in v) (k_"spring" De arrow(x) (t) - k_"damping" arrow(v) (t)) = M arrow(a) (t) $
      - 其中大部分力都很好理解，$arrow(F)_"air_resistance"$ 一般简单取 $arrow(v)$ 的正比例函数即可，damping 是指弹簧自己的阻尼（最终转化为内能）
    - 该式的求解一般有两种方法：
      + Verlet Integration: 从半隐式欧拉法可以简单推出，虽然式子本身是完全等价的，但这一形式的好处在于剔除了 $arrow(v)$ 而完全由顶点位置 $arrow(x)$ 和受力所决定
        $ arrow(x + De t) = 2 arrow(x) - arrow(x - De t) + arrow(a) (t) (De t)^2 $
        - 不仅更快，也更稳定（降低有时一瞬间高速度的影响，感觉有点往 PBD 那边靠的意思）
        - 而且我们的物理系统对 $arrow(x)$ 是更直接的，$arrow(v)$ 是对加速度间接积分出来的，这样对精度也有好处
        - 再来，$arrow(x - De t)$ 作为上一帧的结果，内存中可能有缓存，计算量也小
      + Position Based dynamics (PBD)
        - 但一般来说，目前最主流的布料求解方法还是 PBD，直接由约束计算出位置，而不需要再由约束得出力再算出速度位置，最后一章单独讲
- *Self Collision* 自穿插问题
  - 衣服自身或者衣服之间相互穿模的情况，由于角色衣服经常穿好几层，所以这个问题对高品质游戏很重要，目前还是非常前沿的领域
  - 一般有这些方法：
    + thicker cloth: 单纯把衣服加厚（即使有一定穿模也不影响）
    + substeps: 增加计算精度（一个 step 里解算多个 substep，使得不会穿透很深）
    + Enforce maximal velocity: 设置最大速度值，防止衣料之间穿模的过深
    + contact constraints and friction constraints: 最大速度值的基础上再设置一个反向力，穿模还能弹回来

== Destruction 破坏系统
破坏系统不仅仅是视觉效果的一环，它有时也是 gameplay 的组成，使游戏世界更栩栩如生

- 制作步骤
  + 使用 Chunk Hierarchy 组织，一般是自动生成 level by level 的树状结构来将未被破坏的物体分割成不同大小的 chunk，对不同层级设置不同的破坏阈值
    - 树状结构怎么生成？一般是用 Voronoi Cell 算法（即之前讲云的噪声时的 worley noise）
    - 具体为在 2D 图上随机撒一些种子，每个种子以相同的速度不断扩大半径，直至撞到其他种子区域，稳定下来后就形成不同的块（类似细胞）。对于 3D 物体需要用 Delaunay 三角化
  + 把每个 chunk 视作一个 node，共享边的 chunk 间连一条 edge，构建同一层的不同块之间的关系 (runtime update)
  + 给连接关系设置破坏值（血量）$D$ 和硬度 $H$，每次攻击后计算伤害值并累积
    - 伤害由施加的冲量除以硬度给出，实际上是个并不太合理的式子（如果要更符合物理的话要考虑应力、韧度等）
      $ D = I / H $
    - 以及往往会设置一个球形的衰减（在小范围内伤害相同，在此之外伤害递减）
      $ D_d = cases(
        D\, &d < R_min,
        D dot (frac(R_max - d, R_max - R_min))^K\, &R_min < d < R_max,
        0\, &d > R_max
      ) $
- 切割模型后断口处纹理如何处理（尤其是 3D 物体）？一般有两种方式：
  + 直接制作对应的3D纹理，切割时直接用，但从生成到采样都复杂
  + 离线计算好这些纹理，一旦破碎则切换到对应的纹理，这种需要瞬时处理，也很复杂
- Make it more realistic
  - 许多种破碎方式，均匀的、随机的、中心往外碎等
  - 加上对应的声效、粒子效果等
  - 碎片间的物理互动、相互碰撞（慎用，开销巨大）
- 一些 Popular 的破坏模拟引擎
  + NVIDIA APEX Destruction
  + NVIDIA Blast
  + Havok Destruction（《塞尔达传说：旷野之息》所用物理引擎就是魔改自哈沃克引擎）
  + Chaos Destruction (UE5)
#q[插播一则新闻，任天堂在 2025.4.2 的 switch2 直面会上公布的《Donkey Kong: Bananza》似乎在地形破坏上有重大突破，以至于能以此为核心玩法做一款护航大作。本文编写时还未看到有深入的技术分析，期待后续有文章挖掘一下 #emoji.face.smile]

== Vehicle
游戏中载具系统十分重要，如前文所述我们往往会在角色身上设计一个挂载点 mount 到载具上。那么这个载具具体要怎么建模才能真实又自然呢？这里主要讨论的是 “车”，而飞行器、船、生物坐骑不会详细介绍。

- *载具模型*
  - 通常我们会把车辆建模成一个 rigid body 加上一系列弹簧，一方面模拟形状，另一方面也支持悬挂系统的 scene query
- *受力*
  - Traction Force 驱动力
    - engine 输出扭矩（由发动机转速、油门等影响，具体公式有车载引擎工程师考虑），再经过变速箱、差速器等传递到车轮。车轮转动，（只要不打滑基本都是）静摩擦力成为驱动力
  - Suspension Force 悬挂力
    - 类似弹簧的弹力，轮胎随着离车体距离大小影响施加悬挂力
  - Tire Force 轮胎力
    - 分为 Longitudinal force 纵向力（往车身前方）和 Lateral force 横向力（切向力，垂直于轮胎方向）
    - 对 Longitudinal force，如果是从动轮就只是阻力，如果是驱动轮就有 Traction Force
    - 对 Lateral force，实际上是滑动摩擦力，关系到车的转向，不仅跟路面、轮胎有关，也跟车辆重心有关
- *Center of Mass 重心*
  - 重心很影响车辆的设计和体验，影响牵引力、加速度、稳定性等，它应当是一个可调值。一般来说，重心跟发动机的位置高度相关
  - 当车辆在空中时，重心太靠前则容易 dive，重心靠后则相对稳定
  - 当车辆在转弯时，重心太靠前则容易转向不足 (understeering)，重心靠后则容易转向过度 (oversteering)，跟转动惯量的力臂有关
  - Weight Transfer: 加速时重心会后移，减速时前移
- *Steering angles 转向角*
  - 由于车辆是个刚体，本身有宽度，如果两个轮胎角度相同，靠外的轮胎会发生空转，开出的轨迹容易变成螺旋衰减线
  - 所以实际中需要用轮胎到转动圆的圆心切线算出转动角度 —— Ackermann steering
- *Advanced Wheel Contact*
  - 轮胎与环境的交互如果只用 raycast 容易穿模，最好用 spherecast 将轮胎整体以球体的方式判断
  - 部分游戏中还有飞行器的空气动力学模拟、船的模型，以及坦克的履带模拟等

== Advanced: PBD/XPBD
- 回忆拉格朗日力学
  - 用力学约束而不是运动规律来描述物理系统，反向定义运动规律，从而把很多力学问题化简成求解约束问题
- *PBD*
  - 以匀速圆周运动为例
    - Position Constraint:
      $ C(bx) = norm(bx) - r = 0 $
    - Velocity Constraint:
      $ frac(dif, dif t) C(bx) = frac(dif C, dif bx) frac(dif bx, dif t) eq.delta bJ dot bv = 0 $
      - 前者空间约束关于位置的导数就是 Jacobian 矩阵（在这里就是一个行向量），后者就是速度
      - 换句话说，构建了一个速度的约束：正交于 Jacobian 矩阵
  - 以弹簧运动为例
    $ C_"stretch" (bx_1, bx_2) = norm(bx_1 - bx_2) - d = 0 $
  - Jacobian 矩阵实际上描述了在当前姿态下，为了满足约束（靠近目标点），每一个变量应该扰动的趋势如何。PBD 就类似于梯度下降法，利用 Jacobian 描述的倾向，根据某个步长不断迭代优化约束状态。其约束是用 position $bx$ 来描述，把过去广泛使用的速度、力等概念（容易导致迭代不稳定）给抛弃了
    - 定义第 $k$ 次迭代下的所有顶点的空间位置
      $ bXk = vec(bx_1^((k)), dots.v, bx_n^((k))) $
    - 我们希望添加一个扰动后依然满足约束，用泰勒展开近似。并且扰动是沿着 Jacobian 矩阵的方向
      $
      C(bXk + De bX) approx C(bXk)  + na_bX C(bXk) dot De bX = 0 \
      De bX = la na_bX C(bXk)
      $
    - 于是可以计算出步长
      $
      C(bXk) + na_bX C(bXk) dot la na_bX C(bXk) = 0 \
      => la = - frac(C(bXk), norm(na_bX C(bXk))^2), ~~ De bX = - frac(C(bXk), norm(na_bX C(bXk))^2) na_bX C(bXk)
      $
  - 伪代码流程
    #algo(title: [*Algorithm*: PBD])[
      + *forall* vertices $i$
        + initailize $bx_i = bx_i^0, v_i = v_i^0, om_i = 1\/m_i$
      + *endfor*
      + *loop*
        + *forall* vertices $i$ *do* $v_i <- v_i + De t om_i f_"ext" (bx_i)$ #comment[5 \~ 7, Semi-Implicit Euler]
        + $"dampVelocities"(v_1, dots, v_N)$ #comment[需要对速度施加惩罚]
        + *forall* vertices $i$ *do* $p_i <- bx_i + De t v_i$ #comment[算出当前帧的假的位置记作 $p$（可能有穿插、钻地）]
        + *forall* vertices $i$ *do* $"generateColisionConstraints"(bx_i -> p_i)$ #comment[根据当前帧的位置生成碰撞约束，加上布料本身构成两组约束]
        + *loop* solverIterations *times*
          + $"projectConstraints"(C_1, dots, C_(M + M_"coll"), p_1, dots, p_N)$ #comment[9 \~11，迭代求解约束，直到误差小于阈值或迭代次数过长]
        + *endloop*
        + *forall* vertices $i$
          + $v_i <- (p_i - bx_i) \/ De t$ #comment[12 \~ 15，算出满足约束的该帧真正位置]
          + $bx_i <- p_i$
        + *endfor*
        + $"velocityUpdate"(v_1, dots, v_N)$ #comment[碰撞顶点的速度根据摩擦和恢复系数进行修改（再细调）]
      + *endloop*
    ]
  - PBD 的优势：把约束问题投影成位置校正，绝大多数情况收敛快且稳定，在布料模拟中广泛使用。有个小问题是不好控制约束的优先级（比如把碰撞约束置于其它约束之上）
- *XPBD (Extended PBD)*
  - 在 PBD 的基础上增加了刚度 (stiffness) 来描述约束的软硬程度
    - 一般是用 stiffness 的逆 —— 服从度 (compliance) 来描述，从而能够 handle 无限 stiff 的物体 (rigid body)
    - 例如硬币的刚度设置比较大，放在桌上高频抖动，构成一个比较硬的约束；布料这种比较柔软的就可以设置较小的刚度。从而我们在一个方程里对不同约束设置不同的刚度就能有不同的优先级
  - 重新引入了刚体朝向的影响用于刚体模拟应用（？）
  - 相当于把 PBD 的约束方程升级为服从度矩阵 Compliance Matrix，即下式的 $U(bX)$
    $ U(bX) = 1/2 C(bX)^T al^(-1) C(bX) \ "Block diagonal compliance matrix" $
    - 土法理解：stiffness 类似弹簧硬度（胡克系数），$C(bX)$ 理解为误差偏移量，那么弹簧势能就是 $1/2 k x^2$。多维情况下就变为矩阵，也就是说该公式可以理解为约束的势能
  - XPBD 其实刚刚兴起的 (2022.6)，还没有经过大规模工业化的检验，但正在变得越来越 popular（UE5 的 Chaos 就用的这个）