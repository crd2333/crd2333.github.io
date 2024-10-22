#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Reconstruction",
  lang: "zh",
)

#let SDF = math.text("SDF")
#let clamp = math.text("clamp")
#let Occupancy = math.text("Occupancy")
#let NeRF = math.text("NeRF")

= Implicit Neural Representations
== 简单引入
- 参考
  + #link("https://github.com/vsitzmann/awesome-implicit-representations")[github.com/vsitzmann/awesome-implicit-representations]
  + #link("https://blog.csdn.net/weixin_43117620/article/details/131980822")[浅谈3D隐式表示(SDF, Occupancy field, NeRF)]
  + #link("https://blog.csdn.net/weixin_42145554/article/details/126637671")[概述：隐式神经表示(Implicit Neural Representations, INRs)]
  + #link("https://zhuanlan.zhihu.com/p/156625765")[SIREN: 使用周期激活函数做神经网络表征]
- 三维空间的表示形式可以分为显式和隐式
  - 比较常用的显式表示比如体素 Voxel，点云 Point Cloud，三角面片 Mesh 等
  #fig("/public/assets/AI/Reconstruction/2024-10-10-16-02-46.png", width: 60%)
  - 隐式神经表示(Implicit Neural Representations, INRs)是一种对各种信号进行参数化的新方法。传统的信号表示通常是离散的，而隐式神经表示将信号参数化为一个连续函数、场，将信号的域映射到该坐标上的属性的值，这些映射通常不是解析性的，但可以被神经网络所拟合
  - 显式 vs 隐式
    + 隐式的优点在于：表示不再与空间分辨率相耦合、表征能力更强、泛化性高、相对易于学习、空间需求一般相对较小；
    + 缺点在于：需要后处理、可能过度平滑、计算量大
  - 隐式神经表示的应用领域包括：超分辨率、新视角合成、三维重建等
- 比较常用的隐式表示有：符号距离函数 Signed Distance Funciton(SDF)，占用场 Occupancy Field，神经辐射场 Neural Radiance Field(NeRF) 等
  - 这些函数 function 与场 field 实际上都是一种映射关系，
  $
  SDF(p) = s, ~~~ x in RR^3, s in RR \
  Occupancy(p) = o, ~~~ x in RR^3, o in [0, 1] \
  NeRF(x,y,z,bd) = (R,G,B,sigma), ~~~ x,y,z in RR, "RGB is color, " sigma "is density"
  $
  + SDF: 点在曲面内部则规定距离为负值，点在曲面外部则规定距离为正值，点在曲面上则距离为 $0$ #hide[#link("https://zhuanlan.zhihu.com/p/536530019")[SDF(signed distance field)]]
  + Occupancy: 通常以 $0.5$ 为标准，大于 $0.5$ 倾向于认为点被曲面占用（在内部），$0.5$ 倾向于认为点没有被曲面占用，$0.5$ 认为点在曲面上（即 $F(p)=0.5$ 表示一个曲面）
  + NeRF: 将“空间中的点 + 点发出的一条射线” 映射到 “点的密度值 + 射线的方向对应的颜色值”；或者说，空间中每一个点的每一个角度，都对应一个颜色值和一个透明度。反过来，从空间中一个点出发，沿着某个方向看去，看到这个方向上的颜色和透明度

== Literature Tree
- 可以先从 #link("http://crd2333.github.io/note/Reading/Reconstruction/SIREN")[SIREN（笔记链接）] 和 #link("http://crd2333.github.io/note/Reading/Reconstruction/DeepSDF")[DeepSDF] 开始看
- 然后再看相对近代和比较重要的 #link("http://crd2333.github.io/note/Reading/Reconstruction/NeRF")[NeRF] 及其 #link("http://crd2333.github.io/note/Reading/Reconstruction/NeRF改进工作")[改进工作]
  - NeRF 本质上是用神经网络拟合一个隐式表示场，结合了 Ray-Marching 和体渲染的方法实现新视角图片的合成
  - NeRF 的待改进点在于：速度优化，泛化性，动态场景与大场景，可解释性，视角需求数等
  - NeRF 的改进工作
    - 关于 NeRF 的改进，核心在于提高渲染速度和质量。它慢就慢在两点：逐像素射线并采样点，点的分布不合理；每个点都需要过一遍 MLP 以得到辐射场属性
      - NSVF 从采样的角度出发试图解决问题；
      - FastNeRF, PlenOctrees, KiloNeRF, TensoRF 等工作五花八门，但本质上都还是利用体素化的方法往显式表示那边靠，减少 MLP 前向的时间开销。其中 Plenoxels 是比较激进的一个，变成了完全显式的方法（只是借用了 NeRF 的体渲染方法和辐射场属性）；而 DVGO, InstantNGP 等 Hybrid 的方法结合了显式和隐式的优势，实现了更快的渲染速度
      - MobileNeRF 在体素网格的基础上，把体渲染过程塞到图形渲染 pipeline 里，首次实现了移动设备上的实时渲染
    - 关于 NeRF 的泛化性改进，我看的两篇 GRAF, GIRAFFE 利用 GAN 和额外随机采样的编码来一定程度上变得多样
    - 关于 NeRF 的大场景渲染问题，NeRF++, Mip-NeRF, Mip-NeRF 360 的思路基本上是要么用非线性变换控制场景的采样频率，要么是把光线渲染变成光锥渲染（本质上也是控制了采样频率）
- 最后是基本薄纱 NeRF 的 #link("http://crd2333.github.io/note/Reading/Reconstruction/3DGS")[3DGS]
  - 3DGS 本质上是又回到了显式表示（3D 高斯球），使用 splatting 代替体渲染方法，实现高速渲染
  - 围绕 3DGS 的工作就没有那么 focus on 速度，而是变得五花八门，并且把之前 NeRF 上做过的各种应用都拿过来刷了一遍，但是看得还不多
- 最后，用一张 NeRF 阵营图做结，不得不说总结得确实很有意思也挺有道理
  #fig("/public/assets/AI/Reconstruction/2024-10-24-15-21-18.png")