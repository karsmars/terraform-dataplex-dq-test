# [Draft] Using Dataplex with Terraform

## [Draft] Setting up initial infrastructure
These instructions assume you've downloaded this repository to your machine and are in the `terraform-dataplex-dq-test` top-level directory. Download the repo and delete the `modules/` folder, `main.tf` and `backup.tf`. These will be automatically generated to match your infrastructure later. You will also need to change the 

Install Homebrew on your Mac (or find another way for Windows) by running `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`. You will need to disconnect from Walmart VPN. 

Then install Terraform command line module by running `brew tap hashicorp/tap` followed by `brew install hashicorp/tap/terraform`. 

Once Terraform is installed, run `terraform init` in this directory to tell Terraform to start tracking configuration.

### Transform Dataplex scans to Terraform config
In this first section we will read the existing Dataplex scans as Terraform state, and automatically write TF config files to mirror the existing structure. This is a one-time setup to align our Terraform code with the actual scans we've already written. 

First, you must authenticate to Google Cloud locally on your machine. This involves downloading the Google Cloud SDK (may require leaving Walmart VPN) and then running the command `gcloud auth login` in your terminal shell.

Next, look at `scripts/dataplex_migration.py`. Make sure the project ID and location variables at the top match the project you want to download Dataplex scans from. 

Run this script by executing command `python3 scripts/dataplex_migration.py` This script will read every Dataplex scan for the specified GCP project and write Terraform config files that match. This allows us to download existings scans as code without having to manually recreate them.

The script has 5 parts: 
- Check whether we are authenticated to GCP in the command line
- Create list of differences between actual Dataplex infrastructure, to get list of scans to remove or import to Terraform config
- Run imports to sync up Terraform state, and create a local file copy
- Transform the state file into config file by removing fields which cannot be declared in config
- Modularize the config by splitting into different folders based on schema & table

[TODO] Add a GCS storage bucket for storing TF state

### Set up GitHub build checks using Cloud Build connection
We will now implement automatic build checks into the GitHub pipeline that ensure each time you push code or merge changes, Terraform will check the validity and then apply changes to Dataplex. You should see three YAML files which contain the instructions for Cloud Build checks. 

[TODO] Add the three Cloud Build triggers

[TODO] Add GitHub access token to Secret Manager in Google so the build can comment `terraform plan` details into Pull Requests, and make sure the same project and secret name is reflected in `cloudbuild.pr.yaml`.

[TODO] Is there a low risk way to test the build checks to see if they work, before pushing all our Terraform scans


## [Draft] Using Git and Terraform for normal use
After setting up Terraform, DO NOT make further Dataplex changes to Prod through the UI / web version, because these will not be stored in Terraform config and will be overwritten the next time `terraform apply` is run (which will be when someone else writes a scan and pushes it through code). All configuration changes to Prod must be reflected in code to be preserved.

### Writing scans
If you use a workflow with two Dataplex projects (Dev and Prod), then 

### Deploying dev to prod
First, make sure you have the most recent changes from the `main` Git branch. 
- Run `git checkout main` and `git pull` to get the most recent changes. 
- Run `git checkout -b YOUR-NEW-BRANCH` to create a new branch ready for your changes.

Next, sync changes from Dev to the code: 
- Run `python3 scripts/dataplex_migration.py` with the PROJECT_ID pointed at Dev project to get all current changes in Dev. This will change the Terraform files in the modules folder. 

Finally, push the changes to Prod:
- Commit the changes to Git that you want to merge to Prod (e.g. if there are 2 new scans downloaded but you only want scan A, then commit the file scan A and revert the file for scan B). 
- Push the branch to GitHub, and open a PR to `main`.
- Confirm that the PR build checks pass. The build should also comment in the PR with all proposed changes from the `terraform plan` command -- this allows you to preview what actual changes will be made to Prod.
- Once you and another team member review and approve the PR changes, merge the branch to `main` and it should automatically run `terraform apply`.
- As a final check, confirm that the build checks on `main` pass (otherwise if there is an error, the changes will not be correctly deployed to Prod infrastructure).


## Edge Cases

- Dataset exists in Dev but not Prod
- We want to make changes in Dev but not import all to Prod yet
