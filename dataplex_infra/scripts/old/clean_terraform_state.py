import re
import argparse


# This script parses through a Terraform state file for Google Dataplex scans, and removes any Attribute fields which are not allowed to be declared in a config file:  https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataplex_datascan#attributes-reference
# It is a hacky way of downloading existing infrastructure and creating a main.tf file from it

# The script expects to receive input generated from something like `terraform show > state.txt`
resource_types = { 
    "google_dataplex_datascan":{
        "FIELDS_TO_REMOVE":[
            "id",
            "name",
            "uid",
            "state",
            "create_time",
            "update_time",
            "type",
            "terraform_labels",
            "effective_labels",
            "execution_status"
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
            ]
    }
}
    


def is_resource_start(line, resource_type):
    pattern = rf'^\s*resource\s+"{re.escape(resource_type)}"\s+"[^"]+"\s*{{'
    return re.match(pattern, line)


def extract_key(line):
    line = line.strip()

    # 1. Match key-value (name = "value")
    kv_match = re.match(r'^(?!#)(?:"([^"]+)"|([^\s=]+))\s*=', line)
    if kv_match:
        return kv_match.group(1) or kv_match.group(2)

    # 2. Match block header (key { or key = {)
    block_match = re.match(r'^(?!#)([a-zA-Z0-9_]+)\s*(=)?\s*{', line)
    if block_match:
        return block_match.group(1)

    return None


def count_braces(line):
    # Count braces for nesting level tracking
    open_count = line.count('{') + line.count('[')
    close_count = line.count('}') + line.count(']')
    return open_count, close_count


def clean_lines(lines):
    output = []
    current_resource = None
    nesting = 0
    inside_block_to_remove = False

    for line in lines:
        # Detect entry into a dataplex scan resource
        if current_resource == None:
            for res in resource_types:
                if is_resource_start(line, res):
                    current_resource = res
                    nesting = 1
                    output.append(line)
                    break
            if current_resource is not None:
                continue

        # Inside a dataplex scan resource
        if current_resource is not None:

            open_b, close_b = count_braces(line)
            new_nesting = nesting + open_b - close_b

            # If we're at depth 1 (directly inside resource block)
            if nesting == 1:
                key = extract_key(line)
                if key in resource_types[current_resource]["FIELDS_TO_REMOVE"]:
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

        # Outside target resource, just copy lines
        output.append(line)

    return output

def process_file(input_path, output_path):
    with open(input_path, "r") as f:
        lines = f.readlines()

    cleaned = clean_lines(lines)

    with open(output_path, "w") as f:
        f.write("".join(cleaned))

def main():
    parser = argparse.ArgumentParser(description="Clean top-level fields from specified Terraform resources.")
    parser.add_argument("--input", required=True, help="Input Terraform file path")
    parser.add_argument("--output", required=True, help="Output cleaned file path")
    args = parser.parse_args()

    process_file(args.input, args.output)
    print(f"✅ Cleaned Terraform file saved to: {args.output}")

if __name__ == "__main__":
    main()