defmodule Nuvoqs.OliviaEngine.NLU.IntentPhrases do
  @moduledoc """
  Intent reference phrases for semantic similarity classification.

  Add or expand phrases here to improve NLU accuracy for PT-BR and EN.
  Each phrase uses E5 format: "passage: <description>"
  """

  @phrases [
    {"book_flight",
     [
       "passage: quero reservar um voo",
       "passage: preciso comprar passagem aérea",
       "passage: quero viajar de avião",
       "passage: book a flight to somewhere",
       "passage: I want to fly"
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
     ]},
    {"check_status",
     [
       "passage: verificar status consultar informação",
       "passage: check status information query"
     ]},
    {"cancel_booking",
     [
       "passage: cancelar reserva passagem aérea",
       "passage: cancel my booking reservation"
     ]}
  ]

  @spec all() :: [{String.t(), [String.t()]}]
  def all, do: @phrases
end
