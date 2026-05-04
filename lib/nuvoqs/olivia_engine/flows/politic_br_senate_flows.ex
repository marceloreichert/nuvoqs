defmodule Nuvoqs.OliviaEngine.Flows.PoliticBrSenate do
  @moduledoc """
  Flows for the politic_br_senate chat context.

  Intents handled:
  - greet            → simple greeting
  - listar_senadores → lists senators in the DB
  - consultar_senador → asks for a name, shows senator info
  - ver_votacoes     → asks for a name, shows voting info (stub)
  - seguir_senador   → asks for a name, confirms and registers follower
  """

  use Nuvoqs.OliviaEngine.Flow.DSL

  flow "ver_opcoes" do
    node :start do
      action(:ver_opcoes)
      terminal(true)
    end
  end

  flow "greet" do
    node :start do
      say(
        "Olá! Sou a Olivia, sua assistente para acompanhar o Senado Federal. Posso te ajudar a consultar senadores, ver votações ou acompanhar um parlamentar. Como posso ajudar?"
      )

      terminal(true)
    end
  end

  flow "politic_br_senate_list" do
    node :start do
      action(:politic_br_senate_list)
      terminal(true)
    end
  end

  flow "consultar_senador" do
    node :ask_name do
      say("Qual o nome do senador que deseja consultar?")
      slot :senator_name, prompt: "Digite o nome do senador:", validator: :senator_busca
      on_slots_filled(:show_info)
    end

    node :show_info do
      action(:consultar_senador)
      terminal(true)
    end
  end

  flow "ver_votacoes" do
    node :ask_name do
      say("Qual senador você deseja consultar as votações?")
      slot :senator_name, prompt: "Digite o nome do senador:", validator: :senator_exists
      on_slots_filled(:show_votes)
    end

    node :show_votes do
      action(:ver_votacoes)
      terminal(true)
    end
  end

  flow "deixar_de_seguir_senador" do
    node :ask_name do
      action(:listar_seguidos_para_remover)
      say("Qual deles você deseja deixar de acompanhar?")
      slot :senator_name, prompt: "Digite o nome do senador:", validator: :senator_exists
      on_slots_filled(:confirm_unfollow)
    end

    node :confirm_unfollow do
      action(:confirm_unfollow_prompt)
      transition(:do_unfollow, when: "confirm")
      transition(:cancel, when: "deny")
    end

    node :do_unfollow do
      action(:deixar_de_seguir_senador)
      terminal(true)
    end

    node :cancel do
      say("Ok, mantendo o acompanhamento.")
      terminal(true)
    end
  end

  flow "ver_senadores_que_sigo" do
    node :start do
      action(:ver_senadores_que_sigo)
      terminal(true)
    end
  end

  flow "seguir_senador" do
    node :ask_name do
      action(:check_seguir_limit)
      say("Qual senador você deseja acompanhar?")
      slot :senator_name, prompt: "Digite o nome do senador:", validator: :senator_exists
      on_slots_filled(:confirm_follow)
    end

    node :confirm_follow do
      say(
        "Deseja acompanhar o senador {{senator_name}}? Você receberá atualizações sobre as votações dele."
      )

      transition(:do_follow, when: "confirm")
      transition(:cancel, when: "deny")
    end

    node :do_follow do
      action(:seguir_senador)
      say("Pronto! Você agora acompanha o senador {{senator_name}}.")
      terminal(true)
    end

    node :cancel do
      say("Ok, sem problemas. Posso ajudar com mais alguma coisa?")
      terminal(true)
    end
  end
end
