---
html:
    embed_local_images: true # 设置为 true，那么所有的本地图片将会被嵌入为 base64 格式
    embed_svg: true
    offline: false
    # toc: undefined # 默认是缺省的，目录会被启动，但是不会显示。可以设置为 true 或 false，来主动 显示 或 隐藏

    # 导出设置
puppeteer:
    landscape: false
    format: "A4"
    # timeout: 3000

markdown:
    image_dir: ./assets
    # path: output.md
    ignore_from_front_matter: false
    absolute_image_path: false

    # 自动导出设置
    # export_on_save:
    # html: true
    # markdown: true
    # puppeteer: true # 保存文件时导出 PDF
    # puppeteer: ["pdf", "png"] # 保存文件时导出 PDF 和 PNG
---
上面是 MPE 的导出设置，在渲染中是看不到的，只能看到这句话
***

<span style="font-size: 32px; font-weight: bold;">目录</span>

- 比较两种目录的差异，前者似乎是用 code chuck 实现（可自定义？）

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false ignoreLink=false} -->

<!-- code_chunk_output -->

- [1. markdown的数学公式](#1-markdown的数学公式)
  - [1.1. 基本使用](#11-基本使用)
  - [1.2. 进阶使用](#12-进阶使用)
- [2. Markdown 编辑器(VSCode)的技巧](#2-markdown-编辑器vscode的技巧)
  - [2.1. Markdown 的快捷键](#21-markdown-的快捷键)
  - [2.2. Markdown-index](#22-markdown-index)
  - [paste image](#paste-image)
  - [2.3. Markdown Preview Enhanced(MPE)](#23-markdown-preview-enhancedmpe)
- [3. Markdown Preview Enhanced(MPE) 的使用](#3-markdown-preview-enhancedmpe-的使用)
  - [3.1. 导入](#31-导入)
  - [3.2. 导出](#32-导出)
    - [3.2.1. MPE 与 Pandoc 的使用](#321-mpe-与-pandoc-的使用)
  - [配置文件](#配置文件)
  - [3.3. 一些元素的测试](#33-一些元素的测试)
    - [3.3.2. 图像测试](#332-图像测试)
    - [3.3.3. code chunk](#333-code-chunk)
    - [3.3.4. Admonition](#334-admonition)
    - [3.3.5. 画图](#335-画图)
      - [3.3.5.1. mermaid](#3351-mermaid)
      - [3.3.5.2. graphviz](#3352-graphviz)
      - [3.3.5.3. PlantUML](#3353-plantuml)
      - [3.3.5.4. ditta](#3354-ditta)
    - [3.3.6. 其他](#336-其他)
- [4. Markdown 本身的一些技巧](#4-markdown-本身的一些技巧)
  - [4.1. Markdown 的空格](#41-markdown-的空格)
  - [4.2. markdown 的图片插入](#42-markdown-的图片插入)
  - [4.3. Markdown 反引号的使用](#43-markdown-反引号的使用)
  - [4.4. markdown 页内跳转](#44-markdown-页内跳转)
  - [4.5. markdown 左右分栏](#45-markdown-左右分栏)

<!-- /code_chunk_output -->

[toc]

***

# 1. markdown的数学公式
- 跟 LaTeX 有一定的相通之处（或者说本来就是脱胎于 LaTeX）
## 1.1. 基本使用
1. 上下标
  `^` 表示上标，`_` 表示下标，如果上标或下标内容多于一个字符，则使用 `{}` 括起来。
  例：$(x^2 + x^y )^{x^y}+ x_1^2= y_1 - y_2^{x_1-y_1^2}$
2. 分数
  `\frac{分子}{分母}` 或 `分子\over分母`
  例：$\frac{1-x}{y+1}$ 或 $x \over x+y$
3. 开方
  `\sqrt[n]{a}`   (n=2可省略)
  例：$\sqrt[3]{4}$ 或 $\sqrt{9}$
4. 括号
  - `()[]` 直接写就行，而 `{}` 需要用 `\{` 与 `\}` 转义
  - 大 `()`,需要括号前加 `\left` 和 `\right`（成对出现）；或者用 `\big`、`\Big`、`\bigg`、`\Bigg`（无需成对出现）
  例：$x \in \{1,2,3\}$
  例：$(\sqrt{1 \over 2})^2$与$\left(\sqrt{1 \over 2}\right)^2$与$\Bigg(\sqrt{1\over2}\Bigg)^2$
5. 分段函数
  `\begin{cases}` 开始，`\end{cases}` 结束，中间情况用 `\\` 分隔
  例：$y=\begin{cases} x+y=1\\ x-y = 0 \end{cases}$
6. 向量
  向量用 `\vex{a}`，点乘用 `\cdot`,叉乘用 `\times`
  例：$(\vec{a}\cdot\vec{a})\times\vec{b}$
7. 定积分
  `\int`
  例：$\int_0^1x^2dx$
8. 极限
  `\lim_{n\rightnarrow+\infty}`
  例：$\lim_{n\rightarrow+\infty}\frac{1}{n}$
9. 累加/累乘
  `\sum_1^n`, `\prod_0^n`
  例：$\sum_1^n$, $\prod_{i=0}^n$
10. 省略号
  `\ldots` 底线对齐，`\cdots` 中线对齐
  例：$\ldots$ 与 $\cdots$

## 1.2. 进阶使用
- 公式的对齐
  - 类似 LaTeX，在 `$$  $$` 中使用 `\begin{align*}` 与 `\end{align*}`，中间用 `&` 来指定对齐位置
    - 与 LaTeX 不一样的是，需要用 `$$$$` 包裹，而 LaTeX 直接 `\begin{align*}` 与 `\end{align*}` 就行
- 下大括号的使用
    $$e^x\underbrace{=}_{\text{Taylor expansion}}1+x+\frac{x^2}{2!}+\frac{x^3}{3!}+\cdots$$
- 将文字置于函数底下
  - 有时直接使用下标得到的只是位于右下角（对非内置函数如 $\max$, $\argmax$ 等）
    $$p^*=\argmin_p \underset{p\sim posterior}{E}\{p\}$$
  - 不过可以看到位置出了一点点的问题，暂且不管
***

# 2. Markdown 编辑器(VSCode)的技巧
- 采用 VSCode 作为 Markdown 编辑器
  - 以 Markdown Preview Enhanced 作为核心
  - Markdown All in One 其实可以卸了，因为 MPE 已经包含了大部分功能，还没卸的原因是捆绑的一些快捷键（现在我已经自己做到了）以及判断列表来调整缩进的功能
  - 利用 Markdown-index 方便地为 Markdown 标题生成序号
  - 利用 paste image 插件方便地将剪贴板中的图片粘贴到 Markdown 中
- 不用 Typora 的原因：不开源且收费，不够 fancy，且不符合我一切集成到 VSCode 的习惯

## 2.1. Markdown 的快捷键
- 转为标题：`shift+ctrl+]`
- 加粗：`ctrl+b`
- 倾斜：`ctrl+i`
- 删除线：`ctrl+shift+L`
- 数学公式：`ctrl+$` 或 `shift+$`，通过

## 2.2. Markdown-index
- 只是一个 VSCode 插件罢了，方便地为 VSCode 中的 Markdown 文件的目录生成序号
- 使用方法：在 Markdown 文件中，按下 `Ctrl+Shift+P`，输入 `markdown`，选择 `Markdown add index` 即可
- 还是比较方便的
- 兼容问题
  1. 标题用 MPE 语法隐藏后，计数并没有隐藏
  2. MPE 导出设置处的 `#` 顶格注释会被识别为标题，导致整个文档标题序号出错

## paste image
- 一个 VSCode 插件，方便地将剪贴板中的图片粘贴到 Markdown 中
- 可以自定义图片的存储路径、命名规则
- 按下 `ctrl+alt+v` 即可（多个 `alt` 是为了不和普通的文字粘贴冲突）

## 2.3. Markdown Preview Enhanced(MPE)
- VSCode 编辑 Markdown 的核心插件，单独开一个大标题来讲

***

# 3. Markdown Preview Enhanced(MPE) 的使用
- 可部分参考 [在 VSCode 下用 Markdown Preview Enhanced 愉快地写文档 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/56699805)

## 3.1. 导入
- 参考[MPE官方介绍](https://shd101wyy.github.io/markdown-preview-enhanced/#/zh-cn/file-imports)

- `import`支持导入多种类型的文件，若和本教程一样导入的是markdown文件将会被分析处理然后被引用。支持导入特定行数，如`{line_begin=11}`表示从import指定文件的第11行开始导入，同理`{line_end=-4}`就表示导入到倒数第4行。
    ```markdown
        @import '你的文件' {line_begin=11}
    ```

## 3.2. 导出
- [Markdown Preview Enhanced (MPE) 输出PDF文档分页及页眉页脚 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/493494190?utm_id=0)
- [Markdown Preview Enhanced （MPE）踩坑记录_jiaojiaodubai的博客-CSDN博客](https://blog.csdn.net/qq_43803536/article/details/124774578)
- 导出为 PDF(prince)
  - 需要安装 princexml 这个玩意儿
- 导出为 ebook
  - 要导出电子书，需要事先安装好 `ebook-convert`。
### 3.2.1. MPE 与 Pandoc 的使用
- 下载 pandoc，直接 `choco install pandoc`，存储占用不大所以直接这样装在 C 盘了，会自动添加环境变量
- 然后是在 MPE 的使用。需要在文章开头写一些设置，比如：
    ```markdown
    ---
    output:
      pdf_document:
        path: C:\Users\mofei\Desktop\test.pdf
        toc: true
        pandoc_args: ["--no-tex-ligatures"]
        latex_engine: typst
    ---
    ```
- 也可以是格式化成别的文档形式比如 docx
- `latex_engine` 也可以用 pdflatex
- Pandoc 本身作为一个强大的文档转换工具自然不止能配合 MPE 使用，具体可以参考：
  - [Pandoc 从入门到精通，你也可以学会这一个文本转换利器 - 少数派 (sspai.com)](https://sspai.com/post/77206)
  - [Pandoc：一个超级强大的文档格式转换工具_pandoc是什么软件-CSDN博客](https://blog.csdn.net/horses/article/details/108536784)

## 配置文件
- CSS 样式表
  - `ctrl+shift+p`，选择 `Markdown Preview Enhanced: 自定义样式（全局）`，就会打开一个 css 文件，里面的内容会全局生效
  - 可以进行一些诸如字体等的设置
- 在扩展设置中可以将数学渲染引擎由默认的 KaTeX 改为 MathJax，前者虽然速度快但是少了好些功能，以及在我这的字体有些问题（等号渲染不全）

## 3.3. 一些元素的测试

### 3.3.1. Toc Ignore {ignore = true}
- 这个标题在 toc 中被隐藏了
- 但是，跟 Markdown-index 插件不兼容，导致虽然隐藏但序号加一

### 3.3.2. 图像测试
- 直接引入图像
  - 语法是这样："![Alt text](1.png){width=50%}"
  - 不再测试，痛点是粘贴的图片没有自动放到 assets 里

### 3.3.3. code chunk
```py {cmd=true}
print("Failed to run code")
```
- 估计是路径啊什么的原因，由于代码块需求不高且可被 Jupyter Notebook 替代，所以暂时不管了

```py {.line-numbers, highlight=[3-4]}
print("This is in code chunk")
print("There are line numbers in the left")
print("This line is highlighted")
print("This line is highlighted too")
```

### 3.3.4. Admonition
!!! note This is the admonition title
    This is the admonition body

!!! info More icons
    abstract, tip, success, question, failure, danger, bug, example, quote

### 3.3.5. 画图
- 这些画图语言的语法就不介绍了，不是很懂，需要的时候再查看，可以参考本文件夹下 `Markdown-Totorial` 仓库
#### 3.3.5.1. mermaid
- mermaid 是一个用于画流程图、时序图、甘特图等的工具
  - 无需进行复杂的安装，直接就能使用

#### 3.3.5.2. graphviz
- 一个开源的图片渲染库。安装了这个库才能在 Windows 下实现把 PlantUML 脚本转换为图片。
- 在 MPE 里其本身也可以画图

#### 3.3.5.3. PlantUML
- PlantUML 是一个画图脚本语言，用它可以快速地画出：时序图、流程图、用例图、状态图、组件图
  - 也就是说，跟 mermaid 有一定重叠
- 需要java支持，即要安装jdk
- 安装 graphviz
- 安装 plantuml 插件或这个软件
  - 需要用到一个叫做 `plantuml.jar` 的文件，直接安装这个软件或者只安装插件都可以得到
  - 需要注意的是这个路径得在 MPE 的设置里手动指定

#### 3.3.5.4. ditta
- 一个用字符描述图形的语言，而且是真正的『所见即所得』——你看到的字符怎么摆放，画出来的图形就是什么样的。
- ~~出了点问题，暂未解决~~ 是新版本改了接入的插件，旧ditaa不能用了。详情看他们更新记录。
- 将示例文档的 `{cmd=true run_on_save=true args=["-E"]}` 改成 `{kroki=true}` 就行了

### 3.3.6. 其他
- 可以使用 emoji
:smile:
- 高亮
A simple text with ==marked== word.
- 上下标
不只是数学模式，文本模式也可以使用^上^~下~标


***
# 4. Markdown 本身的一些技巧
## 4.1. Markdown 的空格
- 参考 [Markdown 语言中空格的几种表示方法_markdown 的空格-CSDN博客](https://blog.csdn.net/qq_34719188/article/details/84205243)
- 几种可能需要空格的情况：段首空格、数学公式
  - 段首空格：由于本来是英文环境使用的，没有段首空格的需要，但是中文写手们需要啊
  - 数学公式：数学公式内部的空格是无效的，会被忽略
- 下面按照那个博客介绍的方法来试试
  1. 全角空格，切换到全角模式下（一般的中文输入法都是按 shift + space）输入两个空格就行了。这个相对来说稍微干净一点，而且宽度是整整两个汉字，很整齐
    - 但是搜狗输入法的全角空格用起来很不爽，我给禁用了
    - 但是实测，第一段由于前面没有换行（？）这样没有效果，得结合其他方法
    - ~~非第一段倒是没关系，但是会有判定的问题~~ 啊不对，那是标点的问题
  2. `&nbsp;` 表示半角空格（英文）；`&emsp;` 表示全角空格（中文），这两个都是在非数学公式环境下使用的
  3. `$~~~~$` 数学公式内部的空格，非常好用
  4. 缩进的地方先用 有序 或 无序列表，再下一行使用 tab
  5. 使用样式表
    ```
    p{
      text-indent: 2em; /*首行缩进*/
    }
    ```
  - 样式表指的是 CSS（Cascading Style Sheets，层叠样式表），不是很熟

## 4.2. markdown 的图片插入
- 带居中 caption 的图片，采用 css 样式
```html
<div align="center" style="color:grey"><img width=261em height=49em src="图片文件/QQ截图20230602095658.png"/>
<br>文字</div>

<div align="center" style="color:grey"><img src="图片文件/2.png" style="max-width: 50%"></div><br/> //由于形状不变变成按比例缩放了
```
- 文章 [关于 Markdown 的一些奇技淫巧 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/28987530)

## 4.3. Markdown 反引号的使用
- 遇到了一个问题，如何对反引号使用反引号？如果反引号的内部需要反引号，该如何表示？
- 在 Obsidian 这样非纯正 markdown 环境不太清楚怎么搞，但是在 VSCode 中，需要这样：`` ` ``
    ```
    `` ` ``
    # 会显示一个反引号
    # 注意空格，注意外围双反引号，如果还要嵌套，可以三反引号……
    ```

## 4.4. markdown 页内跳转
- 有两种方式，一是直接用目录，二是自定义锚，如下
  1. 定义一个锚(id)： `<span id="jump">跳转到的地方</span>`
  2. 使用 markdown 语法：`[点击跳转](#jump)`

## 4.5. markdown 左右分栏
- 采用 html 实现（烂）
<html><table style="margin-left: auto; margin-right: auto;"><tr><td>
左侧内容
</td><td>
右侧内容
</td></tr></table></html>