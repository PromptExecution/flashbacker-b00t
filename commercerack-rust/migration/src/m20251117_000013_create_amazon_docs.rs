use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(AmazonDocs::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(AmazonDocs::Username)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Prt)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Doctype)
                            .string_len(40)
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Docid)
                            .big_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Docbody)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::RetrievedGmt)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::ResponseDocid)
                            .big_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::ResponseBody)
                            .text()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::ResentDocid)
                            .big_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(AmazonDocs::Attempts)
                            .small_integer()
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(AmazonDocs::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum AmazonDocs {
    Table,
    Username,
    Mid,
    Prt,
    Doctype,
    Docid,
    Docbody,
    RetrievedGmt,
    ResponseDocid,
    ResponseBody,
    ResentDocid,
    Attempts,
}
