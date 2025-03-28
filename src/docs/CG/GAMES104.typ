#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

= GAMES104
- GAMES104 没有咋写详细笔记，可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）

== Lec1: 游戏引擎导论

== Lec2: 引擎架构分层

== Lec3: 如何构建游戏世界
- QA: 物理和动画互相影响的时候怎么处理
  - 一个比较典型的问题，更多算是业务层面的问题而不是引擎层面，但引擎也要对这种 case 有考虑。以受击被打飞为例，被打到的一瞬间要播放受击动画，击飞后要考虑后续的物理模拟。这么剖析的话怎么做也已经呼之欲出了，也就是做一个权重的混合，一开始是动画的占比较大，把动画的结果作为物理的初始输入，越到后面物理模拟的占比增大（更深入一点，就是 FK 和 IK 的权重变化）。最终能做到受击效果跟预定义的动画很像，但后续的动作变化也很物理、合理。

== Lec4: 游戏引擎中的渲染实践
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

== Lec5: 渲染中光和材质的数学魔法
- 渲染方程及挑战
- 基础光照解决方案
  - Simple light + Ambient
  - Blinn-Phong material
  - Shadow map
- 基于预计算的全局光照
  - 球谐函数
  - Light map: 把全局光照预计算到纹理上，实时渲染时直接采样
    - 现在略微有点过时了，但是其思想依旧重要：第一是空间换时间，第二是把整个空间参数化到 2D Texture 或 3D Volume 上，便于后续管理
  - Light Probe
    - 在空间中放置一些点，采样周围的光照信息，当物体经过时，采样这些点进行插值，算出自己的光照，总之，就是一个空间体素化的思想。这些点不会太多，比如 light map 可能需要采几百万个点来烘焙，而 light probe 可能几百个就差不多了
    - 但问题在于，谁来摆这些点？早期可以让美术手动用编辑器工具放置，但关卡变动导致需要重新放置，因此更好的方法是自动化（根据玩家可到达区域和场景几何均匀地撒点）
    - 还有一种特殊的 probe 叫做 reflection probe，专门用来采样反射光照，密度低一些但精度更高
    - 在实际运用中，我们可能会从相机位置往四周看，从而在 shader 中高效计算出光照；计算出的光照也不会在下一帧直接弃用，而是根据移动距离之类判断是否需要更新；另外，可以对 light probe 进行一些压缩，并不会损失太多精度
    - 总的来说，Light Probe 运行效率很高，它同时处理了 diffuse 和 specular，并且能处理动态物体；不过缺点是一系列 SH light probes 需要一定的计算，以及精度往往不如 light map
- 基于物理的材质
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
- Image-Based Lighting (IBL)
  - 对背光面的表达、对环境光的表达，最常见的方法
- 经典阴影方法
  - Big World and Cascade Shadow
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
- 前沿技术
  - Real-time Ray-Tracing on GPU
  - Real-time Global Illumination
  - Virtual Shadow Maps
- Shader Management
  - 美术画 shader graph 会产生大量 shader，此外程序员编写的 uber shader 在编译展开之后会产生大量的 variants
  - Cross Platform shader

== Lec6: 游戏中地形大气和云的渲染
=== 地形的几何
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

=== 地形的材质
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

=== 地形问题杂项
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

=== 大气和云的渲染





