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
    {received_at_gregorian_second, received_microsecond} =
      :microsecond |> DateTime.utc_now() |> DateTime.to_gregorian_seconds()

    %SmallReply{
      received_at_gregorian_sec: received_at_gregorian_second,
      received_at_microsecond: received_microsecond,
      unique_id: request.unique_id,
      decoded_in: Diploma.Measurer.Server.get_grpc_decoded_in(request.unique_id)
    }
  end

  @spec call_medium(MediumRequest.t(), GRPC.Server.Stream.t()) :: MediumReply.t()
  def call_medium(request, _stream) do
    {received_at_gregorian_second, received_microsecond} =
      :microsecond |> DateTime.utc_now() |> DateTime.to_gregorian_seconds()

    %MediumReply{
      received_at_gregorian_sec: received_at_gregorian_second,
      received_at_microsecond: received_microsecond,
      unique_id: request.unique_id,
      decoded_in: Diploma.Measurer.Server.get_grpc_decoded_in(request.unique_id)
    }
  end

  @spec call_large(LargeRequest.t(), GRPC.Server.Stream.t()) :: LargeReply.t()
  def call_large(request, _stream) do
    {received_at_gregorian_second, received_microsecond} =
      :microsecond |> DateTime.utc_now() |> DateTime.to_gregorian_seconds()

    %LargeReply{
      received_at_gregorian_sec: received_at_gregorian_second,
      received_at_microsecond: received_microsecond,
      unique_id: request.unique_id,
      decoded_in: Diploma.Measurer.Server.get_grpc_decoded_in(request.unique_id)
    }
  end
end
