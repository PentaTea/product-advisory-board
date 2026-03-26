# Product Advisory Board (PAB)

**You don't need another AI to tell you "great idea!" — you need a room full of experts who disagree with each other.**

---

## What is this?

Product Advisory Board is a **multi-agent protocol** for Claude Code that simulates a board of physically isolated AI advisors debating your product decisions. Each advisor runs as an independent subagent with its own context window — they literally cannot see each other's work until the Facilitator synthesizes their outputs.

This isn't prompt engineering. It's **process engineering** — a 5-phase protocol with strict sequencing, file-driven information flow, mandatory red-teaming, and a complete audit trail. Every intermediate artifact is written to disk before the next phase begins.

The output is not "AI-generated advice." It's a **structured decision brief** with consensus points, named disagreements, pressure-tested assumptions, and a clear list of what _you_ still need to decide.

## Quick Start

### 1. Install

**Option A — Local Claude Code plugin (recommended):**

```bash
git clone https://github.com/PentaTea/product-advisory-board.git
cd product-advisory-board
claude --plugin-dir .
```

This loads PAB directly from the cloned directory as a session-local Claude Code plugin. Claude Code auto-discovers the plugin's default `skills/` and `agents/` directories, so the skill and subagents become available together.

> Marketplace install is **not** available yet. A public GitHub repo alone cannot be installed with `claude plugin install` until the plugin is published in a configured marketplace.

**Option B — skills.sh + manual agents:**

```bash
npx skills add PentaTea/product-advisory-board        # installs skill
git clone https://github.com/PentaTea/product-advisory-board.git /tmp/pab
cp /tmp/pab/agents/pab-*.md .claude/agents/            # agents need manual copy
```

> `npx skills add` only handles `skills/`. Agent definitions need a separate copy.

**Option C — Install script:**

```bash
git clone https://github.com/PentaTea/product-advisory-board.git /tmp/pab
cd /path/to/your-project
/tmp/pab/install.sh           # project-level into /path/to/your-project/.claude/
/tmp/pab/install.sh --global  # or user-level (~/.claude/)
```

**Cursor / Codex:** Option A is Claude Code only. Cursor 2.4+ reads `.claude/agents/` natively, so use Options B/C there. Codex uses TOML format for agent definitions (conversion needed).

### 2. Trigger it in Claude Code

If you launched PAB with `claude --plugin-dir`, use the namespaced skill:

```
> /product-advisory-board:product-advisory-board Should we pivot from B2B to B2C for our AI writing assistant?
```

If you installed it by copying files into `.claude/skills/` and `.claude/agents/` (Options B/C), use the standalone skill name:

```
> /product-advisory-board Should we pivot from B2B to B2C for our AI writing assistant?
```

Or use natural language:

```
> 产品顾问团，讨论一下我们要不要做 freemium 模式
> Let's get the advisory board's take on our pricing strategy
```

After installation or launch, open `/agents` and confirm the PAB agents are visible:

- Local plugin mode (`claude --plugin-dir`): `product-advisory-board:pab-scout`, `product-advisory-board:pab-red-team`, and the other PAB agents
- Standalone `.claude/` install: `pab-scout`, `pab-red-team`, and the other `pab-*` agents

### 3. Read the decision brief

The final output lands in `docs/pab-session-{timestamp}/40-decision-brief.md` — a structured document with consensus points, named disagreements, a risk table from the Red Team, unverified assumptions, blind spots, and a clear "decisions you still need to make" section.

## Why existing PM tools fall short

We surveyed 7 popular AI product management repos. Here's the pattern:

| Approach                  | What they do                                        | The problem                                                                                                       |
| ------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Single-prompt PM**      | One big prompt with "think like a PM"               | One context = one perspective. No real tension, no real disagreement.                                             |
| **Role-play prompts**     | "First think as a designer, then as an engineer..." | Same LLM, same context window. The "engineer" already read what the "designer" said — anchoring bias is baked in. |
| **Template collections**  | PRD templates, user story templates, etc.           | Templates structure _output_, not _thinking_. Garbage in, formatted garbage out.                                  |
| **Chat-based brainstorm** | Multi-turn conversation playing different roles     | Earlier messages anchor later ones. By message #5, the LLM is just agreeing with itself.                          |

**The core issue:** These approaches confuse _format_ with _process_. Making an LLM write in a "Product Strategist" format doesn't give you a strategist's independent judgment — it gives you one model's opinion wearing different hats.

PAB solves this with **physical isolation**: each advisor is a separate `Agent()` call with its own context window, its own role definition file, and zero access to other advisors' outputs.

## Architecture

### The Five-Phase Protocol

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

### The Report Chain (Full Audit Trail)

Every phase writes files before moving on. Nothing lives only in memory.

```
docs/pab-session-{timestamp}/
├── 00-context.md                  ← User input, structured
├── 00-topic-analysis.md           ← Team composition + Scout results
├── 01-scout-report.md             ← External expert matching
├── 02-expert-{nn}-{name}.md      ← Domain intelligence from external experts
├── 03-brief-{role}.md            ← Thin briefs (pointers, not content)
├── 10-insight-{role}.md          ← Independent advisor analyses
├── 20-synthesis.md                ← Consensus / conflicts / blind spots
├── 30-debate-{topic}-pro.md      ← Pro arguments (raw)
├── 30-debate-{topic}-con.md      ← Con arguments (raw)
├── 30-debate-{topic}.md          ← Merged debate record
├── 30-redteam-final.md           ← Red Team pressure test
├── 40-decision-brief.md          ← Final decision brief
└── README.md                     ← Report index
```

## Design Principles

### 1. Physical isolation > Role-playing

Most multi-persona prompts run inside a single context window. The "engineer" has already read the "designer's" analysis — anchoring bias is unavoidable.

PAB uses Claude Code's `Agent()` tool to spawn each advisor as a **separate subagent**. Each one gets:

- Its own context window (clean slate)
- Its own role definition (loaded via `subagent_type`, not pasted into prompt)
- Only the files it's told to read (via `<files_to_read>` blocks)

This is not a stylistic choice. It's an **architectural guarantee** against groupthink.

### 2. File-driven, zero hearsay

The Facilitator is a **dispatcher, not a messenger**. Information flows through files, never through prompt paraphrasing:

```
❌  Facilitator reads content → embeds summary in subagent prompt (telephone game)
✅  Facilitator writes content to file → tells subagent which file to read (pointer)
```

Why this matters: every time an LLM paraphrases information, it loses nuance, injects interpretation, and drifts from the source. File-driven flow preserves the original signal.

### 3. Mandatory adversarial thinking

Red Team is not optional — it's selected for **every single session**, regardless of topic type. When all advisors agree (zero directional conflicts), the protocol triggers **Consensus Pressure Testing** instead of skipping debate:

- What shared assumptions are unverified?
- Under what conditions would this consensus collapse?
- Is there an Elephant in the room nobody wants to name?

The system is designed to make "everyone agrees" the _most_ suspicious outcome.

### 4. Full audit chain

Every intermediate artifact is persisted to disk. This means:

- You can review _how_ the board reached its conclusions, not just _what_ they concluded
- You can re-run individual phases with different inputs
- You can share the full deliberation record with your team
- Months later, you can trace back _why_ a decision was made

## Agent Roster

### 8 Core Advisors

| Role                      | File                        | Perspective                                    | Thinking Frameworks                                          |
| ------------------------- | --------------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| **User Advocate**         | `pab-user-advocate.md`      | User pain, JTBD, adoption barriers             | Jobs-to-Be-Done, Mom Test, Journey Mapping                   |
| **Product Strategist**    | `pab-product-strategist.md` | Market positioning, moats, timing              | Moore's Positioning, Porter's 5 Forces, Focus vs. Diffusion  |
| **Growth Analyst**        | `pab-growth-analyst.md`     | Metrics, unit economics, flywheels             | North Star Metric, LTV/CAC, Growth Flywheel                  |
| **Tech Advisor**          | `pab-tech-advisor.md`       | Feasibility, architecture, build cost          | Feasibility Matrix, Tech Debt, Build vs Buy, MVP Scoping     |
| **Red Team Challenger**   | `pab-red-team.md`           | Devil's advocate, pre-mortem, assumptions      | Pre-mortem, Tigers/Paper Tigers/Elephants, 2nd-order effects |
| **Design Thinker**        | `pab-design-thinker.md`     | UX patterns, IA, interaction design            | Nielsen Heuristics, FTUE, Progressive Disclosure, AI UX      |
| **Business Model Expert** | `pab-business-model.md`     | Pricing, monetization, GTM                     | Business Model Canvas, Pricing Strategy, GTM Playbook        |
| **Industry Observer**     | `pab-industry-observer.md`  | Trends, cross-industry analogies, weak signals | Trend Analysis, Time Machine Analogies, First Principles     |

### Scout Agent

The **Scout** (`pab-scout.md`) is a specialized reconnaissance agent that runs _before_ the core advisors. It scans the [agency-agents](https://github.com/msitarzewski/agency-agents) repository (144 roles) and matches 0-3 external domain experts relevant to the current topic. Selection criteria are strict: only experts that cover knowledge gaps the core advisors can't fill.

### External Expert System

When the Scout identifies relevant domain experts:

1. Each expert fetches its role definition from GitHub via `WebFetch`
2. Reads the structured topic context from `00-context.md`
3. Produces a domain intelligence report (`02-expert-{name}.md`)
4. This intelligence is then made available to core advisors via their briefs

This gives PAB dynamic access to 144+ specialized perspectives without bloating the core team.

## Comparison with Other Approaches

| Capability                        | Single PM Prompt | Role-Play Prompt | Template Pack |         **PAB**         |
| --------------------------------- | :--------------: | :--------------: | :-----------: | :---------------------: |
| Multiple independent perspectives |        -         |    Simulated     |       -       | **Physically isolated** |
| Protection against anchoring bias |        -         |        -         |       -       |    **Architectural**    |
| Mandatory adversarial challenge   |        -         |     Optional     |       -       | **Red Team always on**  |
| External domain experts           |        -         |        -         |       -       | **144 roles via Scout** |
| Structured debate on conflicts    |        -         |        -         |       -       | **Pro/Con + Red Team**  |
| Full audit trail                  |        -         |        -         |       -       |   **File per phase**    |
| Reproducible process              |        -         |        -         |    Partial    |  **5-phase protocol**   |
| Consensus pressure testing        |        -         |        -         |       -       |   **Auto-triggered**    |
| Works without custom infra        |       N/A        |       N/A        |      N/A      | **Claude Code native**  |

## How It Works: Information Flow

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

**Key rule:** Arrows labeled "reads" mean the agent uses the `Read` tool itself. The Facilitator never reads a file and pastes its content into another agent's prompt. Information integrity is preserved because every agent reads the source file directly.

## Customization

### Adding a new core advisor

1. **Create the agent definition** at `.claude/agents/pab-{your-role}.md`:

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

2. **Define the thinking frameworks** — each advisor needs 3-5 named analytical frameworks that guide its analysis. These aren't decorative; they're what make the output structured and repeatable.

3. **Define the output format** — a strict template with sections like "Core Stance", "Key Arguments (3-5)", "Risks & Concerns", "Key Assumptions", and "Recommended Next Steps".

4. **Add behavioral constraints** — what this advisor should and shouldn't comment on. Narrow scope = higher quality output. A Tech Advisor that also opines on business models dilutes both perspectives.

5. **Register in SKILL.md** — add the role to the advisor table and the topic-type routing matrix.

### Adjusting team composition

The default team for each topic type is defined in SKILL.md's Phase 0 routing table:

```markdown
| Topic Type       | Default Team                                                      |
| ---------------- | ----------------------------------------------------------------- |
| Product Strategy | Product Strategist + User Advocate + Industry Observer + Red Team |
| Feature Design   | User Advocate + Design Thinker + Tech Advisor + Red Team          |
| Monetization     | Business Model + Growth Analyst + User Advocate + Red Team        |
```

Edit this table to change defaults. The only hard rule: **Red Team is always included**.

### Changing the external expert source

The Scout currently pulls from [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) (144 roles). To use a different role library:

1. Update the WebFetch URL in `pab-scout.md`
2. Adjust the parsing logic in Step 2 of the Scout's execution steps

## FAQ

**Q: How many API calls does a full session make?**
A: Minimum ~8 (Scout + 3 advisors + synthesis + 2 debaters + Red Team), maximum ~16 (Scout + 3 experts + 5 advisors + synthesis + 4 debaters + Red Team). Each is a separate `Agent()` invocation.

**Q: Can I run this with models other than Claude?**
A: PAB is built on Claude Code's `Agent()` tool and `subagent_type` parameter. It's designed for Claude's agent infrastructure specifically. The protocol itself (file-driven isolation, phased deliberation) is model-agnostic in concept, but the implementation is Claude Code native.

**Q: What if an agent fails?**
A: The protocol includes explicit error handling: retry once, then mark as "did not participate (agent failure)" and continue. The synthesis phase notes the missing perspective. No single agent failure blocks the entire session.

**Q: Is the Red Team just a contrarian?**
A: No. The Red Team uses structured frameworks — pre-mortem analysis, Tigers/Paper Tigers/Elephants classification, second-order effects. It must produce at least 3 specific risks with evidence and mitigation strategies. "Everything looks risky" is as useless as "everything looks fine."

**Q: Why files instead of passing data through prompts?**
A: Three reasons. (1) **Fidelity** — LLMs lose nuance when paraphrasing; files preserve the original. (2) **Auditability** — you can inspect exactly what each agent saw. (3) **Debuggability** — when an agent produces a bad output, you can check its input files to understand why.

---

## License

AGPL 3.0
