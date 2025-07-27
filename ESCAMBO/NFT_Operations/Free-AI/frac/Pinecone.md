# Diagrama Mermaid e Explicação Técnica para Busca Vetorial

## Diagrama Mermaid

```mermaid
flowchart TD
    A[Consulta do Usuário] --> B[Embedding da Consulta]
    B --> C[Busca de Similaridade]
    C --> D[Classificação por Relevância]
    D --> E[Top 5 Resultados]
    
    subgraph "Pipeline de Busca Vetorial"
    B -->|Modelo de Embedding\n1536 dimensões| B
    C -->|Comparação com\n10M+ vetores| C
    D -->|Ordenação O(n log n)| D
    end
    
    style A fill:#f9f,stroke:#333
    style E fill:#bbf,stroke:#f66
```

## Lógica em Linguagem Humana (Passo a Passo)

1. **Transformação em Vetor**:
   - Pegamos sua pergunta e convertemos em um "código matemático" (embedding)
   - Como transformar uma frase em coordenadas num mapa multidimensional
   - Usamos um modelo como OpenAI Embeddings (1536 números representando o significado)

2. **Caça aos Semelhantes**:
   - Comparamos esse código com milhões de outros armazenados
   - Calculamos a "proximidade de significado" para cada um (similaridade cosseno)
   - Como encontrar livros com capas similares em uma biblioteca gigante

3. **Peneira Inteligente**:
   - Ordenamos todos os resultados do mais para o menos relevante
   - Selecionamos apenas os 5 melhores matches
   - Como filtrar milhares de produtos e mostrar só os mais adequados

## Pipeline de IA Explicado

```plaintext
┌───────────────────────┐    ┌───────────────────────┐    ┌───────────────────────┐
│                       │    │                       │    │                       │
│   Transformação       │    │   Busca Exaustiva    │    │   Filtro e           │
│    em Vetor           │    │    Vetorial          │    │   Classificação      │
│   (GPU Accelerated)   │───▶│   (15B+ operações)   │───▶│   (Top-K Selection)  │
│                       │    │                       │    │                       │
└───────────────────────┘    └───────────────────────┘    └───────────────────────┘
          50ms                       2000-3000ms                    10ms
```

## Como Otimizar (Versão Aprimorada)

```python
def optimized_retrieval(query, vector_db):
    # Step 1: Embedding com modelo eficiente (ex: Sentence-Transformers)
    query_vector = embedder.encode(query, device='gpu')  # 384 dimensions
    
    # Step 2: ANN Search (Approximate Nearest Neighbors)
    # Usando FAISS ou HNSW para busca aproximada
    distances, ids = vector_db_index.search(query_vector, k=100)
    
    # Step 3: Re-ranking preciso dos candidatos
    top_candidates = [vector_db[i] for i in ids[0]]
    precise_scores = [cosine_similarity(query_vector, vec) for vec in top_candidates]
    
    return sorted(zip(top_candidates, precise_scores), key=lambda x: -x[1])[:5]
```

### Comparação de Desempenho:

| Métrica          | Approach Original | Approach Otimizado |
|------------------|-------------------|--------------------|
| Tempo GPU        | 50ms              | 15ms               |
| Operações        | 15.36B            | ~1M (ANN)          |
| Latência Total   | 2-3s              | 50-100ms           |
| Precisão         | 100%              | 98-99%             |

## Estratégias de Aceleração

1. **ANN (Approximate Nearest Neighbors)**:
   - Troca a busca exata por uma aproximada inteligente
   - Bibliotecas como FAISS (Facebook), HNSW, ou ScaNN (Google)

2. **Redução de Dimensionalidade**:
   - Usar embeddings menores (384d em vez de 1536d)
   - Mantém 95% da acurácia com 1/4 do tamanho

3. **Pré-filtragem**:
   - Adicionar índice invertido para termos-chave
   - Reduz o espaço de busca antes da comparação vetorial

4. **Hardware**:
   - Usar GPUs modernas (Tensor Cores)
   - Quantização (cálculos em 8-bit em vez de 32-bit)

## Fluxo Recomendado para Produção

```mermaid
graph LR
    A[Query] --> B{Pré-filtro?}
    B -->|Sim| C[Filtro por Metadados]
    B -->|Não| D[Embedding]
    C --> D
    D --> E[Busca ANN]
    E --> F[Re-ranking]
    F --> G[Resultados]
    
    style D fill:#7cf,stroke:#333
    style E fill:#c9c,stroke:#333
```