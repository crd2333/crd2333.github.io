#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机图形学",
  lang: "zh",
)

- 主要是 Games 101 的笔记，然后如果 ZJU 课上有新东西的话可以加进来

#quote()[
  - 首先上来贴几个别人的笔记，#strike[自己少记点]
    + #link("https://www.bilibili.com/read/readlist/rl709699?spm_id_from=333.999.0.0")[B站笔记]
    + #link("https://iewug.github.io/book/GAMES101.html#01-overview")[博客笔记]
    + #link("https://www.zhihu.com/column/c_1249465121615204352")[知乎笔记]
    + #link("https://blog.csdn.net/Motarookie/article/details/121638314")[CSDN笔记]
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
  #fig("/public/assets/Courses/CG/img-2024-07-25-10-25-57.png")

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
  #fig("/public/assets/temp/2024-10-31-10-49-32.png", width: 50%)
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
- Breseham's Line Drawing Algorithm：更高效的画线算法，只需要整数运算
  - 注意到每次 $x$ 加一，$y$ 的变化不会超过 $1$
  #fig("/public/assets/Courses/CG/2024-09-18-09-19-46.png")
- 画圆算法
  #fig("/public/assets/Courses/CG/2024-09-18-09-22-15.png")
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
  #algo[
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
  - 事件包括键盘、鼠标、窗口大小变化等
  #fig("/public/assets/Courses/CG/2024-09-22-16-45-55.png", width: 70%)
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
- 计算机图形学领域定义为：为物体赋予*材质*的过程（把材质和着色合在一起），但不涉及 shadow(shading is local!)
- 输入：Viewer direction $v$, Surface normal $n$, Light direction $I$(for each of many lights, Surface parameters(color,shininess)
- 一些物理的光学知识
- Lambertian(Diffuse) Term（漫反射）
  - 在某一 shading point，有 $L_d = k_d I_d \/ r^2 max(0, n dot l)$
  - $k_d$ 是漫反射系数，$I_d$ 是光源强度，$n$ 是法向量，$l$ 是光线方向，$r$ 是光源到点的距离
  - 也可以用半球积分来推导
- Specular Term（高光）
  - 亮度也取决于观察角度，用一个 trick 转化计算：半程向量(half vector) $h = (v + l) \/ ||v + l||$
  - $L_s = k_s I_s \/ r^2 max(0, n dot h)^p$
  - 注意简化掉了光通量项，以及 $p$ 是高光系数，$v$ 是观察方向
- Ambient Term（环境）
  - 过于复杂，一般用一个常数来代替
  - $L_a = k_a I_a$
- 综合得到 Blinn-Phong 模型
  #fig("/public/assets/Courses/CG/img-2024-07-26-23-37-29.png")
- 着色频率
  - Flat Shading, Gouraud Shading, Phong Shading，平面、顶点、像素，依次增加计算量
  - 平面着色的法向量很好理解，但顶点和像素就绕一些，需要插值方法得到平滑效果
- Graphics(Real-time Rendering) Pipeline
  - 顶点处理(Vertex Processing) $->$ 三角形处理(Triangle Processing) $->$ 光栅化(Rasterization) $->$ 片元处理(Fragment Processing) $->$ 帧缓冲处理(Framebuffer Processing)
  - 需要理解之前讲解的各个操作归属于哪个阶段
    + 顶点处理：作用是对所有顶点数据进行MVP变换，最终得到投影到二维平面的坐标信息（同时为Zbuffer保留深度z值）。超出观察空间的会被剪裁掉
    + 三角形处理：容易理解，就是将所有的顶点按照原几何信息变成三角面，每个面由3个顶点组成
    + 光栅化：得到了许许多多个三角形之后，接下来的操作自然就是三角形光栅化了，涉及到抗锯齿、采样方法等
    + 片元处理：在进行完三角形的光栅化之后，知道了哪些在三角形内的点可以被显示，通过片元处理阶段的着色问题确定每个像素点或者说片元(Fragement)的颜色[注：片元可能比像素更小，如 MSAA 抗拒齿操作的进一步细分得到的采样点]。该阶段部分工作可能在顶点处理阶段完成，因为我们需要顶点信息对三角形内的点进行属性插值（e.g. 在顶点处理阶段就算出每个顶点的颜色值，如 Gouraud Shading），当然这一阶段也少不了Z-Buffer来帮助确定深度。另外，片元处理涉及纹理映射的步骤
- Shaders
  - 着色器，运行于 GPU 上
  - GLSL 语言
  - 每个顶点执行一次 $->$ 顶点着色器 vertex shader
  - 每个像素执行一次 $->$ 片元着色器 fragment shader，或者像素着色器 pixel shader
- 纹理映射
  - 3D世界的物体的表面是2D的，将其展开就是一张图，纹理映射就是将这张图映射到物体上
  - 如何知道2D的纹理在3D的物体上的位置？通过纹理坐标。有手动（美工）和自动（参数化）的方法，这里我们就认为已经知道3D物体的每一个三角形顶点对应的纹理 $u v(in [0,1])$ 坐标
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
- （讲完 Geometry 后回来），阴影映射(Shadow Mapping)
  - 图像空间中计算，生成阴影时不需要场景的几何信息；但会产生走样现象
  - Key idea：不在阴影里则能被光源和摄像机同时看道；在阴影里则能被相机看到，但不能被光源看到
  - Step1：在光源处做光栅化，得到深度图（shadow map，二维数组，每个像素存放深度）；Step2：从摄像机做光栅化，得到光栅图像；Step3：把摄像机得到图像中的每个像素所对应的世界空间中物体的点投影回光源处，得到该点的深度值，将此数值跟该 点到光源的距离做比较（注意用的是世界空间中的坐标，即透视投影之前的）
  - 浮点数精度问题，shadow map 和光栅化的分辨率问题（采样频率）
  - 硬阴影、软阴影（后者的必要条件是光源有一定大小）

= Geometry 几何
#info()[
  + 基本表示方法（距离函数SDF、点云）
  + 曲线与曲面（贝塞尔曲线、曲面细分、曲面简化）
  + 网格处理、阴影图
]
- 主要分为两类：隐式几何、显式几何
- 隐式几何：不告诉点在哪，而描述点满足的关系，generally $f(x,y,z)=0$
  - 好处：很容易判断给定点在不在面上；坏处：不容易看出表示的是什么
  - Constructive Solid Geometry(CSG)：可以对各种不同的几何做布尔运算，如并、交、差
  - Signed Distance Function(SDF)：符号距离函数：描述一个点到物体表面的最短距离，外表面为正，内表面为负，SDF 为 $0$ 的点组成物体的表面
    - 对两个“规则”形状物体的 SDF 进行线性函数混合(blend)，可以得到一个新的 SDF，令其为 $0$ 反解出的物体形状将变得很“新奇”
  - 水平集(Level Set)：与 SDF 很像，也是找出函数值为 $0$ 的地方作为曲线，但不像 SDF 会空间中的每一个点有一种严格的数学定义，而是对空间用一个个格子去近似一个函数。通过 Level Set 可以反解 SDF 为 $0$ 的点，从而确定物体表面
- 显式几何：所有曲面的点被直接给出，或者可以通过参数映射关系直接得到
  - 好处：容易直接看出表示是什么；坏处：很难判断内/外
  - 以下均为显式表示法
- 点云，很基础，不多说，但其实不那么常见（除了扫描出来的那种）
- 多边形模型
  - 用得最广泛的方法，一般用三角形或者四边形来建模
  - 在代码中怎么表示一个三角形组成的模型？用 wavefront object file(.obj)
  - v 顶点；vt 纹理坐标；vn 法向量；f 顶点索引（哪三个顶点、纹理坐标、法线）
- 贝塞尔曲线
  - 用三个控制点确定一条二次贝塞尔曲线，de Casteljau 算法。三次、四次等也是一样的思路。用伯恩斯坦多项式
  - 贝塞尔曲线好用的性质
    + 首/尾两个控制点一定是起点/终点
    + 对控制点做仿射变换，再重新画曲线，跟原来的一样，不用一直记录曲线上的每个点
    + 凸包性质：画出的贝塞尔曲线一定在控制点围成的线之内
  - piecewise Bezier Curve：每 $4$ 个顶点为一段，定义多段贝塞尔曲线，每段的终点是下一段的起点
- Splines 样条线：一条由一系列控制点控制的曲线
  - B-splines 基样条：对贝塞尔曲线的一种扩展，比贝塞尔曲线好的一点是：局部性，可以更局部的控制变化
  - NURBS：比B样条更复杂的一种曲线，了解即可
-  贝塞尔曲面：将贝塞尔曲线扩展到曲面
  - 用 $4 times 4$ 个控制点得到三次贝塞尔曲面。每四个控制点绘制出一条贝塞尔曲线，这 $4$ 条曲线上每一时刻的点又绘制出一条贝塞尔曲线，得到一个贝塞尔曲面
- 几何操作：Mesh operations(mesh subdivision, mesh simplification, mesh regularization)，下面依次展开
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

= Ray Tracing 光线追踪
#info()[
  + 基本原理
  + 加速结构
  + 辐射度量学、渲染方程与全局光照
  + 蒙特卡洛积分与路径追踪
]
== 光线追踪原理
- 光栅化：已知三角形在屏幕上的二维坐标，找出哪些像素被三角形覆盖（物体找像素点）；光线追踪：从相机出发，对每个像素发射射线去探测物体，判断这个像素被谁覆盖。（像素点找物体）
- 为什么要有光线追踪，光栅化不能很好的模拟全局光照效果：难以考虑 glossy reflection（反射性较强的物体）, indirect illuminaiton（间接光照）；不好支持 soft shadow；是一种近似的效果，不准确、不真实
- 首先定义图形学中的光线：光沿直线传播；光线之间不会相互影响、碰撞；光路可逆(reciprocity)，从光源照射到物体反射进入人眼，反着来变成眼睛发射光线照射物体
- Recursive (Whitted-Style) Ray Tracing
  - 两个假设前提：人眼是一个点；场景中的物体，光线打到后都会进行完美的反射/折射；
  - 每发生一次折射或者反射（弹射点）都计算一次着色，前提是该点不在阴影内，如此递归计算
    + 从视点从成像平面发出光线，检测是否与物体碰撞
    + 碰撞后生成折射和反射部分
    + 递归计算生成的光线
    + 所有弹射点都与光源计算一次着色，前提是该弹射点能被光源看见
    + 将所有着色通过某种加权叠加起来，得到最终成像平面上的像素的颜色
  - 为了后续说明方便，课程定义了一些概念：
    + primary ray：从视角出发第一次打到物体的光线
    + secondary rays：弹射之后的光线
    + shadow rays：判断可见性的光线
  - 那么问题的重点就成了求交点。接下来对其中的技术细节进行讲解
- Ray Equation：$r(t)=o+t d ~~~ 0 =< t < infty$，光线由点光源和方向定义
- Ray Intersection With Implicit Surface 光线与隐式表面求交
  - General implicit surface: $p: f(p)=0$
  - Substitute ray equation: $f(o+t d)=0$
  - Solve for real,positive roots
- Ray Intersection With Explicit Triangle 光线与显式表面(三角形)求交
  - 通过光线和三角形求交可以实现：渲染（判断可见性，计算阴影、光照）；几何（判断点是否在物体内，通过光源到点的线段与物体交点数量的奇偶性）
  - 求交方法一：遍历物体每个三角形，判断与光线是否相交
    + 光线-平面求交
    + 计算交点是否在三角形内
  - 求交方法二：Möller-Trumbore射线-三角形求交算法
    - 直接结合重心坐标计算
    #fig("/public/assets/Courses/CG/img-2024-07-30-14-36-34.png")
== Accelerating Ray-Surface Intersection
- 空间划分与包围盒 Bounding Volumes
  - 常用 Axis-Aligned-Bounding-Box(AABB) 轴对齐包围盒
  - 算 $t_"enter"$ 和 $t_"exit"$，光线与 box 有交点的判定条件：$t_"enter" < t_"exit" && t_"exit" >= 0$
  - AABB 盒的好处就在于光线与盒子的交点很容易计算，于是我们将复杂的三角形与光线求交问题部分转化为了简单的盒子与光线求交问题：首先做预处理对空间做划分（均匀或非均匀），然后剔除不包含任何三角形的盒子，计算一条光线与哪些盒子有交点，在这些盒子中再计算光线与三角形的交点
  - 非均匀空间划分
    + Oct-Tree：类似八叉树结构，注意下面省略了一些格子的后续划分，格子内没有物体或物体足够少时，停止继续划分
    + BSP-Tree：空间二分的方法，每次选一个方向砍一刀，不是横平竖直（并非 AABB），所以不好求交，维度越高越难算
    + *KD-Tree*：每次划分只沿着某个轴砍一刀，XYZ 交替砍，不一定砍正中间，每次分出两块，类似二叉树结构
    - KD-tree 的缺陷：不好计算三角形与包围盒的相交性（不好初始化）；一个三角形可能属于多个包围盒导致冗余计算
- 对象划分 Bounding Volume Hierarchy(BVH)
  - 逐步对物体进行分区：所有物体分成两组，对两组物体再求一个包围盒（xyz 的最值作为边界）。这样每个包围盒可能有相交（无伤大雅）但三角形不会有重复，并且求包围盒的办法省去了三角形与包围盒求交的麻烦
  - 分组方法：启发式——总是选择最长的轴，或选择处在中间（中位数意义上）的三角形
  - 课上讲的 BVH 是宏观上的概念，没有细讲其实现，可以看 #link("https://www.cnblogs.com/lookof/p/3546320.html")[这篇博客]

== 辐射度量学(Basic radiometry)、渲染方程与全局光照
- Motivation：Whitted styled 光线追踪、Blinn-phong 着色计算不够真实
- 辐射度量学：在物理上准确定义光照的方法，但依然在几何光学中的描述，不涉及光的波动性、互相干扰等
- 几个概念：Radiant Energy 辐射能 $Q$, Radiant Flux(Power) 辐射通量$Phi$, Radiant Intensity 辐射强度 $I$, Irradiance 辐照度 $E$, Radiance 辐亮度 $L$
  + Radiance Energy：$Q[J = "Joule"]$，基本不咋用
  + Radiant Flux：$Phi = (dif Q)/(dif t) [W = "Watt"][l m="lumen"]$，有时也把这个误称为能量
  + 后面三个细讲
- Radiant Intensity: Light Emitted from a Source
  - $I(omega) = (dif Phi)/(dif omega) [W/(s r)][(l m)/(s r) = c d = "candela"]$
  - solid angle 立体角
- Irradiance: Light Incident on a Surface
  - $E = (dif Phi)/(dif A cos theta) [W/m^2]$，其中 $A$ 是投影后的有效面积
  - 注意区分 Intensity 和 Irradiance，对一个向外锥形，前者不变而后者随距离减小
- Radiance: Light Reflected from a Surface
  - $L = (dif^2 Phi(p, omega))/(dif A cos theta dif omega) [W/(s r ~ m^2)][(c d)/(m^2)=(l m)/(s r ~ m^2)=n i t]$，$theta$ 是入射（或出射）光线与法向量的夹角
  - Radiance 和 Irradiance, Intensity 的区别在于是否有方向性
  - 把 Irradiance 和 Intensity 联系起来，Irradiance per solid angle 或 Intensity per projected unit area
- $E(p)=int_(H^2) L_i(p, omega) cos theta dif omega$
- 双向反射分布函数(Bidirectional Reflectance Distribution Function, BRDF)：描述了入射($omega_i$)光线经过某个表面反射后在各个可能的出射方向($omega_r$)上能量分布（反射率）——$f_r(omega_i -> omega_r)=(dif L_r (omega_r))/(dif E_i (omega_i)) = (dif L_r (omega_r)) / (L_i (omega_i) cos theta_i dif omega_i) [1/(s r)]$
- 反射方程：$ L_r(p, omega_r)=int_(H^2) f_r (p, omega_i -> omega_r) L_i (p, omega_i) cos theta_i dif omega_i $
  - 注意，入射光不止来自光源，也可能是其他物体反射的光。递归思想，反射出去的光 $L_r$ 也可被当做其他物体的入射光 $E_i$
- 推广为渲染方程（绘制方程）：$ L_o (p, omega_o)=L_e (p, omega_o) + int_(Omega^+) f_r (p, omega_i, omega_o) L_i (p, omega_i) (n dot omega_i) dif omega_i $
- 把式子通过“算子”概念简写为 $L=E+K L$，然后移项泰勒展开得到 $L=E+K E+K^2 E+...$，如下图，光栅化一般只考虑前两项，这也是为什么我们需要光线追踪
  #fig("/public/assets/Courses/CG/img-2024-07-31-23-36-46.png")
  - 全局光照 = 直接光照(Direct Light) + 间接光照(Indirect Light)

== 蒙特卡洛路径追踪(Path Tracing)
- 概率论基础
- 回忆 Whitted-styled 光线追踪：摄像机发射光线，打到不透明物体，则认为是漫反射，直接连到光源做阴影判断、着色计算；打到透明物体，发生折射、反射。总之光线只有三种行为——镜面反射、折射、漫反射
  + 难以处理毛面光滑材质？
  + 忽略了漫反射物体之间的反射影响
- 采样蒙特卡洛方法解渲染方程：直接光照；全局光照，采用递归
  #fig("/public/assets/Courses/CG/img-2024-08-01-22-25-38.png")
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
- 自然界中的材质
== 计算机图形学中的材质
- 材质 == BRDF（Bidirectional Reflectance Distribution Function，双向反射分布函数）
- 漫反射材质(Diffuse)的 BRDF
  - Light is equally reflected in each output direction
  - 如果再假设入射光也是均匀的，并且有能量守恒定律 $L_o = L_i$，那么：
    #fig("/public/assets/Courses/CG/img-2024-08-04-11-39-26.png")
    - 定义反射率 $rho$ 来表征一定的能量损失，还可以对 RGB 分别定义 $rho$
- 抛光/毛面金属(Glossy)材质的 BRDF
  - 这种材质散射规律是在镜面反射方向附近，一小块区域进行均匀的散射
  - 代码实现上，算出*镜面*反射方向$(x,y,z)$，就以$(x,y,z)$为球心（或圆心），内部随机生成点，以反射点到这个点作为真的光线反射方向。在较高 SPP(samples per pixel)下，就能均匀的覆盖镜面反射方向附近的一块小区域
- 完全镜面反射+折射材质(ideal reflective/refractive)的 BRDF
  - （完全）镜面反射(reflect)
    - 方向描述
      + 直接计算：$omega_o = - omega_i + 2 (omega_i dot n) n$
      + 用天顶角 $phi$ 和方位角 $theta$ 描述：$phi_o = (phi_i+pi) mod 2 pi, ~~ theta_o = theta_i$
      + 还有之前讲过的半程向量描述（简化计算）
    - 镜面反射的 BRDF 不太好写，因为它是一个 delta 函数，只有在某个方向上有值，其它方向上都是 $0$(?)
  - 折射(refract)
    - Snell's Law（斯涅耳定律，折射定律）：$n_1 sin theta_1 = n_2 sin theta_2$
    - $cos theta_t = sqrt(1 - (n_1/n_2)^2 (1 - (cos theta_i)^2))$，有全反射现象（光密介质$->$光疏介质）
    - 折射无法用严格意义上的 BRDF 描述，而应该用 BTDF(T: transmission)，可以把二者统一看作 BSDF(S: scattering) = BRDF + BTDF。不过，通常情况下，当我们说 BRDF 时，其实就指的是 BSDF
    - 反射与折射能量的分配与入射角度物体属性有关，用 Fresnel Equation 描述
- 菲涅尔项(Fresnel Term)
  - 精确计算菲涅尔项（复杂，没有必要），只要知道这玩意儿跟 出/入射角度、介质反射率 $eta$ 有关j就行
  - 近似计算：Schlick’s approximation（性价比更高）：$R(th)=R_0+(1-R_0)(1-cos th)^5$，其中 $R_0=((n_1-n_2)/(n_1+n_2))^2$

== 微表面材质(Microfacet Material)
- 微表面模型：微观上——凹凸不平且每个微元都认为只发生镜面反射(bumpy & specular)；宏观上——平坦且略有粗糙(flat & rough)。总之，从近处看能看到不同的几何细节，拉远后细节消失
- 用法线分布描述表面粗糙程度
  #fig("/public/assets/Courses/CG/img-2024-08-04-12-48-55.png")
- 微表面的 BRDF
  #fig("/public/assets/Courses/CG/img-2024-08-04-12-52-57.png")
  - 其中 $G$ 项比较难理解。 当入射光以非常平(Grazing Angle 掠射角度)的射向表面时，有些凸起的微表面就会遮挡住后面的微表面。$G$项 其实对这种情况做了修正
- 微表面模型效果特别好，是 sota，现在特别火的 PBR(physically Based Rendering)一定会使用微表面模型

== 各向同性(Isotropic)和各向异性(Anisotropic)材质
- 各向同性——各个方向法线分布相似；各项异性——各个方向法线分布不同，如沿着某个方向刷过的金属
- 用 BRDF 定义，各向同性材质满足 BRDF 与方位角 $phi$ 无关($f_r (th_i,phi_i; th_r, phi_r) = f_r (th_i, th_r, |phi_r - phi_i|)$)
- BRDF 的性质总结
  + 非负性(non-negativity)：$f_r (omega_i -> omega_r) >= 0$
  + 线性(linearity)：$L_r (p, omega_r) = int^(H^2) f_r (p, omega_i -> omega_r) L_i (p, omega_i) cos theta_i dif omega_i$
  + 可逆性(reciprocity)：$f_r (omega_i -> omega_r) = f_r (omega_r -> omega_i)$
  + 能量守恒(energy conservation)：$forall omega_r int^(H^2) f_r (omega_i -> omega_r) cos theta_i dif omega_i =< 1$
  + 各向同性和各向异性(Isotropic vs. anisotropic)
- 测量 BRDF
  - 前面对于 BRDF 的讨论都隐藏了 BRDF 的定义细节，即使我们对微表面模型的 BRDF 给出了一个公式，但其中比如菲涅尔项是近似计算的，不够精确。有时候，我们不需要给出 BRDF 的精确模型（公式），只需要测量后直接用即可
  - 一般测量方法：遍历入射、出射方向，测量 radiance（入射出射可以互换，因为光路可逆），复杂度为 $O(n^4)$
  - 一些优化
    + 各向同性的材质，可以把 4D 降到 3D
    + 由于光的可逆性，工作量可以减少一半
    + 不用采样那么密集，就采样若干个点，其中间的点可以插值出来
    + $dots$
  - 测量出来 BRDF 的存储，应该挺热门的方向是用神经网络压缩数据
  - MERL BRDF Database 是一个很好的 BRDF 数据库

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
  - 这种渲染方法，往往是模糊和噪声(bias & variance)之间的平衡：$N$ 取小则噪声大，$N$ 取大则变模糊（BTW，有偏 == 模糊；一致 == 样本接近无穷则能收敛到不模糊的结果）
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
  #fig("/public/assets/Courses/CG/img-2024-08-04-20-58-32.png")
- 如何渲染：随机选择一个方向反弹（决定散射）；随机选择一个行进距离（决定吸收）；每个点都连到光源（感觉有点像 Whitted-Styled），但不再用渲染方程而是用新的 3D 的方程来算着色
- 事实上我们之前考虑的很多物体都不算完美的表面，只是光线进入多跟少的问题

=== 毛发、纤维模型
- 考虑光线如何跟一根曲线作用
- Kajiya-Kay Model（不常用，比较简单、不真实）：光线击中细小圆柱，被反射到一个圆锥形的区域中，同时还会进行镜面反射和漫反射。
- Marschner Model（计算量爆炸，但真实）
  - 把光线与毛发的作用分为三个部分
    + R：在毛发表面反射到一个锥形区域
    + TT：光线穿过毛发表面，发生折射进入内部，然后穿出再发生一个折射，形成一块锥形折射区域
    + TRT：穿过第一层表面折射后，在第二层的内壁发生反射，然后再从第一层折射出去，也是一块锥形区域
  - 把人的毛发认为类似于玻璃圆柱体，分为表皮(cuticle)和皮质(cortex)。皮质层对光线有不同程度的吸收，色素含量决定发色，黑发吸收多，金发吸收少
    #grid2(
      fig("/public/assets/Courses/CG/img-2024-08-04-21-10-19.png"),
      fig("/public/assets/Courses/CG/img-2024-08-04-21-13-52.png")
    )
- 动物皮毛(Animal Fur Appearance)
  - 如果直接把人头发的模型套用到动物身上效果并不好
  - 从生物学的角度发现，皮毛最内层还可以分出*髓质*(medulla)，人头发的髓质比动物皮毛的小得多。而光线进去这种髓质更容易发生散射
  - 双层圆柱模型(Double Cylinder Model)：某些人（闫）在之前的毛发模型基础上多加了两种作用方式 TTs, TRTs，总共五种组成方式
    #fig("/public/assets/Courses/CG/img-2024-08-04-21-25-48.png")

=== 颗粒状材质(Granular Material)
- 由许多小颗粒组成的物体，如沙堡等
- 计算量非常大，因此并没有广泛应用

== 表面模型(Surface Models)
=== 半透明材质(Translucent Material)
- 实际上不太应该翻译成“半透明”(semi-transparent)，因为它不仅仅是半透明所对应的吸收，还有一定的散射
- *次表面散射*(Subsurface Scattering)：光线从一个点进入材质，在表面的下方（内部）经过多次散射后，从其他一些点射出
  - 双向次表面散射反射分布函数(BSSRDF)：是对 BRDF 概念的延伸，某个点出射的 Radiance 是其他点的入射 Radiance 贡献的
    #fig("/public/assets/Courses/CG/img-2024-08-04-21-35-28.png")
  - 计算比较复杂，因此又有一种近似的方法被提出
- Dipole Approximation：引入两个点光源来近似达到次表面散射的效果
  #fig("/public/assets/Courses/CG/img-2024-08-04-21-38-45.png")

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
  #fig("/public/assets/Courses/CG/img-2024-08-05-12-08-38.png")
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
  - Circle of Confusion(CoC)：可以看出C和A成正比——光圈越大越模糊
    #fig("/public/assets/Courses/CG/img-2024-08-05-13-53-49.png")
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
    #fig("/public/assets/Courses/CG/img-2024-08-05-14-27-55.png")

= Color and Perception 光场、颜色与感知
- 光场(Light Field / Lumigraph)
- 一个案例：人坐在屋子里，用一张画布将人眼看到的东西全部画下来。然后在人的前面摆上这个画布，以此 2D 图像替代 3D 场景以假乱真（这其实就是VR的原理）

== 全光函数与光场
- 全光函数是个 $7$ 维函数，包含任意一点的位置 $(x, y, z)$、方向 （极坐标 $th, phi$）、波长$(la)$（描述颜色）、时间$(t)$
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
    #fig("/public/assets/Courses/CG/img-2024-08-05-15-37-39.png")
  - 双平面参数化后在实现上也变得更好理解，直接用一排摄像机组成一个平面就好

== 光场照相机
- Lytro 相机，原理就是光场。它最重要的功能：先拍照，后期动态调节聚焦
- 原理（事实上，昆虫的复眼大概就是这个原理）：
  - 一般的摄像机传感器的位置在下图那一排透镜所在的平面上，每个透镜就是一个像素，记录场景的 irradiance。现在，光场摄像机将传感器后移一段距离，原本位置一个像素用透镜替换，然后光穿过透镜后落在新的传感器上，击中一堆像素，这一堆像素记录不同方向的 radiance
  - 从透镜所在平面往左看，不同的透镜对应不同的拍摄位置，每个透镜又记录了来自不同方向的 radiance。总而言之，原本一个像素记录的 irradiance，通过替换为透镜的方法，拆开成不同方向的 radiance 用多个“像素”存储
    #fig("/public/assets/Courses/CG/img-2024-08-05-17-51-25.png")
- 变焦：对于如何实现后期变焦比较复杂，但思想很简单，首先我已经得到了整个光场，只需算出应该对每个像素查询哪条“像素”对应光线，也可能对不同像素查询不同光线
- 不足之处：分辨率不足，原本 $1$ 个像素记录的信息，需要可能 $100$ 个像素来存储；高成本，为了达到普通相机的分辨率，需要更大的胶片，并且仪器造价高，设计复杂

== 颜色的物理、生物基础
- 光谱：光的颜色 $approx$ 波长，不同波长的光分布为光谱，图形学主要关注可见光光谱
- 光谱功率分布(Spectral Power Distribution, SPD)
  - 自然界中不同的光对应不同的 SPD
  - SPD 有线性性质
- 从生物上，颜色是并不是光的普遍属性，而是人对光的感知。不同波长的光 $!=$ 颜色
- 人眼跟相机类似，瞳孔对应光圈，晶状体对应透镜，视网膜则是传感器（感光元件）
- 视网膜感光细胞：视杆细胞(Rods)、视锥细胞(Cones)
  - Rods 用来感知光的强度，可以得到灰度图
  - Cones 相对少很多，用来感知颜色，它又被分为 $3$ 类(S-Cone, M-Cone, L-Cone)，SML 三类细胞对光的波长敏感度（回应度）不同
    - 事实上，不同的人这三种细胞的比例和数量呈现很大的差异（也就是颜色在不同人眼中是不一样的，只是定义统一成一样）
- 人看到的不是光谱，而是两种曲线积分后得到 SML 再叠加的结果。那么一定存在一种现象：两种光，对应的光谱不同，但是积分出来的结果是一样的，即同色异谱(Metamerism)；事实上，还有同谱异色

== 色彩复制 / 匹配
- 计算机中的成色系统成为 Additive Color（加色系统）
  - 所谓加色法，是指 RGB 三原色按不同比例相加而混合出其他色彩的一种方法
  - 而自然界采用减色法，因此许多颜色混合最后会变成黑色而不是计算机中的白色
- CIE sRGB 颜色匹配
  - 利用 RGB 三原色匹配单波长光，SPD 表现为集中在一个波长上（如前所述，有其它 SPD 也能体现出同样的颜色，但选择最简单的）
  - 然后，给定任意波长的*单波长光*（目标测试光），我们可以测出它需要上述 RGB 的匹配（可能为负，意思是加色系统匹配不出来，但可以把目标也加个色），得到*匹配曲线*
    #fig("/public/assets/Courses/CG/img-2024-08-05-18-32-22.png")
  - 然后对于自然界中并非单波长光的任意 SPD，我们可以把它分解成一系列单波长光，然后分别匹配并加权求和，也就是做积分

== 颜色空间
- Standardized RGB(sRGB)：多用于各种成像设备，上面介绍的就是 sRGB。色域有限（大概为 CIE XYZ 的一半）。
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

= Animation 动画与模拟
#info()[
  + 基本概念、质点弹簧系统、运动学
  + 求解常微分方程，刚体与流体
]

== 基本概念
- 动画历史
- 关键帧动画(Keyframe Animation)
  - 关键位置画出来，中间位置用线性插值或 splines 平滑过渡
- 物理模拟(Physical Simulation)
  - 核心思想就是真的构建物理模型，分析受力，从而算出某时刻的加速度、速度、位置
  - 物理仿真和渲染是分开的两件事

== 质点弹簧系统
- 质点弹簧系统(Mass Spring System)
  - $f_(a->b)=k_s (b-a)/norm(b-a)(norm(b-a)-l)$，存在的问题，震荡永远持续
  - 如果简单的引入阻尼(damping)：$f=-k_d dot(b)$，问题在于它会减慢一切运动（而不只是弹簧内部的震荡运动）
  - 引入弹簧内部阻尼：$f_b=-k_d underbrace((b-a)/norm(b-a) dot (dot(b)-dot(a)), "相对速度在弹簧方向投影") dot underbrace((b-a)/norm(b-a), "重新表征方向")$
- 用弹簧结构模拟布料
  #grid(
    columns: (.3fr, 1fr) * 2,
    row-gutter: 6pt,
    fig("/public/assets/Courses/CG/img-2024-08-06-13-54-14.png", width: 3em),[1. 不能模拟布料，因为它不具备布的特性（不能抵抗切力、不能抵抗对折力）],
    fig("/public/assets/Courses/CG/img-2024-08-06-13-54-32.png", width: 4em),[2. 改进了一点，虽然能抵抗图示对角线的切力，但是存在各向异性。另外依然不能抵抗折叠],
    fig("/public/assets/Courses/CG/img-2024-08-06-13-54-45.png", width: 4em),[3. 可以抵抗切力，有各向同性，不抗对折],
    fig("/public/assets/Courses/CG/img-2024-08-06-13-54-52.png", width: 4em),[4. 红色 skip connection 比较小，仅起辅助作用。现在可以比较好的模拟布料],
  )
- Aside: FEM(Finite Element Method) instead of Springs 也能很好地模拟这些问题
- 粒子系统(Particle Systems)
  - 建模一堆微小粒子，定义每个粒子会受到的力（粒子之间的力、来自外部的力、碰撞等），在游戏和图形学中非常流行，很好理解、实现
  - 实现算法，对动画的每一帧：
    + 创建新的粒子（如果需要）
    + 计算每个粒子的受力
    + 根据受力更新每个粒子的位置和速度
    + 结束某些粒子生命（如果需要）
    + 渲染
  - 应用：粒子效果、流体模拟、兽群模拟

== 运动学
- 正向运动学(Forward Kinematics)
  - 以骨骼动画为例，涉及拓扑结构(Topology: what’s connected to what)、关节相互的几何联系(Geometric relations from joints)、树状结构(Tree structure: in absence of loops)
  - 关节类型
    + 滑车关节(Pin)：允许平面内旋转
    + 球窝关节(Ball)：允许一部分空间内旋转
    + 导轨关节(Prismatic joint)：允许平移
  - 正向运动学就是——给定关节的角度与位移，求出尖端的位置
  - 控制方便、实现直接，但不适合美工创作动画
- 逆运动学(Inverse Kinematics)
  - 通过控制尖端位置，反算出应该旋转多少
  - 有多解、无解的情况，是典型的最优化问题，用优化方法求解，比如梯度下降
- 动画绑定(Rigging)
  - rigging 是一种对角色更高层次的控制，允许更快速且直观的调整姿势、表情等。皮影戏就有点这个味道，但是提线木偶对表情、动作的控制更贴切一些
  - 在角色身体、脸部等位置创造一系列控制点，美工通过调整控制点的位置，带动脸部其他从点移动，从而实现表情变化，动作变化等
  - Blend Shapes：直接在两个不同关键帧之间做插值，注意是对其表面的控制点做插值
- 动作捕捉(Motion capture)
  - 在真人身上放置许多控制点，在不同时刻对人进行拍照，记录控制点的位置，同步到对应的虚拟人物上

== 求解常微分方程
- 单粒子模拟(Single Particle Simulation)
  - 之前讲的多粒子系统只是宏观上的描述，现在我们对单个粒子进行具体方法描述，这样才能扩展到多粒子
  - 假设粒子的运动由*速度矢量场*决定，速度场是关于位置和时间的函数（定义质点在任何时刻在场中任何位置的速度）：$v(x, t)$，从而可以解常微分方程来得到粒子的位置
  - 怎么解？使用欧拉方法（a.k.a 前向欧拉或显示欧拉）
- 欧拉方法
  - 简单迭代方法，用上一时刻的信息推导这一时刻的信息 $x^(t+Delta t)=x^t + Delta t dot(x)^t$
  - 误差与不稳定性：用更小的 $Delta t$ 可以减小误差，但无法解决不稳定性（比如不管采用多小的步长，圆形速度场中的粒子最终都会飞出去，本质上是误差的阶数不够导致不断累计）
    - 定义稳定性：局部截断误差(local truncation error)——每一步的误差，全局累积误差(total accumulated error)——总的累积误差。但真正重要的是步长 $h$ 跟误差的关系（阶数）
  - 对抗误差和不稳定性的方法
    - 中点法(or Modified Euler)：质点在时刻 $t$ 位置 $a$ 经过 $De t$ 来到位置 $b$，取 $a b$ 中点 $c$ 的速度矢量回到 $a$ 重新计算到达位置 $d$
      - 每一步都进行了两次欧拉方法，公式推导后可以看作是加入了二次项
    - 自适应步长(Adaptive Step Size)：先用步长 $T$ 做一次欧拉计算 $X_T$，再用步长 $T/2$ 做两次欧拉得到 $X_T/2$，比较两次位置误差 $"error" = norm(X_T - X_T/2)$，如果 error > threshold，就减少步长，重复上面步骤
    - 隐式欧拉方法(Implicit Euler Method)：用下一个时刻的速度和加速度来计算下一个时刻的位置和速度，但事实上并不知道下一时刻的速度和加速度，因此需要解方程组。
      - 局部误差为 $O(h)$，全局误差为 $O(h^2)$
    - 龙格库塔方法(Runge-Kutta Families)：求解一阶微分方程的一系列方法，特别擅长处理非线性问题，其中最常用的是一种能达到 $4$ 阶的方法，也叫做 RK4
      - 初始化 $(di y)/(di t)=f(t,y), ~~ y(t_0)=y_0$
      - 求解方法（下一时刻等于当前位置加上步长乘以六个速度的平均）：$t_(n+1)=t_n+h, ~~ y_(n+1)=y_n+1/6 h(k_1+2k_2+2k_3+k_4)$
      - 其中 $k_1 \~ k_4$ 为：$k_1=f(t_n, y_n), ~~ k_2=f(t_n+h/2, y_n+h/2 k_1), ~~ k_3=f(t_n+h/2, y_n+h/2 k_2), ~~ k_4=f(t_n+h, y_n+h k_3)$，具体推导为什么是四阶就略过（可以参考《数值分析》）
- 非物理的方法
  - 基于位置的方法(Position-Based)、Verlet积分等方法
  - Idea：使用受限制的位置来更新速度，可以想象成一根劲度系数无限大的弹簧
  - 优点是快速而且简单；缺点是不基于物理，不能保证能量守恒

== 刚体与流体
- 刚体：不会发生形变，且内部所有粒子以相同方式运动
  - 刚体的模拟中会考虑更多的属性
  $ di/(di t) vec(X, th, dot(X), omega) = vec(dot(X), omega, F/M, Gamma/I) $
  - 有了这些属性就可以用欧拉方法或更稳定的方法求解
- 流体，使用基于位置的方法(Position-Based Method)
  - 前面已经说过流体可以用粒子系统模拟，然后我们用基于位置的方法求解
  - 主要思想：水是由一个个刚体小球组成的；水不能被压缩，即任意时刻密度相同；任何一个时刻，某个位置的密度发生变化，就必须通过移动小球的位置进行密度修正；需要知道任何一个位置的密度梯度（小球位置的变化对其周围密度的影响），用机器学习的梯度下降优化；这样简单的模拟最后会一直运动停不下来，我们可以人为的加入一些能量损失
- 模拟大量物体运动的两种思路：
  - 拉格朗日法（质点法）：以每个粒子为单位进行模拟
  - 欧拉法（网格法）：以网格为单位进行分割模拟（跟前面解常微分方程不是一回事）
  - 混合法(Mterial Point Method, MPM)：粒子将属性传递给网格，模拟的过程在网格里做，然后把结果插值回粒子


