import logging

logger = logging.getLogger("CREATE_VIEW_WITH_COMMENTS")

from snowflake.snowpark import Session
from snowflake.snowpark.functions import col
from snowflake.snowpark.exceptions import SnowparkSQLException

def create_view_with_column_comments(
    session: Session,
    SOURCE_NAME: str,
    TARGET_DB_NAME: str,
    TARGET_SCHEMA: str,
    TARGET_VIEW: str) -> str:
    """
    Create a view while keeping the column comments from the source table.

    Args:
        session: The active Snowpark session object.
        SOURCE_NAME: The fully qualified name of the source table (including database and schema).
        TARGET_DB_NAME: The database of the target view.
        TARGET_SCHEMA: The schema of the target view.
        TARGET_VIEW: The name of the target view.

    Returns:
        A string indicating the success or failure of the operation.
    """
    try:
        # 1. Query the information schema to get column comments from the source table
        # This creates a Snowpark DataFrame to retrieve the metadata.
        logger.info(f"Fetching comments from source: {SOURCE_NAME}")

        info_table_path = f"{SOURCE_NAME.split('.')[0]}.INFORMATION_SCHEMA.TABLES"
        table_comment_df = session.table(info_table_path).filter(
            (col("TABLE_CATALOG") == SOURCE_NAME.split('.')[0].upper()) &
            (col("TABLE_SCHEMA") == SOURCE_NAME.split('.')[1].upper()) &
            (col("TABLE_NAME") == SOURCE_NAME.split('.')[2].upper())
        ).select(
            col("COMMENT")
        )
        table_comment_to_apply = table_comment_df.collect()
        table_comment_to_apply = table_comment_to_apply[0]
        table_comment_to_apply = table_comment_to_apply["COMMENT"]

        info_schema_path = f"{SOURCE_NAME.split('.')[0]}.INFORMATION_SCHEMA.COLUMNS"

        comments_df = session.table(info_schema_path).filter(
            (col("TABLE_CATALOG") == SOURCE_NAME.split('.')[0].upper()) &
            (col("TABLE_SCHEMA") == SOURCE_NAME.split('.')[1].upper()) &
            (col("TABLE_NAME") == SOURCE_NAME.split('.')[2].upper())
        ).select(
            col("COLUMN_NAME"),
            col("COMMENT")
        ).order_by(
            col("ORDINAL_POSITION")
        )

        # 2. Collect the metadata into a list of Row objects.
        column_comments_to_apply = comments_df.collect()
        logger.info(f"Found {len(column_comments_to_apply)} columns in the source table.")

        # 3. Loop through each column and format the final sql expression
        TARGET_VIEW_path = f'"{TARGET_DB_NAME}"."{TARGET_SCHEMA}"."{TARGET_VIEW}"'
        columns_with_comments = []
        columns = []
        
        for row in column_comments_to_apply:
            col_name = row["COLUMN_NAME"]
            col_comment = row["COMMENT"]
            columns.append(f"{col_name}")

            # Escape single quotes in the comment string to make it a valid SQL literal
            escaped_comment = col_comment.replace("'", "''")
            column_row = f"  {col_name} COMMENT '{escaped_comment}'"
            columns_with_comments.append(column_row)

        columns_for_select = ", ".join(columns)
        create_view_statement = "\n".join((
            f"CREATE OR REPLACE VIEW {TARGET_DB_NAME}.{TARGET_SCHEMA}.{TARGET_VIEW} (",
            ", ".join(columns_with_comments),
            ")",
            f"COMMENT = '{table_comment_to_apply}'",
            "AS",
            f"SELECT {columns_for_select} FROM {SOURCE_NAME}"
        ))
        logger.info(create_view_statement)
        
        # Execute the DDL statement
        session.sql(create_view_statement).collect()

        success_message = f"SUCCESS: {len(column_comments_to_apply)} column comments have been applied to the view '{TARGET_VIEW_path}'."
        logger.info(success_message)
        return success_message

    except SnowparkSQLException as e:
        error_message = f"ERROR: A database error occurred: {e}"
        logger.critical(error_message)
        return error_message
    except Exception as e:
        error_message = f"ERROR: An unexpected error occurred: {e}"
        logger.critical(error_message)
        return error_message