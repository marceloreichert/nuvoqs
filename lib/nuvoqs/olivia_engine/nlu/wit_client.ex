defmodule Nuvoqs.OliviaEngine.NLU.WitClient do
  @moduledoc """
  HTTP client for the Wit.ai /message API.
  Extracts intents, entities, and traits from user messages.

  ## Configuration

      config :olivia_engine, Nuvoqs.OliviaEngine.NLU.WitClient,
        server_token: "YOUR_WIT_SERVER_TOKEN",
        api_version: "20240304",
        confidence_threshold: 0.6
  """

  require Logger

  @base_url "https://api.wit.ai"

  defstruct [:text, :intents, :entities, :traits, :msg_id]

  @type intent :: %{name: String.t(), confidence: float()}
  @type entity :: %{
          name: String.t(),
          role: String.t(),
          value: any(),
          confidence: float(),
          body: String.t()
        }
  @type t :: %__MODULE__{
          text: String.t(),
          intents: [intent()],
          entities: [entity()],
          traits: map(),
          msg_id: String.t() | nil
        }

  @doc """
  Parses a user message through Wit.ai and returns structured NLU result.

  ## Examples

      iex> WitClient.parse("I want to book a flight to Paris tomorrow")
      {:ok, %WitClient{
        text: "I want to book a flight to Paris tomorrow",
        intents: [%{name: "book_flight", confidence: 0.98}],
        entities: [
          %{name: "wit$location", role: "destination", value: "Paris", confidence: 0.95, body: "Paris"},
          %{name: "wit$datetime", role: "datetime", value: "2025-01-02T00:00:00.000-03:00", confidence: 0.99, body: "tomorrow"}
        ],
        traits: %{}
      }}
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(text) when is_binary(text) do
    config = config()
    token = Keyword.fetch!(config, :server_token)
    version = Keyword.get(config, :api_version, "20240304")
    threshold = Keyword.get(config, :confidence_threshold, 0.6)

    url = "#{@base_url}/message?v=#{version}&q=#{URI.encode(text)}"

    case Req.get(url,
           headers: [{"Authorization", "Bearer #{token}"}],
           connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Logger.debug("Wit.ai API response: #{inspect(body)}")
        {:ok, normalize_response(body, text, threshold)}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("Wit.ai API error: #{status} - #{inspect(body)}")
        {:error, {:wit_api_error, status, body}}

      {:error, reason} ->
        Logger.error("Wit.ai HTTP error: #{inspect(reason)}")
        {:error, {:http_error, reason}}
    end
  end

  defp normalize_response(body, text, threshold) do
    intents =
      body
      |> Map.get("intents", [])
      |> Enum.filter(&(&1["confidence"] >= threshold))
      |> Enum.map(fn i ->
        %{name: i["name"], confidence: i["confidence"]}
      end)

    entities =
      body
      |> Map.get("entities", %{})
      |> Enum.flat_map(fn {key, values} ->
        values
        |> Enum.filter(&(&1["confidence"] >= threshold))
        |> Enum.map(fn e ->
          %{
            name: key,
            role: e["role"] || key,
            value: e["value"],
            confidence: e["confidence"],
            body: e["body"] || ""
          }
        end)
      end)

    traits =
      body
      |> Map.get("traits", %{})
      |> Enum.into(%{}, fn {key, values} ->
        top = List.first(values)

        if top && top["confidence"] >= threshold do
          {key, top["value"]}
        else
          {key, nil}
        end
      end)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    %__MODULE__{
      text: text,
      intents: intents,
      entities: entities,
      traits: traits,
      msg_id: body["msg_id"]
    }
  end

  @doc """
  Returns the top intent name from a parsed result, or nil.
  """
  @spec top_intent(t()) :: String.t() | nil
  def top_intent(%__MODULE__{intents: []}), do: nil

  def top_intent(%__MODULE__{intents: intents}) do
    intents
    |> Enum.max_by(& &1.confidence)
    |> Map.get(:name)
  end

  @doc """
  Extracts entity values by role name.
  """
  @spec get_entity(t(), String.t()) :: any() | nil
  def get_entity(%__MODULE__{entities: entities}, role) do
    case Enum.find(entities, &(&1.role == role || &1.name == role)) do
      nil -> nil
      entity -> entity.value
    end
  end

  defp config do
    Application.get_env(:nuvoqs, __MODULE__, [])
  end
end
