# Sessions (Not Versioned)

Arquivos de sessao (`*.json`, `*.jsonl`) nao devem ser versionados.

Motivo:
- podem conter dados sensiveis de conversa
- podem conter metadados de auth/session

Politica:
- manter apenas armazenamento local/segregado
- aplicar redaction antes de qualquer compartilhamento manual
