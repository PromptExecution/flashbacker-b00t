use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(AmazonOrderEvents::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Type)
                            .string()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Orderid)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Data)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::LockGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::ProcessedGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::ProcessedDocid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonOrderEvents::Attempts)
                            .small_integer()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(AmazonOrderEvents::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum AmazonOrderEvents {
    Table,
    Username,
    Mid,
    Type,
    Orderid,
    Data,
    LockGmt,
    ProcessedGmt,
    ProcessedDocid,
    Attempts,
}
