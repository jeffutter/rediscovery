defmodule Rediscovery.PubSub do
  use GenServer

  import Rediscovery.Logger

  alias Rediscovery.State

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{pubsub: pubsub, redix: redix, prefix: prefix} = opts) do
    debug("PubSub: Starting")
    {:ok, ref} = Redix.PubSub.psubscribe(pubsub, "__keyspace@0__:#{prefix}:*", self())
    {:ok, "OK"} = Redix.command(redix, ["CONFIG", "SET", "notify-keyspace-events", "K$gx"])
    debug("PubSub: Connected")

    {:ok, Map.put(opts, :ref, ref)}
  end

  @impl true
  def handle_info({:redix_pubsub, _pubsub, ref, :psubscribed, _message}, %{ref: ref} = opts) do
    debug("PubSub: Subscribed")
    {:noreply, opts}
  end

  @impl true
  def handle_info(
        {:redix_pubsub, _pubsub, ref, :pmessage, %{channel: "__keyspace@0__:" <> key, payload: "set"}},
        %{redix: redix, prefix: prefix, ref: ref} = opts
      ) do
    node = String.trim_leading(key, prefix <> ":")

    {:ok, data} = Redix.command(redix, ["GET", prefix <> ":" <> node])

    if data do
      :ok = State.add(String.to_atom(node), :erlang.binary_to_term(data))
    end

    {:noreply, opts}
  end

  @impl true
  def handle_info(
        {:redix_pubsub, _pubsub, ref, :pmessage, %{channel: "__keyspace@0__:" <> key, payload: "expired"}},
        %{prefix: prefix, ref: ref} = opts
      ) do
    node = String.trim_leading(key, prefix <> ":")

    :ok = State.remove(node)

    {:noreply, opts}
  end

  def handle_info(
        {:redix_pubsub, _pubsub, ref, :pmessage, %{channel: "__keyspace@0__:" <> key, payload: "del"}},
        %{prefix: prefix, ref: ref} = opts
      ) do
    node = String.trim_leading(key, prefix <> ":")

    :ok = State.remove(node)

    {:noreply, opts}
  end

  @impl true
  def handle_info(
        {:redix_pubsub, _pubsub, ref, :pmessage, %{channel: "__keyspace@0__:" <> _key, payload: "expire"}},
        %{ref: ref} = opts
      ) do
    {:noreply, opts}
  end

  @impl true
  def handle_info(
        {:redix_pubsub, _pubsub, ref, :pmessage, %{channel: "__keyspace@0__:" <> _key} = msg},
        %{ref: ref} = opts
      ) do
    debug("PubSub: unknown pubsub message: #{inspect(msg)}")
    {:noreply, opts}
  end
end
