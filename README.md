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

The node change function receives the following arguments:

- `:reset, nil, %{}` - This indicates the Rediscovery state was reset (either on initial startup or if the supervisor restarts the state process).
- `:added, node, metadata` - When a node is added
- `:removed, node, metadata` - When a node is removed

```elixir
defmodule MyApp do
  def node_change(:reset, _, _) do
    Enum.each(Node.list(), &Node.disconnect/1)
  end

  def node_change(:added, node, _metadata) do
    Node.connect(node)
  end

  def node_change(:removed, node, _metadata) do
    Node.disconnect(node)
  end
end
```
