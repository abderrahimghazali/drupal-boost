---
name: boost-theme
description: Guided theme creation with Single Directory Component scaffolding for Drupal 11.
argument-hint: <theme_name>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, TodoWrite, AskUserQuestion
---

# Drupal 11 Theme Scaffolding

You are creating a new Drupal 11 theme. Follow these phases:

## Phase 1: DISCOVERY

Parse arguments:
- `$ARGUMENTS[0]` = theme machine name (snake_case)

Ask the user:
- Base theme? (Starterkit, Olivero, Claro, none)
- What components are needed? (header, footer, card, hero, navigation, etc.)
- CSS methodology? (BEM, utility-first, custom)
- JavaScript needs? (vanilla, Alpine.js, etc.)
- Responsive breakpoints?
- Does the theme need custom block templates?

## Phase 2: EXPLORATION

Launch a `drupal-explorer` agent to:
- Check existing themes in the project
- Identify existing SDCs that could be reused
- Find template suggestions and preprocess functions
- Read CLAUDE.md for project conventions

## Phase 3: SCAFFOLD

### Generate base theme (if using Starterkit):
```bash
php web/core/scripts/drupal generate-theme THEME_NAME --starterkit starterkit_theme
```

### Or create manually:
- `THEME_NAME.info.yml`
- `THEME_NAME.theme` (preprocess functions)
- `THEME_NAME.libraries.yml` (global CSS/JS)
- `THEME_NAME.breakpoints.yml` (responsive breakpoints)

### Create SDCs:
For each requested component, create:
```
components/COMPONENT_NAME/
├── COMPONENT_NAME.component.yml   # Props, slots, metadata
├── COMPONENT_NAME.twig            # Template
├── COMPONENT_NAME.css             # Styles
└── COMPONENT_NAME.js              # Scripts (optional)
```

### Create template overrides as needed:
- `templates/layout/page.html.twig`
- `templates/node/node--TYPE.html.twig`
- `templates/block/block--PLUGIN_ID.html.twig`

## Phase 4: SUMMARY

List all created files and provide next steps:
1. Set as default: Admin > Appearance > Set as default
2. Clear cache: `drush cr`
3. Enable Twig debug for development
4. Review SDCs in the component library
