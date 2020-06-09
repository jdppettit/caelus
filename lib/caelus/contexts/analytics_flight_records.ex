defmodule Caelus.Contexts.AnalyticsFlightRecords do
  use Timex
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias Caelus.Schema.FlightRecord

  def get_data_by_airport(airport_icao) do
    current_day = get_current_day()
    beginning_day = get_beginning_day()

    query = from r in FlightRecord,
      where: r.departure_icao == ^airport_icao,
      or_where: r.arrival_icao == ^airport_icao,
      where: r.flight_date <= ^current_day,
      where: r.flight_date >= ^beginning_day,
      order_by: [desc: r.flight_date]
    
    case Caelus.Repo.all(query) do
      [_ | _] = records ->
        {:ok, records}
      {:error, error} ->
        Logger.error("#{__MODULE__} Error querying entry record #{inspect(error)}")
        {:error, :not_found}
      error ->
        Logger.error("##{__MODULE__} Unexpected error querying entry record #{inspect(error)}")
        {:error, :database_error}
    end
  end

  def get_current_day() do
    Timex.now()
  end

  def get_beginning_day(shift_days \\ -180) do
    Timex.now()
    |> Timex.shift(days: shift_days)
  end
end