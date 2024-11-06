#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: none,
  lang: "zh",
)

#warning()[
  - 当你在实现一个大功能时，请将它分成小块并定期提交
    - 长时间工作而不做提交并不是一个好主意
  - 慎用复杂 or 不熟的 git 命令
    - 实在不行你先 `mkdir ~/backrepo && cp -r ./* ~/backrepo/` 一下（不会匹配 `.git` 目录哒）
]

- 基础的东西不谈，记录一些（可能）比较危险的操作，多人情况下慎用
- *修改最近一次提交*（常用）
  - `git commit --amend -m "new message"`
  - 本质上是用新的提交，替换掉最近的提交
  - 如果已经推送到远程怎么办？本地处理好然后 `git push -f` \u{1F608}
- *修改更久之前的提交*（更灵活）
  - `git rebase -i HEAD~n`，从 `HEAD` 开始往前数 `n` 个提交
  - 或者 copy 要修改的提交的 hash，然后 `git rebase -i <hash>`
  - 会弹出一个编辑器选择对每个提交的操作
    + `pick` (p): 保留该 commit，默认操作。
    + `reword` (r): 保留该 commit，但允许修改其提交信息。
    + `edit` (e): 保留该 commit，暂停以便进行修改（不仅限于提交信息）。
    + `squash` (s): 将该 commit 合并到前一个 commit，同时保留合并后的提交信息。
    + `fixup` (f): 将该 commit 合并到前一个 commit，但不保留该 commit 的提交信息。
    + `exec` (x): 执行 Shell 命令。
    + `drop` (d): 删除该 commit，不保留其记录。
  - 通过 `rebase` 还可以达成许许多多奇怪的效果，但是慎用
  - e.g.
    - 我想要调转 $A -> B -> C -> D("HEAD")$ 中 $B$ 和 $C$ 的顺序，可以 `git rebase -i HEAD~3`，然后把在弹出的交互界面 (vim or nano, or GitLens Interactive Rebase for me) $B$ 和 $C$ 的顺序调换
    - 我想要把现在暂存区里的内容提交到上上次 commit 里，可以先 `git commit -m "to be merged"`，然后 `git rebase -i HEAD~3`，把新的 commit 往下拖一格，把 `pick` 改成 `squash`（合并到 `HEAD~3` 去），然后保存退出，再次弹出的界面里可以编辑 commit message，保存退出即可
- *删除某个提交*
  - `git reset HEAD^`，删除最近的一个提交
  - 有 $3$ 个选项
    + `--soft`：上次 commit 的提交被撤回到暂存区，当前暂存区的内容依旧在暂存区，工作区内容依旧在工作区
    + `--mixed`（默认）：上次 commit 的提交被撤回到工作区，当前暂存区的内容也被退回到工作区，工作区内容依旧在工作区
    + `--hard`：上次 commit 的提交被完全删除，当前暂存区的内容也没了，工作区内容依旧在工作区
- *恢复丢弃了的修改*
  - 比如说你一个手贱 `git stash drop` 了，文件可能并没有被彻底删除，还是有补救机会的
  - `git fsck` + `--dangling` or `--unreachable` or `--lost-found`
  - 比如说 `git fsck --unreachable` 会列出无法通过任何引用（如分支、标签、HEAD 指针等）访问的对象，当然这只是 hash 看不到内容。可以用 `git fsck --unreachable | awk '{print $3}' | xargs git show >> find.txt`，然后在 txt 里找一找你想要的东西
  - 最后 `git merge <hash>`(`git stash apply <hash>`) 把它应用回来

#hline()

- 在多人协作的时候，直接 `git pull` 可能并不是一个好选择
  - 因为 `pull` = `fetch` + `merge`，如果你 merge 没配置好的话，可能就导致过多无用的 merge 信息
  - 一般来说 merge 的 `fast-forward only` 和 `rebase true` 是更好的选择
  - 如果不确信的话，就先 `git fetch` 然后手动操作吧

#hline()

- Git LFS
  - 参考 #link("https://blog.sinlov.cn/posts/2019/10/20/git-lfs-tutorials/#%E6%9F%A5%E7%9C%8B%E7%8A%B6%E6%80%81")[git lfs 使用详解]
  - git 本身是支持二进制大文件的，但和二进制文件相性不好（二进制文件不好进一步压缩）。二进制文件的内容版本多了以后会影响 git 的工作效率（存储和传输，主要是传输），进而影响用户体验。举个栗子，笔记仓库里内含大量图片
  - git-lfs(Large File Storage) 是一个 Git 扩展，它通过 lazily 下载大文件的相关版本来减少大文件在仓库中的影响。具体来说，大文件是在 checkout 的过程中下载的，而不是 clone 或 fetch 过程中下载的，通过将仓库中的大文件替换为 lfs-pointer 文件来做到这一点
  - 首先需要下载 `git-lfs`，各个平台有所不同，不再赘述。下载完后，使用 `git lfs install` 全局启用
  - 但是 我启用 $!=$ 我工作，需要进一步配置 `.gitattributes` 文件，指定哪些文件需要使用 `git-lfs` 管理
    ```bash
    # 文件形式
    $ git lfs track *.png
    # 文件夹形式
    $ git lfs track model/**
    ```
  - 随后 `git add`，可以通过 `git lfs status` 查看当前的状态，如果没问题的话，那些启用了 `git-lfs` 的文件后面会有 `(LFS: xxx)` 的标记，而不是 `git(xxx)`
  - 之后的使用，跟平时没什么区别了
