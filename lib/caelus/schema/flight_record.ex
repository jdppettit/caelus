defmodule Caelus.Schema.FlightRecord do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  schema "flight_records" do
    field :unique_id, :string
    
    field :flight_date, :date
    field :flight_status, :string

    field :departure_iata, :string
    field :departure_icao, :string
    field :departure_name, :string
    field :departure_timezone, :string
    field :depature_scheduled, :utc_datetime

    field :arrival_iata, :string
    field :arrival_icao, :string
    field :arrival_name, :string
    field :arrival_timezone, :string
    field :arrival_scheduled, :utc_datetime

    field :airline_flight_number, :integer
    field :airline_iata, :string
    field :airline_icao, :string

    field :aircraft_registration, :string
    field :aircraft_type_iata, :string
    field :aircraft_type_icao, :string
    field :aircraft_icao24, :string

    timestamps()
  end

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, __schema__(:fields))
    |> validate_required([
      :target, :type
    ])
  end

  def create_changeset(%__MODULE__{} = model,
    type, target, interval, check_id, last_sent
  ) do
    changeset = __MODULE__.changeset(model, %{
      type: type,
      last_sent: last_sent,
      check_id: check_id,
      target: target,
      interval: interval
    })
    case changeset.valid? do
      true ->
        {:ok, changeset}
      false ->
        Logger.error("#{__MODULE__}: Changeset invalid #{inspect(changeset)}")
        {:error, :changeset_invalid}
    end
  end

  def create_changeset(type, target, interval, check_id, last_sent) do
    changeset = __MODULE__.changeset(%__MODULE__{}, %{
      type: type,
      last_sent: last_sent,
      interval: interval,
      check_id: check_id,
      target: target
    })
    case changeset.valid? do
      true ->
        {:ok, changeset}
      false ->
        Logger.error("#{__MODULE__}: Changeset invalid #{inspect(changeset)}")
        {:error, :changeset_invalid}
    end
  end

  def create_changeset(map) do
    changeset = __MODULE__.changeset(%__MODULE__{}, map)
    case changeset.valid? do
      true ->
        {:ok, changeset}
      false ->
        Logger.error("#{__MODULE__}: Changeset invalid #{inspect(changeset)}")
        {:error, :changeset_invalid}
    end
  end

  def create_changeset(model, map) do
    changeset = __MODULE__.changeset(model, map)
    case changeset.valid? do
      true ->
        {:ok, changeset}
      false ->
        Logger.error("#{__MODULE__}: Changeset invalid #{inspect(changeset)}")
        {:error, :changeset_invalid}
    end
  end

  def insert(changeset) do
    case Caelus.Repo.insert(changeset) do
      {:ok, model} ->
        {:ok, model}
      {_, _} ->
        Logger.error("#{__MODULE__}: Problem inserting record #{inspect(changeset)}")
        {:error, :database_error}
    end
  end

  def update(changeset) do
    case Caelus.Repo.update(changeset) do
      {:ok, model} ->
        {:ok, model}
      {_, _} ->
        Logger.error("#{__MODULE__}: Problem updating record #{inspect(changeset)}")
        {:error, :database_error}
    end
  end
end
