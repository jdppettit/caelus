defmodule Scraper.Providers.AviationStack do
  use GenServer
  require Logger

  alias Caelus.Schema.FlightRecord

  @access_key Application.get_env(:caelus, :aviation_stack_api_key, nil)
  @run_scraper Application.get_env(:caelus, :run_scraper, true)
  @scrape_interval Application.get_env(:caelus, :scrape_interval, 86_400_000)

  def start_link(airport_icao) do
    Logger.debug("#{__MODULE__}: Starting scraper for aviation stack airport #{airport_icao}")
    GenServer.start_link(__MODULE__, airport_icao, name: name(airport_icao))
  end

  def init(airport_icao) do
    Process.send_after(self(), :scrape_data, 1_000)
    {:ok, airport_icao}
  end

  def handle_info(:scrape_data, airport_icao) do
    backoff? = if @run_scraper do
      Logger.info("#{__MODULE__}: Starting arrival data fetch")
      {resp_arr_code, resp_dep_val} = get_arrival_data(airport_icao)
      Logger.info("#{inspect(resp_arr_code)} / #{inspect(resp_dep_val)}")
      Logger.info("#{__MODULE__}: Arrival data fetch complete")

      Logger.info("#{__MODULE__}: Starting depature data fetch")
      {resp_dep_code, resp_dep_val} = get_depature_data(airport_icao)
      Logger.debug("#{inspect(resp_dep_code)}")
      Logger.info("#{__MODULE__}: Depature data fetch complete")

      resp_dep_code == :error or resp_arr_code == :error
    else
      Logger.warn("#{__MODULE__}: Scraper is set to NOT run, skipping run")
    end

    if backoff? do
      Logger.warn("#{__MODULE__}: Received error triggering backoff")
      Process.send_after(self(), :scrape_data, 60_000)
    else
      Logger.info("#{__MODULE__}: Queuing next scrape in #{@scrape_interval}ms")
      Process.send_after(self(), :scrape_data, @scrape_interval)
    end

    {:noreply, airport_icao}
  end

  def handle_info(:terminate, state) do
    {:stop, :normal, state}
  end

  def name(airport_icao) do
    String.to_atom("#{airport_icao}-scraper")
  end

  def get_depature_data(airport_icao) do
    arr_url = construct_url(:depature, airport_icao)
    case Scraper.HTTP.get(arr_url) do
      {:ok, results} -> 
        results["data"]
        |> Enum.map(fn r -> 
          unique_id = construct_unique_id(r)
          changeset_map = construct_map(r, unique_id)
          FlightRecord.upsert(changeset_map, unique_id)
        end)
        get_arrival_data(arr_url, results) # recurse
      {:error, error} ->
        {:error, error}
    end 
  end

  def get_depature_data(arr_url, results) do
    with {:ok, results} <- Scraper.HTTP.get_next(arr_url, results) do
      results["data"]
      |> Enum.map(fn r -> 
        unique_id = construct_unique_id(r)
        changeset_map = construct_map(r, unique_id)
        FlightRecord.upsert(changeset_map, unique_id)
      end)
      get_arrival_data(arr_url, results) # recrurse
    else
      {:none_remaining, _} ->
        :ok
      {:invalid_data, _} ->
        :ok
      {:error, error} ->
        {:error, error}
    end 
  end

  def get_arrival_data(airport_icao) do
    arr_url = construct_url(:arrival, airport_icao)
    case Scraper.HTTP.get(arr_url) do
      {:ok, results} -> 
        results["data"]
        |> Enum.map(fn r -> 
          unique_id = construct_unique_id(r)
          changeset_map = construct_map(r, unique_id)
          FlightRecord.upsert(changeset_map, unique_id)
        end)
        get_arrival_data(arr_url, results) # recurse
      {:error, error} ->
        {:error, error}
    end 
  end

  def get_arrival_data(arr_url, results) do
    with {:ok, results} <- Scraper.HTTP.get_next(arr_url, results) do
      results["data"]
      |> Enum.map(fn r -> 
        unique_id = construct_unique_id(r)
        changeset_map = construct_map(r, unique_id)
        FlightRecord.upsert(changeset_map, unique_id)
      end)
      get_arrival_data(arr_url, results) # recrurse
    else
      {:none_remaining, _} ->
        :ok
      {:invalid_data, _} ->
        :ok
      {:error, error} ->
        {:error, error}
    end 
  end

  def construct_url(type, airport_icao) do
    case type do
      :depature ->
        "http://api.aviationstack.com/v1/flights?access_key=#{@access_key}&dep_icao=#{airport_icao}"
      :arrival ->
        "http://api.aviationstack.com/v1/flights?access_key=#{@access_key}&arr_icao=#{airport_icao}"
    end 
  end

  def construct_map(r, unique_id) do
    changeset_map = %{
      unique_id: unique_id,
      flight_date: r["flight_date"],
      flight_status: r["flight_status"],
      departure_iata: r["departure"]["iata"],
      departure_icao: r["departure"]["icao"],
      departure_name: r["departure"]["name"],
      departure_timezone: r["departure"]["timezone"],
      departure_scheduled: r["departure"]["scheduled"],
      arrival_iata: r["arrival"]["iata"],
      arrival_icao: r["arrival"]["icao"],
      arrival_name: r["arrival"]["name"],
      arrival_timezone: r["arrival"]["timezone"],
      arrival_scheduled: r["arrival"]["scheduled"],
      airline_flight_number: r["flight"]["iata"],
      airline_name: r["airline"]["name"],
      airline_iata: r["airline"]["iata"],
      airline_icao: r["airline"]["icao"],
    }
    if not is_nil(r["aircraft"]) do
      changeset_map
      |> Map.put(:aircraft_registration, r["aircraft"]["registration"])
      |> Map.put(:aircraft_type_iata, r["aircraft"]["iata"])
      |> Map.put(:aircraft_type_icao, r["aircraft"]["icao"])
      |> Map.put(:aircraft_icao24, r["aircraft"]["icao24"])
    else
      changeset_map
    end
  end

  def construct_unique_id(r) do
    FlightRecord.generate_unique_id(
      r["departure"]["scheduled"],
      r["arrival"]["scheduled"],
      r["flight"]["iata"]
    )
  end
end
