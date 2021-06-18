defmodule Rediscovery.StateTest do
  use ExUnit.Case, async: false

  alias Rediscovery.{ProcessGroup, State}

  defmodule FakeListener do
    use GenServer

    def start_link(pid) do
      GenServer.start_link(__MODULE__, pid, [])
    end

    def init(pid) do
      :ok = ProcessGroup.start()
      ProcessGroup.create(Rediscovery.Listener)
      :ok = ProcessGroup.join(Rediscovery.Listener, self())
      {:ok, pid}
    end

    def handle_cast({:change, new_nodes}, pid) do
      send(pid, {:change, self(), new_nodes})

      {:noreply, pid}
    end
  end

  test "Broadcasts a change event when nodes are added" do
    me = self()
    this_node = Node.self()

    start_supervised(State)
    {:ok, listener_pid} = start_supervised({FakeListener, me})

    State.add(this_node, %{})

    assert_receive {:change, ^listener_pid, [{^this_node, %{}}]}
  end

  test "Broadcasts a change event when nodes are removed" do
    me = self()
    this_node = Node.self()

    start_supervised(State)
    {:ok, listener_pid} = start_supervised({FakeListener, me})

    State.add(this_node, %{})
    State.remove(this_node)

    assert_receive {:change, ^listener_pid, []}
  end

  test "Doesn't broadcast a change if the node is already known about" do
    me = self()
    this_node = Node.self()

    start_supervised(State)
    {:ok, listener_pid} = start_supervised({FakeListener, me})

    State.add(this_node, %{})

    assert_receive {:change, ^listener_pid, [{^this_node, %{}}]}

    State.add(this_node, %{})

    refute_receive {:change, ^listener_pid, [{^this_node, %{}}]}
  end
end
