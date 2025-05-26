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
      description = "Rule description for user id rule (this is from test-scripting git branch :) )"
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
