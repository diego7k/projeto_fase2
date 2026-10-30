# Decisões de tratamento

Resumo do que está no documento da entrega. O código de cada passo está em `src/etl.py` e as contagens saem em `docs/log_etl.txt`.

## Origem

Observatório Obstétrico Brasileiro (OOBr), baixado do Synapse (pasta `syn42902915`). Os cinco arquivos estão na versão 4 (atualização de fevereiro de 2025). O `etl.py` confere o MD5 de cada um com o `manifest.csv` antes de começar.

| Arquivo | Linhas | Colunas | Tamanho | Usado? |
|---|---|---|---|---|
| maternos_oficiais | 48.785 | 15 | 11,3 MB | sim |
| desconsiderados | 42.178 | 13 | 9,7 MB | sim |
| analise_cruzada | 48.933 | 18 | 10,8 MB | não, repete os óbitos oficiais com uma linha por óbito |
| ufs | 23.468 | 13 | 1,0 MB | não, a soma de óbitos é igual à dos oficiais (48.933) |
| garbage_codes | 1.554 | 15 | 0,35 MB | não, todas as linhas já estão nos oficiais |

## Recorte

Só 2014 a 2024. Dez anos dão para ver a tendência, incluindo a pandemia (2020 e 2021), e os anos mais antigos têm declarações de óbito pior preenchidas. Também ajuda a ficar bem abaixo do limite de 1 GB do Aiven.

## O que foi feito

1. Coluna `X` removida. É o número da linha na exportação e vem "NA" em 2023 e 2024.
2. `causabas_categoria` separada em `cod_categoria` (O15) e `categoria_descricao` (Eclâmpsia).
3. Idade 99 virou nula (idade não informada no SIM). São 1 caso nos oficiais e 13 nos desconsiderados. O óbito continua na base.
4. Nos desconsiderados ficaram só as idades de 10 a 49 anos. Saíram 881 óbitos com menos de 10 anos (quase todos com idade 0 e causas de recém-nascido, provavelmente declarações de bebês marcadas como gestação por engano) e 1.763 com 50 anos ou mais (a mais velha tinha 65).
5. Nos oficiais as 21 mortes com 50 anos ou mais foram mantidas, porque já foram investigadas e classificadas como maternas. Tirar mudaria o total oficial.
6. Faixa etária de 5 em 5 anos (10 a 14 até 45 a 49), mais "50 ou mais" e "Ignorada". A idade exata continua na coluna `idade`.
7. 2024 marcado com `preliminar = true` (só 745 óbitos oficiais, menos da metade dos outros anos).
8. "Ignorado" e "Sem informação" foram mantidos como categoria. Nos oficiais: 5.342 óbitos sem informação na investigação do comitê, 1.350 sem período do óbito e 432 com raça/cor ignorada.
9. Espaços extras retirados dos textos (ex.: "III - Doenças  do sangue" vinha com dois espaços).
10. Município identificado pelo código IBGE de 6 dígitos, guardado como texto. Os registros de "município ignorado" (2 nos oficiais e 13 nos desconsiderados) continuam e contam no total do estado.
11. Colunas com o mesmo significado têm o mesmo nome nos dois arquivos (`cod_municipio`, `raca_cor`, `periodo_obito`, `qtd_obitos`).
12. Não há linhas duplicadas em nenhum dos dois arquivos. Cada linha já traz a quantidade de óbitos, então não foi preciso agrupar nem fazer amostragem.

## Números em cada etapa

| Etapa | Oficiais: linhas | Oficiais: óbitos | Desconsiderados: linhas | Desconsiderados: óbitos |
|---|---|---|---|---|
| Original (1996–2024) | 48.785 | 48.933 | 42.178 | 42.311 |
| Após recorte 2014–2024 | 18.457 | 18.534 | 12.901 | 12.967 |
| Após tratamento | 18.457 | 18.534 | 10.270 | 10.323 |

Os dois CSVs tratados somam 6,6 MB (4,2 MB + 2,4 MB), contra 21 MB dos dois originais.

## Diferenças em relação à primeira entrega

- Não existe data do óbito, só o ano. A coluna `ano` é inteira.
- Os arquivos não têm nascidos vivos, então a razão de mortalidade materna vai depender do SINASC, que ainda vai entrar no trabalho.

## Banco

PostgreSQL no Aiven, schema `painel`, com duas tabelas (`obitos_maternos_oficiais` e `obitos_desconsiderados`) que seguem as colunas dos CSVs. A carga é feita com `COPY` pelo `src/load.py`.
