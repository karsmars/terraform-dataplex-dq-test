# google_dataplex_datascan.basic_quality:

# google_dataplex_datascan.full_quality:

# google_dataplex_datascan.imported_datascan:

# google_dataplex_datascan.ui-scan-2:

# google_dataplex_datascan.ui-scan-3:

# google_storage_bucket.default:
resource "google_storage_bucket" "default" {
    default_event_based_hold    = false
    enable_object_retention     = false
    force_destroy               = false
    labels                      = {}
    location                    = "US"
    name                        = "spencer-tf-remote-backend"
    project                     = "ferrous-cipher-432403-j0"
    public_access_prevention    = "enforced"
    requester_pays              = false
    rpo                         = "DEFAULT"
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true

    hierarchical_namespace {
        enabled = false
    }


    versioning {
        enabled = true
    }
}

module "dataplex_test" {
  source = "./modules/dataplex_test"
}

module "samples" {
  source = "./modules/samples"
}

module "thelook" {
  source = "./modules/thelook"
}
