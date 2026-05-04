defmodule Nuvoqs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NuvoqsWeb.Telemetry,
      Nuvoqs.Repo,
      {DNSCluster, query: Application.get_env(:nuvoqs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nuvoqs.PubSub},
      # Start a worker by calling: Nuvoqs.Worker.start_link(arg)
      # {Nuvoqs.Worker, arg},
      # Start to serve requests, typically the last entry
      # %{
      #   id: Nuvoqs.Miner.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent,
      #   start:
      #     {Nuvoqs.Miner.Behaviours.EventBehaviour, :start_link,
      #      [Nuvoqs.Miner.Voices.Events.Politic.Br.Senate.PoliticBrSenateEvent]}
      # },
      # Registry for looking up sessions by session_id
      {Registry, keys: :unique, name: Nuvoqs.OliviaEngine.SessionRegistry},
      # DynamicSupervisor for session GenServers
      {DynamicSupervisor, name: Nuvoqs.OliviaEngine.SessionSupervisor, strategy: :one_for_one},
      # Flow registry (ETS-backed, stores flow definitions)
      Nuvoqs.OliviaEngine.Flow.Registry,
      # Actions registry (GenServer, stores action handlers)
      Nuvoqs.OliviaEngine.Flow.Actions,
      # Bumblebee NLU: embedding (intent) + NER models
      Nuvoqs.OliviaEngine.NLU.BumblebeeNLU.intent_serving_spec(),
      Nuvoqs.OliviaEngine.NLU.BumblebeeNLU.ner_serving_spec(),
      NuvoqsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nuvoqs.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    # --- Registrar flows e actions APÓS o supervisor subir ---
    register_flows()
    register_actions()

    {:ok, pid}
  end

  defp register_flows do
    Nuvoqs.OliviaEngine.Flow.Registry.register_module(Nuvoqs.OliviaEngine.Examples.BookFlight)
    Nuvoqs.OliviaEngine.Flow.Registry.register_module(Nuvoqs.OliviaEngine.Flows.PoliticBrSenate)
  end

  defp register_actions do
    alias Nuvoqs.OliviaEngine.Flow.Actions
    alias Nuvoqs.OliviaEngine.Flows.SenateQuery

    Actions.register_validator(:senator_exists, fn name ->
      case SenateQuery.search_by_name(name) do
        [] ->
          {:error, "Senador \"#{name}\" não encontrado. Tente outro nome."}

        [member] ->
          extra = %{senator_url_photo: member.data["url_photo"]}
          {:ok, member.data["name"], extra}

        members ->
          options =
            members
            |> Enum.map(&("• " <> SenateQuery.format_member(&1)))
            |> Enum.join("\n")

          {:error, "Encontrei mais de um senador com esse nome:\n#{options}\nPor favor, seja mais específico."}
      end
    end)

    Actions.register(:ver_opcoes, fn ctx ->
      alias Nuvoqs.OliviaEngine.NLU.IntentPhrases
      suggestions = IntentPhrases.suggestions_for_context(ctx.metadata[:chat_context])

      if suggestions == [] do
        {:ok, "Não há opções configuradas para este contexto."}
      else
        {:ok, "O que você gostaria de fazer?", %{suggestions: suggestions}}
      end
    end)

    Actions.register(:politic_br_senate_list, fn _ctx ->
      members = SenateQuery.list_all()

      if members == [] do
        {:ok, "Nenhum senador cadastrado ainda. Os dados são sincronizados via API do Senado."}
      else
        list =
          members
          |> Enum.map(&SenateQuery.format_member/1)
          |> Enum.join("\n• ")

        {:ok, "Senadores cadastrados (primeiros 15):\n• #{list}"}
      end
    end)

    Actions.register(:consultar_senador, fn ctx ->
      name = ctx.slots[:senator_name]
      url_photo = ctx.slots[:senator_url_photo]

      case SenateQuery.search_by_name(name) do
        [] ->
          {:ok, "Não encontrei nenhum senador com o nome \"#{name}\". Tente outro nome."}

        [member | _] ->
          data = member.data

          entries =
            [
              {data["full_name"] || data["name"] || "—", %{}},
              {"", %{image_url: url_photo}},
              {"Nome parlamentar: #{data["name"] || "—"}", %{}},
              {"Partido: #{data["party_acronym"] || "—"} / Estado: #{data["uf"] || "—"}", %{}}
            ]
            |> then(fn e ->
              if email = data["email"], do: e ++ [{"E-mail: #{email}", %{}}], else: e
            end)
            |> then(fn e ->
              if url = data["url_homepage"], do: e ++ [{"Página: #{url}", %{}}], else: e
            end)

          {:ok, :multi, entries}
      end
    end)

    Actions.register(:ver_votacoes, fn ctx ->
      name = ctx.slots[:senator_name]

      case SenateQuery.search_by_name(name) do
        [] ->
          {:ok, "Não encontrei o senador \"#{name}\". Verifique o nome e tente novamente."}

        [member | _] ->
          label = SenateQuery.format_member(member)
          {:ok, "As votações de #{label} serão exibidas em breve. Estamos integrando com a API do Senado Federal."}
      end
    end)

    Actions.register(:ver_senadores_que_sigo, fn ctx ->
      user_id = ctx.metadata[:user_id] |> to_string() |> String.to_integer()

      case SenateQuery.list_followed_with_photos(user_id) do
        [] ->
          {:ok, "Você ainda não acompanha nenhum senador. Digite \"seguir senador\" para começar!"}

        senators ->
          header = {"Senadores que você acompanha:", %{}}

          entries =
            Enum.map(senators, fn %{label: label, url_photo: photo} ->
              {"• #{label}", %{image_url: photo}}
            end)

          {:ok, :multi, [header | entries]}
      end
    end)

    Actions.register(:listar_seguidos_para_remover, fn ctx ->
      user_id = ctx.metadata[:user_id] |> to_string() |> String.to_integer()

      case SenateQuery.list_followed_with_photos(user_id) do
        [] ->
          {:halt, "Você ainda não acompanha nenhum senador."}

        senators ->
          header = {"Você acompanha os seguintes senadores:", %{}}

          entries =
            Enum.map(senators, fn %{label: label, url_photo: photo} ->
              {"• #{label}", %{image_url: photo}}
            end)

          {:ok, :multi, [header | entries]}
      end
    end)

    Actions.register(:deixar_de_seguir_senador, fn ctx ->
      name = ctx.slots[:senator_name]
      user_id = ctx.metadata[:user_id] |> to_string() |> String.to_integer()

      case SenateQuery.search_by_name(name) do
        [] ->
          {:ok, "Senador \"#{name}\" não encontrado."}

        [member | _] ->
          case SenateQuery.unfollow(user_id, member.id) do
            :ok            -> {:ok, "Você deixou de acompanhar #{SenateQuery.format_member(member)}."}
            {:error, _}    -> {:ok, "Você não estava acompanhando #{SenateQuery.format_member(member)}."}
          end
      end
    end)

    Actions.register(:check_seguir_limit, fn ctx ->
      user_id = ctx.metadata[:user_id] |> to_string() |> String.to_integer()

      if SenateQuery.count_followed(user_id) >= 3 do
        {:halt, "Você já acompanha 3 senadores, que é o limite permitido. Remova um para poder seguir outro."}
      else
        :ok
      end
    end)

    Actions.register(:seguir_senador, fn ctx ->
      name = ctx.slots[:senator_name]
      user_id = ctx.metadata[:user_id] |> to_string() |> String.to_integer()

      case SenateQuery.search_by_name(name) do
        [] ->
          {:ok, "Não encontrei o senador \"#{name}\". Verifique o nome."}

        [member | _] ->
          case SenateQuery.follow(user_id, member.id) do
            {:ok, _} -> {:ok, "Você agora acompanha #{SenateQuery.format_member(member)}!"}
            {:error, _} -> {:ok, "Você já acompanha este senador."}
          end
      end
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NuvoqsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
