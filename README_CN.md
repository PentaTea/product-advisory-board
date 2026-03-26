# Product Advisory Board (PAB)

**你不需要又一个 AI 对你说"好主意！"——你需要一屋子互相拆台的专家。**

---

## 这是什么？

Product Advisory Board 是一个基于 Claude Code 的**多智能体协议**，模拟一组物理隔离的 AI 顾问就你的产品决策进行辩论。每个顾问作为独立的 subagent 运行，拥有自己的上下文窗口——它们在 Facilitator 综合输出之前，字面意义上无法看到彼此的工作成果。

这不是提示词工程，而是**流程工程**——一个包含严格执行顺序的 5 阶段协议，通过文件驱动信息流转，强制执行红队压力测试，并留下完整的审计链。每个中间产物都会写入磁盘，然后才进入下一阶段。

输出不是"AI 生成的建议"，而是一份**结构化决策简报**，包含共识要点、具名分歧、经过压力测试的假设，以及一份清晰的*你*仍需做出决定的事项清单。

## 快速开始

### 1. 安装

**方式 A — 本地 Claude Code Plugin（推荐）：**

```bash
git clone https://github.com/PentaTea/product-advisory-board.git
cd product-advisory-board
claude --plugin-dir .
```

这样会把 PAB 作为当前会话的本地 Claude Code plugin 直接加载。Claude Code 会自动发现插件根目录下默认的 `skills/` 和 `agents/` 目录，因此 skill 和 subagent 会一起可用。

> 目前**还不能**通过 marketplace 安装。仅仅公开到 GitHub 还不够；只有发布到某个已配置的 Claude plugin marketplace 之后，`claude plugin install` 才能生效。

**方式 B — skills.sh + 手动复制 agents：**

```bash
npx skills add PentaTea/product-advisory-board        # 安装 skill
git clone https://github.com/PentaTea/product-advisory-board.git /tmp/pab
cp /tmp/pab/agents/pab-*.md .claude/agents/            # agents 需要手动复制
```

> `npx skills add` 只处理 `skills/`。Agent 定义需要单独复制。

**方式 C — 安装脚本：**

```bash
git clone https://github.com/PentaTea/product-advisory-board.git /tmp/pab
cd /path/to/your-project
/tmp/pab/install.sh           # 项目级安装到 /path/to/your-project/.claude/
/tmp/pab/install.sh --global  # 或用户级安装到 ~/.claude/
```

**Cursor / Codex 兼容性：** 方式 A 仅适用于 Claude Code。Cursor 2.4+ 原生读取 `.claude/agents/`，因此请在 Cursor 中使用方式 B/C。Codex 使用 TOML 格式的 agent 定义（需格式转换）。

### 2. 在 Claude Code 中触发

如果你是通过 `claude --plugin-dir` 启动 PAB 的，请使用带命名空间的 skill 名：

```
> /product-advisory-board:product-advisory-board Should we pivot from B2B to B2C for our AI writing assistant?
```

如果你是把文件手动复制到 `.claude/skills/` 和 `.claude/agents/`（方式 B/C），请使用独立安装时的 skill 名：

```
> /product-advisory-board Should we pivot from B2B to B2C for our AI writing assistant?
```

或使用自然语言：

```
> 产品顾问团，讨论一下我们要不要做 freemium 模式
> Let's get the advisory board's take on our pricing strategy
```

安装或启动后，建议先打开 `/agents` 确认 PAB 的 agent 已经被加载：

- 本地 plugin 模式（`claude --plugin-dir`）：应看到 `product-advisory-board:pab-scout`、`product-advisory-board:pab-red-team` 以及其他 PAB agents
- 独立 `.claude/` 安装：应看到 `pab-scout`、`pab-red-team` 以及其他 `pab-*` agents

### 3. 阅读决策简报

最终输出存放在 `docs/pab-session-{timestamp}/40-decision-brief.md`——一份结构化文档，包含共识要点、具名分歧、Red Team 的风险表格、未验证的假设、盲区，以及清晰的"你仍需做出的决定"部分。

## 为什么现有 PM 工具不够用

我们调研了 7 个热门 AI 产品管理仓库，发现了一个共同模式：

| 方法               | 做了什么                                    | 问题在哪                                                                           |
| ------------------ | ------------------------------------------- | ---------------------------------------------------------------------------------- |
| **单提示词 PM**    | 一个大提示词加上"像 PM 一样思考"            | 一个上下文 = 一个视角。没有真正的张力，没有真正的分歧。                            |
| **角色扮演提示词** | "先以设计师身份思考，再以工程师身份思考..." | 同一个 LLM，同一个上下文窗口。"工程师"已经读过"设计师"说了什么——锚定偏差是内建的。 |
| **模板合集**       | PRD 模板、用户故事模板等                    | 模板规范的是*输出格式*，不是*思考过程*。垃圾输入，格式化的垃圾输出。               |
| **对话式脑暴**     | 多轮对话中扮演不同角色                      | 前面的消息会锚定后面的。到第 5 条消息时，LLM 基本就在跟自己点头了。                |

**核心问题：** 这些方法把*格式*和*流程*搞混了。让 LLM 用"产品策略师"的格式写作，并不能给你策略师的独立判断——只是同一个模型的观点换了几顶帽子。

PAB 用**物理隔离**来解决这个问题：每个顾问是一次独立的 `Agent()` 调用，拥有自己的上下文窗口、自己的角色定义文件，并且对其他顾问的输出零访问权限。

## 架构

### 五阶段协议

```
                         ┌─────────────────────┐
                         │   Context Collection │  Structured user input → 00-context.md
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                    ┌────│     Phase 0: Recon  │  Scout + External Experts + Brief generation
                    │    └──────────┬──────────┘
                    │               │
              ┌─────▼─────┐        │
              │   Scout    │        │  Scans 144 roles from agency-agents
              │ (fg, wait) │        │  Returns 0-3 domain expert matches
              └─────┬─────┘        │
                    │               │
            ┌───────▼───────┐      │
            │ External Experts│     │  Each fetches their role def from GitHub
            │  0-3 (fg, wait) │    │  Writes domain intelligence → 02-expert-*.md
            └───────┬───────┘      │
                    │               │
                    └───────┬──────┘
                            │  Facilitator generates thin briefs (pointers only)
                 ┌──────────▼──────────┐
                 │   Phase 1: Insights  │  3-5 core advisors run IN PARALLEL
                 │  (physically isolated)│  Each writes → 10-insight-{role}.md
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │ Phase 2: Synthesis   │  Facilitator identifies consensus,
                 │                      │  conflicts, blind spots, assumptions
                 │                      │  Writes → 20-synthesis.md
                 └──────────┬──────────┘
                            │
                  ┌─────────▼─────────┐
                  │  Phase 3: Debate   │  Pro/Con agents for each directional
                  │  + Red Team        │  conflict → Red Team pressure test
                  └─────────┬─────────┘
                            │
                  ┌─────────▼─────────┐
                  │ Phase 4: Decision  │  Final brief with named disagreements,
                  │      Brief         │  risk table, unverified assumptions
                  └────────────────────┘
```

### 报告链（完整审计链）

每个阶段在推进前都会写入文件。没有任何东西只存在于内存中。

```
docs/pab-session-{timestamp}/
├── 00-context.md                  ← 用户输入，结构化整理
├── 00-topic-analysis.md           ← 团队组建 + Scout 结果
├── 01-scout-report.md             ← 外部专家匹配
├── 02-expert-{nn}-{name}.md      ← 外部专家的领域情报
├── 03-brief-{role}.md            ← 精简简报（仅指针，不含内容）
├── 10-insight-{role}.md          ← 各顾问独立分析
├── 20-synthesis.md                ← 共识 / 冲突 / 盲区
├── 30-debate-{topic}-pro.md      ← 正方论点（原始）
├── 30-debate-{topic}-con.md      ← 反方论点（原始）
├── 30-debate-{topic}.md          ← 合并后的辩论记录
├── 30-redteam-final.md           ← Red Team 压力测试
├── 40-decision-brief.md          ← 最终决策简报
└── README.md                     ← 报告索引
```

## 设计原则

### 1. 物理隔离 > 角色扮演

大多数多角色提示词在同一个上下文窗口内运行。"工程师"已经读过"设计师"的分析——锚定偏差不可避免。

PAB 使用 Claude Code 的 `Agent()` 工具将每个顾问生成为**独立 subagent**。每个顾问获得：

- 自己的上下文窗口（干净的初始状态）
- 自己的角色定义（通过 `subagent_type` 加载，不是粘贴到提示词里）
- 只能读取被指定的文件（通过 `<files_to_read>` 块）

这不是风格选择，而是防止群体思维的**架构保障**。

### 2. 文件驱动，零传话

Facilitator 是**调度器，不是传话者**。信息通过文件流转，绝不通过提示词转述：

```
❌  Facilitator 读取内容 → 把摘要嵌入 subagent 提示词（传话游戏）
✅  Facilitator 将内容写入文件 → 告诉 subagent 读哪个文件（指针）
```

为什么这很重要：每次 LLM 转述信息，都会丢失细节、注入解读、偏离原意。文件驱动的信息流保留了原始信号。

### 3. 强制对抗性思维

Red Team 不是可选项——它在**每一次会话**中都会被选入，无论议题类型。当所有顾问意见一致（零方向性冲突）时，协议会触发**共识压力测试**而不是跳过辩论：

- 哪些共享假设未经验证？
- 在什么条件下这个共识会崩塌？
- 房间里有没有没人愿意提的大象（Elephant in the room）？

这个系统的设计让"所有人都同意"成为*最可疑的*结果。

### 4. 完整审计链

每个中间产物都持久化到磁盘。这意味着：

- 你可以审查委员会*如何*得出结论，而不仅仅是他们得出了*什么*结论
- 你可以用不同的输入重新运行单个阶段
- 你可以把完整的讨论记录分享给团队
- 几个月后，你可以回溯*为什么*做了某个决策

## 智能体阵容

### 8 位核心顾问

| 角色                      | 文件                        | 视角                         | 思考框架                                                    |
| ------------------------- | --------------------------- | ---------------------------- | ----------------------------------------------------------- |
| **User Advocate**         | `pab-user-advocate.md`      | 用户痛点、JTBD、采纳障碍     | Jobs-to-Be-Done、Mom Test、Journey Mapping                  |
| **Product Strategist**    | `pab-product-strategist.md` | 市场定位、护城河、时机       | Moore's Positioning、Porter's 5 Forces、Focus vs. Diffusion |
| **Growth Analyst**        | `pab-growth-analyst.md`     | 指标、单位经济学、增长飞轮   | North Star Metric、LTV/CAC、Growth Flywheel                 |
| **Tech Advisor**          | `pab-tech-advisor.md`       | 可行性、架构、建设成本       | Feasibility Matrix、Tech Debt、Build vs Buy、MVP Scoping    |
| **Red Team Challenger**   | `pab-red-team.md`           | 魔鬼代言人、预验尸、假设挑战 | Pre-mortem、Tigers/Paper Tigers/Elephants、二阶效应         |
| **Design Thinker**        | `pab-design-thinker.md`     | UX 模式、信息架构、交互设计  | Nielsen Heuristics、FTUE、Progressive Disclosure、AI UX     |
| **Business Model Expert** | `pab-business-model.md`     | 定价、变现、GTM              | Business Model Canvas、Pricing Strategy、GTM Playbook       |
| **Industry Observer**     | `pab-industry-observer.md`  | 趋势、跨行业类比、弱信号     | Trend Analysis、Time Machine Analogies、First Principles    |

### Scout Agent

**Scout**（`pab-scout.md`）是一个专门的侦察智能体，在核心顾问之*前*运行。它扫描 [agency-agents](https://github.com/msitarzewski/agency-agents) 仓库（144 个角色），匹配 0-3 个与当前议题相关的外部领域专家。筛选标准严格：只选择能填补核心顾问知识缺口的专家。

### 外部专家系统

当 Scout 识别到相关的领域专家时：

1. 每个专家通过 `WebFetch` 从 GitHub 获取其角色定义
2. 读取 `00-context.md` 中的结构化议题上下文
3. 产出一份领域情报报告（`02-expert-{name}.md`）
4. 该情报随后通过简报提供给核心顾问使用

这使 PAB 在不膨胀核心团队的前提下，动态获取 144+ 个专业视角。

## 与其他方法的对比

| 能力               | 单提示词 PM | 角色扮演提示词 | 模板包 |           **PAB**           |
| ------------------ | :---------: | :------------: | :----: | :-------------------------: |
| 多个独立视角       |      -      |     模拟的     |   -    |        **物理隔离**         |
| 防止锚定偏差       |      -      |       -        |   -    |       **架构级保障**        |
| 强制对抗性挑战     |      -      |      可选      |   -    |      **Red Team 常驻**      |
| 外部领域专家       |      -      |       -        |   -    | **144 个角色经 Scout 接入** |
| 结构化冲突辩论     |      -      |       -        |   -    |   **Pro/Con + Red Team**    |
| 完整审计链         |      -      |       -        |   -    |     **每阶段一个文件**      |
| 可复现流程         |      -      |       -        |  部分  |       **5 阶段协议**        |
| 共识压力测试       |      -      |       -        |   -    |        **自动触发**         |
| 无需自定义基础设施 |     N/A     |      N/A       |  N/A   |    **Claude Code 原生**     |

## 工作原理：信息流

```
                          ┌──────────┐
                          │   User   │
                          └────┬─────┘
                               │ topic + context
                          ┌────▼─────┐
                          │Facilitator│──────────────────────────────────┐
                          └────┬─────┘                                  │
                    writes     │     reads results                      │
                 ┌─────────────┼─────────────────┐                      │
                 ▼             ▼                  ▼                      │
          ┌────────────┐ ┌──────────┐    ┌──────────────┐               │
          │00-context.md│ │03-brief- │    │20-synthesis.md│              │
          │             │ │ {role}.md│    │               │              │
          └──────┬─────┘ └────┬─────┘    └───────┬──────┘              │
                 │            │                   │                      │
        ┌────────┼────────────┼───────────────────┼──────┐              │
        │reads   │reads       │reads              │reads │              │
        ▼        ▼            ▼                   ▼      ▼              │
   ┌─────────┐ ┌──────┐ ┌──────────┐ ┌───────────┐ ┌────────┐         │
   │  Scout   │ │Expert│ │ Advisor  │ │ Pro/Con   │ │Red Team│         │
   │  Agent   │ │Agents│ │ Agents   │ │ Debaters  │ │        │         │
   └────┬─────┘ └──┬───┘ └────┬─────┘ └─────┬────┘ └───┬────┘         │
        │writes    │writes    │writes       │writes    │writes         │
        ▼          ▼          ▼             ▼          ▼               │
   01-scout-   02-expert-  10-insight-  30-debate-  30-redteam-        │
   report.md   {name}.md   {role}.md    {topic}.md  final.md           │
                                                                        │
                                                         reads all ◄────┘
                                                              │
                                                     ┌────────▼────────┐
                                                     │40-decision-brief│
                                                     │      .md        │
                                                     └─────────────────┘
```

**核心规则：** 标有"reads"的箭头表示智能体自己使用 `Read` 工具读取。Facilitator 绝不会读取一个文件然后把内容粘贴到另一个智能体的提示词中。信息完整性得以保障，因为每个智能体都直接读取源文件。

## 自定义

### 添加新的核心顾问

1. **创建 agent 定义文件**，放在 `.claude/agents/pab-{your-role}.md`：

```yaml
---
name: pab-{your-role}
description: >
  产品顾问团的{角色名}。{一句话描述视角}。
model: sonnet
tools:
  - Read
  - Write
---
```

2. **定义思考框架**——每个顾问需要 3-5 个命名的分析框架来引导其分析。这不是装饰性的；它们是让输出结构化且可复现的关键。

3. **定义输出格式**——一个严格的模板，包含"核心立场"、"关键论点（3-5 个）"、"风险与顾虑"、"关键假设"和"建议下一步"等章节。

4. **添加行为约束**——定义这个顾问应该和不应该评论的范围。窄聚焦 = 更高质量的输出。一个同时对商业模式发表意见的 Tech Advisor 会稀释两个视角。

5. **注册到 SKILL.md**——将角色添加到顾问表和议题类型路由矩阵中。

### 调整团队组成

每种议题类型的默认团队定义在 SKILL.md 的 Phase 0 路由表中：

```markdown
| Topic Type       | Default Team                                                      |
| ---------------- | ----------------------------------------------------------------- |
| Product Strategy | Product Strategist + User Advocate + Industry Observer + Red Team |
| Feature Design   | User Advocate + Design Thinker + Tech Advisor + Red Team          |
| Monetization     | Business Model + Growth Analyst + User Advocate + Red Team        |
```

修改这个表即可更改默认配置。唯一的硬性规则：**Red Team 必须始终包含在内**。

### 更换外部专家来源

Scout 当前从 [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)（144 个角色）拉取。要使用不同的角色库：

1. 更新 `pab-scout.md` 中的 WebFetch URL
2. 调整 Scout 执行步骤第 2 步中的解析逻辑

## FAQ

**Q: 一次完整会话需要多少次 API 调用？**
A: 最少约 8 次（Scout + 3 个顾问 + 综合 + 2 个辩论者 + Red Team），最多约 16 次（Scout + 3 个专家 + 5 个顾问 + 综合 + 4 个辩论者 + Red Team）。每次都是一个独立的 `Agent()` 调用。

**Q: 我可以用 Claude 以外的模型运行吗？**
A: PAB 基于 Claude Code 的 `Agent()` 工具和 `subagent_type` 参数构建，专为 Claude 的智能体基础设施设计。协议本身（文件驱动隔离、分阶段讨论）在概念上与模型无关，但实现是 Claude Code 原生的。

**Q: 如果某个智能体失败了怎么办？**
A: 协议包含明确的错误处理：重试一次，然后标记为"未参与（智能体故障）"并继续。综合阶段会注明缺失的视角。单个智能体的失败不会阻塞整个会话。

**Q: Red Team 只是一个唱反调的吗？**
A: 不是。Red Team 使用结构化框架——Pre-mortem 分析、Tigers/Paper Tigers/Elephants 分类、二阶效应。它必须产出至少 3 个有证据和缓解策略的具体风险。"一切都有风险"和"一切都没问题"一样没用。

**Q: 为什么用文件而不是通过提示词传递数据？**
A: 三个原因。（1）**保真度**——LLM 在转述时会丢失细节；文件保留了原始内容。（2）**可审计性**——你可以精确检查每个智能体看到了什么。（3）**可调试性**——当某个智能体产出了糟糕的输出时，你可以检查它的输入文件来理解原因。

---

## License

AGPL 3.0
