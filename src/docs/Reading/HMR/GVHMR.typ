#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GVHMR",
  lang: "zh",
)

#let GV = math.text("GV")
#let DGV = $De #h(-0.2em) GV$
#let view = math.text("view")
#let c2GV = math.text("c2GV")
#let root = math.text("root")
#let ts = $t s$

= World-Grounded Human Motion Recovery via Gravity-View Coordinates
- 时间：2024.9.10
- 这篇文章是周晓巍老师组的学长，也是我们 CV 导论课的助教的工作，发表在 SIGGRAPH Asia 上。SIGGRAPH 和 SIGGRAPH Asia 是计算机图形学领域的两大顶级会议，由 ACM（美国计算机协会）主办。中了 ACM 的论文需要以它的格式写 #link("https://blog.csdn.net/weixin_41971366/article/details/107722049")[CCS Concepts] 和 ACM Reference Format
- 网上找到的笔记 #link("https://blog.csdn.net/weixin_52142921/article/details/144532501")[World-Grounded Human Motion Recovery via Gravity-View Coordinates]

== 摘要
- 这篇文章着眼于从 monocular video 恢复出 world-grounded 人体运动，其主要挑战在于 world coordinate system 的不确定性（时序上）。以前的方法如何解决这一问题呢？它们通过 autoregressive 的方式预测相对运动，但有误差累计的风险。所以本文就提出一种全新的 Gravity-View (GV) coordinate system，它是通过 world gravity（因此天然跟重力方向对齐）和每帧的 camera view direction 来定义的，大大减少了 image-pose mapping 学习中的不确定性。同时，通过相机旋转方向可以把该坐标系下估计出的位姿转换回 world 坐标系下，形成全局运动序列。本文的方法无论在 camera space 还是 world-grounded space 下，无论在准确度还是速度下，都取得了 SOTA，而且是完全开源的

== 引言
- 引言第一段介绍了 HMR 是什么，尤其是 world-grounded 的限制。它要求从视频中恢复出*人体连续的动作序列*，并且是要在 world coordinate system 下，这个世界坐标系还得是 gravity-aware 的。相比起传统的每个 camera frame 对应的运动估计，它天然地就更适合用作基础数据，供给生成式模型、物理模型使用（比如 text-to-motion 生成、人形机器人模仿学习这些应用需要高质量且一致的数据）
- 第二段讲了现存方法的思路以及主要对比对象 WHAM 的不足之处。为了恢复出全局运动，一个直接的做法就是利用相机位姿来把相机坐标系下的运动转换到世界坐标系下，但这往往并不保证 gravity-aligned 且会导致误差累计。一篇 23.12 的工作 WHAM 试图用 RNN 来自回归地预测全局的相对运动，作出了巨大的改进。但它的问题在于，首先是需要好的初始化，其次是误差累计导致无法维持重力方向的一致性。本文认为，其内在的挑战源于世界坐标系定义的不确定性。给定世界坐标系下的坐标轴，任何绕着重力轴 (y-axis) 的旋转实际上都定义了合法的 gravity-aware world coordinate system
- 第三段就是介绍本文的工作。本文估计视频每帧 gravity-aware human poses，然后将它们基于 gravity constraints 组合起来以避免 gravity 方向的累计误差。这个设计背后的 insights 在于：给定一张图像，gravity-aware human pose 对我们人类而言是很容易推断出来的（朝着重力向下的方向）；并且，当我们把 y-axis 限制为重力方向后，相机旋转这么一个原本是 $3$ 自由度的问题就变成绕着 y-axis 这么一个单自由度问题，从而给定两帧之间的相机变换从直觉上就更容易。于是提出这么一个由重力方向和相机朝向所决定的 Gravity-View (GV) coordinate system 就变得顺理成章。基于此，本文提出一个网络来预测 gravity-aware human orientation；也提出了一个算法来预测 GV systems 之间的相对旋转。这样就把所有帧都对齐到一个一致的 gravity-aware world coordinate system 下了
- 第四段更细化地介绍了本文的做法。GV coordinate 的特性允许每帧的 human rotations 并行处理，在经典的 Transformer 架构上加入 Rotary Positional Embedding (RoPE)，相比传统的 absolute PE 能更好地捕捉视频帧之间的相对关系。在 inference 时，利用 mask 来限制每帧的感受野，从而避免了复杂而耗时的 sliding window，并且支持任意长度的并行推理。另外，还预测了手部和腿部的 stationary labels，用于 refine 腿部的滑动和全局轨迹
- 第五段就是常规总结贡献环节
  + 提出了 GV coordinates 和相应的恢复全局旋转的方法，避免了重力方向的累计误差
  + 提出了 RoPE 增强的 Transformer 架构，帮助泛化到长序列并改进了运动估计的质量
  + 做了详尽的实验证明这一方法不论在 in-camera 还是 world-grounded space 下达到了 SOTA

== 相关工作
- Camera-Space Human Motion Recovery
- World-Grounded Human Motion Recovery

== 方法
#fig("/public/assets/Reading/Human/2025-01-17-18-52-36.png", width:90%)
- 首先给几个形式化定义
  + 输入是单目视频
    $ {I^t}^T_(t=0) $
  + 局部（SMPL 坐标系下的） body poses 和 shape coefficents（帧共享）
    $ {th^t in RR^(21 times 3)}^T_(t=0), be in RR^10 $
  + 从 SMPL space 到 camera space 的人物轨迹，包括旋转 (orientation) 和平移 (translation)
    $ {Ga^t_c in RR^3}^T_(t=0), {ta^t_c in RR^3}^T_(t=0) $
  + 从 SMPL space 到 _gravity-aware_ world space $W$ 的人物轨迹
    $ {Ga^t_w in RR^3}^T_(t=0), {ta^t_w in RR^3}^T_(t=0) $
  - 我们的目标就是上述每一帧的 $th, be$，以及对应的分别在 in-camera 和 world-grounded space 下的描述 $Ga_c, ta_c, Ga_w, ta_w$
  5. 但是本文提出了一个作为中间步骤的 GV coordinate system
    - 定义每一帧从 SMPL space 到 GV space 的人物轨迹
      $ {Ga^t_GV in RR^3}^T_(t=0) $
      - 仅旋转，不考虑平移因为跟相机坐标系共顶点，可以理解为跟 ${ta^t_w in RR^3}^T_(t=0)$ 一样
      - 或者说，仅预测每一帧人物相对 GV system 的朝向
    - 以及 GV coordinates 之间的相对旋转（后面详细解释）
      $ {R^t_DGV}^T_(t=1) $

=== Global Trajectory Representation <global>
- 一般的 human motion recovery 只需要 ${Ga^t_c, ta^t_c}^T_(t=0)$ 就可以了；但对 world-grounded setting 而言还需要 ${Ga^t_w, ta^t_w}^T_(t=0)$
  - 这个 world space $W$ 要求四平八稳、重力朝下（即 $y$ 轴朝下），可以注意到这并非良定义的，因为绕着重力轴的任意朝向都是合法的。因此本文把 $W$ 定义为 $GV_0$，即第零帧的 GV coordinate system
- 对于 Global human trajectory，本文提出首先恢复出每帧的 gravity-aware human pose（相对 GV 坐标系），然后再把它们转化到一致的全局轨迹下
  - 这个方法的灵感正如 introduction 所述，我们人类可以很轻易地推断出一张图片中人物的朝向和重力的方向（即使这张图片是歪着拍的）；而且估计 “人物绕着重力轴的朝向旋转” 这一任务从直觉上来说就更容易且更鲁棒
- 具体来说，GV 坐标系是用重力方向和每一帧的相机朝向（即成像平面的法向量）来定义的
  - 当相机运动，则 GV 坐标系产生变化。我们可以用 DPVO (Visual Odometry) 或 GT gyro (ground truth by IMU in some datasets) 估计每帧之间的相对相机位姿 $R^t_De$，进而把所有的 GV 坐标系都转化到一个一致的 gravity-aware global space 下
  - 对于位移，像 HuMoR 和 WHAM 一样，预测出 SMPL 坐标系下 $t$ 到 $t+1$ 的人物位移，然后推导出相对 world reference frame 的位移
- *Gravity-View Coordinate System*，从重力方向和相机朝向定义 GV 坐标系步骤如下
  + $y$ 轴与重力方向对齐，即 $arrow(y) = arrow(g)$
  + 通过 $arrow(view) = [0,0,1]^T$ 和 $y$ 得到 $arrow(x) = arrow(y) times arrow(view)$
  + 通过 $arrow(x), arrow(y)$ 得到 $arrow(z) = arrow(x) times arrow(y)$
  - 这样我们就可以计算出人物在 GV 坐标系里的朝向 (SMPL to GV)
    $ Ga_GV = R_c2GV dot Ga_c = [arrow(x),arrow(y),arrow(z)]^T dot Ga_c $
- 进一步，我们需要 *Recovering Global Trajectory*，我们以 $GV_0$ 作为 world reference system $W$
  - 世界坐标系下人物中心的轨迹
    - 使用 orientations ${Ga_w^t}$ 把预测出的 local velocities $v^t_root$ 转化到 world coordinate system 下，然后累加起来
    $ ta_w^t = cases(
      [0,0,0]^T\, & t = 0 \
      sum_(i=0)^(t-1) Ga_w^i v^i_root\, ~~~ & t > 0
    ) $
    - [ ] $v_root$ 是什么？
  - 世界坐标系下人物朝向的轨迹
    $ Ga_w^t = cases(
      Ga_GV^0\, & t = 0 \
      (Pi_(i=1)^t R_DGV^i) dot Ga_GV^t ~~~ & t > 0
    ) $
  - [ ] TODO: 这里的推导我有些似懂非懂，先不写出来误人子弟了
- 这样的 GV 坐标系有什么益处呢？
  + GV 坐标系下的人物朝向对神经网络是一个 well-suited 任务（因为 GV 坐标系是根据输入图像各自确定的），同时这种方式使得最后的 global orientation 天然就是 gravity-aware 的
  + 作者还通过消融实验发现这种方式对预测 local pose 和 shape 也有益处
  + 并且，通过 GV 坐标系在 y-axis 上的一致性，消除了系统层面的累计误差
  + 同时，也减轻了相机位姿估计的潜在误差 (GT Gyro / DPVO)
  - 与 WHAM 相比，本文方法抛弃了 autoregressive 的方式，从而允许并行推断，也不需要初始化
  - *用我自己的话来说（不保证正确）*，大概就是两点：第一，利用 GV 坐标系的定义降低网络学习任务的难度，降低了相机位姿和人体位姿之间的多义性（比如，相机偏一点、人也偏一点，这是合法的，但可能性太多了，预测相对 GV 坐标系的人体位姿则大大降低了不确定性的自由度），这样理解的话，不管是相机位姿的预测还是人体位姿的预测都更鲁棒了；第二，通过 GV 坐标系消除了 y 轴方向的累计误差

#fig("/public/assets/Reading/Human/2025-01-21-15-03-57.png", width: 90%)
=== Network Design
- *Input and preprocessing*
  - 跟 WHAM 一样，首先经过预处理模块，用 off-the-shelf 工具得到四种特征
    + bounding box, from #link("https://github.com/haofanwang/CLIFF")[CLIFF]
    + 2D keypoint, from #link("https://github.com/ViTAE-Transformer/ViTPose")[ViTPose]
    + image features, from #link("https://github.com/shubham-goel/4D-Humans")[4D-Humans]（一个把 Transformer 用在 HMR 的工作）
    + relative camera rotations, from #link("https://github.com/princeton-vl/DPVO")[DPVO]
  - 然后用 individual MLPs 把它们映射到同一个维度并相加，得到 per-frame tokens ${f^t_token in RR^512}$
  - 多说一句，这个部分代码里全是 `Conditions`, `denoiser3d` 啥的，感觉像是从 Diffusion 那边的工作继承来的代码，没怎么整理就放出来了；而且输入输出跟论文里略有不一致 (bounding box & 2D keypoint)，或者是我没看懂……
- *Rotary positional embedding*
  - Transformer 利用绝对位置编码引入时序信息的操作相信早已司空见惯，但是这隐含地降低了模型泛化到训练长度以外的能力（人体运动的绝对位置不确定，比如运动序列的起始点可以任意），因此这里引入了旋转位置编码 RoPE
  - RoPE 可以看 #link("https://kexue.fm/archives/8265")[原作者的博客] 和 #link("https://blog.csdn.net/v_JULY_v/article/details/134085503")[一篇 CSDN 博客] 或者 #link("https://www.zhihu.com/tardis/bd/art/647109286")[这篇知乎博客]，可能需要回顾一下传统位置编码与注意力机制（#link("https://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI/Transformer/")[我的笔记]）
    - 总之，RoPE 是一个基于复数知识自然推导出的位置编码，通过相乘而非相加的方式加入，加入后就自然引入了相对信息，详情见上述链接
  - 以 GVHMR 的 notation，Transformer 原版 PE 可以表示如下
    $
    o_i &= sum_(i in T) softmax(a^ts) W_v f_token^i \
    a^ts &= 1 / sqrt(d_k) [W_q (f_token^t + p_t)]^T [W_k (f_token^s + p_s)]
    $
  - 而 RoPE 则是
    $
    o_i &= sum_(i in T) softmax(a^ts) W_v f_token^i \
    a^ts &= (W_q f_token^t)^T R(p^s - p^t) ~ (W_k f_token^s) \
    R(p) &= mat(hat(R)(al_1^T p),,0;, dots.down,;0,,hat(R)(al_(d/2)^T p)) \
    hat(R)(th) &= mat(cos(th), -sin(th); sin(th), cos(th))
    $
    - 其中 $d$ 为注意力编码的维度（对自注意力则 QKV 都相等，这里是 $512$）；$al_i$ 为预定义的频率参数；$hat(R)(th)$ 显而易见为旋转矩阵；$p^t$ 代表第 $t$ 个 token 的时序索引
- *Receptive-field-limited attention mask*
  - 对上述自注意力的 softmax 处添加 mask
    $
    o_i &= sum_(i in T) softmax(a^ts + m^ts) W_v f_token^i \
    m^ts &= cases(0\, &"if" -L < t - s < L, - infty\, ~~~ &"otherwise")
    $
  - 于是 token $t$ 只会对相对 $L$ 步内的位置有影响，赋予模型泛化到任意长序列的能力（而不需要自回归预测如 sliding window 的方式）
- *Network outputs*
  - 经过 relative transformer 后，再用 multimask MLP 得到各个预测目标，包括
    + 弱透视相机参数 $c w$
    + 相机空间下人体朝向 $Ga_c$
    + SMPL 空间下 (local) 人体位姿 $th$
    + 全局轨迹表示 $Ga_GV$ and $v_root$
  - 对于 camera-frame 下的人体运动，这里提到利用 #link("https://github.com/haofanwang/CLIFF")[CLIFF] 的方法把 weak-perspective 相机转化为 full-perspective；对于 world-grounded 下的人体运动，就是 @global 的那一套方法
- *Post-processing*
  - 这里就是说，受 WHAM 的启发，额外预测关节的 stationary probabilities，来更进一步 refine 全局运动
  - 具体而言就是预测 hands, toes, and heels 的静止概率，然后逐帧更新 global translation 来确保静止的关节确实静止
    - 总感觉这种方法不太优雅（不太符合直觉），大家都是预测出来的，不见得 stationary probabilities 就比算出来的 global translation 更高贵（更准确）吧？只能说明算法还有待改进
  - 新的改进过后的关节位置利用逆向运动学 (inverse kinematics) 来重新计算出人体 local pose
    - 这里用了一个现成的 CCD-based IK solver（19 年的工作）
- 总体感觉是，论文里写得虽然难懂但至少还算清晰，代码里则是充斥着继承来而未做整理的感觉……

== 实验
- *Datasets and Metrics*
  - 似乎说是跟 WHAM 一样公平比较，略
- *Comparison on Global / Camera Space Motion Recovery*
  - camera-space 的 SOTA 方法是 HMR2.0 (#link("https://github.com/shubham-goel/4D-Humans")[Humans in 4D: Reconstructing and Tracking Humans with Transformers])
    - 给它加持上 DPVO 以及一个 straightforward baseline 方法从而能够也在 world-grounded 下进行比较
  - world-grounded 的 SOTA 方法是 #link("https://github.com/yohanshin/WHAM")[WHAM: Reconstructing World-grounded Humans with Accurate 3D Motion]
  - 总之就是各种指标都好云云
- *Understanding GVHMR*
  - 各种消融实验，结论是都很有益
  - Running Time，速度上 GVHMR 也有改进
