defmodule Rediscovery.State do
  use GenServer

  import Rediscovery.Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :sets.new(), name: __MODULE__)
  end

  def add(server \\ __MODULE__, node, metadata) do
    GenServer.call(server, {:add, node, metadata})
  end

  def remove(server \\ __MODULE__, node) do
    GenServer.call(server, {:remove, node})
  end

  def replace(server \\ __MODULE__, nodes) do
    GenServer.call(server, {:replace, nodes})
  end

  def state(server \\ __MODULE__) do
    GenServer.call(server, :state)
  end

  @impl true
  def init(state) do
    debug("State: init")
    {:ok, state}
  end

  @impl true
  def handle_call({:add, node, metadata}, _from, nodes) do
    filtered_nodes = remove_node(node, nodes)
    new_nodes = :sets.add_element({node, metadata}, filtered_nodes)
    handle_diffs(nodes, new_nodes)
    count_nodes(new_nodes)
    {:reply, :ok, new_nodes}
  end

  @impl true
  def handle_call({:replace, new_nodes}, _from, old_nodes) do
    new_nodes = :sets.from_list(new_nodes)
    handle_diffs(old_nodes, new_nodes)
    count_nodes(new_nodes)
    {:reply, :ok, new_nodes}
  end

  @impl true
  def handle_call({:remove, node}, _from, nodes) do
    filtered_nodes = remove_node(node, nodes)
    handle_diffs(nodes, filtered_nodes)
    count_nodes(filtered_nodes)
    {:reply, :ok, filtered_nodes}
  end

  @impl true
  def handle_call(:state, _from, nodes) do
    {:reply, :sets.to_list(nodes), nodes}
  end

  defp remove_node(node, nodes) do
    :sets.filter(&(!match?({^node, _}, &1)), nodes)
  end

  defp handle_diffs(old_nodes, new_nodes) do
    if old_nodes != new_nodes do
      nodes = :sets.to_list(new_nodes)

      start_time = System.monotonic_time()

      :telemetry.execute(
        [:rediscovery, :state, :broadcast, :start],
        %{system_time: System.system_time()},
        %{}
      )

      debug("State: Broadcasting new node list -#{inspect(nodes)}")

      Rediscovery.Listener.change(:sets.to_list(new_nodes))

      end_time = System.monotonic_time()

      :telemetry.execute(
        [:rediscovery, :state, :broadcast, :stop],
        %{duration: end_time - start_time},
        %{}
      )
    end

    :ok
  end

  defp count_nodes(nodes) do
    :telemetry.execute(
      [:rediscovery, :node_count],
      %{count: :sets.size(nodes)},
      %{}
    )
  end
end
