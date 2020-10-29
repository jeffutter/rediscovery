defmodule Rediscovery.Poller do
  @behaviour :gen_statem

  alias Rediscovery.State

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
    actions = [{:timeout, 0, :update}]

    {:ok, :waiting, opts, actions}
  end

  def handle_event(
        :timeout,
        :update,
        :waiting,
        %{redix: redix, prefix: prefix, poll_interval: poll_interval} = opts
      ) do
    debug("Poller: Polling")

    key = prefix <> ":*"

    {:ok, keys} = Redix.command(redix, ["KEYS", key])

    res =
      case keys do
        [] ->
          []

        keys ->
          {:ok, res} = Redix.command(redix, ["MGET" | keys])
          Enum.zip(keys, res)
      end

    Enum.each(res, fn {key, data} ->
      node =
        key
        |> String.trim_leading(prefix <> ":")
        |> String.to_atom()

      :ok = State.add(String.to_atom(node), :erlang.binary_to_term(data))
    end)

    actions = [{:timeout, poll_interval, :update}]

    {:next_state, :waiting, opts, actions}
  end
end