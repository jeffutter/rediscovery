defmodule Rediscovery.Supervisor do
  @moduledoc """
  Documentation for `Rediscovery`.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts \\ []) do
    host = Keyword.fetch!(opts, :host)
    port = Keyword.fetch!(opts, :port)
    prefix = Keyword.fetch!(opts, :prefix)
    poll_interval = Keyword.fetch!(opts, :poll_interval)
    update_interval = Keyword.fetch!(opts, :update_interval)
    key_expiration = Keyword.fetch!(opts, :key_expiration)
    metadata_fn = Keyword.fetch!(opts, :metadata_fn)
    node_change_fn = Keyword.fetch!(opts, :node_change_fn)

    redix = Rediscovery.Redix
    pubsub = Rediscovery.Redix.PubSub

    children = [
      {Redix, host: host, port: port, name: redix},
      %{
        id: Redix.PubSub,
        start: {Redix.PubSub, :start_link, [[host: host, port: port, name: pubsub]]}
      },
      {Rediscovery.State, %{node_change_fn: node_change_fn}},
      {Rediscovery.PubSub, %{redix: redix, prefix: prefix, pubsub: pubsub}},
      {Rediscovery.Poller, %{redix: redix, prefix: prefix, poll_interval: poll_interval}},
      {Rediscovery.Updater,
       %{
         redix: redix,
         prefix: prefix,
         update_interval: update_interval,
         key_expiration: key_expiration,
         metadata_fn: metadata_fn
       }}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
