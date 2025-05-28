resource "google_dataplex_datascan" "tf-dataquality-basic" {
  data_scan_id     = "tf-dataquality-basic"
  description      = null
  display_name     = null
  location         = "us-central1"
  project          = "ferrous-cipher-432403-j0"
  
  data {
    entity   = null
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/samples/tables/shakespeare"
  }
  
  data_quality_spec {
    row_filter       = null
    sampling_percent = 100
    
    rules {
      column      = null
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
    field = null
    
    trigger {
    on_demand {}
    }
  }
}

