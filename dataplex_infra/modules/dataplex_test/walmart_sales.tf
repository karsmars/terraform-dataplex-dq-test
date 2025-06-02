resource "google_dataplex_datascan" "sales-scan" {
  data_scan_id     = "sales-scan"
  description      = "Another scan on sales data"
  display_name     = "sales_scan"
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
  }
  
  data_quality_spec {
    row_filter       = null
    sampling_percent = 100
    
    rules {
      column      = "Store"
      description = "Store number should not be negative"
      dimension   = "ACCURACY"
      ignore_null = false
      name        = "store-rule"
      threshold   = 0
      
      sql_assertion {
        sql_statement = <<-EOT
        SELECT Store
      FROM $${data()}
        WHERE Store < 0
        EOT
      }
    }
    rules {
      column      = "Holiday_Flag"
      description = "Checking Holiday Flag"
      dimension   = "ACCURACY"
      ignore_null = false
      name        = "holiday-flag-rule"
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

