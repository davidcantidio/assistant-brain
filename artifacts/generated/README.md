# Artifacts Gerados (Nao Versionados)

Diretorio reservado para saidas geradas localmente por scripts de validacao/auditoria.

## Regras
- estes arquivos NAO sao fonte canonica normativa;
- devem ser reproduziveis a partir de scripts versionados em `scripts/`;
- evidencias estaveis para auditoria devem ficar em `artifacts/phase-*` como Markdown consolidado.

## Exemplos de saida gerada
- `runtime-inventory-*.json`
- `runtime-merge-plan-*.json`
- `runtime-convergence-report-*.json`
- exports temporarios de rollout/canario.
