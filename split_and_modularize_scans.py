import os
import re
from pathlib import Path
from collections import defaultdict

INPUT_FILE = "main.tf"
MODULES_DIR = "modules"

# Match full google_dataplex_datascan resource blocks
RESOURCE_BLOCK_RE = re.compile(
    r'(resource\s+"google_dataplex_datascan"\s+"[^"]+"\s*\{(?:[^{}]*|\{[^{}]*\})*\})',
    re.DOTALL
)

# Extract schema and table from the data.resource field
DATA_RESOURCE_RE = re.compile(
    r'resource\s*=\s*"//bigquery\.googleapis\.com/projects/[^/]+/datasets/(?P<schema>[^/]+)/tables/(?P<table>[^"]+)"'
)

def extract_blocks_from_lines(lines):
    blocks = []
    current_block = []
    inside_block = False
    brace_level = 0

    for line in lines:
        if not inside_block and 'resource "google_dataplex_datascan"' in line:
            inside_block = True
            brace_level = 0
            current_block = [line]
            brace_level += line.count("{") - line.count("}")
        elif inside_block:
            current_block.append(line)
            brace_level += line.count("{") - line.count("}")
            if brace_level == 0:
                blocks.append("".join(current_block))
                inside_block = False
    return blocks

def extract_schema_table(block):
    match = DATA_RESOURCE_RE.search(block)
    if not match:
        return None, None
    return match.group("schema"), match.group("table")

def format_block(block):
    lines = block.strip().split("\n")
    formatted = []
    indent_level = 0
    for line in lines:
        line = line.strip()
        if "}" in line:
            indent_level -= 1
        formatted.append("  " * indent_level + line)
        if "{" in line and not line.startswith("#"):
            indent_level += 1
    return "\n".join(formatted) + "\n\n"

def write_block_to_module(schema, table, block):
    dir_path = Path(MODULES_DIR) / schema
    dir_path.mkdir(parents=True, exist_ok=True)
    file_path = dir_path / f"{table}.tf"
    with open(file_path, "a") as f:
        f.write(format_block(block))

def remove_blocks_from_main(original_content, blocks_to_remove):
    for block in blocks_to_remove:
        original_content = original_content.replace(block, "")
    return original_content.strip() + "\n"

def generate_module_block(schema):
    return f'''
module "{schema}" {{
  source = "./modules/{schema}"
}}
'''.strip()

def insert_module_blocks(main_content, schemas_used):
    existing_modules = set(re.findall(r'module\s+"([^"]+)"\s+\{', main_content))
    module_blocks = [generate_module_block(schema) for schema in sorted(schemas_used) if schema not in existing_modules]

    if module_blocks:
        return main_content.strip() + "\n\n" + "\n\n".join(module_blocks) + "\n"
    else:
        return main_content

def main():
    with open(INPUT_FILE, "r") as f:
        lines = f.readlines()
        original_content = "".join(lines)

    blocks = extract_blocks_from_lines(lines)
    print(f"🔍 Found {len(blocks)} scan resource blocks.")

    moved_blocks = []
    used_schemas = set()

    for block in blocks:
        schema, table = extract_schema_table(block)
        if not schema or not table:
            print("⚠️ Skipping a block (no valid schema/table).")
            continue
        write_block_to_module(schema, table, block)
        moved_blocks.append(block)
        used_schemas.add(schema)

    # Remove scanned blocks
    updated_main = remove_blocks_from_main(original_content, moved_blocks)

    # Inject module declarations
    updated_main = insert_module_blocks(updated_main, used_schemas)

    with open(INPUT_FILE, "w") as f:
        f.write(updated_main)

    print(f"✅ Finished. Scans moved to `modules/`, `main.tf` updated with module declarations.")

if __name__ == "__main__":
    main()
