defmodule Nuvoqs.Miner.Voices.Sources.Politic.Br.Senate.PoliticBrSenateSource do
  @moduledoc false

  @url_list "https://legis.senado.leg.br/dadosabertos/senador/lista/atual"
  @headers [Accept: "Application/json"]
  @options [ssl: [{:versions, [:"tlsv1.2"]}], timeout: 300_000, recv_timeout: 300_000]

  def list_all_members() do
    case HTTPoison.get(@url_list, @headers, @options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
