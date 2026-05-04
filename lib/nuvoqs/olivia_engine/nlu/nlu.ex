defmodule Nuvoqs.OliviaEngine.NLU do
  @moduledoc """
  Behaviour and facade for NLU providers.

  The active provider is configured in config:

      config :ex_chat_engine, ExChatEngine.NLU,
        provider: Nuvoqs.OliviaEngine.NLU.BumblebeeNLU   # local, no API needed
        # provider: Nuvoqs.OliviaEngine.NLU.WitClient     # cloud, needs token

  All providers must return the same struct shape so the Flow.Engine
  works identically regardless of which backend is active.
  """

  @type intent :: %{name: String.t(), confidence: float()}
  @type entity :: %{
          name: String.t(),
          role: String.t(),
          value: any(),
          confidence: float(),
          body: String.t()
        }
  @type nlu_result :: %{
          text: String.t(),
          intents: [intent()],
          entities: [entity()],
          traits: map()
        }

  @callback parse(String.t(), String.t() | nil) :: {:ok, nlu_result()} | {:error, term()}
  @callback top_intent(nlu_result()) :: String.t() | nil
  @callback get_entity(nlu_result(), String.t()) :: any() | nil

  @doc "Parse a message using the configured provider."
  @spec parse(String.t(), String.t() | nil) :: {:ok, nlu_result()} | {:error, term()}
  def parse(text, context \\ nil), do: provider().parse(text, context)

  @doc "Get top intent from a parsed result."
  @spec top_intent(nlu_result()) :: String.t() | nil
  def top_intent(result), do: provider().top_intent(result)

  @doc "Get entity value by role/name from a parsed result."
  @spec get_entity(nlu_result(), String.t()) :: any() | nil
  def get_entity(result, role), do: provider().get_entity(result, role)

  defp provider do
    Application.get_env(:nuvoqs, __MODULE__, [])
    |> Keyword.get(:provider, Nuvoqs.OliviaEngine.NLU.BumblebeeNLU)
  end
end
