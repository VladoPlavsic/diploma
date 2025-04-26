defmodule Diploma.Repo do
  use Ecto.Repo,
    otp_app: :diploma,
    adapter: Ecto.Adapters.Postgres
end
