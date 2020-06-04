defmodule Scraper.Providers.AviationStack do
  use GenServer
  require Logger

  alias Caelus.Schema.FlightRecord

  @default_interval 21_600_000 # six hours
  @access_key Application.get_env(:caelus, :aviation_stack_api_key, nil)

  def start_link(airport_icao) do
    Logger.debug("#{__MODULE__}: Starting scraper for aviation stack airport #{airport_icao}")
    GenServer.start_link(__MODULE__, airport_icao, name: name(airport_icao))
  end

  def init(airport_icao) do
    Process.send_after(self(), :scrape_data, @default_interval)
    {:ok, airport_icao}
  end

  def handle_info(:scrape_data, airport_icao) do
    Process.send_after(self(), :scrape_data, @default_interval)
    {:noreply, airport_icao}
  end

  def handle_info(:terminate, state) do
    {:stop, :normal, state}
  end

  def name(airport_icao) do
    String.to_atom("#{airport_icao}-scraper")
  end

  def get_arrival_data(airport_icao) do
    arr_url = construct_url(:arrival, airport_icao)
    {:ok, results} = Scraper.HTTP.get(arr_url)
    results["data"]
    |> Enum.map(fn r -> 
      unique_id = FlightRecord.generate_unique_id(
        r["depature"]["scheduled"],
        r["arrival"]["scheduled"],
        r["flight"]["iata"]
      )
      changeset_map = %{
        unique_id: unique_id,
        flight_date: r["flight_date"]
        flight_status: r["flight_status"],
        depature_iata: r["depature"]["iata"],
        depature_icao: r["depature"]["icao"],
        depature_name: r["depature"]["name"],
        depature_timezone: r["depature"]["timezone"],
        depature_scheduled: r["depature"]["scheduled"],
        arrival_iata: r["arrival"]["iata"],
        arrival_icao: r["arrival"]["icao"],
        arrival_name: r["arrival"]["name"],
        arrival_timezone: r["arrival"]["timezone"],
        arrival_scheduled: r["arrival"]["scheduled"],
        airline_flight_number: r["flight"]["number"],
        airline_name: r["airline"]["name"],
        airline_iata: r["airline"]["iata"],
        airline_icao: r["airline"]["icao"],
      }
      changeset_map = if not is_nil(r["aircraft"]) do
        changeset_map
        |> Map.put(:aircraft_registration, r["aircraft"]["registration"])
        |> Map.put(:aircraft_type_iata, r["aircraft"]["iata"])
        |> Map.put(:aircraft_type:icao, r["aircraft"]["icao"])
        |> Map.put(:aircraft_icao24, r["aircraft"]["icao24"])
      end
      {:ok, changeset} = FlightRecord.create_changeset(changeset_map)
      {:ok, model} = FlightRecord.insert(changeset)
      get_arrival_data(arr_url, results)
    end)
  end

  def get_arrival_data(url, results) do
    {:ok, results} = Scraper.HTTP.get_next(results)
    results["data"]
    |> Enum.map(fn r -> 
      unique_id = FlightRecord.generate_unique_id(
        r["depature"]["scheduled"],
        r["arrival"]["scheduled"],
        r["flight"]["iata"]
      )
      changeset_map = %{
        unique_id: unique_id,
        flight_date: r["flight_date"]
        flight_status: r["flight_status"],
        depature_iata: r["depature"]["iata"],
        depature_icao: r["depature"]["icao"],
        depature_name: r["depature"]["name"],
        depature_timezone: r["depature"]["timezone"],
        depature_scheduled: r["depature"]["scheduled"],
        arrival_iata: r["arrival"]["iata"],
        arrival_icao: r["arrival"]["icao"],
        arrival_name: r["arrival"]["name"],
        arrival_timezone: r["arrival"]["timezone"],
        arrival_scheduled: r["arrival"]["scheduled"],
        airline_flight_number: r["flight"]["number"],
        airline_name: r["airline"]["name"],
        airline_iata: r["airline"]["iata"],
        airline_icao: r["airline"]["icao"],
      }
      changeset_map = if not is_nil(r["aircraft"]) do
        changeset_map
        |> Map.put(:aircraft_registration, r["aircraft"]["registration"])
        |> Map.put(:aircraft_type_iata, r["aircraft"]["iata"])
        |> Map.put(:aircraft_type:icao, r["aircraft"]["icao"])
        |> Map.put(:aircraft_icao24, r["aircraft"]["icao24"])
      end
      {:ok, changeset} = FlightRecord.create_changeset(changeset_map)
      {:ok, model} = FlightRecord.insert(changeset)
      get_arrival_data(arr_url, results)
  end

  def construct_url(type, airport_icao) do
    case type do
      :depature ->
        "http://api.aviationstack.com/v1/flights?access_key=#{@access_key}&dep_icao=KMSP"
      :arrival ->
        "http://api.aviationstack.com/v1/flights?access_key=#{@access_key}&arr_icao=KMSP"
    end 
  end
end
