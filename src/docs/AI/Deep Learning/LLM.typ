#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "Deep Learning for Language Models",
  lang: "zh",
)

#let softmax = math.op("softmax")
#let QKV = $Q K V$
#let qkv = QKV
#let Concat = math.op("Concat")
#let MultiHead = math.op("MultiHead")
#let Attention = math.op("Attention")
#let head = $"head"$
#let dm = $d_"model"$
#let FFN = math.op("FFN")

= LLM
- 关于 Transformer 的基础可以参考 #link("http://crd2333.github.io/note/Reading/%E8%B7%9F%E6%9D%8E%E6%B2%90%E5%AD%A6AI/Transformer")[原论文阅读笔记]

#hide[
  - #link("https://lhxcs.github.io/note/AI/EfficientAI/LLM/")[lhx 的笔记]
]

== Transformer Design Variants
=== Encoder-Only: BERT
- BERT: #strong[B]idrectional #strong[D]nocder #strong[R]epresentations from #strong[T]ransformers
- BERT 就是字面意思的只含 Encoder，它提出的动机是想类似 CV 那样做一个预训练提取 feather 的模型，然后在上面做 fine-tuning
#fig("/public/assets/AI/AI_DL/LLM/2024-09-21-17-14-54.png")
- 它包含两个预训练任务：
  1. Masked Language Model (MLM)
  $15%$ 的 token 会被特殊处理。其中 $80%$ 替换为为 `<mask>`，$10%$ 替换为随机词，$10%$ 不变（作弊，糊弄，挖空）。

  2. Next Sentence Prediction (NSP)
  $50%$ 的概率选择相邻句子对作为正例，$50%$ 的概率选择随机句子作为负例，然后用第一句话开头的 `<cls>` 抽出的 feather 放到全连接层来预测

  - 个人理解 MLM 这种设计有两方面的原因：
    + 不确定 Google 处理预训练数据是怎么样的，但从李沐提供的数据处理方法可以看出，数据的 mask 处理是在训练开始前就处理好了的（哪个 token 被 mask 在每个训练迭代周期里都是固定的）。如果 mask 方法都是替换为 `<mask>` 标记，有可能导致某些 token 被掩码了，模型自始至终都在预测它却没有见过它，会影响下游任务微调的效果。因此设置 $10%$ 几率不变
    + $15%$ 的词当中以 $10%$ 的概率用任意词替换去预测正确的词。作者在论文中谈到了采取上面的mask策略的好处。大致是说采用上面的策略后，Transformer encoder就不知道会让其预测哪个单词（不仅仅是 `mask`，现在其它 token 也可能需要纠正），逼迫它学习到每个输入 token 的一个上下文的表征分布(a distributional contextual representation)。另外，由于随机替换相对句子中所有 tokens 的发生概率只有$1.5%$($15% * 10%$)，所以并不会影响到模型的语言理解能力

- 输入数据做三种 embedding：
  1. Token Embedding
  2. Segment Embedding：两个句子的区分(`[[0,0,0,0,1,1,1,], ...]`)
  3. Positional Encoding：可学习的位置编码

- BERT 微调
  - 作为不能生成文本的模型，BERT 的下游任务有一定局限性，它的任务一般分为*序列级*和*词元级*应用
  - 序列级应用：单文本分类（如语法上可否接受）、文本对分类或回归（如情感分析）
  #grid2(
    fig("/public/assets/AI/AI_DL/LLM/2024-09-22-15-53-32.png"),
    fig("/public/assets/AI/AI_DL/LLM/2024-09-22-15-53-48.png")
  )
  - 词元级应用：文本标注（如词性分类）、问答（如把语料和问题作为句子对，对语料的每个 token 判断是否是回答的开始与结束）
  #grid2(
    fig("/public/assets/AI/AI_DL/LLM/2024-09-22-15-55-57.png"),
    fig("/public/assets/AI/AI_DL/LLM/2024-09-22-15-56-28.png")
  )

=== Decoder-Only: GPT
- 预训练的目标是 Next word prediction
- 对于小模型(GPT-2) 预先训练好的模型将根据下游任务进行微调。Large model can run in zero-shot/few-shot.


== Positional Encoding
- Absolute Positional Encoding
  - 把位置信息直接加到 embedding 上，会同时影响 #qkv 的值。信息将会沿着整个 Transformer 传播
- Relative Positional Encoding
  - 将位置信息加到 attention score 上，不会影响 $V$。可以泛化到训练中未见的训练长度 (train short, test long)

