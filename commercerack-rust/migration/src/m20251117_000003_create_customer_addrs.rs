use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(CustomerAddrs::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(CustomerAddrs::Mid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Cid)
                            .integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Guid)
                            .string_len(36)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::IsDefault)
                            .small_integer()
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Label)
                            .string_len(15)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Firstname)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Lastname)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::City)
                            .string_len(30)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::State)
                            .string_len(20)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Zip)
                            .string_len(10)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Country)
                            .string_len(2)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Phone)
                            .string_len(12)
                            .null()
                    )
                    .col(
                        ColumnDef::new(CustomerAddrs::Company)
                            .string_len(30)
                            .null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(CustomerAddrs::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum CustomerAddrs {
    Table,
    Mid,
    Cid,
    Guid,
    IsDefault,
    Label,
    Firstname,
    Lastname,
    City,
    State,
    Zip,
    Country,
    Phone,
    Company,
}
