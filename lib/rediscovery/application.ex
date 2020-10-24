defmodule Rediscovery.Application do
  @moduledoc false

  # This application is only used in tests

  def start(_type, _args) do
    case Node.self() do
      :"manager@127.0.0.1" ->
        :ignore
        children = []
        Supervisor.start_link(children, strategy: :one_for_one)

      _ ->
        host = Application.fetch_env!(:rediscovery, :host)
        port = Application.fetch_env!(:rediscovery, :port)
        prefix = Application.fetch_env!(:rediscovery, :prefix)
        update_interval = Application.fetch_env!(:rediscovery, :update_interval)
        key_expiration = Application.fetch_env!(:rediscovery, :key_expiration)
        poll_interval = Application.fetch_env!(:rediscovery, :poll_interval)

        children = [
          {Rediscovery,
           [
             host: host,
             port: port,
             prefix: prefix,
             update_interval: update_interval,
             key_expiration: key_expiration,
             poll_interval: poll_interval
           ]}
        ]

        Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
end
