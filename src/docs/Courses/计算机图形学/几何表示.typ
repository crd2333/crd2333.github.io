---
order: 2
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

#counter(heading).update(4)

= Geometry 几何
#info()[
  + 基本表示方法（距离函数 SDF、点云）
  + 曲线与曲面（贝塞尔曲线、曲面细分、曲面简化）
  + 网格处理、阴影图
]
- 主要分为两类：隐式几何、显式几何，显式几何又可以把参数化表示单独拿出来
- 可以部分参考我的 #link("http://crd2333.github.io/note/CV/Representations")[三维重建笔记]（从 CV 的角度）

== 隐式几何
- 隐式几何：不告诉点在哪，而描述点满足的关系，generally $f(x,y,z)=0$
  - 好处：很容易判断给定点在不在面上；坏处：不容易看出表示的是什么，不容易找到其上的所有点
  - Constructive Solid Geometry(CSG)：可以对各种不同的几何做布尔运算，如并、交、差
  - Signed Distance Function(SDF)：符号距离函数：描述一个点到物体表面的最短距离，外表面为正，内表面为负，SDF 为 $0$ 的点组成物体的表面
    - 对两个“规则”形状物体的 SDF 进行线性函数混合(blend)，可以得到一个新的 SDF，令其为 $0$ 反解出的物体形状将变得很“新奇”
  - 水平集(Level Set)：与 SDF 很像，也是找出函数值为 $0$ 的地方作为曲线，但不像 SDF 会空间中的每一个点有一种严格的数学定义，而是对空间用一个个格子去近似一个函数。通过 Level Set 可以反解 SDF 为 $0$ 的点，从而确定物体表面
  - L-system: 用 CFG 的方法去做分形几何
    - 然后可以把它转成别的表达，从而生成复杂图形比如说树
    - 但是从一个 target shape 推导出目标 L-system 很困难，有一个叫 Metropolis Procedural Modeling 的论文去做这件事
    - 进一步，也可以直接从 shape 的层面得到 shape grammar
  - Subdivision Curves / Surfaces
  - Sweeping

== 参数几何
- 参数几何（在 GAMES101 里被归类为显示，这里我们可以把它单独拿出来看）
  - 如一般参数方程、贝塞尔曲线、样条线、贝塞尔曲面、样条曲面等

=== 曲线
- 一般参数方程
  $ bC = bC(u)= [x(u),y(u),z(u)] $
  - arc length 弧长
  - 插值(Interpolation)
    - 最近邻插值（最暴力的，甚至都不连续）
    - 线性插值（连续，但一阶导不连续）
    - 平滑插值（使用多项式，如 Cubic Hermite Interpolation）
- Hermite Curves
  - 从两个点及其导数插值出一条曲线
  $ P(t) = a t^3 + b t^2 + c t + d $
  - 四个约束，对应于 $P(0),P(1),P'(0),P'(1)$，构成线性方程组 $bh = A [a,b,c,d]$，硬编码解出 $A^(-1)$ 可以从已知的 $bh$ 解出 $[a,b,c,d]$
  - 更进一步，可以使用 basis functions 的思想，不表示为标准 $[a,b,c,d]$ 形式，用 $4$ 个基 $bH_1 (t),bH_2 (t),bH_3 (t),bH_4 (t)$ 来表示
    $ P(t) = sumi^3 h_i bH(t) $
  - 指定 $4$ 个基函数如下
    #fig("/public/assets/Courses/CG/2024-11-13-08-44-14.png",width:60%)
  - 这个 $bH_1 (t)$ 比较有意思，因为比较平滑，可以借以构建伪动画
- Catmull-Rom Curves
  - Hermite 曲线的优化，用 $4$ 个点插值出一条曲线，用点 $0,2$ 连线模拟点 $1$ 的导数，用点 $1,3$ 连线模拟点 $2$ 的导数
  #fig("/public/assets/Courses/CG/2024-11-13-15-21-18.png",width:60%)
- 贝塞尔曲线
  - 用三个控制点确定一条二次贝塞尔曲线（de Casteljau 算法），三次、四次等也是一样的思路（如果是尺规作图或者可视化可以这么做）
  - 本质上是用伯恩斯坦 (Bernstein) 多项式定义出 $n$ 个控制点（作为基）对曲线上点的权重
    $
    C(t) = sumi^n B_(i,n) (t) P_i ~~, t in [0,1] \
    B_(i,n) (t) = C_n^i t^i (1-t)^(n-i)
    $
    #fig("/public/assets/Courses/CG/2024-11-13-15-21-38.png",width:60%)
  - 贝塞尔曲线好用的性质
    + 首/尾两个控制点一定是起点/终点
    + 对称性：由 ${P_0,P_1,dots,P_(n-1)}$ 确定的曲线和 ${P_(n-1),dots,P_1,P_0}$ 确定的曲线是一样的
    + 仿射不变性：对控制点做仿射变换，再重新画曲线，跟原来的一样，不用一直记录曲线上的每个点
    + 凸包性质：画出的贝塞尔曲线一定在控制点围成的线之内
    + Variation Diminishing;: 曲线不会突然变化方向
  - 贝塞尔曲线不好的性质
    + global: 一个控制点的变化会影响整条曲线（牵一发而动全身）
  - piecewise Bezier Curve：每 $4$ 个顶点为一段，定义多段贝塞尔曲线，每段的终点是下一段的起点
- Rational Bezier Curve
  - 有理贝塞尔曲线，对贝塞尔曲线的一种扩展
- Splines 样条线：一条由一系列控制点控制的曲线
  - B-splines 基样条：对贝塞尔曲线的一种扩展，比贝塞尔曲线好的一点是：局部性，可以更局部的控制变化
  - 利用阶数（跟控制点个数解耦）在 平滑性 v.s. 局部性 中做 trade-off
  - NURBS(Non-Uniform Rational B-Spline)：比 B-splines 更复杂的一种曲线
- 总结：两种视角
  $ overbrace(P(t),"parametric curves") = sumin underbrace(P_i,"control points") overbrace(B_(i,n),"basis functions"), t in [t0,t1) $
  + 第一种：对基函数的线性组合，控制点作为系数
  + 第二种：对控制点的加权平均，基函数在对应 $t$ 算出的值作为权重

=== 曲面
- 上述表述可以自然推广到曲面
  $ S(u,v) = sum_(i=0)^n sum_(j=0)^m P_ij B_(i,n) (u) B_(j,m) (v) 0 =< u,v =< 1 $
- 贝塞尔曲面：将贝塞尔曲线扩展到曲面
  - 用 $4 times 4$ 个控制点得到三次贝塞尔曲面。每四个控制点绘制出一条贝塞尔曲线，这 $4$ 条曲线上每一时刻的点又绘制出一条贝塞尔曲线，得到一个贝塞尔曲面
  #fig("/public/assets/Courses/CG/2024-11-20-08-12-39.png",width:60%)
  - 怎么求曲面上的法向量？用曲面的参数方程求出 $u,v$ 方向的切线，然后叉乘得到法向量
- 跟曲线一样，可以自然推广到 B-spline Surface 和 NURBS Surface

== 显式几何
- 显式几何：所有曲面的点被直接给出，或者可以通过参数映射关系直接得到
  - 好处：容易直接看出表示是什么；坏处：很难判断内/外
  - 点云、多边形模型等
- 点云，很基础，不多说，但其实不那么常见（除了扫描出来的那种）

=== 多边形模型
- 用得最广泛的方法，一般用三角形或者四边形来建模
- 如何表示？
  + Vertex-Vertex list
  + Face-Vertex list
- Normal on a mesh
  - 怎么求 face 上的法向量？用三角形的两个边向量叉乘
  - 怎么求 vertex 上的法向量？用相邻三角形的法向量的平均
- 在代码中怎么存储一个三角形组成的模型？用 wavefront object file(.obj)
  - v 顶点；vt 纹理坐标；vn 法向量；f 顶点索引（哪三个顶点、纹理坐标、法线）

== 几何操作
几何操作：Mesh operations(mesh subdivision, mesh simplification, mesh regularization)，下面依次展开
- 曲面细分
  - Loop 细分：分两步，先增加三角形个数，后调整位置
    - 新顶点：$3/8 * (A+B) + 1/8 * (C+D)$
    - 旧顶点：$(1-n*u)*"priginal_position"+u*"neighbor_position_sum"$，其中 $n$ 为顶点的度，$u=3/16 (n=3) "or" 3/(8n)$（$n$ 越大越相信自己）
  - Catmull-Clark 细分
    - 非四边形面、奇异点
    - 一次细分后：每个非四边形面引入一个奇异点；非四边形面全部消失
    - 顶点更新规则：新的边上的点、新的面内的点、旧的点
- 曲面简化
  - 多细节层次(LOD)：如果说 MipMap 是纹理上的层次结构——根据不同距离(覆盖像素区域的大小)选择不同层的纹理；那么 LOD 就是几何的层次结构——根据不同距离(覆盖像素区域的大小)选择不同的模型面数
  - 边坍缩：把某一条边坍缩成一个点，要求这个点距离原先相邻面的距离平方和最小（优化问题）
    - 贪心算法，小顶堆
