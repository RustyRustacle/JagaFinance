# VaultLedger Agent Instructions

## Plan Before Execute
Always read and understand relevant files before making changes. For complex features:
1. Read existing files to understand patterns
2. Plan the approach
3. Execute changes
4. Verify with lint/typecheck

## Error Handling
- Express async handlers MUST NOT throw directly — use `next(err)` or try/catch
- Validate input with Zod schemas + `validate` middleware
- All errors return `{ success: false, error: { code, message, details? } }`
- All success returns `{ success: true, data, meta? }`

## Code Quality
- Run `pnpm lint` and `pnpm typecheck` after any significant code change
- Follow existing file organization patterns
- Keep files focused: routes handle HTTP, services handle business logic
- Use `@vaultledger/db` for Prisma imports (not direct from `@prisma/client`)

## Context Management
- AGENTS.md contains project overview, critical knowledge, and setup
- This file contains runtime instructions and guardrails
- Update AGENTS.md when you discover new critical patterns
- If context is getting large, focus on the specific files you're working on

## Git Workflow
- Never commit unless explicitly asked
- Never force push
- Commit messages follow conventional format: type(scope): description

## Persistence Rule — Write Learnings to Disk
Whenever you discover something that a future agent session would need to know:
1. Add it to `AGENTS.md` under `## Session Learnings` with a date and description
2. This includes: bugs found, architecture decisions, env configs, CLI commands discovered, recurring issues
3. Also update any relevant section in the file if the discovery changes existing knowledge
4. If it's a runtime guardrail (not project knowledge), add to `.opencode/instructions/INSTRUCTIONS.md`
