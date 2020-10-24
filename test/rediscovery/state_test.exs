defmodule Rediscovery.StateTest do
  use ExUnit.Case

  alias Rediscovery.State

  test "Calls the node_change_fn when nodes are added" do
    me = self()
    this_node = Node.self()

    node_change_fn = fn change, node, metadata ->
      send(me, {change, node, metadata})
    end

    start_supervised({State, %{node_change_fn: node_change_fn}})

    State.add(this_node, %{})

    assert_receive {:added, ^this_node, %{}}
  end

  test "Calls the node_change_fn when nodes are removed" do
    me = self()
    this_node = Node.self()

    node_change_fn = fn change, node, metadata ->
      send(me, {change, node, metadata})
    end

    start_supervised({State, %{node_change_fn: node_change_fn}})

    State.add(this_node, %{})
    State.remove(this_node)

    assert_receive {:removed, ^this_node, %{}}
  end

  test "Calls the node_change_fn with a remove AND add event when metadata changes" do
    me = self()
    this_node = Node.self()

    node_change_fn = fn change, node, metadata ->
      send(me, {change, node, metadata})
    end

    start_supervised({State, %{node_change_fn: node_change_fn}})

    State.add(this_node, %{host: "old.host"})
    State.add(this_node, %{host: "new.host"})
    State.remove(this_node)

    assert_receive {:added, ^this_node, %{host: "old.host"}}
    assert_receive {:removed, ^this_node, %{host: "old.host"}}
    assert_receive {:added, ^this_node, %{host: "new.host"}}
  end
end
