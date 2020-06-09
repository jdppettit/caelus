defmodule Caelus.Repo.Migrations.AddAircraftTypes do
  use Ecto.Migration

  def change do
    create table("aircraft_types") do
      add :iata_type, :string
      add :name, :string
    end

    create unique_index(:aircraft_types, [:iata_type])
  end
end
