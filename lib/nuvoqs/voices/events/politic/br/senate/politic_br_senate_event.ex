defmodule Nuvoqs.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent do
  require Logger

  alias Nuvoqs.Voices.Sources.Politic.Br.Senate.PoliticBrSenateSource
  alias Nuvoqs.Voices.Targets.Politic.Br.Senate.PoliticBrSenatePGTarget

  @behaviour Nuvoqs.Behaviours.EventBehaviour

  @interval_ms 1_000 * 60 * 60

  @spec init(any) :: {:ok, any}
  def init(init_arg) do
    {:ok, init_arg}
  end

  @spec interval_ms :: integer()
  def interval_ms(), do: @interval_ms

  @spec process_event :: :ok
  def process_event() do
    Logger.info(
      "Start Processing PoliticBrSenateEvent - " <>
        Timex.format!(Timex.now("America/Sao_Paulo"), "{ISO:Extended}")
    )

    case PoliticBrSenateSource.list_all_members() do
      {:ok, body} ->
        with body_decode <- Jason.decode!(body),
             %{"ListaParlamentarEmExercicio" => active_parliamentarians} <- body_decode,
             %{"Parlamentares" => all_parliamentarians} <- active_parliamentarians,
             %{"Parlamentar" => parliamentarians} <- all_parliamentarians do
          Enum.map(parliamentarians, &do_process/1)
        end

        :ok

      {:error, reason} ->
        Logger.warning(reason)
    end

    Logger.info(
      "End Processing PoliticBrSenateEvent - " <>
        Timex.format!(Timex.now("America/Sao_Paulo"), "{ISO:Extended}")
    )
  end

  defp do_process(data) do
    with %{"IdentificacaoParlamentar" => parliamentary_identification} <- data,
         %{
           "CodigoParlamentar" => identifier,
           "CodigoPublicoNaLegAtual" => current_public_code,
           "EmailParlamentar" => email,
           "FormaTratamento" => form_treatment,
           "MembroLideranca" => leadership_member,
           "MembroMesa" => board_member,
           "NomeCompletoParlamentar" => full_name,
           "NomeParlamentar" => name,
           "SiglaPartidoParlamentar" => party_acronym,
           "UfParlamentar" => uf,
           "UrlFotoParlamentar" => url_photo,
           "UrlPaginaParlamentar" => url_homepage
         } <-
           parliamentary_identification do
             case PoliticBrSenatePGTarget.get_member_by(identifier: identifier) do
        {:ok, :not_found} ->
          board_member = if board_member == "Sim", do: true, else: false
          leadership_member = if leadership_member == "Sim", do: true, else: false

          %{
            "identifier" => identifier,
            "data" => %{
              "current_public_code" => current_public_code,
              "email" => email,
              "form_treatment" => form_treatment,
              "leadership_member" => leadership_member,
              "board_member" => board_member,
              "full_name" => full_name,
              "name" => name,
              "party_acronym" => party_acronym,
              "uf" => uf,
              "url_photo" => url_photo,
              "url_homepage" => url_homepage
            }
          }
          |> PoliticBrSenatePGTarget.post_member()

        {:ok, _data} ->
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    else
      error -> error
    end
  end
end
