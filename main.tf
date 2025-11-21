terraform {
  required_version = ">= 1.7"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.1.0, < 3.0.0"
      configuration_aliases = [
        snowflake.sysadmin,
        snowflake.securityadmin
      ]
    }
  }
}

# Creates views using a stored procedure that preserves column comments
# from source tables/views. Only created when resource_type = "view".
resource "snowflake_execute" "logical_layer_views" {
  provider = snowflake.sysadmin
  for_each = var.resource_type == "view" ? local.share_view_mapping_legacy : {}

  execute = "CALL ${var.procedure_database}.${var.procedure_schema}.${snowflake_procedure_python.view_with_comments_creator.name}('${each.key}', '${each.value[0]}', '${each.value[1]}', '${each.value[2]}');"
  revert  = "DROP VIEW IF EXISTS ${each.value[0]}.${each.value[1]}.${each.value[2]};"

  depends_on = [snowflake_procedure_python.view_with_comments_creator]

  lifecycle {
    replace_triggered_by = [
      snowflake_procedure_python.view_with_comments_creator.id,
      snowflake_procedure_python.view_with_comments_creator.procedure_definition
    ]
  }
}


# Creates dynamic tables that auto-refresh based on configured lag.
# Only created when resource_type = "dynamic_table".
resource "snowflake_dynamic_table" "logical_layer_dynamic_tables" {
  provider = snowflake.sysadmin
  for_each = var.resource_type == "dynamic_table" ? local.share_view_mapping_legacy : {}

  name      = each.value[2]
  database  = each.value[0]
  schema    = each.value[1]
  warehouse = var.dynamic_table_warehouse
  query     = "SELECT * FROM ${each.key}"

  target_lag {
    downstream       = var.dynamic_table_lag_downstream
    maximum_duration = var.dynamic_table_lag_duration
  }
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  provider = snowflake.securityadmin
  for_each = local.database_role_grant_map

  account_role_name = each.value.role
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_usage_current" {
  provider = snowflake.securityadmin
  for_each = local.database_role_grant_map

  account_role_name = each.value.role
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = each.value.database
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_usage_future" {
  provider = snowflake.securityadmin
  for_each = local.database_role_grant_map

  account_role_name = each.value.role
  privileges        = ["USAGE"]

  on_schema {
    future_schemas_in_database = each.value.database
  }
}

resource "snowflake_grant_privileges_to_account_role" "view_select_current" {
  provider = snowflake.securityadmin
  for_each = local.database_role_grant_map

  account_role_name = each.value.role
  privileges        = ["SELECT"]
  always_apply      = true

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = each.value.database
    }
  }

  depends_on = [snowflake_execute.logical_layer_views]
}

resource "snowflake_grant_privileges_to_account_role" "view_select_future" {
  provider = snowflake.securityadmin
  for_each = local.database_role_grant_map

  account_role_name = each.value.role
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = each.value.database
    }
  }

  depends_on = [snowflake_execute.logical_layer_views]
}
