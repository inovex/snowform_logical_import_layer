# Snowflake Logical Import Layer

A Terraform module for creating a logical abstraction layer over Snowflake imported databases and shares. This module enables you to consolidate data from multiple sources into a unified, logical structure while preserving column comments.

## Overview

This module helps you organize imported databases from different shares into your own logical layer. For example, you can collect all the product data, regardless of the original source, into one logical database and schema.

### Key Features

- **Metadata Preservation**: Automatically preserves column and table comments when creating views
- **Flexible Resource Types**: Create either standard views or auto-refreshing dynamic tables
- **Automated Access Control**: Configurable role-based access grants for database, schema, and view levels
- **Multi-Source Consolidation**: Map multiple source tables/views to a unified logical structure

## Prerequisites

### Required Resources

1. **Existing Databases and Schemas**: All source and target databases and schemas must already exist
2. **Snowflake Providers**: Two provider configurations are required:
   - `snowflake.sysadmin`: For creating database objects
   - `snowflake.securityadmin`: For managing grants and permissions
3. **Preview Features**: The sysadmin provider must have Python procedures enabled:
   ```hcl
   preview_features_enabled = ["snowflake_procedure_python_resource"]
   ```

### Required Permissions

- **SYSADMIN role**: CREATE VIEW, CREATE DYNAMIC TABLE, CREATE PROCEDURE permissions
- **SECURITYADMIN role**: GRANT privileges on databases, schemas, and views

## Usage

### Basic Example with Views

```hcl
module "logical_import_layer" {
  source  = "gitlab.dm-drogeriemarkt.com/?"
  version = "1.0.0"

  # Location for the stored procedure
  procedure_database = "SHARED_UTILITIES"
  procedure_schema   = "PROCEDURES"

  # Map source objects to logical layer targets
  source_to_target_mappings = {
    "X.SCHEMA_NAME.TABLE_V3" = {
      target_database = "LOGICAL_PRODUCT_DATA"
      target_schema   = "MASTER_DATA"
      target_name     = "MATERIAL_MASTER"
    }
    "Y.SCHEMA_NAME.TABLE_V1" = {
      target_database = "LOGICAL_PRODUCT_DATA"
      target_schema   = "MASTER_DATA"
      target_name     = "MATERIAL_UNITS"
    }
    "Z.PUBLIC.TABLE_DIM" = {
      target_database = "LOGICAL_PRODUCT_DATA"
      target_schema   = "DIMENSIONS"
      target_name     = "CUSTOMERS"
    }
  }

  # Grant read access to roles
  database_role_grants = {
    "LOGICAL_PRODUCT_DATA" = [
      "DATA_ANALYST_ROLE",
      "DATA_ENGINEER_ROLE",
      "BI_DEVELOPER_ROLE"
    ]
  }

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
  }
}
```

### Advanced Example with Dynamic Tables

```hcl
module "logical_import_layer_dynamic" {
  source  = "gitlab.dm-drogeriemarkt.com/?"
  version = "1.0.0"

  procedure_database = "SHARED_UTILITIES"
  procedure_schema   = "PROCEDURES"

  # Use dynamic tables instead of views
  resource_type = "dynamic_table"

  # Dynamic table configuration
  dynamic_table_warehouse     = "COMPUTE_WH"
  dynamic_table_lag_duration  = "10 minutes"
  dynamic_table_lag_downstream = false

  source_to_target_mappings = {
    "EXTERNAL_SHARE.PROD.TRANSACTIONS" = {
      target_database = "ANALYTICS"
      target_schema   = "STAGING"
      target_name     = "TRANSACTIONS_STAGED"
    }
  }

  database_role_grants = {
    "ANALYTICS" = ["ANALYST_ROLE"]
  }

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
  }
}
```

## Input Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `procedure_database` | `string` | Database where the view creation stored procedure will be deployed |
| `procedure_schema` | `string` | Schema where the view creation stored procedure will be deployed |
| `source_to_target_mappings` | `map(object)` | Map of source objects to target logical layer objects. See structure below. |
| `database_role_grants` | `map(list(string))` | Map of target databases to lists of roles that should receive read access |

#### source_to_target_mappings Structure

```hcl
{
  "FULLY.QUALIFIED.SOURCE" = {
    target_database = "TARGET_DB"
    target_schema   = "TARGET_SCHEMA"
    target_name     = "TARGET_VIEW_NAME"
  }
}
```

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_type` | `string` | `"view"` | Type of resource to create: `"view"` or `"dynamic_table"` |
| `dynamic_table_warehouse` | `string` | `null` | Warehouse for dynamic table operations (required if `resource_type = "dynamic_table"`) |
| `dynamic_table_lag_downstream` | `bool` | `false` | Refresh only when downstream dynamic tables are refreshed |
| `dynamic_table_lag_duration` | `string` | `null` | Maximum staleness (e.g., `"60 seconds"`, `"5 minutes"`, `"2 hours"`) |

## Outputs

| Output | Description |
|--------|-------------|
| `procedure_qualified_name` | Fully qualified name of the stored procedure |
| `created_views` | Map of created views with their fully qualified names |
| `created_dynamic_tables` | Map of created dynamic tables with their fully qualified names |
| `granted_databases` | List of databases that have been granted access |
| `granted_roles` | List of roles that have been granted access |
| `database_role_grants` | Map showing role-to-database access mappings |
| `resource_type` | Type of resources created (view or dynamic_table) |

## Architecture

### Component Overview

1. **Stored Procedure**: Python-based Snowpark procedure that:
   - Queries `INFORMATION_SCHEMA` to extract column metadata
   - Generates `CREATE VIEW` statements with inline column comments
   - Preserves table-level comments from source objects

2. **Logical Layer Resources**: Either views or dynamic tables created from source data

3. **Access Control**: Hierarchical grants providing:
   - Database-level USAGE privileges
   - Schema-level USAGE privileges (current and future)
   - View-level SELECT privileges (current and future)

### Resource Naming Best Practices

- Use descriptive, business-oriented names for target objects
- Group related data in the same target schema
- Consider using prefixes/suffixes to indicate source systems
- Follow your organization's naming conventions

## Troubleshooting

### Common Issues

**Error: "procedure_database must be a non-empty string"**
- Ensure both `procedure_database` and `procedure_schema` are set
- These variables are required and have no default values

**Error: "dynamic_table_warehouse is required when resource_type is 'dynamic_table'"**
- Set `dynamic_table_warehouse` when using dynamic tables
- Example: `dynamic_table_warehouse = "COMPUTE_WH"`

**Error: "Cannot specify both dynamic_table_lag_downstream and dynamic_table_lag_duration"**
- These settings are mutually exclusive
- Use `lag_downstream = true` OR `lag_duration = "10 minutes"`, not both

**Views/Tables not created**
- Verify source objects exist and are accessible
- Check that target databases and schemas exist
- Ensure the procedure database/schema exists before module execution

### Debugging Tips

1. **Check Terraform Plan**: Review the plan output to see what resources will be created
2. **Review Outputs**: After apply, check outputs to verify created resources
3. **Snowflake Query History**: Look for executed procedure calls and DDL statements
4. **Provider Configuration**: Ensure both provider aliases are correctly configured

## Migration from Previous Versions

If you're using the old variable names, update your configuration:

| Old Variable | New Variable |
|--------------|--------------|
| `database_for_procedure` | `procedure_database` |
| `schema_for_procedure` | `procedure_schema` |
| `share_view_mapping` | `source_to_target_mappings` (with new structure) |
| `privilege_mapping` | `database_role_grants` |
| `dynamic_table_target_lag_downstream` | `dynamic_table_lag_downstream` |
| `dynamic_table_target_lag_maximum_duration` | `dynamic_table_lag_duration` |

### Migration Example

**Before:**
```hcl
share_view_mapping = {
  "SOURCE_DB.SCHEMA.TABLE" = ["DEST_DB", "DEST_SCHEMA", "DEST_VIEW"]
}
```

**After:**
```hcl
source_to_target_mappings = {
  "SOURCE_DB.SCHEMA.TABLE" = {
    target_database = "DEST_DB"
    target_schema   = "DEST_SCHEMA"
    target_name     = "DEST_VIEW"
  }
}
```

## Contributing

When contributing to this module:

1. Follow Terraform best practices and style guidelines
2. Update documentation for any variable or output changes
3. Add validation rules for new variables
4. Test with both view and dynamic table configurations
5. Update the CHANGELOG.md with your changes

## License

This module is proprietary to dm-drogerie markt.

## Support

For issues or questions:
- Open an issue in the GitLab repository
- Contact the Tech ERP team
- Review Snowflake documentation for provider-specific questions
