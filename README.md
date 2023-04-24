### 说明

用于自动生成Chroumium lite代码库的shell脚本

### 操作步骤

前提条件：必须在linux或者macos系统下操作。

1. 克隆Chromium源码到本地；
2. 获取chromium远程的tag列表，过滤出每个稳定版本的最后一个版本，可使用工具[git-clone-tags](https://github.com/chinayangxiaowei/git-clone-tags)获取；
3. 将选出的tag存储到“chromium_tags.txt”文件，每行1个；
4. 修改初始化仓库脚本”init_git.sh“；
5. 修改"fetch_chromium_tag.sh"中前几行的repo(新精简仓库路径）与remote（本地Chromium源码路径）
6. 执行 `./fetch_chromium.sh chromium_tags.txt`
7. 定期同步Chromium源码，修改“chromium_tags.txt”文件，重复执行第6步。

### 仓库结构

主分支按照chromium_tags.txt列表中tag所有文件做每一次的差异提交；

如果之后出现了主分支某个tag的补丁更新，则创建v开头的新分支，在此分支进行补丁提交；

由于是1周或者更久提交一次，所以每次提交的是合并补丁；

每提交一次都会在提交位置设置tag 。


