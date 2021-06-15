defmodule Rediscovery.ProcessGroup do
  @moduledoc """
  Wrapper for Erlang process group modules.
  pg2 was removed in OTP 24 and replaced with pg which was introduced in OTP 23.
  """

  @otp_version :erlang.system_info(:otp_release) |> to_string() |> String.to_integer()

  if @otp_version >= 23 do
    def create(name), do: :pg.start(name) |> elem(0)
    def get_local_members(name), do: :pg.get_local_members(name)
    def join(group_name, pid), do: :pg.join(group_name, pid)
  else
    def create(name), do: :pg2.create(name)
    def get_local_members(name), do: :pg2.get_local_members(name)
    def join(group_name, pid), do: :pg2.join(group_name, pid)
  end
end
