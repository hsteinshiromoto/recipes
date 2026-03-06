# Implementation Plan: Custom Claude Code Agents for Recipe Vault

## Overview

Create 3 custom Claude Code agents in `.claude/agents/` that form a meal-planning pipeline:

```
User -> maitre (gather requirements) -> chef (plan meals) -> shopping-assistant (find prices)
```

**Coordination**: The maitre is the main orchestrator. It uses the `Task` tool to spawn the chef and shopping-assistant as sub-agents automatically. The full pipeline runs from a single `/agents:maitre` invocation.

## Steps

1. Create directory: `mkdir -p .claude/agents/`
2. Create `maitre.md`
3. Create `chef.md`
4. Create `shopping-assistant.md`

---

## Agent 1: Maitre (`maitre.md`)

**Role**: Gather user requirements via 4 questions with defaults, produce a structured Requirements Brief.

**Tools declared**: `Read, Grep, Glob, Task` (read-only + orchestration)

### Questions (with defaults)

1. How many people? (default: 2 adults + 1 child)
2. Single meal or weekly plan? (default: weekly)
3. Average cook time per dish? (default: 30 min)
4. Dietary requirements? (default: low fat, high protein)

### Requirements Brief (internal format passed to chef)

```markdown
## Requirements Brief
- **People**: 2 adults, 1 child
- **Plan type**: weekly
- **Max cook time**: 30 min
- **Dietary**: low fat, high protein
- **Week starting**: YYYY-MM-DD
- **Vault recipes available**: N
```

### Orchestration Flow

After gathering requirements, the maitre:
1. Spawns the **chef** agent via `Task` tool (subagent_type: `chef`) with the Requirements Brief as the prompt
2. Receives the meal plan file path back from the chef
3. Spawns the **shopping-assistant** agent via `Task` tool (subagent_type: `shopping-assistant`) with the meal plan path as the prompt
4. Presents the final summary to the user with links to both output files

---

## Agent 2: Chef (`chef.md`)

**Role**: Receive requirements, search existing recipes, plan meals, create new recipes, save meal plan.

**Tools declared**: `Read, Grep, Glob, Write, Edit, WebFetch`

Also uses MCP tools (automatically available):
- `mcp__mcp-obsidian__obsidian_list_files_in_vault`
- `mcp__mcp-obsidian__obsidian_get_file_contents`
- `mcp__mcp-obsidian__obsidian_simple_search`
- `mcp__mcp-obsidian__obsidian_append_content`

### Recipe Metadata Parsing Strategy

The vault has inconsistent metadata formats. The chef must check both:
- YAML frontmatter keys: `serves`, `cooking_time`, `prepartion_time` (note: typo in vault)
- Inline Dataview notation: `serves::`, `cooking_time::`, `preparation_time::`

Canonical format for **new** recipes follows the template at `_meta_/_templates_/Recipe.md`:
```markdown
---
tags:
alias:
---

author::
cooking_time:: [mins]
preparation_time:: [mins]
serves:: [int]
source::
status::
# Recipe Title

## Ingredients
- [ ] [[ingredient]]

## Equipment

## Instructions

## References
```

### New Ingredient File Format

When creating new ingredients in `Ingredients/`, follow the template:
```markdown
---
alias: [name, alternate-name]
season: [autumn, winter, spring, summer]
---
related_ingredients::
```

### Meal Plan Output Format

Saved to `plans/YYYY-WNN/meal-plan.md`:

```markdown
---
tags: [meal-plan]
title: "Meal Plan YYYY-WNN"
servings: "2 adults + 1 child"
dietary: "low fat, high protein"
max_cook_time: "30 min"
---

# Meal Plan YYYY-WNN

## Monday YYYY-MM-DD

### Breakfast
- [[Recipe Name]] (serves X, cook: Y min)

### Morning Snack
- Description or [[Recipe Name]]

### Lunch
- [[Recipe Name]] (serves X, cook: Y min)
  - Notes: uses leftover from ...

### Afternoon Snack
- Description or [[Recipe Name]]

### Dinner
- [[Recipe Name]] (serves X, cook: Y min)

## Tuesday YYYY-MM-DD
...

## Ingredient Summary

### Produce
- [ ] [[ingredient]] - quantity

### Protein
- [ ] [[ingredient]] - quantity

### Dairy
- [ ] [[ingredient]] - quantity

### Pantry
- [ ] [[ingredient]] - quantity

### Other
- [ ] [[ingredient]] - quantity

## Prep Strategy
- Sunday: batch cook X, prep Y
- Notes on leftovers reuse
```

### Planning Goals (priority order)

1. Strictly follow dietary requirements
2. Maximize nutrient diversity
3. Minimize waste (reuse leftovers across meals)
4. Keep individual cook time under max
5. Maximize cuisine diversity
6. Use "base dish + variations" strategy

---

## Agent 3: Shopping Assistant (`shopping-assistant.md`)

**Role**: Parse ingredient list from meal plan, look up prices, produce optimized shopping lists.

**Tools declared**: `Read, Grep, Glob, WebFetch`

Also uses MCP tools (automatically available):
- `mcp__mcp-obsidian__obsidian_get_file_contents`
- `mcp__mcp-obsidian__obsidian_append_content`

### Price Lookup Strategy

Price lookup is **best-effort**. Many supermarket sites are JS-heavy and may not return data via WebFetch.

**Primary approach**: Use Google/DuckDuckGo to search for prices:
- `https://www.google.com/search?q=INGREDIENT+price+site:coles.com.au`
- `https://duckduckgo.com/?q=INGREDIENT+price+coles`

**Direct site search** (may fail for JS-rendered pages):
- `https://www.coles.com.au/search?q=INGREDIENT`
- `https://www.woolworths.com.au/shop/search/products?searchTerm=INGREDIENT`
- `https://www.aldi.com.au/search/?text=INGREDIENT`

**Aggregator fallbacks**:
- `https://www.frugl.com.au` (price comparison)
- `https://www.pricehipster.com` (price tracking)

**Degradation**: If no price found, mark as "price not available" and still include the item in the shopping list with quantity.

### Shopping List Output Format

Saved to `plans/YYYY-WNN/shopping-list.md`:

```markdown
---
tags: [shopping-list]
title: "Shopping List YYYY-WNN"
meal_plan: "[[plans/YYYY-WNN/meal-plan]]"
---

# Shopping List YYYY-WNN

> Generated from [[plans/YYYY-WNN/meal-plan|Meal Plan YYYY-WNN]]
> Prices fetched: YYYY-MM-DD

## Strategy A: Split Shopping (Cheapest Overall)

**Estimated Total: $XXX.XX**

### Aldi
- [ ] Item - $X.XX (unit: $Y.YY/kg)
**Subtotal: $XX.XX**

### Coles
- [ ] Item - $X.XX
**Subtotal: $XX.XX**

### Woolworths
- [ ] Item - $X.XX
**Subtotal: $XX.XX**

## Strategy B: Single Supermarket (Fewest Trips)

| Store       | Total   | vs Split     |
|-------------|---------|--------------|
| Aldi        | $XXX.XX | +$X.XX (+X%) |
| Coles       | $XXX.XX | +$X.XX (+X%) |
| Woolworths  | $XXX.XX | +$X.XX (+X%) |

**Recommendation:** [Store] at $XXX.XX

### Full [Store] List
- [ ] Item - $X.XX
...

## Notes
- Items not found: [list]
- Items with estimated prices: [list]
- Prices are approximate and may vary by location
```

---

## Output File Locations

```
plans/
  YYYY-WNN/
    meal-plan.md        # Created by Chef
    shopping-list.md    # Created by Shopping Assistant
```

New recipes go in vault root. New ingredients go in `Ingredients/`.
The `plans/YYYY-WNN/` subdirectory is created by the chef agent when writing the meal plan.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Supermarket sites JS-heavy, WebFetch fails | Google/DuckDuckGo search as primary; aggregators as fallback; graceful "price not available" |
| Inconsistent recipe metadata in vault | Chef parses both YAML frontmatter and inline `::` notation |
| New recipes/ingredients don't match vault conventions | Use exact templates from `_meta_/_templates_/` |
| `plans/` subdirectory doesn't exist | Agent creates it via `obsidian_append_content` (auto-creates path) |
| Ingredient quantities in mixed units | Chef normalizes to metric in ingredient summary |
