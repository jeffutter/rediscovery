defmodule RediscoveryTest do
  use ExUnit.Case, async: false
  doctest Rediscovery

  test "Finds other nodes" do
    [node1, node2, node3] =
      LocalCluster.start_nodes(:test1, 3,
        applications: [:rediscovery],
        environment: [
          rediscovery: [
            host: "localhost",
            port: 6379,
            prefix: "myapp:test",
            update_interval: 1_000,
            key_expiration: 1_050,
            poll_interval: 1_000
          ]
        ]
      )

    eventually(fn ->
      compare([node1, node2, node3], nodes_in_node_state(node1))
    end)

    eventually(fn ->
      compare([node1, node2, node3], nodes_in_node_state(node2))
    end)

    eventually(fn ->
      compare([node1, node2, node3], nodes_in_node_state(node3))
    end)
  end

  test "Updates when nodes are removed" do
    [node1, node2] =
      LocalCluster.start_nodes(:test2, 2,
        applications: [:rediscovery],
        environment: [
          rediscovery: [
            host: "localhost",
            port: 6379,
            prefix: "myapp:test",
            update_interval: 100,
            key_expiration: 110,
            poll_interval: 100
          ]
        ]
      )

    eventually(fn ->
      compare([node1, node2], nodes_in_node_state(node1))
    end)

    :ok = LocalCluster.stop_nodes([node2])

    eventually(fn ->
      GenServer.call({Rediscovery.Poller, node1}, :renew)
      compare([node1], nodes_in_node_state(node1))
    end)
  end

  def nodes_in_node_state(node) do
    node
    |> :rpc.call(Rediscovery, :state, [])
    |> Enum.map(&elem(&1, 0))
  end

  def compare(nodes1, nodes2) do
    assert MapSet.new(nodes1) == MapSet.new(nodes2)
  end

  def eventually(f, retries \\ 0) do
    if retries > 10 do
      false
    else
      if f.() do
        true
      else
        :timer.sleep(100)
        eventually(f, retries + 1)
      end
    end
  rescue
    err ->
      if retries == 10 do
        reraise err, __STACKTRACE__
      else
        :timer.sleep(200)
        eventually(f, retries + 1)
      end
  end
end
