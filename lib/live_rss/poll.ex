defmodule LiveRSS.Poll do
  @moduledoc """
  LiveRSS.Poll is a GenServer that polls a RSS feed periodically.

  ```elixir
  LiveRSS.Poll.start_link(name: :live_rss_blog, url: "https://blog.test/feed.rss", refresh_every: :timer.hours(2))
  LiveRSS.Poll.start_link(name: :live_rss_videos, url: "https://videos.test/feed.rss", refresh_every: :timer.hours(1))
  LiveRSS.Poll.start_link(name: :live_rss_photos, url: "https://photos.test/feed.rss", refresh_every: :timer.minutes(10))

  %{} = LiveRSS.get(:live_rss_blog)
  ```

  Use `LiveRSS.Poll.start_link/1` to start the GenServer. You can use the following
  options as the example:
  * `name`: the atom name of the process that will be used to retrieve the feed later
  * `url`: the URL of the RSS feed
  * `refresh_every`: the frequency the feed will be fetched by the GenServer
  * on_cov: ([] -> :ok) callback

  You can use `LiveRSS.get/1` to retrieve the feed as a `%{}` map.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    with :ok <- validate_uri(opts),
         {:ok, name} <- validate_name(opts),
         do: GenServer.start_link(__MODULE__, opts, name: name)
  end

  defp validate_name(opts) do
    case opts[:name] do
      nil -> {:error, :invalid_name}
      name when is_atom(name) -> {:ok, name}
      _any -> {:error, :invalid_name}
    end
  end

  defp validate_uri(opts) do
    with url when is_binary(url) <- opts[:url],
         %URI{} = uri <- URI.parse(url),
         %URI{} = uri when is_binary(uri.scheme) and is_binary(uri.host) and is_binary(uri.path) <-
           uri do
      :ok
    else
      _any -> {:error, :invalid_url}
    end
  end

  @doc """
  Returns a `%{}`. If the feed fails to be fetched, it returns nil and logs
  error.
  """
  @spec get(atom()) :: %{} | nil
  def get(process_name) do
    process_name
    |> Process.whereis()
    |> GenServer.call(:get_feed)
  end

  @default_state [refresh_every: :timer.hours(1), url: nil, feed: nil, on_cov: nil]

  @impl true
  def init(state) do
    Logger.info("LiveRSS: Started #{state[:name]} polling every #{state[:refresh_every]}ms")

    state = Keyword.merge(@default_state, state) |> Map.new()
    schedule_polling(state)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_feed, _from, state) do
    case state[:feed] do
      %{} = feed ->
        {:reply, feed, state}

      nil ->
        state = put_feed(state)
        {:reply, state[:feed], state}
    end
  end

  @impl true
  def handle_info(:poll, state) do
    state = put_feed(state)
    schedule_polling(state)

    {:noreply, state}
  end

  defp schedule_polling(state) do
    Process.send_after(self(), :poll, state[:refresh_every])
  end

  defp put_feed(state) do
    case LiveRSS.HTTP.get(state[:url]) do
      {:ok, %{} = new_feed} ->
        Logger.info("LiveRSS: Updated #{state[:name]} data")
        notify_if_enabled(state, new_feed)
        Map.put(state, :feed, new_feed)

      _any ->
        state
    end
  end

  defp notify_if_enabled(%{on_cov: nil} = _state, _new_feed), do: :ok
  defp notify_if_enabled(%{feed: nil} = _state, _new_feed), do: :ok

  defp notify_if_enabled(%{on_cov: callback} = state, new_feed) do
    diff = diff_feeds(state[:feed], new_feed)

    notify(callback, diff)
  end

  defp diff_feeds(previous, new) do
    previous_set = MapSet.new(previous["items"])
    new_set = MapSet.new(new["items"])

    MapSet.difference(new_set, previous_set) |> MapSet.to_list()
  end

  @spec notify(([] -> :ok), [term()]) :: :ok
  defp notify(callback, values)

  defp notify(_callback, []), do: :ok

  defp notify(callback, values) do
    callback.(values)
  end
end
