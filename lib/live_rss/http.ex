defmodule LiveRSS.HTTP do
  @moduledoc """
  This module defines functions to make HTTP requests.
  """

  require Logger

  @spec get(String.t()) :: {:ok, %{}} | :error
  @doc """
  Returns a %{} map from a RSS feed URL. Returns {:ok, %{}} or
  logs the error returning :error.
  """
  def get(feed_url) do
    try do
      with {:ok, {{_, status, _}, _headers, body}} <-
             :httpc.request(:get, {feed_url, []}, [ssl: :httpc.ssl_verify_host_options(true)], []),
           status when status in 200..299 <- status,
           {:ok, %{} = feed} <- FastRSS.parse_rss(IO.iodata_to_binary(body)) do
        {:ok, feed}
      else
        error ->
          Logger.error("LiveRSS: failed to get feed. Reason: #{inspect(error)}")
          :error
      end
    rescue
      ArgumentError ->
        Logger.error("LiveRSS: failed to get feed. Reason: Not XML")
        :error
    end
  end
end
