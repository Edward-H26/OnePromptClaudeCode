> **Parent**: [CLAUDE.md](./CLAUDE.md) | **Related**: [CLAUDE-testing.md](./CLAUDE-testing.md), [CLAUDE-website-workflow.md](./CLAUDE-website-workflow.md), [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md)

# Harness 总览参考 (CLAUDE-skills.md)

本文件是这套 Claude Code harness 的"地图":列出全部 skill、command、MCP、hook、plugin,逐个用大白话解释、给出使用场景,并标出重复或冲突的地方。

计数:**71 skills · 66 commands · 14 agents · 4 hooks · 2 MCP(仓库自带)· 6 plugins**。
验证:`python3 -c "import json; print(len(json.load(open('.claude/skills/skill-rules.json'))['skills']))"`

状态图例:🔴 常驻(每条 prompt 都被 `task-orchestrator-hook.sh` 列出)· 🟢 按需(只在命中关键词/意图时出现,或用 `/命令` 手动开)。当前 **常驻 15 / 按需 56**。

---

## 一、Skills

### 🔴 常驻 · 设计(11)
每写 UI 都用得上,所以常驻。彼此有重叠,见下方"重复冲突"。

- **frontend-design** — 给新界面定独特视觉方向、排版、审美,避免模板感。「做新页面/组件,定基调时」
- **impeccable** — 全面设计/改版/审查/打磨界面(网站、仪表盘、表单、设计系统)。「要把一个界面整体提质时」
- **ui-ux-pro-max** — 超大 UI/UX 知识库(几十种风格、上百配色、字体搭配、UX 规则)。「找风格/配色/字体灵感时」
- **design-taste-frontend** — 给落地页/作品集/改版做"去 AI 味"前端,自动判断方向。「做落地页、作品集时」
- **high-end-visual-design** — 教 AI 像高端设计公司那样做"贵感"网站,屏蔽廉价默认。「要高级感、商业感时」
- **redesign-existing-projects** — 把现有网站/应用升级到高端品质,识别并替换通用套路。「翻新旧站时」
- **minimalist-ui** — 极简编辑风(暖色单色调、扁平 bento、无渐变重阴影)。「要极简风格时」
- **gpt-taste** — 高级 UX/UI + GSAP 动效(AIDA 结构、滚动动画)。「要强动效、滚动叙事时」
- **shadcn-ui** — shadcn/ui 组件库模式(安装、表单 + Zod、主题、可访问组件)。「用 shadcn 搭组件时」
- **web-accessibility** — 按 WCAG 做无障碍(ARIA、键盘导航、读屏)。「要过无障碍标准时」
- **web-design-guidelines** — 拿 Web 界面规范审查 UI 代码。「UI 写完做规范审查时」

### 🔴 常驻 · 学术写作(4)
论文质量类,每篇都用得上。写整篇论文**主推 `academic-pipeline`**(研究→写→审一条龙)。

- **academic-pipeline** — 把研究→写→审→改串成 10 阶段总编排,是**写论文的主推入口**。「想从研究到成稿一条龙时」
- **research-paper-writing** — 提升英文 ML/CV/NLP 论文写作质量(结构、段落、面向审稿人)。「写英文顶会论文时」
- **nature-polishing** — 把中文/粗糙英文润色成 Nature 风格英文,还能修 LaTeX 排版。「润色英文稿、修 LaTeX 排版时」
- **nature-writing** — 从观点/结果/图起草 Nature 风格章节。「从零起草论文章节时」

### 🟢 按需 · 核心(24)
原有的开发/研究/审查/工具类,关键词触发或 `/命令` 手动开。

**开发**
- **backend-dev-guidelines** — Node/Express/TS 后端规范。「写后端路由/服务时」
- **frontend-dev-guidelines** — React/TS 前端模式(Suspense、TanStack)。「写 React 组件/数据获取时」
- **ui-styling** — shadcn/ui + Tailwind 组件样式。「调样式、做布局时」
- **code-refactor** — 批量重命名/替换/改 API 调用。「跨文件大规模改名时」

**研究 / 调试 / 审查**
- **deep-research** — 13 agent 深度研究团队(系统综述、meta 分析、事实核查)。「要严谨多源研究报告时」
- **aiq-research** — 5 阶段 AI-Q 风研究,带引用。「要带引用的结构化研究报告时」
- **investigate** — 系统化根因调试(假设验证,3 次失败就停)。「查 bug 根因时」
- **review** — 资深工程师代码审查(`/review-staff`),找过了 CI 的生产 bug。「合并前审代码时」
- **search-first** — 先搜现有代码再写。「动手改之前先摸代码时」
- **refine** — 评估-优化循环(生成→批评→改→再批评,最多 3 轮)。「做完想再打磨一轮时」

**计划 / QA**
- **office-hours** — 写码前头脑风暴、需求澄清(YC Office Hours 风)。「需求没想清、先聊方案时」
- **plan-design-review** — 资深设计师给方案打分,检测 AI 套路。「评审设计方案时」
- **plan-eng-review** — 工程经理式架构评审(数据流、边界、测试矩阵)。「评审实现方案时」
- **design-review** — 视觉审查 + 原子提交修复 + 前后对比截图。「UI 改完查一遍时」
- **qa** — 浏览器 QA + 自动回归测试。「测网页功能并修时」
- **qa-only** — 只出 QA 报告、不改码。「只要测试报告时」

**工具 / 插件包装**
- **chrome-devtools** — 驱动 Chrome(截图/网络/Lighthouse)。「浏览器调试、性能、截图时」
- **webapp-testing** — Python Playwright 测本地网页。「端到端测本地站时」
- **playwright** — 转 Playwright 插件。「要跨浏览器自动化时」
- **figma** — 转 Figma 插件。「读写 Figma 设计时」
- **github** — 转 GitHub 插件。「仓库/PR/issue/CI 时」
- **context7** — 转 context7 插件。「查某库最新文档时」
- **superpowers** — 转 Superpowers 插件(头脑风暴/TDD/调试/审查)。「想用结构化工程流程时」
- **remotion** — 用 Remotion(React 视频框架)编程做视频。「做程序化视频时」

### 🟢 按需 · 学术(28)
一整套科研流水线,按需触发。注意:写论文有三套并存(见冲突)。

- **academic-paper** — 12 agent 论文写作流水线,11 种模式。「写整篇英文论文(一套主力)」
- **academic-paper-reviewer** — 模拟 5 审稿人(主编+3 审稿+唱反调)。「投稿前自审」
- **citation-check-skill** — 带视觉+联网核查引用真假。「查 AI 有没有编参考文献时」
- **research-writing-skill** — 中文优先的写作/润色/rebuttal。「用中文写论文时」
- **nature-academic-search** — 多源文献检索 + 引用管理(PubMed/CrossRef/arXiv)。「查文献、管参考文献时」
- **nature-citation** — 给段落自动配 Nature/CNS 引用。「补引用时」
- **nature-data** — 写数据可用性声明、仓库选择、FAIR 元数据。「投稿写 data availability 时」
- **nature-figure** — Nature 级科研配图(Python/R,投稿级 SVG/PDF/TIFF)。「做投稿数据图时」
- **nature-paper-to-patent** — 论文/代码转中文发明专利草稿。「要申专利时」
- **nature-paper2ppt** — 论文转 Nature 风中文 PPT。「论文做组会/答辩汇报时」
- **nature-reader** — PDF 论文转中英对照、图表感知精读稿。「精读文献时」
- **nature-response** — 写审稿意见回复(rebuttal)。「回审稿意见时」
- **nature-reviewer** — 模拟审稿人审你的稿。「投稿前自审(Nature 风)」
- **office-academic-skill** — 中文优先 Word/PPT 学术工作流(精读报告、组会 PPT、DOCX/PPTX)。「做中文学术汇报材料时」
- **scientific-figure-making** — figures4papers 发表级作图。「做论文数据图(另一套)」
- **scientific-toolkit-skill** — 科研计算工具箱(MATLAB/Octave、Python 分析、信号处理)。「做数据分析/科学计算时」
- **paper-spine** — PaperSpine 流水线主入口,从头写一篇论文出 LaTeX/PDF/Word。「用 PaperSpine 那套写论文时」
- **paper-spine-***(11 个:`-audit/-build/-citation/-humanize/-intake/-latex/-research/-rewrite/-translate/-ui/-update`)— PaperSpine 的内部步骤,跟着主入口走,平时不单独用。

### 🟢 按需 · 设计降级(4)
原本常驻、后来降为按需的设计/画图 skill。

- **image-to-code** — 图先行建站:先生成设计图、分析、再还原成网站(依赖图像生成,当前环境可能跑不全)。「有设计图要还原成代码时」
- **industrial-brutalist-ui** — 粗野工业风(瑞士排版 + 终端美学)。「要这种特定硬核风格时」
- **fireworks-tech-graph** — 自然语言→技术图(架构/流程/时序),导出 SVG+PNG。「要画架构图/流程图时」
- **diagram-design** — 技术/产品图做成 HTML+SVG,能抓品牌色。「要带品牌风的图表时」

---

## 二、Commands(66)

机制:**打 `/名字` = 调用同名 skill**(绝大多数 1:1)。名字不同的 4 个:
- `/backend-dev` → backend-dev-guidelines
- `/frontend-dev` → frontend-dev-guidelines
- `/review-staff` → review
- `/build-fix` → 增量修 build/类型错误

常驻 skill 不需要手动开,但也都各有同名 `/命令` 可手动触发。

---

## 三、MCP 服务器

- **仓库自带(随仓库走,已启用):** `remotion-docs`(查 Remotion 文档)、`remotion-app`(操作 Remotion 项目)。
- **会话级(来自你机器的全局配置 / 插件,不在仓库里):** context7、github、playwright、chrome-devtools、figma、computer-use,以及 claude.ai 的 Canva / Hugging Face / PDF Viewer / Scholar Gateway / Tavily 连接器。

---

## 四、Hooks(4 个,wired 在 settings.json)

一个时机一个钩子:

1. **session-start.sh**(SessionStart,开会话)— 引导本地配置 + 注入仓库规则 + 压缩快照恢复。
2. **task-orchestrator-hook.sh**(UserPromptSubmit,你发消息)— 判断意图(分析/写代码/纯问)+ 列出该用的 skill(读 skill-rules.json)+ 提示词含糊时提醒先澄清 + auth 类提示 `/security-review`。
3. **post-edit-check.sh**(PostToolUse 改文件)— 按文件类型跑检查:TS/JS 跑 tsc,Python 跑 pyright/ruff,其它跑对应 linter,并记录改动文件。
4. **workflow-completion-gate.sh**(Stop,答完)— 改了前端就提醒做浏览器验证 + 清 14 天前的过期缓存。

> 另有两个 gitignore、但仍在用的辅助脚本:`git-guard.sh`(拦 commit/push,audit 冒烟测试依赖它)、`session-rules-reinject.sh`(压缩恢复时重注规则)。不要删。

---

## 五、Plugins(6 个,enabledPlugins)

`pyright-lsp`、`typescript-lsp`(语言服务/类型检查)、`frontend-design`(更强 UI 实现)、`feature-dev`(代码探索/架构 agent)、`code-review`(定向审查)、`code-simplifier`(清理简化)。

---

## 六、重复 / 冲突(重点)

功能重叠太多时 AI 容易选错,以下是最该注意的几组:

1. **"写一整篇论文"三套并存**:`paper-spine`(12 个)、`academic-paper` + `academic-pipeline`、`nature-writing`/`research-paper-writing`。**主推 `academic-pipeline`**(研究→写→审一条龙,已设为常驻),其余按需。
2. **科研/示意图四个重叠**:`nature-figure` 和 `scientific-figure-making`(科研数据图)、`fireworks-tech-graph` 和 `diagram-design`(架构/示意图)。各留一个即可。
3. **审稿两个**:`academic-paper-reviewer` 与 `nature-reviewer`。
4. **学术 PPT 两个**:`nature-paper2ppt` 与 `office-academic-skill`。
5. **深度研究两个**:`deep-research`(更全)与 `aiq-research`。
6. **泛化设计五个**:`frontend-design`/`impeccable`/`ui-ux-pro-max`/`design-taste-frontend`/`high-end-visual-design` 都是"把 UI 做好看",高度重叠。常驻其实留 1 个就够。
7. **shadcn 两个**:`shadcn-ui` 与 `ui-styling` 都涉及 shadcn + Tailwind。
8. **风格 skill 互斥审美**:`minimalist-ui`(极简)、`industrial-brutalist-ui`(粗野)、`gpt-taste`(动效)只在选定风格时用。
9. **浏览器/QA 重叠**:`chrome-devtools`/`playwright`/`webapp-testing` 都驱动浏览器;`qa`/`qa-only`/`design-review`/`web-design-guidelines` 都沾 QA/审查。不冲突但冗余。
10. **互补不冲突(放心)**:`nature-citation`(加引用)vs `citation-check-skill`(查引用)是两回事,留着都对。

---

## 七、维护与技术备注

- 改了 skill / command / hook / 模板的数量后,要同步更新 `README.md` 的计数(audit 会校验),并跑 `bash scripts/audit-workflow.sh` 和 `bash scripts/doctor-workflow.sh` 确认全绿。
- 这套 harness 的"常驻 vs 按需"完全由 `skills/skill-rules.json` 的 `alwaysActive` 决定,改那个 JSON 就改了行为,不用动 hook。
- **Source vs Runtime**:跟踪的是 `.claude/CLAUDE*.md`、`hooks/`、`commands/`、`prompt-templates/`、`agents/`、`skills/`、`settings.json`;gitignore 的是 `plugins/`、`projects/`、`.claude/runtime/`、`.claude.json`、`settings.local.json`。`skills/ui-styling/canvas-fonts/` 是设计工作流的一部分,有意纳入跟踪。
- **可选插件**:对鉴权敏感、重复或依赖机器环境的集成,应在 `.claude/settings.local.json` 里启用,而不是放进共享的跟踪配置。
- **`effortLevel` 语义**:`settings.json` 里的 `max` 只在当前会话生效,除非同时在 `env` 里设 `CLAUDE_CODE_EFFORT_LEVEL`。两者都设才把意图和持久化绑定。参见 https://code.claude.com/docs/en/model-config#adjust-effort-level
- **流式与思考**:思考预算超过 32K token 时 Anthropic 建议用批处理。Claude Code 是交互式流式,所以把 `MAX_THINKING_TOKENS` 控制在 32000 以内,避免长思考阶段 `Stream idle timeout`。参见 https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
