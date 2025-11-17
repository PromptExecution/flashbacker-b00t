use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(InventoryLog::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(InventoryLog::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Pid)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Sku)
                            .string_len(35)
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Qty)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::QtyBefore)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Action)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Luser)
                            .string_len(10)
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Note)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Orderid)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(InventoryLog::Uuid)
                            .string_len(36)
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(InventoryLog::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum InventoryLog {
    Table,
    Mid,
    Pid,
    Sku,
    Qty,
    QtyBefore,
    Action,
    Luser,
    Note,
    Orderid,
    Uuid,
}
