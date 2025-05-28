resource "google_dataplex_datascan" "dev-scan" {
  data_scan_id     = "dev-scan"
  description      = null
  display_name     = null
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dev_47c30c8a/tables/dev"
  }
  
  data_quality_spec {
    row_filter       = null
    sampling_percent = 100
    
    rules {
      column      = "order_id"
      description = "Sample rule for non-null column"
      dimension   = "COMPLETENESS"
      ignore_null = false
      name        = "non-null"
      threshold   = 1
      
    non_null_expectation {}
    }
    rules {
      column      = "user_id"
      description = "Sample rule for non-null column"
      dimension   = "COMPLETENESS"
      ignore_null = false
      name        = "non-null"
      threshold   = 1
      
    non_null_expectation {}
    }
    rules {
      column      = "created_at"
      description = "Sample rule for non-null column"
      dimension   = "COMPLETENESS"
      ignore_null = false
      name        = "non-null"
      threshold   = 1
      
    non_null_expectation {}
    }
    rules {
      column      = "order_id"
      description = "Sample rule for unique column"
      dimension   = "UNIQUENESS"
      ignore_null = false
      name        = "unique"
      threshold   = 0
      
    uniqueness_expectation {}
    }
    rules {
      column      = "status"
      description = "Sample rule for values in a set"
      dimension   = "VALIDITY"
      ignore_null = false
      name        = "one-of-set"
      threshold   = 0
      
      set_expectation {
        values = [
        "Shipped",
        "Complete",
        "Processing",
        "Cancelled",
        "Returned",
        ]
      }
    }
    rules {
      column      = "num_of_item"
      description = "Sample rule for values in a range"
      dimension   = "VALIDITY"
      ignore_null = false
      name        = "range-values"
      threshold   = 0.99
      
      range_expectation {
        max_value          = "1"
        min_value          = null
        strict_max_enabled = false
        strict_min_enabled = false
      }
    }
    rules {
      column      = null
      description = "Sample rule for a non-empty table"
      dimension   = "VALIDITY"
      ignore_null = false
      name        = "not-empty-table"
      threshold   = 0
      
      table_condition_expectation {
        sql_expression = "COUNT(*) > 0"
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

