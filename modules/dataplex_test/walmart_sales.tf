resource "google_dataplex_datascan" "ui-scan-1" {
  data_scan_id     = "ui-scan-1"
  description      = "The first scan created in the UI (hoorah!) test comment"
  display_name     = "ui-scan-1"
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
  }
  
  data_quality_spec {
    row_filter       = "Date > date('2012-01-01')"
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
      FROM ${data()}
        WHERE Unemployment > 10
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

resource "google_dataplex_datascan" "ui-scan-2" {
  data_scan_id     = "ui-scan-2"
  description      = "This is the second scan created in UI"
  display_name     = "ui-scan-2"
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
    field = null
    
    trigger {
    on_demand {}
    }
  }
}

resource "google_dataplex_datascan" "ui-scan-3" {
  data_scan_id     = "ui-scan-3"
  description      = "This is a test to see if we can import this to terraform"
  display_name     = "ui-scan-3"
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
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
    field = null
    
    trigger {
    on_demand {}
    }
  }
}

resource "google_dataplex_datascan" "ui-scan-4" {
  data_scan_id     = "ui-scan-4"
  description      = "Made this in UI"
  display_name     = "ui-scan-4"
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/dataplex_test/tables/walmart_sales"
  }
  
  data_quality_spec {
    row_filter       = null
    sampling_percent = 90
    
    rules {
      column      = "Temperature"
      description = null
      dimension   = "VALIDITY"
      ignore_null = false
      name        = null
      threshold   = 1
      
    non_null_expectation {}
    }
  }
  
  execution_spec {
    field = null
    
    trigger {
    on_demand {}
    }
  }
}

