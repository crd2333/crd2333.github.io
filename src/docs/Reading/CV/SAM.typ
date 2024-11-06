#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "SAM",
  lang: "zh",
)

= Segment Anything
- 时间：2023.4.5
- 如标题所述，这篇论文只做了一件事情 —— （零样本）「分割一切」，类似 GPT-4 已经做到的「回答一切」。它将 NLP 的 prompt 范式引入了 CV 领域，进而为 CV 基础模型提供更广泛的支持与深度研究。SAM 的名称来源于 Segment Anything Model，它的出现统一了分割这个任务的下流应用，说明了 CV 的大模型是可能存在的，几乎“让 CV 不存在了”
- Demo 展示了许多形式的交互，能很好的自动分割图像中的所有内容，能根据提示词（点、框、区域、文本）进行图像分割，可以为任何图像或视频中的任何物体生成 mask

== 摘要 & 引言
- Segment Anything(SA) 项目：图像分割领域一个新的任务、新的模型和数据集。建立了迄今为止最大的分割数据集，在 11M 图像上有超过 1 亿个 mask。模型的设计和训练是灵活的，可以 zero-shot 到新的图像分布和任务，并且打败了许多 supervised/finetuned 的分割模型
- NLP 领域正在被“大规模数据集上预训练大型语言模型，用零样本和少样本泛化”的范式彻底改变。这些“基础模型”的泛化能力通常来自提示工程(prompt engineering)。经验表明，这种行为随着模型规模、数据集大小和总的训练计算量而改善(Scaling Law)
- 基础模型也在 CV 得到了一定程度的探索。最突出的 illustration 是图像文本对齐（e.g. CLIP and ALIGN 使用对比学习），训练后的模型在提示工程的加持下 获得 zero shot 的能力，它们的编码器还可以有效地与其他模块进行组合，以实现下游任务如图像生成(e.g, DALL·E）。但总的来说，CV 整个领域大大超出这个范围，缺少丰富的训练数据
- 因此这项工作的目标就是开发一个可提示的图像分割领域的基础模型，在一个大数据集上预训练，解决一系列下游分割问题。
- 项目关键三部分：任务、模型和数据。为此探索以下问题
  + 什么 task 可以实现零样本泛化？
  + 对应的 model 架构是什么？
  + 哪些 data 可以支持这项任务和模型？
  - 后续一个个展开

#fig("/public/assets/Reading/CV/SAM/2024-10-28-19-19-43.png")
== Task
- *提示分割任务(prompted segmentation task)*：在给定任何 prompt 下返回一个有效的分割掩码 mask
  - prompt 有多种类型，比如点、框、区域、文本。这个 prompt 可能是上游任务的输出（比如前面套一个目标检测任务，输出锚框）
  - 模型需要有对模棱两可的 prompt 的处理能力。比如点衬衫可能表示衬衫或穿衬衫的人，模型应该至少输出一个合理的 mask，从而可以用来解决下游任务
- *Pre-Training*
  - 根据提示分割任务自然地提出一种预训练算法，为每个训练样本模拟一系列提示，将模型预测出的掩码与 GroundTruth 比较
  - 继承了交互式分割的方法，但不同的是，交互式分割目标是在足够的用户输入后最终预测有效的掩码，而 SAM 的目标是始终为任何 prompt 预测有效的掩码。这种效果十分困难，需要专门的模型和损失函数选择，在第三节详细讨论
- *Zero-shot transfer*
  - 很直观地，因为预训练任务要求模型对任何 prompt 做出适当响应，因此下游任务直接设计适当 prompt 即可。比如对 instance segmentation 任务来说，detector 输出的框就可以作为 prompt 输入
- *Related tasks*
  - 分割领域非常广泛：有 interactive segmentation 交互式分割，edge detection 边缘检测，super pixelization 超像素化，object proposal generation 对象建议生成，foreground segmentation 前景分割，semantic segmentation 语义分割，instance segmentation 实例分割，panoptic segmentation 全景分割等
  - 而 SAM 的目标是泛化到包括现有和新的分割任务。这种能力是一种作为基础组件去进行任务泛化的形式，是泛化能力的体现，与以前的多任务分割系统是不一样的（那些就只是每个模型各自能处理固定的子任务，然后组合在一起）
- *Discussion*
  - prompting 和 composition 是很强大的工具，可能使得模型能够应用到目前想不到的任务上去，展现更大的潜力。例如，CLIP 最开始只是文本图像对齐提取特征的模型，后来却被 DALL·E 应用到图像生成领域。作者预计它们这么有影响力的工作也能有类似的效果

== Model
- SAM 一共分为 3 个组件：Image encoder, Prompt encoder, 轻量快速的 Mask decoder
- *Image encoder*
  - 使用 MAE 方法预训练的 ViT，image encoder 相对耗时，但对每个图像只运行一次，并且可以在 prompt encoder 之前用
- *Prompt encoder*
  - 主要分为两类：sparse(points, boxes, text) 和 dense(masks)
  - points, boxes 通过 positional encoding 和每个种类各自的 learned embeddings 相加来表示；自由文本使用 CLIP 现成的 text encoder 来表示；dense 表示（即掩码）使用卷积嵌入，并与图像嵌入元素相加
- *Mask decoder*
  - mask decoder 需要有效地将 image embedding, prompt embeddings 以及一个额外的输出 token 映射到 mask
  - 具体设计就是 Transformer 里面的一些设计，然后跟一个 dynamic mask prediction head
    - 具体而言就是 prompt self-attention 和 bidirection cross-attention(prompt-to-image, image-to-prompt)
    - 过两个 block 之后，对 image embedding 进行上采样
    - MLP 将输出 token 映射到 dynamic mask prediction head，然后在每个图像位置计算掩码前景概率
- *Resolving ambiguity*
  - 如果给了一个带歧义的 prompt，模型可能对多个掩码都认为有效。那为了解决这个问题就干脆对单个 prompt 预测多个输出掩码就好了
  - 作者认为 $3$ 个掩码输出一般就足够了(whole, part and subpart)。输出哪三个呢？模型预测每个掩码的 IoU 分数，据此对 mask 进行排序
  - 训练期间只用哪个 loss 最小的 mask 来梯度反传
- *Efficiency*
  - 整个模型是很看重效率的，image encoder 可能慢了点，但是 prompt encoder 和 mask encoder 在 Web 浏览器中以 CPU 运行，运行时间大约为 50 毫秒。这样才能无缝无感知地给用户提供交互式体验
- *Losses and training*
  - 使用 focal loss 和 dice loss 的线性组合。使用 geometric prompts 的混合来训练（文本 prompt 是后加的），在每个掩码中随机采样 $11$ 轮 prompt 来组成 prompt-ground truth 对来模拟交互式分割

== Data
- Data Engine 这一块不算特别创新，因为这种 pseudo-label 左脚踩右脚上天的方式早就有了，但这一块对 SAM 其实有可能反而是最重要的（因为网络上分割相关的数据没有图像文本对那么多），主要分为三个阶段：
- *Assisted-manual stage* 人工辅助阶段
  - 第一阶段，SAM 使用常见的公共分割数据集训练一个小的模型，然后人工在浏览器上交互式地对其预测结果使用像素级别的 "brush" 和 "eraser" 工具进行 refine
  - 没有对标注对象施加语义约束，标注员被建议按重要顺序标注他们能够命名或描述的对象，自由地标注 "stuff" 和 "things"，但是没有收集这些名称或描述，并且鼓励一个掩码图像用 $30$ 秒左右的时间
  - 在收集足够的数据标注之后，SAM 仅使用新标注的掩码重新训练。随着收集的掩码越来越多，image encoder 从 ViT-B 扩展到 ViT-H，其他架构细节也不断进化
  - 这样重新训练的过程总共进行 $6$ 次。随着模型改进，每个掩码的平均花费标注员的时间降低，每个图像的平均掩码数量增加。总的来说，在这个阶段收集了 $120 K$ 张图像的 $4.3 M$ 个掩码
- *Semi-automatic stage* 半自动阶段
  - 这个阶段的目标是增加掩码的多样性，提高模型的 segment anything 能力
  - 在第一阶段的所有掩码上使用通用的 "object" 类别训练了一个 bounding box 检测器，自动检测置信度高的掩码。随后像向标注员展示填充了可信掩码的图像，要求他们标注任何未标注的对象
  - 与 stage 1 一样，定期在新收集的数据上重新训练模型（5次）。随着模型改进，每个掩码（不包括自动掩码）的平均花费标注员的时间又升高（因为这些对象更难标注），每个图像的平均掩码数量增加（包括自动掩码）。总的来说，在这个阶段收集了 $180 K$ 张图像的 $10.2 M$ 个掩码
- *Fully automatic stage* 完全自动阶段
  - 在最终阶段，标注是完全自动的，真正是左脚踩右脚上天的时刻了。这当然是有条件的，首先到此为止已经收集了足够数量和多样的掩码来大大改进模型，其次模型已经有了一定的 ambiguity-aware 能力
  - 当然对预测出的伪标签还是要进行一定筛选的，主要是两个指标 —— confident 和 stable
    + 模型内有个模块是用 MLP 把 IoU output token 映射到 IoU scores(confident scores)；
    + 此外还识别并选择 stable 的掩码，也就是说把阈值在 $0.5-delta$ 和 $0.5+delta$ 之间调整，如果结果都是相似的(IoU > $95%$)，那认为这个掩码是稳定的
    + 在选择 confident 和 stable 的掩码之后，应用非极大值抑制(non-maximal suppression，NMS)来过滤重复项。为了进一步提高较小掩码的质量，还裁剪出局部区域的多个重叠的放大图像处理
  - 完全自动的掩码生成过程应用于数据集中的所有 $1.1 M$ 张图像，产生了 $1.1 B$ 个高质量掩码，形成最终的 SA-1B 数据集
- SA-1B 数据集
  - 作者的这个数据集因为质量很高所以也算是贡献之一，作者将它发布出来以推动未来工作发展。这里对它进行了说明和横向对比
  - Images。$1.1 M$ 张图像高分辨率很高($3300 times 4950$ in avg)。因为可能带来访存挑战，因此又发布了下采样的版本，最短边设置为 $1500$ 像素。即使是下采样后也比许多现有数据集更高（例如 COCO 是 $480 times 640$ 像素），对人脸、车牌这种以往被模糊处理的分割有很大帮助
  - Masks。Data Engine 产生了$1.1 B$ 个掩码，其中 $99.1%$ 是完全自动的，因此评估其质量至关重要。作者直接将它们与专业标注进行比较，主要结论是这些自动生成的掩码质量很高、属性很好：
    - Mask quality。作者随机抽取了 $500$ 张图像（约 $50 K$ 个掩码），要求专业标注者改进这些图像中所有掩码的质量，产生了自动预测和专业修正的 mask pair。计算了每对之间的 IoU 发现 $94%$ pair 的 IoU > $90%$，97% pair 的 IoU> $75%$。相比之下，以前工作估计过标注者自己之间的 IoU 一致性也就只有 $85-91%$。另外作者还在后续实验通过人类打分证实了掩码质量相对于各种数据集就是更高。所以最后 SA-1B 数据集只包含了那些自动生成的掩码
    - Mask properties。主要对比了这些：对象分布（大家都有摄影师偏见，SA-1B 已经是最小的那个），每张图片的掩码数量（图片多，每张图的掩码数量也最多），图像相对掩码大小（倾向于中小型掩码），形状复杂性（大家都差不多）

== 实验 & 结论
- 在实验之前作者还谈论了一些 RAI(Responsible AI) 的问题，这里就略过了
- 然后作者做了一系列 zero-shot 的实验
  - Zero-Shot Single Point Valid Mask Evaluation 零样本单点有效掩码评估
  - Zero-Shot Edge Detection 零样本边缘检测
  - Zero-Shot Object Proposals 零样本对象建议
  - Zero-Shot Instance Segmentation 零样本实例分割
  - Zero-Shot Text-to-Mask 零样本文本转掩码
    - 这里的关键点是，由于 CLIP 的 image embedding 与其 text embedding 对齐，因此我们可以使用 image embedding 进行训练，但在推理时使用 text embedding。也就是说，在推理的时候，通过 CLIP 的 text encoder 得到的 embedding 作为 SAM 的 prompt
    - 另外，当 SAM 仅靠文本无法做出正确预测时，一个额外的点 prompt 可以提供帮助
  - 不细展开了，反正就是说各种指标都很好（有时候比 supervised 的还好，有时候虽然指标差一点但在人看来反而更好）
- 最后还有 Ablations，也不展开
- 作者的讨论和结论，分为 Foundation models, Compositionality, Limitations 三个部分，前两部分已经简单提过
  - Limitations：虽然 SAM 在总体上表现得很好，但它并不完美
    - 它可能会错过精细的结构，有时会使小的断开的组件产生幻觉，并且不会像 zoom-in 等计算密集型的方法那样清晰地产生边界
    - 一般来说，当提供了许多点时，作者预计那些专用交互式分割方法一般优于 SAM。因为与这些方法不同，SAM 是为通用性和广度而设计的，而不是高 IoU 指标
    - SAM 可以实时处理提示，但是当使用一个巨大的 image encoder 时，SAM 就做不到实时了
    - SAM 文本到 mask 任务的尝试是探索性的，并不完全鲁棒，作者相信可以通过更多的努力来改进
    - SAM 可以执行许多任务，但如何设计简单的 prompt 来实现语义和全景分割尚不清楚
    - 最后，还有一些领域特定的工具，预计会在那些特定领域中优于 SAM
- 业界评价
  - 虽然作者们声称要 "segment everything"，但距离这个目标还有很长的路要走。CV 最大的困难之一，就是图像语义可以无限细分，且逻辑关系非常复杂，势必会遇到识别的粒度和确定性之间的冲突。至少到目前为止，没有任何方法可以解决这个问题，也就没法做到真正的万物分割
  - 不过这个工作确实把 engineering 做到了极致，而且上手即用，非常方便。SAM 作为 foundation model 的潜力非常大，很可能拥有与 CLIP 比肩的影响力，未来将为大量的视觉任务提供支持
  - SAM 其实缩小了大厂和小厂的差距，使得大部分没有资源和数据训练视觉 foundation model 的人，都可以使用 SAM 的特征做各种下游任务
  - SAM 一出，有人认为“CV 不存在了”。NLP 领域的 Prompt 范式已经延展到 CV 领域，可以预想这类范式在学术界将迎来一次爆发。总而言之，未来已来，CV 的 Large Model 时代将彻底开启，至少标注是肯定不存在了
  - 不过，下游任务所面临的困难或许比预训练还要更多！还是强调：CV 还有很长的路要走，不要散布恐慌，自己吓自己
