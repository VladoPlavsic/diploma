defmodule Diploma.Measurer.Server do
  use GenServer

  defmodule State do
    defstruct grpc: %{}, rest: %{}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:grpc_encoded, encoding_time, byte_size, time}, state) do
    {:noreply,
     put_in(state, [Access.key(:grpc), time], %{
       byte_size: byte_size,
       time: encoding_time
     })}
  end

  def handle_cast({:grpc_decoded, decoding_time, byte_size, request_id}, state) do
    {:noreply,
     put_in(state, [Access.key(:grpc), request_id], %{
       byte_size: byte_size,
       time: decoding_time
     })}
  end
end
