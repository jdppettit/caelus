defmodule Analytics.AnalyticsSupervisor do
  use DynamicSupervisor

  require Logger

  @airports Application.get_env(:caelus, :airports, [])

  def start_link(_arg) do
    Logger.debug("#{__MODULE__}: ScraperSupervisor starting")
    v = DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    schedule_computers()
    v
  end

  def init(:ok) do
    DynamicSupervisor.init([
      strategy: :one_for_one,
      max_restarts: 1000,
      max_seconds: 5
    ])
  end

  def schedule_computers do
    Enum.map(@airports, fn airport_icao -> 
      Logger.info("#{__MODULE__}: Starting computer for airport #{airport_icao} data")
      DynamicSupervisor.start_child(__MODULE__, %{
        id: Analytics.Computer.Terra,
        start: {Analytics.Computer.Terra, :start_link, [airport_icao]}
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
