#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

#let occ = math.text("occ")
#let unocc = math.text("unocc")
#let dst = math.text("dst")
#let src = math.text("src")
#let into = $int_Om$
#let intop = $int_(Om^+)$

= GAMES202
有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- GAMES202 也没有咋写详细笔记，可以参考这些笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 GAMES104 的内容。

== Lec1: Introduction


== Lec2: Recap of CG Basics


== Lec3/4: Real-time Shadows

- *Shadow Map*
  - 最简单的 Shadow Map 算法，用 ray casting 算 visibility，不赘述，会因为像素宽度和视角与平面垂直发生 self-occlusion 问题
  - Second-depth shadow mapping
    - 使用最小深度和次小深度的中间值，但也意味着计算阴影的时间随之翻倍
    - RTR does not trust in Complexity! 实时渲染里面，一切都看最终跑起来的效果，即使复杂度低但常数项大、系数大的算法也不一定能用（不要小看翻倍的代价）
  - Cascade Shadow Map
    - 应对大世界挑战而生的多分辨率阴影贴图
  - *RTR 积分近似方程*
    $ into f(x) g(x) dif x = frac(into f(x) dif x, into dif x) dot into g(x) dif x $
    - 它是 Shadow Map 背后的数学基础，非常重要，后续也会继续用到
      $ L_o (p, om_o) approx frac(intop V(p, om_i) dif om_i, intop dif om_i) intop L_i (p, om_i) f_r (p, om_i, om_o) cos th_i dif om_i $
    - 要求是：要么 support $Om$ 比较小，要么 $g(x)$ 比较光滑（这里的光滑不是导数意义，而是说值变化小，即较平稳的意思）
- *PCSS (Percentage Closer Soft Shadows)*
  #grid(
    columns: (43%, 20%, 30%),
    column-gutter: 8pt,
    fig("/public/assets/CG/GAMES202/2025-04-18-23-46-11.png"),
    fig("/public/assets/CG/GAMES202/2025-04-18-23-37-12.png"),
    fig("/public/assets/CG/GAMES202/2025-04-18-23-37-33.png")
  )
  - PCSS 注意到阴影的软硬程度跟这个像素到被遮挡物的距离有关，于是以自适应的方式调整 PCF 的 window 大小，达成更好的阴影效果
  - 利用那张经典的相似三角形图，利用 blocker depth 显式建模了 window 大小。具体而言，就是在 PCF 步骤之前额外查一次 blocker depth
  - 但是查 blocker depth 本身也要有一个 window 做平均，这里有用 const size 的方法，也有用启发式的方法（离光源越近则一般 window 较大）
- *VSSM (Variance Soft Shadow Map)* (a.k.a. VSM)
  - PCF 的采样过程较慢，利用泊松样斑等方法提高采样效率是一种方法；而 VSSM 是将其视为概率分布，利用均值和方差对其加速
    - 其思想是，我并不需要确切知道窗口内的深度值，只需要知道窗口内深度的排名，也就是分布内的 CDF
    - 首先，如果将其视为高斯分布（只是为了方便理解），那么只用知道 window 内的深度分布的均值和方差就确定其分布的 PDF。均值 $E(X)$ 可以用硬件上的 mipmap 实现；方差可以由 $var(X)=E(X^2)-E^2 (X)$ 得到，也就是在存深度图的时候可以另开一个 channel 存深度平方值
    - 其次，利用切比雪夫不等式估计（视为约等式），哪怕不视为高斯分布也可以直接估计出 CDF 而无需先得到 PDF
  - VSSM 同时也对 blocker search 的过程进行加速，注意这一过程我们需要计算*遮挡物的平均深度* $z_occ$，而无需考虑非遮挡物的深度 $z_unocc$，而我们能观察到下式
    $ N_1 / N z_unocc + N_2 / N z_occ = z_avg $
    - $z_avg$ 用下面介绍的 range query 方法很容易得到，而 $N_1 / N = P(x > t)$，也可以用 Chebychev 得到！
    - 至于剩下的 $z_unocc$，没办法，估计它为 $z_unocc=t$，即跟 shading point 视为同一平面（这是不得已的假设，但是是有道理的，因为绝大多数情况下我们都是在平面上算阴影）
  - 但这里要对 PCSS 和 VSSM 做个比较，后者当然是更高效的算法，但 PCSS 目前反而压过了 VSSM。这是因为我们可以用 PCSS 的低采样噪声版本，即在格子里面取部分 samples；而目前在屏幕空间的降噪技术发展得非常好，我们可以容忍一些噪声
  - *具体实现: MIPMAP and Summed-Area Variance Shadow Maps*
    - 给一个 texture 和 window size，要快速查询出每一点在窗口内的均值 (range query)，这可以用 mipmap 和 summed area table (SAT) 来实现
    - Recall mipmap: 快速的、近似的、方形的 range query。但首先它是方形的（可以用各向异性过滤解决），其次它是近似的、不准的，为此这里介绍 SAT 方法
    - SAT 与算法与数据结构中的前缀和紧密关联，总之就是需要 $O(N)$ 的预计算
    - 问题，跟原本的 PCF 采样比快在哪里？因为每个像素都是并行的，过一次 window 感觉不是很慢呀
- *Moment Shadow Map (MSM)*
  - 在 VSSM 的基础上更进一步引入*矩*的概念（VSSM 可以认为是只用了一阶和二阶矩），从而达成更准的近似（四阶）
  - 具体计算说是非常复杂，没有进一步推导
- *SDF-based Shadow*
  - SDF + ray marching $->$ safe distance
  - SDF for shadow $->$ safe angle
  #fig("/public/assets/CG/GAMES202/2025-04-18-23-51-55.png", width: 80%)
  - SDF 的存储，一般用 hierarchy 的方法存一棵树，只在物体边界的叶子附近才存值。还有一些用深度学习压缩的方法（闫令琪评价：毫无意义！）
  - 至于怎么计算 SDF，一般都认为是其它领域研究的问题（比如 CV，233），CG 这边就当作是能直接拿到的东西
  - SDF 的优势是，在做阴影层面（不考虑生成存储的情况下）对硬阴影软阴影处理相同，比 shadow map 方法快，效果也很不错；另外对于移动物体它也可以处理；但问题在于不好处理物体形变，以及 SDF 生成的物体没法做贴图

== Lec5/6: Real-time Environment Lighting
环境贴图是一种记录了场景中任意一点在不同方向上接受到的光照强度的贴图，它默认这些环境光来自无穷远，因此它所记录的强度与位置无关（这也是为什么用环境贴图渲染的时候，走到哪里都会有一种漂浮感；而且如果贴图上有个桌子，你是无法在桌子上放个物体的）。再强调一遍，*这里是环境光，四面八方都有光源，不是单独几个光源！*

目前主流的环境贴图包括 Spherical Map 和 Cube Map。类似这种处理环境光照的方法被统称为 *IBL (image-based lighting)*。

=== Basic IBL
基于环境光的方法一般不考虑 visibility，即不考虑阴影：
  $ L_o (p, om_0) = intop bbox(L_i (p, om_i)) obox(f_r (p, om_i, om_o) cos th_i) cancelbox(V(p, om_i)) dif om_i $

按照之前路径追踪的做法，解渲染方程需要借助蒙特卡洛积分去进行一个（无偏的）估计，即基于采样的方法。虽然近年来 TAA 等一系列 temporal 方法的发展使得采样对 real-time 来说不算太慢，但下面我们还是优先避免采样的方法。

- *Split-Sum 近似渲染方程*
  - Two Observation
    - 如果 BRDF 是 glossy 的，那它就满足 small support；如果是 diffuse 的，就满足 smooth
    - 正好满足 RTR 积分近似方程！于是我们把渲染方程拆成两块（环境光项和 BRDF 项），用不同的思路进行近似与预计算
      $ L_o (p, om_o) approx rbox(inset: #6pt, baseline: #12pt, frac(int_(Om_(f_r)) L_i (p, om_i) dif om_i, int_(Om_(f_r)) dif om_i)) obox(inset: #6pt, baseline: #10pt, intop f_r (p, om_i, om_o) cos th_i dif om_i) $
    - 工业界使用 sum 形式而非 intergral 形式
      $ 1/N sum_(k=1)^N frac(L_i (l_k) f(l_k,v) cos th_(l_k), p(l_k, v)) approx rbox(inset: #6pt, baseline: #12pt, 1/N sum_(k=1)^N L_i (l_k)) obox(inset: #6pt, baseline: #12pt, 1/N sum_(k=1)^N frac(f(l_k,v) cos th_(l_k), p(l_k,v))) $
  - Environment Lighting Term
    - 对于 diffuse 材质，即对整个环境贴图做平均。用球谐函数对环境贴图展开近似，然后取低阶系数即可
    - 对于 specular / glossy 材质，即在镜面反射方向的 lobe 内先采样后平均，但*先采样后平均 $approx$ 先平均后采样*。于是可以采用*预滤波 prefiltering* 方式，不同模糊等级的 mipmap 用 BRDF 来确定（实际用 roughness $al$）
  - BRDF Term
    - 基本思想仍是预计算，考虑 microfacet 的 BRDF，由 roughness $al$ 和 color (Fresnel term) 决定。而 Fresnel 项需要考虑基础反射率 $R_0$ 的三个 RGB 通道，同时跟入射角、反射角、半程向量夹角三个变量有关。这样是 $7$ 维的存储，需要进行压缩
      #fig("/public/assets/CG/GAMES101/img-2024-08-04-12-52-57.png",width: 50%)
      - Fresnel Term: Schlick Approximation
        $ F = R_0 + (1 - R_0) (1 - cos th_i)^5 $
      - NDF Term: Beckmann distribution
        $ D = frac(exp(- (tan^2 th_h) / al^2), pi al^2 cos^4 th_h) $
    - 首先，在实时渲染中，入射、反射夹角基本相等，半程向量夹角可以据此计算，三个角可以看成一个维度 ($7 -> 5$)
    - 其次，可以把基础反射率 $R_0$ 三个通道视为相同，即针对灰度 ($5 -> 3$)
    - 更进一步，把 Schlick Approximation 带入，能把 $R_0$ 从积分中拆出来，视为常数 ($3 -> 2$)
      $
      F = R_0 (1 - (1 - cos th)^5) + (1 - cos th)^5 \
      intop f_r (p, om_i, om_o) cos th_i dif om_i = intop frac(f_r (p, om_i, om_o), F) dot F cos th_i dif om_i \
      intop f_r (p, om_i, om_o) cos th_i dif om_i approx R_0 intop frac(f_r (p, om_i, om_o), F) (1 - (1 - cos th)^5) cos th_i dif om_i + intop frac(f_r (p, om_i, om_o), F) (1 - cos th)^5 cos th_i dif om_i
      $
      - 约等号是因为 Schlick 本身就是 BRDF 的近似
    - 于是最终变成二维函数，可以做 Look Up Table (LUT)，存储为 roughness 和 $cos th_v$ 的纹理
  - 综上所述，我们把环境光项和 BRDF 项分开处理，工业界会把它拆成 diffuse 和 specular 两种情况
    $ L_o (p, om_o) approx "Prefilterd"(R, al) * (R_0 dot "LUT".r + "LUT".g) $
    #fig("/public/assets/CG/GAMES202/2025-04-18-20-23-11.png", width: 60%)
- *Shadow from Environment Lighting*
  - 前面没有考虑 visibility，如果要考虑的话就变得更为困难
    - *多光源问题* (many-light problem)：如果把环境光理解为非常多个小的多光源，shadowmap 的数量线性增加
    - *难以采样*：visibility 项可能非常复杂；同时也无法用积分拆分近似来处理，因为考虑 visibility 项后，small support 和 smooth BRDF 两个条件都无法满足
  - 工业界对此也没有好的办法，一般是摆烂只用一个主要光源做环境光照
  - 环境光阴影的其他相关研究
    + Imperfect shadow maps：全局光照阴影的一个解决方案
    + Light cuts：离线渲染中把场景中的反射物当做小光源，然后通过归类得到近似结果（Offline 中的 many-light 问题）
    + Real-time Ray Tracing (RTRT)：或许是未来的终极解决方案
    + Precomputed Radiance Transfer (PRT)：下面将要介绍，可以得到非常准确的环境光阴影，但有一定代价

=== PRT (Precomputed Radiance Transfer)
- 前置知识
  - 傅里叶级数展开、基函数、滤波
  - *球谐函数*，很重要但这里不想写了，略
- PRT 的基本思想
  - 把渲染方程分为 lighting（环境光项）和 light transport (Visibility & BRDF) 两部分，我们认为（假设）只有 liighting 部分发生变化（旋转 or 更换光源），而 light transport 部分不变
    - 环境光照是无限远处，visibility 是着色点对无限远处的光照可见性，当然不变；BRDF 是对某个出射角度在某个入射角度的性质，也是不变值
    - 换句话说，我们考虑的是静态场景动态光源
  - 于是，lighting 部分可以用球谐函数近似（预计算），light transport 部分不变，也可以预计算！
- 分为 Diffuse 和 Glossy 两种情况介绍
  - *Diffuse* Case
    - 计算方法一：BRDF 对 diffuse 而言是个常数，提到积分号外，再将 $L(i)$ 写成球谐函数形式
      $
      L(i) approx sum l_i B_i (i) \
      L(o) approx rho sum l_i underbrace(int_Om B_i (i) V(i) max(0,n dot i) dif om_i, T_i) \
      L(o) approx rho sum l_i T_i
      $
      - 理解一：$T_i$ 部分就是 light transport 在球谐函数上投影的系数，可以预计算，最终公式变为两个向量的点乘
      - 理解二：每个基函数 $B_i (i)$ 都是一个光源，每个 $T_i$ 都是算了一遍渲染方程（球谐函数所描述的环境光作用于物体的结果），最后以 $l_i$ 为权重叠加求和
    - 计算方法二：分别将 lighting 和 light transport 进行球谐展开再代回，利用 SH 的正交性得到同样的结果
      $
      L_i = L(i) approx sum_p c_p B_p (i) \
      T_i = rho V(i) max(0,n dot i) approx sum_q c_q B_q (i)
      $
      $
      L(o) &approx intop sum_p c_p B_p (i) sum_q c_q B_q (i) dif om_i \
      &= sum_p sum_q c_p c_q intop B_p (i) B_q (i) dif om_i \
      $
    #fig("/public/assets/CG/GAMES202/2025-04-18-22-54-29.png", width: 50%)
  - *Glossy* Case
    - 此时 BRDF 不再是个常数，与入射、出射角度都有关，此时再将 light transport 投影到球谐函数上的结果不再是一个系数，而是一组系数
      $
      T_i (o) approx sum t_ij B_j (o) \
      L(o) approx sum l_i sum t_ij B_j (o) = sum (sum l_i t_ij) B_j (o)
      $
    - 结果从原来的向量点乘变为了向量与矩阵的乘法，矩阵大小为基函数阶数 $n$ $*$ 视角采样次数 $m$，可以用三种方式理解
      + 横向理解：对每个基函数 $B_j (o)$，将 $T_i (o)$ 的任一方向投影到它，得到一组系数（个数为 $m$）
      + 纵向理解：对 $T_i (o)$ 的每个方向单独考虑，都能像之前那样进行球谐展开到 $n$ 个基函数上，得到一组系数（个数为 $n$）
      + 倒推法：最后得到的结果是不同方向上的 irradiance，是一个向量，而 lighting 部分球谐展开得到的是一个向量，向量只有乘以矩阵才能得到向量
    - 所以对于 glossy 材质，使用 PRT 的效率会比 diffuse 差很多，存储空间也更大，是球谐阶数平方的关系 ($n^2$)
  - *Inter-Reflection Case / Multi Bounce*
    #tbl(
      columns: 2,
      [表达式], [含义],
      [LE], [light $->$ eye],
      [LGE], [light $->$ glossy $->$ eye],
      [LGGE], [light $->$ glossy $->$ glossy $->$ eye],
      [L(D|G)\*E], [light $->$ (diffuse or glossy)\*n $->$ eye],
      [LS\*(D|G)\*E], [light $->$ specular*n $->$ (diffuse or glossy)\*n $->$ eye]
    )
    - 对于多次反射的间接光而言，不管光线从光源出发最终到我们眼睛之间经历多少 diffuse / specular / glossy 的反射，都能被 PRT 中的 light transport 项表达，再复杂都能预计算（通过预计算将 light transport 的复杂度与实际渲染解耦）
- *总结*
  - 使用 SH 分别近似 lighting 和 light transport，转化并存储为 lighting coefficients 和 coefficients / matrices
  - 优点：
    + 把逐顶点 / 逐像素操作转化为向量点乘、矩阵计算，性能提升巨大
    + 不仅能计算带阴影的环境光，还处理了 multi bounce case
  - 缺陷：
    + 渲染对象必须具备静态场景、动态光源的条件，且材质不能改变，否则需要重新预计算
    + 由于使用 SH，只适合描述低频信息（阶数不能太高，且对 glossy 效果一般）
- 此外还介绍了一些除 SH 外的其它 PRT 方法
  - 小波函数 wavelet，解决了 SH 的频率限制但同时失去了旋转不变性
  - Zonal Harmonics、Spherical Gaussian (SG) 球面高斯、Piecewise Constant 等

== Lec7/8/9: Real-time Global Illumination
这部分加入较多 GAMES104 的知识，以及一些从其它博客看来的东西。

=== 三维空间方法
- *RSM (Reflective Shadow Map)* 是一种基于 shadow map 的全局光照方法
  - GI 总体上一般有两派方法，一派是以 Tay Tracing 为代表的从相机出发多次 bounce 收集光照信息；另一派是以 photon mapping 为代表的从光源出发多次 bounce 到一定程度留下光子，相机直接对光子做着色。从这个角度来说，RSM 算是 photon mapping 思想最早的应用（先驱），后面要讲的几个方法也很多是用这种 inject light into scene 的思路
  - RSM 的基本思想是把光源的反射信息存储在 shadow map 中（实际上这个 map 存储了场景中直接光照的信息，叫 shadow map 反而不恰当，只是因为生成方式类似而得名），然后根据其分辨率把每个像素都当做一个次级光源计算间接光照
    $ E_p (x,n) = phi_p frac(max(0, iprod(n_p, frac(x-x_p,norm(x-x_p))) max(0, iprod(n, frac(x_p-x,norm(x_p-x))))), norm(x - x_p)^2) $
    - 通常将将所有次级光源的表面设为 diffuse（摆脱视角依赖），且不考虑 visibility（避免每个次级光源都再生成 shadow map）
  - 减少采样数
    - 理论上 RSM 上每个点都能对当前 shading point 有贡献，需要 $n^2 ("e.g." n = 512)$ 次采样
    - 优化一点的话，可以预计算一些斑点状的 pattern 并重用它（比如 Poisson sampling），然后以 shading point 为中心根据距离和深度来加权计算虚拟光源的贡献，这样只用约 $400$ 次采样就足够
      - 从 shading point 的角度来看实际上就是用 cone tracing 模拟往四周、往远近的采样，只是那个年代还没有明确提出这个概念（参见下面的 SVOGI）
      - 既然实质上是个 cone tracing，那能不能对 RSM 也使用 mipmap 呢？很遗憾不太行，因为 RSM 上相邻两个点有可能距离、法向差异很大。对此，后来有更加粗暴的加速方法
    - 我们直接把 RSM 压缩，在 low-resolution 的图像上用周围四个点插值出原本 high-resolution 的结果（利用 indirect light 的低频性），对于极少部分 artifacts（利用 normal, world space position 验证）再重新回到 high-resolution 上采样
  #grid(
    columns: (40%, 30%, 30%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES202/2025-04-17-21-23-03.png", width: 95%),
    fig("/public/assets/CG/GAMES202/2025-04-17-21-21-57.png"),
    fig("/public/assets/CG/GAMES202/2025-04-17-21-34-38.png")
  )
  - RSM 主要用于处理间接光照，尤其适用于强方向性光源如手电筒、聚光灯。严格来说不算“三维空间”方法，但主要是为了强调跟后面屏幕空间的区别
- *Light Propagating Volume (LPV)* 是一种基于体积的全局光照方法
  #grid(
    columns: (70%, 30%),
    column-gutter: 4pt,
    [
      - 它的基本思想是查询每个 shading point 在任意方向上的 radiance，并且注意到 radiance 随直线传播不衰减，因此把场景分为 grid (voxels) 来存储光照信息
      - 具体分为三步
        + Generation: 对场景中光源生成直接光照（次级光源），即 RSM 的 map
        + Injection: 预先将场景分为 3D grid，用两阶 SH（$4$ 个数，注意，用了 SH 都会导致高频信息丢失，即假设了 diffuse）存储次级光源 voxel 的 radiance
        + Propagation: 对每个 voxel 进行 $6$ 个面的 radiance 传播、加和，迭代四五次直到收敛（同样，为简单起见不考虑 visibility）
        + Rendering: 采样 voxel 渲染图像
      - LPV 不需要预计算，光源和场景都是可以变化的，但是计算量可能还是稍大
    ],
    fig("/public/assets/CG/GAMES202/2025-04-15-21-58-48.png", width: 90%)
  )
  - 问题
    - 由于 voxel 的分辨率导致 light leaking。对此工业界使用多分辨率 voxel 方法，称作 cascaded LPV，学术界叫 multi-scale 或 level of detail
    - 另外，LPV 多次 propagation 的过程，如同是假设了光的传播速度、扩散范围跟 iteration 有关，实际上是不太符合物理规律的（虽然我们做游戏的其实也没那么关注物理hhh），本质上是一个包含很多 hack 的老算法，现在已经不怎么用了
  - 不过 LPV 的思路是很有启发性的，它是第一个想到把空间体素化的方法，以及第一个把 SH 引入 GI，启发了后续的许多工作
- *Sparse Voxel Octree for Real-time GI (SVOGI)* 是 NVIDIA 对 LPV 的改进版
  - 闫老师讲的 VXGI 实际上是指 SVOGI，VXGI 是 SVOGI 的改进版（最终落地版），或者也可以认为 VXGI 有两种实现: Sparse Voxel Octree 和 Clipmap
  - SVOGI 的基本思想是利用保守光栅化 (Conservative Rasterization)，确保场景中再薄、再小的 triangle 都能被 voxelize；并且用八叉树管理（实际上数据结构更复杂，还要存储上下左右前后的信息）来管理不均匀的 voxel 划分，形成 hierarchical Voxel
    #grid(
      columns: (75%, 25%),
      [
        - 保守光栅化
          - 标准光栅化判定的是像素中心，只有黄色像素和绿色像素会被认为位于三角形内；
          - 使用内保守光栅化的时候，只有绿色像素会被认为位于三角形内
          - 使用外保守光栅化的时候，包括蓝色像素也会被认为位于三角形内
        - 显然 SVOGI 这里用的是外保守光栅化，前两种可能会导致丢失一些三角形特征
      ],
      fig("/public/assets/CG/GAMES202/2025-04-17-23-44-52.png")
    )
  - 跟 RSM 一样是个 two-pass algorithm，跟之前方法做个比较：
    + RSM 直接照亮 pixels 作为次级光源 $->$ 场景中 hierarchical voxel 作为次级光源
    + LPV 构建体素后进行 propagation，次级光源主动去找其它体素 $->$ 构建体素后每个 shading point 都根据其 normal 做 cone tracing 跟体素求交，shading point 去找次级光源（当然这跟 RSM 也不一样，RSM 也是 shading point 找次级光源，但是通过 sample 的方式）
  #grid(
    columns: (40%, 55%),
    column-gutter: 2em,
    fig("/public/assets/CG/GAMES202/2025-04-17-21-10-18.png"),
    fig("/public/assets/CG/GAMES202/2025-04-15-22-14-14.png")
  )
  - SVOGI two-pass
    - Pass 1 (Light-Pass): 关注场景中哪些表面被直接光照照亮
      - 每个体素存储直接光源的*入射方向区间*和体素对应的受光表面的*法线方向区间*（而不是 LPV 那样存 SH）
      - 得到低层级体素的光照信息后向高层级传播
    - Pass 2 (Render-Pass): 提出了 cone tracing 的概念，并与 mipmap 相结合：
      - 对于 glossy 材质，产生一个 cone，在传播过程中扩散变大的截面大小，在八叉树相应层级查询（截面越大查询体素越大）
      - 对于 diffuse 材质 则是用多个 cone 覆盖半球（不考虑缝隙和重叠），多一层循环，效率也低一些
      - mip 同时也起到 smooth 的作用。这种 cone tracing 的方式也是对空间进行 hierarchical voxelization 划分的一个优势
  - 总之，SVOGI 的渲染质量比较好（甚至接近光追），但比 LPV 还慢，且 Light-Pass 前的体素化会有一定预处理需求（限制了如动态场景的应用）。SVOGI 的实现非常复杂，现在也已经没人用了，被 VXGI 完全替代，之所以要提它，主要就是因为它把体素 hierarchical 化，以及第一个明确提出了 cone tracing 的概念
- *VXGI (Voxel Global Illumination)* 也是 NVIDIA 提出的基于 Voxel 的 GI 方法
  - 从数据结构上看，VXGI 是 SVOGI 的改进：复杂 GPU 八叉树结构和一系列 hack $->$ View-Dependent Voxelization (i.e. Clipmaps)
  - Clipmaps 的构建与更新
    - cilp 这个词中文意为“回形针”，clipmap 比较难翻译。总的来说就是不再需要费心费力构建整个场景的 hierarchical voxel，而是只需要关心相机视野即可。它同样是个树状结构，但近处 voxel 细分得更密，远处 voxel 粗糙一些。它的数据结构对 GPU 更 friendly，实现起来更清晰、明确、简单
      #grid(
        columns: (33%, 27%, 40%),
        column-gutter: 4pt,
        fig("/public/assets/CG/GAMES202/2025-04-17-22-23-58.png"),
        fig("/public/assets/CG/GAMES202/2025-04-17-22-24-09.png"),
        fig("/public/assets/CG/GAMES202/2025-04-17-23-21-15.png")
      )
    - 每个 voxel 存储的是 3/6 个方向的 Emittance (Radiance?)、3/6 个方向的 Opacity，形成两个 3D 纹理。前者从 RSM 注入得到，后者后面会讲
    - clipmap 随相机移动的更新方式很讲究，使用环形寻址 (toroidal addressing) 的方式，每次只用更新周围部分的 voxel（实际上是又写回来了），而中间的大部分是可以重用的，且不需要 memory copy
      $ "texture address" = frac("worldPos".xyz, "clipmapSize".xyz) $
      #fig("/public/assets/CG/GAMES202/2025-04-17-22-27-21.png")
  - Voxelization for Opacity & Shading with Cone Tracing
    - VXGI 处理了体素的透明度问题
      - 透明度的计算比较复杂，首先将三角形投影到三个面找到主投影面（fragment 数量最多的面，为了统一化？）。启用 MSAA 进行超采样，并将它们重投影回另外两个面，计算每个面上的覆盖率，并做一次 blur 来 thicken the result (?)
      $ "Opacity" = "number of the covered MSAA samples" / "MSAA_Resolution"^2 $
      #grid(
        columns: (75%, 25%),
        column-gutter: 4pt,
        fig("/public/assets/CG/GAMES202/2025-04-17-22-38-55.png"),
        fig("/public/assets/CG/GAMES202/2025-04-17-22-39-59.png")
      )
    - Shading 采用跟 SVOGI 一样的 cone tracing 方法，根据 BRDF 和 normal 决定锥体的大小和数量，根据在锥体截面的面积决定采样的 clipmap level，通过透明度实现类似 NeRF, 3DGS 的体渲染效果
      $
      C_dst <- C_dst + (1 - al_dst) C_src \
      al_dst <- al_dst + (1 - al_dst) al_src
      $
      - 当然这样 naively combine the opacity 也有问题，如上右图所示会出现错误的漏光
  - 可供参考的资料
    + #link("https://cgvr.cs.uni-bremen.de/theses/finishedtheses/VoxelConeTracing/S4552-rt-voxel-based-global-illumination-gpus.pdf")[rt-voxel-based-global-illumination-gpus.pdf]
    + #link("https://zhuanlan.zhihu.com/p/549938187")[实时全局光照VXGI技术介绍]
- *DDGI (Dynamic Diffuse Global Illumination)* 又是 NVIDIA 提出的算法，基于 Probe 的 GI 算法
  - 完整算法 DDGI 可以在动态场景、光源中实时生成 diffuse GI（依赖 RTRT 硬件支持）；但如果只需要静态场景、（动态）光源，也可以将光追预计算从而在低端设备运行
    - 预计算其实也可以有少量动态物体，只被间接光照亮但不参与生成，由于 DDGI 本身也只做了 diffuse GI，不会有太多 artifacts
    - 基于该算法 NVIDIA 实现了大名鼎鼎的 RTXGI
  - *DDGI Probe*
    - 摆放在场景中，记录某一位置三个关于方向的函数
      + $E(om)$: probe 从 $om$ 方向的半球面接收到的 irradiance
      + $r(om)$ 和 $r^2 (om)$: probe 往 $om$ 方向看到的最近物体的距离以及平方（半球上的均值）
        - 类似 VSM 使用深度和平方深度均值进行切比雪夫测试来估计处在阴影的概率，这里采用类似做法估计 probe 与 shading point 间存在遮挡的概率
    - 这些信息被存储在纹理贴图中，通过双线性插值恢复出关于方向的连续函数
      - 存储方式是八面体映射 (Octahedron mapping)，irradiance 被存储为 $6^2$ 三通道纹理，$r(om), r^2 (om)$ 被存储为 $14^2$ 的双通道纹理
      - 边界处理：为保证双线性插值正确，在上述基础上扩展一层边界。四边倒置填充，四角对角填充 ($6^2 -> 8^2, 14^2 -> 16^2$)
    #grid(
      columns: (78%, 20%),
      column-gutter: 8pt,
      fig("/public/assets/CG/GAMES202/2025-04-19-09-49-45.png"),
      fig("/public/assets/CG/GAMES202/2025-04-19-09-56-58.png")
    )
  - *DDGI Volume*
    - 将一组 probe 打包成一个立方体，在 Volume 内的着色点会被计算出的间接光照亮。DDGI Volume 仅捕获动态光源的间接光照，静态光源一般使用光照烘焙 (Lightmap) 的方式
    - 在场景中应用多个 Volume 以覆盖，一般每个 Volume 有 $8^3$ 个 probe。打包存储为一个大图集，横轴为 $8^2$，纵轴为 $8$，以 irradiance 为例，每个 probe 各自占有 $8^2$，合计 $512 times 64$
    - 实际应用中常需要多种 Volume 协同工作：
      + 基于实时光线追踪的 Volume
        - 绑定到相机上跟随相机移动以对相机视锥内物体应用间接光照，可以绑定多个大小的 Volume 进行级联，体积越小精度越高
      + 基于预计算的 Volume
        - 将 Volume 拖进场景中就会自动在其中放置 probe，预计算场景的几何信息并在运行阶段实时更新光照
        - 一般需要做 hierarchical Volume，用大的 Volume 囊括整个场景，对每个小区域放置 Volume。任何一个 shading point 会采样所有包含它的 Volume 并加权混合结果
        - Volume 最外两层 probe 之间会做线性淡出来避免明显边界，以室内高精度 Volume 和室外低精度 Volume 为例，会导致淡出区域室外 Volume 权重变大，在放置时最好让这个线性淡出区域刚好处于室外。虽然还是需要人工放置，但 Volume 的工作量比 Probe 小得多
  - *生成 DDGI Volume*
    - 摆放好 DDGI Volume 与 Probes 后，考虑如何将场景光照信息收集起来
    - 对于基于预计算的 DDGI，这一步比较简单。一般来说，凡是与光照无关、只和几何有关的数据都可以移入预计算阶段。用离线射线检测来将场景的几何 (position, normal) 与材质信息 (albedo) 写进纹理中，包装成 G-Buffer 送入延迟渲染流程跑一遍，将光照结果写入 probe 中。当然此时也有一些细节比如 Volume 剔除
    - 对于基于实时光追的 DDGI，分为以下三步
      + 发射光线：从每个 probe 发射光线，用硬件光追解算，存到 per-Volume 的三张三通道 texture 中 (position, normal, albedo)，纹理的横轴为每个 probe 采样数，纵轴为 $8^3$ probe 数量
      + 计算 radiance：texture 打包为 G-Buffer 送入延迟渲染流程，结果存入 radiance texture
      + ProbeBlend：texture 中的每个纹素指的是某个 probe 在某一方向的 radiance, position，离我们想要的半球面上的 $E(om)$, $r(om)$, $r^2 (om)$ 还差一步混合
        $
        E(om) = frac(sum L_i cos th_i, sum cos th_i) \
        r(om) = frac(sum d_i cos^s th_i, sum cos^s th_i), ~~~~ r^2 (om) = frac(sum d_i^2 cos^s th_i, sum cos^s th_i)
        $
        - 这里 radiance $->$ irradiance 的转换有点没懂？评论区：
          #q[半球积分 $int cos(t) dif s = pi = 2pi/N sum cos(t)$，故而 $sum cos(t) = N/2$。因此除以 $sum cos(t)$ 相当于乘以 $2/N$。为了匹配蒙特卡罗积分的 $1/N$，算 $E(om)$ 还要乘以 $0.5$ 后保存，随后使用时再乘以 $2pi$ 以匹配整个半球积分效果。这是 RTXGI 中代码实现]
        - 算 $r$ 就更不符合均值原则了，加了个 empirical sharpness factor $s$，一般取 $50$ (?!)
      + 时间超采样：复用上一帧的结果，变相达到增大采样率的目的，且通过单次 bounce 达到多次 bounce 的效果。具体而言就是一个 alpha-blend
  - *Render by DDGI Volume*
    - 得到 Volume 的光照信息后，剩下的就是如何对每一着色点进行渲染。我们先写出渲染方程，将 diffuse 项拆出（DDGI 只算 diffuse 部分的 GI，specular 部分另外考虑）。对 diffuse 部分，只要着色点在 Volume 内，总能找到周围 $8$ 个 probe 进行采样
      $
      L_o (om_o) = int_Om L(om_i) [f_"diff" (om_i, om_o) + f_"spec" (om_i, om_o)] cos th dif om_i \
      L_"diff" (om_o) = f_"diff" (om_i, om_o) L(om_i) cos th dif om_i = rho/pi E(n_i)
      $
    - 其中 $n_i$ 是表面法线，$E(n_i)$ 可以由 $8$ 个 probe 上的 $E(n_i)$ 加权平均近似。权重由三个因子相乘得到
      + 三线性插值系数：如果 probe 离着色点较远，降低权重
      + 方向系数：如果着色点到 probe 的方向与表面法线的夹角过大，降低权重（注意是降低而不是常见处理如光源在表面背面时直接截断，因为使用 probe 接受到的 irradiance 来近似着色点，而不是将 probe 当做光源照亮着色点）
      + 切比雪夫系数：如果着色点与 probe 之间有较大的概率存在遮挡物，降低权重（类似 VSM）
      - 三个系数做不同的指数运算后（为了控制三者比重）相乘，并归一化得到最后的系数
  - 可供参考的资料
    + #link("https://zhuanlan.zhihu.com/p/404520592")[动态漫反射全局光照 (Dynamic Diffuse Global Illumination)]
    + #link("https://zhuanlan.zhihu.com/p/597206371")[DDGI（一）- 概述]、#link("https://zhuanlan.zhihu.com/p/598121479")[DDGI（二）- 方法概述及更新 probe]、#link("https://zhuanlan.zhihu.com/p/599117680")[DDGI（三）- 基于 probe 的着色]、#link("https://zhuanlan.zhihu.com/p/599315264")[DDGI（四）- 总结]

=== 屏幕空间方法 (SSGI)
屏幕空间方法只使用屏幕信息，换句话说，是对 existing renderings 进行后处理，知道的信息较少。比如，给一张图用神经网络算出 GI 的方法就属于 screen space 方法。

- Screen Space Ambient Occlusion (SSAO)
  - 首先要知道 AO 方法一般易于实现且比较便宜，并且可以让环境变得更立体。AO 方法非常常用，很多时候即使用其它方法算过 GI 了，也会再加一层 AO 来增强边角部分的遮挡感
  - Key Idea: 跟 Blinn-Phong 一样假设 ambient light 是个常数，但是考虑 different visibility（数学上，就是 RTR approximation equation 把 visibility 拆出来），此外假设物体材质为 diffuse
  - 如果是在 3D space，visibility 只需要往四周采样即可，但在 screen space，我们只能*在 Z-Buffer 中采样*！
    - 采样时，需要考虑一个半径的 trade-off（太大了容易把宽敞空间算作遮蔽，太小则会漏掉遮蔽）
    - 会有一些几何导致 Z-Buffer 失效，但反正都已经采样了，不在乎这点误差
    - 进一步，可以用 G-Buffer 来存法向信息（延迟渲染普及之后），来实现半球上的 SSAO，真正把 $cos th$ 加权纳入考虑 ($->$ GTAO)
  #fig("/public/assets/CG/GAMES202/2025-04-17-21-55-57.png", width: 90%)
- Screen Space Directional Occlusion (SSDO)
  - SSDO 跟 SSAO 一样，也是用 camera 处的可见性间接反应 shading point 处对次级光源的可见性；但它对间接光照的考虑正好跟 SSAO 相反，它假设次级光源来自比较近的地方，被遮挡的点反而是要考虑的光源
    - SSAO 是假设次级光源来自远处，被遮挡点则没有间接光照。也因此，SSAO 只是简单地为物体加上阴影，而不能真正把有颜色的间接光照算出来 (color bleeding)
    - 实际上，SSAO 跟 SSDO 应该互补，才是正确的效果。更一般地说，*Ray Tracing 才是 AO 的真正未来方向*
    #align(center, [AO: #redt[indirect illumination] + no #text(fill: orange)[indirect illumination] #h(2em) DO: no #redt[indirect illumination] + #text(fill: orange)[indirect illumination]])
  #grid(
    columns: (56%, 44%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES202/2025-04-17-21-49-28.png"),
    fig("/public/assets/CG/GAMES202/2025-04-17-21-50-07.png")
  )
  - 总之，SSDO 的光照细节会更好；不过它具有一切使用 Screen Space 算法的弊端，如 false occlusion、信息丢失（且由于无法像 SSAO 那样考虑来自远处的间接光，信息丢失更严重）
- Screen Space Reflection (SSR)
  - SSR 实际上不止反射，它*几乎是把 Ray Tracing 搬到了屏幕空间里*，因此可以处理 specular, glossy, diffuse 等情况（无非是反射光线数量和方向分布的问题，diffuse 会慢一些）
  - SSR 假设屏幕空间已经基本具备所有模拟光线弹射的条件 (normal, depth)，而由于屏幕空间无法做 ray casting，因此需要用 ray marching 来处理反射光线（这里用动态步长的层级结构来加速，即 min-pooling mipmap）。找到反射光线与物体的交点（次级光源）后，剩下的着色方法就跟 ray tracing 一模一样（注意要假设次级光源为 diffuse）
  #grid(
    columns: (65%, 35%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES202/2025-04-17-22-02-01.png"),
    [
      #fig("/public/assets/CG/GAMES202/2025-04-17-22-03-16.png")
      #v(-0.5em)
      #fig("/public/assets/CG/GAMES202/2025-04-17-22-08-00.png")
    ]
  )
  - Ray Reuse 优化：相邻的两个 shading point，不考虑 visibility 情况下，方向相近的 ray 可以重用（通过存储 hitpoint data）
  - SSR 的效果很不错，对 specular, glossy 情况下效率也很高；但它依然有 Screen Spcae 的缺点（比如一个浮在空中的正方体的底面，其反射到下方的镜子应该是黑的，但 Screen Spcae 反射不出该信息），以及重用 neighbor ray 带来的 incorrect visibility 问题

== Lec10/11: Real-time Physically-Based Rendering
- 微表面模型 Microfacet
  $ f_r (om_o, om_i) = frac(F_r (om_o) G(om_o,om_i) D(w_h), 4 (n dot om_o) (n dot om_i)) $
  - Fresnel Term
    - 一般采用 Schlick approximation
  - Geometry (Shadowing-Masking) Term
    - 描述微表面的自遮挡现象，主要是 grazing angle 时做一定惩罚
    - 为了解决能量守恒问题 (no consideration for multiple bounce)，需要补偿项，一般用 Kulla-Conty Approximation，其推导略复杂。
      - 先考虑不带颜色（没有任何能量吸收），假设白炉测试，积分出来的 $1-E(mu_o)$ 不带入射角度。然后对一般情况利用光路可逆性再加一个归一化项 $c$ 使得两式相等，从而把入射方向纳入考虑，算出 $E_avg$
      - 进一步，对带颜色的，又引入 $F_avg$
      - 工业界常常使用 mocrofacet 和 diffuse 混合使用的方法，这是完全错误的，会导致能量不守恒！
  - Normal Distribution Term
    - 描述微表面的分布，一般用 Beckmann 或 GGX (Trowbridge-Reitz)，或者 GTR (Generalized Trowbridge-Reitz)
  - 此外还讲了一个基于 microfacet 的方法，叫做 LTC (Linearly Transformed Cosines)，没太听懂，但总之宗旨是：把变化 BRDF + 变化光源通过一个变换矩阵变成固定 BRDF + 变化光源（将标准空间中的反射波瓣线性映射到余弦空间），从而固定的 BRDF 为 cosine 的形式具有解析解
- Disney Principled BRDF
  - 没有细讲，介绍了其相关特点
- 以及介绍了 PBR 的对立面 NPR (Non-Physically Based Rendering)
  - 首先介绍了一堆卡通渲染的例子
  - outline，主要分为 shading, geometry, postprocessing 三种方法
  - color block，对正常渲染的结果进行阈值化，可以是渲染过程中做，也可以是后处理做
  - stroke surface，根据明暗给物体表面加上笔划，主要是用纹理贴图来做

== Lec12/13: Real-time Ray Tracing
光线追踪在当时已经不是什么新鲜的话题（现在更是普遍），尤其是 18 年英伟达的 RTX 架构出世，总之至少能做到每帧约 1 SPP (1 sample per pixel) 的计算量（也可能更多，但更多不太可能x）。这样的结果自然非常 noisy，因此 RTRT 的核心其实不是 RT 本身，而是*降噪*。降噪既要保证实时，又要保证质量，那么选择面就变得非常窄，像切变滤波 (sheer filtering)、离线滤波 (offline filtering) 和深度学习都用不了（DL 存疑，当年不行，本质因为神经网络 inference 过慢，现在可能有一点变化，比如 TensorCore）。

噪声的根本原因是因为采样率不足，解决方法一般就两中，一是（或暴力或取巧地）增加采样数，二是低通滤波，沿着这两个思路提出 *Temporal Accumulation* 和 *Spatial Filtering*。

- *Temporal Accumulation*
  - 通过时间上的均摊来变相增加采样率。自然的问题是，如何对每一帧的像素找到前一帧的对应像素？找到这个值后，做线性加权即可
    - 这里的对应关系寻找在 CG 中被称为 *motion vector*。CV 中有类似的概念叫 optical flow，但不同在于，前者的信息更多（整个渲染过程以及相机相对位姿均已知）
    - 并且随着延迟渲染的发展，G-Buffer 中可以存储 world space coordinates, normal, RGB, Object ID 等，可以拿到更多信息
  - Temporal 对时间上的复用效果非常好，但问题也很明显。老师总结了四点：
    + Switching Scenes (Burn-in Period)
    + Screen Space Issue
    + Disocclusion
    + Shading Failure (delay or lagging)
    - 总之就是，如果对应像素不在屏幕内，或对应元素不可信（被遮挡，或 shading 发生变化），就会无法复用，从而被去噪所掩盖的问题重新暴露出来
    - 解决方法自然是有的，一般分为 Clamping（将上一帧结果强制贴近到当前帧）和 Detection（记录 Object ID，如果变化则通过改变 $al$ 取消复用）两种，但或多或少会重新引入噪声
  - 即使有这么多问题，但 Temporal Accumulation 仍然是效果很好很常用的方法，其缺陷掩盖一下就不会太严重，而且工业界要求也没那么高#strike[（毕竟电子竞技不需要视力）]
- *Spatial Filtering*
  - 一种简单想法是直接用高斯滤波 (Gaussian filtering)，但是纹理边界这种高频信息也会被一起模糊
  - 双边滤波 (Bilateral filtering)
    - 高斯滤波的改进，核心思想是使用欧氏距离的高斯分布和像素的色值差异 (position dist & color dist) 共同决定滤波核的权值
    - 一定程度上合理，但用像素值差异实际上不能完全反映边界和噪声的区别
  - 联合双边滤波 (Cross / Joint bilateral filtering)
    - 利用 "free" feature of G-Buffer，它不涉及 multi-bounces，因此是 noise-free 的 (depth, normal, color, position, etc.)
    - 高斯函数不是距离衰减的唯一选择，例如 exponential (absolute), cosine (clamped) 都可以。以高斯函数为例，每种特征有一个自己的 $si$，不同的高斯调调参后乘在一起
  - 改进 large filtering kernel，一般有两种方法
    + Separate Passes: $N^2 -> N + N$（对高斯函数，数学上本身就是正交可拆分的；对于各种联合滤波，理论上不太能但实现上能）
    + Progressively Growing Sizes: 先用小的 kernel 滤波，然后用大的 kernel 做“空洞卷积”（实际上的卷积核大小没变）
      - 从 higher / deeper level 理解，growing sizes 实际上是逐步去除更低频的高频信息；skip samples 之所以安全是因为采样本质上等于频谱的搬移，当更高频信息被去除，搬移就是安全的
- *Outlier Removal (and temporal clamping)*
  - 有时滤波后的结果仍然是 noisy 的，甚至 blocky，大多数时候是因为 outliers，需要在滤波前检测并去除
  - Outliers 在 rendering 领域有个名字叫 fireflies（火萤、萤火虫）。在图形领域，从理论上来讲并不应该去除它们，反而说明这个方向上探索不够，应该增大采样率来把 variance 降下去；但从 RTRT 的角度我们等不起
  - 对每个像素，看 (e.g.) $7 times 7$ 的邻域，算均值和方差，把 $[mu - k si, mu + k si]$ 之外的值 clamp 到这个范围

== Lec14: A Glimpse of Industrial Solutions
- *Specific Filtering Solutions for RTRT*
  - Spatiotemporal Variance-Guided Filtering (SVGF)
    - 更细致分析三个指导 filtering 的因素
      + Depth: 在考虑深度时，利用深度的梯度将其点所在的切平面也考虑在内，对同一平面的点施加更小的惩罚
      + Normal: 法线的点乘衡量相似度，用类似 Blinn-Phong specular term 的指数来衰减（注意，使用法线、凹凸贴图*前*的结果来做）
      + Color: RGB 转换为 Luminance 作差衡量，但考虑 outlier 的影响，除以在 spacial, temporal, spacial $3$ 个层面的方差
    - SVGF 效果不错，但有时倾向于 over-blur，算是在过度模糊和噪声之间的 trade-off；另外 temporal 的老问题 —— 场景固定、光源移动时的拖影 也还在
  - Recurrent AutoEncoder (RAE)
    - 用神经网络降噪，且有 G-Buffer 的辅助，用最典型的 U-Net 结构。用 recurrent 引入时序信息，后续也有单图的做法
    - 纯 DL 大力出奇迹，没有涉及 motion vector 之类，也就没有对应的那些问题。但其问题在于神经网络速度慢，在那个时候大概要 $50ms$，基本没有实用价值
- *Temporal Anti-Aliasing (AA) / Super Sampling (SS)*
  - TAA 基本跟 RTRT 里面的方法一模一样，不同在于有个 jitter filtering 的概念，用一种固定 pattern 进行采样的抖动，比纯随机更好
  - DLSS
    + DLSS 1.0: 将低分辨率硬拉成高分辨率势必需要一些额外信息。DLSS 1.0 通过数据驱动的方法去硬猜，针对每个游戏或者场景单独训练出一个神经网络，学习一些常见的物体边缘，将分辨率拉高后模糊的边缘替换
    + DLSS 2.0: 引入 temporal 信息，即 TAA-like 方法。但不同在于，由于需要真正提升分辨率，因此对于 temporal failure 不再能用 clamping 方法处理（会导致小像素的值是根据周围点颜色猜测出来的，即高分辨率但模糊）。神经网络不是直接输出混合后的颜色，而是预测怎么将上一帧和当前帧的结果混合
- *Deferred Shading 延迟渲染*
  - 见 GAMES104
- *Tiled Shading & Clustered Shading*
  - 见 GAMES104
- *Level of Detail (LOD)*
  - 比如 Cascaded Shadow Map, Cascaded LPV
  - 再比如 Geometry LOD，预先产生一个细模，根据距离决定简化程度用于渲染
    - 会有 popping artifacts，解决办法是 leave it to TAA（本身就适宜处理这种时序上的变化）
    - 这就是 UE5 的 Nanite 系统的原理
  - 一些技术上的难题
    + 不同部位的 LOD，如何避免缝隙？(how to become waterproof)
    + 动态加载 LOD，如何利用 cache？（提一嘴，虚拟纹理）
    + 使用 geometry textures 表示 geomertry（没听懂，好像是 GAMES102 的内容）
    + 如何用 clipping, culling 等方法来加速？
- *Global Illumination Solutions*
  - 回忆经典的 SSR 的 fail case，没有任何的 GI 解决方法可以应对所有情况，除了直接上 RTRT。于是工业界很自然的思路是 hybrid solutions：先做一遍 SSR 得到一个近似的 GI，对于 SSR failure cases，使用 hardware / software ray tracing 来补充
  - Software Ray Tracing
    - \* 用 SDF 加速 ray tracing，对近处着色点用 high quality SDF，对远处用 low quality SDF
    - \* 如果场景中有强烈的方向光源或者点光源（e.g. 手电筒），通过 RSM 解决
    - 如果场景偏 diffuse，通过 DDGI (dynamic diffuse GI) 解决，这部分没讲，总之是 3D grid 中的 probes
  - Hardware Ray Tracing
    - \* RTRT 的 indirect illumination 没必要那么精确，没必要用原始的 geometry，使用 low-poly proxies 即可（用简化模型代替原始模型）
    - Probes (RTXGI)，RTRT 结合 probe 的思路，叫做 RTXGI
  - 以上带 \* 的方法结合起来就是 UE5 的 Lumen 系统
- 这门课没涉及到的（前面的区域，以后再来探索吧\~）
  + Texturing an SDF
  + Transparent material and order-independent transparency
  + Particle rendering
  + Post processing (depth of field,motion blur, etc.)
  + Random seed and blue noise
  + Foveated rendering
  + Probe based global illumination
  + ReSTIR, Neural Radiance Caching, etc.
  + Many-light theory and light cuts
  + Participating media, SSSSS (screenspace subsurface scattering)
  + Hair appearance
