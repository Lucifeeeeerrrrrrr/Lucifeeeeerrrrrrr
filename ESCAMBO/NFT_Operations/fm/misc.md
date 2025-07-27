// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// INeuralSignalService.ts
// Symbolic: Contract for neural signal extraction cortex
import { NeuralSignalResponse } from '../../../components/context/deepgram/interfaces/neural/NeuralSignalTypes';

export interface INeuralSignalService {
  generateNeuralSignal(
    prompt: string,
    temporaryContext?: string,
    language?: string
  ): Promise<NeuralSignalResponse>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// ISemanticEnricher.ts
// Symbolic: Contract for semantic enrichment cortex

export interface ISemanticEnricher {
  enrichSemanticQueryForSignal(
    core: string,
    query: string,
    intensity: number,
    context?: string,
    language?: string
  ): Promise<{ enrichedQuery: string; keywords: string[] }>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Orch-OS Neural-Symbolic Interface Specification
 * 
 * SimpleModule - Interface para módulos de UI colapsáveis/expansíveis.
 * Intenção simbólica: Representa um córtex neuralmente adaptável que pode
 * expandir ou colapsar para otimizar a densidade cognitiva da interface.
 */

import { ReactNode } from 'react';

export interface SimpleModuleProps {
  /** Título do módulo cortical */
  title: string;
  
  /** Define se o módulo inicia em estado expandido */
  defaultOpen?: boolean;
  
  /** Conteúdo neural do módulo */
  children: ReactNode;
  
  /** Usado apenas para debugging visual - não para produção */
  debugBorder?: boolean;
}

export interface SimpleModuleState {
  /** Estado atual (expandido/colapsado) */
  isExpanded: boolean;
  
  /** Função para alternar entre estados */
  toggle: () => void;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// onnxruntimeConfig.ts
// Symbolic cortex: Global ONNX Runtime configuration for Orch-OS
// Optimizes neural execution providers and suppresses unnecessary warnings

/**
 * Global ONNX Runtime configuration to optimize performance and reduce warnings
 * Symbolic: Neural execution environment optimization for browser compatibility
 */
export class OnnxRuntimeConfig {
  
  /**
   * Initialize global ONNX Runtime environment settings
   * This should be called once at application startup before any model loading
   */
  static initializeGlobalOnnxSettings(): void {
    // Suppress ONNX Runtime console warnings globally if possible
    try {
      // Try to configure global ONNX environment if available
      if (typeof window !== 'undefined' && (window as any).ort) {
        const ort = (window as any).ort;
        
        // Configure global ONNX Runtime settings
        if (ort.env) {
          // Set global log level to suppress warnings
          ort.env.logLevel = 'error'; // Only show errors, suppress warnings
          ort.env.debug = false; // Disable debug output
        }
      }
      
      // Set environment variables for ONNX Runtime behavior in Electron/Node
      if (typeof process !== 'undefined' && process.env) {
        // Suppress ONNX Runtime warnings via environment variables
        process.env.ORT_LOGGING_LEVEL = '3'; // Error level only
        process.env.ORT_ENABLE_VERBOSE_LOGGING = '0'; // Disable verbose logging
        process.env.ORT_DISABLE_ALL_LOGS = '0'; // Keep error logs only
      }
      
      console.log('[ONNX-CONFIG] ✅ Global ONNX Runtime optimization settings applied');
    } catch (error) {
      console.warn('[ONNX-CONFIG] ⚠️ Could not apply global ONNX settings:', error);
    }
  }
  
  /**
   * Get optimized session options for ONNX Runtime
   * Based on official ONNX Runtime documentation and community best practices
   * @see https://onnxruntime.ai/docs/performance/transformers-optimization.html
   */
  static getOptimizedSessionOptions(device: 'cpu' | 'webgpu' | 'wasm' = 'wasm'): any {
    return {
      // ✅ RECOMMENDED: Specify execution providers in order of preference
      executionProviders: device === 'webgpu' 
        ? ['webgpu', 'wasm'] 
        : device === 'cpu'
        ? ['cpu']
        : ['wasm'],
        
      // ✅ RECOMMENDED: Control logging level (production setting)
      logSeverityLevel: 2, // Show warnings and errors (0=Verbose, 1=Info, 2=Warning, 3=Error, 4=Fatal)
      logVerbosityLevel: 0, // Minimize verbosity but don't completely silence
      
      // ✅ RECOMMENDED: Optimizations that are safe for browser environments
      graphOptimizationLevel: 'basic', // Use basic optimizations (recommended for production)
      enableProfiling: false, // Disable profiling for production performance
      
      // ⚠️ CONDITIONAL: Browser-specific settings (only disable if causing issues)
      ...(typeof window !== 'undefined' && {
        // These are only disabled if running in browser and causing compatibility issues
        enableCpuMemArena: true,  // Keep enabled unless it causes issues
        enableMemPattern: true,   // Keep enabled for better performance
      }),
      
      // ✅ RECOMMENDED: Thread management for browser compatibility
      ...(device === 'wasm' && {
        interOpNumThreads: 1,     // Single thread for WASM compatibility
        intraOpNumThreads: 1,     // Single thread for WASM compatibility
      }),
      
      // ✅ RECOMMENDED: CPU-specific optimizations for Node.js/Electron
      ...(device === 'cpu' && {
        interOpNumThreads: 0,     // Use all available cores
        intraOpNumThreads: 0,     // Use all available cores
      }),
    };
  }
  
  /**
   * ⚠️ OPTIONAL: Suppress specific harmless ONNX Runtime warnings
   * WARNING: Use this only for known harmless warnings that clutter the console
   * @see https://onnxruntime.ai/docs/performance/transformers-optimization.html
   */
  static suppressHarmlessOnnxWarnings(): void {
    if (typeof console !== 'undefined') {
      const originalWarn = console.warn;
      const originalError = console.error;
      
      // Function to check if message is a known harmless ONNX warning
      const isHarmlessOnnxWarning = (message: string): boolean => {
        return (
          message.includes('[W:onnxruntime:, session_state.cc:1280 VerifyEachNodeIsAssignedToAnEp] Some nodes were not assigned to the preferred execution providers') ||
          message.includes('[W:onnxruntime:, session_state.cc:1282 VerifyEachNodeIsAssignedToAnEp] Rerunning with verbose output') ||
          // Specific ONNX Runtime informational messages that are expected in browser
          (message.includes('VerifyEachNodeIsAssignedToAnEp') && message.includes('Some nodes were not assigned')) ||
          (message.includes('ORT explicitly assigns shape related ops to CPU to improve perf'))
        );
      };
      
      // Intercept console.warn for ONNX warnings
      console.warn = function(...args: any[]) {
        const message = args.join(' ');
        
        if (isHarmlessOnnxWarning(message)) {
          // These warnings are expected and harmless - ONNX Runtime is working correctly
          return;
        }
        
        // Keep ALL other warnings - important for debugging
        originalWarn.apply(console, args);
      };
      
      // Intercept console.error for ONNX warnings (since ONNX Runtime uses console.error for some warnings)
      console.error = function(...args: any[]) {
        const message = args.join(' ');
        
        if (isHarmlessOnnxWarning(message)) {
          // These warnings are expected and harmless - ONNX Runtime is working correctly
          return;
        }
        
        // Keep ALL other errors - critical for debugging
        originalError.apply(console, args);
      };
      
      console.log('[ONNX-CONFIG] 🔇 Suppressing known harmless ONNX Runtime warnings');
    }
  }
  
  /**
   * Restore original console methods
   * Call this if you need to restore normal console behavior
   */
  static restoreConsole(): void {
    // This would require storing references to original methods
    // For now, reload the page to restore console
    console.log('[ONNX-CONFIG] 📢 To restore full console logging, reload the page');
  }
}

/**
 * Auto-initialize ONNX Runtime configuration when this module is imported
 */
if (typeof window !== 'undefined') {
  // Initialize on browser load
  window.addEventListener('load', () => {
    OnnxRuntimeConfig.initializeGlobalOnnxSettings();
    OnnxRuntimeConfig.suppressHarmlessOnnxWarnings();
  });
} else {
  // Initialize immediately in Node.js environments
  OnnxRuntimeConfig.initializeGlobalOnnxSettings();
} // SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// NeuralSignalTypes.ts
// Interface for neural signal types generated by the language model

import { SymbolicQuery } from '../../types/SymbolicQuery';

/**
 * Represents a symbolic neural signal for the artificial brain model
 * Each signal describes a cognitive core to be activated, its intensity, and the symbolic search target
 */
export interface NeuralSignal {
  /**
   * Cognitive core to be activated
   * - memory: Memory and associative recall (hipocampus)
   * - valence: Emotional polarity and affective intensity (amygdala)
   * - metacognitive: Introspection and reflection (prefrontal cortex)
   * - associative: Associative connections between concepts (association cortex)
   * - language: Language processing (Broca and Wernicke areas)
   * - planning: Planning and strategy (dorsolateral cortex)
   */
  core: string;
  
  /**
   * Intensity of activation of this core (0.0 to 1.0)
   */
  intensity: number;
  
  /**
   * Symbolic query for the cognitive core (what to search for)
   * Can contain the main query and additional metadata
   */
  symbolic_query: SymbolicQuery;

  /**
   * Quantity of memories to be retrieved by the core
   */
  topK?: number;

  /**
   * Pinecone search results for this core
   */
  pineconeResults?: string[];

  /**
   * Symbolic insights pre-analyzed (e.g. "emotion": "anxiety")
   */
  symbolicInsights?: Record<string, unknown>;

  /**
   * Expanded keywords for semantic search
   */
  keywords?: string[];

  /**
   * Additional parameters for neural signal processing
   */
  params?: Record<string, unknown>;

  /**
   * Contextual filters for search
   */
  filters?: Record<string, unknown>;

  /**
   * Indicates if semantic expansion should be applied
   */
  expand?: boolean;
  
  /**
   * Emotional valence of the neural signal
   */
  valence?: string;
  
  /**
   * Score indicating the level of contradiction in the signal (0.0 to 1.0)
   */
  contradictionScore?: number;
  
  /**
   * Score indicating the coherence of the signal (0.0 to 1.0)
   */
  coherence?: number;
  
  /**
   * Patterns detected in the neural signal
   */
  patterns?: string[];
}

/**
 * Response returned by the neural signal generation service
 */
export interface NeuralSignalResponse {
  /**
   * Array of neural signals generated representing the activation of cognitive cores
   */
  signals: NeuralSignal[];
  
  /**
   * High-level analysis of generated signals and symbolic cognitive state
   */
  analysis?: string;
}

/**
 * Represents the result of processing a neural core after memory search
 * and synthesis of relevant information.
 * Used in the neural integration phase.
 */
export interface NeuralProcessingResult {
  /**
   * Núcleo cognitivo that was activated (e.g. 'memory', 'valence')
   */
  core: string;
  
  /**
   * Intensity of activation of this core (0.0 to 1.0)
   */
  intensity: number;
  
  /**
   * Consolidated textual output of this core processing
   */
  output: string;
  
  /**
   * Symbolic insights extracted and structured
   */
  insights: Record<string, unknown>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// ICompletionService.ts
// Symbolic: Neural pathway for language model completions and function executions

/**
 * Interface que define o retorno de uma resposta de streaming do modelo
 */
export interface ModelStreamResponse {
  responseText: string;
  messageId: string;
  isComplete: boolean;
  isDone: boolean;
}

/**
 * Interface para o serviço de completions com ou sem function calling
 * Symbolic: Representa o córtex de geração de texto e execução de funções simbólicas
 */
export interface ICompletionService {
  /**
   * Envia uma requisição ao modelo de linguagem com suporte a function calling
   * @param options Opções da requisição incluindo modelo, mensagens, ferramentas, etc.
   * @returns Resposta completa após o processamento
   */
  callModelWithFunctions(options: {
    model: string;
    messages: Array<{role: string; content: string}>;
    tools?: Array<{
      type: string;
      function: {
        name: string;
        description: string;
        parameters: Record<string, unknown>;
      }
    }>;
    tool_choice?: {type: string; function: {name: string}};
    temperature?: number;
    max_tokens?: number;
  }): Promise<{
    choices: Array<{
      message: {
        content?: string;
        tool_calls?: Array<{
          function: {
            name: string;
            arguments: string;
          }
        }>
      }
    }>
  }>;

  /**
   * Envia requisição para o modelo e processa o stream de resposta
   * Symbolic: Fluxo neural contínuo de processamento de linguagem
   */
  streamModelResponse(messages: Array<{role: string; content: string}>): Promise<ModelStreamResponse>;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// INeuralSignalService.ts
// Symbolic: Neural interface for symbolic signal generation and processing

import { NeuralSignalResponse } from "../neural/NeuralSignalTypes";

/**
 * Interface para o serviço de geração de sinais neurais simbólicos
 * Symbolic: Representa o córtex de geração e processamento de sinais neurais
 */
export interface INeuralSignalService {
  /**
   * Gera sinais neurais simbólicos baseados em um prompt para ativação do cérebro artificial
   * @param prompt O prompt estruturado para gerar sinais neurais (estímulo sensorial)
   * @param temporaryContext Contexto temporário opcional (campo contextual efêmero)
   * @returns Resposta contendo array de sinais neurais para ativação das áreas cerebrais
   */
  generateNeuralSignal(prompt: string, temporaryContext?: string, language?: string): Promise<NeuralSignalResponse>;

  /**
   * Expande semanticamente a query de um núcleo cerebral, retornando uma versão enriquecida, 
   * palavras-chave e dicas de contexto.
   * Symbolic: Expansão de campo semântico para ativação cortical
   */
  enrichSemanticQueryForSignal(
    core: string, 
    query: string, 
    intensity: number, 
    context?: string, 
    language?: string
  ): Promise<{ enrichedQuery: string, keywords: string[] }>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// IOpenAIService.ts
// Interface para o serviço de comunicação com a API OpenAI

import { NeuralSignalResponse } from "../neural/NeuralSignalTypes";
import { AIResponseMeta, Message } from "../transcription/TranscriptionTypes";

export interface IOpenAIService {
  /**
   * Inicializa o cliente OpenAI
   */
  initializeOpenAI(apiKey: string): void;
  
  /**
   * Carrega a chave da API do OpenAI do ambiente
   */
  loadApiKey(): Promise<void>;
  
  /**
   * Garante que o cliente OpenAI está disponível
   */
  ensureOpenAIClient(): Promise<boolean>;
  
  /**
   * Envia requisição para OpenAI e processa o stream de resposta
   */
  streamOpenAIResponse(messages: Message[]): Promise<AIResponseMeta>;
  
  /**
   * Cria embeddings para o texto fornecido
   * @param text Texto para gerar embedding
   * @param model Modelo de embedding a ser usado (opcional)
   */
  createEmbedding(text: string, model?: string): Promise<number[]>;
  
  /**
   * Cria embeddings para um lote de textos (processamento em batch)
   * @param texts Array de textos para gerar embeddings
   * @param model Modelo de embedding a ser usado (opcional)
   * @returns Array de arrays de numbers representando os embeddings
   */
  createEmbeddings?(texts: string[], model?: string): Promise<number[][]>;
  
  /**
   * Verifica se o cliente OpenAI está inicializado
   */
  isInitialized(): boolean;
  
  /**
   * Gera sinais neurais simbólicos baseados em um prompt para ativação do cérebro artificial
   * @param prompt O prompt estruturado para gerar sinais neurais (estímulo sensorial)
   * @param temporaryContext Contexto temporário opcional (campo contextual efêmero)
   * @returns Resposta contendo array de sinais neurais para ativação das áreas cerebrais
   */
  generateNeuralSignal(prompt: string, temporaryContext?: string, language?: string): Promise<NeuralSignalResponse>;

  /**
   * Expande semanticamente a query de um núcleo cerebral, retornando uma versão enriquecida, palavras-chave e dicas de contexto.
   */
  enrichSemanticQueryForSignal(core: string, query: string, intensity: number, context?: string, language?: string): Promise<{ enrichedQuery: string, keywords: string[] }>;
  
  /**
   * Envia uma requisição ao OpenAI com suporte a function calling
   * @param options Opções da requisição incluindo modelo, mensagens, ferramentas, etc.
   * @returns Resposta completa após o processamento
   */
  callOpenAIWithFunctions(options: {
    model: string;
    messages: Array<{role: string; content: string}>;
    tools?: Array<{
      type: string;
      function: {
        name: string;
        description: string;
        parameters: Record<string, unknown>;
      }
    }>;
    tool_choice?: {type: string; function: {name: string}};
    temperature?: number;
    max_tokens?: number;
  }): Promise<{
    choices: Array<{
      message: {
        content?: string;
        tool_calls?: Array<{
          function: {
            name: string;
            arguments: string;
          }
        }>
      }
    }>
  }>;
} 