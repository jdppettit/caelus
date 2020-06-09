defmodule Scraper.HTTP do
  require Logger

  def get(path) do
    Logger.info("#{__MODULE__}: Request begin GET #{path}")
    res = HTTPoison.get(
      path
    )
    |> handle_response("get")
  end

  def get_next(path, %{
    "pagination" => %{
      "limit" => limit,
      "offset" => offset,
      "total" => total,
      "count" => count
    }
  } = res) when count > 0 do
    Logger.info("Stats: limit #{limit} offset #{offset} total #{total} count #{count}")
    new_offset = offset + limit
    Logger.info("#{__MODULE__}: Request begin get next #{path}&offset=#{new_offset}")
    res = HTTPoison.get(
      "#{path}&offset=#{new_offset}"
    )
    |> handle_response("get_next")
  end

  def get_next(path, %{
    "pagination" => %{
      "limit" => limit,
      "offset" => offset,
      "total" => total,
      "count" => count
    }
  } = res) when count == 0 do
    Logger.info("#{__MODULE__}: Request begin get next with zero count #{path}")
    {:none_remaining, []}
  end

  def get_next(_path, _res) do
    Logger.info("#{__MODULE__}: Request begin get next with incorrect params")
    {:invalid_data, []}
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

  defp handle_response({:error, error}, action) do
    case error do
      %HTTPoison.Error{id: nil, reason: timeout} ->
        {:error, :timeout_exceeded}
      _ ->
        Logger.error("#{__MODULE__}: Got error #{inspect(error)} for action #{action}")
        {:error, :unknown}
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