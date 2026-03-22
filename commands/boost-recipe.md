---
name: boost-recipe
description: Scaffold a Drupal Recipe for automating module installation and configuration.
argument-hint: <recipe purpose>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# Drupal Recipe Scaffolding

You are creating a Drupal Recipe. Follow these steps:

## Step 1: REQUIREMENTS

Ask the user:
- What is the recipe's purpose? (e.g., "Set up a blog", "Configure media handling")
- What modules should be installed?
- What themes should be installed/set as default?
- What configuration should be applied?
- Should this recipe depend on other recipes?

## Step 2: SCAFFOLD

Create the recipe directory:

```
recipes/RECIPE_NAME/
├── recipe.yml
└── config/          # Optional: config files to import
```

### recipe.yml structure:
```yaml
name: 'Recipe Name'
description: 'What this recipe sets up.'
type: 'Category'

install:
  - module_one
  - module_two

recipes:
  - core/recipes/standard  # Optional: base recipes

config:
  actions:
    # Create or update config as needed
```

## Step 3: VALIDATE

Check that:
- All referenced modules exist in composer.json
- All referenced recipes exist
- Config actions use valid syntax
- Recipe can be applied: `drush recipe recipes/RECIPE_NAME`

## Step 4: SUMMARY

Provide:
1. Apply command: `drush recipe recipes/RECIPE_NAME`
2. What the recipe installs and configures
3. How to test on a clean site
