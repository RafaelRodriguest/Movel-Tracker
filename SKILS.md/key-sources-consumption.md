# Feat: Seleção de Chaves, Fontes, Consumo e Baterias

## Objetivo

O objetivo é que os técnicos consigam selecionar e gravar, qual o modelo de chave usado em cada contexto( Portão, Gradil 1, Gradil 2), Qual fonte utilizada em cada Gabinete, Campo editavel para inserir o cunsumo de cada fonte e dois campos de seleção para inserir a quantidade de bateria em cada Gabinete.


## Requisitoos

- Eliminar os campos estáticos `padraoChave` e `consumoAtual` e verificar a necessidade criação de uma nova tela para inserir essas informações dessa feature que esta sendo trabalhada aqui.

- Apenas usuários com role `cell_owner` poderão editar. Usuários `geral` continuam visualizando os valores, sem interação.

- Os dados precisam ser persistidos e pesquisados no banco de dados, já que todos os perfis irão conseguir vizualizar as informações que forem sendo editadas.
- Aproveite o que já funciou em termos de implementação do projeto até aqui para implementar as melhores alternativas para cada caso.


## Regras de cada item que será incluido.

### Padrão de Chave (`padrao_chave`)

Criar 03 campos de Dropdown Search Selection( ou outro mais adequado para esse contexto se preferir), para selecionar a informação de chaves:

## chave portão:
selecionar apenas um desse itens e salvar:

- NO CONT A
- MA GDA
- MA GDV
- MA GDB
- MA GMR
- GD SLS V
- GD CHI V
- GD PHE V
- GD BBL V
- GD ITZ V
- MA PCN V
- MULTLOCK
- EBT TETRA

## chave gradil 01:

selecionar apenas um desse itens e salvar:

- NO CONT A
- MA GDA
- MA GDV
- MA GDB
- MA GMR
- GD SLS V
- GD CHI V
- GD PHE V
- GD BBL V
- GD ITZ V
- MA PCN V
- MULTLOCK
- EBT TETRA

## chave gradil 02:

- NO CONT A
- MA GDA
- MA GDV
- MA GDB
- MA GMR
- GD SLS V
- GD CHI V
- GD PHE V
- GD BBL V
- GD ITZ V
- MA PCN V
- MULTLOCK
- EBT TETRA

### Fonte Gabinete (`Fontes`)

Criar 02 campos de Dropdown Search Selection( ou outro mais adequado para esse contexto se preferir), para selecionar a informação da fonte que está sendo utilizada em cada gabinete.

## Fonte 01:
Selecionar apenas um desse itens e salvar:

- ELTEK 2500
- ELTEK FLATPACK 3000
- EMERSON
- VERTIV
- DELTA DPR4000
- DELTA DP2900

## Fonte 02:
Selecionar apenas um desse itens e salvar:

- ELTEK 2500
- ELTEK FLATPACK 3000
- EMERSON
- VERTIV
- DELTA DPR4000
- DELTA DP2900


### Consumo de cada fonte (`Consumo`)

Criar 02 campos para inserir as informações de corrente de consumo em Amperes (A), já deixe o A fixo.

Consumo fonte 01:___________ A
Consumo fonte 02:___________ A


### Quantidade de baterias (`Quantidade de baterias`)

Criar 02 campos de Dropdown Search Selection( ou outro mais adequado para esse contexto se preferir), para selecionar a informação da quantidade de baterias.

- Quantidade de baterias Fonte 01: escolher de 01 a 09;
- Quantidade de baterias Fonte 01: escolher de 01 a 09;













