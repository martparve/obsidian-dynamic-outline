# Factory

This project uses the Code Factory workflow. See `factory/CLAUDE.md` for full documentation.

### Resolving Backlog Items

```bash
./factory/resolve <item_id>    # or: ./factory/resolve --next
```

After the agent completes:

```bash
./factory/complete <item_id>
```

**Rules:**
- Never compose agent prompts manually. `./factory/resolve` output IS the prompt.
- Never skip `./factory/complete`. It tracks progress and prevents drift.
- Only use factory-defined agents from `factory/agents/`.
- Max 3 parallel agents.
- If a factory script fails, errors, or produces unexpected output: STOP. Report the exact error to the user. Never work around it, improvise a manual alternative, or attempt to fix the factory scripts inline. Factory bugs are fixed upstream.
