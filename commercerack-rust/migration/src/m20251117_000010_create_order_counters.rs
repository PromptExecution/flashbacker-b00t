use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(OrderCounters::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(OrderCounters::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderCounters::Merchant)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderCounters::Counter)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderCounters::LastPid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(OrderCounters::LastServer)
                            .string_len(25)
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(OrderCounters::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum OrderCounters {
    Table,
    Mid,
    Merchant,
    Counter,
    LastPid,
    LastServer,
}
