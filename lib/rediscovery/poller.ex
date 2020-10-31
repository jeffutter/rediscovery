defmodule Rediscovery.Poller do
  use GenServer

  alias Rediscovery.State

  import Rediscovery.Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def renew(server \\ __MODULE__) do
    GenServer.call(server, :renew)
  end

  def init(opts) do
    {:ok, opts, {:continue, :renew}}
  end

  def handle_continue(:renew, %{poll_interval: poll_interval} = opts) do
    do_renew(opts)
    schedule(poll_interval)
    {:noreply, opts}
  end

  def handle_call(:renew, _from, opts) do
    do_renew(opts)
    {:reply, :ok, opts}
  end

  def handle_info(:renew, %{poll_interval: poll_interval} = opts) do
    do_renew(opts)
    schedule(poll_interval)
    {:noreply, opts}
  end

  defp schedule(interval) do
    Process.send_after(self(), :renew, interval)
  end

  defp do_renew(%{redix: redix, prefix: prefix}) do
    debug("Poller: Renewing")

    key = prefix <> ":*"

    case Redix.command(redix, ["KEYS", key]) do
      {:ok, []} ->
        []

      {:ok, keys} ->
        {:ok, res} = Redix.command(redix, ["MGET" | keys])

        keys
        |> Enum.zip(res)
        |> Enum.map(fn {key, data} ->
          node =
            key
            |> String.trim_leading(prefix <> ":")
            |> String.to_atom()

          {node, :erlang.binary_to_term(data)}
        end)
        |> State.replace()

      {:error, reason} ->
        error("Poller: failed to fetch keys: #{inspect(reason)}")
    end
  end
end
