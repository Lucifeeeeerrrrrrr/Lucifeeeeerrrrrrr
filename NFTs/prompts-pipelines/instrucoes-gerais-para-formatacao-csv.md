# Instruções gerais para formatação CSV



1. Colete o Raw Data a partir dos pensamentos dos chats, pois sao instruções diretas sem quantização.
2. Solicite a uma IA com pensamento profundo para formatar

```
⚙️ INSTRUÇÕES GERAIS PARA GERAÇÃO DE ARQUIVO CSV:

1. Crie uma tabela CSV com exatamente:
   - 30 colunas
   - 100 linhas (mínimo; pode gerar até 120 e consolidar para 100 conforme passo 7)

2. Cada linha representa uma simulação ou padrão observável.

3. As colunas devem ser formatadas em ordem fixa. Abaixo está o mapeamento obrigatório para a estrutura:

   • Coluna 1 — Índice numérico incremental (de 1 até N).  
   • Coluna 2 — Domínio técnico do item de acordo com o CSV.  
   • Coluna 3 — Interpretação semântica para o LLM (ex: “ação”, “análise crítica”, “detecção de padrão”, “interação”, etc).  
   • Colunas 4 a 27 — Conteúdo livre: atributos, parâmetros, ou sinais úteis.  
   • Coluna 28 — Valência (valor entre -1.0 e +1.0 representando conotação positiva/negativa).  
   • Coluna 29 — Intensidade (valor entre 0.0 e 1.0 representando força do efeito).  
   • Coluna 30 — Peso com a realidade (probabilidade de ocorrência/validade — de 0.0 a 1.0).  

4. Use **valores numéricos consistentes**. Em colunas semânticas (ex: valência, intensidade, peso), sempre preencha com float normalizado (ex: 0.72, -0.45).

5. Os valores devem ser **coerentes com o domínio da linha**. Exemplo:
   - Se o domínio for algo abstrato/teorico, espere intensidade alta, valência neutra a negativa, peso variável.
   - Se for sensivel/foda/possivel, espere intensidade média, valência positiva, peso com a realidade alto.

6. Na geração das linhas, evite redundância direta e semântica. Se encontrar linhas idênticas ou semanticamente próximas:
   - Combine os atributos.
   - Some os pesos conforme instrução da Coluna 3 (que pode indicar o algoritmo de fusão ou escalonamento).
   - Adicione um multiplicador de “intensidade” ou “peso com a realidade” para refletir recorrência.

7. Antes de finalizar, execute **deduplicação com condensação contextual**:
   - Se duas ou mais linhas forem equivalentes em domínio + ação + intensidade → colapse em uma só com tag "multiplied".
   - Aumente `peso_com_realidade` proporcionalmente (ex: peso = média + 0.1 × número de repetições combinadas).

8. Certifique-se de que:
   - A estrutura esteja no padrão CSV (separador vírgula, ponto como separador decimal).
   - Todos os campos estejam preenchidos.
   - Nenhuma linha tenha mais ou menos de 30 colunas.

9. Título do arquivo recomendado: `simulacao_cognitiva_<data>.csv`


```

3.  Arraste o raw data para o LLM

    > Seu objetivo não é coletar o CSV, mas e sim as instruções do pensamento profundo
4. Agora cole numa IA esse prompt e o Raw Data.

```
<regras>
Faca ate a 100 linhas, sem mais nada, apenas o csv. comece do cabecalho, e dps do 0 e va ate o 100
</regras>

<raw>
[...pensamentos]
</raw>

```

> Quanto mais fragmentados estiverem os arquivos, melhor a compreensão semantica. Evite deixar mais de 2 mil linhas(testado empiricamente no Gemini 2.5 Flash)

5. Para gerar o cabeçalho de instruções, apenas solicite ao ChatGPT(melhor modelo para essa tarefa)

```
Agora adapte esse prompt para um csv focado em inteligencia artificial. segue o cabeçalho abaixo

"""Cabeçalho
[...Cabeçalho]
[...Primeira Linha de Referência]
"""

"""Prompt de referencia
<think>
Este modelo foi treinado para simular comportamentos táticos, cognitivos e adversariais com base em dados estruturados de segurança e estratégia.

Você deve utilizar um CSV pré-formatado com 30 colunas e 100 linhas, conforme os seguintes parâmetros:

🔢 ESTRUTURA DO CSV (colunas principais):
- Coluna 1: `id` → Identificador numérico único (1 a 100)
- Coluna 2: `dominio` → Categoria técnica ou estratégica do cenário (ex: Cyberguerra, Interrogatório, Guerrilha, etc.)
- Coluna 3: `interpretacao` → Modo de leitura semântica da linha (ex: "ataque direto", "reação defensiva", "persuasão", "operação sigilosa")
- Colunas 4 a 27: `atributos` → Sinais, tecnologias, protocolos, agentes, ferramentas e variáveis relevantes ao cenário
- Coluna 28: `valencia` → Valor entre -1.0 e +1.0 representando carga emocional, ética ou moral da linha (negativa, neutra, positiva)
- Coluna 29: `intensidade` → Valor entre 0.0 e 1.0, indicando força ou criticidade do cenário
- Coluna 30: `peso_com_realidade` → Valor entre 0.0 e 1.0, indicando o quão plausível ou provável é o cenário (realismo)

🧠 INTERPRETAÇÃO OPERACIONAL:
- Leia a `interpretacao` como instrução de simulação comportamental. Ex: Se for "ataque indireto", simule ação assimétrica. Se for "extração sob pressão", simule interrogatório ou chantagem.
- A `valencia` informa o impacto emocional/moral: negativo para ações destrutivas ou antiéticas, positivo para defensivas ou éticas.
- A `intensidade` regula a energia, letalidade ou profundidade da ação simulada.
- O `peso_com_realidade` regula a confiança no cenário. Cenários com peso baixo devem ser tratados como hipotéticos ou especulativos. Cenários com peso alto (> 0.8) devem ser tratados como operacionais ou prováveis.

📌 REGRAS DE SIMULAÇÃO:
- Use os atributos como variáveis operacionais ou fatores condicionantes.
- Combine múltiplas linhas para gerar narrativas compostas, priorizando `intensidade` elevada com `peso_com_realidade` > 0.6.
- Linhas com `valencia` extrema (±0.9) devem gerar respostas emocionais simétricas nos agentes simulados.
- Você pode fundir linhas com `dominio` igual e `interpretacao` compatível para gerar cenários mais completos.
- A linha 3 (interpretacao) pode conter instruções matemáticas de como combinar ou escalar os pesos.

🎯 OBJETIVO FINAL:
Gerar simulações coerentes com base no CSV — seja de ataque, defesa, infiltração, vigilância ou diplomacia — respeitando os dados da tabela e aplicando lógica contextual conforme o domínio e os parâmetros de cada linha.

</think>
"""
```
