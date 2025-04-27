---
order: 5
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
#counter(heading).update(11)

= 游戏引擎中的粒子和声效系统
== Particle System 粒子系统
- Particle 在游戏中通常是一个 Sprite / 3D Model，具有 Position, Velocity, Size, Color, Lifetime...
- *Life Cycle*
  - 发射源 (Source) $->$ 产生 (Spawn) $->$ 环境交互 (Reaction to environment) $->$ 死亡 (Death)
- *Emitter 粒子发射器*
  - 控制粒子 Spawn 规则、模拟逻辑和渲染
  - 许多个 emitter 以及活着的粒子共同组成了 *Particle System*。比如火焰效果中有 flame, spark, smoke 等不同发射器，美术需要考虑如何用简单系统的组合展现复杂效果
  - spawn 规则可以有 single position spawn（向四周喷射）、area spawn（范围内随机）、mesh spawn（以 mesh 形状为基底喷射）；发射时也有频率、速度、方向等不同表现；spawn mode 可以是 Continuous（持续不断地喷发）、Burst（猛地喷发）
- *Simulate 模拟*
  - 粒子最常受到的力：Gravity, Viscous drag, Wind field 等，由于粒子不需要太严格，求解使用显式、隐式、半隐式等都可以，一般显示欧拉法计算即可
  - 除了模拟位置的变化，还可以加上 rotation, color, size 等。这些变化在早期基本预先设定好，再开放几个参数给美术即可，现在的游戏中一般就更复杂
  - 粒子与环境的互动，比如 Collision，如果直接调用物理系统会非常慢（因为粒子非常多），所以这里需要对粒子特化的高效算法
- *Particle Type*
  - 粒子不能仅仅抽象成一个质点，常见的有以下几种类型：
    + Billboard Particle
      - 广告牌 sprite，始终朝向摄像机因此看起来像 3D
    + Mesh Particle
      - 同一个 3D mesh 用各种随机值去控制 Transform，使其具有随机感
    + Ribbon Particle
      - 样条形粒子，打出一条光带。在飞行过程中不断拉出额外的一个个控制节点，然后以一定宽度连起来获得完整曲线（曲带）
      - 一般不是直接相连而是使用样条曲线插值（如 Catmull-Rom 曲线，简单且插值点过控制点）

== Particle System Rendering 粒子渲染
- Particle 渲染的问题
  - 由于其半透明特性涉及到大量的排序问题，而且其数量比起场景中的半透明物体（顶天了也就几十个）要多得多
  - 同时半透明粒子每个都需要绘制再 alpha blend，overdraw 情况非常严重，开销巨大（尤其在屏幕分辨率大且粒子布满整个屏幕的情况下，更是导致突然掉帧的性能杀手）
- 粒子排序一般有两种 Mode：
  + Global
    - 所有 emitter 的所有粒子都一起排序，结果正确但消耗巨大
  + Hierarchy
    - per system $->$ per emitter $->$ per particle (within emitter)
    - Sort rules
      + Between particles: 根据 particle 到相机距离
      + Between systems or emitters: 用 bounding box
    - 靠的相近的 emitter 会导致出现错位并且会有闪现的问题（视觉效果上影响非常大），但性能更好且相对比较好写
- 粒子与屏幕分辨率
  - 由于多数时候粒子 fuzzy 一点关系不大，所以可以用下采样的将分辨率降低后进行渲染，获得粒子的 color, alpha 后再融合到原场景中。这个思路在现代引擎中越来越流行 (DLSS)
  - 此外还可以用一些算法把某一绘制次数过多的像素上的某些粒子 cut 掉（比如离相机过近的粒子）

== GPU Particle
从前两节可以看到，粒子系统不管是模拟还是渲染都很耗性能，并且为了更好的画面效果需要海量的粒子，对 CPU 的负担很大。而 GPU 正好适合处理这种海量、并发的任务，从产生到模拟到排序都可以放入 GPU，并且读取 Z-Buffer 还更快。不过 GPU 上有一个难点是控制粒子的生命周期。

- *Intial State*
  - Particle Pool: 先建立一个粒子池，设计一个数据结构 (stack)，描述所有粒子的位置、颜色、速度、尺寸等描述信息（描述了需要使用粒子的上限数量，这样后面不断的生成、死亡都只需要操作 index）
  - Dead List: 记录当前死亡的粒子，初始时包含所有粒子序号
  - Alive List: 记录当前存活的粒子，初始时为空。当 emitter 发射 $x$ 个粒子，则从 pool 结尾取出 $x$ 个粒子放入 alive list，把 dead list 后 $x$ 个序号清空
- *Simulate*
  - 对 alive list（记作 list 0）中的每个粒子进行模拟，并建立下一帧的 alive list（记作 list 1）
  - 如果粒子在下一帧死了，就将其序号 append 到 dead list（需要保证原子性），否则保留，这样得到下一帧需要渲染的粒子列表
    - 这种操作在过去的 GPU 上不好实现，但 compute shader 允许我们在一个 batch 中设置全局变量来保值原子性
  - 并且由于数据都在 GPU 上，可以方便地进行视角剔除 frustum culling，建立 Alive List After Culling，并计算它们的距离写入 Distance buffer
- *Sort, Render and Swap Alive Lists*
  + 根据上边保存的 Distance buffer 对 Alive list After Culling 排序
    - 用什么排序算法进行 global sort？parallel mergesort，这里涉及到 ADS 里讲过的把 merge 问题转化为 rank 问题，并且这里还涉及到内存局部性的问题
  + 根据排序渲染粒子
  + 更新交换 alive list0, alive list1 以及它们的数量指针
- *Depth Buffer Collision*
  - 在 GPU 上组织粒子系统的另一个好处是可以直接拿到 Depth Buffer 在 screen space 上模拟碰撞
  - 把粒子重投影回上一帧整个 frame 的 depth buffer 上（因为这一帧的还没拿到），用读出的 depth value 和一定 thickness value 判定是否碰撞，如果发生碰撞就用屏幕空间计算出的法向将粒子反弹

在 GPU 上实现粒子系统基本已经成为现代游戏引擎的标配，不过往深了做还是有各种进阶的应用。

== Advanced Particles
- *Crowd Simulation*
  - 直接利用粒子 (Animated Particle Mesh) 来模拟人群，用简化版的 skinning（每个顶点只受一个 bone 影响）
  - 有了简单的 skeleton 和 skinning 后，就可以把所有可能的动画和不同动画代表的 particle 属性、状态全部记录到一个纹理上
  - 每个 particle 维持一个小状态机，当 particle 的属性变化时就从纹理图中找到对应的动画进行切换
- *Navigation Texture*
  - 如果我们希望所有粒子既沿着设定路径又有随机移动，最简单的想法就是所有人往一个方向走但给一点随机，但不好控制粒子人物不要走到建筑物里等
  - 可以利用 SDF 场来制作一个导航纹理图，其正负性代表建筑物的内外，给走进建筑的粒子一个反向力
  - 从而，在某个位置 spawn 一个粒子，并设定目的地和初始速度后，再搭配一些噪声，就会如同受一股力一样在地图中飘动
- *Advanced Applications*
  - 总之，以前所讲的 particle 是非常古典的应用，而现代游戏引擎中 particle 的应用已经五花八门到远远超出想象，比如 Skeleton mesh emitter, Dynamic procedural splines, Reactions to other players, Interacting with environment... PPT 中给了两个 demo 非常酷炫
- *Design Philosophy*
  - 再者，粒子系统在设计哲学上也不断演进
  - Preset Stack-Style Modules: 以前的粒子系统的行为都是预设好的，根据预设的不同类型、参数决定粒子后续的行为
    - 好处是一目了然、易于理解，非 TA 也能快速根据典型行为达成想要的效果
    - 坏处是功能固定，不好扩展，Code-based 导致不同游戏团队的代码分歧，且粒子数据不好共享
  - Graph-Based Design: 现代引擎中的每个粒子都有自己的变化、模拟、扰动，形成可参数化和共享的图形资产，各种粒子的变化形成模块化工具而非硬编码功能
  - Hybrid Design: Graphs 提供总的控制，Stacks 提供模块化行为和可读性。目前做的比较好的是 UE5 的 Niagara 粒子系统

== Sound System Basics 声效系统基础
一般来讲粒子效果系统跟声效系统是不分家的，因此这里放到一起来讲，但限于篇幅都只能是浅尝辄止。声音对于游戏的重要性自不必多说，尤其是对于沉浸感的提升，有时它可能比画面更重要，甚至可成为部分品类的灵魂（想想看电影，关掉声音只看画面可能没什么感觉，但关掉画面只听声音有时依然能想象、勾勒出画面）。

- *Terminologies*
  - Volume 音量
    - 声音在物理上就是空气压强变化，其主体是纵波（当然也导致一定的横波），在单位面积产生一定压强，也就是感受到的音量大小
    - 常用单位是分贝。分贝 $0$ 大概是 $3$ 米远一只蚊子的声音，其压强记为 $p_0$。那么分贝与声压的关系就是
      $ L = 20 log_10 (p/p_0) "dB" $
    - 人对声音的感知不是线性的，而是 $log$ 的关系（跟地震类似）
  - Pitch 尖锐度（音高）
    - 本质就是空气震动的频率，决定了声音的刺耳程度
  - Timbre 音色
    - 本质是 overtones or harmonics 的组合，同一个音调用不同乐器演奏的区别
  - Phase and Noise Cancelling 相位以及降噪
    - 降噪的原理就是用相同频率、强度但反向相位的波去中和掉噪音
  - Human Hearing Characteristic 听觉的人体感受
    - 人耳对频率的感知范围是 $20 wave 20K Hz$，对音量的感知范围是 $0 wave 130 "dB"$
    - 超出听力频率的声音虽然听不到，但还是会影响音色因而能感知到（有些电影可能会用这类技术渲染氛围）
- *Digital Sound*
  - 声音是模拟信号，需要数字化处理，涉及脉冲编码调制 Pulse-code Modulation (PCM)
  - Sampling: 采样的频率，香农定理要求我们以至少两倍的频率采样才能无损
  - Quatizing: 量化的精度，决定了声音的精细程度，可均匀划分或非均匀划分。bit depth 是每个样本中的信息位数
  - Audio Format (Encoding): 各种音乐格式，在 Quality, Storage, Multi-channel, Patent 四个维度上各有千秋，游戏中一般使用 OGG（是个有损压缩格式）

== Audio Rendering 音频渲染
三维空间中有很多声源构成一个声场，受位置、距离等因素影响，最终听到的音频表现也不同，这一过程也叫 “渲染” 但跟光学那一套不太一样。

- *Listenner*
  - 游戏中需要一个 listenner 来接受声音，需要有这些属性：
    + 位置：如果是第一人称游戏，一般就挂在 main controller 身上；如果是第三人称游戏，
    + 速度：模拟多普勒效应
    + 朝向：侧着听和正着听的效果是不同的
- *Spatialization 空间感*
  - 人是如何从声音中感知空间的？一般是通过声音的大小、到达左右耳时间差和音色差等
  - *Panning*: 调整声音在不同通道上的音量、音色、延迟来产生虚拟空间感的算法
    - Linear Panning: 线性地把声音从 left channel 移到 right channel，从而产生从左到右的空间感。但由于人对声音感知是音强的平方，会导致声音有强弱变化
    - Equal Power Panning: 用 $sin^2, cos^2$ 的比例把声音从 left channel 移到 right channel，保持音量不变
    - 上两个都是比较简单的，通过基于物理真实测算和人体心理学感知的复杂方法可以真正模拟前后左右上下的空间感。不过目前咱臭打游戏的大部分还停留在两个耳机一戴的 stereo display
- *Attenuation 声音衰弱*
  - 总体上 sound pressure 随距离以 $1\/r$ 比例衰弱，但真实情况下会更复杂，高频低频衰弱程度不同（视频中以吃鸡为例非常明显）
  - Attenuation Shape: Sphere 模拟最简单的球形衰减，Capsule 模拟河流等（离远了减弱，但沿着走向相同），Box 模拟室内声音到室外迅速衰减，Cone 模拟定向性声音（如高音喇叭）……
- *Obstruction and Occlusion 障碍物*
  - Obstruction 是指 Source 跟 Listener 之间有直接物体阻挡，但可以绕过并利用惠更斯原理传播的情形
  - Occlusion 是指 Source 跟 Listener 之间整个被挡住，只能透过传播（声音震动墙，墙再震动这边的空气）的情形
  - 这二者的声音表现是完全不同的，最简单的做法就是从 Listenner 向 Source 以不同角度做 Raycast，query 出是否被物体阻挡以及阻挡物材质对能量的吸收程度，从而蒙特卡洛积分出声音的效果
- *Reverb 混响*
  - 在教堂中对话、骑马穿过桥洞等场景下，混响对空间感的影响非常大
  - 由三个部分组成，干音 direct (dry)、回音 early reflections (echo)、尾音 late reverberations (tail)，后二者也统称湿音 wet
    - 可以类比为光照的直接光照、次级光照和无限弹射的多级光照（统称间接光照）
  - 不同材质对不同声音吸收不同 (Absorption)，空间的大小也会影响混响的延迟 (Reverberation Time)
  - 如果只有回音没有尾音，声音会非常难受，有混音声音才好听（e.g. 浴室麦霸）
  - 定义四种基本参数 Pre-delay (seconds), HF ratio, Wet level, Dry level 给声效师调节
- *Doppler Effect 多普勒效应*
  - 声源和听者之间的相对速度导致声音的频率发生变化
- *Spatialization —— Soundfield*
  - 不局限于 Listener 处声音的采集，利用 Ambisonics 技术对整个声场进行采集
  - 在 360 videos, VR 中应用广泛
- *Common Middlewares*
  - 声效引擎常见的中间件有 Fmod 和 Wwise，前者维护有点拉胯，后者在越来越受重视（3A 游戏中用的更多）
  - 同时有越来越多的游戏引擎开始自己写声效引擎（如 UE5 的 MetaSound）