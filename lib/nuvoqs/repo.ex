defmodule Nuvoqs.Repo do
  use Ecto.Repo,
    otp_app: :nuvoqs,
    adapter: Ecto.Adapters.Postgres
end
