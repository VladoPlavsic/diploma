defmodule Diploma.GRPC.Server do
  use GRPC.Server, service: Diploma.Helloworld.Service, measurer: Diploma.Measurer.Server

  alias Diploma.Helloworld.HelloRequest
  alias Diploma.Helloworld.HelloReply

  @spec say_hello(HelloRequest.t(), GRPC.Server.Stream.t()) :: HelloReply.t()
  def say_hello(request, _stream) do
    IO.inspect("Here")
    %HelloReply{message: "Hello #{request.name}"}
  end
end
