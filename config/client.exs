use Mix.Config

config :grpc, GRPC.Server.Supervisor, start_server: false
config :diploma, Quic.Server, start_server: false
