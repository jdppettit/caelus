defmodule Analytics.Computer.Terra do
  use GenServer
  require Logger

  alias Caelus.Contexts.AnalyticsFlightRecords, as: FlightRecord

  @run_analytics Application.get_env(:caelus, :run_analytics, true)
  @analytics_interval Application.get_env(:caelus, :analytics_interval, 1_000)

  def start_link(airport_icao) do
    Logger.debug("#{__MODULE__}: Starting computer Terra for airport #{airport_icao}")
    GenServer.start_link(__MODULE__, airport_icao, name: name(airport_icao))
  end

  def init(airport_icao) do
    Process.send_after(self(), :scrape_data, 1_000)
    {:ok, airport_icao}
  end

  def handle_info(:scrape_data, airport_icao) do
    Logger.info("#{__MODULE__}: Terra processing data for #{airport_icao}")
    compute(airport_icao)
    Process.send_after(self(), :scrape_data, @analytics_interval)
    {:noreply, airport_icao}
  end

  def handle_info(:terminate, state) do
    {:stop, :normal, state}
  end

  def name(airport_icao) do
    String.to_atom("#{airport_icao}-terra")
  end

  def compute(airport_icao) do
    with {:ok, records} <- FlightRecord.get_data_by_airport(airport_icao) do
      airline_data = compile_airline_frequency(records)
      #aircraft_data = compile_aircraft_frequency(records)
      #source_data = compile_source_frequency(records)
      #destination_data = compile_destination_frequency(records)
    else
      _ ->
        nil
    end
  end

  def compile_airline_frequency(records) do
    frequency_map = records
    |> Enum.reduce(%{}, fn r, acc -> 
      if Map.has_key?(acc, r.airline_name) do
        current_value = Map.get(acc, r.airline_name)
        acc = Map.replace!(acc, r.airline_name, current_value + 1)
      else
        acc = Map.put(acc, r.airline_name, 1)
      end
    end)
    
    extracted_values = extract_counts(frequency_map) |> IO.inspect(label: "extracted values")
    std_dev = calculate_standard_deviation(extracted_values) |> IO.inspect(label: "std dev")
    mean = calculate_mean(extracted_values) |> IO.inspect(label: "mean")
    filtered_values = filter_outliers(extracted_values, std_dev, mean) |> IO.inspect(label: "filtered")
  end

  def compile_aircraft_frequency(records) do
    frequency_map = records
    |> Enum.reduce(%{}, fn r, acc -> 
      if Map.has_key?(acc, r.airline_name) do
        current_value = Map.get(acc, r.aircraft_type_iata)
        acc = Map.replace!(acc, r.aircraft_type_iata, current_value + 1)
      else
        acc = Map.put(acc, r.aircraft_type_iata, 1)
      end
    end)
    
    extracted_values = extract_counts(frequency_map) |> IO.inspect(label: "extracted values")
    std_dev = calculate_standard_deviation(extracted_values) |> IO.inspect(label: "std dev")
    mean = calculate_mean(extracted_values) |> IO.inspect(label: "mean")
    filtered_values = filter_outliers(extracted_values, std_dev, mean) |> IO.inspect(label: "filtered")
  end

  def extract_counts(map) do
    Map.keys(map)
    |> Enum.map(fn k -> 
      Map.get(map, k)
    end)
  end

  def calculate_standard_deviation(values) do
    Numerix.Statistics.std_dev(values)
  end

  def calculate_mean(values) do
    Numerix.Statistics.mean(values)
  end

  def filter_outliers(values, std_dev, mean) do
    values 
    |> Enum.filter(fn v -> 
      abs((mean - v) / std_dev) <= 1
    end)
  end
end