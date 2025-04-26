defmodule DiplomaWeb.GRPCEndpoint do
  use GRPC.Endpoint

  # intercept GRPC.Server.Interceptors.Logger
  run(Diploma.GRPC.Server)
end
