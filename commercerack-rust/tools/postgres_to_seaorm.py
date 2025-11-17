#!/usr/bin/env python3
"""
PostgreSQL to SeaORM Migration Generator

Parses PostgreSQL schema.sql and generates SeaORM migration files for all tables.
Follows b00t gospel: use existing crates (SeaORM) instead of writing custom database interfaces.
"""

import re
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Tuple, Optional

# PostgreSQL to SeaORM type mappings
TYPE_MAP = {
    # Integer types
    r'smallint': 'small_integer()',
    r'integer': 'integer()',
    r'bigint': 'big_integer()',
    r'serial': 'integer()',
    r'bigserial': 'big_integer()',

    # Boolean
    r'boolean': 'boolean()',

    # String types
    r'varchar\((\d+)\)': lambda m: f'string_len({m.group(1)})',
    r'character varying\((\d+)\)': lambda m: f'string_len({m.group(1)})',
    r'char\((\d+)\)': lambda m: f'char_len({m.group(1)})',
    r'text': 'text()',

    # Date/Time types
    r'timestamp': 'timestamp()',
    r'timestamp without time zone': 'timestamp()',
    r'timestamp with time zone': 'timestamp_with_time_zone()',
    r'date': 'date()',
    r'time': 'time()',

    # Decimal types
    r'numeric\((\d+),(\d+)\)': lambda m: f'decimal_len({m.group(1)}, {m.group(2)})',
    r'decimal\((\d+),(\d+)\)': lambda m: f'decimal_len({m.group(1)}, {m.group(2)})',
    r'real': 'float()',
    r'double precision': 'double()',

    # Binary types
    r'bytea': 'binary()',

    # JSON
    r'json': 'json()',
    r'jsonb': 'json_binary()',

    # UUID
    r'uuid': 'uuid()',
}

def parse_postgres_type(pg_type: str) -> str:
    """Convert PostgreSQL type to SeaORM ColumnType"""
    pg_type = pg_type.lower().strip()

    for pattern, replacement in TYPE_MAP.items():
        match = re.match(pattern, pg_type)
        if match:
            if callable(replacement):
                return replacement(match)
            else:
                return replacement

    # Fallback - check if it's an ENUM type
    if not any(c in pg_type for c in ['(', ')', ' ']):
        # Likely a custom ENUM type
        return 'string()'  # ENUMs stored as strings in SeaORM

    print(f"Warning: Unknown type '{pg_type}', using string()", file=sys.stderr)
    return 'string()'

def parse_create_table(sql: str) -> Tuple[Optional[str], List[Dict]]:
    """Parse a CREATE TABLE statement and extract table name and columns"""

    # Extract table name (handle both quoted and unquoted)
    table_match = re.search(r'CREATE TABLE\s+"?([a-z_]+)"?\s*\(', sql, re.IGNORECASE)
    if not table_match:
        return None, []

    table_name = table_match.group(1)

    # Extract column definitions
    columns = []

    # Get the content between parentheses
    paren_match = re.search(r'CREATE TABLE[^(]+\((.*)\)', sql, re.DOTALL | re.IGNORECASE)
    if not paren_match:
        return None, []

    table_content = paren_match.group(1)
    lines = table_content.split('\n')

    for line in lines:
        line = line.strip().rstrip(',')

        # Skip constraints and indexes
        skip_keywords = ['PRIMARY KEY', 'UNIQUE INDEX', 'INDEX', 'CHECK', 'CONSTRAINT', 'FOREIGN KEY', 'CREATE', 'ON TABLE', 'ON COLUMN', 'COMMENT']
        if not line or any(kw in line.upper() for kw in skip_keywords):
            continue

        # Skip closing parenthesis and semicolon
        if line.startswith(')') or line == ';':
            continue

        # Parse column definition
        # Format: "column_name" type [NOT NULL] [DEFAULT value] [PRIMARY KEY]
        col_match = re.match(r'"?([a-z_]+)"?\s+([a-z0-9_ ()]+)(.*)$', line, re.IGNORECASE)
        if not col_match:
            continue

        col_name = col_match.group(1)
        col_type = col_match.group(2).strip()
        col_attrs = col_match.group(3).strip()

        # Determine attributes
        not_null = 'NOT NULL' in col_attrs.upper()
        is_primary = 'PRIMARY KEY' in col_attrs.upper()
        auto_increment = 'serial' in col_type.lower()

        # Extract default value
        default = None
        default_match = re.search(r"DEFAULT\s+'([^']*)'", col_attrs, re.IGNORECASE)
        if default_match:
            default = f'"{default_match.group(1)}"'
        elif re.search(r'DEFAULT\s+(\d+)', col_attrs, re.IGNORECASE):
            num_match = re.search(r'DEFAULT\s+(\d+)', col_attrs, re.IGNORECASE)
            default = num_match.group(1)
        elif 'DEFAULT CURRENT_TIMESTAMP' in col_attrs.upper():
            default = None  # SeaORM handles this differently
        elif 'DEFAULT NULL' in col_attrs.upper():
            default = None

        columns.append({
            'name': col_name,
            'type': parse_postgres_type(col_type),
            'not_null': not_null,
            'is_primary': is_primary,
            'auto_increment': auto_increment,
            'default': default
        })

    return table_name, columns

def to_pascal_case(s: str) -> str:
    """Convert snake_case or SCREAMING_SNAKE_CASE to PascalCase"""
    parts = s.lower().split('_')
    return ''.join(word.capitalize() for word in parts)

def to_snake_case(s: str) -> str:
    """Convert PascalCase or camelCase to snake_case"""
    s = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', s)
    s = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s)
    return s.lower()

def generate_migration(table_name: str, columns: List[Dict], migration_num: int) -> str:
    """Generate SeaORM migration Rust code"""

    rust_table = to_pascal_case(table_name)

    code = f'''use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {{
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {{
        manager
            .create_table(
                Table::create()
                    .table({rust_table}::Table)
                    .if_not_exists()
'''

    # Add columns
    for col in columns:
        col_name_enum = f"{rust_table}::{to_pascal_case(col['name'])}"
        col_type = col['type']

        code += f'                    .col(\n'
        code += f'                        ColumnDef::new({col_name_enum})\n'
        code += f'                            .{col_type}\n'

        if col['auto_increment']:
            code += f'                            .auto_increment()\n'
            code += f'                            .primary_key()\n'
        elif col['is_primary']:
            code += f'                            .primary_key()\n'
            code += f'                            .not_null()\n'
        elif col['not_null']:
            code += f'                            .not_null()\n'
        else:
            code += f'                            .null()\n'

        if col['default'] and not col['auto_increment']:
            code += f'                            .default({col["default"]})\n'

        code += f'                    )\n'

    code += '''                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(''' + rust_table + '''::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ''' + rust_table + ''' {
    Table,
'''

    # Add column enums
    for col in columns:
        code += f'    {to_pascal_case(col["name"])},\n'

    code += '}\n'

    return code

def main():
    schema_file = Path(sys.argv[1] if len(sys.argv) > 1 else '../migrations/001_initial_schema.sql')
    output_dir = Path('migration/src')

    if not schema_file.exists():
        print(f"Error: Schema file not found: {schema_file}", file=sys.stderr)
        sys.exit(1)

    # Read schema
    with open(schema_file, 'r', encoding='utf-8') as f:
        schema_sql = f.read()

    # Extract only CREATE TABLE statements (up to semicolon, not including triggers)
    # Match CREATE TABLE ... ); and stop there
    table_pattern = r'CREATE TABLE[^;]*\);'
    table_matches = re.finditer(table_pattern, schema_sql, re.IGNORECASE | re.DOTALL)

    migrations = []
    migration_num = 1

    for match in table_matches:
        table_sql = match.group(0)

        table_name, columns = parse_create_table(table_sql)

        if not table_name or not columns:
            continue

        print(f"Generating migration {migration_num:03d} for table: {table_name} ({len(columns)} columns)")

        # Generate migration code
        migration_code = generate_migration(table_name, columns, migration_num)

        # Save to file
        timestamp = datetime.now().strftime('%Y%m%d') + f'_{migration_num:06d}'
        filename = f'm{timestamp}_create_{to_snake_case(table_name)}.rs'

        output_file = output_dir / filename
        with open(output_file, 'w') as f:
            f.write(migration_code)

        migrations.append((migration_num, table_name, filename))
        migration_num += 1

    print(f"\n✅ Generated {len(migrations)} migrations")
    print(f"📁 Output directory: {output_dir.absolute()}")

    # Update lib.rs to include all migrations
    lib_rs = output_dir / 'lib.rs'
    with open(lib_rs, 'w') as f:
        f.write('pub use sea_orm_migration::prelude::*;\n\n')

        # Module declarations
        for num, table, filename in migrations:
            mod_name = filename.replace('.rs', '')
            f.write(f'mod {mod_name};\n')

        f.write('\npub struct Migrator;\n\n')
        f.write('#[async_trait::async_trait]\n')
        f.write('impl MigratorTrait for Migrator {\n')
        f.write('    fn migrations() -> Vec<Box<dyn MigrationTrait>> {\n')
        f.write('        vec![\n')

        for num, table, filename in migrations:
            mod_name = filename.replace('.rs', '')
            f.write(f'            Box::new({mod_name}::Migration),\n')

        f.write('        ]\n')
        f.write('    }\n')
        f.write('}\n')

    print(f"📝 Updated {lib_rs}")
    print("\n🎉 All migrations generated successfully!")
    print("\nNext steps:")
    print("  1. Review generated migrations in migration/src/")
    print("  2. Run: cargo build --package migration")
    print("  3. Run: cargo run --package migration -- up")

if __name__ == '__main__':
    main()
