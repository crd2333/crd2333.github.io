---
order: 5
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

#let DR = $cal(D R)$
#let mI = $mono(I)$
#let hcN = $hat(cN)$
#let hcJ = $hat(cJ)$
#let cZ = $cal(Z)$
#let cR = $cal(R)$
#let hcZ = $hat(cZ)$
#let front = math.text("front")
#let back = math.text("back")
#let ECON = math.text("ECON")
#let IF = math.text("IF")
#let EX = math.text("EX")

= ICON: Implicit Clothed humans Obtained from Normals
- 时间：2021.12
- 跟后面的 ECON 是同一个作者的工作

== 摘要 & 相关工作
- 摘要：当前学习 realistic 且 animatable 的 3D clothed avatars 的方法，要么基于需要 posed 3D scans，要么是用 2D 图像但只适用于“精心控制的姿态”（换句话说，姿势鲁棒性差）。相比之下，作者的目标是仅从 2D 图像中学习一个 avatar，并且是在 unconstrained poses 下。给定一组图像，作者的方法是从每张图像中估计 detailed 3D surface，然后将它们结合成一个 animatable avatar。implicit functions 非常适合完成第一个任务，因为可以捕捉到头发和衣服等细节。当前的方法姿势鲁棒性差，常常生成 broken or disembodied limbs, non-human shapes，或者缺失细节的表面。问题在于这些方法使用对 global pose 敏感的 global feature encoder。为了解决这个问题，作者提出 ICON("Implicit Clothed humans Obtained from Normals")使用局部特征。ICON 有两个主要模块，均利用了 SMPL(-X) body 模型。首先，ICON 以 SMPL(-X) normals 为条件来推断出 detailed clothed-human normals(front/back)。其次，用一个 visibility-aware 的 implicit surface regressor 生成一个人体 occupancy field（进而得到等值面即人体表面）。很重要的一点是，在推理时，一个反馈循环交替进行 —— 使用推断出的 clothed normals 优化 SMPL(-X) mesh，然后又用其优化 normals。用这种方法生成一个主体在不同姿态下的多个重建帧后，作者进一步使用 SCANimate 的修改版来生成一个 animatable avatar。数据集评估表明，即使在训练数据很少的情况下，ICON 在重建方面也优于 SOTA。此外，它对分布外样本（e.g. 野外场景下的姿态/图像和框外裁剪）更加鲁棒。ICON 向“从野外图像中重建鲁棒的 3D 穿衣人体”迈出了一步。这使得我们可以直接从视频中创建 avatar，并且 personalized 的衣服可以随着姿态而变化。模型和代码在 #link("https://icon.is.tue.mpg.de")
- 相关工作
  - Mesh-based statistical models
  - Deep implicit representations
  - Statistical models & implicit functions

== 阅读作者的解读
- #link("https://zhuanlan.zhihu.com/p/477379718")[原作者的解读]
- 原作者的解读讲了很多来龙去脉、insights、概括及延展，我这里就记录阅读作者的解读时的一些困惑，以及倒回去看相关工作中的论文（精读！）
  - 包括 PIFu, ARCH++, PaMIR, SCANimate, PIFuHD
#q[围绕“姿势水平(洋文: pose robustness)“，我会用“我今天算是得罪你们一下”，“为什么要提高姿势水平”，“如何提高姿势水平的”，“把我批判一番”，“历史的进程”这五个章节，来讲一下 ICON 的过去现在和将来。]

=== 我今天算是得罪你们一下
#q[
  首先，明确 ICON 的任务：给一张彩色图片，将二维纸片人，还原成拥有丰富几何细节的三维数字人。围绕这一任务，之前有许多基于显式表达的方法(expliclit representation: mesh, voxels, depth map & point cloud, etc)，但直到三年前PIFu (ICCV'19)第一个把隐式表达(implicit representation)用到这个问题，衣服的几何细节才终于好到 —— 艺术家愿意扔到 Blender 里面玩一玩的地步。但 PIFu 有两个严重的缺陷，速度慢+姿势鲁棒性差。我们在 MonoPort(ECCV'20) 中一定程度上解决了“速度慢”这个问题，整个推理到渲染加一块，普通显卡，可以做到 15FPS 的速度，后来我们把重建和AR做了一个结合，用 iPad 陀螺仪控制渲染的相机位姿，最后有幸获得 SIGGRAPH Real-Time Live 的 Best Show Award (SIGGRAPH 2020 有哪些不容错过的内容？)
]
- 显式表示和隐式表示可以参考 #link("http://crd2333.github.io/note/AI/3DV/Representations")[我之前的笔记]
- 关于 PIFu 因为比较经典所以还是去了解一下，见 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/PIFu%20&%20PIFuHD")[PIFu 笔记]
- 至于 ICON 作者的 MonoPort: Octree surface localization Hard Negative Mining，算是比较简单，从名字基本就了解了
  + 一是用 Octree 减少无用空间的点 query
  + 二是集中精力攻克难关，加大复杂纹理处的采样密度
#q[
  但是“姿态鲁棒性”一直没有得到很好的解决。PIFuHD 将 PIFu 做到了 4K 图片上，把数字人的几何细节又提了一个档次，但还是只能在站立/时装姿势(fashion pose)下得到满意的结果。ARCH 以及 ARCH++ 尝试把问题从姿态空间(pose space)转换到标准空间（canonical space, 把人摆成“大”字）来解决，但这种转换，首先很依赖于姿态估计(HPS)的准确性，其次，由于转换依赖于 SMPL 自带的蒙皮骨骼权重(skinning weights)，这个权重是写死的且定义在裸体上，强行用到穿衣服的人上，由动作带动的衣服褶皱细节就不那么自然。
]
- PIFuHD 是 PIFu 原作者的新作，发于 CVPR2020(oral)，见 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/PIFu%20&%20PIFuHD")[PIFuHD 笔记]
- *Human Pose and Shape estimation(HPS)*，一般都是以 SMPL 为基础去优化它的那个参数化表示，然后重建出一个 body mesh（body 的意思是不包含衣服细节和纹理）。为了理解这段话，我去详细阅读了 SMPL(2015) 并写了 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/SMPL")[SMPL 笔记]
- 并简单看了看 #link("https://zhuanlan.zhihu.com/p/443392971")[ARCH++ 的解读]，*ARCH++* 的核心思路是为每个点找到其 spatial feature 和 apperance feature
  #fig("/public/assets/Reading/human/2024-11-06-21-58-09.png",width: 90%)
  - 对 spatial feature，文章首先预测出一个带有 blending weight 的 mesh template，且可以实现 posed space 和 canonical space 的双向变换（这可以用 SMPL 或者作者之前工作 ARCH 的 "semantic deformation field"）。将 posed mesh(pose space) 变换到 template mesh(canonical space) 下，在后者的 mesh 表面均匀采点，输入到 Pointnet++ 中为每个采样点 encode 出 spatial feature。空间中任意点 $(x,y,z)$ 的特征根据这些采样点插值得到（找距离最近的 k 个点，结合距离插值）
  - 对 appearance feature，过一个 encoder 得到 feature map，再将 pose space 中的点 $(x',y',z')$ 投影到 feature map 上，查找到该点的 appearance 特征
  - 注意到 $(x,y,z)$ 和 $(x',y',z')$ 分别是 canonical space 和 pose space 下的点，两者通过 semantic deformation field 联系在一起，共同反映了同一个人体。理论上来说只需要用这两者的 feature 训练一个反映该人物几何的 occupancy field 即可（canonical space 或 pose space 都行，用 semantic deformation field 双向转换）。但可能训练难度略大或是依然不太对齐，ARCH++ 对每个人都训练了两个空间下的 occupancy filed（结构相同，参数不同的 MLP），分别用所在 space 下的 ground truth mesh 进行监督
- 不是很理解 semantic deformation field 是什么意思，找了一篇 #link("https://blog.csdn.net/weixin_42145554/article/details/119925616")[ARCH 的解读] 没看懂，自己去看了看原论文发现写得也不是很清楚，而且还不开源，服了
#q[
  另外一个思路，就是加几何先验(geometric prior)，通俗点说，就是我给你一个粗糙的人体几何，然后根据图像信息，来雕琢出来一个细致的人体几何。GeoPIFu (+estimated voxel), PaMIR (+voxelized SMPL), S3(+lidar) 都有做尝试。我尝试过直接把准确的几何先验(ground truth SMPL)灌给 PaMIR，但 PaMIR 依旧不能在训练集中没见过的姿态上（比如舞蹈，运动，功夫，跑酷等）重建出满意的结果。
]
- PaMIR 是 TPAMI2020 的工作，见 #link("http://crd2333.github.io/note/Reading/Sparse%20view%20Reconstruction/PaMIR")[PaMIR 笔记]

=== 为什么要提高姿势水平
#q[那么，有没有可能，扔掉昂贵且费时费力的扫描流程，用 PIFu 从视频中做逐帧重建(Images to Meshes)，然后把重建结果直接扔给 SCANimate 做建模呢(Meshes to Avatar)？]
- 参考 SCANimate(CVPR2021 oral) 的 #link("https://zhuanlan.zhihu.com/p/392907185")[这篇解读]
  - SCANimate 的输入是一系列穿着衣物的人体原始扫描数据(raw scans)，换句话说就是需要一个在时间域上动作各异的 ground truth mesh，*如果 ICON 重建的同一个人不同动作的 mesh 足够好*，当然就可以丢给它去输出一个 animatable avatar
  - SCANimate 主要就是定义了 canonical space 和 posed space，以及从前者到后者的 *LBS* 权重和后者到前者的 *逆 LBS* 权重，分别用 forward skinning net 和 inverse skinning net 去拟合
    $
    w(bx_i^c) = g^c (bx_i^c; Theta_1) : RR^3 |-> RR^K \
    w(bx_i^s) = g^s (bx_i^s, bz_i^s; Theta_2) : RR^3 times RR^(Z_s) |-> RR^K
    $
    - 其中 $bz_i^s$ 是一个latent embedding。按道理 $x^s$ 先 unpose 再 repose 后的结果记为 $x^p$，应该跟 $x^s$ 相等，据此提出弱监督方案，利用 geometric cycle-consistency 训练；由 ground truth mesh 预先 fit 好的 SMPL 蒙皮权重可以作为过程中的 guidance
    - 但是它这个优化目标函数我没太看懂
  - 随后训练一个 locally *pose-aware* implicit function 去预测 SDF，利用注意力机制将顶点的空间变化与相关的某些 pose feature 关联起来，其中 $W in RR^(K times K)$ 是可学习的权重映射，$theta$ 就是用于驱动 pose 的输入
    $ f(bx, (W dot g^c (bx)) compose theta) $
  - 总之就是说定义了两个空间中的转换，后续很多主打 animatable 的工作也都用了类似的思路

=== 如何提高姿势水平
#hline()
- 这里先打断一下，我们总结一下 ICON 以前的方法大概是怎么做的(PIFu, PIFuHD, PaMIR, #strike[GeoPIFu, S3], ...)
  #fig("/public/assets/Reading/Human/2024-11-07-21-59-34.png",width: 70%)
  - 对于 PIFu，它大致是用一个 2D CNN 抽图像特征。对场景中的 3D 点，其 $x,y$ 去取出对应特征，和 $z$ concate 在一起送入 MLP 预测 Occupacy 或 SDF
  - 对于在 PIFu 基础上引入 shape 先验(SMPL)的方法，大致是先重建一个糙一点的 mesh，用 3D CNN 抽场景特征，用 $x,y,z$ 去取出对应特征，代替之前的 $z$ 送入 MLP
  - 这样子做，首先这个 encoder 就挺巨大的，不好训练；其次更重要的是它们是 global encoder，模型设计的内含的 prior 压根就不适合这个任务
    - 比方说人的左手移动一下，我们当然希望提出的特征只在左手区域变一点，而其它比如脚的区域特征没什么变化。否则，“牵一发而动全身”会导致模型需要大量数据而且很难泛化
    - 但对于 global encoder，无论是 2D 还是 3D CNN，它们的感受野都不是 $1$ 而是还挺大的（SHM 网络，先变小后变大），整个模型设计就决定了它不那么 local
#hline()

#q[
  ICON 在思路上，借鉴了很多相关工作。比如 PIFuHD 里面的法向图(Normal Image)，以及和 PaMIR 一样，都用了 SMPL body 做几何空间约束，这两个信息都是不可或缺的：SMPL body 提供了一个粗糙的人体几何，而法向图则包含了丰富的衣服褶皱细节，一粗一细，相得益彰
]
#q[
  - 然后，问题就来了：
    + 怎么从图像中提取出准确且细致的 normal image？
    + 直接从图像中预测的 SMPL body 如果不准确该怎么办？
    + SMPL body 这个几何约束，该怎么用？
  - 这是三个独立的问题吗？不是，它们其实是高度相关的。
    + *SMPL 辅助 normal 预测*。pix2pix 地从 RGB 猜 normal，要在不同姿态上做到足够泛化，就需要灌进去大量的训练数据。但，既然 SMPL body 已经提供了粗糙的人体几何，这个几何也可以渲染成 body normal 的形式，那么，如果我们把这个 body normal 和 RGB 合并一下，一块扔进网络作为输入，原来 pix2pix 的问题就可以转化为 —— 用 RGB 的细节信息对粗糙的 body normal 进行形变(wraping)和雕琢(carving)最后获得 clothed normal —— 这样一个新问题，而这个问题的解决，可以不依赖于大量训练数据。
    + *normal 帮助优化 SMPL*。既然 clothed normal 可以从图像中攫取到 SMPL body 没有的几何细节，那么有没有可能用这些信息去反过来优化 SMPL body？这样，SMPL body 和 clothed normal 就可以左右手互搏，相互裨益迭代优化，body mesh 准了，normal image 就对，normal image 对了，反过来还可以进一步优化 body mesh，1+1>2，双赢，就是赢两次。
    + *扔掉 global encoder*。最后，SMPL body 和 clothed normal 都有了，即人大致的体型和衣服几何细节都有了，我们真的需要像 S3, PaMIR, GeoPIFu 那样，怼一个巨大的全局卷积神经网络(2D/3D global CNN)来提特征，然后用 Implicit MLP 雕琢出穿衣人的精细外形吗？ICON 的答案是，不需要，SDF is all you need
  - 下面这张图，展示了 ICON 整个处理管线。先从图像中预测 SMPL body，渲染出正反 body normal，与原始图像合并起来，过一个法向预测网络，出正反 clothed normal，然后对于三维空间中的点，clothed normal 取三维，body normal 上取三维（注意，这里是从 SMPL mesh 上用最近邻取的，而不是从 body normal image 中取的），SDF 取一维，一共七维，直接扔进 implict MLP，Marching Cube 取一下 $0.5$ level-set 等值面，打完收工
]
- 终于！来到 ICON 正文方法部分！
#fig("/public/assets/Reading/Human/2024-11-07-18-53-24.png")
- 上图是 ICON 的总体 pipeline
  + *HPS*。先用 HPS 模块从图像中预测 SMPL body（记作 $cM$）
    - 这里 ICON 支持 PyMAF, PARE, PIXIE, HybrlK, BEV 等。PARE 对遮挡好一些，PIXIE 手和脸准一些，PyMAF 最稳定，但依旧对一些很难的 case 束手无策
    - 论文中，作者用 PyMAF 预测出 $beta in RR^10, th in RR^(3 times K)$，其中 $N = 6890$ vertices 并且 $K = 24$ joints。另外 ICON 也支持 SMPL-X
    - 对 SMPL-X 实现，为了增强鲁棒性，作者对 shape 和 pose 参数增加了经验性的 perturbed noise，不过由于 refinement module 的存在，即使添加了 noise 性能下降也不算太多，甚至能跟用 ground truth SMPL-X 的 PaMIR 相当。总之，这样做 slightly worse for in-distribution poses, but better for out-of distribution poses
  + *SMPL body $->$ body normal*。在 weak-perspective camera 模型下(scale $s in RR$, translation $t in RR^3$)，使用 PyTorch3D differentiable renderer（记作 $DR$），把 $cM$ 渲染成正反(observable side and occluded side)两面的 body normal ${cN_front^b, cN_back^b}$
    $ DR(cM) -> {cN_front^b, cN_back^b} $
  + *body normal $->$ clothed normal*。正反 body normal 和原始图片 $mI$ concat 起来，分别送入各自的法向预测网络 $cG_front, cG_back$，出正反 clothed normal
    $
    cG_front^N (cN_front^b) -> hcN_front^c \
    cG_back^N (cN_back^b) -> hcN_back^c
    $
    - 这个 $cG^N$ 在 Implementation details 里提到跟 PIFuHD 是同一个架构，即 pix2pixHD 地用类似风格迁移的方式从 body normal 预测 clothed normal
    - 用下面的 loss 来训练 $cG^N$，其中 $cL_"pixel"$ 是 ground-truth $cN^c$ 和 $hcN^c$ 之间的 L1 loss，只有它的话会使推理的 normal 变得 blurry，加入 perceptual loss $cL_"VGG"$ 可以保持细节
    $ cL_N = cL_"pixel" + la_"VGG" cL_"VGG" $
  #grid(
      columns: (42%, 58%),
      [
        4. *Refining SMPL (if during inference)*。通过从 SMPL body 渲染出的 $cN^b$ 和预测出的 $hcN^c$ 之间的差异，以及从 $cN^b$ 和 $mI$ segmented (by #link("https://github.com/danielgatis/rembg")[rembg], a tool to remove background) 出来的轮廓(silhouette)之间的差异，来优化 $beta, th, t$
          $
          cL_"SMPL" = min_(th,beta,t)(la_(N_"diff")cL_(N_"diff") + cL_(S_"diff") ) \
          cL_(N_"diff") = abs(cN^b - hcN^c), cL_(S_"diff") = abs(cS^b - hat(cS)^c)
          $
        + *Refining normals (if during inference)*。把变得更准的 SMPL mesh 重新送入 $DR$，得到新的 $cN^b$，再送入 $cG^N$ 得到更 reliable and detailed 的 $hcN^c$
        + *Refinement loop (if during inference)*。反复迭代上面两步
          - Implementation details 里面说是迭代了 $50$ 次，每一次在 Quadro RTX 5000 GPU 上大概 $460 ms$
          - *疑问*，根据我的理解，前面得到 body mesh 和 normal 的过程，和后面根据这些重建 clothed mesh 的过程是两个分割开的模块。那后面模块训练的时候需不需要前面模块推理做 optimize-based refinement loop？
      ],
      fig("/public/assets/Reading/Human/2024-11-08-18-19-11.png", width: 80%)
    )
  7. *Local-feature extraction*。提取全局特征用于后续隐式重建，具体有以下 $3$ 种特征。对于空间中一个 query point $P$：从 SMPL mesh 上取最近邻 $P^b$，$P$ 与 $P^b$ 的 signed distance 取一维；$P^b$ 的 barycentric surface normal 取三维；根据 $P^b$ 的可见性选择从预测出的正反 clothed normal $hcN_front^c,hcN_back^c$ 取三维
    $
    cF_P = [underbrace(cF_s (P),1), underbrace(cF_n^b (P),3), underbrace(cF_n^c (P),3)] \
    cF_n^c (P) = cases(hcN_front^c (pi(P)) ~~ "if" P^b "is visible", hcN_back^c (pi(P)) ~~ "else") ~~~ "where" pi "is the projection function"
    $
    #fig("/public/assets/Reading/Human/2024-11-07-22-24-53.png", width: 60%)
    - 这里的 $cF_P$ 是独立于 global body pose 的局部特征。回忆 ICON 之前的方法，它们用 2D/3D SHM 提取出来一个不好说是什么的*全局特征*；而 ICON 这边很明确就是*只在局部敏感*的 signed distance, body normal, clothed normal
    - 这里用了 #link("https://github.com/NVIDIAGameWorks/kaolin")[kaolin] 去计算每个 point 的 signed distance $cF_s$ 和 barycentric surface normal $cF_n^b$（*疑问*，怎么算的？）
  + *Inplicit Function*。最后用一个 MLP 基于这些特征去预测 $P$ 点的 occupancy $hat(o)(P)$，与 ground truth $o(P)$ 做 MSE loss 去训练
  + *Marching Cube*。再常规地用 Marching Cube 算法重建 mesh 即可
  + *Meshes to Avatar*。最后的最后，不忘初心，把重建出的一个人不同姿态的 mesh 丢给 SCANimate 做 animatable avatar
- 最终效果还是非常好的，可以说轻松达到了 SOTA。为了确保公平比较，作者除了把 benchmark 们放出来的模型在测试集上跑了结果，还在 ICON 的框架内，重新复现了 PIFu, PaMIR。ICON 在离谱姿势、未见数据上优势明显，而且练起来非常省数据

=== 把我批判一番
#q[
  - ICON 现有的问题主要集中在这样几块：
    + 鱼和熊掌不可得兼。SMPL prior 带来了稳定性，但也破坏了 implicit function 原有的优势——几何表达的自由性，因此，对于那些离裸体比较远的部分，比如两腿之间的裙子，比如随风飞扬的外套，就挂了。而这些部分，最原始的 PIFu 不见的做的比 ICON 差，毕竟 PIFu 是没有引入任何几何先验的，总之，稳定性 vs 自由度，是一个 trade-off
    + 慢。SMPL-normal 迭代优化的设计思路，导致单张图要跑 20s 才能出来不错的结果，实时性大大折扣
    + 性能天花板受制于 HPS。重建结果受 SMPL 准确性影响极大，SMPL-Normal 的迭代优化，并不能彻底解决严重的姿势估计错误，ICON 现在支持 PyMAF, PARE 以及 PIXIE 三种 HPS，PARE 对遮挡好一些，PIXIE 手和脸准一些，PyMAF 最稳定，但依旧对一些很难的 case 束手无策。所以，尽管 HPS 已经被人做烂了，围绕各种 corner case 一年能出几百篇论文，但我们依然不能说这个问题解决了，也不能说，这个问题没有价值了，至少，对于 ICON 而言，HPS 的准确度，是一切的基础，HPS 挂了，迭代优化到猴年马月也没用
    + 几何比法向差。clothed normal 的质量和最终重建的人体几何质量，有 gap。已经有很多用户和我抱怨这件事了，normal 明明看起来很好，但 geometry 的质量就打了折扣。理论上，重建人体渲染出来的 normal image 和网络预测出来的 clothed normal 不应该有那么大差距，这块我还在 debug，希望下一个版本可以修复
]
- 字面意思比较好理解，关于第一点，因为 SMPL 给的是 naked body 的先验，这个先验还是比较强的，于是对于那些 Loose clothing 就寄了
  - 在同样使用 SMPL 作为几何先验的其他工作中，比如 PaMIR，这个 trade-off 也普遍存在（虽然 PaMIR 用了一个 trick 打了个补丁）
  - PaMIR 在 body reference optimization 阶段（根据最后的 occupancy 预测值），用最终的 occupancy 反馈去修正 SMPL 参数的时候，有个表面内外惩罚不一样的细节，不过不好说效果有多少
  - 而 ICON 是用从不完全观测(2D image)推断出的二手货 normal 去反馈 SMPL 参数，好像就没管内外的问题？不过作者后续的工作 ECON 说是更好地平衡了这个 trade-off
- 性能天花板受制于 HPS，比如 Extreme pose 或 Extreme perspective 下，同样也是由于比较依赖 SMPL 这种强先验
- “几何比法向差” 这个不理解，作者不说是 bug 吗？怎么后续开源代码里是额外加了个模块去修复呢？
  #q[在 ICON 的开源代码中，我们引入了一个后处理模块(-loop_cloth)，对于 ICON 直出的 mesh，用从图像中估计的 normal 进行“二次抛光”，这个没写在论文中，但实际效果还不错，抛光后的 mesh 较 ICON 直出的结果，拥有了更加自然的褶皱细节，面片拓扑也更规整。当然，也额外多费一点时间。]
  - 注：这个不是 bug，就是 SMPL body 和 normal map 之间 trade-off 的一个体现，所以既然 normal 更好，后续 ECON 就直接改为以 normal 为主了

=== 历史的进程
#q[
  - 基于ICON，接下来还可以做点啥：
    + ICON++，进一步提升 ICON 的重建质量，更快更细节更稳定更泛化更通用
    + 把 ICON 用到别的任务中，比如不做人了，做动物，比如用 ICON 做个数据集，基于数据集，搞个生成模型啥的
    + Wildvideo-ICON, Multiview-ICON, Multiperson-ICON
    + 扔掉 3D supervision，非监督，自监督，以及训练范式的改进，比如，E2E-ICON
]
#fig("/public/assets/Reading/Human/2024-11-10-12-07-49.png",width: 70%)
- 总结一下就是
  + 效果方面的提升（表示质量、细节质量、泛化质量、速度提升）
  + 更多方面的任务应用（多人、遮挡、野外、动物，弹幕视频、支持多视角）
  + 整个范式的改进（自/半监督、端到端）
#hline()
- 整个 pipeline 看下来，总体感觉 ICON 的过程还是比较复杂，用了好多模块（通过复杂步骤来实现各种约束增加的技术路线，相当于是说，把神经网络端到端的训练又给拆开了换成精心设计的手工特征了），不像（比如说）KaiMing 大佬的工作那种简单又极致的美感。但是每个模块的加入都有其合理性，而且消融实验也有力地证明了加得该、加得妙

== 论文十问
- 作者自己也回答了一遍并上传了 ReadPaper（乐
+ 论文试图解决什么问题？
  - PIFu, PIFuHD, PaMIR, ARCH, ARCH++，当下市面上主流的基于单张图像，使用 implicit function 进行三维穿衣人体重建的算法，虽然在站立/时装姿势下表现不错，但对于较难的人体姿态（e.g. 舞蹈，运动，功夫，跑酷），泛化性和鲁棒性极差，而单纯的对训练数据进行增广，费钱费卡，提升还很有限 $-->$ 希望能用很少一点数据，就训练出对人体姿态足够鲁棒的模型
  - 另外，随着 NASA, SCANimate, SNARF, MetaAvatar, Neural-GIF 等一系列工作爆发，如何从动态的三维人体 scan 中学出来一个 animatable neural avatar 渐渐成为一个研究热点，但高质量的动态人体扫描费钱费人工，普通用户或者没有多视角采集设备的团队很难进入这个领域 $-->$ 希望直接从单目图像视频中重建高质量三维人体模型，直接扔进已有框架，得到质量尚可的可驱动数字人
  - 作者针对这两个问题，提出了 ICON
+ 这是否是一个新的问题？
  - 是也不是。人体重建是个老问题了；从动态三维扫描中学一个可驱动数字人也是个老问题。但怎么把基于图像的人体重建的质量，提升到可以和动态三维扫描相媲美，从而让两类方法可以顺利嫁接（效果好到可以嫁接，就算新了）
+ 这篇文章要验证一个什么科学假设？
  - 强模型先验(SMPL prior)和几何表达的自由(model-free representation)之间可以找到一个平衡点
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 除了文章中几个合作者，THU 的 Yebin Liu, ETH 的 Siyu Tang，以及 MRL 的 Shunsuke Saito, Tuny Tung，MPI 的 Gerard Pons-Moll 和 Justus Thies 都值得关注
+ 论文中提到的解决方案之关键是什么？
  - 关键就是怎么彻底扔掉全局卷积模块，以及设计了一个左右手互搏的策略来迭代优化以实现 $1+1>2$ 的效果
+ 论文中的实验是如何设计的？
  - 在一个统一的框架下，复现了 PIFu, PaMIR 及各种变种，同样的训练数据，最终确保始终只有单一变量控制，最后的测试数据从 BUFF 拓展为 CAPE，这样就可以充分衡量算法在 in-/out- of distribution 的姿势下鲁棒与否
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 数据集 AGORA, CAPE，#link("https://github.com/YuliangXiu/ICON")[代码]，#link("https://icon.is.tue.mpg.de/")[主页]，#link("https://colab.research.google.com/drive/1-AWeWhPvCTBX0KfMtgtMk10uPU05ihoA?usp=sharing")[Google Colab]
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - 必要的定量和定性分析，以及AMT上用户感知测试，并对方法各模块进行了消融验证
+ 这篇论文到底有什么贡献？
  - 分而治之，巧妙设计的人工特征，有的时候比生硬地怼网络，要更高效
+ 下一步呢？有什么工作可以继续深入？
  - 单目视频，多人遮挡，系统加速，大规模跑，拓展多视角

= ECON: Explicit Clothed humans Optimized via Normal integration
- 时间：2022.12

== 摘要 & 相关工作
- 摘要：深度学习、扫描数据、Implicit Functions 推动了细节的、穿衣的 3D 人体模型技术发展，但远非完美。基于 IF 的方法能够回复自由形式的 geometry，但对于 novel poses or clothes 会产生 disembodied limbs 或 degenerate shapes。为了提高鲁棒性，现有工作使用显式参数化身体模型(SMPL)做约束，但限制了 free-form surfaces 的恢复（例如宽松衣物）。作者希望探索有机结合 implicit representation 和 explicit body regularization 特性的方法。为此作者提出两个观察：(1) 相比 full-3D surfaces，当前网络更擅长推断 detailed 2D map；(2) 参数化模型可以被视为拼接 detailed surface patches 的 "canvas"。基于此，作者的 ECON 有三个步骤：(1) 推断穿衣人体前后侧的 detailed 2D normal maps；(2) 由此恢复 2.5D 前后表面（d-BiNI，一样细节但依旧不完整），在 SMPL-X body mesh 的帮助下，将这些表面相互注册（？）；(3) 在 d-BiNI 表面之间 "inpaints" 缺失的 geometry，如果面部和手部有噪声，可以选择用 SMPL-X 的面部和手部替换。ECON 即使在宽松衣物和困难姿势下也能推断出逼真的 3D 人体。根据 CAPE 和 Renderpeople 数据集的定量评估，这超越了以前的方法。Perceptual studies 还表明，ECON 的 perceived realism 有显著提高
- 相关工作
  - Explicit-shape-based approaches
  - Implicit-function-based approaches
  - combine parametric body models with expressive implicit representations
== 阅读作者的解读
- #link("https://zhuanlan.zhihu.com/p/626295986")[原作者的解读]
- 同样，这里我就阅读一下作者解读，记录自己的困惑和理解
- ECON 写得相对没有 ICON 那么清晰了，很多细节也没讲，这里我自己把它分为“思路和动机”、“技术细节”、“问题和结论”三个部分

=== 思路和动机
- 之前 ICON 提到过 稳定性 vs 自由度 的 trade-off，所以作者这里说
  #q[PIFu(HD) 的大火，导致整个领域内大家纷纷开始卷 Implicit Function (IF)，就是因为它能做到自由拓扑。以前 mesh-based 方法揪不出来的衣服褶皱、头发纹路、开衫夹克、宽松裙子等，上了 IF 就都能搞出来了。而 ICON 虽然号称比 PIFuHD 拥有更好的泛化性，但这仅仅体现在姿态上，却以牺牲宽松衣服重建效果为代价，相当于忘记了 Clothed Human Reconstruction 这个问题的“初心”。]
- 所以作者就想有个办法，对 SMPL-X 取其精华去其糟粕，具体他是这么想的：
  #q[如果让法向图(Normal map)来主导整个重建过程，而不仅仅用来做二次抛光呢？之前的抛光，“主”是粗糙的几何，“辅”是 normal。如果主辅易位，normal 作为“主”，而粗糙几何 SMPL body 作为“辅”，这个问题会不会有更好的解法？]
  - 其实呢，还有另一个解法，那就是直接抛弃 SMPL，把 setting 降低到骨骼，这是组里学长的工作，还不太了解（还没看x）

=== 技术细节
- 总体 pipeline 如图，分 Normal Estimation, Front and Back Surface Reconstruction, Shape Completion 三步
#fig("/public/assets/reading/human/2024-11-14-11-43-04.png",width: 80%)
==== Normal Estimation
- 这部分跟 ICON 很像，或者说直接就是把 ICON 的 image-to-image translation network 搬过来
- 不过 ICON 里面提到，由于图像缺失背面信息，预测出的背面法向 $hcN_B^c$ 往往过于平滑
  - 于是 ECON 从别的论文抄了个模块，加了个 #link("https://arxiv.org/abs/1810.08771")[MRF loss]，最小化 feature space 中 predicted $hcN^c$ 和 ground truth $cN^c$ 的误差
  - 这里我没去看那篇论文，反正就是对原有 ICON 的法向预测网络加个 loss 进行 finetune
- 另外一点是 ICON 里面用到的 inference 时的 refinement loop，这里也是这样，然后利用 2D body landmarks 加了个 loss $cL_J_"diff"$
  $
  cL_"SMPL_X" = cL_N_"diff" + cL_S_"diff" + cL_J_"diff" \
  cL_J_"diff" = la_J_"diff" abs(cJ^b - hcJ^c)
  $
  - 也就是用一个 2D keypoint estimator (#link("https://arxiv.org/abs/1906.08172")[Mediapipe]) 从 RGB image $mI$ 预测出 $hcJ^c$，然后从预测的 SMPL-X $cM^b$ 重投影得到 $cJ^b$
  - 这里记号好奇怪，带 hat 的是作为参考的，而不带 hat 的才是跟要优化参数相关的
  - 工程里（细节），如果 clothing normal 和 body normal 的 mask（去除背景的有效区域）重叠小于 $50%$，说明人很有可能穿着宽松的衣服，就把 $la_J_"diff"$ 变大

==== Front and Back Surface Reconstruction (Normal Integration)
#q[
  这样就会很自然联想到 Normal Integration 这个技术路线，这是个挺古早的技术了，但本身是个 ill-posed problem，即如果
    + normal map 有悬崖，即存在不连续区域(discontinuity)，这在关节几何(articulated objects)中很常见
    + 悬崖落差未知，即 boundary condition 不明确
    + normal map 本身又是有噪声的
  那么 normal 就很难通过优化过程，唯一确定 depth，换句话说，此时 normal 与 depth，是一对多的关系
]
- 这个 normal integration 是什么意思呢？
  - 我们知道所谓 normal map 实质上就是一个 shape 为 $(3,H,W)$ 的以像素为粒度来表示 $(x,y,z)$ 法向的图像，我们把坐标对齐之后，对 $z$ 方向进行积分，自然可以得到一个 depth map，我自己画了个图来形象化展示这个过程
  #fig("/public/assets/reading/human/2024-11-14-14-31-02.png",width: 40%)
  - 思路大体是这样，但数学推导上复杂得多。ECON 这里提到的核心文章 #link("https://link.springer.com/chapter/10.1007/978-3-031-19769-7_32")[Bilateral Normal Integration] 就是考虑到 discontinuity 的问题，引入了半光滑（即表面在水平和垂直方向上单侧可微、单侧连续）的假设，引入所谓 Bilateral（双边）的概念，统一了正交和透视情况下的 normal integration 问题。具体的数学，看不懂
#q[
  但我们知道，人体是一个有很强先验信息的 articulated object。如果可以将人体先验，即 SMPL-X depth，作为一个几何软约束(soft geometric constrain)，加入到整个 Normal Integration 的优化方程中。那么不光悬崖落差有了一个大致的初始值，normal 中的噪声也被约束住了，避免因 normal noise 干扰整个积分过程，导致表面突刺 (artifacts)。同时，对于在 normal map 上连续，但 SMPL-X depth 上不连续的区域，比如两腿中间的裙子（有 normal 覆盖，没 SMPL-X depth 覆盖），可以仅在 normal 上积分的同时，尽量与 nearby surface 保持连贯性。这就是文章中提到的 d-BiNI (depth-aware BiNI)。
]

- 这里我们希望把 clothed normal maps “提升”到 2.5D 表面，希望满足：
  + 高频表面细节与预测的 clothed normal maps 一致
  + 低频表面变化，与 SMPL-X 一致（包括 discontinuities）
  + 前后轮廓的深度尽量接近
- 但是不像 PIFu 和 ICON 一样从 normal map 用 implicit 回归出表面，ECON 显式地用 variational normal integration 方法建模了 depth-normal 关系，提出了 depth-aware, silhouette-consistent bilateral normal integration (d-BiNI)
  $
  "d-BiNI"(hcN_F^c, hcN_B^c, cZ_F^b, cZ_B^b) -> hcZ_F^b, hcZ_B^b \
  min_(hcZ_F^b, hcZ_B^b) cL_n (hcZ_F^c;hcN_F^c) + cL_n (hcZ_B^c;hcZ_B^c) + la_d [cL_d (hcZ_F^c;hcZ_F^b)+cL_d (hcZ_B^c;cZ_B^b)] + la_s cL_s (hcZ_F^c;hcZ_B^c) \
  $
  - 同样，这里利用 SMPL-X 先验，把 body mesh $cM^b$ 先渲染成 front-back depth map $cZ_F^b, cZ_B^b$，然后用 clothed normal maps 去雕琢
  - 优化的 loss 分别是：由 BiNI 提出的 $cL_n$，来自 SMPL-X 的 depth prior $cL_d$，以及 front-back silhouette consistency $cL_s$
  - 具体的前向计算方法和 loss 项公式在附录里，显式地用几个矩阵去表示 depth-normal 关系，然后用神经网络的前向反向方法去优化，并且实现了 CUDA 加速
#q[整个优化过程，有一个更形象的解释——把裸体模特(SMPL-X body)慢慢地塞进一套做好的衣服(Normal map)中，把衣服撑起来。]
- 这时我们就可以理解前面说的 2.5D 是什么意思了
  - 我们得到的 front-back surface $cM_F, cM_B$ 已经超越了 clothed normal map，因为它有深度
  - 但是它还称不上是 3D，因为非正、背面的侧方向没有闭合，这就是下一步要做的事情

==== Shape Completion
#q[
  #tab 好了，现在正反两面的衣服已经被人体“撑起来”了，这个时候我们会注意到，正反两面的间隙，尤其是侧面，有缝，这就好比旗袍开叉开到了胳肢窝。所以接下来我们要做的，就是补全这个裂缝。

  在 ECON 中，我们提供了两种补全策略，一种是用类似 IF-Nets 的思路（如下图），输入 SMPL-X body 和 d-BiNI 优化出来的正反面，implicitly 做几何补全，称为 IF-Nets+，其结果我们标记为 $ECON_IF$

  另一种策略则不需要 data-driven 地去学这种补全策略，而是直接 register SMPL-X body into front & back surfaces，其结果我们标记为 $ECON_EX$ 。换言之，就是将 SMPL-X 直接进行显式形变 (explicit deformation)，直到其与 d-BiNI 优化出来的正反面完全重合。这种方法扔掉了 DL 模块，整个 pipeline 更干净，但缺乏补全未知区域的“想象力”。正反面完整时，一切正常，但遇到遮挡，优化出来的正反面本身就会有缺陷，因此形变后的 $ECON_EX$ 结果，遮挡边界处几何不连贯，遮挡处则显得“赤裸裸”。

  如果输入图片没有遮挡，我比较推荐 explicit 的策略 (use_ifnet: False)，因为快且稳定，而如果有遮挡，就不得不上 IF-Nets+ (use_ifnet: True)
]
#fig("/public/assets/reading/human/2024-11-14-15-43-23.png",width: 70%)

- 这里就是说设计了两种方法，一个快且稳定但泛化性差(EX)，一个慢且复杂(IF)
  + EX:
    - 首先把 SMPL body mesh $cM^b$ 的可见部分的三角形都删掉，得到 mesh $cM^"cull"$，包含了正反面看不到的 side-view boundaries 和被遮挡区域
    - 结合前面得到的正反表面 $cM_F, cM_B$，过一个经典的 Poisson Surface Reconstruction，得到无懈可击的重建结果 $ECON_EX$
    - 但前提是，$cM^"cull"$ 的部分不能有 clothing, hair 这种 naked body 没有建模的东西
  + IF:
    - 从一个 general-purpose shape completion method IF-Nets 设计了一个 voxelized SMPL-guided IF-Nets+
    - IF-Nets+ 用 ground-truth 3D shapes 有监督训练，把 ground truth 体素化的前后 clothed depth maps $cZ_F^c,cZ_b^c$（随机 mask 来模拟遮挡）和体素化 body mesh $cM^b$ 作为输入训练，输出 occupancy field，然后用经典的 Marching Cubes 得到 $cR_IF$
    - 这个 $cR_IF$ 已经是个 mesh 了，但却不把它作为最终结果。因为首先体素化就是个 lossy 的过程，其次 Marching Cubes 算法的分辨率受限，所以它把 ${hcZ_{F,B}^c}$ 的细节都平滑掉了，而且 face or hands 处重建很得奇怪
    - 因此这里我们把 (1) d-BiNI surfaces $cM_F,cM_B$，(2) 从 $cR_IF$ 同样删去可见区域得到的 $cM^"cull"$，以及可选的 (3) 从 SMPL body mesh 裁剪来的 face or hands，也像 EX 那样做个 Poisson Surface Reconstruction，这样才得到最终的 $ECON_IF$
  - 感觉，有点 ugly 了，尤其是用得更多的 IF。。。

=== 评价
#q[
  以上就是 ECON 的完整思路了，三步走，normal estimation + normal integration + shape completion。simple yet effective，既没有引入新的网络设计，也没有增加训练数据，连 normal estimator 都是从 ICON 继承过来的。如果说 ICON 是将 feature encoder 简化为七维度的手工特征，ECON 就是将 encoder + implicit regressor 合并为一个 explicit optimizer，这样问题本身，就从 data-driven learning，转化为一个纯优化问题。从此我们只需要关注用什么方法可以拿到更好的 normal map，就可以了。
]
- 作者自己说他让问题没有变得复杂化，但（个人认为）：
  + 首先，这是在 ICON 的基础上才有的“没有更复杂”，如果单看 ECON 这一篇，各种手工特征和细节想必让人头皮发麻。而且我是觉得相比 ICON 就是更复杂了
  + 其次，确实没有引入新的“网络设计”，但是从别的论文里拿来了不少模块，包括用前向反向方法训练的显式表示的参数（这难道不算网络吗？）。本身 ICON 已经用了很多模块了，现在更多了
  + 另外，ECON 确实把 encoder + implicit regressor 合并成一个 explicit optimizer 了，但这个 optimizer 内部的各个小步骤可不见得比原本少
  - 总之，如果从方法复杂度的角度来看，不完全认同这种用复杂步骤来实现各种约束实现效果增加的技术路线，如果说 ICON 给人感觉很精巧精致，那么 ECON 就个人感觉稍微有点过头了（我可能还得多看看别的论文是怎么做的，有没有更好的办法）。话虽这么说，效果确实好（
- 但是的但是，从另外一个层面看，作者自己是怎么想的呢？
  - 他更多的是想要去 Deep Learning 化，变得不那么 data-driven，摆脱强监督，也就能不用那么依赖数据
  - 比如下图，把 PUFu, PIFuHD, PaMIR, ICON, ECON 都抽象总结一下。后续的提 feature 和 predict 变成了非神经网络的方法，而剩下的 HPS 和 normal map 呢，可以考虑怎么把它转化到半监督、自监督的 setting 下
  #grid3(
    column-gutter: 10pt,
    fig("/public/assets/reading/human/2024-11-14-21-15-00.png"),
    fig("/public/assets/reading/human/2024-11-14-21-15-18.png"),
    fig("/public/assets/reading/human/2024-11-14-21-16-37.png")
  )
  - 其实在 ECON 前后的这段时期 (22-23)，在不限于人体的各种领域比如场景表示，已经有从 implicit 又转回到 explicit 的趋势（包括基于 NeRF 的各种工作也是），这跟 ECON 背后的这种 general insight 不谋而合
  - 而且在 ECON 发布几个月以后，3DGS 横空出世（有点佩服作者的预见性），从 implicit 又转回到 explicit 的这个过程，本身就有点 “把暴力黑盒的神经网络换成精细的、类神经网络的足够 powerful 的三维表示” 的感觉
#q[
  #tab 不同于 implicit-based methods，$ECON_EX$ 没有任何 implicit 模块，这也是标题的立意，单目穿衣人重建这个问题，不是非要上 implicit 才能保住细节，explicit 也可以的，一个数字人，显式隐式各自表述。

  而且 ECON 的三明治结构，也适用于通用物体，比如去年 3DV Best Paper Honourable Mention，Any-shot GIN，大同小异。这种三明治设计简化了重建，正反面搞定了，九成的物体几何信息就有了，留给补全模块的工作量就小很多。同时，补全能“填缝”，也能应对大面积遮挡，所以 ECON 天然地可以处理多人遮挡场景。

  同时，由于优化还是基于 SMPL-X 几何先验，所以 ECON 的结果，已经内嵌了一个严丝和缝的 SMPL-X 参数化模型，所以接下来，无论是要做皮肤裸露部位（手，脸）的替换，还是做驱动动画，都很容易。
]
- 所以，为什么 ECON 这样做可以更好地结合 SMPL-X body 和 clothed normal map 之间的那个 trade-off 呢？
  - 个人觉得，就是 Implicit 的方法更多是一个黑盒，输入给它 clothed normal map 和 body mesh normal 和 SDF 后，你也不知道它在返回输出之前做了什么，在人体的哪些部分对哪个输入比较看重等，都是未知的
  - 与之相对的，改成 Explicit 之后，首先是引入了 “把衣服撑起来” 这个先验(Inductive biase)，而且过程中的变换、参数的设置都更好由我们控制，某种程度上使得表达变得更加 powerful
- 这个三明治结构的提法倒是第一次见，感觉应该是指先集中精力克服大部分难关，然后补全小问题的这种思路
- 随后，因为补全填缝的思路而天然能够处理多人遮挡、因为基于 SMPL-X 先验而能够做替换和动画，这都是意外之喜了

#q[
  尽管有各种问题，（但个人认为），ECON 依旧是目前为止，泛化性最好的，单图穿衣人重建算法，我们在 AMT 上花了六百欧做了上千组 perception study，最后的结论是——除了在 fashion images 上和 PIFuHD 打了个平手，其他所有的 hard cases，challenging poses or loose clothing，ECON 的重建质量一骑绝尘。

  而 fashion images 上打平手的主要原因，主要还是因为这个屈腿的问题，所以，只要 SMPL-X estimate 可以解决掉屈腿的问题（比如像 BEDLAM 那样造 synthetic data，然后用 perfect SMPL-X gt 而不是 pseudo SMPL-X gt 做训练），那么 ECON 就是六边形战士，单目穿衣人重建界的马龙（只要限定词足够多，就没人可以打败我）。
]
- 这里没什么好说的，效果确实好

== 问题和展望
#q[
  ECON 也有一些问题，比如
  + SMPL-X 对于直立站姿的预测结果往往会屈腿，这会 “带坏” ECON 的重建
  + SMPL-X 的手腕旋转如果预测错误，直接替换就会出现图示的 stitching artifacts
  4. 极端宽松的衣服下，目前 normal 预估的质量无法保证，伴随着 ECON 的重建也会有破洞
  - 至于 3.，人体和衣服之间往往是有距离的，而 ECON 的优化过程，目前没有考虑衣服的紧合度 tightness（具体实现中，我们手工设定了 thickness=2cm），导致在一些极端的情况下，人会看起来扁扁的，这个问题，或许可以通过额外预测 tightness，并将其引入到 d-BiNI 优化过程中来解决。
]
- 这些问题都挺好理解的，SMPL-X 本身的问题自然会影响到 ECON，以及极端宽松的情况本身就是很难的问题，不能苛责 ECON；至于 3. 这个问题也好解决，大不了“人肉梯度下降”手调超参（不过我感觉 3. 挺严重的，好多图片重建得都看起来很扁，尤其是考虑如果人体是侧着重建的，那岂不是要被压成一片了）
- 论文中给出的未来工作（除了解决上述问题以外）
  + *neural avatars*: 目前 ECON 重建的只是 3D geometry，可以进一步恢复出骨架和 skinning weights，得到 fully-animatable avatar（这点 ECON 后面其实已经做了）。另外，考虑如何生成人体背面 texture，也 avatar 构建也很有意义。以及，从重建的 geometry 中分离出衣服、发型、配饰等，可以用来做模拟、合成、编辑和风格迁移等任务。总而言之，ECON 的重建结果以及它底下的 SMPL-X body，可以作为 3D shape prior 来学习 neural avatars（就跟 ICON 后续丢给 SCANimate 一样）
  + *data augmentation*: 现有的 real clothed humans with 3D ground truth 数据集很有限，比如 RenderPeople 和 CAPE；而跟 3D 不搭边的 2D 图像数据集就数不胜数了。ECON 可以用来从图片中恢复出 normal maps 或者 3D humans，从而扩大数据集，比如作者在附录里对 SHHQ 做的那样。随着 ECON-like 的方法逐渐成熟，大量数据就可以赋能 generative models of 3D clothed avatars 的训练，在海量数据上 scale up
  + *negative impact*: 随着重建技术的成熟，低成本的逼真 avatar 制作技术也会逐渐成熟。虽然这种技术对娱乐、电影制作、远程会议和未来元宇宙应用有益，但也会促进 deep-fake avatar 的制作。所以必须建立规范云云
  - 以及再补充一下，ICON 那边提到的 —— 效果方面的提升、更多方面的任务应用、整个范式的改进等都还是能做的

== 论文十问
- 同样，作者自己也回答了一遍并上传了 ReadPaper
+ 论文试图解决什么问题？
  - ICON (CVPR22) 从单张图片中重建的人物几何，其 mesh 的质量，相比于其预测的 normal map，有明显的差距，对于宽松衣服，这种落差尤其明显。ECON 重新思考人物单目重建这个问题，既然 normal map 包含丰富的几何表面细节，而 SMPL-X 本身又提供了足够的人体结构姿态先验，那么，有没有可能从 normal map 出发，结合已有的 SMPL-X，直接“优化”出拥有更好细节及灵活拓扑的三维人物
+ 这是否是一个新的问题？
  - 单目人物重建这个问题，不新；三明治结构做重建这个思路，不新；用 IF-Nets 做补全，不新；Normal Integration，不新；但把以上几点有机地融合到一块，最终实现 ECON 这样的效果，还是蛮新的
+ 这篇文章要验证一个什么科学假设？
  - 单目人物重建三大要素: details (normal), pose (SMPL-X), continuity (poisson)。两味原料，一勺汤，三者完备，直接上优化，不需要 data-driven，就可以解决这个问题
+ 有哪些相关研究？如何归类？谁是这一课题在领域内值得关注的研究员？
  - 这个子领域，对作者启发比较大的几位研究者：Shunsuke Saito, Zerong Zheng, Zeng Huang。当然 #link("http://xiuyuliang.cn/")[作者本人] 也值得关注:)
+ 论文中提到的解决方案之关键是什么？
  - 关键在于扫到了 Xu Cao 的 BiNI(Bilateral normal integration.” European Conference on Computer Vision. Springer, Cham, 2022) 这篇论文，作者将深度信息加入进去，增加了正反面联合优化，叫 d-BiNI，这是 ECON 的核心组件，其他的模块是赠送的
+ 论文中的实验是如何设计的？
  - 比了很多 SOTA，ECON 当然是新 SOTA，但我依然建议大家忽略这块，原因有二。一，论文放出来后，开源代码里面做了诸多优化升级，现在的算法跑出来的结果，比论文中提升了不止一点点，之后有时间可能会重新跑分数。二，目前的 metric 和人眼敏感度并不协调，分数并不能充分反映最后重建的质量，所以我建议大家还是跑出结果，自己拖到 meshlab 转着看一下，你就知道和之前的方法差距多么巨大
+ 用于定量评估的数据集是什么？代码有没有开源？
  - 数据集 RenderPeople 和 CAPE。#link("https://github.com/YuliangXiu/ECON")[代码]。另外多说一句，ECON 目前支持 Windows Ubuntu Docker，也有配套的 Blender 插件
+ 论文中的实验及结果有没有很好地支持需要验证的科学假设？
  - “不能支持我做什么实验啊，这个问题好怪”（乐
+ 这篇论文到底有什么贡献？
  - 是时候重新思考 implicit 和 explicit 的表达优劣了，单目人物重建可以没有 implicit
+ 下一步呢？有什么工作可以继续深入？
  - 目前 ECON 整个 pipeline，需要强监督训练的地方有两个，SMPL-X estimator, Normal estimator，这两个如果都可以做成无监督，那么单目人物重建这个问题，就真正可以在海量的二维图像上 scale up 了，RenderPeople 已经赚的够多了，可以歇歇了
