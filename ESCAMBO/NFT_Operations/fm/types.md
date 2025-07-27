// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

import { SymbolicInsight } from './SymbolicInsight';
import { SymbolicQuery } from './SymbolicQuery';
import { SymbolicContext } from './SymbolicContext';
import { UserIntentWeights } from '../symbolic-cortex/integration/ICollapseStrategyService';

export type CognitionEvent =
  | { type: 'raw_prompt'; timestamp: string; content: string }
  | { type: 'temporary_context'; timestamp: string; context: string }
  | { type: 'neural_signal'; timestamp: string; core: string; symbolic_query: SymbolicQuery; intensity: number; topK: number; params: Record<string, unknown> }
  | { type: 'symbolic_retrieval'; timestamp: string; core: string; insights: SymbolicInsight[]; matchCount: number; durationMs: number }
  | { type: 'fusion_initiated'; timestamp: string }
  | { type: 'neural_collapse'; timestamp: string; isDeterministic: boolean; selectedCore: string; numCandidates: number; temperature?: number; emotionalWeight: number; contradictionScore: number; justification?: string; userIntent?: UserIntentWeights; insights?: SymbolicInsight[]; emergentProperties?: string[] }
  | { type: 'symbolic_context_synthesized'; timestamp: string; context: SymbolicContext }
  | { type: 'gpt_response'; timestamp: string; response: string; symbolicTopics?: string[]; insights?: SymbolicInsight[] }
  | { type: 'emergent_patterns'; timestamp: string; patterns: string[]; metrics?: { archetypalStability?: number; cycleEntropy?: number; insightDepth?: number } };// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Structure for synthesized symbolic context.
 */
export interface SymbolicContext {
  summary: string;
  [key: string]: string | number | boolean | object | undefined;

}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Structure for symbolic insights extracted from neural signals.
 * Core type definition for symbolic neural processing.
 */
export interface SymbolicInsight {
  type: string;
  content?: string;
  core?: string;
  [key: string]: string | number | boolean | object | undefined;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Structure for symbolic queries associated with neural signals.
 * Adjust as needed.
 */
export interface SymbolicQuery {
  query: string;
  [key: string]: string | number | boolean | object | undefined;

}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// CognitionLogContext.tsx
// Context for managing cognition logs in the application

import React, { createContext, useContext, useEffect, useState } from 'react';
import { CognitionEvent } from './deepgram/types/CognitionEvent';
import symbolicCognitionTimelineLogger from './deepgram/services/utils/SymbolicCognitionTimelineLoggerSingleton';
import { CognitionLogExporter } from './deepgram/services/utils/CognitionLogExporter';
import cognitionLogExporterFactory from './deepgram/services/utils/CognitionLogExporterFactory';

/**
 * Interface for the cognition log context
 */
interface CognitionLogContextType {
  /** Current cognition events */
  events: CognitionEvent[];
  /** Available exporters */
  exporters: CognitionLogExporter[];
  /** Clear all cognition events */
  clearEvents: () => void;
  /** Export events using the specified exporter */
  exportEvents: (exporterLabel: string) => void;
}

/**
 * Context for managing cognition logs in the application
 */
const CognitionLogContext = createContext<CognitionLogContextType | null>(null);

/**
 * Provider for the cognition log context
 */
export const CognitionLogProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [events, setEvents] = useState<CognitionEvent[]>([]);
  const [exporters] = useState<CognitionLogExporter[]>(
    cognitionLogExporterFactory.getExporters()
  );

  // Updates events periodically
  useEffect(() => {
    const updateEvents = () => {
      setEvents([...symbolicCognitionTimelineLogger.getTimeline()]);
    };

    // Initial update
    updateEvents();

    // Update every second
    const interval = setInterval(updateEvents, 1000);
    return () => clearInterval(interval);
  }, []);

  // Clears all events
  const clearEvents = () => {
    symbolicCognitionTimelineLogger.clear();
    setEvents([]);
  };

  // Exports events using the specified exporter
  const exportEvents = (exporterLabel: string) => {
    const exporter = exporters.find(e => e.label === exporterLabel);
    if (exporter) {
      exporter.export(events);
    }
  };

  return (
    <CognitionLogContext.Provider value={{ events, exporters, clearEvents, exportEvents }}>
      {children}
    </CognitionLogContext.Provider>
  );
};

/**
 * Hook to access the cognition log context
 */
export const useCognitionLog = (): CognitionLogContextType => {
  const context = useContext(CognitionLogContext);
  if (!context) {
    throw new Error('useCognitionLog must be used within a CognitionLogProvider');
  }
  return context;
};

export default CognitionLogContext; // SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

import React, { createContext, useState, useEffect } from "react";
import { getOption, setOption, subscribeToStorageChanges, STORAGE_KEYS } from "../../services/StorageService";

/**
 * Hook personalizado para gerenciar configurações do storage
 * Permite um "espelhamento neural" de uma configuração global do storage
 */
function useStorageSetting<T>(key: string, defaultValue: T): [T, (value: T) => void] {
  // Estado local que espelha o valor no storage
  const [value, setValue] = useState<T>(() => {
    const storedValue = getOption<T>(key);
    return storedValue !== undefined ? storedValue : defaultValue;
  });

  // Efeito para sincronizar com mudanças no storage
  useEffect(() => {
    const handleStorageChange = (changedKey: string, newValue: any) => {
      if (changedKey === key && newValue !== undefined) {
        console.log(`💾 [STORAGE-MIRROR] Valor atualizado para ${key}:`, newValue);
        setValue(newValue as T);
      }
    };
    
    // Inscreve para mudanças e retorna função de limpeza
    return subscribeToStorageChanges(handleStorageChange);
  }, [key]);

  // Função para atualizar o valor
  const updateValue = (newValue: T) => {
    setValue(newValue);
    setOption(key, newValue);
  };

  return [value, updateValue];
}

// =====================================
// Contexto de linguagem do Orch-OS
// =====================================

export const LanguageContext = createContext<{  
  language: string;
  setLanguage: (language: string) => void;
}>({ language: "pt-BR", setLanguage: () => {} });

export const LanguageProvider = ({ children }: { children: React.ReactNode }) => {
  // Espelha configurações diretamente do storage neural
  const [language, setLanguageInternal] = useStorageSetting(STORAGE_KEYS.DEEPGRAM_LANGUAGE, "pt-BR");
  
  // Simples wrapper para manter a API consistente
  const setLanguage = (newLanguage: string) => {
    setLanguageInternal(newLanguage);
    console.log(`🌎 LanguageContext: Idioma alterado para ${newLanguage}`);
  };
  
  // O contexto agora é sempre atualizado automaticamente graças ao espelhamento neural

  return (
    <LanguageContext.Provider value={{ language, setLanguage }}>
      {children}
    </LanguageContext.Provider>
  );
};// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// index.ts
// Export organization of all contexts and services

// Interfaces
export * from './deepgram/interfaces/deepgram/IDeepgramContext';
export * from './deepgram/interfaces/deepgram/IDeepgramService';
export * from './interfaces/IAudioContextService';
export * from './interfaces/IAudioDeviceService';
export * from './interfaces/IMicrophoneContext';
export * from './interfaces/IRecorderService';

// Microphone services
export { AudioContextService } from './microphone/AudioContextService';
export { AudioDeviceService } from './microphone/AudioDeviceService';
export { default as MicrophoneProvider, useMicrophone } from './microphone/MicrophoneContextProvider';
export { RecorderService } from './microphone/RecorderService';

// Deepgram services
export { DeepgramAudioAnalyzer } from './deepgram/AudioAnalyzer';
export { DeepgramConnectionService } from './deepgram/DeepgramConnectionService';
export { default as DeepgramProvider, useDeepgram } from './deepgram/DeepgramContextProvider';
export { DeepgramTranscriptionService } from './deepgram/services/DeepgramTranscriptionService';

// Transcription context
export { TranscriptionProvider, useTranscription } from './transcription';

// Enums
export { ConnectionState } from './deepgram/interfaces/deepgram/IDeepgramService';
export { MicrophoneEvents, MicrophoneState } from './interfaces/IMicrophoneContext';
 