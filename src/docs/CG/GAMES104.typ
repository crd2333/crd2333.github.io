#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- GAMES104 没有咋写详细笔记，可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）

= Lec1: 游戏引擎导论

= Lec2: 引擎架构分层

= Lec3: 如何构建游戏世界
- QA: 物理和动画互相影响的时候怎么处理
  - 一个比较典型的问题，更多算是业务层面的问题而不是引擎层面，但引擎也要对这种 case 有考虑。以受击被打飞为例，被打到的一瞬间要播放受击动画，击飞后要考虑后续的物理模拟。这么剖析的话怎么做也已经呼之欲出了，也就是做一个权重的混合，一开始是动画的占比较大，把动画的结果作为物理的初始输入，越到后面物理模拟的占比增大（更深入一点，就是 FK 和 IK 的权重变化）。最终能做到受击效果跟预定义的动画很像，但后续的动作变化也很物理、合理。

= Lec4: 游戏引擎中的渲染实践
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

= Lec5: 渲染中光和材质的数学魔法
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

= Lec6: 游戏中地形大气和云的渲染
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

= Lec7: 游戏中渲染管线、后处理和其他的一切
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

= Lec8: 游戏引擎的动画技术基础
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

= Lec9: 高级动画技术：动画树、IK 和表情动画
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

= Lec10: 游戏引擎中物理系统的基础理论和算法
- 物理系统对游戏引擎的重要性无需多言，这里另外推荐几篇文章
  + #link("https://www.zhihu.com/question/43616312")[为什么很少有游戏支持场景破坏？是因为技术问题吗？]
  + #link("https://www.bilibili.com/opus/573944313792790732")[如何创造《彩虹六号：围攻》的破坏系统？]

== 物理对象与形状






#v(30em)