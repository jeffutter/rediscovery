defmodule Rediscovery.Updater do
  use GenServer

  import Rediscovery.Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    {:ok, opts, {:continue, :update}}
  end

  def handle_continue(:update, %{update_interval: update_interval} = opts) do
    update(opts)
    schedule(update_interval)
    {:noreply, opts}
  end

  def handle_info(:update, %{update_interval: update_interval} = opts) do
    update(opts)
    schedule(update_interval)
    {:noreply, opts}
  end

  defp update(%{prefix: prefix, redix: redix, key_expiration: key_expiration, metadata_fn: metadata_fn}) do
    metadata = metadata_fn.()

    key = prefix <> ":" <> to_string(Node.self())

    case Redix.command(redix, ["SET", key, :erlang.term_to_binary(metadata), "PX", key_expiration]) do
      {:ok, "OK"} ->
        debug("Updater: SET #{key} = #{inspect(metadata)}")

      {:error, reason} ->
        error("Updater: failed to fetch keys: #{inspect(reason)}")
    end
  end

  def terminate(reason, %{redix: redix, prefix: prefix}) do
    key = prefix <> ":" <> to_string(Node.self())

    case Redix.command(redix, ["DEL", key]) do
      {:ok, _} ->
        debug("Updater: DEL #{key}")

      _ ->
        debug("Updater: Failed to DEL key #{key}")
    end

    info("Updater: exiting - #{inspect(reason)}")

    :ok
  end

  defp schedule(interval) do
    Process.send_after(self(), :update, interval)
  end
end
