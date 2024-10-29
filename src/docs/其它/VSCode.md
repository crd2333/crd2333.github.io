# VSCode 的使用技巧
## 常用快捷键
- 光标操作(重点记忆)
  - 光标换行：`ctrl+enter`
  - 光标跳跃单词：`ctrl+左右`
  - 复制光标：`ctrl+alt+上下`
  - 移动行：`alt+上下`
  - 移动视图：`ctrl+上下`
  - 选择整行：`ctrl+L`
  - 删除当前行：`ctrl+x`
  - 选中：`shift+上下左右`
  - 选中所有出现的当前单词：`ctrl+shift+L`
  - 缩进与取消缩进：
  - 缩进：`tab`或`ctrl+[`
  - 取消缩进：`shift+tab`或`ctrl+]`
- 工具栏
  - 左侧工具栏：`ctrl+b`
  - 从左侧工具栏中选择文件打开：`ctrl+0`
  - 从上方选项卡中切换文件：`ctrl+tab`
  - 最近打开的文件：`ctrl+p`
  - 打开设置：`ctrl+，`
  - 终端：`ctrl+～`
  - git：`ctrl+shift+g`
  - bash:`ctrl+shift+点`
- 常用操作
  - 代码格式化`shift+ctrl+i`
  - 撤销与恢复：`ctrl+z`和`ctrl+y`
  - 注释：`ctrl+/`单行或多行
  - 字体大小：`ctrl+加减`

## 资源管理器与源代码管理的忽略
- 在 `settings.json` 中添加如下内容
    ```json
        // VSCode 资源管理器中不显示的文件
        "files.exclude": {
            "**/__pycache__": true,
            "**/.gitkeep": true,
            "**/.obsidian": true,
            "**/*.code-workspace": true,
            "**/*.lnk": true,
            "**/*.url": true
        },
        // VSCode 源代码管理中不显示的文件夹
        "git.ignoredRepositories": [
            "D:\\Obsidian\\Study"
        ],
    ```
- git 管理的话，还有一种比较相反的做法，只追踪打开文件所在的仓库
    ```json
    "git.autoRepositoryDetection": "openEditors"
    ```

## VSCode Snippets
- 芝士什么：可自定义的代码片段，常用于快速输入一些代码、模板等
- 可以参考：
  - [一个案例学会 VSCode Snippets，极大提高开发效率 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/457062272)
  - [VSCode Snippets：提升开发幸福感的小技巧 - 掘金 (juejin.cn)](https://juejin.cn/post/7076609496046370847)
  - 对 LaTeX 而言
    - [latex---vscode编辑器配置及快捷键（snnipets）设置 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/350249305)


## VSCode 键绑定
- 通过左下角的 `设置-键盘快捷方式` 打开，方便而强大地自定义快捷键
- 进阶：通过编辑 `keybindings.json` 文件来自定义更复杂的功能，如带参数等
  - 例子：LaTeX 文本加粗，实现按下 `ctrl+b` 后，选中的文本被 `\textbf{}` 包裹
    ```json
        {
            "key": "ctrl+b", // LaTeX 文本加粗
            "command": "editor.action.insertSnippet",
            "args": {
            "snippet": "\\textbf{${TM_SELECTED_TEXT}}"
            },
            "when": "editorTextFocus && !editorReadonly && editorLangId =~ /^latex$/"
        },
    ```

## VSCode 如何调试
- [VScode tasks.json和launch.json的设置 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/92175757)
- ~~还是不会~~ 以现在(23.11.28)的视角看，似乎这些调试相关文章有不少都过时了，我现在只需要对 `C`, `Cpp` 分别搞一个 `tasks.json`，然后保证处在两个工作区就好了

!!! warning
    - 编译的时候看的是**当前工作区一级文件夹**下的 `.vscode` 文件夹中的内容，而不是当前编译文件所在的文件夹下的 `.vscode`
    - 我因为工作区的组织架构用到了工作区内二级目录，所以这个问题困扰了我很久，仍未解决。
      - 目前的办法是另外新建了一个工作区，在这个工作区内把各个语言的编译配置文件都放在一级目录下

### VSCode python 文件的调试
- 对于单文件不带参数的 python 文件，添加断点然后直接调试就好了
- 对于带参数的或者从模块启动的，有两种方法：
  1. 一种方法是改变 `launch.json`，把参数或者模块的信息加入其中
  2. 使用代理文件。创建 `debugProxy.py` 托管你需要调试的命令
- 基本上还是用第一种方法的多一点，正常一点
- 当然，也有通过 pdb（可能类似 gdb？）不通过 VSCode 直接进行调试，我估计如果我那边不顺利的话也要这么搞了