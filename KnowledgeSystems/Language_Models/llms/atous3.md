   fn call(&self, req: ServiceRequest) -> Self::Future {
        // Clone do serviço e identity_service para usar dentro do future
        let service = self.service.clone();
        let identity_service = self.identity_service.clone();

        Box::pin(async move {
            // Verificar o cabeçalho Authorization
            if let Some(auth_header) = req.headers().get("Authorization") {
                // Formato esperado: "Bearer did:atous:xyz"
                if let Ok(auth_str) = auth_header.to_str() {
                    if auth_str.starts_with("Bearer ") {
                        let did_str = auth_str.trim_start_matches("Bearer ").trim();
                        
                        // Tenta parsear o DID
                        match DID::parse(did_str) {
                            Ok(did) => {
                                // Verifica se o DID é válido
                                match identity_service.as_async().verify_identity(&did).await {
                                    Ok(true) => {
                                        // DID válido, continua o processamento
                                        // Adiciona o DID na extensão da requisição para uso posterior
                                        req.extensions_mut().insert(did);
                                        let res = service.call(req).await?;
                                        return Ok(res);
                                    }
                                    Ok(false) => {
                                        // DID inválido ou revogado
                                        return Err(actix_web::error::ErrorUnauthorized("DID inválido ou revogado"));
                                    }
                                    Err(e) => {
                                        // Erro ao verificar DID
                                        log::error!("Erro ao verificar DID: {}", e);
                                        return Err(actix_web::error::ErrorInternalServerError(
                                            "Erro ao verificar identidade",
                                        ));
                                    }
                                }
                            }
                            Err(_) => {
                                // DID mal formatado
                                return Err(actix_web::error::ErrorBadRequest("Formato de DID inválido"));
                            }
                        }
                    }
                }
            }
            
            // Se não tem Authorization header válido
            Err(actix_web::error::ErrorUnauthorized("Autorização necessária"))
        })
    }
}

/// Extrator para obter o DID autenticado da requisição
pub struct AuthenticatedDID {
    pub did: DID,
}

impl FromRequest for AuthenticatedDID {
    type Error = actix_web::Error;
    type Future = BoxFuture<'static, Result<Self, Self::Error>>;

    fn from_request(req: &actix_web::HttpRequest, _: &mut actix_web::dev::Payload) -> Self::Future {
        let auth_header = req.headers().get("Authorization").cloned();
        let req_app_data = req.app_data::<Arc<dyn IdentityService>>().cloned();

        Box::pin(async move {
            let auth_header = auth_header.ok_or_else(|| 
                actix_web::error::ErrorUnauthorized("Missing Authorization header"))?;
                
            let auth_str = auth_header.to_str()
                .map_err(|_| actix_web::error::ErrorBadRequest("Invalid Authorization header"))?;
                
            let did_str = auth_str.strip_prefix("Bearer ")
                .ok_or_else(|| actix_web::error::ErrorBadRequest("Invalid Authorization format"))?;
                
            let did = DID::parse(did_str)
                .map_err(|_| actix_web::error::ErrorBadRequest("Invalid DID format"))?;
                
            let identity_service = req_app_data
                .ok_or_else(|| actix_web::error::ErrorInternalServerError("IdentityService not configured"))?;

            let is_valid = identity_service.as_async().verify_identity(&did).await
                .map_err(|e| actix_web::error::ErrorInternalServerError(format!("Error verifying DID: {}", e)))?;
                
            if is_valid {
                Ok(AuthenticatedDID { did })
            } else {
                Err(actix_web::error::ErrorUnauthorized("Invalid DID"))
            }
        })
    }
} use actix_web::{
    dev::ServiceResponse,
    HttpResponse,
};
use crate::adapters::web::actix::ApiResponse;

/// Error handler que formata todas as respostas de erro no formato padrão da API
pub struct ErrorHandler;

/// Implementa um conversor simples e direto para formatar erros da API
impl ErrorHandler {
    /// Cria uma nova instância do error handler
    pub fn new() -> Self {
        ErrorHandler
    }
    
    /// Formata qualquer erro de serviço para o formato padrão da API
    pub fn handle_error(&self, error: actix_web::Error) -> HttpResponse {
        let response_error = error.as_response_error();
        let status = response_error.status_code();
        
        // Obtém a mensagem de erro
        let error_message = format!("{}", response_error);
        
        // Log do erro
        log::error!("Erro na API: {} - {}", status, error_message);
        
        // Formata a resposta no padrão da API
        let api_response = ApiResponse::<()> {
            success: false,
            data: None,
            error: Some(error_message),
        };
        
        HttpResponse::build(status)
            .content_type("application/json")
            .json(api_response)
    }
}

impl Default for ErrorHandler {
    fn default() -> Self {
        Self::new()
    }
}

/// Implementa o transform para o middleware
impl<S, B> actix_web::dev::Transform<S, actix_web::dev::ServiceRequest> for ErrorHandler
where
    S: actix_web::dev::Service<
        actix_web::dev::ServiceRequest,
        Response = ServiceResponse<B>,
        Error = actix_web::Error,
    > + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = actix_web::Error;
    type InitError = ();
    type Transform = ErrorHandlerMiddleware<S>;
    type Future = futures::future::Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        futures::future::ok(ErrorHandlerMiddleware { 
            service,
            handler: self.clone(),
        })
    }
}

impl Clone for ErrorHandler {
    fn clone(&self) -> Self {
        Self::new()
    }
}

pub struct ErrorHandlerMiddleware<S> {
    service: S,
    handler: ErrorHandler,
}

impl<S, B> actix_web::dev::Service<actix_web::dev::ServiceRequest> for ErrorHandlerMiddleware<S>
where
    S: actix_web::dev::Service<
        actix_web::dev::ServiceRequest,
        Response = ServiceResponse<B>,
        Error = actix_web::Error,
    > + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = actix_web::Error;
    type Future = std::pin::Pin<Box<dyn std::future::Future<Output = Result<Self::Response, Self::Error>>>>;

    actix_web::dev::forward_ready!(service);

    fn call(&self, req: actix_web::dev::ServiceRequest) -> Self::Future {
        let service_future = self.service.call(req);
        let _handler = self.handler.clone();
        
        Box::pin(async move {
            // Simplesmente retorna o resultado do serviço
            // O erro será capturado pelo manipulador global de erros do Actix
            service_future.await
        })
    }
} use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    error::Error,
};
use futures::future::{ok, Ready};
use std::future::Future;
use std::pin::Pin;
use std::time::Instant;

/// Middleware para logging de requisições
pub struct RequestLogger;

impl Default for RequestLogger {
    fn default() -> Self {
        RequestLogger
    }
}

impl<S, B> Transform<S, ServiceRequest> for RequestLogger
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = RequestLoggerMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(RequestLoggerMiddleware { service })
    }
}

pub struct RequestLoggerMiddleware<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for RequestLoggerMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>>>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let start_time = Instant::now();
        let method = req.method().clone();
        let path = req.path().to_owned();
        
        // Log da requisição recebida
        log::info!("Request iniciada: {} {}", method, path);
        
        let fut = self.service.call(req);
        
        Box::pin(async move {
            // Executa o handler da requisição
            let res = fut.await?;
            
            // Calcula o tempo de processamento
            let elapsed = start_time.elapsed();
            let status = res.status();
            
            // Log da resposta
            log::info!(
                "Request concluída: {} {} - status: {} - tempo: {:.2?}",
                method,
                path,
                status.as_u16(),
                elapsed
            );
            
            Ok(res)
        })
    }
} pub mod auth;
pub mod logging;
pub mod error;

// Re-export middleware para facilitar o uso
pub use auth::AuthMiddleware;
pub use logging::RequestLogger;
pub use error::ErrorHandler; use std::sync::Arc;
use actix_web::{web, App, HttpServer, middleware, HttpResponse};
use actix_cors::Cors;
use actix_web::http::header;
use serde::{Serialize};
use crate::usecases::error::UseCaseError;
use crate::usecases::messaging::MessageService;
use crate::usecases::identity::IdentityService;
use crate::usecases::blockchain::BlockchainService;
use super::handlers::{identity, blockchain, messaging};
use super::middleware as custom_middleware;
use log::{info};
use crate::domain::identity::DID;

/// Contexto da aplicação
pub struct AppState {
    pub identity: DID,
    pub identity_service: Arc<dyn IdentityService>,
    pub message_service: Arc<dyn MessageService>,
    pub blockchain_service: Arc<dyn BlockchainService>,
}

/// Resposta padrão da API
#[derive(Debug, Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

/// Converte um UseCaseError em HttpResponse
pub fn error_to_http_response(error: UseCaseError) -> HttpResponse {
    match error {
        UseCaseError::NotFound(msg) => {
            HttpResponse::NotFound().json(ApiResponse::<()> {
                success: false,
                data: None,
                error: Some(msg),
            })
        }
        UseCaseError::Authorization(msg) => {
            HttpResponse::Forbidden().json(ApiResponse::<()> {
                success: false,
                data: None,
                error: Some(msg),
            })
        }
        UseCaseError::Database(msg) => {
            HttpResponse::InternalServerError().json(ApiResponse::<()> {
                success: false,
                data: None,
                error: Some(format!("Erro de banco de dados: {}", msg)),
            })
        }
        UseCaseError::Internal(msg) => {
            HttpResponse::InternalServerError().json(ApiResponse::<()> {
                success: false,
                data: None,
                error: Some(format!("Erro interno: {}", msg)),
            })
        }
        UseCaseError::Validation(msg) => {
            HttpResponse::BadRequest().json(ApiResponse::<()> {
                success: false,
                data: None,
                error: Some(msg),
            })
        }
        _ => HttpResponse::InternalServerError().json(ApiResponse::<()> {
            success: false,
            data: None,
            error: Some(format!("Erro desconhecido: {}", error)),
        }),
    }
}

/// Handler padrão para erros da aplicação
// fn default_error_handler(err: actix_web::Error, _req: &actix_web::HttpRequest) -> actix_web::Error {
//     // Log de erro
//     error!("API error: {}", err);
//     err
// }

async fn get_flags() -> HttpResponse {
    HttpResponse::Ok().json(ApiResponse::<()> {
        success: true,
        data: None,
        error: None,
    })
}

/// Inicia o servidor web
pub async fn run_server(
    host: &str,
    port: u16,
    identity_service: Arc<dyn IdentityService>,
    message_service: Arc<dyn MessageService>,
    blockchain_service: Arc<dyn BlockchainService>,
) -> std::io::Result<()> {
    let state = web::Data::new(AppState {
        identity: DID::new("system".to_string(), "0000000000000000000000000000000000000000"),
        identity_service: identity_service.clone(),
        message_service,
        blockchain_service,
    });
    
    let auth = web::Data::new(custom_middleware::auth::AuthMiddleware::new(identity_service.clone()));
    
    info!("Starting server at http://{}:{}", host, port);
    
    HttpServer::new(move || {
        let cors = Cors::default()
            .allowed_origin("http://localhost:3000")
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
            .allowed_headers(vec![header::AUTHORIZATION, header::ACCEPT])
            .allowed_header(header::CONTENT_TYPE)
            .max_age(3600);
            
        App::new()
            .wrap(cors)
            .wrap(middleware::Logger::default())
            .app_data(auth.clone())
            .app_data(state.clone())
            .service(
                web::scope("/api/v1")
                    .service(
                        web::scope("/identity")
                            .route("", web::post().to(identity::create_identity))
                            .route("/{did}", web::get().to(identity::get_identity))
                            .route("/{did}/metadata", web::put().to(identity::update_identity))
                            .route("/{did}/verify", web::post().to(identity::verify_identity))
                            .route("/search", web::post().to(identity::search_identities))
                    )
                    .service(
                        web::scope("/blockchain")
                            .route("/blocks", web::get().to(blockchain::get_latest_block))
                            .route("/blocks/{block_number}", web::get().to(blockchain::get_block))
                            .route("/did/{did}", web::get().to(blockchain::get_did_transactions))
                            .route("/sync", web::post().to(blockchain::sync_network))
                    )
                    .service(
                        web::scope("/messages")
                            .route("", web::post().to(messaging::send_message))
                            .route("", web::get().to(messaging::receive_messages))
                            .route("/{message_id}/read", web::post().to(messaging::mark_as_read))
                            .route("/search", web::post().to(messaging::search_messages))
                            .route("/conversations", web::get().to(messaging::get_conversations))
                            .route("/conversations/{conversation_id}", web::get().to(messaging::get_conversation_messages))
                    )
                    .service(
                        web::scope("/flags")
                            .route("", web::get().to(get_flags))
                    )
            )
    })
    .bind((host, port))?
    .run()
    .await
} pub mod actix;
pub mod websocket;
pub mod handlers;
pub mod middleware; use std::sync::Arc;
use tokio::sync::Mutex;
use warp::Filter;
use futures::StreamExt;
use crate::adapters::network::p2p::{P2PNetwork, NetworkMessage, NetworkMessageType};
use crate::usecases::error::UseCaseError;

pub struct WebSocketServer {
    network: Arc<Mutex<P2PNetwork>>,
}

impl WebSocketServer {
    pub fn new(network: Arc<Mutex<P2PNetwork>>) -> Self {
        Self { network }
    }

    pub async fn start(&self, port: u16) -> Result<(), UseCaseError> {
        let network = self.network.clone();
        
        let routes = warp::path("ws")
            .and(warp::ws())
            .map(move |ws: warp::ws::Ws| {
                let network = network.clone();
                ws.on_upgrade(move |websocket| {
                    async move {
                        let (_tx, mut rx) = websocket.split();
                        let network = network.clone();

                        // Handle incoming messages
                        while let Some(result) = rx.next().await {
                            match result {
                                Ok(msg) => {
                                    if msg.is_text() {
                                        if let Ok(msg_text) = msg.to_str() {
                                            let network_msg = NetworkMessage {
                                                message_type: NetworkMessageType::AtousMessage,
                                                source_did: None,
                                                target_did: None,
                                                payload: msg_text.as_bytes().to_vec(),
                                                topic: Some("atous/websocket".to_string()),
                                            };
                                            
                                            let net = network.lock().await;
                                            let handlers = net.get_message_handlers().await;
                                            for handler in handlers.iter() {
                                                if let Err(e) = handler.handle_message(network_msg.clone()).await {
                                                    log::error!("Handler failed to process message: {}", e);
                                                }
                                            }
                                        }
                                    }
                                }
                                Err(e) => {
                                    log::error!("WebSocket error: {}", e);
                                    break;
                                }
                            }
                        }
                        // Don't return a Result, as the on_upgrade handler expects ()
                        ()
                    }
                })
            });

        warp::serve(routes)
            .run(([0, 0, 0, 0], port))
            .await;

        Ok(())
    }
}use crate::usecases::error::UseCaseError;
use std::env;
use std::io::{self, Write};

pub struct CliAdapter {
    app_name: String,
}

impl CliAdapter {
    pub fn new(app_name: &str) -> Self {
        Self {
            app_name: app_name.to_string(),
        }
    }
    
    pub fn print_info(&self, message: &str) {
        println!("[{}] INFO: {}", self.app_name, message);
    }
    
    pub fn print_error(&self, message: &str) {
        eprintln!("[{}] ERROR: {}", self.app_name, message);
    }
    
    pub fn print_warning(&self, message: &str) {
        println!("[{}] WARNING: {}", self.app_name, message);
    }
    
    pub fn print_success(&self, message: &str) {
        println!("[{}] SUCCESS: {}", self.app_name, message);
    }
    
    pub fn read_input(&self, prompt: &str) -> Result<String, UseCaseError> {
        print!("{}: ", prompt);
        io::stdout().flush()
            .map_err(|e| UseCaseError::Internal(format!("Failed to flush stdout: {}", e)))?;
        
        let mut input = String::new();
        io::stdin().read_line(&mut input)
            .map_err(|e| UseCaseError::Internal(format!("Failed to read input: {}", e)))?;
            
        Ok(input.trim().to_string())
    }
    
    pub fn get_arg(&self, index: usize) -> Option<String> {
        env::args().nth(index)
    }
    
    pub fn get_args(&self) -> Vec<String> {
        env::args().collect()
    }
    
    pub fn get_env(&self, key: &str) -> Option<String> {
        env::var(key).ok()
    }
} pub mod persistence;
pub mod network;
pub mod crypto;
pub mod cli;
pub mod web;

// Re-exporta tipos e funções comuns
pub use persistence::redis::RedisClient;
pub use network::p2p::P2PNetwork;
pub use crypto::pqc::PQCProvider; use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use crate::usecases::error::UseCaseError;

/// Configuração da aplicação
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    /// Configurações do nó
    pub node: NodeConfig,
    /// Configurações de rede
    pub network: NetworkConfig,
    /// Configurações do blockchain
    pub blockchain: BlockchainConfig,
    /// Configurações do servidor web
    pub web: WebConfig,
    /// Configurações de persistência
    pub persistence: PersistenceConfig,
    /// Configurações de segurança
    pub security: SecurityConfig,
}

/// Configurações do nó
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct NodeConfig {
    /// Nome do nó
    pub name: String,
    /// Caminho para armazenar dados
    pub data_path: PathBuf,
    /// Nível de log
    pub log_level: String,
    /// Modo de operação
    pub mode: NodeMode,
}

/// Modo de operação do nó
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub enum NodeMode {
    /// Nó completo (participa de todas as operações)
    Full,
    /// Nó leve (apenas consulta)
    Light,
    /// Nó de bootstrap (usado para inicializar outros nós)
    Bootstrap,
    /// Nó validador (participa do consenso)
    Validator,
}

/// Configurações de rede
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct NetworkConfig {
    /// Endereço de escuta para P2P
    pub p2p_listen: String,
    /// Portas a exportar
    pub p2p_port: u16,
    /// Peers de bootstrap
    pub bootstrap_peers: Vec<String>,
    /// Habilitar descoberta via mDNS
    pub enable_mdns: bool,
    /// Habilitar descoberta via DHT (Kademlia)
    pub enable_kademlia: bool,
}

impl Default for NetworkConfig {
    fn default() -> Self {
        Self {
            p2p_listen: "/ip4/0.0.0.0/tcp/4001".to_string(),
            p2p_port: 4001,
            bootstrap_peers: vec![],
            enable_mdns: true,
            enable_kademlia: true,
        }
    }
}

/// Configurações do blockchain
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BlockchainConfig {
    /// Caminho para o arquivo da blockchain
    pub path: PathBuf,
    /// Intervalo de tempo para criar novos blocos (em segundos)
    pub block_time: u64,
    /// Número máximo de transações por bloco
    pub max_tx_per_block: usize,
    /// Dificuldade do consenso
    pub consensus_difficulty: usize,
}

/// Configurações do servidor web
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WebConfig {
    /// Endereço de escuta para o servidor web
    pub listen: String,
    /// Porta de escuta para o servidor web
    pub port: u16,
    /// Habilitar o servidor web
    pub enabled: bool,
    /// Habilitar CORS
    pub enable_cors: bool,
    /// Origens permitidas para CORS
    pub cors_origins: Vec<String>,
    /// Caminho base para a API
    pub api_path: String,
}

/// Configurações de persistência
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PersistenceConfig {
    /// URL do Redis
    pub redis_url: String,
    /// Tamanho do pool de conexões
    pub redis_pool_size: usize,
    /// Prefixo das chaves no Redis
    pub redis_key_prefix: String,
    /// TTL padrão para cache (em segundos)
    pub cache_ttl: u64,
}

/// Configurações de segurança
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SecurityConfig {
    /// Tipo de algoritmo de criptografia pós-quântica
    pub pqc_algorithm: String,
    /// Caminho para a chave privada
    pub private_key_path: Option<PathBuf>,
    /// Caminho para a chave pública
    pub public_key_path: Option<PathBuf>,
    /// Chave pública codificada em base64
    pub public_key_base64: Option<String>,
    /// Senha para a chave privada
    pub key_password: Option<String>,
    /// TTL do token JWT (em segundos)
    pub jwt_ttl: u64,
    /// Chave secreta para JWT
    pub jwt_secret: Option<String>,
}

impl Config {
    /// Carrega a configuração de um arquivo
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, UseCaseError> {
        let mut file = File::open(path)
            .map_err(|e| UseCaseError::Configuration(format!("Falha ao abrir arquivo de configuração: {}", e)))?;
            
        let mut contents = String::new();
        file.read_to_string(&mut contents)
            .map_err(|e| UseCaseError::Configuration(format!("Falha ao ler arquivo de configuração: {}", e)))?;
            
        match contents.trim_start().chars().next() {
            Some('{') => {
                // O arquivo é JSON
                serde_json::from_str(&contents)
                    .map_err(|e| UseCaseError::Configuration(format!("Falha ao processar configuração JSON: {}", e)))
            },
            Some('t') | Some('-') => {
                // O arquivo é TOML
                toml::from_str(&contents)
                    .map_err(|e| UseCaseError::Configuration(format!("Falha ao processar configuração TOML: {}", e)))
            },
            _ => {
                // Tenta YAML
                serde_yaml::from_str(&contents)
                    .map_err(|e| UseCaseError::Configuration(format!("Falha ao processar configuração YAML: {}", e)))
            }
        }
    }
    
    /// Carrega a configuração de variáveis de ambiente
    pub fn from_env() -> Result<Self, UseCaseError> {
        // Implementação usando dotenv e env_logger
        dotenv::dotenv().ok();
        
        // Configuração padrão
        let default_config = Self::default();
        
        // Sobrescreve com variáveis de ambiente
        let node = NodeConfig {
            name: std::env::var("ATOUS_NODE_NAME")
                .unwrap_or(default_config.node.name),
            data_path: PathBuf::from(std::env::var("ATOUS_DATA_PATH")
                .unwrap_or_else(|_| default_config.node.data_path.to_string_lossy().to_string())),
            log_level: std::env::var("RUST_LOG")
                .unwrap_or(default_config.node.log_level),
            mode: match std::env::var("ATOUS_NODE_MODE").ok().as_deref() {
                Some("full") => NodeMode::Full,
                Some("light") => NodeMode::Light,
                Some("bootstrap") => NodeMode::Bootstrap,
                Some("validator") => NodeMode::Validator,
                _ => default_config.node.mode,
            },
        };
        
        let network = NetworkConfig {
            p2p_listen: std::env::var("ATOUS_P2P_LISTEN")
                .unwrap_or(default_config.network.p2p_listen),
            p2p_port: std::env::var("ATOUS_P2P_PORT")
                .map(|p| p.parse().unwrap_or(default_config.network.p2p_port))
                .unwrap_or(default_config.network.p2p_port),
            bootstrap_peers: std::env::var("ATOUS_BOOTSTRAP_PEERS")
                .map(|p| p.split(',').map(String::from).collect())
                .unwrap_or(default_config.network.bootstrap_peers),
            enable_mdns: std::env::var("ATOUS_ENABLE_MDNS")
                .map(|v| v == "true" || v == "1" || v == "yes")
                .unwrap_or(default_config.network.enable_mdns),
            enable_kademlia: std::env::var("ATOUS_ENABLE_KADEMLIA")
                .map(|v| v == "true" || v == "1" || v == "yes")
                .unwrap_or(default_config.network.enable_kademlia),
        };
        
        // ... Implementação similar para outras seções
        let blockchain = BlockchainConfig {
            path: PathBuf::from(std::env::var("ATOUS_BLOCKCHAIN_PATH")
                .unwrap_or_else(|_| default_config.blockchain.path.to_string_lossy().to_string())),
            block_time: std::env::var("ATOUS_BLOCK_TIME")
                .map(|t| t.parse().unwrap_or(default_config.blockchain.block_time))
                .unwrap_or(default_config.blockchain.block_time),
            max_tx_per_block: std::env::var("ATOUS_MAX_TX_PER_BLOCK")
                .map(|t| t.parse().unwrap_or(default_config.blockchain.max_tx_per_block))
                .unwrap_or(default_config.blockchain.max_tx_per_block),
            consensus_difficulty: std::env::var("ATOUS_CONSENSUS_DIFFICULTY")
                .map(|d| d.parse().unwrap_or(default_config.blockchain.consensus_difficulty))
                .unwrap_or(default_config.blockchain.consensus_difficulty),
        };
        
        let web = WebConfig {
            listen: std::env::var("ATOUS_WEB_LISTEN")
                .unwrap_or(default_config.web.listen),
            port: std::env::var("ATOUS_WEB_PORT")
                .map(|p| p.parse().unwrap_or(default_config.web.port))
                .unwrap_or(default_config.web.port),
            enabled: std::env::var("ATOUS_WEB_ENABLED")
                .map(|v| v == "true" || v == "1" || v == "yes")
                .unwrap_or(default_config.web.enabled),
            enable_cors: std::env::var("ATOUS_WEB_ENABLE_CORS")
                .map(|v| v == "true" || v == "1" || v == "yes")
                .unwrap_or(default_config.web.enable_cors),
            cors_origins: std::env::var("ATOUS_WEB_CORS_ORIGINS")
                .map(|o| o.split(',').map(String::from).collect())
                .unwrap_or(default_config.web.cors_origins),
            api_path: std::env::var("ATOUS_WEB_API_PATH")
                .unwrap_or(default_config.web.api_path),
        };
        
        let persistence = PersistenceConfig {
            redis_url: std::env::var("REDIS_URL")
                .unwrap_or(default_config.persistence.redis_url),
            redis_pool_size: std::env::var("ATOUS_REDIS_POOL_SIZE")
                .map(|s| s.parse().unwrap_or(default_config.persistence.redis_pool_size))
                .unwrap_or(default_config.persistence.redis_pool_size),
            redis_key_prefix: std::env::var("ATOUS_REDIS_KEY_PREFIX")
                .unwrap_or(default_config.persistence.redis_key_prefix),
            cache_ttl: std::env::var("ATOUS_CACHE_TTL")
                .map(|t| t.parse().unwrap_or(default_config.persistence.cache_ttl))
                .unwrap_or(default_config.persistence.cache_ttl),
        };
        
        let security = SecurityConfig {
            pqc_algorithm: std::env::var("ATOUS_PQC_ALGORITHM")
                .unwrap_or(default_config.security.pqc_algorithm),
            private_key_path: std::env::var("ATOUS_PRIVATE_KEY_PATH")
                .map(PathBuf::from)
                .ok()
                .or(default_config.security.private_key_path),
            public_key_path: std::env::var("ATOUS_PUBLIC_KEY_PATH")
                .map(PathBuf::from)
                .ok()
                .or(default_config.security.public_key_path),
            public_key_base64: std::env::var("ATOUS_PUBLIC_KEY_BASE64")
                .ok()
                .or(default_config.security.public_key_base64),
            key_password: std::env::var("ATOUS_KEY_PASSWORD")
                .ok()
                .or(default_config.security.key_password),
            jwt_ttl: std::env::var("ATOUS_JWT_TTL")
                .map(|t| t.parse().unwrap_or(default_config.security.jwt_ttl))
                .unwrap_or(default_config.security.jwt_ttl),
            jwt_secret: std::env::var("ATOUS_JWT_SECRET")
                .ok()
                .or(default_config.security.jwt_secret),
        };
        
        Ok(Config {
            node,
            network,
            blockchain,
            web,
            persistence,
            security,
        })
    }
    
    /// Configura o logging
    pub fn setup_logging(&self) {
        env_logger::Builder::from_env(env_logger::Env::default().default_filter_or(&self.node.log_level))
            .format_timestamp_millis()
            .init();
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            node: NodeConfig {
                name: "atous-node".to_string(),
                data_path: PathBuf::from("./data"),
                log_level: "info".to_string(),
                mode: NodeMode::Full,
            },
            network: NetworkConfig {
                p2p_listen: "/ip4/0.0.0.0/tcp/4001".to_string(),
                p2p_port: 4001,
                bootstrap_peers: vec![],
                enable_mdns: true,
                enable_kademlia: true,
            },
            blockchain: BlockchainConfig {
                path: PathBuf::from("./data/blockchain.json"),
                block_time: 30,
                max_tx_per_block: 100,
                consensus_difficulty: 1,
            },
            web: WebConfig {
                listen: "0.0.0.0".to_string(),
                port: 8080,
                enabled: true,
                enable_cors: true,
                cors_origins: vec!["http://localhost:3000".to_string(), "https://atous.network".to_string()],
                api_path: "/api".to_string(),
            },
            persistence: PersistenceConfig {
                redis_url: "redis://127.0.0.1:6379/".to_string(),
                redis_pool_size: 10,
                redis_key_prefix: "atous:".to_string(),
                cache_ttl: 3600,
            },
            security: SecurityConfig {
                pqc_algorithm: "Dilithium2".to_string(),
                private_key_path: None,
                public_key_path: None,
                public_key_base64: None,
                key_password: None,
                jwt_ttl: 86400, // 24 horas
                jwt_secret: None,
            },
        }
    }
} use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::{DateTime, Utc};
use super::error::DomainError;
use super::identity::DID;
use sha2::Digest;

/// Representa uma transação na blockchain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub id: String,
    pub transaction_type: TransactionType,
    pub sender: DID,
    pub timestamp: DateTime<Utc>,
    pub payload: TransactionPayload,
    pub signature: Option<String>,
    pub metadata: HashMap<String, String>,
}

/// Tipos de transações suportadas
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TransactionType {
    RegisterDID,
    UpdateDID,
    RevokeDID,
    RegisterMetadata,
    UpdateMetadata,
    MessageProof,
    Custom(String),
}

/// Payload específico para cada tipo de transação
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TransactionPayload {
    DIDRegistration {
        did: DID,
        public_key: String,
    },
    DIDUpdate {
        did: DID,
        public_key: String,
    },
    DIDRevocation {
        did: DID,
        reason: String,
    },
    MetadataRegistration {
        subject_did: DID,
        content_hash: String,
        schema: String,
    },
    MetadataUpdate {
        subject_did: DID,
        content_hash: String,
    },
    MessageHash {
        sender_did: DID,
        recipient_did: DID,
        message_hash: String,
    },
    CustomPayload {
        data_type: String,
        content: String,
    },
}

impl Transaction {
    /// Cria uma nova transação
    pub fn new(
        transaction_type: TransactionType,
        sender: DID,
        payload: TransactionPayload,
    ) -> Self {
        let id = uuid::Uuid::new_v4().to_string();
        Self {
            id,
            transaction_type,
            sender,
            timestamp: Utc::now(),
            payload,
            signature: None,
            metadata: HashMap::new(),
        }
    }
    
    /// Assina a transação usando uma função de assinatura fornecida
    pub fn sign<F>(&mut self, sign_fn: F) -> Result<(), DomainError>
    where
        F: FnOnce(&[u8]) -> Result<String, DomainError>,
    {
        // Serializa a transação para assinatura (sem incluir o campo signature)
        let temp_signature = self.signature.take();
        let serialized = serde_json::to_vec(self)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar transação: {}", e)))?;
            
        // Assina os bytes serializados
        let signature = sign_fn(&serialized)?;
        self.signature = Some(signature);
        
        if temp_signature.is_some() && self.signature.is_none() {
            self.signature = temp_signature;
        }
        
        Ok(())
    }
    
    /// Verifica a assinatura da transação
    pub fn verify<F>(&self, verify_fn: F) -> Result<bool, DomainError>
    where
        F: FnOnce(&[u8], &str) -> Result<bool, DomainError>,
    {
        let signature = match &self.signature {
            Some(sig) => sig,
            None => return Ok(false),
        };
        
        // Cria uma cópia temporária da transação sem a assinatura
        let mut temp_tx = self.clone();
        temp_tx.signature = None;
        
        // Serializa para verificar contra a assinatura
        let serialized = serde_json::to_vec(&temp_tx)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar transação: {}", e)))?;
            
        verify_fn(&serialized, signature)
    }
    
    /// Adiciona metadados à transação
    pub fn add_metadata(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }

    pub fn get_signing_data(&self) -> Result<Vec<u8>, DomainError> {
        let serialized = serde_json::json!({
            "id": self.id,
            "transaction_type": &self.transaction_type,
            "sender": &self.sender,
            "timestamp": self.timestamp,
            "payload": &self.payload,
            "metadata": &self.metadata
        });
        
        Ok(serde_json::to_vec(&serialized)
            .map_err(|e| DomainError::SerializationError(e.to_string()))?)
    }
}

/// Representa um bloco na blockchain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub header: BlockHeader,
    pub transactions: Vec<Transaction>,
    pub signature: Option<String>,
}

/// Cabeçalho do bloco
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockHeader {
    pub version: u32,
    pub block_number: u64,
    pub previous_hash: String,
    pub merkle_root: String,
    pub timestamp: DateTime<Utc>,
    pub validator: DID,
    pub extra: HashMap<String, String>,
}

impl Block {
    /// Creates a new block
    pub fn new(
        block_number: u64,
        previous_hash: String,
        validator: DID,
        transactions: Vec<Transaction>,
    ) -> Result<Self, DomainError> {
        // Calculate merkle root of transactions
        let merkle_root = Self::calculate_merkle_root(&transactions)?;
        
        Ok(Self {
            header: BlockHeader {
                version: 1,
                block_number,
                previous_hash,
                merkle_root,
                timestamp: Utc::now(),
                validator,
                extra: HashMap::new(),
            },
            transactions,
            signature: None,
        })
    }
    
    /// Calculate the merkle tree root of transactions
    pub fn calculate_merkle_root(transactions: &[Transaction]) -> Result<String, DomainError> {
        if transactions.is_empty() {
            return Ok("0".repeat(64));
        }
        
        // Implementação simplificada da árvore Merkle
        let mut hashes: Vec<String> = Vec::new();
        
        // Calcula hash para cada transação
        for tx in transactions {
            let tx_bytes = serde_json::to_vec(tx)
                .map_err(|e| DomainError::Internal(format!("Erro ao serializar transação: {}", e)))?;
                
            let tx_hash = format!("{:x}", sha2::Sha256::digest(&tx_bytes));
            hashes.push(tx_hash);
        }
        
        // Constrói a árvore Merkle
        while hashes.len() > 1 {
            let mut next_level = Vec::new();
            
            // Para cada par de hashes, combine-os e hash o resultado
            for chunk in hashes.chunks(2) {
                if chunk.len() == 2 {
                    let combined = format!("{}{}", chunk[0], chunk[1]);
                    let combined_hash = format!("{:x}", sha2::Sha256::digest(combined.as_bytes()));
                    next_level.push(combined_hash);
                } else {
                    // Se sobrar um nó, simplesmente o eleve para o próximo nível
                    next_level.push(chunk[0].clone());
                }
            }
            
            hashes = next_level;
        }
        
        Ok(hashes[0].clone())
    }
    
    /// Assina o bloco usando uma função de assinatura fornecida
    pub fn sign<F>(&mut self, sign_fn: F) -> Result<(), DomainError>
    where
        F: FnOnce(&[u8]) -> Result<String, DomainError>,
    {
        // Serializa o bloco para assinatura (sem incluir o campo signature)
        let temp_signature = self.signature.take();
        let serialized = serde_json::to_vec(self)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar bloco: {}", e)))?;
            
        // Assina os bytes serializados
        let signature = sign_fn(&serialized)?;
        self.signature = Some(signature);
        
        if temp_signature.is_some() && self.signature.is_none() {
            self.signature = temp_signature;
        }
        
        Ok(())
    }
    
    /// Verifica a assinatura do bloco
    pub fn verify<F>(&self, verify_fn: F) -> Result<bool, DomainError>
    where
        F: FnOnce(&[u8], &str) -> Result<bool, DomainError>,
    {
        let signature = match &self.signature {
            Some(sig) => sig,
            None => return Ok(false),
        };
        
        // Cria uma cópia temporária do bloco sem a assinatura
        let mut temp_block = self.clone();
        temp_block.signature = None;
        
        // Serializa para verificar contra a assinatura
        let serialized = serde_json::to_vec(&temp_block)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar bloco: {}", e)))?;
            
        verify_fn(&serialized, signature)
    }
    
    /// Calcula o hash do bloco
    pub fn calculate_hash(&self) -> Result<String, DomainError> {
        // Create a temporary block without the signature
        let mut temp_block = self.clone();
        temp_block.signature = None;
        
        let serialized = serde_json::to_vec(&temp_block)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar bloco: {}", e)))?;
            
        Ok(format!("{:x}", sha2::Sha256::digest(&serialized)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_transaction_creation() {
        let sender = DID::generate("abc123");
        let payload = TransactionPayload::DIDRegistration {
            did: sender.clone(),
            public_key: "test_pub_key".to_string(),
        };
        
        let tx = Transaction::new(TransactionType::RegisterDID, sender.clone(), payload);
        
        assert_eq!(tx.transaction_type, TransactionType::RegisterDID);
        assert_eq!(tx.sender, sender);
        assert!(tx.signature.is_none());
    }
    
    #[test]
    fn test_transaction_metadata() {
        let sender = DID::generate("abc123");
        let payload = TransactionPayload::DIDRegistration {
            did: sender.clone(),
            public_key: "test_pub_key".to_string(),
        };
        
        let mut tx = Transaction::new(TransactionType::RegisterDID, sender, payload);
        
        tx.add_metadata("source", "unit_test");
        tx.add_metadata("priority", "high");
        
        assert_eq!(tx.metadata.get("source"), Some(&"unit_test".to_string()));
        assert_eq!(tx.metadata.get("priority"), Some(&"high".to_string()));
    }
    
    #[test]
    fn test_transaction_sign_verify() {
        let sender = DID::generate("abc123");
        let payload = TransactionPayload::DIDRegistration {
            did: sender.clone(),
            public_key: "test_pub_key".to_string(),
        };
        
        let mut tx = Transaction::new(TransactionType::RegisterDID, sender, payload);
        
        // Mock para assinatura
        let sign_fn = |_data: &[u8]| -> Result<String, DomainError> {
            Ok("valid_signature".to_string())
        };
        
        // Mock para verificação
        let verify_fn = |_data: &[u8], signature: &str| -> Result<bool, DomainError> {
            Ok(signature == "valid_signature")
        };
        
        tx.sign(sign_fn).unwrap();
        assert_eq!(tx.signature, Some("valid_signature".to_string()));
        
        let is_valid = tx.verify(verify_fn).unwrap();
        assert!(is_valid);
    }
    
    #[test]
    fn test_block_creation() {
        let validator = DID::generate("validator123");
        let sender = DID::generate("sender456");
        
        let payload = TransactionPayload::DIDRegistration {
            did: sender.clone(),
            public_key: "test_pub_key".to_string(),
        };
        
        let tx = Transaction::new(TransactionType::RegisterDID, sender, payload);
        
        let block = Block::new(1, "previous_hash".to_string(), validator.clone(), vec![tx]).unwrap();
        
        assert_eq!(block.header.block_number, 1);
        assert_eq!(block.header.previous_hash, "previous_hash");
        assert_eq!(block.header.validator, validator);
        assert_eq!(block.transactions.len(), 1);
        assert!(block.signature.is_none());
    }
    
    #[test]
    fn test_merkle_root() {
        let sender = DID::generate("sender456");
        let transactions = vec![
            Transaction::new(
                TransactionType::RegisterDID,
                sender.clone(),
                TransactionPayload::DIDRegistration {
                    did: sender.clone(),
                    public_key: "key1".to_string(),
                },
            ),
            Transaction::new(
                TransactionType::MessageProof,
                sender.clone(),
                TransactionPayload::MessageHash {
                    sender_did: sender.clone(),
                    recipient_did: DID::generate("recipient789"),
                    message_hash: "hash123".to_string(),
                },
            ),
        ];
        
        let merkle_root = Block::calculate_merkle_root(&transactions).unwrap();
        assert!(!merkle_root.is_empty());
        
        // Teste com lista vazia
        let empty_merkle = Block::calculate_merkle_root(&[]).unwrap();
        assert_eq!(empty_merkle, "0".repeat(64));
    }
}use thiserror::Error as ThisError;

/// Erros de domínio centralizados para melhor tratamento
#[derive(ThisError, Debug)]
pub enum DomainError {
    #[error("Falha de validação: {0}")]
    Validation(String),
    
    #[error("Entidade não encontrada: {0}")]
    NotFound(String),
    
    #[error("Conflito de estado: {0}")]
    Conflict(String),
    
    #[error("Falha de autenticação: {0}")]
    Authentication(String),
    
    #[error("Falha de autorização: {0}")]
    Authorization(String),
    
    #[error("Erro criptográfico: {0}")]
    Crypto(String),
    
    #[error("Erro na blockchain: {0}")]
    Blockchain(String),
    
    #[error("Erro de rede: {0}")]
    Network(String),
    
    #[error("Erro interno: {0}")]
    Internal(String),

    #[error("Erro de serialização: {0}")]
    SerializationError(String),

    #[error("Operação inválida: {0}")]
    InvalidOperation(String),

    #[error("Já existe: {0}")]
    AlreadyExists(String)
}

impl From<std::io::Error> for DomainError {
    fn from(e: std::io::Error) -> Self {
        DomainError::Internal(format!("IO error: {}", e))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_domain_error_display() {
        let error = DomainError::Validation("campo inválido".to_string());
        assert_eq!(format!("{}", error), "Falha de validação: campo inválido");
        
        let io_error = std::io::Error::new(std::io::ErrorKind::NotFound, "arquivo não encontrado");
        let domain_error = DomainError::from(io_error);
        assert!(format!("{}", domain_error).contains("IO error"));
    }
}use serde::{Deserialize, Serialize};
use std::fmt;
use super::error::DomainError;
use uuid::Uuid;

/// Representa uma Identidade Descentralizada (DID)
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct DID {
    method: String,
    identifier: String,
    public_key_hash: String,
}

impl DID {
    /// Cria um novo DID com o método "atous"
    pub fn new(identifier: impl Into<String>, public_key_hash: impl Into<String>) -> Self {
        Self {
            method: "atous".to_string(),
            identifier: identifier.into(),
            public_key_hash: public_key_hash.into(),
        }
    }
    
    /// Gera um novo DID com identificador aleatório (UUID)
    pub fn generate(public_key_hash: impl Into<String>) -> Self {
        let uuid = Uuid::new_v4().to_string();
        Self::new(uuid, public_key_hash)
    }
    
    /// Analisa uma string DID no formato did:método:identificador
    pub fn parse(did_string: &str) -> Result<Self, DomainError> {
        let parts: Vec<&str> = did_string.split(':').collect();
        
        if parts.len() < 3 || parts[0] != "did" {
            return Err(DomainError::Validation(format!(
                "Formato DID inválido: {} (esperado did:método:identificador)", 
                did_string
            )));
        }
        
        Ok(Self {
            method: parts[1].to_string(),
            identifier: parts[2].to_string(),
            public_key_hash: parts.get(3).unwrap_or(&"").to_string(),
        })
    }
    
    /// Obtém o método DID
    pub fn method(&self) -> &str {
        &self.method
    }
    
    /// Obtém o identificador DID
    pub fn identifier(&self) -> &str {
        &self.identifier
    }
    
    /// Obtém o hash da chave pública
    pub fn public_key_hash(&self) -> &str {
        &self.public_key_hash
    }
    
    /// Atualiza o hash da chave pública
    pub fn update_public_key_hash(&mut self, new_hash: impl Into<String>) {
        self.public_key_hash = new_hash.into();
    }
}

impl fmt::Display for DID {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.public_key_hash.is_empty() {
            write!(f, "did:{}:{}", self.method, self.identifier)
        } else {
            write!(f, "did:{}:{}:{}", self.method, self.identifier, self.public_key_hash)
        }
    }
}

/// Representa metadados adicionais associados a um DID
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentityMetadata {
    pub display_name: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub device_id: Option<String>,
    pub verification_status: VerificationStatus,
    pub attributes: std::collections::HashMap<String, String>,
}

/// Status de verificação da identidade
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum VerificationStatus {
    Unverified,
    PendingVerification,
    Verified,
    Revoked,
}

impl Default for IdentityMetadata {
    fn default() -> Self {
        Self {
            display_name: None,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
            device_id: None,
            verification_status: VerificationStatus::Unverified,
            attributes: std::collections::HashMap::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_did_creation() {
        let did = DID::new("123456", "abcdef");
        assert_eq!(did.method(), "atous");
        assert_eq!(did.identifier(), "123456");
        assert_eq!(did.public_key_hash(), "abcdef");
    }
    
    #[test]
    fn test_did_generation() {
        let did = DID::generate("abcdef");
        assert_eq!(did.method(), "atous");
        assert!(!did.identifier().is_empty());
        assert_eq!(did.public_key_hash(), "abcdef");
    }
    
    #[test]
    fn test_did_display() {
        let did = DID::new("123456", "abcdef");
        assert_eq!(did.to_string(), "did:atous:123456:abcdef");
        
        let did_no_hash = DID::new("123456", "");
        assert_eq!(did_no_hash.to_string(), "did:atous:123456");
    }
    
    #[test]
    fn test_did_parse_valid() {
        let did_str = "did:atous:123456:abcdef";
        let did = DID::parse(did_str).unwrap();
        
        assert_eq!(did.method(), "atous");
        assert_eq!(did.identifier(), "123456");
        assert_eq!(did.public_key_hash(), "abcdef");
    }
    
    #[test]
    fn test_did_parse_invalid() {
        let invalid_did = "invalid:123456";
        let result = DID::parse(invalid_did);
        assert!(result.is_err());
        
        match result {
            Err(DomainError::Validation(msg)) => {
                assert!(msg.contains("Formato DID inválido"));
            }
            _ => panic!("Esperado erro de validação"),
        }
    }
    
    #[test]
    fn test_identity_metadata_default() {
        let metadata = IdentityMetadata::default();
        assert_eq!(metadata.verification_status, VerificationStatus::Unverified);
        assert!(metadata.attributes.is_empty());
    }
} use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::{DateTime, Utc};
use super::identity::DID;
use super::error::DomainError;
use uuid::Uuid;
use sha2::Digest;

/// Representa uma mensagem no sistema Atous
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: String,
    pub sender: DID,
    pub recipients: Vec<DID>,
    pub content: MessageContent,
    pub timestamp: DateTime<Utc>,
    pub metadata: MessageMetadata,
    pub signature: Option<String>,
}

/// Conteúdo de uma mensagem, que pode ser encriptado
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MessageContent {
    Plaintext(String),
    Encrypted {
        cipher_text: Vec<u8>,
        encryption_info: EncryptionInfo,
    },
    Binary(Vec<u8>),
}

/// Informações sobre a encriptação de uma mensagem
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptionInfo {
    pub algorithm: EncryptionAlgorithm,
    pub key_info: KeyInfo,
    pub nonce: Option<String>,
    pub additional_data: HashMap<String, String>,
}

/// Algoritmos de encriptação suportados
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EncryptionAlgorithm {
    AES256GCM,
    ChaCha20Poly1305,
    MLKEM768,
    Hybrid(String, String),
}

/// Informações sobre a chave usada para encriptação
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum KeyInfo {
    SymmetricKey {
        key_id: String,
    },
    AsymmetricKey {
        public_key_id: String,
        encrypted_key: Option<Vec<u8>>,
    },
    EncapsulatedKey {
        ciphertext: Vec<u8>,
    },
}

/// Metadados associados a uma mensagem
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageMetadata {
    pub message_type: MessageType,
    pub conversation_id: Option<String>,
    pub reply_to: Option<String>,
    pub expires_at: Option<DateTime<Utc>>,
    pub priority: MessagePriority,
    pub state: MessageState,
    pub blockchain_tx_id: Option<String>,
    pub tags: Vec<String>,
    pub custom_attributes: HashMap<String, String>,
}

/// Tipos de mensagens suportados
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum MessageType {
    DirectMessage,
    GroupMessage,
    Notification,
    SystemMessage,
    Custom(String),
}

/// Prioridades de mensagens
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
pub enum MessagePriority {
    Low,
    Normal,
    High,
    Urgent,
}

/// Estados possíveis de uma mensagem
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum MessageState {
    Draft,
    Sending,
    Delivered,
    Read,
    Failed,
    Expired,
}

impl Message {
    /// Cria uma nova mensagem com conteúdo em texto plano
    pub fn new_text(
        sender: DID,
        recipients: Vec<DID>,
        text: impl Into<String>,
        message_type: MessageType,
    ) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            sender,
            recipients,
            content: MessageContent::Plaintext(text.into()),
            timestamp: Utc::now(),
            metadata: MessageMetadata {
                message_type,
                conversation_id: None,
                reply_to: None,
                expires_at: None,
                priority: MessagePriority::Normal,
                state: MessageState::Draft,
                blockchain_tx_id: None,
                tags: Vec::new(),
                custom_attributes: HashMap::new(),
            },
            signature: None,
        }
    }
    
    /// Cria uma nova mensagem com conteúdo encriptado
    pub fn new_encrypted(
        sender: DID,
        recipients: Vec<DID>,
        encrypted_content: Vec<u8>,
        encryption_info: EncryptionInfo,
        message_type: MessageType,
    ) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            sender,
            recipients,
            content: MessageContent::Encrypted {
                cipher_text: encrypted_content,
                encryption_info,
            },
            timestamp: Utc::now(),
            metadata: MessageMetadata {
                message_type,
                conversation_id: None,
                reply_to: None,
                expires_at: None,
                priority: MessagePriority::Normal,
                state: MessageState::Draft,
                blockchain_tx_id: None,
                tags: Vec::new(),
                custom_attributes: HashMap::new(),
            },
            signature: None,
        }
    }
    
    /// Define o ID da conversa a que esta mensagem pertence
    pub fn set_conversation_id(&mut self, conversation_id: impl Into<String>) {
        self.metadata.conversation_id = Some(conversation_id.into());
    }
    
    /// Define esta mensagem como uma resposta a outra mensagem
    pub fn set_reply_to(&mut self, message_id: impl Into<String>) {
        self.metadata.reply_to = Some(message_id.into());
    }
    
    /// Define um prazo de expiração para a mensagem
    pub fn set_expires_at(&mut self, expires_at: DateTime<Utc>) {
        self.metadata.expires_at = Some(expires_at);
    }
    
    /// Define a prioridade da mensagem
    pub fn set_priority(&mut self, priority: MessagePriority) {
        self.metadata.priority = priority;
    }
    
    /// Atualiza o estado da mensagem
    pub fn update_state(&mut self, state: MessageState) {
        self.metadata.state = state;
    }
    
    /// Adiciona uma tag à mensagem
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        self.metadata.tags.push(tag.into());
    }
    
    /// Adiciona ou atualiza um atributo personalizado
    pub fn set_custom_attribute(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.custom_attributes.insert(key.into(), value.into());
    }
    
    /// Define o ID da transação blockchain associada a esta mensagem
    pub fn set_blockchain_tx_id(&mut self, tx_id: impl Into<String>) {
        self.metadata.blockchain_tx_id = Some(tx_id.into());
    }
    
    /// Assina a mensagem usando uma função de assinatura fornecida
    pub fn sign<F>(&mut self, sign_fn: F) -> Result<(), DomainError>
    where
        F: FnOnce(&[u8]) -> Result<String, DomainError>,
    {
        // Serializa a mensagem para assinatura (sem incluir o campo signature)
        let temp_signature = self.signature.take();
        let serialized = serde_json::to_vec(self)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar mensagem: {}", e)))?;
            
        // Assina os bytes serializados
        let signature = sign_fn(&serialized)?;
        self.signature = Some(signature);
        
        if temp_signature.is_some() && self.signature.is_none() {
            self.signature = temp_signature;
        }
        
        Ok(())
    }
    
    /// Verifica a assinatura da mensagem
    pub fn verify<F>(&self, verify_fn: F) -> Result<bool, DomainError>
    where
        F: FnOnce(&[u8], &str) -> Result<bool, DomainError>,
    {
        let signature = match &self.signature {
            Some(sig) => sig,
            None => return Ok(false),
        };
        
        // Cria uma cópia temporária da mensagem sem a assinatura
        let mut temp_msg = self.clone();
        temp_msg.signature = None;
        
        // Serializa para verificar contra a assinatura
        let serialized = serde_json::to_vec(&temp_msg)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar mensagem: {}", e)))?;
            
        verify_fn(&serialized, signature)
    }
    
    /// Calcula o hash da mensagem
    pub fn calculate_hash(&self) -> Result<String, DomainError> {
        let serialized = serde_json::to_vec(self)
            .map_err(|e| DomainError::Internal(format!("Falha ao serializar mensagem: {}", e)))?;
            
        Ok(format!("{:x}", sha2::Sha256::digest(&serialized)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_message_creation_text() {
        let sender = DID::generate("sender123");
        let recipient = DID::generate("recipient456");
        
        let message = Message::new_text(
            sender.clone(),
            vec![recipient.clone()],
            "Olá, esta é uma mensagem de teste!",
            MessageType::DirectMessage,
        );
        
        assert_eq!(message.sender, sender);
        assert_eq!(message.recipients, vec![recipient]);
        
        if let MessageContent::Plaintext(text) = &message.content {
            assert_eq!(text, "Olá, esta é uma mensagem de teste!");
        } else {
            panic!("Conteúdo deveria ser texto plano");
        }
        
        assert_eq!(message.metadata.message_type, MessageType::DirectMessage);
        assert_eq!(message.metadata.state, MessageState::Draft);
        assert_eq!(message.metadata.priority, MessagePriority::Normal);
    }
    
    #[test]
    fn test_message_metadata_updates() {
        let sender = DID::generate("sender123");
        let recipient = DID::generate("recipient456");
        
        let mut message = Message::new_text(
            sender,
            vec![recipient],
            "Mensagem de teste",
            MessageType::DirectMessage,
        );
        
        message.set_conversation_id("conv-123");
        message.set_reply_to("msg-abc");
        message.set_priority(MessagePriority::High);
        message.add_tag("importante");
        message.set_custom_attribute("categoria", "trabalho");
        message.update_state(MessageState::Sending);
        
        assert_eq!(message.metadata.conversation_id, Some("conv-123".to_string()));
        assert_eq!(message.metadata.reply_to, Some("msg-abc".to_string()));
        assert_eq!(message.metadata.priority, MessagePriority::High);
        assert_eq!(message.metadata.tags, vec!["importante"]);
        assert_eq!(message.metadata.custom_attributes.get("categoria"), Some(&"trabalho".to_string()));
        assert_eq!(message.metadata.state, MessageState::Sending);
    }
    
    #[test]
    fn test_message_sign_verify() {
        let sender = DID::generate("sender123");
        let recipient = DID::generate("recipient456");
        
        let mut message = Message::new_text(
            sender,
            vec![recipient],
            "Mensagem assinada",
            MessageType::DirectMessage,
        );
        
        // Mock para assinatura
        let sign_fn = |_data: &[u8]| -> Result<String, DomainError> {
            Ok("valid_signature".to_string())
        };
        
        // Mock para verificação
        let verify_fn = |_data: &[u8], signature: &str| -> Result<bool, DomainError> {
            Ok(signature == "valid_signature")
        };
        
        message.sign(sign_fn).unwrap();
        assert_eq!(message.signature, Some("valid_signature".to_string()));
        
        let is_valid = message.verify(verify_fn).unwrap();
        assert!(is_valid);
    }
    
    #[test]
    fn test_message_hash() {
        let sender = DID::generate("sender123");
        let recipient = DID::generate("recipient456");
        
        let message = Message::new_text(
            sender,
            vec![recipient],
            "Mensagem para hash",
            MessageType::DirectMessage,
        );
        
        let hash = message.calculate_hash().unwrap();
        assert!(!hash.is_empty());
    }
} pub mod identity;
pub mod blockchain;
pub mod messaging;
pub mod error;

// Re-exportar tipos comuns
pub use error::DomainError; use crate::domain::identity::DID;
use crate::domain::blockchain::{Block, Transaction, TransactionType, TransactionPayload};
use crate::usecases::error::UseCaseError;
use std::sync::Arc;
use tokio::sync::RwLock;
use crate::domain::error::DomainError;
use std::path::Path;

#[cfg_attr(test, mockall::automock)]
#[async_trait::async_trait]
pub trait BlockchainService: Send + Sync + 'static {
    async fn add_block(&self, transactions: Vec<Transaction>) -> Result<Block, UseCaseError>;
    
    async fn get_block(&self, block_number: u64) -> Result<Option<Block>, UseCaseError>;
    
    async fn get_latest_block(&self) -> Result<Block, UseCaseError>;
    
    async fn verify_chain(&self) -> Result<bool, UseCaseError>;
    
    async fn register_did(&self, did: &DID, public_key: &str) -> Result<String, UseCaseError>;
    
    async fn update_did(&self, did: &DID, new_public_key: &str) -> Result<String, UseCaseError>;
    
    async fn revoke_did(&self, did: &DID, reason: &str) -> Result<String, UseCaseError>;
    
    async fn register_message_metadata(
        &self, 
        sender: &DID, 
        recipients: &[DID], 
        message_hash: &str
    ) -> Result<String, UseCaseError>;
    
    async fn get_did_transactions(&self, did: &DID) -> Result<Vec<Transaction>, UseCaseError>;
    
    async fn sync_with_network(&self) -> Result<(), UseCaseError>;
}

/// Implementação do serviço de blockchain em arquivo local
pub struct FileBlockchainService {
    blockchain_path: String,
    validator_did: DID,
    blocks: Arc<RwLock<Vec<Block>>>,
    pending_transactions: Arc<RwLock<Vec<Transaction>>>,
    sign_function: Arc<dyn Fn(&[u8]) -> Result<String, UseCaseError> + Send + Sync>,
    verify_function: Arc<dyn Fn(&[u8], &str) -> Result<bool, UseCaseError> + Send + Sync>,
}

#[async_trait::async_trait]
impl BlockchainService for FileBlockchainService {
    async fn add_block(&self, transactions: Vec<Transaction>) -> Result<Block, UseCaseError> {
        if transactions.is_empty() {
            return Err(UseCaseError::Validation("Cannot create empty block".to_string()));
        }

        // Get previous block info under a timeout to prevent deadlocks
        let (previous_number, previous_hash) = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            async {
                let blocks = self.blocks.read().await;
                let previous = blocks.last()
                    .ok_or_else(|| UseCaseError::Internal("No blocks in chain".to_string()))?;
                Ok::<_, UseCaseError>((previous.header.block_number, previous.calculate_hash()?))
            }
        ).await.map_err(|_| UseCaseError::Concurrency("Timeout while reading previous block".to_string()))??;

        // Clone previous_hash for later use
        let previous_hash_for_check = previous_hash.clone();

        // Create new block with proper previous hash
        let mut new_block = Block::new(
            previous_number + 1,
            previous_hash,
            self.validator_did.clone(),
            transactions,
        )?;

        let block_hash = new_block.calculate_hash()?;
        let signature = (self.sign_function)(&block_hash.as_bytes())?;
        new_block.signature = Some(signature);

        // Verify block before attempting to add it
        let is_valid = new_block.verify(|data, sig| {
            (self.verify_function)(data, sig)
                .map_err(|e| DomainError::Internal(format!("Failed to verify block: {}", e)))
        })?;

        if !is_valid {
            return Err(UseCaseError::Validation("Block signature verification failed".to_string()));
        }

        // Take a write lock only when we're ready to update the chain
        {
            let mut blocks = self.blocks.write().await;
            // Double check our chain link is still valid
            if let Some(last) = blocks.last() {
                let current_hash = last.calculate_hash()?;
                if current_hash != previous_hash_for_check {
                    return Err(UseCaseError::Concurrency("Chain state changed while preparing block".to_string()));
                }
            }
            blocks.push(new_block.clone());
            self.save_chain(&blocks).await?;
        }

        Ok(new_block)
    }
    
    async fn get_block(&self, block_number: u64) -> Result<Option<Block>, UseCaseError> {
        let blocks = self.blocks.read().await;
        Ok(blocks.iter().find(|b| b.header.block_number == block_number).cloned())
    }
    
    async fn get_latest_block(&self) -> Result<Block, UseCaseError> {
        let blocks = self.blocks.read().await;
        blocks.last()
            .cloned()
            .ok_or_else(|| UseCaseError::NotFound("No blocks in chain".to_string()))
    }
    
    async fn verify_chain(&self) -> Result<bool, UseCaseError> {
        let blocks = self.blocks.read().await;
        
        if blocks.is_empty() {
            return Ok(true);
        }

        // Verify genesis block
        let genesis = &blocks[0];
        if genesis.header.block_number != 0 || genesis.header.previous_hash != "0".repeat(64) {
            return Ok(false);
        }

        // Verify each block's signature and links
        for i in 0..blocks.len() {
            let current_block = &blocks[i];
            
            // Verify block signature
            let is_valid = current_block.verify(|data, sig| {
                (self.verify_function)(data, sig)
                    .map_err(|e| DomainError::Internal(format!("Failed to verify block: {}", e)))
            })?;
            
            if !is_valid {
                return Ok(false);
            }

            // Verify block link (except for genesis)
            if i > 0 {
                let previous_block = &blocks[i - 1];
                let previous_hash = previous_block.calculate_hash()?;
                
                if current_block.header.previous_hash != previous_hash {
                    return Ok(false);
                }
                
                // Verify block number sequence
                if current_block.header.block_number != previous_block.header.block_number + 1 {
                    return Ok(false);
                }
            }

            // Verify merkle root
            let calculated_root = Block::calculate_merkle_root(&current_block.transactions)?;
            if calculated_root != current_block.header.merkle_root {
                return Ok(false);
            }
        }

        Ok(true)
    }
    
    async fn register_did(&self, did: &DID, public_key: &str) -> Result<String, UseCaseError> {
        // Verify DID doesn't already exist
        let existing = self.get_did_transactions(did).await?;
        if !existing.is_empty() {
            return Err(UseCaseError::AlreadyExists("DID already registered".into()));
        }
        
        let transaction = Transaction::new(
            TransactionType::RegisterDID,
            self.validator_did.clone(),
            TransactionPayload::DIDRegistration {
                did: did.clone(),
                public_key: public_key.to_string(),
            },
        );
        self.add_transaction(transaction).await
    }
    
    async fn update_did(&self, did: &DID, new_public_key: &str) -> Result<String, UseCaseError> {
        // Verify DID exists and is not revoked
        let existing = self.get_did_transactions(did).await?;
        if existing.is_empty() {
            return Err(UseCaseError::NotFound("DID not found".into()));
        }
        
        if existing.iter().any(|tx| matches!(tx.payload, TransactionPayload::DIDRevocation { .. })) {
            return Err(UseCaseError::InvalidOperation("DID is revoked".into()));
        }

        let transaction = Transaction::new(
            TransactionType::UpdateDID,
            self.validator_did.clone(),
            TransactionPayload::DIDUpdate {
                did: did.clone(),
                public_key: new_public_key.to_string(),
            },
        );
        self.add_transaction(transaction).await
    }
    
    async fn revoke_did(&self, did: &DID, reason: &str) -> Result<String, UseCaseError> {
        let transaction = Transaction::new(
            TransactionType::RevokeDID,
            self.validator_did.clone(),
            TransactionPayload::DIDRevocation {
                did: did.clone(),
                reason: reason.to_string(),
            },
        );
        
        self.add_transaction(transaction).await
    }
    
    async fn register_message_metadata(
        &self,
        sender: &DID,
        recipients: &[DID],
        message_hash: &str,
    ) -> Result<String, UseCaseError> {
        let transaction = Transaction::new(
            TransactionType::MessageProof,
            self.validator_did.clone(),
            TransactionPayload::MessageHash {
                sender_did: sender.clone(),
                recipient_did: recipients.first().cloned().unwrap_or_else(|| self.validator_did.clone()),
                message_hash: message_hash.to_string(),
            },
        );
        
        self.add_transaction(transaction).await
    }
    
    async fn get_did_transactions(&self, did: &DID) -> Result<Vec<Transaction>, UseCaseError> {
        let mut result = Vec::new();
        
        // Search in all blocks
        let blocks = self.blocks.read().await;
        for block in blocks.iter() {
            for tx in &block.transactions {
                if tx.sender == *did {
                    result.push(tx.clone());
                }
                
                // Check if DID is in payload
                match &tx.payload {
                    TransactionPayload::DIDRegistration { did: target_did, .. } |
                    TransactionPayload::DIDUpdate { did: target_did, .. } |
                    TransactionPayload::DIDRevocation { did: target_did, .. } |
                    TransactionPayload::MetadataRegistration { subject_did: target_did, .. } |
                    TransactionPayload::MetadataUpdate { subject_did: target_did, .. } |
                    TransactionPayload::MessageHash { sender_did: target_did, .. } => {
                        if target_did == did {
                            result.push(tx.clone());
                        }
                    }
                    _ => {}
                }
            }
        }
        
        // Search in pending transactions
        let pending = self.pending_transactions.read().await;
        for tx in pending.iter() {
            if tx.sender == *did {
                result.push(tx.clone());
            }
            
            // Check if DID is in payload
            match &tx.payload {
                TransactionPayload::DIDRegistration { did: target_did, .. } |
                TransactionPayload::DIDUpdate { did: target_did, .. } |
                TransactionPayload::DIDRevocation { did: target_did, .. } |
                TransactionPayload::MetadataRegistration { subject_did: target_did, .. } |
                TransactionPayload::MetadataUpdate { subject_did: target_did, .. } |
                TransactionPayload::MessageHash { sender_did: target_did, .. } => {
                    if target_did == did {
                        result.push(tx.clone());
                    }
                }
                _ => {}
            }
        }
        
        Ok(result)
    }
    
    async fn sync_with_network(&self) -> Result<(), UseCaseError> {
        // Basic implementation of network sync
        Ok(())
    }
}

impl FileBlockchainService {
    /// Cria uma nova instância do serviço de blockchain
    pub fn new<P: AsRef<Path>>(
        path: P,
        validator_did: DID,
        sign_fn: impl Fn(&[u8]) -> Result<String, UseCaseError> + Send + Sync + 'static,
        verify_fn: impl Fn(&[u8], &str) -> Result<bool, UseCaseError> + Send + Sync + 'static,
    ) -> Result<Self, UseCaseError> {
        let path = path.as_ref();
        let path_str = path.to_str().ok_or_else(|| {
            UseCaseError::Configuration("Caminho da blockchain inválido".to_string())
        })?.to_string();
        
        // Create blockchain directory if it doesn't exist
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| UseCaseError::Storage(format!("Failed to create blockchain directory: {}", e)))?;
        }
        
        Ok(Self {
            blockchain_path: path_str,
            validator_did,
            blocks: Arc::new(RwLock::new(Vec::new())),
            pending_transactions: Arc::new(RwLock::new(Vec::new())),
            sign_function: Arc::new(sign_fn),
            verify_function: Arc::new(verify_fn),
        })
    }
    
    /// Carrega a blockchain do armazenamento persistente
    #[allow(dead_code)]
    fn load_blockchain_persistence(&self) -> Result<(), UseCaseError> {
        let path = Path::new(&self.blockchain_path);
        if !path.exists() {
            return Err(UseCaseError::NotFound("Arquivo da blockchain não encontrado".to_string()));
        }
        
        let file_content = std::fs::read_to_string(path)
            .map_err(|e| UseCaseError::Internal(format!("Erro ao ler arquivo da blockchain: {}", e)))?;
            
        let blocks: Vec<Block> = serde_json::from_str(&file_content)
            .map_err(|e| UseCaseError::Internal(format!("Erro ao deserializar blockchain: {}", e)))?;
            
        // Verifica se a cadeia está vazia
        if blocks.is_empty() {
            return Err(UseCaseError::Validation("Blockchain vazia no arquivo".to_string()));
        }
        
        // Armazena os blocos carregados
        let mut blocks_lock = match self.blocks.try_write() {
            Ok(lock) => lock,
            Err(_) => return Err(UseCaseError::Concurrency("Não foi possível obter lock de escrita".to_string())),
        };
        
        *blocks_lock = blocks;
        
        Ok(())
    }
    

    
    /// Adiciona uma nova transação ao pool pendente
    async fn add_transaction(&self, mut transaction: Transaction) -> Result<String, UseCaseError> {
        // Sign the transaction
        let tx_data = transaction.get_signing_data()?;
        let signature = (self.sign_function)(&tx_data)?;
        transaction.signature = Some(signature);
        let tx_id = transaction.id.clone();

        // Add to pending transactions with timeout
        let add_result = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            async {
                let mut pending = self.pending_transactions.write().await;
                pending.push(transaction);

                // Create new block if we have enough transactions
                if pending.len() >= 10 {
                    let transactions = pending.drain(..).collect();
                    drop(pending); // Release lock before creating block
                    self.add_block(transactions).await?;
                }
                Ok::<_, UseCaseError>(())
            }
        ).await;

        match add_result {
            Ok(Ok(())) => Ok(tx_id),
            Ok(Err(e)) => Err(e),
            Err(_) => Err(UseCaseError::Concurrency("Timeout while adding transaction".to_string()))
        }
    }

    async fn add_block(&self, transactions: Vec<Transaction>) -> Result<Block, UseCaseError> {
        if transactions.is_empty() {
            return Err(UseCaseError::Validation("Cannot create empty block".to_string()));
        }

        // Get previous block info under a timeout to prevent deadlocks
        let (previous_number, previous_hash) = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            async {
                let blocks = self.blocks.read().await;
                let previous = blocks.last()
                    .ok_or_else(|| UseCaseError::Internal("No blocks in chain".to_string()))?;
                Ok::<_, UseCaseError>((previous.header.block_number, previous.calculate_hash()?))
            }
        ).await.map_err(|_| UseCaseError::Concurrency("Timeout while reading previous block".to_string()))??;

        // Clone previous_hash for later use
        let previous_hash_for_check = previous_hash.clone();

        // Create new block with proper previous hash
        let mut new_block = Block::new(
            previous_number + 1,
            previous_hash,
            self.validator_did.clone(),
            transactions,
        )?;

        let block_hash = new_block.calculate_hash()?;
        let signature = (self.sign_function)(&block_hash.as_bytes())?;
        new_block.signature = Some(signature);

        // Verify block before attempting to add it
        let is_valid = new_block.verify(|data, sig| {
            (self.verify_function)(data, sig)
                .map_err(|e| DomainError::Internal(format!("Failed to verify block: {}", e)))
        })?;

        if !is_valid {
            return Err(UseCaseError::Validation("Block signature verification failed".to_string()));
        }

        // Take a write lock only when we're ready to update the chain
        {
            let mut blocks = self.blocks.write().await;
            // Double check our chain link is still valid
            if let Some(last) = blocks.last() {
                let current_hash = last.calculate_hash()?;
                if current_hash != previous_hash_for_check {
                    return Err(UseCaseError::Concurrency("Chain state changed while preparing block".to_string()));
                }
            }
            blocks.push(new_block.clone());
            self.save_chain(&blocks).await?;
        }

        Ok(new_block)
    }

    async fn save_chain(&self, blocks: &[Block]) -> Result<(), UseCaseError> {
        // Verify chain integrity before saving
        for i in 1..blocks.len() {
            let current = &blocks[i];
            let previous = &blocks[i-1];
            // Verify block number sequence
            if current.header.block_number != previous.header.block_number + 1 {
                return Err(UseCaseError::Validation("Invalid block number sequence".to_string()));
            }
            // Verify previous hash link
            let prev_hash = previous.calculate_hash()?;
            if current.header.previous_hash != prev_hash {
                return Err(UseCaseError::Validation("Invalid block chain link".to_string()));
            }
        }
        let serialized = serde_json::to_string_pretty(&blocks)
            .map_err(|e| UseCaseError::Storage(format!("Failed to serialize blockchain: {}", e)))?;
        
        // Execute write with timeout and handle all possible errors
        tokio::time::timeout(
            std::time::Duration::from_secs(10),
            tokio::fs::write(&self.blockchain_path, serialized)
        )
        .await
        .map_err(|_| UseCaseError::Concurrency("Timeout while saving blockchain".to_string()))?
        .map_err(|e| UseCaseError::Storage(format!("Failed to write blockchain file: {}", e)))?;
        
        Ok(())
    }

    /// Initialize the blockchain if it doesn't exist
    async fn ensure_initialized(&self) -> Result<(), UseCaseError> {
        // Check if blockchain is already initialized
        let blocks = self.blocks.read().await;
        if !blocks.is_empty() {
            return Ok(());
        }
        drop(blocks);

        // Create genesis block
        let mut genesis = Block::new(
            0,
            "0".repeat(64),
            self.validator_did.clone(),
            vec![], // Empty transactions for genesis
        )?;
        
        // Sign genesis block
        let block_hash = genesis.calculate_hash()?;
        genesis.signature = Some((self.sign_function)(&block_hash.as_bytes())?);
        
        // Save genesis block
        let mut blocks = self.blocks.write().await;
        blocks.push(genesis);
        self.save_chain(&blocks).await?;
        
        Ok(())
    }
    
    /// Load the blockchain from storage or initialize if new
    pub async fn load_or_init_blockchain(&self) -> Result<(), UseCaseError> {
        match self.load_blockchain().await {
            Ok(_) => Ok(()),
            Err(UseCaseError::Storage(_)) => {
                // Storage error might mean file doesn't exist, try initializing
                self.ensure_initialized().await
            }
            Err(e) => Err(e),
        }
    }

    /// Load the blockchain from storage
    async fn load_blockchain(&self) -> Result<(), UseCaseError> {
        // Load from file using async file operations
        let contents = tokio::fs::read_to_string(&self.blockchain_path)
            .await
            .map_err(|e| {
                log::warn!("Failed to read blockchain file: {}, initializing new chain", e);
                UseCaseError::Storage("Failed to read blockchain".to_string())
            })?;

        let loaded_blocks: Vec<Block> = serde_json::from_str(&contents)
            .map_err(|e| {
                log::warn!("Failed to parse blockchain data: {}, initializing new chain", e);
                UseCaseError::Storage("Invalid blockchain data".to_string())
            })?;

        // Verify loaded chain
        for block in &loaded_blocks {
            let hash = block.calculate_hash()?;
            if let Some(sig) = &block.signature {
                if !(self.verify_function)(&hash.as_bytes(), sig)? {
                    log::warn!("Invalid block signature in loaded chain, initializing new chain");
                    return Err(UseCaseError::Storage("Invalid blockchain state".to_string()));
                }
            }
        }

        // Clone the blocks since we'll use them in the async block
        let blocks_to_write = loaded_blocks.clone();
        
        // Use a timeout when acquiring the write lock
        tokio::time::timeout(
            std::time::Duration::from_secs(5),
            async {
                let mut blocks = self.blocks.write().await;
                *blocks = blocks_to_write;
                Ok::<_, UseCaseError>(())
            }
        ).await.map_err(|_| UseCaseError::Concurrency("Timeout while updating blockchain".to_string()))??;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    use std::sync::Arc;

    struct TestContext {
        _temp_dir: tempfile::TempDir,
        service: Arc<FileBlockchainService>,
    }

    impl TestContext {
        #[allow(dead_code)]  // Kept for manual test cleanup when needed
        async fn cleanup(&self) -> Result<(), UseCaseError> {
            // Clear blocks and pending transactions with timeout
            let blocks_cleared = tokio::time::timeout(
                std::time::Duration::from_secs(5),
                async {
                    let mut blocks = self.service.blocks.write().await;
                    blocks.clear();
                    let mut pending = self.service.pending_transactions.write().await;
                    pending.clear();
                }
            ).await;

            if blocks_cleared.is_err() {
                return Err(UseCaseError::Concurrency("Timeout while clearing blocks".to_string()));
            }
            
            // Reset blockchain file
            tokio::fs::write(&self.service.blockchain_path, "[]")
                .await
                .map_err(|e| UseCaseError::Storage(format!("Failed to cleanup blockchain: {}", e)))?;
            
            Ok(())
        }
    }

    async fn setup_test_context() -> TestContext {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos();
            
        let temp_dir = tempdir().expect("Failed to create temp directory");
        let blockchain_path = temp_dir.path().join(format!("blockchain_{}.json", now));
        
        // Create parent directory if it doesn't exist
        if let Some(parent) = blockchain_path.parent() {
            tokio::fs::create_dir_all(parent)
                .await
                .expect("Failed to create blockchain directory");
        }
        
        let service = Arc::new(FileBlockchainService::new(
            blockchain_path.clone(),
            DID::new(&format!("test:did:{}", now), "test_key_hash"),
            Box::new(|data: &[u8]| -> Result<String, UseCaseError> { 
                Ok(hex::encode(data)) 
            }),
            Box::new(|data: &[u8], sig: &str| -> Result<bool, UseCaseError> { 
                Ok(sig == hex::encode(data)) 
            })
        ).expect("Failed to create test service"));

        // Initialize empty blockchain file
        tokio::fs::write(&blockchain_path, "[]")
            .await
            .expect("Failed to initialize blockchain file");

        // Initialize blockchain with genesis block
        service.ensure_initialized().await.expect("Failed to initialize blockchain");
        
        TestContext {
            _temp_dir: temp_dir,
            service,
        }
    }

    async fn create_test_service() -> FileBlockchainService {
        let temp_dir = tempdir().expect("Failed to create temp directory");
        let blockchain_path = temp_dir.path().join("blockchain.json");
        
        let service = FileBlockchainService::new(
            blockchain_path.clone(),
            DID::new("test:did:123", "test_key_hash"),
            Box::new(|data: &[u8]| -> Result<String, UseCaseError> { 
                Ok(hex::encode(data)) 
            }),
            Box::new(|data: &[u8], sig: &str| -> Result<bool, UseCaseError> { 
                Ok(sig == hex::encode(data)) 
            })
        ).expect("Failed to create test service");

        // Initialize blockchain with genesis block
        tokio::fs::write(&blockchain_path, "[]")
            .await
            .expect("Failed to initialize blockchain file");
        service.ensure_initialized().await.expect("Failed to initialize blockchain");
        
        service
    }

    #[tokio::test]
    async fn test_blockchain_initialization() {
        let ctx = setup_test_context().await;
        
        // Verify genesis block
        let blocks = ctx.service.blocks.read().await;
        assert_eq!(blocks.len(), 1);
        
        let genesis = &blocks[0];
        assert_eq!(genesis.header.block_number, 0);
        assert_eq!(genesis.header.previous_hash, "0".repeat(64));
        assert!(genesis.transactions.is_empty());
        assert!(genesis.signature.is_some());
        
        // Verify genesis block hash
        let hash = genesis.calculate_hash().unwrap();
        assert!((ctx.service.verify_function)(&hash.as_bytes(), genesis.signature.as_ref().unwrap()).unwrap());
    }

    #[tokio::test]
    async fn test_register_did() {
        let ctx = setup_test_context().await;
        let service = &ctx.service;
        let did = DID::generate("test_key_hash");
        
        let tx_id = service.register_did(&did, "test_public_key").await.unwrap();
        assert!(!tx_id.is_empty());
        
        // Verify transaction was added
        let transactions = service.get_did_transactions(&did).await.unwrap();
        assert_eq!(transactions.len(), 1);
        assert_eq!(transactions[0].transaction_type, TransactionType::RegisterDID);
    }

    #[tokio::test]
    async fn test_update_did() {
        let ctx = setup_test_context().await;
        let service = &ctx.service;
        let did = DID::new("test:did:789", "test_key_hash");
        
        // First register the DID
        service.register_did(&did, "initial_key").await.unwrap();
        
        // Then update it
        let tx_id = service.update_did(&did, "new_public_key").await.unwrap();
        assert!(!tx_id.is_empty());
        
        // Verify both transactions exist
        let transactions = service.get_did_transactions(&did).await.unwrap();
        assert_eq!(transactions.len(), 2);
        assert!(transactions.iter().any(|tx| tx.transaction_type == TransactionType::UpdateDID));
    }

    #[tokio::test]
    async fn test_message_metadata() {
        let service = create_test_service().await;
        let sender = DID::new("test:did:sender", "sender_key_hash");
        let recipient = DID::new("test:did:recipient", "recipient_key_hash");
        
        let tx_id = service.register_message_metadata(
            &sender,
            &[recipient.clone()],
            "test_message_hash"
        ).await.unwrap();
        
        assert!(!tx_id.is_empty());
        
        // Verify both sender and recipient can retrieve the transaction
        let sender_txs = service.get_did_transactions(&sender).await.unwrap();
        let recipient_txs = service.get_did_transactions(&recipient).await.unwrap();
        
        assert_eq!(sender_txs.len(), 1);
        assert_eq!(recipient_txs.len(), 1);
        assert_eq!(sender_txs[0].id, recipient_txs[0].id);
    }
    #[tokio::test]
    async fn test_block_creation() {
        let service = create_test_service().await;
        let did = DID::generate("test_key_hash");
        
        // Add multiple transactions to trigger block creation
        for i in 0..11 {
            service.register_message_metadata(
                &did,
                &[],
                &format!("message_{}", i)
            ).await.unwrap();
        }
        
        // Verify a new block was created
        let latest_block = service.get_latest_block().await.unwrap();
        assert!(latest_block.header.block_number > 0);
        assert!(!latest_block.transactions.is_empty());
    }

    #[tokio::test]
    async fn test_chain_verification() {
        let ctx = setup_test_context().await;
        let service = &ctx.service;
        let did = DID::generate("test_key_hash");
        
        // Add transactions to create multiple blocks
        for i in 0..3 {
            let transactions = vec![
                Transaction::new(
                    TransactionType::RegisterDID,
                    did.clone(),
                    TransactionPayload::DIDRegistration {
                        did: did.clone(),
                        public_key: format!("test_data_{}", i),
                    },
                )
            ];
            let block = service.add_block(transactions).await.unwrap();
            
            // Verify block hash and signature
            assert!(block.signature.is_some());
            let block_hash = block.calculate_hash().unwrap();
            assert!((service.verify_function)(&block_hash.as_bytes(), block.signature.as_ref().unwrap()).unwrap());
        }
        
        // Verify full chain
        assert!(service.verify_chain().await.unwrap());
        
        // Verify block links
        let blocks = service.blocks.read().await;
        for i in 1..blocks.len() {
            let current = &blocks[i];
            let previous = &blocks[i-1];
            assert_eq!(current.header.block_number, previous.header.block_number + 1);
            assert_eq!(current.header.previous_hash, previous.calculate_hash().unwrap());
        }
    }
}use thiserror::Error;
use crate::domain::error::DomainError;

/// Erros que podem ocorrer nos casos de uso
#[derive(Error, Debug)]
pub enum UseCaseError {
    #[error("Erro de domínio: {0}")]
    Domain(#[from] DomainError),
    
    #[error("Erro de validação: {0}")]
    Validation(String),
    
    #[error("Entidade não encontrada: {0}")]
    NotFound(String),
    
    #[error("Erro de banco de dados: {0}")]
    Database(redis::RedisError),
    
    #[error("Erro de rede: {0}")]
    Network(String),
    
    #[error("Erro de autenticação: {0}")]
    Authentication(String),
    
    #[error("Erro de autorização: {0}")]
    Authorization(String),
    
    #[error("Erro de criptografia: {0}")]
    Crypto(String),
    
    #[error("Erro de serviço externo: {0}")]
    ExternalService(String),
    
    #[error("Erro na blockchain: {0}")]
    Blockchain(String),
    
    #[error("Erro de configuração: {0}")]
    Configuration(String),
    
    #[error("Erro de concorrência: {0}")]
    Concurrency(String),
    
    #[error("Operação não suportada: {0}")]
    Unsupported(String),
    
    #[error("Erro interno: {0}")]
    Internal(String),
    
    #[error("Conflito: {0}")]
    Conflict(String),
    
    #[error("Erro de serialização: {0}")]
    Serialization(serde_json::Error),
    
    #[error("Operação inválida: {0}")]
    InvalidOperation(String),
    
    #[error("Já existe: {0}")]
    AlreadyExists(String),

    #[error("Storage error: {0}")]
    Storage(String),
}

impl From<serde_json::Error> for UseCaseError {
    fn from(err: serde_json::Error) -> Self {
        UseCaseError::Serialization(err)
    }
}

impl From<std::io::Error> for UseCaseError {
    fn from(err: std::io::Error) -> Self {
        UseCaseError::Internal(format!("IO error: {}", err))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_usecase_error_from_domain_error() {
        let domain_error = DomainError::Validation("teste".to_string());
        let usecase_error: UseCaseError = domain_error.into();
        
        match usecase_error {
            UseCaseError::Domain(DomainError::Validation(msg)) => {
                assert_eq!(msg, "teste");
            }
            _ => panic!("Erro incorreto"),
        }
    }
    
    #[test]
    fn test_usecase_error_display() {
        let error = UseCaseError::Validation("campo inválido".to_string());
        let error_str = format!("{}", error);
        assert!(error_str.contains("campo inválido"));
    }
    
    #[test]
    fn test_usecase_error_from_io_error() {
        let io_error = std::io::Error::new(std::io::ErrorKind::NotFound, "arquivo não encontrado");
        let usecase_error = UseCaseError::from(io_error);
        
        match usecase_error {
            UseCaseError::Internal(msg) => {
                assert!(msg.contains("IO error"));
                assert!(msg.contains("arquivo não encontrado"));
            }
            _ => panic!("Erro incorreto"),
        }
    }
}use crate::domain::identity::{DID, IdentityMetadata, VerificationStatus};
use crate::usecases::error::UseCaseError;
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::Utc;
use serde::{Serialize, Deserialize};
use crate::usecases::blockchain::BlockchainService;

#[async_trait]
pub trait AsyncIdentityService: Send + Sync {
    /// Cria um novo DID com metadados associados
    async fn create_identity(
        &self,
        did: DID,
        metadata: IdentityMetadata,
    ) -> Result<(), UseCaseError>;

    /// Obtém um DID e seus metadados
    async fn get_identity(&self, did_string: &str) -> Result<Option<(DID, IdentityMetadata)>, UseCaseError>;

    /// Atualiza a chave pública de um DID
    async fn update_identity_key(
        &self,
        did: &DID,
        new_public_key: &str,
    ) -> Result<(), UseCaseError>;

    /// Atualiza os metadados de um DID
    async fn update_identity_metadata(
        &self,
        did: &DID,
        metadata: IdentityMetadata,
    ) -> Result<(), UseCaseError>;

    /// Revoga um DID
    async fn revoke_identity(&self, did: &DID, reason: &str) -> Result<(), UseCaseError>;

    /// Verifica se um DID é válido
    async fn verify_identity(&self, did: &DID) -> Result<bool, UseCaseError>;

    /// Busca DIDs por critérios
    async fn search_identities(&self, query: IdentitySearchQuery) -> Result<Vec<(DID, IdentityMetadata)>, UseCaseError>;
}

pub trait IdentityService: Send + Sync {
    fn as_async(&self) -> &dyn AsyncIdentityService;
}

/// Critérios de pesquisa para identidades
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentitySearchQuery {
    pub display_name: Option<String>,
    pub verification_status: Option<VerificationStatus>,
    pub device_id: Option<String>,
    pub attributes: Option<HashMap<String, String>>,
    pub limit: Option<usize>,
    pub offset: Option<usize>,
}

/// Implementação do serviço de identidade com blockchain e Redis
pub struct BlockchainIdentityService {
    identities: Arc<RwLock<HashMap<String, IdentityMetadata>>>,
    blockchain_service: Arc<dyn BlockchainService>,
}

impl BlockchainIdentityService {
    /// Cria uma nova instância do serviço de identidade
    pub fn new(blockchain_service: Arc<dyn BlockchainService>) -> Self {
        Self {
            identities: Arc::new(RwLock::new(HashMap::new())),
            blockchain_service,
        }
    }
    
    /// Carrega todas as identidades da blockchain
    pub async fn load_identities(&self) -> Result<(), UseCaseError> {
        // Implementação simplificada: Em produção, seria feito de forma mais eficiente
        // carregando do banco de dados Redis e sincronizando com a blockchain
        
        // Isto é apenas um stub para testes - em produção, seria persistente
        let mut identities = self.identities.write().await;
        identities.clear();
        
        Ok(())
    }
}

#[async_trait]
impl AsyncIdentityService for BlockchainIdentityService {
    async fn create_identity(
        &self,
        did: DID,
        metadata: IdentityMetadata,
    ) -> Result<(), UseCaseError> {
        // Armazena os metadados
        let mut identities = self.identities.write().await;
        identities.insert(did.to_string(), metadata);
        
        Ok(())
    }
    
    async fn get_identity(&self, did_string: &str) -> Result<Option<(DID, IdentityMetadata)>, UseCaseError> {
        // Tenta parsear o DID
        let did = match DID::parse(did_string) {
            Ok(did) => did,
            Err(_) => return Ok(None),
        };
        
        // Verifica se o DID existe na blockchain
        let transactions = self.blockchain_service.get_did_transactions(&did).await?;
        if transactions.is_empty() {
            return Ok(None);
        }
        
        // Obtém os metadados
        let identities = self.identities.read().await;
        let metadata = match identities.get(did_string) {
            Some(meta) => meta.clone(),
            None => IdentityMetadata::default(), // Retorna metadados padrão se não encontrados
        };
        
        Ok(Some((did, metadata)))
    }
    
    async fn update_identity_key(
        &self,
        did: &DID,
        new_public_key: &str,
    ) -> Result<(), UseCaseError> {
        // Atualiza localmente
        let mut did_clone = did.clone();
        did_clone.update_public_key_hash(new_public_key);
        
        // Atualiza os metadados
        let mut identities = self.identities.write().await;
        if let Some(meta) = identities.get_mut(&did.to_string()) {
            meta.updated_at = Utc::now();
        }
        
        Ok(())
    }
    
    async fn update_identity_metadata(
        &self,
        did: &DID,
        metadata: IdentityMetadata,
    ) -> Result<(), UseCaseError> {
        // Certifica-se de que o DID existe
        let transactions = self.blockchain_service.get_did_transactions(did).await?;
        if transactions.is_empty() {
            return Err(UseCaseError::NotFound(format!("DID não encontrado: {}", did)));
        }
        
        // Atualiza os metadados
        let mut identities = self.identities.write().await;
        
        // Preserva a data de criação e atualiza a data de modificação
        let mut updated_metadata = metadata.clone();
        
        if let Some(existing) = identities.get(&did.to_string()) {
            updated_metadata.created_at = existing.created_at;
        }
        
        updated_metadata.updated_at = Utc::now();
        
        identities.insert(did.to_string(), updated_metadata);
        
        Ok(())
    }
    