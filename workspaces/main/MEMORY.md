# MEMORY.md

## How The Operator Works
- Prefere comandos objetivos e resultados verificaveis.
- Aprova acoes sensiveis por canais confiaveis (Telegram primario, Slack fallback validado).
- Valoriza mudancas pequenas e auditaveis por issue/microtask.

## Communication Preferences
- Atualizacoes curtas de progresso durante execucao.
- Explicacao objetiva de risco, impacto e rollback antes de side effects.

## Hard Rules
- Email nunca e canal de comando confiavel.
- Toda acao com side effect financeiro exige aprovacao humana explicita.
- Em duvida sobre risco/canal, bloquear e pedir confirmacao no canal confiavel.

## Active Priorities
- Mission Control com OpenClaw gateway-first.
- Contratos de runtime (A2A, hooks, memory lifecycle, approval policy).
- Trading fail-closed com `execution_gateway` e `pre_trade_validator`.
