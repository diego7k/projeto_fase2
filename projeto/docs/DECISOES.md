# Decisões técnicas - Fase 2 (Big Data e Analytics)

## 1. Origem dos dados
- Fonte: Observatório Obstétrico Brasileiro (OOBR), óbitos na gravidez/puerpério, 1996-2024, baixado do Synapse (pasta `syn42902915`).
- Arquivos originais (versão original) em `data/raw/`, com `manifest.csv` (ID Synapse, versão e MD5 de cada arquivo).
- Dados originais: 5 CSVs, ~33 MB, 164.918 linhas no total.

## 2. Diferenças entre a proposta da fase 1 e os dados reais
| Previsto na fase 1 | O que existe nos dados | Decisão |
|---|---|---|
| Data de óbito (DATE) | Só existe o ano | Usar `ano` (INTEGER) em `dim_tempo` |
| Nascidos vivos / razão de mortalidade materna | Não existem nos arquivos | Não armazenar; indicador pode ser calculado depois com nascidos vivos do SINASC (outra fonte) |
| Violência obstétrica | Não existe nos arquivos (são óbitos maternos) | Escopo da fase 2 = mortalidade materna; violência obstétrica fica fora da base atual |
| Limite de 1 GB exigia agregar/reduzir | Dados tratados ocupam ~9 MB em CSV | Sem necessidade de amostragem ou agregação extra; mantidas todas as colunas úteis |

## 3. Tratamentos aplicados (código em `src/etl.py`)
| Problema | Ação | Justificativa |
|---|---|---|
| Coluna `X` (índice do R) | Removida | Sem valor analítico |
| Espaços/tipos como texto | `strip()`; ano e idade para inteiro; `codigo` com 6 dígitos | Tipagem do PostgreSQL |
| Estado civil com variação de gênero (Solteira/Solteiro, Casada/Casado...) | Unificado em 6 categorias | Evitar contar a mesma categoria duas vezes |
| `necropsia` nula (1 registro) | Preenchida com "Ignorado" | Mesma categoria já usada na base |
| 140 linhas idênticas em `analise_cruzada` | **Mantidas** | Cada linha é 1 óbito; o total (48.933) bate com `maternos_oficiais` e `ufs`. Removê-las perderia óbitos reais |
| Municípios "ignorados" (21) | Mantidos e sinalizados (`municipio_ignorado`) | Os óbitos existem, só falta o município |
| 6 registros com idade < 10 anos | Mantidos na faixa "0 a 9" | Possível erro da fonte, sinalizado no log |
| Nomes de colunas com mais de 63 caracteres (arquivo `ufs`) | Encurtados | PostgreSQL trunca nomes maiores que 63 caracteres |
| Repetição de texto em todas as linhas | Modelo estrela (dimensões + fatos) | Menos redundância e consultas mais simples para o painel |

## 4. Validações (ver `docs/log_etl.txt`)
- Óbitos maternos: 48.933 em `maternos_oficiais` = `analise_cruzada` = `ufs`.
- Óbitos desconsiderados: 42.311 em `desconsiderados` = soma das colunas "descons" de `ufs`.
- Nenhuma chave estrangeira sem correspondência.

## 5. Modelagem
Modelo estrela em PostgreSQL (schema `painel`): 8 dimensões e 5 tabelas fato, uma por arquivo de origem.
Justificativa: dados são contagens por dimensões (tempo, local, faixa etária, raça/cor, causa), o que combina com consultas agregadas de painel.

## 6. Ferramentas
Python/pandas (ETL), PostgreSQL no Aiven (banco em nuvem), psycopg2 (carga via COPY), GitHub (versionamento).
