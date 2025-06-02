resource "google_storage_bucket" "tf_state_dev" {
  name     = "ferrous-cipher-prod-tfstate
  location = "US"
  project  = "ferrous-cipher-prod"
  versioning { enabled = true }
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "tf_state_prod" {
  name     = "spencer-tf-remote-backend"
  location = "US"
  project  = "ferrous-cipher-432403-j0"
  versioning { enabled = true }
  uniform_bucket_level_access = true
}