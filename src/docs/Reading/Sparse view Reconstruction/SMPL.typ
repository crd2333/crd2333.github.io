---
order: 1
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

= SMPL(A Skinned Multi-Person Linear Model)
- 时间：2015.10
- 参考 #link("https://www.cnblogs.com/sariel-sakura/p/14321818.html")[SMPL 模型学习] 和 #link("https://zhuanlan.zhihu.com/p/256358005")[SMPL 论文解读和相关基础知识介绍]
  - 等写完了之后才发现有一篇讲的最好的 #link("https://zhuanlan.zhihu.com/p/158700893")[人体动作捕捉与SMPL模型 (mocap and SMPL model)]
- 这篇文章的摘要、引言、相关工作、实验就不仔细读了，主要看一下方法部分
- 提到三维重建中的人体重建话题，SMPL 是绕不开的一个模型，影响力非常大。如果要做分类的话，它属于 explicit 方法中的 mesh-based model，因此很自然地与图形渲染引擎兼容
- 它主要是针对裸体人体的 shape（高矮胖瘦）和 pose（动作姿势）进行参数化(parametric)建模。因为 shape 参数是通过 PCA 降维出的对人体表示影响最大的几个维度，因此 SMPL 也被称为基于 statistical 的模型
- SMPL 最核心的部分就是采集了不同姿势的*真实人体网格*，要建立*形状参数*(shape)、*姿势参数*(pose)与网格(mesh)的*对应关系*，训练出这个对应关系。文章剩下的部分，就是细节了，比如 shape、pose 参数怎么处理，用什么函数等等。具体而言（下面会有点绕）：
  - 参数如何表示？
    - *Shape*: 我们知道 SMPL 把人体分解成 shape 和 pose，但 shape 很显然又受 pose 影响，所以又将 shape 进一步分解为：rest pose template 即 $bT in RR^(3N)$，再加上 identity-dependent shape 即 $B_S (beta)$ 和 non-rigid pose-dependent shape 即 $B_P (th)$
      $ T_P (beta, th) = bT + B_S (beta) + B_P (th) $
    - *Pose*: 使用 kinematic tree 表示人体的姿势，记录树上每个关节点相对父节点的旋转关系，构成 SMPL 模型的姿势参数(pose)。具体是使用*轴角*表示法（我们知道，任意旋转可以用一个“旋转轴+旋转角”刻画，这可以压缩为一个向量表示，其方向与旋转轴一致，而长度等于旋转角），即 $th = [omega_0, omega_1, ..., omega_K]$ 表示每个关节点相对父节点的轴角（除了 $omega_0$ 是根节点以外）
  - *Shape blend shapes*: 由 shape 引起的顶点偏移 $B_S (beta) in RR^(3N)$
    - 其中 $bS_n$ 是 PCA 出来的主成分，合并为 $cS$
    $ B_S (beta; cS) = sum_(n=1)^(abs(beta)) beta_n bS_n $
  - *Pose blend shapes*: 由 pose 引起的顶点偏移 $B_P (th) in RR^(3N)$
    - 用*罗德里格斯公式*把轴角 $th = [omega_0, omega_1, ..., omega_K]$ 转换为 $3 times 3$ 旋转矩阵，也就是下面那个 $9K$ 的由来，这个转换记作 $R: RR^abs(th) |-> RR^(9K)$，每个 $omega_i$ 转换结果记作 $R_n (th)$，合记为 $R(th)$。另外这里 $th^*$ 表示静息 pose，把它减掉只考虑 offset
    - $cP = [bP_1, ..., bP_(9K)] in RR^(3N times 9K)$ 意思是所有关节点的旋转与所有顶点的偏移之间的全连接（有点粗暴，作者后续练了个 Sparse SMPL，因为模型容量小了所以效果下降了一点，不过还是可以用的）
    $ B_P (th; cP) = sum_(n=1)^(9K) (R_n (th) - R_n (th^*)) bP_n $
  - *Joint Positions*: 用模型学到的参数，通过 shape 参数预测关节点位置
    - 其中 $bJ$ 是关节点位置的预测函数，$cJ$ 是模型参数的一部分（一个从 rest vertices 映射到 rest poses 的矩阵）
    $ bJ (beta; cJ,bT, cS) = cJ (bT + B_S (beta; cS)): RR^abs(beta) |-> RR^(3K) $
  - *blend-skinning*: 最后用模型学到的 blend-skinning 权重 $cW$（顶点受哪些关节点影响、影响多少）去做蒙皮
    - 模型参数：$Phi = {bT, cW, cS, cJ , cP}$
    $ M(beta,th; Phi) = W(T_P (beta, th), J(beta), th, cW) $
    - 具体而言，每个顶点 $overline(t)_i in T_P (beta,th)$ 被转化为
      $
      overline(t)'_i = [sum_(k=1)^(K) w_(k,i) G'_k (th, J(beta))] overline(t)_i \
      G'_k (th, J(beta)) = G_k (th, J(beta)) G_k (th^*, J(beta))^(-1) \
      G_k (th, J(beta)) = Pi_(j in A(k)) mat(exp(omega_j), bold(j)_j;bold(0), 1) \
      w_j = I + hat(omega)_j sin(norm(omega_j)) + hat(omega)_j^2 cos(norm(omega_j)) in RR^(3 times 3) ~~~~ "(Rodrigues’s Formula)"
      $
      - 其中 $A(k)$ 定义了关节 $k$ 的有序集合，$J(beta)$ 表示关节点位置，$G_k$ 是第 $k$ 个关节点的 world transformation，$G'_k$ 跟 $G_k$ 相比是移除了 rest pose $th^*$ 影响后的同一个变换
      - 事实上 $overline(t)_i --> overline(t)'_i$ 这一步就是标准的 LBS 算法的形式，每个权重 $w_(k,i)$ 可以理解为 pose moved 骨骼 $k$ 对 $T_p$ 中顶点 $i$ 的影响系数，每个 $G'_k$ 把静息顶点 $overline(t)_i$ 拽到某个地方
  - 具体步骤是：
    + Add shape blend shapes
    + Infer shape-dependent joint locations，根据 shape 调整 joint
    + Add pose blend shapes
    + Get the global joint location，计算关节点的全局位置
    + Do skinning，做混合蒙皮
  - 训练过程，目标是调整参数最小化数据集上顶点的重建误差，因为分解了 shape 和 pose 因此可以分开训练，但具体怎么练的没太看懂
- 图片描述
  #fig("/public/assets/Reading/Human/2024-11-03-21-25-16.png")
  + template mesh，蒙皮的 blend weights（由颜色指示），关节显示为白点
  + 只考虑 identity-driven blend shape；以及根据 shape 调整关节点位置（这张图感觉不是很明显）
  + 添加了 pose 影响的 shape，可以看到臀部有所扩展
  + 在特定 pose 下，用 dual quaternion skinning 蒙皮
- SMPL 的总体模型为
  - 输入 shape 参数 $beta$（10-D vector），pose 参数 $theta$（75-D vector，$23+1=24$ 个关节点每个 $3$ 个旋转自由度，加上根节点也就是整个人体的 $3$ 自由度 position），一共 $85$ 个参数
    - $10$ 个参数的具体物理意义和 $24$ 个关节点的具体物理位置有很多介绍，这里不赘述
  - 过程中 rest pose template $bT in RR^(3N)$、蒙皮权重 $cW$、shape 顶点偏移主成分 $cS$、rest vertices 到 rest pose 的映射 $cJ$、pose 顶点偏移 $cP$ 都是通过训练得到的
  - 最后输出一个具有 $6980$ 个顶点的 mesh，并且有了模型参数以后，我们可以调整输入参数 shape 和 pose 来控制人体
  #fig("/public/assets/Reading/Human/2025-01-25-15-28-05.png", width: 30%)

= SMPL 的衍生工作
- SMPL 影响力非常大，我们知道人体重建任务最关键的是 geometry and appearance，SMPL 成为对前者广泛应用的一个基础先验(prior)或模板(template)
  - 这类利用 SMPL 做先验的方法，使用参数化人体形状来正则化解空间。基于人类归纳的统计分布，将人体变形分解为几组低维的参数化表示（如形状、姿态）。通过对人体形变空间的低维流形嵌入，大大缩小了合理的解空间，用来对抗单目数据的歧义性。此类方法往往通过优化、回归等手段，建立图像与人体低维参数空间的映射，来实现人体重建
  - 然而，人类裸体形状还比较符合低维假设，但各式衣物的形状归属于极其高维的空问，难以参数化为低维表示。这就使得参数化人体的方法难以推广到穿衣人体之上
- 后续的工作中对 SMPL 有各种各样的叫法，mesh-based, explicit, prior, template, parametric, statistical, body mesh, human pose and shape estimation(HPS) 实际上很多都是指 SMPL 及其衍生模型
- 以及，后续还有对 SMPL 的直接扩展 —— SMPL-X，对 hand 和 face 也做了参数化表示
- 对标 SMPL 身体模型，还有 FLAME 脸部模型，加上了 Blendshape(Morph target animation) 的思想
  - 参考 #link("https://zhuanlan.zhihu.com/p/591136896")[基于FLAME的三维人脸重建技术总结]

== HPS
- 在 Sparse View Reconstruction of Human 的领域，我们希望从一张图中重建出穿衣人体的 3D 模型，甚至还希望它能动。先不考虑穿衣和动画的问题，我们知道 SMPL 是从一系列 mesh 中学出模型参数 $Phi = {bT, cW, cS, cJ , cP}$，然后通过手调 shape 和 pose 参数来控制人体。很自然地，我们会考虑能不能继承 SMPL 的 $Phi$（当然也可以不继承），然后*从单张 RGB 图像中*回归出 shape 和 pose 参数，从而重建出一个 body mesh（不带衣服），进而给后续穿衣、动画提供先验、模板呢？这就是 (single image) monocular Human Pose and Shape Estimation(HPS)
- 围绕 monocular HPS 有非常多的工作
  - 在 SMPL 出来之前，一开始基本都是 Optimize-Based 的方法，后来又变成 Learning-based 的方法（研究基于什么模态进行学习，比如 raw pixels, Surface landmarks, pose keypoints and silhouettes, semantic part segmentation）
  - 等 SMPL 出来后，因为它提供了很强的先验，所以这两种途径有点收敛到把 SMPL parametric representation 作为 regress target 的意思（也就是像上面那样直接继承 SMPL 的模型参数 $Phi = {bold(T), cal(W), cal(S), cal(J) , cal(P)}$，然后用各自的方法回归 SMPL 的参数化表示 $beta, th$）
- monocular HPS 有哪些困难？
  + 数据缺乏：缺乏大规模的 (图片，mesh) 对。现存的这种数据基本是在实验室环境采集的，这样训练的模型在真实场景、野外场景的图片上泛化性不好
  + 单视图 2D-to-3D 固有歧义性：多个 3D 姿势可能对应同样的 2D 投影。而且人类是很多样性的(bushi)，有各种各样的姿势和体态
  + 回归旋转矩阵存在困难：SMPL 的 pose space 本身就不适合作为回归目标(periodicity, non-minimal representation, discontinuities)。许多方法将其作为一个分类问题来解决（将角度分成一块一块的），这种离散化的方法牺牲了精度
- #q[ICON 作者按：ICON 现在支持 PyMAF, PARE 以及 PIXIE 三种 HPS，PARE 对遮挡好一些，PIXIE 手和脸准一些，PyMAF 最稳定，但依旧对一些很难的 case 束手无策。所以，尽管 *HPS 已经被人做烂了，围绕各种 corner case 一年能出几百篇论文*，但我们依然不能说这个问题解决了，也不能说，这个问题没有价值了，至少，对于 ICON 而言，HPS 的准确度，是一切的基础，HPS 挂了，迭代优化到猴年马月也没用]
  - 就是说 HPS 有非常多的方法，尤其是 SMPL-based，这里讲两个我稍微看了一下的论文
- *GCMR*。参考 #link("https://www.jianshu.com/p/32a493d4f482")[这篇解读]
  #fig("/public/assets/Reading/Human/2024-11-08-11-59-08.png",width: 80%)
  - 作者认为很多方法继承 SMPL 的模型参数，只回归参数表示，这是非常 self-constraint 的，因为首先 SMPL 就没有建模 hand pose, facial expression, clothes 等，而且更重要的是 SMPL 的 pose space 本身就不适合作为回归目标
  - 而 GCMR 用了一个更 hybrid 的学习方式，它不回归 SMPL 的参数化表示，而是利用 SMPL 的 template mesh $bold(T)$，用 GCN 显式建模它的拓扑结构（这是由基于 Graph 的网络特性支持的，用一般网络结构根本没法想），然后回归 mesh 上各个点坐标。具体做法就是用 CNN 提取图像特征信息，嵌入到 $bold(T)$ 的各个顶点中，然后直接 GCN 一把梭，得到最后的 mesh
  - 这里好像根本不涉及 $beta,th$ 的参数表示对吧，但是作者说，如果我们仍然需要特定的模型参数化，可以从这个 mesh 可靠地回归出来
- *HMR*。参考 #link("https://zhuanlan.zhihu.com/p/441172308")[这篇解读]
  #fig("/public/assets/Reading/Human/2024-11-08-11-59-52.png", width: 80%)
  - PS：感觉 HMR(Human Mesh Recovery) 名字取得有点高，跟 HPS 一个 level 了快233
  - HMR 如何解决前述困难？
    + 虽然缺乏成对的 (图像，mesh) 数据，但是有大量的 2D keypoints 标注的图片数据集和大量单独的 3D mesh 动捕、动画数据。HMR 的一个关键贡献就是通过一个 GAN 框架充分利用这些 unpaired 的数据。具体来说，给定一张图片，网络推导出 3D mesh 的 $beta, th$ 参数和相机参数(Generator)，然后将预测 3D mesh 投影到 2D 平面，让投影的 keypoints 和 2D keypoints 标注相匹配
    + 为了解决 2D-to-3D 的歧义性，网络推导得到的 3D mesh 的参数被送到一个 Discriminator 中，Discriminator 来判断输入的 3D 参数是网络生成的还是真实标注的。因此 Discriminator 起到了弱监督的 $la$ 作用，鼓励网络生成符合人体正常结构的参数（隐式学习每个关节的角度限制，抑制生成不合理的身体形状）
    + 为了解决 SMPL 参数回归困难的问题，HMR 使用了迭代反馈的方法来回归这些值（没看懂）
- SMPLify 和 SMPLify-X，没看，可以参考 #link("https://zhuanlan.zhihu.com/p/495059992")[SMPL、SMPL-X 模型]
- 以及 ICON, ECON 里提到的 PyMAF, PARE, PIXIE 等等，都没细看，贴一个找到的 #link("https://zhuanlan.zhihu.com/p/500070132")[PyMAF 解读]

== Canonical Space and Pose Space
- 从另外一个思路出发，SMPL 的那个 template mesh $bT$ 就是一个刨除 pose 影响下的静息姿态，我们称为在 canonical space 下；当调整了 pose 后，通过 SMPL 的蒙皮权重，我们可以将这个 template mesh 用 LBS 转换到 pose space 下
- 后续的一个思路是通过 Pose Space 与 Canonical Space 之间的转换，实现广义的“归一化”，从而方便后续的处理，容易改变人体的姿态（从一个规整的姿势去变换而不是从五花八门的姿势去变换）
- 从 HPS 得到 $beta, th$，通过 SMPL 的蒙皮权重(skinning weights)可以从 canonical space 下的 rest pose template $T$ 转化到 pose space；至于逆过来也简单，把那个算 $G'_k (th, J(beta)) = G_k (th, J(beta)) G_k (th^*, J(beta))^(-1)$ 的 $th,th^*$ 位置换一换
  - HumanNeRF 和 SHERF 就是这么做的，只不过 HumanNeRF 特殊一点，转化成了可学习的 volume 表达，而 SHERF 就直接用估计出来写死的权重去做了（因为前者是 Optimization-based，而后者是 Learning-based 的、要泛化的），具体看 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SHERF")[SHERF 笔记]

#v(2em)

#hline()
- 最后引用一个 #link("https://www.zhihu.com/question/292017089/answer/1091565390")[知乎网友的评论]（略有调整）
#q[
  - 如果你只是用它，你需要知道的是：你可以通过 pose 和 shape（也有人会加上一个 global 的 transition 项来控制整体的位移）来生成一个裸体的人体的 mesh。你可以用 SMPL 去 fitting 一个 scans, image or video，搞成优化问题(fitting)或者使用 Deep Neural Network 进行 regression。遗憾地是 SMPL 的 pose、shape 参数不含人体的 prior 知识，容易发生违背人体结构信息的错乱（主要是 pose 比较需要先验约束）
    - 在一些优化的 paper 中人们会限制关节的弯曲的角度，避免出现过于夸张的弯曲。或者对于基于已有的 mocap 数据集训练一个 GMM 模型，将当前 pose 样本与该模型的距离作为度量，避免一个 pose 偏离 pose 的基本分布（这个角度更有统计学的意味）
    - 在一些 learning 的 paper 中，人们使用 discriminator 或者训练一个 pose 上的 VAE
  - 进一步，如果你觉得 naked human body 满足不了你，可以在每个顶点施加位移向量，生成 detailed human body（也可以在 UV 空间使用一个 displacement map 进行位移）。一般来说 performance capture 或者 human 3D reconstruction 需要生成这种 detailed 的 human body 才行
    - 使用 SMPL 做这件事的一个潜在问题是，SMPL 的 blending 参数是在裸体下训练的，而你 reconstruct 有一些 details（比如衣服，头发的偏移）。如果你这时候依然使用原来的 blending 权重去 drive 这个 mesh 做动画，效果会不真实。目前(2020)流行的方法是提取出 garment mesh 的部分，使用 PBS(Physical based simulation) 去做 animation 等应用
  - 从今天来看，现在的 SMPL 其实被拓展集成了很多新的模块：
    + 能够处理抓取交互，能够与场景交互
    + 能够建模呼吸等动作 $->$ 让模型更加 realistic
    + 基于 SMPL 的 Garment 模型（最早是衣服和人体不分割 $->$ single layer; 后来衣服单独作为一层建模 $->$ 2 layers）
    + 语言描述与 SMPL 模型的对应关系（发在 TOG 上的 Body Talk: Crowdshaping Realistic 3D Avatars with Words）
    + 更加灵活的手部
    + 更加细致的面部表情(SMPL-X)
    + 将 SMPL 的模型 bind 到卡通人物或者动物上
    + 使用 SMPL 结合 differentiable renderer 来做数据合成：week-supervision/self-supervision
      - 这其中的一个例子是 Multi Garment Net，使用可微渲染进行监督。可以想见，基于 SMPL 与可微渲染器应当可以在一些任务如 reconstruction, Human Pose Estimation, Human Mesh recovery 上完成 self-supervision; 再比如 NIPS 17 Self-supervised Learning of Motion Capture，都是很规整很经典的做法
    + 等等
  - 关于应用
    + 3D pose estimation/analysis
      - 补充一下：除了大家常见的视觉信号(image/video)，MIT 的一个团队研究了使用 wifi 信号复原人体模型（进行 pose 和 shape 的估计），可见 SMPL 这类参数化模型应用的广泛之处
    + motion estimation/analysis
    + 3D reconstruction （最近再和隐函数一结合，建模效果惊奇，这篇工作叫 PaMIR，发在 TPAMI）
    + 之前的工作往往聚焦于衣服和人体，最近有一个工作 SMPLicit: Topology-aware Generative Model for Clothed People 补充了头发以及宽松衣服（以往的工作一般都是紧身衣），他们的针对宽松衣服提了通用的服装模型，可以进一步看看。
    + 为 SMPL 模型提供衣服：Tailornet: Predicting clothing in 3d as a function of human pose, shape and garment style, CVPR2020
    + 2D image/video synthesis SMPL （作为中间体指导最终的合成）
    + animation
    + 使用 SMPL 合成数据库/改进网络的监督方法，这类监督往往需要 differentiable renderer 或者简单的projection
    + SMPL 与 Neural Rendering 结合（使用点渲染 Point-based rendering）
    + human-scene contact: SMPL 人体模型与场景的联系。例如，给定一个场景的扫描数据，生成该场景下可能的人体姿态
    + 等等
]

