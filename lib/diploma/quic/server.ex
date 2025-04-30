defmodule Diploma.Quic.Server do
  use GenServer

  require Logger

  @server_opts %{
    certfile: ~c"priv/cert.pem",
    keyfile: ~c"priv/key.pem",
    alpn: [~c"http/3"],
    idle_timeout_ms: 60_000,
    peer_bidi_stream_count: 10,
    sslkeylogfile: ~c"priv/ssl_key.log",
    keep_alive_interval_ms: 30_000
  }

  @port 4567

  def start_link(start_server: true) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_link(_) do
    :ignore
  end

  def init(_) do
    case :quicer.listen(~c"127.0.0.1:#{@port}", @server_opts) do
      {:ok, listener} ->
        Logger.info("Listening on port #{@port} with QUIC")
        {:ok, %{listener: listener, conn: nil, streams: %{}}, {:continue, :accept_loop}}

      {:error, reason} ->
        Logger.error("Failed to start QUIC listener: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def handle_continue(:accept_loop, state) do
    accept_connections(state)
  end

  defp accept_connections(%{listener: listener} = state) do
    case :quicer.async_accept(listener, %{}) do
      {:ok, _conn} ->
        {:noreply, state}

      error ->
        Logger.error("Failed to accept connection: #{inspect(error)}")
        {:stop, error}
    end
  end

  def handle_info({:quic, :new_conn, conn, _}, state) do
    accept_connections(state)

    case :quicer.async_handshake(conn) do
      :ok ->
        {:noreply, state}

      error ->
        Logger.error("Failed to handshake: #{inspect(error)}")
        {:stop, error}
    end
  end

  def handle_info({:quic, :connected, conn, _}, state) do
    case :quicer.async_accept_stream(conn, %{active: true}) do
      {:ok, conn} ->
        {:noreply, %{state | conn: conn}}

      {:error, _} = error ->
        Logger.error("Failed to accept stream: #{inspect(error)}")
        {:stop, error}
    end
  end

  def handle_info({:quic, :new_stream, stream, _}, %{conn: conn} = state) do
    case :quicer.async_accept_stream(conn, %{active: true}) do
      {:ok, conn} ->
        {:noreply,
         %{state | streams: Map.put(state.streams, stream, %{frames: [], decoded: nil})}}

      {:error, _} = error ->
        Logger.error("Failed to accept stream: #{inspect(error)}")
        {:stop, error}
    end
  end

  def handle_info({:quic, :closed, _, _} = msg, state) do
    Logger.error("Connection closed: #{inspect(msg)}", state: inspect(state))
    {:stop, msg}
  end

  def handle_info({:quic, :stream_closed, stream, _}, state) do
    state = %{state | streams: Map.delete(state.streams, stream)}
    {:noreply, state}
  end

  def handle_info({:quic, :send_shutdown_complete, stream, true} = msg, state) do
    state = %{state | streams: Map.delete(state.streams, stream)}
    {:noreply, state}
  end

  def handle_info({:quic, :peer_send_shutdown, stream, _value}, state) do
    :quicer.shutdown_stream(stream)
    {:noreply, state}
  end

  def handle_info({:quic, :transport_shutdown, stream, _value}, state) do
    accept_connections(state)
    {:noreply, state}
  end

  def handle_info(
        {:quic, binary_part, stream, %{flags: 0, absolute_offset: offset}} = msg,
        %{streams: streams} = state
      ) do
    frames = [%{chunk_no: offset, binary_part: binary_part} | streams[stream][:frames]]
    {:noreply, %{state | streams: put_in(streams, [stream, :frames], frames)}}
  end

  def handle_info(
        {:quic, binary_part, stream, %{flags: 2, absolute_offset: offset}} = msg,
        %{streams: streams} = state
      ) do
    frames = [%{chunk_no: offset, binary_part: binary_part} | streams[stream][:frames]]
    state = %{state | streams: put_in(streams, [stream, :frames], frames)}

    received_at = DateTime.utc_now(:microsecond)

    {decode_time, {{%{unique_id: uid} = _message, byte_size}, state}} =
      :timer.tc(fn -> decode_message(state, stream) end)

    GenServer.cast(Diploma.Measurer.Server, {:quic_decoded, decode_time, byte_size, uid})
    send_reply(stream, received_at, uid, decode_time)
    {:noreply, state}
  end

  defp decode_message(state, stream) do
    sorted_frames =
      state[:streams][stream][:frames]
      |> Enum.sort_by(fn %{chunk_no: chunk_no} -> chunk_no end)
      |> Enum.map(& &1.binary_part)

    raw_value = Enum.join(sorted_frames, "")
    decoded_value = :erlang.binary_to_term(raw_value)

    {{decoded_value, byte_size(raw_value)},
     put_in(state, [:streams, stream, :decoded], decoded_value)}
  end

  defp send_reply(stream, received_at, unique_id, decoding_time) do
    {received_at_gregorian_second, received_microsecond} =
      DateTime.to_gregorian_seconds(received_at)

    reply = %Diploma.Proto.SmallReply{
      received_at_gregorian_sec: received_at_gregorian_second,
      received_at_microsecond: received_microsecond,
      unique_id: unique_id,
      decoded_in: decoding_time
    }

    :quicer.send(stream, :erlang.term_to_binary(reply))
    :quicer.shutdown_stream(stream)
  end
end
