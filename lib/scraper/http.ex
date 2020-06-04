defmodule Scraper.HTTP do
  require Logger

  def get(path) do
    Logger.info("#{__MODULE__}: Request begin GET #{path}")
    res = HTTPoison.get(
      path
    )
    |> handle_response("get")
  end

  defp handle_response({:ok, resp}, action) do
    case resp.status_code do
      code when code in 200..299 ->
        Logger.info("#{__MODULE__}: Handle response success: Received a #{code} for #{action}")
        send_success(resp)
      code when code in 400..499 ->
        Logger.info("#{__MODULE__}: Handle response failed: Received a #{code} for #{action} Body: #{inspect(resp.body)}")
        send_not_found(resp)
      code when code in 500..599 ->
        Logger.info("#{__MODULE__}: Handle response failed: Received a #{code} for #{action} Body: #{inspect(resp.body)}")
        send_failure(resp, action)
      _ ->
        Logger.info("#{__MODULE__}: Handle response failed: Received a #{inspect(resp.status_code)} Body: #{inspect(resp.body)}")
        send_failure(resp, action)
    end 
  end

  defp send_success(resp) do
    {:ok, Poison.decode!(resp.body)}
  end

  defp send_failure(%{status_code: status_code} = _resp, action) do
    {:error, %{message: "request failed for #{action}", status_code: status_code}}
  end

  defp send_not_found(_resp) do
    {:error, :not_found}
  end
end