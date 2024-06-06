#!/usr/bin/env python

import os
from pathlib import Path
from natsort import natsorted

PROJECT_ROOT = Path(__file__).resolve().parents[1]

def get_files(folder_path: Path=PROJECT_ROOT):
    markdown_files = [file for file in folder_path.glob('*.md')]
    return natsorted(markdown_files)


def main():

     with open(f"{PROJECT_ROOT / 'index.md'}", 'w') as index_file:
        index_file.write(f"# Index")

        for item in ["Recipes", "Ingredients", "Equipments"]:
            folder_path = PROJECT_ROOT / item if item != "Recipes" else PROJECT_ROOT
            markdown_files = get_files(folder_path)
            index_file.write(f"\n\n## {item}\n\n")
                
            for file in markdown_files:
                if file.stem in ["index", "README"]:
                    continue
                
                index_file.write(f"- [[{file.stem}]]\n")


if __name__ == '__main__':
    main()
