defmodule Diploma.Measurer.Server do
  use GenServer

  defmodule State do
    defstruct grpc: %{}, quic: %{}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def get_grpc_decoded_in(unique_id) do
    GenServer.call(__MODULE__, {:get_grpc_decoded_in, unique_id})
  end

  def handle_call({:get_grpc_decoded_in, unique_id}, _from, %{grpc: grpc} = state) do
    {:reply, grpc[unique_id][:decoding_time], state}
  end

  def handle_cast({:grpc_encoded, encoding_time, byte_size, unique_id}, state) do
    {:noreply,
     update_in(state, [Access.key(:grpc), unique_id], fn original_map ->
       Map.merge(original_map, %{
         byte_size: byte_size,
         encoding_time: encoding_time
       })
     end)}
  end

  def handle_cast({:quic_encoded, encoding_time, byte_size, unique_id}, state) do
    {:noreply,
     update_in(state, [Access.key(:quic), unique_id], fn original_map ->
       Map.merge(original_map, %{
         byte_size: byte_size,
         encoding_time: encoding_time
       })
     end)}
  end

  def handle_cast({:grpc_decoded, decoding_time, byte_size, unique_id}, state) do
    {:noreply,
     put_in(state, [Access.key(:grpc), unique_id], %{
       byte_size: byte_size,
       decoding_time: decoding_time
     })}
  end

  def handle_cast({:quic_decoded, decoding_time, byte_size, unique_id}, state) do
    {:noreply,
     put_in(state, [Access.key(:quic), unique_id], %{
       byte_size: byte_size,
       decoding_time: decoding_time
     })}
  end

  def handle_cast({:grpc_sent_at, timestamp, unique_id}, state) do
    {:noreply,
     put_in(state, [Access.key(:grpc), unique_id], %{
       client_sent_at: timestamp
     })}
  end

  def handle_cast({:quic_sent_at, timestamp, unique_id}, state) do
    {:noreply,
     put_in(state, [Access.key(:quic), unique_id], %{
       client_sent_at: timestamp
     })}
  end

  def handle_cast({:grpc_response, received_at, decoding_time, unique_id}, state) do
    {:noreply,
     update_in(state, [Access.key(:grpc), unique_id], fn original_map ->
       original_map
       |> Map.merge(%{
         server_received_at: received_at,
         decoding_time: decoding_time
       })
       |> calculate_on_wire_time()
     end)}
  end

  def handle_cast({:quic_response, received_at, decoding_time, unique_id}, state) do
    {:noreply,
     update_in(state, [Access.key(:quic), unique_id], fn original_map ->
       original_map
       |> Map.merge(%{
         server_received_at: received_at,
         decoding_time: decoding_time
       })
       |> calculate_on_wire_time()
     end)}
  end

  defp calculate_on_wire_time(
         %{
           client_sent_at: sent_at,
           server_received_at: recv_at,
           decoding_time: decoding_time,
           encoding_time: encoding_time
         } = request_info
       ) do
    total_request_time = DateTime.diff(recv_at, sent_at, :microsecond)
    Map.put(request_info, :time_on_the_wire, total_request_time - (decoding_time + encoding_time))
  end
end
