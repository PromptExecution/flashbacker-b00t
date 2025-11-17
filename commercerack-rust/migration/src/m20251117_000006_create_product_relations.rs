use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(ProductRelations::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ProductRelations::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::Pid)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::ChildPid)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::Relation)
                            .string_len(16)
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::Qty)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::IsActive)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(ProductRelations::ListPos)
                            .small_integer()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(ProductRelations::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum ProductRelations {
    Table,
    Mid,
    Pid,
    ChildPid,
    Relation,
    Qty,
    IsActive,
    ListPos,
}
