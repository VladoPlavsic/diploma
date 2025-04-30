defmodule Diploma.Quic.Connection do
  use GenServer

  def start_link(args) do
    IO.inspect(args)
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(init_arg) do
    IO.inspect(init_arg)
    {:ok, %{}}
  end
end
