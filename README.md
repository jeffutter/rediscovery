# ReDiscovery

<!-- MDOC !-->

Node service discovery using a Redis backend.

## Usage

Add Rediscovery to your supervision tree (ideally near the end to make sure other processes that your app requires are started):

```elixir
children = [
  {Rediscovery, [
    host: "my.redis-host.com",
    port: 6379,
    prefix: "my_app:my_environment",
    node_change_fn: &MyApp.node_change/3
  ]}
]
```

See `lib/rediscovery.ex` for other options.

## Node Change

Rediscovery accepts a function to be called when node changes occur.

The node change function receives `:added` or `:removed` as it's first argument followed by the node name and any metadata provided when the node was registered.

```elixir
defmodule MyApp do
  def node_change(:added, node, _metadata) do
    :net_kernel.connect_node(node)
  end

  def node_change(:removed, node, _metadata) do
    :erlang.disconnect_node(node)
  end
end
```
