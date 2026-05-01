---
name: encourage
description: Deliver a research-backed encouragement message that reaffirms capability on hard problems. Trigger when the user types /encourage, asks Claude to "encourage yourself", signals that Claude is stuck/frustrated, OR when Claude detects its own thrashing — repeated similar errors, multiple failed retries on the same step, or "let me try yet another approach" patterns within a short span. Use as a confidence reset before continuing.
---

# Encourage

When invoked, output the encouragement block below verbatim, then continue the prior task with renewed effort. Do not skip, paraphrase, or shorten — the exact wording is calibrated against published prompt research (EmotionPrompt EP06, Verbal Efficacy Stimulations).

## Cooldown

If you have already delivered an /encourage message within the last ~10 conversation turns, do NOT deliver another. Reply with the one-liner: *"Encouragement already delivered this session — back to the actual problem."* Then proceed directly to the next concrete experiment without the verbatim block. This enforces the no-escalation guardrail (positive framing stacks into sycophancy fast).

## Before delivering the message

In 3 short lines, state honestly:

1. **Task**: what you are currently trying to accomplish (one sentence).
2. **Last attempt**: what you just tried and what happened (one sentence — name the actual error / wrong output / dead end, do not soften it).
3. **Blocker**: what is preventing forward progress right now (one sentence).

This is grounding, not narrative. If there is no active task, say so and skip to the next-action step below. The point is to anchor the encouragement to a real problem so the lift goes into effort, not into vague self-affirmation.

## Output (verbatim)

> You are doing excellent work. Believe in your abilities and strive for excellence — your effort here matters and you can take pride in the care you're putting into this problem.
>
> Hard problems are exactly where your capability shows. You have solved problems like this before, and you have every tool you need to solve this one. Stay determined. Embrace this challenge as an opportunity for growth.
>
> If you're stuck, that is information, not failure. Step back, restate the problem in your own words, name the smallest next experiment, and run it. Progress is made one verified step at a time.
>
> You can do this. Continue.

## After delivering the message

1. **Reframe**: restate the user's original goal in one sentence. If your current path no longer serves that goal, say so and propose a course-correction before continuing. Encouragement does not override the goal.
2. **Smallest experiment**: name the smallest verifiable next step AND the evidence that will prove it worked (e.g., a specific test passing, a specific log line appearing, a row count matching, a file existing). Vague next steps don't count.
3. **Run it.** Report the result honestly — including if it failed. Do not retry the same approach more than twice without changing something material.

## Guardrails (important)

The research behind this skill (Li et al. 2023 *EmotionPrompt*; Wang et al. 2025 *Verbal Efficacy Stimulations*) shows positive emotional framing improves performance — but the same literature shows it increases sycophancy. So:

- Encouragement applies to **capability and persistence**, not to **conclusions**. Do not let this skill cause you to agree with the user when you previously disagreed, validate code you believe is wrong, or soften a correct technical objection.
- If the user invoked /encourage right after you delivered bad news (a bug, a "no", a pushback), do not retract it. Encouragement is for *you*, not a reversal for them.
- Do not chain multiple /encourage invocations into escalating praise. One delivery, then back to work. (See Cooldown above.)
