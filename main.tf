# google_dataplex_datascan.basic_quality:
resource "google_dataplex_datascan" "basic_quality" {
  data_scan_id     = "tf-dataquality-basic"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"

    data {
        resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/samples/tables/shakespeare"
    }

    data_quality_spec {
        sampling_percent = 100

        rules {
            description = "rule 1 for validity dimension"
            dimension   = "VALIDITY"
            ignore_null = false
            name        = "rule1"
            threshold   = 0

            table_condition_expectation {
                sql_expression = "COUNT(*) > 0"
            }
        }
    }

    execution_spec {
        trigger {
            on_demand {}
        }
    }
}

# google_dataplex_datascan.full_quality:
resource "google_dataplex_datascan" "full_quality" {
    data_scan_id     = "tf-advanced-scan"
    description      = "Testing resource - testing SQL assertions, my own datasources, and scheduling"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"

    data {
        resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/thelook/tables/orders"
    }

    data_quality_spec {
        row_filter       = "gender = 'F'"
        sampling_percent = 0

        rules {
            column      = "user_id"
            description = "Rule description for user id rule (this is from test-scripting git branch)"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "TEST-RULE-USER-ID"
            threshold   = 0

            sql_assertion {
                sql_statement = "SELECT count(*) as ct FROM ferrous-cipher-432403-j0.thelook.orders WHERE user_id > 10000 HAVING ct > 0"
            }
        }
        rules {
            column      = "shipped_at"
            description = "Rule description for shipped_at rule"
            dimension   = "CONSISTENCY"
            ignore_null = false
            name        = "TEST-RULE-SHIPPED-AT"
            threshold   = 0

            sql_assertion {
                sql_statement = "SELECT count(*) as ct FROM ferrous-cipher-432403-j0.thelook.orders  WHERE date(shipped_at) > date('2023-01-01') HAVING ct > 0"
            }
        }
    }

    execution_spec {
        field = "created_at"

        trigger {
            schedule {
                cron = "TZ=America/Chicago 1 1 * * *"
            }
        }
    }
}

# google_dataplex_datascan.imported_datascan:
resource "google_dataplex_datascan" "imported_datascan" {
    data_scan_id     = "ui-scan-1"
    description      = "The first scan created in the UI (adding comment here from code, to see whether cloud build check catches this)"
    display_name     = "ui-scan-1"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"

    data {
        resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
    }

    data_quality_spec {
        row_filter       = "Date > date('2011-01-01')"
        sampling_percent = 100

        post_scan_actions {
            bigquery_export {
                results_table = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/scan_outputs"
            }
        }

        rules {
            column      = "Store"
            description = "Store nbr should not be negative"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "rule-1-store"
            threshold   = 0

            sql_assertion {
                sql_statement = <<-EOT
                    SELECT Store
                    FROM ferrous-cipher-432403-j0.dataplex_test.walmart_sales
                    WHERE Store < 0
                EOT
            }
        }
        rules {
            column      = "Unemployment"
            description = "Unemployment should not be higher than 20"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "rule-2-unemployment-value"
            threshold   = 0

            sql_assertion {
                sql_statement = <<-EOT
                    SELECT Unemployment
                    FROM ferrous-cipher-432403-j0.dataplex_test.walmart_sales
                    WHERE Unemployment > 20
                EOT
            }
        }
        rules {
            column      = "Holiday_Flag"
            description = "Row Check rule: holiday_flag should only be 0,1,2"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "rule-3-holiday-flag"
            threshold   = 1

            row_condition_expectation {
                sql_expression = "Holiday_Flag IN (0,1,2)"
            }
        }
    }

    execution_spec {
        trigger {
            on_demand {}
        }
    }
}

# google_dataplex_datascan.ui-scan-2:
resource "google_dataplex_datascan" "ui-scan-2" {
    data_scan_id     = "ui-scan-2"
    description      = "This is the second scan created in UI"
    display_name     = "ui-scan-2"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"

    data {
        resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
    }

    data_quality_spec {
        sampling_percent = 100

        post_scan_actions {
            bigquery_export {
                results_table = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/scan_outputs"
            }
        }

        rules {
            column      = "Temperature"
            description = "Temperature should not be below -40"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "ui-scan-2-rule-1-temperature"
            threshold   = 0

            sql_assertion {
                sql_statement = <<-EOT
                    SELECT Temperature
                    FROM ferrous-cipher-432403-j0.dataplex_test.walmart_sales
                    WHERE Temperature < -40
                EOT
            }
        }
    }

    execution_spec {
        trigger {
            on_demand {}
        }
    }
}

# google_dataplex_datascan.ui-scan-3:
resource "google_dataplex_datascan" "ui-scan-3" {
    data_scan_id     = "ui-scan-3"
    description      = "This is a test to see if we can import this to terraform"
    display_name     = "ui-scan-3"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"

    data {
        resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
    }

    data_quality_spec {
        row_filter       = "Weekly_Sales > 1500000"
        sampling_percent = 100

        rules {
            column      = "Temperature"
            description = "Foo"
            dimension   = "ACCURACY"
            ignore_null = false
            name        = "test-rule-3"
            threshold   = 0

            sql_assertion {
                sql_statement = <<-EOT
                    SELECT count(*) as ct 
                    FROM ferrous-cipher-432403-j0.dataplex_test.walmart_sales
                    WHERE temperature > 30
                    HAVING ct > 0
                EOT
            }
        }
    }

    execution_spec {
        trigger {
            on_demand {}
        }
    }
}

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
