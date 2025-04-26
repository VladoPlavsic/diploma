defmodule Diploma.Helloworld.HelloRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :name, 1, type: :string
end

defmodule Diploma.Helloworld.HelloReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :message, 1, type: :string
end

defmodule Diploma.Helloworld.Service do
  @moduledoc false
  use GRPC.Service,
    name: "diploma.services.ChargerService",
    protoc_gen_elixir_version: "0.14.1",
    syntax: :proto3

  rpc(:say_hello, Diploma.Helloworld.HelloRequest, Diploma.Helloworld.HelloReply)
end

defmodule Diploma.Helloworld.Stub do
  @moduledoc false
  use GRPC.Stub, service: Diploma.Helloworld.Service
end
