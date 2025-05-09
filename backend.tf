terraform {
  backend "gcs" {
    bucket = "spencer-tf-remote-backend"
  }
}
