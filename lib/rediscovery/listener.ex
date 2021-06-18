defmodule Rediscovery.Listener do
  @callback list() :: [node()]
  @callback add(list({node(), map()})) :: any()
  @callback remove(list(node())) :: any()
  alias Rediscovery.ProcessGroup

  def change(nodes) when is_list(nodes) do
    case ProcessGroup.get_local_members(__MODULE__) do
      {:error, {:no_such_group, _}} -> :ok
      pids -> Enum.each(pids, &GenServer.cast(&1, {:change, nodes}))
    end
  end

  defmacro __using__([]) do
    quote location: :keep do
      use GenServer

      @behaviour unquote(__MODULE__)

      def start_link(_) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end

      @impl true
      def init(nil) do
        :ok = ProcessGroup.start()
        ProcessGroup.create(unquote(__MODULE__))
        :ok = ProcessGroup.join(unquote(__MODULE__), self())
        {:ok, nil, {:continue, :setup}}
      end

      def change(server \\ __MODULE__, nodes) when is_list(nodes) do
        GenServer.cast(server, {:change, nodes})
      end

      @impl GenServer
      def handle_continue(:setup, nil) do
        nodes = Rediscovery.State.state()
        __MODULE__.change(nodes)
        {:noreply, nil}
      end

      @impl GenServer
      def handle_cast({:change, new_nodes}, nil) do
        old_nodes = :sets.from_list(__MODULE__.list())
        new_nodes_set = :sets.from_list(Enum.map(new_nodes, &elem(&1, 0)))

        if old_nodes != new_nodes_set do
          same = :sets.intersection([old_nodes, new_nodes_set])
          added = :sets.subtract(new_nodes_set, same)
          removed = :sets.subtract(old_nodes, same)

          if !:sets.is_empty(removed) do
            to_remove = :sets.to_list(removed)

            __MODULE__.remove(to_remove)
          end

          if !:sets.is_empty(added) do
            new_node_map = Map.new(new_nodes)

            to_add =
              added
              |> :sets.to_list()
              |> Enum.map(&{&1, Map.get(new_node_map, &1)})

            __MODULE__.add(to_add)
          end
        end

        {:noreply, nil}
      end
    end
  end
end
