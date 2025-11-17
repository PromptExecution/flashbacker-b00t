use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(AmazonDocumentContents::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Docid)
                            .big_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Msgid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Feed)
                            .string()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Sku)
                            .string_len(35)
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::Debug)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocumentContents::AckGmt)
                            .integer()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(AmazonDocumentContents::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum AmazonDocumentContents {
    Table,
    Mid,
    Docid,
    Msgid,
    Feed,
    Sku,
    Debug,
    AckGmt,
}
