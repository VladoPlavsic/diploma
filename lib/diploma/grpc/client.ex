defmodule Diploma.GRPC.Client do
  use GenServer

  alias Diploma.Proto.MediumRequest.{
    CreateOrderRequest,
    OrderItem,
    Address,
    PaymentMethod,
    CreditCard,
    Paypal,
    BankTransfer,
    Dimensions
  }

  @metadata %{measurer: Diploma.Measurer.Server}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    {:ok, %{channel: channel}}
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

  def handle_call(:call_small, _from, %{channel: channel} = state) do
    request = %Diploma.Proto.SmallRequest{}
    {:ok, res} = Diploma.Proto.Stub.call_small(channel, request, metadata: @metadata)

    {:reply, res, state}
  end

  def handle_call(:call_medium, _from, %{channel: channel} = state) do
    request = generate_medium_request()
    {:ok, res} = Diploma.Proto.Stub.call_medium(channel, request, metadata: @metadata)

    {:reply, res, state}
  end

  def handle_call(:call_large, _from, %{channel: channel} = state) do
    request = %Diploma.Proto.LargeRequest{
      orders: Enum.map(1..100, fn _ -> generate_medium_request() end)
    }

    {:ok, res} = Diploma.Proto.Stub.call_large(channel, request, metadata: @metadata)

    {:reply, res, state}
  end

  defp generate_medium_request do
    %Diploma.Proto.MediumRequest{
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
