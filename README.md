# nuvoqs


# Nuvoqs.OliviaEngine

Framework open-source em Elixir/OTP para gerenciamento de chatbots com integração Wit.ai.

## Características

- **Engine de diálogos OTP**: cada conversa é um processo GenServer isolado (fault-tolerant, escalável)
- **Integração Wit.ai**: classificação de intenções, extração de entidades e traits
- **Slot filling automático**: coleta entidades obrigatórias/opcionais antes de avançar no fluxo
- **Fluxos ramificados**: transições condicionais baseadas em intenções (confirm/deny/cancel)
- **DSL Elixir**: defina fluxos de forma declarativa ou via JSON na API REST
- **Actions extensíveis**: callbacks customizados executados em nós do fluxo
- **API REST**: Phoenix endpoint para integração com qualquer frontend/canal

## Arquitetura

```
┌─────────────────────────────────────────────────┐
│                 Nuvoqs.OliviaEngine (OTP)               │
│                                                  │
│  ┌──────────┐    ┌────────────────┐    ┌──────┐ │
│  │ API REST │───▶│ SessionManager │───▶│Wit.ai│ │
│  │ (Phoenix)│    │(DynSupervisor) │    │Client│ │
│  └──────────┘    └───────┬────────┘    └──────┘ │
│                          │                       │
│              ┌───────────┼───────────┐           │
│              ▼           ▼           ▼           │
│         ┌─────────┐ ┌─────────┐ ┌─────────┐     │
│         │Session 1│ │Session 2│ │Session N│     │
│         │ Dialog  │ │ Dialog  │ │ Dialog  │     │
│         │ Slots   │ │ Slots   │ │ Slots   │     │
│         └─────────┘ └─────────┘ └─────────┘     │
│                          │                       │
│              ┌───────────┴───────────┐           │
│              ▼                       ▼           │
│         ┌──────────┐         ┌────────────┐      │
│         │Flow Defs │         │Action Runner│     │
│         │(DSL/JSON)│         │ (Callbacks) │     │
│         └──────────┘         └────────────┘      │
└─────────────────────────────────────────────────┘
```

## Setup

### 1. Pré-requisitos

- Elixir >= 1.15
- Erlang/OTP >= 26
- Uma app no [Wit.ai](https://wit.ai) com intenções e entidades configuradas

### 2. Instalação

```bash
git clone <repo-url>
cd ex_chat_engine
mix deps.get
```

### 3. Configuração

Edite `config/config.exs` ou use variáveis de ambiente:

```bash
export WIT_SERVER_TOKEN="seu_token_do_wit_ai"
```

### 4. Iniciar o servidor

```bash
mix run --no-halt
# API disponível em http://localhost:4000
```

## Uso da API

### Enviar mensagem

```bash
curl -X POST http://localhost:4000/api/sessions/user123/messages \
  -H "Content-Type: application/json" \
  -d '{"text": "I want to book a flight to Paris"}'
```

Resposta:
```json
{
  "session_id": "user123",
  "responses": ["Great, let's book a flight! Where would you like to go?"]
}
```

### Iniciar um fluxo específico

```bash
curl -X POST http://localhost:4000/api/sessions/user123/flows/book_flight
```

### Ver estado da sessão

```bash
curl http://localhost:4000/api/sessions/user123
```

Resposta:
```json
{
  "session": {
    "session_id": "user123",
    "flow_name": "book_flight",
    "current_node": "collect_info",
    "slots": {"destination": "Paris"},
    "message_count": 2
  }
}
```

### Registrar fluxo via JSON

```bash
curl -X POST http://localhost:4000/api/flows \
  -H "Content-Type: application/json" \
  -d '{
    "name": "order_pizza",
    "entry_node": "start",
    "nodes": {
      "start": {
        "say": "What pizza would you like?",
        "slots": [
          {"name": "flavor", "entity": "pizza_flavor", "prompt": "Which flavor?"},
          {"name": "size", "entity": "pizza_size", "prompt": "What size? (small/medium/large)"}
        ],
        "on_slots_filled": "confirm"
      },
      "confirm": {
        "say": "{{size}} {{flavor}} pizza. Confirm?",
        "transitions": [
          {"target": "done", "when": "confirm"},
          {"target": "start", "when": "deny"}
        ]
      },
      "done": {
        "say": "Pizza ordered!",
        "action": "order_pizza",
        "terminal": true
      }
    }
  }'
```

### Listar fluxos

```bash
curl http://localhost:4000/api/flows
```

### Resetar sessão

```bash
curl -X DELETE http://localhost:4000/api/sessions/user123
```

## Definindo fluxos com DSL Elixir

```elixir
defmodule MyApp.Flows.Support do
  use Nuvoqs.OliviaEngine.Flow.DSL

  flow "customer_support" do
    node :greeting do
      say "Hi! How can I help you today?"
      transition :check_order, when: "check_order"
      transition :report_issue, when: "report_issue"
      transition :greeting  # fallback - ask again
    end

    node :check_order do
      slot :order_id, entity: "order_number", prompt: "What's your order number?"
      on_slots_filled :show_order
    end

    node :show_order do
      action :lookup_order
      say "Here's your order status for #{{order_id}}."
      terminal true
    end

    node :report_issue do
      slot :issue_type, entity: "issue_category", prompt: "What kind of issue?"
      slot :description, entity: "wit$message_body", prompt: "Please describe the issue."
      on_slots_filled :create_ticket
    end

    node :create_ticket do
      action :create_support_ticket
      say "I've created a support ticket for your {{issue_type}} issue."
      terminal true
    end
  end
end
```

Registre no startup da aplicação:

```elixir
# No Application.start/2:
Nuvoqs.OliviaEngine.Flow.Registry.register_module(MyApp.Flows.Support)
```

## Registrando actions

```elixir
Nuvoqs.OliviaEngine.Flow.Actions.register(:lookup_order, fn ctx ->
  order_id = ctx.slots[:order_id]
  # ... consultar banco/API ...
  {:ok, "Order #{order_id}: shipped, arriving tomorrow."}
end)

Nuvoqs.OliviaEngine.Flow.Actions.register(:create_support_ticket, fn ctx ->
  # ... criar ticket no sistema ...
  {:ok, "Ticket ##{:rand.uniform(9999)} created."}
end)
```

## Configuração do Wit.ai

No console do Wit.ai, configure:

1. **Intents**: `book_flight`, `confirm`, `deny`, `cancel`, `check_order`, `report_issue`
2. **Entities**: use built-ins (`wit$location`, `wit$datetime`, `wit$number`) e crie custom entities conforme seu domínio
3. **Training**: adicione exemplos de frases para cada intent

## Conceitos-chave

| Conceito | Descrição |
|----------|-----------|
| **Flow** | Grafo dirigido de nós que define uma conversa |
| **Node** | Estado no fluxo (tem mensagem, slots, transições) |
| **Slot** | Entidade necessária para avançar (ex: destino, data) |
| **Transition** | Aresta entre nós, condicionada a uma intenção |
| **Action** | Callback executado ao entrar em um nó |
| **Session** | Processo OTP isolado por usuário/conversa |

## Licença

MIT
