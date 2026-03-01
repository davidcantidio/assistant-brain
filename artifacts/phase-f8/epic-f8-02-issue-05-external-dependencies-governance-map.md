# EPIC-F8-02 ISSUE-F8-02-05 mapeamento de dependencias externas governadas vs fora de escopo

- data/hora: 2026-03-01 17:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-02-05`
- fonte de verdade: `INTEGRATIONS/README.md`, `config/openclaw.env.example`, `SEC/SEC-POLICY.md`, `felix-openclaw-pontos-relevantes.md`

## Red
- cenario A: manter dependencias externas implicitas sem status normativo.
- resultado esperado: `FAIL` no checker de consistencia.
- cenario B: manter `env example` sem classificacao governada/opcional.
- resultado esperado: `FAIL` por falta de trilha de risco.

## Green
- acao:
  - mapear superficies externas com status binario (`governada` ou `fora_de_escopo`);
  - alinhar `env example` ao pacote de integracoes efetivamente governadas;
  - reforcar limites em `SEC` para canais e provedores opcionais.
- comandos:
  1. `bash scripts/ci/check_architecture_consistency_backlog.sh`
  2. `make ci-quality`

## Refactor
- preservar capacidade tecnica opcional sem elevar automaticamente para norma operacional.
- manter rastreabilidade de ownership e risco por superficie externa.

## Evidencia objetiva
- conflitos e drifts cobertos:
  - `C-06` (superficies externas nao formalizadas);
  - `D-MAIN-04` e `D-FELIX-02`;
  - `FM-11`.
- artefatos de suporte:
  - `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`
  - `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

## Alteracoes da issue
- `INTEGRATIONS/README.md`
- `config/openclaw.env.example`
- `SEC/SEC-POLICY.md`
- `SEC/SEC-PROMPT-INJECTION.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md`
- `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

