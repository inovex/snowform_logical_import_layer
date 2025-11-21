variables {
  source_to_target_mappings = {
    "SOURCE_DB.SOURCE_SCHEMA.SOURCE_VIEW" = {
      target_database = "DEST_DB"
      target_schema   = "DEST_SCHEMA"
      target_name     = "DEST_VIEW"
    }
  }
  database_role_grants = {
    "DEST_DB" = ["ROLE_1", "ROLE_2"]
  }
  resource_type                = "view"
  dynamic_table_warehouse      = "WAREHOUSE_NAME"
  dynamic_table_lag_downstream = false
  dynamic_table_lag_duration   = "12 hours"
  procedure_database           = "MY_DATABASE"
  procedure_schema             = "MY_SCHEMA"
}

mock_provider "snowflake" {
  alias = "mockprovider"
}

run "test_grant_db_usage" {
  command = plan

  providers = {
    snowflake.sysadmin      = snowflake.mockprovider
    snowflake.securityadmin = snowflake.mockprovider
  }

  assert {
    condition     = length(snowflake_grant_privileges_to_account_role.database_usage) == 2
    error_message = "Number of role grants is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_1"].account_role_name == "ROLE_1"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_1"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_1"].on_account_object[0].object_name == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_2"].account_role_name == "ROLE_2"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_2"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.database_usage["DEST_DB:ROLE_2"].on_account_object[0].object_name == "DEST_DB"
    error_message = "Database name is incorrect"
  }
}

run "test_grant_schema_usage" {
  command = plan

  providers = {
    snowflake.sysadmin      = snowflake.mockprovider
    snowflake.securityadmin = snowflake.mockprovider
  }

  assert {
    condition     = length(snowflake_grant_privileges_to_account_role.schema_usage_current) == 2
    error_message = "Number of role grants is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_1"].account_role_name == "ROLE_1"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_1"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_1"].on_schema[0].all_schemas_in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_2"].account_role_name == "ROLE_2"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_2"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_current["DEST_DB:ROLE_2"].on_schema[0].all_schemas_in_database == "DEST_DB"
    error_message = "Database is incorrect"
  }
}

run "test_grant_future_schema_usage" {
  command = plan

  providers = {
    snowflake.sysadmin      = snowflake.mockprovider
    snowflake.securityadmin = snowflake.mockprovider
  }

  assert {
    condition     = length(snowflake_grant_privileges_to_account_role.schema_usage_future) == 2
    error_message = "Number of role grants is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_1"].account_role_name == "ROLE_1"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_1"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_1"].on_schema[0].future_schemas_in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_2"].account_role_name == "ROLE_2"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_2"].privileges == toset(["USAGE"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.schema_usage_future["DEST_DB:ROLE_2"].on_schema[0].future_schemas_in_database == "DEST_DB"
    error_message = "Database is incorrect"
  }
}

run "test_grant_view_select" {
  command = plan

  providers = {
    snowflake.sysadmin      = snowflake.mockprovider
    snowflake.securityadmin = snowflake.mockprovider
  }

  assert {
    condition     = length(snowflake_grant_privileges_to_account_role.view_select_current) == 2
    error_message = "Number of role grants is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_1"].account_role_name == "ROLE_1"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_1"].always_apply == true
    error_message = "Always apply is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_1"].privileges == toset(["SELECT"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_1"].on_schema_object[0].all[0].in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_1"].on_schema_object[0].all[0].object_type_plural == "VIEWS"
    error_message = "Type of object granted is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_2"].account_role_name == "ROLE_2"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_2"].always_apply == true
    error_message = "Always apply is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_2"].privileges == toset(["SELECT"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_2"].on_schema_object[0].all[0].in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_current["DEST_DB:ROLE_2"].on_schema_object[0].all[0].object_type_plural == "VIEWS"
    error_message = "Type of object granted is incorrect"
  }
}

run "test_grant_future_view_select" {
  command = plan

  providers = {
    snowflake.sysadmin      = snowflake.mockprovider
    snowflake.securityadmin = snowflake.mockprovider
  }

  assert {
    condition     = length(snowflake_grant_privileges_to_account_role.view_select_future) == 2
    error_message = "Number of role grants is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_1"].account_role_name == "ROLE_1"
    error_message = "Role name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_1"].privileges == toset(["SELECT"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_1"].on_schema_object[0].future[0].in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_1"].on_schema_object[0].future[0].object_type_plural == "VIEWS"
    error_message = "Type of object granted is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_2"].account_role_name == "ROLE_2"
    error_message = "Role name is incorrect"

  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_2"].privileges == toset(["SELECT"])
    error_message = "Privilege is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_2"].on_schema_object[0].future[0].in_database == "DEST_DB"
    error_message = "Database name is incorrect"
  }

  assert {
    condition     = snowflake_grant_privileges_to_account_role.view_select_future["DEST_DB:ROLE_2"].on_schema_object[0].future[0].object_type_plural == "VIEWS"
    error_message = "Type of object granted is incorrect"
  }
}