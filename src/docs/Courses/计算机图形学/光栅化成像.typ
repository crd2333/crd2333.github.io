---
order: 1
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机图形学",
  lang: "zh",
)

- 主要是 Games 101 的笔记，然后加入了部分 ZJU 课上的新东西

#quote()[
  - 首先上来贴几个别人的笔记，#strike[自己少记点]
    + #link("https://www.bilibili.com/read/readlist/rl709699?spm_id_from=333.999.0.0")[B站笔记]
    + #link("https://iewug.github.io/book/GAMES101.html#01-overview")[博客笔记]
    + #link("https://www.zhihu.com/column/c_1249465121615204352")[知乎笔记]
    + #link("https://blog.csdn.net/Motarookie/article/details/121638314")[CSDN笔记]
  - #link("https://sites.cs.ucsb.edu/~lingqi/teaching/games101.html")[Games101 的主页]
]

= Overview 图形学概述
- 课程内容主要包含
  + 光栅化(rasterization)：把三维空间的几何形体显示在屏幕上。实时(30fps)是一个重要的挑战
  + 几何表示(geometry)：如何表示一条光滑的曲线、一个曲面，如何细分以得到更复杂的曲面，形变时如何保持拓扑结构
  + 光线追踪(ray tracing)：慢但是真实。实时是一个重要的挑战。本节课还介绍实时光线追踪
  + 动画/模拟(animation/simulation)：譬如扔一个球到地上，球如何反弹、挤压、变形等
- 这节课不包含：OpenGL, DirectX, Vulcan 等计算机图形学 API、Maya, Blender, Unity, Unreal Engine 等 3D 建模、计算机视觉（一切需要猜测的事情，识别）、硬件编程
- CG 和 CV 的区别
  - 实际上并没有明显的界限
  #fig("/public/assets/Courses/CG/img-2024-07-25-10-25-57.png", width: 80%)

= Math 数学基础
== Linear Algebra 向量与线性代数
- 以右手坐标系讲解，但引擎可能是左手坐标系
- 点乘判断前后；叉乘判断左右和点在凸多边形内外
- Vector
  - 如何表示
  - 相加、点积、叉积

== Transformation 变换
#info()[
  + 二维与三维
  + 模型、视图、投影
]
#let gt = $hat(g) times hat(t)$
- 各种变换矩阵，后统一归为仿射变换（在齐次坐标的概念下）
  - 平移
  - 缩放（反直觉是这是对原点而言的）
  - 旋转（2D 相对于原点，3D 相对于轴）
- 齐次坐标的引入：用矩阵乘向量统一表示平移、旋转、缩放等操作
  - $(x,y,z)$ $->$ $(x,y,z,1)$; $(x,y,z,w)$ $->$ $(x/w,y/w,z/w)$
  - point 和 vector 的不同表示
- 例子
  - 绕任意点旋转
  - 绕任意轴 $(x_1, y_1, z_1) - (x_2, y_2, z_2)$ 旋转 $theta$ 角
    + 把这跟轴平移过原点
    + 旋转使其跟某个轴重合，以 $z$ 轴为例，那么就先后绕 $x$ 轴和 $y$ 轴旋转
    + 绕重合轴($z$ 轴)旋转 $theta$ 角
    + 再做 1, 2 步的逆变换回去
- Viewing (观测) transformation
  - View (视图) / Camera transformation
  - Projection (投影) transformation
    - Orthographic (正交) projection
    - Perspective (透视) projection
- 在现实生活中如何照一张照片？
  + 找个好地方摆 pose（Model 变换）
  + 把相机放个好角度（View 变换）
  + 按快门（Projection 变换）
  - MVP: model, view, projection
- 模型变换(Model)
  - 就是之前的几种仿射变换（如果线性的话）
  $
    M_"model" = mat(a, b, c, t_x; d, e, f, t_y; g, h, i, t_z; 0, 0, 0, 1)\
    "for any axis: "~~~ upright(R) = E cos theta + (1 - cos theta) mat(k_(x) ; k_(y) ; k_(z)) (k_(x), k_(y), k_(z)) + sin theta mat(0, -k_(z), k_(y) ; k_(z), 0, -k_(x) ; -k_(y), k_(z), 0)
  $
- 视图/相机变换(View)
  - 也被叫做 ModelView transformation，因为对模型也要做（保持相对关系不变），我们要把整个世界变换到相机坐标系(View Reference Coordinate System)下
  - 定义相机位姿（SLAM 中的外参）：position, lookat, up
    - 看起来有 $9$ 个参数，实际上是 $6$ 个自由度(6-DOF)，因为后两个方向可以用叉乘合并表示
    - 一般把相机转到原点，看向(*gaze at*) $-z$，up direction(*top*) 为 $y$ 轴
  - 先平移对齐远点，再旋转对齐轴($g$ to $-Z$, $t$ to $Y$, $(g times t)$ to $X$)
  $
    T_"view" = mat(1,0,0,-x_e;0,1,0,-y_e;0,0,1,-z_e;0,0,0,1), ~~~~~~~ R_"view" = mat(x_gt, y_gt, z_gt, 0; x_t, y_t, z_t, 0; x_(-g), y_(-g), z_(-g), 0; 0, 0, 0, 1) =^("typically") mat(1,0,0,0;0,1,0,0;0,0,1,0;0,0,0,1) \
    M_"view" = R_"view" times T_"view"
  $
- 投影变换(Projection)
  - 正交投影
    - 视口是个 $[l,r] [b,t] [f,n]$（注意这里 z 轴是小的 far，大的 near）的长方体
    - 但一般 $f,n$ 通过 aspect ratio(width / height) 和 field of view（FOV，视野角）计算
    $
      tan ("fovY") / 2=t / (|n|), ~~~~~~~~
      "aspect"=r / t
    $
    - 先将立方体的中心平移到原点，再将立方体缩放到$[-1,1]^3$中（也就是一个平移矩阵+一个缩放矩阵），方便之后的计算
    $
      M_"ortho" = mat(2/(r-l), 0, 0, 0; 0, 2/(t-b), 0, 0; 0, 0, 2/(n-f), 0; 0, 0, 0, 1) mat(1, 0, 0, -(r+l)/2; 0, 1, 0, -(t+b)/2; 0, 0, 1, -(n+f)/2; 0, 0, 0, 1) = mat(2/(r-l), 0, 0, -(r+l)/(r-l); 0, 2/(t-b), 0, -(t+b)/(t-b); 0, 0, 2/(n-f), -(n+f)/(n-f); 0, 0, 0, 1)
    $
  - 透视投影（近大远小）
    - PRP: Projection Reference Point = Eye position
    - 如何做？从理解的角度看，首先在远平面上挤(squish)一下，然后做正交投影，也就是分为两步
    - 这里的推导很妙，利用了两个性质：近平面的点不会发生变化；远平面的点 z 的值不会发生变化
    $
      M_"persp" = M_"ortho" times mat(n, 0, 0, 0; 0, n, 0, 0; 0, 0, n+f, -n f; 0, 0, 1, 0)
    $

= Rasterization 光栅化
#info()[
  + 三角形的离散化
  + 深度测试与抗锯齿
]
- 上节课操作后，所有物体都处在$[-1,1]^3$的立方体中，接下来把他画在屏幕上，这一步就叫做光栅化
  - 光栅化算法得名于光栅化显示器(CRT)，生成二维图像的过程是从上到下，从左到右一个像素一个像素来。
- Raster == screen in German, rasterization == drawing onto the screen
- 屏幕空间
  - *视口变换*：（暂时忽略 z 轴）将$[-1,1]^2$变换到屏幕空间的矩阵
    - 一是要考虑屏幕的宽高比，二是要考虑将坐标系原点移到左上角
  $ M_"viewport"=mat(w/2,0,0,w/2; 0,h/2,0,h/2; 0,0,1,0; 0,0,0,1) $
- 显示方式
  + Cathode Ray Tube (CRT)：电子束扫描，优化——隔行扫描
  + Frame Buffer：存储屏幕上每个像素的颜色值
  + Flat Panel Display：LCD（液晶显示器）, OLED
  + LED
  + Electrophoretic Display：如 Kindle

#note(caption: [ CG MVP 矩阵的联系和 CV 内外参矩阵 #h(2em) #text(fill: gray.darken(30%))[纯属个人理解]])[
  - 如果读者对 CV 有所了解的话，MVP 变换跟 CV 里的内外参矩阵有很多相似之处
  #fig("/public/assets/Courses/CV/2024-10-31-10-49-32.png", width: 50%)
  - 我们可以把这个过程归纳一下，一共有 $4$ 个坐标系
    + *{world}* 世界坐标系。可以任意指定 $x_w$ 轴 和 $y_w$ 轴，表示物体或者场景在真实世界中的位置
    + *{camera}* 相机坐标系。相机在 {world} 坐标系里有 position, lookat, up，共 $6$ 个自由度。一般我们会把 {world} $->$ {camera} 的过程定义为：position 转到原点，$-z$ 轴作为 lookat，$y$ 轴作为 up
    + *{image}* 图像坐标系，在图形学里我们也叫做 *NDC*(Normalized Device System) 坐标系，即归一化为一个 $[-1,1]^3$ 的正方体
    + *{pixel}* 像素坐标系，也叫屏幕坐标系，图像的左上角为原点 $O_"pix"$, $u, v$ 轴和图像两边重合
  - 从 CG 的视角：Model 矩阵是在 {world} 内的变换；View 矩阵是从 {world} 到 {camera}；Projection 矩阵是从 {camera} 到 {image}；最后 Viewport 矩阵是从 {image} 到 {pixel}
  - 从 CV 的视角，外参矩阵是从 {world} 到 {camera}；内参矩阵是从 {camera} 直接到 {pixel}，但我们又把内外参矩阵的乘积也就是整个过程又称作*投影矩阵*
  - 所谓*投影*，在 CG 中从 {camera} 到 NDC，已经非常接近 image 了（$z$ 只是用于可见性的深度），因此这一步叫做*投影*；而在 CV 中，*投影*取 {world} 直接投射到图像平面之意
    - 命名上的差异，或许可一窥社区趣味与风向。CG 更关注渲染的真实性，在 NDC 坐标系内还要细化光照、着色、光栅化与光追之类，定义得更细节；CV 更关注计算机对视觉的理解，或者说从 3D 到 2D 的匹配与对应，投影概念定义得更宽泛
]

== 画线算法
- DDA(Digital Differential Analyzer)：数字微分分析器，用来画直线，但受限于浮点数精度
- Breseham's Line Drawing Algorithm：更高效的画线算法，只需要整数运算 #h(1fr)
  - 注意到每次 $x$ 加一，$y$ 的变化不会超过 $1$
  #fig("/public/assets/Courses/CG/2024-09-18-09-19-46.png", width: 80%)
- 画圆算法
  #fig("/public/assets/Courses/CG/2024-09-18-09-22-15.png", width: 80%)
  - 但 Further acceleration 可能会有误差累积的问题
  - Breseham's Circle Drawing Algorithm
    - 把 360° 分成 8 个部分，每次画一个点，然后对称画出另外 7 个点
    - 以 $x=0,y=R$ 开始为例 $d_1 = (x+1)^2 + y^2 - R^2, d_2 = (x+1)^2 + (y-1)^2 - R^2, ~ d = d_1 + d_2$，判断 $d$ 的正负
- 多边形填充
  - 一种方法是判断每个像素在多边形内外（叉积或奇偶检验）
  - 另一种方法是 scan-line method，从上到下、左到右扫描
    - 找到扫描线与多边形的*交点*，然后按照扫描线的方向*排序*，每两个交点之间*填充*
    - 也可以用 Breseham 的思想加速

== Visible Algorithm
- Hidden Surface Removal (Visible Algorithm)，总体而言有两种思路
  - Object-space, Object Precision Algorithm
    - 如 Back-face Culling, Painter's Algorithm
    ```
    for (each object in the world) {
      determine the parts of the object whose view is
      unobstructed by other parts or any other object;
      draw those parts;
    }
    ```
  - Image-space, Image Precision Algorithm
    - 如 z-buffer
    ```
    for (each pixel in the image) {
      determine the object closest to the viewer that is
      intersected by the projector through the pixel;
      draw the pixel;
    }
    ```
- Back-face Culling
  - 通过法向量判断三角形的正反面，只画正面
  - 无法处理所有情况（如被遮挡的正面）
- 画家算法(Painter's Algorithm)：油画家，先画远的，再画近的覆盖掉
  - 物体作为一个整体有时候难以排序（一个三角形，每条边都一半架在另一条边上），一个简单的解决办法是把物体分成小块，引出 Warnock's Area Subdivision
  #algo(title: [Painter's Algorithm])[
    - Start with whole image
    - If one of the easy cases is satisfied,draw what's in front
      - front polygon covers the whole window or
      - there is at most one polygon in the window
    - Otherwise, subdivide region into 4 windows and repeat
    - If region is single pixel,choose surface with smallest depth
  ]
  - Advantages:
    + No over-rendering
    + 可以实现 Anti-aliases. Go deeper to get sub-pixel information
  - Disadvantages:
    + Tests are quite complex and slow
    + 对硬件极不友好
- Z-buffering（深度缓冲）
  - 怎么算深度？前面深度都是基于 vertex，现在要得到三角形内任意点的深度。可以用双线性插值（回忆之前的画线算法，用扫描线先得到两个扫描交点的插值，然后做扫描线上的插值）或者重心坐标得到。这个计算还是比较耗时的，所以在渲染时存一张深度图
  - 暂不考虑相同深度，处理不了透明物体，另外 z-buffering 可能会与 MSAA 结合

#note()[
  - 这里我们可以介绍一个历史，z-buffer 很早就被提出来了，但这种粗暴的方式当时不被人所接受
  - 人们 prefer 一种 closed-form 的形式，比如 Binary Space Partition Tree(BSP Tree)，早年间 2.5D 游戏一般就是这么做的（场景基本都不动）
  - 或者用 K-d Tree
]

== Anti-Aliasing
- 三角形：光栅化的基本单位
  - 原因：三角形是最基本（最少边）的多边形；其他多边形都可以拆分为三角形（建模常用四边形，但到了引擎里拆成三角形）；三角形必定在一个平面内；容易定义三角形的里外；三角形内任意一点可以通过三个定点的线性插值计算得到
- 把三角形转化为像素：简单近似采样
  - 使用内积计算内点外点
  - 使用*包围盒*(Bounding Box)减小计算量，或者 incremental triangle traversal 等
  - 问题：Jaggies（锯齿）/ Aliasing（走样，混叠）
- 需要抗锯齿、抗走样的方法，为此先介绍采样理论：把到达光学元件上的光，产生的信息，离散成了像素，对这些像素采样，形成了照片
- 采样产生的问题(artifacts)：走样、摩尔纹、车轮效应，本质都是信号变化频率高于采样频率
  - 香农采样定理：采样频率 $>=$ 原始频率的两倍，才能很好地恢复
  - 总体而言主要有两种方式 —— Super Sampling（提高采样率）, Area Sampling（干掉高频信号）
- Super Sampling —— MSAA(Multi-Sample Anti-Aliasing)，多重采样抗锯齿
  - 分辨率定死，但增大采样率。把一个像素划分为几个小点，用小点的覆盖率来模拟大点的颜色
  - 增大计算负担，但也有一些优化，比如只在边缘处采样、复用采样点等
  - 另外的一些里程碑式的抗锯齿方案：FXAA, TAA
- Area Sampling —— Blurring(Pre-Filtering) Before Sampling
  - 不能 Sample then filter, or called blurred aliasing
  - 为什么不行？为此介绍*频域、时域*的知识
    - 傅里叶、滤波、卷积
    - 卷积定理：时域的卷积 = 频域的乘积，反过来也成立
    - 采样不同的间隔，会引起频谱不同间隔进行复制，所相交的部分就是走样
    - 所谓反走样就是把高频信息砍掉，砍掉虚线方块以外，再以原始采样频率进行采样，这样就不易交叉了
- Super resolution
  - 把图片从低分辨率放大到高分辨率
  - 本质跟抗锯齿类似，都是采样频率不够的问题
  - 使用 DLSS(Deep Learning Super Sampling) 技术

== \*OpenGL
- OpenGL 是一个跨平台的图形 API，用于渲染 2D 和 3D 图形
- OpenGL Ecosystem
  - OpenGL, WebGL, OpenGL ES, OpenGL NG, Vulkan, DirectX ...
  - #link("https://blog.csdn.net/qq_23034515/article/details/108283747")[WebGL，OpenGL和OpenGL ES三者的关系]
- OpenGL 是做什么的？
  - 定义对象形状、材质属性和照明
    - 从简单的图元、点、线、多边形等构建复杂的形状。
  - 在3D空间中定位物体并解释合成相机
  - 将对象的数学表示转换为像素
    - 光栅化
  - 计算每个物体的颜色
    - 遮光
- Three Stages in OpenGL
  - Define Objects in World Space
  - Set Modeling and Viewing Transformations
  - Render the Scene
  - 跟我们学的顺序类似
- OpenGL Primitives
  - GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_LINE_LOOP, GL_TRIANGLES, GL_QUADS, GL_POLYGON, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_QUAD_STRIP
  - 放到 `glBegin` 里决定如何解释，具体见 PPT
- OpenGL 的命令基本遵守一定语法
  - 所有命令以 `gl` 开头
  - 常量名基本是大写
  - 数据类型以 `GL` 开头
  - 大多数命令以两个字符结尾，用于确定预期参数的数据类型
- OpenGL 是 Event Driven Programming
  - 通过注册回调函数(callbacks)来处理事件
  - 事件包括键盘、鼠标、窗口大小变化等 #h(1fr)
  #fig("/public/assets/Courses/CG/2024-09-22-16-45-55.png", width: 50%)
- Double buffering
  - 隐藏绘制过程，避免闪烁
  - 有时也会用到 Triple buffering
- 后来看了看 OpenGL 的相关教程，感觉现在的实现和这里不太一样（可能过时了）。。。还是以网络教程为准
- WebGL Tutorial / OpenGL ES

= Shading 着色
#info()[
  + 光照和基本着色模型
  + 着色频率、图形管线、纹理映射
  + 插值、高级纹理映射
]

== 光照和基本着色模型
- 什么是 *color*？brains's reaction to a specific visual stimulus. 是观察者体验到的主观感觉。没有观察者，就没有所谓的颜色
  - Depend on
    + Physics of light
    + Interaction of light with physical materials
    + Interpretation of the resulting phenomenon by the human visual system and the human brain
  - 我们将会在 #link("http://crd2333.github.io/note/Courses/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/%E5%85%89%E7%BA%BF%E4%BC%A0%E6%92%AD%E7%90%86%E8%AE%BA")[光线传播理论 —— 光场、颜色与感知] 处更详细讨论
- 计算机图形学领域把 shading 定义为：为物体赋予*材质*的过程（把材质和着色合在一起），但不涉及 shadow(shading is local!)
- 输入：Viewer direction $v$, Surface normal $n$, Light direction $I$(for each of many lights, Surface parameters(color,shininess)
- 一些物理的光学知识
  - 主要分为几何光学 Particle Model 和波动光学 Wave Model，我们主要研究前者
  - 性质
    + 特定频率沿直线传播
    + 光子携带能量 $e=h f$，有波长，行为具有周期性
    + 颜色取决于波长，亮度取决于光子数量
    + 光的波谱
- Lambertian(Diffuse) Term 漫反射
  - 在某一 shading point，有 #h(1fr)
    $ L_d = k_d (I_d \/ r^2) max(0, n dot l) $
  - $k_d$ 是漫反射系数，$I_d$ 是光源强度，$n$ 是法向量，$l$ 是光线方向，$r$ 是光源到点的距离
  - 也可以用半球积分来推导
- Specular Term 高光
  $ L_s = k_s (I_s \/ r^2) max(0, n dot h)^p $
  - 亮度也取决于观察角度，用一个 trick 转化计算：半程向量(half vector) #h(1fr)
    $ h = (v + l) / norm(v + l) $
  - 注意简化掉了光通量项，以及 $p$ 是高光系数，$v$ 是观察方向
- Ambient Term 环境
  - 过于复杂，一般用一个常数来代替
  $ L_a = k_a I_a $
- 综合得到 Blinn-Phong 模型
  #fig("/public/assets/Courses/CG/img-2024-07-26-23-37-29.png",width: 70%)
- 我们将在 #link("http://crd2333.github.io/note/Courses/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/%E5%85%89%E7%BA%BF%E4%BC%A0%E6%92%AD%E7%90%86%E8%AE%BA")[光线传播理论 —— 材质与外观] 处更详细讨论

== 着色频率、图形管线
- 着色频率
  - Flat Shading, Gouraud Shading, Phong Shading，平面、顶点、像素，依次增加计算量
  - 平面着色的法向量很好理解，但顶点和像素就绕一些，需要插值方法得到平滑效果
- Graphics(Real-time Rendering) Pipeline
  - *命令*(Command) $->$ *顶点处理*(Vertex Processing) $->$ *三角形处理*(Triangle Processing) 或者更宽泛地 *图元装配*(Primitives Assembly) $->$ *光栅化*(Rasterization) $->$ *片元处理*(Fragment Processing) $->$ *帧缓冲处理*(Framebuffer Processing) $-$ *显示*(Display)
  #fig("/public/assets/Courses/CG/2024-11-06-09-33-43.png", width: 50%)
  - 需要理解之前讲解的各个操作归属于哪个阶段
    + *顶点处理*：作用是对所有顶点数据进行 MVP 变换，最终得到投影到二维平面的坐标信息（同时为 Zbuffer 保留深度 $z$ 值）。超出观察空间的会被剪裁掉。另外，顶点处理涉及*纹理映射*的步骤。具体而言做了：Vertex transformation, Normal transformation, Texture coordinate generation, Texture coordinate transformation, Lighting(light sources and surface reflection)
    + *三角形处理*或者说*图元装配*
      - 如果是三角形，容易理解，就是将所有的顶点按照原几何信息变成三角面，每个面由 $3$ 个顶点组成；类似地， $1$ vert $->$ point, $2$ verts $->$ line
      - 还做了 Clipping, Perspective projection, Transform to window coordinates (viewport), Determine orientation(CW/CCW), Back-face cull
    + *光栅化*：得到了许许多多个三角形之后，接下来的操作自然就是三角形光栅化了，涉及到抗锯齿、采样方法等。具体而言：Setup(per-triangle), Sampling(triangle =(fragments)), Interpolation(interpolate colors and coordinates)
    + *片元处理*：在进行完三角形的光栅化之后，知道了哪些在三角形内的点可以被显示，通过片元处理阶段的着色问题确定每个像素点或者说片元(Fragement)的颜色[注：片元可能比像素更小，如 MSAA 抗拒齿操作的进一步细分得到的采样点]。该阶段部分工作可能在顶点处理阶段完成，因为我们需要顶点信息对三角形内的点进行属性插值（e.g. 在顶点处理阶段就算出每个顶点的颜色值，如 Gouraud Shading），当然这一阶段也少不了 Z-Buffer 来帮助确定深度。另外，片元处理也涉及*纹理映射*的步骤。具体而言：Combine texture sampler outputs, Per-fragment shading
    + *帧缓冲处理*：Owner, scissor, depth, alpha and stencil tests; Blending or compositing
    + *显示*：Gamma correction 伽玛校正，Analog to digital conversion 模数转换
  - 其中 Vertex Processing, Primitives Assembly, Fragement Processing 是 programmable 的，分别对应 vertex shader, geometry shader, fragment shader
- Shaders
  - 着色器，运行于 GPU 上
  - GLSL 语言实现 Programmable Graphics Pipeline
  - 每个顶点执行一次 $->$ 顶点着色器 vertex shader
  - 每个像素执行一次 $->$ 片元着色器 fragment shader，或者像素着色器 pixel shader
  - Geometry shader 一般是不怎么改的

== 纹理
- 纹理映射
  - 3D 世界的物体的表面是 2D 的，将其展开就是一张图，纹理映射就是将这张图映射到物体上
  - 如何知道 2D 的纹理在3D的物体上的位置？通过纹理坐标。有手动（美工）和自动（参数化）的方法，这里我们就认为已经知道 3D 物体的每一个三角形顶点对应的纹理 $u v(in [0,1])$ 坐标
  - 四方连续纹理：tiled texture，保证纹理拼接时的连续性
- 三角形内插值: 重心坐标(Barycentric Coordinates)
  - 重心坐标：$(x,y)=al A + beta B + ga C ~~~ (al+beta+ga=1)$，通过 $al, beta, ga >= 0$ 可以任意表示三角形内的点，且与三个顶点所在坐标系无关。这个重心坐标跟三角形重心不是一回事，三角形重心的重心坐标为 $(1/3, 1/3, 1/3)$
  - 对什么运用插值：插值的属性：纹理坐标，颜色，法向量等等，统一记为 $V$，插值公式为 $V = al V_A + beta V_B + ga V_C$
  - 重心坐标没有投影不变性，所以要在三维中插值后再投影（特殊的如深度，要逆变换回3D插值后再变换回来）
- 纹理过大过小
  - Texture Magnification：如果纹理过小
    - 比如一个4K分辨率的墙贴上一个$256*256$的纹理，那么就会出现 uv 坐标非整数的情况（a pixel on texture，简记为 *texel*，纹理元素、纹素，不可以取非整数值）
    - 使用 nearest（四舍五入）, bilinear（双线性插值, 4）, bicubic（双三次插值, 16）
  - Texture Minification：如果纹理过大
    - 问题：走样、摩尔纹、锯齿等（且越远越严重）。原因在于屏幕上 pixel 越远就对应越大面积的 texel（footpoint 现象）；或者说，采样的频率跟不上信号的频率
    - 一个很自然的想法是类似之前抗走样所采用的超采样方法，但这里提出另一种 mipmap(image pyramid) 方法：Allowing (fast, approx, square) range queries
      - 离线预处理（在渲染前生成）每个 footprint 对应纹理区域（不同 level）里的均值
      - 开销：$1+1/4+dots approx 4/3$，仅仅是额外的 33% 开销
      - 计算 level：用 pixel 的相邻点投影到 texel 估算 footpoint 大小（近似为正方形）再取对数；然后因为 level 是不连续的，通过三线性插值（两个层内双线性再一个层之间线性）得到连续性，避免突兀
      - 优化：真实情况屏幕空间上的区域对应的 footprint 并不一定是正方形，导致 overblur，为此提出各向异性滤波(*Anisotropic Filtering*)，开销为 $3$ 倍。进一步，依旧无法解决斜着的区域，用 EWA Filtering
- Environment Map 环境光映射
  - 前面说的纹理可以扩展到其它概念（数据，而非仅仅是图像），比如将某一点四周的环境光（光源、反射 or anything else）也存储在一个贴图上
  - 这样的做法是一种假设：环境光与物体的位置无关，只与观察方向有关（即环境光不随距离衰减）。然后各个方向的光源可以用一个球体进行存储，即任意一个 3D 方向，都标志着一个 texel
  - 适用于什么场景呢？比如说一个大屋子里面的小茶壶，它相对整个屋子是很小的，如果假设环境光没有衰减，那它反射的光就只和方向有关
  - 但是，类比地球仪，展开后把球面信息转换到平面上，从而得到环境 texture，同时存在拉伸和扭曲问题
  - 解决办法：Cube Map（天空盒），将球面一一映射到立方体的六个面上，这样展开后得到的纹理面就是均匀的
- Bump Mapping 凹凸贴图
  - 在不改变物体本身几何形状的情况下，通过纹理来模拟物体表面的凹凸不平
- Displacement Mapping 位移贴图
  - 与之相对，位移贴图的输入同样是一张纹理图，但它的输出真的对物体的几何形状进行了改变，从而对物体边缘和物体阴影有更好的效果
  - 这要求建模的三角形足够细到比纹理的采样频率还高。但又引申出一个问题，为什么不直接在建模上体现其位移？因为这样便于修改、特效；另外，DirectX 中的动态曲面细分：开始先用粗糙的三角形，应用 texture 的过程中检测是否需要把三角形拆分的更细
- 三维纹理
  - 前面说的纹理局限于 2D，但可以扩展到 3D
  - 三维纹理，定义空间中任意一点的纹理：并没有真正生成纹理的图，而是定义一个三维空间的噪声函数经过各种处理，变成需要的样子（如地形生成）
- 阴影纹理
  - 阴影可以预先计算好，直接写在 texture 里，然后把着色结果乘以阴影纹理的值
- 3D Texture 和体渲染
- 图形渲染管线
- （讲完 Geometry 后回来），阴影映射(Shadow Mapping)
  - 图像空间中计算，生成阴影时不需要场景的几何信息；但会产生走样现象
  - Key idea：不在阴影里则能被光源和摄像机同时看道；在阴影里则能被相机看到，但不能被光源看到
  - 步骤
    + Step1：在光源处做光栅化，得到深度图（shadow map，二维数组，每个像素存放深度）；
    + Step2：从摄像机做光栅化，得到光栅图像；
    + Step3：把摄像机得到图像中的每个像素所对应的世界空间中物体的点投影回光源处，得到该点的深度值，将此数值跟该点到光源的距离做比较（注意用的是世界空间中的坐标，即透视投影之前的）
  - 浮点数精度问题，shadow map 和光栅化的分辨率问题（采样频率）
  - 硬阴影、软阴影（后者的必要条件是光源有一定大小）
