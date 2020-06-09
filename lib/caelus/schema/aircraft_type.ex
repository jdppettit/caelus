defmodule Caelus.Schema.AircraftType do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  schema "aircraft_types" do
    field :iata_type, :string
    field :name, :string
  end

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, __schema__(:fields))
    |> validate_required([
      :iata_type,
      :name
    ])
    |> unique_constraint(:iata_type)
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

  def upsert(changeset, iata_type) do
    case Caelus.Repo.get_by(__MODULE__, [iata_type: iata_type]) do
      model when not is_nil(model) ->
        Logger.debug("#{__MODULE__}: Found existing record, updating")
        __MODULE__.changeset(model, changeset)
        |> __MODULE__.update
      model when is_nil(model) ->
        Logger.debug("#{__MODULE__}: No existing record found, inserting")
        __MODULE__.changeset(%__MODULE__{}, changeset)
        |> __MODULE__.insert
    end 
  end

  def data_loaded? do
    types = Caelus.Repo.all(__MODULE__)
    length(types) > 0
  end

  def get_name_by_iata(iata_type) do
    case Caelus.Repo.get_by(__MODULE__, [iata_type: iata_type]) do 
      model when not is_nil(model) ->
        model.name
      e ->
        IO.inspect(e, label: "e")
        "Unknown Type"
    end 
  end
end
