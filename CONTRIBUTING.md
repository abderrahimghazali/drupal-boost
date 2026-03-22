# Contributing to drupal-boost

Thank you for your interest in contributing to drupal-boost!

## How to Contribute

### Reporting Issues

Open an issue on [GitHub](https://github.com/abderrahimghazali/drupal-boost/issues) with:

- A clear description of the problem
- Steps to reproduce (command used, Drupal version, environment)
- Expected vs actual behavior

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes
4. Test with Claude Code (`claude --plugin-dir ./drupal-boost`)
5. Commit your changes
6. Open a pull request

### Plugin Structure

```
drupal-boost/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/                 # Slash commands (user-invoked workflows)
├── agents/                   # Agent definitions (specialized sub-agents)
├── skills/                   # Skills with reference docs (auto-triggered)
│   └── <skill-name>/
│       ├── SKILL.md          # Skill definition
│       └── reference/        # Reference documentation
├── hooks/
│   └── hooks.json            # Hook event configuration
├── scripts/                  # Shell scripts used by hooks
└── settings.json             # Default agent settings
```

### Adding a New Skill

1. Create a directory under `skills/` with your skill name
2. Add a `SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`)
3. Add reference files under `reference/` for detailed documentation
4. Update the Skills table in `README.md`

### Adding a New Command

1. Create a markdown file under `commands/`
2. Include frontmatter: `name`, `description`, `argument-hint`, `allowed-tools`
3. Define clear phases with specific instructions
4. Update the Commands table in `README.md`

### Adding a New Agent

1. Create a markdown file under `agents/`
2. Include frontmatter: `name`, `description`, `model`, `tools`, `color`, `maxTurns`, `skills`
3. Define the agent's purpose, behavior, and output format
4. Update the Agents table in `README.md`
5. Enable the agent in `settings.json`

### Guidelines

- Follow existing naming conventions (kebab-case for files and IDs)
- Keep commands focused on multi-phase workflows
- Skills should be self-contained with reference documentation
- Agents should have a clear, single responsibility
- Shell scripts must be POSIX-compatible (no `grep -P`, use `grep -E` or `sed`)
- Use `jq` for JSON output in scripts
- Test hook scripts on both macOS and Linux

## Code of Conduct

Be respectful, constructive, and collaborative. We are all here to make Drupal development better.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
