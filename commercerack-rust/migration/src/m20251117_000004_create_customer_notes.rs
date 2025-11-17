use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(CustomerNotes::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(CustomerNotes::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerNotes::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerNotes::Cid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerNotes::Luser)
                            .string_len(10)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerNotes::Note)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerNotes::Type)
                            .string_len(3)
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(CustomerNotes::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum CustomerNotes {
    Table,
    Mid,
    Username,
    Cid,
    Luser,
    Note,
    Type,
}
