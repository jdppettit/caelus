defmodule Caelus.Repo.Migrations.BaseMigration do
  use Ecto.Migration

  def change do
    create table("flight_records") do
      add :unique_id, :string

      add :flight_date, :date
      add :flight_status, :string

      add :departure_iata, :string
      add :departure_icao, :string
      add :departure_name, :string
      add :departure_timezone, :string
      add :depature_scheduled, :utc_datetime
  
      add :arrival_iata, :string
      add :arrival_icao, :string
      add :arrival_name, :string
      add :arrival_timezone, :string
      add :arrival_scheduled, :utc_datetime
  
      add :airline_flight_number, :string
      add :airline_name, :string
      add :airline_iata, :string
      add :airline_icao, :string
  
      add :aircraft_registration, :string
      add :aircraft_type_iata, :string
      add :aircraft_type_icao, :string
      add :aircraft_icao24, :string    

      timestamps()
    end

    create unique_index(:flight_records, [:unique_id])
  end
end
