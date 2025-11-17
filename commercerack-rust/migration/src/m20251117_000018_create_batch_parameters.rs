use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(BatchParameters::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(BatchParameters::Uuid)
                            .string_len(36)
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Luser)
                            .string_len(10)
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Title)
                            .string_len(80)
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::LastrunTs)
                            .timestamp()
                            .null()
                            .default("0000-00-00 00:00:00")
                    )
                    .col(
                        ColumnDef::new(BatchParameters::LastjobId)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::BatchExec)
                            .string_len(45)
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Apiversion)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(BatchParameters::Yaml)
                            .text()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(BatchParameters::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum BatchParameters {
    Table,
    Uuid,
    Mid,
    Username,
    Luser,
    Title,
    LastrunTs,
    LastjobId,
    BatchExec,
    Apiversion,
    Yaml,
}
