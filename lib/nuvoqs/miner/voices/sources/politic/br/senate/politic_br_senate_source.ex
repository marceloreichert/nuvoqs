defmodule Nuvoqs.Miner.Voices.Sources.Politic.Br.Senate.PoliticBrSenateSource do
  @moduledoc false

  @url_list "https://legis.senado.leg.br/dadosabertos/senador/lista/atual"

  def list_all_members() do
    case Req.get(@url_list,
           headers: [accept: "application/json"],
           receive_timeout: 300_000
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
