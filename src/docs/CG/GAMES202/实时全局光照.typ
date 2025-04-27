---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES202 笔记",
  lang: "zh",
)

有点后悔没有早点开始看这门课，里面的很多概念当初我在网上四处扒资料才理解了一点点……

- GAMES202 也没有咋写详细笔记，可以参考这些笔记
  + #link("https://zhuanlan.zhihu.com/p/363333150")[知乎 | Games202 高质量实时渲染课堂笔记 by CarlHer]
  + #link("https://www.zhihu.com/column/c_1473816420539097088")[知乎 | GAMES202 高质量实时渲染-个人笔记 by 风烟流年]（这个可能整理得更好一些）
  + #link("https://blog.csdn.net/yx314636922/category_11601225.html")[CSDN | GAMES202 by 我要吐泡泡了哦]（这个也不错）

另外，这门课据闫令琪的说法，不会有 GAMES101 那样贯穿的主线，而是分几个 topic 来介绍。Global Illumination (GI) 部分加入 GAMES104 的内容。

#let dst = math.text("dst")
#let src = math.text("src")
#counter(heading).update(4)

= Lec7/8/9: Real-time Global Illumination
这部分加入较多 GAMES104 的知识，以及一些从其它博客看来的东西。

== 三维空间方法
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

== 屏幕空间方法 (SSGI)
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
  - SSR 假设屏幕空间已经基本具备所有模拟光线弹射的条件 (normal, depth)，而由于屏幕空间无法做 ray casting，因此需要用 ray marching 来处理反射光线（这里用动态步长的层级结构来加速，即 min-pooling mipmap，或者叫 Hi-Z）。找到反射光线与物体的交点（次级光源）后，剩下的着色方法就跟 ray tracing 一模一样（注意要假设次级光源为 diffuse）
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
