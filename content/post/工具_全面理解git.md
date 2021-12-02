---
title: Git用法和原理
date: 2020-05-29 14:24:00
description: "Git是工作中常用的版本管理工具，理解其原理能帮助我们更正确的使用。"
tags: ["git"]
categories: ["工具"]
keywords: ["git"]
---

## 版本控制

**版本控制**就是记录项目文件的历史变化。它为我们**查阅日志**，**回退**，**协作**等方面提供了有力的帮助。

版本控制一般分为集中化版本控制和分布式版本控制。

![集中化的版本控制系统](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/git_001.png)

![git_002](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/git_002.png)

集中化主要的版本数据都保存服务端。

分布式版本数据分散在多端。

## Git

Git 属于分布式版本控制，也是现在比较流行的一种版本管理工具。

Git 项目有三个区块：工作区 / 暂存区 / 版本库

- 工作区存放从版本库提取出来的文件，供我们编辑修改；
- 暂存区保存了下一次要提交的目录信息；
- 版本库保存项目版本元数据和 Objects 数据，后文会详解。

![Git工作流程](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/git_space.png)

Git 工作流程

```bash
# 下载
<<==== clone
# 上传
====>> add ====>> commit ====>> push
# 更新
<<==== merge|rebase <<===== fetch

```

#### 区分 Pull vs Fetch

我们将一个更新操作拆分为**数据更新+合并处理**两部分，这样来看 fetch 只是进行数据更新。而 pull 其实是 ( fetch + (merge|rebase) )组合操作，它执行**数据更新**同时执行**合并处理**。pull 默认是 fetch+merge 组合 ，也可以通过参数 --rebase 指定为 fetch + rebase。

#### 区分 Merge vs Rebase

**合并处理**是 Git 很重要的一块知识。两个命令在工作中也经常使用，区分它们对我们很有用。

场景如下

项目有一个 mywork 分支。C2 时间点我和小明各自下载项目进行功能开发，小明效率比较高，先推送了 C3 C4 到远程仓库。我本地仓库现在有 C5 C6 两个提交，要推送到远程仓库，需先同步远程仓库版本。

![rebase1](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/rebase1.png)

如果通过 fetch + merge 方式，Git 会将远程最新(C4)和本地最新(C6)进行合并并产生一个新的(C7)。

冲突处理步骤

```bash
git merge # 发生冲突会出现冲突标记
“<<<<<<< HEAD
40
=======
41
>>>>>>> 41”
# 手动处理冲突
git add .
git commit -m 'fix conflict'
git push origin HEAD
```

![git merge](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/rebase2.png)

如果通过 fetch + rebase 方式，git 会先将 C5 C6 存储到.git/rebase 零时目录，合并成功后删除。

冲突处理步骤

```bash
git rebase # 发生冲突会出现冲突标记
“<<<<<<< HEAD
40
=======
41
>>>>>>> 41”
# 手动处理冲突
git add .
git rebase --continue
git push origin HEAD
```

![git rebase](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/rebase3.png)

![rebase5](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/rebase5-8423914.png)

#### 小结

git merge 会产生大量 Merge 日志，可能会对查看带来不便。不过大家还是根据实际情况进行选取。

#### 关于撤销回退几种场景

提交后发现有文件漏了，又不想提交两次。此时通过 “git commit --amend” 可以合并为一个提交。

```bash
git commit -m 'initial commit'
git add .gitignore
git commit --amend
```

如果文件想撤回且尚未提交，执行下面命令撤出暂存空间（index）

```bash
git reset HEAD <file>...
```

关于 reset 其它用法

```bash
# 重置到指定版本，之前提交内容将丢失
git reset --hard HEAD
# 重置到指定版本，保留更改的文件但未标记为提交
git reset --mixed HEAD
# 重置到指定版本，保留所有改动文件
git reset –soft HEAD
```

**特别注意** 当你使用 “git reset --hard HEAD” 重置到某一版本，发现搞错了想回退。这时你可能会执行“git log”，但是发现已经没有以前的版本记录，怎么办？送你一瓶后悔药如下

```bash
# reflog 是Git操作的全日志记录
git reflog

6241462 (HEAD -> master) HEAD@{0}: reset: moving to 6241462
ea9b5ab HEAD@{1}: reset: moving to ea9b5ab
6241462 (HEAD -> master) HEAD@{2}: commit: Hello
34cd1e3 HEAD@{3}: commit: 3
ea9b5ab HEAD@{4}: commit: 2
729a8b1 (origin/master) HEAD@{5}: commit (initial): 1

# 找到最左边对应hash值就可以回退到任意位置
git reset --hard {index}
```

如果想撤回文件修改内容且文件尚未提交，执行下面命令

```bash
git checkout -- <file>
```

如果创建的分支名称需要更改

```bash
git branch -m old new

# 如果分支已经推送到远程，先删除再推送新分支
git push origin --delete old
git push origin new
```

如果**需要撤回的提交**已经推送到了远程仓库，那么补救的方式只有创建新的提交。

可以利用 revert 快速撤回到需要回退的版本。

```bash
# 还原最近一个提交
git revert HEAD
# 还原倒数第二个
git revert HEAD^
# 还原倒数第第四个
git revert HEAD~3
```

## 版本库 Objects

这一节介绍一下 Git 版本库的存储模型。

项目历史变动信息都记录在 object 文件。文件名称是通过**哈希算法** ( 这里是 SHA1(对象内容) ) 产生的 40 位字符。

这种做法的一个优点就是“在对比两对象是否相同时，只需要比较文件名称就能迅速得出结果”

> 哈希算法：简单来说就是向函数输入一些内容，输出长度固定的字符串。这里 SHA1 函数固定输出 40 长度字符。

object 文件分 **blob** **tree** **commit** **tag** 四种类型

- **blob** 存储文件数据，一般是一个文件；

- **tree** 存储目录和树的引用（子文件目录）；

- **commit** 存储单一树引用，时间点，提交作者，上一次提交指针；

- **tag** 标记特定的**commit** 比如说发版。

> 特别注意：Subversion，CVS，Perforce，Mercurial 等是存储前后两次提交的差异数据。Gi-每次提交时，它都会以树状结构存储项目中所有文件的外观快照。

#### Blob

![blob](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/blob.png)

Blob 是二进制数据块，不会引用其它东西。如果目录树（或存储库中多个不同版本）中的两个文件具有内容相同，它们将共享相同的 Blob 对象。

#### Tree

![tree](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/tree.png)

Tree 存储 blob 和 tree 的引用。

```bash
# 我查询 add1a1306e20...
git ls-tree add1a1306e20...

100644 blob 4661b39c3460a5c1f9e9309e6341962e0499b037	README.md
040000 tree ad46b24a4b0648ede3ca090dde32c89b89f7f2c1	src
...
```

#### Commit

![commit](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/commit.png)

Commit 包含下面几个信息

1. **tree** 提交时间点的目录；
2. **parent** 上一个提交；
3. **author** 提交人；

```bash
git show -s --pretty=raw add1a1306e....

commit add1a1306e....
tree 81d4e4271a56575da7f992dc0dfc72ff7ddff94c
parent cd397e4c373013b19825b857b43ad8f677607f5d
author lixingping <lixingping233@gmail.com> 1589783810 +0800
committer lixingping <lixingping233@gmail.com> 1589783810 +0800
```

#### Tag

![tag](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/tag.png)

```bash
git cat-file tag v_1.0

object 24d16acd6aa08f74556c7ce551fa571b4bfe4079
type commit
tag v_1.0
tagger lixingping <lixingping233@gmail.com> 1588591122 +0800
```

#### 例子

假设项目目录结构如下，我们进行一个初始提交。几种文件关系如下图

```bash
|-- read.txt
    --| lib
      --| hello.java
```

![commit_process](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/commit_process.png)

## 附上一些常用命令

生成 SSH key

```shell
ssh-keygen -t rsa -b 4096 -C "email@example.com"
# 指定生成的文件
ssh-keygen -t rsa -b 4096 -C "email@example.com" -f ~/.ssh/id_rsa_example
# id_rsa_example.pub 粘贴远程仓库

# 配置多个远程仓库
touch ~/.ssh/config

#添加一下内容
Host github.com
HostName github.com
User git
IdentityFile ~/.ssh/id_rsa_github

Host example.com
HostName example.com
User git
IdentityFile ~/.ssh/id_rsa_example

```

配置

```bash
git config –global user.name “xxx”
git config –global user.email “xxx@email.com“
git config --global core.autocrlf true # 建议配置 windows mac换行符不统一问题
git config --global core.editor vim # 配置默认编辑器
git config --global core.excludesfile ~/.gitignore_global # 配置全局忽略文件
git config –list # 查看配置信息
```

分支管理

```bash
git branch --list # 罗列本地所有分支
git branch --all  # 罗列本地和远程所有分支
git branch -r     # 罗列远程所有分支
git branch -v     # 显示各分支最后提交信息
git checkout <branch name> # 切换分支
git checkout -b <new branch name> # 创建新分支
git push origin <new branch name> # 推送新分支到远程
git checkout -m <old branch> <new branch> # 重命名分支名称
git branch -d <[list]branch name> # 删除本地分支
git push origin --delete <branch name> # 删除远程分支
```

标签管理

```bash
git tag -l # 罗列本地所有标签
git show <tag name> # 显示指定标签
git tag -a v_1.0.0 -m "备注" # 创建标签
git push origin <tag name> # 推送标签到远程
git tag -d <tag name> # 删除本地标签
git push --delete origin <tag name> # 删除远程标签
```

## 总结

工作多年以来一直在使用 Git，但是对 Git 没有一个系统了解，所以写这篇文章归整一下。

欢迎大家留言交流，一起学习分享！！！
