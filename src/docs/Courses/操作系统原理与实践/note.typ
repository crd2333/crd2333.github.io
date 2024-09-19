#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "操作系统原理与实践",
  lang: "zh",
)

= Class 1
- 基本是复习

= Class 2
- UNIX family tree
  - NUIX, BSD, Solaris, Linux...
  - Ubuntu = Linux Core + GNU
- Kernel 的工作是抽象封装和资源管理
- 对 OS 的一个最常见误区是“一个 running program”，事实上 OS 在启动后一般是闲置的，并且要求内存占用小
  - It's code that resides in memory and is ready to be executed at any moment
  - It can be executed on behalf of a job(or process in modern terms, a process is a running job)
- 为了实现 APP $->$ OS $->$ HardWare 的层级，需要把访问硬件的指令分类(privileged / unprivileged)，即至少支持两个 Mode
  - arm64 有 4 个 Mode，RISC-V 有 3 个 Mode（有一个没抄完因此叫 reserved）
  // #grid2()
- OS Event
  - 分为 interrupt 和 exception(traps)
- When a user program needs to do something privileged, it calls a *system call*. A system call is a special kind of *trap*