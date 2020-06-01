defmodule Scraper.ScraperSupervisor do
  use DynamicSupervisor

  require Logger

  @airports ['KMSP']

  def start_link(_arg) do
    Logger.debug("#{__MODULE__}: ScraperSupervisor starting")
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    schedule_scrapers()
  end

  def init(:ok) do
    DynamicSupervisor.init([
      strategy: :one_for_one,
      max_restarts: 1000,
      max_seconds: 5
    ])
  end

  def schedule_scrapers do
    Enum.map(@airpots, fn airport_icao -> 
      Logger.info("#{__MODULE__}: Starting scraper for airport #{airport_icao}")
      DynamicSupervisor.start_child(__MODULE__, %{
        id: Scraper.AviationStack,
        start: {Scraper.AviationStack, :start_link, [airport_icao]}
      })
    end)
  end

  def get_child_by_name(name) do
    Process.whereis(String.to_atom(name))
  end

  def kill_child(name) do
    case Process.whereis(String.to_atom(name)) do
      pid when not is_nil(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        Logger.info("#{__MODULE__}: Terminating child #{inspect(name)} because of update")
        {:ok, nil}
      nil ->
        {:error, :not_running}
      _error ->
        {:error, :unexpected_error}
    end
  end
end
