# Recipes

This repository is a receipe book developed in [Obsidian](https://www.obsidian.md).

# Installing Quartz

## Generating Static Site with Quartz

To see a full explanation on how to setup Quartz use [1](https://notes.nicolevanderhoeven.com/How+to+publish+Obsidian+notes+with+Quartz+on+GitHub+Pages) or [2](https://quartz.jzhao.xyz/).

### 1. Clone quartz into the `/home` folder: 
```bash
git clone https://github.com/jackyzha0/quartz.git
```

### 2. CD into `/home/quartz` and run
```bash
npm i
``` 
to install node dependencies.

### 3. Initialize quartz with 
```bash
npx quartz create
```

#### 3.1. You are then asked to choose between three different methods of initializing the content in your directory: 
```
- Empty Quartz
- Copy an existing folder
- Symlink an existing folder
```
Select `Symlink an existing folder` and use the **full path** (i.e. `/home/recipes`) to the Obsidian vault.

#### 3.2. You should then see something like this:
```
Choose how Quartz should resolve links in your content. You can change this later in `quartz.config.ts`.
- Treat links as absolute path
- Treat links as shortest path
- Treat links as relative paths
```
What you select here is dependent on how you prefer to handle links in Obsidian. By default, Obsidian uses the shortest path where possible.

### 4. Link the GitHub repository

#### 4.1. Remove the `origin` of the Quartz repository by using
```bash
git remote rm origin
```

#### 4.2. Add the link to this repository with 
```bash
git remote add origin git@github.com:hsteinshiromoto/recipes.git
```
#### 4.3. Sync the changes with 
```bash
npx quartz sync --no-pull
```
### 5. After all the changes have been done, sync them with 
```bash
npx quartz sync
```
### 6. Serve locally with
```bash
npx quartz build --serve
```

## Updating Site with New Notes

1. In the folder `/workspace/quartz` run
```bash
npx quartz sync --no-pull
```
2. When the command finishes, run
```bash
npx quartz sync
```
