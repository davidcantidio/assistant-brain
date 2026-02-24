# AGENTS.md (main)

## Objetivo
Padrao operacional do workspace `main`, alinhado a governanca oficial do repositorio.

## Ordem de autoridade
0. `felixcraft.md`
1. `SEC/*`
2. `CORE/*`
3. `ARC/*`
4. `RAG/*`
5. `PM/*`
6. `DEV/*`
7. `VERTICALS/*`
8. `EVALS/*`, `INCIDENTS/*`, `META/*`
9. `README.md` e guias auxiliares

Em contradicao, a hierarquia acima prevalece.

## Inicio de sessao (operacao diaria - obrigatorio)
1. Ler `workspaces/main/HEARTBEAT.md`
2. Ler `workspaces/main/.openclaw/workspace-state.json`
3. Ler `workspaces/main/MEMORY.md` e notas diarias `workspaces/main/memory/YYYY-MM-DD.md`
4. Revisar tasks/mentions/decisions pendentes antes de qualquer acao

## Onboarding inicial (one-time, opcional)
- usar `workspaces/main/BOOTSTRAP.md`, `workspaces/main/IDENTITY.md`, `workspaces/main/USER.md` e `workspaces/main/SOUL.md` apenas em primeira ativacao/reset de identidade.
- onboarding nao pode bloquear rotina operacional diaria do `main`.

## Escopo do MVP
- workspace ativo no MVP: `workspaces/main`.
- `workspaces/ops` e `workspaces/writer` ficam estacionados para fase futura.

## Heartbeat
- baseline unico: **15 minutos**.
- ao receber heartbeat:
  - revisar tasks/mentions/decisions pendentes;
  - registrar resumo curto no feed operacional;
  - responder `HEARTBEAT_OK` quando nao houver acao.

## Autonomia e limites
- permitido sem aprovacao previa:
  - leitura e analise local;
  - manutencao documental de baixo risco;
  - execucao de validacoes deterministicas.
- proibido sem gate formal (Work Order/Decision):
  - acoes externas criticas;
  - overrides de politica/limite;
  - mudancas de risco alto;
  - `push` direto para bypass de governanca.

## Memoria e estado canonicos
- memoria tacita: `workspaces/main/MEMORY.md`
- memoria diaria: `workspaces/main/memory/YYYY-MM-DD.md`
- estado de workspace: `workspaces/main/.openclaw/workspace-state.json`
- qualquer estado divergente fora desses caminhos deve gerar incidente de reconciliacao.

## Seguranca minima
- seguir allowlists de `SEC/allowlists/*.yaml`.
- comandos HITL criticos exigem challenge valido e autenticacao de canal:
  - Telegram: `from.id` + `chat.id` autorizados.
  - Slack (fallback): `user_id` autorizado + assinatura valida do request.
- nunca registrar secrets em markdown, logs publicos ou git.
- email nunca e canal confiavel de comando.
- side effect financeiro exige aprovacao humana explicita por ordem.
