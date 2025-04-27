---
order: 3
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
#counter(heading).update(7)

= 游戏引擎的动画技术基础
== 2D 游戏动画技术
- 精灵动画 (sprite animation)
  - 把游戏人物的动画一帧一帧记录下来，然后循环播放
- Live2D
  - 把角色的各个部件拆成一个个小图元，通过图元的旋转、变形使角色变得鲜活，并且需要给各种图元设置深度来表达层级关系

== 3D 游戏动画技术
- *基于层次的刚体动画 Rigid Hierarchy Animation*
  - 早期动画实现方式，将角色用一系列的刚体块表示，用关节点约束
  - 把刚体用作骨骼，动的时候 mesh 会互相穿插
- *顶点动画 Vertex Animation*
  - 将每个顶点的复杂物理计算结果按照时间帧保存到一张纹理上（预烘焙），一个轴表示每个顶点，另一个轴表示不同时间该顶点的偏移量
  - 一般会存两个 texture，一个存位置，一个存法向
- *变形目标动画 Morph Target Animation*
  - 顶点动画的变种，把一系列 key frame 存下来，LERP 出想要的动画，通常用于面部
- *蒙皮动画 Skinning Animation*
  - 骨骼驱动顶点，每个顶点可能有不止一个骨骼驱动，可以避免 mesh 穿插，同时消耗也比逐顶点小
  - 2D 有时也用骨骼蒙皮动画
- *基于物理的动画 Physics-based Animation*
  - Ragdoll 布娃娃系统
  - 布料和流体模拟
  - Inverse Kinematics (IK) 反向动力学

== 蒙皮动画的实现
- *Animation DCC (Digital Content Creating) Process*
  + Mesh：网格一般分为四个 Stage: Blockout, Highpoly, Lowpoly, Texture。这里一般会制作固定姿势的 mesh (T-pose / A-pose)，把高精度的 mesh 转化为低精度，有时还会为肘关节添加额外的细节来优化
  + Skeleton binding：在工具的帮助下创建一个跟 mesh 匹配的 skeleton，绑定上跟 game play 相关的 joint
  + Skinning：在工具的帮助下通过权重绘制，将骨骼和 mesh 结合起来
  + Animation creation：将骨骼设置为所需姿势，做关键帧，之后插值出中间动画
  + Exporting：一般把 mesh, skeleton, skinning data, animation clip 等统一导出为 `.fbx` 文件。一些细节上的处理比如跳跃动画的 root 位移不会存下来而是用专门的位移曲线来记录
  #fig("/public/assets/AI/Human/2024-11-02-19-54-23.png", width: 50%)
- *骨骼的构建与绑定*
  - 三种 space：Local, Model, World
  - 通用骨骼标准：人形的有 Humannoid，骨骼起点在跨部，root 在两脚之间；四足动物有另外标准，骨骼起点一般在尾椎，root 在四足之间
  - 骨骼的绑定，利用叫做 mount 的关节。例如人骑在马上，不仅位置连接，方向也要绑死
- *3D 旋转的数学原理*
  - 2D 旋转
  - 3D 旋转之欧拉角 (Euler Angle)
    - Yaw, Pitch, Roll
    - 问题：旋转顺序依赖、万向节死锁问题、插值和叠加问题、不便表达任意轴旋转
  - 3D 旋转之四元数 (Quaternion)
- *骨骼 pose 的三个维度*
  + Orientation: 一般只需要 Rotation 即可表达骨骼链的位置
  + Position: 但某些情况也要用到位移，比如 root 表达的位置、人脸骨骼等
  + Scale: 一般只用于面部表达
  #fig("/public/assets/CG/GAMES104/2025-03-30-15-02-00.png", width: 60%)
  - 蒙皮动画只保存顶点相对骨骼 local space 最终的 Affine Matrix，以及骨骼权重
- *动画片段与插值*
  - 动画资产一般是十几二十帧，远小于实际游戏帧率，需要应用时插值
    - 注意是同一个 clip 内不同 pose / frame 之间的插值，后面会涉及到 clips 之间的插值，称为 blend
  - 针对位移和缩放，一般直接线性插值即可
  - 针对旋转
    - 反向插值：角度超过 $180°$ 时变换相乘结果小于 $0$，需要反向插值
    - 球面线性插值 (Slerp)：四元数线性插值后取 normalize，避免长度发生变化\
    - 均匀球面插值 (Slerp)：改进四元数插值不均匀的问题（头尾快中间慢）。但计算稍贵且分母 $sin$ 值小可能不稳定，实践中一般跟 Slerp 结合（$th$ 小用前者，$th$ 大用后者）

== 动画压缩技术
- *DoF Reduction*
  - 对大部分骨骼而言，translation 和 scale 不怎么变化，可以直接去掉
- *Keyframe Reduction*
  - 针对旋转，比较简单的方法是使用 Key Frame 然后插值（用步进的方法，每当误差超过一定阈值则设为关键帧并回退，因此关键帧间隔不固定）
  - Catmull-Rom Spline，类似贝塞尔曲线，在 $P_1, P_2$ 之外再取 $P_0, P_3$ 来拟合，缓解插值出来都是笔直折线的问题
- *Size Reduction*
  - 四元数很多时候不需要 $32bit$ 浮点数精度，可以将数值压缩到 $0 wave 1$ 之间然后乘以 $65535$ 用 $16bit$ unsigned integer 表示
  - 且利用 normalization 的特性，取四个值中最大的并用 $2bit$ 指示（通过 $1$ 减去剩下三个值得到），剩下的三个值均在 $[-sqrt(2)/2, sqrt(2)/2]$ 之间，各用 $15bits$ 来表示，总共用 $47bits (-> 48bits)$ 表示原本 $128bits$ 的四元数
- *压缩误差*
  - 骨骼使用从起点局部定义到叶节点的方法，压缩误差不断累积，需要有方法进行*量化*并反向偏移来补偿（但也会导致新的抖动问题）
  - 最简单的方法自然是对 Translation, Rotation, Scale 施加 L1 / L2 的 loss，但不同骨骼对误差敏感度不同，且不符合人眼感受
  - 实际可用的是视觉误差 Visual Error，对每个关节定义两个 Fake Vertex，通过 offset 控制距离，如果精度敏感就设置大一些，只需对比这两个点压缩前后的误差

= 高级动画技术：动画树、IK 和表情动画
== 动画混合
- *混合中的数学 —— 线性插值*
  - 动画 blend 需要在不同 clip 之间线性插值，需要一个权重表示比例。以跑步为例，用当前速度和步行 clip 的速度、跑步 clip 的速度计算权重即可
  - 对齐混合时间线，blend 需要每个动画循环播放，因此时间线必须一致。比如跑步和走路要左右脚各一次循环，脚的落地时间一致（跑 $1.5s$、走 $3s$）。插值时从 clip1, clip2 对应帧取 pose
- *混合空间 Blend Space*
  - 1D Blend Space
    - 以走路为例，在直走、向左以及向右等多个 clips 中插值，变量只有移动方向因此为一维混合
    - 但采样点可以有多个，插值也不一定是线性、均匀的
  - 2D Blend Space
    - 依旧以走路为例，如果除了角度，行走速度也可以变化，就成为二维混合空间
    - *Delaunay Triangulation 三角网格化*
      - clip 在空间中的分布往往是非均匀的（以走路为例，侧向行走时速度超过一个较低阈值马上就会进入跑步，否则无法保持平衡）。另一个问题是 clip 之间的插值成本较高，我们不希望由于分布的非均匀性导致某个点需要在很多个 clips 之间插值
      - 德劳内三角化方法把 clips 化成不同三角形，根据点在某个三角形内的重心坐标进行插值，限制插值的 clips 数量
- *Skeleton Masked Blending 骨骼遮罩混合*
  - 很多动画值影响局部，可以用 blend mask 遮住无关部分。从而可以做上下半身动画的同时播放，还能减少 blend 计算量
- *Addictive Blending*
  - 使用一个差值形成的 difference clip，直接加在其它 clip 上，如加上旋转或缩放
  - 使用和制作需要谨慎，因为随意增加差值容易带来人体超自然扭曲问题

== 动画状态机与混合树 Animation State Machine and Blend Tree
- 一些动画之间存在逻辑关系、顺序关系而不能任意插值，比如 jump 分为“起跳”、“滞空”、“落地”三个部分，这时自然要引入动画状态机
- 下面的部分主要是以 UE 的实现为例（因为做得比较好，自由灵活且交互符合直觉）；Unity 也有类似实现如 Animator Controller，但设计上不够方便，而新兴的 playable API 还不够成熟
- *动画状态机 Animation State Machine (ASM)*
  - 包含 node 和 transition
  - node 可以是单个 clip，也可以是一整个 blend space 打包成的节点（比如 UE 的一整个动画蓝图），总之是一个可以循环的 state
  - transition 是两个 node 之间的连接，涉及如何 blend 以及触发条件的问题
    - transition 的时间，一般是一个 magic number $0.2s$
    - transition cross fades，一般有两种方式 —— 常规 smooth transition 和 frozen transition
      - 实现上一般用不同的 cross fade curves，最常用的就是 linear 和 ease in out
- *Layered ASM*
  - 把角色的不同部位分成不同的状态机来管理，从而让整个动画看起来更灵活流畅
  - 如 Devil May 5，角色上半身进行复杂攻击，下半身跑跳，还有一层受击反应
- *动画混合树 Animation Blend Tree*
  - 其思想最初来源于表达式树，从一个 output 节点单向展开，不同 clip 之间做 “四则运算”
  - 叶子节点可以是 Clip / Blend Space / ASM，是一个递归的结构
  - 非叶节点是 blend node，可以做很多灵活操作
    + Lerp: 二通道、多通道等
    + Masked Add: 实现上面的 Layered ASM
    + Addictive Add: 实现上面的 Addictive Blending
  - 动画树的核心作用是*控制变量* (control parameters)，暴露给外面的 GamePlay 系统来控制决定动画的混合行为以及最终的动画展现
    - 变量有两种，一种是速度体力血量等环境变量，一种是根据 event 事件触发调整的变量（类似 private data）
    - 引擎中有大量专门的计算结构根据这些变量来计算每个 blend 的百分比

== Inverse Kinematics 反向动力学
- *FK and IK*
  - 前述根据骨骼运动驱动 mesh 的方法属于正向动力学 (Forward Kinematics)，而 IK 则是要求 mesh 最终要达到的位置，反解出过程中的运动
  - 典型例子比如用手抓把手或者走在不平的地上，这时的约束点被称为末端效果器 End Effector
#grid(
  columns: (80%, 30%),
  column-gutter: 1em,
  [
- *Two Bones IK*
  - 走路时，大腿、小腿长度 $a, b$ 固定（所以其实是 $3$ 个关节点，两个刚体骨骼），如果确定了脚踩阶梯的位置，跨部到阶梯的距离 $c$ 也可计算，于是可以确定大腿抬起的角度 $th$
  - 但由于这样求解本质是两个球的交点，解是一个圆环（可能会内八或外八），此时需要美术提供一个参考方向 reference vector 找到唯一解
- *Multi-Joint IK*
  - 实际情况中 IK 远比 Two Bones 复杂，主要有两个难点
    + 自由度太高，计算花费高：需要实时计算高维非线性（包括旋转、平移、放缩）方程的解
    + 解有无穷多个：确定了首尾两个目标点，中间的关节点可以随意移动
  - 在解 IK 之前，很重要的一点是判断可达性 (Reachability)，不能达到分两种情况：
    + （太远）所有关节的长度加起来也达不到目标点
    + （太近）全身最长的骨骼比其他骨骼的长度加起来都大，即近处盲区
  - 以及 Multi-Joint IK 还有个难点是人体骨骼种类与旋转的多样性
    - Hinge, Ball-and-socket, Pivot, Saddle, Condyloid, Gliding
    - 例如，手指指节是 hinge joint，只能往手心转且旋转角度有限。错误的处理会导致很离谱的扭曲
  - 于是我们常常使用启发式算法求近似解，不追求全局最优，且常常利用迭代法
  ],
  image("/public/assets/CG/GAMES104/2025-03-30-19-59-05.png", width: 50%),
)
- *CCD (Cyclic Coordinate Decent)*
  - 在 orientation space 上求解，从最末端节点开始向父节点依次遍历，每次尽可能旋转使其离目标点最近（到达该节点与目标点连线），多次迭代得到一个近似解。如果超过设定迭代次数还没有收敛，就认为不可达
  - 优化
    + 限制每次旋转角度 (within tolerance regions)，避免一开始就转得太多（造成类似于 “头过去了但腰还笔直杵在原地” 的非自然情况），让整个旋转尽量均摊到每个关节上
    + 让越靠近根节点的关节旋转角度越小（这两点其实都有点类似机器学习中的学习率）
- *FABRIK (Forward and Backward Reaching Inverse Kinematics)*
  - 在 position space 上求解，具体步骤
    + Forward: 首先将最末端节点强行拉到目标位置。这时骨骼变长，不管，把它拉到末端节点和父节点连线上，表现为戳出去一段长度；随后把父节点移动到骨骼拉长后的位置，导致它跟父节点相连的骨骼也变长……以此类推（也可能不是变长而是变短，anyway，一个意思）
    + Backward: 反向迭代，从根节点开始移回原位置，也会造成骨骼长度变化的连锁反应
    + 多次重复 forward, backward 迭代，直到收敛。如果超过设定迭代次数还没有收敛，就认为不可达
  - FABRIK 也能添加约束：骨骼垂直于 target 形成一个平面，与 range of rotation 形成交点，作为 reposition target
- *IK with Multiple End-Effectors*
  - 前面只考虑了单一约束点（末端约束），但实际应用中如《塞尔达传说：荒野之息》中的爬墙，双手双脚都被约束。此时，视图把一个点移到目标点可能导致其它已经就位的节点又偏移开。在 CCD, FABRIK 中有对应多 constraint 的解决办法，但并非最优解
  - 比较推荐的解法是把关节点的位置和目标位置视作一个向量方程，*用 Jacobian Matrix 以类似梯度下降的方式*求解
    - 即每次从当前点往 Jacobian 的方向（梯度方向）走一小步，一次次迭代 hit 到目标点
    - 算是多约束 IK 在游戏引擎中的标准解法，但计算量稍大，因此也有不少优化
    - 在后续物理系统会详细介绍
- *Other IK Solutions*
  - Physics-based Method：更自然，但计算量大
  - PBD (Position Base Dynamics): 和传统的基于物理的方法不同，有更好的视觉表现，以及更低的计算花费。UE5 中的 Fullbody IK 就是 XPBD (Extended PBD)
- *IK Still in Challenge*
  + IK 假设关节是一个个点，骨骼是一条条线段，都没有体积，但实际上在蒙皮之后可能出现重叠、穿插等问题
  + IK with predication 很难做。比如人物移动中弯腰躲避障碍，不可能是撞到了才变化而是提前预知。目前游戏中这种自然的变化都是动画师预先设计好的
  + 更自然的人类行为很难做，如中心平衡、支撑等，可能需要 data-driven、深度学习的介入
- 考虑 IK 后的动画制作 pipeline，在 Post-Processing 中让动画符合环境的约束
  #fig("/public/assets/CG/GAMES104/2025-03-30-22-17-41.png", width: 60%)

== 面部动画
- Morph Target Animation
  - Facial Action Coding System
  - UV Texture Facial Animation
  - Muscle Model Animation
  - 行业天花板是 UE 的 MetaHuman

== 动画重定向 Retargeting
- 现在大多数动画都采用动捕来获取，很自然地我会希望采集到的动画能应用到不同高矮胖瘦的角色上
- 先介绍一些术语 (terminology)：
  + Source Character 原角色
  + Target Character 目标角色
  + Source Animation 原角色动画
  + Target Animation 目标动画
- *同标准骨骼结构*
  - 骨骼结构相同但蒙皮后高矮胖瘦甚至静息 A-Pose 下的倾向不同
  - 基本操作是将它们的骨骼无视具体长短一一对应，然后按 rotation, translation, scale 不同 track 分别处理
    + 对于骨骼的 rotation，需要注意只能 apply 相对角度（如果存的不是 local space 下的数据需要做一步转换）
    + 对于骨骼的 translation，会考虑两个骨骼的相对长度，然后按照长度进行等比例进行的改变
      - 这里还有一些细节。比如对于角色的移动，需要根据角色离地高度不同做适当调整，一般一角色腰线高度为准，并且位移速度也会以此适当缩放
    + 对于骨骼的 scale，也是进行比例改变
  - 还有一些特殊情况会用 IK 来解决
    - 比如总腿长一致但大小腿长度不同的角色，移动可能没什么问题（其实也会不自然），但蹲下就可能浮空或嵌地。用 IK 把脚锁在地面上可以解决该问题
    - 但一般角色会 offline 做好 retargeting，因此问题不算太大
  - 最后的最后，如果还不行，就辛苦美术手动调整一下吧
- *不同标准骨骼重定向*
  - NVIDIA 的 Omniverse: 使用骨骼映射的方法，非常符合直觉。先把找到名字相同的 shared skeleton，把它们的长度归一化；随后针对 target 骨骼，去找每个骨骼对应 source 的位置，并适当调整。最终形成虽然不一一对应，但大致位置形状类似的结果
    #fig("/public/assets/CG/GAMES104/2025-03-30-22-51-56.png", width: 80%)
  - 此外还可能有一些涉及深度学习的方法
- *动画重定向的挑战*
  + IK 那里提到的自穿插、重叠问题，以及自然行为问题
  + 自接触约束，比如两个角色动作相同，但由于肩宽问题导致鼓掌时无法碰到一起
  + 面部表情领域使用 Morph Animation 也要做 retargeting，此时也有比如小眼睛闭眼动画到大眼睛模型上就闭不上眼的问题，这时可以利用拉普拉斯算子模拟橡皮表面把顶点拉到闭合
