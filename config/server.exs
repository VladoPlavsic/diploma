use Mix.Config

config :grpc, GRPC.Server.Supervisor, start_server: true
config :diploma, Quic.Server, start_server: true
