defmodule Diploma.GRPC.Client do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    {:ok, %{channel: channel}}
  end

  def say_hello() do
    GenServer.call(__MODULE__, :say_hello)
  end

  def handle_call(:say_hello, _from, %{channel: channel} = state) do
    request = %Diploma.Helloworld.HelloRequest{name: "grpc-elixir"}

    {:ok, response} =
      Diploma.Helloworld.Stub.say_hello(channel, request,
        metadata: %{measurer: Diploma.Measurer.Server}
      )

    {:reply, response, state}
  end
end
