resource "snowflake_procedure_python" "view_with_comments_creator" {
  provider = snowflake.sysadmin

  name     = "CREATE_VIEW_WITH_COLUMN_COMMENTS"
  database = var.procedure_database
  schema   = var.procedure_schema

  runtime_version  = "3.11"
  snowpark_package = "1.30.0"
  execute_as       = "CALLER"

  # Input: Fully qualified source table/view name
  arguments {
    arg_name      = "source_name"
    arg_data_type = "VARCHAR(1000)"
  }

  # Input: Target database name
  arguments {
    arg_name      = "target_db_name"
    arg_data_type = "VARCHAR(100)"
  }

  # Input: Target schema name
  arguments {
    arg_name      = "target_schema"
    arg_data_type = "VARCHAR(100)"
  }

  # Input: Target view name
  arguments {
    arg_name      = "target_view"
    arg_data_type = "VARCHAR(100)"
  }

  return_type = "VARCHAR(1000)"
  handler     = "CREATE_VIEW_WITH_COLUMN_COMMENTS"

  # Python code implementing the view creation logic
  procedure_definition = file("${path.module}/create_view_with_comments_procedure.py")
}
