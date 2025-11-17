use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(OrderEvents::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(OrderEvents::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::Prt)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::Orderid)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::Event)
                            .string_len(10)
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::LockId)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::LockGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderEvents::Attempts)
                            .small_integer()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(OrderEvents::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum OrderEvents {
    Table,
    Mid,
    Username,
    Prt,
    Orderid,
    Event,
    LockId,
    LockGmt,
    Attempts,
}
