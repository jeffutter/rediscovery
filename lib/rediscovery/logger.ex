defmodule Rediscovery.Logger do
  @moduledoc """
  Logging helpers to format log messages related to rediscovery
  """

  require Logger

  def debug(msg) do
    case Application.get_env(:rediscovery, :debug, false) do
      dbg when dbg in [nil, false, "false"] ->
        :ok

      _ ->
        Logger.debug(log_message(msg))
    end
  end

  def info(msg), do: Logger.info(log_message(msg))
  def error(msg), do: Logger.error(log_message(msg))

  @compile {:inline, log_message: 1}
  defp log_message(msg) do
    "[rediscovery:#{Node.self()}] #{msg}"
  end
end
