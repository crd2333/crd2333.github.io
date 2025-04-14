#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

#let QA(..args) = note(caption: [QA], ..args)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

= 游戏引擎导论

= 引擎架构分层

= 如何构建游戏世界
#QA(
  [物理和动画互相影响的时候怎么处理],
  [一个比较典型的问题，更多算是业务层面的问题而不是引擎层面，但引擎也要对这种 case 有考虑。以受击被打飞为例，被打到的一瞬间要播放受击动画，击飞后要考虑后续的物理模拟。这么剖析的话怎么做也已经呼之欲出了，也就是做一个权重的混合，一开始是动画的占比较大，把动画的结果作为物理的初始输入，越到后面物理模拟的占比增大（更深入一点，就是 FK 和 IK 的权重变化）。最终能做到受击效果跟预定义的动画很像，但后续的动作变化也很物理、合理。]
)

= 游戏引擎中的渲染实践
- Hardware architecture
  - SIMD and SIMT，前者在很多地方都能看到，后者是指 single instruction multiple threads，相当于一个指令发给很多线程，然后每个线程又可以对一个指令处理多个数据，实现成倍的效率提升。
  - GPU architecture, Data Flow from CPU to GPU, Cache...
  - 随着 GPU 越来越强，GPU-Driven 变成一种趋势，把 CPU 的工作交给 GPU 来做
- Render data Organization
  - Mesh render component
  - Renderable
  - ...
  - Sub Mesh 子网格。指把一个模型拆分为多个网格，方便对每个网格设置不同材质。虚幻里叫 section
  - Instency 实例化 Use Handler to Reuse Resources。还涉及到合批 GPU Batch Rendering 的概念，例如 Unity 的 SRP Batcher
  - Sort by Material，合批的同时按材质排序，虽然整体计算量不变，但避免了 GPU 切换的开销
- Visibility
  - 视锥剔除，一般在 CPU 上做
  - PVS (Potentially Visible Set) 把世界分区域，预计算每个区域能看到哪些区域
    - 实际上现在完全用 PVS 做的游戏基本没有了，更多是作为一种思想，把世界划分为类似的 zone
    - 大世界里面这种方法的使用也相对减少
  - GPU Culling
    - Early-Z
- Texture Compression
  - 常见的 block-based compression format
    - On PC: BC7 (modern) or DXTC (old)
    - On Mobile: ASTC (modern) or ETC / PVRTC (old)
- Modern Rendering
  - Programmable Mesh Pipeline
  - *Cluster-Based Mesh*，也就是虚幻引擎 *Nanite* 的原理

= 渲染中光和材质的数学魔法
- 渲染方程及挑战
- 基础光照解决方案
  - Simple light + Ambient
  - Blinn-Phong material
  - Shadow map
- *基于预计算的全局光照*
  - 球谐函数
  - Light map: 把全局光照预计算到纹理上，实时渲染时直接采样
    - 现在略微有点过时了，但是其思想依旧重要：第一是空间换时间，第二是把整个空间参数化到 2D Texture 或 3D Volume 上，便于后续管理
  - *Light Probe*
    - 在空间中放置一些点，采样周围的光照信息，当物体经过时，采样这些点进行插值，算出自己的光照，总之，就是一个空间体素化的思想。这些点不会太多，比如 light map 可能需要采几百万个点来烘焙，而 light probe 可能几百个就差不多了
    - 但问题在于，谁来摆这些点？早期可以让美术手动用编辑器工具放置，但关卡变动导致需要重新放置，因此更好的方法是自动化（根据玩家可到达区域和场景几何均匀地撒点）
    - 还有一种特殊的 probe 叫做 reflection probe，专门用来采样反射光照，密度低一些但精度更高
    - 在实际运用中，我们可能会从相机位置往四周看，从而在 shader 中高效计算出光照；计算出的光照也不会在下一帧直接弃用，而是根据移动距离之类判断是否需要更新；另外，可以对 light probe 进行一些压缩，并不会损失太多精度
    - 总的来说，Light Probe 运行效率很高，它同时处理了 diffuse 和 specular，并且能处理动态物体；不过缺点是一系列 SH light probes 需要一定的计算，以及精度往往不如 light map
- *基于物理的材质*
  - 微表面材质
  - Cook-Torrance BRDF
  - Disney Principled BRDF
  - PBR 这方面知识点实在太多，回到材质上，用得比较规范且主流的两种是 PBR Specular Glossiness 和 PBR Metalness Roughness
  - PBR Specular Glossiness
    - 几乎不用设置任何参数，所有都用图来表达，包括 Diffuse, Specular, Glossiness，然后就能很方便地算出 Cook-Torrance 模型的结果
    - 有个问题是过于灵活，尤其是 specular 那一项，美术设置不好容易导致菲涅尔项炸掉，为此提出
  - PBR Metalness Roughness
    - 相对粗暴（“土法炼钢”），首先设置一个 Base Color，然后可以设置 Roughness 和 Metalness
    - 可以理解为 MR 模型是在 SG 外面包了一层，如果是非金属（Metalness 较低），那么你的 specular 就锁死了，否则可以逐渐地从 base color 里面取出来
    - 也就是说，MR 是个很强的通用函数，但容易用不好，MR 则是对它略做限制但更易用
- *Image-Based Lighting (IBL)*
  - 对背光面的表达、对环境光的表达，最常见的方法
- *经典阴影方法*
  - Big World and *Cascade Shadow*
    - 不同距离、尺度的 shadow 对精度要求不同，可以从相机视锥触发根据距离划分不同层级的阴影
    - 这个方法在过去具有统治地位的影响力，结果也相当不错（不过现在有各种各样 fancy 的方法出来）
    - 一个很大的问题是 blend between cascade layers，简单的线性插值会导致阴影边缘锯齿；并且它也算用空间换时间；另外，生成远处的 shadow 相当于把很大一部分场景都绘制了一遍，开销不低（shadow 这东西在游戏引擎中是一个 expensive 的开销）
  - 软阴影
    - 最经典的就是 PCF (Percentage Closer Filtering)
    - 在实战中更多使用其改进 PCSS (Percentage Closest Soft Shadow)
  - VSSM (Variance Shadow Map)
    - 通过对深度值进行方差计算，来实现阴影模糊
#note(caption: "Summary of Popular 3A Rendering")[
  - Light map + Light probe
  - PBR + IBL
  - Cascade shadow + VSSM
]
#q[以上这些渲染方法，最好还是看 GAMES202，更专业对口]
- 前沿技术
  - Real-time Ray-Tracing on GPU
  - Real-time Global Illumination
  - Virtual Shadow Maps
- Shader Management
  - 美术画 shader graph 会产生大量 shader，此外程序员编写的 uber shader 在编译展开之后会产生大量的 variants
  - Cross Platform shader

= 游戏中地形大气和云的渲染
== 地形的几何
- Simple Idea: Height field (map)
  - 用 mesh grid 来表达地形，但对大世界有明显的问题
- Adaptive Mesh Tessellation（细分）
  - Two Golden Rules of Optimization (View-dependent error bound)
    - Distance to camera and FoV
    - Error compare to ground truth (pre-computation)
  - 最简单的方法是 Triangle-Based Subdivision
    - 会有 T-Junction 问题需要处理
    - 这个方法无论在效率、表达能力上都没有问题，但是不符合我们制作地形的直觉（我们 prefer 豆腐块，而不是七巧板一样的三角形）
  - 但更常用的是 Quad-tree Based Subdivision
    - 用一个四叉树来表示地形，四叉树的每个节点都可以有不同的细分级别
    - 处理方便，而且地块的方法跟纹理、跟人的直觉更适配，是一个非常好用的数据结构
    - 也会有 T-Junction 问题，但这里是用 stiching 来解决
  - 还有一种方法是 Triangulated Irregular Network (TIN)
    - 这种方法不如以上两种广泛，但也有一些游戏使用，尤其是在某些地形比较平坦、某些地形又比较复杂的情况下，上面两种方法在这种情况下都不方便
    - 于是使用面片简化的方法，把不必要的顶点剔除，同时把顶点 align 到 feature 上，提前把地形划分好
      - 从信号频率的角度思考，上面两种方法太通用，不好表达地形复杂变化的高频信号；而 TIN 的灵活性更高
    - 自然，这需要预处理，可重用性不高；但它所用的三角形会更少，并且在 runtime rendering 上更有优势
- GPU-based tessellation
  - 事实上，上面说的这种程序员在 CPU 上 build 好顶点再送进 GPU 的方法，在逐渐让步于 GPU-driven 的自动化过程
  - 在古老的图形 API DX11 上，在 Vertex Shader 和 Geometry Shader 之间插入 Hull Shader, Tessellation, Domain Shader 阶段（名字取得比较奇怪，总之就是为了细分而设计的）
  - 在现代的图形 API DX12 上，用一个 Mesh Shader 代替前面的 Vertex Shader, Hull Shader, Tessellation, Domain Shader 以及 Geometry Shader
  - GPU-driven 的另一个好处是，自动调整的顶点允许我们构建 Real-time Deformable Terrain！
- Non-Heightfield Terrain
  - 以上基于高度的地形不好做洞穴、悬崖、倒勾等
    - 一般会通过一些 hack 来实现，比如：摆一个模型假装是 terrain 的一部分；以及在 vertex 上做标记取消掉用到该顶点的三角形（退化），也就是 dig a hole in terrain
  - Crazy Idea: Volumetric Representation
    - 王希老师说目前用的还不多（夹带私货），但据我所知现在 (2025) 已经有一些游戏用上了，比如《雾锁王国》基于体素的建造系统
    - 引入大名鼎鼎的 Marching Cubes 算法

== 地形的材质
- 用 PBR 的 MR 模型，每种材质存 Base Color, Normal, Roughness（metalness 作为一个 alpha channel 加到 Base Color 上），以及额外的 Height Map
- 材质混合
  - 有多种材质后，一种简单的方法是用 splat map 来混合，让艺术家以笔刷来绘制
  - 但是过渡得太假，另一种比较 hack 的方式是 blending with height
    - 在两种 texture 之间，利用高度值来做非线性插值
    - 一个小细节是动态场景下会有抖动变化，可以用 height bias 的 hack 来缓解
  - 但游戏中肯定不止两种材质，这引出 Sampling from Material Texture Array（不要跟 3D texture 搞混）
    - 这个方法简单但可以想见过于昂贵，有没有更好的方法呢？引出 Virtual Texture
- Bump, Parallax and Displacement Mapping
  - 老师讲课时 (2022) 大多还是用 bump 多，但也越来越多升级成 displacement
- Virtual Texture
  - 这个方法建立了一个 virtual indexed texture 来表示所有 blemded terrain materials，根据 view-depend LOD 只加载需要的 tiles 的 materials data，需要把材质 pre-bake 到 tiles 中并存到 physical textures 中
  - 弹幕说的方案简单阐述：绘制两遍，第一遍把需要用的贴图的 tile 以及自身的 UV 等等信息输出到 rendertarget 上，CPU 根据 RT 的数据将资源送到 GPU，第二遍绘制才是真正的渲染
    - 实现上牵涉到 Direct Storage，甚至用 DMA 直接绕开 CPU 把数据从 SSD 送到 GPU
  - 理解起来的话，就是利用了局部性原理，大大降低显存占用，只加载少量常用的材质

== 地形问题杂项
- Floating-point Precision Error
  - 浮点数 IEEE 表示格式导致数字大则精度下降，于是距离远的物体会相互打架，物理模拟会直接炸掉，大世界无法构建……
  - 最粗暴的方法是直接改用 double，还有一种方法是 Camera-Relative Rendering，也就是以相机为远点算距离，能缓解一部分问题
- Tree Rendering
  - 最著名的中间件 SpeedTree
- Decorator Rendering
  - 一般用最简单的 mesh 来表达，或者 billboard
- Road and Decals Rendering
  - 道路最常见的方法是样条线 spline，方便美术控制，但程序上还需要对高度场进行一些处理
  - decal 贴花，比如血迹、弹孔、污垢等，美术在场景中撒很多贴花，让场景变得更真实。可以用 Parallax Maps 来实现
  - 无论是道路还是贴花，都可以一股脑地 bake 到 virtual texture 中
    - 这也是 virtual texture 的好处之一，把复杂度转移到 baking 过程，在 real-time render 时候就简单了

== 大气散射理论
- *Analytic Atmosphere Appearance Modeling*
  - 一个经验模型，定位类似与大气渲染中的 Blinn-Phong，给出方位角 $th, phi$ 就算出一个解析解得到颜色
  - 优点：计算简单且有效；缺点：只有地表视角，参数写死解固定，不能覆盖下雨等真实情况
-  *辐射传递方程 RTE (Radiative Transfer Equation)*
  - 考虑大气中各种半透明粒子（各种气体和气溶胶介质），被称为 Participating Media 参与介质，它们与光的交互
    + 光被吸收 (Absorption)
    + 光被散射 (Out-scattering)
    + 自发光 (Emission)
    + 周边被点亮的气体散射来照亮自己 (In-scattering)
  - 合到一起就形成了辐射传递方程，类似于大气渲染中的渲染方程，知道概念即可，不用记，后续全都预计算
- *体积渲染公式 VRE (Volume Rendering Equation)*
  - RTE 表达的是空间中的梯度，对 RTE 积分就得到体积渲染公式 VRE
  - 同样不用记，知道 $2$ 个主要变量即可：
    + 通透度 Transmittance：在 $M$ 点放一个东西，到 $P$ 点还剩下多少（路径积分的结果）
    + 散射函数 Scattering Function：路径叠加到的沿途散射过来的光，打到相机的部分
- *Real Physics in Atmosphere 大气物理学*
  - 真实的物理模型，考虑两种不同的散射模型 —— Rayleigh Scattering, Mie Scattering
    - Rayleigh Scattering
      - 当空气中介质尺寸远小于光的波长的时候（气体）：空气中的光四面八方均匀散射；且对波长越短的光，散射得越远
      - Rayleigh Scattering Equation
        #fig("/public/assets/CG/GAMES104/2025-03-29-11-14-45.png")
        - 看着很复杂，但当我们固定海拔 $h$ 和气体折射率 $n$ 后，就是一个只随 $th$ 变化的方程
      - 借此可以解释天空是蓝色、晚霞是红色
    - Mie Scattering
      - 当空气中介质尺寸接近或大于光的波长的时候（气溶胶）：散射有一定方向性，更多散射在光的传播方向上；对波长不敏感
      - Mie Scattering Equation
        #fig("/public/assets/CG/GAMES104/2025-03-29-11-17-02.png")
        - 这里引入了一个 $g$ 参数，当它为零时等同于 Rayleigh Scattering；大于零时同图中“章鱼”形状；小于零时会往相反方向散射更多（不常用）
      - 借此可以解释雾（气溶胶）是无差别散射的白色，傍晚的光晕是有方向性的散射
  - Variant Air Molecules Absorption 光的吸收
    - 气体吸收不同波长的光，比如臭氧吸收红橙黄光，甲烷吸收红光
    - 计算也要考虑光的吸收，但实际过程中会假设这些气体均匀分布在整个大气中（实际上并不是，比如臭氧集中在大气上层）
  - Single Scattering vs Multiple Scattering
    - 类似 GI 中的直接光照与间接光照的区别。单次散射指实现方向所有点散射到相机方向的光线（以及过程中的 Transmittance 积分）的能量和，多次散射则不止考虑视线方向上的点（是现代 3A 游戏必须考虑的问题）
    - 但跟 GI 也有不同，GI 是对面上的多次弹射，而 Multiple Scattering 是作用于空间中连续不断的空气

== 实时大气渲染
- Ray Marching
  - 经典方法，沿着射线方向逐渐步进，需要考虑 step 大小，以及过程中的 Transmittance, Scattering
  - 无论是哪种大气效果，都是用 Ray Marching 来实现。其计算量的问题，通过用空间换时间来解决 (lookup table, LUT)
- *PreComputed Atmospheric Scattering*
  - Transmittance LUT
    - 把大气中任意一点到大气边缘的通透度表示为用两个参数描述的 LUT，直接读出 Transmittance
      + $th$: 视线和天顶的夹角
      + $h$: 海拔高度
    - 任意两点的通透度可以通过点到边缘值的除法得到
    #fig("/public/assets/CG/GAMES104/2025-03-29-11-52-57.png", width: 60%)
  - Single Scattering LUT
    - 考虑太阳方向，把大气中任意一点到大气边缘的光照表示为用四个参数描述的 LUT，直接读出光照
      + $eta$: 太阳方向和天顶的夹角，$cos$ 值记为 $mu_s$
      + $th$: 视线和天顶的夹角，$cos$ 值记为 $mu$
      + $phi$: 太阳方向和视线的夹角，$cos$ 值记为 $v$
      + $h$: 海拔高度
    - 将这个四维表存在 3D texture 中，方便中间高度采样
    #fig("/public/assets/CG/GAMES104/2025-03-29-12-00-30.png", width: 60%)
    - 左下角公式描述了一个细节，不止计算远处天空的颜色，远处物体的颜色也要加雾效。通过到大气边缘的能量与物体到大气边缘的能量（乘以通透度）作差得到
  - Multiple Scattering LUT
    - 通过 Transmittance LUT 和 Single Scattering LUT，可以计算出二次、三次以及更多次散射的 LUT 表
    - 形状上与 Single Scattering LUT 一模一样，但会亮一点，一般 $3 wave 4$ 次就足够
  - 总之，这种方法预计算时很复杂，但 runtime 可以做到实时；且由于是大气的预计算，不管是太阳变化、人物变化都没有问题
  - 但其缺点也很明显
    + 预计算消耗很大，尤其是在移动端（即使在 PC 端也要几毫秒甚至一秒，不过可以分散到加载关卡的多帧中）
    + 无法处理大气的动态环境调整，比如晴天到阴雨的过渡（每帧的表都要计算），同时艺术家编辑时调节参数也不方便
    + Runtime 实时处理时需要做很多逐像素的高维 LUT 表的插值（为了效率经常要下采样）
- *Production Friendly Quick Sky and Atmosphere Rendering*
  - 假设散射是低频的，且各向同性（不再从物理上考虑 Mie Scattering 的方向性），于是每级散射都是同样的百分比衰减，Multiple Scattering 变成等比数列
  - 这样极大加快了速度，可以进行每帧计算而不是预计算。此时，原方法 LUT 中的高度 $h$ 和太阳位置夹角都时刻重算，于是只用天顶角和方位角即可表示，化四维为二维
  - 如果再加上大气中沿着路径的透明度积分影响，就再加上一个相机距离的参数，形成一个 3D texture
  - 从而，太阳月亮、下雨晴天等情况都能表达，并且效率非常高，支持移动端。只有在空气散射度特别高、雾很浓的情况下，会有比较大的偏差，甚至有色偏

== 云的渲染
- 云的类型一般就是层云、积雨云、卷层云，还会随着高度变化
- *早期实现云的方式*
  + Mesh-Based Clod Modeling: mesh 硬做，辅以概率模型、noise、腐蚀算法，效率低且不动态，现在基本没人用了
  + Billboard Cloud: 半透明插片模拟，效率高但效果差
- *Volumetric Cloud Modeling*
  - 效果好、动态、真实，但计算量大（不过 3A 游戏都在用）
  - 思路：Weather Texture（形状分布，$0-1$ 值表示厚度） + 平移、扰动变形（Noise Functions，如棉絮状噪声的 Perlin Noise 和细胞结构状噪声的 Worley Noise，近似模拟分形的效果）
  - 具体实现：给定原始 weather texture 生成的云是柱状的，用低频 noise 进行边缘模糊化、腐蚀化，用高频噪声雕刻细节，涉及较多颜色加减的 hack
- *Rendering Cloud by Ray Marching*
  - 依旧是经典的 Ray Marching 方法，没打到云时用大步长，打到后用小步长，计算每一个点的通透度和散射
  - 云的通透度和散射计算跟大气不是一套体系，因为云通透度很低，比大气散射更简化，可以有更多假设
  - 总而言之，现代 3A 游戏中的云并不是一个个面片，而是存在 GPU 中的虚拟 3D texture，用 ray marching 的方法解析出来的结果。
  - 效果很美，虽然计算量较大，但属于现代游戏引擎的标配

== 雾效
- 时间上在下一节课，但内容上感觉放在这里更合适
- *Depth Fog*
  - 简单有效常用，在很多商业引擎内置 (e.g. Unity) 为默认设置
  - 通过深度图记录的深度来计算并施加雾效的 factor，分为 linear, exponential, exponential squared 三种
- *Height Fog*
  - 真实的雾是气溶胶，与高度相关，比如爬山时山脚有雾山顶没有的现象。Height Fog 假设高于某高度时开始呈 exp 衰减
  - 从高处看向低处 fog 内的物体时，沿途的 fog 对物体最终着色有影响，同时 fog 的分布也并非匀质，因此需要积分
  - 积分过程中，fog 对颜色的影响、眼睛和物体在高面以上或以下的情况会使其变复杂。一般就简化为对 fog 密度进行积分，由于是 exp 形式，所以能求出解析解
- *Voxel-besed Volumetric Fog*
  - 俗称*体积雾*，可以实现雾气的丁达尔效果、God Ray 效果等
  - 用类似 GAMES202 里讲的 Clustered Shading 的体素切分，以视锥非均匀划分体素，做到近处细远处粗
  - 工程实践时一般构建一个 3D texture 存储中间结果，其在 $x, y$ 方向的划分应该与屏幕分辨率成比例 (e.g. $16:9$)，而不是常用的 $2$ 的幂次方，方便显示的连续性
  - 具体计算方法跟之前讲的大气、云的渲染大同小异

= 游戏中渲染管线、后处理和其他的一切
== Ambient Occlusion 环境光遮蔽
- Precomputed AO
  - 烘焙出 AO 贴图，需要额外的存储空间，只能用于静态物体，应用非常广泛
- SSAO (Screen Space Ambient Occlusion)
  - 对每个像素以给定半径采样球内像素，计算 occlusion factor
  - SSAO+，把法向利用起来，把球改成半球
- HBAO (Horizon Based Ambient Occlusion)
  - 使用深度图作为 heightfield，用 Ray Marching 思想向周围探索最大仰角，将天顶可见范围作为可见性（采样点 $->$ 半球积分）。另外，通过一个 attenuation function 来截断远处的影响（只考虑局部）
  - 具体实现上有一些技巧，向四周采样的 step 和 direction 做了 random jitter
  - 问题：来自四面八方不同角度的光的贡献值是不一样的，类似 PBR 的 fresnel 项，这点在 SSAO, HBAO 中都没有考虑
- GTAO (GTAO: Ground Truth Ambient Occlusion)
  - 加入了 cosine factor，弥补了前述方法的不足；去掉了 attenuation function (?)；加入了 multi-bounce 的快速近似（真正实现了 color bleeding 的效果）
  - 如何近似：用机器学习的方式，将 multi-bounce 的结果与 AO 值的曲线拟合成一个仅仅 $3$ 阶的多项式方程
    - 这样的近似方法从结果上来看，跟大气渲染里面只算一次 bounce 但却能 approximate 出多次 bounce 的方法类似
    - 同时这种近似方法背后是否有原理呢？原论文没有理论证明，但其实是有理论基础的。类似于我们在 microfacet 模型 $G$ 项中用一个 roughness 来近似几何的不平整度。即原始的精确计算可能是复杂的积分，但从统计学分布上可以用简单的多项式去拟合
  - 总之，名字取得非常霸气，工业上也用得很多
- Ray Tracing Ambient Occlusion
  - 从屏幕每个像素 cast ray 判定遮挡，使用 RTT 硬件和 TAA 思路加速，一般远处 $1$ SPP (sample per-pixel)，近处细节 $2 wave 4$ SPP
  - Ray Tracing 是 AO 的真正未来方向。GAMES202 里面讲了 SSR 方法，可以在屏幕空间模拟 Ray Tracing 的效果，也可以真正地使用 RTRT 辅以去噪来实现

== Anti-Aliasing 抗锯齿
- SSAA (Super Sampling Anti-Aliasing)
  - 通过多重采样来实现抗锯齿，简单粗暴，但开销大
- MSAA (Multi Sampling Anti-Aliasing)
  - 先采样深度判断是否为边缘，边缘再多倍 shading
- FXAA (Fast Approximate Anti-Aliasing)
  - 不采用增大采样率的做法，而是以 CV 的方式后处理，通过模糊边缘来实现抗锯齿，简单高效，但模糊问题较严重
  - 效果好速度快很实用，现代显卡一般集成了
- TAA (Temporal Anti-Aliasing)
  - 详见 GAMES202，目前游戏引擎主流算法，但会有一系列 temporal 问题

== 后处理
- 后处理就是“美颜相机”（滤镜），一般有两类目的：1. 让物理更加真实正确；2. 风格化表达。下面介绍三类最常用的效果
- Bloom 泛光
  - 游戏中看到霓虹灯、强光刺眼的光晕效果
  - 现实世界中的 bloom 是因为人眼和相机一样不能完美的聚焦到一个焦平面上，会产生一种发散；另一种解释是人眼晶状体是一种半透明材质，光线进入会产生散射
  - 实现过程
    + 计算 RGB 对应的 luminance，看是否超过阈值（阈值一般是个 magic number，或开启 HDR 后使用平均光场亮度）
    + 降采样几层（减小后续 filter kernel 大小）
    + 从最底层开始每一层高斯模糊到上一层大小 (Blur Up)，然后叠加
- Tone Mapping 曝光调整
  - 跟 HDR 相关，曝光时间导致图像部分过亮部分过暗，需要 Tone Mapping 调整曝光曲线，把 HDR 的图片信息映射到普通 LDR /SDR 显示器上
  - 可以用的曲线有很多，但基本都类似 Sigmoid 那种 S 形，这方面比较常用的有 Filmic S-Curve, ACES
- Color Grading 调色
  - 就是一个转换图像颜色空间从而调整色彩的映射，一般用一个 LUT 来做。例如，一个 $256^3$ 的 LUT，每个格子对应一个颜色。当然实际上由于颜色的连续性可以以更小的 LUT 用插值实现
  - 简单但非常常用，美术只需要调色板而不需要去 p 图，算是游戏引擎编辑器必须要实现的功能之一，性价比极高

== Rendering Pipeline
- *Forward Rendering*
  - 最原始的渲染管线：Shadow Pass $->$ Shading Pass $->$ Post-Processing Pass
  - 问题
    + 透明度排序，需要从远到近绘制，有时物体由于交叉而无法排序，需要顺序无关半透明算法（可以参考 #link("https://blog.csdn.net/qq_35312463/article/details/115827894")[vulkan\_顺序无关的半透明混合 (OIT)]
    + 难以处理 Multiple Light
  - Forward Rendering 结合后面的 Tile-Based Rendering 叫做 Forward+，算是 CG 行业的黑话
- *Deferred Rendering*
  - 第一个 pass 先渲染 GBuffer 而不做实际着色，第二个 pass 再遍历所有像素以及所有光源进行着色
  - 好处是，只会在 visible fragments 上计算着色（跟 Early-Z 一样），同时真正着色时 GBuffer 的信息利用起来更方便也更好 debug
  - 问题
    + 需要大量的内存来存储 GBuffer，带宽也是个问题（尤其是移动端）
    + 透明物体处理困难
    + 不支持 MSAA（参考 #link("https://zhuanlan.zhihu.com/p/135444145")[延迟渲染与 MSAA 的那些事]）
- Tile-Based Rendering & Cluster-Based Rendering
  - GAMES202 里讲过
- *Visibility Buffer*
  - GBuffer 实际上是把几何与材质一起存下来，而 VBuffer 把几何与材质解耦，只存储几何信息，可以用来反向查找对应材质信息
    - GBuffer: Depth, Normal, Albedo, Roughness, etc.
    - VBuffer: Depth, Primitive ID, Barycentrics
  - 为什么要这么做呢？有下面几个原因
    + GBuffer 存储占用大，这个很好理解
    + GBuffer 希望将可见性与着色相分离，但实际上并不彻底！GBuffer 存储纹理信息需要大量采样的着色工作并没有被推迟，导致 overdraw 的浪费（而尤其是现代游戏中几何密度高到甚至超过像素，这个问题就更严重）
    + 可见性与着色分离不彻底的另一个潜在问题是，立即采样材质要求 drawcall 必须按材质进行批处理 (batching)，从而丧失了更有效地调度工作负载的机会
    + 此外，GBuffer 难以支持 MSAA，而 VBuffer 由于有了 Primitive ID 和 Barycentrics 且占用更小使其变为可能
  - 不过，这样一个全新、激进的渲染技术可能会导致对应 shader、texture、美术制作流程等需要发生重大变化，需要再走一次 forward rendering 到 deferred rendering 的革命。但是，依旧可以相信它是一个美好的未来

== 其它
- *游戏引擎中的挑战*
  + 不同模块相当于积木，如何把它们有机地组合在一起以应对不同的复杂项目
  + 很多计算需要消耗的 buffer 内存的时间远小于一帧（例如中间值），应该被马上释放，但没有精密的内存管理时很多显存会被浪费。而 pipeline 越复杂就越难以管理
  + 新一代图形 API 比如 Vulkan, DX12，开放了硬件算力、内存管理等 low level 内容
- *Frame Graph / Render Graph*
  - 将管线里的模块分为不同的 Frame Graph，然后利用一个有向无环图 (DAG) 自动检测所用资源之间的相关性并优化
  - 比如 Unity 的 URP 和 HDRP，其底层都是基于 SRP，这个就是非常好的实践
  - 个人认为，从 DL 那边的经验来看，这种自动计算图的框架性质的东西必然是未来的方向，但目前还不太成熟，大家还在探索
- *Render to Monitor: V-Sync、G-Sync*
  - 显示器刷新频率是一定的，但 GPU 渲染频率会随场景复杂程度变化。如果显示器刷新时 GPU 正好写到一般，就会出现屏幕撕裂 (Screen Tearing) 的现象
  - V-Sync：保证每个 framebuffer 全部写完后再整个刷新上去，但也会带来刷新率降低、操作延迟、画面时快时慢的问题
  - Variable Refresh Rate: 显示器刷新率根据 GPU 渲染频率动态调整，支持这种功能的显示器可以开 G-Sync 或 FreeSync 功能，相比 V-Sync 延迟会小很多
  #q[这里可以看一些有关帧数的深度科普 #link("https://www.bilibili.com/opus/243701426539479343")[帧与时间 论 FPS 游戏相关的性能参数]、#link("https://www.yystv.cn/p/12110")[将游戏机制和帧数绑定，给玩家们制造了多少的乐子与麻烦？]]

= 游戏引擎的动画技术基础
- 这部分之前看过且简单归纳过，只再看一遍，不记笔记了

== 2D 游戏动画技术
- 精灵动画 (sprite animation)
  - 把游戏人物的动画一帧一帧记录下来，然后循环播放
- Live2D
  - 把角色的各个部件拆成一个个小图元，通过图元的旋转、变形使角色变得鲜活，并且需要给各种图元设置深度来表达层级关系

== 3D 游戏动画技术
- *基于层次的刚体动画 Rigid Hierarchy Animation*
  - 早期动画实现方式，将角色用一系列的刚体块表示，用关节点约束
  - 把刚体用作骨骼，动的时候 mesh 会互相穿插
- *顶点动画 Vertex Animation*
  - 将每个顶点的复杂物理计算结果按照时间帧保存到一张纹理上（预烘焙），一个轴表示每个顶点，另一个轴表示不同时间该顶点的偏移量
  - 一般会存两个 texture，一个存位置，一个存法向
- *变形目标动画 Morph Target Animation*
  - 顶点动画的变种，把一系列 key frame 存下来，LERP 出想要的动画，通常用于面部
- *蒙皮动画 Skinning Animation*
  - 骨骼驱动顶点，每个顶点可能有不止一个骨骼驱动，可以避免 mesh 穿插，同时消耗也比逐顶点小
  - 2D 有时也用骨骼蒙皮动画
- *基于物理的动画 Physics-based Animation*
  - Ragdoll 布娃娃系统
  - 布料和流体模拟
  - Inverse Kinematics (IK) 反向动力学

== 蒙皮动画的实现
- *Animation DCC (Digital Content Creating) Process*
  + Mesh：网格一般分为四个 Stage: Blockout, Highpoly, Lowpoly, Texture。这里一般会制作固定姿势的 mesh (T-pose / A-pose)，把高精度的 mesh 转化为低精度，有时还会为肘关节添加额外的细节来优化
  + Skeleton binding：在工具的帮助下创建一个跟 mesh 匹配的 skeleton，绑定上跟 game play 相关的 joint
  + Skinning：在工具的帮助下通过权重绘制，将骨骼和 mesh 结合起来
  + Animation creation：将骨骼设置为所需姿势，做关键帧，之后插值出中间动画
  + Exporting：一般把 mesh, skeleton, skinning data, animation clip 等统一导出为 `.fbx` 文件。一些细节上的处理比如跳跃动画的 root 位移不会存下来而是用专门的位移曲线来记录
  #fig("/public/assets/AI/Human/2024-11-02-19-54-23.png", width: 50%)
- *骨骼的构建与绑定*
  - 三种 space：Local, Model, World
  - 通用骨骼标准：人形的有 Humannoid，骨骼起点在跨部，root 在两脚之间；四足动物有另外标准，骨骼起点一般在尾椎，root 在四足之间
  - 骨骼的绑定，利用叫做 mount 的关节。例如人骑在马上，不仅位置连接，方向也要绑死
- *3D 旋转的数学原理*
  - 2D 旋转
  - 3D 旋转之欧拉角 (Euler Angle)
    - Yaw, Pitch, Roll
    - 问题：旋转顺序依赖、万向节死锁问题、插值和叠加问题、不便表达任意轴旋转
  - 3D 旋转之四元数 (Quaternion)
- *骨骼 pose 的三个维度*
  + Orientation: 一般只需要 Rotation 即可表达骨骼链的位置
  + Position: 但某些情况也要用到位移，比如 root 表达的位置、人脸骨骼等
  + Scale: 一般只用于面部表达
  #fig("/public/assets/CG/GAMES104/2025-03-30-15-02-00.png", width: 60%)
  - 蒙皮动画只保存顶点相对骨骼 local space 最终的 Affine Matrix，以及骨骼权重
- *动画片段与插值*
  - 动画资产一般是十几二十帧，远小于实际游戏帧率，需要应用时插值
    - 注意是同一个 clip 内不同 pose / frame 之间的插值，后面会涉及到 clips 之间的插值，称为 blend
  - 针对位移和缩放，一般直接线性插值即可
  - 针对旋转
    - 反向插值：角度超过 $180°$ 时变换相乘结果小于 $0$，需要反向插值
    - 球面线性插值 (Slerp)：四元数线性插值后取 normalize，避免长度发生变化\
    - 均匀球面插值 (Slerp)：改进四元数插值不均匀的问题（头尾快中间慢）。但计算稍贵且分母 $sin$ 值小可能不稳定，实践中一般跟 Slerp 结合（$th$ 小用前者，$th$ 大用后者）

== 动画压缩技术
- *DoF Reduction*
  - 对大部分骨骼而言，translation 和 scale 不怎么变化，可以直接去掉
- *Keyframe Reduction*
  - 针对旋转，比较简单的方法是使用 Key Frame 然后插值（用步进的方法，每当误差超过一定阈值则设为关键帧并回退，因此关键帧间隔不固定）
  - Catmull-Rom Spline，类似贝塞尔曲线，在 $P_1, P_2$ 之外再取 $P_0, P_3$ 来拟合，缓解插值出来都是笔直折线的问题
- *Size Reduction*
  - 四元数很多时候不需要 $32bit$ 浮点数精度，可以将数值压缩到 $0 wave 1$ 之间然后乘以 $65535$ 用 $16bit$ unsigned integer 表示
  - 且利用 normalization 的特性，取四个值中最大的并用 $2bit$ 指示（通过 $1$ 减去剩下三个值得到），剩下的三个值均在 $[-sqrt(2)/2, sqrt(2)/2]$ 之间，各用 $15bits$ 来表示，总共用 $47bits (-> 48bits)$ 表示原本 $128bits$ 的四元数
- *压缩误差*
  - 骨骼使用从起点局部定义到叶节点的方法，压缩误差不断累积，需要有方法进行*量化*并反向偏移来补偿（但也会导致新的抖动问题）
  - 最简单的方法自然是对 Translation, Rotation, Scale 施加 L1 / L2 的 loss，但不同骨骼对误差敏感度不同，且不符合人眼感受
  - 实际可用的是视觉误差 Visual Error，对每个关节定义两个 Fake Vertex，通过 offset 控制距离，如果精度敏感就设置大一些，只需对比这两个点压缩前后的误差

= 高级动画技术：动画树、IK 和表情动画
== 动画混合
- *混合中的数学 —— 线性插值*
  - 动画 blend 需要在不同 clip 之间线性插值，需要一个权重表示比例。以跑步为例，用当前速度和步行 clip 的速度、跑步 clip 的速度计算权重即可
  - 对齐混合时间线，blend 需要每个动画循环播放，因此时间线必须一致。比如跑步和走路要左右脚各一次循环，脚的落地时间一致（跑 $1.5s$、走 $3s$）。插值时从 clip1, clip2 对应帧取 pose
- *混合空间 Blend Space*
  - 1D Blend Space
    - 以走路为例，在直走、向左以及向右等多个 clips 中插值，变量只有移动方向因此为一维混合
    - 但采样点可以有多个，插值也不一定是线性、均匀的
  - 2D Blend Space
    - 依旧以走路为例，如果除了角度，行走速度也可以变化，就成为二维混合空间
    - *Delaunay Triangulation 三角网格化*
      - clip 在空间中的分布往往是非均匀的（以走路为例，侧向行走时速度超过一个较低阈值马上就会进入跑步，否则无法保持平衡）。另一个问题是 clip 之间的插值成本较高，我们不希望由于分布的非均匀性导致某个点需要在很多个 clips 之间插值
      - 德劳内三角化方法把 clips 化成不同三角形，根据点在某个三角形内的重心坐标进行插值，限制插值的 clips 数量
- *Skeleton Masked Blending 骨骼遮罩混合*
  - 很多动画值影响局部，可以用 blend mask 遮住无关部分。从而可以做上下半身动画的同时播放，还能减少 blend 计算量
- *Addictive Blending*
  - 使用一个差值形成的 difference clip，直接加在其它 clip 上，如加上旋转或缩放
  - 使用和制作需要谨慎，因为随意增加差值容易带来人体超自然扭曲问题

== 动画状态机与混合树 Animation State Machine and Blend Tree
- 一些动画之间存在逻辑关系、顺序关系而不能任意插值，比如 jump 分为“起跳”、“滞空”、“落地”三个部分，这时自然要引入动画状态机
- 下面的部分主要是以 UE 的实现为例（因为做得比较好，自由灵活且交互符合直觉）；Unity 也有类似实现如 Animator Controller，但设计上不够方便，而新兴的 playable API 还不够成熟
- *动画状态机 Animation State Machine (ASM)*
  - 包含 node 和 transition
  - node 可以是单个 clip，也可以是一整个 blend space 打包成的节点（比如 UE 的一整个动画蓝图），总之是一个可以循环的 state
  - transition 是两个 node 之间的连接，涉及如何 blend 以及触发条件的问题
    - transition 的时间，一般是一个 magic number $0.2s$
    - transition cross fades，一般有两种方式 —— 常规 smooth transition 和 frozen transition
      - 实现上一般用不同的 cross fade curves，最常用的就是 linear 和 ease in out
- *Layered ASM*
  - 把角色的不同部位分成不同的状态机来管理，从而让整个动画看起来更灵活流畅
  - 如 Devil May 5，角色上半身进行复杂攻击，下半身跑跳，还有一层受击反应
- *动画混合树 Animation Blend Tree*
  - 其思想最初来源于表达式树，从一个 output 节点单向展开，不同 clip 之间做 “四则运算”
  - 叶子节点可以是 Clip / Blend Space / ASM，是一个递归的结构
  - 非叶节点是 blend node，可以做很多灵活操作
    + Lerp: 二通道、多通道等
    + Masked Add: 实现上面的 Layered ASM
    + Addictive Add: 实现上面的 Addictive Blending
  - 动画树的核心作用是*控制变量* (control parameters)，暴露给外面的 GamePlay 系统来控制决定动画的混合行为以及最终的动画展现
    - 变量有两种，一种是速度体力血量等环境变量，一种是根据 event 事件触发调整的变量（类似 private data）
    - 引擎中有大量专门的计算结构根据这些变量来计算每个 blend 的百分比

== Inverse Kinematics 反向动力学
- *FK and IK*
  - 前述根据骨骼运动驱动 mesh 的方法属于正向动力学 (Forward Kinematics)，而 IK 则是要求 mesh 最终要达到的位置，反解出过程中的运动
  - 典型例子比如用手抓把手或者走在不平的地上，这时的约束点被称为末端效果器 End Effector
#grid(
  columns: (80%, 30%),
  column-gutter: 1em,
  [
- *Two Bones IK*
  - 走路时，大腿、小腿长度 $a, b$ 固定（所以其实是 $3$ 个关节点，两个刚体骨骼），如果确定了脚踩阶梯的位置，跨部到阶梯的距离 $c$ 也可计算，于是可以确定大腿抬起的角度 $th$
  - 但由于这样求解本质是两个球的交点，解是一个圆环（可能会内八或外八），此时需要美术提供一个参考方向 reference vector 找到唯一解
- *Multi-Joint IK*
  - 实际情况中 IK 远比 Two Bones 复杂，主要有两个难点
    + 自由度太高，计算花费高：需要实时计算高维非线性（包括旋转、平移、放缩）方程的解
    + 解有无穷多个：确定了首尾两个目标点，中间的关节点可以随意移动
  - 在解 IK 之前，很重要的一点是判断可达性 (Reachability)，不能达到分两种情况：
    + （太远）所有关节的长度加起来也达不到目标点
    + （太近）全身最长的骨骼比其他骨骼的长度加起来都大，即近处盲区
  - 以及 Multi-Joint IK 还有个难点是人体骨骼种类与旋转的多样性
    - Hinge, Ball-and-socket, Pivot, Saddle, Condyloid, Gliding
    - 例如，手指指节是 hinge joint，只能往手心转且旋转角度有限。错误的处理会导致很离谱的扭曲
  - 于是我们常常使用启发式算法求近似解，不追求全局最优，且常常利用迭代法
  ],
  image("/public/assets/CG/GAMES104/2025-03-30-19-59-05.png", width: 50%),
)
- *CCD (Cyclic Coordinate Decent)*
  - 在 orientation space 上求解，从最末端节点开始向父节点依次遍历，每次尽可能旋转使其离目标点最近（到达该节点与目标点连线），多次迭代得到一个近似解。如果超过设定迭代次数还没有收敛，就认为不可达
  - 优化
    + 限制每次旋转角度 (within tolerance regions)，避免一开始就转得太多（造成类似于 “头过去了但腰还笔直杵在原地” 的非自然情况），让整个旋转尽量均摊到每个关节上
    + 让越靠近根节点的关节旋转角度越小（这两点其实都有点类似机器学习中的学习率）
- *FABRIK (Forward and Backward Reaching Inverse Kinematics)*
  - 在 position space 上求解，具体步骤
    + Forward: 首先将最末端节点强行拉到目标位置。这时骨骼变长，不管，把它拉到末端节点和父节点连线上，表现为戳出去一段长度；随后把父节点移动到骨骼拉长后的位置，导致它跟父节点相连的骨骼也变长……以此类推（也可能不是变长而是变短，anyway，一个意思）
    + Backward: 反向迭代，从根节点开始移回原位置，也会造成骨骼长度变化的连锁反应
    + 多次重复 forward, backward 迭代，直到收敛。如果超过设定迭代次数还没有收敛，就认为不可达
  - FABRIK 也能添加约束：骨骼垂直于 target 形成一个平面，与 range of rotation 形成交点，作为 reposition target
- *IK with Multiple End-Effectors*
  - 前面只考虑了单一约束点（末端约束），但实际应用中如《塞尔达传说：荒野之息》中的爬墙，双手双脚都被约束。此时，视图把一个点移到目标点可能导致其它已经就位的节点又偏移开。在 CCD, FABRIK 中有对应多 constraint 的解决办法，但并非最优解
  - 比较推荐的解法是把关节点的位置和目标位置视作一个向量方程，*用 Jacobian Matrix 以类似梯度下降的方式*求解
    - 即每次从当前点往 Jacobian 的方向（梯度方向）走一小步，一次次迭代 hit 到目标点
    - 算是多约束 IK 在游戏引擎中的标准解法，但计算量稍大，因此也有不少优化
    - 在后续物理系统会详细介绍
- *Other IK Solutions*
  - Physics-based Method：更自然，但计算量大
  - PBD (Position Base Dynamics): 和传统的基于物理的方法不同，有更好的视觉表现，以及更低的计算花费。UE5 中的 Fullbody IK 就是 XPBD (Extended PBD)
- *IK Still in Challenge*
  + IK 假设关节是一个个点，骨骼是一条条线段，都没有体积，但实际上在蒙皮之后可能出现重叠、穿插等问题
  + IK with predication 很难做。比如人物移动中弯腰躲避障碍，不可能是撞到了才变化而是提前预知。目前游戏中这种自然的变化都是动画师预先设计好的
  + 更自然的人类行为很难做，如中心平衡、支撑等，可能需要 data-driven、深度学习的介入
- 考虑 IK 后的动画制作 pipeline，在 Post-Processing 中让动画符合环境的约束
  #fig("/public/assets/CG/GAMES104/2025-03-30-22-17-41.png", width: 60%)

== 面部动画
- Morph Target Animation
  - Facial Action Coding System
  - UV Texture Facial Animation
  - Muscle Model Animation
  - 行业天花板是 UE 的 MetaHuman

== 动画重定向 Retargeting
- 现在大多数动画都采用动捕来获取，很自然地我会希望采集到的动画能应用到不同高矮胖瘦的角色上
- 先介绍一些术语 (terminology)：
  + Source Character 原角色
  + Target Character 目标角色
  + Source Animation 原角色动画
  + Target Animation 目标动画
- *同标准骨骼结构*
  - 骨骼结构相同但蒙皮后高矮胖瘦甚至静息 A-Pose 下的倾向不同
  - 基本操作是将它们的骨骼无视具体长短一一对应，然后按 rotation, translation, scale 不同 track 分别处理
    + 对于骨骼的 rotation，需要注意只能 apply 相对角度（如果存的不是 local space 下的数据需要做一步转换）
    + 对于骨骼的 translation，会考虑两个骨骼的相对长度，然后按照长度进行等比例进行的改变
      - 这里还有一些细节。比如对于角色的移动，需要根据角色离地高度不同做适当调整，一般一角色腰线高度为准，并且位移速度也会以此适当缩放
    + 对于骨骼的 scale，也是进行比例改变
  - 还有一些特殊情况会用 IK 来解决
    - 比如总腿长一致但大小腿长度不同的角色，移动可能没什么问题（其实也会不自然），但蹲下就可能浮空或嵌地。用 IK 把脚锁在地面上可以解决该问题
    - 但一般角色会 offline 做好 retargeting，因此问题不算太大
  - 最后的最后，如果还不行，就辛苦美术手动调整一下吧
- *不同标准骨骼重定向*
  - NVIDIA 的 Omniverse: 使用骨骼映射的方法，非常符合直觉。先把找到名字相同的 shared skeleton，把它们的长度归一化；随后针对 target 骨骼，去找每个骨骼对应 source 的位置，并适当调整。最终形成虽然不一一对应，但大致位置形状类似的结果
    #fig("/public/assets/CG/GAMES104/2025-03-30-22-51-56.png", width: 80%)
  - 此外还可能有一些涉及深度学习的方法
- *动画重定向的挑战*
  + IK 那里提到的自穿插、重叠问题，以及自然行为问题
  + 自接触约束，比如两个角色动作相同，但由于肩宽问题导致鼓掌时无法碰到一起
  + 面部表情领域使用 Morph Animation 也要做 retargeting，此时也有比如小眼睛闭眼动画到大眼睛模型上就闭不上眼的问题，这时可以利用拉普拉斯算子模拟橡皮表面把顶点拉到闭合

= 游戏引擎中物理系统的基础理论和算法
- 物理系统对游戏引擎的重要性无需多言，这里另外推荐几篇文章
  + #link("https://www.zhihu.com/question/43616312")[为什么很少有游戏支持场景破坏？是因为技术问题吗？]
  + #link("https://www.bilibili.com/opus/573944313792790732")[如何创造《彩虹六号：围攻》的破坏系统？]

== 物理对象与形状
- *Actor 对象*
  - Actor 是游戏引擎物理对象的基本单元（注意跟角色动画的那个 actor 不是一个概念），一般分为以下四类
    + Static Actor 静态物体：不懂的物体，如地面、墙壁等
    + Dynamic Actor 动态物体：专指符合动力学原理的动态物体，可能受到力 / 扭矩 / 冲量的影响，如 NPC 等
    + Trigger Actor 触发器：与 GamePlay 高度相关的触发开关，如自动门、传送门等
    + Kinematic Actor 运动物体：专指不符合动力学原理的动态物体，根据游戏的需要由游戏逻辑控制，但反物理的表现经常出现 bug，因此需要谨慎使用
  - 分组能够很大程度上减少需要运算的数量，后面还会提到 sleeping 的概念，让一段时间不动的物体进入休眠状态
- *Actor Shape 对象形状*
  - 游戏中往往会用简单形状的物理对象来替代表达实际渲染的复杂物体，常见形状有：
    + Sphere 球：最简单的形状，适用于各种类球形物体
    + Capsule 胶囊：碰撞体积小且计算量小，适用于人形角色
    + Box 立方体：适用于各种建筑家具等
    + Convex Mesh 凸包：精细一点的物体比如岩石
    + Triangle Mesh 三角形网格：适用于精细一点的建筑等
    + Height Field 高度场：适用于地形，一般只会有一个
  - 用简单几何体模拟物理对象有两个原则：
    + 形状近似即可，不用完美贴合
    + 几何形状越简单越好（尽量避免 triangle mesh），数量越少越好

== 力与运动
- *一些物理概念*
  + 质量和密度 Mass and Density：往往取其一即可
  + 质心 Center of Mass：在做载具时很重要
  + 摩擦和恢复（弹性） Friction and Restitution
  + 力 Forces：有直接的拉力、重力、摩擦力，也有冲量 impulse
  + 牛顿定侓 Newton's Laws
  + 刚体动力学 Rigid Body Dynamics：在部分场景下非常重要，如台球游戏
- *欧拉法*
  - 显式欧拉法 Explicit (Forward) Euler's Method
    - 与积分直觉最接近的算法，下一时间的速度和位置都用上一时间的量计算
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t0) De t,
        x(t1) = x(t0) + v(t0) De t
      ) $
    - 用当前状态值去预估未来状态，$De t$ 并非无限小导致误差积累而能量不守恒（能量爆炸）
  - 隐式欧拉法 Implicit (Backward) Euler's Method
    - 用下一时间的速度和位置来计算当前时间的量
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t1) De t,
        x(t1) = x(t0) + v(t1) De t
      ) $
    - $De t$ 也并非无限小导致能量不守恒（能量衰减），但至少衰减是符合物理规律的（空气阻力、摩擦力等），因此在游戏中相对更容易接受
  - 半隐式欧拉法 Semi-Implicit Euler's Method
    - 结合前两种方法，新速度用旧的力去算，新位置用新速度算。暗含了力不随位置改变的假设（很危险的假设，在比如橡皮筋弹射的情形完全错误）
      $ cases(
        v(t1) = v(t0) + M^(-1) F(t0) De t,
        x(t1) = x(t0) + v(t1) De t
      ) $
    - 它的优点是大部分时候稳定、计算简单有效、随着时间的推移能够保存能量；缺点是在做一些 $sin, cos$ 相关运动时，积分出的周期会比正确值长一点点，在相位上会有偏移差

== 碰撞检测
- 碰撞检测一般分为两个阶段
  + *Broad phase 初筛* —— 快速判断是否相交，过滤大部分物体，一般简化为 AABB (Axis-Aligned Bounding Box)，常用两种算法：
    + BVH Tree: 动态更新成本低，方法成熟
    + Sort and Sweep: 比 BVH 更快，先沿轴把每个静态物体的 AABB 边界大小值排序，再沿着每个轴逐个扫描，如果 minmax 没按顺序出现则有可能发生碰撞。静态物体排序好后可以只插入排序更新动态物体，因此效率高
  + *Narrow phase 细筛* —— 详细计算碰撞并给出信息（碰撞点、方向、深度等）
- *Narrow phase Methods*
  - Basic Shape Intersection Test: 对于球、胶囊体这样简单的形状，可以直接判断距离和半径大小来判定是否相交
  - Minkowski Difference-based Methods
    - 利用闵可夫斯基距离，将 “两个多边形是否相交” 问题转换为 “一个多边形是否过原点” 问题
    - GJK (Gilbert-Johnson-Keerthi) 算法
      - 可以参考这篇文章 #link("https://zhuanlan.zhihu.com/p/511164248")[碰撞检测算法之 GJK 算法]
      - 总之是类似牛顿迭代法，逐步往原点方向逼近的思想
    - SAT (Separating Axis Theorem) 算法
      - 2D 空间中，如果两个物体分离，肯定能找到一根轴把它们分隔开，不然就是相交。因此可以在两个多边形的边上进行穷举计算，把两个凸包的每条边当做分隔线试试，看另一个凸包的所有顶点是否在同侧
      - 推广到 3D 空间，则是穷举所有面，还需要额外穷举两个物体的边叉乘形成的面

== 碰撞解决
- 检测到碰撞后需要将碰撞物体分开，最简单的早期办法是直接加一个 Penalty Force，但有时会导致物体突然炸开
  #fig("/public/assets/CG/GAMES104/2025-04-01-11-17-55.png", width: 60%)
- 现代引擎比较流行的方法是把力学问题变成数学上的*约束问题*，利用拉格朗日力学对速度进行约束。解约束的常用办法有：
  + Sequential impulses 顺序推力
  + Semi-implicit integration 半隐式积分
  + Non-linear Gauss-Seidel Method: 现代物理引擎最常用，快速且对大部分情形稳定。给碰撞物体加个小冲量来影响速度，看此时是不是还碰撞（是否符合拉格朗日约束），不断重复直到误差可以接受或者迭代次数超过设定
  #fig("/public/assets/CG/GAMES104/2025-04-01-11-18-03.png", width: 60%)

== 杂项
- *场景请求 Scene Queries*
  - 游戏引擎中物理系统的一个重要组成部分，场景来 query 物理系统以获取一些信息
  - Raycast: 打出一条射线来判断是否与其他物体相交，有 $3$ 种返回情况
    + Multiple hits: 返回所有打中物体
    + Closest hit: 返回打中的最近的物体
    + Any hit: 打中就返回，不关心具体打中的信息（最快）
  - Sweep: 对 box, sphere, capsule and convex 等形状进行扫描判断
  - Overlap: 对 box, sphere, capsule and convex 等特定形状包围的区域查询是否有物体交叠
- *Efficiency*
  - Collision Group & Sleeping
- *Accuracy*
  - Continuous Collision Detection (CCD)
    - 物体快速运动时碰到一个比较薄的物体，如果在前后两帧都没有检测到，就穿出物体，也叫 Tunneling Problem
    - 最朴素的方法就是把物体做得厚一些，没办法的情况下使用 Time-of-Impact (TOI) 方法进行保守前进 (Conservative advancement)：物体在环境中先计算一个安全移动距离，在此范围内随便移动，但在靠近碰撞物体时，把碰撞检测计算频率增加
- *Determinism*
  - 物理引擎非常重要的难点，在不同帧率、硬件端侧、计算顺序、计算精度下结果都会大不一样。目前即使是商业物理引擎也难以做到在不同硬件上结果一直，需要大量处理来保持逻辑一致性
  - 对于 online 游戏，如果能做到 determinism，就不需要同步很多中间状态，只需同步输入即可

= 物理系统的高级应用
== Character Controller
- Character Controller 不同于普通的 Dynamic Actor，它其实是反物理的，与 Kinematic Actor 很像，比如：
  + 可控的刚体间交互，比如飞来物体可能无法撞飞我
  + 摩擦力假设为无穷大，可以站停在位置上
  + 几乎瞬时的加速、减速、转向，甚至可以传送（比如林克相比不死人、褪色者的性能简直强到离谱）
- 角色控制器的创建
  - 因此 Character Controller 一般用一个 Kinematic Actor 包起来即可
  - 人形角色可以用 Capsule, Box, Convex，其中 Capsule 是最常见的。
    - 很多游戏中会使用双层 capsule，内层用于碰撞计算，外层用作 “保护膜”，避免角色离其他东西太近。例如角色高速运动卡到墙里、或是相机近平面卡到墙后
- 角色与环境的交互
  + Sliding: 角色与墙发生碰撞时，不该停下来，而是沿着墙的切线滑动
  + Auto stepping: 游戏世界不全是连续的，遇到台阶时可能需要先往上抬一点再往前移动
  + Slope limit: 坡度过高时角色无法走上去而是往下滑，在支持攀岩的游戏中则是转化为攀爬
  + Volume update: 角色蹲起、趴下时，对应的碰撞体积也要修改，并且在更新之前要做 overlap 测试，避免动作切换时角色卡墙
  + Push Objects: 角色碰到 Dynamic Actor 时触发回调函数，根据角色的速度、质量等计算出冲量去推动物体
  + Moving Platform: 站在移动平台上时，通过 raycast 检测并在逻辑上把 controller 和平台绑定在一起（除非要进行更高标准精细计算），从而防止平台水平移动或角色跳跃时两者脱钩（没有惯性），或者平台上下移动而角色上下抽动
  - 总的来说，这一部分的实现并不困难但很细节，要想做得真实需要大量设计

== Ragdoll 布娃娃系统
- 为什么需要布娃娃系统？
  - 当角色死亡或昏迷时，其形体最好用物理模拟来表现，而不是纯用动画。举个栗子，当角色被刺杀并播放死亡动画后，应该顺着重力倒下，并且如果身在斜坡或悬崖应该掉下去（与环境互动）
  - 如果纯用动画，则工作量大且有些时候不自然。一般来说我们会将二者结合使用
- 布娃娃系统具体实现
  - 将原本人体的 skeleton 映射成 ragdoll 的 skeleton（也是一系列 joints），一般为了减少计算会减少至十几个，相互之间用 rigid body 连接
  - 需要对这些 joints 施加合适的 constraints，仔细调整 rigid bodies 的形状，形成合理的转变动作，一般由 TA 完成
  - 一般骨骼分为以下三种
    + Active joints: ragdoll 和原本骨骼共有，直接用原骨骼变化
    + Intermediate joints: ragdoll 新生成的中间骨骼，这一过程类似于不同骨骼类型的 retargeting，也需要进行等比缩放、插值等处理
    + Leaf joints: 不由 ragdoll 接管的在刚体尽头外未被覆盖的原骨骼，保持其动画设定跟着其父节点变化
- 混合动画和布娃娃系统
  - 一般在角色死亡后会进行从动画转到由 ragdoll 接管的过程，从而结合二者，需要考虑这个变化的边界和权值
  - 而更高级的做法是相互 blend 使用，把动画的状态作为物理系统的初始输入计算，把物理的盐酸结果叠加回动画（类似于在物理解算中支持骨骼蒙皮动画）

== Cloth Simulation 布料模拟
- *Animation-based Cloth Simulation*
  - 给布料添加骨骼，使用骨骼动画驱动布料顶点
  - 优点是廉价可控，移动端常用（提一嘴，《原神》这种卖角色的游戏在布料动画模拟上做得挺不错）；缺点是不够真实、和环境没有交互以及设计上受限
- *Rigid Body-based Cloth Simulation*
  - 同样给布料添加骨骼，但不由动画而是由物理引擎驱动（加约束并物理解算）
  - 优点是廉价有交互；缺点是效果一般，美术工作量大，不够鲁棒，且对物理引擎的性能要求相对高
- *Mesh-based Cloth Simulation*
  - Physical Mesh: 物理模拟所用的网格自然不会是 Render Mesh 那么精细，一般会稀疏很多，面数在十分之一左右。精细顶点的运动可以通过 barycentrics 插值得到
  - Cloth Simulation Constraints: 需要对移动范围做个约束（需要美术刷权重）。比如披风，越靠近肩膀范围越小，更符合物理实际，且可以减少穿模概率（不过这是目前游戏引擎都很难解决的问题）
  - Cloth Physical Material: 指定布料的硬度、切向韧性、褶皱程度等，可以结合渲染的材质达到更一致的效果
  - *Cloth Solver*
    - 使用弹簧质点系统建模每个顶点的受力
      $ arrow(F)_"net"^"vertex" (t) = M arrow(g) + arrow(F)_"wind" (t) + arrow(F)_"air_resistance" (t) + sum_("springs" in v) (k_"spring" De arrow(x) (t) - k_"damping" arrow(v) (t)) = M arrow(a) (t) $
      - 其中大部分力都很好理解，$arrow(F)_"air_resistance"$ 一般简单取 $arrow(v)$ 的正比例函数即可，damping 是指弹簧自己的阻尼（最终转化为内能）
    - 该式的求解一般有两种方法：
      + Verlet Integration: 从半隐式欧拉法可以简单推出，虽然式子本身是完全等价的，但这一形式的好处在于剔除了 $arrow(v)$ 而完全由顶点位置 $arrow(x)$ 和受力所决定
        $ arrow(x + De t) = 2 arrow(x) - arrow(x - De t) + arrow(a) (t) (De t)^2 $
        - 不仅更快，也更稳定（降低有时一瞬间高速度的影响，感觉有点往 PBD 那边靠的意思）
        - 而且我们的物理系统对 $arrow(x)$ 是更直接的，$arrow(v)$ 是对加速度间接积分出来的，这样对精度也有好处
        - 再来，$arrow(x - De t)$ 作为上一帧的结果，内存中可能有缓存，计算量也小
      + Position Based dynamics (PBD)
        - 但一般来说，目前最主流的布料求解方法还是 PBD，直接由约束计算出位置，而不需要再由约束得出力再算出速度位置，最后一章单独讲
- *Self Collision* 自穿插问题
  - 衣服自身或者衣服之间相互穿模的情况，由于角色衣服经常穿好几层，所以这个问题对高品质游戏很重要，目前还是非常前沿的领域
  - 一般有这些方法：
    + thicker cloth: 单纯把衣服加厚（即使有一定穿模也不影响）
    + substeps: 增加计算精度（一个 step 里解算多个 substep，使得不会穿透很深）
    + Enforce maximal velocity: 设置最大速度值，防止衣料之间穿模的过深
    + contact constraints and friction constraints: 最大速度值的基础上再设置一个反向力，穿模还能弹回来

== Destruction 破坏系统
破坏系统不仅仅是视觉效果的一环，它有时也是 gameplay 的组成，使游戏世界更栩栩如生

- 制作步骤
  + 使用 Chunk Hierarchy 组织，一般是自动生成 level by level 的树状结构来将未被破坏的物体分割成不同大小的 chunk，对不同层级设置不同的破坏阈值
    - 树状结构怎么生成？一般是用 Voronoi Cell 算法（即之前讲云的噪声时的 worley noise）
    - 具体为在 2D 图上随机撒一些种子，每个种子以相同的速度不断扩大半径，直至撞到其他种子区域，稳定下来后就形成不同的块（类似细胞）。对于 3D 物体需要用 Delaunay 三角化
  + 把每个 chunk 视作一个 node，共享边的 chunk 间连一条 edge，构建同一层的不同块之间的关系 (runtime update)
  + 给连接关系设置破坏值（血量）$D$ 和硬度 $H$，每次攻击后计算伤害值并累积
    - 伤害由施加的冲量除以硬度给出，实际上是个并不太合理的式子（如果要更符合物理的话要考虑应力、韧度等）
      $ D = I / H $
    - 以及往往会设置一个球形的衰减（在小范围内伤害相同，在此之外伤害递减）
      $ D_d = cases(
        D\, &d < R_min,
        D dot (frac(R_max - d, R_max - R_min))^K\, &R_min < d < R_max,
        0\, &d > R_max
      ) $
- 切割模型后断口处纹理如何处理（尤其是 3D 物体）？一般有两种方式：
  + 直接制作对应的3D纹理，切割时直接用，但从生成到采样都复杂
  + 离线计算好这些纹理，一旦破碎则切换到对应的纹理，这种需要瞬时处理，也很复杂
- Make it more realistic
  - 许多种破碎方式，均匀的、随机的、中心往外碎等
  - 加上对应的声效、粒子效果等
  - 碎片间的物理互动、相互碰撞（慎用，开销巨大）
- 一些 Popular 的破坏模拟引擎
  + NVIDIA APEX Destruction
  + NVIDIA Blast
  + Havok Destruction（《塞尔达传说：旷野之息》所用物理引擎就是魔改自哈沃克引擎）
  + Chaos Destruction (UE5)
#q[插播一则新闻，任天堂在 2025.4.2 的 switch2 直面会上公布的《Donkey Kong: Bananza》似乎在地形破坏上有重大突破，以至于能以此为核心玩法做一款护航大作。本文编写时还未看到有深入的技术分析，期待后续有文章挖掘一下 #emoji.face.smile]

== Vehicle
游戏中载具系统十分重要，如前文所述我们往往会在角色身上设计一个挂载点 mount 到载具上。那么这个载具具体要怎么建模才能真实又自然呢？这里主要讨论的是 “车”，而飞行器、船、生物坐骑不会详细介绍。

- *载具模型*
  - 通常我们会把车辆建模成一个 rigid body 加上一系列弹簧，一方面模拟形状，另一方面也支持悬挂系统的 scene query
- *受力*
  - Traction Force 驱动力
    - engine 输出扭矩（由发动机转速、油门等影响，具体公式有车载引擎工程师考虑），再经过变速箱、差速器等传递到车轮。车轮转动，（只要不打滑基本都是）静摩擦力成为驱动力
  - Suspension Force 悬挂力
    - 类似弹簧的弹力，轮胎随着离车体距离大小影响施加悬挂力
  - Tire Force 轮胎力
    - 分为 Longitudinal force 纵向力（往车身前方）和 Lateral force 横向力（切向力，垂直于轮胎方向）
    - 对 Longitudinal force，如果是从动轮就只是阻力，如果是驱动轮就有 Traction Force
    - 对 Lateral force，实际上是滑动摩擦力，关系到车的转向，不仅跟路面、轮胎有关，也跟车辆重心有关
- *Center of Mass 重心*
  - 重心很影响车辆的设计和体验，影响牵引力、加速度、稳定性等，它应当是一个可调值。一般来说，重心跟发动机的位置高度相关
  - 当车辆在空中时，重心太靠前则容易 dive，重心靠后则相对稳定
  - 当车辆在转弯时，重心太靠前则容易转向不足 (understeering)，重心靠后则容易转向过度 (oversteering)，跟转动惯量的力臂有关
  - Weight Transfer: 加速时重心会后移，减速时前移
- *Steering angles 转向角*
  - 由于车辆是个刚体，本身有宽度，如果两个轮胎角度相同，靠外的轮胎会发生空转，开出的轨迹容易变成螺旋衰减线
  - 所以实际中需要用轮胎到转动圆的圆心切线算出转动角度 —— Ackermann steering
- *Advanced Wheel Contact*
  - 轮胎与环境的交互如果只用 raycast 容易穿模，最好用 spherecast 将轮胎整体以球体的方式判断
  - 部分游戏中还有飞行器的空气动力学模拟、船的模型，以及坦克的履带模拟等

== Advanced: PBD/XPBD
#let bXk = $bX^((k))$
- 回忆拉格朗日力学
  - 用力学约束而不是运动规律来描述物理系统，反向定义运动规律，从而把很多力学问题化简成求解约束问题
- *PBD*
  - 以匀速圆周运动为例
    - Position Constraint:
      $ C(bx) = norm(bx) - r = 0 $
    - Velocity Constraint:
      $ frac(dif, dif t) C(bx) = frac(dif C, dif bx) frac(dif bx, dif t) eq.delta bJ dot bv = 0 $
      - 前者空间约束关于位置的导数就是 Jacobian 矩阵（在这里就是一个行向量），后者就是速度
      - 换句话说，构建了一个速度的约束：正交于 Jacobian 矩阵
  - 以弹簧运动为例
    $ C_"stretch" (bx_1, bx_2) = norm(bx_1 - bx_2) - d = 0 $
  - Jacobian 矩阵实际上描述了在当前姿态下，为了满足约束（靠近目标点），每一个变量应该扰动的趋势如何。PBD 就类似于梯度下降法，利用 Jacobian 描述的倾向，根据某个步长不断迭代优化约束状态。其约束是用 position $bx$ 来描述，把过去广泛使用的速度、力等概念（容易导致迭代不稳定）给抛弃了
    - 定义第 $k$ 次迭代下的所有顶点的空间位置
      $ bXk = vec(bx_1^((k)), dots.v, bx_n^((k))) $
    - 我们希望添加一个扰动后依然满足约束，用泰勒展开近似。并且扰动是沿着 Jacobian 矩阵的方向
      $
      C(bXk + De bX) approx C(bXk)  + na_bX C(bXk) dot De bX = 0 \
      De bX = la na_bX C(bXk)
      $
    - 于是可以计算出步长
      $
      C(bXk) + na_bX C(bXk) dot la na_bX C(bXk) = 0 \
      => la = - frac(C(bXk), norm(na_bX C(bXk))^2), ~~ De bX = - frac(C(bXk), norm(na_bX C(bXk))^2) na_bX C(bXk)
      $
  - 伪代码流程
    #algo(title: [*Algorithm*: PBD])[
      + *forall* vertices $i$
        + initailize $bx_i = bx_i^0, v_i = v_i^0, w_i = 1\/m_i$
      + *endfor*
      + *loop*
        + *forall* vertices $i$ *do* $v_i <- v_i + De t w_i f_"ext" (bx_i)$ #comment[5 \~ 7, Semi-Implicit Euler]
        + $"dampVelocities"(v_1, dots, v_N)$ #comment[需要对速度施加惩罚]
        + *forall* vertices $i$ *do* $p_i <- bx_i + De t v_i$ #comment[算出当前帧的假的位置记作 $p$（可能有穿插、钻地）]
        + *forall* vertices $i$ *do* $"generateColisionConstraints"(bx_i -> p_i)$ #comment[根据当前帧的位置生成碰撞约束，加上布料本身构成两组约束]
        + *loop* solverIterations *times*
          + $"projectConstraints"(C_1, dots, C_(M + M_"coll"), p_1, dots, p_N)$ #comment[9 \~11，迭代求解约束，直到误差小于阈值或迭代次数过长]
        + *endloop*
        + *forall* vertices $i$
          + $v_i <- (p_i - bx_i) \/ De t$ #comment[12 \~ 15，算出满足约束的该帧真正位置]
          + $bx_i <- p_i$
        + *endfor*
        + $"velocityUpdate"(v_1, dots, v_N)$ #comment[碰撞顶点的速度根据摩擦和恢复系数进行修改（再细调）]
      + *endloop*
    ]
  - PBD 的优势：把约束问题投影成位置校正，绝大多数情况收敛快且稳定，在布料模拟中广泛使用。有个小问题是不好控制约束的优先级（比如把碰撞约束置于其它约束之上）
- *XPBD (Extended PBD)*
  - 在 PBD 的基础上增加了刚度 (stiffness) 来描述约束的软硬程度
    - 一般是用 stiffness 的逆 —— 服从度 (compliance) 来描述，从而能够 handle 无限 stiff 的物体 (rigid body)
    - 例如硬币的刚度设置比较大，放在桌上高频抖动，构成一个比较硬的约束；布料这种比较柔软的就可以设置较小的刚度。从而我们在一个方程里对不同约束设置不同的刚度就能有不同的优先级
  - 重新引入了刚体朝向的影响用于刚体模拟应用（？）
  - 相当于把 PBD 的约束方程升级为服从度矩阵 Compliance Matrix，即下式的 $U(bX)$
    $ U(bX) = 1/2 C(bX)^T al^(-1) C(bX) \ "Block diagonal compliance matrix" $
    - 土法理解：stiffness 类似弹簧硬度（胡克系数），$C(bX)$ 理解为误差偏移量，那么弹簧势能就是 $1/2 k x^2$。多维情况下就变为矩阵，也就是说该公式可以理解为约束的势能
  - XPBD 其实刚刚兴起的 (2022.6)，还没有经过大规模工业化的检验，但正在变得越来越 popular（UE5 的 Chaos 就用的这个）

= 游戏引擎中的粒子和声效系统
== Particle System 粒子系统
- Particle 在游戏中通常是一个 Sprite / 3D Model，具有 Position, Velocity, Size, Color, Lifetime...
- *Life Cycle*
  - 发射源 (Source) $->$ 产生 (Spawn) $->$ 环境交互 (Reaction to environment) $->$ 死亡 (Death)
- *Emitter 粒子发射器*
  - 控制粒子 Spawn 规则、模拟逻辑和渲染
  - 许多个 emitter 以及活着的粒子共同组成了 *Particle System*。比如火焰效果中有 flame, spark, smoke 等不同发射器，美术需要考虑如何用简单系统的组合展现复杂效果
  - spawn 规则可以有 single position spawn（向四周喷射）、area spawn（范围内随机）、mesh spawn（以 mesh 形状为基底喷射）；发射时也有频率、速度、方向等不同表现；spawn mode 可以是 Continuous（持续不断地喷发）、Burst（猛地喷发）
- *Simulate 模拟*
  - 粒子最常受到的力：Gravity, Viscous drag, Wind field 等，由于粒子不需要太严格，求解使用显式、隐式、半隐式等都可以，一般显示欧拉法计算即可
  - 除了模拟位置的变化，还可以加上 rotation, color, size 等。这些变化在早期基本预先设定好，再开放几个参数给美术即可，现在的游戏中一般就更复杂
  - 粒子与环境的互动，比如 Collision，如果直接调用物理系统会非常慢（因为粒子非常多），所以这里需要对粒子特化的高效算法
- *Particle Type*
  - 粒子不能仅仅抽象成一个质点，常见的有以下几种类型：
    + Billboard Particle
      - 广告牌 sprite，始终朝向摄像机因此看起来像 3D
    + Mesh Particle
      - 同一个 3D mesh 用各种随机值去控制 Transform，使其具有随机感
    + Ribbon Particle
      - 样条形粒子，打出一条光带。在飞行过程中不断拉出额外的一个个控制节点，然后以一定宽度连起来获得完整曲线（曲带）
      - 一般不是直接相连而是使用样条曲线插值（如 Catmull-Rom 曲线，简单且插值点过控制点）

== Particle System Rendering 粒子渲染
- Particle 渲染的问题
  - 由于其半透明特性涉及到大量的排序问题，而且其数量比起场景中的半透明物体（顶天了也就几十个）要多得多
  - 同时半透明粒子每个都需要绘制再 alpha blend，overdraw 情况非常严重，开销巨大（尤其在屏幕分辨率大且粒子布满整个屏幕的情况下，更是导致突然掉帧的性能杀手）
- 粒子排序一般有两种 Mode：
  + Global
    - 所有 emitter 的所有粒子都一起排序，结果正确但消耗巨大
  + Hierarchy
    - per system $->$ per emitter $->$ per particle (within emitter)
    - Sort rules
      + Between particles: 根据 particle 到相机距离
      + Between systems or emitters: 用 bounding box
    - 靠的相近的 emitter 会导致出现错位并且会有闪现的问题（视觉效果上影响非常大），但性能更好且相对比较好写
- 粒子与屏幕分辨率
  - 由于多数时候粒子 fuzzy 一点关系不大，所以可以用下采样的将分辨率降低后进行渲染，获得粒子的 color, alpha 后再融合到原场景中。这个思路在现代引擎中越来越流行 (DLSS)
  - 此外还可以用一些算法把某一绘制次数过多的像素上的某些粒子 cut 掉（比如离相机过近的粒子）

== GPU Particle
从前两节可以看到，粒子系统不管是模拟还是渲染都很耗性能，并且为了更好的画面效果需要海量的粒子，对 CPU 的负担很大。而 GPU 正好适合处理这种海量、并发的任务，从产生到模拟到排序都可以放入 GPU，并且读取 Zbuffer 还更快。不过 GPU 上有一个难点是控制粒子的生命周期。

- *Intial State*
  - Particle Pool: 先建立一个粒子池，设计一个数据结构 (stack)，描述所有粒子的位置、颜色、速度、尺寸等描述信息（描述了需要使用粒子的上限数量，这样后面不断的生成、死亡都只需要操作 index）
  - Dead List: 记录当前死亡的粒子，初始时包含所有粒子序号
  - Alive List: 记录当前存活的粒子，初始时为空。当 emitter 发射 $x$ 个粒子，则从 pool 结尾取出 $x$ 个粒子放入 alive list，把 dead list 后 $x$ 个序号清空
- *Simulate*
  - 对 alive list（记作 list 0）中的每个粒子进行模拟，并建立下一帧的 alive list（记作 list 1）
  - 如果粒子在下一帧死了，就将其序号 append 到 dead list（需要保证原子性），否则保留，这样得到下一帧需要渲染的粒子列表
    - 这种操作在过去的 GPU 上不好实现，但 compute shader 允许我们在一个 batch 中设置全局变量来保值原子性
  - 并且由于数据都在 GPU 上，可以方便地进行视角剔除 frustum culling，建立 Alive List After Culling，并计算它们的距离写入 Distance buffer
- *Sort, Render and Swap Alive Lists*
  + 根据上边保存的 Distance buffer 对 Alive list After Culling 排序
    - 用什么排序算法进行 global sort？parallel mergesort，这里涉及到 ADS 里讲过的把 merge 问题转化为 rank 问题，并且这里还涉及到内存局部性的问题
  + 根据排序渲染粒子
  + 更新交换 alive list0, alive list1 以及它们的数量指针
- *Depth Buffer Collision*
  - 在 GPU 上组织粒子系统的另一个好处是可以直接拿到 Depth Buffer 在 screen space 上模拟碰撞
  - 把粒子重投影回上一帧整个 frame 的 depth buffer 上（因为这一帧的还没拿到），用读出的 depth value 和一定 thickness value 判定是否碰撞，如果发生碰撞就用屏幕空间计算出的法向将粒子反弹

在 GPU 上实现粒子系统基本已经成为现代游戏引擎的标配，不过往深了做还是有各种进阶的应用。

== Advanced Particles
- *Crowd Simulation*
  - 直接利用粒子 (Animated Particle Mesh) 来模拟人群，用简化版的 skinning（每个顶点只受一个 bone 影响）
  - 有了简单的 skeleton 和 skinning 后，就可以把所有可能的动画和不同动画代表的 particle 属性、状态全部记录到一个纹理上
  - 每个 particle 维持一个小状态机，当 particle 的属性变化时就从纹理图中找到对应的动画进行切换
- *Navigation Texture*
  - 如果我们希望所有粒子既沿着设定路径又有随机移动，最简单的想法就是所有人往一个方向走但给一点随机，但不好控制粒子人物不要走到建筑物里等
  - 可以利用 SDF 场来制作一个导航纹理图，其正负性代表建筑物的内外，给走进建筑的粒子一个反向力
  - 从而，在某个位置 spawn 一个粒子，并设定目的地和初始速度后，再搭配一些噪声，就会如同受一股力一样在地图中飘动
- *Advanced Applications*
  - 总之，以前所讲的 particle 是非常古典的应用，而现代游戏引擎中 particle 的应用已经五花八门到远远超出想象，比如 Skeleton mesh emitter, Dynamic procedural splines, Reactions to other players, Interacting with environment... PPT 中给了两个 demo 非常酷炫
- *Design Philosophy*
  - 再者，粒子系统在设计哲学上也不断演进
  - Preset Stack-Style Modules: 以前的粒子系统的行为都是预设好的，根据预设的不同类型、参数决定粒子后续的行为
    - 好处是一目了然、易于理解，非 TA 也能快速根据典型行为达成想要的效果
    - 坏处是功能固定，不好扩展，Code-based 导致不同游戏团队的代码分歧，且粒子数据不好共享
  - Graph-Based Design: 现代引擎中的每个粒子都有自己的变化、模拟、扰动，形成可参数化和共享的图形资产，各种粒子的变化形成模块化工具而非硬编码功能
  - Hybrid Design: Graphs 提供总的控制，Stacks 提供模块化行为和可读性。目前做的比较好的是 UE5 的 Niagara 粒子系统

== Sound System Basics 声效系统基础
一般来讲粒子效果系统跟声效系统是不分家的，因此这里放到一起来讲，但限于篇幅都只能是浅尝辄止。声音对于游戏的重要性自不必多说，尤其是对于沉浸感的提升，有时它可能比画面更重要，甚至可成为部分品类的灵魂（想想看电影，关掉声音只看画面可能没什么感觉，但关掉画面只听声音有时依然能想象、勾勒出画面）。

- *Terminologies*
  - Volume 音量
    - 声音在物理上就是空气压强变化，其主体是纵波（当然也导致一定的横波），在单位面积产生一定压强，也就是感受到的音量大小
    - 常用单位是分贝。分贝 $0$ 大概是 $3$ 米远一只蚊子的声音，其压强记为 $p_0$。那么分贝与声压的关系就是
      $ L = 20 log_10 (p/p_0) "dB" $
    - 人对声音的感知不是线性的，而是 $log$ 的关系（跟地震类似）
  - Pitch 尖锐度（音高）
    - 本质就是空气震动的频率，决定了声音的刺耳程度
  - Timbre 音色
    - 本质是 overtones or harmonics 的组合，同一个音调用不同乐器演奏的区别
  - Phase and Noise Cancelling 相位以及降噪
    - 降噪的原理就是用相同频率、强度但反向相位的波去中和掉噪音
  - Human Hearing Characteristic 听觉的人体感受
    - 人耳对频率的感知范围是 $20 wave 20K Hz$，对音量的感知范围是 $0 wave 130 "dB"$
    - 超出听力频率的声音虽然听不到，但还是会影响音色因而能感知到（有些电影可能会用这类技术渲染氛围）
- *Digital Sound*
  - 声音是模拟信号，需要数字化处理，涉及脉冲编码调制 Pulse-code Modulation (PCM)
  - Sampling: 采样的频率，香农定理要求我们以至少两倍的频率采样才能无损
  - Quatizing: 量化的精度，决定了声音的精细程度，可均匀划分或非均匀划分。bit depth 是每个样本中的信息位数
  - Audio Format (Encoding): 各种音乐格式，在 Quality, Storage, Multi-channel, Patent 四个维度上各有千秋，游戏中一般使用 OGG（是个有损压缩格式）

== Audio Rendering 音频渲染
三维空间中有很多声源构成一个声场，受位置、距离等因素影响，最终听到的音频表现也不同，这一过程也叫 “渲染” 但跟光学那一套不太一样。

- *Listenner*
  - 游戏中需要一个 listenner 来接受声音，需要有这些属性：
    + 位置：如果是第一人称游戏，一般就挂在 main controller 身上；如果是第三人称游戏，
    + 速度：模拟多普勒效应
    + 朝向：侧着听和正着听的效果是不同的
- *Spatialization 空间感*
  - 人是如何从声音中感知空间的？一般是通过声音的大小、到达左右耳时间差和音色差等
  - *Panning*: 调整声音在不同通道上的音量、音色、延迟来产生虚拟空间感的算法
    - Linear Panning: 线性地把声音从 left channel 移到 right channel，从而产生从左到右的空间感。但由于人对声音感知是音强的平方，会导致声音有强弱变化
    - Equal Power Panning: 用 $sin^2, cos^2$ 的比例把声音从 left channel 移到 right channel，保持音量不变
    - 上两个都是比较简单的，通过基于物理真实测算和人体心理学感知的复杂方法可以真正模拟前后左右上下的空间感。不过目前咱臭打游戏的大部分还停留在两个耳机一戴的 stereo display
- *Attenuation 声音衰弱*
  - 总体上 sound pressure 随距离以 $1\/r$ 比例衰弱，但真实情况下会更复杂，高频低频衰弱程度不同（视频中以吃鸡为例非常明显）
  - Attenuation Shape: Sphere 模拟最简单的球形衰减，Capsule 模拟河流等（离远了减弱，但沿着走向相同），Box 模拟室内声音到室外迅速衰减，Cone 模拟定向性声音（如高音喇叭）……
- *Obstruction and Occlusion 障碍物*
  - Obstruction 是指 Source 跟 Listener 之间有直接物体阻挡，但可以绕过并利用惠更斯原理传播的情形
  - Occlusion 是指 Source 跟 Listener 之间整个被挡住，只能透过传播（声音震动墙，墙再震动这边的空气）的情形
  - 这二者的声音表现是完全不同的，最简单的做法就是从 Listenner 向 Source 以不同角度做 Raycast，query 出是否被物体阻挡以及阻挡物材质对能量的吸收程度，从而蒙特卡洛积分出声音的效果
- *Reverb 混响*
  - 在教堂中对话、骑马穿过桥洞等场景下，混响对空间感的影响非常大
  - 由三个部分组成，干音 direct (dry)、回音 early reflections (echo)、尾音 late reverberations (tail)，后二者也统称湿音 wet
    - 可以类比为光照的直接光照、次级光照和无限弹射的多级光照（统称间接光照）
  - 不同材质对不同声音吸收不同 (Absorption)，空间的大小也会影响混响的延迟 (Reverberation Time)
  - 如果只有回音没有尾音，声音会非常难受，有混音声音才好听（e.g. 浴室麦霸）
  - 定义四种基本参数 Pre-delay (seconds), HF ratio, Wet level, Dry level 给声效师调节
- *Doppler Effect 多普勒效应*
  - 声源和听者之间的相对速度导致声音的频率发生变化
- *Spatialization —— Soundfield*
  - 不局限于 Listener 处声音的采集，利用 Ambisonics 技术对整个声场进行采集
  - 在 360 videos, VR 中应用广泛
- *Common Middlewares*
  - 声效引擎常见的中间件有 Fmod 和 Wwise，前者维护有点拉胯，后者在越来越受重视（3A 游戏中用的更多）
  - 同时有越来越多的游戏引擎开始自己写声效引擎（如 UE5 的 MetaSound）

= 引擎工具链基础
工具链在引擎中仿佛默默无闻，但其实是非常重要的组成部分。游戏引擎在宣传时总是强调其渲染、物理、AI 等等有多酷炫，但相关从业者看了也就大概知道怎么个实现了，更重要的反而是工具链的设计。一般商业引擎里的工具链代码量是超过引擎 Runtime 部分的。

#fig("/public/assets/CG/GAMES104/2025-04-04-21-53-38.png")

工具链是衔接不同岗位之间的桥梁（调和不同思维方式的人一起工作的平台），同时它也是各种 DCC (Digital Content Creation) 工具到游戏引擎的桥梁，它处在 ACP (Asset Conditioning Pipeline) 这一层。

== 复杂的工具
- *GUI 界面*
  - GUI 就是工具的操作界面，正在变得越来越复杂，它要求 fast iteraction, separation of design and implementation, reusability
  - 两大类实现方式
    + Immediate Mode
      - 例如 Unity UGUI
      - 每次绘制时由游戏逻辑直接发出绘图命令，需要不间断发出指令
      - 好处是直接、简单、快，坏处是扩展性差、把业务压力给到逻辑这边，压力大
    + Retain Mode
      - 例如 UE UMG, Qt GUI
      - 类似于 Graphics 的 Command Buffer，GUI 绘制逻辑时根据存储的命令自行绘制，如果不需要更新，就不用发出命令，且把游戏逻辑和工具的 GUI 逻辑分开了
      - 好处是扩展性强，性能高、可维护性高，但往深处做就要涉及到许多 Design Pattern 的概念
- *Design Pattern 设计模式*
  - 当一个工具有几十上百个功能时，如果不遵循某一设计模式的指导，往往会越来越混乱甚至动辄炸掉
  #grid2(
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-04-22-14-27.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-04-22-14-36.png", width: 70%),
  )
    #fig("/public/assets/CG/GAMES104/2025-04-04-22-14-57.png", width: 70%)
  - MVC
    - Model 管理组织应用数据 $->$ View 任何表示信息的方式如图、表 $->$ Controller 接受输入并更新 Model 和 View
    - 数据流是单向的，原始数据不会被弄脏，一定程度上能够解耦二者
    - 最经典，变种也最多的设计模式
  - MVP
    - Presenter 从 Model 里取数据呈现给 View，又从 View 的用户交互里反馈给 Model
    - 把 Model 和 View 拆分得更彻底、干净，二者的功能和测试更独立，代价是 Presenter 会比较臃肿
  - MVVM
    - 与 MVP 相似但是用 ViewModel 来代替 Presenter，不是在代码里写死对 View 和 Model 的 query，而是利用 Binding 的机制区分得更好
    - MVVM 的 View 更多是一个 designer 而非传统的也是一个 developer，降低了对代码的依赖，更强调所见即所得，从而可以直接让 UX Designer 来做。一般是直接用 xml, json 等文件即可描述
    - 这也是现代最常用的模型，好处是独立开发、方便测试和复用，坏处是平台依赖性强、debug 困难、对简单 UI 需求太 overkill 以及必须得在现成框架上开发（当然这也不全是坏处，比如现在在 `.cs` 里写 GUI 比 `.cpp` 里方便太多）
  - 建议：游戏引擎工具链需要有非常强的工程可扩展性，最好不要自己造轮子，而应该选择最成熟的结构和方案
- *数据的加载和存储*
  - 序列化 (Serialization) 和反序列化 (Deserialization) 其实就是 save 和 load，将数据转化为二进制块方便存储。它不仅局限于存到硬盘，也广泛应用于网络传输、工具链传输中
  - 存储形式
    + Text File
      - 最简单的 txt 以及结构化的 xml, json, yaml 等。比如 Unity 用 subset of YAML，Cryengine 用 XML / Json
      - 好处是易读，容易 debug。引擎推荐优先支持此类，测试完成后转成 Binary File
    + Binary File
      - 二进制文件，例如 Unity 的 `*.asset` 和 Runtime、Unreal 的 `*.uasset`、FBX Binary 等
      - 好处是存储容量小，并且容易加密，安全性高，且省去了语义的 Parse 处理。比如 FBX Binary 比 FBX Text 占用小很多，总体加载速度能快 $10$ 倍。因此上线产品一般用这种形式
- *资产引用*
  - 游戏中很多东西会重复出现，为了节省内存需要资产引用，通过引用实例化 (Instance) 重复对象 (Prefab)
  - Object Instance Variance（Prefab 与 Prefab Variant）
    + 通过*复制*的方式构建变体：复制原先数据并修改，但是比较低效并且丧失关联性
    + 通过*数据继承 (Data Inheritance)* 的方式构建变体：继承原数据并 override

== Deserialization 资产加载
-* Parse 资产解析*
  - 加载资产是一个 Parse 的过程，并且所读到的某个属性可能还没被加载出来，需要构建一个 Key-Type-Value Pair Tree
    #fig("/public/assets/CG/GAMES104/2025-04-05-11-01-19.png", width: 50%)
  - 树状结构在 text 和 binary 文件里的形式
    + Text: store in asset（需要第三方库解析成一个 dictionary 再二次 Parse）
    + Binary: store in a table
  - Endianness 字节端序
    - 即大小端，不同游戏平台规则不同，做适配时需要注意
- *Asset Version Compatibility 资产版本兼容性*
  - 很多软件都只做到向下（向后）兼容，那怎么做到向上（向前）兼容？在元宇宙、分布式部署这类场景里非常需要
  - *By Version Hardcode*
    - 给资产添加版本号，对新版本新增的数据类型读取其 default value，对删除的数据类型不进行读取
    - Unreal 的做法，但其实不太好，随着时间的更迭代码越来越臃肿
  - *By Field UID*
    - 提出了 Protocol Buffer 的概念，给数据的每一个属性定义单调递增的 UID。存储时为每个 filed 根据 UID 生成固定大小的 key 并存储 data；读取时遇到 filed in schema but not in data 就用默认值，遇到 filed in data but not in schema 就跳过
    - Google 的做法，相对鲁棒

== Robust Tools 如何制作高鲁棒性的工具
游戏引擎工具链一旦崩溃，整个团队都得停摆，我们实际上得服务团队所有人，是最底层的打工仔（悲）。

- *Undo & Redo, Crash Recovery*
  - Undo & Redo 听起来简单，但（尤其是对游戏引擎）不同操作之间有很深的 correlation 且很多态；Crash 更是致命，设计得再好的工具也难免崩溃，一旦崩溃就几小时白干
- 这个问题在软件工程中其实是一个 well-studied problem，有一个成熟的 design pattern 来解决 —— *Command Pattern*
  - 记录用户所有操作（分解为多个 Command）并记录，定时保存到磁盘上
  - Command 的定义
    + UID 是唯一、累加的，用于记录执行顺序
    + Data 用于存储操作数据
    + `Invoke` 和 `Revoke` 方法用于执行和撤销操作
    + `Serialize` 和 `Deserialize` 方法用于序列化和反序列化，一般由所操作的数据实现
  - Command 的 $3$ 种主要操作：Add, Delete, Update

== Make Tool Chain 如何制作工具链
各个工具如果全部单独写的话，那将没有任何*可扩展性 (Scalability) 和可维护性 (Maintainability)*，因此需要找到这些工具通用的部分，把任何复杂结构用简单的 Building Block 构成，用一个标准的 Schema 去描述它们。

- *Schema*
  - 是一个 Description Structure，在不同工具之间规范化数据，自动生成标准化的用户界面
  - 需要有 Basic Elements (Atomic Types, Class Type, Container)，要有 Inheritance 的能力，要能支持 Data Reference
  - 两种定义方式
    + Standalone schema definition file
      - 直接用类似脚本的语言或结构化语言定义 schema，用一套方法反射成引擎代码，让引擎知道怎么读、写、编辑资产文件
      - 好处是好理解，把数据定义和工程实践相剥离；坏处是需要代码生成器，可能有版本问题，难以定义 function, API
    + Defined in code
      - UE 的做法，类似于 C++ 等高级语言的类，通过宏来描述数据、方法是 meta 的、可以反射的
      - 好处是可以包装 function 等，支持性好；坏处是对鲁棒性要求高
- 引擎数据的 $3$ 种 View
  - Runtime View: 在 CPU 和内存中，在乎读取速度和计算速度
  - Storage View: 在 SSD, HHD 中，在乎读写速度和存储空间
  - Tools View: 在 Human 尤其是非 Programmer 看来，需要更好理解的界面（比如弧度变为角度、颜色直观显示等）和多样的编辑模式 (Beginer Mode, Expert Mode)

== What You See is What You Get (WYSIWYG) 所见即所得
工具体系的核心精神：所见即所得，即工具是什么样运行时就是什么样（与运行环境配置一致），让设计师以最快的速度和最低的成本去尝试。

- *Stand-alone Tools*
  - 早期工具链独立于引擎，因为它的逻辑非常复杂，有很多 dirty and special 的代码，为了让引擎相对干净，把它独立出来
  - 好处是工具接入简单 (as a DCC tool plugin)，但是难以做到所见即所得。现在基本不用了
- *In Game Tools*
  - 直接在游戏引擎上做的工具，需要在 Runtime 层上架一层 Editor Scene，再实现 Editor GUI
  - 好处：完全 In-Game Editing，所见即所得，对生产效率提升帮助巨大
  - 坏处：开发成本高，需要引擎向上兼容编辑器需求；需要做复杂的 UI；容易导致工具链跟引擎同步崩溃
- *Play in Editor (PIE)*
  - 在编辑器里直接就能启动 (Play in editor world)；或者把编辑器中的数据拷贝一份启动游戏，类似于新开一个沙盒做分身 (Play in PIE world)
  - 前者比较简单，但 editor 跟 runtime 的数据难以分开（容易导致二者行为不一致出现 bug）
  - 后者是 UE / Unity 等商业引擎的做法，相当于多花一点内存更好地模拟游戏单独运行的环境，不过架构会更复杂

== Plugin 可拓展性
引擎太过复杂，做得再多也不能自大地认为完全覆盖了用户的需求，需要将引擎设计为一个平台让用户以插件 Plugin 的方式制作工具，比如 Unity 商店。

- 这要求引擎
  + 提供 PluginManager 来管理插件的加载和卸载
  + 提供 Interface 来为插件提供一系列抽象类，插件可以选择实例化不同的类来实现相应功能的开发
  + 提供对应的 API，暴露引擎的一系列函数，让插件可以自定义相关逻辑
  - 引擎自身功能也要尽可能 API 化、Module 化

= 引擎工具链高级概念与应用
== Architecture of World Editor 世界编辑器
世界编辑器（地图编辑器）是一个平台 Hub，把所有制作世界的逻辑集合起来，又对不同 user 呈现出不同 view。

- UE 的例子
  #fig("/public/assets/CG/GAMES104/2025-04-05-14-23-49.png", width: 80%)
- *Editor Viewport*
  - 设计师和游戏世界交互的窗口，下面跑了一个 Editor Mode 的 full game，额外提供很多为编辑而生的特殊功能
  - 因此会有部分 Editor Only 的代码，比如 Unity `.cs` 脚本里面写 `#if UNITY_EDITOR` 的宏，如果不小心开放很可能成为外挂入口
  - 需要引擎能支持多种 view，比如编辑的 view 和过场动画的 view 等
- Editable Object
  - Everything is an Editable Object，UE 里叫 Actor，Unity 里叫 Object (GameObject)
  - Object 的管理
    - 用 different views 显示所有 objects，比如 tree view
    - 分成各种 categories, groups, layers，还要支持 filger, search
  - Schema-Driven Object Property Editing
    - 选中一个 Object，通过 schema 反射出它拥有的属性，在一个 Panel 里生成界面提供给 designer 编辑
    - UE 中叫 Detail，Unity 中叫 Inspector，还有些叫 Property
- *Content Browser*
  - 在最初的时候，往往是一个有经验的 TA 规定所有 Assets 的存储结构，构成一个巨大的树状文件夹结构。但是一方面 TA 不可能预知未来游戏的复杂演化，另一方面这种组织方式不适合引用与改动
  - 因此需要一个 Content Browser 来组织所有的 Asset
    - 可以视作一个巨大的 "Ocean"，通过所需资产的名字、标签等检索
    - 根据不同项目来生成所需的 view，而不需要关心资产的位置（甚至不用在本地，可以是远程的数据库）
    - 当然仍旧会支持树状文件夹结构，但更多只是一个 view
- *Mouse Picking 鼠标选取*
  - 最基本的方法就是用 Raycast，相当于交给物理系统负责，但 query 性能较差
  - 也可以用 RTT (Render To Texture) 的方式，把 ObjectId 写在 FrameBuffer 上
    - 能够轻易地且快速地 query，支持 range queries
    - 如果跑的是 Editor Mode 且管线不支持 Visibility Buffer 等技术的话，就需要一个额外的 pass 来渲染。当然开发机一般配置较高问题不太大
    - 当然对透明物体（不写入 buffer）、微小粒子等还需要额外的 code 来处理，比如给 particle 挂载一个虚拟体代为选中
- *Object Transform Editing*
  - 更改平移、旋转、缩放，要支持快捷键、高亮等交互
  - 这方面逻辑简单，但想要打磨得比较好，并且达到成熟 DCC 工具的水平还是需要花不少功夫
- *Terrain*
  - Landform $->$ Height map, Appearance $->$ Texture map, Vegetation $->$ Tree instances & Decorator distribution map
  - Height Brush: smooth 是一个很大的难点，需要精心设计。此外艺术家有时有自定义笔刷的需求 (Scalability)
  - Instance Brush: 刷出来的 instance 是所见即所得的，且支持进一步的修改，但可能导致大量的数据冗余。这方面的问题可能需要 PCG 来解决
- *Environment*
  - 现代游戏越来越像电影，需要各种 Sky, Light, Roads, Rivers 的环境效果把氛围渲染好。这方面是通过各种各样的插件、工具协作完成，需要引擎为它们设计好空间
  - Rule System 环境规则
    - 比如路上不能有树，路应该适应地形……这些当然可以固定住让艺术家手调，但万恶的策划变来变去的需求会让工作量巨大
    - 更好的方法是程序化生成 (PCG)，先把原始的数据分层（road 的分布、tree 的分布、water 的分布……），定义一套规则系统来约束，让程序整合最后的结果
    - 更细节地，要求 deterministic（结果应该是确定性的）和 locality（局部调整不影响其它已经满意的区域），要求符合直觉（Deep Learning 可以掺一脚），要求对设计师友好（设计师可以方便、低门槛地自定义规则）

== Plugin Architecture
- *Double Dispatch*
  - 引擎设计时考虑的是 Mesh, Particle, Animation, Physical 等系统（横向），但 Plugin 可能还会考虑对某一类对象做功能（纵向）
  - 即，插件需要同时考虑引擎系统和对象两个维度，支持矩阵形数据访问。反过来有些 high level 的特殊功能最好不要内嵌在引擎系统里而是用 Plugin 的形式可供选用
    #fig("/public/assets/CG/GAMES104/2025-04-05-15-35-04.png", width: 60%)
- *Plugin 模型*
  + Covered: 新的插件能覆盖老的
  + Distributed: 不同插件各自执行，最后合并结果
  + Pipeline: 输入输出相连协作
  + Onion rings: 洋葱圈，插件之间相互依赖，读取另一个插件的处理后的结果作为输入，自己处理后的结果再传回去进一步修改
  - 四种模型都有广泛使用，引擎应当保持开放性。更宽泛意义上来说，软件工程师一边要考虑设计的严谨一致，又妥协于工程的复杂而允许不同 pattern 共存。应当秉持实用主义原则，以解决问题为优先
  #grid2(
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-04.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-17.png", width: 50%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-25.png", width: 70%),
    fig("/public/assets/CG/GAMES104/2025-04-05-15-41-35.png", width: 70%)
  )
- *Version Control 版本控制*
  - 引擎更新版本、接口修改后可能会导致插件功能失效，因此在一开始设计接口时就考虑到这些问题
  - 不过这些问题对我们初学者而言就太过复杂了，没有 $10$ 年经验搞不定其中复杂度和丰富度。因此老师不认为程序员写了 $5 wave 10$ 年代码就应该做管理和架构（但事实是，$35$ 岁还没爬到这一层的就要 “毕业” 了，唉）

== Design Narrative Tools 设计叙事工具
现代游戏做的越来越像电影，Storytelling 就变得很重要（腹诽一句，感觉这个走向脱离了游戏的本质，很高兴老师的观点跟我一致）。

这方面 UE 里叫 Sequencer，Unity 里叫 Timeline，相当于电影导演的统筹安排，一个一个角色各自在不同的时间做不同的事，游戏中一些过场动画就是这样做的。很繁琐，但所有电影、游戏都是这样一点一点构建出来的。这个过程涉及到很多工具的实现，这里没有细讲。

Timeline 的过程中，工具是如何调整 Runtime 里各个对象某个 component 的 parameter 的？这就引出下面的话题 —— Reflection，可以说反射是 Timeline 的基石之一。

== Reflection and Gameplay
回忆一下，虽然我们有 schema，但它只是一个描述，我们需要的是绑定好的可以直接操作 (set, get) 的数据；另一方面，游戏中的 Gameplay 非常复杂多样，作为一个引擎不可能知道也不可能把它们写到引擎里面，并且也难以用数据配置做出所有的玩法（任何语言所能描述的东西都有上限）。

还有另一种可视化编程 (Visual Scripting System) 比如 UE 的蓝图 (Blueprint) 的需求，标志着低代码、低门槛编程的未来方向。我们不可能只是预设一系列节点，因此也向引擎提出了可扩展性的需求。

因此，引擎应该允许游戏团队基于现有的功能增加新的逻辑，然而逻辑增加需要接口、工具相应地更新，工作量非常大，那就需要反射 Reflection。

「反射允许程序在运行时检查、修改和操作其自身的结构和行为」，在如今高级语言基本都支持 (e.g. C\#, Java)。引擎实现功能后，工具可以通过知道有哪些开放类和接口可以访问，这时在蓝图中创建对象时，其接口参数全部可以展现。

早期用 C / C++ 编写的引擎为了实现类似反射的效果，用了很多 Tempalte 元编程的 hack，在反射这一概念提出后就成了无用功。那么现在 C++ 如何实现反射？C++ 代码在编译时会翻译成抽象语法树 (Abstract Syntax Tree, AST)，比如类就会被翻译成一个树状结构表，在这个表里就比较容易提取接口和参数。提取到相应数据内容后还需要自动生成操作代码 (Code Generation)，提出一个叫做 Code Rendering 的概念（多说一句，代码生成这个概念几乎没有缺点，不仅 bug 少，而且能更好地做到 code, data 的分离）。

== Collaborative Editing
协同编辑是引擎发展方向，只要 AGI 一天不到达，未来越来越复杂甚至倾向于开放世界的现代游戏就越来越需要多人协同编辑。但大量数据、不同版本如何协作？

- Conficts
  - 用 Git, SVN 等工具管理 Merge 冲突，但依旧要花许多时间
  - 如何尽可能避免冲突？Split Assets —— Layering / Dividing the World
  - Layering: 分层编辑，概念非常好，但很多时候层与层之间有相互依赖，不能分得很清楚
  - Dividing: 分块编辑，不仅更符合直觉，对 dynamically expand the world 支持也比较好；但有时候 asset 可能跨界，所以可能需要支持不规则划分
  - One File Per Actor (OFPA): UE5 新提出的概念，每个对象都创建一个文件，再也不会冲突。但问题也比较大，茫茫多的小文件不仅让版本控制系统提交变得很慢，也让分包时多一个迁移的步骤（学过 OS 都知道，操作系统最恨的就是小文件这种碎片内存）
- Coordinate Editing in One Scene
  - 不过，以上这种本地做完再提交、合并的方式只是协同编辑的初始形态，畅享真正的协同编辑：许多人同时在一个场景里编辑
  - 非常困难的问题在于时序上的控制、原子性操作、Undo/Redo、Operation Merge 等。这些问题结合起来更是复杂，比如操作 $A$ 和操作 $B$ 有时序依赖关系并最终合并出一个结果，但操作 $A$ 随后被 Undo 了，操作 $B$ 应该如何变化？最终结果应该怎么办？
  - 简单的处理办法：Instance lock, Asset lock。复杂的处理办法：Operation Transform (OT), Conflict-free Replicated Data Type (CRDT)。这里都没有详细展开
- Collaborative Editing Workflow
  - 所有的操作不要直接 apply 到最终结果，先发往 Collaborative Server 统一结算完再发回给大家并同步 Remote Storage
  - 付出的代价是一点点的延迟（但在局域网是可以接受的），好处是避免争议，因此被现代很多协同编辑系统所采用
  - 不过鲁棒性有限（Server 炸掉就全完了），因此这个系统还处在比较早期的阶段，是下一代游戏引擎的前沿方向之一

= 游戏引擎的玩法系统基础
- Challenges in GamePlay
  + 玩法系统要和 Animation, Effect, UI, Audio, Interface Devices 等多个系统共同协作，因此岗位涉及面非常广泛（杂学）
  + 游戏类型多样化，即使是同一个游戏也有很多玩法（扩展性），网游在这一方面更新、堆料更甚
  + 玩法系统的迭代极快，比引擎渲染等系统快得多，往往在设计总监提出需求后，马上就要出 demo，一两个月内就要迭代一个版本

== Event Mechanism 事件机制
GameObject 需要相互交互，这种机制如果都用 ifelse 写死实现，未免太过复杂，一般都用 Event / Message Mechanism 实现。

- *Publish-subscribe Pattern 发布-订阅模式*
  - 不同的发布者 (publishers) 发送不同类型的事件给事件调度者 (event dispatcher)
  - event dispatcher 把事件告诉对应的订阅者 (subscribers)，做出相应的动作 (callback)，注意订阅者不知道发布者是谁
  - 该模式的三个关键点为：Event Definition, Callback Registration, Event Dispatching
- *Event Definition*
  - Event Type + Event Argument
  - Event 可以使用基类继承出不同的类型，但还是那个问题，策划需求千变万化，因此需要支持 editable 并且 可视化在 editor 中（回忆 Code Rendering 的做法）
  - 但不断加入新的事件类型都会导致引擎重新编译，这时常见的做法有
    + 将新事件新编译成的 C++ 代码做成 DLL，runtime 注入到系统中（UE 的做法）
    + 上层采用 C\# 语言，方便动态挂接和扩展
    + 用脚本语言如 lua
- *Callback Registration*
  - 说是回调其实就是触发 (invoke)，概念本身很好理解。但在游戏引擎中，回调函数的注册和触发有一个时间差，在这段时间发生的意外（如订阅者被销毁）可能导致奇奇怪怪的行为 —— 回调函数的安全性跟对象的生命周期强相关
  - 可以用 C++ 类似智能指针的技术解决
    + 强引用：订阅者在有事件注册时不能销毁。可能导致系统内存越来越大，一般较少使用
    + 弱引用：在执行回调函数前，判断订阅者是否存在，若不存在则注销回调函数，比较简单高效，一般用得更多
    - 二者都非常重要，需要灵活使用
- *Event Dispatching*
  - Trivial Dispatching: 把所有的消息从头到尾扫一遍，依次遍历所有 GO 看是否有相应函数，但不管是时间还是空间的复杂度都过高
  - Immediate Dispatching
    - 事件发生时打断父函数的执行，马上触发回调函数，但有这些问题：
      + Deep well of callbacks: 比如炸弹的连环爆炸，产生极深的调用栈
      + Blocked by function: 一个事件引发了一系列事件，其中有某个耗时极高，后面的都被堵塞，导致突然掉帧
      + Difficult for parallelization: 顺序触发导致相互之间有依赖关系，难以并行
  - Event Queue Dispatching
    - 把事件存储到 Queue 中，下一帧统一处理；同时未来跨进程、跨网络处理的需要，将事件序列化到一个 Event Buffer 中，用的时候再反序列化（涉及反射）
    - 具体实现
      + 使用环形队列组织的 Ring Buffer 管理内存。不仅只用申请一次并反复重用；而且当 head 和 tail 重合（队列满，一般说明出 bug 了）时，可以直接截断从而只错误几帧数据而不会直接崩溃
      + 使用 Batching 分批管理，用单独的 dispatcher 和 buffer。对 locality 更友好，且 debug 也更方便
    - 问题
      + Timeline not determined
        - 比如先动画后物理等消息执行的顺序无法保证，所以为了保持鲁棒性，需要做非常精细的处理，同时也是 bug 高发地（对程序员尚且如此，设计师更是难以理解）
        - 因此允许部分 event 依旧是 hardcode 或密集处理的，还需要引擎支持 PreTick, ImmediateTick, PostTick 操作
      + one-frame delays
        - 设计上天然导致了至少一帧的误差，及时性差（比如战斗打击感，第一帧受击，第二帧扣血并积累异常值，第三帧才触发爆血特效，几帧的差异那些动作天尊触手怪们是能感受出来的）
        - 因此在需要及时性的地方，可能需要一些 hardcode 专门处理
  - Event 系统中是否需要考虑 Priority？一般来说如果事件系统的正确性依赖于顺序，会导致 Publish-subscribe Pattern 两边的耦合性过强，另外也不方便并行化执行，因此尽量不要为事件预设优先级

== Game Logic and Scripting Languages 游戏逻辑与脚本系统
- 早期游戏逻辑可以直接写死在 c++ 里，而且效率可能更高，但这样不可持续，因为
  + 每次对游戏逻辑进行修改都要重新编译
  + 遇到错误代码时，很容易导致程序崩溃
  + 已发布游戏遇到 bug 时，难以进行热更新（打一个补丁就解决）
  + 玩法基本由设计师负责，他们不会写代码
- *Scripting Languages 脚本语言*
  - 工作机制：先被编译为 bytecode，再到虚拟机上运行
  - 优点
    + 可以快速迭代
    + 好学易上手，即使是策划也能将一些玩法用脚本实现
    + 热更新方便（热更新的本质就是用替换指针为新的实现，当然若函数中用到全局变量需要重置）
    + 运行在虚拟机沙盒上，可以自己 crash（立马重启脚本重新接入）而不会导致引擎 crash，更稳定
  - 缺点
    + 慢，但可以用 Just In Time (JIT) 优化，一边解释一边编译（一般会认为这种方式肯定比不过静态编译，但实际上 JIT 可以知道代码执行的路径，做得好甚至能比静态编译更快）
    + 弱类型语言在反射时不方便，可能需要看结果推测类型，效率低
  - 游戏引擎中比较受欢迎的脚本语言有 Lua, JavaScript 等，Lua 可能是最流行的（魔兽世界一己之力带火其在网游中的应用）。还有一些好像不算脚本语言但也是虚拟机运行且有很多库、使用方便的编程语言如 C\#， Python 也有一定应用
- *脚本语言的 GO 管理*
  - 脚本语言和引擎之间最难的问题就是对象生命周期的管理，到底是由引擎管理还是由脚本管理？
  - 引擎管理
    - 需要引擎对生命周期管理更严谨，否则内存泄露产生严重后果（尤其是 Cpp 写的），脚本访问对象时需要判断是否存在
    - 但是当玩法越发复杂时（比如突然创建出几个对象），在脚本中创建更方便而不是一定要到引擎里绕一圈
  - 脚本管理
    - 将 GO 的生命周期完全交给脚本负责，脚本创建 Garbage Collection (GC) 机制自动管理
    - 省事但慢，甚至吃掉 $10%$ 时间
  - 各有利弊，一般大型单机都是引擎直接管理，而玩法复杂的比如 MMORPG 一般用脚本管理
- *Architectures for Scripting System 脚本语言的架构*
  + 引擎包脚本：以引擎为主体控制 tick 的 flow，把某段特定处理写成脚本来调用
  + 脚本包引擎：主要玩法写脚本里，把引擎当成 SDK 库提供各种服务（现在用的少）

== Visual Scripting 可视化脚本
UE 的蓝图，Unity 的 Visual Scripting, Shader Graph 都是可视化脚本，这种形式对艺术家友好、符合他们的直觉，并且可视化更不容易产生错误（debug 非常方便）。

- Program Language 的概念与 BluePrint 的对应：
  + Variable: 每个变量有自己的 type 和 scope，在可视化脚本中用不同颜色的 pins 来指示类型，颜色相同才能用 wires 相连
  + Statement and Expression: 用专门的 expression nodes 和 statement nodes
  + Control Flow: 用 execution pins 和 execution wires 表示控制流
  + Function: 把一整个 Graph 打包成一个 node
  + Class: blueprint 本身就是一个类
- 可视化脚本的问题
  - 可视化脚本很难合并，会丧失语义且效率低下
  - 画 graph 的人之外很难理解（非线性网状的弊端），可读性差
- 可视化脚本就是脚本
  - 鉴于之前提到的问题，很多团队前期用可视化脚本，成熟后会翻译为代码

== Gameplay 中的 3C
3C 系统，Character, Control, Camera，是游戏体验的核心。要了解什么是 3C 系统，《双人成行》可以作为最好的案例

- *Character*
  - 移动：在之前所讲的动画混合之外，真正实现起来要考虑非常多的细节打磨（障碍、上下坡、起步、停下、滑行、滑冰、飞行……）
  - 与环境互动：雪地系统、音效、粒子等等
  - 真实物理互动：既要考虑人为控制又要考虑物理输入，一般用状态机控制各种状态，总之是大量的 animation script / graph 与 logic script / graph 结合的结果
- *Control*
  - 输入设备控制：鼠标键盘、手柄、方向盘、VR 设备等，甚至是手势识别、脑机接口
  - 操作优化：自动吸附、辅助瞄准、调整相机
  - Feedback: 振动或力反馈，键鼠 RGB 勉强也算
  - 按键组合：Context Awareness（同一输入在不同情景下效果不同）, Chord（同一时间的输入给予唯一行为）, Key Sequences（考虑历史输入打出组合）
- *Camera*
  - 相机并不只是完全固定在角色身后，而是随着角色跑动、走动等状态变化，相机远近大小焦距都跟着变化；有时又要放开相机的控制
  - Spring Arm: 当靠近墙时，保证相机不穿墙（有时又想要穿墙但降低透明度）
  - 相机效果：抖动、滤镜、各种后处理
  - 视角变化：第一第三人称切换、武器不同变化、载具不同变化，变化过程还需要插值
  - Subjective Feelings: 综合运用这些效果实现身临其境感、电影感，Camera 系统是一个性价比非常高的系统

= 游戏引擎的玩法系统：基础 AI
== Navigation 寻路系统
- 导航的基本思路
  + Map Representation
  + Path Finding
  + Path Smoothing

=== Map Representation
- *Walkable Area*
  - 让 AI 知道哪些部分可以通过，要考虑物理碰撞和走、跳、攀爬、载具等多种情况
  - 其表达方式有 Waypoint Network, Grid, Navigation Mesh, Sparse Voxel Octree 等。每种方式都有其优缺点，经常使用多种方式结合
- *Waypoint Network*
  - 早期游戏引擎使用很多，如同地铁一样，通过设置关键点、walkable area 的边界点以及算法插值出的中间点形成网状结构
  - 非常类似与地铁，寻路时有限找到最近的点，之后沿着路网抵达目标
  - 优点是好实现、效率高，缺点是不方便动态更新以及对 walkable area 的利用效率低（总走路中间）
- *Grid*
  - 对地图上的每个三角都转化成小网格，类似光栅化
  - 优点是便于动态更新、好实现、方便 debug，缺点是精确度取决于分辨率（过细还容易降低寻路算法性能）、存储空间浪费、难以表达三维地图
- *Navigation Mesh (NavMesh)*
  - 把 walkable area 用 convex polygon 或 triangle 表达出来，相对 Waypoint Network 的点线表达变成面的表达，并且解决 grid 难以表达三维层叠结构的问题
    - polygon 比 triangle 好处在于避免拉出细长的三角形，利用效率更高
    - 但要求每个 polygon 是 convex 的，否则进出同一个 polygon 可能会走出 walkable area；另一个好处在于每两个 convex polygon 之间的边 (Portal) 是唯一的
  - 优点是支持 3D、精确、快速、灵活、动态，因此是现代游戏引擎最普遍的方法；缺点是生成算法复杂，并且只能表达贴地寻路而无法表达飞行等情况
  - *NavMesh 的生成*
    - NavMesh 的生成其实比较困难，早期会让设计师手动拉出来，但现在基本是用开源库如 Recast 自动生成，之后再细调
    - 另外 Generation 不能继承之前的和设计师手调的结果，有任何更新都要重新做，也是一个很大的缺陷
    + Voxelize 成体素网格，然后标记出 walkable 的体素（通过坡度等计算）
    + 用 edge detection 方法找到离边缘最近的 edge voxel，得到 distance field
    + 找到局部的距离边缘最远的 voxel，使用洪水算法 (Watershed Algorithm) 向外扩散，类似之前讲过的 Voronoi 算法，得到对空间的划分
      - 这里实际上还有很多的细节，比如不允许 2D view 上 region overlapping，同一个 region 蔓延到自身底下时要截断等。这里不做过多展开
      - 2, 3 这两步合称为 Region Segmentation
    + 再通过进一步处理（比如连通区域变为凸多边形之类，比较复杂），就生成我们想要的 NavMesh
  - *Advanced Features*
    - Polygon Flag: 通过打标签的方式标记不同地形，从而可以控制寻路的优先级与可通过性、控制走上去的生效和粒子效果
    - Tile: 前面说了 NavMesh 的生成对动态变化不友好，可以通过地图分块的方式缓解这一问题。当然这里还有一些细节比如 tileSize 的考量、不同 tile 内生成的 NavMesh 要连接对齐等
    - Off-mesh Link: 允许建立手动的连接点，比如梯子攀爬（坡度过高会被 NavMesh 认为不可通过）、钩锁滑行等
- *Sparse Voxel Octree*
  - 把空间划分为八叉树体素，相当于把 grid 3D 化并做了八叉树优化，但存储消耗大的缺点依旧存在，另外它虽然生成比较方便但寻路比较麻烦。主要用于航天航空游戏

=== Path Finding
- 以上无论哪种方式都可以把几何元素的重心作为节点，生成边和权重，从而转化为在 graph 上的（近似）最短路径问题
- *经典算法*
  - Depth-First Search，时间换空间；Breadth-First Search，空间换时间
  - 但这两种方式都开销巨大，并且不能计算加权最短路径
- *Dijkstra Algorithm*
  - 可以解决有权图中最短路径问题，具体过程从略
  - 但游戏很多时候不需要最优而是近似即可（甚至最优反而不真实），因此一个启发式算法更符合直觉，引入 A-Star 算法
- *A-Star Algorithm*
  - 在 Dijkstra 的基础上，加入了启发式函数 (Heuristic Function)，即对每个节点除了从起点到此的准确代价外，再计算一个估计值（到目标的距离），从而加速搜索
    $ f(n) = g(n) + h(n) $
    - $h(n)$ 的选取比较讲究，要满足一些性质等等，一般越高越快收敛，越低越容易继续找到最短路径，这里从略
  - A\* on NavMesh
    - NavMesh 的 $g(n)$ 如何计算？如果直接把每个 polygon 的 centers 或 vertices 相连，可能会高估代价，采用 hybrid 方法又会导致过多 nodes。一般用 portal 的中心是一个比较好的 balance
    - NavMesh 的 $h(n)$ 如何计算？直接用粗暴的直线相连（取了个高大上的欧拉距离的名字）
  - A\* 的效率远远超过经典准确算法，而且游戏里有障碍物的情况其实不多，粗暴的启发式算法也能达到很好的效果

=== Path Smoothing
不管是 Waypoint Network, Grid 还是 NavMesh，直接得到的路径都是 zigzag 的，充满不必要的转弯，因此我们需要平滑化处理。对 NavMesh 可以使用 "String Pulling" – Funnel Algorithm

- *Funnel Algorithm 烟囱算法*
  - 实际上已经非常类似于人走路时对道路的感知，比较难以用语言描述，不如看图，以 2D 为例（推广到 3D 会更复杂）
  + 从起始点，把当前 polygon 的两端作为视野，看向下一个 polygon，如果被视野覆盖就看向下一个 polygon 并更新视野（以新的 polygon 的两端为视野）
  + 直到某个 polygon 被部分遮挡时，左边被挡就沿左视野走，右边被挡就沿右视野走，直到到达被卡视野的 polygon 的端点，重复进行上述过程
  + 如果迭代过程中发现终点就在视野里就直接走向终点
  #fig("/public/assets/CG/GAMES104/2025-04-06-12-47-40.png", width: 80%)
  #fig("/public/assets/CG/GAMES104/2025-04-06-12-47-51.png", width: 55%)

== Steering 转向系统
寻路系统以点、线为考量做出相对合理的路径规划，但对实际物体如载具，需要考虑它们本身的体积和不同的移动能力（油门、刹车、转向、加速度）等，需要对动作进一步调整以显得 Reasonable。

早期游戏中特别对载具相关的 NPC，它可能寻路系统严格遵守了 walkable area，但因为加入了更符合物理实际的 Steering 系统而走到了没有规划过的区域（寻路失效），如果物理模拟 tick 的步长再大那么一点，可能就卡在那一区域来回转动、抖动，进而被玩家玩弄。

- *Steering Behaviors*
  - Seek / Flee
    - 追踪移动目标或逃离目标，速度与加速度的调整，可能还会绕着目标震荡
    - 输入自身位置与目标位置，输出加速度
    - Seek / Flee Variations: Pursue, Wander, Path Following, Flow Filed Following
  - Velocity Match
    - 速度匹配，启动时的加速与快到达目标时的减速，在数学上需要一定处理，特别是对弧线时、双方共同运动时更复杂
    - 一般来说每个 tick 假设对方匀速运动算出自身的加速度而不用完全掌握对方信息（真实世界也是如此），也能算出不错的结果
    - 输入自身速度与目标速度以及匹配时间，输出加速度
  - Align
    - 朝向匹配，要考虑角速度、角加速度，如 NPC 看向主角、群体朝向同一方向等
    - 输入自身朝向与目标朝向，输出角加速度

== Crowd Simulation 群体模拟
现代 AI 经常要处理群体情况，比如城市中的人群、四散的动物……群体模拟需要做到：避免碰撞、成群的来回移动 (Swarming)、编队运动 (motion in formation)。

- *群体模拟模型*
  - 图形学大牛 Reynolds（他也是 Steering 系统的开山鼻祖）提出的 Boids 模型将 Crowd Simulation Models 分为三类
    + Microscopic: 微观方法，自底向上地定义每一个体的行为，合起来组成群体行为
    + Macroscopic: 宏观方法，定义群体宏观的运动趋势，所有个体按照该趋势移动
    + Mesoscopic: hybrid 方法，将群体分组，既有宏观的趋势也有微观的个体行为
- *Microscopic 微观方法*
  - 基于规则的模型，用简单规则控制每个个体的运动
    - 分离 (Separation)：避开自己的所有“邻居”（斥力）
    - 凝聚性 (Cohesion)：朝向群体的“质心”移动
    - 一致性 (Alignment)：和邻近的对象朝向同一个方向移动
  - 简单易实现，但不适合模拟复杂行为规则，且在宏观上不可控、不受人影响
- *Macroscopic 宏观方法*
  - 人群的运动暗含某种规则，不会像鱼群那样撞到就让开，随机找方向走，如同无头苍蝇。这种就很适合用宏观方法模拟
  - 从宏观的角度模拟人群的运动，用势能场、流体力学控制运动，不会考虑个体间的交互和环境对个体的作用
  - 把区域划分成 zone graph，让人沿着 lane 行走，既要避免 lane 之间的频繁切换，又要在十字路口允许分叉
- *Mesoscopic 方法*
  - 结合了微观和宏观的方法，群体分为很多小组，每组分别运动
  - 既指定了宏观的目标位置，又让个体以微观规则调整行为，最典型的应用就是 RTS 游戏里的单位移动
- *Collision Avoidance 避免碰撞*
  - 相比群体同时寻路 (Path Finding, Path Smoothing) 的巨大开销，给一个大体目标然后用避免碰撞的方式来调整行为是一个更廉价的选择，下面两种方法成为引擎的标配
  - Force-based Models 基于力的模型
    - 使用距离场给障碍物增加一个反向力
    - 好处是可以被拓展去模拟更慌乱的人群的行为；坏处是类似于物理模拟，模拟的步长应该足够小
  - Velocity-based models 速度障碍法
    #fig("/public/assets/CG/GAMES104/2025-04-06-14-30-34.png", width: 80%)
    - Velocity Obstacle (VO)：其它方向走来的物体在速度域上形成障碍，如果判断产生碰撞就需要调整速度比如靠左避让
    - Reciprocal Velocity Obstacle (RVO)：在 VO 的基础上考虑相互性（假设对方采取相同的决策行为）
    - Optimal Reciprocal Collision Avoidance (ORCA)：当参与的对象不止两个时，$A, B$ 之间的避让可能又会影响到 $C$。数学上非常复杂，“空间上的所有速度在一段时间内形成速度空间上呈羽毛球状的锥形区，用闵可夫斯基求和并求一个对所有对象公平的子节点”，听不懂
    - 总之这类算法虽然确实可以找到理论最优且优雅的解，但写起来非常复杂，处理不好会导致计算复杂度很高，在易实现这方面不如基于力的模型

== Sensing 感知
- 对世界、环境的感知是人类和 AI 决策的依据，分为内部和外部信息
  - Internal Information
    - 智能体自己的信息，如位置、血量、护甲、buff 等，可以自由方便地获取（之前讲的脚本系统，很方便获取一系列属性）
  - External Information
    - Static Spatial Information: 如 Navigation Data、战术地图 Tactical Map、可交互物体 Smart Object、掩体点 Cover Point 等
    - Dynamic Spatial Information
      - 如因子图 Influence Map（热力图，有很多维度，比如动态更新的危险系数）、动态寻路数据 Marks on Navigation Data、视野 Sight Area
      - 以及最重要的 GameObjects 数据，包括 ID、互相的可见性、威胁度、上一次感知时的所用的方法和所处的位置……

总之，这些都非常类似人类对世界的感知（并不是上帝视角），有视觉、听觉并随距离衰减，有活动范围、视野等，但如果感知太多会影响性能，因此一般会取舍几个，并范围内共享信息。

实际上讲到这里很多部分已经超出引擎的职责范围，而更多是由游戏开发组自己设计的，引擎需要做的是提供开放的接口、定义感知的精度，把自主权开放给上层。

== Classic Decision Making Algorithms 经典决策算法
决策算法是 AI 的核心，上述的寻路、转向、感知等都只是决策算法的基础。

- 决策算法一般分为
  + *Finite State Machine (FSM) 有限状态机*
  + *Behavior Tree 行为树*（AI 最核心的体系）
  + Hierarchical Tasks Network 层次任务网络
  + Goal Oriented Action Planning 目标驱动的行为计划系统
  + Monte Carlo Tree Search 蒙特卡洛搜索树
  + Deep Learning 深度学习
  - 前两种是 forward planning，后四种是 backward planning，之后再讲

=== Finite State Machine 有限状态机
- 根据某些条件 (Condition) 转换 (Transition) 一个状态 (State) 到其他状态
- 好处：容易执行、容易理解，对简单例子应对起来非常快（比如吃豆人的状态机可以用 $3$ 个 state 和 $6$ 个 transition 表达）
- 坏处：可维护性差，特别是添加和移动状态；重用性差，不能被应用于其他项目或角色；可扩展性差，很难去修改复杂的案例
- 改进：Hierarchical 有限状态机 (HFSM)
  - 把状态机分为很多层或模块，每层状态机之间有相互的接口，内部复杂度可控
  - 好处是增加可读性，部分解决上述问题；但坏处是会造成一定的性能下降，难以跳模块，反应速度也会下降
- 属于古老的方法

=== Behavior Tree 行为树
状态机是对人类行为的抽象，但人类真实思考不是像状态机那样一团乱麻、跳来跳去，也不完全是列出 $1, 2, 3$ 的条件支撑做出最后的决策，而是以一个树状的结构，通过一个个分支抵达最终的抉择（Behavior Tree 的祖宗是决策树 Decision Tree）。

- *Execution Nodes 执行节点*
  - 分为 Condition Node 和 Action Node
  - 前者感知自我或环境状态，立马执行完返回 true / false；后者有一定执行过程，返回 success / failure / running
  - PreCondition: 把 Condition Node 和 Action Node, Control Node 结合从而简化行为树（语法糖）
- *Control Nodes 控制节点*
  - Sequencer Node 顺序执行：从左到右顺序遍历子节点，直到某个节点失败或所有节点成功
  - Selector Node 条件执行：根据条件和优先级尝试所有子节点，一旦某个子节点满足条件，立马执行该行为
  - Parallel Node 并行执行：一个智能体同时进行多个行为
  - Decorator Node 装饰节点：起修饰作用，例如循环执行、执行一次、计时器、定时等（语法糖 again）
#fig("/public/assets/CG/GAMES104/2025-04-06-15-21-22.png", width: 80%)
- *Tick a Behavior Tree*
  - 状态机只需要每次 tick 检查当前 state 所有 transition 的 condition，而行为树要考虑的就多了
  + 每一 tick 更新都要从根节点开始判断，否则可能一些行为的更新不够及时
  + 对于根节点开始导致的效率问题，可以做一定优化，比如修改为从上一帧节点继续，但设置一些 event 激活某些子树或重置到根节点；或者像 UE 那样做 State Tree
  + 同时在 running 的动作可能不止一个，只要符合行为树的规范即可
  + 行为之间要有优先级
- *Blackboard*
  - 用于记录行为状态 (memory)，把数据与逻辑分离，在行为树的不同分支能够交换信息
- *行为树的优点*
  + 模块化、层级组织（每个子树可以被看作是一个模块）
  + 可读性高，用 $5$ 类节点就把智能体甚至人类的行为模拟出来
  + 容易维护，并且修改只会影响树的一部分
  + 反应快，每个 tick 会快速的根据环境来改变行为
  + 容易 Debug，每个 tick 都是一个完整的决策
- *行为树的缺点*
  + 如果不优化，每个 tick 都从根节点触发，会造成更大的开销
  + 反应性越好，条件越多，每帧的花销也越大
  + 机械式地执行动作，没有 high level goal $->$ AI Planning

= 游戏引擎的玩法系统：高级 AI
== Hierarchical Tasks Network 层次任务网络
HTN 经典且应用广泛，它 Make a Plan Like Human，从任务或目标出发，把目标分为几个步骤，步骤内可以包含不同选项，并根据自身状态选择合适的行为一次完成步骤，完全类似人的思考过程。

- *HTN Framework*
  - World State：取名不好，AI 对世界的主观认知而不是客观描述，反馈到 Planner
  - Sensors：即 Perception，传感器、感知器，从游戏中抓取状态
  - HTN Domain：层次化树状 tasks
  - Planner：从 World State 和 HTN Domain 生成计划
  - Plan Runner：执行计划，更新 World State，当然可能不会一帆风顺而需要 RePlan
- *HTN Task Types*
  - Primitive Task 基本任务
    - 表示一个具体的动作，每个 primitive task 都有 Precondition (world state properties)、Action、Effects (modify properties) 三要素
    - Precondition 用于读取状态，Action 作用于客观真实世界，Effects 更新状态（只有对 World State 有影响才写到这里）
  - Compound Task 复合任务
    - 由很多 method 构成，每个 method 有自己的 Precondition，其内部可以是 Primitive Task 或者 Compound Task
    - methods 按照一定的优先级组织起来，执行时按照优先级选择，全部执行完毕返回 true（类似于结合了行为树的 selector 和 Sequencer）
  #fig("/public/assets/CG/GAMES104/2025-04-06-16-49-54.png", width: 80%)
- *Planning*
  + 从 root task 开始检查 precondition，选择一个满足条件的 compound task
  + 对这个当前指向的 compound task，展开进行以下操作
    + 先把 world state 拷贝一份，然后检查 precondition
    + 如果满足，就假设这个 task 里的 action 全部可以执行成功，并把其 effect 修改到拷贝的 world state 里
      - 这里假设全部完成实际上是带着目的的预测，跟人类对未来的假想非常像，这里就跟 BT 展现出不同
      - 同时这些 action 可能持续时间很长而环境会发生变化，但没关系也假设成功，后续 Replan 会解决这一问题
    + 如果不满足，就层层返回 false，去选择下一个 task
  + 重复第二步直到没有 task 为止
- *Run Plan*
  - 最终，Plan 输出遍历过程中经历的一串 Primitive Task，交给 Plan Runner 执行
  - 如果发现 Plan 得好好的但执行失败了，就需要 Replan
- *Replan*
  - 需要 Replan 的情况
    + 当前没有 plan
    + 当前的 plan 执行失败或成功执行完成
    + Sensor 感应到 World State 发生变化
- *总结*
  - 优点
    + HTN 类似于对 BT 的 high level 包装简化，同时其 hierarchical 的设计更符合人的直觉；
    + 它输出的 plan 带有目的和 long-term effect
    + 在同 case 下它一般比 BT 更快
  - 缺点
    + 由于用户行为不可预测，因此 task 很容易失败，特别是在高度不确定性的环境里，如果 HTN 链路做太长很容易震荡
    + world state 与 effect 的设计是一个挑战，比如设计师可能忘记设置某个条件、效果，需要程序这边做一些静态检查

== Goal Oriented Action Planning 目标驱动的行为计划系统
GOAP 这一方法更加自动化，比前述方法一般会更适合动态环境。

- *GOAP Structure*
  - GOAP 的整体结构与 HTN 非常相似，Sensor, World State 的定义相同；Domain 被替换为 Goal Set 和 Action Set；输出的 Planning 是一系列 Action，比起在 HTN 中称为 “计划” 这里更应称为 “规划”
  - *Goal Set 目标集合*
    - 在 HTN 中，“目标” 这一概念其实没有显式定义（设计师写在注释里），而是由几个 task 组成；而 GOAP 中的目标有严格数学定义
      - 把目标定量地表达出来而不是隐含在 tree 结构里，是 GOAP 的一个核心不同
    - Goal 有 Precondition, Priority, States 三个属性，States 集合就是用来描述目标的，一般用几个 bool 值表示
  - *Action Set 行为集合*
    - 每个 Action 类似之前的 Primitive Task，在 Precondition, Action, Effect 之外又加了 Cost 属性
    - GOAP 中没有树状结构把所有动作串在一起，要用 Cost 来选 Action。Cost 是由开发者定义的代价权重，用于排序优先级
- *Backward Planning*
  - GOAP 在规划时会从目标 Backward 推导需要执行的动作，是一种类似人类的思考方式
  + 在以优先级排序的 Goal Set 中选取一个 Precondition 满足的目标，下面尝试达成它的 State
  + 筛选目前 World State 中没有满足的，放入 Unsatisfied States Stack
  + 从 State Stack 的栈顶开始，找到 Effect 能够满足它的 Action，把这一 State 移除，并把 Action 加入 Plan Stack
  + 如果这一 Action 的 Precondition 也不满足，就加入 Unsatisfied States Stack（为了满足某个 State 而执行的动作又产生新的需求）
  + 重复上述过程，直到 Unsatisfied States Stack 为空，Plan Stack 中的动作就是最终的计划
  - GOAP 中除了令 Unsatisfied State Stack 为空即能够达成目标之外，另一个核心的点在于如何选择最小 Cost 路径达成目标
  - 这包括如何选择 Goal、如何选择 Action，可以转化为路径规划问题，用代价图求解
- *Build States-Action-Cost Graph*
  - 有向图的 Node 是 States 的组合；Directed Edge 是各种 Action 以及其 Cost，要求 Precondition 满足其出发节点的 State
  - 要从起点（Goal 的 States）到达终点（当前 World State），这样整个规划问题就等价于有向图上的最短路问题
    - 也就是从终点出发倒推模拟回当前状态（实际上我觉得这种图的理解比刚才 Stack 的理解更直观）
  - 构建 Graph 后，可以用 A\* 算法求解，用不满足 State 的个数作为启发式函数。另外，A\* 不能保证最优的特点又恰恰可以引入随机性、真实性
- *总结*
  - 优点
    + 比起 HTN 更加动态灵活
    + 更够解耦 AI 的目标与行为：无论是 FSM, BT, HTN，它们达成目标的行为都是通过一个拓扑结构锁死的，而 GOAP 在给定目标后随机出的结构有时令人类都非常惊讶
    + HTN 容易导致 Precondition / Effect 不匹配的错误，导致死锁，而 GOAP 中智能体的行为不是由设计师预设的
  - 缺点
    + 比 BT, FSM, HTN 都慢（HTN 最快）
    + 如果真正把决策交给 GOAP，需要对 World State 和 Action Precondition / Effect 做出精细的定量表达

== Monte Carlo Tree Search 蒙特卡洛搜索树
后面的蒙特卡洛树搜索和深度学习都跟机器学习领域的 AI 强相关，也算是我个人的老本行了，就记得简单一点。

- MCTS
  - Iteration Steps: Selection, Expansion, Simulation, Backpropagation。
  - Selection
    - 选择可能性没有穷尽的 node (expandable node)
    - exploration & exploitation $->$ UCB
  - Expansion
    - 扩展 node，添加子节点
  - Simulation
    - （多次）随机模拟游戏，直到结束
  - Backpropagation
    - 反向传播，更新 node 的值
  - Choose the Best Move
    - Max child、Robust Child（鲁棒性一定程度上已经反映了 $Q/N$）、Max-Robust Child、Secure Child（LCB，UCB 翻版）
- 总结
  - 优点：表现更多样化（有随机数），AI 全自动决策，适合搜索空间巨大的决策问题
  - 缺点：计算复杂度大所以难以用在实时游戏中，并且复杂游戏中也难以准确定量定义状态和行为
  - MCTS 适合回合制、行动数值反馈明显的游戏

== Machine Learning 机器学习
- Machine Learning 四种类型
  - Supervised Learning, Unsupervised Learning, Semi-supervised Learning, *Reinforcement Learning*（游戏中最重要）
- Markov Decision Process (MDP) 马尔可夫决策过程
  - State, Reward, Action, *Policy*
- Build Advanced Game AI
  + State (Observation)
  + Action
  + Reward
  + NN Design
  + Training Strategy
- 在控制一些宏观行为的时候可以使用神经网络，在控制细节行为的时候可以用设计师配置的行为树等等（什么你说很有钱？那没事了）

= 网络游戏的架构基础
- 网络游戏和单机游戏相比有很多难点，比如
  + Consistency: 如何在保证每个玩家的游戏状态是一致的、如何进行网络同步
  + Reliability: 如何处理延迟、丢包和重连
  + Security: 如何反作弊、反账号篡改
  + Diversity: 如何处理不同的设备和系统，以及这么多设备系统的热更新
  + Complexity: 极高的 Concurrency, Availability 要求极高的 Performance

== Network Protocols 网络协议
=== 传统网络协议
网络协议要解决的核心问题是实现两台计算机之间的数据通信。随着软件应用和硬件连接变得越来越复杂，直接进行通信非常困难，因此人们提出了中间层 Intermediate Layer 的概念来隔绝掉应用和软件，让开发者专注于程序本身而不是具体通信过程。

在现代计算机网络中人们设计了 OSI 分层模型来对通信过程进行封装和抽象。一般来说我们只用在最上层的 Application 混一混就行了，如果对这七层协议了解的话，可以对其中冗余的地方进行底层优化。

- *Socket*
  - 网络游戏开发一般不需要很底层的通信协议，大多数情况知道如何使用 socket 建立连接即可
  - socket 是一个简单的结构体，只需要知道对方的 IP 和 Port 就可以
  - Setup socket 时，需要考虑 domain 是 IPv4 还是 IPv6，type 是 TCP 还是 UDP，protocol 一般是 $0$
  #align(center)[`int socket (int domain, int type, int protocol)`]
- *Transmission Control Protocol 传输控制协议*
  - TCP 是最经典也是著名的网络协议，它连接牢靠，可以按顺序接收，还可以进行流量控制（网络差时可以降低发包效率）
  - Retransmission Mechanisms: TCP 的核心原理。这个机制要求 Receiver 接受到消息后向 Sender 发送 Acknowledgment (ACK) 确认消息已经收到，Sender 收到后就可以继续发下一个包，否则反复发送
  - Congestion Control: TCP 会根据 loss 的数量主动调整 Congestion Window (CWND)，避免网络拥堵。这有效地保证了服务器不被堵死，但也导致 high delay 和 delay jitter（带宽一上一下，并且前置消息收不到后续的也都被卡住）
- *User Datagram Protocol 用户数据报协议*
  - UDP 的发明者也是 TCP 发明者之一，本质是一个轻量级的端到端协议，其特点是
    + Connectionless，不需要握手（长时间连接）
    + 不管 Flow Control 和 Congerstion Control
    + 不保证顺序和可靠性
  - 因为简单，所以开销小，包头只有 $8$ 字节（TCP 有 $20$ 字节）
- 现代网络游戏需要根据游戏类型不同来使用合适的网络协议
  + 对实时性要求高的游戏会优先选择 UDP
  + 策略类、时间不敏感的游戏则会考虑使用 TCP
  + 大型 MMO 游戏会使用复合类型，比如登录、聊天、邮件用 TCP，战斗用 UPD
  + 说是这么说，但其实一般会根据具体需求魔改出 Reliable UDP，或者用第三方库

=== Reliable UDP
- TCP 复杂又笨重，UDP 轻量但不可靠，有没有办法结合二者优势呢？有的兄弟，有的。现代网络游戏往往会基于 UDP 定制网络协议，采用第三方协议或完全自定义
- 我们想要什么？Game Server 应该做到
  + 链接保活 (TCP)
  + 一定的逻辑顺序 (TCP)
  + 快速响应低延迟 (UDP)
  + 支持广播 (UDP)
- *一些概念*
  - Positive acknowledgment (ACK) & Negative ACK (NACK or NAK): 确认某一信息收到或没收到
  - Sequence Number (SEQ): 序列号，TCP 中的重要概念，标记主机发出的每个包
  - Timeouts: 超时时间，时间过长就不管它
- *Automatic Repeat Request 自动重传请求*
  - ARQ 是基于 ACK 的错误控制方法，所有通信算法都要实现 ARQ 功能，一个常见的方法是使用 *Sliding Window Protocol 滑动窗口协议*
  - 滑动窗口协议按 SEQ 的顺序发包，每次发送 `window_size` 个，等待 ACK，接受多少滑动多少。分几种策略
    + Stop-and-Wait ARQ: `window_size = 1`，每次只发一个包，等待 ACK 后再发下一个包，太笨了没人用
    + Go-Back-N ARQ: 没接收到 ACK 时，会回头把包含那个包的整个窗口都重发
    + Selective Repeat ARQ: 只重发没有收到 ACK 的包 (NARK)，效率高但实现复杂
- *Forward Error Correction (FEC)*
  - UDP 不保证可靠性，需要引擎自行考虑，我们在自定义网络协议时一般会结合 FEC 方法让丢包数据也能自动恢复，避免反复发送，一般属于空间换时间
  + XOR FEC 异或校验位: 使用异或运算恢复丢失的那一个包（如果多个包丢失则无效）
  + Reed-Solomon Codes: 利用 Vandemode 范德蒙矩阵及其逆矩阵来恢复丢失的数据，可以覆盖丢包率高的场景

== Clock Synchronization 时钟同步
就好像相对论，每个人接受到的时间都是局部的，需要进行同步。

- *Round Trip Time (RTT)*
  - 客户端向服务器端发送一个包后都需要等待网络通信延迟导致的一定时间才能收到回包，这个间隔的时间称为 RTT
  - 类似于 ping 的概念，区别在于 ping 更偏底层，而 RTT 一般是应用层自己写的
  - 跟 latency 的区别在于，latency 是发出端到接受端的单向时间，而 RTT 是双向的
- *Network Time Protocol (NTP)*
  - 时间同步其实是一个 well-studied 问题。一般会设定一个 Reference clock，要求极度精确（比如原子钟），使用无线电或光纤而不是网络来传输（因为网络延迟不稳定），然后通过 Time Server Stratums 的概念一层层同步
  - 游戏中一般不会有多层，Server 作为 Reference Clock，Client 通过网络与其同步即可，具体而言：
    + Client 在 $t_1^c$ 向 Server 发送消息，Server 在 $t_2^s$ 收到消息，随后又在 $t_3^s$ 发送回包，Client 在 $t_4^c$ 收到回包
    + NTP 假设网络上行下行延迟相（做了个平均）且没有波动，算出时间偏差为
      $ t_"offset" = frac((t_2^s - t_1^c) + (t_3^s - t_4^c), 2) $
    + Client 本地的时间通过 offset 来校正
      $ t_"corrected" = t^c + t_"offset" $
  - 实践中往往通过多次 NTP 得到一系列 RTT 值，把高于平均值 $50%$ 的部分丢弃（波动、不可靠），剩下的平均值的 $1.5$ 倍用作真实 RTT 的估计

== Remote Procedure Call (RPC) 远程过程调用
- 利用 socket 可以实现客户端、服务端通信，但完全基于 socket 的通信非常复杂，因为
  + 网络游戏中客户端、服务端要发送大量不同类型的消息和相应反馈，都要打包成对应网络协议，导致游戏逻辑无比复杂
  + 客户端和服务器有不同的硬件和操作系统，它们的语言、数据类型大小、大小端、数据对其要求可能都不一样
  - 因此现代网络游戏一般会使用 RPC 方式实现通信，在客户端可以像本地调用函数的方式来向服务器发送请求（复杂度解耦），使开发人员可以专注于游戏逻辑而不是具体网络协议实现
- *RPC*
  - Interface Definition Language 界面定义语言：跟之前在工具链讲过的 Schema 是共通的概念，例如 Google ProtoBuf 等
  - RPC stubs：在启动时，Stub Compiler 编译 IDL，Server / Client 端的程序员实现自己侧的逻辑并链接到自己侧的 stubs，明确双方有哪些 RPC 可以调用，如果调用的 RPC 不存在就返回报错但不会让程序 crash
  - Real RPC Package Journey: 真实游戏中的 RPC 在实际进行调用时还有很多的消息处理、压缩解压缩和加密工作

== Network Topology 网络拓扑
设计网络游戏时还需要考虑网络自身的架构。

- *Original Peer-to-Peer (P2P)*
  - 每个客户端之间直接建立通信，任何一个客户端的时间需要 broadcast 到所有其他客户端
  - 现在用的较少，一般用于双人点对点游戏，或者比较抠 or 穷没有服务端的游戏
- *P2P with Host Server*
  - 当 P2P 需要集中所有玩家的信息时，选择其中一个客户端作为主机，其它客户端通过连接主机实现联机
  - 主机的处理性能、网络质量很影响所有人的体验，现在很多需要房主开房、开服的游戏都是这个模式
- *Dedicated Server 专用服务器*
  - 现代的大型商业网络游戏必须使用专用服务器，从而能够同步所有玩家的状态
  - 为了满足不同网络条件的玩家的需求，运营商可能还需要自己建立网络线路（一般直接走光缆专线）

== Game Synchronization 游戏同步
即使我们已经做了时钟同步，但由于延迟客观存在，不同玩家视角下的对方可能有不同的行为表现，需要有游戏同步技术来保证玩家体验的一致性。目前常用的同步技术有 Snapshot 快照同步、 Lockstep 帧同步（锁步同步）和 State Synchronization 状态同步。

=== Snapshot Synchronization 快照同步
- *Snapshot Synchronization*
  - 客户端只负责发送输入到服务端，其它所有逻辑都在服务端处理。服务端把整个游戏的状态生成为一个快照，再发送给每个客户端给玩家反馈
- *Snapshot Interpolation*
  - 快照同步在 Performance, Bandwidth 方面均给服务器提出了非常巨大的挑战，导致 Jitter and Hitches
  - 实际游戏中一般会降低服务器上游戏运行的帧率，在客户端上通过插值的方式提高帧率 (Keep an interpolation buffer)
- *Delta Compression*
  - 每次生成快照的成本相对较高，为了压缩数据可以使用状态的变化量来对游戏状态进行表示
- *总结*
  - 优点：非常简单也易于实现
  - 缺点：基本浪费客户端算力，同时在服务器上产生过大的压力
  - 现代网络游戏基本不会使用

=== Lockstep Synchronization 帧同步
- Lockstep Origin and in Online Game
  - Lockstep 最初来源于军队的步伐同步，在 same time 做出 same action，拓宽到游戏上，类似于把世界变成回合制
  - 很明显，所有生成的事件都按照相同的唯一顺序交付是确保不同节点之间游戏状态一致性的充分条件
  - 在帧同步中，服务器更多地是完成数据的分发工作 (dipatch)，其宗旨为
    $ "Same Input" + "Same Execution Process" = "Same State" $
- *Lockstep Initialization*
  - 使用帧同步时首先需要初始化，将客户端上所有游戏数据与服务器同步，一般在游戏的 loading 阶段完成
- *Deterministic Lockstep*
  - 所有客户端在每一轮将玩家数据各自发送到服务器上，服务器接收到所有数据后再统一转发给客户端，然后由客户端执行游戏逻辑，整个过程公平而确定
  - 当然其缺陷也很明显，游戏进程取决于最慢的用户。当某一玩家滞后甚至掉线，所有玩家都得等待，并且这种延迟是不固定的。这种情况在早期联网游戏中很常见
- *Bucket Synchronization*
  - 对原始 Lockstep 进行一定改进，服务器只等待 bucket 长度的时间，如果超时没有收到就直接跳过，看下一个 bucket 能否收到
    - 弹幕：LOL 会给没有收到的玩家赋予默认操作走回泉水
    - 网络游戏设计中一般有两种策略：网络差者获利与网络好者获利，前者可能导致可以通过拔网线等方式争取更多的反应、决策时间（例如《马里奥制造》）。Bucket Synchronization 可以算是后者
  - Bucket Synchronization 本质是对玩家数据的一致性以及游戏体验进行的一种权衡
- *Deterministic Difficulties*
  - 帧同步的一大难点在于要保证不同客户端上游戏世界在相同输入下有完全一致的输出。否则，一整局游戏只有最开始的同步，在后续不断的演化下极易产生蝴蝶效应
  - 在物理引擎部分我们描述过这一概念的难点，在不同客户端上要保证
    + 浮点数一致性：使用 IEEE 754 标准表达，但不同平台上行为可能不同，一种方法是使用 Floating Point Numbers，但应用并不广泛
    + 随机数一致性：使用相同的种子和伪随机数生成算法
    + 各种容器和算法的一致性：挑选确定性的容器和算法
    + 数学运算函数一致性：查表法，把 $sin, cos$ 等的结果定死
    + 物理模拟一致性：很难
    + 代码逻辑执行顺序一致性
  - 完全确定性的保证几乎不可能，好消息是，只用把核心的业务逻辑如角色移动、伤害、血量等影响结算的游戏状态做成确定性的，如渲染等可以不确定
- *Tracing and Debugging*
  - 现代网络游戏的逻辑十分复杂，可能无法避免地出现一些 bug，引擎需要为上面的应用层提供追踪功能
  - 一般我们要求客户端定时记录游戏状态，例如使用 checksum 技术存储数据，又如把所有关键函数的 core, parameter 变成哈希值存下来，每隔一定时间上传本地 log。服务器自动比较 logs，定位哪一帧、哪一步运算出了 bug
- *Lag and Delay*
  - 帧同步并没有真正解决延迟和抖动问题。对抖动问题，可以通过在客户端上用 buffer 缓存若干帧来解决（类似视频网站缓存），当然缓存帧越大延迟越高
  - 另一方面可以把游戏逻辑帧和渲染帧分离（一般渲染帧数会更高），客户端通过对渲染帧插值的方式获得平滑效果
    - 逻辑、渲染的解耦使画面不会因为网络原因出现抖动，同时也可以结合之前说过的垂直同步 V-Sync 来避免撕裂现象，另外对后面的断线重连也有一定好处
  - 更进一步，甚至对动作都可以进行插值，以及评论区提到客户端可以对用户输入进行一定预测（类似后面状态同步的做法）
- *Reconnection Problem*
  - 帧同步时，客户端每隔若干帧会设置一个关键帧，更新游戏世界的快照，保证即使游戏崩溃了也可以从快照中恢复。服务器端也可以保存快照，当客户端断线过久时采用服务器端快照恢复
  - quick catch up: 为了从关键帧快照追赶队友的当前帧（追帧），暂停关闭渲染，全力执行游戏逻辑，每秒能追很多倍
  - Observing: 服务器端保存快照的另一个作用是实现观战和回放功能，它们的实现机制跟断线重连是一致的
- *Lockstep Cheating Issues*
  - 帧同步中，玩家可以通过发送虚假的状态来实现作弊行为，因此要有反作弊机制
  - 对于多人游戏，可以使用投票机制，所有玩家都会发送校验码 checksum，找出哪个玩家进行作弊
  - 对于双人游戏，单个玩家无法确定作弊，服务器端也必须保存校验码，如果服务器没法验证就无计可施（当然，双人情形作弊只有一个玩家收到损害，相对不严重，而且一般双人游戏用 P2P 实现即可）
  - 但帧同步的机制本来就是客户端上存储了所有的游戏信息，因此还是容易出现通过作弊破解 “战争迷雾” 而得到全局信息，而这是校验码无法避免的。现在的帧同步游戏会用很多方法、策略来规避这个问题
- *Lockstep Summary*
  - 优点
    + 占用带宽少，适合需要实时反馈的游戏
    + 解决 determinism 问题后开发效率高，类似单机游戏
    + 适合对打击操作敏感的游戏（状态同步）
    + 方便做观战、录像、回放
  - 缺点
    + 一致性很难保持
    + 全图挂难以解决
    + 断线重连机制设计得不好会导致需要很长时间恢复

=== State Synchronization 状态同步
状态同步是目前大型网游（比如 MMORPG）非常流行的同步技术。

- *State*
  - 帧同步的基本思想是每个客户端提交和服务端发放都只针对部分状态，即为了表示游戏世界所必要的量 (e.g. HP, MP)
  - 如果游戏世界太过复杂，可以设置 Area Of Interest (AOI) 来减少同步数据
- *Server Authorizes the Game World*
  - 状态同步跟快照同步、帧同步很大的不同在于，服务端在收到所有玩家数据后会运行游戏逻辑，模拟一整个游戏世界，然后把下一时刻的状态按需分发给用户（放作弊能力稍强一些），客户端接受状态并模拟本地的游戏世界
- *Authorized and Replicated Clients*
  - 状态同步中，服务器称为 authorized server，是整个游戏世界的绝对权威；玩家的本地客户端称为 authorized client，是玩家操作游戏角色的接口；在其他玩家视角下的同一角色则称为 replicated client，仅仅是 authorized client 的一个副本
- *State Synchronization Example*
  - 以一个射击游戏击中敌方的过程为例
  + 玩家 A (Authorized) 在本地按下开火键，将这一行为发送给 Server
  + Server 收到信息后，将玩家 A 的开火行为广播给所有玩家 A, B, C, D
  + 玩家 A 收到 Server 端确认后才开火；玩家 B, C, D 视野中的玩家 A (replicated) 也会开火（本地模拟），但并不负责击中效果的结算
  + 同一时刻 Server 端模拟玩家 A 的开火行为，结算并判定其击中玩家 B，发生扣血、爆炸等事件，并广播给所有玩家
  - 可以看到，状态同步非常大的一个好处在于它不要求各个 Client 的模拟是 deterministic 的，结算由 Server 来完成，整个游戏世界本质上是由统一的服务器驱动；另外，它可以只同步部分发生变化的状态以及各个玩家可见的状态，节省带宽
- *Dumb Client Problem*
  - 游戏角色的所有行为都要经过服务器确认才能执行，client 的操作总是会有一定滞后
  - 要缓解该问题可以在 client 端对玩家的行为进行预测。比如当角色需要移动时，首先在本地移动半步 (Client-side prediction)，等到服务器确认可以移动后再进行对齐 (reconciliation)
  - Client-side prediction: client 总是领先于 server half RTT 程度的动作，即时响应输入并维护一个 buffered command frame (Ring buffer)
  - Reconciliation: 来自 server 端的消息跟 buffer 中 half RTT 前的消息对比，如果不一致就以 server 为准，退回到该状态并 replay buffer 中的后续操作
  - 这个机制是典型的网络差者不利，他们的角色状态会不断地被服务器修正（例如 Apex 的闪回、吞子弹，网络差到一定地步连路都走不动）
- *Packet Loss*
  - 对于丢包的问题，状态同步方法可以在 server 端为每个 client 维护一个 tiny input buffer
  - 如果发生丢包（server 端一定时间内没有收到信息，表现为 run out of buffer），server 会 duplicate 最后一个输入
- *帧同步和状态同步两种主流同步技术的对比*
  #csvtbl(
    ```
    , Lockstep Synchronization, State Synchronization
    Deterministic Logic, 必要, 不必要
    Response, Poor, Better
    Network Traffic, 通常低, 通常高
    Development Efficiency, 开发容易，调试困难, 复杂得多
    Number of Players, 支持少量玩家, 支持大量玩家
    Cross Platform, 相对困难, 相对容易
    Reconnection, 相对困难, 相对容易
    Replay File Size, 小, 大
    Cheat, 相对容易, 相对困难
    ```
  )
  - 一般来说，帧同步比较适合网络较好、特定类型的游戏，状态同步比较适合网络不稳、游戏业务复杂、玩家数量多的大型游戏
  - 目前商业引擎做状态同步比较多（缺省行为），而帧同步则需要游戏团队做额外修改、加 hardcode

= 网络游戏的进阶架构
== Character Movement Replication 角色移动复制
角色 A 的行为到 server 端产生了一定延迟和抖动，到另一个角色 B 的视角下延迟和抖动更大。这个问题在前面部分实际上已经部分讨论，在 Lockstep 中我们针对抖动问题，说把游戏逻辑和渲染分开，对渲染帧进行插值来平滑动画效果；在 State Synchronization 中我们说可以对玩家的自己行为进行预测和修正。这一 part 就是单独把这个问题拉出来再讨论。

- *Interpolation*
  - 在两个已知点之间进行插值，得到中间的点，需要建立一个 buffer 存储用于插值的点。另外一个细节在于，Interpolation 要求对信息做进一步的 deferred render，避免要插值时下一个点还没到，换句话说需要额外增加人为延迟
  - 插值还有一个潜在问题是可能平滑掉高频信息（如果角色确实是走走停停的话），不过一般来说人眼倾向于连续动作，并不那么 care 这个问题
  - Interpolation 带来的延迟加上本身就有的延迟，在高速运动游戏中很有可能导致两方的本地逻辑判断不一致（PPT 中红车认为自己撞到了，灰车认为没有的例子），这就需要预测，引出 Extrapolation
- *Extrapolation*
  - 既然每个 client 都清楚自己接收到的 replica 数据存在延迟（且能做一定数值估计），那么就可以通过速度、加速度等信息预测其未来的状态
  - *Dead Reckoning* 航位推算：航空领域的一个专有名词，指的是通过出发位置、空速管测量的相对空气速度、空气的方向和速度来推算飞向原目标位置的应该用的方向和速度（对抗风的干扰）。对应到游戏引擎的概念，就是解决一个追赶问题 —— 我已知延迟存在的情况下如何追赶对方（不能直愣愣朝着对方走，而应该有一定预判），这里涉及到大名鼎鼎的算法 Projective Velocity Blending (PVB)
  - *Projective Velocity Blending (PVB)*
    #fig("/public/assets/CG/GAMES104/2025-04-08-23-19-26.png", width: 50%)
    - 假设当前 replica 位置在 $p_0$，在 blend 的时间点 $t_B$ 时，如果不做调整会在当前速度、加速度作用下沿#redt[红线]走到 $p_t|_(t=t_B)$；而 server 端发来的 $t_0$ 时刻准确位置在 $p'_0$，同时也接收到速度 $v'_0$、加速度 $a'_0$，准确位置应该沿#text(fill: green, [绿线])走到 $p'_t|_(t=t_B)$
    - PVB 的做法就是对速度进行一个线性插值，让真实坐标沿着#bluet[蓝线]转移
      $
      la = frac(t-t_0, t_B-t_0) \
      v_t = v_0 + la (v'_0 - v_0) \
      p_t = p_0 + v_t t + 1/2 a'_0 t^2 => p_d = p_t + la(p'_t - p_t)
      $
    - 并不是一个基于物理的解决方案，但好处在于，不会看到角色的位置瞬间变化，而是逐步追上目标点位置
    - PVB 还有很多变种和小 trick 解决边界情况，这里了解它的核心思想即可。当然实际上用 PVB 来解 Dead Reckoning 问题时，在插值过程中会不断发来新的包，因此永远是一个动态追赶的过程
  - *Collision Issues*
    - 当双方都在进行 Extrapolation 时，可能出现 collision weird 的情况，其原因是虽然我自己预测出已经撞到停下了，但对方 replica 根据上一 snapshot 进行 extrapolation 会继续前进，导致两辆车嵌入对方而不是一触即离
    - 再结合一些物理引擎会给嵌在一起的物体施加巨大的力，导致两辆车可能只是轻轻碰撞却飞得很远的问题
    - *Physics Simualtion Blending During Collision*
      - 这个问题非常复杂，一种解决思想是在客户端提前进行物理检测，如果发生碰撞就把控制位置同步的权利从 Dead Reckoning 转移到物理引擎上，过一段时间后再逐步转回去（相当于权利移交给预碰撞）
      - 但这又严重依赖于物理引擎的 determinism。有的算法会把预测到要相撞后的一段时间 (e.g. $100ms$) 内玩家输入关闭，把位置同步全部交给插值，让双方同步（没太懂为什么关闭输入就能同步。。。）
- *总结*
  - 单机游戏做得再酷炫，要真正在网络游戏中也实现甚至进一步与 GamePlay 相结合，是一个设计上十分挑战的问题
  - Interpolation 的应用场景
    + 玩家经常以很大的加速度移动（这里有一个反直觉的常识，controller 的加速度一般会比车辆的加速度大很多，因为是为了手感而反物理操控）
    + GamePlay 受 extrapolation 的 wrap 问题影响严重（因为外插是预测，有时候容易卡到不希望的状态）
    + 更具体的例如 FPS, MOBA 游戏等
  - Extrapolation 的应用场景
    + Player 以符合物理规律的方式移动（预测更准）
    + GamePlay 受网络延迟影响严重
    + 更具体的例如赛车游戏、载具游戏等
  - 结合 Interpolation 和 Extrapolation 的应用场景
    - 角色移动用内插，上了载具之后用外插
    - 当网络波动，没有足够数据接受到时用外插

== Hit Registration 命中判定
- 射击游戏里，在玩家的视角射中敌人爆头显得十分自然，但在真实情况里是一个非常复杂、漫长的过程：
  +  敌方进入视野；
  + 经过 half RTT 传到 server 并被 buffer 后再处理；
  + server 端经过 half RTT 传到 client，又要经过 buffer、插值；
  + client 端玩家反应过来开枪；
  + 开枪信号又要经过 half RTT 传到 server 进行结算
  - 需要尝试解决的问题：Where is the Enemy? Where Should I Shot?
  - 实际上 Hit Registration 这一问题没有 ground truth，最重要的是达成一个共识，一般有两种流派
    + Client-side Hit Detection
    + Server-side Hit Registration
- *Client-side Hit Detection*
  - 使用 replicated 角色位置检测客户端上的命中事件，将命中事件发送到 server 端，server 端进行简单验证 (verification)
    - server 端做的验证包括但不限于：
      + StartPoint 不能跟 shooter 差太远
      + HitPoint 跟 HitObject 也不能差太远
      + 从 StartPoint 到 HitPoint 的 RayCast 之间不应该有障碍
    - 但真实情况下，就算是相对简单的 Client-side Hit Detection，server verification 也会很 tricky and complicated
  - 非常适合于 PUBG 这种大地图 + 多人在线的游戏，以及 Battlefield 3 这种破坏和载具系统丰富的游戏
  - 其好处是：1. 非常高效，对 server 端压力较小，可以模拟 hitscan, projectile, projectile + gravity 等不同弹道类型；2. 非常符合玩家直觉、射击手感好
  - 其坏处是 server 端轻信 client 端结果，容易导致作弊 (e.g. fake hit event message, lag switches, infinite ammo...)
- *Server-side Hit Registration*
  - server 端验证最大的问题在于 client 不知道敌人的准确位置，如果严格遵守真实情况则永远打不中，为此需要引入延迟补偿 Lag Compensation 机制
  - *Lag Compensation*
    - 一句话理解就是状态回溯，server 端保存一系列快照，处理命中事件往回拨一段时间，在当时的快照进行验证
    - 由于运行的是同一个游戏，server 端、client 端 ticking 的周期和 interpolation 所用算法均已知，假设网络波动不明显，server 端对各个 client 往回拨的时间可以有相对准确的估计
    $ "RewindTime" = "Current Server Time" - "Packet Latency" - "Client View Interpolation Offset" $
  - Cover Problems
    - Running into Cover：虽然我已经躲进掩体，但 server 端以开枪人视角为准，我可能还是会暴毙 (Shooter's Advantage)
    - Coming out from Cover：我从掩体出来，对方眼中我还在掩体因此发现不了，而我能先手发现对方并开枪 (Peeker's Advantage)
    - 鉴于这种种问题，此类游戏往往采用局域网把延迟尽量降低，同时把 tick rate 尽量调高，以求对双方都公平
- *一些 hack*
  - Startup Frames to Ease Latency Feeling
    - 给各种动作加上几帧的前摇，让用户专注于动画而不是延迟，从而为网络同步争取宝贵的时间
  - Local Forecast VFX Impacts
    - 击中特效、声效 (instant feedback) 可以在 client 端提前播放，server 端确认后再进行对齐 (permanent effects)。这也是经典头上冒火星不掉血的由来

== MMOG Network Architecture 大型多人在线游戏网络架构
MMOG: Massively Multiplayer Online Game，大型多人在线游戏，或者一般叫 MMO。很多人一提到 MMO 就想到 MMORPG，实际上还有 MMOFPS 等。各种游戏类型做大、做联网之后都能叫 MMO。并且现在的 MMO 有不局限于某一类型，而是构建虚拟小世界（元宇宙雏形）的趋势。

- *Game Sub-Systems*
  - 从 GamePlay 的角度，可以把游戏分成这些子系统
    + User management
    + Matchmaking
    + Trading system
    + Social system
    + Data storage
    + ...
- *MMO Architecture*
  - 从架构角度，可以把游戏分成这些层
  #fig("/public/assets/CG/GAMES104/2025-04-11-14-13-30.png", width: 60%)
  + Players
  + Link Layer
    - MMO 的 server 非常复杂，需要保护起来，用户首先跟 Login Server 建立连接（链接、握手、账号验证）
    - Gateway: 把服务器的内外网隔绝开，类似于一个防火墙，进行加密、解密、压缩等
  + Business Layer
    - Lobby Server: 大厅可以认为是一种特殊的游戏模式，作为一个等待 MatchMaking 的缓冲池
    - Character Server: 角色服务器，存储玩家的角色信息、物品信息等
    - Trading System: 交易系统需要保证绝对的原子性与安全性
    - Social System: 社交系统，负责玩家之间的交互等，有时还专门把 chat, mail servers 分开
    - MatchMaking: 把拥有不同等级、实力、延迟等属性的玩家匹配在一起
  + Data Layer
    - 游戏数据复杂而多样，包括 player data（公会、地下城、仓库等）, monitoring data, mining data 等，需要持久安全地保存，并且高效地组织用于 retrieve and analysis
    - 数据库一般分为三种
      + Relational Data Storage: 关系型数据库，适合存储结构化数据，e.g. MySQL
      + Non-Relational Data Storage: 游戏中有一些不需要严格按照关系进行存储、查询的数据（关系型数据库存储负载较重），比如 Log Data, Game States, Quest Data……非关系数据库在这种情况下更轻量、更高效，e.g. MongoDB
      + In-Memory Data Storage: MMOG 几百个 server 产生大量的中间数据，如果读写磁盘就太慢，需要用内存数据库来管理
- *Distributed System*
  - 随着游戏人数的上涨，服务器的负载也越来越重，一般会采用分布式架构
    - 分布式系统是一种计算环境，其中各种组件分布在网络上的多台计算机上
    - 比如数据同时写到多个数据库中，读写的效率更高且安全性更高，还有冷热表、灾难备份等概念
  - *Challenges with Distributed systems*
    + Data access mutual exclusion: 不同 services 的访问不会互相冲突构成死锁
    + Idempotence: 访问同一数据多次（消息冗余发来）不会产生不同的结果
    + Failure and partial failure: 部分服务宕机不会影响其他服务的正常运行
    + Unreliable network: 对不可靠网络的容忍能力
    + Distributed bugs spread epidemically: 避免分布式 bug 在不同 server 之间传播、震荡甚至放大
    + Consistency and consensus: 各个业务产生的结果必须一致
    + Distributed transaction: 事务处理
- *Load Balancing*
  - 有了分布式系统就可以解决上面说的游戏人数上涨问题，负载均衡是分布式系统中最重要的一个问题
  - 我们首先来思考*负载均衡的困难性*，以用于玩家信息管理的 character server 为例
    + 玩家数量动态变化，新玩家注册、老玩家注销，没有办法划分某一段玩家 ID 由某一个 server 负责
    + 服务器数量动态变化，server 宕机、增加、减少等，没有办法按玩家 ID 的余数划分
  - 类似问题非常多，一个很经典的解决方法叫做*一致性哈希 Consistent Hashing*
    - 对 Player ID 和 Server IP / Port 分别设计 hash 函数，映射到 $[0, 2^32- 1]$ 的空间上（一个 $32bit$ integer 的空间），形成一个环形
    - 定义规则，比如逆时针规则：每个 Player ID 按逆时针寻找最近的 Server 负责。当某个 server 挂掉或是增加时，在圆环中插入，根据规则会有部分 Player ID 需要重新分配；Player ID 的增删也是同理
    - 从而我们把复杂问题简单化 —— 动态变化的问题转化为两个 hash 函数分布的均匀性问题；并且只要两个 hash 函数定下来，也不再需要任何 rpc query 来显式调整负载
    - *Virtual Server Nodes*: 对 hash 函数的优化，增加虚拟节点，虚拟节点再映射回真实节点，增加 hash 函数的均匀性
- *Servers Management*
  - 承接上面，分布式系统的巨量服务会不断宕机、增加、减少，如何管理这些 services 是一个很大的问题；另外，MMO 游戏中各种服务的依赖关系错综复杂也给管理带来了困难
  - 对这一概念，分布式系统里更专业的术语叫 *Service Discovery 服务发现*
    + 每个服务向 Service Discovery System 注册 (Register) 自己的信息 (e.g. Apache ZooKeeper, etcd)
      #align(center, [server type/server_name\@server_ip:port])
    + 随后当应用层 request 某个服务时，Gateway 对 Service Discovery System 进行 query，得到相应的服务并进行负载均衡处理
    + 当服务有什么变动，Service Discovery System 会 watch 到并通知 Gateway（观察者）
    #fig("/public/assets/CG/GAMES104/2025-04-11-21-42-26.png", width: 80%)

== Bandwidth Optimization 带宽优化
- *带宽为什么重要？*
  + 基于使用的计费，例如手机流量、云服务，与成本息息相关
  + 带宽大了延迟也大，容易出现拥塞
  + 网关为了平衡可能主动掐断 message overflow 的连接
- *计算带宽*
  - 影响因素
    + 玩家数量 player numbers: $n$
    + 更新频率 update frequency: $f$
    + 更新的游戏状态数量（包体大小）size of game state: $s$
  - 每秒传输数据
    + Server: $O(n dot s dot f)$
    + Client (downstream): $O(s dot f)$
    + Client (upstream): $O(f)$
  - 带宽优化就是分别优化这三项影响因素
- *Data Compression 数据压缩*
  - 浮点数表示的 position, rotation, speed 等，如果用 vector3，可以考虑是否能把 y 轴弃用；此外考虑是否能用低精度浮点表示，或者转化为定点数 $->$ 可以称得上是网络游戏数据压缩中最重要的算法，大大减小 size of game state $s$
  - 由于角色的移速限制，往往只会在一块小区域内活动，可以对地图进行分区从而降低浮点数精度
- *Object Relevance 对象相关性*
  - 只传输跟玩家相关的对象，大大减小 size of game state $s$
  - Static Zones: 对非开放世界，采用静态区域划分，只传输玩家所在区域内的对象
  - *Area of Interest (AOI)*
    - 感兴趣区域，超出这一范围就不可见、不可交互，也就不传输
    - Direct Range-Query: 直接暴力查询，遍历每个对象计算距离，确定是否在范围内。对每个玩家对象都计算一遍，复杂度为 $O(n^2)$
    - Spatial-Grid
      - 把空间划分成格子，玩家周围格子内的对象划入 AOI
      - 玩家的 AOI 可以被 cache 成 list，enter / leave 格子时更新
      - 好处是时间复杂度为 $O(1)$，坏处是额外的内存开销（空间换时间），且性能跟 Grid Size 强相关，另外无法处理 varying AOI 的情况
    - Orthogonal Linked-list
      - 类似碰撞检测时说的 sweep and prune（Sort and Sweep 做粗筛），把物体按 x, y 轴建立链表并分别遍历做 range query，取其交集；当然对象移动时需要做更新
      - 好处是内存友好、支持 varying AOI，坏处是插入对象的时间复杂度为 $O(n)$，且不适合对象频繁大距离移动的情况
    - Potentially Visible Set (PVS): 预计算可见性集，每次更新时只需要查表加入附近区域的对象即可，适合 e.g. 高速移动的赛车游戏
- *Varying Update Frequency by Player Position*
  - 一般而言只有离玩家近的对象才能进行交互，为此根据距离对更新频率做衰减
  - 减小 update frequency $f$

== Anti-Cheat 反作弊
- 作弊方式多种多样
  + 修改游戏代码：修改、读取内存数据，破解客户端等
  + 系统软件调用：重载 D3D Render Hook（底层的绘制 SDK，比如画三角形变成画线框），模拟鼠标和键盘操作等
  + 网络数据包拦截：发送假包、修改包数据等
- *Executable Packers & Obfuscating Memory*
  - 外挂可能获取玩家坐标在内存中的位置用于穿墙、获取玩家血量用于锁血等，甚至利用这些值的位置在内存中找出更大的数据结构的位置，比如玩家对象本身。这一问题在采用帧同步、客户端验证的游戏中尤甚
  - 可以给*客户端加壳 (Executable Packer)*，把它加密包起来，在游戏运行时实时解密使 exe 得以运行
  - 还有一种方法是*内存混淆 (Obfuscating Memory)*，把高度敏感的数据在内存中加密，在使用的瞬间进行解密
- *Verifying Local Files by Hashing*
  - 外挂可能替换游戏文件例如材质，从而使敌人变得更明显、使墙壁变透明等
  - 通过不停对游戏文件计算 hash 并上传服务器，验证文件完整性，避免文件被篡改
- *Packet Interception and Manipulation*
  - 作弊者可能会拦截、修改数据包，甚至伪造数据包发送给服务器。对此服务器一般难以检测，用额外的检测机制又提高了负载
  - 一般的方法是对网络包进行加密，最核心的有两种算法：
    + *Symmetric-key algorithm 对称加密算法*
      - 发送方和接收方使用同一个密钥进行加密和解密
      - 快速且效率，但密钥的分发和管理是一个问题
    + *Asymmetric encryption 非对称加密算法*
      - 客户端和服务端使用不同的密钥，客户端的公钥被破解了无伤大雅，没有私钥无法打开数据
      - 例如 SSL，安全但是慢，一般只用于加密重要数据且尽量少用
      - 具体应用时，在登录时用 Asymmetric encryption 建立私钥公钥对，只用这一次建立一个安全的网络连接；之后用其加密方法传递 Symmetric-key，用对称加密算法进行具体数据的传输；不断更新该 Symmetric-key 使其被破解也没关系（只影响这一次传输）
      #fig("/public/assets/CG/GAMES104/2025-04-11-23-35-18.png", width: 40%)
  - 现代网络游戏中对加密问题非常重视（基本是刚需），一般会做成引擎底层功能提供服务
- *System Software Invoke*
  - 外挂可能通过钩子勾到引擎里去，注入代码
  - 一些反作弊软件如 VAC, Easy Anti-Cheat（小蓝熊）等会扫描内存中游戏的签名，监控系统调用，检测是否有异常的调用；以及对一些可疑的应用程序、外挂做报警
- *AI Cheat*
  - 以上方法或多或少都有解决的办法，但 AI 作弊作为一种新兴的作弊方式，可能会对游戏造成很大的影响，目前还没有成熟的解决方案
  - AI Cheat 一般全平台通用、不需要修改游戏文件、独立于游戏运行。比如把 YOLO 用到枪战游戏，直接在屏幕空间进行目标检测，移动鼠标并开火，很难检测且门槛越来越低
- *Statistic-Bases System*
  - 基于大数据、深度学习识别出玩家行为的异常 pattern，跟 AI Cheat 属于道高一尺、魔高一丈的比拼关系，用 AI 打败 AI，还处在早期阶段
  - 还有一些游戏如 CSGO 会把超出统计数据的对局录像，交由人类审核 (overwatch)，判断是否作弊（不太可取）
- *Detecting Known Cheat Program*
  - 一般用作牟利的外挂总会有一些特征可供记录，通过对比已知的外挂程序，进行检测
  - 对商业型外挂效果较好

#q[反外挂是长期战、持久战。]

== Build a Scalable World
如何构建可扩展的游戏服务器 (Scalable Game Servers)？

#grid(
  columns: (65%, 35%),
  column-gutter: 4pt,
  [
    + *Zoning*
      - 把游戏世界划分成多个区域（对世界的横向空间划分），每个区域由一个 server 负责
      - 分布可能不均匀，可以采用四叉树划分等方式，进行动态的区域划分
      - 如何让玩家感受不到区域切换 (seamless) 是一个挑战
        - 给 Zone Border 设置宽度 ($>=$ max AOI radius)，在这个宽度内做特殊处理
          - 例如 Active Entity $A$ 处在 Zone $A$ 和 Zone $B$ 的 Border 中，归属于 Zone $A$ 管理。Zone $B$ 中也有一个 Entity $B$，虽然它的逻辑、行为归属于 Zone $B$，但在 Zone $A$ 中创建一个 ghost 显示给 Entity $A$
          - 从而在 Cross Border 时，分 #cnum(1)#cnum(2)#cnum(3)#cnum(4)#cnum(5) 不同的阶段
          #grid2(
            fig("/public/assets/CG/GAMES104/2025-04-12-10-23-44.png"),
            fig("/public/assets/CG/GAMES104/2025-04-12-10-38-09.png", width: 80%)
          )
        - 另外这里有个细节，为了防止反复跨越 Border Line 导致的高频更新，一般会设置一个阈值，只有当玩家移动超过一定距离后才会进行切换（因此图中 #cnum(3) 应该还未切换到 Zone $B$）
    + *Instancing*
      - 同时独立地运行多个游戏区域实例，类似于副本
      - 减少拥堵和竞争的同时也降低了沉浸感
    + *Replication*
      - 复制游戏到很多层，允许更高的用户密度，跟前面说的 load balancing 类似
      - 跟 Zoning 跨区时的处理类似，如果要让某个 layer 的玩家看到足够多的玩家，实际上很多都是 ghost
    + *Combination*
      - 综合结合以上方法，首先考虑动态划分 Zones，但不能分得太小，否则一方面容易造成频繁跨区，另一方面至少也得大于 max AOI radius
      - 如果一个 Zone 已经很小但依旧负载过重，就考虑 Replication，分发到多个 server
      - Instancing 则作为补充和 GamePlay 的需要
  ],
  [
    #fig("/public/assets/CG/GAMES104/2025-04-12-10-13-10.png")
    #fig("/public/assets/CG/GAMES104/2025-04-12-10-44-38.png")
  ]
)

= 面向数据编程与任务系统
== Parallel Programming 并行编程
- *Basics of Parallel Programming*
  + 摩尔定律的终结
  + 多核
  + 进程和线程
  + 多任务类型：Preemptive / Non-Preemptive
  + Thread Context Switch $->$ expensive
  + Embarrassingly Parallel Problem v.s. Non-embarrassingly Parallel Problem
    - 前者是理想情况，任务之间没有依赖关系，互不影响，容易并行化，最简单的例子就是蒙特卡洛采样，丢到多个线程各自执行；后者是真实情况下经常出现的情形，任务之间有各种 dependency
  + Data Race in Parallel Programming
    - Blocking Algorithm - Locking Primitives，都是操作系统里的基本概念
      - Issues with Locks: Deadlock Caused by Thread Crash, Priority Inversion
    - Lock-free Programming - Atomic Operations
      - Lock Free vs. Wait Free: 后者对整个系统做到 $100%$ 利用几乎难以达到，但对某个具体数据结构的完全利用还是有相应解法的
  + Compiler Reordering Optimizations
    - 编译器指令重排优化了性能，但存在打乱并行编程执行顺序的风险，硬件上的乱序执行也会导致类似问题
    - Cpp11 允许显式禁止编译器重排，但代价是性能下降
    - 程序开发一般有 debug 版本和 release 版本，debug 版本下基本可以认为执行顺序是严格的，release 版本下则不一定
- *Parallel Framework of Game Engine*
  - *Fixed Multi-thread*
    - 最简单的解法，把游戏引擎的各个模块分到不同的线程中去，e.g. Render, Simulation, Logic etc.
    - 1. 进程之间产生木桶效应，最慢的进程决定整体性能；2. 并且很难通过把一个模块拆分的方式解决，因为会出现 data racing 问题，且没有利用好 locality；3. 再者，每个模块的负载是动态变化而无法预先定义的，而用动态分配的方式会产生更多的 bug；4. 最后，玩家所用设备的芯片数五花八门，除非对每种数量预设都做过优化，否则部分核心直接闲置
  - *Thread Fork-Join*
    - 将引擎中一致性高、计算量大的任务（如动画运算、物理模拟）fork 出多个子任务，分发到预先定义的 work thread 中去执行，最后再将结果汇总
    - 显而易见这种 pattern 也会有许多核的闲置，但一般比 fixed 方法好，且鲁棒性更强，是 Unity, UE 等引擎的做法
    - 以 UE 为例，它显式地区分了 Named Thread (Game, Render, RHI, Audio, Stats...) 以及一系列 Worker Thread
  - *Task graph*
    - 把任务总结成有向无环图，节点表示任务，边表示依赖关系；把这个图丢给芯片，自动根据 dependency 决定执行顺序与并行化
    - dependency 的定义可以很淳朴，不断往每个 task 的 prerequest list 中 add 即可；问题在于，很多任务无法简单地划分，而且在运行过程中又可能产生新的任务、新的依赖，而这些在早期的 Task Graph 这样一个静态结构里没有相应的表述

== Job System 任务系统
- *Coroutine 协程*
  - 一个轻量级的执行上下文，允许在执行过程中 yield 出去，并在之后的某个时刻 resume 回来（被 invoke）
  - 跟 Thread 概念比较，它的切换由程序员控制，不需要 kernel switch 的开销，始终在同一个 thread 中执行
  - 两种 Coroutine
    - Stackful Coroutine: 拥有独立的 runtime stack，yield 后再回来能够恢复上下文，跟函数调用非常类似
    - Stackless Coroutine: 没有独立的 stack，切换成本更低，但对使用者而言更复杂（需要程序员自己显式保存需要恢复的数据）；并且只有 top-level routine 可以 yield，subroutine without stack 不知道返回地址而不能 yield
    - 两种方式无所谓高下，需要根据具体情况选择
  - 另外还有一个难点在于 Coroutine 在部分操作系统、编程语言中没有原生支持或支持机制各不相同
- *Fiber-based Job System*（可以参考 #link("https://zhuanlan.zhihu.com/p/594559971")[Fiber-based Job System 开发日志1]）
  - Fiber 也是一个轻量级的执行上下文，它跟 Coroutine 一样，也不需要 kernel switch 的开销，非常类似于 User Space Thread（某种程度上更像）。但不同在于，它的调度交由用户自定义的 scheduler 来完成，而不是像 Coroutine 那样 yield 来 resume 回去
    - 个人总结：Fiber 比 Thread 更灵活、轻量，比 Coroutine 更具系统性
    - 并且，对比这种通过调度方式分配和 Thread Fork-Join 方式分配，显然设定一个 scheduler 时时刻刻把空闲填满的方式更高效
  - Fiber-based Job System 中，Thread 是执行单元，跟 Logic Core 构成 1:1 关系以减少 context switch 开销；每个 Fiber 都属于一个 Thread，一个 Thread 可以有多个 Fibers 但同时只能执行一个，它们之间的协作是 cooperative 而非线程那样 preemptive 的
  - 通过创建 jobs 而不是线程来实现多任务处理（jobs 之间可以设置 dependency, priority），然后塞到 Fiber 中（类似于一个 pool），job 在执行过程中可以像 Coroutine 那样 yield 出去
  #fig("/public/assets/CG/GAMES104/2025-04-12-15-50-15.png", width: 50%)
  - *Job Scheduler*
    - Schedule Model
      - LIFO / FIFO Mode
      - 一般是 Last in First Out 更好，因为在多数情况下，job 执行过程中产生新的 job 和 dependency (tree like)，这些新的任务应该被优先解决
    - Job Dependency: job 产生新的依赖后 yield 出去，移到 waiting queue 中，由 scheduler 调度何时重启
    - Job Stealing: jobs 的执行时间难以预测准确，当某一 work thread 空闲，scheduler 从其他 work thread 中 steal jobs 分配给它
  - *总结*
    - 优点
      + 容易实现任务的调度和依赖关系处理
      + 每个 job stack 相互独立
      + 避免了频繁的 context switch
      + 充分利用了芯片，基本不会有太多空闲（随着未来芯片核数的增加，Fiber-based Job System 很有可能成为主流）
    - 缺点
      + Cpp 不支持原生 Fiber，且在不同操作系统上的实现不同，需要实现者对并行编程非常熟悉（一般是会让团队里基础最扎实、思维最缜密的成员负责搭建基座，其它成员只负责上层的脚本）
      + 且这种涉及到内存的底层实现系统非常难以 debug

== Data-Oriented Programming (DOP)
- *Programming Paradigms*
  - 存在各种各样的编程范式，不同编程语言又不局限于某一种范式
  - 游戏引擎这样复杂的系统往往需要几种的结合
  #fig("/public/assets/CG/GAMES104/2025-04-12-16-28-44.png", width: 80%)
  - 早期编程使用 Procedural Oriented Programming (POP) 就足够，后来随着复杂度增加，Object-Oriented Programming (OOP) 成为主流
- *Problems of OOP*
  + Where to Put Codes: 一个最简单的攻击逻辑，放在 Attacker 类里还是 Vectim 类里？存在二义性，不同程序员有不同的写法
  + Method Scattering in Inheritance Tree: 难以在深度继承树中找到方法的实现（甚至有时候还是组合实现的），并且同样存在二义性
  + Messy Based Class: Base Class 过于杂乱，包含很多不需要的功能
  + Performance: 内存分散不符合 locality，加上 virtual functions 问题更甚
  + Testability: 为了测试某一个功能要把整个对象创建出来，不符合 unit test 的原则
- *Data-Oriented Programming (DOP)*
  - 一些概念引入
    - Processor-Memory Performance Gap，直接导致 DOP 思想的产生
    - The Evolution of Memory - Cache & Principle of Locality
    - SIMD
    - LRU & its Approximation (Random Replace)
    - Cache Line & Cache Hit / Miss
  - DOP 的几个原则
    + Data is all we have 一切都是数据
    + Instructions are data too 指令也是数据
    + Keep both code and data small and process in bursts when you can 尽量保持代码和数据在 cache 中临近（内存中可以分开）
- *Performance-Sensitive Programming 性能敏感编程*
  - Reducing Order Dependency: 减少顺序依赖，例如变量一旦初始化后尽量不修改，从而允许更多 part 能够并行
  - False Sharing in Cache Line: 确保高频更新的变量对其 thread 保持局部（减少两个线程的交集），避免两个 threads 同时读写某一 cache line（cache contension，为了保持一致性需要 sync 到内存再重新读到 cache）
  - Branch prediction: 分支预测一旦出错，开销会很大。为了尽量避免 mis-prediction，会把用作判断的数组排个序来减少分支切换次数，或是干脆分到不同的容器里执行来砍掉分支判断 (Existential Processing)
- *Performance-Sensitive Data Arrangements 性能敏感数据组织*
  - Array of Structure vs. Structure of Array
  - SOA 效率更高，例如 vertices 的存储，它把 positions, normals, colors 等分开共同存储

== Entity Component System (ECS)
过去基于 OOP 的 Component-based Design，患有 OOP 的一系列毛病；而 ECS 则是 DOP 的一种实现方式，实际上就是之前讲过的概念的集合。

- *ECS 组成*
  - Entity: 实体，通常就是一个指向一组 componet 的 ID
  - Component: 组件，不同于 Component-based Design，ECS 中的 component 仅是一段数据，没有任何逻辑行为
  - System: 系统，包含一组逻辑行为，对 component 进行读写，逻辑相对简单方便并行化
  - 即把过去离散的 GO 全部打散，把数据和逻辑分开，数据按照 SOA 的方式整合存储为 Component，逻辑通过 System 来处理，只保留 Entity ID 作为索引
- *Unity ECS*
  - 采用 Unity Data-Oriented Tech Stack (DOTS)，分为三个组成部分
    + Entity Component System (ECS): 提供 DOP framework
    + C\# Job System: 提供简单的产生 multithreaded code 的方式
    + Burst Compiler: 自定义编译器，绕开 C\# 运行在虚拟机上的低效限制，直接产生快速的 native code
  - Unity ECS
    - Archetype: 对 Entities 的分组，即 type of GO
    - Data Layout: 每种 archetype 的 components 打包在一起，构成 chunks (with fixed size, e.g. 16KB)
      - 这样能够提供比单纯的所有 components 放在一起更细粒度的管理。比如是把所有 GO（包括角色、载具、道具）的 tranform 全堆在一起，还是把所有角色的、所有载具的、所有道具的 tranform 分开再存在一起？显然后者更好
    #fig("/public/assets/CG/GAMES104/2025-04-12-18-46-36.png", width: 70%)
    - System: 逻辑相对简单，拿到不同的 component 做某种运算
  - Unity C\# Job System
    - 允许用户以简单方式编写 multithreaded code，编写各种 jobs 且可以设置 dependency
    - jobs 需要 native containers 来存储数据、输出结果（绕开 C\# 虚拟机的限制，变为裸指针分配的与内存一一对应的一段空间），也因此需要做 safety check，需要 manully dispose（又回到老老实实写 Cpp 的感觉，也算是一开始使用 C\# 带来的恶果吧）
    - Safety System 提供越界、死锁、数据竞争等检查（jobs 操作的都是 copy of data，消除数据竞争问题）
  - Unity Burst Compiler
    - High-Performance C\# (HPC\#) 让用户以 C\#-like 的语法写 Cpp-like 代码，并编译成高效的 native code（很伟大的工作）
    - 摈弃了大多数的 standard library，不再允许 allocations, reflection, the garbage collection and virtual calls
- *Unreal Mass Framework —— MassEntity*
  - Entity: 跟 Unity 的 Entity 一样，都是一个 ID
  - Component
    - 跟 Unity 一样有 Archetype，由 fragments 和 tags 组成，fragments 就是数据，tags 是一系列用于过滤不必要处理的 bool 值
    - fragment 这个名字取得就比 Unity 好，既跟传统的 component 做出区分，又表示内存中一小块碎片、数据
  - System
    - UE 里叫 Processors，这个名字也起得比较切贴，用于处理数据
    - 提供两大核心功能 `ConfigureQueries()` and `Execute()`
  - Fragment Query
    - Processor 初始化完成后运行 `ConfigureQueries()`，筛选满足 System 要求的 Entities 的 Archetype，拿到所需的 fragments
    - 缓存筛选后的 Archetype 以加速未来执行
  - Execute
    - Query 后拿到的是 fragments 的引用（而不是真的搬过来，因为也是按照 trunk 存储、处理），Execute 时将相应 fragments chunk 搬运并执行相应操作

然而游戏是个很复杂、很 dependent 的系统，很难把所有逻辑按 ECS 架构组织，这可能也是为什么 ECS 在现今还未成为主流（有 “好看不好用” 的评价）。做游戏引擎千万不要有执念，关键是在什么场合把什么技术用对。

- Everything You Need Know About Performance（对着这张图进行优化）
  #fig("/public/assets/CG/GAMES104/2025-04-12-19-47-59.png", width: 90%)

= 动态全局光照和 Lumen
先讲了一堆 GI 的内容，这部分可以转战 Games202（具体笔记补充在那边）。







#v(80em)