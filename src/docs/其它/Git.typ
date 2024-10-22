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
    - 我想要把现在暂存区里的内容提交到上上次 commit 里，可以先 `git commit -m "to be merged"`，然后 `git rebase -i HEAD~2`，把新的 commit 往下拖一格，把 `pick` 改成 `squash`（合并到 `HEAD~2` 去），然后保存退出，再次弹出的界面里可以编辑 commit message，保存退出即可
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