defmodule Diploma.GRPC.Server do
  use GRPC.Server, service: Diploma.Proto.Service, measurer: Diploma.Measurer.Server

  alias Diploma.Proto.SmallRequest
  alias Diploma.Proto.SmallReply

  alias Diploma.Proto.MediumRequest
  alias Diploma.Proto.MediumReply

  alias Diploma.Proto.LargeRequest
  alias Diploma.Proto.LargeReply

  @spec call_small(SmallRequest.t(), GRPC.Server.Stream.t()) :: SmallReply.t()
  def call_small(request, _stream) do
    %SmallReply{message: "Hello #{request.name}"}
  end

  @spec call_medium(MediumRequest.t(), GRPC.Server.Stream.t()) :: MediumReply.t()
  def call_medium(request, _stream) do
    %MediumReply{message: ""}
  end

  @spec call_large(LargeRequest.t(), GRPC.Server.Stream.t()) :: LargeReply.t()
  def call_large(request, _stream) do
    %LargeReply{message: ""}
  end
end
