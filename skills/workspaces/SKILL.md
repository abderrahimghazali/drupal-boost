---
name: workspaces
description: Drupal Workspaces module for content staging, parallel workspaces, and batch publishing. Use when setting up content staging workflows or implementing editorial workflows with Workspaces.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Drupal Workspaces

The Workspaces module provides content staging — make changes in a workspace without affecting the live site, then publish everything at once.

## Enable Workspaces

```bash
drush en workspaces -y
```

## Core Concepts

- **Live workspace** — The default workspace. Content here is visible on the live site.
- **Custom workspaces** — Staging areas where content can be drafted, reviewed, and published as a batch.
- **Publishing** — Moves all workspace changes to the Live workspace.

## Setup

### Create a Workspace
1. Go to Admin > Content > Workspaces
2. Click "Add workspace"
3. Set name, parent (optional), and permissions

### Via Drush
```bash
drush ev "\Drupal::entityTypeManager()->getStorage('workspace')->create(['id' => 'staging', 'label' => 'Staging'])->save();"
```

### Switch Workspaces
Use the workspace switcher toolbar or:
```bash
drush ev "\Drupal::service('workspaces.manager')->setActiveWorkspace(\Drupal::entityTypeManager()->getStorage('workspace')->load('staging'));"
```

## Publishing Workflow

1. Switch to workspace (e.g., "Staging")
2. Create/edit content — changes only visible in the workspace
3. Review changes in the workspace
4. Click "Publish" to push all changes to Live

## Workspace-Aware Code

### Check Active Workspace
```php
$workspaceManager = \Drupal::service('workspaces.manager');
if ($workspaceManager->hasActiveWorkspace()) {
  $workspace = $workspaceManager->getActiveWorkspace();
  $workspace_id = $workspace->id();
}
```

### Execute Outside Workspace Context
```php
$workspaceManager->executeOutsideWorkspace(function () {
  // Code here runs in the Live workspace context
});
```

## Permissions

- `administer workspaces` — Full workspace administration
- `create workspace` — Create new workspaces
- `edit own workspace` — Edit workspaces you created
- `edit any workspace` — Edit all workspaces
- `delete own workspace` — Delete workspaces you created
- `delete any workspace` — Delete all workspaces
- `view own workspace` — View workspaces you created
- `view any workspace` — View all workspaces

## Limitations

- Not all entity types support workspaces (nodes, taxonomy terms, and menu links do)
- Custom entity types need `workspace` entity key to support workspaces
- Config changes are NOT workspace-aware — they apply globally
- Some contrib modules may not be workspace-compatible

## Key Rules

- Use workspaces for content staging, not config changes
- Always test workspace publishing on a staging environment first
- Check workspace compatibility of contrib modules before relying on them
- Use `executeOutsideWorkspace()` when you need to read/write live content from workspace context
- Plan your editorial workflow before setting up workspaces (who creates, who reviews, who publishes)
