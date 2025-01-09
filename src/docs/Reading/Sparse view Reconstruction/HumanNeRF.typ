---
order: 4
draft: true
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Sparse view Reconstruction -- Human",
  lang: "zh",
)
#let skel = math.text("skel")
#let NR = math.text("NR")
#let pose = math.text("pose")

= HumanNeRF: Free-viewpoint Rendering of Moving People from Monocular Video
- 时间：2022.1 (CVPR2022 oral)
- 参考 #link("https://zhuanlan.zhihu.com/p/691329488")[Human-NeRF详细理解：从LBS到Human-NeRF] 和 #link("https://zhuanlan.zhihu.com/p/546465126")[论文随记 | HumanNeRF]
- 首先需要知道它干了什么
  - 输入一个单目、运动人体的视频，经过离线的逐帧分割（需要手动清理）和三维位姿估计，基于优化的方法去训练网络参数（过拟合到这个视频的人体表示），推理时在任意时刻暂停可以渲染出 360° 人体
  - 方法是数据驱动的，端到端的，需要 3D 位姿 refinement 但不需要 template model
#fig("/public/assets/reading/human/2024-11-15-12-04-34.png",width:80%)
- 基本思想是：target/observation space 下的采样点 $bx$，如果我们把它通过一个 motion field 逆变换回 canonical space $bx_c$，然后像 NeRF 那样过 MLP 得到密度和颜色，跟原本的采样点的密度和颜色应该是一一对应的
  $ F_o (bx,bp) = F_c (T(bx,bp)) $
  - 注：observation space 和 canonical space 下的点本身是一一对应，但实际上，NeRF 的一个像素对应空间中多个采样点，这就做不到一一对应了（回忆之前的 MipNeRF 等工作就是在缓解这件事情）。Anyway，虽然这是固有缺陷，但至少大方向上能用
- motion field 如何实现？
  - 第一，把 motion field 解耦成骨骼驱动的变形(Skeletal motion)和在其上的偏置(Non-rigid motion)
    $ T(bx,bp) = T_skel (bx,bp) + T_NR (T_skel (bx,bp),bp) $
    - 其中，$p = (J,Omega)$ 指 $K$ 个关节点的位置和局部关节旋转矩阵
  - 第二，参照 Vid2Actor 把 SMPL 写死的蒙皮权重改成 volume 的（与空间相关的）$w_o^i (bx)$，学习一个逆变换
- 下面跟着 pipeline 来理一遍它的算法
  + 先用离线的 3D body + camera pose 估计，出一个比较糙的 Body pose $bp=(J,Omega)$
  + *Pose Correction*: $J$ 固定，优化 $Om$。相比直接去优化 $De_Omega (bp)$，用参数为 $th_pose$ 的 MLP 根据当前 $Omega$ 去预测出更新值 $De_Omega (bp)$ 收敛更快（这有点奇怪，一般估计 SMPL 参数时，基于优化的方法会比基于学习的方法更直接来着）
    $
    De_Om (bp) = "MLP"_(th_pose) (Omega) \
    P_pose (bp) = (J, De_Om (bp) times.circle Omega)
    $
  + *Skeletal Motion*: 逆线性混合蒙皮，把 observation space 的点映射到 canonical space，怎么实现逆变换？
    $
    "Given" p=(J,Om): J={j_i}, Om={om_i}, ~~ "and predefined canonical pose" bp_c=(J^c,Om^c) \
    T_skel (bx,bp) = sum_(i=1)^K w_o^i (bx) (R_i bx + bt_i) \
    mat(R_k, bt_k;0,1) = Pi_(i in ta(k)) mat(exp(om_i^c), j_i^c;0,1) {Pi_(i in ta(k)) mat(exp(om_i), j_i;0,1)}^(-1)
    $
    - 比较 LBS 那个公式 $G'_k (th, J(beta)) = G_k (th, J(beta)) G_k (th^*, J(beta))^(-1)$，就是 $th$ 和 $th^*$ 换了个位置，也就是逆 LBS
    - $w_o^i$ 依然是对第 $i$ 个骨骼的 blend weight，只是加个 $o$ 表示是把 observation space 中的任意点 $bx$ 拉扯到 canonical space 去，而且是根据 $bx$ 可学习的；而不是原始公式中 $w^(k,i)$ 是对第 $k$ 个骨骼只对 $i in N$ 那么多个 rest pose template 顶点的 blend weight (canonical space $->$ observation space)
    - 但是呢，如果我们对 $N$ 张图片都去学这么一个 observation space 下的 ${w_o^i (bx)}$，很容易过拟合且泛化性不好。所以我们只学 canonical space 下的一组 $w_c^i (bx)$，然后据此推出 $w_o^i (bx)$
      $ w_o^i (bx) = frac(w_c^i (R_i bx + bt_i), sumkK w_c^k (R_k bx + bt_k)) $
      - 这个又怎么理解呢？实际上没有 LBS 那个又局部全局又两种 space 那么绕，就是说 —— 所谓权重就是 $K$ 个骨骼不同的贡献，那把 canonical space 下的不同贡献直接拿来当 observation space 下的贡献。这可能限制了 observation space 的表达精度，但也限制了复杂度
      - 后面 SHERF 直接就没有做可学习的 volume，而是直接用了 SMPL 写死的蒙皮权重
    - 那这组 ${w_c^i (bx)}$ 又是怎么学出来的呢？
      - 最基本的想法是，用一个 MLP，输入 $bx$，输出 $K$ 个权重，作者这里说要 $K$ 次 evaluations 我没看懂。但总之，MLP 会比下面用 CNN 慢
      - 另一种想法是，把它们打包成一个 $K+1$ 通道的 CNN 来预测，用 CNN 网络结构的优势降低计算复杂度。这里再加了一个 background 通道，我们对 CNN 的输出做 channel-wise softmax，强制跨通道单位划分，视为一个分类问题，于是上式的分母 $f(bx) = sumkK w_c^k (R_k bx + bt_k)$ 可以据此视为采样点在人体表面的概率（如果很小，说明都分到背景类上去了）
      - 再进一步优化，volume 表示真的需要那么高精度吗？用 limited resolution 结合三线性插值重采样，虽然精度低一点，但能提供 smoothness 来帮助正则化
  + *Non-Rigid Motion*: 原始 observation space 下的人是穿着衣服帽子等有纹理和细节的，而骨骼驱动、混合蒙皮这些都只基于 naked body，这里我们需要把这些细节在 canonical space 下修正回来
    $
    De bx (bx,bp) = T_NR (T_skel (bx,bp),bp) \
    T_NR (bx,bp) = "MLP"_(th_NR) (ga(bx);Om)
    $
    - 好像没什么好说的，就是被 $T_skel$ 牵扯完的点，加上经典的但略微修改了的（见后）positional encoding $ga(dot)$，用 $Om$ conditioned MLP 预测一个偏移
    - 注：Pose Correction + Skeletal Motion + Non-Rigid Motion 这三步都是为了更好的实现逆 LBS 变换，让后面 NeRF Prediction 能更准
  + *NeRF Prediction*: 最后就是 NeRF 经典的 MLP（参数为 $th_c$）预测密度和颜色了，我们刚刚做了那么多把一个 observation space 下的采样点 $bx$ 映射到 canonical space 下 $bx_c$，丢进 MLP 预测出的结果可以直接当做 $bx$ 的密度和颜色
    - 体渲染就用 NeRF 那一套，不过对累计可见性的 $al$ 加了那个 $f(bx)$ 的逻辑（非表面点即使它非常可见我们也不关心）
      $ al_i = 1 - exp(-si(bx_i)De t_i) --> \ al_i = f(bx)(1 - exp(-si(bx_i)De t_i)) $
    - 采样时没用分层采样的方法，因为 SMPL body 的先验已经把采样范围限定小很多了，只在 bounding box 里面进行采样
- 然后就是怎么训练了，给定视频输入帧 ${I_1,I_2,dots,I_N}$，离线预测出的 body poses ${bp_1,bp_2,dots,bp_N}$ 和 cameras $be_1,be_2,dots,be_N$，求解
  $ argmin_Th sumiN cL{Ga[F_c (T(bx,bp_i)),be_i],I_i} $
  - 其中 $Ga$ 是一个渲染器，$cL$ 是一个 loss function，优化对象 $Th={th_c,th_skel,th_NR,th_pose}$ 是所有网络参数
  - 损失函数，以在一幅图像上采样的 $G$ 个大小为 $H times H$ 的 patch 为粒度，每个 batch 渲染 $G times H times H$ 条射线（实验采用 $G=6,H=32$）
    $ cL = cL_"LPIPS" + la cL_"MSE" $
  - 虽然分了很多步骤，但还是端到端地训练
    - 然而有一个问题是，由于 Non-Rigid Motion 在训练过程中过拟合到输入图像了，导致一部分 Skeletal Motion 也被它建模了（解耦没做好），于是最终效果变差，在 unseen views 质量下降
    - 解决办法是，从 #link("https://arxiv.org/abs/2011.12948")[Nerfies: Deformable Neural Radiance Fields] 抄了个 positional encoding 的改进，在优化开始阶段 disable non-rigid motions，慢慢地启用它（类似 Coarse-to-Fine 策略），具体来说：
      $
      ga_ta (bx) = (bx, dots, w_k (ta) sin(2^k pi bx), w_k (ta) cos(2^k pi bx), dots, w_L (ta) sin(2^L pi bx), w_L (ta) cos(2^L pi bx)) \
      w_k (ta) = frac(1-cos(clamp(ta-k,0,1)pi), 2) \
      ta(t) = L frac(max(0,t-T_s),T_e-T_s)
      $
      - $t$ 是当前 iteration，$T_s, T_e$ 分别代表什么时候开始启用和什么时候完全启用 frequency bands of positional encoding
    #q[训练神经网络不是黑盒子炼丹，是分步骤炼丹，要确保我们设计的网络正在干它该干的事情，要清楚每个网络的作用和意义，有时候这种耦合行为的解决能大幅提高训练出来的质量，使人不得不认真对待]
- 结果的话，还挺不错，达到了 SOTA。limitations 的话，我归纳了一下
  + 前面说的采样点那个缺陷；
  + 如果所有帧都不包含身体某一部分时会相应出现 artifacts；
  + 方法比较依赖初始的位姿估计；
  + 如果包含运动模糊等比较难的 case 重建出的新视图可能会失败；
  + 非刚性运动比较依赖姿势，比如衣物宽松、长发飘飘就容易寄；
  + 光照上假设漫反射，旋转一定角度后外观不会明显变化（原始 NeRF 好像也没怎么建模这方面）；
  + 最后，需要人工干预去分割视频，把那些没用或是离谱的帧给剔除掉，限制了应用的广度
- 大体就是这样，不是很复杂，挺自然、符合直觉的一个把 NeRF 应用到人体的工作，下面回到 SHERF