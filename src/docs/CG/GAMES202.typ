#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

#let occ = math.text("occ")
#let unocc = math.text("unocc")

= GAMES202
有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- GAMES202 也没有咋写详细笔记，可以参考这些笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 Games104 的内容。

== Lec1: Introduction


== Lec2: Recap of CG Basics


== Lec3/4: Real-time Shadows
最简单的 Shadow Map 算法，用的是所谓 ray casting 算 visibility，会因为像素宽度和视角与平面垂直的问题发生 self-occlusion 问题。

RTR does not trust in Complexity! 实时渲染里面，一切都看最终跑起来的效果，即使复杂度低但常数项大的算法也不一定能用。

- *RTR 积分近似方程*
  $ int_Om f(x) g(x) dif x = frac(int_Om f(x) dif x, int_Om dif x) dot int_Om g(x) dif x $
  - 它是 Shadow Map 背后的数学基础，非常重要，后续也会继续用到
  - 要求是：要么 support $Om$ 比较小，要么 $g(x)$ 比较光滑（这里的光滑不是导数意义，而是说值变化小，即较平稳的意思）
- *PCSS (Percentage Closer Soft Shadows)*
  - PCSS 注意到阴影的软硬程度跟这个像素到被遮挡物的距离有关，于是以自适应的方式调整 PCF 的 window 大小，达成更好的阴影效果
  - 利用那张经典的相似三角形图，利用 blocker depth 显式建模了 window 大小。具体而言，就是在 PCF 步骤之前额外查一次 blocker depth
  - 但是查 blocker depth 本身也要有一个 window 做平均，这里有用 const size 的方法，也有用启发式的方法（离光源越近则一般 window 较大）
- *VSSM (Variance Soft Shadow Map)*
  - PCF 的采样过程较慢，利用泊松样斑等方法提高采样效率是一种方法；而 VSSM 是将其视为概率分布，利用均值和方差对其加速
    - 其思想是，我并不需要确切知道窗口内的深度值，只需要知道窗口内深度的排名，也就是分布内的 CDF
    - 首先，如果将其视为高斯分布（只是为了方便理解），那么只用知道 window 内的深度分布的均值和方差就确定其分布的 PDF。均值 $E(X)$ 可以用硬件上的 mipmap 实现；方差可以由 $var(X)=E(X^2)-E^2 (X)$ 得到，也就是在存深度图的时候可以另开一个 channel 存深度平方值
    - 其次，利用切比雪夫不等式估计（视为约等式），哪怕不视为高斯分布也可以直接估计出 CDF 而无需先得到 PDF
  - VSSM 同时也对 blocker search 的过程进行加速，注意这一过程我们需要计算*遮挡物的平均深度* $z_occ$，而无需考虑非遮挡物的深度 $z_unocc$，而我们能观察到下式
    $ N_1 / N z_unocc + N_2 / N z_occ = z_avg $
    - $z_avg$ 用下面介绍的 range query 方法很容易得到，而 $N_1 / N = P(x > t)$，也可以用 Chebychev 得到！
    - 至于剩下的 $z_unocc$，没办法，估计它为 $z_unocc=t$，即跟 shading point 视为同一平面（这是不得已的假设，但是是有道理的，因为绝大多数情况下我们都是在平面上算阴影）
  - 但这里要对 PCSS 和 VSSM 做个比较，后者当然是更高效的算法，但 PCSS 目前反而压过了 VSSM。这是因为我们可以用 PCSS 的低采样噪声版本，即在格子里面取部分 samples；而目前在屏幕空间的降噪技术发展得非常好，我们可以容忍一些噪声
- *MIPMAP and Summed-Area Variance Shadow Maps*
  - 给一个 texture 和 window size，要快速查询出每一点在窗口内的均值 (range query)，这可以用 mipmap 和 summed area table (SAT) 来实现
  - Recall mipmap: 快速的、近似的、方形的 range query。但首先它是方形的（可以用各向异性过滤解决），其次它是近似的、不准的，为此这里介绍 SAT 方法
  - SAT 与算法与数据结构中的前缀和紧密关联，总之就是需要 $O(N)$ 的预计算
  - 问题，跟原本的 PCF 采样比快在哪里？因为每个像素都是并行的，过一次 window 感觉不是很慢呀
- *Moment Shadow Map*
  - 在 VSSM 的基础上更进一步引入*矩*的概念（VSSM 可以认为是只用了一阶和二阶矩），从而达成更准的近似（四阶）
  - 具体计算说是非常复杂，没有进一步推导
- *sdf-based shadow*
  - sdf + ray marching $->$ safe distance
  - sdf for shadow $->$ safe angle
  - sdf 的存储，一般用 hierarchy 的方法存一棵树，只在物体边界的叶子附近才存值。还有一些用深度学习压缩的方法（闫令琪评价：毫无意义！）
  - 至于怎么计算 sdf，一般都认为是其它领域研究的问题（比如 CV，233），CG 这边就当作是能直接拿到的东西
  - sdf 的优势是，在做阴影层面（不考虑生成存储的情况下）对硬阴影软阴影处理相同，比 shadow map 方法快，效果也很不错；另外对于移动物体它也可以处理；但问题在于不好处理物体形变，以及 sdf 生成的物体没法做贴图

== Lec5/6: Real-time Environment Lighting
环境贴图是一种记录了场景中任意一点在不同方向上接受到的光照强度的贴图，它默认这些环境光来自无穷远，因此它所记录的强度与位置无关（这也是为什么用环境贴图渲染的时候，走到哪里都会有一种漂浮感；而且如果贴图上有个桌子，你是无法在桌子上放个物体的）。*这里是环境光，四面八方都有光源，不是单独几个光源！*

目前主流的环境贴图包括 Spherical Map 和 Cube Map。类似这种处理环境光照的方法被统称为 *IBL (image-based lighting)*。

按照之前路径追踪的做法，解渲染方程需要借助蒙特卡洛积分去进行一个（无偏的）估计，即基于采样的方法。虽然近年来 TAA 等一系列 temporal 方法的发展使得采样对 real-time 来说不算太慢，但下面我们还是优先考虑不采样的方法。

- *Split-Sum 近似渲染方程*
  - 这里有点复杂，不记了（可以看上面的笔记）
  - 总而言之就是，在不考虑 visibility 的情况下，利用积分近似公式拆分，把渲染方程拆成两块（环境光项和 BRDF 项），用不同的思路进行近似与预计算
  - 这里其实是比较核心、比较重要的一块知识，跟前面 microfacet、后面 PBR 的联系都非常紧密
- *Shadow from environment lighting*
  - 前面没有考虑 visibility 如果要考虑的话就变得更为困难，总结为*多光源问题* (many-light problem) 和*难以采样*。同时也无法用积分拆分近似来处理，因为考虑 visibility 项后，support 小和变化 BRDF 两个条件都无法满足
  - 工业界对此也没有好的办法，一般是摆烂只用一个主要光源做环境光照。未来的终极解决方案，或许是 Real-time Ray Tracing (RTRT)
  - 下面会介绍一种可以非常准确得到环境光阴影但有一定代价的算法 Precomputed Radiance Transfer (PRT)
- *球谐函数*
  - 很重要但这里不想写了，略。
- *PRT (Precomputed Radiance Transfer)*
  - PRT 的基本思想是，把渲染方程分为 lighting（环境光项）和 lighting transport (Visibility & BRDF) 两部分，我们认为（假设）只有 liighting 部分发生变化（旋转 or 更换光源），而 lighting transport 部分不变
    - 环境光照是无限远处，visibility 是着色点对无限远处的光照可见性，当然不变；BRDF 是对某个出射角度在某个入射角度的性质，也是不变值。也就是，我们考虑静态场景动态光源
  - 于是，lighting 部分可以用球谐函数近似（预计算），lighting transport 部分不变，也可以预计算！
  - 分为 diffuse 和 glossy 两种情况介绍
  - 此外还介绍了一些除 SH 外的其它 PRT 方法如 wavelet

== Lec7/8/9: Real-time Global Illumination
=== 三维空间方法
- *RSM (Reflective Shadow Map)* 是一种基于 shadow map 的全局光照方法
  - 它的基本思想是把光源的反射信息存储在 shadow map 中，然后根据其分辨率把每个像素都当做一个次级光源计算间接光照
  - 通常将将所有次级光源的表面设为 diffuse（摆脱视角依赖），且不考虑 visibility（避免每个次级光源都再生成 shadow map）
  - 再优化一点的话，就是以 shading point 为中心，只根据其部分周围点的距离和深度来加权计算虚拟光源的贡献。
  - RSM 主要用于处理间接光照，尤其适用于强方向性光源如手电筒、聚光灯。严格来说不算“三维空间”方法，但主要是为了强调跟后面屏幕空间的区别
- *Light Propagating Volume (LPV)* 是一种基于体积的全局光照方法
  - 它的基本思想是查询每个 shading point 在任意方向上的 radiance，并且注意到 radiance 随直线传播不衰减，因此把场景分为 grid (voxels) 来存储光照信息
  - 具体分为三步
    + Generation: 对场景中光源生成直接光照（次级光源），shadow map 就足够了
    + Injection: 预先将场景分为 3D grid，用两阶 SH（$4$ 个数，注意，用了 SH 都会导致高频信息丢失，即假设了 diffuse）存储次级光源 voxel 的 radiance
    + Propagation: 对每个 voxel 进行 $6$ 个面的 radiance 传播、加和，迭代四五次直到收敛（同样，为简单起见不考虑 visibility）
    + Rendering: 采样 voxel 渲染图像
  - 问题：由于 voxel 的分辨率导致 light leaking
    - 工业界使用多分辨率 voxel，叫 cascaded LPV，学术界叫 multi-scale 或 level of detail
  - LPV 不需要预计算，光源和场景都是可以变化的，但是计算量可能还是稍大
- *VXGI (Voxel Global Illumination)* 是 NVIDIA 提出的一个基于 voxel 的全局光照方法
  - 它的基本思想也是把场景分为 (hierarchical) voxel，跟 RSM 一样是个 two-pass algorithm，但不同在于：
    + 从 RSM 直接照亮 pixels $->$ (hierarchical) voxel；
    + 从 LPV 的构建体素后一次 propagation $->$ 构建体素后每个 shading point 都根据其 normal 做 cone tracing 再次跟体素求交（当然这跟 RSM 也不一样，前者是次级光源主动去找其它体素，而后者是 shading point 去找次级光源）
  - Pass 1 (Light-Pass): 关注场景中哪些表面被直接光照照亮。每个体素存储直接光源的*入射方向区间*和体素对应的受光表面的*法线方向区间*（而不是 SH）
  - Pass 2 (Render-Pass): 对于 glossy 材质，产生一个 cone，根据 footprint 到八叉树中相应层级进行查询；对于 diffuse 材质 则是用多个 cone 覆盖半球（不考虑缝隙和重叠）
  - 总之，VXGI 的渲染质量比较好（甚至接近光追），但比 LPV 还慢，且 Light-Pass 前的体素化会有一定预处理需求（限制了如动态场景的应用）

=== 屏幕空间方法
屏幕空间方法只使用屏幕信息，换句话说，是对 existing renderings 进行后处理，知道的信息较少。比如，给一张图用神经网络算出 GI 的方法就属于 screen space 方法。

- Screen Space Ambient Occlusion (SSAO)
  - 首先要知道 AO 方法一般易于实现且比较便宜，并且可以让环境变得更立体。AO 方法非常常用，很多时候即使用其它方法算过 GI 了，也会再加一层 AO 来增强边角部分的遮挡感
  - Key Idea: 跟 Blinn-Phong 一样假设 ambient light 是个常数，但是考虑 different visibility（数学上，就是 RTR approximation equation 把 visibility 拆出来），此外假设物体材质为 diffuse
  - 如果是在 3D space，visibility 只需要往四周采样即可，但在 screen space，我们只能*在 Z-Buffer 中采样*！
    - 采样时，需要考虑一个半径的 trade-off（太大了容易把宽敞空间算作遮蔽，太小则会漏掉遮蔽）
    - 会有一些几何导致 z-buffer 失效，但反正都已经采样了，不在乎这点误差
    - 进一步，可以用 GBuffer 来存法向信息（延迟渲染普及之后），来实现半球上的 SSAO，真正把 $cos th$ 加权纳入考虑 ($->$ GTAO)
- Screen Space Directional Occlusion (SSDO)
  - SSDO 跟 SSAO 一样，也是用 camera 处的可见性间接反应 shading point 处对次级光源的可见性；但它对间接光照的考虑正好跟 SSAO 相反，它假设次级光源来自比较近的地方，被遮挡的点反而是要考虑的光源
    - SSAO 是假设次级光源来自远处，被遮挡点则没有间接光照。也因此，SSAO 只是简单地为物体加上阴影，而不能真正把有颜色的间接光照算出来 (color bleeding)
    - 实际上，SSAO 跟 SSDO 应该互补，才是正确的效果。更一般地说，*Ray Tracing 才是 AO 的真正未来方向*
  - 总之，SSDO 的光照细节会更好；不过它具有一切使用 Screen Space 算法的弊端，如 false occlusion、信息丢失（且由于无法像 SSAO 那样考虑来自远处的间接光，信息丢失更严重）
- Screen Space Reflection (SSR)
  - SSR 实际上不止反射，它*几乎是把 Ray Tracing 搬到了屏幕空间里*，因此可以处理 specular, glossy, diffuse 等情况（无非是反射光线数量和方向分布的问题，还可以对采样算法进行一些优化）
  - SSR 假设屏幕空间已经基本具备所有模拟光线弹射的条件 (normal, depth)，而由于屏幕空间无法做 ray casting，因此需要用 ray marching 来处理反射光线（这里用动态步长的层级结构来加速，即 min-pooling mipmap）。找到反射光线与物体的交点（次级光源）后，剩下的着色方法就跟 ray tracing 一模一样（注意要假设次级光源为 diffuse）

== Lec10/11: Real-time Physically-Based Rendering
- 微表面模型 Microfacet
  $ f_r (w_o, w_i) = frac(F_r (w_o) G(w_o,w_i) D(w_h), 4 (n dot w_o) (n dot w_i)) $
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
    - 并且随着延迟渲染的发展，GBuffer 中可以存储 world space coordinates, normal, RGB, Object ID 等，可以拿到更多信息
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
    - 利用 "free" feature of GBuffer，它不涉及 multi-bounces，因此是 noise-free 的 (depth, normal, color, position, etc.)
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
    - 用神经网络降噪，且有 GBuffer 的辅助，用最典型的 U-Net 结构。用 recurrent 引入时序信息，后续也有单图的做法
    - 纯 DL 大力出奇迹，没有涉及 motion vector 之类，也就没有对应的那些问题。但其问题在于神经网络速度慢，在那个时候大概要 $50ms$，基本没有实用价值
- *Temporal Anti-Aliasing (AA) / Super Sampling (SS)*
  - TAA 基本跟 RTRT 里面的方法一模一样，不同在于有个 jitter filtering 的概念，用一种固定 pattern 进行采样的抖动，比纯随机更好
  - DLSS
    + DLSS 1.0: 将低分辨率硬拉成高分辨率势必需要一些额外信息。DLSS 1.0 通过数据驱动的方法去硬猜，针对每个游戏或者场景单独训练出一个神经网络，学习一些常见的物体边缘，将分辨率拉高后模糊的边缘替换
    + DLSS 2.0: 引入 temporal 信息，即 TAA-like 方法。但不同在于，由于需要真正提升分辨率，因此对于 temporal failure 不再能用 clamping 方法处理（会导致小像素的值是根据周围点颜色猜测出来的，即高分辨率但模糊）。神经网络不是直接输出混合后的颜色，而是预测怎么将上一帧和当前帧的结果混合
- *Deferred Shading 延迟渲染*
  - 传统的光栅化过程：Triangles $->$ fragments $->$ depth test $->$ shade $->$ pixel。很多 fragment 即使通过了 depth test 后续也会被其它 fragment 覆盖，却进行了 shading 计算，导致浪费（一个极端的例子，所有 mesh 被以从远到近的顺序送入，全部通过了 depth test，但大量之前的 mesh 被部分覆盖）
  - 延迟渲染的基本思路就是 2 pass rasterization：第一次不做 shading，只更新 depth buffer；第二次重新 rasterize，此时通过 depth test 的物体一定是最终可见的
    - 注：弹幕提醒这里似乎讲错了，这其实是 Early-Z 而不是 Deferred Shading，后者的重点在于 GBuffer 和多光源
- *Tiled Shading & Clustered Shading*
  - Key Observation 是光照强度随距离平方衰减，如果做一个阈值，那么光源的影响范围是一个球体
  - 我们可以从屏幕的视角分成若干个小块 (tile)，每个小块只跟相交的光源交互；进一步，每个小块（3D 空间中是一个视锥）可以在深度方向进行切片，形成一个 3D grid (cluster)，每个 cluster 只跟相交的光源交互。用这类方法，可以避免无意义 shading
  - 这个方法最初实际上来源于移动端显存不足的问题，通过切分为 tile 来减小 GBuffer 需求，一小块渲染好了放到 Framebuffer 中再算下一小块（因此也可以减小 Framebuffer 的读写压力）
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
