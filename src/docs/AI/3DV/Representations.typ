#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reconstruction",
  lang: "zh",
)

#let SDF = math.text("SDF")
#let clamp = math.text("clamp")
#let Occupancy = math.text("Occupancy")
#let NeRF = math.text("NeRF")

#info(caption: "参考")[
  + #link("https://github.com/vsitzmann/awesome-implicit-representations")[github.com/vsitzmann/awesome-implicit-representations]
  + #link("https://blog.csdn.net/weixin_43117620/article/details/131980822")[浅谈3D隐式表示(SDF, Occupancy field, NeRF)]
  + #link("https://blog.csdn.net/weixin_42145554/article/details/126637671")[概述：隐式神经表示(Implicit Neural Representations, INRs)]
  + #link("https://zhuanlan.zhihu.com/p/156625765")[SIREN: 使用周期激活函数做神经网络表征]
  + #link("https://games-cn.org/gamesdiyiqixueshushalongguandianjijin/")[GAMES 关于 NeRF 的学术沙龙]
]

= 3D Scene Representations & Reconstruction
== 简单引入
- 与经典的二维图像表示相比，三维表示是对整个 3D 场景的完整建模，有时我们还引入时间维度而成为 4D 动态建模
- 有效的三维表示是实现三维重建、三维目标检测、场景语义分割等任务的基础
- 在 CV, CG 社区的长期探索下，基于许多不同的考量（直观性、准确性、分辨率、计算效率、易用性、空间存储等），三维表示逐渐变得五花八门，大体可以分为显式和隐式

=== 显式
- 所有点（或者更宽泛一点，场景表示）被直接给出，或者可以通过映射关系直接得到
- 比较常用的显式表示比如体素 Voxel、点云 Point Cloud、三角面片 Mesh、深度图 depth map 等
#fig("/public/assets/AI/Reconstruction/2024-10-10-16-02-46.png", width: 60%)
- *体素*
  - 体素是 2D 像素表示的直接推广，有时也叫体素网格 (grid)，体素表示的一个很直观的例子是 —— Minecraft
  - 在体素中可以存储*几何占有率*、*体积*、*密度*和*符号距离*等信息以方便渲染
  - 体素表示的*规则性*和*易于处理*使其应用非常广泛，在很多任务中被拿来引入*结构化信息*，而且它很容易与神经网络相结合（经典工作比如 3D ShapeNets, 3D-R2N2）。然而，体素表示的空间存储随分辨率呈*立方级别增长*，直接导致了八叉树数据结构的引入
- *点云*
  - 点云是 CV 这边非常经典的表示方法，后面将要介绍的 3D Gaussion 便是点云的推广
  - 点云是三维空间中点的无序集合，可以将其视为 3D 形状曲面的*离散化样本*。点云具有*无序性*、*点之间的相互作用*（离散但并不孤立，共同组成局部结构）和*变换不变性*
  - 在点云上可以存储三维坐标 $x,y,z$、RGB、分类值、强度值、时间等等
  - CV 这边的很多传统方法都是基于点云，例如可以由 SfM 直接输出，很容易获得。点云表示灵活而高效，且多样性非常高，同一 3D 形状可以由不同的点云表示，但这有时也是缺点。点云的不规则性使得它们相对较难用现有用于规则网格数据的神经网络进行处理（经典工作比如 PointNet）。另外，点云表示的信息量有限（本质是三维几何形状的低分辨率重采样，只能提供片面的几何信息）
- *三角面片*
  - 也叫三角网格、多边形网格（多边形可以被拆分为三角形），是 CV 中非常经典的表示方法，被广泛应用于建模、动画、渲染。另外，由于工业界经典而成熟的*图形渲染管线*是基于三角形的，所以很多其它 3D 场景表示到最后还是要求转换为三角网格
  - 三角面片上可以存储三角形的*顶点坐标*、*法向量*、*纹理坐标*、*颜色*等信息
  - 三角面片具有*顶点无序性*、*方向性*、*拓扑性*。与体素相比，三角网格仅对场景曲面建模，更紧凑且占用内存少；与点云相比，三角网格提供了模拟点关系的*曲面点的连通性*。三角网格的建模满足*有边界的流形(manifold with boundary)*，易于编辑和处理（经典工作比如 pixel2mesh）
- *深度图*
  - 深度图是一种二维图像，每个像素点存储了对应点的*深度信息*（在该图的位姿下，相机到场景中点的距离）
  - 深度图的常见获取方式包括：通过特殊传感器或 RGB-D 相机直接获取深度；利用双目或多目相机的视差计算深度；利用先验知识或模型对图像进行分析，推测出每个像素点的深度
  - 深度图归根到底还是图，在 3D 语境下*不易操作*。因此要想表示三维场景，往往需要将其转化为点云
- *3D Gaussion*
  - 见后

=== 隐式
- 不直接说明点（或者更宽泛一点，场景表示）在哪，而描述其满足的关系
- 比较常用的隐式表示有：代数曲面、分形几何 Fractals、Constructive Solid Geometry(CSG)、Signed Distance Funciton(SDF)、Occupancy Field、Neural Radiance Field(NeRF) 等
- *基于代数几何*的隐式表示：其中*代数曲面*是指用解析的方式来描述曲面；*分形几何*是指自相似（自递归）的形体（如雪花）；*CSG* 是基于集合的描述，利用集合的交、并、差等运算来描述物体。这些方法通常需要人工设计特征，难以泛化，因此我们往往重点关注下面这一类
- *基于神经表示*(Implicit Neural Representations, INRs)的隐式表示：即*隐式神经表示*，利用神经网络对各种信号进行参数化。传统的信号表示通常是离散的，而隐式神经表示将信号参数化为一个连续函数、场，将信号的域映射到该坐标上的属性的值。这些映射通常不是解析性的，但可以被神经网络所拟合
- 隐式表示相对显式表示的
  - 优点
    + *表示不再与空间分辨率相耦合*：这直接得益于隐式表示的连续性。一个直接推论是，隐式表示具有“无限分辨率”，使超分辨率成为可能
    + *表征能力（有时）更强*：在神经网络的加持下，隐式表示可以拟合更复杂的特征和场景，通常比显式表示更加强大。但这也不绝对 (e.g., 3DGS)
    + *可泛化性*：跨神经隐式表示的泛化等同于学习函数空间上的先验，通过神经网络权重的预训练实现 —— 这通常被称为元学习
    + *相对易于学习*：与显式表示相比，隐式表示将场景抽象成函数、场，这天然更适合神经网络去拟合，易于与各种网络结构结合。神经隐式表征可以灵活地融合到可微分的基于学习的管线中
    + *空间需求一般相对较小*：只需存储神经网络参数
  - 缺点
    + *需要后处理*：图形渲染管线是基于显式 triangle mesh 的，除此之外的其它显式方法或隐式方法要么用自己的一套渲染方案（比如 3DGS 的 splatting，NeRF 的体渲染），要么就探索如何转化为 triangle mesh
    + *过度平滑和伪影*：过度平滑，即图像放大后难以保持锐利和纹理，导致高频信息丢失和视觉上变得平滑；伪影，即 Artifacts，包括模糊、马赛克效应或者不自然纹理等现象
    + *计算量大*：隐式神经表示需要对整个三维几何物体每个点进行神经网络前向推理，计算量大，十分耗时，难以实时
    + *难以解释和编辑*：神经网络的一贯缺点，内部是个黑盒。当然在 3D Representations 这个语境下可以把网络固化到显式表示来可视化，但编辑依旧困难
- 另外翻译一个来自 awesome-implicit-representations 的观点
  #q[
    - 一个令人兴奋的重叠点是神经隐式表示与神经网络架构中*对称性*的研究。例如，创建一个对 3D 旋转具有等效性的神经网络架构，通过神经隐式表示，可以立即获得一条通向“对旋转具有等效性的生成模型”的可行路径。
    - 隐式神经表示的另一个关键前景在于直接在这些表示空间中*操作的算法*。换句话说：什么是“卷积神经网络”？相当于对隐式表示所表示的图像进行操作的神经网络
  ]
- 常用的隐式神经表示，如 SDF, Occupancy Field, NeRF，这些无论是 function 还是 field 实际上都是一种映射关系：
  $
  SDF(bx) = s, ~~~ bx in RR^3, s in RR \
  Occupancy(bx) = o, ~~~ bx in RR^3, o in [0, 1] \
  NeRF(bx,bd) = (R G B,sigma), ~~~ bx in RR^3, "RGB is color, " sigma "is density"
  $
  + *SDF*：空间中的一个点到物体表面最近的距离，点在曲面内部则规定距离为负值，点在曲面外部则规定距离为正值，点在曲面上则距离为 $0$。用神经网络去近似这个函数，相当于一个回归任务
    - 一个非常相近的概念是水平集 Level Set，还不是很清楚两者的区别
  + *Occupancy*：空间中的一个点是否被物体占用，通常以 $0.5$ 为标准，大于 $0.5$ 倾向于认为点被曲面占用（在内部），$0.5$ 倾向于没有被占用（在外部），$0.5$ 认为点在曲面上（即 $F(p)=0.5$ 表示一个曲面）。用神经网络去近似这个函数，相当于一个二分类任务，得到的*分类决策边界*等价于曲面描述
    - 变种：利用条件变量 $bc$ 编码一个特定曲面的形状，利用占用场来表示点的颜色值
    $ Occupancy(bx, bc) = (o, R G B), ~~~ bx in RR^3, o in [0, 1], "RGB is color" $
  + *NeRF*: 将“空间中的点 + 点发出的一条射线” 映射到 “点的密度值 + 射线方向对应的颜色值”；或者说，空间中每一个点的每一个角度，都对应一个颜色值和一个透明度。反过来，从空间中一个点出发，沿着某个方向看去，能看到这个方向上的颜色和透明度

#v(1em)
#hline()

- 其实很多时候，显式和隐式的表示不是那么非黑即白，我在分类的时候也进行了一些斟酌
  - 比如传统的 Occupancy, SDF 和 voxels 结合在一起(TSDF)，合称为 volume 表示
  - NeRF 有五花八门的基于 *baking* 思想把特征*固化*在显式表示的工作，以及融合显式了表示的 hybrid 工作
  - 3DGS 后续也有很多往显式那边靠的工作
- 过度拘泥于显式与隐式没有任何意义，重要的是理解并融汇它们的优点
  - 可能 *Hybrid* implicit / explicit (condition implicit on local features) 才会是一个比较好的方向
  - 大方向是往深度学习那边走（不管是隐式神经表示那样直接用神经网络，还是像 3DGS 那样借用参数优化的思想）。事实上，就像 3DGS，只要满足*参数是可学习的*，*计算/查询是可微分的*，那么这种表示方法就可能是有效的
- 另外，如果不从显隐式的角度分类，3D 模型还可以分成 *shape* 和 *appearance* 两个部分
  - *shape(Geometry)* 这边，主要有 Mesh, Point Cloud, Voxel, Depth Map, Implicit Surface, SDF, Occupancy 等，还可再细分为 hard 和 soft 两类
  - *appearance* 这边，最常见的还是 *材质纹理贴图* + *环境光照*，易于编辑修改；NeRF 则使用了*辐射场*（Radiance Field，或者说表面光场 Surface light filed）的概念 —— 描述每个点对不同方向的光照，这可以用 RGB 来直接表达，也可以用球谐函数 SH 来间接表达

== Literature Tree of 3D Representations & Reconstruction
- 上个部分从分类的角度对 3D Representations 做了一定的介绍
- 下面将从时间线的角度进行梳理

=== 传统 3D 重建
- 基于点云的传统三维重建方法 pipeline：
  + 运动恢复结构(SfM)：给定多视角图片和相机内参，估计场景稀疏三维点云和相机外参（位姿）
  + 多视立体视觉(MVS)：对稀疏三维点云进行稠密化
  + 表面和纹理重建：将稠密点云转化为三角网格，为三角网格的顶点进行纹理映射
  - CV 导论课上学的 pipeline 则如下（道理是一样的）
    + Depth maps $->$ Point Cloud $->$ Occupancy Volume (Poisson reconstruction)
    + Occupancy volume $->$ mesh (Marching cubes)
    + Texture Mapping
- 传统的三维重建弊端在于
  - 如果相应的视角图像缺失，最终生成的模型会产生一些空洞，而且难以修改（不够灵活）
  - 传统三维重建每个步骤的算法都较为复杂，不够端到端，不够简洁，不够鲁棒（当然，一味追求端到端也不好，因为这整个过程比如 rendering 是有物理含义在里面的，某些模块使用人工设计去加先验和 inductive biase 是有道理的）
- 因此现在我们往往转向*深度学习*方法，以往传统方法一般是只拿某个组件来用了。然而深度学习方法之间亦有差距，我个人将其粗略划分为三个时代：前 NeRF 时代、NeRF 时代、3DGS 时代

=== 前 NeRF 时代
- #link("http://crd2333.github.io/note/Reading/Reconstruction/SIREN")[SIREN（笔记链接）]
  - 相比起其它探索三维表示的工作，SIREN 关注的是用于三维隐式表示的媒介，即用于拟合的那个神经网络。SIREN 证明了使用正弦函数作为激活函数的 MLP 在捕捉高频信息、周期信息方面比 ReLU-based MLP 更具有优势
- #link("http://crd2333.github.io/note/Reading/Reconstruction/DeepSDF")[DeepSDF]
  - DeepSDF 用神经网络做回归任务去拟合离散的 SDF；并且引入了 latent code $bz$ 来得到一定程度的泛化性，使用 decoder-only 的架构预训练出 decoder。推理时利用场景部分输入来优化 $bz$，从而得到可以用 $(x,y,z)$ query 的整个场景的 SDF 表示

=== NeRF
- 然后再看相对近代和比较重要的 #link("http://crd2333.github.io/note/Reading/Reconstruction/NeRF")[NeRF]
  - NeRF 本质上是用 MLP 拟合一个隐式表示场（场景中任意点和方向可以查询颜色和密度），结合了 Ray-Marching 和体渲染的方法实现新视角图片的合成
  - NeRF 究竟好在哪里呢？我个人参考一些资料提出以下几点
    + 相比传统方法，NeRF 是端到端的，也就是说前面步骤出错，可以基于后续反馈来反传去修正，而以前的方法只是一系列 hand crafted 步骤
    + 重建这种从低维恢复高维信息的过程是具有多解性的，传统 SDF, mesh 等的表达相对来说比较确定性（即使有解，它也很难准确地去逼近），而 NeRF 这个辐射场的概念以及 MLP 的强大拟合能力就让它优化的自由度变得非常高（但其实这个空间过大也不是好事，所以后续也有一些工作去增加约束和正则化）
    + 从优化的角度它有很多好处，无论是 geometry, color，甚至 illumination，虽然不是基于物理的，但是它可以把这些变化用一个 code 去表示，作为网络的输入。其次很重要的一点就是 volume rendering 的过程比较简单（一个线性的方程），导致 loss function 本身就会相对好优化
    + NeRF 这个框架相对好改造，能塞进很多东西，比如那个 PE，比如各种先验知识，以及后续的一些融合几何 + 语义表示的工作。换句话说，神经网络这种东西比较好魔改，能融进深度学习发展至今的很多 technique
  - NeRF 的待改进点在于：速度优化，泛化性，动态场景与大场景，可解释性，视角需求数，物理模拟等
- #link("http://crd2333.github.io/note/Reading/Reconstruction/NeRF%20改进工作")[NeRF 的改进工作]（可能看得还不够多）
  - 关于 NeRF 的*速度*：NeRF 的核心制约因素在于速度，它慢就慢在两点
    + Ray-Marching 逐像素射线并采样点，点的分布不高效
      - NSVF 从采样的角度出发试图解决问题，为后续很多工作所借鉴；
    + 每个点都需要过一遍 MLP 以得到辐射场属性
      - FastNeRF, PlenOctrees, KiloNeRF, TensoRF 等工作五花八门，但本质上都还是利用体素化的方法往显式表示那边靠，减少 MLP 前向的时间开销
        - 其中 Plenoxels 是比较激进的一个，变成了完全显式的方法（只是沿用了 NeRF 的体渲染方法和辐射场属性）
        - 而 DVGO, InstantNGP 等 Hybrid 的方法结合了显式和隐式的优势，实现了更快的渲染速度
        - MobileNeRF 在体素网格的基础上，利用 baking 固化了很多信息，把 MLP 的 Decoder 塞到图形渲染 pipeline 里，首次实现了移动设备上的实时渲染（推理）
  - 关于 NeRF 的*泛化性改进*，我看的两篇 GRAF, GIRAFFE 利用 GAN 和额外随机采样的编码来一定程度上变得多样
  - 关于 NeRF 的*大场景无界渲染*问题，NeRF++, Mip-NeRF, Mip-NeRF 360 的思路基本上是要么用非线性变换控制场景的采样频率，要么是把光线渲染变成光锥渲染（本质上也是控制了采样频率）

=== 3DGS
- #link("http://crd2333.github.io/note/Reading/Reconstruction/3DGS")[3DGS] 一经提出，就以它的即时速度引起巨大关注，基本薄纱 NeRF 了
  - 3DGS 本质上是又回到了显式表示 —— 3D 高斯球（Gaussion 本身作为一种概率描述，其在 3D 场景中的分布可以被看作是一个椭球），使用 splatting 代替 volume rendering 方法（某种程度上可以看作是一种逆变换），实现高速渲染
  - 事实上从 NeRF 逐渐转回到显式表示的方法如 PlenOctrees, Plenoxels, InstantNGP 早有预兆，这也反映出一种趋势：对实时性的追求
  - 另外 3DGS 虽然是显式表示，但吸收了*神经网络参数优化*的思想（和*现代算力*的加持），可以看作是把*整个场景都视为一个神经网络*，从而把参数调到最优
    - 我觉得这是挺有意思的一点，站在现代回顾传统方法（用高斯球表示场景并渲染在 EWA splatting, 2001 里早已出现），依旧能给技术带来巨大进步。其实隐式函数也是一样，几十年前就有了，但在神经网络加持下又以隐式神经表示的形式重新出现
  - 从*离散和连续*的角度来看，高斯球可以被视作有体积、各项异性的一个个点云，这是离散的；但在高斯球内部又是连续的、可微的（投影到图像坐标系下，对渲染结果的贡献是连续的、可微的，场景表达更连贯）。Gaussion 表示在离散和连续间取得一种平衡，所谓*中庸之道*，莫过于此
  - 围绕 3DGS 的工作就没有那么 focus on 速度，而是变得五花八门，并且把之前 NeRF 上做过的各种应用都拿过来刷了一遍，但是我现在看得还不多

#v(3em)

#hline()

- 最后，引用两张图来比较各种三维表示的优劣
#grid(
  columns: (61%, 39%),
  fig("/public/assets/AI/Reconstruction/2024-10-26-11-19-54.png"),
  fig("/public/assets/AI/Reconstruction/2024-10-26-11-29-04.png")
)
- 然后用一张 NeRF 阵营图做结，不得不说总结得确实很有意思也挺有道理
  #fig("/public/assets/AI/Reconstruction/2024-10-24-15-21-18.png")
