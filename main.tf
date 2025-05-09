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
        row_filter       = "Weekly_Sales > 1600000"
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







resource "google_storage_bucket" "default" {
  name     = "spencer-tf-remote-backend"
  location = "US"
 

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
 

  versioning {
    enabled = true
  }
}


resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"

  # You can store the template in a file and use the templatefile function for
  # more modularity, if you prefer, instead of storing the template inline as
  # we do here.
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.default.name}"
    }
  }
  EOT
}

resource "google_dataplex_datascan" "basic_quality" {
  location     = "us-central1"
  data_scan_id = "tf-dataquality-basic"

  data {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/samples/tables/shakespeare"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_quality_spec {
    rules {
      dimension = "VALIDITY"
      name = "rule1"
      description = "rule 1 for validity dimension"
      table_condition_expectation {
        sql_expression = "COUNT(*) > 0"
      }
    }
  }

  project = "ferrous-cipher-432403-j0"

}


resource "google_dataplex_datascan" "full_quality" {
  location = "us-central1"
  data_scan_id = "tf-advanced-scan"
  description = "Testing resource - testing SQL assertions, my own datasources, and scheduling"
  
  data {
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/thelook/tables/orders"
  }

  execution_spec {
    trigger {
      schedule {
        cron = "TZ=America/Chicago 1 1 * * *"
      }
    }
    field = "created_at"
  }

  data_quality_spec {  
    row_filter="gender = 'F'"
    rules {
      column = "user_id"
      dimension = "ACCURACY"
      sql_assertion {
        sql_statement = "SELECT count(*) as ct FROM ferrous-cipher-432403-j0.thelook.orders WHERE user_id > 10000 HAVING ct > 0"
      }
      name = "TEST-RULE-USER-ID"
      description = "Rule description for user id rule bwahaha"
    } 

    rules {
      column = "shipped_at"
      dimension = "CONSISTENCY"
      sql_assertion {
        sql_statement = "SELECT count(*) as ct FROM ferrous-cipher-432403-j0.thelook.orders  WHERE date(shipped_at) > date('2023-01-01') HAVING ct > 0"
      }
      name = "TEST-RULE-SHIPPED-AT"
      description = "Rule description for shipped_at rule"
    }
  }

  project = "ferrous-cipher-432403-j0"

}


resource "google_dataplex_datascan" "imported_datascan" {
    data_scan_id     = "ui-scan-1"
    description      = "The first scan created in the UI"
    display_name     = "ui-scan-1"
    labels           = {}
    location         = "us-central1"
    project          = "ferrous-cipher-432403-j0"
    data {
        entity   = null
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
        field = null

        trigger {
            on_demand {}
        }
    }
}
