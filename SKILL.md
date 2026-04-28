---
name: yunxiao-bug-fix
description: >-
  处理阿里云效 Bug 的通用技能。覆盖搜索、分析、修复、用户确认、状态更新、评论记录等全生命周期。
  当用户提供云效链接、提到bug/缺陷/工作项，或要求处理云效 bug 时使用。
---

# 云效 Bug 处理通用技能

## 概述
本 Skill 定义了一套基于云效 MCP 的标准化 Bug 处理流程。提供可复用的工具调用流程、参数规范和输出格式。

## 前置条件
- 已配置云效 MCP 服务器（`mcp_aliyun_yunxiao`）
- 具有云效项目的访问权限
- 需要动态获取的环境信息：
  - `organizationId`（通过 `mcp_aliyun_yunxiao_get_current_organization_info` 获取）
  - `userId`（同上）
  - `projectId`（从链接提取或通过 `mcp_aliyun_yunxiao_search_projects` 获取）

## 执行流程

### 步骤 1: 环境初始化
每次开始前必须先获取用户和组织信息：

**工具调用：**
```javascript
mcp_aliyun_yunxiao_get_current_organization_info()
// 返回: { organizationId, userId, ... }
```

**可选调用（需要查找项目时）：**
```javascript
mcp_aliyun_yunxiao_search_projects({ 
  organizationId, 
  scenarioFilter: "participate" // 或 "manage", "favorite"
})
```

**流程分支判断：**
- **场景 A：用户提供具体 Bug 链接** → 从链接提取 Bug ID → 跳转到步骤 2.5（展示确认）
- **场景 B：用户模糊请求（如"我的Bug"）** → 执行步骤 2（搜索）→ 步骤 2.5（展示列表）

### 步骤 2: 搜索工作项（仅场景 B）
**工具调用：** `mcp_aliyun_yunxiao_search_workitems`

**关键词智能映射：**
根据用户的自然语言自动构建查询参数：

| 用户说 | 自动执行 |
|--------|---------|
| "待确认的bug" | `statusStage: "1"` 或 `status: "28"` |
| "我的bug" | `assignedTo: "self"` |
| "高优先级bug" | `orderBy: "priority", sort: "desc"` |
| "最近创建的bug" | `orderBy: "gmtCreate", sort: "desc"` |

**必填参数：**
```json
{
  "organizationId": "<从步骤1获取>",
  "category": "Bug",
  "spaceId": "<projectId>"
}
```

**常用过滤参数：**

| 参数 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `statusStage` | string | 状态阶段：1=未开始，2=进行中，3=已关闭 | `"1,2"` 排除已关闭 |
| `includeDetails` | boolean | 是否在搜索结果中直接返回工作项的描述详情 | `true` 推荐启用 |
| `assignedTo` | string | 指派人 userId，特殊值 `"self"` 表示当前用户 | `"self"` |
| `orderBy` | string | 排序字段 | `"priority"`, `"gmtCreate"` |
| `sort` | string | 排序方向 | `"desc"`, `"asc"` |
| `status` | string | 状态 ID，多个用逗号分隔 | `"28,100005"` |
| `subject` | string | 标题关键词（模糊搜索） | `"登录"` |
| `subjectDescription` | string | 标题或描述关键词 | `"登录失败"` |
| `page` | number | 页码 | `1` |
| `perPage` | number | 每页数量（最大200） | `100` |

**最佳实践：**
- ✅ 默认使用 `statusStage: "1,2"` 排除已关闭项
- ✅ 始终启用 `includeDetails: true` 避免 N+1 查询
- ✅ 大数据量时使用分页

### 步骤 2.5: 展示Bug信息并等待用户确认（必须）
**⚠️ 关键步骤：获取到Bug信息后，必须先展示给用户确认，不要直接开始修复！**

**场景 1：搜索后展示列表**

```markdown
## 🐛 你的待处理 Bug（共 X 个）

### TXRP-592 - [Bug标题]
**优先级：** [高/中/低] | **状态：** [状态名称] | **指派给：** [指派人姓名]

**问题描述：**
[从工作项获取的完整描述内容]

**截图：** [查看截图](链接)（如果有）

---

**请选择要修复的Bug：**
- 回复Bug编号（如 "TXRP-592" 或 "修复 TXRP-592"）开始修复
- 或告诉我你想先看哪个Bug的详细信息
```

**场景 2：直接链接后展示确认**

```markdown
## 🐛 Bug 详情

**Bug ID:** [工作项ID]
**标题:** [Bug标题]
**状态:** [状态名称] | **优先级:** [高/中/低]
**指派给:** [指派人姓名] | **创建者:** [创建者姓名] | **验证者:** [验证者姓名]

**问题描述：**
[从工作项获取的完整描述内容]

**截图：** [查看截图](下载链接)（如果有）

**评论：** （如果有）
- **[评论人]** ([日期])：[评论内容]

---

**是否开始修复此 Bug？**
- 回复 **"开始修复"** 或 **"确认"** → 开始分析和修复
- 回复 **"取消"** → 不处理此 Bug
```

**只有在用户明确确认后，才能继续步骤3。**

### 步骤 3: 获取详情与上下文（针对用户确认的Bug）
**⚠️ 前置条件：用户已确认要修复此 Bug。此步骤所有子步骤必须依次完整执行，不可跳过！**

**① 获取工作项详情（必须）：**
```javascript
mcp_aliyun_yunxiao_get_work_item({ organizationId, workItemId })
```

**② 获取评论列表（必须）：**
```javascript
mcp_aliyun_yunxiao_list_work_item_comments({ organizationId, workItemId })
```

**③ 获取附件列表（必须）：**
```javascript
mcp_aliyun_yunxiao_list_workitem_attachments({ organizationId, workItemId })
```

**④ 下载并查看截图（必须）：**
```javascript
mcp_aliyun_yunxiao_get_workitem_file({ organizationId, workitemId, id })
// 返回临时下载链接，必须 curl 下载到本地后才能查看
```
- ❗ 截图附件包含关键的 UI 问题信息，**必须查看，不可跳过**
- ❗ 附件链接不能直接访问，**必须 curl 下载到本地后再查看**
- ❗ 即使 Bug 描述文字已清晰，也必须查看截图
- 如果确实没有附件，记录"无附件"后继续步骤 4

**⚠️ 完成以上全部 ① ② ③ ④ 步骤后，才能进入步骤 4！**

### 步骤 4: 代码定位
根据 Bug 信息定位相关代码：

1. **关键词搜索：** 使用 `grepSearch` 搜索标题/描述中的关键词
2. **路径推断：** 根据功能模块推断可能的文件路径
3. **Git 历史：** 查看相关功能的最近修改记录
4. **询问用户：** 无法定位时请求用户提供线索

### 步骤 5: 分析与修复
**输出格式规范：**

```markdown
**涉及文件：** `path/to/file`

**问题代码（行号）：**
\```language
// 有问题的代码片段
\```

**问题描述：** 
解释为什么会导致 Bug，包括逻辑错误、边界条件等。

**修复方案表格：**
| 涉及模块 | 代码问题 | 方案 | 手动验证步骤 |
|---------|---------|------|------------|
| 模块路径 | 问题简述 | 修复方法 | 1. 步骤1<br>2. 步骤2<br>3. 预期结果 |

**修复类型：** ✅ 纯前端修复 / ⚠️ 需要后端配合
```

**⚠️ 修复代码后，必须执行步骤 6 的用户确认流程，不要自动更新云效！**

### 步骤 6: 用户确认（必须）
**⚠️ 关键步骤：修复代码后必须等待用户明确确认，不要自动更新云效！**

修复完成后，向用户展示修复内容并询问：

```markdown
✅ 代码已修复完成

**修复内容：**
- [列出修改的文件和关键改动]

**验证步骤：**
1. [操作步骤1]
2. [操作步骤2]
3. [预期结果]

---

**请确认是否完成修复？**
- 回复 **"确认"** → 我将更新云效状态为"开发完成"并添加修复评论
- 回复 **"需要调整"** → 我将重新修复
- 回复 **"仅更新代码"** → 不更新云效，仅保留代码修改
```

**用户回复处理：**
- **"确认" / "可以" / "没问题"** → 执行步骤 7
- **"需要调整" / 提出修改意见** → 返回步骤 5 重新修复
- **"仅更新代码" / "不更新云效"** → 跳过步骤 7，流程结束

### 步骤 7: 更新云效状态与评论（需用户确认）
**⚠️ 此步骤仅在用户明确确认后执行**

**更新工作项：**
```javascript
// 1. 先读取当前状态
const workItem = await mcp_aliyun_yunxiao_get_work_item({ organizationId, workItemId })

// 2. 更新字段（只更新需要改的字段）
mcp_aliyun_yunxiao_update_work_item({
  organizationId,
  workItemId,
  updateWorkItemFields: {
    status: "<新状态ID>",
  }
})
```

**添加评论：**
```javascript
mcp_aliyun_yunxiao_create_work_item_comment({
  organizationId,
  workItemId,
  content: "Markdown 格式的评论内容"
})
```

**状态 ID 获取（自动容错）：**
1. **动态查询**：调用 `mcp_aliyun_yunxiao_get_work_item_workflow` 查询实际状态流
2. **自动容错**：若状态 ID 更新失败，重新查询并重试
3. **动态适配**：使用查询到的实际状态 ID 进行更新

**常见状态 ID 参考：**

| 状态名称 | 常见 ID | statusStage | 说明 |
|---------|--------|-------------|------|
| 待确认 | 28 | 1 | 新建的 bug |
| 待处理 | 100005 | 1 | 已确认，等待处理 |
| 进行中 | 100010 | 2 | 正在修复 |
| 开发完成 | 100011 | 2 | 开发完成，待测试 |
| 测试中 | 100012 | 2 | 测试中 |
| 已修复 | - | 3 | 已完成 |
| 已关闭 | - | 3 | 已关闭 |

**注意**：状态 ID 可能因项目而异，建议使用动态查询。

### 步骤 8: 验证与记录
- 运行相关测试验证修复效果
- 确认云效状态已更新
- 确认评论已成功添加

## 输出规范

### Bug 列表输出格式
```markdown
## 🐛 Bug 列表（共 X 个）

### PROJ-123 - 问题标题 优先级(高)

**问题内容：** 简要描述

**截图：** [链接]（如果有）

**评论：** 
- **评论人** (日期)：评论内容

---
```

### 评论内容格式
**默认评论模版：**

```markdown
✅ 已修复 | ⏱️ 修复时间：YYYY-MM-DD HH:mm
❗ 感谢测试同学 @{验证者姓名} 精准报 Bug，定位准确，帮助快速修复！
⭐ 测试人，YYDS！每一个被你点亮的缺陷，都是产品进步的台阶。

**⬇️ 验证步骤**
1. [操作步骤1]
2. [操作步骤2]
3. [预期结果]

**⚠️ 问题原因**
[详细描述导致 Bug 的根本原因]

**⚡ 修复方案**
- [修复点1：具体的代码修改说明]
- [修复点2：具体的代码修改说明]

**➡️ 涉及文件**
`path/to/file1.vue`
```

## 最佳实践

### 必须遵守
- ✅ 所有 ID 必须动态获取，绝不硬编码
- ✅ 默认使用 `statusStage: "1,2"` 排除已关闭项
- ✅ 使用 `includeDetails: true` 避免 N+1 查询
- ✅ **获取到Bug信息后，必须先展示给用户确认**
- ✅ **用户确认后，必须完整执行步骤3全部子步骤**
- ✅ **附件截图必须 curl 下载到本地查看**
- ✅ **修复代码后必须等待用户确认**
- ✅ 更新前先读取当前状态
- ✅ 状态 ID 更新失败时，自动查询 workflow 并重试

### 避免做法
- ❌ 硬编码 organizationId、projectId、状态 ID
- ❌ **获取到Bug信息后直接开始修复**
- ❌ **用户确认后跳过步骤3**
- ❌ **跳过截图查看步骤**
- ❌ **通过 URL 直接访问截图**
- ❌ **修复代码后未经确认就自动更新云效**

## 工具参考

本 Skill 使用的云效 MCP 工具（前缀 `mcp_aliyun_yunxiao_`）：

- `get_current_organization_info` - 获取当前组织信息
- `search_projects` - 搜索项目
- `search_workitems` - 搜索工作项
- `get_work_item` - 获取工作项详情
- `update_work_item` - 更新工作项
- `list_work_item_comments` - 获取评论列表
- `create_work_item_comment` - 创建评论
- `list_workitem_attachments` - 获取附件列表
- `get_workitem_file` - 获取附件文件
- `get_work_item_workflow` - 获取工作流状态

## 扩展资源

需要更详细的示例和高级用法，请查看：
- [references/工作流示例.md](references/工作流示例.md) - 真实场景示例
- [references/状态映射指南.md](references/状态映射指南.md) - 状态 ID 映射指南
- [scripts/download-screenshot.sh](scripts/download-screenshot.sh) - 截图下载脚本
