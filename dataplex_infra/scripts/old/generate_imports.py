import subprocess
import json
import re

# Configuration
PROJECT_ID = "ferrous-cipher-432403-j0"
LOCATION = "us-central1"
TF_FILE = "imported_scans.tf"
IMPORT_SCRIPT = "import_commands.sh"

def check_gcloud_auth():
    """Ensure gcloud is authenticated with at least one account."""
    try:
        result = subprocess.run(
            ["gcloud", "auth", "list", "--format=json"],
            capture_output=True, text=True, check=True
        )
        accounts = json.loads(result.stdout)
        if not accounts:
            raise RuntimeError("🚫 No authenticated gcloud accounts found.")
        print(f"🔐 Authenticated as: {accounts[0]['account']}")
    except subprocess.CalledProcessError as e:
        print("❌ Failed to check gcloud auth. Is gcloud installed and initialized?")
        raise

def sanitize(name):
    """Make scan ID safe for Terraform resource names."""
    return re.sub(r'[^a-zA-Z0-9_]', '_', name.lower())

def list_scans(project, location):
    """Use gcloud to list all existing Dataplex scans."""
    cmd = [
        "gcloud", "dataplex", "datascans", "list",
        f"--project={project}", f"--location={location}",
        "--format=json"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)

def generate_stub(resource_name):
    """Return a Terraform stub block."""
    return f'resource "google_dataplex_datascan" "{resource_name}" {{\n  # configuration will be populated after import\n}}\n\n'

def generate_import_cmd(scan_id, resource_name, project, location):
    """Return terraform import command for the scan."""
    full_id = f"projects/{project}/locations/{location}/dataScans/{scan_id}"
    return f'terraform import google_dataplex_datascan.{resource_name} "{full_id}"\n'

def write_outputs(scans):
    with open(TF_FILE, "w") as tf_out, open(IMPORT_SCRIPT, "w") as sh_out:
        for scan in scans:
            scan_id = scan["name"].split("/")[-1]
            resource_name = sanitize(scan_id)
            tf_out.write(generate_stub(resource_name))
            sh_out.write(generate_import_cmd(scan_id, resource_name, PROJECT_ID, LOCATION))

def main():
    check_gcloud_auth()
    print("🔍 Listing existing Dataplex scans...")
    scans = list_scans(PROJECT_ID, LOCATION)
    print(f"✅ Found {len(scans)} scans. Generating Terraform stubs and import commands...")
    write_outputs(scans)
    print(f"📄 Wrote Terraform to `{TF_FILE}` and import commands to `{IMPORT_SCRIPT}`.")

if __name__ == "__main__":
    main()
