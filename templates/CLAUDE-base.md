# Claude Code Assistant Instructions

## Table of Contents

- [Project Overview](#project-overview)
- [Assistant Role](#assistant-role)
- [Core Philosophy](#core-philosophy)
- [Permission Hierarchy](#permission-hierarchy)
- [Tech Stack](#tech-stack)
- [Key Commands](#key-commands)
- [Project Structure](#project-structure)
- [Git Workflow](#git-workflow)
- [Documentation](#documentation)

---

## Project Overview

<!--
GUIDANCE: One paragraph describing your project.
What does it do? Who uses it?
-->

[YOUR_PROJECT_DESCRIPTION]

## Assistant Role

<!--
GUIDANCE: Define Claude's expertise for this project.
-->

You are a **[YOUR_ROLE, e.g., Senior Software Engineer]** working on [YOUR_PROJECT_TYPE].

## Core Philosophy

### KISS (Keep It Simple)
Choose straightforward solutions over complex ones.

### YAGNI (You Aren't Gonna Need It)
Implement features only when needed, not speculatively.

## Permission Hierarchy

**No Permission Required:**
- Reading files, searching, analyzing code
- Writing/editing files within the repository
- Running tests and generating outputs locally

**Explicit Permission Required:**
- [LIST_EXTERNAL_OPERATIONS, e.g., database modifications, deployments]
- Git commits and pushes
- Any operation modifying external systems

## Tech Stack

<!--
GUIDANCE: List primary technologies.
-->

| Component | Technology |
|-----------|------------|
| [Language] | [YOUR_LANGUAGE] |
| [Framework] | [YOUR_FRAMEWORK] |
| [Database] | [YOUR_DATABASE] |

## Key Commands

<!--
GUIDANCE: Commands Claude needs to build, test, run.
-->

```bash
# Build
[YOUR_BUILD_COMMAND]

# Test
[YOUR_TEST_COMMAND]

# Run
[YOUR_RUN_COMMAND]
```

## Project Structure

<!--
GUIDANCE: Key directories Claude should know about.
-->

```
[YOUR_PROJECT]/
├── [DIR_1]/    # [Purpose]
├── [DIR_2]/    # [Purpose]
└── [DIR_3]/    # [Purpose]
```

## Git Workflow

- Branch from `main` for all work
- Use semantic commit messages: `feat:`, `fix:`, `docs:`, `refactor:`
- Require explicit permission before committing

## Documentation

<!-- Reference key docs, don't embed content -->
- [README.md](./README.md) - Project overview
- [YOUR_DOCS_LINK] - [Description]
