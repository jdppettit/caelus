defmodule Scraper.Providers.AviationStack do
    use GenServer
    require Logger

    @default_interval 21_600_000 # six hours

    def start_link(airport_icao) do
      Logger.debug("#{__MODULE__}: Starting #{type} check for check #{id}")
      GenServer.start_link(__MODULE__, check, name: name(airport_icao))
    end

    def init(airport_icao) do
      Process.send_after(self(), :scrape_data, @default_interval)
      {:ok, airport_icao}
    end

    def handle_info(:scrape_data, airport_icao do
      Process.send_after(self(), :scrape_data, @default_interval)
      {:noreply, %{check: check}}
    end

    def handle_info(:terminate, state) do
      {:stop, :normal, state}
    end

    def name(airport_icao) do
      String.to_atom("#{airport_icao}-scraper")
    end
  end
end