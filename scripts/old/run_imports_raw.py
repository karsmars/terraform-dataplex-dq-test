import subprocess
import re
from pathlib import Path

IMPORT_SCRIPT = "import_commands.sh"
OUTPUT_FILE = "full_imported_config.tf"


def run_command(cmd):
    print(f"▶️ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Error: {result.stderr.strip()}")
    return result


def main():
    if not Path(IMPORT_SCRIPT).exists():
        print(f"❌ File not found: {IMPORT_SCRIPT}")
        return

    with open(IMPORT_SCRIPT, "r") as script_file, open(OUTPUT_FILE, "w") as output:
        for line in script_file:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # Run the terraform import command
            result = run_command(line)
            if result.returncode != 0:
                continue

            # Run `terraform show` to get the state after import
            show_result = run_command("terraform show")
            if show_result.returncode != 0:
                continue

            output.write(show_result.stdout)
            output.write("\n\n")

    print(f"✅ Done. Full config written to `{OUTPUT_FILE}`.")


if __name__ == "__main__":
    main()
