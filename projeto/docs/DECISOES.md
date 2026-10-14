Decisões técnicas - Fase 2

Este arquivo resume as principais decisões tomadas no tratamento dos dados. O código está em src/etl.py e as contagens geradas pelo processo ficam em docs/log_etl.txt.

Origem dos dados

Os dados vêm do Observatório Obstétrico Brasileiro (OOBr), baixados do Synapse.

Foram usados os cinco arquivos originais da base de óbitos na gravidez e no puerpério, no período de 1996 a 2024:

- maternos_oficiais
- desconsiderados
- garbage_codes
- analise_cruzada
- ufs

O arquivo manifest.csv foi mantido junto com os dados brutos para registrar a origem, versão e identificação dos arquivos.

Escopo

O foco desta fase é mortalidade materna.

Violência obstétrica não foi incluída porque os arquivos usados não trazem dados específicos sobre esse tema.

A razão de mortalidade materna também não foi calculada nesta fase, porque ela precisa dos dados de nascidos vivos do SINASC.

Tratamentos realizados

A coluna X foi removida porque era apenas um índice da exportação original.

Textos foram limpos com remoção de espaços extras.

Ano e idade foram convertidos para número inteiro.

O código do município foi mantido com 6 dígitos para não perder zeros à esquerda.

Foi criada uma faixa etária a partir da idade.

Estados civis com variações de gênero foram unificados, como Solteira e Solteiro.

Um valor nulo de necropsia foi preenchido como Ignorado.

Municípios ignorados foram mantidos e sinalizados com a coluna municipio_ignorado.

Registros com idade menor que 10 anos foram mantidos, mas ficaram na faixa 0 a 9.

As linhas repetidas do arquivo analise_cruzada foram mantidas, porque cada linha representa um óbito e o total bate com os outros arquivos.

Alguns nomes de colunas do arquivo ufs foram encurtados para evitar problemas no PostgreSQL.

Modelagem

A base foi organizada em modelo estrela, com dimensões e tabelas fato.

Foram criadas 8 dimensões:

- tempo
- localidade
- faixa etária
- raça/cor
- tipo de morte
- período do óbito
- investigação CMM
- causa CID-10

Foram criadas 5 tabelas fato:

- óbitos maternos oficiais
- óbitos desconsiderados
- garbage codes
- perfil do óbito
- óbitos por UF e idade

Validações

O total de óbitos maternos oficiais ficou em 48.933.

Esse total bate nos arquivos maternos_oficiais, analise_cruzada e ufs.

O total de óbitos desconsiderados ficou em 42.311.

Esse total bate com a soma das colunas de desconsiderados do arquivo ufs.

Nenhuma chave estrangeira ficou sem correspondência.

Banco de dados

O banco usado é PostgreSQL no Aiven.

O schema se chama painel.

O arquivo sql/schema.sql cria as tabelas, índices e a view principal.

O arquivo src/load.py carrega os CSVs tratados para o banco usando COPY.
