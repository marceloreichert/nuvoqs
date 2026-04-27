# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Nuvoqs.Repo.insert!(%Nuvoqs.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Nuvoqs.Repo

type_voices =
  Repo.insert!(%Nuvoqs.Schemas.TypeVoiceSchema{
    name: "Politics"
  })

Repo.insert!(%Nuvoqs.Schemas.VoiceSchema{
  name: "Brasil - Senado Federal",
  tag: "br_senate",
  sync_time: 1000,
  type_voice_id: type_voices.id
})
