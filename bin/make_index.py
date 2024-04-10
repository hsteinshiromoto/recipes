#!/usr/bin/env python

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

def generate_index_markdown(folder_path: Path=PROJECT_ROOT):
    markdown_files = [file for file in folder_path.glob('*.md')]

    with open(f"{folder_path / 'index.md'}", 'w') as index_file:
        index_file.write("# Index\n\n")
        index_file.write("## Recipes\n\n")
        for file in markdown_files:

            if file.name in ('index.md', 'README.md'):
                continue
            index_file.write(f"- [[{file.name}]]\n")

if __name__ == '__main__':
    generate_index_markdown()
