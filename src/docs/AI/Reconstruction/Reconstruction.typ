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
  + SDF: 点在曲面内部则规定距离为负值，点在曲面外部则规定距离为正值，点在曲面上则距离为 $0$，可能可以参考 #link("https://zhuanlan.zhihu.com/p/536530019")[SDF(signed distance field)基础理论和计算]（还没怎么看）
  + Occupancy: 通常以 $0.5$ 为标准，大于 $0.5$ 倾向于认为点被曲面占用（在内部），$0.5$ 倾向于认为点没有被曲面占用，$0.5$ 认为点在曲面上（即 $F(p)=0.5$ 表示一个曲面）
  + NeRF: 将“空间中的点 + 点发出的一条射线” 映射到 “点的密度值 + 射线的方向对应的颜色值”；或者说，空间中每一个点的每一个角度，都对应一个颜色值和一个透明度。反过来，从空间中一个点出发，沿着某个方向看去，看到这个方向上的颜色和透明度
#hline()
- 可以先从 #link("http://crd2333.github.io/note/Reading/Reconstruction/SIREN")[SIREN] 和 #link("http://crd2333.github.io/note/Reading/Reconstruction/DeepSDF")[DeepSDF] 开始看
- 然后再看相对近代和比较重要的 #link("http://crd2333.github.io/note/Reading/Reconstruction/NeRF")[NeRF] 及其改版
- 最后是基本薄纱 NeRF 的 3DGS


