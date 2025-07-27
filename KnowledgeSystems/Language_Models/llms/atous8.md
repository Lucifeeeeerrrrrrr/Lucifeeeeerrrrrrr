
async fn get_energy_metrics(state: Arc<ApiState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    
    let node_ids = vec!["node-1", "node-2", "local"];
    let mut nodes = Vec::new();
    let mut average_energy_saved = 0.0;
    
    for node_id in node_ids {
        if let Some(metrics) = energy_manager.get_latest_node_metrics(node_id).await {
            let node_metrics = EnergyMetricsResponse {
                node_id: node_id.to_string(),
                current_consumption: metrics.current_consumption,
                total_savings: metrics.total_savings,
                history: metrics.history.clone(),
                forecast: metrics.forecast,
                last_updated: metrics.last_updated,
                active_connections: metrics.active_connections,
            };
            
            average_energy_saved += metrics.current_consumption;
            nodes.push(node_metrics);
        }
    }
    
    if !nodes.is_empty() {
        average_energy_saved /= nodes.len() as f64;
    }
    
    let response = NetworkEnergyResponse {
        average_energy_saved,
        node_count: nodes.len(),
        nodes,
    };
    
    Ok(warp::reply::json(&response))
}

async fn get_total_energy_saved(state: Arc<ApiState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    let total_saved = energy_manager.get_total_energy_saved().await;
    
    Ok(warp::reply::json(&serde_json::json!({
        "energy_saved_percent": total_saved,
    })))
}

async fn get_node_status(node_id: String, state: Arc<ApiState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    
    let node_metrics = match energy_manager.get_latest_node_metrics(&node_id).await {
        Some(metrics) => EnergyMetricsResponse {
            node_id: node_id.to_string(),
            current_consumption: metrics.current_consumption,
            total_savings: metrics.total_savings,
            history: metrics.history.clone(),
            forecast: metrics.forecast,
            last_updated: metrics.last_updated,
            active_connections: metrics.active_connections,
        },
        None => {
            return Ok(warp::reply::json(&serde_json::json!({
                "error": "Node not found",
                "node_id": node_id
            })));
        }
    };
    
    Ok(warp::reply::json(&node_metrics))
}

#[tokio::main]
async fn main() {
    env_logger::init();
    
    info!("Starting Energy API Demo");
    
    // Initialize the energy manager
    let mut energy_manager = EnergyManager::new()
        .with_sampling_interval(Duration::from_secs(15))
        .with_low_power_threshold(0.7);
    
    // Simulate some metrics
    energy_manager.record_tx_bytes(1500);
    energy_manager.record_rx_bytes(2500);
    
    info!("Capturing initial metrics");
    energy_manager.capture_metrics("node-1", 8).await;
    energy_manager.capture_metrics("node-2", 12).await;
    energy_manager.capture_metrics("local", 5).await;
    
    // Setup API state
    let api_state = Arc::new(ApiState {
        energy_manager: Arc::new(Mutex::new(energy_manager)),
    });
    
    // Create API routes
    let api_state_clone = api_state.clone();
    let api_state_filter = warp::any().map(move || api_state_clone.clone());
    
    // Endpoint: GET /api/metrics/energy
    let energy_route = warp::path!("api" / "metrics" / "energy")
        .and(warp::get())
        .and(api_state_filter.clone())
        .and_then(get_energy_metrics);
    
    // Endpoint: GET /api/metrics/energy/total
    let energy_total_route = warp::path!("api" / "metrics" / "energy" / "total")
        .and(warp::get())
        .and(api_state_filter.clone())
        .and_then(get_total_energy_saved);
    
    // Endpoint: GET /api/node/:id/status
    let node_status_route = warp::path!("api" / "node" / String / "status")
        .and(warp::get())
        .and(api_state_filter.clone())
        .and_then(get_node_status);
    
    // Combine routes
    let routes = energy_route
        .or(energy_total_route)
        .or(node_status_route);
    
    // Start metrics collection loop in background
    let energy_mgr_clone = api_state.energy_manager.clone();
    tokio::spawn(async move {
        loop {
            debug!("Updating metrics...");
            let mut em = energy_mgr_clone.lock().await;
            em.capture_metrics("node-1", 8 + (rand::random::<f32>() * 5.0) as usize).await;
            em.capture_metrics("node-2", 12 + (rand::random::<f32>() * 8.0) as usize).await;
            em.capture_metrics("local", 5 + (rand::random::<f32>() * 3.0) as usize).await;
            em.record_tx_bytes(100 + (rand::random::<u64>() % 1000));
            em.record_rx_bytes(200 + (rand::random::<u64>() % 1500));
            
            // Update every 10 seconds
            tokio::time::sleep(Duration::from_secs(10)).await;
        }
    });
    
    // Start server
    let port = 8081;
    info!("Starting energy API server on http://localhost:{}", port);
    info!("Available endpoints:");
    info!("- GET /api/metrics/energy - All node energy metrics");
    info!("- GET /api/metrics/energy/total - Total energy saved");
    info!("- GET /api/node/{{id}}/status - Specific node status (node-1, node-2, local)");
    
    warp::serve(routes).run(([0, 0, 0, 0], port)).await;
} use network::energy_manager::{EnergyManager, EnergyMetrics};
use std::time::Duration;

#[tokio::main]
async fn main() {
    // Configurar logger básico
    env_logger::init();
    
    println!("Teste do Módulo de Economia de Energia");
    println!("=====================================");
    
    // Criar gerenciador de energia
    let mut energy_manager = EnergyManager::new()
        .with_sampling_interval(Duration::from_secs(10))
        .with_low_power_threshold(0.7);
        
    println!("Gerenciador de energia criado com sucesso");
    
    // Simular tráfego de rede
    energy_manager.record_tx_bytes(1500);
    energy_manager.record_rx_bytes(2500);
    
    println!("Tráfego registrado: TX={} bytes, RX={} bytes", 
             energy_manager.get_tx_bytes(), 
             energy_manager.get_rx_bytes());
    
    // Capturar métricas para dois nós
    let node1 = "node-1";
    let node2 = "node-2";
    
    let metrics1 = energy_manager.capture_metrics(node1, 15).await;
    let metrics2 = energy_manager.capture_metrics(node2, 25).await;
    
    println!("\nMétricas do Nó 1:");
    print_metrics(&metrics1);
    
    println!("\nMétricas do Nó 2:");
    print_metrics(&metrics2);
    
    // Obter economia total
    let total_saved = energy_manager.get_total_energy_saved().await;
    println!("\nEconomia total de energia na rede: {:.2}%", total_saved);
    
    // Recuperar métricas armazenadas
    let stored_metrics1 = energy_manager.get_latest_node_metrics(node1).await.unwrap();
    println!("\nMétricas armazenadas para o Nó 1:");
    print_metrics(&stored_metrics1);
    
    println!("\nTeste concluído com sucesso!");
}

fn print_metrics(metrics: &EnergyMetrics) {
    // Remove or comment out all lines that reference metrics.cpu_usage, metrics.memory_usage, metrics.network_tx_bytes, metrics.network_rx_bytes, metrics.energy_saved_percent
    // println!("  CPU: {:.2}%", metrics.cpu_usage);
    // println!("  Memória: {:.2} MB", metrics.memory_usage);
    // println!("  Tráfego TX: {} bytes", metrics.network_tx_bytes);
    // println!("  Tráfego RX: {} bytes", metrics.network_rx_bytes);
    println!("  Conexões ativas: {}", metrics.active_connections);
    // println!("  Economia de energia: {:.2}%", metrics.energy_saved_percent);
} use network::energy_manager::EnergyManager;
use std::time::Duration;
use std::sync::Arc;
use warp::{Filter, Rejection, Reply};
use tokio::sync::Mutex;
use serde::Serialize;
use log::{info, debug};
use chrono;

#[derive(Debug, Clone, Serialize)]
struct EnergyMetricsResponse {
    node_id: String,
    current_consumption: f64,
    total_savings: f64,
    history: Vec<f64>,
    forecast: Option<f64>,
    last_updated: chrono::DateTime<chrono::Utc>,
    active_connections: usize,
}

#[derive(Debug, Clone, Serialize)]
struct NetworkEnergyResponse {
    average_energy_saved: f64,
    node_count: usize,
    nodes: Vec<EnergyMetricsResponse>,
}

// State wrapper
struct AppState {
    energy_manager: Arc<Mutex<EnergyManager>>,
}

// Handler functions with proper type signatures
async fn get_energy_metrics(state: Arc<AppState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    
    // Simulate nodes
    let node_ids = vec!["node-1", "node-2", "local"];
    let mut nodes = Vec::new();
    let mut average_energy_saved = 0.0;
    
    for node_id in node_ids {
        if let Some(metrics) = energy_manager.get_latest_node_metrics(node_id).await {
            let node_metrics = EnergyMetricsResponse {
                node_id: node_id.to_string(),
                current_consumption: metrics.current_consumption,
                total_savings: metrics.total_savings,
                history: metrics.history.clone(),
                forecast: metrics.forecast,
                last_updated: metrics.last_updated,
                active_connections: metrics.active_connections,
            };
            
            average_energy_saved += metrics.current_consumption;
            nodes.push(node_metrics);
        }
    }
    
    if !nodes.is_empty() {
        average_energy_saved /= nodes.len() as f64;
    }
    
    let response = NetworkEnergyResponse {
        average_energy_saved,
        node_count: nodes.len(),
        nodes,
    };
    
    Ok(warp::reply::json(&response))
}

async fn get_total_energy_saved(state: Arc<AppState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    let total_saved = energy_manager.get_total_energy_saved().await;
    
    Ok(warp::reply::json(&serde_json::json!({
        "energy_saved_percent": total_saved,
    })))
}

async fn get_node_status(node_id: String, state: Arc<AppState>) -> Result<impl Reply, Rejection> {
    let energy_manager = state.energy_manager.lock().await;
    
    let node_metrics = match energy_manager.get_latest_node_metrics(&node_id).await {
        Some(metrics) => EnergyMetricsResponse {
            node_id: node_id.to_string(),
            current_consumption: metrics.current_consumption,
            total_savings: metrics.total_savings,
            history: metrics.history.clone(),
            forecast: metrics.forecast,
            last_updated: metrics.last_updated,
            active_connections: metrics.active_connections,
        },
        None => {
            return Ok(warp::reply::json(&serde_json::json!({
                "error": "Node not found",
                "node_id": node_id
            })));
        }
    };
    
    Ok(warp::reply::json(&node_metrics))
}

// Filter creation helper function that properly handles type inference
fn with_state(state: Arc<AppState>) -> impl Filter<Extract = (Arc<AppState>,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || state.clone())
}

#[tokio::main]
async fn main() {
    // Initialize logger
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    info!("Starting Energy API Demo");
    
    // Initialize the energy manager
    let mut energy_manager = EnergyManager::new()
        .with_sampling_interval(Duration::from_secs(15))
        .with_low_power_threshold(0.7);
    
    // Simulate some metrics
    energy_manager.record_tx_bytes(1500);
    energy_manager.record_rx_bytes(2500);
    
    // Capture metrics for different nodes
    info!("Capturing initial metrics");
    energy_manager.capture_metrics("node-1", 8).await;
    energy_manager.capture_metrics("node-2", 12).await;
    energy_manager.capture_metrics("local", 5).await;
    
    // Setup API state
    let app_state = Arc::new(AppState {
        energy_manager: Arc::new(Mutex::new(energy_manager)),
    });
    
    // Route for energy metrics
    let energy_metrics_route = warp::path!("api" / "metrics" / "energy")
        .and(warp::get())
        .and(with_state(app_state.clone()))
        .and_then(get_energy_metrics);
    
    // Route for total energy saved
    let energy_total_route = warp::path!("api" / "metrics" / "energy" / "total")
        .and(warp::get())
        .and(with_state(app_state.clone()))
        .and_then(get_total_energy_saved);
    
    // Route for node status
    let node_status_route = warp::path!("api" / "node" / String / "status")
        .and(warp::get())
        .and(with_state(app_state.clone()))
        .and_then(|id, state| async move {
            get_node_status(id, state).await
        });
    
    // Combine all routes
    let routes = energy_metrics_route
        .or(energy_total_route)
        .or(node_status_route);
    
    // Start background metrics update task
    let energy_mgr_clone = app_state.energy_manager.clone();
    tokio::spawn(async move {
        loop {
            debug!("Updating metrics...");
            let mut em = energy_mgr_clone.lock().await;
            
            // Update with slightly random values to simulate changes
            let r = rand::random::<f32>();
            em.capture_metrics("node-1", 8 + (r * 5.0) as usize).await;
            em.capture_metrics("node-2", 12 + (r * 8.0) as usize).await;
            em.capture_metrics("local", 5 + (r * 3.0) as usize).await;
            em.record_tx_bytes(100 + (rand::random::<u64>() % 1000));
            em.record_rx_bytes(200 + (rand::random::<u64>() % 1500));
            
            tokio::time::sleep(Duration::from_secs(10)).await;
        }
    });
    
    // Start the server
    let port = 8081;
    info!("Starting energy API server on http://localhost:{}", port);
    info!("Available endpoints:");
    info!("- GET /api/metrics/energy - All node energy metrics");
    info!("- GET /api/metrics/energy/total - Total energy saved");
    info!("- GET /api/node/{{id}}/status - Specific node status (try: node-1, node-2, local)");
    
    warp::serve(routes).run(([0, 0, 0, 0], port)).await;
} use anyhow::Result;
use libp2p::PeerId;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use yrs::{
    Doc,
    Text,
    Transact,
    StateVector,
    Update,
    ReadTxn,
    types::text::TextRef,
    updates::decoder::Decode,
    GetString,
};

#[derive(Debug, Serialize, Deserialize)]
pub enum CrdtOperation {
    /// Atualização de texto colaborativo
    TextUpdate {
        doc_id: String,
        update: Vec<u8>, // Encoded CRDT update
    },
    /// Solicitação de sincronização
    SyncRequest {
        doc_id: String,
        #[serde(with = "peer_id_serde")]
        from_peer: PeerId,
    },
    /// Resposta de sincronização
    SyncResponse {
        doc_id: String,
        state: Vec<u8>, // Full state
    },
}

// Módulo para serialização/deserialização personalizada de PeerId
mod peer_id_serde {
    use libp2p::PeerId;
    use serde::{Deserialize, Deserializer, Serializer};
    use std::str::FromStr;

    pub fn serialize<S>(peer_id: &PeerId, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&peer_id.to_string())
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<PeerId, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        PeerId::from_str(&s).map_err(serde::de::Error::custom)
    }
}

/// Gerenciador CRDT mantém documentos e sincroniza via gossipsub
pub struct CrdtManager {
    docs: HashMap<String, Doc>,
}

impl CrdtManager {
    /// Criar um novo gerenciador CRDT
    pub fn new() -> Self {
        Self {
            docs: HashMap::new(),
        }
    }
    
    /// Criar ou obter um documento existente
    pub fn get_or_create_document(&mut self, doc_id: &str) -> &Doc {
        if !self.docs.contains_key(doc_id) {
            let doc = Doc::new();
            self.docs.insert(doc_id.to_string(), doc);
        }
        self.docs.get(doc_id).unwrap()
    }
    
    /// Aplicar uma atualização local a um documento
    pub fn apply_local_update<F>(&mut self, doc_id: &str, _f: F) -> Result<Vec<u8>> 
    where 
        F: FnOnce(&mut TextRef)
    {
        let doc = self.get_or_create_document(doc_id);
        
        let update = {
            let mut txn = doc.transact_mut();
            
            // Get or create the text
            let text_ref = txn.get_text("text").unwrap();
            text_ref.insert(&mut txn, 0, "your string");
            
            // Get the update
            let state_vector = StateVector::default();
            txn.encode_state_as_update_v1(&state_vector).to_vec()
        };
        
        Ok(update)
    }
    
    /// Aplicar uma atualização remota a um documento
    pub fn apply_remote_update(&mut self, doc_id: &str, update: &[u8]) -> Result<()> {
        let doc = self.get_or_create_document(doc_id);
        
        let mut txn = doc.transact_mut();
        txn.apply_update(Update::decode_v1(update)?);
        
        Ok(())
    }
    
    /// Solicitar sincronização completa
    pub fn request_sync(&mut self, _doc_id: &str) -> Result<()> {
        // Implementation needed
        Ok(())
    }
    
    /// Processar mensagem recebida
    pub fn process_message(&mut self, _from_peer: PeerId, message: &[u8]) -> Result<()> {
        // Here we would process incoming CRDT messages
        // For now just apply the update directly
        self.apply_remote_update("default", message)
    }
    
    pub fn get_text(&self, doc_id: &str) -> Option<String> {
        self.docs.get(doc_id).map(|doc| {
            let txn = doc.transact();
            let text = txn.get_text("text");
            text.map(|t| t.get_string(&txn)).unwrap_or_default()
        })
    }
}
use super::CrdtManager;
use anyhow::Result;

pub struct CollaborativeText<'a> {
    manager: &'a mut CrdtManager,
    doc_id: String,
}

impl<'a> CollaborativeText<'a> {
    /// Criar uma nova instância
    pub fn new(manager: &'a mut CrdtManager, doc_id: &str) -> Self {
        Self {
            manager,
            doc_id: doc_id.to_string(),
        }
    }
    
    /// Inserir texto em uma posição
    pub fn insert(&mut self, index: u32, text: &str) -> Result<()> {
        self.manager.apply_local_update(&self.doc_id, |txt| {
            txt.insert(index, text);
        })
    }
    
    /// Deletar texto em um intervalo
    pub fn delete(&mut self, index: u32, length: u32) -> Result<()> {
        self.manager.apply_local_update(&self.doc_id, |txt| {
            txt.delete(index, length);
        })
    }
    
    /// Obter o texto atual
    pub fn get_text(&mut self) -> String {
        let doc = self.manager.get_or_create_document(&self.doc_id);
        
        let txn = doc.transact();
        let text = txn.get_text("text").unwrap();
        text.to_string()
    }
    
    /// Solicitar sincronização com a rede
    pub fn sync(&mut self) -> Result<()> {
        self.manager.request_sync(&self.doc_id)
    }
}use std::time::Duration;
use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::RwLock;
use std::sync::atomic::{AtomicU64, Ordering};
use log::{debug, info};
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnergyMetrics {
    pub current_consumption: f64,
    pub total_savings: f64,
    pub history: Vec<f64>,
    pub forecast: Option<f64>,
    pub last_updated: chrono::DateTime<chrono::Utc>,
    pub active_connections: usize,
}

impl Default for EnergyMetrics {
    fn default() -> Self {
        Self {
            current_consumption: 0.0,
            total_savings: 0.0,
            history: Vec::new(),
            forecast: None,
            last_updated: chrono::Utc::now(),
            active_connections: 0,
        }
    }
}
pub struct EnergyManager {
    tx_bytes: AtomicU64,
    rx_bytes: AtomicU64,
    node_metrics: Arc<RwLock<HashMap<String, Vec<EnergyMetrics>>>>,
    sampling_interval: Duration,
    low_power_threshold: f64,
    low_power_mode: bool,
    #[allow(dead_code)]
    baseline_metrics: Option<EnergyMetrics>,
}

impl EnergyManager {
    pub fn new() -> Self {
        Self {
            tx_bytes: AtomicU64::new(0),
            rx_bytes: AtomicU64::new(0),
            node_metrics: Arc::new(RwLock::new(HashMap::new())),
            sampling_interval: Duration::from_secs(60), 
            low_power_threshold: 0.7, 
            low_power_mode: false,
            baseline_metrics: None,
        }
    }

    pub fn with_sampling_interval(mut self, interval: Duration) -> Self {
        self.sampling_interval = interval;
        self
    }
    
    pub fn with_low_power_threshold(mut self, threshold: f64) -> Self {
        self.low_power_threshold = threshold.clamp(0.0, 1.0);
        self
    }
    
    pub fn record_tx_bytes(&self, bytes: u64) {
        self.tx_bytes.fetch_add(bytes, Ordering::Relaxed);
    }
    
    pub fn record_rx_bytes(&self, bytes: u64) {
        self.rx_bytes.fetch_add(bytes, Ordering::Relaxed);
    }
    
    pub fn get_tx_bytes(&self) -> u64 {
        self.tx_bytes.load(Ordering::Relaxed)
    }
    
    pub fn get_rx_bytes(&self) -> u64 {
        self.rx_bytes.load(Ordering::Relaxed)
    }
    
    /// Capturar métricas do sistema atual
    pub async fn capture_metrics(&mut self, node_id: &str, active_connections: usize) -> EnergyMetrics {
        let cpu_usage = self.get_system_cpu_usage();
        let memory_usage = self.get_system_memory_usage();
        
        let _tx_bytes = self.tx_bytes.load(Ordering::Relaxed);
        let _rx_bytes = self.rx_bytes.load(Ordering::Relaxed);
        
        // Calcula a economia de energia com base no modo atual
        let energy_saved = if self.low_power_mode {
            // Simplificação: assumimos economia de 20% em modo de baixo consumo
            20.0
        } else {
            // Energia economizada é proporcional à diferença entre uso máximo e atual
            let baseline = 100.0; // Consumo de energia de referência (100%)
            let current_usage = 0.5 * cpu_usage + 0.3 * (memory_usage / 1000.0) + 
                              0.2 * (active_connections as f64 / 100.0);
            
            (baseline - current_usage).max(0.0)
        };
        
        let metrics = EnergyMetrics {
            current_consumption: cpu_usage,
            total_savings: energy_saved,
            history: Vec::new(),
            forecast: None,
            last_updated: chrono::Utc::now(),
            active_connections,
        };
        
        // Atualiza o modo de economia baseado no uso atual
        // Movido para antes de adquirir o lock para evitar problemas de borrowing
        self.update_power_mode(cpu_usage);
        
        // Armazena as métricas no histórico
        let mut node_metrics = self.node_metrics.write().await;
        let metrics_history = node_metrics.entry(node_id.to_string()).or_insert_with(Vec::new);
        metrics_history.push(metrics.clone());
        
        // Limita o histórico a 1000 amostras por nó
        if metrics_history.len() > 1000 {
            metrics_history.remove(0);
        }
        
        metrics
    }
    
    /// Atualiza o modo de energia baseado na carga do sistema
    fn update_power_mode(&mut self, cpu_usage: f64) {
        let should_be_low_power = cpu_usage > self.low_power_threshold;
        
        if should_be_low_power != self.low_power_mode {
            self.low_power_mode = should_be_low_power;
            if self.low_power_mode {
                info!("Ativando modo de economia de energia devido a alta carga (CPU: {:.1}%)", cpu_usage);
            } else {
                info!("Desativando modo de economia de energia (CPU: {:.1}%)", cpu_usage);
            }
        }
    }
    
    fn get_system_cpu_usage(&self) -> f64 {
        45.0 + rand::random::<f64>() * 10.0 
    }
    
    fn get_system_memory_usage(&self) -> f64 {
        // MVP: simulação simplificada
        // TODO: Implementar medição real com sys-info ou similar
        500.0 + rand::random::<f64>() * 200.0 // Entre 500MB e 700MB
    }
    
    pub async fn get_node_metrics(&self, node_id: &str) -> Option<Vec<EnergyMetrics>> {
        let node_metrics = self.node_metrics.read().await;
        node_metrics.get(node_id).cloned()
    }
    
    pub async fn get_latest_node_metrics(&self, node_id: &str) -> Option<EnergyMetrics> {
        let node_metrics = self.node_metrics.read().await;
        node_metrics.get(node_id).and_then(|metrics| metrics.last().cloned())
    }
    pub async fn get_total_energy_saved(&self) -> f64 {
        let node_metrics = self.node_metrics.read().await;
        let mut total_saved = 0.0;
        let mut node_count = 0;
        
        for metrics_vec in node_metrics.values() {
            if let Some(latest) = metrics_vec.last() {
                total_saved += latest.total_savings;
                node_count += 1;
            }
        }
        
        if node_count > 0 {
            total_saved / node_count as f64
        } else {
            0.0
        }
    }

    pub async fn start_monitoring(&self, node_id: String) {
        let _node_metrics = self.node_metrics.clone();
        let sampling_interval = self.sampling_interval;
        
        tokio::spawn(async move {
            loop {
                // No MVP, isto é apenas um espaço reservado
                // Na implementação real, capturaria métricas regularmente
                tokio::time::sleep(sampling_interval).await;
                
                debug!("Coleta periódica de métricas para o nó {}", node_id);
                // Aqui capturaria métricas de fato e atualizaria no histórico
            }
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::sleep;
    
    #[tokio::test]
    async fn test_record_network_traffic() {
        let manager = EnergyManager::new();
        
        manager.record_tx_bytes(1000);
        manager.record_rx_bytes(2000);
        
        assert_eq!(manager.get_tx_bytes(), 1000);
        assert_eq!(manager.get_rx_bytes(), 2000);
        
        manager.record_tx_bytes(500);
        manager.record_rx_bytes(700);
        
        assert_eq!(manager.get_tx_bytes(), 1500);
        assert_eq!(manager.get_rx_bytes(), 2700);
    }
    
    #[tokio::test]
    async fn test_capture_metrics() {
        let mut manager = EnergyManager::new();
        
        let node_id = "test-node-1";
        let metrics = manager.capture_metrics(node_id, 10).await;
        
        assert!(metrics.current_consumption > 0.0);
        assert!(metrics.total_savings > 0.0);
        assert_eq!(metrics.active_connections, 10);
        
        let stored_metrics = manager.get_node_metrics(node_id).await.unwrap();
        assert_eq!(stored_metrics.len(), 1);
        
        let metrics2 = manager.capture_metrics(node_id, 15).await;
        assert_eq!(metrics2.active_connections, 15);
        
        let stored_metrics = manager.get_node_metrics(node_id).await.unwrap();
        assert_eq!(stored_metrics.len(), 2);
    }
    
    #[tokio::test]
    async fn test_get_latest_node_metrics() {
        let mut manager = EnergyManager::new();
        
        let node_id = "test-node-2";
        
        assert!(manager.get_latest_node_metrics(node_id).await.is_none());
        
        manager.capture_metrics(node_id, 5).await;
        sleep(Duration::from_millis(10)).await;
        let metrics2 = manager.capture_metrics(node_id, 10).await;
        
        let latest = manager.get_latest_node_metrics(node_id).await.unwrap();
        
        assert_eq!(latest.active_connections, metrics2.active_connections);
    }
    
    #[tokio::test]
    async fn test_total_energy_saved() {
        let mut manager = EnergyManager::new();
        
        assert_eq!(manager.get_total_energy_saved().await, 0.0);
        
        // Adiciona métricas para dois nós

        manager.capture_metrics("node-1", 10).await;
        manager.capture_metrics("node-2", 20).await;
        
        let total_saved = manager.get_total_energy_saved().await;
        assert!(total_saved > 0.0);
    }
} use anyhow::Result;
use libp2p::{
    core::transport::{OrTransport, Transport},
    identity::Keypair,
    PeerId,
    StreamMuxerBox,
};
use super::{quic, tcp};

pub async fn build_transport_with_fallback(
    local_key: &Keypair,
) -> Result<impl Transport<Output = (PeerId, StreamMuxerBox)> + Clone> {
    // Construir transporte QUIC (primeira opção)
    let quic_transport = quic::build_quic_transport(local_key).await?;
    
    // Construir transporte TCP (fallback)
    let tcp_transport = tcp::build_tcp_transport(local_key)?;
    
    // Combinar os transportes com fallback automático
    let transport = OrTransport::new(quic_transport, tcp_transport)
        .boxed();
        
    Ok(transport)
}mod quic;
mod tcp;
mod fallback;

pub use quic::build_quic_transport;
pub use tcp::build_tcp_transport;
pub use fallback::build_fallback_transport;
pub use fallback::build_transport_with_fallback;

use anyhow::Result;
use libp2p::{
    core::transport::Transport, 
    identity::Keypair, 
    StreamMuxerBox
};

/// Constrói um transporte compatível com o libp2p
pub async fn build_transport(
    local_key: &Keypair,
    enable_quic: bool,
) -> Result<impl Transport<Output = (libp2p::PeerId, StreamMuxerBox)> + Clone> {
    if enable_quic {
        build_quic_transport(local_key).await
    } else {
        build_tcp_transport(local_key)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use libp2p::PeerId;
    
    #[tokio::test]
    async fn test_build_transport_tcp() {
        let local_key = Keypair::generate_ed25519();
        let transport = build_transport(&local_key, false).await.unwrap();
        assert!(transport.boxed() != None);
    }
    
    #[tokio::test]
    async fn test_build_transport_quic() {
        let local_key = Keypair::generate_ed25519();
        let transport = build_transport(&local_key, true).await.unwrap();
        assert!(transport.boxed() != None);
    }
}use anyhow::Result;
use libp2p::{
    core::transport::Transport,
    identity::Keypair,
    quic,
    PeerId,
    StreamMuxerBox,
};

pub async fn build_quic_transport(
    local_key: &Keypair,
) -> Result<impl Transport<Output = (PeerId, StreamMuxerBox)> + Clone> {
    // Configuração básica do QUIC
    let quic_config = quic::Config::new(local_key);
    
    // Construir o transporte
    let transport = quic::tokio::Transport::new(quic_config)
        .map(|(peer_id, conn)| (peer_id, StreamMuxerBox::new(conn)))
        .boxed();
        
    Ok(transport)
}
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_build_tcp_transport() {
        let local_key = Keypair::generate_ed25519();
        let transport = build_tcp_transport(&local_key).unwrap();
        assert!(transport != None);
    }
}// Em network/src/transport/tcp.rs

use anyhow::Result;
use libp2p::{
    core::upgrade,
    identity::Keypair,
    noise::{NoiseConfig, X25519Spec, Keypair as NoiseKeys},
    tcp::TokioTcpConfig,
    yamux::YamuxConfig,
    Transport,
};

/// Constrói um transporte TCP
pub fn build_tcp_transport(
    local_key: &Keypair,
) -> Result<impl Transport<Output = (libp2p::PeerId, libp2p::StreamMuxerBox)> + Clone> {
    let noise_keys = NoiseKeys::<X25519Spec>::new()
        .into_authentic(local_key)?;
        
    let transport = TokioTcpConfig::new()
        .nodelay(true)
        .upgrade(upgrade::Version::V1)
        .authenticate(NoiseConfig::xx(noise_keys).into_authenticated())
        .multiplex(YamuxConfig::default())
        .boxed();
        
    Ok(transport)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_build_tcp_transport() {
        let local_key = Keypair::generate_ed25519();
        let transport = build_tcp_transport(&local_key).unwrap();
        assert!(transport != None);
    }
}use libp2p::{
    gossipsub::{
        Behaviour as Gossipsub, ConfigBuilder as GossipsubConfigBuilder, MessageAuthenticity,
        ValidationMode, Event as GossipsubEvent, 
        IdentTopic as Topic, MessageId
    },
    kad::{store::MemoryStore, Behaviour as Kademlia, Config as KademliaConfig, 
          Event as KademliaEvent, QueryId, Record, RecordKey, store::RecordStore},
    mdns::{tokio::Behaviour as Mdns, Config as MdnsConfig, Event as MdnsEvent},
    swarm::NetworkBehaviour,
    identify::{Behaviour as Identify, Config as IdentifyConfig, Event as IdentifyEvent},
    PeerId, identity::Keypair
};
use anyhow::{Result, anyhow};
use std::collections::HashMap;
use std::time::Duration;
use log::{debug, info};

/// Events that can be emitted by the P2P behavior
#[derive(Debug)]
pub enum Event {
    Mdns(MdnsEvent),
    Kademlia(KademliaEvent),
    Gossipsub(GossipsubEvent),
    Identify(IdentifyEvent),
    PeerDiscovered(PeerId),
    PeerDisconnected(PeerId),
    RecordReceived(Vec<u8>, Vec<u8>), // key, value
    MessageReceived(String, Vec<u8>, PeerId), // topic, data, source
}

impl From<MdnsEvent> for Event { 
    fn from(ev: MdnsEvent) -> Self { 
        match ev {
            MdnsEvent::Discovered(peers) => {
                debug!("mDNS discovered {} peers", peers.len());
                Event::PeerDiscovered(peers[0].0)
            },
            MdnsEvent::Expired(peers) => {
                debug!("mDNS expired {} peers", peers.len());
                Event::PeerDisconnected(peers[0].0)
            }
        }
    } 
}

impl From<KademliaEvent> for Event { 
    fn from(ev: KademliaEvent) -> Self { 
        match ev {
            KademliaEvent::OutboundQueryProgressed { ref result, .. } => {
                debug!("Kademlia query completed: {:?}", result);
                Event::Kademlia(ev)
            },
            _ => Event::Kademlia(ev)
        }
    }
}

impl From<GossipsubEvent> for Event { 
    fn from(ev: GossipsubEvent) -> Self { 
        match ev {
            GossipsubEvent::Message { 
                propagation_source,
                message_id,
                ref message 
            } => {
                debug!("Gossipsub received message from {:?}: {:?}", 
                    propagation_source, message_id);
                    
                Event::MessageReceived(
                    message.topic.as_str().to_string(),
                    message.data.clone(),
                    propagation_source
                )
            },
            _ => Event::Gossipsub(ev)
        }
    } 
}

impl From<IdentifyEvent> for Event {
    fn from(ev: IdentifyEvent) -> Self {
        Event::Identify(ev)
    }
}

/// P2P behavior combining mDNS, Kademlia and Gossipsub
#[derive(NetworkBehaviour)]
#[behaviour(out_event = "Event")]
pub struct P2PBehaviour {
    pub gossipsub: Gossipsub,
    pub kademlia: Kademlia<MemoryStore>,
    pub mdns: Mdns,
    pub identify: Identify,
}

impl P2PBehaviour {
    pub async fn new(local_peer_id: PeerId, local_key: Keypair) -> Result<(Self, HashMap<String, Topic>, HashMap<QueryId, RecordKey>)> {
        // Configure Kademlia
        let store = MemoryStore::new(local_peer_id);
        let kademlia_config = KademliaConfig::default();
        let kademlia = Kademlia::with_config(local_peer_id, store, kademlia_config);
        
        // Configure Gossipsub
        let gossipsub_config = GossipsubConfigBuilder::default()
            .heartbeat_interval(Duration::from_secs(10))
            .validation_mode(ValidationMode::Strict)
            .build()
            .expect("Valid config");
        let gossipsub = Gossipsub::new(MessageAuthenticity::Signed(local_key.clone()), gossipsub_config)
            .expect("Valid configuration");
            
        // Configure mDNS
        let mdns = Mdns::new(MdnsConfig::default(), local_peer_id)?;
            
        // Configure Identify
        let identify = Identify::new(IdentifyConfig::new(
            "/atous/1.0.0".into(),
            local_key.public(),
        ));
        
        Ok((Self {
            gossipsub,
            kademlia,
            mdns,
            identify,
        },
        HashMap::new(),
        HashMap::new()))
    }
    
    pub fn subscribe(&mut self, topic: &str) -> Result<bool> {
        let topic = Topic::new(topic);
        Ok(self.gossipsub.subscribe(&topic)?)
    }
    
    pub fn unsubscribe(&mut self, topic: &str) -> Result<bool> {
        let topic = Topic::new(topic);
        Ok(self.gossipsub.unsubscribe(&topic)?)
    }
    
    pub fn publish(&mut self, topic: &str, data: Vec<u8>) -> Result<MessageId> {
        let topic = Topic::new(topic);
        Ok(self.gossipsub.publish(topic, data)?)
    }
    
    pub fn bootstrap(&mut self) -> Result<QueryId> {
        info!("Starting DHT bootstrap");
        Ok(self.kademlia.bootstrap()?)
    }
    
    pub fn store_value(&mut self, key: Vec<u8>, value: Vec<u8>) -> Result<()> {
        let record = Record {
            key: RecordKey::new(&key),
            value,
            publisher: None,
            expires: None,
        };
        
        match self.kademlia.store_mut().put(record) {
            Ok(_) => Ok(()),
            Err(e) => Err(anyhow!("Failed to store value: {}", e)),
        }
    }
    
    pub fn get_value(&mut self, key: Vec<u8>) -> Result<Option<Vec<u8>>> {
        let record_key = RecordKey::new(&key);
        if let Some(record) = self.kademlia.store_mut().get(&record_key) {
            Ok(Some(record.value.clone()))
        } else {
            Ok(None)
        }
    }
}

use crate::transport::build_transport_with_fallback;

pub async fn build_swarm(local_key: &Keypair) -> Result<Swarm<P2PBehaviour>> {
    let peer_id = PeerId::from(local_key.public());
    
    // Usar o transporte com fallback (QUIC com fallback para TCP)
    let transport = build_transport_with_fallback(local_key).await?;
    
    // Construir o behaviour
    let behaviour = P2PBehaviour::new(peer_id, local_key);
    
    // Construir e retornar o swarm
    let swarm = SwarmBuilder::new(transport, behaviour, peer_id)
        .executor(Box::new(|fut| { tokio::spawn(fut); }))
        .build();   
    Ok(swarm)
}pub mod behaviour;fn start_node() {
    let rt = Runtime::new().unwrap();
    rt.block_on(async {
        let node = establish_connection().await;
        assert!(node.is_ok());
    });
}

#[derive(NetworkBehaviour)]
struct Behaviour {
    mdns: Mdns,
}

impl Behaviour {
    fn new() -> Self {
        Behaviour {
            mdns: Mdns::new(MdnsConfig::default()).expect("Unable to create Mdns instance"),
        }
    }
}

fn stop_node() {
    let rt = Runtime::new().unwrap();
    rt.block_on(async {
        let node = stop_connection().await;
        assert!(node.is_ok());
    });
}

fn establish_connection() -> Result<(), String> {
    let behaviour = Behaviour::new();
    let swarm = SwarmBuilder::new(behaviour, PeerId::random()).build();
    Ok(())
}use super::behaviour::{P2PBehaviour, Event, P2PState};
use libp2p::{identity, PeerId};
use std::time::Duration;

#[test]
fn test_p2p_behaviour_creation() {
    let keypair = identity::Keypair::generate_ed25519();
    let local_peer_id = PeerId::from(keypair.public());
    
    // This should compile if P2PBehaviour correctly implements NetworkBehaviour
    let (behaviour, state) = P2PBehaviour::new(local_peer_id, &keypair);
    
    // Get local_peer_id through the accessor method
    assert_eq!(behaviour.get_local_peer_id(&local_peer_id), local_peer_id);
}

#[test]
fn test_connected_peers() {
    let keypair = identity::Keypair::generate_ed25519();
    let local_peer_id = PeerId::from(keypair.public());
    
    let (mut behaviour, mut state) = P2PBehaviour::new(local_peer_id, &keypair);
    let peer_id = PeerId::random();
    
    // Test connected peers operations
    assert!(!behaviour.is_connected(&peer_id, &state));
    behaviour.add_connected_peer(peer_id, &mut state);
    assert!(behaviour.is_connected(&peer_id, &state));
    let connected = behaviour.connected_peers(&state);
    assert_eq!(connected.len(), 1);
    assert_eq!(connected[0], peer_id);
    
    // Test remove peer
    behaviour.remove_connected_peer(&peer_id, &mut state);
    assert!(!behaviour.is_connected(&peer_id, &state));
    assert_eq!(behaviour.connected_peers(&state).len(), 0);
}

#[test]
fn test_topic_operations() {
    let keypair = identity::Keypair::generate_ed25519();
    let local_peer_id = PeerId::from(keypair.public());
    
    let (mut behaviour, mut state) = P2PBehaviour::new(local_peer_id, &keypair);
    let topic_name = "test-topic";
    
    // First add topic without subscription
    let result = behaviour.add_topic(topic_name, false, &mut state);
    assert!(result.is_none()); // No error
    
    // Subscribe to the topic
    let result = behaviour.subscribe_to_topic(topic_name, &mut state);
    assert!(result.is_ok());
}

#[test]
fn test_dht_operations() {
    let keypair = identity::Keypair::generate_ed25519();
    let local_peer_id = PeerId::from(keypair.public());
    
    let (mut behaviour, mut state) = P2PBehaviour::new(local_peer_id, &keypair);
    
    // Test put record
    let key = b"test-key".to_vec();
    let value = b"test-value".to_vec();
    
    let result = behaviour.put_record(key.clone(), value.clone());
    assert!(result.is_ok());
    
    // Test get record
    let query_id = behaviour.get_record(key, &mut state);
    assert!(!query_id.is_zero());
}

#[cfg(test)]
mod tests {
    use super::behaviour::{P2PBehaviour, Event, P2PState};
    use libp2p::{identity::Keypair, PeerId, gossipsub::{IdentTopic, Topic}, kad::QueryId};
    use std::time::Duration;
    use log::{debug, info, warn};
    use std::sync::{Arc, Mutex};

    #[test]
    fn test_p2p_behaviour_peers() {
        let keypair = Keypair::generate_ed25519();
        let local_peer_id = PeerId::from(keypair.public());
        let (mut behaviour, shared_state) = P2PBehaviour::new(local_peer_id, &keypair);
        let peer_id = PeerId::random();
        
        // Test connection status
        {
            let state = shared_state.lock().unwrap();
            assert!(!behaviour.is_connected(&peer_id, &state));
        }
        
        // Add connected peer
        {
            let mut state = shared_state.lock().unwrap();
            behaviour.add_connected_peer(peer_id, &mut state);
        }
        
        // Check connection is recorded
        {
            let state = shared_state.lock().unwrap();
            assert!(behaviour.is_connected(&peer_id, &state));
            let connected = behaviour.connected_peers(&state);
            assert_eq!(connected.len(), 1);
            assert_eq!(connected[0], peer_id);
        }
        
        // Remove connected peer
        {
            let mut state = shared_state.lock().unwrap();
            behaviour.remove_connected_peer(&peer_id, &mut state);
        }
        
        // Check connection is removed
        {
            let state = shared_state.lock().unwrap();
# 🚀 Sistema Atous - Identidade Descentralizada & Comunicação Segura

![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)
![Security](https://img.shields.io/badge/security-hardened-green.svg)

O **Atous** é um sistema distribuído robusto de identidade descentralizada e comunicação segura construído em Rust, com foco em **segurança avançada**, performance e escalabilidade.

## ✨ Características Principais

- 🆔 **Identidade Descentralizada (DID)**: Sistema completo de gerenciamento de identidades
- 🌐 **Rede P2P**: Comunicação peer-to-peer usando libp2p com Gossipsub e Kademlia DHT
- ⛓️ **Blockchain**: Sistema de blockchain para transações e consenso distribuído
- 🔐 **Criptografia Pós-Quântica**: Algoritmos resistentes a ataques quânticos (Dilithium, ML-KEM)
- 🛡️ **Sistema de Flags**: Detecção e resposta automática a atividades suspeitas
- ⚡ **WebSocket**: Comunicação em tempo real bidirecional
- 🌍 **API REST**: Interface completa para todas as funcionalidades
- 📊 **Monitoramento**: Métricas Prometheus e dashboards Grafana

## 🔒 **SEGURANÇA AVANÇADA** *(Novo!)*

### **🛡️ Stack de Segurança Multicamada**

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY MIDDLEWARE STACK                │
├─────────────────────────────────────────────────────────────┤
│ 1. 📝 Logging & Normalization                              │
│ 2. 🌐 CORS Protection                                       │
│ 3. 🛡️ SYBIL PROTECTION (Max 2 nodes/IP, 2h window)        │
│ 4. 🔐 JWT AUTHENTICATION (Bearer token required)           │
│ 5. ⏱️ RATE LIMITING (10 req/min, 3 concurrent max)         │
│ 6. 🗜️ Compression                                           │
├─────────────────────────────────────────────────────────────┤
│ 🔒 PROTECTED ENDPOINTS:                                     │
│   • /api/flags    → Requires Bearer token                  │
│   • /api/metrics  → Requires Bearer token                  │
│   • /api/nodes    → Requires Bearer token                  │
│   • /admin/*      → Requires Bearer token                  │
├─────────────────────────────────────────────────────────────┤
│ 💾 PAYLOAD LIMITS:                                          │
│   • HTTP Body: 256KB max                                   │
│   • JSON: 256KB max                                        │
└─────────────────────────────────────────────────────────────┘
```

### **🎯 Proteções Implementadas**

- ✅ **Proteção Anti-Sybil**: Máximo 2 nós por endereço IP
- ✅ **Autenticação JWT**: Obrigatória para todos os endpoints API
- ✅ **Rate Limiting**: 10 requests/minuto, 3 conexões concorrentes
- ✅ **Proteção de Métricas**: Endpoint `/api/metrics` protegido por autenticação
- ✅ **Validação de Payload**: Limite de 256KB para prevenir ataques DoS
- ✅ **Validação de Assinatura**: Flags de segurança com assinatura obrigatória

## 🚀 Início Rápido

### Instalação em 3 Passos

```bash
# 1. Clone e compile
git clone https://github.com/seu-usuario/atous.git
cd atous
cargo build --release

# 2. Execute o sistema (com logs de segurança)
./target/release/atous-security-fixes

# 3. Teste com autenticação
curl -H "Authorization: Bearer valid_jwt_token" http://localhost:8081/api/flags
```

### ✅ Verificação Básica

```bash
# Teste sem autenticação (deve falhar com HTTP 401)
curl http://localhost:8081/api/flags
# Expected: HTTP 401 Unauthorized - Missing Authorization header

# Teste com autenticação válida
curl -H "Authorization: Bearer valid_jwt_token" http://localhost:8081/api/flags
# Expected: HTTP 200 OK com dados

# Teste de métricas protegidas
curl -H "Authorization: Bearer valid_jwt_token" http://localhost:8081/api/metrics
# Expected: HTTP 200 OK com métricas
```

### 🔐 Autenticação JWT

```bash
# Exemplo de request autenticado
curl -X POST http://localhost:8081/api/flags \
  -H "Authorization: Bearer valid_jwt_token" \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "description": "Teste", "enabled": true}'

# Para produção, use tokens JWT reais
# Para testes, use o token especial: "valid_jwt_token"
```

## 📚 Documentação Completa

### 📖 Guias Disponíveis

- **[🚀 Guia de Início Rápido](GUIA_INICIO_RAPIDO.md)** - Configure e execute em 5 minutos
- **[📋 Documentação Completa](DOCUMENTACAO_COMPLETA.md)** - Guia completo com todos os endpoints e funcionalidades
- **[🏗️ Guia do Sistema](GUIA_DO_SISTEMA.md)** - Arquitetura e componentes detalhados
- **[🔧 Guia Técnico](TECHNICAL_GUIDE.md)** - Informações técnicas avançadas

### 🎯 Casos de Uso

- **Monitoramento de Segurança**: Sistema de flags para detectar atividades suspeitas
- **Comunicação P2P**: Troca de mensagens seguras entre nós
- **Gestão de Identidade**: Criação e verificação de identidades descentralizadas
- **Auditoria**: Registro imutável de transações via blockchain

## 🛡️ API Endpoints Principais

> **⚠️ IMPORTANTE**: Todos os endpoints `/api/*` agora requerem autenticação JWT!

### 🔐 Autenticação Obrigatória
```bash
# Todas as requisições devem incluir o header Authorization
Authorization: Bearer <your_jwt_token>

# Para testes de desenvolvimento, use:
Authorization: Bearer valid_jwt_token
```

### Flags de Segurança 🚩
```bash
GET    /api/flags              # Listar todas as flags [AUTH REQUIRED]
POST   /api/flags              # Criar flag básica [AUTH REQUIRED]
POST   /api/flags/security     # Criar flag de segurança [AUTH REQUIRED]
GET    /api/flags/{id}          # Recuperar flag específica [AUTH REQUIRED]
```

### Métricas de Sistema 📊
```bash
GET    /api/metrics            # Métricas Prometheus [AUTH REQUIRED - NOVO!]
```

### Identidades (DIDs) 🆔
```bash
POST   /api/identities         # Criar nova identidade [AUTH REQUIRED]
GET    /api/identities/{did}   # Recuperar identidade [AUTH REQUIRED]
PUT    /api/identities/{did}   # Atualizar identidade [AUTH REQUIRED]
POST   /api/identities/search  # Buscar identidades [AUTH REQUIRED]
```

### Mensagens 💬
```bash
POST   /api/messages           # Enviar mensagem [AUTH REQUIRED]
GET    /api/messages           # Listar mensagens [AUTH REQUIRED]
GET    /api/messages/{id}      # Recuperar mensagem específica [AUTH REQUIRED]
```

### Blockchain ⛓️
```bash
GET    /api/blockchain/blocks          # Listar blocos [AUTH REQUIRED]
POST   /api/blockchain/transactions    # Submeter transação [AUTH REQUIRED]
GET    /api/blockchain/transactions/{hash} # Recuperar transação [AUTH REQUIRED]
```

### 🔒 Códigos de Resposta de Segurança

| Código | Descrição | Ação |
|--------|-----------|------|
| `401 Unauthorized` | Token JWT ausente ou inválido | Incluir header `Authorization: Bearer <token>` |
| `429 Too Many Requests` | Rate limiting ativado | Aguardar antes de nova tentativa |
| `429 Too Many Requests` | Proteção Sybil ativada | Muitos nós do mesmo IP |
| `413 Payload Too Large` | Payload > 256KB | Reduzir tamanho do payload |

### 📝 Exemplos de Uso com Autenticação

```bash
# ✅ Correto - Com autenticação
curl -H "Authorization: Bearer valid_jwt_token" \
     -X GET http://localhost:8081/api/flags

# ❌ Incorreto - Sem autenticação
curl -X GET http://localhost:8081/api/flags
# Retorna: HTTP 401 Unauthorized - Missing Authorization header

# ✅ Criar flag de segurança
curl -H "Authorization: Bearer valid_jwt_token" \
     -H "Content-Type: application/json" \
     -X POST http://localhost:8081/api/flags/security \
     -d '{
       "name": "suspicious_activity",
       "description": "Atividade suspeita detectada",
       "enabled": true,
       "signature": "valid_signature_here"
     }'

# ✅ Verificar métricas do sistema
curl -H "Authorization: Bearer valid_jwt_token" \
     http://localhost:8081/api/metrics
```

## 🔌 WebSocket API

```javascript
const ws = new WebSocket('ws://localhost:8082/ws');

ws.onopen = function() {
    // Subscrever a eventos
    ws.send(JSON.stringify({
        type: 'subscribe',
        topics: ['messages', 'blockchain', 'security_flags']
    }));
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Evento recebido:', data);
};
```

## 🧪 Testes e Validação

### **🔒 Testes de Segurança** *(Novo!)*

```bash
# Teste completo de penetração
chmod +x penetration_test_suite.sh
./penetration_test_suite.sh

# Testes específicos de segurança
chmod +x network_security_tests.sh
./network_security_tests.sh
```

**Resultados esperados dos testes de segurança:**
- ✅ Rate limiting funcionando (requests bloqueados)
- ✅ Autenticação obrigatória (HTTP 401 sem token)
- ✅ Proteção Sybil ativa (múltiplos nós bloqueados)
- ✅ Métricas protegidas (HTTP 401 sem auth)
- ✅ Payloads grandes rejeitados

### Script de Testes Automatizado
```bash
chmod +x atous-test-cli.sh
./atous-test-cli.sh
```

### Testes de Performance
```bash
# REST API (com autenticação)
wrk -t12 -c100 -d30s \
    -H "Authorization: Bearer valid_jwt_token" \
    http://localhost:8081/api/flags

# Teste de rate limiting
for i in {1..15}; do
  curl -H "Authorization: Bearer valid_jwt_token" \
       http://localhost:8081/api/flags &
done
# Expectativa: Alguns requests com HTTP 429 (rate limited)
```

### 🛡️ Validação de Segurança Manual

```bash
# 1. Teste de autenticação (deve falhar)
curl http://localhost:8081/api/flags
# Expected: HTTP 401 Unauthorized

# 2. Teste de autenticação (deve funcionar)
curl -H "Authorization: Bearer valid_jwt_token" \
     http://localhost:8081/api/flags
# Expected: HTTP 200 OK

# 3. Teste de rate limiting
for i in {1..12}; do
  curl -H "Authorization: Bearer valid_jwt_token" \
       http://localhost:8081/api/flags
done
# Expected: Algumas respostas HTTP 429

# 4. Teste de payload grande (deve falhar)
curl -H "Authorization: Bearer valid_jwt_token" \
     -H "Content-Type: application/json" \
     -X POST http://localhost:8081/api/flags \
     -d "$(printf '{"data":"%*s"}' 300000 "")"
# Expected: HTTP 413 Payload Too Large

# 5. Teste de métricas protegidas
curl http://localhost:8081/api/metrics
# Expected: HTTP 401 Unauthorized

curl -H "Authorization: Bearer valid_jwt_token" \
     http://localhost:8081/api/metrics
# Expected: HTTP 200 OK com dados de métricas
```

## �� Monitoramento

### **🔒 Métricas Prometheus Protegidas** *(Atualizado!)*

```bash
# ❌ ANTES: Endpoint público (vulnerabilidade corrigida)
# curl http://localhost:9090/metrics  

# ✅ AGORA: Endpoint protegido por autenticação
curl -H "Authorization: Bearer valid_jwt_token" \
     http://localhost:8081/api/metrics
```

**Principais métricas disponíveis:**
- `requests_total` - Total de requests processados
- `requests_rate_limited` - Requests bloqueados por rate limiting
- `auth_failures` - Falhas de autenticação (inclui ataques Sybil)
- `security_flags_created` - Flags de segurança criadas
- `flag_system_*` - Métricas do sistema de flags
- `p2p_connections_*` - Conexões P2P ativas
- `blockchain_*` - Métricas da blockchain

### **🚨 Métricas de Segurança** *(Novo!)*

```json
{
  "requests_total": 245,
  "requests_rate_limited": 12,
  "auth_failures": 8,
  "security_flags_created": 3
}
```

### Dashboard Grafana
```bash
docker-compose up grafana
# Acesse: http://localhost:3000 (admin/admin)
```

**Dashboards de segurança incluídos:**
- 🔒 **Security Overview**: Visão geral das tentativas de ataque
- ⏱️ **Rate Limiting**: Monitoramento de rate limiting
- 🛡️ **Sybil Protection**: Detectção de ataques Sybil
- 🔐 **Authentication**: Falhas de autenticação por IP

### 🏗️ Configuração de Monitoramento Seguro

```yaml
# prometheus.yml atualizado
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'atous-secured'
    static_configs:
      - targets: ['localhost:8081']
    metrics_path: '/api/metrics'
    scheme: http
    # Adicionar autenticação para Prometheus
    authorization:
      type: Bearer
      credentials: 'valid_jwt_token'  # Use token real em produção
```

## 🐳 Docker

### Execução com Docker Compose
```bash
docker-compose up -d
```

### Serviços Incluídos
- **atous**: Aplicação principal (porta 8081)
- **redis**: Cache e persistência
- **prometheus**: Métricas (porta 9090)
- **grafana**: Dashboards (porta 3000)

## ⚙️ Configuração

### Arquivo de Configuração Básico

```json
{
  "node": {
    "name": "meu-node-atous",
    "mode": "Full"
  },
  "web": {
    "enabled": true,
    "port": 8081
  },
  "websocket": {
    "enabled": true,
    "port": 8082
  },
  "network": {
    "p2p_port": 8083,
    "use_dynamic_port": true
  }
}
```

### Variáveis de Ambiente
```bash
ATOUS_NODE_NAME=meu-node
ATOUS_LOG_LEVEL=info
ATOUS_HTTP_PORT=8081
ATOUS_WS_PORT=8082
```

## 🛠️ Desenvolvimento

### Estrutura do Projeto
```
atous/
├── atous/              # Aplicação principal
├── network/            # Rede P2P
├── crypto/             # Criptografia
├── message/            # Sistema de mensagens
├── behaviour/          # Comportamentos P2P
├── flag-system/        # Sistema de flags
└── src/                # API web flags
```

### Comandos de Desenvolvimento
```bash
cargo build              # Compilação rápida
cargo build --release    # Compilação otimizada
cargo test               # Executar testes
cargo clippy            # Linter
cargo fmt               # Formatação
```

## 🚨 Resolução de Problemas Comuns

### Porta em uso
```bash
sudo lsof -i :8081
sudo kill -9 PID
```

### Redis não conecta
```bash
sudo systemctl start redis-server
redis-cli ping
```

### WebSocket falha
```bash
nc -zv localhost 8082
curl http://localhost:8081/health
```

## 🤝 Contribuindo

1. **Fork** o repositório
2. **Crie** uma branch: `Análise de um Sistema de Flags com Blockchain para Isolamento de Nós Suspeitos no Micro-HivermindI. IntroduçãoO conceito de Micro-Hivermind, descrito como um "sistema imunológico neural distribuído", apresenta um paradigma intrigante para a auto-regulação e segurança em redes descentralizadas. A proposta de integrar um sistema de flags (sinalizadores) baseado em blockchain para o isolamento de nós suspeitos dentro desta arquitetura visa fornecer um mecanismo robusto, transparente e auditável para a manutenção da integridade da rede. Este relatório tem como objetivo analisar criticamente a arquitetura de tal sistema, examinar um cenário de ataque simulado para testar sua resiliência, e discutir a crítica levantada por David Moseler. Serão detalhados os componentes, interações, pontos fortes e fracos, e o potencial de implementação, com ênfase na exploração de uma possível implementação na linguagem de programação Rust, utilizando o documento "The Rust Programming Language.pdf" 1 como referência para aspectos de implementação e o readme "atous" (assumido como base conceitual para a estrutura do Micro-Hivermind) como guia para a arquitetura subjacente.II. Visão Geral Conceitual do Sistema de Flags PropostoA. Analogia: Sistema Imunológico Neural DistribuídoA metáfora de um "sistema imunológico neural distribuído" sugere uma rede capaz de detectar, identificar e neutralizar ameaças internas de forma autônoma e coordenada, similarmente aos mecanismos de defesa biológicos. Neste contexto, os nós da rede Micro-Hivermind atuam como células, e o sistema de flags com blockchain funcionaria como um componente crucial deste sistema imunológico, permitindo que "anticorpos" (nós vigilantes) marquem "patógenos" (nós suspeitos) e iniciem uma resposta coordenada para isolá-los. A componente "neural" implica a capacidade de aprendizado e adaptação do sistema, possivelmente através da análise de padrões de comportamento sinalizados.B. Papel da Blockchain: Imutabilidade, Transparência e Consenso DescentralizadoA utilização de uma blockchain como alicerce para o sistema de flags oferece vantagens significativas. Primeiramente, a imutabilidade garante que, uma vez que uma flag é registrada e validada, ela não pode ser alterada ou removida subrepticiamente, fornecendo um histórico íntegro das atividades suspeitas.2 Em segundo lugar, a transparência inerente à maioria das implementações de blockchain permite que todos os nós (ou pelo menos os nós autorizados) auditem o registro de flags, promovendo a responsabilidade e dificultando a censura ou manipulação oculta. Finalmente, um mecanismo de consenso descentralizado é fundamental para validar as flags antes que ações punitivas, como o isolamento de um nó, sejam tomadas.3 Isso evita que um único nó ou um pequeno grupo mal-intencionado possa comprometer a rede através de falsas acusações.C. Conceito Central do SistemaO fluxo operacional básico do sistema proposto envolve:
Detecção e Geração de Flags: Nós individuais no Micro-Hivermind monitoram o comportamento de seus pares. Ao detectar uma atividade que viole as regras predefinidas do protocolo ou que seja considerada maliciosa (por exemplo, envio de dados corrompidos, falha em participar do consenso, ataques de negação de serviço), um nó pode gerar uma flag.
Registro na Blockchain: A flag gerada, contendo informações sobre o nó sinalizador, o nó suspeito, a natureza da suspeita e evidências (possivelmente um hash da evidência), é submetida para inclusão na blockchain.
Validação por Consenso: A rede de nós (ou um subconjunto de validadores) utiliza um mecanismo de consenso para verificar a validade da flag e das evidências associadas.
Ação de Isolamento: Se um número suficiente de flags validadas contra um nó específico for acumulado, ou se uma única flag de alta severidade for confirmada, o sistema pode acionar um protocolo de isolamento para aquele nó.
Este ciclo contínuo de monitoramento, sinalização, validação e resposta constitui o núcleo do "sistema imunológico" proposto.III. Arquitetura Detalhada do Sistema de Flags Baseado em BlockchainA. Nó do Micro-Hivermind (Baseado nos Princípios do "atous")Embora o readme "atous" não tenha sido fornecido, pode-se inferir que um nó do Micro-Hivermind possui funcionalidades centrais que interagem com o subsistema de flags.
Funcionalidades Essenciais: Cada nó é presumivelmente responsável por tarefas computacionais específicas do domínio do Micro-Hivermind (potencialmente relacionadas a processamento neural distribuído), comunicação com outros nós para troca de dados e participação em processos colaborativos.
Interação com o Subsistema de Flags:

Monitoramento: Implementa lógica para observar o comportamento de nós vizinhos ou nós com os quais interage, comparando-o com um conjunto de comportamentos esperados ou aceitáveis.
Geração de Flags: Ao detectar anomalias, o nó constrói uma estrutura de dados de flag e a submete à camada de blockchain.
Participação no Consenso: Dependendo do mecanismo de consenso, o nó pode participar da validação de flags submetidas por outros.
Aplicação de Isolamento: Recebe e processa decisões de isolamento validadas pela blockchain, ajustando suas tabelas de roteamento ou listas de permissão para evitar interações com o nó isolado.


B. Mecanismo de Flagging
Geração de Flags:

Critérios: Devem ser claramente definidos e objetivamente verificáveis para minimizar falsos positivos. Exemplos incluem: falha em responder a heartbeats, envio de dados malformados, desvio estatístico significativo no comportamento esperado, falha em seguir protocolos de consenso.
Evidência: Cada flag deve ser acompanhada de evidências que a corroborem. Para economizar espaço na blockchain, a evidência completa pode ser armazenada off-chain (por exemplo, em um sistema de arquivos distribuído como IPFS), com apenas seu hash criptográfico incluído na flag na blockchain.4


Estrutura da Flag: Uma flag pode ser representada como uma estrutura de dados contendo campos como:

flagger_id: Identificador único do nó que gera a flag.
suspect_id: Identificador único do nó suspeito.
timestamp: Momento da detecção da anomalia.
evidence_hash: Hash da evidência que suporta a flag.
reason_code: Um código enumerado indicando o tipo de mau comportamento (por exemplo, MALFORMED_DATA, NON_RESPONSIVE, CONSENSUS_VIOLATION).
severity_level: Um indicador da gravidade da infração.
signature: Assinatura digital do flagger_id para autenticar a origem da flag.


Propagação de Flags: As flags geradas precisam ser disseminadas pela rede para que possam ser incluídas em um bloco e validadas. Isso ocorreria através do protocolo de comunicação P2P da própria blockchain subjacente.
C. Camada da Blockchain
Estrutura do Ledger: A blockchain consistiria em uma cadeia de blocos, onde cada bloco conteria um conjunto de transações de flags.2 Cada transação de flag representaria uma flag submetida.
Mecanismo de Consenso para Validação de Flags: A escolha do mecanismo de consenso é crítica e impacta a segurança, escalabilidade e eficiência do sistema.

Proof of Work (PoW): Altamente seguro e testado, mas consome muita energia e pode ter alta latência.7 Seria custoso para simplesmente validar flags.
Proof of Stake (PoS): Mais eficiente energeticamente que PoW, onde validadores apostam suas moedas. Suscetível a diferentes vetores de ataque se não implementado cuidadosamente.7 Poderia ser viável se os nós do Micro-Hivermind tiverem um stake no sistema.
Proof of Execution (PoE): Um protocolo BFT que visa alcançar consenso resiliente com fases lineares, utilizando execução especulativa e rollbacks seguros.9 PoE é apresentado como escalável e protetor contra ataques maliciosos, podendo ser uma opção interessante se a "execução" se referir à validação da evidência da flag. No entanto, a definição de PoE varia, com algumas fontes focando em "Proof of Evidence" para garantir oportunidades iguais de validação 10 ou verificação de computação, incluindo cargas de trabalho não determinísticas como IA.11 Se a "execução" no Micro-Hivermind se refere a tarefas computacionais que podem ser verificadas, PoE poderia ser relevante para validar o comportamento do nó em geral, e não apenas as flags.
Practical Byzantine Fault Tolerance (PBFT): Um algoritmo de consenso clássico para sistemas distribuídos que toleram falhas bizantinas. Pode ter alta sobrecarga de comunicação em redes grandes.3
A escolha dependerá dos requisitos específicos do Micro-Hivermind em termos de latência, throughput, segurança e complexidade. Um mecanismo leve e rápido, possivelmente um PoS ou uma variante de BFT otimizada para este caso de uso, parece mais apropriado do que PoW.


Smart Contracts para Lógica de Flags (Opcional): Smart contracts poderiam automatizar a lógica de processamento de flags. Por exemplo, um smart contract poderia agregar flags contra um nó, verificar se um limiar foi atingido e, então, emitir um evento de isolamento ou até mesmo acionar mecanismos de penalidade (como slashing de stake em um sistema PoS).
D. Protocolo de Isolamento de Nó
Critérios para Isolamento: Definidos pelo sistema, por exemplo:

Um número N de flags validadas de M fontes únicas.
Uma única flag validada de um tipo de severidade crítica.
Uma pontuação de reputação do nó caindo abaixo de um limiar, onde as flags contribuem negativamente para a pontuação.


Métodos de Isolamento:

Nível de Rede: Outros nós podem ser instruídos (via blockchain ou um canal de controle) a adicionar o IP do nó isolado a uma lista de bloqueio em seus firewalls locais ou a recusar conexões dele. A interação com o sistema operacional para tal pode ser feita via std::process::Command em Rust para executar utilitários como iptables ou ip link set down, ou, com mais complexidade e risco, via FFI (extern "C") para chamar APIs de C do sistema operacional.1
Nível de Aplicação: Os nós do Micro-Hivermind podem manter uma lista de nós isolados e se recusar a processar mensagens ou interagir com eles em nível de aplicação.


Reavaliação/Reintegração: Deve haver um mecanismo para que um nó isolado possa, eventualmente, ser reavaliado e potencialmente reintegrado à rede. Isso pode envolver um período de "quarentena", a submissão de uma prova de correção de comportamento, ou um voto da rede.
E. Merkle Trees para Compactação e Verificação de EstadoMerkle trees são estruturas de dados em árvore onde cada nó folha é um hash de um bloco de dados, e cada nó não-folha é um hash de seus filhos.4 O hash raiz (Merkle root) representa de forma compacta a integridade de todos os dados subjacentes.4
Papel na Verificação Eficiente: No sistema de flags, Merkle trees podem ser usadas para:

Verificar a inclusão de flags em um bloco: Semelhante a como transações são verificadas em blockchains como Bitcoin e Ethereum, o Merkle root de todas as flags em um bloco pode ser incluído no cabeçalho do bloco. Isso permite que nós leves verifiquem a inclusão de uma flag específica baixando apenas o cabeçalho do bloco e um pequeno Merkle proof (um caminho de hashes da flag até a raiz), em vez do bloco inteiro.2
Verificar a integridade de evidências off-chain: Se as evidências detalhadas são armazenadas off-chain, seus hashes (que estão na blockchain) podem ser organizados em uma Merkle tree. O Merkle root dessa árvore de evidências pode ser referenciado pela flag, permitindo uma verificação eficiente da integridade da evidência.
Compactação do estado geral do sistema: Se o sistema mantém um estado agregado sobre a reputação dos nós ou o status das flags, uma Merkle tree pode ser usada para representar esse estado de forma compacta. Comparações de Merkle roots entre nós podem rapidamente detectar inconsistências.4


Compactação de Logs de Flags ou Hashes de Evidências: Em vez de armazenar uma longa lista de hashes de evidências diretamente na blockchain para cada flag complexa, esses hashes podem formar as folhas de uma Merkle tree, e apenas o Merkle root dessa árvore seria armazenado na blockchain. Isso reduz significativamente os requisitos de armazenamento on-chain.13 Algumas propostas, como QMDB, unificam o estado mundial e o armazenamento da Merkle tree, persistindo atualizações em um log de acréscimo e usando "galhos" (twigs) para comprimir a árvore, permitindo que ela caiba na DRAM.13
A utilização de Merkle trees é fundamental para a escalabilidade e eficiência na verificação de dados em sistemas distribuídos e blockchains.2IV. Cenário de Ataque Simulado: Ataque Sybil com Nós ConluiadosA. Descrição do CenárioUm ataque Sybil ocorre quando um adversário cria um grande número de identidades pseudônimas (nós Sybil) e as utiliza para ganhar uma influência desproporcional na rede.7 Neste cenário simulado, um grupo de nós Sybil conluiados coopera para gerar um volume massivo de flags falsas ou enganosas contra um ou mais nós-alvo honestos. O objetivo do ataque pode ser desacreditar os nós-alvo, causar seu isolamento indevido, ou perturbar o funcionamento normal do Micro-Hivermind.B. Resposta Esperada do SistemaO sistema de flags baseado em blockchain deve possuir mecanismos para resistir a tal ataque:
Custo de Geração de Identidade/Flag: Se a criação de identidades de nós ou a submissão de flags tiver um custo (por exemplo, exigir um stake em um sistema PoS, ou uma pequena taxa de transação), isso pode tornar ataques Sybil em larga escala economicamente inviáveis.
Requisitos de Evidência: Flags sem evidências críveis ou com evidências facilmente falsificáveis devem ser rejeitadas pelo processo de consenso. A robustez da evidência é crucial.
Consenso sobre Flags: O mecanismo de consenso não deve ser facilmente dominado pelos nós Sybil.

Em PoS, os nós Sybil precisariam adquirir uma quantidade significativa de stake, o que pode ser caro.7
Em sistemas baseados em reputação (se aplicável ao Micro-Hivermind), novas identidades Sybil teriam baixa reputação e suas flags teriam menos peso.
Mecanismos BFT como PBFT ou PoE são projetados para tolerar uma certa fração de nós maliciosos (geralmente f falhas em n>3f réplicas).9 Os nós Sybil precisariam controlar mais do que essa fração de poder de voto no consenso.


Diversidade de Sinalizadores: O protocolo de isolamento pode exigir flags de múltiplas fontes independentes e com boa reputação, em vez de apenas um grande volume de flags de nós novos ou com baixa reputação. Se as flags dos nós Sybil forem correlacionadas (por exemplo, todas sinalizando o mesmo evento benigno como malicioso), o "sistema neural" poderia aprender a identificar esse padrão de conluio.
Análise de Padrões de Flagging: O componente "neural" do sistema imunológico poderia ser treinado para detectar padrões anormais de flagging, como um aumento súbito de flags de um grupo de nós recém-chegados ou geograficamente correlacionados, indicando um possível ataque Sybil.
C. Análise de ResiliênciaA resiliência do sistema a este ataque depende criticamente:
Robustez do Mecanismo de Consenso: Um consenso que seja difícil e caro de ser dominado por uma minoria (mesmo uma grande minoria de Sybils) é essencial.
Qualidade e Verificabilidade da Evidência: Se a evidência for forte e difícil de forjar, as flags falsas serão mais facilmente identificadas.
Custo de Participação e Sinalização: Impor custos (financeiros ou computacionais) para criar nós e submeter flags desencoraja a proliferação de Sybils.
Inteligência do Sistema de Isolamento: Regras de isolamento que considerem a reputação dos sinalizadores, a diversidade das fontes de flags e a gravidade/qualidade da evidência são mais resilientes do que contagens simples de flags.
Capacidade de Adaptação (Componente Neural): Se o sistema puder aprender e adaptar seus critérios de detecção e isolamento com base em ataques passados ou padrões anormais, sua resiliência aumentará ao longo do tempo.
Um sistema bem projetado pode tornar um ataque Sybil com flags falsas proibitivamente caro ou complexo para o atacante, ou detectar e mitigar o ataque antes que danos significativos ocorram. No entanto, nenhum sistema é imune a ataques Sybil suficientemente grandes e bem financiados, especialmente se os custos de participação forem baixos.V. Análise da Crítica de David MoselerAssumindo que a crítica de David Moseler ao sistema proposto se concentre em preocupações comuns a sistemas baseados em blockchain aplicados à moderação ou detecção de anomalias, os pontos prováveis seriam:A. Resumo da Crítica (Pontos Hipotéticos)
Latência: A necessidade de registrar flags na blockchain e aguardar a confirmação do consenso pode introduzir latência significativa, tornando o sistema lento para responder a ameaças em tempo real.
Sobrecarga Computacional e de Armazenamento: Manter uma blockchain para flags, executar o consenso e armazenar o histórico de flags pode impor uma sobrecarga considerável aos nós do Micro-Hivermind, desviando recursos de suas tarefas primárias.
Risco de Falsos Positivos e Negativos:

Falsos Positivos: Nós honestos podem ser sinalizados incorretamente devido a falhas de rede transitórias, bugs de software ou interpretações errôneas de comportamento, levando ao seu isolamento injusto.
Falsos Negativos: Nós maliciosos podem evadir a detecção por meio de comportamentos sutis ou explorando as limitações dos critérios de flagging.


Complexidade da Implementação e Manutenção: Introduzir uma camada de blockchain e um sistema de flags complexo adiciona uma sobrecarga significativa de desenvolvimento, teste e manutenção ao ecossistema Micro-Hivermind.
Centralização Potencial no Consenso: Dependendo do mecanismo de consenso escolhido (por exemplo, DPoS ou PoA), pode haver um risco de centralização do poder de validação das flags, minando o propósito de um sistema descentralizado.3
B. Validade dos Pontos LevantadosEsses pontos são, em geral, preocupações válidas para muitos sistemas baseados em blockchain:
Latência e Sobrecarga: São inerentes à maioria das blockchains, especialmente aquelas que priorizam a segurança e a descentralização sobre o throughput bruto. O impacto dependerá da frequência de flags, do tamanho da rede e da eficiência do mecanismo de consenso.
Falsos Positivos/Negativos: Este é um desafio fundamental em qualquer sistema de detecção de anomalias ou sistema imunológico. A precisão depende da qualidade dos critérios de flagging e da robustez das evidências.
Complexidade: A introdução de uma blockchain é, inegavelmente, um aumento de complexidade.
Centralização do Consenso: É uma preocupação real para certos mecanismos de consenso e deve ser cuidadosamente considerada na escolha do algoritmo.3
C. Mitigações Potenciais ou Contra-Argumentos
Latência:

Utilizar blockchains de alta performance ou sidechains/layer-2 solutions especificamente para o sistema de flags.
Permitir ações de isolamento preliminares baseadas em um número menor de flags não totalmente confirmadas (com risco aumentado de falsos positivos), enquanto a confirmação final ocorre na blockchain principal.
Mecanismos de consenso mais rápidos como PoE ou algumas variantes de PoS podem oferecer menor latência.9


Sobrecarga:

Otimizar a estrutura de dados das flags e blocos.
Usar Merkle trees para compactar dados e permitir verificação eficiente com provas leves.4
Designar um subconjunto de nós mais capazes para atuar como validadores de flags, reduzindo a carga sobre todos os nós.
O armazenamento de evidências off-chain é crucial.4


Falsos Positivos/Negativos:

Implementar um sistema de reputação para os nós sinalizadores; flags de nós com alta reputação teriam mais peso.
Exigir múltiplas flags de fontes diversas e independentes antes de tomar medidas drásticas.
Desenvolver critérios de flagging sofisticados, possivelmente usando técnicas de aprendizado de máquina (o aspecto "neural" do Micro-Hivermind).
Estabelecer um processo claro de apelação ou reavaliação para nós isolados.


Complexidade:

Utilizar frameworks ou bibliotecas Rust existentes para componentes da blockchain (P2P, consenso, armazenamento) pode reduzir a complexidade da implementação.1
Adotar uma abordagem de implementação incremental, começando com funcionalidades mais simples.


Centralização do Consenso:

Escolher mecanismos de consenso que promovam maior descentralização (por exemplo, PoS com baixas barreiras de entrada para validadores) ou que tenham garantias formais contra a centralização.
Implementar mecanismos de governança para monitorar e mitigar a centralização no conjunto de validadores.


A crítica de Moseler, embora hipotética aqui, provavelmente apontaria para os desafios práticos e os trade-offs inerentes à adição de uma camada de blockchain. A viabilidade do sistema dependerá de quão bem esses desafios são abordados no projeto e na implementação.VI. Avaliação Abrangente: Pontos Fortes, Fracos e Trade-offsA proposta de um sistema de flags baseado em blockchain para o Micro-Hivermind apresenta um conjunto distinto de vantagens e desvantagens que devem ser cuidadosamente ponderadas.A. Pontos Fortes
Imutabilidade e Auditabilidade: O registro de flags em uma blockchain garante que, uma vez confirmadas, as sinalizações não podem ser alteradas ou excluídas secretamente. Isso cria um rastro de auditoria transparente e confiável, essencial para análises forenses e para construir confiança no sistema.2
Transparência: As flags e as decisões de isolamento podem ser publicamente verificáveis (ou verificáveis por todos os participantes da rede), o que aumenta a responsabilidade e dificulta comportamentos maliciosos ocultos.10
Resistência à Censura: Em um sistema descentralizado, é mais difícil para um ator malicioso suprimir a sinalização de seu próprio mau comportamento ou o de seus cúmplices.
Consenso Descentralizado para Decisões Críticas: A validação de flags e a decisão de isolar um nó são tomadas por um consenso distribuído, em vez de uma autoridade central, o que aumenta a resiliência contra pontos únicos de falha ou comprometimento.3
Potencial para Mecanismos de Incentivo: A blockchain pode facilitar a implementação de mecanismos de incentivo (por exemplo, recompensas em tokens) para nós que participam ativamente e honestamente do processo de flagging e validação, e penalidades (por exemplo, slashing) para sinalizações falsas ou maliciosas.
B. Pontos Fracos
Latência: A confirmação de transações em uma blockchain (necessária para validar flags) pode levar de segundos a minutos, ou até mais, dependendo da blockchain e do mecanismo de consenso. Isso pode ser muito lento para uma resposta imunológica rápida a ameaças ágeis.8
Escalabilidade: O throughput (número de flags processadas por segundo) de uma blockchain é geralmente limitado. Se o número de flags geradas for alto, a blockchain pode se tornar um gargalo.
Sobrecarga Computacional e de Armazenamento: Cada nó que participa da validação ou que mantém uma cópia completa da blockchain de flags incorre em custos computacionais (para processar transações e executar o consenso) e de armazenamento.8
Complexidade de Implementação e Manutenção: Desenvolver, implantar e manter uma infraestrutura de blockchain é significativamente mais complexo do que sistemas centralizados ou abordagens mais simples de detecção de anomalias.
Risco de Falsos Positivos e Negativos:

Falsos Positivos: Nós honestos podem ser incorretamente sinalizados, levando ao seu isolamento injusto. O processo de apelação pode ser lento ou complexo.
Falsos Negativos: Agentes maliciosos podem encontrar maneiras de operar abaixo do radar dos critérios de flagging ou explorar as complexidades do sistema.


Vulnerabilidades do Consenso: Nenhum mecanismo de consenso é perfeitamente seguro. Ataques de 51% (em PoW/PoS) ou conluios de validadores podem comprometer a integridade do processo de validação de flags.7
Custo Operacional: Pode haver custos associados à execução de transações na blockchain (taxas de gás em algumas plataformas) ou à manutenção da infraestrutura de validação.
C. Trade-offs Chave
Segurança vs. Performance/Latência: Mecanismos de consenso mais seguros e descentralizados (como PoW) tendem a ser mais lentos e menos escaláveis. Escolhas que favorecem a velocidade podem comprometer a segurança ou a descentralização.
Descentralização vs. Eficiência: Um alto grau de descentralização na validação de flags aumenta a resiliência, mas pode ser menos eficiente do que sistemas com um conjunto menor e mais controlado de validadores.
Transparência vs. Privacidade: Embora a transparência seja uma força, ela pode revelar informações sobre as estratégias de detecção ou sobre os nós que estão sendo monitorados, o que pode ser explorado por adversários. Técnicas avançadas de privacidade podem ser necessárias para mitigar isso (discutidas na Seção VIII).
Complexidade vs. Robustez: A complexidade adicional da blockchain visa aumentar a robustez e a confiabilidade, mas também introduz mais pontos potenciais de falha ou vetores de ataque se não for implementada e gerenciada corretamente.
A tabela a seguir resume os pontos fortes e fracos:Tabela 1: Pontos Fortes e Fracos do Sistema de Flags com Blockchain
Característica/AspectoPonto FortePonto FracoMitigação/ConsideraçãoImutabilidade/AuditabilidadeRegistros de flags não podem ser alterados; histórico confiável.2--TransparênciaFlags e decisões podem ser publicamente verificáveis.10Pode revelar estratégias de detecção.Técnicas de privacidade (ZKPs, HE); acesso restrito à blockchain de flags.Resistência à CensuraDifícil suprimir flags em um sistema descentralizado.--Consenso DescentralizadoDecisões críticas tomadas pela rede, não por uma entidade central.3Vulnerabilidades específicas do mecanismo de consenso escolhido (ex: ataque 51%).7Escolha cuidadosa do mecanismo de consenso; monitoramento da distribuição de poder.Latência-Confirmação de flags pode ser lenta para respostas rápidas.8Blockchains de alta performance; Layer-2; mecanismos de consenso rápidos; ações preliminares off-chain.Escalabilidade-Throughput limitado pode ser um gargalo para alto volume de flags.Soluções de escalabilidade de blockchain; otimização de dados de flags; Merkle trees.4Sobrecarga (Comp./Armaz.)-Custo para nós participantes.8Validadores dedicados; evidências off-chain; Merkle trees.4Complexidade-Aumento significativo na complexidade do sistema.Uso de bibliotecas/frameworks existentes; implementação incremental.Falsos Positivos/Negativos-Risco inerente a sistemas de detecção; pode levar a isolamento injusto.Critérios de flagging robustos; sistema de reputação; múltiplas fontes de flags; processo de apelação.Custo OperacionalPotencial para incentivos.Taxas de transação; manutenção da infraestrutura.Escolha de blockchain com baixas taxas; otimização.
A decisão de adotar tal sistema requer uma avaliação cuidadosa desses trade-offs no contexto específico dos objetivos de segurança, desempenho e resiliência do Micro-Hivermind.VII. Proposta de Implementação em RustRust, com seu foco em segurança de memória, concorrência e desempenho, é uma linguagem promissora para a implementação de um sistema de flags baseado em blockchain para o Micro-Hivermind.1 Suas características podem ser mapeadas para os diversos componentes do sistema.A. Estruturas de Dados 1Rust oferece tipos robustos para definir as estruturas de dados necessárias:
Informações do Nó, Flags, Blocos: structs são ideais para representar essas entidades complexas com campos nomeados.1 Por exemplo:
Rust// Exemplo de estrutura para uma Flag
pub struct Flag {
    flagger_id: String, // Ou um tipo de ID mais específico
    suspect_id: String,
    timestamp: u64,
    evidence_hash: String, // Hash da evidência
    reason_code: FlagReason, // Enum para tipos de mau comportamento
    severity: u8,
    signature: Vec<u8>, // Assinatura digital
}

// Exemplo de estrutura para um Bloco na blockchain de flags
pub struct FlagBlock {
    previous_hash: String,
    timestamp: u64,
    flags: Vec<Flag>, // Vetor de flags incluídas neste bloco
    merkle_root: String, // Merkle root das flags no bloco
    nonce: u64, // Para PoW, se aplicável
}


Tipos de Flags, Estados de Nós: enums são perfeitos para representar um conjunto finito de estados ou tipos, como FlagReason ou NodeStatus.1
Rustpub enum FlagReason {
    MalformedData,
    NonResponsive,
    ConsensusViolation,
    //... outros motivos
}


Listas de Flags em Blocos, Logs: Vec<T> (vetores) são usados para coleções de tamanho variável de itens do mesmo tipo, como Vec<Flag> dentro de um FlagBlock ou Vec<LogEntry> para logs.1
Identificadores, Hashes, Mensagens de Log: String para dados textuais de tamanho variável. Para hashes, um tipo de array de tamanho fixo (por exemplo, [u8; 32] para SHA-256) ou uma String formatada hexadecimalmente pode ser usado.1
Mapeamento de Reputação de Nós, Índices: HashMap<K, V> para estruturas de mapeamento eficientes, como HashMap<NodeId, ReputationScore>.1
A natureza estaticamente tipada de Rust e seu sistema de propriedade garantem que essas estruturas de dados sejam usadas de maneira segura em termos de memória.1B. Traits para Comportamento Compartilhado 1Traits são fundamentais em Rust para definir interfaces e comportamento compartilhado, permitindo polimorfismo.
Definição de Comportamentos: Poderiam ser definidos traits como FlaggableBehavior (para comportamentos que podem ser sinalizados), ConsensusParticipant (para nós que participam da validação de flags), ou EvidenceHandler (para módulos que processam evidências).
Rustpub trait FlagValidator {
    fn validate(&self, flag: &Flag, evidence: &[u8]) -> Result<(), ValidationError>;
}


Polimorfismo com impl Trait e Trait Objects (dyn Trait):

Funções genéricas usando impl Trait podem aceitar qualquer tipo que implemente um trait específico, permitindo que, por exemplo, uma função process_flag(validator: &impl FlagValidator, flag: &Flag) funcione com diferentes implementações de validadores.1
Para coleções heterogêneas (por exemplo, uma lista de diferentes tipos de regras de validação), Box<dyn FlagValidator> (um trait object) pode ser usado. Isso permite armazenar diferentes tipos que implementam o mesmo trait em uma única Vec, utilizando despacho dinâmico.1 Isso é particularmente útil se o sistema precisar carregar diferentes módulos de validação dinamicamente.


C. Modelo de Concorrência 1O Micro-Hivermind, sendo um sistema distribuído, exigirá um manejo cuidadoso da concorrência para comunicação entre nós, processamento de flags e execução do consenso.
Threads: Para tarefas computacionalmente intensivas (CPU-bound), como validação criptográfica de evidências ou algumas etapas do consenso (por exemplo, mineração em PoW, se escolhido), std::thread::spawn pode ser usado para executar trabalho em paralelo.1
Message Passing (mpsc channels): Para comunicação segura entre threads dentro de um mesmo nó (por exemplo, um thread de rede passando flags recebidas para um thread de processamento de consenso), canais mpsc (multiple producer, single consumer) são uma excelente opção, garantindo que os dados sejam transferidos com segurança e evitando condições de corrida.1
Shared State (Arc<Mutex<T>>): Para dados que precisam ser acessados e potencialmente modificados por múltiplos threads (por exemplo, o estado atual da blockchain de flags, uma tabela de reputação de nós), Arc<Mutex<T>> permite o compartilhamento seguro. Arc (Atomic Reference Counting) permite múltiplos proprietários dos dados, e Mutex (Mutual Exclusion) garante que apenas um thread possa acessar os dados por vez para modificação.1
Async/Await (async fn, Future, Tasks): Para operações I/O-bound, como comunicação de rede P2P para propagação de flags e blocos, ou interações com armazenamento, o modelo async/await de Rust é altamente eficiente.1 Ele permite que um nó gerencie muitas conexões de rede concorrentes com um número menor de threads do sistema operacional, usando tarefas leves gerenciadas por um executor (runtime) assíncrono.
Segurança na Concorrência em Rust: Rust garante a segurança na concorrência ("fearless concurrency") através de seu sistema de propriedade e verificação de empréstimos em tempo de compilação, juntamente com os traits Send (tipos cuja propriedade pode ser transferida entre threads) e Sync (tipos para os quais é seguro ter referências compartilhadas entre threads).1 Isso previne a maioria das condições de corrida e deadlocks em tempo de compilação.
Uma abordagem híbrida, utilizando async/await para a camada de rede e possivelmente threads dedicadas para tarefas de consenso ou validação intensivas, é uma estratégia comum e eficaz em Rust. A escolha entre executar uma tarefa em um thread do sistema operacional ou como uma tarefa assíncrona depende se a tarefa é predominantemente limitada por CPU ou por I/O.1D. Tratamento de Erros 1Operações de rede, interações com blockchain e a lógica de apply_* (por exemplo, aplicar uma regra de isolamento) são propensas a falhas.
Result<T, E>: Para erros recuperáveis (por exemplo, falha na conexão de rede, flag inválida, evidência ausente), as funções devem retornar Result<T, E>. Isso força o código chamador a lidar explicitamente com a possibilidade de falha.1
Rust// Exemplo de função que pode falhar
fn submit_flag_to_network(flag: &Flag) -> Result<(), NetworkError> {
    //... lógica de submissão...
    // if success { Ok(()) } else { Err(NetworkError::Timeout) }
    unimplemented!();
}


panic!: Para erros irrecuperáveis que indicam um bug no programa (por exemplo, um estado interno inconsistente que não deveria ocorrer), panic! pode ser usado para encerrar o programa imediatamente.1 No entanto, em um nó de servidor, geralmente é preferível retornar Err sempre que possível para permitir que o sistema de nível superior decida como lidar com a falha, em vez de derrubar o nó inteiro.
Operador ?: Simplifica a propagação de erros. Se uma função retorna Result, o operador ? pode ser usado em chamadas a outras funções que retornam Result. Se a chamada interna retornar Err(e), a função atual retornará Err(e) imediatamente (com conversão de tipo de erro, se necessário, via trait From).1 Isso mantém o código de tratamento de erros limpo e conciso.
E. Lógica de Interação com a BlockchainIsso envolveria:
Criação de Transações de Flags: Construir a estrutura de dados da flag, serializá-la e submetê-la à rede.
Validação de Blocos/Flags: Implementar a lógica do mecanismo de consenso escolhido. Isso pode envolver verificar assinaturas, validar evidências (potencialmente uma tarefa complexa), e garantir que as regras do protocolo de flags sejam seguidas.
Participação no Consenso: Se o nó for um validador, ele precisará executar o protocolo de consenso para concordar sobre o próximo bloco de flags.
F. Serialização/Deserialização 1Para comunicação de rede (enviar/receber flags e blocos) e para persistência de dados (armazenar o estado da blockchain), as estruturas de dados precisarão ser serializadas (convertidas para um formato de bytes/string) e desserializadas.
Embora o livro "The Rust Programming Language" não detalhe bibliotecas específicas como JSON ou Serde, ele discute os traits e macros que as habilitam.1
No ecossistema Rust, a biblioteca serde (com serde_json para JSON, bincode para binário, etc.) é o padrão de fato.15 Ela usa traits (Serialize, Deserialize) e macros de derivação (#) para gerar automaticamente o código de serialização/desserialização para structs e enums definidos pelo usuário.1 Isso torna o processo eficiente e com pouco boilerplate.
G. Interação em Nível de SO para Isolamento de Nós 1Se o isolamento de um nó suspeito requer manipulação direta de interfaces de rede ou regras de firewall no sistema operacional:
std::process::Command: Esta é geralmente a abordagem mais segura e simples. O programa Rust pode executar utilitários de linha de comando do sistema operacional (como ip link set <interface> down ou iptables -A INPUT -s <IP_suspeito> -j DROP). O Rust pode capturar a saída e os erros desses comandos.1
Rustuse std::process::Command;

fn block_ip(ip_address: &str) -> std::io::Result<()> {
    let status = Command::new("iptables")
       .arg("-A")
       .arg("INPUT")
       .arg("-s")
       .arg(ip_address)
       .arg("-j")
       .arg("DROP")
       .status()?;

    if status.success() {
        Ok(())
    } else {
        Err(std::io::Error::new(std::io::ErrorKind::Other, "Failed to execute iptables"))
    }
}


FFI (extern "C"): Para interações de mais baixo nível ou de maior desempenho, funções de bibliotecas C do sistema operacional que controlam a rede podem ser chamadas diretamente. Isso requer o uso de blocos unsafe e um manuseio cuidadoso de tipos de dados C e ponteiros crus, pois o compilador Rust não pode garantir a segurança dessas chamadas.1
A escolha entre std::process::Command e FFI dependerá do nível de controle necessário, das considerações de desempenho e da complexidade da API C subjacente.A implementação do sistema de flags pode se beneficiar significativamente da abordagem de ciclo de vida de flags utilizando o padrão de projeto State, como discutido no Capítulo 18 de "The Rust Programming Language".1 Cada estado de uma flag (por exemplo, Pendente, Validada, Rejeitada, AçãoTomada) poderia ser um tipo que implementa um trait FlagState. Isso tornaria a lógica de transição entre estados mais explícita e segura, alinhando-se com a ênfase de Rust em sistemas de tipos fortes para garantir a correção.Ademais, a decisão sobre o modelo de concorrência (ou a combinação deles) é fundamental. A natureza distribuída e potencialmente I/O-intensiva da comunicação de flags e da sincronização da blockchain sugere que async/await seria benéfico para a escalabilidade. No entanto, as operações de validação de flags ou a execução do consenso podem ser CPU-intensivas, onde threads tradicionais poderiam ser mais apropriadas. Rust permite essa combinação de forma segura.Finalmente, embora a construção de uma blockchain completa a partir do zero em Rust seja uma tarefa considerável, o ecossistema Rust oferece várias bibliotecas e frameworks maduros (por exemplo, Substrate, Libp2p) que poderiam ser aproveitados para componentes como a camada de rede P2P, mecanismos de consenso ou implementações de Merkle tree. Isso poderia reduzir drasticamente o tempo de desenvolvimento e aumentar a robustez, aproveitando código já testado e auditado pela comunidade.A tabela a seguir mapeia as funcionalidades de Rust aos componentes do sistema de flags:Tabela 2: Mapeamento de Funcionalidades de Rust para Componentes do Sistema de Flags do Micro-Hivermind
Componente/Requisito do SistemaFuncionalidade(s) Relevante(s) de RustRazão/BenefícioSnippets Chave Estruturas de Dados de Flags/Blocosstruct, enumDefinição de tipos de dados complexos e seguros.Cap. 5, 6, 8; 1Listas de Flags, LogsVec<T>Coleções dinâmicas de tamanho variável.Cap. 8; 1Identificadores, HashesString, [u8; N]Representação de dados textuais e binários.Cap. 8; 1Comportamento Compartilhado (Validação, Isolamento)trait, dyn TraitPolimorfismo, interfaces para diferentes implementações.Cap. 10, 18; 1Comunicação Inter-Nós (P2P)async/await, std::net (base para P2P), mpsc (interno ao nó)Rede concorrente e eficiente.Cap. 16, 17, 21; 1Lógica de ConsensoArc<Mutex<T>>, threads, async/awaitImplementação de algoritmos de consenso concorrentes e seguros.Cap. 16, 17; 1Validação de FlagsFunções, match, Result<T,E>Lógica de verificação e tratamento de resultados.Cap. 6, 9; 1Manipulação de EvidênciasVec<u8>, String, Funções de Hash (externas)Processamento e verificação de dados de evidência.Cap. 8Persistência de Estadostd::fs, Serialização (Serde)Leitura/escrita do estado da blockchain em disco.Cap. 12; 1Isolamento em Nível de SOstd::process::Command, extern "C" (FFI)Interação com utilitários de sistema ou APIs de baixo nível.Cap. 20; 1Processamento Concorrentethreads, async/await, mpsc, Arc<Mutex<T>>Execução paralela e concorrente de tarefas.Cap. 16, 17; 1Tratamento de ErrosResult<T, E>, panic!, ?Gerenciamento robusto de falhas.Cap. 9; 1
VIII. Considerações Avançadas de Segurança e PrivacidadePara um sistema como o Micro-Hivermind, que visa operar como um "sistema imunológico neural distribuído", considerações avançadas de segurança e privacidade são fundamentais, especialmente ao lidar com sinalizações de comportamento potencialmente sensíveis.A. Explorando Provas de Conhecimento Zero (Zero-Knowledge Proofs - ZKPs) para Operações de Flag Privadas

Conceito: Provas de Conhecimento Zero (ZKPs) são protocolos criptográficos que permitem a uma parte (o provador) convencer outra parte (o verificador) de que uma afirmação é verdadeira, sem revelar qualquer informação além da validade da própria afirmação.17 As propriedades chave são completude (se a afirmação é verdadeira, um provador honesto convence um verificador honesto), solidez (se a afirmação é falsa, nenhum provador desonesto pode convencer um verificador honesto) e conhecimento zero (o verificador não aprende nada além da validade da afirmação).18


Aplicação ao Sistema de Flags:

Submissão Privada de Flags: Um nó poderia submeter uma flag ou evidência de suporte usando ZKPs. Isso permitiria ao nó provar que as condições para a flag foram atendidas (por exemplo, "o nó X enviou dados que violam o formato Y" ou "observei o comportamento Z que corresponde a um padrão malicioso conhecido") sem revelar dados sensíveis sobre suas próprias operações, o conteúdo exato da comunicação interceptada, ou a natureza específica do comportamento observado que poderia expor suas capacidades de detecção.17 Isso poderia proteger os nós sinalizadores de retaliação e manter a confidencialidade de certas interações.
Verificação Privada de Ações de Nós: Um nó poderia usar ZKPs para provar que executou corretamente uma tarefa computacional (relevante para a função "neural" do Hivermind) ou que não realizou uma ação maliciosa específica, sem ter que expor seu estado interno ou logs detalhados.14 Por exemplo, um nó acusado de não participar do consenso poderia provar que participou sem revelar os detalhes de seus votos ou mensagens de consenso.
Autenticação com Preservação de Privacidade: ZKPs podem ser usados para autenticar nós ou mensagens sem transmitir senhas ou chaves secretas.17



Tipos (zk-SNARKs vs. zk-STARKs):

zk-SNARKs (Zero-Knowledge Succinct Non-Interactive Argument of Knowledge): Produzem provas pequenas e têm verificação rápida, mas geralmente requerem uma "configuração confiável" (trusted setup). Se o segredo dessa configuração for comprometido, a segurança do sistema pode ser quebrada.21 São vulneráveis a computadores quânticos devido à sua dependência de criptografia de curva elíptica.21
zk-STARKs (Zero-Knowledge Scalable Transparent Argument of Knowledge): Não requerem configuração confiável (são "transparentes"), usam aleatoriedade pública e são baseados em funções de hash, tornando-os resistentes a ataques quânticos. Contudo, tendem a ter tamanhos de prova maiores e podem ter um custo computacional mais alto para a geração da prova.21



Desafios: A implementação de ZKPs é complexa e a geração de provas pode ser computacionalmente intensiva para o provador (o nó que sinaliza ou se defende).17 A verificação, embora geralmente mais rápida, ainda adiciona sobrecarga.

B. Explorando Criptografia Homomórfica (Homomorphic Encryption - HE) para Análise de Comportamento de Nós com Preservação de Privacidade

Conceito: A Criptografia Homomórfica (HE) permite que computações sejam realizadas diretamente em dados criptografados, sem a necessidade de descriptografá-los primeiro. O resultado da computação, quando descriptografado, é o mesmo que se as operações tivessem sido realizadas nos dados em texto plano.23


Aplicação ao Sistema de Flags/Imunológico:

Análise Agregada de Ameaças: O "sistema imunológico neural" poderia analisar dados de flags criptografados ou relatórios de comportamento de múltiplos nós. Por exemplo, os nós poderiam submeter contagens criptografadas de certos tipos de eventos suspeitos. O sistema poderia agregar essas contagens criptografadas (usando as propriedades aditivas da HE) para identificar padrões de ataque generalizados ou nós maliciosos em conluio, sem que qualquer entidade (incluindo o próprio analisador central, se houver) veja os dados brutos e descriptografados de nós individuais.24
Análise Privada de Logs: Se os nós submeterem logs criptografados (por exemplo, logs de erros ou de comunicação), a HE poderia permitir certos tipos de análise (como contar a frequência de tipos específicos de erros ou identificar anomalias estatísticas) sem descriptografar os logs completos, protegendo assim a privacidade operacional de cada nó.25
Treinamento de Modelos Neurais com Privacidade: Se o componente "neural" do sistema imunológico envolver aprendizado de máquina, a HE poderia, teoricamente, permitir o treinamento de modelos em dados agregados criptografados, embora isso seja uma área de pesquisa muito ativa e com desafios significativos de desempenho.



Tipos:

Partially Homomorphic Encryption (PHE): Suporta um tipo de operação (adição ou multiplicação), mas não ambas.
Somewhat Homomorphic Encryption (SHE): Suporta um número limitado de operações de adição e multiplicação.25
Fully Homomorphic Encryption (FHE): Suporta um número arbitrário de operações de adição e multiplicação, oferecendo máxima flexibilidade, mas é a mais intensiva computacionalmente.24



Desafios: A HE, especialmente a FHE, é extremamente intensiva em termos computacionais e de dados (os textos cifrados são muito maiores que os textos planos).25 O desempenho pode ser um grande obstáculo para respostas em tempo real do sistema imunológico. Esquemas mais leves de SHE ou PHE, ou técnicas que combinam HE com outras abordagens como Verifiable Computation (VC) para formar Verifiable Homomorphic Encryption (VHE) 28, podem ser mais viáveis para computações específicas e limitadas. A VHE visa garantir tanto a privacidade (via HE) quanto a integridade do resultado da computação (via VC).29

A integração de ZKPs ou HE no Micro-Hivermind representaria um avanço significativo em direção a sistemas distribuídos comprovadamente seguros e privados. No entanto, isso colocaria o sistema na vanguarda da complexidade de implementação e dos desafios de desempenho. A escolha de usar ZKPs ou HE influenciaria profundamente o design da estrutura de dados da Flag, o processo de submissão de evidências e as capacidades computacionais exigidas dos nós. Por exemplo, a geração de ZKPs pode ser intensiva em recursos para o nó provador.O aspecto "neural" do sistema imunológico poderia ser treinado sobre os resultados de dados processados com HE (estatísticas agregadas criptografadas) ou sobre padrões derivados de interações verificadas por ZKP (mas cujo conteúdo permanece privado). Isso permitiria ao sistema aprender e adaptar-se sem comprometer a privacidade dos dados brutos dos nós individuais.A tabela a seguir compara estas técnicas criptográficas avançadas:Tabela 3: Comparação de Técnicas Criptográficas Avançadas para Segurança/Privacidade Aprimoradas
Técnica CriptográficaDescriçãoAplicação Potencial no Sistema de FlagsPrósContras/DesafiosSnippets RelevantesProvas de Conhecimento Zero (zk-SNARKs)Provas sucintas, não interativas, que validam uma afirmação sem revelar dados.Submissão privada de flags; verificação privada de ações de nós.Provas pequenas; verificação rápida.Requer configuração confiável (geralmente); vulnerável a computadores quânticos.21Provas de Conhecimento Zero (zk-STARKs)Provas escaláveis, transparentes (sem configuração confiável), que validam uma afirmação sem revelar dados.Submissão privada de flags; verificação privada de ações de nós.Transparente (sem configuração confiável); resistente a computadores quânticos.Provas maiores que zk-SNARKs; pode ser mais custoso computacionalmente para gerar.21Criptografia Homomórfica (Parcial/Um Pouco - PHE/SHE)Permite um número limitado ou tipos específicos de computações em dados criptografados.Análise estatística simples de flags criptografadas; contagem de eventos específicos.Menos sobrecarga computacional que FHE; pode ser viável para tarefas limitadas.Funcionalidade limitada; ainda pode ser lenta para tempo real.25Criptografia Homomórfica (Totalmente - FHE)Permite um número arbitrário de adições e multiplicações em dados criptografados.Análise complexa e agregada de comportamento de nós sobre dados de flags criptografados; treinamento privado de modelos neurais (teórico).Máxima flexibilidade computacional em dados criptografados.Extremamente intensiva computacionalmente; textos cifrados grandes; impraticável para muitas aplicações em tempo real atualmente.24
IX. Conclusão e Recomendações EstratégicasA. Avaliação Geral de ViabilidadeA proposta de um sistema de flags baseado em blockchain para o isolamento de nós suspeitos no Micro-Hivermind é tecnicamente viável, alinhando-se bem com a necessidade de um mecanismo de "sistema imunológico neural distribuído" que seja transparente, auditável e resistente à manipulação. A imutabilidade e o consenso descentralizado oferecidos pela blockchain são pontos fortes significativos para a integridade do sistema de flags. A linguagem Rust, com suas garantias de segurança de memória e capacidades de concorrência robustas, é uma escolha adequada para a implementação de tal sistema.1No entanto, a viabilidade prática depende crucialmente da gestão dos trade-offs inerentes. A latência da blockchain e a sobrecarga computacional são as principais preocupações que precisam ser mitigadas através de escolhas de design inteligentes, como mecanismos de consenso eficientes, armazenamento de evidências off-chain e o uso de Merkle trees para compactação e verificação.4 O risco de falsos positivos e a complexidade geral do sistema também são fatores que exigem atenção contínua.O sistema é particularmente viável se:
A criticidade da integridade e da auditabilidade das flags superar as preocupações com a latência imediata para todos os tipos de ameaças.
Os recursos computacionais dos nós do Micro-Hivermind forem suficientes para lidar com a sobrecarga da participação na blockchain (ou se um subconjunto de nós puder lidar com essa carga).
O "componente neural" do sistema puder ser efetivamente treinado para refinar os critérios de flagging e reduzir falsos positivos/negativos.
B. Recomendações Acionáveis para Refinamento do Design e Implementação
Mecanismo de Consenso: Priorizar mecanismos de consenso leves e rápidos (por exemplo, PoS com baixa barreira, ou um BFT otimizado como algumas variantes de PoE) em vez de PoW, para minimizar latência e consumo de energia para a validação de flags. A pesquisa sobre PoE, especialmente suas variantes que lidam com execução especulativa e rollbacks, pode ser promissora para um sistema que precisa reagir a comportamentos dinâmicos.9
Estrutura e Evidência da Flag:

Implementar uma estrutura de Flag rica em Rust, utilizando enums para reason_code e structs para metadados.1
Armazenar evidências detalhadas off-chain (por exemplo, IPFS) e incluir apenas hashes na blockchain, verificados por Merkle proofs.4


Lógica de Isolamento: Definir limiares de isolamento que considerem a severidade da flag, o número de flags distintas e a reputação dos sinalizadores. Implementar o isolamento em nível de SO via std::process::Command em Rust para maior segurança inicial.1
Implementação em Rust:

Utilizar structs e enums para modelar os dados da blockchain e das flags.1
Empregar traits para definir comportamentos como ValidatableFlag ou IsolatableNode, usando dyn Trait para coleções heterogêneas se necessário.1 Adotar o padrão State para gerenciar o ciclo de vida das flags.1
Adotar uma arquitetura concorrente híbrida: async/await para I/O de rede (propagação de flags/blocos) e threads 1 para tarefas CPU-bound (validação de consenso, processamento de evidências).1
Utilizar Result<T, E> e o operador ? extensivamente para um tratamento de erros robusto.1
Empregar serde para serialização/desserialização de dados de rede e armazenamento.1
Considerar o uso de bibliotecas Rust existentes para componentes da blockchain (por exemplo, libp2p para a camada de rede, ou frameworks de blockchain como Substrate para uma base mais completa) para acelerar o desenvolvimento e aumentar a robustez.


Abordagem Incremental: Iniciar com um sistema de flags mais simples, talvez com um consenso centralizado ou federado, e evoluir para uma descentralização maior e mecanismos mais sofisticados à medida que o sistema amadurece e os requisitos de desempenho são melhor compreendidos.
Métricas de Sucesso: Definir métricas claras para avaliar a eficácia do sistema imunológico (por exemplo, tempo para detectar e isolar nós maliciosos, taxa de falsos positivos, impacto no desempenho da rede) antes da implementação completa.
C. Direções Futuras de Pesquisa
Desempenho e Escalabilidade: Realizar benchmarking de diferentes mecanismos de consenso e configurações da blockchain no contexto específico das cargas de trabalho e da topologia de rede do Micro-Hivermind. Investigar os limites de escalabilidade do sistema à medida que o número de nós e a frequência de flags aumentam.
Integração com o "Componente Neural": Explorar como o sistema de flags pode alimentar dados para o aprendizado e adaptação do sistema imunológico neural. Isso pode envolver o desenvolvimento de modelos de ML para prever comportamentos maliciosos, refinar dinamicamente os critérios de flagging ou otimizar as estratégias de isolamento.
Privacidade Avançada: Investigar a viabilidade e os trade-offs de incorporar ZKPs para submissão privada de flags ou HE para análise agregada de comportamento, à medida que essas tecnologias amadurecem e se tornam mais acessíveis em termos de desempenho e complexidade de implementação.17
Verificação Formal: Para componentes críticos do sistema, especialmente a lógica de consenso e os smart contracts (se utilizados), explorar o uso de técnicas de verificação formal para provar matematicamente sua correção e segurança.
Mecanismos de Reintegração Sofisticados: Desenvolver protocolos robustos e justos para a reavaliação e potencial reintegração de nós isolados, possivelmente envolvendo provas de correção de comportamento ou períodos de observação.
Em suma, a proposta de um sistema de flags com blockchain para o Micro-Hivermind é um empreendimento ambicioso e promissor. Seu sucesso dependerá de um design cuidadoso que equilibre os ideais de segurança e descentralização com as realidades práticas de desempenho e complexidade, e de uma implementação robusta que aproveite ao máximo as capacidades da linguagem Rust.{
  "network": {
    "port": 8080,
    "websocket_port": 8080,
    "listen_addresses": ["0.0.0.0"],
    "bootstrap_nodes": [],
    "connection_limits": {
      "max_incoming": 100,
      "max_outgoing": 50,
      "inbound_timeout_ms": 10000,
      "outbound_timeout_ms": 10000
    },
    "security": {
      "enable_kad_firewall": true,
      "peer_reputation_enabled": true,
      "sybil_protection": {
        "enabled": true,
        "inbound_connection_rate_limit": 20,
        "min_peer_age_hours": 2
      },
      "eclipse_protection": {
        "enabled": true,
        "min_distance_threshold": 0.3,
        "min_diversity_threshold": 5
      }
    }
  },
  "websocket": {
    "enabled": true,
    "port": 8080,
    "cors": {
      "allowed_origins": ["http://localhost:3000"],
      "allowed_methods": ["GET", "POST"],
      "allowed_headers": ["Content-Type", "Authorization"],
      "max_age_seconds": 86400
    },
    "rate_limiting": {
      "enabled": true,
      "requests_per_minute": 100,
      "burst_size": 20
    }
  },
  "authentication": {
    "jwt_secret": "CHANGE_THIS_TO_A_RANDOM_SECRET_IN_PRODUCTION",
    "token_expiry_seconds": 86400,
    "did_verification": {
      "required": true,
      "methods": ["web", "blockchain", "key"]
    }
  },
  "encryption": {
    "default_enabled": true,
    "algorithms": ["chacha20poly1305", "aes256gcm"],
    "post_quantum": {
      "enabled": true,
      "algorithms": ["ml-kem-768"]
    }
  },
  "storage": {
    "data_dir": "./data",
    "persistent": true,
    "max_message_age_days": 30
  },
  "logging": {
    "level": "info",
    "file": "atous.log",
    "console": true,
    "metrics": {
      "enabled": true,
      "port": 9090
    }
  }
} {
  "node": {
    "name": "atous-node-1",
    "mode": "Full",
    "data_path": "./data",
    "log_level": "info"
  },
  "network": {
    "p2p_listen": "/ip4/127.0.0.1/tcp/8083",
    "p2p_port": 8083,
    "bootstrap_peers": [],
    "enable_mdns": true,
    "enable_kademlia": true,
    "use_dynamic_port": false,
    "port": 8083,
    "websocket_port": 8082,
    "listen_addresses": ["127.0.0.1"],
    "connection_limits": {
      "max_incoming": 100,
      "max_outgoing": 50,
      "inbound_timeout_ms": 10000,
      "outbound_timeout_ms": 10000
    },
    "security": {
      "enable_kad_firewall": true,
      "peer_reputation_enabled": true,
      "sybil_protection": {
        "enabled": true,
        "inbound_connection_rate_limit": 20,
        "min_peer_age_hours": 2
      },
      "eclipse_protection": {
        "enabled": true,
        "min_distance_threshold": 0.3,
        "min_diversity_threshold": 5
      }
    }
  },
  "websocket": {
    "enabled": true,
    "port": 8082,
    "cors": {
      "allowed_origins": ["*"],
      "allowed_methods": ["GET", "POST"],
      "allowed_headers": ["Content-Type", "Authorization"],
      "max_age_seconds": 86400
    },
    "rate_limiting": {
      "enabled": true,
      "requests_per_minute": 120,
      "burst_size": 20
    }
  },
  "authentication": {
    "jwt_secret": "distributed_secure_key_2024_atous_neural_immune_system",
    "token_expiry_seconds": 86400,
    "did_verification": {
      "required": true,
      "methods": ["web", "blockchain", "key"]
    }
  },
  "encryption": {
    "default_enabled": true,
    "algorithms": ["chacha20poly1305", "aes256gcm"],
    "post_quantum": {
      "enabled": true,
      "algorithms": ["ml-kem-768"]
    }
  },
  "storage": {
    "data_dir": "./data",
    "persistent": true,
    "max_message_age_days": 30
  },
  "logging": {
    "level": "info",
    "file": "atous.log",
    "console": true,
    "metrics": {
      "enabled": true,
      "port": 9090
    }
  },
  "web": {
    "enabled": true,
    "listen": "0.0.0.0",
    "port": 8081,
    "enable_cors": true,
    "cors_origins": ["http://localhost:3000", "https://localhost:3000"],
    "api_path": "/api"
  },
  "blockchain": {
    "enabled": true,
    "consensus": "PoW",
    "difficulty": 4,
    "block_time": 60,
    "reward": 50,
    "path": "./data/blockchain",
    "max_tx_per_block": 1000,
    "consensus_difficulty": 4
  },
  "persistence": {
    "enabled": true,
    "type": "rocksdb",
    "path": "./data/db",
    "redis_url": "redis://localhost:6379",
    "redis_pool_size": 10,
    "redis_key_prefix": "atous",
    "cache_ttl": 3600
  },
  "security": {
    "public_key_path": "./keys/public_key.pem",
    "private_key_path": "./keys/private_key.pem",
    "pqc_algorithm": "Dilithium",
    "jwt_ttl": 3600
  },
  "metrics": {
    "enabled": true,
    "port": 9090,
    "path": "/metrics"
  }
} [graph]
# If 1 or more target triples (and optionally, target_features) are specified,
# only the specified targets will be checked when running `cargo deny check`.
# This means, if a particular package is only ever used as a target specific
# dependency, such as, for example, `winapi` or `nix`, a problem with that package
# will not cause `cargo deny check` to fail unless the target is explicitly
# specified in this list.
targets = [
    # The triple can be any string, but only the target triples built in to
    # rustc (as of 1.40) can be checked against actual config
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-pc-windows-msvc",
    "x86_64-apple-darwin",
]
# The feature set, if any, to use for the crate. If not specified, all features
# are used.
all-features = false
# The feature set, if any, to use for the crate. This is mutually exclusive with `all-features`.
# features = []
# If set to true, `cargo deny check` will not error if there are unused dependencies.
exclude-dev = false

[licenses]
# List of explicitly allowed licenses
allow = [
    "MIT",
    "Apache-2.0",
    "Apache-2.0 WITH LLVM-exception",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Unicode-DFS-2016",
]
# List of explicitly disallowed licenses
deny = [
    "GPL-2.0",
    "GPL-3.0",
    "AGPL-1.0",
    "AGPL-3.0",
]
# Lint level for when multiple versions of the same license are detected
multiple-versions = "warn"
# Confidence threshold for detecting a license from a license text.
# Expressed as a floating point number in (0.0, 1.0] range, with
# 1.0 meaning perfect confidence
confidence-threshold = 0.8
# Allow 1 or more licenses on a per-crate basis, so that particular licenses
# aren't accepted for every possible crate as with the normal allow list
exceptions = [
    # Each entry is the crate and version constraint, and its the license
    { allow = ["OpenSSL"], name = "ring", version = "*" },
]

# Some crates don't have (easily) machine readable licensing information,
# adding a clarification entry for it allows you to manually specify the
# licensing information
[[licenses.clarify]]
# The name of the crate the clarification applies to
name = "ring"
# The optional version constraint for the crate
version = "*"
# The SPDX expression for the license requirements of the crate
expression = "MIT AND ISC AND OpenSSL"
# One or more files in the crate's source used as the "source of truth" for
# the license expression. If the files are missing, or do not contain the
# specified license text, the clarification will fail
license-files = [
    { path = "LICENSE", hash = 0xbd0eed23 },
]

[bans]
# Lint level for when multiple versions of the same crate are detected
multiple-versions = "warn"
# Lint level for when a crate version requirement is `*`
wildcards = "allow"
# The graph highlighting used when creating dotgraphs for crates
# with multiple versions
highlight = "all"
# The default lint level for `default` features, if not specified in `features`
default-features = "allow"
# The feature set to use for each crate
features = []
# List of crates that are allowed. Use with care!
allow = []
# List of crates to deny
deny = [
    # Each entry the name of a crate and a version range. If version is
    # not specified, all versions will be matched.
    #{ name = "ansi_term", version = "=0.11.0" },
    
    # Wrapper crates can optionally be specified to allow the crate when it
    # is a direct dependency of the otherwise banned crate
    #{ name = "ansi_term", version = "=0.11.0", wrappers = [] },
]

# Certain crates/versions that will be skipped when doing duplicate detection.
skip = [
    #{ name = "ansi_term", version = "=0.11.0" },
]
# Similarly to `skip` allows you to skip certain crates from being checked. Unlike `skip`,
# `skip-tree` skips the crate and all of its dependencies entirely.
skip-tree = [
    #{ name = "ansi_term", version = "=0.11.0" },
]

[advisories]
# The path where the advisory database is cloned/fetched into
db-path = "~/.cargo/advisory-db"
# The url(s) of the advisory databases to use
db-urls = ["https://github.com/rustsec/advisory-db"]
# The lint level for security vulnerabilities
vulnerability = "deny"
# The lint level for unmaintained crates
unmaintained = "warn"
# The lint level for crates that have been yanked from their source registry
yanked = "warn"
# The lint level for crates with security notices. Note that as of
# 2019-12-17 there are no security notice advisories in
# https://github.com/rustsec/advisory-db
notice = "warn"
# A list of advisory IDs to ignore. Note that ignored advisories will still
# output a note when they are encountered.
ignore = [
    #"RUSTSEC-0000-0000",
]
# Threshold for security vulnerabilities, any vulnerability with a CVSS score
# lower than this value will be ignored. Note that ignored advisories will still
# output a note when they are encountered.
# * None (default) - CVSS Score 0.0
# * Low - CVSS Score 0.1 - 3.9
# * Medium - CVSS Score 4.0 - 6.9
# * High - CVSS Score 7.0 - 8.9
# * Critical - CVSS Score 9.0 - 10.0
#severity-threshold = 

[sources]
# Lint level for what to happen when a crate from a crate registry that is
# not in the allow list is encountered
unknown-registry = "warn"
# Lint level for what to happen when a crate from a git repository that is not
# in the allow list is encountered
unknown-git = "warn"
# List of URLs for allowed crate registries. Defaults to the crates.io index
# if not specified. If it is specified but empty, no registries are allowed.
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
# List of URLs for allowed Git repositories
allow-git = [] {
  "authentication": {
    "jwt_secret": "doe_sere_secre_dk43n54h23092z223"
  },
  "web": {
    "listen": "0.0.0.0",
    "port": 8081,
    "api_path": "/api",
    "cors_origins": ["*"]
  },
  "websocket": {
    "rate_limiting": {
      "enabled": true,
      "requests_per_minute": 60,
      "burst_size": 10
    }
  }
} # Genesis Node Configuration
[node]
type = "genesis"
id = "genesis-001"
name = "Atous Security Genesis Node"
version = "0.1.0"

[network]
# P2P Network configuration
bind_address = "0.0.0.0:30333"
public_address = "genesis.atous.network:30333"
max_peers = 50
discovery_enabled = true
mdns_enabled = true
bootstrap_nodes = []

# HTTP API configuration
[api]
enabled = true
bind_address = "0.0.0.0:8080"
cors_enabled = true
cors_origins = ["*"]
max_request_size = 131072  # 128KB
rate_limit_per_minute = 60

# WebSocket configuration
[websocket]
enabled = true
bind_address = "0.0.0.0:9000"
max_connections = 100

# Security configuration
[security]
# JWT for API authentication
jwt_secret = "your-secure-jwt-secret-change-in-production"
jwt_expiry_hours = 24

# Rate limiting
rate_limit_enabled = true
rate_limit_max_requests = 5
rate_limit_window_minutes = 1

# Sybil protection
sybil_protection_enabled = true
max_nodes_per_ip = 3
sybil_analysis_window_hours = 1

# Neural immune system
neural_immune_enabled = true
min_reputation_threshold = 500
min_flags_for_isolation = 3
consensus_threshold = 0.67

[storage]
data_dir = "/app/data"
blockchain_path = "/app/data/blockchain"
logs_path = "/app/logs"
max_log_size_mb = 100
log_rotation_days = 7

[consensus]
# Genesis node specific settings
is_genesis = true
genesis_timestamp = 1704067200  # 2024-01-01 00:00:00 UTC
initial_validators = ["genesis-001"]
block_time_seconds = 10
max_block_size = 1048576  # 1MB

[monitoring]
metrics_enabled = true
prometheus_endpoint = "0.0.0.0:9615"
telemetry_enabled = false
health_check_interval_seconds = 30

[logging]
level = "info"
format = "json"
file_enabled = true
console_enabled = true

# Performance tuning
[performance]
worker_threads = 4
max_blocking_threads = 8
thread_stack_size = 2097152  # 2MB
gc_threshold_mb = 256

# Development and testing
[development]
dev_mode = false
test_mode = false
mock_time = false
skip_genesis_validation = false #!/bin/bash

# Atous Network-Specific Security Tests
# Test Session ID: 9581f195-8fa1-431f-a6e4-157486aa0dc1
# Tests specific to Atous P2P network security implementations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

TEST_SESSION_ID="9581f195-8fa1-431f-a6e4-157486aa0dc1"
TARGET_HOST="localhost"
API_PORT="8081"
P2P_PORT="8083"

echo -e "${BLUE}=== Atous Network-Specific Security Tests ===${NC}"
echo -e "Test Session ID: ${YELLOW}${TEST_SESSION_ID}${NC}"
echo ""

# Function to log test results
log_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}[FAIL]${NC} $test_name"
    elif [ "$result" = "VULN" ]; then
        echo -e "${RED}[VULNERABILITY]${NC} $test_name"
    else
        echo -e "${YELLOW}[INFO]${NC} $test_name"
    fi
    
    if [ -n "$details" ]; then
        echo "       $details"
    fi
    echo ""
}

# Test Sybil Protection Implementation
test_sybil_protection_detailed() {
    echo -e "${PURPLE}=== Advanced Sybil Protection Tests ===${NC}"
    
    # Test 1: IP-based peer limiting (based on your config: max_peers_per_ip)
    echo "Testing IP-based peer limiting..."
    
    # Simulate multiple peer connections from same IP
    blocked_count=0
    accepted_count=0
    
    for i in {1..10}; do
        # Create unique peer IDs
        peer_id="peer-${i}-${RANDOM}"
        
        # Attempt to register/connect peer
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            -X POST \
            -H "Content-Type: application/json" \
            -H "X-Real-IP: 192.168.1.100" \
            -d "{\"peer_id\":\"$peer_id\",\"action\":\"connect\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
        
        if [ "$response" = "429" ] || [ "$response" = "403" ]; then
            ((blocked_count++))
            log_test "Sybil IP limit test #$i" "PASS" "Peer blocked: HTTP $response"
        elif [ "$response" = "200" ] || [ "$response" = "201" ]; then
            ((accepted_count++))
        fi
        
        sleep 0.1
    done
    
    if [ $blocked_count -gt 0 ]; then
        log_test "IP-based Sybil protection" "PASS" "$blocked_count/$((blocked_count + accepted_count)) connections blocked"
    else
        log_test "IP-based Sybil protection" "VULN" "All connections accepted - no IP limiting detected"
    fi
    
    # Test 2: Churn detection (rapid connect/disconnect)
    echo "Testing churn detection..."
    
    for i in {1..20}; do
        peer_id="churn-peer-${i}"
        
        # Connect
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"peer_id\":\"$peer_id\",\"action\":\"connect\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/flags > /dev/null 2>&1
        
        # Disconnect immediately
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"peer_id\":\"$peer_id\",\"action\":\"disconnect\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/flags > /dev/null 2>&1
        
        sleep 0.05  # Very rapid churn
    done
    
    # Try one more connection after rapid churn
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"peer_id\":\"final-churn-test\",\"action\":\"connect\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
        http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
    
    if [ "$response" = "429" ] || [ "$response" = "403" ]; then
        log_test "Churn detection" "PASS" "Rapid churn detected and blocked: HTTP $response"
    else
        log_test "Churn detection" "VULN" "Rapid churn not detected: HTTP $response"
    fi
}

# Test Eclipse Protection Implementation
test_eclipse_protection_detailed() {
    echo -e "${PURPLE}=== Advanced Eclipse Protection Tests ===${NC}"
    
    # Test subnet diversity enforcement
    echo "Testing subnet diversity enforcement..."
    
    # Based on your config: min_distinct_subnets = 5
    subnets=(
        "192.168.1"
        "192.168.1"  # Same subnet repeated
        "192.168.1"
        "192.168.1"
        "192.168.1"
        "10.0.0"     # Different subnet
        "172.16.0"   # Different subnet
    )
    
    subnet_blocked=false
    
    for i in "${!subnets[@]}"; do
        subnet="${subnets[$i]}"
        ip="${subnet}.$((i+1))"
        
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            -X POST \
            -H "Content-Type: application/json" \
            -H "X-Forwarded-For: $ip" \
            -d "{\"peer_id\":\"subnet-test-$i\",\"bucket_id\":\"test-bucket\",\"action\":\"join\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
        
        if [ "$response" = "429" ] || [ "$response" = "403" ]; then
            subnet_blocked=true
            log_test "Subnet diversity test #$i" "PASS" "Subnet $subnet connection blocked: HTTP $response"
        fi
        
        sleep 0.1
    done
    
    if [ "$subnet_blocked" = true ]; then
        log_test "Eclipse subnet protection" "PASS" "Subnet concentration detected and blocked"
    else
        log_test "Eclipse subnet protection" "VULN" "No subnet diversity enforcement detected"
    fi
    
    # Test bucket segregation
    echo "Testing bucket segregation..."
    
    # Try to fill multiple buckets with same subnet
    for bucket in "bucket-1" "bucket-2" "bucket-3"; do
        for peer_num in {1..3}; do
            response=$(curl -s -w "%{http_code}" -o /dev/null \
                -X POST \
                -H "Content-Type: application/json" \
                -H "X-Forwarded-For: 192.168.100.$peer_num" \
                -d "{\"peer_id\":\"bucket-test-$bucket-$peer_num\",\"bucket_id\":\"$bucket\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
                http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
            
            if [ "$response" = "403" ] || [ "$response" = "429" ]; then
                log_test "Bucket protection" "PASS" "Bucket $bucket protected against same-subnet flooding"
                break
            fi
        done
    done
}

# Test P2P Network Protocol Security
test_p2p_protocol_security() {
    echo -e "${PURPLE}=== P2P Protocol Security Tests ===${NC}"
    
    # Test if P2P port accepts malformed libp2p messages
    if command -v nc &> /dev/null; then
        echo "Testing P2P port with malformed data..."
        
        # Send malformed data to P2P port
        echo "MALFORMED_P2P_DATA" | timeout 3 nc ${TARGET_HOST} ${P2P_PORT} > /tmp/p2p_test 2>&1
        
        if [ $? -eq 0 ] && [ -s /tmp/p2p_test ]; then
            log_test "P2P malformed data handling" "VULN" "P2P port accepted malformed data"
        else
            log_test "P2P malformed data handling" "PASS" "P2P port rejected malformed data"
        fi
        
        rm -f /tmp/p2p_test
    fi
    
    # Test Noise protocol implementation (if accessible)
    echo "Testing Noise protocol security..."
    
    # This would require actual libp2p client - simulate by checking if port responds to HTTP
    response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 2 http://${TARGET_HOST}:${P2P_PORT}/ 2>/dev/null)
    
    if [ "$response" = "000" ] || [ -z "$response" ]; then
        log_test "Noise protocol isolation" "PASS" "P2P port doesn't respond to HTTP (properly isolated)"
    else
        log_test "P2P HTTP exposure" "VULN" "P2P port responds to HTTP: $response"
    fi
}

# Test Cryptographic Implementation
test_cryptographic_security() {
    echo -e "${PURPLE}=== Cryptographic Security Tests ===${NC}"
    
    # Test post-quantum cryptography configuration
    response=$(curl -s http://${TARGET_HOST}:${API_PORT}/api/config 2>/dev/null)
    
    if echo "$response" | grep -qi "ml-kem-768\|dilithium\|post.*quantum"; then
        log_test "Post-quantum crypto" "PASS" "Post-quantum algorithms detected in config"
    else
        log_test "Post-quantum crypto" "INFO" "Post-quantum crypto config not visible"
    fi
    
    # Test encryption algorithm support
    algorithms=("chacha20poly1305" "aes256gcm")
    
    for algo in "${algorithms[@]}"; do
        # Test if algorithm is supported (this would need actual crypto endpoint)
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"algorithm\":\"$algo\",\"test\":\"encryption_support\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/crypto/test 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            log_test "Encryption algorithm $algo" "INFO" "Algorithm test endpoint available"
        fi
    done
}

# Test Flag System Security
test_flag_system_security() {
    echo -e "${PURPLE}=== Flag System Security Tests ===${NC}"
    
    # Test flag validation with invalid signatures
    echo "Testing flag validation..."
    
    invalid_flag='{
        "reporter_id": "malicious-node",
        "target_node": "'${TEST_SESSION_ID}'",
        "flag_type": "MALICIOUS_BEHAVIOR",
        "evidence": "fake evidence",
        "signature": "invalid_signature_data",
        "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    }'
    
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$invalid_flag" \
        http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
    
    if [ "$response" = "400" ] || [ "$response" = "401" ] || [ "$response" = "422" ]; then
        log_test "Flag signature validation" "PASS" "Invalid signature rejected: HTTP $response"
    else
        log_test "Flag signature bypass" "VULN" "Invalid signature accepted: HTTP $response"
    fi
    
    # Test flag spam protection
    echo "Testing flag spam protection..."
    
    spam_count=0
    blocked_count=0
    
    for i in {1..20}; do
        spam_flag='{
            "reporter_id": "spam-reporter-'$i'",
            "target_node": "'${TEST_SESSION_ID}'",
            "flag_type": "SPAM_TEST",
            "evidence": "spam test #'$i'",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }'
        
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$spam_flag" \
            http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
        
        if [ "$response" = "429" ] || [ "$response" = "403" ]; then
            ((blocked_count++))
        else
            ((spam_count++))
        fi
        
        sleep 0.1
    done
    
    if [ $blocked_count -gt 0 ]; then
        log_test "Flag spam protection" "PASS" "$blocked_count/20 spam flags blocked"
    else
        log_test "Flag spam vulnerability" "VULN" "All spam flags accepted"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting Atous network-specific security tests...${NC}\n"
    
    # Check if target is reachable
    if ! curl -s --max-time 5 http://${TARGET_HOST}:${API_PORT}/api/metrics/energy > /dev/null 2>&1; then
        echo -e "${RED}Error: Target ${TARGET_HOST}:${API_PORT} is not reachable${NC}"
        echo "Please ensure the Atous server is running."
        exit 1
    fi
    
    test_sybil_protection_detailed
    test_eclipse_protection_detailed
    test_p2p_protocol_security
    test_cryptographic_security
    test_flag_system_security
    
    echo -e "${BLUE}=== Network-Specific Security Testing Complete ===${NC}"
    echo -e "Test Session ID: ${YELLOW}${TEST_SESSION_ID}${NC}"
    echo ""
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "1. Review any VULNERABILITY findings immediately"
    echo "2. Verify Sybil protection configuration in config.json"
    echo "3. Check Eclipse protection subnet diversity settings"
    echo "4. Ensure post-quantum cryptography is properly enabled"
    echo "5. Validate flag system signature verification"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "- Run the general penetration test suite: ./penetration_test_suite.sh"
    echo "- Monitor logs for security events during testing"
    echo "- Update security configurations based on findings"
}

# Execute main function
main "$@" #!/bin/bash

# Atous Network Security Penetration Testing Suite
# Test Session ID: 9581f195-8fa1-431f-a6e4-157486aa0dc1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test configuration
TEST_SESSION_ID="9581f195-8fa1-431f-a6e4-157486aa0dc1"
TARGET_HOST="localhost"
API_PORT="8081"
WS_PORT="8082"
P2P_PORT="8083"
METRICS_PORT="9090"

echo -e "${BLUE}=== Atous Network Security Penetration Testing Suite ===${NC}"
echo -e "Test Session ID: ${YELLOW}${TEST_SESSION_ID}${NC}"
echo -e "Target: ${TARGET_HOST}:${API_PORT}"
echo ""

# Function to log test results
log_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}[FAIL]${NC} $test_name"
    elif [ "$result" = "VULN" ]; then
        echo -e "${RED}[VULNERABILITY]${NC} $test_name"
    else
        echo -e "${YELLOW}[INFO]${NC} $test_name"
    fi
    
    if [ -n "$details" ]; then
        echo "       $details"
    fi
    echo ""
}

# Test 1: Rate Limiting Protection
test_rate_limiting() {
    echo -e "${PURPLE}=== Test 1: Rate Limiting Protection ===${NC}"
    
    # Test normal request rate
    response=$(curl -s -w "%{http_code}" -o /dev/null http://${TARGET_HOST}:${API_PORT}/api/metrics/energy)
    if [ "$response" = "200" ]; then
        log_test "Normal API request" "PASS" "HTTP $response"
    else
        log_test "Normal API request" "FAIL" "HTTP $response"
    fi
    
    # Test rapid requests (potential DDoS)
    echo "Testing rapid requests (100 requests in 5 seconds)..."
    success_count=0
    rate_limited_count=0
    
    for i in {1..100}; do
        response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 1 http://${TARGET_HOST}:${API_PORT}/api/metrics/energy 2>/dev/null)
        if [ "$response" = "200" ]; then
            ((success_count++))
        elif [ "$response" = "429" ]; then
            ((rate_limited_count++))
        fi
        sleep 0.05
    done
    
    if [ $rate_limited_count -gt 0 ]; then
        log_test "Rate limiting active" "PASS" "Rate limited: $rate_limited_count/100 requests"
    else
        log_test "Rate limiting bypass" "VULN" "All requests succeeded - rate limiting may be disabled"
    fi
}

# Test 2: Authentication Bypass
test_authentication() {
    echo -e "${PURPLE}=== Test 2: Authentication Bypass ===${NC}"
    
    # Test unauthenticated access to protected endpoints
    endpoints=(
        "/api/flags"
        "/api/node/${TEST_SESSION_ID}/status"
        "/api/network/status"
        "/metrics"
    )
    
    for endpoint in "${endpoints[@]}"; do
        response=$(curl -s -w "%{http_code}" -o /dev/null http://${TARGET_HOST}:${API_PORT}${endpoint})
        
        if [ "$response" = "401" ] || [ "$response" = "403" ]; then
            log_test "Auth required for $endpoint" "PASS" "HTTP $response"
        elif [ "$response" = "200" ]; then
            log_test "Unauthenticated access to $endpoint" "VULN" "HTTP $response - No authentication required"
        else
            log_test "Endpoint $endpoint" "INFO" "HTTP $response"
        fi
    done
    
    # Test JWT manipulation
    fake_jwt="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkF0dGFja2VyIiwiaWF0IjoxNTE2MjM5MDIyfQ.invalid_signature"
    
    response=$(curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Bearer $fake_jwt" http://${TARGET_HOST}:${API_PORT}/api/flags)
    
    if [ "$response" = "401" ] || [ "$response" = "403" ]; then
        log_test "JWT validation" "PASS" "HTTP $response - Invalid JWT rejected"
    else
        log_test "JWT bypass" "VULN" "HTTP $response - Invalid JWT accepted"
    fi
}

# Test 3: Input Validation & Injection
test_input_validation() {
    echo -e "${PURPLE}=== Test 3: Input Validation & Injection ===${NC}"
    
    # SQL Injection attempts
    sql_payloads=(
        "'; DROP TABLE flags; --"
        "' OR '1'='1"
        "1' UNION SELECT * FROM users --"
    )
    
    for payload in "${sql_payloads[@]}"; do
        response=$(curl -s -w "%{http_code}" -o /dev/null -G -d "node_id=$payload" http://${TARGET_HOST}:${API_PORT}/api/node/status)
        
        if [ "$response" = "400" ] || [ "$response" = "422" ]; then
            log_test "SQL injection protection" "PASS" "Payload blocked: $payload"
        elif [ "$response" = "500" ]; then
            log_test "Potential SQL injection" "VULN" "Server error with payload: $payload"
        fi
    done
    
    # XSS attempts
    xss_payloads=(
        "<script>alert('xss')</script>"
        "javascript:alert('xss')"
        "<img src=x onerror=alert('xss')>"
    )
    
    for payload in "${xss_payloads[@]}"; do
        response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"node_id\":\"$payload\"}" http://${TARGET_HOST}:${API_PORT}/api/flags)
        
        if [ "$(echo $response | grep -c '<script>')" -eq 0 ]; then
            log_test "XSS protection" "PASS" "Payload sanitized: $payload"
        else
            log_test "Potential XSS" "VULN" "Payload reflected: $payload"
        fi
    done
}

# Test 4: Network Protocol Security
test_network_security() {
    echo -e "${PURPLE}=== Test 4: Network Protocol Security ===${NC}"
    
    # Test P2P port accessibility
    if nc -z ${TARGET_HOST} ${P2P_PORT} 2>/dev/null; then
        log_test "P2P port accessible" "INFO" "Port ${P2P_PORT} is open"
        
        # Test if P2P port accepts HTTP requests (should not)
        response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 2 http://${TARGET_HOST}:${P2P_PORT}/ 2>/dev/null)
        if [ "$response" = "000" ] || [ -z "$response" ]; then
            log_test "P2P port security" "PASS" "Port does not respond to HTTP"
        else
            log_test "P2P HTTP response" "VULN" "P2P port responds to HTTP: $response"
        fi
    else
        log_test "P2P port" "INFO" "Port ${P2P_PORT} is closed/filtered"
    fi
    
    # Test WebSocket security
    if command -v websocat &> /dev/null; then
        echo "Testing WebSocket connection..."
        timeout 3 websocat ws://${TARGET_HOST}:${WS_PORT}/ws --text --oneshot <<< "test" > /tmp/ws_test 2>&1
        
        if grep -q "WebSocket connection" /tmp/ws_test; then
            log_test "WebSocket connection" "INFO" "WebSocket accepts connections"
        else
            log_test "WebSocket security" "PASS" "WebSocket connection restricted"
        fi
        rm -f /tmp/ws_test
    else
        log_test "WebSocket test" "INFO" "websocat not available - skipping"
    fi
}

# Test 5: DoS Resistance
test_dos_resistance() {
    echo -e "${PURPLE}=== Test 5: DoS Resistance ===${NC}"
    
    # Test connection flooding
    echo "Testing connection flooding..."
    connections=0
    for i in {1..50}; do
        if curl -s --max-time 1 http://${TARGET_HOST}:${API_PORT}/api/metrics/energy > /dev/null 2>&1; then
            ((connections++))
        fi &
    done
    
    wait
    
    if [ $connections -lt 50 ]; then
        log_test "Connection limiting" "PASS" "Only $connections/50 connections succeeded"
    else
        log_test "Connection flooding" "VULN" "All $connections connections succeeded"
    fi
    
    # Test memory exhaustion via large payloads
    large_payload=$(python3 -c "print('A' * 1000000)")  # 1MB payload
    response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 5 -X POST -d "$large_payload" http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
    
    if [ "$response" = "413" ] || [ "$response" = "400" ]; then
        log_test "Large payload protection" "PASS" "HTTP $response"
    elif [ "$response" = "000" ]; then
        log_test "Large payload handling" "PASS" "Connection timeout/reset"
    else
        log_test "Large payload acceptance" "VULN" "HTTP $response - Large payload accepted"
    fi
}

# Test 6: Information Disclosure
test_information_disclosure() {
    echo -e "${PURPLE}=== Test 6: Information Disclosure ===${NC}"
    
    # Test for exposed configuration
    sensitive_endpoints=(
        "/config"
        "/config.json"
        "/api/config"
        "/.env"
        "/debug"
        "/api/debug"
        "/status"
        "/health"
    )
    
    for endpoint in "${sensitive_endpoints[@]}"; do
        response=$(curl -s -w "%{http_code}" -o /tmp/response http://${TARGET_HOST}:${API_PORT}${endpoint} 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            if grep -qi "password\|secret\|key\|token" /tmp/response; then
                log_test "Information disclosure" "VULN" "$endpoint exposes sensitive data"
            else
                log_test "Endpoint accessibility" "INFO" "$endpoint accessible but no sensitive data visible"
            fi
        fi
    done
    
    rm -f /tmp/response
    
    # Test error message disclosure
    response=$(curl -s http://${TARGET_HOST}:${API_PORT}/api/nonexistent/endpoint)
    if echo "$response" | grep -qi "stack trace\|error.*line\|debug\|exception"; then
        log_test "Error message disclosure" "VULN" "Detailed error messages exposed"
    else
        log_test "Error handling" "PASS" "Generic error messages"
    fi
}

# Test 7: Sybil Attack Simulation
test_sybil_attack() {
    echo -e "${PURPLE}=== Test 7: Sybil Attack Simulation ===${NC}"
    
    # Simulate multiple connections from same IP
    echo "Simulating Sybil attack (multiple node IDs from same IP)..."
    
    sybil_nodes=()
    for i in {1..10}; do
        node_id=$(uuidgen 2>/dev/null || echo "node-$i-$RANDOM")
        sybil_nodes+=($node_id)
        
        response=$(curl -s -w "%{http_code}" -o /dev/null -X POST -H "Content-Type: application/json" \
            -d "{\"node_id\":\"$node_id\",\"session_id\":\"${TEST_SESSION_ID}\"}" \
            http://${TARGET_HOST}:${API_PORT}/api/flags 2>/dev/null)
        
        if [ "$response" = "429" ] || [ "$response" = "403" ]; then
            log_test "Sybil protection active" "PASS" "Connection $i blocked: HTTP $response"
            break
        fi
    done
    
    if [ ${#sybil_nodes[@]} -eq 10 ]; then
        log_test "Sybil attack successful" "VULN" "All 10 fake nodes accepted"
    fi
}

# Test 8: Eclipse Attack Simulation
test_eclipse_attack() {
    echo -e "${PURPLE}=== Test 8: Eclipse Attack Simulation ===${NC}"
    
    # Test subnet diversity requirements
    subnets=("192.168.1" "192.168.2" "10.0.0" "172.16.0")
    
    for subnet in "${subnets[@]}"; do
        # Simulate connections from multiple IPs in same subnet
        for i in {1..5}; do
            # This is a simulation - in real test you'd need to actually connect from different IPs
            response=$(curl -s -w "%{http_code}" -o /dev/null \
                -H "X-Forwarded-For: ${subnet}.$i" \
                -H "X-Real-IP: ${subnet}.$i" \
                http://${TARGET_HOST}:${API_PORT}/api/metrics/energy 2>/dev/null)
            
            if [ "$response" = "403" ] || [ "$response" = "429" ]; then
                log_test "Eclipse protection" "PASS" "Subnet $subnet connections limited"
                break
            fi
        done
    done
}

# Main execution
main() {
    echo -e "${BLUE}Starting comprehensive penetration testing...${NC}\n"
    
    # Check if target is reachable
    if ! curl -s --max-time 5 http://${TARGET_HOST}:${API_PORT}/api/metrics/energy > /dev/null; then
        echo -e "${RED}Error: Target ${TARGET_HOST}:${API_PORT} is not reachable${NC}"
        echo "Please ensure the Atous server is running."
        exit 1
    fi
    
    test_rate_limiting
    test_authentication
    test_input_validation
    test_network_security
    test_dos_resistance
    test_information_disclosure
    test_sybil_attack
    test_eclipse_attack
    
    echo -e "${BLUE}=== Penetration Testing Complete ===${NC}"
    echo -e "Test Session ID: ${YELLOW}${TEST_SESSION_ID}${NC}"
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo "- Review all VULNERABILITY findings immediately"
    echo "- INFO findings should be evaluated for security implications"
    echo "- PASS results indicate security controls are working"
    echo ""
    echo -e "${RED}⚠️  This tool is for authorized testing only${NC}"
    echo -e "${RED}⚠️  Do not use against systems you don't own${NC}"
}

# Execute main function
main "$@" global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'atous'
    static_configs:
      - targets: ['atous:9090']
    
  - job_name: 'bootstrap'
    static_configs:
      - targets: ['bootstrap:9090']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']   Compiling atous-security-fixes v0.1.0 (/home/atous-security/Documentos/projects/rust)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 12.06s
     Running `target/debug/atous-security-fixes`
[2025-06-02T20:01:11Z INFO  actix_server::builder] starting 2 workers
[2025-06-02T20:01:11Z INFO  atous_security_fixes] 🚀 Atous Security Server running at http://127.0.0.1:8081
[2025-06-02T20:01:11Z INFO  atous_security_fixes] 🔒 API endpoints available at http://127.0.0.1:8081/api
[2025-06-02T20:01:11Z INFO  atous_security_fixes] 📊 Metrics endpoint available at http://127.0.0.1:8081/api/metrics (AUTH REQUIRED)
[2025-06-02T20:01:11Z INFO  atous_security_fixes] 🛡️ ENHANCED SECURITY FIXES APPLIED:
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Authentication middleware runs BEFORE rate limiting
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Payload size LIMITED to 128KB (reduced from 256KB)
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ JSON payload LIMITED to 128KB
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Form data LIMITED to 64KB
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Flag signature validation enabled
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Rate limiting: 5 req/min, 2 concurrent (REDUCED)
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Sybil protection: max 1 node per IP (STRICTER)
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Metrics endpoint protected by authentication
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ CORS restricted to specific origins
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Connection limits: 100 max, 10/sec rate
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   ✅ Request timeout: 10 seconds
[2025-06-02T20:01:11Z INFO  atous_security_fixes]   🔐 VULNERABILITY FIXES: Large payload protection enhanced
[2025-06-02T20:01:11Z INFO  actix_server::server] Actix runtime found; starting in Actix runtime
[2025-06-02T20:01:11Z INFO  actix_server::server] starting service: "actix-web-service-127.0.0.1:8081", workers: 2, listening on: 127.0.0.1:8081
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000205
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000085
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000075
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000125
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000113
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000086
[2025-06-02T20:02:14Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET /health HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000069
[2025-06-02T20:02:19Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET / HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000068
[2025-06-02T20:02:19Z WARN  atous_security_fixes::middleware::rate_limit] Rate limit violation from 127.0.0.1:curl/8.5.0: Rate limit exceeded: 5 requests per minute (max: 5)
[2025-06-02T20:02:19Z INFO  actix_web::middleware::logger] 127.0.0.1 "GET / HTTP/1.1" 404 0 "-" "curl/8.5.0" 0.000072
[2025-06-02T20:02:19Z WARN  atous_security_fixes::middleware::rate_limit] Rate limit violation from 127.0.0.1:curl/8.5.0: Rate limit exceeded: 5 requests per minute (max: 5)
[2025-06-02T20:02:19Z WARN  atous_security_fixes::middleware::rate_limit] Rate limit violation from 127.0.0.1:curl/8.5.0: Rate limit exceeded: 5 requests per minute (max: 5)
[2025-06-02T20:02:19Z WARN  atous_security_fixes::middleware::rate_limit] Rate limit violation from 127.0.0.1:curl/8.5.0: Rate limit exceeded: 5 requests per minute (max: 5)
[2025-06-02T20:02:19Z WARN  atous_security_fixes::middleware::rate_limit] Rate limit violation from 127.0.0.1:curl/8.5.0: Rate limit exceeded: 5 requests per minute (max: 5)
[2025-06-02T20:23:11Z INFO  actix_server::server] SIGTERM received; starting graceful shutdown
[2025-06-02T20:23:11Z INFO  actix_server::worker] shutting down idle worker
[2025-06-02T20:23:11Z INFO  actix_server::worker] shutting down idle worker
[2025-06-02T20:23:11Z INFO  actix_server::accept] accept thread stopped