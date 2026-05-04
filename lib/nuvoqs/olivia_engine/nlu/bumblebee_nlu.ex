defmodule Nuvoqs.OliviaEngine.NLU.BumblebeeNLU do
  @moduledoc """
  Local NLU engine using Bumblebee (Nx + Axon + HuggingFace models).

  Uses two models:
  - **Intent classification**: zero-shot classification (no fine-tuning needed)
    or a fine-tuned text classification model
  - **Entity extraction**: BERT-based Named Entity Recognition (NER)

  ## Configuration

      config :nuvoqs, Nuvoqs.OliviaEngine.NLU.BumblebeeNLU,
        # Intent classification mode:
        #   :zero_shot  - uses zero-shot model with candidate labels (no training needed)
        #   :fine_tuned - uses a fine-tuned text classification model
        intent_mode: :zero_shot,

        # For :zero_shot mode - the candidate intent labels
        intent_labels: ["book_flight", "check_order", "cancel", "confirm", "deny", "greet"],

        # For :fine_tuned mode - HuggingFace repo with your fine-tuned model
        # intent_model: "your-org/your-intent-model",
        # intent_tokenizer: "your-org/your-intent-model",

        # NER model (works out of the box)
        ner_model: "dslim/bert-base-NER",
        ner_tokenizer: "google-bert/bert-base-cased",

        # Zero-shot model
        zero_shot_model: "facebook/bart-large-mnli",
        zero_shot_tokenizer: "facebook/bart-large-mnli",

        # Minimum confidence to accept a prediction
        confidence_threshold: 0.5
  """

  require Logger

  defstruct [:text, :intents, :entities, :traits]

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
          traits: map()
        }

  # ── Nx.Serving names (registered in Application supervisor) ──

  @intent_serving Nuvoqs.OliviaEngine.NLU.IntentServing

  # ── Public API ──

  @doc """
  Parses a user message using local Bumblebee models.
  Returns the same struct shape as the old WitClient for drop-in compatibility.

  ## Examples

      iex> BumblebeeNLU.parse("I want to book a flight to Paris tomorrow")
      {:ok, %BumblebeeNLU{
        text: "I want to book a flight to Paris tomorrow",
        intents: [%{name: "book_flight", confidence: 0.92}],
        entities: [
          %{name: "LOC", role: "LOC", value: "Paris", confidence: 0.99, body: "Paris"},
        ],
        traits: %{}
      }}
  """
  @spec parse(String.t(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def parse(text, context \\ nil) when is_binary(text) do
    Logger.info("Parsing text: #{inspect(text)} [context: #{inspect(context)}]")
    threshold = config(:confidence_threshold, 0.5)

    with {:ok, intents} <- classify_intent(text, threshold, context) do
      result = %__MODULE__{
        text: text,
        intents: intents,
        entities: [],
        traits: %{}
      }

      {:ok, result}
    end
  rescue
    e ->
      Logger.error("BumblebeeNLU parse failed: #{inspect(e)}")
      {:error, {:nlu_error, e}}
  end

  @doc "Returns the top intent name, or nil."
  @spec top_intent(t()) :: String.t() | nil
  def top_intent(%__MODULE__{intents: []}), do: nil

  def top_intent(%__MODULE__{intents: intents}) do
    intents
    |> Enum.max_by(& &1.confidence)
    |> Map.get(:name)
  end

  @doc "Extracts entity value by role/name."
  @spec get_entity(t(), String.t()) :: any() | nil
  def get_entity(%__MODULE__{entities: entities}, role) do
    case Enum.find(entities, &(&1.role == role || &1.name == role)) do
      nil -> nil
      entity -> entity.value
    end
  end

  # ── Serving builders (called from Application supervisor) ──

  @doc """
  Builds the intent classification Nx.Serving.
  Add this to your supervision tree.
  """
  @spec intent_serving_spec() :: {Nx.Serving, keyword()}
  def intent_serving_spec do
    repo = config(:embedding_model, "intfloat/multilingual-e5-small")
    Logger.info("[BumblebeeNLU] Loading embedding model #{repo}...")
    {:ok, model} = Bumblebee.load_model({:hf, repo})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, repo})

    serving =
      Bumblebee.Text.text_embedding(model, tokenizer,
        compile: [batch_size: 16, sequence_length: 128],
        defn_options: [compiler: EXLA],
        output_pool: :mean_pooling,
        output_attribute: :hidden_state
      )

    Logger.info("[BumblebeeNLU] Embedding model ready.")
    {Nx.Serving, serving: serving, name: @intent_serving, batch_size: 16, batch_timeout: 50}
  end

  alias Nuvoqs.OliviaEngine.NLU.IntentPhrases

  # ── Private: Intent via cosine similarity ─────────────────────────────

  defp classify_intent(text, threshold, context) do
    query = "query: #{text}"
    %{embedding: user_emb} = Nx.Serving.batched_run(@intent_serving, query)

    all_scored =
      Enum.map(IntentPhrases.for_context(context), fn {intent_name, phrases} ->
        max_score =
          phrases
          |> Enum.map(&cached_phrase_embedding/1)
          |> Enum.map(&cosine_similarity(user_emb, &1))
          |> Enum.max()

        %{name: intent_name, confidence: max_score}
      end)

    top = Enum.max_by(all_scored, & &1.confidence)
    intents = if top.confidence >= threshold, do: [top], else: []
    {:ok, intents}
  end

  defp cached_phrase_embedding(phrase) do
    key = {:phrase_emb, phrase}

    case :persistent_term.get(key, nil) do
      nil ->
        %{embedding: emb} = Nx.Serving.batched_run(@intent_serving, phrase)
        :persistent_term.put(key, emb)
        emb

      emb ->
        emb
    end
  end

  # ── Private: Cosine similarity ────────────────────────────────────────

  defp cosine_similarity(a, b) do
    a = l2_normalize(a)
    b = l2_normalize(b)
    Nx.dot(a, b) |> Nx.to_number()
  end

  defp l2_normalize(tensor) do
    Nx.divide(tensor, Nx.LinAlg.norm(tensor))
  end

  # ── Config helper ──

  defp config(key, default \\ nil) do
    Application.get_env(:nuvoqs, __MODULE__, [])
    |> Keyword.get(key, default)
  end
end
