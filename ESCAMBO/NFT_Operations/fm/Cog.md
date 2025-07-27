// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// Interface for cognitive log exporters
import { CognitionEvent } from '../../types/CognitionEvent';

export interface CognitionLogExporter {
  label: string;
  export(log: CognitionEvent[], filename?: string): void;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// Factory for cognitive log exporters
import { CognitionLogExporter } from './CognitionLogExporter';
import { CognitionLogJsonExporter } from './CognitionLogJsonExporter';
import { CognitionLogTxtExporter } from './CognitionLogTxtExporter';

/**
 * Factory responsible for creating and providing cognitive log exporters
 * Following the Factory Method pattern of SOLID
 */
export class CognitionLogExporterFactory {
  private static instance: CognitionLogExporterFactory;
  private exporters: CognitionLogExporter[] = [];

  private constructor() {
    // Initializes default exporters
    this.registerDefaultExporters();
  }

  /**
   * Gets the unique instance of the factory (Singleton)
   */
  public static getInstance(): CognitionLogExporterFactory {
    if (!CognitionLogExporterFactory.instance) {
      CognitionLogExporterFactory.instance = new CognitionLogExporterFactory();
    }
    return CognitionLogExporterFactory.instance;
  }

  /**
   * Registers default exporters of the system
   */
  private registerDefaultExporters(): void {
    this.exporters = [
      new CognitionLogJsonExporter(),
      new CognitionLogTxtExporter()
    ];
  }

  /**
   * Adds a new exporter to the list
   * @param exporter Exporter to be added
   */
  public registerExporter(exporter: CognitionLogExporter): void {
    this.exporters.push(exporter);
  }

  /**
   * Removes an exporter based on the label
   * @param label Label of the exporter to be removed
   */
  public unregisterExporter(label: string): void {
    this.exporters = this.exporters.filter(e => e.label !== label);
  }

  /**
   * Gets all registered exporters
   */
  public getExporters(): CognitionLogExporter[] {
    return [...this.exporters];
  }
}

// Export a singleton instance of the factory for global use
export default CognitionLogExporterFactory.getInstance();// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// JSON exporter for cognitive log
import { CognitionEvent } from '../../types/CognitionEvent';
import { CognitionLogExporter } from './CognitionLogExporter';

export class CognitionLogJsonExporter implements CognitionLogExporter {
  label = 'Export cognitive log (JSON)';
  export(log: CognitionEvent[], filename = 'symbolic_cognition_session.json') {
    const blob = new Blob([JSON.stringify(log, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// TXT exporter for cognitive log
import { CognitionEvent } from '../../types/CognitionEvent';
import { CognitionLogExporter } from './CognitionLogExporter';

export class CognitionLogTxtExporter implements CognitionLogExporter {
  label = 'Export cognitive log (TXT)';
  export(log: CognitionEvent[], filename = 'symbolic_cognition_session.txt') {
    const txt = log.map(e => JSON.stringify(e, null, 2)).join('\n---\n');
    const blob = new Blob([txt], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Common types and interfaces used across Deepgram service modules
 */
import { ListenLiveClient } from "@deepgram/sdk";
import { ConnectionState } from "../../interfaces/deepgram/IDeepgramService";

/**
 * Speaker segment buffer structure
 */
export interface SpeakerBuffer {
  lastSpeaker: string;
  currentSegment: string[];
  formattedSegment: string;
  lastFlushedText: string;
}

/**
 * Transcription callback data structure
 */
export interface TranscriptionData {
  text: string;
  isFinal: boolean;
  channel: number;
  speaker: string;
}

/**
 * Connection status information
 */
export interface ConnectionStatus {
  state: ConnectionState;
  stateRef: ConnectionState;
  hasConnectionObject: boolean;
  readyState: number | null;
  active: boolean;
}

/**
 * Audio processing result
 */
export interface AudioProcessingResult {
  buffer: ArrayBuffer | null;
  valid: boolean;
}

/**
 * Connection state update callback
 */
export type ConnectionStateCallback = (state: ConnectionState) => void;

/**
 * Connection object update callback
 */
export type ConnectionCallback = (connection: ListenLiveClient | null) => void;

/**
 * Transcription event callback
 */
export type TranscriptionEventCallback = (event: string, data: any) => void;// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Logger utility for Deepgram services
 * Provides consistent logging throughout the Deepgram service modules
 */
export class Logger {
  private context: string;
  
  constructor(context: string) {
    this.context = context;
  }
  
  /**
   * Log informational message
   */
  public info(message: string): void {
    console.log(`✅ [${this.context}] ${message}`);
  }
  
  /**
   * Log debug message with optional data
   */
  public debug(message: string, data?: any): void {
    if (data) {
      console.log(`🔍 [${this.context}] ${message}:`, data);
    } else {
      console.log(`🔍 [${this.context}] ${message}`);
    }
  }
  
  /**
   * Log warning message with optional error
   */
  public warning(message: string, error?: any): void {
    if (error) {
      console.warn(`⚠️ [${this.context}] ${message}:`, error);
    } else {
      console.warn(`⚠️ [${this.context}] ${message}`);
    }
  }
  
  /**
   * Log error message with optional error object
   */
  public error(message: string, error?: any): void {
    if (error) {
      console.error(`❌ [${this.context}] ${message}:`, error);
    } else {
      console.error(`❌ [${this.context}] ${message}`);
    }
  }
  
  /**
   * Handle error with context
   */
  public handleError(context: string, error: any): void {
    console.error(`❌ [${this.context}] ${context}:`, error);
  }
}

export default Logger;// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// SpeakerIdentificationService.ts
// Service responsible for speaker identification and normalization

import { getPrimaryUser } from '../../../../../config/UserConfig';
import { EXTERNAL_SPEAKER_LABEL, SpeakerSegment, SpeakerTranscription } from "../../interfaces/transcription/TranscriptionTypes";
import { ISpeakerIdentificationService } from "../../interfaces/utils/ISpeakerIdentificationService";
import { LoggingUtils } from "../../utils/LoggingUtils";

export class SpeakerIdentificationService implements ISpeakerIdentificationService {
  private primaryUserSpeaker: string = getPrimaryUser();
  private currentSpeaker: string = "";

  constructor(primaryUserSpeaker?: string) {
    if (primaryUserSpeaker) {
      this.primaryUserSpeaker = primaryUserSpeaker;
    }
  }

  /**
   * Sets the name of the primary speaker (user)
   */
  setPrimaryUserSpeaker(name: string): void {
    if (name && name.trim()) {
      this.primaryUserSpeaker = name.trim();
      LoggingUtils.logInfo(`Primary speaker set as: "${this.primaryUserSpeaker}"`);
    }
  }
  
  /**
   * Gets the primary speaker (user)
   */
  getPrimaryUserSpeaker(): string {
    return this.primaryUserSpeaker;
  }

  /**
   * Normalizes the speaker identification for comparison
   * Converts variations like "user", "usuario", etc. to the primaryUserSpeaker
   */
  normalizeAndIdentifySpeaker(speaker: string): string {
    // If the input text is empty, return the primary speaker
    if (!speaker || !speaker.trim()) {
      return this.primaryUserSpeaker;
    }
    
    // Remove brackets if they exist
    const cleanSpeaker = speaker.replace(/^\[|\]$/g, '').trim();
    
    // Simple rule:
    // 1. If it is exactly "Guilherme", return primaryUserSpeaker
    // 2. If it is a pattern "Speaker N", return "external"
    // 3. For other cases, assume primaryUserSpeaker
    
    if (cleanSpeaker === this.primaryUserSpeaker) {
      return this.primaryUserSpeaker;
    }
    
    if (/^speaker\s*\d+$/i.test(cleanSpeaker)) {
      return "external";
    }
    
    // If it is a variation of "user", return primaryUserSpeaker
    if (/^(user|usuario|usuário)$/i.test(cleanSpeaker)) {
      return this.primaryUserSpeaker;
    }
    
    // By default, assume it is the primary user
    return this.primaryUserSpeaker;
  }

  /**
   * Extracts speech segments from a transcription that mixes speakers
   * Example: "[Guilherme] Olá [Speaker 0] Como vai? [Guilherme] Estou bem"
   * → [{ speaker: "Guilherme", text: "Olá" }, { speaker: "Speaker 0", text: "Como vai?" }, ...]
   */
  splitMixedTranscription(text: string): SpeakerSegment[] {
    const segments: SpeakerSegment[] = [];
    
    // Sanitize the input text
    const cleanText = text?.trim() || "";
    if (!cleanText) {
      return segments;
    }
    
    // Regex simplified to capture patterns like [Speaker] text until the next [Speaker]
    // Captures group 1: speaker name between brackets
    // Captures group 2: text spoken until the next speaker or end of the string
    const speakerPattern = /\[([^\]]+)\]\s*(.*?)(?=\s*\[[^\]]+\]|$)/gs;
    
    let match;
    let matchFound = false;
    let lastSpeakerKey = "";
    
    while ((match = speakerPattern.exec(cleanText)) !== null) {
      matchFound = true;
      const rawSpeaker = match[1].trim();
      const spokenText = match[2].trim();
      
      if (spokenText) {
        // Simple rule: If the speaker is "Guilherme", assign to the user
        // If the speaker is "Speaker N", assign as external
        let speakerToUse;
        
        if (rawSpeaker === this.primaryUserSpeaker) {
          speakerToUse = this.primaryUserSpeaker;
        } else if (/^speaker\s*\d+$/i.test(rawSpeaker)) {
          speakerToUse = "external";
        } else {
          // For other cases, use normalization
          speakerToUse = this.normalizeAndIdentifySpeaker(rawSpeaker);
        }
        
        // Show speaker if different from the previous one
        const showSpeaker = (lastSpeakerKey !== speakerToUse);
        lastSpeakerKey = speakerToUse;
        
        LoggingUtils.logInfo(`Segmento [${rawSpeaker}] → ${speakerToUse}: "${spokenText.substring(0, 30)}..."`);
        
        segments.push({
          speaker: speakerToUse,
          text: spokenText,
          showSpeaker: showSpeaker
        });
      }
    }
    
    // If no speaker pattern is found, consider the complete text
    if (!matchFound && cleanText) {
      // Use the current speaker of the service, if available
      const speakerToUse = this.currentSpeaker || this.primaryUserSpeaker;
      
      segments.push({
        speaker: speakerToUse,
        text: cleanText,
        showSpeaker: true // Always show when there is no explicit pattern
      });
      
      LoggingUtils.logInfo(`Text without speaker labels, assigned to: "${speakerToUse}"`);
    }
    
    return segments;
  }

  /**
   * Filters transcriptions by specific speaker
   */
  filterTranscriptionsBySpeaker(speaker: string, transcriptions: SpeakerTranscription[]): SpeakerTranscription[] {
    return transcriptions.filter(
      st => st.speaker === speaker
    );
  }

  /**
   * Filters transcriptions by the primary user,
   * extracting only segments where the user is speaking
   */
  filterTranscriptionsByUser(transcriptions: SpeakerTranscription[]): SpeakerTranscription[] {
    const userTranscriptions = transcriptions.filter(st => {
      // Basic verification: speaker must be the primary user
      if (st.speaker !== this.primaryUserSpeaker) {
        LoggingUtils.logInfo(`[FiltroUser] Rejeitado: speaker diferente do usuário principal (${st.speaker}) - texto: ${st.text.substring(0, 60)}`);
        return false;
      }
      // If the text contains speaker delimiters [...], ensure no external segments are present
      if (st.text.includes('[') && st.text.includes(']')) {
        const segments = this.splitMixedTranscription(st.text);
        if (segments.some(segment => segment.speaker !== this.primaryUserSpeaker)) {
          LoggingUtils.logInfo(`[FiltroUser] Rejeitado: transcrição mista com segmento externo detectado - texto: ${st.text.substring(0, 60)}`);
          return false;
        }
      }
      // If the text starts with an external speaker pattern, it is not from the user
      if (/^speaker\s*\d+\s*:/i.test(st.text)) {
        LoggingUtils.logInfo(`[FiltroUser] Rejeitado: começa como falante externo - texto: ${st.text.substring(0, 60)}`);
        return false;
      }
      // If the text explicitly mentions '[Speaker' at the beginning, log for diagnosis
      if (/^\[Speaker\s*\d+\]/i.test(st.text)) {
        LoggingUtils.logInfo(`[FiltroUser] Rejeitado: possível segmento externo no início - texto: ${st.text.substring(0, 60)}`);
        return false;
      }
      return true;
    });
    
    LoggingUtils.logInfo(`Filtrado ${userTranscriptions.length} transcrições do usuário principal`);
    return userTranscriptions;
  }

  /**
   * Verifies if only the primary user is speaking
   */
  isOnlyUserSpeaking(transcriptions: SpeakerTranscription[]): boolean {
    if (transcriptions.length === 0) {
      return true; // No transcriptions yet, assume only user
    }
    
    // For each transcription, verify if it contains only the user speaking
    for (const transcription of transcriptions) {
      // If the transcription contains speaker markers [Speaker]
      if (transcription.text.includes('[') && transcription.text.includes(']')) {
        const segments = this.splitMixedTranscription(transcription.text);
        
        // If any segment is not from the primary user, it is not just the user speaking
        const hasNonUserSegment = segments.some(segment => 
          this.normalizeAndIdentifySpeaker(segment.speaker) !== this.primaryUserSpeaker
        );
        
        if (hasNonUserSegment) {
          return false;
        }
      } else {
        // If no markers, verify by the speaker field
        if (this.normalizeAndIdentifySpeaker(transcription.speaker) !== this.primaryUserSpeaker) {
          return false;
        }
      }
    }
    
    // If it got here, all transcriptions are from the user
    return true;
  }

  /**
   * Prepares the transcription text for sending, combining all inputs
   */
  prepareTranscriptionText(
    transcriptionList: string[],
    speakerTranscriptions: SpeakerTranscription[],
    lastTranscription: string
  ): string {
    // If we have transcriptions by speaker, use primarily these
    if (speakerTranscriptions.length > 0) {
      // Use a Set to avoid duplicate text
      const processedTexts = new Set<string>();
      
      // First, sort by timestamp to ensure chronological order
      const sortedTranscriptions = [...speakerTranscriptions]
        .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
      
      // Process each transcription, maintaining all speakers in sequence
      const conversationPieces: string[] = [];
      let lastSpeakerKey = "";
      
      for (const st of sortedTranscriptions) {
        // Avoid duplicate text
        if (processedTexts.has(st.text)) continue;
        processedTexts.add(st.text);
        
        // For transcriptions already with [Speaker] format
        if (st.text.includes('[') && st.text.includes(']')) {
          // Divide into segments to preserve multiple speakers within the same sentence
          const speakerPattern = /\[([^\]]+)\]\s*(.*?)(?=\s*\[[^\]]+\]|$)/gs;
          let match;
          let segmentFound = false;
          
          while ((match = speakerPattern.exec(st.text)) !== null) {
            segmentFound = true;
            if (match[1] && match[2]) {
              const rawSpeaker = match[1].trim();
              const spokenText = match[2].trim();
              
              // For each segment, determine if to show the speaker or not
              const speakerKey = /^speaker\s*\d+$/i.test(rawSpeaker) ? 
                `speaker_${rawSpeaker}` : rawSpeaker;
              
              // Show speaker if different from the previous one
              const showSpeaker = (lastSpeakerKey !== speakerKey);
              
              // Format the text appropriately
              if (showSpeaker && spokenText) {
                conversationPieces.push(`[${rawSpeaker}] ${spokenText}`);
              } else if (spokenText) {
                conversationPieces.push(spokenText);
              }
              
              lastSpeakerKey = speakerKey;
            }
          }
          
          // If no segments found, add the text as is
          if (!segmentFound && st.text.trim()) {
            conversationPieces.push(st.text.trim());
          }
        } else {
          // For transcriptions without explicit [Speaker] format
          // Determine the correct speaker
          let speakerLabel: string;
          let speakerKey: string;
          
          if (st.speaker === this.primaryUserSpeaker) {
            speakerLabel = this.primaryUserSpeaker;
            speakerKey = this.primaryUserSpeaker;
          } else {
            // For external speakers, verify if they have a specific number using a more precise regex
            const speakerMatch = st.text.match(/\bspeaker\s*(\d+)\b/i);
            if (speakerMatch && speakerMatch[1]) {
              speakerLabel = `Speaker ${speakerMatch[1]}`;
              speakerKey = `speaker_${speakerMatch[1]}`;
            } else {
              speakerLabel = EXTERNAL_SPEAKER_LABEL;
              speakerKey = "external";
            }
          }
          
          // Show speaker if different from the previous one
          const showSpeaker = (lastSpeakerKey !== speakerKey);
          
          // Format the text appropriately
          if (showSpeaker) {
            conversationPieces.push(`[${speakerLabel}] ${st.text}`);
          } else {
            conversationPieces.push(st.text);
          }
          
          lastSpeakerKey = speakerKey;
        }
      }
      
      return conversationPieces.join("\n");
    }
    
    // Alternative case: use the traditional list
    const validTranscriptions = transcriptionList
      .filter(text => text && text.trim().length > 0);
    
    if (validTranscriptions.length > 0) {
      // Remove duplicates while maintaining order
      const uniqueTranscriptions = [...new Set(validTranscriptions)];
      return uniqueTranscriptions.join(" ").trim();
    }
    
    // Last option: use the last known transcription
    if (lastTranscription && lastTranscription.trim()) {
      return lastTranscription.trim();
    }
    
    return "Please respond based only on the context provided.";
  }
} // SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// SymbolicCognitionTimelineLogger.ts
// Logging structure for symbolic timeline with precise timestamps

import { CognitionEvent } from '../../types/CognitionEvent';
import { SymbolicInsight } from '../../types/SymbolicInsight';
import { SymbolicQuery } from '../../types/SymbolicQuery';
import { SymbolicContext } from '../../types/SymbolicContext';
import { LoggingUtils } from '../../utils/LoggingUtils';
import { UserIntentWeights } from '../../symbolic-cortex/integration/ICollapseStrategyService';

export class SymbolicCognitionTimelineLogger {
  private timeline: CognitionEvent[] = [];

  private now(): string {
    return new Date().toISOString();
  }

  /**
   * Records a raw prompt in the timeline.
   * @param content Textual content of the prompt sent to the system.
   */
  logRawPrompt(content: string): void {
    this.timeline.push({ type: 'raw_prompt', timestamp: this.now(), content });
  }

  /**
   * Records a temporary context in the timeline.
   * @param context Temporary textual context used in processing.
   */
  logTemporaryContext(context: string): void {
    this.timeline.push({ type: 'temporary_context', timestamp: this.now(), context });
  }

  /**
   * Records a neural signal in the timeline, including symbolic query and parameters.
   * @param core Neural signal core (e.g., memory, emotion).
   * @param symbolic_query Symbolic query associated with the signal.
   * @param intensity Signal intensity.
   * @param topK TopK parameter used in search.
   * @param params Additional signal parameters.
   */
  logNeuralSignal(core: string, symbolic_query: SymbolicQuery, intensity: number, topK: number, params: Record<string, unknown>): void {
    this.timeline.push({
      type: 'neural_signal',
      timestamp: this.now(),
      core,
      symbolic_query,
      intensity,
      topK,
      params
    });
  }

  /**
   * Records the result of a symbolic retrieval in the timeline.
   * @param core Core of the associated signal.
   * @param insights Array of extracted symbolic insights.
   * @param matchCount Number of matches found.
   * @param durationMs Search duration in milliseconds.
   */
  logSymbolicRetrieval(core: string, insights: SymbolicInsight[], matchCount: number, durationMs: number): void {
    const safeInsights = Array.isArray(insights) ? insights : [];
    if (!insights || safeInsights.length === 0) {
      LoggingUtils.logInfo(`No insights extracted for core: ${core}`);
    }
    this.timeline.push({
      type: 'symbolic_retrieval',
      timestamp: this.now(),
      core,
      insights: safeInsights,
      matchCount,
      durationMs
    });
  }

  /**
   * Records the initiation of a symbolic fusion process in the timeline.
   */
  logFusionInitiated(): void {
    this.timeline.push({ type: 'fusion_initiated', timestamp: this.now() });
  }

  /**
   * Logs a neural collapse event in the timeline
   * @param isDeterministic Indicates if the collapse was deterministic or probabilistic
   * @param selectedCore Neural core selected for collapse
   * @param numCandidates Number of candidates available before collapse
   * @param emotionalWeight Emotional weight of the result
   * @param contradictionScore Contradiction value of the result
   * @param temperature Symbolic temperature used (only for non-deterministic collapses)
   * @param justification Textual justification for the collapse decision
   * @param userIntent User intent weights inferred from the original text
   * @param insights Symbolic insights associated with the collapse
   * @param emergentProperties Emergent properties detected in the neural response patterns
   */
  logNeuralCollapse(isDeterministic: boolean, selectedCore: string, numCandidates: number, emotionalWeight: number, contradictionScore: number, temperature?: number, justification?: string, userIntent?: UserIntentWeights, insights?: SymbolicInsight[], emergentProperties?: string[]): void {
    this.timeline.push({ 
      type: 'neural_collapse',
      timestamp: this.now(),
      isDeterministic,
      selectedCore,
      numCandidates,
      temperature,
      emotionalWeight,
      contradictionScore,
      justification,
      userIntent,
      insights,
      emergentProperties
    });
  }

  /**
   * Records the synthesized symbolic context in the timeline.
   * @param context Synthesized symbolic context object.
   */
  logSymbolicContextSynthesized(context: SymbolicContext): void {
    this.timeline.push({ type: 'symbolic_context_synthesized', timestamp: this.now(), context });
  }

  /**
   * Records the GPT model response in the timeline, including symbolic topics and insights.
   * @param data Response string or detailed object with topics and insights.
   */
  logGptResponse(data: string | { response: string; symbolicTopics?: string[]; insights?: SymbolicInsight[] }): void {
    if (typeof data === 'string') {
      LoggingUtils.logInfo('No insights extracted in GPT response (string).');
      this.timeline.push({ 
        type: 'gpt_response', 
        timestamp: this.now(), 
        response: data, 
        insights: []
      });
    } else {
      const hasInsights = data.insights && Array.isArray(data.insights) && data.insights.length > 0;
      if (!hasInsights) {
        LoggingUtils.logInfo('No insights extracted in GPT response (object).');
      }
      this.timeline.push({
        type: 'gpt_response',
        timestamp: this.now(),
        response: data.response,
        symbolicTopics: data.symbolicTopics,
        insights: hasInsights ? data.insights : []
      });
    }
  }

  /**
   * Returns the complete timeline of recorded cognitive events.
   */
  getTimeline(): CognitionEvent[] {
    return this.timeline;
  }

  /**
   * Logs detected emergent symbolic patterns.
   * This is part of the Orch-OS scientific introspection layer for tracking
   * emergent cognitive phenomena across processing cycles.
   * 
   * @param patterns Array of emergent symbolic pattern descriptions
   * @param metrics Scientific metrics associated with the patterns
   */
  logEmergentPatterns(patterns: string[], metrics?: { 
    archetypalStability?: number; 
    cycleEntropy?: number; 
    insightDepth?: number 
  }): void {
    this.timeline.push({
      type: 'emergent_patterns',
      timestamp: this.now(),
      patterns,
      metrics
    });
    
    // Log para debugging/monitoramento
    LoggingUtils.logInfo(`[Timeline] Logged ${patterns.length} emergent patterns`);
  }

  clear() {
    this.timeline = [];
  }
}

export default SymbolicCognitionTimelineLogger;// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// SymbolicCognitionTimelineLoggerSingleton.ts
import SymbolicCognitionTimelineLogger from './SymbolicCognitionTimelineLogger';

const symbolicCognitionTimelineLogger = new SymbolicCognitionTimelineLogger();
export default symbolicCognitionTimelineLogger;// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// UIUpdateService.ts
// Service responsible for updating the UI and sending notifications

import { UIUpdater } from "../../interfaces/transcription/TranscriptionTypes";
import { IUIUpdateService } from "../../interfaces/utils/IUIUpdateService";
import { LoggingUtils } from "../../utils/LoggingUtils";

export class UIUpdateService implements IUIUpdateService {
  private setTexts: UIUpdater;
  
  constructor(setTexts: UIUpdater) {
    this.setTexts = setTexts;
  }
  
  /**
   * Updates the UI with new values
   */
  updateUI(update: Record<string, any>): void {
    this.setTexts((prev: any) => ({ ...prev, ...update }));
  }
  
  /**
   * Notifies the start of prompt processing via IPC
   */
  notifyPromptProcessingStarted(temporaryContext?: string): void {
    if (typeof window !== 'undefined' && window.electronAPI) {
      try {
        // 1. Send command to main process via IPC
        if (window.electronAPI.sendNeuralPrompt) {
          window.electronAPI.sendNeuralPrompt(temporaryContext);
          LoggingUtils.logInfo("Prompt sent to main process");
        }
      } catch (e) {
        LoggingUtils.logError("Error sending notifications via IPC", e);
      }
    }
  }
  
  /**
   * Notifies the completion of the prompt via IPC
   */
  notifyPromptComplete(response: string): void {
    if (typeof window !== 'undefined' && window.electronAPI?.sendPromptUpdate) {
      try {
        window.electronAPI.sendPromptUpdate('complete', response);
        LoggingUtils.logInfo("Final response sent via IPC");
      } catch (e) {
        LoggingUtils.logError("Error sending final response via IPC", e);
      }
    }
  }
  
  /**
   * Notifies an error in prompt processing via IPC
   */
  notifyPromptError(errorMessage: string): void {
    if (typeof window !== 'undefined' && window.electronAPI?.sendPromptUpdate) {
      try {
        window.electronAPI.sendPromptUpdate('error', errorMessage);
      } catch (e) {
        LoggingUtils.logError("Error sending error notification via IPC", e);
      }
    }
  }
} // SPDX-License-Identifier: MIT OR Apache-2.0
import { getOption, STORAGE_KEYS } from './../../../../services/StorageService';
// Copyright (c) 2025 Guilherme Ferrari Brescia

// DeepgramTranscriptionService.ts
// Main transcription service for Deepgram that orchestrates other services

import { getPrimaryUser } from '../../../../config/UserConfig';
import { IDeepgramTranscriptionService } from "../interfaces/deepgram/IDeepgramService";
import { IMemoryService } from "../interfaces/memory/IMemoryService";
import { IOpenAIService } from "../interfaces/openai/IOpenAIService";
import { ITranscriptionStorageService } from "../interfaces/transcription/ITranscriptionStorageService";
import { SpeakerTranscription, SpeakerTranscriptionLog, UIUpdater } from "../interfaces/transcription/TranscriptionTypes";
import { ISpeakerIdentificationService } from "../interfaces/utils/ISpeakerIdentificationService";
import { IUIUpdateService } from "../interfaces/utils/IUIUpdateService";
import { DefaultNeuralIntegrationService } from "../symbolic-cortex/integration/DefaultNeuralIntegrationService";
import { INeuralIntegrationService } from "../symbolic-cortex/integration/INeuralIntegrationService";
import { LoggingUtils } from "../utils/LoggingUtils";
import { MemoryService } from "./memory/MemoryService";
import { OpenAIServiceFacade } from "./openai/OpenAIServiceFacade";
import { TranscriptionPromptProcessor } from "./transcription/TranscriptionPromptProcessor";
import { TranscriptionStorageService } from "./transcription/TranscriptionStorageService";
import { SpeakerIdentificationService } from "./utils/SpeakerIdentificationService";
import { UIUpdateService } from "./utils/UIUpdateService";

export class DeepgramTranscriptionService implements IDeepgramTranscriptionService {


  // Essential services
  private speakerService: ISpeakerIdentificationService;
  private storageService: ITranscriptionStorageService;
  private memoryService: IMemoryService;
  private openAIService: IOpenAIService;
  private uiService: IUIUpdateService;

  // Configuration
  private model: string = getOption(STORAGE_KEYS.DEEPGRAM_MODEL) || "nova-2-general";
  private interimResultsEnabled: boolean = true;
  private useSimplifiedHistory: boolean = false;
  private currentLanguage: string = getOption(STORAGE_KEYS.DEEPGRAM_LANGUAGE) || 'pt-BR';

  // Properties for the neural system (kept for backward compatibility)
  private _neuralMemory: Array<{
    timestamp: number;
    core: string;
    intensity: number;
    pattern?: string;
  }> = [];

  /**
   * Returns the current state of prompt processing
   * @returns true if a prompt is currently being processed, false otherwise
   */
  public isProcessingPromptRequest(): boolean {
    return this.transcriptionPromptProcessor.isProcessingPromptRequest();
  }

  // Neural integration service
  private neuralIntegrationService: INeuralIntegrationService;

  // Transcription prompt processor
  private transcriptionPromptProcessor: TranscriptionPromptProcessor;

  constructor(setTexts: UIUpdater, primaryUserSpeaker: string = getPrimaryUser()) {
    // Initialize services
    this.speakerService = new SpeakerIdentificationService(primaryUserSpeaker);
    this.storageService = new TranscriptionStorageService(this.speakerService, setTexts);
    this.openAIService = new OpenAIServiceFacade();
    this.memoryService = new MemoryService(this.openAIService);
    this.uiService = new UIUpdateService(setTexts);

    // Initialize the neural integration service
    this.neuralIntegrationService = new DefaultNeuralIntegrationService(this.openAIService);

    // Initialize the transcription prompt processor
    // Note: HuggingFace service is optional and can be added when available
    this.transcriptionPromptProcessor = new TranscriptionPromptProcessor(
      this.storageService,
      this.memoryService,
      this.openAIService,
      this.uiService,
      this.speakerService,
      this.neuralIntegrationService
      // TODO: Add HuggingFace service when implemented: , this.huggingFaceService
    );

    // Set reference back to this service in the storage service to enable auto-triggering
    if (this.storageService instanceof TranscriptionStorageService) {
      this.storageService.setTranscriptionService(this);
    }

    // Load API key
    this.loadApiKey();
  }

  // Main interface methods

  /**
   * Sets the name of the primary speaker (user)
   */
  setPrimaryUserSpeaker(name: string): void {
    this.speakerService.setPrimaryUserSpeaker(name);
  }

  /**
   * Adds a new transcription received from the Deepgram service
   */
  addTranscription(text: string, speaker?: string): void {
    this.storageService.addTranscription(text, speaker);
  }

  /**
   * Clears transcription data
   */
  clearTranscriptionData(): void {
    this.storageService.clearTranscriptionData();
    this.memoryService.clearMemoryData();
    this.memoryService.resetTranscriptionSnapshot();
  }

  /**
   * Returns the current list of transcriptions
   */
  getTranscriptionList(): string[] {
    return this.storageService.getTranscriptionList();
  }

  /**
   * Returns transcriptions organized by speaker
   */
  getSpeakerTranscriptions(): SpeakerTranscription[] {
    return this.storageService.getSpeakerTranscriptions();
  }

  /**
   * Returns transcription logs grouped by speaker
   */
  getTranscriptionLogs(): SpeakerTranscriptionLog[] {
    return this.storageService.getTranscriptionLogs();
  }

  /**
   * Accesses the internal storage service directly
   * @returns The instance of the storage service
   * @internal Only for internal use
   */
  getStorageServiceForIntegration(): ITranscriptionStorageService {
    return this.storageService;
  }

  /**
   * Verifies if only the primary user speaker is speaking
   */
  isOnlyUserSpeaking(): boolean {
    return this.speakerService.isOnlyUserSpeaking(this.storageService.getSpeakerTranscriptions());
  }

  /**
   * Activates or deactivates the simplified history mode
   */
  setSimplifiedHistoryMode(enabled: boolean): void {
    this.useSimplifiedHistory = enabled;
    this.memoryService.setSimplifiedHistoryMode(enabled);
    LoggingUtils.logInfo(`Simplified history mode: ${enabled ? "activated" : "deactivated"}`);
  }

  /**
   * Sets the processing language for transcription and neural processing
   */
  setProcessingLanguage(language: string): void {
    this.currentLanguage = language;
    this.transcriptionPromptProcessor.setLanguage(language);
    LoggingUtils.logInfo(`Processing language updated to: ${language}`);
  }

  /**
   * Gets the current processing language
   */
  getProcessingLanguage(): string {
    return this.transcriptionPromptProcessor.getCurrentLanguage();
  }



  /**
   * Processes the transcription using OpenAI backend (default behavior)
   * For HuggingFace processing, use sendTranscriptionPromptWithHuggingFace
   */
  async sendTranscriptionPrompt(temporaryContext?: string): Promise<void> {
    return await this.transcriptionPromptProcessor.processWithOpenAI(temporaryContext);
  }

  /**
   * Processes the transcription using HuggingFace backend for enhanced privacy
   */
  async sendTranscriptionPromptWithHuggingFace(temporaryContext?: string): Promise<void> {
    return await this.transcriptionPromptProcessor.processWithHuggingFace(temporaryContext);
  }

  /**
   * Loads the OpenAI API key from the environment
   */
  private async loadApiKey(): Promise<void> {
    await this.openAIService.loadApiKey();
  }

  // Implementation of IDeepgramTranscriptionService methods

  async connect(language?: string): Promise<void> {
    if (language) {
      this.currentLanguage = language;
      this.transcriptionPromptProcessor.setLanguage(language);
    }
    LoggingUtils.logInfo(`Connecting transcription service. Language: ${this.currentLanguage}`);
    return Promise.resolve();
  }

  async disconnect(): Promise<void> {
    LoggingUtils.logInfo("Disconnecting transcription service");
    return Promise.resolve();
  }

  async startProcessing(): Promise<void> {
    LoggingUtils.logInfo("Starting transcription processing");
    return Promise.resolve();
  }

  async stopProcessing(): Promise<void> {
    LoggingUtils.logInfo("Stopping transcription processing");
    return Promise.resolve();
  }

  setModel(model: string): void {
    if (this.model !== model) {
      this.model = model;
      LoggingUtils.logInfo(`Model defined for: ${model}`);
    }
  }

  toggleInterimResults(enabled: boolean): void {
    this.interimResultsEnabled = enabled;
    LoggingUtils.logInfo(`Interim results: ${enabled ? "enabled" : "disabled"}`);
  }

  // ... (rest of the code remains the same)
  reset(): void {
    LoggingUtils.logInfo("Resetting transcription state");
    this.clearTranscriptionData();
    this.transcriptionPromptProcessor.reset();
  }

  isConnected(): boolean {
    return false;
  }

  /**
   * Enable or disable automatic detection of questions for auto-triggering prompts
   */
  setAutoQuestionDetection(enabled: boolean): void {
    if (this.storageService instanceof TranscriptionStorageService) {
      this.storageService.setAutoQuestionDetection(enabled);
      LoggingUtils.logInfo(`Auto-question detection ${enabled ? 'enabled' : 'disabled'}`);
    }
  }
}