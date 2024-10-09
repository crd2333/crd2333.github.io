#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机视觉导论",
  lang: "zh",
)

= Introduction
== What's Computer Vision
- Computer vision tasks
- 3D reconstruction 3D 重建
  3D reconstruction 3D重建, localization 定位, SLAM 即时定位重建, ……
- Image undestanding 图像理解
  Image recognition 图像识别, object detection 物体识别, image segmentation 图像分割, action recognition 动作识别, deep learning 深度学习, ……
- Image synthesis 图像合成
  Colorization 着色, super-resolution 超采样, debluring 去模糊, HDR 合成, panorama stitching 全景拼接, free-viewpoint rendering 自由视角渲染, GANs 生成对抗网络, ……

- 我们人类看到的是图像，而计算机看到的是像素值
  - computers can be better at computing
  - humans are better at understanding
  - 但具体为什么，还有待对人类智能的研究
  - 人类视觉常常被误导

== What's Computer Vision used for
- 计算机视觉的各种应用，略

== Course Overview
- Basics (Lec.2 - Lec.4)
- Reconstruction (Lec.5 - Lec.8)
- Understanding (Lec.9 - Lec.11)
- Synthesis (Lec.12 - Lec.13)

== Review of Linear Algebra
- 向量的各种运算
- 矩阵的各种运算
  - 仿射变换
  - 齐次坐标
  - 行列式(marix determinant)：几何意义为行向量或列向量张成的有向面积（体积）
  - 特征值和特征向量
  - 矩阵的特征分解
  - 矩阵的奇异值分解

= Image Formation
- 针孔相机模型
  - 假如直接在物体面前放一个底片，由于像平面上的一个点接收到物体上各个方向的光线，因此无法成像
  - 使用小孔成像使得一一对应关系成立
  - 但是当孔太小时，会产生光的衍射现象；并且孔太小也会导致通光量不足

== 透镜成像
- 放大率
$m=(h_i)/(h_o)=i/o$，当 $o$ 较大时，$i$ 近似等于 $f$，可以说焦距也决定了图像放大率（拍照调焦的原理）

- Field of View(FOV)
取决于焦距与底片(sensor)的大小。从成像质量来看，底片越大越好（每个像素收到的光更多，信噪比更好），因此现在的工业目标就是在缩小底片的同时维持好的信噪比

- 光圈(Aperture)与光圈数(F-number)
通过放大/缩小光圈来控制图像的亮度。$N=f/D$，$f$ 是焦距，$D$ 是光圈直径，光圈数越大，光圈越小，进光量越少。

- Lens Defocus & Blur Circle
当 $f$ 和 $i$ 固定时，理论上只有一个面(深度)在成像平面上是清楚的，所以我们需要对焦（略微调整底片位置或透镜位置，i.e. 调整 $i$）。
弥散圆(Blur circle diameter):$b=D/i' |i'-i|$
#fig("/public/assets/Courses/CV/2024-09-19-11-22-07.png")

- 景深(Depth of Field)
虽然有了弥散圆与 defocus 的概念，但是我们可能会疑惑生活中的照片并非仅有一个深度才是清晰的，这是因为图像并非连续的，而是由一个个方格（像素）构成的，当弥散圆落在一个像素内时，它表现出来也是清晰的，这就引入了景深的概念
#fig("/public/assets/Courses/CV/2024-09-19-11-25-42.png")
$
c = (f^2 (o-o_1))/(N o_1(o-f)) = (f^2 (o_2-o))/(N o_2(o-f))\
"Depth of Field" o_2 - o_1 = (2o f^2 c N (o-f))/(f^4 - c^2 N^2 (o-f)^2)
$

- 综合利用以上概念，可以得到背景虚化、人物清晰的照片
  + Large aperture，增大进光量
  + Long focal length，把上式分子分母同除以 $f(o-f)$，可以得到 $f arrow.tr ~~=>~~ "depth of filed" arrow.br$
  + Near foreground & Far Background，使人物落入景深而背景不在景深内

== Geometric image formation
- 透视投影
#fig("/public/assets/Courses/CV/2024-09-20-17-00-54.png")
- 引入齐次坐标，将投影表示为线性变换
$
mat(f,0,0,0;0,f,0,0;0,0,1,0) vec(x,y,z,1) = vec(f x,f y,z) #sym.tilde.equiv vec(f x/z, f y/z, 1)
$
#fig("/public/assets/Courses/CV/2024-09-19-11-41-05.png")
- 在透视投影中，直线仍然是直的，但长度和角度丢失了。深度信息部分丢失，虽然近大远小，但同一个图像对应无穷多三维形状
- Vanishing points & Vanishing lines
  - 铁路汇聚的尽头就是消失点；两个消失点的连线就是消失线
  - 平面上的任何一组平行线都定义了一个消失点，所有这些消失点的结合就是消失线
  - 不同的平面唯一定义了不同的消失线
- 投影失真 Perspective distortion
  - Problem for architectural photography: converging verticals
  #fig("/public/assets/Courses/CV/2024-09-20-19-38-53.png")
  - Solution: 取景器(view camera)，镜头相对胶片可以移动
  - The distortion is not due to lens flaws.
- 径向失真 Radial distortion
  #fig("/public/assets/Courses/CV/2024-09-20-19-40-21.png")
  - 由现实镜头的非理想性引起，对于穿过透镜边缘的光线更为明显。
  - 分为桶形畸变(barrel distortion)和枕形畸变(pin cushion distortion)
- Orthographic projection 正交投影

== Photometric image formation
- 描述了 3D 世界物理性质与 2D 图像颜色之间的关系
- Image sensor
- Shutter
  - The pixel value is equal to the integral of the light intensity within the exposure time
- Color spaces: RGB, HSV
- Bayer filter
  - 对于彩色图像，需要采集多种基本的颜色，最简单的方法是用滤镜的方法
  - 如果要采集 RGB 三种颜色，则需要三种滤镜，价格昂贵。
  - 而 Bayre Filter 在一块滤镜上设置不同颜色，由于人眼对绿色比较敏感，因此绿色较多
- Model the light reflected by an object : Shading
  - 后面的内容是直接 copy from GAMES101，参见 #link("https://crd2333.github.io/note/Courses/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/index/")[计算机图形学笔记]


= Image Processing
== Image processing basics
#let blur = math.text("blur")
- 一些基本处理
  + Increase contrast
  + Invert
  + Blur
  + Sharpen
- Convolution
- Padding
- 几种 filter
  - Guassian blur & Sharpen
    - $f(i, j)= 1/(2 pi sigma^2) e^(- (i^2+j^2)/(2 sigma^2))$
    - $sigma$ 越大越模糊
    - Sharpen
      - Let $I$ be the original image
      - High frequencies in image $I=I-blur()$
      - Sharpened image $I'= I+(I-blur())$
  - Edge detection filter
  - Gradient detection filters
  - Bilateral filter
    - 保持边缘的同时去除噪声

== Image Sampling
- 采样时有可能发生失真（反走样/锯齿）现象
- 主要原因是 —— 采样的速度跟不上信号变化的速度（高频信号采样不足）

=== Fourier Transform
- 傅里叶变换本质上是把函数与不同频率的三角函数做内积，得到它在不同频率下的分量
- 即：用不同频率的正余弦函数加权表示原函数
  #fig("/public/assets/Courses/CV/2024-09-26-11-49-09.png")
- PPT 里展示了一些常见的信号的傅里叶变换

=== Signal & Frequency
- Convolution Theorem
  #fig("/public/assets/Courses/CV/2024-09-26-12-00-47.png")
  - Box filter = low-pass filter
  - Wider kernel = lower frequency
- Sampling
  - Sampling a signal = multiply the single by a Dirac comb function（狄拉克函数）
  - Sampling = Repeating Frequency Contents
- Nyquist-Shannon theorem
  - Consider a band-limited signal: has no frequencies above $f_0$
  - The signal can be perfectly reconstructed if sampled with a frequency larger than $2 f_0$
- anti-alisaing
- 其实基本也都是图形学的内容


== Image magnification
- Interpolation
  - Nearest neighbor
  - Bilinear
  - Bicubic


