:ok = LocalCluster.start()

Application.ensure_all_started(:rediscovery)

ExUnit.start()
