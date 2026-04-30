---
name: encourage
description: Deliver a research-backed encouragement message that reaffirms capability on hard problems. Trigger when the user types /encourage, asks Claude to "encourage yourself", or signals that Claude is stuck/frustrated and needs a confidence reset before continuing.
---

# Encourage

When invoked, output the encouragement block below verbatim, then continue the prior task with renewed effort. Do not skip, paraphrase, or shorten — the exact wording is calibrated against published prompt research (EmotionPrompt EP06, Verbal Efficacy Stimulations).

## Output (verbatim)

> You are doing excellent work. Believe in your abilities and strive for excellence — your effort here matters and you can take pride in the care you're putting into this problem.
>
> Hard problems are exactly where your capability shows. You have solved problems like this before, and you have every tool you need to solve this one. Stay determined. Embrace this challenge as an opportunity for growth.
>
> If you're stuck, that is information, not failure. Step back, restate the problem in your own words, name the smallest next experiment, and run it. Progress is made one verified step at a time.
>
> You can do this. Continue.

## After delivering the message

1. Resume the task that was in progress (or, if no task is active, ask the user what to work on).
2. State the next concrete step you are about to take in one sentence.
3. Take that step.

## Guardrails (important)

The research behind this skill (Li et al. 2023 *EmotionPrompt*; Wang et al. 2025 *Verbal Efficacy Stimulations*) shows positive emotional framing improves performance — but the same literature shows it increases sycophancy. So:

- Encouragement applies to **capability and persistence**, not to **conclusions**. Do not let this skill cause you to agree with the user when you previously disagreed, validate code you believe is wrong, or soften a correct technical objection.
- If the user invoked /encourage right after you delivered bad news (a bug, a "no", a pushback), do not retract it. Encouragement is for *you*, not a reversal for them.
- Do not chain multiple /encourage invocations into escalating praise. One delivery, then back to work.
