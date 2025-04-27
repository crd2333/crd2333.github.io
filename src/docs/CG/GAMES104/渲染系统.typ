---
order: 2
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

#let QA(..args) = note(caption: [QA], ..args)
#counter(heading).update(3)

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
  - 球谐函数的介绍，略
  - *Light Map*: 把全局光照预计算到纹理上，实时渲染时直接采样
    - 现在略微有点过时了，但是其思想依旧重要：第一是空间换时间，第二是把整个空间参数化到 2D Texture 或 3D Volume 上，便于后续管理
  - *Light Probe*
    - 在空间中放置一些点，采样周围的光照信息（通常会使用完整的三阶 SH，$27$ 个系数来保存 irradiance），当物体经过时，采样这些点进行插值，算出自己的光照，总之，就是一个空间体素化的思想。这些点不会太多，比如 light map 可能需要采几百万个点来烘焙，而 light probe 可能几百个就差不多了
    - 但问题在于，谁来摆这些点？早期可以让美术手动用编辑器工具放置，但关卡变动导致需要重新放置，因此更好的方法是自动化（根据玩家可到达区域和场景几何均匀地撒点）
    - 还有一种特殊的 probe 叫做 reflection probe，专门用来采样反射光照，密度低一些但精度更高
    - 在实际运用中，我们可能会从相机位置往四周看，从而在 shader 中高效计算出光照；计算出的光照也不会在下一帧直接弃用，而是根据移动距离之类判断是否需要更新；另外，可以对 light probe 进行一些压缩，并不会损失太多精度
    - 总的来说，Light Probe 运行效率很高，它同时处理了 diffuse 和 specular，并且能处理动态物体；不过缺点是一系列 SH light probes 需要一定的计算，以及精度往往不如 light map
  - *Irradiance Volume*
    - 这里额外拓展一个技术，后续应用非常广泛。它是一种离散的描述空间中光照信息的方案，将空间划分为一个个小立方体，每一个小立方体中记录光照信息（一般我们管这个收集光照信息的叫 Probe）。实际上跟 Light Probe 关系非常紧密（可能也就是空间划分方式和存储方式有所不同？）
    - 先采样出 radiance 分布函数 $L(x,om)$，再半球积分得到 irradiance 分布函数 $E(x,om)$ 并存储（似乎还有 Radiance Transfer 版本）。之后就可以作为 3D texture 进行 trilinear 采样
  - 可参考的文章
    + #link("https://zhuanlan.zhihu.com/p/265463655")[游戏中的全局光照（四）Lightmap、LightProbe 和 Irradiance Volume]
    + #link("https://zhuanlan.zhihu.com/p/23410011")[游戏中的 Irradiance Volume]
    + #link("https://zhuanlan.zhihu.com/p/622940005")[四十九、The Irradiance Volume]
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
  - 事实上，上面说的这种程序员在 CPU 上 build 好顶点再送进 GPU 的方法，在逐渐让步于 GPU-Driven 的自动化过程
  - 在古老的图形 API DX11 上，在 Vertex Shader 和 Geometry Shader 之间插入 Hull Shader, Tessellation, Domain Shader 阶段（名字取得比较奇怪，总之就是为了细分而设计的）
  - 在现代的图形 API DX12 上，用一个 Mesh Shader 代替前面的 Vertex Shader, Hull Shader, Tessellation, Domain Shader 以及 Geometry Shader
  - GPU-Driven 的另一个好处是，自动调整的顶点允许我们构建 Real-time Deformable Terrain！
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
这里把几种渲染管线都梳理一遍，不止老师上课讲的那几种。

- *Forward Rendering*
  - 最原始的渲染管线：Shadow Pass $->$ Shading Pass $->$ Post-Processing Pass
    - Shading Pass 内的像素着色阶段先进行着色计算 (fragment shader)，再进行输出合并（深度测试、模板测试、混合等）
  - 问题
    + 透明度排序，需要从远到近绘制，有时物体由于交叉而无法排序，需要顺序无关半透明算法（参考 #link("https://blog.csdn.net/qq_35312463/article/details/115827894")[vulkan\_顺序无关的半透明混合 (OIT)]）
    + 难以处理 Multiple Light
    + 原始未优化版本的 overdraw 比较多，很多无效的着色计算
  - *Early-Z*
    - 这是针对*渲染流水线内部*而言的，仍然只执行*一次渲染*，把输出合并阶段的深度测试提到着色计算之前
    - 硬件层面优化，一般是默认开启，但如果在 fragment shader 里写了 `discard` 或修改 depth 的语句就会失效
    - 对于比较友好的顺序来说，能有效避免无效着色计算，但在比较恶心的顺序下依然会 overdraw（除非预先进行排序）
    - 还有一个类似的概念 *Z-Culling*，似乎跟 Tile-Based 有关，以及通过 on-chip 缓存比 Early-Z 少一次读深度操作
  - *Z-PrePass*
    - 延迟渲染的前身，*把一次渲染变成两次渲染*，第一次只写入 Z-Buffer，第二次关闭深度写入，只有通过深度测试的像素才计算光照（这可以看出它必须跟 Early-Z 结合才起效，Z-PrePass 其实是一种软件技术）
    - 彻底解决了一个像素多次绘制的问题，但需要执行两次 vertex shader，或者说第二次渲染依旧需要对全场景各个物体进行绘制（为此后面提出了 Deferred Rendering，通过 G-Buffer 使第二次渲染可以不执行 vertex shader）
- *Deferred Rendering*
  - 也是分两次渲染，第一个 pass 先渲染 G-Buffer 而不做实际着色，第二个 pass 严格来说已经不走渲染流水线，而是直接对 G-Buffer 的操作
  - 优点
    + 只会在 visible fragments 上计算着色，节省大量 overdraw 的无效计算
    + 只对可见像素着色更重要的是，将光源数量和场景复杂度解耦（$n$ 个物体、$m$ 个光源，从 $O(m \* n)$ 变为 $O(m + n)$）
    + 同时真正着色时 G-Buffer 的信息利用起来更方便（更好进行 post-processing），也更好 debug
  - 缺点
    + 需要大量的内存来存储 G-Buffer，带宽也是个问题（尤其是移动端）
    + 透明物体处理困难
    + 一般来说不支持太多种类的 shader，尤其是应美术要求做的可能需要奇奇怪怪中间值的 shader 没法支持（没法存到 G-Buffer）
    + 不支持 MSAA（又是 buffer 的问题，参考 #link("https://zhuanlan.zhihu.com/p/135444145")[延迟渲染与 MSAA 的那些事]）
  - 现在的大型电脑游戏基本都已经是延迟渲染，而手游大多还停留在前向渲染，或是魔改出 Tile-Based Rendering 变相实现延迟渲染
  - *Hi-Z*
    - 核心原理是利用上一帧的深度图和相机矩阵，来对当前帧的场景做剔除。如果没有被覆盖怎么办？原始的 Hi-Z 是一个保守算法，它宁可少剔除也不愿错误剔除
    - 因为逐像素对比性能太差，为此提出 Hierarchical-Z Buffer（也是由此得名），构建一个 min-value mipmap 来加速，只有通过剔除的物体才会写入 Deferred Rendering 的 G-Buffer
    - 一些资料中说它是 CPU 端的剔除，又有一些资料中说它是 GPU-Driven Render Pipeline 的一环，个人理解其实两者都是对的
      - 如果是在 CPU 端的剔除，顶点可以直接不提交 GPU。比 Early-Z, Z-PrePass 这种不能减少 vertex shader 计算量的方式受益大得多，适用于细碎且数量多的模型。但涉及到深度图从 GPU 回读到 CPU 问题（也可以做分帧回读，但会让延迟更大）
      - 如果是 GPU 端的剔除，涉及到 GPU -Driven Render Pipeline，修改风险太高且很多团队不具备该开发能力。当然现在随着 compute shader 的发展，在 GPU 上进行通用计算不再是新鲜事，慢慢地 Hi-Z 更多已经变成 GPU 端剔除的一环了
    - Hi-Z 不仅仅用于剔除，这种层级结构的思想在 GI 中也可应用于加速 tracing (SSR, Lumen)
- *Tile-Based Rendering & Cluster-Based Rendering*
  - Key Observation 是光照强度随距离平方衰减，如果做一个阈值，那么光源的影响范围是一个球体
  - Tile-Based Rendering
    - 从屏幕的视角分成若干个小块 (tile)，每个小块只跟相交的光源交互（通过 Pre-z pass 得到 min/max depth，维护光源索引列表）
    - Forward+: Forward Rendering 结合 Tile-Based Rendering 就叫做 Forward+，算是 CG 行业的黑话
  - Cluster-Based Rendering
    - 将以上思想进一步发扬光大，每个小块（3D 空间中是一个视锥）可以在深度方向进行切片，形成一个 3D grid (cluster)，每个 cluster 只跟相交的光源交互
    - 还有一种也叫 Cluster 的技术 —— Mesh Cluster Rendering，它所指的 cluster 是将每个 mesh instance 切分为小块，从而实现更彻底的剔除。名字类似但所指不同，切勿搞混
  - 这类方法可以有效避免无意义 shading（尤其是在多光源情形下），最初实际上来源于移动端显存不足的问题，通过切分为 tile 来减小 G-Buffer 需求，一小块渲染好了放到 Framebuffer 中再算下一小块（因此也可以减小 Framebuffer 的读写压力）
  #grid(
    columns: (30%, 40%, 30%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-10-23-47.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-10-23-17.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-10-26-36.png")
  )
- *Visibility Buffer*
  - *V-Buffer 生成阶段*：把几何与材质解耦，只存储几何信息，用来反向查找对应材质信息
    - G-Buffer: Depth, Normal, Albedo, Roughness, etc. 实际上是把几何与材质一起存储
    - V-Buffer: Depth, Instance ID, Primitive ID, MaterialID，后面三个 ID 可以被压到 unit32 中（似乎有一些实现也传了 Barycentrics）
  - *Shading 阶段*：在对每个像素着色时，加载 Instance ID 对应的 MVP 矩阵，通过 Triangle ID 找到三个顶点（同时拿到 UV 坐标），投影到屏幕上并重新生成重心坐标，通过重心坐标插值得到纹理信息，随后便是正常的 shading 过程
    - 可以理解为，原本由光栅化阶段完成的工作，现在都由我们手动控制。听起来很费性能，但实际上完全可以接受，这是因为：
      + 通过 Primitive ID 到 Vertex Buffer 里取数据的 Cache Coherence 是很高的（只读不写）
      + 一个三角形在屏幕上覆盖多个像素，这些像素对应的三角形是一样的，Cache Hit Rate 也很高
  - 为什么要这么做呢？有下面几个原因
    + G-Buffer 存储占用大，占用大不仅对带宽要求很高，并且对 cache 不够 friendly，这个很好理解
    + G-Buffer 希望将可见性与着色相分离，但实际上并不彻底！
      - G-Buffer 存储纹理信息需要大量采样的工作并没有被推迟，导致纹理读写层面的 overdraw（最终被覆盖像素的纹理也要做）。这一点对比 Z-PrePass 甚至还倒退了（虽然少一次 vertex shader，但多了很多纹理采样）
      - 现代游戏中几何密度高到甚至超过像素，这个采样问题就更严重，在树叶、草繁多的场景尤为明显
    + 可见性与着色分离不彻底的另一个潜在问题是，立即采样材质要求 drawcall 必须按材质进行批处理 (batching)，从而丧失了更有效地调度工作负载的机会
    + Quad Overdraw 问题
      - 无论是 Early-Z / Z-PrePass 还是 Deferred Rendering，都无法避免该问题，这对 mesh 多且碎的情况尤为严重
      - 硬件为了确定 mipmap 的 `ddx`, `ddy` 而采用最小 $2 times 2$ 粒度的处理方式，详见 Nanite 部分介绍
    + 此外，G-Buffer 难以支持 MSAA，而 V-Buffer 由于有了 Primitive ID 和 Barycentrics 且占用更小使其变为可能
  - 不过，这样一个全新、激进的渲染技术可能会导致对应 shader、texture、美术制作流程等需要发生重大变化，需要再走一次 Forward 到 Deferred 的革命，但依旧可以相信它是一个美好的未来
  - Visibility Buffer + Deferred Shading
    - 未来美好，但在此之前仍需要将 Visibility + Deferred 结合，按需取用（一般只对树、草等启用 V-Buffer 方式）
    - 使用 V-Buffer 渲染的物体，做到纹理采样为止，不进行最后一步的光照计算，也写到 G-Buffer 中，同传统 Deferred Shading 汇合，后续则是无感知地在 G-Buffer 上进行最终的光照计算

- 参考资料
  + #link("https://zhuanlan.zhihu.com/p/389396050")[渲染杂谈：early-z、z-culling、hi-z、z-perpass到底是什么？]
  + #link("https://zhuanlan.zhihu.com/p/386420933")[Shader 学习 (20) 延迟渲染和前向渲染]
  + #link("https://zhuanlan.zhihu.com/p/85615283")[Forward+ Shading]
  + #link("https://zhuanlan.zhihu.com/p/278793984")[Compute Shader 进阶应用：结合 Hi-Z 剔除海量草渲染]
  + #link("https://zhuanlan.zhihu.com/p/47615677")[Hi-Z GPU Occlusion Culling]
  + #link("https://zhuanlan.zhihu.com/p/697659813")[Unity 实现 Hi-z 遮挡剔除上（CPU 篇）]、#link("https://zhuanlan.zhihu.com/p/700453220")[Unity 实现 Hi-z 遮挡剔除下（GPU 篇）]
  + #link("https://zhuanlan.zhihu.com/p/416731287")[Hierarchical Z-Buffer Occlusion Culling 到底该怎么做？]
  + #link("https://zhuanlan.zhihu.com/p/683761529")[Visibility Buffer 在 Unity 中的一些实践]

- *GPU-Driven Rendering Pipeline*
  - 又是一个巨大的话题，这里只是简单提一提趋势，具体的实践可以看最后《前沿介绍》一节
  - 传统 CPU 驱动的渲染管线有何弊端？
    + draw primitives 比较昂贵，哪怕只画一个 triangle 也要把整个管线走一遍，为此经常需要 batch 化
      - Explosion of DrawCalls: 在如今复杂游戏中，drawcall 组合爆炸，并不是那么好 batch 化
      $ "Meshes" x "RenderStates" x "LoDs" x "Materials" x "Animations" $
    + GPU 等待 CPU 使其不能满载运行
      - CPU 不仅需要做 Frustum / Occlusion Culling，准备 drawcall，无法跟上 GPU
  - 未来的趋势又如何？
    + Compute Shader - General Computation on GPU
      - GPU 上 compute shader 的发展允许我们把一些通用计算搬到 GPU 上，依然保持高速、并行的特点
      - 这样渲染全权交给 GPU (e.g. Lod selection, visibility culling, ...)，CPU 就能空出来做其它事情 (e.g. AI, GameLogic, ...)
    + Draw-Indirect Graphics API
      - 可以将大量的 drawcall 合并为一个单一的 drawcall（即使网格拓扑不同），构成一个间接绘制的命令。在不同的平台上叫法不同，但其表现形式都是往 GPU buffer 或 GPU compute program 里指定特定参数 (e.g. `vkCmdDrawIndexedIndirect` (Vulkan), `ExecuteIndirect` (D3D12), ...)
      - 从而真正把 DrawPrimitive 变成 DrawScene，避免 CPU 跟 GPU 的频繁通信


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