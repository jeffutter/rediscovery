defmodule RediscoveryTest do
  use ExUnit.Case
  doctest Rediscovery

  test "Finds other nodes" do
    [node1, node2, node3] =
      LocalCluster.start_nodes(:test, 3,
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
      compare([node1, node2, node3], Map.keys(:rpc.call(node1, Rediscovery, :state, [])))
    end)

    eventually(fn ->
      compare([node1, node2, node3], Map.keys(:rpc.call(node2, Rediscovery, :state, [])))
    end)

    eventually(fn ->
      compare([node1, node2, node3], Map.keys(:rpc.call(node3, Rediscovery, :state, [])))
    end)
  end

  test "Updates when nodes are removed" do
    [node1, node2] =
      LocalCluster.start_nodes(:test, 2,
        applications: [:rediscovery],
        environment: [
          rediscovery: [
            host: "localhost",
            port: 6379,
            prefix: "myapp:test",
            update_interval: 100,
            key_expiration: 120,
            poll_interval: 100
          ]
        ]
      )

    eventually(fn ->
      compare([node1, node2], Map.keys(:rpc.call(node1, Rediscovery, :state, [])))
    end)

    :ok = LocalCluster.stop_nodes([node2])

    eventually(fn ->
      compare([node1], Map.keys(:rpc.call(node1, Rediscovery, :state, [])))
    end)
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
