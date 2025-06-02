resource "google_dataplex_datascan" "iris-scan" {
  data_scan_id     = "iris-scan"
  description      = "This is a scan on iris created originally in dev (My Project Prod)"
  display_name     = "iris_scan"
labels           = {}
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/ferrous-cipher-432403-j0/datasets/flowers/tables/iris"
  }
  
  data_quality_spec {
    row_filter       = "sepal_length > 1.0"
    sampling_percent = 100
    
    rules {
      column      = null
      description = "Check for freshness on iris"
      dimension   = "FRESHNESS"
      ignore_null = false
      name        = "fresh-flowers"
      threshold   = 0
      
      sql_assertion {
        sql_statement = <<-EOT
        SELECT count(*) as ct
      FROM $${data()}
        HAVING ct = 0
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

