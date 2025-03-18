---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)

= PIFu: Pixel-Aligned Implicit Function for High-Resolution Clothed Human Digitization
- 时间：2019.5
- 参考了 #link("https://www.slagworld.com/index.php/archives/46/")[这篇解读]、#link("https://zhuanlan.zhihu.com/p/148509062")[这篇] 以及 #link("https://zhuanlan.zhihu.com/p/256325213")[这篇]
#fig("/public/assets/Reading/Human/2024-11-05-22-53-48.png", width: 70%)
- 先不管 RGB，PIFu 就是一个 “SHM image encoder + 预测 occupancy 的隐式函数” 训练出的端到端模型
  $ f_v (F(x),z(X)) = s $
  - 其中 $s in [0,1]$，$x = pi(X)$ 表示 3D 点 $X$ 在 2D 图片上的投影位置，$z(X)$ 表示 $X$ 在此图片中对应相机坐标系下的深度值
    - 这里我的一个疑惑点是，对于单视角输入按理说是可以不用相机内外参的，看了原论文发现此种情况假定相机是 "weak perspectie projection and the pitch angle of $0$ degree"，也就是假定相机平视，并且只需要指定一个合适的焦距 $f$ 和 3D 点的平均深度 $overline(z)$ 即可#strike[（我没看代码，但我猜后者可以从训练时的 model、推理时 Bounding Box 得到，前者应该随便指定一个合适的就行，大不了调一下？）]
  - $bF(x)=g(I(x))$ 表示输入图片 $I$ 在 $x$ 处双线性采样得到的特征向量
    - 注意这里是 pixel-aligned 特征，这也是标题的由来，作者称这样重建出的模型能更好保留图片的一些细节
  - $g(dot)$ 是一个 stacked hourglass model (SHM) image encoder
    - hourglass model 是一个长得像沙漏一样（看上面图）的对称网络，跟 U-Net 很像，也用到了 skip connection，经常用于人体姿势识别。主要 insight 是，传统卷积网络大多只使用最后一层特征，但人体姿态估计这种事情，往往需要多尺度的信息。而 stacked 就是把它们堆叠起来，复用全身关节信息来提高单个关节的识别精度
    - 这方面有挺多文章参考的（如 #link("https://blog.csdn.net/u010712012/article/details/108723210")[这篇]），我还没仔细看
  - 至于 RGB，把 $f_v$ 换成 $f_c$ 预测 $r g b in [0,255]^3$ 即可，两者一结合就得到 shape + texture
- train 阶段
  - 输入数据是 $m$ 个对应的 pair $(2D "image"，3D "mesh")$，每个 image 需要知道它的内外参或者假定相机是弱透视矩阵，以及它的 mask 信息（监督图像特征向量中哪些属于人体哪些属于背景，这可以通过 detection 很常见的 removebg 应用得到）
  - 对每一个 2D 图像输入到 encoder $g$，得到深度特征 $bF_V in RR^(h times w times c)$；对于 3D 模型，可以（均匀+表面附近高斯抖动）采样得到 $n$ 个 3D 点 ${X_1, ..., X_n}$，得到其对应 $f_v$ 真值 ${f_v^*(X_1), ..., f_v^*(X_n)}$，然后同时优化 $g$ 和 $f_v$
- inference 阶段：输入就是一张图片，图片的内外参或者假定相机是弱透视矩阵，以及图片的 mask 信息，以及该图片中人体所处的大致 Bounding Box。对 Bounding Box 进行采样得到 3D Occupacy Field，跑一遍 Marching Cube 就得到重建出的 mesh
- 另外 PIFu 也支持输入多视角图片（但此时需要对应相机内外参）及它们的 mask 信息，具体就是额外训练一个多视图推理网络 $f_2$ 把之前那个隐式函数（记作 $f_1$）对不同图片的信息聚合起来，这样信息多了自然效果更好（主要是对单视角不可见区域）

= PIFuHD: Multi-Level Pixel-Aligned Implicit Function for High-Resolution 3D Human Digitization
- 时间：2020.4 (CVPR2020 oral)
- 参考 #link("https://zhuanlan.zhihu.com/p/149657262")[这篇解读] 和 #link("https://zhuanlan.zhihu.com/p/264863982")[这篇解读]
#fig("/public/assets/Reading/Human/2024-11-07-13-41-36.png")
- 主要的 insight 是：准确地预测三维模型需要大范围的空间信息，但精细表面信息需要高维度特征信息，由于显存大小限制，大感受野和高分辨率难以两全。基于此，作者提出 *Coarse-to-Fine 框架*（先低分辨率预测大致形状，再高分辨率雕刻出细节）；同时，作者提出一个可以有效预测人体背部精细细节的解决方案 (*Normal Image*)
- *Coarse level*: 与 PIFu 类似，输入原始图片下采样之后的 $512 times 512$ 大小的图片 $I_L$，用 SHM 网络训练，输出特征分辨率是 $128 times 128$，这一部分主要关注于生成全局的几何信息。不同之处在于还添加了 $512 times 512$ 的*预测得到的*图像域的正面法相图 $F_L$ 和反面法向图 $B_L$
  $ f^L (bX) = g^L (Phi^L (x_L,I_L,F_L,B_L),Z) $
  - 其中 $bX$ 是 3D 点，投影（现在是正交投影了）到图像空间 $I_L$ 上是 $x_L$，$Z$ 是该相机视角下的深度，$Phi^L$ 是一个 SHM 提特征（也就是后面 ICON 提到的 global encoder），$g^L$ 是拟合隐式函数的 MLP
  - 这里从函数的表述上相对 PIFU 进步了些，$f(bX, I) = g (Phi(x, I) , Z)$ 可以看作是用 3D 点 $bX$ 去 query 图像 $I$ 预测出 occupancy
- *Fine level*: SHM 输入是原始的 $1024 times 1024$ 的图片 $I_H$，输出 $512 times 512$ 大小的图像特征，用大分辨率的特征图去雕琢三维模型细节。同样这里也加入了 $F_H, B_H$
  $ f^H (bX) = g^H ((x_H,I_H,F_H,B_H), Omega(X)) $
  - 其中变量 notation 是类似的，$x_H=2x_L$；$Phi^H$ 的结构跟 $Phi^L$ 是一样的，输入是 $1024$ 的图片 crop 成 $512$（*之所以能* crop 是因为卷积网络可以用滑动窗口去 train，之后用 $1024$ 的全图进行 inference；*之所以要* crop 是因为显存不够大，$24G$ 都不够用）
  - 因为做了 crop，感受野没有覆盖全图，所以在 $g^H$ 中没有直接输入投影的深度 $Z$，而是把之前 Coarse level 中 $g^L$ 的一个中间层输出（提取出的 3D embedding）拿来记作 $Omega(bX)$，包含了全局信息
- *Normal estimation*
  - 这里的 insight 是，PIFu 预测不可见区域比如说背部，会生成一个 feature-less and smooth 的表面。这有部分原因是损失函数设计使 MLP 偏爱在不确定情况下直接摆烂生成平滑表面，也有部分原因是本身这种不可见预测太难了
  - 于是自然的想法就是把难度分摊一部分到 feature extraction 阶段。具体而言，作者直接为 front 和 back 分别训练了一个 pix2pixHD 网络（对应后面 ICON 说 pix2pix 猜 normal），从 RGB 输入预测出法向图输出（这里我没看代码，但我猜是提前另外训练好这俩网络，然后嵌入到 PIFuHD 的架构中，冻住或者只允许极小调整）
  - 这个网络呢，最初是李飞飞组的一个风格迁移（或许 image $->$ normal image 也算风格迁移？）的工作提出的 #link("https://arxiv.org/abs/1603.08155")[Perceptual Losses for Real-Time Style Transfer and Super-Resolution]，用一个叫 Perceptual Loss 的东西训练，网络结构跟 FCN 挺像的
- PIFuHD 的表现非常惊艳，作者虽然只开源了 inference 代码，但依然有超级高的 stars。但是怎么说呢？*个人理解* PIFuHD 之所以效果提升更多还是 Course-to-fine 的功劳（毕竟名字都叫 HD，笑）。而正反 normal 这部分，它也是网络预测出来的，不能说就当做 ground truth（大体上是对的，但细节部分不保证）。在论文当中，作者也多次使用 plausible 这个词；另外当人不是平行于相机平面时，按照作者方式得到的正反面的法向，大概率不太合理
- 相比之下，ICON 从 SMPL body 那里得到一个更强的先验，然后交替优化，这个法向的效果*看起来*（毕竟我没跑过代码，笑）就有说服力得多