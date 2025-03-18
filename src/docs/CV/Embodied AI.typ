---
order: 4
---

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Embodied AI",
  lang: "zh",
)

= Low-level Embodied Intelligence with Foundation Models
- From [stanford CS25] V3 I Low-level Embodied Intelligence with Foundation Models
- 据说是 “入门必看，用讲故事的形式介绍了 Google 解决主流问题的方法和模型”

== 引言
- Why Embodied Intelligence
  - Real world is really complex.
  - We want robot to have "ambient intelligence".
- 有很多种方法实现具身智能，其中一种是创造足够复杂的模拟交互式环境
  - e.g. GibsonEnv in CVPR18, and iGibson in RA-L2020, IROS2021, CoRL2021
- 从大规模模拟数据到基础模型
  - 如果使用 model-free 的强化学习，即使学会一件最简单的事也要成千上万的模拟尝试
  - 尝试利用基础模型中的大量语义先验（可以把基础模型看作是大量数据的压缩，是一个可供查询的知识库）
  - 结合大规模 offline 数据集和大容量模型(e.g. Transformer)，使用语言作为通用胶水
- From "Internet Al" to "Embodied Al"
  - 数据集：从静态数据集到动态的模拟环境
  - 任务：从视觉的 Classification, Segmentation, Detection Generation, Captioning 等到更复杂的 Visual Navigation, Manipulation, Rearragement, Embodied-QA, Mobile Manipulation, Instruction Following...
- Where are we in foundation models + robotics
  - high level reasoning(planning)
  - low level control
- 为什么我们认为基础模型一般用于高层次规划而难以用于低层次控制？
  + Challenge 1: 莫拉维克悖论(Moravec's paradox)，一个人工智能和机器人技术的观察结果。与朴素的直觉假设恰好相反，模型前向推理需要的计算量其实很少，但感觉运动和感知技能则需要大量的计算资源（原因是模型一直在通过推理进行学习，但它们并不像人类一样把感知和运动刻在了 DNA 里）
  + Challenge 2: training data biase，比如我们的基础模型（大语言模型）训练的数据中有教你如何做菜的文章，却没有教你如何把手向左移动 5 cm（fine-tune 当然是一个办法，但其实不算特别好做，后面会展开）
  + Challenge 3: LLM 缺少对 low level control 的 interface，换句话说，很难要求 LLM 输出关节的具体角度或编写详尽的控制代码
- 所以本次课分为两部分
  + Part 1: Model consolidation, joint scaling, positive transfer
  + Part 2: New interfaces of LLMs

== Model Consolidation, Joint Scaling, Positive Transfer
- 模型整合：在一个模型中完成高层次规划和低层次控制
- 聚合 scale：不仅 scale 昂贵的机器人数据，也 scale 视觉语言模型的预训练数据
- 正向转移：模型受益于多样的 joint training（互联网语言、视觉、视觉语言等多模态跨模态的训练）
  - 其实 NLP 那边到处可见 positive transfer，因为太常见所以没人提，但是 Robotics 这边还没发展到那个阶段，也还没有那么多数据
- 从这张图中我们可以看到模型越来越趋向于整合，它的背后是任务的整合，把所有任务都表示成(vision plus text to text task)
  #fig("/public/assets/AI/Embodied/2024-10-06-13-11-04.png")
- #link("https://palm-e.github.io/")[PaLM-E]
  #fig("/public/assets/AI/Embodied/2024-10-07-11-11-52.png")
  - 它使用 muitimodal tokens（来自 ViT 或机器人 sensory data），训练参数把它变换到单词语义的嵌入空间，很自然地把基础大语言模型与多模态数据对齐
  - Trained on: robot data, Internet-scale VQA, captioning，在多种数据上展现出 Positive Transfer
  - Neural 3D scene, and robot state encoders into the LLM
  - Obiect-centric reasoning（传统的 ViT 是基于网格的，不是很能保持对象及其关系的理解）
- RT-2: Vision-Language-Action Models Transfer Web Knowledge to Robotic Control
  - 比起 PaLM-E，RT-2 结合了低层次控制（更加 end to end？）
  - 它可以在桌上的一堆玩具中把 extinct animal 跟 dinosaur 以及 action to pick up 联系起来（即使在机器人训练数据集中没有见过，不过互联网 catalog 中可能有）

=== 一般的 VLM 和 RT-1 的架构
- VLM 大致架构（Google 内部使用的 PaLi），用 ViT 抽取图像特征，然后和文本信息一起送入另一个 Transformer
  #fig("/public/assets/AI/Embodied/2024-10-07-11-13-52.png", width: 70%)
- #link("https://robotics-transformer1.github.io/")[RT-1 架构]（时间：2022.12）
  #fig("/public/assets/AI/Embodied/2024-10-07-11-17-03.png")
  - language instruction 通过通用 sentence encoder 抽特征，然后和图像一起送入 FILM EfficientNet，先后压缩成 81 个、8 个 tokens，加上位置编码后送入Transformer 块，生成 7 个自由度的 actions
    - FILM EfficientNet 是一个卷积神经网络(basically ResNet)，它把图像 tokonize 化，同时把吸收理解语言嵌入并附加在 ResNet 的中间层
    - 其实有很多种融合 Vision Language 的方法（early fufusuon, late fusion, cross attention...），这只是其中一种考虑到 latency 的做法
  - RT-1 与一般的具有特殊输出标记的 VLM 十分相似，所以直接用大型预训练 VLM 作为 policy 是非常自然的

=== #link("https://robotics-transformer2.github.io/")[RT-2 架构], VLA
- 时间：2023.7
- Represent actions in VLM
  - 机器人机械臂的位置、角度，可以建模成浮点数、人类语言、正整数
  - Google 尝试后使用了 discretized to 256 bins 的做法，使用一系列数字来表征动作
  #fig("/public/assets/AI/Embodied/2024-10-07-11-27-58.png", width: 80%)
- training the model
  #fig("/public/assets/AI/Embodied/2024-10-07-11-30-01.png", width: 80%)
  - 在预训练好的 VLM 上 co-fine-tune，即混合互联网图文数据和机器人数据，使得模型保持 Internet acale knowledge 并且不会因为过小的机器人数据而过拟合
    - 这可能是以后每个垂直领域都要用的方法
  - 机器人的数据基本上是构造成 QA 的形式
- Inference
  #fig("/public/assets/AI/Embodied/2024-10-07-11-29-10.png", width: 80%)
  - 继续将任务指令构造成 QA，和机器人观察（自回归，过去+现在，相机的 RGB 图像）送入模型
  - 使用 constraint decoding(?) 确保模型始终输出8 个数字，然后 de-tokenize 成 anti-factor delta pose，送给机器人去运行
  - 因为整个前向过程涉及到亿级参数，所以是以大概 3 \~ 10 Hz 的速率远程运行在 TPU 集群上
- Chain of thoughts 现象
  - 通过 prompt 引导 VLA 去一步步思考计划，用这种 augmented instructions 去微调
  - 结果模型展现出逻辑链的能力
- Summary of Vision-Language-Action (VLA) models
  - Improved generalization
  - New tasks and obiects
  - Chain-of-Thought (CoT) reasoning
  - Improving underlying model can improve robot control
  - Future
    + Increasing motion diversity
    + Extending on CoT capabilities

=== #link("https://robotics-transformer-x.github.io/")[RT-X 数据集]（时间：2023.10）
- 另一个 positive transfer 的例子
  - 集合了许多家实验室的数据，把机器人数据集变得更大，包含多种任务和机器人实例
  - 在这个数据集上训练的机器人表现出显著的正向迁移特性

== New interfaces of LLMs
- LLMs <-> reward as an interface <-> low-level control
- Language Models as general pattern machines

=== #link("https://language-to-reward.github.io/")[Reward as An Interface]
- 时间：2023.6
- 动机
  - 当我们规定 action representation 后，Language Model 经过微调就能生成 action tokens，从一个 high-level 的角度看，动作可以视为语言模型的另一种特殊语言
  - 我们是否能生成超出微调范围的 more expressive actions？之前我们说缺少一个 API，但是其实一个具体的 API 往往限死了模型的上限
  - 作者认为最佳的 API 应该是奖励函数，它是通用的且已被强化学习所验证，更重要的，它是 actions 的重参数化(reparameterization)
    - 试想我们让机器人拿起一个水杯，这是一个 skill（或者说，一种观察和行动之间的映射）
    - 但是 skills 有更通用的定义 —— 一组目标和一组约束，这有利于模型在不同 skill 之间能够 tranferable
    - 而更进一步，目标和约束都可以用奖励函数来表征
- 模型
  - 模型总览图
    #fig("/public/assets/AI/Embodied/2024-10-07-11-09-21.png")
  - 我们可以要求模型输出奖励函数，然后用一个 Motion Controller（可以是强化学习，或者单纯的一个预测控制的模型如 MuJoCo MPC）在这组奖励函数上去优化
  - 然后，原来的 LLM 可以视为 reward translation，基本上它分两阶段把自然语言 describe 成动作描述，再 encoder 成 reward functions
    - 消融实验证明，结果的提升不仅来自 reward encoder，two-stage 的 translator 也很重要
    #fig("/public/assets/AI/Embodied/2024-10-07-11-09-53.png")
- 实验结果
  + 在 Quadruped Robot（自由度较多所以很难让模型直接输出动作）上，语言模型似乎能生成合适的奖励函数，让四足机器人两脚站起来
  + 甚至可以通过自然语言调整来一步步指导它学会太空漫步这种复杂动作（一步步指导这种行为在之前的模型上也是不可能的）
  + 在 transfer to real 的过程中，模型可能会输出过于灵活的动作导致硬件无法执行，所以需要一些正则化和限制
- 这些做法看起来不那么端到端，但也启示我们：当你的领域与语言差太大时，最好找一个中间表示，并要求模型在直接进入更模糊的表示之前用这个中间表示进行解释

=== #link("https://general-pattern-machines.github.io/")[LLM as Genereal Pattern Machines]
- 时间：2023.7
- Example
  + high-level semantics: The student takes out the \_\_\_\_
  + Low-level patterns: 70, 76, 66, 60, 54, \_\_\_\_
- 过去我们把语言模型视为一个语义引擎(semantic engine)，这里我们探索使用 LLM 的低级接口，本质上是要求它推理不同的序列，并且效果出奇地好，可以解决 ARC, PCFG 等任务，这里聚焦于 Sequence Improvement
  #fig("/public/assets/AI/Embodied/2024-10-07-11-07-45.png")
- Sequence Improvement 是使用 state, action, reward tuples 来 prompt LM，看它是否能产生获得更高 reward 的行动。换句话说，是在 LLM 的 context 中做强化学习（而不需要特定的 algorithm, replaybuffer）
- 这将能允许我们使用 clicker trainning（一种 human feedback 的方式，当机器人做正确的事时 click 一下，即给正向 reward）进行训练

== Summary
- 这次演讲的关键要点是
  - 我们看到越来越多的基础模型不仅在机器人的 semantic reasoning 方面，而且更多地在生成动作这种 low-level control 方面使用
  - Part 1:Model consolidation, joint scaling, positive transfer
    - Rethink the Scaling Law of Robotics Transformer.
    - A new recipe for scaling robot model and data.
      + RT-2 shows you can do more with the same data.
      + RT-X shows you can do a lot more with more data.
    - Positive transfers everywhere.
  - Part 2:New interfaces of LLMs
    - Develop new(lower) level interfaces to LLMs.
- GPT 总结
  - 本次演讲介绍了两种通过将大型语言模型(LLM)与机器人技术集成来实现低级具身智能的新方法，重点是“RT-2”和“语言奖励”。
    + 前者通过协同微调机器人轨迹数据和广泛的基于网络的视觉语言任务，将先进的视觉语言模型与机器人控制相结合，从而形成了具有强大泛化能力的鲁棒 RT-2 模型。这种方法允许机器人执行未经训练的命令，并有效地执行多阶段语义推理任务，体现了上下文理解和对用户命令的响应方面的重大进步。
    + 后者使用 LLM 生成奖励代码，在高级语言指令和低级机器人动作之间架起一座桥梁。该方法允许实时用户交互，有效地控制机器人手臂执行各种任务，并优于基线方法。
  - 这些项目表明，语言模型可以扩展到其传统的高级推理任务领域之外，不仅在解释和生成指令方面，而且在精细生成低级机器人动作方面都发挥着至关重要的作用。









