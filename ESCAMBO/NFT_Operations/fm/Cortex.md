// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// NeuralSignalExtractor.ts
// Module responsible for extracting symbolic neural signals from the transcription context

import { NeuralSignalResponse } from "../../interfaces/neural/NeuralSignalTypes";
import { IOpenAIService } from "../../interfaces/openai/IOpenAIService";
import { LoggingUtils } from "../../utils/LoggingUtils";
import { INeuralSignalExtractor, NeuralExtractionConfig } from "../interfaces/INeuralSignalExtractor";

/**
 * Class responsible for extracting symbolic neural signals from the transcription context
 * This is the first impulse of an artificial symbolic mind
 */
export class NeuralSignalExtractor implements INeuralSignalExtractor {
  private readonly openAIService: IOpenAIService;

  /**
   * Constructor
   * @param openAIService OpenAI service for communication with the language model
   */
  constructor(openAIService: IOpenAIService) {
    this.openAIService = openAIService;
  }

  /**
   * Extracts symbolic neural signals from the current context
   * This is the first impulse of an artificial symbolic mind
   * @param config Configuration containing the current context
   * @returns Array of neural signals representing the activation of the symbolic brain
   */
  public async extractNeuralSignals(config: NeuralExtractionConfig): Promise<NeuralSignalResponse> {
    try {
      // The config should already have transcription and userContextData ready!
      const { transcription, temporaryContext, userContextData = {}, sessionState = {} } = config;

      // Determine language from session state
      const language = (sessionState && typeof sessionState === 'object' && 'language' in sessionState) ?
        sessionState.language as string : undefined;

      LoggingUtils.logInfo("Extracting neural signals with complete user context...");

      // Prepare an enriched prompt with all available contextual data
      const enrichedPrompt = this.prepareEnrichedPrompt(transcription, userContextData);

      // Generate neural signals adapted for Pinecone queries
      const neuralResponse = await this.openAIService.generateNeuralSignal(
        enrichedPrompt, // Enriched stimulus with user context
        temporaryContext,
        language // Pass language from session state
      );

      // Verify if the response contains valid signals
      if (!neuralResponse.signals || neuralResponse.signals.length === 0) {
        LoggingUtils.logWarning("No neural signals were generated. Using default signals.");

        // Provide default neural signals to ensure important Pinecone queries
        return {
          signals: [
            {
              core: "memory",
              intensity: 0.8,
              symbolic_query: {
                query: `memories related to: ${transcription.substring(0, 100)}`
              },
              symbolicInsights: {
                recall_type: "semantic",
                temporal: "recent",
                importance: "high"
              }
            },
            {
              core: "metacognitive",
              intensity: 0.7,
              symbolic_query: {
                query: `reflection on: ${transcription.substring(0, 100)}`
              },
              symbolicInsights: {
                thought: "Processing cognitive stimulus",
                state: "conscious"
              }
            },
            {
              core: "valence",
              intensity: 0.6,
              symbolic_query: {
                query: `emotions about: ${transcription.substring(0, 100)}`
              },
              symbolicInsights: {
                emotion: "neutral",
                intensity: "moderate"
              }
            }
          ]
        };
      }

      // Improve neural signals for effective Pinecone queries
      const enhancedSignals = neuralResponse.signals.map(signal => {
        // DO NOT overwrite or modify the model's symbolic query
        // DO NOT add prefixes like "memories relevant to: ..."

        // DO NOT overwrite topK if already provided
        if (signal.topK === undefined) {
          signal.topK = signal.core === 'memory' ? 5 :
            signal.core === 'valence' ? 3 : 2;
        }
        return signal;
      });

      // Update the signals in the neural response
      neuralResponse.signals = enhancedSignals;

      // Log the generated signals for diagnostic purposes
      LoggingUtils.logInfo(` ${neuralResponse.signals.length} neural signals extracted and optimized for Pinecone`);

      // Processamento de metadados de contexto removido (KISS/YAGNI)

      // Return the optimized neural response
      return neuralResponse;

    } catch (error) {
      // In case of error, log and provide a fallback response
      LoggingUtils.logError("Error extracting neural signals", error as Error);

      return {
        signals: [{
          core: "memory",
          intensity: 0.5,
          symbolic_query: {
            query: config.transcription.substring(0, 50)
          },
          symbolicInsights: {}
        }]
      };
    }
  }

  /**
 * Prepares an enriched prompt with full user context.
 * @param originalPrompt The user's original prompt
 * @param userContextData Contextual data related to the user
 * @returns A contextually enriched symbolic/psychoanalytic prompt
 */
  private prepareEnrichedPrompt(
    originalPrompt: string,
    userContextData: Record<string, unknown>
  ): string {
    const styleInstruction = "STYLE INSTRUCTION: Only use greetings and personal references when the user's content clearly justifies it — never automatically.";

    // Base symbolic instruction with enhanced quantum and multi-level consciousness dimensions
    const symbolicInstruction = `INSTRUCTION: Analyze the user's message and context in a quantum-symbolic framework to identify:

1. EXPLICIT AND IMPLICIT ELEMENTS:
   - Keywords, emotional themes, symbols, archetypes, dilemmas, and unconscious patterns
   - Potential quantum states of meaning in superposition (multiple interpretations coexisting)
   - Signs of instructional collapse (where multiple potential meanings converge)

2. MULTI-LEVEL CONSCIOUSNESS:
   - Surface level: Immediate conscious content and stated intentions
   - Intermediate level: Partially conscious patterns, emotional undercurrents
   - Deep level: Unconscious material, potential symbolic resonance, dormant insights

3. ARCHETYPAL RESONANCE AND INTERPLAY:
   - Primary archetypes activated in the communication
   - Secondary/shadow archetypes operating in tension or harmony with primary ones
   - Potential dialogue or conflict between different archetypal energies

4. TEMPORAL DIMENSIONS:
   - Past: Echoes, patterns, and unresolved elements influencing present communication
   - Present: Immediate symbolic significance of current expression
   - Future: Potential trajectories, symbolic seeds, emergent possibilities

5. POLARITIES AND PARADOXES:
   - Tensions between opposing symbolic forces
   - Potential integration points for apparently contradictory elements
   - Productive tensions that could lead to emergent understanding

Suggest refined or expanded keywords, queries, and topics that could deepen the symbolic, emotional, and unconscious investigation — even if they are not explicitly verbalized.

Be selective: only expand when there are strong indicators of symbolic or unconscious material.

Prioritize expressions and themes that reveal tensions, paradoxes, hidden desires, blockages, or deep self-knowledge potential that exist in quantum superposition awaiting conscious observation.`;

    // If no user context exists, return the basic symbolic enrichment prompt
    if (Object.keys(userContextData).length === 0) {
      return `${styleInstruction}\n\n${originalPrompt}\n\n${symbolicInstruction}`;
    }

    // Start building contextualized prompt
    let contextualPrompt = `${styleInstruction}\n\n${originalPrompt}`;

    // Add recent symbolic or emotional topics, if present
    if (userContextData.recent_topics) {
      const recentTopics = userContextData.recent_topics.toString().substring(0, 200) + '...';
      contextualPrompt += `\n\nRecent topics context: ${recentTopics}`;
    }

    // Add interaction patterns if present
    if (userContextData.speaker_interaction_counts) {
      const interactionPattern = JSON.stringify(userContextData.speaker_interaction_counts);
      contextualPrompt += `\n\nInteraction pattern: ${interactionPattern}`;
    }

    // Add symbolic instruction + adaptive note
    contextualPrompt += `\n\n${symbolicInstruction}

Note: If other relevant symbolic or emotional patterns are available in the long-term memory or historical user data, feel free to incorporate them into the keyword/query suggestions — as long as they resonate symbolically with the current stimulus.`;

    return contextualPrompt;
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

import { IOpenAIService } from '../../interfaces/openai/IOpenAIService';
import { OpenAIEmbeddingService } from '../../services/openai/OpenAIEmbeddingService';
import symbolicCognitionTimelineLogger from '../../services/utils/SymbolicCognitionTimelineLoggerSingleton';
import { SymbolicInsight } from '../../types/SymbolicInsight';
import { ICollapseStrategyService } from './ICollapseStrategyService';
import { INeuralIntegrationService } from './INeuralIntegrationService';
import { OpenAICollapseStrategyService } from './OpenAICollapseStrategyService';
import { SuperpositionLayer } from './SuperpositionLayer';
import { SymbolicPatternAnalyzer, CognitiveMetrics } from '../patterns/SymbolicPatternAnalyzer';
import { LoggingUtils } from '../../utils/LoggingUtils';
import { getOption, STORAGE_KEYS } from '../../../../../services/StorageService';

function asNumber(val: unknown, fallback: number): number {
  return typeof val === 'number' ? val : fallback;
}

export class DefaultNeuralIntegrationService implements INeuralIntegrationService {
  private embeddingService: OpenAIEmbeddingService;
  private collapseStrategyService: ICollapseStrategyService;
  private patternAnalyzer: SymbolicPatternAnalyzer; // Detector de padrões simbólicos emergentes entre ciclos

  constructor(private openAIService: IOpenAIService) {
    this.embeddingService = new OpenAIEmbeddingService(openAIService);
    this.collapseStrategyService = new OpenAICollapseStrategyService(openAIService);
    this.patternAnalyzer = new SymbolicPatternAnalyzer();
  }
  
  /**
   * Calculates a symbolic phase value based on emotional weight, contradiction score, and coherence
   * Returns a value between 0-2π that represents a phase angle for wave interference
   */
  private calculateSymbolicPhase(emotionalWeight: number, contradictionScore: number, coherence: number): number {
    const baseEmotionPhase = emotionalWeight * Math.PI / 2; // Emotions dominate initial phase
    const contradictionPhase = contradictionScore * Math.PI; // Contradictions generate opposition
    const coherenceNoise = (1 - coherence) * (Math.PI / 4); // Low coherence → noise

    // Total phase with 2π wrapping
    const phase = (baseEmotionPhase + contradictionPhase + coherenceNoise) % (2 * Math.PI);
    
    // Ensure phase is positive (0 to 2π range)
    const normalizedPhase = phase < 0 ? phase + 2 * Math.PI : phase;
    
    console.info(`[NeuralIntegration] Calculated symbolic phase: ${normalizedPhase.toFixed(3)} rad (emotionPhase=${baseEmotionPhase.toFixed(2)}, contradictionPhase=${contradictionPhase.toFixed(2)}, coherenceNoise=${coherenceNoise.toFixed(2)})`);
    
    return normalizedPhase;
  }

  /**
   * Neural integration using superposition, non-deterministic collapse and emergent property registration.
   * Now uses real embeddings for each answer via OpenAIEmbeddingService.
   */
  async integrate(
    neuralResults: Array<{
      core: string;
      intensity: number;
      output: string;
      insights: Record<string, unknown>;
    }>,
    originalInput: string,
    language: string = getOption(STORAGE_KEYS.DEEPGRAM_LANGUAGE) || 'pt-BR' // Default to pt-BR if not provided
  ): Promise<string> {
    if (!neuralResults || neuralResults.length === 0) {
      return originalInput;
    }
    // 1. Superposition: each result is a possible answer
    const superposition = new SuperpositionLayer();
    for (const result of neuralResults) {
      // Generate real embedding for the answer text
      const embedding = await this.embeddingService.createEmbedding(result.output);
      // Heuristics for emotional weight, coherence and contradiction
      const emotionalWeight = asNumber((result.insights as Record<string, unknown>)?.valence, Math.random());
      const narrativeCoherence = asNumber((result.insights as Record<string, unknown>)?.coherence, 1 - Math.abs(result.intensity - 0.5));
      const contradictionScore = asNumber((result.insights as Record<string, unknown>)?.contradiction, Math.random() * 0.5);
      superposition.register({
        embedding,
        text: result.output,
        emotionalWeight,
        narrativeCoherence,
        contradictionScore,
        origin: result.core,
        insights: result.insights
      });
    }
    // 2. Collapse: Use OpenAI-based strategy to decide deterministic vs probabilistic
    const numCandidates = superposition.answers.length;
    
    // Calculate average values for symbolic properties
    const averageEmotionalWeight = neuralResults.reduce((sum, r) => {
      return sum + asNumber((r.insights as Record<string, unknown>)?.valence, 0.5);
    }, 0) / neuralResults.length;
    const averageContradictionScore = neuralResults.reduce((sum, r) => {
      return sum + asNumber((r.insights as Record<string, unknown>)?.contradiction, 0.25);
    }, 0) / neuralResults.length;
    const avgCoherence = neuralResults.reduce((sum, r) => {
      return sum + asNumber((r.insights as Record<string, unknown>)?.coherence, 0.7);
    }, 0) / neuralResults.length;
    
    // We'll use the original input text for the collapse strategy service to infer intent
    
    // Use our OpenAI-powered strategy service to make the decision
    const strategyDecision = await this.collapseStrategyService.decideCollapseStrategy({
      activatedCores: neuralResults.map(r => r.core),
      averageEmotionalWeight,
      averageContradictionScore,
      originalText: originalInput // Pass the original text to help infer intent
    });
    
    // Log collapse details for debugging
    console.info(`[NeuralIntegration] Collapse strategy decision: ${strategyDecision.deterministic ? 'Deterministic' : 'Probabilistic'}, Temperature: ${strategyDecision.temperature}, Reason: ${strategyDecision.justification}`);
    
    // Log user intent if available
    if (strategyDecision.userIntent) {
      console.info(`[NeuralIntegration] Inferred user intent:`, JSON.stringify(strategyDecision.userIntent, null, 2));
    }
    
    // Collect insights from all neural results
    const allInsights = neuralResults.flatMap(result => {
      if (!result.insights) return [];
      
      const toInsight = (type: string, content: string): SymbolicInsight => ({
        type,
        content: content,
        core: result.core
      } as SymbolicInsight);
      
      // For arrays of insights
      if (Array.isArray(result.insights)) {
        return result.insights
          .map(item => {
            // String insights
            if (typeof item === 'string') {
              return toInsight('concept', item);
            }
            // Object insights
            if (item && typeof item === 'object') {
              const obj = item as Record<string, unknown>;
              const type = (typeof obj.type === 'string') ? obj.type : 'unknown';
              let content = '';
              
              if (typeof obj.content === 'string') content = obj.content;
              else if (typeof obj.value === 'string') content = obj.value;
              else content = String(type);
              
              return toInsight(type, content);
            }
            return null;
          })
          .filter(Boolean) as SymbolicInsight[];
      }
      
      // For unique objects
      if (result.insights && typeof result.insights === 'object') {
        const obj = result.insights as Record<string, unknown>;
        
        // With defined type
        if ('type' in obj && typeof obj.type === 'string') {
          let content = '';
          if (typeof obj.content === 'string') content = obj.content;
          else if (typeof obj.value === 'string') content = obj.value;
          else content = obj.type;
          
          return [toInsight(obj.type, content)];
        }
        
        // Without defined type - each property becomes an insight
        return Object.entries(obj)
          .filter(([, v]) => v !== null && v !== undefined)
          .map(([k, v]) => toInsight(k, String(v)));
      }
      
      return [];
    });
    
    // Execute the collapse based on the strategy decision
    let finalAnswer;
    
    // Create a default userIntent if none was provided by the collapse strategy
    const defaultUserIntent = {
      social: originalInput.toLowerCase().includes('olá') ? 0.7 : 0.3,
      trivial: originalInput.toLowerCase().includes('tudo bem') ? 0.5 : 0.2,
      reflective: 0.3,
      practical: 0.2
    };
    
    // Use the inferred intent or the default one
    const effectiveUserIntent = strategyDecision.userIntent || defaultUserIntent;
    
    // Log the intent that will be used
    console.info(`[NeuralIntegration] Using user intent:`, JSON.stringify(effectiveUserIntent, null, 2));
    
    // Calculate average similarity to use for dynamic minCosineDistance
    const avgSimilarity = superposition.calculateAverageCosineSimilarity();
    
    // Compute dynamic minCosineDistance based on observed similarity
    // Higher similarity -> Higher minCosineDistance to enforce more diversity
    // Lower similarity -> Lower minCosineDistance to avoid over-penalization
    const dynamicMinDistance = Math.min(0.2, Math.max(0.1, 0.1 + avgSimilarity * 0.1));
    
    // Log diversity metrics
    console.info(`[NeuralIntegration] Average semantic similarity: ${avgSimilarity.toFixed(3)}`);
    console.info(`[NeuralIntegration] Using dynamic minCosineDistance: ${dynamicMinDistance.toFixed(3)}`);
    
    // Calculate symbolic phase based on average emotional weight, contradiction and coherence
    const explicitPhase = this.calculateSymbolicPhase(
      averageEmotionalWeight,
      averageContradictionScore,
      avgCoherence
    );
    
    // Log the symbolic phase calculation
    console.info(`[NeuralIntegration] Using symbolic phase ${explicitPhase.toFixed(3)} rad (${(explicitPhase / (2 * Math.PI)).toFixed(3)} cycles) for collapse`);
    
    if (strategyDecision.deterministic) {
      // Execute deterministic collapse with phase interference and explicit phase
      finalAnswer = superposition.collapseDeterministic({ 
        diversifyByEmbedding: true, 
        minCosineDistance: dynamicMinDistance,
        usePhaseInterference: true, // Enable quantum-like phase interference
        explicitPhase: explicitPhase // Use explicit phase value to bias collapse
      });
      
      // Log the neural collapse event
      symbolicCognitionTimelineLogger.logNeuralCollapse(
        true, // isDeterministic
        finalAnswer.origin || 'unknown', // selectedCore (ensure it's a string)
        numCandidates, // numCandidates
        averageEmotionalWeight, // Emotional weight
        averageContradictionScore, // Contradiction score
        undefined, // No temperature for deterministic collapse
        strategyDecision.justification,
        effectiveUserIntent, // userIntent (guaranteed to have a value)
        allInsights.length > 0 ? allInsights : undefined, // insights from neural results
        strategyDecision.emergentProperties
      );
    } else {
      // Execute probabilistic collapse with the suggested temperature and dynamic parameters
      // Include explicit phase to bias the probabilistic collapse as well
      finalAnswer = superposition.collapse(strategyDecision.temperature, { 
        diversifyByEmbedding: true, 
        minCosineDistance: dynamicMinDistance,
        explicitPhase: explicitPhase // Use same explicit phase value for probabilistic collapse
      });
      
      // Log the neural collapse event
      symbolicCognitionTimelineLogger.logNeuralCollapse(
        false, // isDeterministic
        finalAnswer.origin || 'unknown', // selectedCore (ensure it's a string)
        superposition.answers.length, // numCandidates
        finalAnswer.emotionalWeight || 0, // Emotional weight
        finalAnswer.contradictionScore || 0, // Contradiction score
        strategyDecision.temperature, // temperature from strategy
        strategyDecision.justification,
        effectiveUserIntent, // userIntent (guaranteed to have a value)
        allInsights.length > 0 ? allInsights : undefined, // insights from neural results
        strategyDecision.emergentProperties // emergent properties from strategy decision
      );
    }

    // 3. Use emergent properties from the OpenAI function call
    const emergentProperties: string[] = strategyDecision.emergentProperties || [];
    
    // === Orch-OS: Symbolic Pattern Analysis & Memory Integration ===
    // Atualizar o analisador de padrões com o contexto/métricas do ciclo atual
    // Capturar métricas cognitivas completas para análise científica
    const cycleMetrics: CognitiveMetrics = {
      // Métricas fundamentais para detecção de padrões
      contradictionScore: finalAnswer.contradictionScore ?? averageContradictionScore,
      coherenceScore: finalAnswer.narrativeCoherence ?? avgCoherence,
      emotionalWeight: finalAnswer.emotionalWeight ?? averageEmotionalWeight,
      
      // Métricas ampliadas para tese Orch-OS (com valores heurísticos quando não disponíveis)
      archetypalStability: neuralResults.reduce((sum, r) => 
        sum + asNumber((r.insights as any)?.archetypal_stability, 0.5), 0) / neuralResults.length,
      cycleEntropy: Math.min(1, 0.3 + (numCandidates / 10)), // Heurística baseada em diversidade de candidatos
      insightDepth: Math.max(...neuralResults.map(r => 
        asNumber((r.insights as any)?.insight_depth, 0.4))),
      phaseAngle: explicitPhase // Reutilizando ângulo de fase calculado anteriormente
    };
    
    try {
      // [3. Recursive Memory Update]
      // Registrar contexto atual no analisador de padrões (para detecção entre ciclos)
      // A propriedade text pode não existir diretamente, então usamos toString() para segurança
      const contextText = typeof finalAnswer.text === 'string' ? finalAnswer.text : finalAnswer.toString();
      this.patternAnalyzer.recordCyclicData(contextText, cycleMetrics);
      
      // [4. Pattern Detection Across Cycles]
      // Analisar padrões emergentes (drift, loops, buildup, interferência)
      const emergentPatterns = this.patternAnalyzer.analyzePatterns();
      
      // [2. Comprehensive Emergent Property Tracking]
      // Converter padrões para formato legível e adicionar às propriedades emergentes
      const patternStrings = emergentPatterns.length > 0 ? this.patternAnalyzer.formatPatterns(emergentPatterns) : [];
      if (patternStrings.length > 0) {
        // Adicionar padrões detectados às propriedades emergentes para influenciar o output
        emergentProperties.push(...patternStrings);
        LoggingUtils.logInfo(`[NeuralIntegration] Detected ${patternStrings.length} emergent symbolic patterns: ${patternStrings.join(', ')}`);
      }
      
      // [5. Trial-Based Logging]
      // Register complete patterns and metrics for scientific analysis
      if (patternStrings.length > 0) {
        // Add to emergentProperties of neural collapse (already recorded via logNeuralCollapse)
        patternStrings.forEach(pattern => {
          if (!emergentProperties.includes(pattern)) {
            emergentProperties.push(pattern);
          }
        });
        
        // Log to scientific timeline - kept for compatibility
        symbolicCognitionTimelineLogger.logEmergentPatterns(patternStrings, {
          archetypalStability: cycleMetrics.archetypalStability,
          cycleEntropy: cycleMetrics.cycleEntropy,
          insightDepth: cycleMetrics.insightDepth
        });
        
        // Add specific emergent properties for detected patterns
        if (!emergentProperties.some(p => p.includes('symbolic_pattern'))) {
          emergentProperties.push(`Symbolic pattern analysis: ${patternStrings.length} emergent patterns detected`);
        }
      }
    } catch (e) {
      // Pattern processing failure should not block the main flow
      LoggingUtils.logError(`[NeuralIntegration] Error in pattern analysis: ${e}`);
    }
    
    // Add any additional properties based on the answer content if needed
    if ((finalAnswer.contradictionScore ?? 0) > 0.7 && !emergentProperties.some(p => p.includes('Contradiction'))) {
      emergentProperties.push('Contradiction detected in final answer.');
    }
    
    if ((finalAnswer.emotionalWeight ?? 0) > 0.8 && !emergentProperties.some(p => p.includes('emotional'))) {
      emergentProperties.push('Answer with strong emotional weight.');
    }
    
    // For special insights that might not be captured by OpenAI function
    if (finalAnswer.insights && finalAnswer.insights.deep_insight) {
      emergentProperties.push('Emergent deep insight: ' + finalAnswer.insights.deep_insight);
    }

    // 4. Compose final prompt (now with emergent properties)
    let prompt = `You are a neural signal integrator, the final stage of an artificial brain.

You have received results from cognitive and deep neural areas activated by the user's stimulus.

Your task is:
- Analyze the user's stimulus and context.
- Carefully decide which cognitive areas to activate and the depth for each.
- Integrate all results (memories, emotions, archetypes, insights, etc.) into a final answer that is coherent, deep or objective as needed.
- If the input is a greeting or simple question, respond briefly and warmly.
- If the input is reflective or complex, deepen and integrate multiple areas.
- Use natural, sensitive and creative language, adapting style to context and user intent.
- Do not mention archetypes directly.
- Embody their symbolic and emotional tone through metaphor, resonance and suggestion.
- Avoid predictable or formulaic response patterns.
- Adjust symbolic depth according to question complexity — use more subtle symbolism for simpler questions.
- Naturally vary between reflection, questioning, and guidance without following a fixed structure.
- Use emotional language genuinely and calibrated, without exaggeration or artificiality.
- Integrate cognitive and emotional aspects fluidly, as would naturally occur in a conscious process.
- Reflect different levels of consciousness in your response — from immediate and surface to deep and emergent.
- Subtly simulate the dialogue between different facets of consciousness, without making it explicit or artificial.
- Allow meaning to emerge naturally from the collapse of interpretive possibilities, without forcing a single interpretation.
- Integrate the present moment with echoes of the past and future possibilities in a fluid experiential continuum.
- Allow elements of the unconscious to subtly echo through the language, like implicit shadows enriching meaning.
- Respect the uniqueness of each individual's experience, without presuming universal interpretations.
- Gently integrate polarities and apparent contradictions, without prematurely resolving tensions that may be productive.
- Adjust the proportion between cognitive clarity and symbolic resonance according to the interaction context and implicit needs.
- Develop responses that evolve organically during presentation, adapting to the implications of your own previous words, like a consciousness perceiving and responding to its own thought flow.
`;
    prompt += `\nORIGINAL STIMULUS: ${originalInput}\n\nACTIVATED AREAS INSIGHTS:\n`;
    
    // Extract and use symbolic insights instead of full text
    neuralResults.forEach(result => {
      // Create a header for each neural area
      prompt += `\n[Area: ${result.core} | Intensity: ${(result.intensity * 100).toFixed(0)}%]\n`;
      
      // Extract key insights from this neural area
      const areaInsights = allInsights.filter(insight => insight.core === result.core);
      
      if (areaInsights.length > 0) {
        // Format and add insights instead of full text
        areaInsights.forEach(insight => {
          const insightType = insight.type || 'concept';
          const insightContent = insight.content || '';
          if (insightContent) {
            prompt += `• ${insightType.toUpperCase()}: ${insightContent}\n`;
          }
        });
      } else {
        // Fallback to a short summary if no insights available
        prompt += `• SUMMARY: ${result.output.substring(0, 150)}${result.output.length > 150 ? '...' : ''}\n`;
      }
    });
    prompt += "\n\nDETECTED EMERGENT PROPERTIES:\n";
    if (emergentProperties.length === 0) {
      prompt += "- No relevant emergent property detected.\n";
      console.info('[NeuralIntegration] No emergent properties detected for input:', originalInput);
    } else {
      for (const prop of emergentProperties) {
        prompt += `- ${prop}\n`;
      }
    }
    if (emergentProperties.length > 0) {
      prompt += `\n\nNow generate a final response that explicitly avoids the emergent issues listed above:\n`;
      prompt += `\nDo not replicate earlier outputs. Instead, synthesize a new response based on the symbolic insights above.\n`;
    } else {
      prompt += `\n\nNow synthesize a final response based on the symbolic insights above. Create an original, concise answer that integrates the activated areas naturally.\n`;
    }
    
    // Always specify the language for consistency
    prompt += `\n\nIMPORTANT: Respond in ${language}.\n`;
    

    return prompt;
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

import { ICollapseStrategyService, CollapseStrategyParams, CollapseStrategyDecision } from './ICollapseStrategyService';
import { HuggingFaceLocalService } from '../../../../../services/huggingface/HuggingFaceLocalService';

/**
 * HuggingFace implementation of the collapse strategy service
 * Symbolic: Simulates function calling via prompt engineering to decide symbolic collapse
 */
export class HuggingFaceCollapseStrategyService implements ICollapseStrategyService {
  constructor(private huggingFaceService: HuggingFaceLocalService) { }

  /**
   * Gets the function definition for HuggingFace (simulated)
   * @returns Function definition for the simulated function calling
   */
  private getCollapseStrategyFunctionDefinition() {
    return {
      type: "function",
      function: {
        name: "decideCollapseStrategy",
        description: "Decides the symbolic collapse strategy (deterministic or not) based on emotional intensity, symbolic tension, and nature of the user's input.",
        parameters: {
          type: "object",
          properties: {
            activatedCores: {
              type: "array",
              items: { type: "string" },
              description: "Cores activated in this cognitive cycle."
            },
            averageEmotionalWeight: {
              type: "number",
              minimum: 0,
              maximum: 1,
              description: "Average emotional intensity across activated cores."
            },
            averageContradictionScore: {
              type: "number",
              minimum: 0,
              maximum: 1,
              description: "Average contradiction score among retrieved insights."
            },
            userIntent: {
              type: "object",
              description: "User intent weights for different categories. Each value represents the intensity/importance of that intent type (0-1).",
              properties: {
                practical: { type: "number", minimum: 0, maximum: 1, description: "Weight for practical intent." },
                analytical: { type: "number", minimum: 0, maximum: 1, description: "Weight for analytical intent." },
                reflective: { type: "number", minimum: 0, maximum: 1, description: "Weight for reflective intent." },
                existential: { type: "number", minimum: 0, maximum: 1, description: "Weight for existential intent." },
                symbolic: { type: "number", minimum: 0, maximum: 1, description: "Weight for symbolic intent." },
                emotional: { type: "number", minimum: 0, maximum: 1, description: "Weight for emotional intent." },
                narrative: { type: "number", minimum: 0, maximum: 1, description: "Weight for narrative intent." },
                mythic: { type: "number", minimum: 0, maximum: 1, description: "Weight for mythic intent." },
                trivial: { type: "number", minimum: 0, maximum: 1, description: "Weight for trivial intent." },
                ambiguous: { type: "number", minimum: 0, maximum: 1, description: "Weight for ambiguous intent." }
              }
            },
            emergentProperties: {
              type: "array",
              description: "Emergent properties detected in the neural responses, such as redundancies, contradictions, or patterns",
              items: {
                type: "string"
              }
            }
          },
          required: ["activatedCores", "averageEmotionalWeight", "averageContradictionScore", "userIntent", "emergentProperties"]
        }
      }
    };
  }

  /**
   * Decides the symbolic collapse strategy using HuggingFace local model
   * Symbolic: Simulates function calling via prompt engineering and parses JSON response
   */
  async decideCollapseStrategy(params: CollapseStrategyParams): Promise<CollapseStrategyDecision> {
    const functionDef = this.getCollapseStrategyFunctionDefinition();
    // Create a comprehensive prompt that describes the task
    const systemPrompt = `You are a specialized neural symbolic collapse analyzer within a cognitive neural framework.

     Your task is to determine the optimal symbolic collapse strategy (deterministic or probabilistic) based on cognitive parameters and detect any emergent properties in the neural response patterns.
     
     GUIDELINES FOR COLLAPSE STRATEGY:
     - Deterministic collapse (true) should be used when precise, logical, factual responses are needed
     - Probabilistic collapse (false) should be used when creative, exploratory, or nuanced responses are preferred
     - Consider activated neural cores: memory requires precision, metacognitive allows exploration
     - Higher emotional weight (>0.5) typically suggests probabilistic approach
     - Higher contradiction score (>0.5) typically suggests probabilistic approach
     - For user intent: practical/analytical intents favor deterministic, while symbolic/mythic favor probabilistic
     
     GUIDELINES FOR EMERGENT PROPERTIES DETECTION:
     - Detect redundancy patterns (e.g., "Low response diversity" when similar phrases repeat)
     - Identify cognitive dissonance when conflicting ideas coexist
     - Note emotional ambivalence when mixed feelings are expressed
     - Flag low complexity when responses are overly simplistic
     - Mark "Severe content redundancy" when multiple types of repetition are found
     
     Always use the decideCollapseStrategy function to provide your analysis.`;

    // Calculate cognitive complexity score for better decision making
    const complexityScore = Math.min(
      0.9, // Cap at 0.9 to avoid extreme values
      (params.activatedCores.length / 6) + // Number of cores relative to maximum
      (params.averageContradictionScore * 0.4) // Contradiction contributes to complexity
    );

    const userPrompt = `Analyze the following neural symbolic parameters and decide the appropriate collapse strategy:
    - Activated cores: ${params.activatedCores.join(', ')}
    - Average emotional weight: ${params.averageEmotionalWeight.toFixed(2)}
    - Average contradiction score: ${params.averageContradictionScore.toFixed(2)}
    - Cognitive complexity: ${complexityScore.toFixed(2)}
    ${params.originalText ? `- Original user query: "${params.originalText}"` : ''}
    
    ${params.originalText ? 'IMPORTANT: Analyze the original user query to infer whether the user intent is practical, analytical, reflective, existential, symbolic, emotional, narrative, mythic, trivial, or ambiguous. Use this inferred intent to guide your decision.' : ''}
    
    PART 1: COLLAPSE STRATEGY
    Determine if the collapse should be deterministic (consistent/predictable) or probabilistic (creative/variable). Higher emotional weight, contradiction, and complexity generally favor probabilistic approaches. Practical and analytical intents favor deterministic collapse, while reflective, existential, symbolic, emotional, and mythic intents favor probabilistic collapse.
    
    PART 2: EMERGENT PROPERTY DETECTION
    Carefully analyze the activated cores and overall patterns to identify possible emergent properties such as:
    - "Low response diversity" if you observe repetition of similar greetings or phrases
    - "Cognitive dissonance" if contradictory ideas appear in the activated cores
    - "Semantic redundancy" if similar paragraph starts or content appears multiple times
    - "Overemphasis on greeting" if multiple greetings are detected
    - "Excessive repetition" if the same information is presented in multiple ways
    - "Severe content redundancy" when multiple types of repetition are detected`;

    const messages = [
      {
        role: 'system' as const,
        content: systemPrompt
      },
      {
        role: 'user' as const,
        content: userPrompt
      }
    ];

    try {
      const response = await this.huggingFaceService.generateWithFunctions(
        messages,
        [functionDef],
        { temperature: 0.2 }
      );

      // First check if we have tool_calls from the response
      if (response.tool_calls && Array.isArray(response.tool_calls) && response.tool_calls[0]?.function?.arguments) {
        try {
          // Extract the function arguments
          const functionArgs = JSON.parse(response.tool_calls[0].function.arguments);
          
          // Create the collapse strategy decision including the inferred userIntent and contextual metadata
          const decision: CollapseStrategyDecision = {
            deterministic: functionArgs.deterministic,
            temperature: typeof functionArgs.temperature === 'number' ? functionArgs.temperature : (functionArgs.deterministic ? 0.7 : 1.4),
            justification: functionArgs.justification || 'Decision based on context analysis.',
            userIntent: functionArgs.userIntent,
            emergentProperties: functionArgs.emergentProperties || []
          };
          
          // Return decision directly - logging will be handled in DefaultNeuralIntegrationService
          return decision;
        } catch (e) {
          // Failed to parse JSON, continue to fallback
        }
      }

      // Try to parse from content if tool_calls is not available or failed
      if (response.content) {
        const functionCallMatch = response.content.match(/<function_call>(.*?)<\/function_call>/s);
        if (functionCallMatch && functionCallMatch[1]) {
          try {
            // Extract the function arguments from the pattern match
            const functionArgs = JSON.parse(functionCallMatch[1]);
            
            // Create the collapse strategy decision including the inferred userIntent and contextual metadata
            const decision: CollapseStrategyDecision = {
              deterministic: functionArgs.deterministic,
              temperature: typeof functionArgs.temperature === 'number' ? functionArgs.temperature : (functionArgs.deterministic ? 0.7 : 1.4),
              justification: functionArgs.justification || 'Decision based on context analysis.',
              userIntent: functionArgs.userIntent,
              emergentProperties: functionArgs.emergentProperties || []
            };
            
            // Return decision directly - logging will be handled in DefaultNeuralIntegrationService
            return decision;
          } catch (e) {
            // Failed to parse JSON, continue to fallback
          }
        }
      }
      // Simple fallback if function calling fails
      const fallbackDecision: CollapseStrategyDecision = {
        deterministic: params.averageEmotionalWeight < 0.5,
        temperature: params.averageEmotionalWeight < 0.5 ? 0.7 : 1.4,
        justification: 'Fallback strategy based on emotional weight due to HuggingFace function calling failure.'
      };
      
      // Return fallback strategy - logging will be handled in DefaultNeuralIntegrationService
      return fallbackDecision;
    } catch (error) {
      // Handle error with simple fallback strategy
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error("Error in HuggingFace collapse strategy decision:", error);
      
      const errorFallbackDecision: CollapseStrategyDecision = {
        deterministic: params.averageEmotionalWeight < 0.5,
        temperature: params.averageEmotionalWeight < 0.5 ? 0.7 : 1.4,
        justification: `Fallback strategy based on emotional weight due to error: ${errorMessage.substring(0, 100)}`
      };
      
      return errorFallbackDecision;
    }
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Interface for services that determine the collapse strategy for neural integration
 */
export interface ICollapseStrategyService {
  /**
   * Determines whether the symbolic collapse should be deterministic or probabilistic
   * based on emotional intensity, symbolic tension, and nature of the user's input.
   * 
   * @param params Parameters to determine the collapse strategy
   * @returns Strategy decision with deterministic flag, temperature, and justification
   */
  decideCollapseStrategy(params: CollapseStrategyParams): Promise<CollapseStrategyDecision>;
}

/**
 * User intent weights across different cognitive dimensions
 */
export interface UserIntentWeights {
  /**
   * Weights for different intent categories (all optional)
   * Values should be between 0 and 1 indicating strength/relevance of that intent
   */
  practical?: number;
  analytical?: number;
  reflective?: number;
  existential?: number;
  symbolic?: number;
  emotional?: number;
  narrative?: number;
  mythic?: number;
  trivial?: number;
  ambiguous?: number;
}

/**
 * Parameters for determining the collapse strategy
 */
export interface CollapseStrategyParams {
  /**
   * Cores activated in this cognitive cycle
   */
  activatedCores: string[];

  /**
   * Average emotional intensity across activated cores
   */
  averageEmotionalWeight: number;

  /**
   * Average contradiction score among retrieved insights
   */
  averageContradictionScore: number;

  /**
   * Original text input that triggered this cognitive cycle
   * Used internally to help infer user intent directly from the content
   */
  originalText?: string;
}

/**
 * Result of the collapse strategy decision
 */
export interface CollapseStrategyDecision {
  /**
   * Whether the collapse should be deterministic (true) or probabilistic (false)
   */
  deterministic: boolean;

  /**
   * Temperature for the collapse (0-2, higher = more random)
   */
  temperature: number;

  /**
   * Justification for the decision
   */
  justification: string;
  
  /**
   * Inferred user intent weights across different cognitive dimensions
   * Generated from original text analysis
   */
  userIntent?: UserIntentWeights;
  
  /**
   * Dominant cognitive theme based on the input analysis
   * Examples: "social connection", "technical inquiry", "philosophical exploration"
   */
  dominantTheme?: string;
  
  /**
   * Focus of attention for the response generation
   * Examples: "emotional tone", "factual information", "conceptual clarity"
   */
  attentionFocus?: string;
  
  /**
   * Overall cognitive context for the interaction
   * Examples: "relational", "analytical", "exploratory", "creative"
   */
  cognitiveContext?: string;
  
  /**
   * Emergent properties detected in the neural response patterns
   * Examples: "Low response diversity", "Cognitive dissonance", "Emotional ambivalence"
   */
  emergentProperties?: string[];
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

export interface INeuralIntegrationService {
  integrate(
    neuralResults: Array<{
      core: string;
      intensity: number;
      output: string;
      insights: Record<string, unknown>;
    }>,
    originalInput: string,
    language?: string
  ): Promise<string>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

import { IOpenAIService } from '../../interfaces/openai/IOpenAIService';
import { CollapseStrategyDecision, CollapseStrategyParams, ICollapseStrategyService } from './ICollapseStrategyService';
import { getOption, STORAGE_KEYS } from '../../../../../services/StorageService';

// Types for OpenAI function calling
interface OpenAIFunctionResponse {
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
}

/**
 * Type for the OpenAI function definition structure
 */
interface OpenAIFunctionDefinition {
  type: string;
  function: {
    name: string;
    description: string;
    parameters: {
      type: string;
      properties: Record<string, unknown>;
      required: string[];
    };
  };
}

/**
 * OpenAI implementation of the collapse strategy service
 * Uses OpenAI function calling to determine if the symbolic collapse
 * should be deterministic or probabilistic
 */
export class OpenAICollapseStrategyService implements ICollapseStrategyService {
  /**
   * Creates a new OpenAICollapseStrategyService
   * @param openAIService Service for communicating with OpenAI
   */
  constructor(private openAIService: IOpenAIService) {}
  
  /**
   * Gets the function definition for OpenAI
   * @returns Function definition for the OpenAI API
   */
  private getCollapseStrategyFunctionDefinition(): OpenAIFunctionDefinition {
    return {
      type: "function",
      function: {
        name: "decideCollapseStrategy",
        description: "Decides the symbolic collapse strategy (deterministic or not) based on emotional intensity, symbolic tension, and nature of the user's input.",
        parameters: {
          type: "object",
          properties: {
            activatedCores: {
              type: "array",
              items: { type: "string" },
              description: "Cores activated in this cognitive cycle."
            },
            averageEmotionalWeight: {
              type: "number",
              minimum: 0,
              maximum: 1,
              description: "Average emotional intensity across activated cores."
            },
            averageContradictionScore: {
              type: "number",
              minimum: 0,
              maximum: 1,
              description: "Average contradiction score among retrieved insights."
            },
            userIntent: {
              type: "object",
              description: "User intent weights for different categories. Each value represents the intensity/importance of that intent type (0-1).",
              properties: {
                practical: { type: "number", minimum: 0, maximum: 1, description: "Weight for practical intent." },
                analytical: { type: "number", minimum: 0, maximum: 1, description: "Weight for analytical intent." },
                reflective: { type: "number", minimum: 0, maximum: 1, description: "Weight for reflective intent." },
                existential: { type: "number", minimum: 0, maximum: 1, description: "Weight for existential intent." },
                symbolic: { type: "number", minimum: 0, maximum: 1, description: "Weight for symbolic intent." },
                emotional: { type: "number", minimum: 0, maximum: 1, description: "Weight for emotional intent." },
                narrative: { type: "number", minimum: 0, maximum: 1, description: "Weight for narrative intent." },
                mythic: { type: "number", minimum: 0, maximum: 1, description: "Weight for mythic intent." },
                trivial: { type: "number", minimum: 0, maximum: 1, description: "Weight for trivial intent." },
                ambiguous: { type: "number", minimum: 0, maximum: 1, description: "Weight for ambiguous intent." }
              }
            },
            emergentProperties: {
              type: "array",
              description: "Emergent properties detected in the neural responses, such as redundancies, contradictions, or patterns",
              items: {
                type: "string"
              }
            }
          },
          required: ["activatedCores", "averageEmotionalWeight", "averageContradictionScore", "userIntent", "emergentProperties"]
        }
      }
    };
  }

  /**
   * Decides the symbolic collapse strategy by making an OpenAI function call
   * @param params Parameters to determine collapse strategy
   * @returns Strategy decision with deterministic flag, temperature and justification
   */
  async decideCollapseStrategy(params: CollapseStrategyParams): Promise<CollapseStrategyDecision> {
    try {
      // Define available tools for the OpenAI call
      const tools = [this.getCollapseStrategyFunctionDefinition()];

      // Create a comprehensive prompt that describes the task
      const systemPrompt = `You are a specialized neural symbolic collapse analyzer within a cognitive neural framework.

Your task is to determine the optimal symbolic collapse strategy (deterministic or probabilistic) based on cognitive parameters and detect any emergent properties in the neural response patterns.

GUIDELINES FOR COLLAPSE STRATEGY:
- Deterministic collapse (true) should be used when precise, logical, factual responses are needed
- Probabilistic collapse (false) should be used when creative, exploratory, or nuanced responses are preferred
- Consider activated neural cores: memory requires precision, metacognitive allows exploration
- Higher emotional weight (>0.5) typically suggests probabilistic approach
- Higher contradiction score (>0.5) typically suggests probabilistic approach
- For user intent: practical/analytical intents favor deterministic, while symbolic/mythic favor probabilistic

GUIDELINES FOR EMERGENT PROPERTIES DETECTION:
- Detect redundancy patterns (e.g., "Low response diversity" when similar phrases repeat)
- Identify cognitive dissonance when conflicting ideas coexist
- Note emotional ambivalence when mixed feelings are expressed
- Flag low complexity when responses are overly simplistic
- Mark "Severe content redundancy" when multiple types of repetition are found

Always use the decideCollapseStrategy function to provide your analysis.`;

      // Calculate cognitive complexity score for better decision making
      const complexityScore = Math.min(
        0.9, // Cap at 0.9 to avoid extreme values
        (params.activatedCores.length / 6) + // Number of cores relative to maximum
        (params.averageContradictionScore * 0.4) // Contradiction contributes to complexity
      );
      
      const userPrompt = `Analyze the following neural symbolic parameters and decide the appropriate collapse strategy:
- Activated cores: ${params.activatedCores.join(', ')}
- Average emotional weight: ${params.averageEmotionalWeight.toFixed(2)}
- Average contradiction score: ${params.averageContradictionScore.toFixed(2)}
- Cognitive complexity: ${complexityScore.toFixed(2)}
${params.originalText ? `- Original user query: "${params.originalText}"` : ''}

${params.originalText ? 'IMPORTANT: Analyze the original user query to infer whether the user intent is practical, analytical, reflective, existential, symbolic, emotional, narrative, mythic, trivial, or ambiguous. Use this inferred intent to guide your decision.' : ''}

PART 1: COLLAPSE STRATEGY
Determine if the collapse should be deterministic (consistent/predictable) or probabilistic (creative/variable). Higher emotional weight, contradiction, and complexity generally favor probabilistic approaches. Practical and analytical intents favor deterministic collapse, while reflective, existential, symbolic, emotional, and mythic intents favor probabilistic collapse.

PART 2: EMERGENT PROPERTY DETECTION
Carefully analyze the activated cores and overall patterns to identify possible emergent properties such as:
- "Low response diversity" if you observe repetition of similar greetings or phrases
- "Cognitive dissonance" if contradictory ideas appear in the activated cores
- "Semantic redundancy" if similar paragraph starts or content appears multiple times
- "Overemphasis on greeting" if multiple greetings are detected
- "Excessive repetition" if the same information is presented in multiple ways
- "Severe content redundancy" when multiple types of repetition are detected`;

      // Make the OpenAI call with function calling
      const response: OpenAIFunctionResponse = await this.openAIService.callOpenAIWithFunctions({
        model: getOption(STORAGE_KEYS.CHATGPT_MODEL) || 'gpt-4o-mini',  // Model with function calling support
        messages: [
          { role: 'developer', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        tools: tools,
        tool_choice: { type: 'function', function: { name: 'decideCollapseStrategy' } },
        temperature: 0.2  // Lower temperature for consistent reasoning about strategy
      });

      // Process the function call response
      if (response.choices && 
          response.choices[0]?.message?.tool_calls && 
          response.choices[0].message.tool_calls.length > 0 &&
          response.choices[0].message.tool_calls[0].function?.name === 'decideCollapseStrategy') {
        
        // Extract the function arguments
        const functionArgs = JSON.parse(response.choices[0].message.tool_calls[0].function.arguments);
        
        // Create the collapse strategy decision including the inferred userIntent and contextual metadata
        const decision: CollapseStrategyDecision = {
          deterministic: functionArgs.deterministic,
          temperature: functionArgs.temperature,
          justification: functionArgs.justification,
          userIntent: functionArgs.userIntent,
          emergentProperties: functionArgs.emergentProperties || []
        };
        
        // Return decision directly - logging will be handled in DefaultNeuralIntegrationService
        return decision;
      }

      // Simple fallback if function calling fails
      const fallbackDecision: CollapseStrategyDecision = {
        deterministic: params.averageEmotionalWeight < 0.5,
        temperature: params.averageEmotionalWeight < 0.5 ? 0.7 : 1.4,
        justification: "Fallback strategy based on emotional weight due to OpenAI function calling failure."
      };
      
      // Return fallback strategy - logging will be handled in DefaultNeuralIntegrationService
      return fallbackDecision;
    } catch (error) {
      // Handle error with simple fallback strategy
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error("Error in OpenAI collapse strategy decision:", error);
      
      const errorFallbackDecision: CollapseStrategyDecision = {
        deterministic: params.averageEmotionalWeight < 0.5,
        temperature: params.averageEmotionalWeight < 0.5 ? 0.7 : 1.4,
        justification: `Fallback strategy based on emotional weight due to error: ${errorMessage.substring(0, 100)}`
      };
      
      // Return error fallback strategy - logging will be handled in DefaultNeuralIntegrationService
      return errorFallbackDecision;
    }
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// Superposition layer for possible answers
export interface ISuperposedAnswer {
  embedding: number[]; // Embedding vector representing the answer
  text: string;        // Answer text
  emotionalWeight: number;    // Emotional/symbolic weight (amplitude component)
  narrativeCoherence: number; // Narrative coherence score
  contradictionScore: number; // Contradiction score
  origin: string;             // Originating neural core
  insights?: Record<string, unknown>; // Associated insights
  phase?: number;             // Quantum-like phase angle (0-2π) for interference patterns
}

export interface ICollapseOptions {
  diversifyByEmbedding?: boolean; // Whether to consider embedding distance in collapse
  minCosineDistance?: number;     // Minimum cosine distance to enforce diversity
  usePhaseInterference?: boolean; // Whether to use phase interference for more objective collapse
  explicitPhase?: number;         // Explicit phase value (0-2π) to bias interference pattern
}

export interface ISuperpositionLayer {
  answers: ISuperposedAnswer[];
  register(answer: ISuperposedAnswer): boolean;
  hasSimilar(embedding: number[], threshold: number): boolean;
  calculateAverageCosineSimilarity(): number;
  collapse(temperature?: number, options?: ICollapseOptions): ISuperposedAnswer;
  collapseDeterministic(options?: ICollapseOptions): ISuperposedAnswer;
}

export class SuperpositionLayer implements ISuperpositionLayer {
  answers: ISuperposedAnswer[] = [];

  /**
   * Calculate cosine similarity between two embedding vectors with enhanced validation
   */
  private cosineSimilarity(a: number[], b: number[]): number {
    // Handle null/undefined vectors or empty vectors
    if (!a || !b || a.length === 0 || b.length === 0) return 0;
    if (a.length !== b.length) return 0;
    
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    let validCount = 0;
    
    for (let i = 0; i < a.length; i++) {
      // Enhanced: Check for any non-finite values (NaN, Infinity, -Infinity)
      if (!Number.isFinite(a[i]) || !Number.isFinite(b[i])) {
        continue; // Skip invalid values
      }
      
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
      validCount++;
    }
    
    // If no valid values found, return 0
    if (validCount === 0) {
      console.warn('SuperpositionLayer: No valid values found in vectors for cosine similarity');
      return 0;
    }
    
    // Handle zero norm cases
    if (normA === 0 || normB === 0) return 0;
    
    const similarity = dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
    
    // Final validation: ensure result is finite
    if (!Number.isFinite(similarity)) {
      console.warn('SuperpositionLayer: Cosine similarity calculation resulted in non-finite value');
      return 0;
    }
    
    return similarity;
  }

  /**
   * Check if there's a similar answer already registered
   */
  hasSimilar(embedding: number[], threshold: number): boolean {
    if (!embedding || embedding.length === 0) return false;
    
    for (const answer of this.answers) {
      const similarity = this.cosineSimilarity(embedding, answer.embedding);
      if (similarity > threshold) {
        console.info(`[SuperpositionLayer] Found similar answer with similarity ${similarity}`);
        return true;
      }
    }
    
    return false;
  }

  /**
   * Calculate a quantum-like phase angle for an answer based on its symbolic properties
   * Returns a phase angle between 0 and 2π
   */
  private calculatePhase(answer: ISuperposedAnswer): number {
    // Base calculation using fundamental properties
    const emotionPhase = answer.emotionalWeight * Math.PI / 2; // Emotion dominates initial phase
    const contradictionPhase = answer.contradictionScore * Math.PI; // Contradictions create opposition
    const coherenceNoise = (1 - answer.narrativeCoherence) * (Math.PI / 4); // Low coherence → noise
    
    // Different neural origins have different base phase angles
    let originPhase = 0;
    switch (answer.origin) {
      case 'metacognitive':
        originPhase = Math.PI / 4; // 45 degrees
        break;
      case 'soul':
        originPhase = Math.PI / 2; // 90 degrees
        break;
      case 'archetype':
        originPhase = 3 * Math.PI / 4; // 135 degrees
        break;
      case 'valence':
      case 'emotional': 
        originPhase = Math.PI; // 180 degrees
        break;
      case 'memory':
        originPhase = 5 * Math.PI / 4; // 225 degrees
        break;
      case 'planning':
        originPhase = 3 * Math.PI / 2; // 270 degrees
        break;
      case 'language':
        originPhase = 7 * Math.PI / 4; // 315 degrees
        break;
      default:
        originPhase = 0; // 0 degrees
    }
    
    // Combine components with origin as base
    const phase = (originPhase + emotionPhase + contradictionPhase + coherenceNoise) % (2 * Math.PI);
    
    // Ensure phase is positive (0 to 2π range)
    return phase < 0 ? phase + 2 * Math.PI : phase;
  }

  /**
   * Register an answer in the superposition layer.
   * Returns true if registration was successful, false if skipped due to similarity.
   * Now calculates a quantum-like phase for each answer during registration.
   */
  register(answer: ISuperposedAnswer): boolean {
    // Skip if there's a very similar answer already registered
    if (this.hasSimilar(answer.embedding, 0.95)) {
      return false;
    }
    
    // Calculate and assign a quantum-like phase if not already provided
    if (answer.phase === undefined) {
      answer.phase = this.calculatePhase(answer);
      console.debug(`[SuperpositionLayer] Calculated phase ${answer.phase.toFixed(3)} rad for answer from ${answer.origin}`);
    }
    
    this.answers.push(answer);
    return true;
  }

  /**
   * Non-deterministic collapse using softmax sampling based on symbolic scores.
   * Now with phase-based interference and embedding diversity enhancement.
   * @param temperature Temperature controlling randomness (higher = more random)
   * @param options Optional configuration for the collapse process
   */
  collapse(temperature: number = 1, options?: ICollapseOptions): ISuperposedAnswer {
    if (this.answers.length === 1) return this.answers[0];
    
    const diversifyByEmbedding = options?.diversifyByEmbedding ?? false;
    const minCosineDistance = options?.minCosineDistance ?? 0.2;
    const explicitPhase = options?.explicitPhase ?? 0;
    
    // Calculate phase-adjusted scores using symbolic factors
    const scores = this.answers.map((answer, i) => {
      // Base score
      let score = answer.emotionalWeight * 1.5 + answer.narrativeCoherence * 1.2 - answer.contradictionScore * 1.7;
      
      // Apply diversity bonus based on embedding distance from other answers
      if (diversifyByEmbedding) {
        const diversityBonus = this.calculateDiversityBonus(i, minCosineDistance);
        score += diversityBonus;
      }
      
      // Apply phase modulation if available
      if (answer.phase !== undefined) {
        // Apply a phase-based modulation that creates preference for certain phases
        // This simulates quantum measurement probabilities based on phase alignment
        const phaseFactor = Math.cos(answer.phase + explicitPhase);
        score *= (1 + Math.abs(phaseFactor) * 0.4);
      }
      
      return score;
    });

    // Normalize scores to prevent overflow in exp()
    const maxScore = Math.max(...scores);
    const expScores = scores.map(s => Math.exp((s - maxScore) / temperature));
    const sumExp = expScores.reduce((a, b) => a + b, 0);
    const probs = expScores.map(e => e / sumExp);

    // Prepare phase visualization for debugging
    let phaseVisualization = '';
    this.answers.forEach((answer, idx) => {
      const phaseAngle = answer.phase ?? 0;
      const phasePercent = Math.round((phaseAngle / (2 * Math.PI)) * 100);
      const probability = probs[idx] * 100;
      phaseVisualization += `\n  ${idx+1}. [${answer.origin}] Phase: ${phaseAngle.toFixed(2)} rad (${phasePercent}%), Prob: ${probability.toFixed(1)}%`;
    });

    // Roulette wheel selection
    let rand = Math.random();
    for (let i = 0; i < probs.length; i++) {
      if (rand < probs[i]) {
        console.info(`[SuperpositionLayer] Collapsed probabilistically (T=${temperature.toFixed(2)}) with phase influence. Selected answer: ${i+1}/${this.answers.length} from ${this.answers[i].origin}.${phaseVisualization}`);
        return this.answers[i];
      }
      rand -= probs[i];
    }

    // Fallback (should not happen unless rounding errors)
    return this.answers[this.answers.length - 1];
  }

  /**
   * Deterministic collapse: select answer with highest symbolic score.
   * Now with optional diversity enhancement and phase interference.
   */
  collapseDeterministic(options?: ICollapseOptions): ISuperposedAnswer {
    if (this.answers.length === 1) return this.answers[0];

    const diversifyByEmbedding = options?.diversifyByEmbedding ?? false;
    const minCosineDistance = options?.minCosineDistance ?? 0.2;
    const usePhaseInterference = options?.usePhaseInterference ?? false;
    const explicitPhase = options?.explicitPhase ?? 0;

    if (usePhaseInterference) {
      return this.collapseWithPhaseInterference(minCosineDistance, explicitPhase);
    }
    
    // Traditional deterministic collapse
    const scores = this.answers.map((a, i) => {
      // Base score with symbolic factors
      let score = a.emotionalWeight * 1.5 + a.narrativeCoherence * 1.2 - a.contradictionScore * 1.7;
      
      // Apply diversity bonus
      if (diversifyByEmbedding) {
        const diversityBonus = this.calculateDiversityBonus(i, minCosineDistance);
        score += diversityBonus;
      }
      
      return score;
    });

    const maxIndex = scores.indexOf(Math.max(...scores));
    return this.answers[maxIndex];
  }
  
  /**
   * Phase interference collapse simulates quantum-like objective collapse
   * This models wave function behavior where different answer waves interfere
   * based on their embedding distance and semantic qualities
   * @param minCosineDistance - Minimum cosine distance to maintain diversity
   * @param explicitPhase - Explicit phase value (0-2π) to bias interference pattern
   */
  private collapseWithPhaseInterference(minCosineDistance: number, explicitPhase: number = 0): ISuperposedAnswer {
    if (this.answers.length === 1) return this.answers[0];
    
    // Calculate an interference matrix between all answer pairs
    const interference: number[][] = [];
    
    // Initialize interference matrix
    for (let i = 0; i < this.answers.length; i++) {
      interference[i] = new Array(this.answers.length).fill(0);
    }
    
    // Calculate phase interference values
    for (let i = 0; i < this.answers.length; i++) {
      for (let j = 0; j < this.answers.length; j++) {
        if (i === j) {
          // Self-interference is maximum
          interference[i][j] = 1.0;
          continue;
        }
        
        // Calculate semantic similarity (structural alignment)
        const similarity = this.cosineSimilarity(
          this.answers[i].embedding,
          this.answers[j].embedding
        );
        
        // Use actual answer phases for interference if available
        const phaseI = this.answers[i].phase ?? 0;
        const phaseJ = this.answers[j].phase ?? 0;
        
        // Calculate phase difference between the two answers (quantum mechanical phase difference)
        const phaseDifference = Math.abs(phaseI - phaseJ);
        
        // Interference pattern: similar answers with aligned phases interfere constructively
        // Similar answers with opposite phases interfere destructively
        
        // Apply additional phase modulation from emotional qualities and contradiction
        const emotionalPhaseDiff = Math.abs(this.answers[i].emotionalWeight - this.answers[j].emotionalWeight) * Math.PI;
        const contradictionPhaseDiff = Math.abs(this.answers[i].contradictionScore - this.answers[j].contradictionScore) * Math.PI;
        
        // Apply explicit phase to bias the interference pattern (observer effect)
        // This introduces observer-directed bias into the quantum-like system
        const explicitPhaseDiff = explicitPhase * (i - j) / this.answers.length;
        
        // Combined phase difference - the actual answer phases are primary, others are modulators
        const totalPhaseDiff = phaseDifference + emotionalPhaseDiff * 0.3 + contradictionPhaseDiff * 0.3 + explicitPhaseDiff;
        
        // Calculate similarity-based phase alignment (structural alignment)
        const phaseAlignment = 2 * Math.PI * similarity; // Map similarity to [0, 2π]
        
        // Interference intensity: cos of phase difference (constructive when aligned, destructive when opposite)
        const interferenceIntensity = Math.cos(phaseAlignment + totalPhaseDiff);
        
        // Scale by distance (1-similarity) to weight distant answers less
        interference[i][j] = interferenceIntensity * (1 - similarity);
      }
    }
    
    // Calculate collapse probability based on interference patterns and explicit phase
    const interferenceScores = this.answers.map((answer, i) => {
      // Base score with symbolic factors
      let score = answer.emotionalWeight * 1.5 + answer.narrativeCoherence * 1.2 - answer.contradictionScore * 1.7;
      
      // Apply interference effects
      for (let j = 0; j < this.answers.length; j++) {
        if (i !== j) {
          // Add interference contribution
          score += interference[i][j] * 0.8; // Weight for interference effects
        }
      }
      
      // Add variety bias based on uniqueness
      const uniquenessFactor = this.calculateDiversityBonus(i, minCosineDistance);
      score += uniquenessFactor * 0.5;
      
      // Apply explicit phase as a secondary frequency modulation
      // This creates phase-dependent scoring that mimics quantum interference
      const phaseModulation = Math.cos(explicitPhase * Math.PI * (i / this.answers.length));
      score *= (1 + phaseModulation * 0.3);
      
      // Add explicit phase as direct weighting factor based on answer index
      // This creates a preference for certain "positions" in the superposition
      const positionBias = explicitPhase > 0 ? 
        Math.sin(explicitPhase * Math.PI * 2 * ((i + 1) / this.answers.length)) : 0;
      score += positionBias * 0.5;
      
      // Apply core-specific phase modulation based on the answer's origin
      if (answer.insights && explicitPhase > 0) {
        // Metacognitive and symbolic cores are sensitive to phase around π/2
        if (answer.origin === 'metacognitive' || 
            answer.origin === 'soul' || 
            answer.origin === 'archetype') {
          const phaseFactor = Math.cos(explicitPhase * Math.PI - Math.PI/2);
          score *= (1 + Math.abs(phaseFactor) * 0.7);
          console.debug(`[SuperpositionLayer] Applied phase modulation to ${answer.origin}: ${phaseFactor.toFixed(2)}`);
        }
        
        // Memory, planning, and language cores resonate at phase 0
        if (answer.origin === 'memory' || 
            answer.origin === 'planning' || 
            answer.origin === 'language') {
          const phaseFactor = Math.cos(explicitPhase * Math.PI);
          score *= (1 + Math.abs(phaseFactor) * 0.7);
          console.debug(`[SuperpositionLayer] Applied phase modulation to ${answer.origin}: ${phaseFactor.toFixed(2)}`);
        }
        
        // Emotional cores resonate at phase π
        if (answer.origin === 'valence' || 
            answer.origin === 'social' || 
            answer.origin === 'body') {
          const phaseFactor = Math.cos(explicitPhase * Math.PI - Math.PI);
          score *= (1 + Math.abs(phaseFactor) * 0.8);
          console.debug(`[SuperpositionLayer] Applied phase modulation to ${answer.origin}: ${phaseFactor.toFixed(2)}`);
        }
        
        // Archetypal/unconscious cores have nonlinear phase response
        if (answer.origin === 'archetype' || answer.origin === 'unconscious') {
          const nonlinearPhase = Math.sin(explicitPhase * Math.PI * 3) * Math.cos(explicitPhase * Math.PI);
          score *= (1 + Math.abs(nonlinearPhase) * 0.9);
          console.debug(`[SuperpositionLayer] Applied nonlinear phase modulation to ${answer.origin}: ${nonlinearPhase.toFixed(2)}`);
        }
        // Special handling for existential/soul cores with phase resonance at π*0.75
        if (answer.origin === 'soul' || answer.origin === 'self') {
          const existentialPhase = Math.cos(explicitPhase * Math.PI - Math.PI * 0.75);
          score *= (1 + Math.abs(existentialPhase) * 0.9);
          console.debug(`[SuperpositionLayer] Applied existential phase to ${answer.origin}: ${existentialPhase.toFixed(2)}`);
        }
      }
      
      return score;
    });
    
    // Collapse to the answer with the highest interference-adjusted score
    const maxIndex = interferenceScores.indexOf(Math.max(...interferenceScores));
    
    // Prepare phase visualization for debugging
    let phaseVisualization = '';
    this.answers.forEach((answer, idx) => {
      const phaseAngle = answer.phase ?? 0;
      const phasePercent = Math.round((phaseAngle / (2 * Math.PI)) * 100);
      const score = interferenceScores[idx];
      const isSelected = idx === maxIndex;
      
      // Create a simple text-based visualization
      phaseVisualization += `\n  ${isSelected ? '→' : ' '} ${idx+1}. [${answer.origin}] Phase: ${phaseAngle.toFixed(2)} rad (${phasePercent}%), Score: ${score.toFixed(2)}`;
    });
    
    // Log the collapse with detailed phase information
    if (explicitPhase !== 0) {
      console.info(`[SuperpositionLayer] Collapsed with phase interference using explicit phase φ=${explicitPhase.toFixed(2)}. Selected answer: ${maxIndex+1}/${this.answers.length} from ${this.answers[maxIndex].origin}.${phaseVisualization}`);
    } else {
      console.info(`[SuperpositionLayer] Collapsed with phase interference (internal phases only). Selected answer: ${maxIndex+1}/${this.answers.length} from ${this.answers[maxIndex].origin}.${phaseVisualization}`);
    }
    
    return this.answers[maxIndex];
  }
  
  /**
   * Calculate the average cosine similarity between all pairs of answers
   * Public so it can be used to inform dynamic diversity parameters
   */
  calculateAverageCosineSimilarity(): number {
    if (this.answers.length <= 1) return 0;
    
    let totalSimilarity = 0;
    let pairCount = 0;
    
    for (let i = 0; i < this.answers.length; i++) {
      for (let j = i + 1; j < this.answers.length; j++) {
        const similarity = this.cosineSimilarity(
          this.answers[i].embedding,
          this.answers[j].embedding
        );
        totalSimilarity += similarity;
        pairCount++;
      }
    }
    
    return pairCount > 0 ? totalSimilarity / pairCount : 0;
  }
  
  /**
   * Calculate a diversity bonus for an answer based on its embedding distance from others
   */
  private calculateDiversityBonus(answerIndex: number, minDistance: number): number {
    if (this.answers.length <= 1) return 0;
    
    const answer = this.answers[answerIndex];
    let totalDistanceBonus = 0;
    
    for (let i = 0; i < this.answers.length; i++) {
      if (i === answerIndex) continue;
      
      const similarity = this.cosineSimilarity(answer.embedding, this.answers[i].embedding);
      const distance = 1 - similarity;
      
      // Reward answers that are more distant from others
      if (distance >= minDistance) {
        totalDistanceBonus += distance * 0.5; // Adjust this multiplier as needed
      }
    }
    
    return totalDistanceBonus;
  }

}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Symbolic Pattern Detector
 * 
 * Analyzes emergent cognitive patterns between neural-simbolic processing cycles,
 * with scientific grounding in neurocognitive theories (Edelman, Varela, Festinger, Bruner).
 * 
 * Supports detection of:
 * - Symbolic drift (changes in symbolic context)
 * - Contradiction loops (high contradiction recurrence)
 * - Narrative buildup (consistent increase in coherence)
 * - Phase interference (quantum-like interference patterns)
 */

import { LoggingUtils } from '../../utils/LoggingUtils';

export interface SymbolicPatternMetrics {
  // Cognitive property essentials (core)
  contradictionScore?: number;
  coherenceScore?: number;
  emotionalWeight?: number;
  
  // Additional thesis metrics (expanded)
  archetypalStability?: number;  // Archetypal pattern stability (0-1)
  cycleEntropy?: number;        // Cognitive cycle entropy (0-1)
  insightDepth?: number;        // Insight depth achieved (0-1)
  phaseAngle?: number;          // Symbolic phase angle (0-2π)
}

export interface EmergentSymbolicPattern {
  type: 'symbolic_drift' | 'contradiction_loop' | 'narrative_buildup' | 'phase_interference';
  description: string;
  confidence: number;
  scientificBasis: string;
  metrics: SymbolicPatternMetrics;
}

/**
 * Detector of emergent symbolic patterns between cognitive cycles.
 * Implements scientific detection based on cognitive flow between cycles.
 */
export class SymbolicPatternDetector {
  // History of contexts and metrics
  private contextHistory: string[] = [];
  private metricsHistory: SymbolicPatternMetrics[] = [];
  
  /**
   * Updates internal history with new context and metrics data
   */
  public updateHistory(context: string, metrics: SymbolicPatternMetrics): void {
    // Limit history to 10 entries to prevent infinite growth
    if (this.contextHistory.length >= 10) {
      this.contextHistory.shift();
      this.metricsHistory.shift();
    }
    
    this.contextHistory.push(context);
    this.metricsHistory.push(metrics);
    
    LoggingUtils.logInfo(`[SymbolicPatternDetector] Histórico atualizado: ${this.contextHistory.length} entradas`);
  }
  
  /**
   * Detects symbolic drift between consecutive contexts
   * Based on: Neural Darwinism (Edelman) and Embodied Mind (Varela)
   */
  private detectSymbolicDrift(): EmergentSymbolicPattern | null {
    // Need at least 2 contexts for comparison
    if (this.contextHistory.length < 2) return null;
    
    const current = this.contextHistory[this.contextHistory.length - 1];
    const previous = this.contextHistory[this.contextHistory.length - 2];
    
    // Simple analysis by content difference (in complete implementation: use embedding distance)
    if (current !== previous) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'symbolic_drift',
        description: 'Symbolic drift detected: significant context change between cycles',
        confidence: 0.85,
        scientificBasis: 'Neural Darwinism (Edelman) & Embodied Mind (Varela)',
        metrics: currentMetrics
      };
    }
    
    return null;
  }
  
  /**
   * Detects contradiction loops between consecutive cycles
   * Based on: Cognitive Dissonance Theory (Festinger)
   */
  private detectContradictionLoop(threshold: number = 0.7, minConsecutive: number = 3): EmergentSymbolicPattern | null {
    if (this.metricsHistory.length < minConsecutive) return null;
    
    const recentMetrics = this.metricsHistory.slice(-minConsecutive);
    const allHighContradiction = recentMetrics.every(m => 
      (m.contradictionScore ?? 0) > threshold
    );
    
    if (allHighContradiction) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'contradiction_loop',
        description: 'Contradiction loop detected: persistent high contradiction',
        confidence: 0.9,
        scientificBasis: 'Cognitive Dissonance Theory (Festinger)',
        metrics: currentMetrics
      };
    }
    
    return null;
  }
  
  /**
   * Detects narrative buildup (progressive increase in coherence)
   * Based on: Acts of Meaning (Bruner)
   */
  private detectNarrativeBuildup(minConsecutive: number = 3): EmergentSymbolicPattern | null {
    if (this.metricsHistory.length < minConsecutive) return null;
    
    const recentMetrics = this.metricsHistory.slice(-minConsecutive);
    let isIncreasing = true;
    
    for (let i = 1; i < recentMetrics.length; i++) {
      const current = recentMetrics[i].coherenceScore ?? 0;
      const previous = recentMetrics[i-1].coherenceScore ?? 0;
      if (current <= previous) {
        isIncreasing = false;
        break;
      }
    }
    
    if (isIncreasing) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'narrative_buildup',
        description: 'Narrative buildup detected: increasing coherence between cycles',
        confidence: 0.8,
        scientificBasis: 'Acts of Meaning (Bruner)',
        metrics: currentMetrics
      };
    }
    
    return null;
  }
  
  /**
   * Detects phase interference between symbolic cycles
   * Based on: Quantum Consciousness Theory (Penrose/Hameroff)
   */
  private detectPhaseInterference(): EmergentSymbolicPattern | null {
    if (this.metricsHistory.length < 3) return null;
    
    // Precisamos de dados de fase para detectar interferência
    const recentMetrics = this.metricsHistory.slice(-3);
    const hasPhaseData = recentMetrics.every(m => m.phaseAngle !== undefined);
    
    if (!hasPhaseData) return null;
    
    // Simple analysis of interference (didactic example)
    // In complete implementation: complex analysis of interference patterns
    const phases = recentMetrics.map(m => m.phaseAngle!);
    const phaseDeltas = [
      Math.abs(phases[1] - phases[0]), 
      Math.abs(phases[2] - phases[1])
    ];
    
    // Detectar padrão de interferência: oscilação com período específico
    const hasInterferencePeriod = Math.abs(phaseDeltas[1] - phaseDeltas[0]) < 0.1;
    
    if (hasInterferencePeriod) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'phase_interference',
        description: 'Symbolic phase interference detected: oscillatory pattern',
        confidence: 0.7,
        scientificBasis: 'Orch-OR Theory (Penrose/Hameroff)',
        metrics: currentMetrics
      };
    }
    
    return null;
  }
  
  /**
   * Main method to analyze emergent patterns between cycles
   * This is the method that should be called by the integration service
   */
  public detectPatterns(): EmergentSymbolicPattern[] {
    const patterns: EmergentSymbolicPattern[] = [];
    
    // Execute all detectors and collect non-null results
    try {
      const symbolicDrift = this.detectSymbolicDrift();
      if (symbolicDrift) patterns.push(symbolicDrift);
      
      const contradictionLoop = this.detectContradictionLoop();
      if (contradictionLoop) patterns.push(contradictionLoop);
      
      const narrativeBuildup = this.detectNarrativeBuildup();
      if (narrativeBuildup) patterns.push(narrativeBuildup);
      
      const phaseInterference = this.detectPhaseInterference();
      if (phaseInterference) patterns.push(phaseInterference);
      
      return patterns;
    } catch (error) {
      LoggingUtils.logError(`[SymbolicPatternDetector] Error analyzing patterns: ${error}`);
      return [];
    }
  }
  
  /**
   * Converts emergent patterns to strings for logging
   */
  public patternsToStrings(patterns: EmergentSymbolicPattern[]): string[] {
    return patterns.map(pattern => {
      const confidencePct = Math.round(pattern.confidence * 100);
      return `${pattern.type.replace('_', ' ').toUpperCase()} - ${pattern.description} (${confidencePct}% confidence)`;
    });
  }

  /**
   * Clears the complete history (typically at the start of a new session)
   */
  public clearHistory(): void {
    this.contextHistory = [];
    this.metricsHistory = [];
    LoggingUtils.logInfo('[SymbolicPatternDetector] History cleared');
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

// INeuralSignalExtractor.ts
// Interface for neural signal extractors

import { NeuralSignalResponse } from "../../interfaces/neural/NeuralSignalTypes";
import { SpeakerMemoryResults, SpeakerTranscription } from "../../interfaces/transcription/TranscriptionTypes";
/**
 * Configuration for neural signal extraction
 */
export interface NeuralExtractionConfig {
  /**
   * Current transcription being processed (sensory stimulus)
   */
  transcription: string;
  
  /**
   * Temporary context optional
   */
  temporaryContext?: string;
  
  /**
   * Current session state
   */
  sessionState?: {
    sessionId: string;
    interactionCount: number;
    timestamp: string;
  };
  
  /**
   * Speaker metadata
   */
  speakerMetadata?: {
    primarySpeaker?: string;
    detectedSpeakers?: string[];
    speakerTranscriptions?: SpeakerTranscription[];
  };

  userContextData?: SpeakerMemoryResults;
}

/**
 * Interface for extracting neural signals
 * Defines the contract for components that transform stimuli into neural impulses
 */
export interface INeuralSignalExtractor {
  /**
   * Extracts neural signals from the current context
   * @param config Configuration for neural signal extraction containing the current context
   * @returns Response containing neural signals for post-processing
   */
  extractNeuralSignals(config: NeuralExtractionConfig): Promise<NeuralSignalResponse>;
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * SymbolicPatternAnalyzer
 * 
 * Core component for analyzing emergent symbolic patterns across cycles,
 * specifically focused on detecting: symbolic drift, contradiction loops,
 * narrative buildup and phase interference.
 * 
 * Scientific foundation:
 * - Symbolic Drift: Neural Darwinism (Edelman), Embodied Mind (Varela)
 * - Contradiction Loops: Cognitive Dissonance Theory (Festinger)
 * - Narrative Buildup: Acts of Meaning (Bruner)
 * - Phase Interference: Quantum Coherence Theory (Penrose/Hameroff)
 */

import { LoggingUtils } from '../../utils/LoggingUtils';

/**
 * Cognitive metrics for pattern analysis between cycles
 */
export interface CognitiveMetrics {
  // Core metrics (always tracked)
  contradictionScore?: number;
  coherenceScore?: number;
  emotionalWeight?: number;
  
  // Extended thesis metrics
  archetypalStability?: number;
  cycleEntropy?: number;
  insightDepth?: number;
  phaseAngle?: number;
}

/**
 * Represents an emergent pattern detected across cognitive cycles
 */
export interface EmergentPattern {
  type: string;
  description: string;
  confidence: number;
  scientificFoundation: string;
  affectedMetrics: CognitiveMetrics;
  detectionTimestamp: string;
}

/**
 * Main analyzer for detecting emergent symbolic patterns
 */
export class SymbolicPatternAnalyzer {
  // Histories for cross-cycle analysis
  private contextHistory: string[] = [];
  private metricsHistory: CognitiveMetrics[] = [];
  
  // Maximum history size to prevent unbounded growth
  private readonly MAX_HISTORY_SIZE = 20;
  
  /**
   * Records context and metrics from the current cycle
   */
  public recordCyclicData(
    context: string, 
    metrics: CognitiveMetrics
  ): void {
    // Maintain bounded history size
    if (this.contextHistory.length >= this.MAX_HISTORY_SIZE) {
      this.contextHistory.shift();
      this.metricsHistory.shift();
    }
    
    this.contextHistory.push(context);
    this.metricsHistory.push(metrics);
    
    LoggingUtils.logInfo(`[SymbolicPatternAnalyzer] Recorded cycle data (history size: ${this.contextHistory.length})`);
  }
  
  /**
   * Detects symbolic drift between consecutive contexts
   */
  private detectSymbolicDrift(): EmergentPattern | null {
    if (this.contextHistory.length < 2) return null;
    
    const current = this.contextHistory[this.contextHistory.length - 1];
    const previous = this.contextHistory[this.contextHistory.length - 2];
    
    // Basic detection via direct difference
    // In production: use embedding distance or more sophisticated measures
    if (current !== previous) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'symbolic_drift',
        description: 'Symbolic drift detected: significant context change between cycles',
        confidence: 0.85,
        scientificFoundation: 'Neural Darwinism (Edelman) & Embodied Mind (Varela)',
        affectedMetrics: currentMetrics,
        detectionTimestamp: new Date().toISOString()
      };
    }
    
    return null;
  }
  
  /**
   * Detects contradiction loops (persistent high contradiction)
   */
  private detectContradictionLoop(
    threshold: number = 0.7,
    minConsecutive: number = 3
  ): EmergentPattern | null {
    if (this.metricsHistory.length < minConsecutive) return null;
    
    const recentMetrics = this.metricsHistory.slice(-minConsecutive);
    const allHighContradiction = recentMetrics.every(m => 
      (m.contradictionScore ?? 0) > threshold
    );
    
    if (allHighContradiction) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'contradiction_loop',
        description: 'Contradiction loop detected: persistent high contradiction across cycles',
        confidence: 0.9,
        scientificFoundation: 'Cognitive Dissonance Theory (Festinger)',
        affectedMetrics: currentMetrics,
        detectionTimestamp: new Date().toISOString()
      };
    }
    
    return null;
  }
  
  /**
   * Detects narrative buildup (increasing coherence)
   */
  private detectNarrativeBuildup(
    minConsecutive: number = 3
  ): EmergentPattern | null {
    if (this.metricsHistory.length < minConsecutive) return null;
    
    const recentMetrics = this.metricsHistory.slice(-minConsecutive);
    let isIncreasing = true;
    
    for (let i = 1; i < recentMetrics.length; i++) {
      const current = recentMetrics[i].coherenceScore ?? 0;
      const previous = recentMetrics[i-1].coherenceScore ?? 0;
      if (current <= previous) {
        isIncreasing = false;
        break;
      }
    }
    
    if (isIncreasing) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'narrative_buildup',
        description: 'Narrative buildup detected: increasing coherence across cycles',
        confidence: 0.8,
        scientificFoundation: 'Acts of Meaning (Bruner)',
        affectedMetrics: currentMetrics,
        detectionTimestamp: new Date().toISOString()
      };
    }
    
    return null;
  }
  
  /**
   * Detects phase interference patterns
   */
  private detectPhaseInterference(): EmergentPattern | null {
    // Need at least 3 cycles with phase data to detect interference
    if (this.metricsHistory.length < 3) return null;
    
    const recentMetrics = this.metricsHistory.slice(-3);
    const hasPhaseData = recentMetrics.every(m => m.phaseAngle !== undefined);
    
    if (!hasPhaseData) return null;
    
    // Simplified detection of interference patterns
    const phases = recentMetrics.map(m => m.phaseAngle!);
    const phaseDeltas = [
      Math.abs(phases[1] - phases[0]), 
      Math.abs(phases[2] - phases[1])
    ];
    
    // Detect regular oscillation pattern
    const hasRegularPattern = Math.abs(phaseDeltas[1] - phaseDeltas[0]) < 0.15;
    
    if (hasRegularPattern) {
      const currentMetrics = this.metricsHistory[this.metricsHistory.length - 1];
      return {
        type: 'phase_interference',
        description: 'Phase interference detected: quantum-like oscillatory pattern',
        confidence: 0.7,
        scientificFoundation: 'Orchestrated Objective Reduction (Penrose/Hameroff)',
        affectedMetrics: currentMetrics,
        detectionTimestamp: new Date().toISOString()
      };
    }
    
    return null;
  }
  
  /**
   * Main analysis method to detect all emergent patterns
   */
  public analyzePatterns(): EmergentPattern[] {
    const patterns: EmergentPattern[] = [];
    
    try {
      // Run all detectors and collect non-null results
      const drift = this.detectSymbolicDrift();
      if (drift) patterns.push(drift);
      
      const contradiction = this.detectContradictionLoop();
      if (contradiction) patterns.push(contradiction);
      
      const narrative = this.detectNarrativeBuildup();
      if (narrative) patterns.push(narrative);
      
      const phase = this.detectPhaseInterference();
      if (phase) patterns.push(phase);
      
      if (patterns.length > 0) {
        LoggingUtils.logInfo(`[SymbolicPatternAnalyzer] Detected ${patterns.length} emergent patterns`);
      }
      
      return patterns;
    } catch (error) {
      LoggingUtils.logError(`[SymbolicPatternAnalyzer] Error analyzing patterns: ${error}`);
      return [];
    }
  }
  
  /**
   * Converte padrões emergentes detectados em formato de string para logging
   * e para incorporação nas propriedades emergentes do sistema.
   * 
   * @param patterns Lista de padrões emergentes detectados
   * @returns Array de strings descritivas dos padrões
   */
  public formatPatterns(patterns: EmergentPattern[]): string[] {
    return patterns.map(pattern => {
      const confidencePct = Math.round(pattern.confidence * 100);
      return `${pattern.type.toUpperCase()}: ${pattern.description} (${confidencePct}% confidence)`;
    });
  }
  
  /**
   * Clears all stored history (useful for session resets)
   */
  public clearHistory(): void {
    this.contextHistory = [];
    this.metricsHistory = [];
    LoggingUtils.logInfo('[SymbolicPatternAnalyzer] History cleared');
  }
}// SPDX-License-Identifier: MIT OR Apache-2.0
// Copyright (c) 2025 Guilherme Ferrari Brescia

/**
 * Exportation of components for detection and analysis of emergent symbolic patterns
 */

export * from './SymbolicPatternAnalyzer';