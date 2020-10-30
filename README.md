# ReDiscovery

<!-- MDOC !-->

Node service discovery using a Redis backend.

## Usage

### Listener

Rediscovery requires a listener. This module gets called whenever node changes are detected. The module must provide the following callbacks:

- `list/0` - This returns the list of nodes that the listener knows about.
- `add/1` - This receives `[{node, metadata}]` whenever Rediscovery detects that a node has been added.
- `remove/1` - This receives `[node]` whenever Rediscovery detects that a node should be removed.

An example listener could look like the following:

```elixir
defmodule MyApp.Listener do
  use Rediscovery.Listener
  
  @impl true
  def list do
    Node.list()
  end
  
  @impl true
  def add(nodes) do
    Enum.each(nodes, fn {node, _metadata} ->
      Node.connect(node)
    end
  end
  
  @impl true
  def remove(nodes) do
    Enum.each(&Node.disconnect/1)
  end
end
```

### Supervision Tree

Add Rediscovery, followed by any Listener modules to your supervision tree (ideally near the end to make sure other processes that your app requires are started):

```elixir
children = [
  {Rediscovery, [
    host: "my.redis-host.com",
    port: 6379,
    prefix: "my_app:my_environment",
  ]},
  MyApp.Listener
]
```

See `lib/rediscovery.ex` for other options for Rediscovery.
