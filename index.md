---
alias: 
tags: 
status:
date created: Friday, 1st March 2024, 22:33:58
---

# Recipe Book

## Recipe Index

```dataview
LIST
FROM -"Ingredients" AND -"Equipments" AND -"_meta_" AND -"index" AND -"README"
SORT file.name ASC
```

## Ingredient Index

```dataview
LIST
FROM "Ingredients"
SORT file.name ASC
```