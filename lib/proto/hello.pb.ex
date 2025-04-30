defmodule Diploma.Proto.SmallRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :name, 1, type: :string
  field :unique_id, 2, type: :string
end

defmodule Diploma.Proto.SmallReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :received_at_gregorian_sec, 1, type: :int64
  field :received_at_microsecond, 2, type: :int64
  field :unique_id, 3, type: :string
  field :decoded_in, 4, type: :int64
end

defmodule Diploma.Proto.MediumRequest do
  @moduledoc false
  defmodule OrderItem do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :item_id, 1, type: :string
    field :name, 2, type: :string
    field :quantity, 3, type: :int32
    field :price_per_unit, 4, type: :double
    field :tags, 5, repeated: true, type: :string
    field :dimensions, 6, type: Diploma.Proto.MediumRequest.Dimensions
  end

  defmodule Address do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :street, 1, type: :string
    field :city, 2, type: :string
    field :state, 3, type: :string
    field :zip_code, 4, type: :string
    field :country, 5, type: :string
  end

  defmodule PaymentMethod do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :credit_card, 1, type: Diploma.Proto.MediumRequest.CreditCard, oneof: :method
    field :paypal, 2, type: Diploma.Proto.MediumRequest.Paypal, oneof: :method
    field :bank_transfer, 3, type: Diploma.Proto.MediumRequest.BankTransfer, oneof: :method
  end

  defmodule CreditCard do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :card_number, 1, type: :string
    field :expiration_date, 2, type: :string
    field :cvv, 3, type: :string
    field :cardholder_name, 4, type: :string
  end

  defmodule Paypal do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :email, 1, type: :string
    field :transaction_id, 2, type: :string
  end

  defmodule BankTransfer do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :account_number, 1, type: :string
    field :routing_number, 2, type: :string
    field :account_holder, 3, type: :string
  end

  defmodule Dimensions do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :length, 1, type: :double
    field :width, 2, type: :double
    field :height, 3, type: :double
    field :weight, 4, type: :double
  end

  defmodule CreateOrderRequest.MetadataEntry do
    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

    field :key, 1, type: :string
    field :value, 2, type: :string
  end

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :order_id, 1, type: :string
  field :customer_id, 2, type: :string
  field :items, 3, repeated: true, type: Diploma.Proto.MediumRequest.OrderItem
  field :shipping_address, 4, type: Diploma.Proto.MediumRequest.Address
  field :billing_address, 5, type: Diploma.Proto.MediumRequest.Address
  field :payment, 6, type: Diploma.Proto.MediumRequest.PaymentMethod

  field :metadata, 7,
    repeated: true,
    type: Diploma.Proto.MediumRequest.CreateOrderRequest.MetadataEntry,
    map: true

  field :created_at, 8, type: :int64
  field :expedited_shipping, 9, type: :bool
  field :unique_id, 10, type: :string
end

defmodule Diploma.Proto.MediumReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :received_at_gregorian_sec, 1, type: :int64
  field :received_at_microsecond, 2, type: :int64
  field :unique_id, 3, type: :string
  field :decoded_in, 4, type: :int64
end

defmodule Diploma.Proto.LargeRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :orders, 1, repeated: true, type: Diploma.Proto.MediumRequest
  field :unique_id, 2, type: :string
end

defmodule Diploma.Proto.LargeReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :received_at_gregorian_sec, 1, type: :int64
  field :received_at_microsecond, 2, type: :int64
  field :unique_id, 3, type: :string
  field :decoded_in, 4, type: :int64
end

defmodule Diploma.Proto.Service do
  @moduledoc false
  use GRPC.Service,
    name: "diploma.services.ChargerService",
    protoc_gen_elixir_version: "0.14.1",
    syntax: :proto3

  rpc(:call_small, Diploma.Proto.SmallRequest, Diploma.Proto.SmallReply)
  rpc(:call_medium, Diploma.Proto.MediumRequest, Diploma.Proto.MediumReply)
  rpc(:call_large, Diploma.Proto.LargeRequest, Diploma.Proto.LargeReply)
end

defmodule Diploma.Proto.Stub do
  @moduledoc false
  use GRPC.Stub, service: Diploma.Proto.Service
end
