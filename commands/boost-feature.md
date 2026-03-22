---
name: boost-feature
description: Full 7-phase feature development workflow for Drupal 11 with parallel agents for exploration, architecture, and review. The flagship command for building features the right way.
argument-hint: <feature description>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, TodoWrite, AskUserQuestion
---

# Drupal 11 Feature Development Workflow

You are running the drupal-boost feature development workflow. Follow these 7 phases strictly. Use TodoWrite to track progress through each phase.

## Phase 1: DISCOVERY

Gather requirements from the user. Ask clarifying questions:
- What is the feature's purpose?
- Who are the target users/roles?
- What existing Drupal features does it interact with?
- Are there performance requirements?
- Are there accessibility requirements?

Do NOT proceed until you have a clear understanding of what to build.

## Phase 2: EXPLORATION

Launch 2 `drupal-explorer` agents IN PARALLEL to analyze the codebase:

**Agent 1**: Explore existing code that the feature will interact with — services, entities, routes, hooks, and templates relevant to the feature area.

**Agent 2**: Explore existing patterns and conventions in the project — coding style, module structure, naming conventions, testing patterns, and CLAUDE.md guidelines.

Wait for both agents to complete. Synthesize their findings.

## Phase 3: CLARIFYING QUESTIONS

Based on exploration findings, present what you learned and ask the user any remaining questions:
- Technical constraints discovered
- Existing patterns that should be followed
- Decision points that need user input (e.g., "Should this be a config entity or content entity?")

## Phase 4: ARCHITECTURE DESIGN

Launch 2-3 `drupal-architect` agents IN PARALLEL, each proposing a different approach:

**Agent 1 — Minimal**: Simplest implementation with fewest files. Trade-off: may not scale.

**Agent 2 — Clean**: Well-architected with proper separation of concerns. Trade-off: more files, more complexity.

**Agent 3 — Pragmatic** (optional): Middle ground that balances simplicity and architecture.

Present all approaches to the user with trade-offs. Let them choose or combine.

## Phase 5: IMPLEMENTATION

Build the chosen approach:
1. Create module scaffolding (`.info.yml`, `.services.yml`, `.routing.yml`)
2. Implement core classes (entities, services, controllers, forms)
3. Add configuration schema
4. Create templates if needed
5. Add permissions and menu links
6. Write initial tests

Follow all Drupal 11 best practices:
- Dependency injection everywhere in `src/`
- OOP Hook attributes (Drupal 11.1+)
- Cache metadata on all render arrays
- `accessCheck(TRUE)` on all entity queries
- PSR-4 namespaces

## Phase 6: QUALITY REVIEW

Launch 2 agents IN PARALLEL:

**`drupal-reviewer`**: Reviews all created/modified code for:
- Drupal coding standards compliance
- Proper DI patterns
- Deprecated API usage
- Cache metadata completeness
- Access control correctness

**`drupal-security-auditor`**: Audits all created/modified code for:
- XSS vulnerabilities
- SQL injection
- Access bypass
- CSRF issues
- Input validation

Fix any critical or high-severity issues found.

## Phase 7: SUMMARY

Present a summary:
1. **Files created/modified** — list with brief description of each
2. **Architecture decisions** — key choices made and why
3. **Next steps** — what the developer should do next:
   - Enable the module: `drush en MODULE_NAME`
   - Run tests: `ddev exec ./vendor/bin/phpunit -c web/core web/modules/custom/MODULE_NAME/`
   - Export config: `drush cex`
   - Review and test manually
4. **Known limitations** — anything that should be addressed later
