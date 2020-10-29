defmodule Rediscovery do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Rediscovery.State

  import Rediscovery.Logger

  @options_schema [
    host: [
      type: :string,
      required: true
    ],
    port: [
      type: :non_neg_integer,
      required: true
    ],
    prefix: [
      type: :string,
      required: true
    ],
    poll_interval: [
      type: :non_neg_integer,
      default: 10_000
    ],
    update_interval: [
      type: :non_neg_integer,
      default: 10_000
    ],
    key_expiration: [
      type: :non_neg_integer,
      default: 15_000
    ],
    metadata_fn: [
      type: {:fun, 0},
      default: &__MODULE__.default_metadata_fn/0
    ],
    node_change_fn: [
      type: {:fun, 3},
      default: &__MODULE__.default_node_change_fn/3
    ]
  ]

  def default_metadata_fn do
    %{}
  end

  def default_node_change_fn(change, node, metadata) do
    debug("Change: #{change} - #{node} - #{inspect(metadata)}")
    :ok
  end

  def child_spec(opts) do
    opts = NimbleOptions.validate!(opts, @options_schema)
    Rediscovery.Supervisor.child_spec(opts)
  end

  def start_link(opts) do
    opts = NimbleOptions.validate!(opts, @options_schema)
    Rediscovery.Supervisor.start_link(opts)
  end

  def state do
    State.state()
  end
end