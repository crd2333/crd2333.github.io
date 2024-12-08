---
order: 3
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机图形学",
  lang: "zh",
)

- 主要是 Games 101 的笔记，然后加入了部分 ZJU 课上的新东西

#quote()[
  - 首先上来贴几个别人的笔记
    + #link("https://www.bilibili.com/read/readlist/rl709699?spm_id_from=333.999.0.0")[B站笔记]
    + #link("https://iewug.github.io/book/GAMES101.html#01-overview")[博客笔记]
    + #link("https://www.zhihu.com/column/c_1249465121615204352")[知乎笔记]
    + #link("https://blog.csdn.net/Motarookie/article/details/121638314")[CSDN笔记]
  - #link("https://sites.cs.ucsb.edu/~lingqi/teaching/games101.html")[Games101 的主页]
]

#counter(heading).update(5)

= Ray Tracing 光线追踪
#info()[
  + 基本原理
  + 加速结构
  + 辐射度量学、渲染方程与全局光照
  + 蒙特卡洛积分与路径追踪
]

== 光线追踪原理
- 光栅化 v.s. 光线追踪
  - 光栅化：已知三角形在屏幕上的二维坐标，找出哪些像素被三角形覆盖（物体找像素点）；
  - 光线追踪：从相机出发，对每个像素发射射线去探测物体，判断这个像素被谁覆盖（像素点找物体）
- 为什么要有光线追踪，光栅化不能很好的模拟全局光照效果：难以考虑 glossy reflection（反射性较强的物体）, indirect illuminaiton（间接光照）；不好支持 soft shadow；是一种近似的效果，不准确、不真实
- 首先定义图形学中的光线：光沿直线传播；光线之间不会相互影响、碰撞；光路可逆(reciprocity)，从光源照射到物体反射进入人眼，反着来变成眼睛发射光线照射物体
- Recursive (Whitted-Style) Ray Tracing
  #fig("/public/assets/courses/cg/2024-11-28-22-28-10.png",width:60%)
  - 两个假设前提：人眼是一个点；场景中的物体，光线打到后都会进行完美的反射/折射；
  - 每发生一次折射或者反射（弹射点）都计算一次着色，前提是该点不在阴影内，如此递归计算
    + 从视点从成像平面发出光线，检测是否与物体碰撞
    + 碰撞后生成折射和反射部分
    + 递归计算生成的光线
    + 所有弹射点都与光源计算一次着色，前提是该弹射点能被光源看见
    + 将所有着色通过某种加权叠加起来，得到最终成像平面上的像素的颜色
  - 为了后续说明方便，课程定义了一些概念：
    + *primary ray*：从视角出发第一次打到物体的光线
    + *secondary rays*：弹射之后的光线
    + *shadow rays*：判断可见性的光线
  - 那么问题的重点就成了求交点。接下来对其中的技术细节进行讲解

== Ray-Surface Intersection
- Ray Equation
  $ r(t)=o+t d ~~~ 0 =< t < infty $
  - 光线由点光源和方向定义
- Ray Intersection With Implicit Surface 光线*与隐式表面求交*
  - General implicit surface: $p: f(p)=0$
  - 直接把光线方程带入: $f(o+t d)=0$
  - 求解 real, positive roots 即可
- Ray Intersection With Explicit Triangle 光线*与显式表面（三角形）求交*
  - 通过光线和三角形求交可以实现
    + 渲染（判断可见性，计算阴影、光照）；
    + 几何（判断点是否在物体内，通过光源到点的线段与物体交点数量的奇偶性）
  - 求交方法一：遍历物体每个三角形，判断与光线是否相交
    + 光线-平面求交
    + 计算交点是否在三角形内
    #fig("/public/assets/courses/cg/2024-11-28-22-33-57.png",width: 40%)
  - 求交方法二：Möller-Trumbore 射线-三角形求交算法（MT 算法）
    - 计算光线是否在三角形内以及与平面交点
    - 核心出发点是用重心坐标表示平面 #h(1fr)
    #fig("/public/assets/Courses/CG/img-2024-07-30-14-36-34.png",width: 40%)
    - 具体步骤
      + 求解 $t，b1，b2$（三个式子三个未知数，求解方法为克莱姆法则）
      + 解出来之后，看是否合理：#cnum(1) 沿着这个方向（$t$ 非负）；#cnum(2) 在三角形内（$b1，b2$ 非负）

== Accelerating Ray-Surface Intersection
- 空间划分与包围盒 Bounding Volumes
- 常用 Axis-Aligned-Bounding-Box(AABB) 轴对齐包围盒
  - 加速原理：AABB 盒的好处就在于光线与盒子的交点很容易计算
    - 复杂的三角形与光线求交问题 $-->$ 先是简单的盒子与光线求交问题，再是盒子内的三角形与光线求交（更精细的相交判断）
    + 首先做预处理对空间做划分（均匀或非均匀）
    + 剔除不包含任何三角形的盒子
    + 计算一条光线与哪些盒子有交点
    + 在这些盒子中再计算光线与三角形的交点
- 以 2D 为例，在 x-plane 和 y-plane 上分别求出 $t_min$ 和 $t_max$，然后
  $ t_"enter"=max{t_min}, t_"exit"=min{t_max} $
  - 算 $t_"enter"$ 和 $t_"exit"$，光线与 box 有交点的判定条件当且仅当 #h(1fr)
    $ t_"enter" < t_"exit" "&&" t_"exit" >= 0 $
  #fig("/public/assets/courses/cg/2024-11-28-22-45-08.png",width: 60%)
- 包围盒的划分，一般有 Uniform grids，Spatial Partitions 和 Object Partitions 三种

=== Uniform Grid
- 将场景划分成一个个规整的格子，步骤如下
  + 找到包围盒
  + 创建格子
  + 存储每个对象至格子中
- 问题
  - 分辨率太小则失去划分的意义，太大则要做很多次和格子求交的计算
  - 通常只适用于规整的场景
=== Spatial Partitions
- 特指非均匀空间划分
  + Oct-Tree：类似八叉树结构，注意下面省略了一些格子的后续划分，格子内没有物体或物体足够少时，停止继续划分
  + BSP-Tree：空间二分的方法，每次选一个方向砍一刀，不是横平竖直（并非 AABB），所以不好求交，维度越高越难算
  + *KD-Tree*：每次划分只沿着某个轴砍一刀，XYZ 交替砍，不一定砍正中间，每次分出两块，类似二叉树结构
    - KD-tree 的缺陷：不好计算三角形与包围盒的相交性（不好初始化）；一个三角形可能属于多个包围盒导致冗余计算
  #fig("/public/assets/courses/cg/2024-11-28-22-51-25.png",width:50%)

=== Object Partitions
- 对象划分 Bounding Volume Hierarchy(BVH)
  #fig("/public/assets/courses/cg/2024-11-28-22-52-20.png",width:50%)
  - 将一个场景用一个包围盒包住，按照一定划分方案递归地将盒子划分成两组，对两组物体再求一个包围盒（$x y z$ 的最值作为边界），最终划分到叶子节点时每个都只包含少量三角形
  - 这样每个包围盒可能有相交（无伤大雅）但三角形不会有重复（不会出现在多个包围盒中），并且求包围盒的办法省去了三角形与包围盒求交的麻烦
  - 分组方法一般采用启发式
    + 按轴的次序进行划分
    + 按最长轴进行划分
    + 选择处在中间（中位数意义上，划分后两边数量相同）的三角形
  - 课上讲的 BVH 是宏观上的概念，没有细讲其实现，可以看 #link("https://www.cnblogs.com/lookof/p/3546320.html")[这篇博客]

== 辐射度量学(Basic radiometry)、渲染方程与全局光照
- Motivation：Blinn-phong 着色计算、Whitted styled 光线追踪都不够真实
- 辐射度量学：在物理上准确定义光照的方法，但依然在几何光学中的描述，不涉及光的波动性、互相干扰等
- 几个概念：
  + *Radiance Energy 辐射能 $Q$* #h(1fr)
    $ Q ~~~ [J = "Joule"] $
    - 基本不咋用
  + *Radiant Flux(Power) 辐射通量 $Phi$*
    $ Phi = (dif Q)/(dif t) ~~~ [W = "Watt"][l m="lumen"] $
    - 有时也把这个误称为能量
  + *Radiant Intensity 辐射强度 $I$*
    - Light Emitted from a Source
    $ I(omega) = (dif Phi)/(dif omega) ~~~ [W/(s r)][(l m)/(s r) = c d = "candela"] $
    - solid angle 立体角
  + *Irradiance 辐照度 $E$*
    - Light Incident on a Surface
    - *Irradiance* 是指单位照射面积所接收到的 power
    $ E = (dif Phi)/(dif A cos theta) ~~~ [W/m^2] $
    - 其中 $A$ 是投影后的有效面积
    - 注意区分 Intensity 和 Irradiance，对一个向外锥形，前者不变而后者随距离减小
  + *Radiance 辐亮度 $L$*
    - Light Reflected from a Surface
    - *Radiance* 是指每单位立体角，每单位垂直面积的功率。同时指定了光的方向与照射表面所受到的亮度
    $ L = (dif^2 Phi(p, omega))/(dif A cos theta dif omega) ~~~ [W/(s r ~ m^2)][(c d)/(m^2)=(l m)/(s r ~ m^2)=n i t] $
    - $theta$ 是入射（或出射）光线与法向量的夹角
    - Radiance 和 Irradiance, Intensity 的区别在于是否有方向性
    - 把 Irradiance 和 Intensity 联系起来，Irradiance per solid angle 或 Intensity per projected unit area
    - *Irradiance* 与 *Radiance* 之间的关系 #h(1fr)
      $ E(p)=int_(H^2) L_i (p, omega) cos theta dif omega $
- 双向反射分布函数(Bidirectional Reflectance Distribution Function, BRDF)
  - 是一个 4D function $f(i,o)$（3D 的方向由于用单位向量表示所以少一个自由度，例如球面的 $th, phi$ 表示）
  - 如果固定 $i$，就是描述了入射($omega_i$)光线经过某个表面反射后在各个可能的出射方向($omega_r$)上能量分布（反射率）
  $ f_r (omega_i -> omega_r)=(dif L_r (omega_r))/(dif E_i (omega_i)) = (dif L_r (omega_r)) / (L_i (omega_i) cos theta_i dif omega_i) ~~~ [1/(s r)] $
- 用 BRDF 描述的反射方程
  $ L_r (p, omega_r)=int_(H^2) f_r (p, omega_i -> omega_r) L_i (p, omega_i) cos theta_i dif omega_i $
  - 注意，入射光不止来自光源，也可能是其他物体反射的光（递归思想，反射出去的光 $L_r$ 也可被当做其他物体的入射光 $E_i$）
- 推广为渲染方程（绘制方程）
  - 物体自发光 + 反射方程，式中 $Om^+$ 表示上半球面，$p$ 是着色点
  $ L_o (p, omega_o)=L_e (p, omega_o) + int_(Omega^+) f_r (p, omega_i, omega_o) L_i (p, omega_i) (n dot omega_i) dif omega_i $
  - 换一个角度看，把式子通过“算子”概念简写为 $L=E+K L$ #h(1fr)
    - 然后移项泰勒展开得到 $L=E+K E+K^2 E+...$，如下图
    - 光栅化实质上是只考虑了前两项（直接光照），这也是为什么我们需要光线追踪
    - 全局光照 = 直接光照(Direct Light) + 间接光照(Indirect Light)
    #fig("/public/assets/Courses/CG/img-2024-07-31-23-36-46.png", width: 60%)

== 蒙特卡洛路径追踪(Path Tracing)
- 概率论基础
- 回忆 Whitted-styled 光线追踪
  - 摄像机发射光线，打到不透明物体，则认为是漫反射，直接连到光源做阴影判断、着色计算；
  - 打到透明物体，发生折射、反射
  - 总之光线只有三种行为——镜面反射、折射、漫反射
  - 缺陷：
    + 难以处理毛面光滑材质
    + 忽略了漫反射物体之间的反射影响
- 采用蒙特卡洛方法解渲染方程：直接光照；全局光照，采用递归
  #fig("/public/assets/Courses/CG/img-2024-08-01-22-25-38.png", width: 70%)
  - 问题一：$"rays"=N^"bounces"$，指数级增长。当 $N=1$ 时，就称为 *path tracing* 算法
    - $N=1$ 时 noise 的问题：在每个像素内使用 $N$ 条 path，将 path 结果做平均（同时也解决了采样频率，解决锯齿问题）
  - 问题二：递归算法的收敛条件。如果设置终止递归条件，与自然界中光线就是弹射无数次相悖。如何不无限递归又不损失能量？
    - 俄罗斯轮盘赌 RussianRoulette(RR)，以一定的概率停止追踪（类似神经网络的 dropout）
    - 期望停止次数为 $1/(1-P)$
    - 而结果的正确性由 $E=P times L_o / P + (1-P) times 0 = L_o$ 保证
  - 问题三：低采样数的情况下噪点太多，而高采样率又费性能（当光源越小，越多的光线被浪费）
    - _*重要性采样*_：直接采样光源的表面（其它方向概率为 $0$），这样就没有光线被浪费
    - 蒙特卡洛在（单个像素内）立体角 $omega$ 上采样，在 $omega$ 上积分；现在对光源面采样，就需要把公式写成对光源面的积分 $ L_(o) (x, omega_(o)) & = integral_(Omega^(+)) L_(i) (x, omega_(i)) f_(r) (x, omega_(i), omega_(o)) cos theta dif omega_(i) \ & = integral_(A) L_(i) (x, omega_(i)) f_(r) (x, omega_(i), omega_(o)) (cos theta cos theta') /  norm(x^(prime) - x)^2) dif A $
    - 这样又只考虑了直接光照，对间接光照依旧按原本方式处理
  - 最终着色计算伪代码为：
    ```
    // 如果 depth 为 0，wo 为从像素打出的光线的出射方向，与物体的第一个交点为 p
    // 如果 depth 不为 0，从之前的交点投出反射光线或光源光线作为 wo，p 为新的交点
    Shade(p, wo) {
      // 1、来自光源的贡献
      对光源均匀采样，即随机选择光源表面一个点x';  // pdf_light = 1 / A
      shoot a ray form p to x';
      L_dir = 0.0;
      if (the ray is not blocked in the middle)	// 判断是否被遮挡
      L_dir = L_i * f_r * cosθ * cosθ' / |x' - p|^2 / pdf_light;

      // 2、来自其他物体的反射光
      L_indir = 0.0;
      Test Russian Roulette with probability P_RR;
      Uniformly sample the hemisphere toward wi;  //pdf_hemi = 1 / 2π
      Trace a ray r(p,wi);
      if (ray r hit a non-emitting object at q)
          L_indir = shade(q, -wi) * f_r * cosθ / pdf_hemi / P_RR;
      return L_dir + L_indir;
    }
    ```
- 最后的结语与拓展
  - Ray tracing: Previous vs. Modern Concepts
    - 过去：Ray tracing == Whitted-style ray tracing
    - 现在：一种 light transport 的广泛方法，包括 (Unidirectional & bidirectional) path tracing, Photon mapping, Metropolis light transport, VCM / UPBP
  - 如何对半球进行均匀采样，更一般地，如何对任意函数进行这样的采样？
  - 随机数的生成(low discrepancy sequences)
  - multiple importance sampling：把对光源和半球的采样相结合
  - 对一个像素的不同 radiance 是直接平均还是加权平均(pixel reconstruction filter)？
  - 算出来的 radiance 还不是最终的颜色（而且并非线性对应），还需要 gamma correction，curves, color space 等

= Materials and Appearances 材质与外观
- 自然界中的材质，实际上并不要求完全一致，我们追求的是计算机模拟真实感

== 计算机图形学中的材质
- 这一节，我们将细化之前提到的 BRDF 概念
  - 在图形学中，材质 == BRDF(Bidirectional Reflectance Distribution Function)
- *漫反射材质(Diffuse)的 BRDF*
  - Light is equally reflected in each output direction
    $ f(i,o) = "constant" $
  - 如果再假设入射光也是均匀的，并且有能量守恒定律 $L_o = L_i$，那么： #h(1fr)
    #fig("/public/assets/Courses/CG/img-2024-08-04-11-39-26.png",width:80%)
    - 定义反射率 $rho$ 来表征一定的能量损失，还可以对 RGB 分别定义 $rho$
- *抛光/毛面金属(Glossy)材质的 BRDF*
  - 这种材质散射规律是在镜面反射方向附近，一小块区域进行均匀的散射
  - 代码实现上，算出*镜面*反射方向$(x,y,z)$，就以$(x,y,z)$为球心（或圆心），内部随机生成点，以反射点到这个点作为真的光线反射方向。在较高 SPP(samples per pixel)下，就能均匀的覆盖镜面反射方向附近的一块小区域
- *（完全）镜面反射(reflect)的 BRDF *
  - 方向描述
    + 直接计算：$omega_o = - omega_i + 2 (omega_i dot n) n$
    + 用天顶角 $phi$ 和方位角 $theta$ 描述：$phi_o = (phi_i+pi) mod 2 pi, ~~ theta_o = theta_i$
    + 还有之前讲过的半程向量描述（简化计算）$h = frac(i+o,norm(i+o))$
  - 镜面反射的 BRDF 不太好写，因为它是一个 delta 函数，只有在某个方向上有值，其它方向上都是 $0$
- *折射材质(ideal reflective/refractive)的 BRDF*
  - Snell's Law（斯涅耳定律，折射定律）：$n_1 sin theta_1 = n_2 sin theta_2$
  - $cos theta_t = sqrt(1 - (n_1/n_2)^2 (1 - (cos theta_i)^2))$，有全反射现象（光密介质$->$光疏介质）
  - 折射无法用严格意义上的 BRDF 描述，而应该用 BTDF(T: transmission)
    - 可以把二者统一看作 BSDF(S: scattering) = BRDF + BTDF
    - 不过，通常情况下，当我们说 BRDF 时，其实就指的是 BSDF
  - 反射与折射能量的分配与入射角度物体属性有关，用 Fresnel Equation 描述
- *菲涅尔项(Fresnel Term)*
  - 菲涅尔效应指：视线垂直于表面时，反射较弱；而当视线非垂直表面时，夹角越小，反射越明显。譬如看脚底游泳池的水是透明的，但是远处的水面反射强烈
  - 定性分析：绝缘体和导体的菲涅尔项不同
  - 定量分析：精确计算菲涅尔项。但很复杂，没有必要，只要知道这玩意儿跟 出/入射角度、介质反射率 $eta$ 有关就行
  - 近似计算：Schlick’s approximation（性价比更高） #h(1fr)
    $ R(th)=R_0+(1-R_0)(1-cos th)^5 $
    - 其中 $R_0=((n_1-n_2)/(n_1+n_2))^2$

== 微表面材质(Microfacet Material)
- 微表面模型
  - 微观上 —— 凹凸不平且每个微元都认为只发生镜面反射(bumpy & specular)；
  - 宏观上 —— 平坦且略有粗糙(flat & rough)。总之，从近处看能看到不同的几何细节，拉远后细节消失
  - 微表面 BRDF 的核心是认为每个微表面都有自己的法向量，它们的分布对整体的法向量有贡献
- 用法线分布描述表面粗糙程度
  #fig("/public/assets/Courses/CG/img-2024-08-04-12-48-55.png",width: 30%)
- 微表面的 BRDF (Microfacet Material's BRDF)
  - 可以看到，微表面材质模型对前面说的几种模型做了整合
  #fig("/public/assets/Courses/CG/img-2024-08-04-12-52-57.png",width: 50%)
  - $F$ 函数是菲涅尔项
    - 它解释了菲涅耳效应，该效应使得与表面成较高的入射角的光线会以更高的镜面反射率进行反射
  - $G$ 是几何衰减项
    - 当入射光以非常平(Grazing Angle 掠射角度)的射向表面时，有些凸起的微表面就会遮挡住后面的微表面，也就是 *shadowing*
    - 当出射光以非常平的角度离开表面时，有些凸起的微表面就会遮挡住前面的微表面，也就是 *masking*
    - $G$项 其实对这些情况做了修正
  - $D$ 是法向分布项
    - 它解释了在观看者角度反射光的微平面的比例，描述了在这个表面周围的法线分布情况
    - 例如，当输入向量 $h$ 时，如果微平面中有 $35%$ 与向量 $h$ 取向一致，则法线分布函数就会返回 $0.35$
  - 不同的 microfacet BRDFs 主要在 $D$ 上有所不同，经典模型包括: Blinn, Cook-Torrance, Ashikmin, GGX, Oren-Nayar
  - 以 Cook-Torrance Model 为例
    $
    D = frac(e^(frac(-tan^2 (al),m^2)), pi m^2 cos^4 (al)), ~~~ al = arccos (n dot h)\
    G = min(1, frac(2 (h dot n) (o dot n), o dot n), frac(2 (h dot n) (i dot n), o dot n))
    $
    - D is the Beckmann distribution
    - Parameter m controls the shape of highlight
    - Highly compact representation
- 可以根据物体微表面是否具有方向性将物体分类 —— 各向同性(Isotropic)和各向异性(Anisotropic)材质
  - *各向同性* —— 各个方向法线分布相似；
  - *各向异性* —— 各个方向法线分布不同，如沿着某个方向刷过的金属
  - 后者会造成一个现象，高光方向会跟物体的方向不一致 #h(1fr)
    #fig("/public/assets/Courses/CG/2024-11-27-18-53-25.png",width: 40%)
  - 用 BRDF 定义，各向同性材质满足 BRDF 与方位角 $phi$ 无关
    $ f_r (th_i,phi_i; th_r, phi_r) = f_r (th_i, th_r, |phi_r - phi_i|) $
    - $phi_i,phi_r$ 各自的描述变为它们的差值，BRDF 从 4D 降低到 3D
- 微表面模型效果特别好，是 SOTA，现在特别火的 PBR(physically Based Rendering)一定会使用微表面模型

== BRDF Summary
- BRDF 的性质总结
  + 非负性(non-negativity) #h(1fr)
    $ f_r (omega_i -> omega_r) >= 0 $
  + 线性(linearity)
    $ L_r (p, omega_r) = int^(H^2) f_r (p, omega_i -> omega_r) L_i (p, omega_i) cos theta_i dif omega_i $
  + 可逆性(reciprocity)
    $ f_r (omega_i -> omega_r) = f_r (omega_r -> omega_i) $
  + 能量守恒(energy conservation)
    $ forall omega_r, int^(H^2) f_r (omega_i -> omega_r) cos theta_i dif omega_i =< 1 $
  + 各向同性和各向异性(Isotropic vs. anisotropic)
- *测量 BRDF (Reflectance Capture)*
  - 前面对于 BRDF 的讨论都隐藏了 BRDF 的定义细节。况且，即使我们对微表面模型的 BRDF 给出了一个公式，但其中比如菲涅尔项本身就是近似计算的，不够精确。有时候，我们不需要给出 BRDF 的精确模型（公式），只需要测量后直接用即可
  - 我们希望 Reflectance Capture 能够 Accurate modeling of real-world materials
    + High fidelity
    + High performance
    + Fully / semi-automatic
    - Tuning BRDF parameters is an art!
  - 一般测量方法
    - 遍历入射、出射方向，测量 radiance（入射出射可以互换，因为光路可逆），复杂度为 $O(n^4)$
    - 这是最普遍的方法，质量也最高，但极度 time consuming
    - 一些优化
      + 各向同性的材质，可以把 4D 降到 3D
      + 由于光的可逆性，工作量可以减少一半
      + 不用采样那么密集，就采样若干个点，其中间的点可以插值出来
      + ...
  - Illumination Multiplexing 测量方法
    - 用 hundreds of 光源同时照射，相机的数量少一些(one or a couple of cameras)
    - 每个光源在任意时刻的亮度有所不同（基函数），通过光源的不同组合(Project certain patterns)去照射
    - 然后用计算的方法去反解如果每个灯单独亮时的反射情况(recover the reflectance with a lookup table)
    - Far more efficient, Widely used in movie production
  - 测量出来 BRDF 的存储，一个挺热门的方向是用神经网络压缩数据
  - MERL BRDF Database 是一个很好的 BRDF 数据库
- 可视化 BRDF
  - 一个有用的工具 #link("https://www.disneyanimation.com/technology/brdf.html")[Disney's BRDF Explorer]

= Advanced Topics in Rendering 渲染前沿技术介绍
- 偏概述和思想介绍，具体技术细节不展开
- *有偏*、*无偏*，以及有偏中的*一致*

== 无偏光线传播方法
- 普通的 Path Tracing 也是无偏的
- 双向路径追踪 (Bidirectional Path Tracing, BDPT)
  - 从摄像机出发投射子路径，从光源出发投射子路径，把两者的端点相连（在技术上比较复杂）
  - 之前学的路径追踪对于某些用间接光照亮的场景不太好用（由于光源角度苛刻，成功采样概率小），而 BDPT 可以提高采样效率从而减少噪点，但会导致计算速度下降
- Metropolis Light Transport(MLT)
  - 马尔可夫链蒙特卡洛(Markov Chain Monte Carlo, MCMC)的应用
  - 马尔可夫链可以根据一个样本，生成跟这个样本靠近的下一个样本，使得这些样本的分布跟被积函数曲线相似，这样的 variance 较小。用在路径追踪里面，就可以实现“局部扰动现有路径去获取一个新的路径”（在现有采样点附近生成新采样点，连起来得到新路径）
  - 适用于复杂场景（间接光照、Caustics 现象），只要找到一条，我就能生成很多条
  - 缺陷：难以估计收敛速度，不知道跑多久能产生没有噪点的渲染结果图；不能保证每像素的收敛速度相等，通常会产生“肮脏”的结果，因此一般不用于渲染动画

== 有偏光线传播方法
- 光子映射(Photon Mapping)
  - 适用于渲染焦散(caustics)、Specular-Diffuse-Specular(SDS)路径
  - 实现方法（两步）
    + Stage 1——photon tracing：光源发射光子，类似光线一样正常传播（反射、折射），打到 Diffuse 表面后停止并记录
    + Stage 2——photon collection(final gathering)：摄像机出发打出子路径，正常传播，打到 Diffuse 表面后停止
    + Calculation——local density estimation：对于每个像素，找到它附近的 $N$ 个光子（怎么找？把光子排成加速结构如 k 近邻），计算它们的密度为 $N/A$
  - 这种渲染方法，往往是模糊和噪声(bias & variance)之间的平衡：$N$ 取小则噪声大，$N$ 取大则变模糊
    - BTW，有偏 == 模糊；一致 == 样本接近无穷则能收敛到不模糊的结果
  - 由于局部密度估计应该估计每个着色点的密度 $(di N) / (di A)$，但是实际计算的是 $(Delta N) / (Delta A)$，只有加大 $N$ 使 $Delta A$ 趋近于 $0$ 才能使估计值趋近于真实值，因此是一个有偏但一致的方法
    - 此时我们也能明白为什么用固定 $N$ 计算 $A$ 的方法而不是固定 $A$，因为后者永远有偏
- 光子映射 + 双向路径追踪 (Vertex Connection and Merging, VCM)
  - 很复杂，但是想法很简单，依旧是提高采样效率
  - 在 BDPT 的基础上，如果光源的子路径和摄像机的子路径最后交点非常接近但又不可能反射折射到对方，那么就把光源子路径认为是发射光子的路径，从而把这种情况也利用起来
- 实时辐射度算法(Instant Radiosity, IR)
  - 有时也叫 many-light approaches
  - 关键思想： 把光源照亮的点（经过 $1$ 次或多次弹射）当做一堆新的点光源(Vritual Point Light) (VPL)，用它们照亮着色点。然后用普通的光线追踪算法计算
  - 从相机发射光线击中的每个着色点，都连接到这些光源计算光照。对于那些 VPL，是从真正光源发射后经过弹射形成，某种意义上也是一种双向路径追踪。宏观上看，这个方法实现了用直接光照的计算方法得到的间接光照的结果
  - 优点是计算速度快，通常在漫反射场景会有很好的表现；缺点是不能处理 Glossy 材质，以及当光源离着色点特别近时会出现异常亮点（因为渲染方程中有 $1/r^2$ 项）

== 非表面模型(Non-Surface Models)
=== 参与介质(Participating Media)或散射介质
- 类似云、雾霾等，显然不是定义在一个表面上的，而是定义在空间中的。当光线穿过，介质会吸收一定的能量，并且朝各个方向散射能量
- 定义参与介质以何种方式向外散射的函数叫相位函数(Phase Function)，很像 3D 的 BRDF
  #fig("/public/assets/Courses/CG/img-2024-08-04-20-58-32.png", width: 80%)
- 如何渲染：随机选择一个方向反弹（决定散射）；随机选择一个行进距离（决定吸收）；每个点都连到光源（感觉有点像 Whitted-Styled），但不再用渲染方程而是用新的 3D 的方程来算着色
- 事实上我们之前考虑的很多物体都不算完美的表面，只是光线进入多跟少的问题

=== 毛发、纤维模型
- 考虑光线如何跟一根曲线作用
- Kajiya-Kay Model（不常用，比较简单、不真实）：光线击中细小圆柱，被反射到一个圆锥形的区域中，同时还会进行镜面反射和漫反射
- Marschner Model（计算量爆炸，但真实）
  - 把光线与毛发的作用分为三个部分
    + R：在毛发表面反射到一个锥形区域
    + TT：光线穿过毛发表面，发生折射进入内部，然后穿出再发生一个折射，形成一块锥形折射区域
    + TRT：穿过第一层表面折射后，在第二层的内壁发生反射，然后再从第一层折射出去，也是一块锥形区域
  - 把人的毛发认为类似于玻璃圆柱体，分为表皮(cuticle)和皮质(cortex)。皮质层对光线有不同程度的吸收，色素含量决定发色，黑发吸收多，金发吸收少
    #grid2(
      fig("/public/assets/Courses/CG/img-2024-08-04-21-10-19.png", width: 70%),
      fig("/public/assets/Courses/CG/img-2024-08-04-21-13-52.png", width: 80%)
    )
- 动物皮毛(Animal Fur Appearance)
  - 如果直接把人头发的模型套用到动物身上效果并不好
  - 从生物学的角度发现，皮毛最内层还可以分出*髓质*(medulla)，人头发的髓质比动物皮毛的小得多。而光线进去这种髓质更容易发生散射
  - 双层圆柱模型(Double Cylinder Model)：某些人（闫）在之前的毛发模型基础上多加了两种作用方式 TTs, TRTs，总共五种组成方式
    #fig("/public/assets/Courses/CG/img-2024-08-04-21-25-48.png", width: 60%)

=== 颗粒状材质(Granular Material)
- 由许多小颗粒组成的物体，如沙堡等
- 计算量非常大，因此并没有广泛应用

== 表面模型(Surface Models)
=== 半透明材质(Translucent Material)
- 实际上不太应该翻译成“半透明”(semi-transparent)，因为它不仅仅是半透明所对应的吸收，还有一定的散射
- *次表面散射*(Subsurface Scattering)：光线从一个点进入材质，在表面的下方（内部）经过多次散射后，从其他一些点射出
  - 双向次表面散射反射分布函数(BSSRDF)：是对 BRDF 概念的延伸，某个点出射的 Radiance 是其他点的入射 Radiance 贡献的
    #fig("/public/assets/Courses/CG/img-2024-08-04-21-35-28.png", width: 70%)
  - 计算比较复杂，因此又有一种近似的方法被提出
- Dipole Approximation：引入两个点光源来近似达到次表面散射的效果
  #fig("/public/assets/Courses/CG/img-2024-08-04-21-38-45.png", width: 70%)

=== 布料材质(Cloth)
- 布料有一系列缠绕的纤维组成
- 三个层级：纤维(fiber)缠绕形成股(ply)，股缠绕形成线(thread)，线编织形成布料(cloth)
- 有时当做一个表面，忽略细节使用 BRDF 进行渲染
- 有时看做参与介质进行渲染，计算量巨大
- 有时直接把每一根纤维都进行渲染，计算量巨大

== 细节模型
- 微表面模型中最重要的是它的法线分布(NDF)，但是我们描述这个分布用的都是很简单的模型，比如正态分布之类的，真实的分布要更复杂（基本符合统计规律的同时包含一些细节，比如划痕之类）
- 如果使用法线贴图来把这些起伏细节都定义出来，会非常耗时。使用路径追踪困难的点在于，微表面的镜面反射在法线分布复杂的情况下，很难建立有效的的光线通路从相机出发打到光源（反之也是一样）
- 我们可以让一个像素对应一块小区域(patch)，用 patch 的统计意义的法线分布来反射光线。当 patch 变得微小时，一样能够显示出细节（感觉又是速度和细度的 trade-off）
  #grid2(
    fig("/public/assets/Courses/CG/img-2024-08-05-10-44-43.png"),
    fig("/public/assets/Courses/CG/img-2024-08-05-10-45-02.png")
  )
- 另外，在深入到这么微小的尺度后，波动光学效应也变得明显。这方面的公式完全没有提到（涉及复数域上的积分等），波动光学的 BRDF 结果与几何光学类似，但由于干涉出现不连续的特点

== 程序化生成外观
- 纹理这种东西的存储是个大问题，Can we define details without textures?
- 因此有一种方法是不存，把它变成一个 noise 函数(3D)，什么时候要用就去动态查询，生成的噪声可能需要经过 thresholding 二值化处理
- 应用：车绣效果、程序化地形、水面、木头纹理

= Cameras, Lenses and Light Fields 相机与透镜
- *图像* = *合成* + *捕捉*（*捕捉*，比如拿个相机把真实的物体拍下来，之后用到你的*图像*里）
- 一些部件
  + 快门：可以控制光在一个极短的时间内进入相机
  + 传感器：在曝光过程中，在传感器每个点上记录其接受到的 irradiance（没有方向信息）
  + 针孔相机和透镜相机（为什么要有针孔或者透镜，正因为记录的是 irradiance）
- 针孔相机：没有景深，任何地方都是锐利的而不是虚化的
- 视场(Field of Vied, FOV)
  - 定义针孔相机的 $h$ 和 $f$，$"FOV" = 2 * arctan(0.5 * h / f)$
  #fig("/public/assets/Courses/CG/img-2024-08-05-12-08-38.png",width: 60%)
  - 通常描述焦距都会换算到 $h=35"mm"$ 所对应的焦距长度
  - 如果改传感器大小，涉及到传感器和胶片的关系，一般认为混淆着使用二者概念
- 曝光(Exposure)
  - H = T x E
    - T：曝光时间（time），通过快门控制多长时间光可以进入（明亮和昏暗的场景中）
    - E：辐照度(irradiance)，感光器的单位面积上接收到的辐射通量总和，通过光圈大小(aperture)和焦距控制
  - 摄影中的曝光影响因素
    - 快门(Shutter speed)：改变传感器每个像素吸收光的时间，快门打开时间长，拍摄运动的物体就会拖影（运动模糊），因为物体在光圈打开这段时间内可能每刻都在运动，而相机把每一刻的信息都记录下来了
    - 光圈大小(Aperture size)：通过开关光圈改变光圈级数(F-Number, F-Stop)。写作 $F N$ 或 $F \/ N$,其中 $N$ 就是 $F$ 数，可以简单形象的理解为光圈直径的倒数（实际上 F-Stop 的数值为 焦距与光圈直径之比，即 $f/D$），*基本上也就等同于透镜的大小*。大光圈会模糊（浅景深），小光圈更清晰。原因见后面章节 CoC 介绍
    - 感光度(ISO gain)：可以简单的理解成后期处理，把结果乘上一个数。在信号的角度理解，这样的操作同时将噪声放大
- 薄透镜近似(Thin Lens Approximation)
  - 理想的薄透镜应该有以下性质
    + 任意平行光穿过透镜会聚焦在焦点处
    + 任意光通过焦点射向透镜，会变为互相平行的光
    + 假设薄透镜的焦距可以任意改变（用透镜组来实现）
  - 薄透镜公式：$1/f = 1/z_i + 1/z_o$
  - Circle of Confusion(CoC)：可以看出C和A成正比——光圈越大越模糊 #h(1fr)
    #fig("/public/assets/Courses/CG/img-2024-08-05-13-53-49.png",width: 70%)
- 渲染中模拟透镜(Ray Tracing Ideal Thin Lenses)
  - 一般光线追踪和光栅化使用的是针孔摄像机模型，但是如果想做出真实相机中的模糊效果，需要模拟薄透镜相机（而且不再需要 MVP 等）
  - (One possible setup)定义成像平面尺寸、透镜焦距 $f$、透镜尺寸（光圈影响模糊程度）、透镜与相机成像平面的距离 $z_i$，根据公式$1/f = 1/z_o + 1/z_i$，算出 focal plane 到透镜的距离 $z_o$
  - 渲染
    + 遍历每个感光器上的点 $x'$（视锥体近平面的每个像素），连接 $x'$ 和透镜中心，与 focal plane 相交于 $x'''$，则 $x'$ 对应的所有经过透镜的光线必然都要相交于这一点
    + 在透镜平面随机采样 SPP 个点 $x''$，*以 $x''$ 作为光线的起点*。一般 SPP 不为 $1$(e.g. 50, cover the whole len)
    + 以 $(x'''-x'')/(|x'''-x''|)$ 得到光线方向$arrow(d)$
    + 计算最近交点，最终得到 radiance，记录到 $x'$
  - 好像还有简化的方法，参考 #link("https://blog.csdn.net/Motarookie/article/details/122998400#:~:text=简化实现方法")[根据我抄的笔记]
- 景深(Depth of Field)
  - 在 focal point 附近的一段范围内的 CoC 并不大（比一个像素小或者差不多大），如果从场景中来的光经过理想透镜后落在这一段内，可以认为场景中的这段深度的成像是清晰、锐利的
    #fig("/public/assets/Courses/CG/img-2024-08-05-14-27-55.png",width: 70%)

= Color and Perception 光场、颜色与感知
- 光场(Light Field / Lumigraph)
- 一个案例：人坐在屋子里，用一张画布将人眼看到的东西全部画下来。然后在人的前面摆上这个画布，以此 2D 图像替代 3D 场景以假乱真（这其实就是VR的原理）

== 全光函数与光场
- 全光函数是个 7D 函数，包含任意一点的位置 $(x, y, z)$、方向 （极坐标 $th, phi$）、波长$(la)$（描述颜色）、时间$(t)$
  - 全光函数描述了摄像机在任何位置，往任何方向看，在任何时间上看到的不同的颜色，描述了整个空间（全息空间）
  - 而光场是全光函数的一小部分，描述任意一点向任意方向的光线的强度
- 光线的定义
  - 一般空间中，我们用 5D 来描述：3D 位置 $(x, y, z)$ + 2D 方向 $(th, phi)$（这里似乎隐含了固定极坐标轴朝向的意思，可能默认轴对齐了）
  - 光场中用 4D 来描述：2D 位置 + 2D 方向 $(th, phi)$，这是怎么理解呢？
- 黑盒（包围盒）思想与光场
  - 我们是怎么看物体的？就像前面的案例一样，我们其实可以不关心物体是什么、怎么组成，当做黑盒。我只需要知道，从某个位置看某个方向过去，能看到什么。
  - 用一个包围盒套住物体。从任何位置、任何方向看向物体，与包围盒有一个交点；由于光路可逆，也可以描述为：从包围盒上这个交点，向任意方向发射光线。如果我们知道包围盒(2D)上任意一点向任意方向(2D)发射光线的信息(radiance)，这就是光场（个人理解：有点往 Path Tracing 里面引入纹理映射的感觉）
  - 再升级一步，由于两点确定一条直线：2D 位置 + 2D 方向 $->$ 2D 位置 + 2D 位置。于是，我们可以用两个平面（两个嵌套的盒子）来描述光场
  - 双平面参数化后的两种视角，物体在 st 面的右侧。图 a 从 uv 面看 st，描述了从不同位置能看到什么样的物体；图 b 从 st 面看 uv，描述了对物体上的同一个点，从不同方向看到的样子（神经辐射场理解方式：每个像素存的是 irradiance ，遍历 uv 面所有点就是把 irradiance 展开成 radiance）
    #fig("/public/assets/Courses/CG/img-2024-08-05-15-37-39.png", width: 80%)
  - 双平面参数化后在实现上也变得更好理解，直接用一排摄像机组成一个平面就好

== 光场照相机
- Lytro 相机，原理就是光场。它最重要的功能：先拍照，后期动态调节聚焦
- 原理（事实上，昆虫的复眼大概就是这个原理）：
  - 一般的摄像机传感器的位置在下图那一排透镜所在的平面上，每个透镜就是一个像素，记录场景的 irradiance。现在，光场摄像机将传感器后移一段距离，原本位置一个像素用透镜替换，然后光穿过透镜后落在新的传感器上，击中一堆像素，这一堆像素记录不同方向的 radiance
  - 从透镜所在平面往左看，不同的透镜对应不同的拍摄位置，每个透镜又记录了来自不同方向的 radiance。总而言之，原本一个像素记录的 irradiance，通过替换为透镜的方法，拆开成不同方向的 radiance 用多个“像素”存储
    #fig("/public/assets/Courses/CG/img-2024-08-05-17-51-25.png", width: 80%)
- 变焦：对于如何实现后期变焦比较复杂，但思想很简单，首先我已经得到了整个光场，只需算出应该对每个像素查询哪条“像素”对应光线，也可能对不同像素查询不同光线
- 不足之处：分辨率不足，原本 $1$ 个像素记录的信息，需要可能 $100$ 个像素来存储；高成本，为了达到普通相机的分辨率，需要更大的胶片，并且仪器造价高，设计复杂

== 颜色的物理、生物基础
- 光谱：光的颜色 $approx$ 波长，强度 $approx$ 光子数量，不同波长的光分布为光谱，图形学主要关注可见光光谱
- 光谱功率分布(Spectral Power Distribution, SPD)
  - 自然界中不同的光对应不同的 SPD
  - SPD 有线性性质
- 从生物上，颜色是并不是光的普遍属性，而是人对光的感知。不同波长的光 $!=$ 颜色
- 人眼跟相机类似，瞳孔对应光圈，晶状体对应透镜，视网膜则是传感器（感光元件）
- 视网膜感光细胞：视杆细胞(Rods)、视锥细胞(Cones)
  - Rods 用来感知光的强度，可以得到灰度图
  - Cones 相对少很多，用来感知颜色，它又被分为 $3$ 类(S-Cone, M-Cone, L-Cone)，SML 三类细胞对光的波长敏感度（回应度）不同
    - 事实上，不同的人这三种细胞的比例和数量呈现很大的差异（也就是颜色在不同人眼中是不一样的，只是定义统一成一样）
- 人看到的不是光谱，而是两种曲线积分后得到 SML 再叠加的结果
  #fig("/public/assets/Courses/CG/2024-11-14-14-03-31.png", width:70%)
  - 那么一定存在一种现象：两种光，对应的光谱不同，但是积分出来的结果是一样的，即同色异谱(Metamerism)；事实上，还有同谱异色

== 色彩复制 / 匹配
- 计算机中的成色系统成为 Additive Color（加色系统）
  - 所谓加色法，是指 RGB 三原色按不同比例相加而混合出其他色彩的一种方法
  - 而自然界采用减色法，因此许多颜色混合最后会变成黑色而不是计算机中的白色
- CIE sRGB 颜色匹配
  - 利用 RGB 三原色匹配单波长光，SPD 表现为集中在一个波长上（如前所述，有其它 SPD 也能体现出同样的颜色，但选择最简单的）
  - 然后，给定任意波长的*单波长光*（目标测试光），我们可以测出它需要上述 RGB 的匹配（可能为负，意思是加色系统匹配不出来，但可以把目标也加个色），得到*匹配曲线*
    #fig("/public/assets/Courses/CG/img-2024-08-05-18-32-22.png", width: 70%)
  - 然后对于自然界中并非单波长光的任意 SPD，我们可以把它分解成一系列单波长光，然后分别匹配并加权求和，也就是做积分

== 颜色空间
- Standardized RGB(sRGB)：多用于各种成像设备，上面介绍的就是 sRGB。色域有限（大概为 CIE XYZ 的一半）
- CIE XYZ
  - 这种颜色空间的匹配函数，对比之前的sRBG，没有负数段
  - 匹配函数不是实验测出，而是人为定义的
  - 绿色 $y$ 的分布较为对称，用这三条匹配函数组合出来的 $Y$（类比之前的 $G$） 可以一定程度上表示亮度
- HSV
  - 基于感知而非 SPD 的色彩空间，对美工友好
  - H 色调(Hue)：描述颜色的基本属性，如红、绿、蓝等
  - S 饱和度(Saturation)：描述颜色的纯度，越不纯越接近白色
  - V 亮度(Value) or L(Light)：描述颜色的明暗程度
- CIE LAB
  - 也是基于感知的颜色空间
  - L 轴是亮度（白黑），A 轴是红绿，B 轴是黄蓝
  - 轴的两端是互补色，这是通过实验得到的，可以用视觉暂留效果验证
- 减色系统：CMYK
  - 蓝绿色(Cyan)、品红色(Magenta)、黄色(Yellow)、黑色(Key)
  - CMY 本身就能表示 K，加入 K 是经济上的考量（颜料生产成本和需求）
