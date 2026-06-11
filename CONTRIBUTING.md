# Contributing to batagor

## Branching Strategy

We use **trunk-based development**. All work merges into `main` via short-lived feature branches. Branches should live for no more than a few days — if a branch is growing large, break it into smaller PRs.

## Branch Naming

| Prefix | Use for |
|--------|---------|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Non-functional changes (deps, config, docs) |

Example: `fix/deletion-background-interval`

## Pull Requests

- Link the related GitHub issue in the PR description (e.g. `Closes #22`)
- Keep scope small — one issue per PR
- Test on a physical device before requesting review (simulator cannot test camera or location)
- PRs must target `main`

**PR checklist:**
- [ ] Tested on device
- [ ] No debug code or leftover `print` statements
- [ ] Both `batagor` and `widget` targets build without warnings if widget-related code was touched
- [ ] `WidgetCenter.shared.reloadAllTimelines()` called if media data was modified

## Labels

| Label | When to use |
|-------|-------------|
| `bug` | Something is broken |
| `feature` | New capability |
| `improvement` | Enhancement to existing behavior |
| `documentation` | Docs and contributor guides |
| `testing` | Unit or integration tests |
| `area: camera` | Camera capture flow |
| `area: gallery` | Gallery and media browsing |
| `area: widget` | Home screen widget |
| `area: deletion` | Auto-deletion and cleanup |
