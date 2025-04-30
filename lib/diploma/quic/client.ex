defmodule Diploma.Quic.Client do
  require Logger
  use GenServer

  @host ~c"127.0.0.1"

  @port 4567

  @connect_opts [
    alpn: [~c"http/3"],
    verify: :verify_none,
    keep_alive_interval_ms: 30_000,
    idle_timeout_ms: 60_000
  ]

  def start_link(%{measurer: measurer}) do
    GenServer.start_link(__MODULE__, %{measurer: measurer}, name: __MODULE__)
  end

  def init(%{measurer: measurer}) do
    connect(measurer)
  end

  def call_small() do
    GenServer.call(__MODULE__, :call_small)
  end

  def call_medium() do
    GenServer.call(__MODULE__, :call_medium)
  end

  def call_large() do
    GenServer.call(__MODULE__, :call_large)
  end

  def handle_call(:call_small, _from, %{conn: conn, measurer: measurer} = state) do
    request = Diploma.GRPC.Client.generate_small_request()
    GenServer.cast(measurer, {:quic_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, res} = send_message(conn, request, measurer)

    {:reply, res, state}
  end

  def handle_call(:call_medium, _from, %{conn: conn, measurer: measurer} = state) do
    request = Diploma.GRPC.Client.generate_medium_request()
    GenServer.cast(measurer, {:quic_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, res} = send_message(conn, request, measurer)

    {:reply, res, state}
  end

  def handle_call(:call_large, _from, %{conn: conn, measurer: measurer} = state) do
    request = Diploma.GRPC.Client.generate_large_request()
    GenServer.cast(measurer, {:quic_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, res} = send_message(conn, request, measurer)

    {:reply, res, state}
  end

  defp send_message(conn, message, measurer) do
    case :quicer.start_stream(conn, []) do
      {:ok, stream} ->
        {encoding_time, encoded} =
          :timer.tc(fn ->
            :erlang.term_to_binary(message)
          end)

        GenServer.cast(
          measurer,
          {:quic_encoded, encoding_time, byte_size(encoded), message.unique_id}
        )

        :quicer.send(stream, encoded, 0x0004)

      {:error, reason} ->
        Logger.error("Failed to accept stream: #{inspect(reason)}")
    end
  end

  def handle_info({:quic, :peer_send_shutdown, stream, _value}, state) do
    # :quicer.close_stream(stream)
    {:noreply, state}
  end

  def handle_info(
        {:quic, :streams_available, _ref,
         %{bidi_streams: bidi_streams, unidi_streams: unidi_streams}} = msg,
        state
      ) do
    state =
      state
      |> Map.put(:bidi_streams, bidi_streams)
      |> Map.put(:unidi_streams, unidi_streams)

    {:noreply, state}
  end

  def handle_info({:quic, :send_shutdown_complete, stream, true} = msg, state) do
    Logger.debug("Received data: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info({:quic, :closed, _ref, _conn_state}, %{measurer: measurer} = _state) do
    # ???
    {:ok, state} = connect(measurer)
    {:noreply, state}
  end

  def handle_info({:quic, :dgram_state_changed, _stream, _value}, state) do
    {:noreply, state}
  end

  def handle_info({:quic, :stream_closed, _stream, _value}, state) do
    # Server closed stream
    {:noreply, state}
  end

  def handle_info({:quic, :shutdown, _stream, _value}, state) do
    # Server closed connection
    {:noreply, state}
  end

  def handle_info({:quic, data, stream, _value} = msg, %{measurer: measurer} = state) do
    res = :erlang.binary_to_term(data)

    GenServer.cast(
      measurer,
      {:quic_response, Diploma.GRPC.Client.decode_time_from_res(res), res.decoded_in,
       res.unique_id}
    )

    {:noreply, state}
  end

  defp connect(measurer) do
    case :quicer.connect(@host, @port, @connect_opts, 15_000) do
      {:ok, conn} ->
        # keep_alive(conn)
        IO.puts("Connected to QUIC server.")
        {:ok, %{conn: conn, measurer: measurer}}

      {:error, reason} ->
        IO.puts("Failed to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
