
-----------------------------------------------------------------------------------------------------------

假设你是一位精通 github action 的高级开发人员, 现在有如下 github action 配置:
```yaml
name: Release
on:
  push:
    tags:
      - "v*"
      - "test-v*"
  pull_request:
permissions: write-all
env:
  UBUNTU_CODENAME: noble
  UBUNTU_VERSION: "24.04"
  DOCKER_VERSION: "29.5.2"
  NERDCTL_VERSION: "2.3.1"
  FLANNEL_VERSION: "1.9.1-flannel1"
  FLANNEL_MINI_VERSION: "1.9.1"
  BINFMT_VERSION: "deploy/v7.0.0-28"
  BINFMT_QEMU_VERSION: "7.0.0"
jobs:
  release-x86_64:
    runs-on: ubuntu-latest
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1
          persist-credentials: false
      - name: Build for x86_64 (none)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=none
          ls -lah dist/img
      - name: Build for x86_64 (docker)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=docker
          ls -lah dist/img
      - name: Build for x86_64 (containerd)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=containerd
          ls -lah dist/img
      - name: Build for x86_64 (incus)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=incus
          ls -lah dist/img
      - name: Upload x86_64 artifacts
        uses: actions/upload-artifact@v4
        with:
          name: x86_64-imgs
          path: dist/img/*amd64*
  release-aarch64:
    runs-on: ubuntu-24.04-arm
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1
          persist-credentials: false
      - name: Build for aarch64 (none)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=none
          ls -lah dist/img
      - name: Build for aarch64 (docker)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=docker
          ls -lah dist/img
      - name: Build for aarch64 (containerd)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=containerd
          ls -lah dist/img
      - name: Build for aarch64 (incus)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=incus
          ls -lah dist/img
      - name: Upload aarch64 artifacts
        uses: actions/upload-artifact@v4
        with:
          name: aarch64-imgs
          path: dist/img/*arm64*
  create-release:
    runs-on: ubuntu-latest
    needs: [release-x86_64, release-aarch64]
    if: github.event_name != 'pull_request'
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1
          persist-credentials: false
      - uses: actions/download-artifact@v4
        with:
          name: x86_64-imgs
          path: dist/img
      - uses: actions/download-artifact@v4
        with:
          name: aarch64-imgs
          path: dist/img
      - name: Create release
        run: >
          tag="${GITHUB_REF##*/}"

          gh release create "${tag}" --draft --title "${tag}" dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-none.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-none.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-none.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-none.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-docker.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-docker.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-docker.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-docker.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-containerd.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-containerd.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-containerd.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-containerd.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-incus.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-incus.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-incus.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-incus.raw.gz.sha512sum

```
请为这个配置文件添加详细的注释, 说明 github action 语法, 说明配置的含义和作用, 说明为什么要这么配置, 说明运行之后的最终效果

作为一名精通 CI/CD 与 GitHub Actions 架构的高级开发人员, 我将为你从语法解析、设计理念与考量(Why)、运行流程与最终效果三个维度, 对这份配置文件进行深度剖析, 并在配置文件内添加详尽的专业级注释.

---

### 一、带完整注释的 GitHub Actions 配置

```yaml
# ==============================================================================
# 工作流名称: 显示在 GitHub 仓库的 Actions 页面顶部
# ==============================================================================
name: Release
# ==============================================================================
# 触发器配置 (Triggers)
# 作用: 定义什么时候启动这个自动化工作流
# ==============================================================================
on:
  # 场景1: 当推送特定格式的 Git Tag 时触发(通常用于正式发版)
  push:
    tags:
      - "v*" # 匹配以 'v' 开头的标签, 如 v1.0.0, v24.04.1
      - "test-v*" # 匹配以 'test-v' 开头的标签, 用于发布前在测试环境做打包验证
  # 场景2: 当有人提交或更新 Pull Request 时触发
  # 作用: 充当 CI 验证(门禁), 确保 PR 中的代码不会破坏两类架构的镜像构建流程
  pull_request:
# ==============================================================================
# 权限配置 (Permissions)
# 语法: 声明当前 GITHUB_TOKEN 的授权范围.
# 说明: 'write-all' 赋予所有资源读写权限. 在生产实践中推荐使用最小权限原则(如 contents: write),
# 这里配置 write-all 主要是为了确保后续有权限上传 Artifact、调用 GitHub CLI 创建 Release.
# ==============================================================================
permissions: write-all
# ==============================================================================
# 全局环境变量 (Workflow-level Environment Variables)
# 作用: 集中定义跨 Job 共享的构建元数据与依赖组件版本号.
# 为什么要这么配: 单一数据源(Single Source of Truth), 避免在下方数十行命令中硬编码版本号;
#                升级版本时只需在此修改一处, 防止不同架构构建出来的组件版本不一致.
# ==============================================================================
env:
  UBUNTU_CODENAME: noble # Ubuntu 24.04 代号
  UBUNTU_VERSION: "24.04" # 目标基础镜像系统版本
  DOCKER_VERSION: "29.5.2" # 内置 Docker 引擎版本
  NERDCTL_VERSION: "2.3.1" # containerd CLI 工具版本
  FLANNEL_VERSION: "1.9.1-flannel1" # CNI 网络插件版本
  FLANNEL_MINI_VERSION: "1.9.1"
  BINFMT_VERSION: "deploy/v7.0.0-28" # 跨平台架构仿真相关配置版本
  BINFMT_QEMU_VERSION: "7.0.0"
# ==============================================================================
# 任务定义 (Jobs)
# GitHub Actions 默认按并发方式执行多个 Job, 除非显式指定依赖关系.
# ==============================================================================
jobs:
  # ----------------------------------------------------------------------------
  # Job 1: 构建 x86_64 (amd64) 架构的各类镜像
  # ----------------------------------------------------------------------------
  release-x86_64:
    # 运行在 GitHub 托管的标准 Ubuntu 虚拟机上(底层为 x86_64 硬件架构)
    runs-on: ubuntu-latest
    # 设置 3 小时超时时间. 构建完整 OS 镜像(解压、安装内核、打包、压缩)非常耗时,
    # 超过默认 360 分钟或者防止任务挂死占用过多计费时长, 180 分钟是一个合理的防护边界.
    timeout-minutes: 180
    steps:
      # Step 1: 拉取仓库代码
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1 # 浅克隆(Shallow Clone), 只拉取最后一次 Commit, 极致节省拉取时间
          persist-credentials: false # 安全最佳实践: 不保留 Git Token, 防止后续脚本误读或泄露凭证
      # Step 2-5: 针对 x86_64 架构, 分别构建 4 种不同容器运行时(Runtime)的基础系统镜像
      # 为什么要分开成多个 Step?
      # 1. 关注点分离: 失败时能精准一眼看出是哪个 Runtime 崩溃了;
      # 2. 日志隔离: 折叠后独立查看各构建阶段的编译日志与输出;
      # 3. Step 结尾的 ls 能够即时校验产物是否成功生成到 dist/img.
      - name: Build for x86_64 (none)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=none
          ls -lah dist/img
      - name: Build for x86_64 (docker)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=docker
          ls -lah dist/img
      - name: Build for x86_64 (containerd)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=containerd
          ls -lah dist/img
      - name: Build for x86_64 (incus)
        run: |
          make image OS_ARCH=x86_64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=incus
          ls -lah dist/img
      # Step 6: 暂存当前 Job 构建出的 x86_64 产物
      # 为什么要这么做: GitHub Actions 每个 Job 运行在独立的干净虚拟机中, 磁盘不互通.
      # 必须上传至暂存区(Artifacts), 后续的汇总发布 Job 才能下载使用.
      - name: Upload x86_64 artifacts
        uses: actions/upload-artifact@v4
        with:
          name: x86_64-imgs # 产物包名称, 供 downstream job 索引
          path: dist/img/*amd64* # 通配符过滤: 仅上传 amd64 相关的文件(镜像本体 raw.gz 及 checksum 校验和)
  # ----------------------------------------------------------------------------
  # Job 2: 构建 aarch64 (arm64) 架构的各类镜像
  # ----------------------------------------------------------------------------
  release-aarch64:
    # 核心设计: 直接在 GitHub 官方提供的原生 ARM64 机器上构建!
    # 为什么要这么配: ARM 镜像如果在 x86 runner 上靠 QEMU 用户态仿真构建, 由于指令集翻译,
    # 耗时可能延长 5~10 倍且极易遇到底层内存段错误; 采用原生 ARM Runner 执行效率最高、稳定性最好.
    runs-on: ubuntu-24.04-arm
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1
          persist-credentials: false
      # 针对 aarch64 同样构建 4 种运行时系统镜像
      - name: Build for aarch64 (none)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=none
          ls -lah dist/img
      - name: Build for aarch64 (docker)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=docker
          ls -lah dist/img
      - name: Build for aarch64 (containerd)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=containerd
          ls -lah dist/img
      - name: Build for aarch64 (incus)
        run: |
          make image OS_ARCH=aarch64 UBUNTU_CODENAME=${UBUNTU_CODENAME} UBUNTU_VERSION=${UBUNTU_VERSION} DOCKER_VERSION=${DOCKER_VERSION} BINFMT_VERSION=${BINFMT_VERSION} BINFMT_QEMU_VERSION=${BINFMT_QEMU_VERSION} RUNTIME=incus
          ls -lah dist/img
      # 暂存 arm64 架构的所有产物
      - name: Upload aarch64 artifacts
        uses: actions/upload-artifact@v4
        with:
          name: aarch64-imgs
          path: dist/img/*arm64*
  # ----------------------------------------------------------------------------
  # Job 3: 汇总跨架构产物并正式发布 GitHub Release
  # ----------------------------------------------------------------------------
  create-release:
    runs-on: ubuntu-latest
    # 依赖声明: 扇入(Fan-in)模式. 必须等待 release-x86_64 和 release-aarch64 两个 Job
    # 均执行成功后, 本 Job 才会启动; 若任何一个架构构建失败, 本步骤直接跳过, 防止发出残缺版本.
    needs: [release-x86_64, release-aarch64]
    # 条件判断: 仅当触发事件[不是]pull_request 时才执行.
    # 为什么要这么配: PR 只需要跑上面两个 Job 验证能否编译成功即可(CI), 绝不能在提交 PR 时就去发 Release!
    # 只有当用户推送指定 Tag 时, 本 Job 才会执行发布.
    if: github.event_name != 'pull_request'
    # 将系统内置的 GITHUB_TOKEN 注入环境变量, 供 gh (GitHub CLI) 免密鉴权
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1
          persist-credentials: false
      # 下载上游 x86_64 Job 生成的产物并还原到 dist/img 目录
      - uses: actions/download-artifact@v4
        with:
          name: x86_64-imgs
          path: dist/img
      # 下载上游 aarch64 Job 生成的产物并合并还原到同一个 dist/img 目录
      - uses: actions/download-artifact@v4
        with:
          name: aarch64-imgs
          path: dist/img
      # 调用 GitHub CLI 一键创建草稿 Release 并附带所有资产
      # 语法: '>' 表示 YAML 折叠多行字符串, 内部换行符视为空格
      - name: Create release
        run: >
          # 使用 Bash 参数扩展, 剥离 refs/tags/ 前缀, 提取出纯粹的 Tag 名字(如 v1.0.0) tag="${GITHUB_REF##*/}"

          # 调用 gh cli 工具: # --draft: 先以草稿形式发布(安全防御措施, 防止发版过程中用户下载未校验产物, 需人工核对后点正式发布) # --title: Release 显示标题为对应 Tag # 后面追加了 16 个文件的完整路径(4 种 Runtime * 2 种 Arch * [镜像本体 + sha512 校验文件]) gh release create "${tag}" --draft --title "${tag}" dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-none.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-none.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-none.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-none.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-docker.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-docker.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-docker.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-docker.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-containerd.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-containerd.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-containerd.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-containerd.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-incus.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-amd64-incus.raw.gz.sha512sum dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-incus.raw.gz dist/img/ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-arm64-incus.raw.gz.sha512sum
```

---

### 二、核心架构设计理念与技术要点(Why it's designed this way)

1. 双触发机制与"CI/CD 合一"的设计模式:
   * 在 PR 时: 执行 `release-x86_64` 和 `release-aarch64` 做编译验证, `create-release` 通过 `if: github.event_name != 'pull_request'` 自动拦截跳过. 这避免了为 PR 和 Tag 编写两套雷同的流水线, 极大地降低了维护成本.
   * 在 Tag 时: 三个 Job 协同执行, 完成全流程构建与最终发布.

2. 原生跨架构并行编译策略(Native Multi-Arch Runners):
   * `release-x86_64` 使用 `ubuntu-latest`(AMD64 物理机).
   * `release-aarch64` 使用 `ubuntu-24.04-arm`(ARM64 物理机).
   * 优势: 两个任务完全并行执行, 总耗时等于两个架构中耗时较长的那个, 而不是两者相加; 且避免了使用 QEMU 模拟构建系统镜像时的性能骤降和段错误风险.

3. 依赖汇聚模型(Fan-Out / Fan-In 架构):
   * 采用 `upload-artifact@v4` 和 `download-artifact@v4` 解决 GitHub Actions 异构 Runner 之间文件系统隔离的问题.
   * 通过 `needs: [release-x86_64, release-aarch64]` 实现"汇聚(Fan-in)", 只有全架构编译无损通过, 才会触发发布.

4. 草稿防御性发布(Draft Release):
   * 脚本使用了 `gh release create "${tag}" --draft`.
   * 构建 OS 镜像涉及高达 16 个核心二进制与哈希文件, 万一上传过程中发生网络抖动或需要人工核查, 草稿状态不会触发下游监听 Releases 的 Webhook 或向最终用户推送通知, 直到人工在 Web 端验收通过点击"Publish"完成最终释放.

---

### 三、运行之后的最终效果

#### 场景 A: 开发者提交了一个 PR(Pull Request)

1. GitHub 检测到 PR 触发事件, 启动 `Release` 工作流.
2. `release-x86_64` 与 `release-aarch64` 两个 Job 同时启动, 并行在各自硬件上构建 4 种运行时(none, docker, containerd, incus)的系统镜像.
3. 校验通过后, 产物被上传到该次 Run 的临时 Artifacts 空间(可供开发者手动下载测试).
4. `create-release` Job 被条件 `if` 识别为 False, 自动跳过(Skipped). PR 页面显示绿色对勾 ✅, 证明代码合并不会打断编译.

#### 场景 B: 管理员打 Tag 触发发版(如 `git tag v1.0.0 && git push origin v1.0.0`)

1. GitHub 识别到满足 `v*` 规则, 启动流水线.
2. 架构 Job 1(x86)和 Job 2(arm64)开始并行编译, 产物分别上传到 Artifacts.
3. 两个架构全部构建成功后, 激活 `create-release`.
4. 第三台机器检出代码, 将两个架构的 Artifacts 全部拉取到本地的 `dist/img` 目录下.
5. 通过 `gh release create`, 在 GitHub 仓库的 Releases 页面自动生成一个名为 `v1.0.0` 的 Draft Release, 其资产列表包含清晰分类的 16 个发布文件:
   * `ubuntu-24.04-minimal-cloudimg-amd64-none.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-arm64-none.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-amd64-docker.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-arm64-docker.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-amd64-containerd.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-arm64-containerd.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-amd64-incus.raw.gz` 及 `.sha512sum`
   * `ubuntu-24.04-minimal-cloudimg-arm64-incus.raw.gz` 及 `.sha512sum`

---

### 四、高级开发建议(优化与避坑点)

作为代码审查(Code Review), 这份配置整体结构清晰, 但有以下几处细节可以进一步升级到生产顶配标准:

1. 升级 Action 版本:
   * 脚本中还在使用 `actions/checkout@v2`. 该版本基于老旧的 Node.js 运行时, 在较新的 Runner 环境中会出现 Deprecation Warning. 强烈建议升级为 `actions/checkout@v4`.

2. 最小权限原则(Security Hardening):
   * `permissions: write-all` 过于宽泛. 建议仅授予发布所需的写权限:
     ```yaml
     permissions:
       contents: write # 满足 gh release create 和 tag 读写
     ```

3. 引入构建矩阵(Matrix Strategy)精简代码:
   * 目前 `release-x86_64` 和 `release-aarch64` 内部重复硬编码了 4 次 `make image`, 如果改用 `strategy.matrix: { runtime: [none, docker, containerd, incus] }`, 不仅能减少重复 YAML 代码, 还能让这 4 种 RunTime 的镜像以 8 个并发 Job 同时起跑, 将整体 180 分钟的排队构建时间压缩到 1/4 左右.
