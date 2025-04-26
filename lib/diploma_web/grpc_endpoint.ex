defmodule DiplomaWeb.GRPCEndpoint do
  use GRPC.Endpoint

  run(Diploma.GRPC.Server)
end
