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
    pub_sub = Keyword.fetch!(opts, :pub_sub)

    redix = Rediscovery.Redix
    pubsub = Rediscovery.Redix.PubSub

    redix_pubsub =
      case pub_sub do
        true ->
          [%{id: Redix.PubSub, start: {Redix.PubSub, :start_link, [[host: host, port: port, name: pubsub]]}}]

        false ->
          []
      end

    rediscovery_pubsub =
      case pub_sub do
        true ->
          [{Rediscovery.PubSub, %{redix: redix, prefix: prefix, pubsub: pubsub}}]

        false ->
          []
      end

    children =
      [
        {Redix, host: host, port: port, name: redix},
        redix_pubsub,
        Rediscovery.State,
        rediscovery_pubsub,
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
      |> List.flatten()

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
