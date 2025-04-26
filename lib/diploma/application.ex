defmodule Diploma.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    grpc_overrides = Application.fetch_env!(:grpc, GRPC.Server.Supervisor)

    # List all child processes to be supervised
    children =
      [
        {GRPC.Server.Supervisor,
         endpoint: DiplomaWeb.GRPCEndpoint,
         port: 50051,
         start_server: grpc_overrides[:start_server]},
        {Diploma.Measurer.Server, []}
      ] ++
        if(grpc_overrides[:start_server],
          do: [],
          else: [{Diploma.GRPC.Client, []}]
        )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Diploma.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DiplomaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
