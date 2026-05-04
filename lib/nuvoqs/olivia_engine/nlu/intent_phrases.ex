defmodule Nuvoqs.OliviaEngine.NLU.IntentPhrases do
  @moduledoc """
  Intent reference phrases for semantic similarity classification.
  Each phrase uses E5 format: "passage: <description>"
  Phrases are grouped by context — use `for_context/1` to get the right set.
  """

  @general_phrases [
    {"confirm",
     [
       "passage: sim confirmo está correto",
       "passage: pode ser concordo",
       "passage: yes confirm that is right"
     ]},
    {"deny",
     [
       "passage: não está errado não quero",
       "passage: no that is wrong deny"
     ]},
    {"cancel",
     [
       "passage: cancelar operação desistir",
       "passage: cancel abort nevermind"
     ]},
    {"greet",
     [
       "passage: olá bom dia como vai",
       "passage: oi hello hi hey"
     ]},
    {"goodbye",
     [
       "passage: tchau até logo encerrar",
       "passage: goodbye bye see you"
     ]}
  ]

  @senate_phrases [
    {"ver_opcoes",
     [
       "passage: ver opções o que posso fazer",
       "passage: quais são as opções disponíveis menu ajuda",
       "passage: como posso usar este assistente"
     ]},
    {"consultar_senador",
     [
       "passage: consultar senador ver perfil",
       "passage: quero ver os dados de um senador pesquisar informações",
       "passage: buscar detalhes sobre um senador",
       "passage: ver perfil completo do parlamentar",
       "passage: quem é mostrar informações do senador"
     ]},
    {"ver_votacoes",
     [
       "passage: como o senador votou",
       "passage: quais foram as votações recentes do senado",
       "passage: resultado da votação",
       "passage: histórico de votos do senador"
     ]},
    {"seguir_senador",
     [
       "passage: quero começar a seguir um novo senador agora",
       "passage: adicionar um parlamentar novo para monitorar votações",
       "passage: inscrever em alertas de um senador específico",
       "passage: passar a acompanhar um senador que ainda não sigo"
     ]},
    {"politic_br_senate_list",
     [
       "passage: lista de senadores",
       "passage: quais são os senadores",
       "passage: mostrar todos os senadores",
       "passage: senadores do meu estado"
     ]},
    {"deixar_de_seguir_senador",
     [
       "passage: remover senador da minha lista",
       "passage: deixar senador fora da lista",
       "passage: cancelar monitoramento de senador",
       "passage: não quero mais receber alertas desse senador",
       "passage: desinscrever de senador",
       "passage: parar de receber notificações do parlamentar"
     ]},
    {"ver_senadores_que_sigo",
     [
       "passage: ver minha lista de senadores acompanhados",
       "passage: quais parlamentares já estou monitorando",
       "passage: mostrar minha lista parlamentares cadastrados",
       "passage: exibir senadores que já cadastrei para acompanhar"
     ]},
    {"confirm",
     [
       "passage: sim confirmo está correto",
       "passage: pode ser concordo",
       "passage: yes confirm that is right"
     ]},
    {"deny",
     [
       "passage: não está errado não quero",
       "passage: no that is wrong deny"
     ]},
    {"cancel",
     [
       "passage: cancelar operação desistir sair",
       "passage: não quero mais parar cancel abort nevermind"
     ]},
    {"greet",
     [
       "passage: olá bom dia como vai",
       "passage: oi hello hi hey"
     ]},
    {"goodbye",
     [
       "passage: tchau até logo encerrar",
       "passage: goodbye bye see you"
     ]}
  ]

  @spec for_context(String.t() | nil) :: [{String.t(), [String.t()]}]
  def for_context("politic_br_senate"), do: @senate_phrases
  def for_context(_), do: @general_phrases

  @spec suggestions_for_context(String.t() | nil) :: [{String.t(), String.t()}]
  def suggestions_for_context("politic_br_senate") do
    [
      {"Consultar senador", "consultar_senador"},
      {"Seguir senador", "seguir_senador"},
      {"Deixar de seguir", "deixar_de_seguir_senador"},
      {"Minha lista", "ver_senadores_que_sigo"}
    ]
  end
  def suggestions_for_context(_), do: []

  @spec all() :: [{String.t(), [String.t()]}]
  def all, do: @general_phrases
end
