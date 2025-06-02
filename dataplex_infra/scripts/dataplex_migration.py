import subprocess
import json
import re
import os
from pathlib import Path
import datetime
import shutil

# We use the current time as a filename to avoid name conflicts
START_TIME = datetime.datetime.now()

IMPORT_PROJECT_ID = "ferrous-cipher-prod"
EXPORT_PROJECT_ID = "ferrous-cipher-432403-j0"
LOCATION = "us-central1"
TF_FILE = f"{START_TIME}_imported_scans.tf"
IMPORT_SCRIPT = f"{START_TIME}_import_commands.sh"
MOVED_SCANS_FILE =  f"{START_TIME}_moved_scans.json"
RAW_STATE_FILE = f"{START_TIME}_full_imported_config.tf"
MAIN_FILE = "main.tf"
MODULES_DIR = "modules"


RESOURCE_TYPES = {
    "google_dataplex_datascan": {
        "FIELDS_TO_REMOVE": [
            "id",
            "name",
            "uid",
            "state",
            "create_time",
            "update_time",
            "type",
            "terraform_labels",
            "effective_labels",
            "execution_status",
        ]
    },
    "google_storage_bucket":{
        "FIELDS_TO_REMOVE":[
            "self_link",
            "url",
            "effective_labels",
            "id",
            "project_number",
            "terraform_labels",
            "soft_delete_policy",
            "time_created",
            "updated",
        ]
    }
}

# ---------- STEP 1: GCLOUD AUTH / TERRAFORM INIT ----------
def move_to_correct_directory():
    script_dir = Path(__file__).resolve().parent.parent
    os.chdir(script_dir)

    print("Changed working directory to script location (should be dataplex_infra, otherwise abort): ", Path.cwd())


def check_gcloud_auth():
    print("🔐 Checking gcloud auth...")
    result = subprocess.run(["gcloud", "auth", "list", "--format=json"], capture_output=True, text=True, check=True)
    accounts = json.loads(result.stdout)
    if not accounts:
        raise RuntimeError("🚫 No authenticated gcloud accounts found.")
    print(f"✅ Authenticated as: {accounts[0]['account']}")
    input("🔎 Press Enter to continue...")


def initialize_dev_terraform():
    print("Initializing Terraform dev instance locally...")
    
    result = subprocess.run(["terraform", "init", "-backend-config=backend-dev.tfbackend", "-reconfigure"], capture_output=True, text=True, check=True)
    
    # if not accounts:
    #     raise RuntimeError("🚫 Terraform init failed.")
    print(f"✅ Terraform init succeeded.")
    input("🔎 Press Enter to continue...")


def initializations():
    move_to_correct_directory()


# ---------- STEP 2: GENERATE IMPORT FILES ----------
def sanitize(name):
    return re.sub(r'[^a-zA-Z0-9-]', '-', name.lower())


def list_scans(project, location):
    print("📡 Listing Dataplex scans...")
    cmd = ["gcloud", "dataplex", "datascans", "list", f"--project={project}", f"--location={location}", "--format=json"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def get_existing_state_resources():
    result = subprocess.run(["terraform", "state", "list"], capture_output=True, text=True)
    state_entries = result.stdout.strip().split("\n")
    resources = set()
    for entry in state_entries:

        # This regex matches dataplex datascans at top level, as well as those in modules
        match = re.match(r"(?:.*\.)?google_dataplex_datascan\.([^.]+)$", entry)
        if match:
            resources.add(match.group(1))
    return resources


def generate_import_files(scans):
    existing_state = get_existing_state_resources()

    sanitized_scans = []
    sanitized_scan_ids = set()

    # For tracking which scans need a command to move terraform state into module (will be equal to list of new scans)
    moved_scans = []

    for scan in scans:
        scan_id = scan["name"].split("/")[-1]
        resource_name = sanitize(scan_id)
        full_id = scan["name"]
        sanitized_scans.append((resource_name, full_id))
        sanitized_scan_ids.add(resource_name)

    added = 0
    skipped = 0
    removed = 0

    with open(TF_FILE, "w") as tf_out, open(IMPORT_SCRIPT, "w") as sh_out:
        for resource_name, full_id in sanitized_scans:
            if resource_name in existing_state:
                print(f"⚠️ Skipping existing scan: {resource_name}")
                skipped += 1
                continue

            print(f"➕ Adding new scan: {resource_name}")
            tf_out.write(f'resource "google_dataplex_datascan" "{resource_name}" {{\n  # configuration will be populated after import\n}}\n\n')
            sh_out.write(f'terraform import google_dataplex_datascan.{resource_name} \"{full_id}\"\n')
            added += 1
            moved_scans.append(resource_name)

        for resource_name in existing_state:
            if resource_name not in sanitized_scan_ids:
                print(f"❌ Scheduling state removal: {resource_name}")
                sh_out.write(f'terraform state rm google_dataplex_datascan.{resource_name}\n')
                removed += 1
    
    with open(MOVED_SCANS_FILE, "w") as f:
        json.dump(moved_scans, f)

    print(f"✅ Terraform state sync complete. {skipped} skipped, {added} imports written, {removed} removals written to `{IMPORT_SCRIPT}`.")
    input("📥 Press Enter to continue with import/removal of terraform state...")


# ---------- STEP 3: RUN IMPORTS ----------

def run_imports():
    with open(IMPORT_SCRIPT, "r") as script_file:
        for line in script_file:
            line = line.strip()
            if not line or line.startswith("#"): continue

            print(f"📦 Importing: {line}")
            result = subprocess.run(line, shell=True)
            if result.returncode != 0:
                print(f"⚠️ Import failed, skipping: {line}")
                continue
    
    # Delete the import script and import TF after cleaning
    os.remove(IMPORT_SCRIPT)  
    os.remove(TF_FILE)
    print(f"Deleted`{IMPORT_SCRIPT}` and `{TF_FILE}`.")

    # Run Terraform refresh to see if there are changes in any other scans
    print("Refreshing Terraform state..")
    subprocess.run("terraform refresh", shell=True, capture_output=True, text=True)

    # Only call terraform show once, after all imports
    print("📄 Running final terraform show to capture full state...")
    result = subprocess.run("terraform show -no-color", shell=True, capture_output=True, text=True)
    with open(RAW_STATE_FILE, "w") as output:
        output.write(result.stdout)

    print(f"📦 Final Terraform state saved to `{RAW_STATE_FILE}`.")
    input("🧹 Press Enter to clean Terraform file...")


# ---------- STEP 4: TRANSFORM STATE FILE INTO CONFIG ----------
def is_resource_start(line, resource_type):
    pattern = rf'^\s*resource\s+"{re.escape(resource_type)}"\s+"[^"]+"\s*{{'
    return re.match(pattern, line)


def extract_key(line):
    line = line.strip()

    # 1. Match key-value (name = "value")
    kv_match = re.match(r'^(?!#)(?:("[^"]+")|([^\s=]+))\s*=.*', line)
    if kv_match:
        return kv_match.group(1) or kv_match.group(2)

    # 2. Match block header (key { or key = {)
    block_match = re.match(r'^([a-zA-Z0-9_]+)\s*(=)?\s*{', line)
    if block_match:
        return block_match.group(1)

    return None


def count_braces(line):
    # Count braces for nesting level tracking
    open_count = line.count('{') + line.count('[')
    close_count = line.count('}') + line.count(']')
    return open_count, close_count


# Used for the ${data()} construction in Dataplex SQL assertion rules: https://cloud.google.com/dataplex/docs/auto-data-quality-overview#data-reference-parameter
# If we put ${data()} into Terraform config, it thinks this is a variable it should look for. We want to escape it so Terraform ignores it, but Dataplex can read it
def escape_data_reference_parameter(text):
    # Replace ' ${data()}' with ' $${data()}'
    return re.sub(r'\s\${data\(\)}', r' $${data()}', text)


def replace_project_reference(text):
    return text.replace(IMPORT_PROJECT_ID, EXPORT_PROJECT_ID)


def clean_lines(lines):
    output = []
    current_resource = None
    nesting = 0
    inside_block_to_remove = False

    for line in lines:
        # Skip comments in TF config
        if line.strip().startswith("#"):
            continue
        
        # Properly escape character, and replace import project name with export project name
        line = escape_data_reference_parameter(line)
        line = replace_project_reference(line)

        # Detect entry into a dataplex scan resource
        if current_resource is None:
            for res in RESOURCE_TYPES:
                if is_resource_start(line, res):
                    current_resource = res
                    nesting = 1
                    break
           
            # append to output, skip to next line
            output.append(line)
            continue

        open_b, close_b = count_braces(line)
        new_nesting = nesting + open_b - close_b

        # If we're at depth 1 (directly inside resource block)
        if nesting == 1:
            key = extract_key(line)
            if key in RESOURCE_TYPES[current_resource]["FIELDS_TO_REMOVE"]:
                if new_nesting > 1:
                    inside_block_to_remove = True
                
                nesting = new_nesting
                continue
        
        nesting = new_nesting
        if inside_block_to_remove:
            if new_nesting == 1:
                inside_block_to_remove = False
            continue


        # End of the resource
        if nesting < 1:
            current_resource = None
            output.append(line)
            continue
        

        output.append(line)
        continue
    return output



def clean_state_file():
    with open(RAW_STATE_FILE, "r") as f:
        lines = f.readlines()

    cleaned = clean_lines(lines)

    with open(MAIN_FILE, "w") as f:
        f.writelines(cleaned)

    os.remove(RAW_STATE_FILE)  # Delete the raw state file after cleaning
    print(f"🧼 Cleaned config saved to `{MAIN_FILE}` and deleted `{RAW_STATE_FILE}`.")
    input("📁 Press Enter to modularize scans by table...")


# ---------- STEP 5: SPLIT BY SCHEMA/TABLE ----------

# useful for getting schema and table from data resource url
DATA_RESOURCE_RE = re.compile(
    r'resource\s*=\s*"//bigquery\.googleapis\.com/projects/[^/]+/datasets/(?P<schema>[^/]+)/tables/(?P<table>[^"]+)"'
)

# useful for getting scan_id from resource
SCAN_ID_RE = re.compile(r'\bdata_scan_id\s*=\s*"(?P<scan_id>[^"]+)"')

def extract_blocks(lines):
    blocks = []
    current_block = []
    inside = False
    level = 0
    for line in lines:
        if not inside and 'resource "google_dataplex_datascan"' in line:
            inside = True
            current_block = [line]
            level = line.count("{") - line.count("}")
        elif inside:
            current_block.append(line)
            level += line.count("{") - line.count("}")
            if level <= 0:
                blocks.append("".join(current_block))
                inside = False
    return blocks


def extract_schema_table(block):
    match = DATA_RESOURCE_RE.search(block)
    return (match.group("schema"), match.group("table")) if match else (None, None)


def extract_scan_id(block):
    match = SCAN_ID_RE.search(block)
    return match.group("scan_id") if match else None


def extract_scan_metadata(block):
    scan_id = extract_scan_id(block)
    schema, table = extract_schema_table(block)
    return scan_id, schema, table


def format_block(block):
    lines = block.strip().split("\n")
    formatted = []
    indent = 0
    for line in lines:
        line = line.strip()
        if "}" in line:
            indent -= 1
        formatted.append("  " * indent + line)
        if "{" in line and not line.startswith("#"):
            indent += 1
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
    

def reset_modules_dir():
    modules_path = Path(MODULES_DIR)
    if modules_path.exists():
        print(f"🧹 Removing existing modules folder: {MODULES_DIR}")
        shutil.rmtree(modules_path)
    modules_path.mkdir(parents=True, exist_ok=True)
    print(f"✅ Created fresh modules folder: {MODULES_DIR}")


def modularize_scans():
    with open(MAIN_FILE, "r") as f:
        lines = f.readlines()
        original_content = "".join(lines)

    blocks = extract_blocks(lines)
    print(f"🔍 Found {len(blocks)} scan resource blocks.")

    # Clear out old modules directory first
    reset_modules_dir()

    moved_blocks = []
    used_schemas = set()
    # Get list of scans that need terraform state moved to module
    with open(MOVED_SCANS_FILE, 'r') as f:
        scans_needing_state_moved = json.load(f)

    for block in blocks:
        scan_id, schema, table = extract_scan_metadata(block)
        if not schema or not table:
            print("⚠️ Skipping a block (no valid schema/table).")
            continue
        write_block_to_module(schema, table, block)

        # Check if we need to move block in terraform state
        if not scan_id:
            print("⚠️ Did not find scan_id")
            continue
        
        if scan_id in scans_needing_state_moved:
            old_path = f"google_dataplex_datascan.{scan_id}"
            new_path = f"module.{schema}.google_dataplex_datascan.{scan_id}"
            print(f"🔀 Moving state: {old_path} → {new_path}")
            subprocess.run(["terraform", "state", "mv", old_path, new_path], check=True)               
        
        moved_blocks.append(block)
        used_schemas.add(schema)

    # Remove scanned blocks
    updated_main = remove_blocks_from_main(original_content, moved_blocks)

    # Inject module declarations
    updated_main = insert_module_blocks(updated_main, used_schemas)

    # Remove MOVED_SCANS_FILE
    os.remove(MOVED_SCANS_FILE)

    with open(MAIN_FILE, "w") as f:
        f.write(updated_main)
    print(f"✅ Modularization complete. Check `modules/` and updated `{MAIN_FILE}`.")


# ---------- MAIN ----------
def main():
    move_to_correct_directory()
    check_gcloud_auth()
    initialize_dev_terraform()
    scans = list_scans(IMPORT_PROJECT_ID, LOCATION)
    generate_import_files(scans)
    run_imports()
    clean_state_file()
    modularize_scans()


if __name__ == "__main__":
    main()
