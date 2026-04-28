# 云效 Bug 修复技能

一个符合 [Agent Skills 开放标准](https://skill.md) 的 AI Agent 技能包，用于处理阿里云效的 Bug 全生命周期管理。

## 🎯 这是什么？

这个技能让 AI Agent 能够：
- 🔍 在云效项目中搜索和发现 Bug
- 📋 获取完整的 Bug 上下文（详情、评论、附件）
- 🔧 分析并修复代码问题
- ✅ 更新 Bug 状态并添加结构化评论
- 🤖 遵循最佳实践，内置容错机制

## 📦 什么是 Agent Skills？

Agent Skills 是 Anthropic 开发的[开放标准](https://github.com/agentskills/agentskills)，用于给 AI Agent 提供可复用的能力。一个技能是一个包含以下内容的文件夹：
- `SKILL.md` - 核心指令和工作流
- `scripts/` - 可执行的辅助脚本
- `references/` - 详细文档和示例
- `assets/` - 模板和资源

技能使用**渐进式披露**：Agent 只在需要时加载所需内容。

## 🚀 快速开始

### 前置条件

1. **云效 MCP 服务器**：需要配置云效 MCP 服务器
2. **访问权限**：有效的云效账号和项目访问权限
3. **支持技能的 Agent**：任何支持 Agent Skills 标准的 Agent：
   - Claude Code
   - Claude.ai
   - VS Code + Claude 扩展
   - GitHub Copilot
   - Cursor
   - 以及[更多](https://skill.md)

### 安装

#### 方式 1：克隆仓库
```bash
git clone https://github.com/willnie9/yunxiao-bug-fix.git
cd yunxiao-bug-fix
```

#### 方式 2：下载 ZIP
下载并解压到你的技能目录。

#### 方式 3：在 Agent 中使用
将整个 `yunxiao-bug-fix` 文件夹复制到你的 Agent 技能目录：
- **Claude Code**: `~/.claude/skills/`
- **VS Code**: `.vscode/skills/` 或工作区技能文件夹
- **其他 Agent**: 查看你的 Agent 文档

### 配置

1. **在 MCP 设置中配置云效 MCP 服务器**：

```json
{
  "mcpServers": {
    "mcp_aliyun_yunxiao": {
      "command": "node",
      "args": ["/path/to/yunxiao-mcp-server/index.js"],
      "env": {
        "YUNXIAO_ACCESS_TOKEN": "你的token"
      }
    }
  }
}
```

2. **验证安装**：询问你的 Agent：
```
列出我的可用技能
```

你应该能在列表中看到 `yunxiao-bug-fix`。

## 💡 使用示例

### 示例 1：修复特定 Bug
```
修复这个 bug：https://devops.aliyun.com/projex/project/xxx/bug/TXRP-592
```

Agent 会：
1. 从 URL 提取 Bug ID
2. 获取 Bug 详情并展示供确认
3. 你确认后，获取完整上下文（评论、附件、截图）
4. 定位并分析有问题的代码
5. 提出修复方案并等待你的批准
6. 更新云效状态并添加详细评论

### 示例 2：搜索你的 Bug
```
显示我的待处理 bug
```

Agent 会：
1. 搜索分配给你的 Bug
2. 显示带优先级和描述的列表
3. 等待你选择要修复哪一个

### 示例 3：高优先级 Bug
```
项目中有哪些高优先级的 bug？
```

### 示例 4：关键词搜索
```
查找与"登录"相关的 bug
```

## 📚 文档

- **[SKILL.md](SKILL.md)** - 核心工作流和指令（Agent 加载）
- **[快速开始.md](快速开始.md)** - 5分钟上手指南
- **[references/工作流示例.md](references/工作流示例.md)** - 真实使用示例
- **[references/状态映射指南.md](references/状态映射指南.md)** - 云效状态 ID 完整指南
- **[scripts/download-screenshot.sh](scripts/download-screenshot.sh)** - 下载附件的辅助脚本

## 🎨 特性

### 渐进式披露
技能使用三级加载策略：
1. **第 1 级**：技能名称和描述（始终加载，~100 tokens）
2. **第 2 级**：完整的 SKILL.md 指令（相关时加载，~3000 tokens）
3. **第 3 级**：参考文档和脚本（按需加载）

这让 Agent 的上下文保持精简，同时在需要时提供深度专业知识。

### 用户确认工作流
技能**绝不**在未经确认的情况下进行破坏性更改：
- ✅ 开始修复前显示 Bug 详情
- ✅ 应用更改前显示修复计划
- ✅ 更新云效状态前确认
- ✅ 添加评论前等待批准

### 容错机制
内置错误处理：
- 🔄 使用正确的 ID 自动重试状态更新
- 🔍 状态 ID 失败时动态查询工作流
- 📦 优雅处理缺失的附件
- 🛡️ 状态变更前验证转换

### 完整的上下文收集
绝不遗漏重要信息：
- 📝 始终获取评论（可能包含协调信息）
- 📎 始终检查附件
- 🖼️ 始终下载并查看截图
- 🔗 跟踪 Bug 描述中的引用

## 🏗️ 技能结构

```
yunxiao-bug-fix/
├── SKILL.md                          # 核心技能定义
├── README.md                         # 本文件
├── 快速开始.md                        # 5分钟上手指南
├── LICENSE                           # MIT 许可证
├── scripts/
│   └── download-screenshot.sh        # 截图下载辅助脚本
├── references/
│   ├── 工作流示例.md                  # 真实示例
│   └── 状态映射指南.md                # 状态 ID 参考
└── assets/
    └── 评论模板.md                    # 默认评论模板
```

## 🔧 自定义

### 自定义评论模板

编辑 `assets/评论模板.md` 来自定义添加到云效 Bug 的评论格式。

默认模板包含：
- ✅ 状态和时间戳
- ❗ 感谢测试同学并 @提及
- ⬇️ 验证步骤
- ⚠️ 问题原因分析
- ⚡ 修复方案详情
- ➡️ 涉及文件列表

### 自定义状态映射

技能会动态查询状态 ID，但你可以在 `references/状态映射指南.md` 中添加项目特定的映射。

### 额外脚本

在 `scripts/` 目录添加自定义脚本。Agent 可以根据需要发现并执行它们。

## 🤝 贡献

欢迎贡献！本技能遵循 [Agent Skills Specification v1.0](https://github.com/agentskills/agentskills)。

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 进行更改
4. 用你的 Agent 测试
5. 提交更改 (`git commit -m '添加某个特性'`)
6. 推送到分支 (`git push origin feature/amazing-feature`)
7. 开启 Pull Request

详见 [贡献指南.md](贡献指南.md)

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Anthropic](https://www.anthropic.com) 创建了 Agent Skills 标准
- [Agent Skills 社区](https://github.com/agentskills/agentskills) 提供开放规范
- 阿里云效团队提供平台

## 🔗 链接

- [Agent Skills 规范](https://github.com/agentskills/agentskills)
- [Agent Skills 文档](https://skill.md)
- [阿里云效](https://www.aliyun.com/product/yunxiao)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io)

## 📞 支持

- **问题反馈**：[GitHub Issues](https://github.com/willnie9/yunxiao-bug-fix/issues)
- **讨论交流**：[GitHub Discussions](https://github.com/willnie9/yunxiao-bug-fix/discussions)

## 📊 版本历史

### v1.0.0 (2026-04-28)
- 首次发布
- 完整的 Bug 生命周期管理
- 渐进式披露实现
- 容错的状态更新
- 用户确认工作流
- 全面的中文文档

---

**用 ❤️ 为 Agent Skills 社区打造**

*一次编写，到处使用。一起构建更好的 Agent。*
