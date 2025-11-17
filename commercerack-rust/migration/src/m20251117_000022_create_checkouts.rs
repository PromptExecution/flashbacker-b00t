use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Checkouts::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(Checkouts::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::Sdomain)
                            .string_len(50)
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::Cartid)
                            .string_len(36)
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::Cid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::HandledGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::ClosedGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(Checkouts::Assistid)
                            .string_len(5)
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(Checkouts::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum Checkouts {
    Table,
    Mid,
    Username,
    Sdomain,
    Cartid,
    Cid,
    HandledGmt,
    ClosedGmt,
    Assistid,
}
