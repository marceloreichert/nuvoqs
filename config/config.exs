# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :nuvoqs, :scopes,
  user: [
    default: true,
    module: Nuvoqs.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Nuvoqs.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :nuvoqs,
  ecto_repos: [Nuvoqs.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :nuvoqs, NuvoqsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NuvoqsWeb.ErrorHTML, json: NuvoqsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Nuvoqs.PubSub,
  live_view: [signing_salt: "IIOPZlYJ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :nuvoqs, Nuvoqs.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  nuvoqs: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  nuvoqs: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# ── Nx / EXLA ──
# Use EXLA CPU backend for Bumblebee inference (no GPU required)
config :nx, :default_backend, EXLA.Backend

config :exla,
  preferred_clients: [:host],
  clients: [host: [platform: :host]]

# ── NLU Provider ──
# To switch to WitClient (cloud), change provider to:
# Nuvoqs.OliviaEngine.NLU.WitClient
config :nuvoqs, Nuvoqs.OliviaEngine.NLU,
  provider: Nuvoqs.OliviaEngine.NLU.BumblebeeNLU

config :nuvoqs, Nuvoqs.OliviaEngine.NLU.BumblebeeNLU,
  # Embedding model para similaridade semântica multilingual (PT-BR nativo)
  embedding_model: "intfloat/multilingual-e5-small",
  ner_model: "dslim/bert-base-NER",
  ner_tokenizer: "google-bert/bert-base-cased",
  confidence_threshold: 0.6

config :nuvoqs, Nuvoqs.OliviaEngine.NLU.WitClient,
  server_token: System.get_env("WIT_SERVER_TOKEN") || "CK4BAITE52NIHI4CMFXCYFZS4WMYPBXG",
  api_version: "20240304",
  confidence_threshold: 0.6

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
