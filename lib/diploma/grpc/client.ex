defmodule Diploma.GRPC.Client do
  use GenServer

  alias Diploma.Proto.MediumRequest.{
    OrderItem,
    Address,
    PaymentMethod,
    Dimensions
  }

  alias Diploma.Proto.Stub

  @server_ip "158.160.173.180"
  @server_ip "127.0.0.1"
  @metadata %{measurer: Diploma.Measurer.Server}

  def start_link(%{measurer: measurer}) do
    GenServer.start_link(__MODULE__, %{measurer: measurer}, name: __MODULE__)
  end

  def init(%{measurer: measurer}) do
    {:ok, channel} = GRPC.Stub.connect("#{@server_ip}:50051")
    {:ok, %{channel: channel, measurer: measurer}}
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

  def handle_call(:call_small, _from, %{channel: channel, measurer: measurer} = state) do
    request = generate_small_request()
    GenServer.cast(measurer, {:grpc_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, %{unique_id: uid} = res} = Stub.call_small(channel, request, metadata: @metadata)
    GenServer.cast(measurer, {:grpc_response, decode_time_from_res(res), res.decoded_in, uid})

    {:reply, res, state}
  end

  def handle_call(:call_medium, _from, %{channel: channel, measurer: measurer} = state) do
    request = generate_medium_request()
    GenServer.cast(measurer, {:grpc_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, %{unique_id: uid} = res} = Stub.call_medium(channel, request, metadata: @metadata)
    GenServer.cast(measurer, {:grpc_response, decode_time_from_res(res), res.decoded_in, uid})

    {:reply, res, state}
  end

  def handle_call(:call_large, _from, %{channel: channel, measurer: measurer} = state) do
    request = generate_large_request()
    GenServer.cast(measurer, {:grpc_sent_at, DateTime.utc_now(:microsecond), request.unique_id})
    {:ok, %{unique_id: uid} = res} = Stub.call_large(channel, request, metadata: @metadata)
    GenServer.cast(measurer, {:grpc_response, decode_time_from_res(res), res.decoded_in, uid})

    {:reply, res, state}
  end

  def decode_time_from_res(res) do
    DateTime.from_gregorian_seconds(
      res.received_at_gregorian_sec,
      {res.received_at_microsecond, 6}
    )
  end

  def generate_small_request do
    %Diploma.Proto.SmallRequest{unique_id: UUID.uuid1()}
  end

  def generate_large_request do
    %Diploma.Proto.LargeRequest{
      unique_id: UUID.uuid1(),
      orders: Enum.map(1..100, fn _ -> generate_medium_request() end)
    }
  end

  def generate_medium_request do
    %Diploma.Proto.MediumRequest{
      unique_id: UUID.uuid1(),
      order_id: "ORD-20250426-XYZ#{generate_random_integer()}",
      customer_id: "CUST-12345#{generate_random_integer()}",
      items: generate_order_items(50),
      shipping_address: %Address{
        street: "123 Elm Street#{generate_random_integer()}",
        city: "Springfield#{generate_random_integer()}",
        state: "IL#{generate_random_integer()}",
        zip_code: "62704#{generate_random_integer()}",
        country: "USA#{generate_random_integer()}"
      },
      billing_address: %Address{
        street: "456 Oak Avenue#{generate_random_integer()}",
        city: "Springfield#{generate_random_integer()}",
        state: "IL#{generate_random_integer()}",
        zip_code: "62704#{generate_random_integer()}",
        country: "USA#{generate_random_integer()}"
      },
      payment: %PaymentMethod{},
      metadata: %{
        "customer_type" => "premium#{generate_random_integer()}",
        "campaign" => "spring_sale#{generate_random_integer()}",
        "order_source" => "mobile_app#{generate_random_integer()}",
        "gift_wrap" => "true#{generate_random_integer()}"
      },
      created_at: :os.system_time(:second),
      expedited_shipping: true
    }
  end

  defp generate_order_items(n) do
    for i <- 1..n do
      %OrderItem{
        item_id: "ITEM-#{i}",
        name: "Product ##{i}",
        quantity: Enum.random(1..5),
        price_per_unit: Enum.random(100..1000) / 10,
        tags: ["electronics", "gadget", "sale", "new", "popular"],
        dimensions: %Dimensions{
          length: Enum.random(10..50) / 1.0,
          width: Enum.random(10..50) / 1.0,
          height: Enum.random(5..20) / 1.0,
          weight: Enum.random(1..5) / 1.0
        }
      }
    end
  end

  defp generate_random_integer() do
    Enum.random(1_000_000..9_999_999)
  end
end
