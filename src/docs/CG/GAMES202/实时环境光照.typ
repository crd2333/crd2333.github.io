---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- 其他可以参考的笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 GAMES104 的内容。

#let intop = $int_(Om^+)$
#counter(heading).update(3)

= Lec5/6: Real-time Environment Lighting
环境贴图是一种记录了场景中任意一点在不同方向上接受到的光照强度的贴图，它默认这些环境光来自无穷远，因此它所记录的强度与位置无关（这也是为什么用环境贴图渲染的时候，走到哪里都会有一种漂浮感；而且如果贴图上有个桌子，你是无法在桌子上放个物体的）。再强调一遍，*这里是环境光，四面八方都有光源，不是单独几个光源！*

目前主流的环境贴图包括 Spherical Map 和 Cube Map。类似这种处理环境光照的方法被统称为 *IBL (image-based lighting)*。

== Basic IBL
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

== PRT (Precomputed Radiance Transfer)
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