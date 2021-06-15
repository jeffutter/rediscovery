defmodule Rediscovery.ListenerTest do
  use ExUnit.Case, async: false

  defmodule FakeListener do
    use Rediscovery.Listener

    @impl true
    def list do
      [:fake1@node]
    end

    @impl true
    def add(nodes) do
      pid = :persistent_term.get({FakeListener, :test_pid})
      send(pid, {:add, nodes})
    end

    @impl true
    def remove(nodes) do
      pid = :persistent_term.get({FakeListener, :test_pid})
      send(pid, {:remove, nodes})
    end
  end

  test "Calls add when nodes are added" do
    :persistent_term.put({FakeListener, :test_pid}, self())
    on_exit(fn -> :persistent_term.erase({FakeListener, :test_pid}) end)
    start_supervised(Rediscovery.State)
    start_supervised(FakeListener)

    FakeListener.change([{:fake2@node, %{}}])

    assert_receive {:add, [{:fake2@node, %{}}]}
  end

  test "Calls remove when nodes are removed" do
    :persistent_term.put({FakeListener, :test_pid}, self())
    on_exit(fn -> :persistent_term.erase({FakeListener, :test_pid}) end)
    start_supervised(Rediscovery.State)
    start_supervised(FakeListener)

    FakeListener.change([])

    assert_receive {:remove, [:fake1@node]}
  end

  test "Receives events cast from :pg" do
    :persistent_term.put({FakeListener, :test_pid}, self())
    on_exit(fn -> :persistent_term.erase({FakeListener, :test_pid}) end)
    start_supervised(Rediscovery.State)
    start_supervised(FakeListener)

    FakeListener.change([{:fake3@node, %{}}])

    assert_receive {:add, [{:fake3@node, %{}}]}
    assert_receive {:remove, [:fake1@node]}
  end
end
