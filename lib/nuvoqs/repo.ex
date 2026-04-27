defmodule nuvoQs.Repo do
  use Ecto.Repo,
    otp_app: :nuvoQs,
    adapter: Ecto.Adapters.Postgres
end
