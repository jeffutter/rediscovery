defmodule Rediscovery.Updater do
  @behaviour :gen_statem

  import Rediscovery.Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, opts, [])
  end

  def callback_mode do
    [:handle_event_function]
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    actions = [{:timeout, 0, :update}]

    {:ok, :waiting, opts, actions}
  end

  def handle_event(
        :timeout,
        :update,
        :waiting,
        %{
          prefix: prefix,
          redix: redix,
          update_interval: update_interval,
          key_expiration: key_expiration,
          metadata_fn: metadata_fn
        } = opts
      ) do
    metadata = metadata_fn.()

    key = prefix <> ":" <> to_string(Node.self())

    {:ok, "OK"} = Redix.command(redix, ["SET", key, :erlang.term_to_binary(metadata), "PX", key_expiration])

    debug("Updater: SET #{key} = #{inspect(metadata)}")

    actions = [{:timeout, update_interval, :update}]

    {:next_state, :waiting, opts, actions}
  end

  def terminate(reason, _state, %{redix: redix, prefix: prefix}) do
    key = prefix <> ":" <> to_string(Node.self())

    {:ok, _} = Redix.command(redix, ["DEL", key])
    debug("Updater: DEL #{key}")

    error("Updater: exiting - #{inspect(reason)}")

    :ok
  end
end
