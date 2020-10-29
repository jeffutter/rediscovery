defmodule Rediscovery.State do
  use GenServer

  import Rediscovery.Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {:sets.new(), opts}, name: __MODULE__)
  end

  def add(node, metadata) do
    GenServer.call(__MODULE__, {:add, node, metadata})
  end

  def remove(node) do
    GenServer.call(__MODULE__, {:remove, node})
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :reset}}
  end

  @impl true
  def handle_continue(:reset, {_nodes, opts} = state) do
    node_change(opts, :reset, nil, %{})

    {:noreply, state}
  end

  @impl true
  def handle_call({:add, node, metadata}, _from, {nodes, opts}) do
    filtered_nodes = remove_node(node, nodes)
    new_nodes = :sets.add_element({node, metadata}, filtered_nodes)
    handle_diffs(nodes, new_nodes, opts)
    count_nodes(new_nodes)
    {:reply, :ok, {new_nodes, opts}}
  end

  @impl true
  def handle_call({:remove, node}, _from, {nodes, opts}) do
    filtered_nodes = remove_node(node, nodes)
    handle_diffs(nodes, filtered_nodes, opts)
    count_nodes(filtered_nodes)
    {:reply, :ok, {filtered_nodes, opts}}
  end

  @impl true
  def handle_call(:state, _from, {nodes, opts}) do
    {:reply, Map.new(:sets.to_list(nodes)), {nodes, opts}}
  end

  defp remove_node(node, nodes) do
    :sets.filter(&(!match?({^node, _}, &1)), nodes)
  end

  defp handle_diffs(old_nodes, new_nodes, opts) do
    same = :sets.intersection([old_nodes, new_nodes])
    added = :sets.subtract(new_nodes, same)
    removed = :sets.subtract(old_nodes, same)

    if removed != :sets.new() do
      removed
      |> :sets.to_list()
      |> Enum.each(fn {node, metadata} ->
        info("State: Removing Node: #{node}")
        node_change(opts, :removed, node, metadata)
      end)
    end

    if added != :sets.new() do
      added
      |> :sets.to_list()
      |> Enum.each(fn {node, metadata} ->
        info("State: Adding Node: #{node}")
        node_change(opts, :added, node, metadata)
      end)
    end

    :ok
  end

  defp node_change(%{node_change_fn: node_change_fn}, change, node, metadata) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:rediscovery, :node_change, :start],
      %{system_time: System.system_time()},
      %{change: change}
    )

    node_change_fn.(change, node, metadata)

    end_time = System.monotonic_time()

    :telemetry.execute(
      [:rediscovery, :node_change, :stop],
      %{duration: end_time - start_time},
      %{change: change}
    )
  end

  defp count_nodes(nodes) do
    :telemetry.execute(
      [:rediscovery, :node_count],
      %{count: :sets.size(nodes)},
      %{}
    )
  end
end
