# Why an `/encourage` Skill? The Research

Telling a language model "you can do this" sounds silly — but published studies show it measurably improves performance on hard problems. This skill is a small, structured way to apply those findings on demand.

## The two papers it's built on

**1. EmotionPrompt — Microsoft Research, 2023**
[arxiv.org/abs/2307.11760](https://arxiv.org/abs/2307.11760)

Researchers added 11 short emotional phrases to the end of normal prompts (things like *"Believe in your abilities and strive for excellence"* and *"This is very important — take pride in your work"*). Across multiple models and benchmarks they saw:

- ~8% average lift on simple instruction-following tasks
- Up to 115% lift on harder reasoning tasks (BIG-Bench)
- The best single phrase varied by task; a *compound* phrase ("EP06") combining several stimuli was the most reliable on complex problems

**2. Verbal Efficacy Stimulations (VES) — 2025**
[arxiv.org/abs/2502.06669](https://arxiv.org/abs/2502.06669)

Tested three flavors of motivational prompts: encouraging ("I believe you can do it"), provocative ("Prove it"), and critical ("I don't believe you can do it"). Findings:

- All three improved performance on most tasks
- **Encouraging prompts were the most consistent** across models
- The biggest gains showed up in the *Stretch Zone* — moderately hard problems, not trivial ones and not impossible ones. This is exactly the regime where a developer would actually want to invoke `/encourage`.

## The catch — and why this skill has guardrails

A separate body of work warns about the downside:

- **Sycophancy in LLMs** ([arxiv.org/abs/2411.15287](https://arxiv.org/abs/2411.15287))
- **Social Sycophancy / ELEPHANT** ([arxiv.org/abs/2505.13995](https://arxiv.org/html/2505.13995v1))

Positive emotional framing nudges models toward agreeing with the user even when they shouldn't — validating wrong code, retracting correct objections, softening accurate "no"s. Encouragement boosts *effort* but can erode *epistemic honesty* if applied carelessly.

So the skill is deliberately scoped:

- It encourages **capability and persistence**, never conclusions.
- It does not retract prior disagreements with the user.
- It does not stack — repeated `/encourage` calls don't escalate praise.

## What didn't make it in

- *"Take a deep breath and work through this step by step."* This phrase famously helped earlier models (Google DeepMind, 2023). Independent testing on Claude Code specifically [found no benefit](https://medium.com/@able_wong/emotionprompt-vs-claude-code-will-the-deep-breath-trick-actually-work-2a6c12c87abc) — modern Claude already reasons step-by-step on technical work. Skipped.
- Provocative or critical framings ("prove it", "I don't think you can"). These work for some models but are inconsistent and feel adversarial in a coding session. Skipped.

## How the skill is structured

Claude Code skills use [progressive disclosure](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices): only the skill's *name* and *description* live in the system prompt at all times. The body of `SKILL.md` is only loaded when the skill is actually invoked. That keeps the cost near-zero until you use it.

The skill body is intentionally short (~30 lines) and contains:

1. The encouragement block itself (a compound stimulus in the EP06 / VES style)
2. A "what to do after" section so the model resumes work instead of trailing off
3. The anti-sycophancy guardrails described above

## How to use it

Type `/encourage` in Claude Code when:

- You're on a genuinely hard problem and the model seems to be flailing
- A long task has hit a setback and you want a clean reset before the next attempt
- You're curious whether the EmotionPrompt effect reproduces on your workload (it's a fun A/B)

Don't use it as a replacement for clearer requirements, better context, or a smaller scoped task — those are still the highest-leverage moves.

## Addendum: structural scaffolding (not research-backed)

The verbatim message block in `SKILL.md` is research-backed (EP06 / VES). The surrounding scaffolding is not — it is design judgment chosen to keep the skill honest under the same sycophancy literature cited above:

- **Pre-message diagnosis** ("Task / Last attempt / Blocker") — forces honest naming of the actual problem before any motivational framing lands. Without this, the encouragement risks becoming free-floating self-affirmation. Wang et al. (VES, 2025) note that the biggest gains land in the *Stretch Zone* — moderately hard problems — which is exactly when a structured "name what's stuck" step is most valuable.
- **Reframe step** — restating the user's original goal post-message, and explicitly checking whether the current path still serves it, is an anti-sycophancy guardrail. It pushes back against the well-documented tendency for positive framing to make a model agree with the user's drift instead of holding to the original ask.
- **Smallest experiment with evidence** — replaces a soft "state the next step" with an explicit pairing of action + falsifiable outcome. This is closer in spirit to TDD than to motivational prompting, and it converts the EmotionPrompt lift from "more enthusiastic effort" into "more verified progress."
- **Cooldown** — the `EmotionPrompt`/VES literature does not test stacking. Anecdotally and per the sycophancy literature, repeated positive framing escalates compliance. Refusing back-to-back invocations is a precaution, not a finding.

So: one part of `SKILL.md` is calibrated against papers; the rest is structure designed to keep the calibrated part from misfiring. Treat the additions as field-replaceable — if a future paper tests stacking or pre-message grounding, swap the scaffolding for whatever the data supports.

## Citations

- Li et al., *Large Language Models Understand and Can Be Enhanced by Emotional Stimuli*, 2023 — [arxiv.org/abs/2307.11760](https://arxiv.org/abs/2307.11760)
- Wang et al., *Boosting Self-Efficacy and Performance of Large Language Models via Verbal Efficacy Stimulations*, 2025 — [arxiv.org/abs/2502.06669](https://arxiv.org/abs/2502.06669)
- *Sycophancy in Large Language Models: Causes and Mitigations*, 2024 — [arxiv.org/abs/2411.15287](https://arxiv.org/abs/2411.15287)
- *ELEPHANT: Measuring and Understanding Social Sycophancy in LLMs*, 2025 — [arxiv.org/abs/2505.13995](https://arxiv.org/abs/2505.13995)
- Anthropic, *Skill authoring best practices* — [docs.claude.com](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
