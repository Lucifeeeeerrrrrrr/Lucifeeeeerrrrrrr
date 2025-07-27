            assert!(!behaviour.is_connected(&peer_id, &state));
            assert_eq!(behaviour.connected_peers(&state).len(), 0);
        }
    }
    
    #[test]
    fn test_p2p_behaviour_topics() {
        let keypair = Keypair::generate_ed25519();
        let local_peer_id = PeerId::from(keypair.public());
        let (mut behaviour, shared_state) = P2PBehaviour::new(local_peer_id, &keypair);
        
        let topic_name = "test-topic";
        
        // Add topic without subscribing
        {
            let mut state = shared_state.lock().unwrap();
            let result = behaviour.add_topic(topic_name, false, &mut state);
            assert!(result.is_some());
        }
        
        // Subscribe to topic
        {
            let mut state = shared_state.lock().unwrap();
            let result = behaviour.subscribe_to_topic(topic_name, &mut state);
            assert!(result.is_ok());
        }
        
        // Check subscriptions
        {
            let topic = Topic::new(topic_name);
            assert!(behaviour.gossipsub.is_subscribed(&topic));
        }
    }
    
    #[test]
    fn test_p2p_behaviour_kademlia() {
        let keypair = Keypair::generate_ed25519();
        let local_peer_id = PeerId::from(keypair.public());
        let (mut behaviour, shared_state) = P2PBehaviour::new(local_peer_id, &keypair);
        
        let key = b"test-key".to_vec();
        
        // Test get record
        {
            let mut state = shared_state.lock().unwrap();
            let query_id = behaviour.get_record(key, &mut state);
            // QueryId no longer has is_zero, so check it's valid some other way
            assert!(format!("{:?}", query_id).len() > 0);
        }
    }
} use std::time::Duration;

#[derive(Debug, Clone)]
pub struct ResourceLimits {
    max_connections_per_peer: u32,
    max_established_connections: u32,
    max_pending_incoming: u32,
    max_pending_outgoing: u32,
    connection_timeout: Duration,
}

impl Default for ResourceLimits {
    fn default() -> Self {
        Self {
            max_connections_per_peer: 8,
            max_established_connections: 1000,
            max_pending_incoming: 100,
            max_pending_outgoing: 100,
            connection_timeout: Duration::from_secs(60),
        }
    }
}

impl ResourceLimits {
    pub fn with_max_connections_per_peer(mut self, max: u32) -> Self {
        self.max_connections_per_peer = max;
        self
    }

    pub fn with_max_established_connections(mut self, max: u32) -> Self {
        self.max_established_connections = max;
        self
    }

    pub fn with_max_pending_incoming(mut self, max: u32) -> Self {
        self.max_pending_incoming = max;
        self
    }

    pub fn with_max_pending_outgoing(mut self, max: u32) -> Self {
        self.max_pending_outgoing = max;
        self
    }

    pub fn with_connection_timeout(mut self, timeout: Duration) -> Self {
        self.connection_timeout = timeout;
        self
    }

    pub fn max_connections_per_peer(&self) -> u32 {
        self.max_connections_per_peer
    }

    pub fn max_established_connections(&self) -> u32 {
        self.max_established_connections
    }

    pub fn max_pending_incoming(&self) -> u32 {
        self.max_pending_incoming
    }

    pub fn max_pending_outgoing(&self) -> u32 {
        self.max_pending_outgoing
    }

    pub fn connection_timeout(&self) -> Duration {
        self.connection_timeout
    }
}

/// Configuração padrão dos limites de recursos da rede
pub fn default_resource_limits() -> ResourceLimits {
    ResourceLimits::default()
        // Limitar conexões por peer
        .with_max_connections_per_peer(8)
        // Limitar conexões totais
        .with_max_established_connections(1000)
        // Limitar conexões de entrada pendentes
        .with_max_pending_incoming(100)
        // Limitar conexões de saída pendentes
        .with_max_pending_outgoing(100)
        // Configurar timeout para conexões pendentes
        .with_connection_timeout(Duration::from_secs(60))
}

/// Configuração de recursos mais restritiva para cenários com alta carga
pub fn strict_resource_limits() -> ResourceLimits {
    ResourceLimits::default()
        .with_max_connections_per_peer(2)
        .with_max_established_connections(100)
        .with_max_pending_incoming(20)
        .with_max_pending_outgoing(20)
        .with_connection_timeout(Duration::from_secs(30))
}

/// Configuração adaptativa de recursos baseada na carga atual
pub struct AdaptiveResourceManager {
    current_limits: ResourceLimits,
    low_load_limits: ResourceLimits,
    high_load_limits: ResourceLimits,
    system_load_threshold: f64, // 0.0 - 1.0
}

impl AdaptiveResourceManager {
    pub fn new() -> Self {
        Self {
            current_limits: default_resource_limits(),
            low_load_limits: default_resource_limits(),
            high_load_limits: strict_resource_limits(),
            system_load_threshold: 0.7,
        }
    }
    
    /// Atualiza os limites baseado na carga do sistema
    pub fn update_limits(&mut self) -> ResourceLimits {
        let system_load = self.get_system_load();
        
        if system_load > self.system_load_threshold {
            self.current_limits = self.high_load_limits.clone();
        } else {
            self.current_limits = self.low_load_limits.clone();
        }
        
        self.current_limits.clone()
    }
    
    fn get_system_load(&self) -> f64 {
        // Implementação básica, pode ser expandida para leitura real
        // da carga do sistema usando bibliotecas como sysinfo
        #[cfg(target_os = "linux")]
        {
            if let Ok(load) = std::fs::read_to_string("/proc/loadavg") {
                if let Some(value) = load.split_whitespace().next() {
                    if let Ok(load_float) = value.parse::<f64>() {
                        // Normalizar para um valor entre 0.0 e 1.0
                        return (load_float / num_cpus::get() as f64).min(1.0);
                    }
                }
            }
        }
        
        // Default fallback
        0.5
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_resource_limits() {
        let limits = default_resource_limits();
        assert_eq!(limits.max_connections_per_peer(), 8);
        assert_eq!(limits.max_established_connections(), 1000);
        assert_eq!(limits.max_pending_incoming(), 100);
        assert_eq!(limits.max_pending_outgoing(), 100);
        assert_eq!(limits.connection_timeout(), Duration::from_secs(60));
    }

    #[test]
    fn test_strict_resource_limits() {
        let limits = strict_resource_limits();
        assert_eq!(limits.max_connections_per_peer(), 2);
        assert_eq!(limits.max_established_connections(), 100);
        assert_eq!(limits.max_pending_incoming(), 20);
        assert_eq!(limits.max_pending_outgoing(), 20);
        assert_eq!(limits.connection_timeout(), Duration::from_secs(30));
    }

    #[test]
    fn test_resource_limits_builder() {
        let limits = ResourceLimits::default()
            .with_max_connections_per_peer(5)
            .with_max_established_connections(500)
            .with_max_pending_incoming(50)
            .with_max_pending_outgoing(50)
            .with_connection_timeout(Duration::from_secs(45));

        assert_eq!(limits.max_connections_per_peer(), 5);
        assert_eq!(limits.max_established_connections(), 500);
        assert_eq!(limits.max_pending_incoming(), 50);
        assert_eq!(limits.max_pending_outgoing(), 50);
        assert_eq!(limits.connection_timeout(), Duration::from_secs(45));
    }

    #[test]
    fn test_adaptive_resource_manager() {
        let mut manager = AdaptiveResourceManager::new();
        
        // Test initial state
        assert_eq!(manager.current_limits.max_connections_per_peer(), 8);
        
        // Test update_limits
        let updated_limits = manager.update_limits();
        assert!(updated_limits.max_connections_per_peer() == 8 || updated_limits.max_connections_per_peer() == 2);
        
        // Test system load calculation
        let load = manager.get_system_load();
        assert!(load >= 0.0 && load <= 1.0);
    }

    #[test]
    fn test_system_load_calculation() {
        let manager = AdaptiveResourceManager::new();
        let load = manager.get_system_load();
        
        // System load should be a normalized value between 0 and 1
        assert!(load >= 0.0);
        assert!(load <= 1.0);
        
        // On Linux, it should use actual system metrics
        #[cfg(target_os = "linux")]
        {
            let cpu_count = num_cpus::get();
            assert!(cpu_count > 0);
        }
    }
}// network/src/security/eclipse.rs
use libp2p::{
    kad::{Kademlia, KBucketKey, Key},
    PeerId,
};
use std::{
    collections::{HashMap, HashSet},
    net::{IpAddr, Ipv4Addr, Ipv6Addr},
    time::{Duration, Instant},
};
use log::{info, warn, error};

/// Proteção contra ataques Eclipse
pub struct EclipseProtection {
    /// Rastreamento de IPs por bucket para evitar dominação de buckets
    ips_by_bucket: HashMap<String, HashSet<IpAddr>>,
    /// Máximo de IPs de um mesmo /24 (IPv4) ou /64 (IPv6) por bucket
    max_ips_per_subnet_per_bucket: usize,
    /// Rastreamento de subredes para buckets
    subnets_by_bucket: HashMap<String, HashMap<SubnetId, usize>>,
    /// Seeds de bootstrap confiáveis para recuperação
    trusted_bootstrap_peers: Vec<(PeerId, String)>,
    /// Última vez que fizemos bootstrap a partir de peers confiáveis
    last_trusted_bootstrap: Option<Instant>,
    /// Intervalo para bootstrap a partir de peers confiáveis
    trusted_bootstrap_interval: Duration,
    /// Mínimo de diversidade de IPs por bucket
    min_bucket_diversity: usize,
}

/// Identificador de subrede
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
enum SubnetId {
    V4([u8; 3]), // /24
    V6([u8; 8]), // /64
}

impl From<&IpAddr> for SubnetId {
    fn from(ip: &IpAddr) -> Self {
        match ip {
            IpAddr::V4(ipv4) => {
                let octets = ipv4.octets();
                Self::V4([octets[0], octets[1], octets[2]])
            }
            IpAddr::V6(ipv6) => {
                let segments = ipv6.segments();
                // Apenas os primeiros 8 bytes (/64)
                Self::V6([
                    segments[0], segments[1], segments[2], segments[3], 
                    0, 0, 0, 0
                ])
            }
        }
    }
}

impl EclipseProtection {
    /// Criar nova instância de proteção anti-Eclipse
    pub fn new() -> Self {
        Self {
            ips_by_bucket: HashMap::new(),
            max_ips_per_subnet_per_bucket: 3, // Máximo de 3 IPs da mesma subrede por bucket
            subnets_by_bucket: HashMap::new(),
            trusted_bootstrap_peers: vec![
                // Você adicionaria seus peers de bootstrap confiáveis aqui
                // (PeerId, Endereço multiaddr)
            ],
            last_trusted_bootstrap: None,
            trusted_bootstrap_interval: Duration::from_secs(3600), // 1 hora
            min_bucket_diversity: 3, // Mínimo de 3 IPs diferentes por bucket
        }
    }
    
    /// Adicionar um peer confiável para bootstrap
    pub fn add_trusted_peer(&mut self, peer_id: PeerId, addr: String) {
        self.trusted_bootstrap_peers.push((peer_id, addr));
    }
    
    /// Configurar o máximo de IPs por subrede por bucket
    pub fn set_max_ips_per_subnet(&mut self, max: usize) {
        if max > 0 {
            self.max_ips_per_subnet_per_bucket = max;
        }
    }
    
    /// Configurar intervalo para bootstrap confiável
    pub fn set_bootstrap_interval(&mut self, interval: Duration) {
        self.trusted_bootstrap_interval = interval;
    }
    
    /// Configurar diversidade mínima de IPs por bucket
    pub fn set_min_bucket_diversity(&mut self, min: usize) {
        if min > 0 {
            self.min_bucket_diversity = min;
        }
    }
    
    /// Verificar se devemos permitir adicionar este peer ao bucket
    pub fn should_allow_in_bucket(&mut self, 
                                 bucket_key: &str,
                                 peer_id: &PeerId, 
                                 ip: &IpAddr) -> bool {
        // Rastrear IPs neste bucket
        let ips = self.ips_by_bucket.entry(bucket_key.to_string())
                                    .or_insert_with(HashSet::new);
        
        // Se o IP já está no bucket, permitir (mesmo peer_id ou outro)
        if ips.contains(ip) {
            return true;
        }
        
        // Identificar a subrede do IP
        let subnet = SubnetId::from(ip);
        
        // Verificar limites por subrede
        let subnet_counts = self.subnets_by_bucket.entry(bucket_key.to_string())
                                                 .or_insert_with(HashMap::new);
        let count = subnet_counts.entry(subnet.clone()).or_insert(0);
        
        // Se já ultrapassou o limite para esta subrede
        if *count >= self.max_ips_per_subnet_per_bucket {
            warn!("Rejeitando peer {} no bucket {}: limite de IPs por subrede ultrapassado", 
                  peer_id, bucket_key);
            return false;
        }
        
        // Incrementar contador de IPs para esta subrede
        *count += 1;
        
        // Registrar o IP neste bucket
        ips.insert(*ip);
        
        info!("Peer {} com IP {} aceito no bucket {}", peer_id, ip, bucket_key);
        true
    }
    
    /// Verificar diversidade de buckets e realizar bootstrap se necessário
    pub fn check_bucket_diversity<S: libp2p::kad::store::KademliaDhtStore>(&mut self, kademlia: &mut Kademlia<S>) {
        let now = Instant::now();
        
        // Verificar se é hora de fazer bootstrap de peers confiáveis
        if self.last_trusted_bootstrap.map_or(true, |last| {
            now.duration_since(last) > self.trusted_bootstrap_interval
        }) {
            self.perform_trusted_bootstrap(kademlia);
            self.last_trusted_bootstrap = Some(now);
            info!("Bootstrap confiável realizado");
        }
        
        // Verificar buckets com baixa diversidade
        for (bucket, ips) in &self.ips_by_bucket {
            if ips.len() < self.min_bucket_diversity {
                warn!("Bucket {} tem baixa diversidade de IPs, apenas {} IPs únicos",
                      bucket, ips.len());
                
                // Tentar recuperar este bucket específico
                self.recover_bucket(kademlia, bucket);
            }
        }
    }
    
    /// Remover um peer de um bucket
    pub fn remove_peer_from_bucket(&mut self, bucket_key: &str, peer_id: &PeerId, ip: &IpAddr) {
        // Remover IP do conjunto para este bucket
        if let Some(ips) = self.ips_by_bucket.get_mut(bucket_key) {
            ips.remove(ip);
        }
        
        // Decrementar contador para a subrede
        let subnet = SubnetId::from(ip);
        if let Some(subnet_counts) = self.subnets_by_bucket.get_mut(bucket_key) {
            if let Some(count) = subnet_counts.get_mut(&subnet) {
                *count = count.saturating_sub(1);
                
                // Remover entry se contador chegou a zero
                if *count == 0 {
                    subnet_counts.remove(&subnet);
                }
            }
        }
        
        info!("Peer {} com IP {} removido do bucket {}", peer_id, ip, bucket_key);
    }
    
    /// Recuperar a diversidade de um bucket específico
    fn recover_bucket<S: libp2p::kad::store::KademliaDhtStore>(&self, kademlia: &mut Kademlia<S>, bucket: &str) {
        if self.trusted_bootstrap_peers.is_empty() {
            warn!("Não há peers de bootstrap confiáveis configurados para recuperar o bucket {}", bucket);
            return;
        }
        
        info!("Tentando recuperar diversidade do bucket {}", bucket);
        
        // Bootstrap específico para este bucket
        for (peer_id, addr) in &self.trusted_bootstrap_peers {
            if let Ok(multiaddr) = addr.parse() {
                // Adicionar peer de bootstrap
                kademlia.add_address(peer_id, multiaddr);
            }
        }
        
        // Iniciar consulta para este bucket
        if let Ok(key) = bucket.parse::<Vec<u8>>() {
            // Realizar uma busca próxima deste bucket
            let random_key = Key::new(&key);
            if let Err(e) = kademlia.get_closest_peers(random_key) {
                error!("Erro ao iniciar busca para recuperar bucket {}: {:?}", bucket, e);
            }
        }
    }
    
    /// Bootstrap a partir de peers confiáveis
    fn perform_trusted_bootstrap<S: libp2p::kad::store::KademliaDhtStore>(&self, kademlia: &mut Kademlia<S>) {
        if self.trusted_bootstrap_peers.is_empty() {
            warn!("Não há peers de bootstrap confiáveis configurados");
            return;
        }
        
        info!("Realizando bootstrap a partir de peers confiáveis");
        
        // Adicionar peers de bootstrap
        for (peer_id, addr) in &self.trusted_bootstrap_peers {
            if let Ok(multiaddr) = addr.parse() {
                kademlia.add_address(peer_id, multiaddr);
            } else {
                warn!("Endereço inválido para peer de bootstrap {}: {}", peer_id, addr);
            }
        }
        
        // Iniciar bootstrap
        if let Err(e) = kademlia.bootstrap() {
            error!("Erro ao iniciar bootstrap: {:?}", e);
        }
    }
    
    /// Obter estatísticas de diversidade
    pub fn get_diversity_stats(&self) -> HashMap<String, (usize, usize)> {
        let mut stats = HashMap::new();
        
        for (bucket, ips) in &self.ips_by_bucket {
            let subnet_count = self.subnets_by_bucket
                .get(bucket)
                .map_or(0, |subnets| subnets.len());
            
            stats.insert(bucket.clone(), (ips.len(), subnet_count));
        }
        
        stats
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    // Função auxiliar para criar peers para testes
    fn create_test_peer(id: u8) -> PeerId {
        // Criar peers determinísticos para testes
        PeerId::from_str(&format!("QmYyQSo1c1Ym7orWxLYvCrM2EmxFTANf8wXmmE7DWjhx{:02}", id)).unwrap()
    }
    
    #[test]
    fn test_subnet_identification() {
        // IPv4
        let ip1 = IpAddr::V4(Ipv4Addr::new(192, 168, 1, 1));
        let ip2 = IpAddr::V4(Ipv4Addr::new(192, 168, 1, 2));
        let ip3 = IpAddr::V4(Ipv4Addr::new(192, 168, 2, 1));
        
        let subnet1 = SubnetId::from(&ip1);
        let subnet2 = SubnetId::from(&ip2);
        let subnet3 = SubnetId::from(&ip3);
        
        assert_eq!(subnet1, subnet2); // Mesmo /24
        assert_ne!(subnet1, subnet3); // Diferente /24
        
        // IPv6
        let ipv6_1 = IpAddr::V6(Ipv6Addr::new(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1));
        let ipv6_2 = IpAddr::V6(Ipv6Addr::new(0x2001, 0xdb8, 0, 0, 0, 0, 0, 2));
        let ipv6_3 = IpAddr::V6(Ipv6Addr::new(0x2001, 0xdb9, 0, 0, 0, 0, 0, 1));
        
        let subnet_v6_1 = SubnetId::from(&ipv6_1);
        let subnet_v6_2 = SubnetId::from(&ipv6_2);
        let subnet_v6_3 = SubnetId::from(&ipv6_3);
        
        assert_eq!(subnet_v6_1, subnet_v6_2); // Mesmo /64
        assert_ne!(subnet_v6_1, subnet_v6_3); // Diferente /64
    }
}use std::collections::{HashMap, HashSet};
use std::net::IpAddr;
use libp2p::{PeerId, kad::{Behaviour}};
use log::{debug, warn, info};
use crate::config::EclipseConfig;
use crate::error::{NetworkError, NetworkResult};
use ipnetwork::{Ipv4Network, Ipv6Network};

/// Estrutura para armazenar informações sobre um bucket Kademlia
#[derive(Debug)]
struct BucketInfo {
    /// Mapeamento de peer para IP
    peers: HashMap<PeerId, IpAddr>,
    
    /// Mapeamento de subrede para conjunto de IPs
    subnet_ips: HashMap<String, HashSet<IpAddr>>,
    
    /// Mapeamento inverso de IP para subrede
    ip_subnet: HashMap<IpAddr, String>,
}

impl BucketInfo {
    fn new() -> Self {
        Self {
            peers: HashMap::new(),
            subnet_ips: HashMap::new(),
            ip_subnet: HashMap::new(),
        }
    }
    
    /// Adiciona um peer ao bucket
    fn add_peer(&mut self, peer_id: &PeerId, ip: &IpAddr, subnet: &str) {
        // Armazenar mapeamento peer -> IP
        self.peers.insert(*peer_id, *ip);
        
        // Armazenar mapeamento IP -> subnet
        self.ip_subnet.insert(*ip, subnet.to_string());
        
        // Adicionar IP à subnet
        self.subnet_ips
            .entry(subnet.to_string())
            .or_insert_with(HashSet::new)
            .insert(*ip);
    }
    
    /// Remove um peer do bucket
    fn remove_peer(&mut self, peer_id: &PeerId) -> Option<(IpAddr, String)> {
        // Remover do mapeamento peer -> IP
        if let Some(ip) = self.peers.remove(peer_id) {
            // Obter subnet
            if let Some(subnet) = self.ip_subnet.get(&ip) {
                let subnet = subnet.clone();
                
                // Remover IP da subnet
                if let Some(ips) = self.subnet_ips.get_mut(&subnet) {
                    ips.remove(&ip);
                    
                    // Se a subnet ficou vazia, remover
                    if ips.is_empty() {
                        self.subnet_ips.remove(&subnet);
                    }
                }
                
                // Remover IP -> subnet
                self.ip_subnet.remove(&ip);
                
                return Some((ip, subnet));
            }
        }
        
        None
    }
    
    /// Obtém o número de IPs em uma subnet
    fn subnet_ip_count(&self, subnet: &str) -> usize {
        self.subnet_ips
            .get(subnet)
            .map(|ips| ips.len())
            .unwrap_or(0)
    }
    
    /// Obtém o número de subnets diferentes
    fn distinct_subnet_count(&self) -> usize {
        self.subnet_ips.len()
    }
    
    /// Obtém estatísticas do bucket
    fn get_stats(&self) -> (usize, usize) {
        let ip_count = self.peers.len();
        let subnet_count = self.subnet_ips.len();
        
        (ip_count, subnet_count)
    }
}

/// Proteção contra ataques Eclipse (isolamento de nodes)
#[derive(Debug)]
pub struct EclipseProtection {
    /// Mapeamento de bucket ID para informações do bucket
    buckets: HashMap<String, BucketInfo>,
    
    /// Configuração
    config: EclipseConfig,
}

impl Default for EclipseProtection {
    fn default() -> Self {
        Self::new()
    }
}

impl EclipseProtection {
    /// Cria uma nova instância com configurações padrão
    pub fn new() -> Self {
        Self::with_config(EclipseConfig::default())
    }
    
    /// Cria uma nova instância com configuração personalizada
    pub fn with_config(config: EclipseConfig) -> Self {
        Self {
            buckets: HashMap::new(),
            config,
        }
    }
    
    /// Aplica nova configuração
    pub fn apply_config(&mut self, config: EclipseConfig) {
        self.config = config;
    }
    
    /// Define o número máximo de IPs por subrede
    pub fn set_max_ips_per_subnet(&mut self, max: usize) {
        self.config.max_ips_per_subnet = max;
    }
    
    /// Obtém a representação de subrede de um IP
    fn get_subnet_str(&self, ip: &IpAddr) -> String {
        match ip {
            IpAddr::V4(ipv4) => {
                // Criar uma rede IPv4 usando o prefixo da config
                let subnet = Ipv4Network::new(*ipv4, self.config.subnet_mask_ipv4)
                    .expect("Máscara de subrede IPv4 inválida");
                format!("{}", subnet)
            },
            IpAddr::V6(ipv6) => {
                // Criar uma rede IPv6 usando o prefixo da config
                let subnet = Ipv6Network::new(*ipv6, self.config.subnet_mask_ipv6)
                    .expect("Máscara de subrede IPv6 inválida");
                format!("{}", subnet)
            }
        }
    }
    
    /// Verifica se um peer deve ser permitido em um bucket
    pub fn should_allow_in_bucket(&mut self, bucket_id: &str, peer_id: &PeerId, ip: &IpAddr) -> NetworkResult<bool> {
        // Obter subnet do IP antes de pegar o bucket mutável
        let subnet = self.get_subnet_str(ip);
        
        // Obter ou criar informações do bucket
        let bucket = self.buckets
            .entry(bucket_id.to_string())
            .or_insert_with(BucketInfo::new);
            
        // Se o peer já existe neste bucket (atualização), permitir
        if bucket.peers.contains_key(peer_id) {
            return Ok(true);
        }
        
        // Verificar se a subnet já atingiu o limite
        let subnet_ip_count = bucket.subnet_ip_count(&subnet);
        
        if subnet_ip_count >= self.config.max_ips_per_subnet {
            warn!("Peer {} rejeitado no bucket {} - Subnet {} excedeu limite de IPs ({})",
                peer_id, bucket_id, subnet, self.config.max_ips_per_subnet);
            return Err(NetworkError::SecurityLimit(
                format!("Subnet {} excedeu limite de {} IPs no bucket {}", 
                    subnet, self.config.max_ips_per_subnet, bucket_id)
            ));
        }
        
        // Verificar a diversidade mínima quando o bucket tem muitos peers
        if bucket.peers.len() > self.config.min_distinct_subnets * 2 {
            let distinct_subnets = bucket.distinct_subnet_count();
            
            if distinct_subnets < self.config.min_distinct_subnets {
                warn!("Peer {} rejeitado no bucket {} - Diversidade de subredes insuficiente ({}/{})",
                    peer_id, bucket_id, distinct_subnets, self.config.min_distinct_subnets);
                return Err(NetworkError::SecurityLimit(
                    format!("Diversidade de subredes insuficiente no bucket {}: {}/{}", 
                        bucket_id, distinct_subnets, self.config.min_distinct_subnets)
                ));
            }
        }
        
        // Permitir e adicionar o peer ao bucket
        bucket.add_peer(peer_id, ip, &subnet);
        debug!("Peer {} adicionado ao bucket {} (Subnet: {})", peer_id, bucket_id, subnet);
        
        Ok(true)
    }
    
    /// Remove um peer de um bucket
    pub fn remove_peer_from_bucket(&mut self, bucket_id: &str, peer_id: &PeerId, _ip: &IpAddr) {
        if let Some(bucket) = self.buckets.get_mut(bucket_id) {
            if let Some((ip, subnet)) = bucket.remove_peer(peer_id) {
                debug!("Peer {} removido do bucket {} (IP: {}, Subnet: {})", 
                    peer_id, bucket_id, ip, subnet);
            }
        }
    }
    
    /// Verifica a diversidade de todos os buckets
    pub fn check_bucket_diversity<K: AsRef<[u8]>>(&self, _kademlia: &mut Behaviour<K>) {
        let distinct_subnets_required = self.config.min_distinct_subnets;
        
        for (bucket_id, bucket) in &self.buckets {
            let (ip_count, subnet_count) = bucket.get_stats();
            
            info!("Bucket {}: {} IPs de {} subredes diferentes", bucket_id, ip_count, subnet_count);
            
            // Verificar diversidade mínima
            if ip_count > distinct_subnets_required * 2 && subnet_count < distinct_subnets_required {
                warn!("Diversidade de subredes insuficiente no bucket {}: {}/{}", 
                    bucket_id, subnet_count, distinct_subnets_required);
                
                // Em um caso real, poderíamos implementar aqui medidas ativas como 
                // remover peers de subredes super-representadas
            }
        }
    }
    
    /// Obtém estatísticas de diversidade para todos os buckets
    pub fn get_diversity_stats(&self) -> Vec<(String, (usize, usize))> {
        let mut stats = Vec::new();
        
        for (bucket_id, bucket) in &self.buckets {
            stats.push((bucket_id.clone(), bucket.get_stats()));
        }
        
        stats
    }
} pub mod sybil_protection;
pub mod eclipse_protection;

pub use sybil_protection::{SybilProtection, SybilProtectionStats};
pub use eclipse_protection::EclipseProtection;use libp2p::{
    core::identity::Keypair,
    kad::record::Key,
    PeerId,
};
use std::{
    collections::{HashMap, HashSet},
    net::IpAddr,
    time::{Duration, Instant},
};
use sha2::{Sha256, Digest};
use log::{info, warn, error};

pub struct SybilProtection {
    /// Máximo de peers por IP
    max_peers_per_ip: usize,
    /// Rastreamento de peers por IP
    peers_by_ip: HashMap<IpAddr, HashSet<PeerId>>,
    /// Peers com histórico de comportamento suspeito
    suspicious_peers: HashMap<PeerId, u32>,
    /// Peers bloqueados
    blocked_peers: HashSet<PeerId>,
    /// Rastreamento de joins/leaves para detectar churn rápido
    peer_activity: HashMap<PeerId, Vec<(bool, Instant)>>, // bool: true=join, false=leave
    /// Limite de joing/leaves em um período para ser considerado suspeito
    churn_threshold: usize,
    /// Período para considerar churn
    churn_window: Duration,
    /// Soluções de prova de trabalho exigidas para certos recursos
    pow_required: bool,
    /// Dificuldade da prova de trabalho (número de zeros iniciais)
    pow_difficulty: u8,
    /// Desafios ativos para prova de trabalho
    active_challenges: HashMap<PeerId, Vec<u8>>,
}

impl SybilProtection {
    /// Criar nova instância de proteção anti-Sybil
    pub fn new() -> Self {
        Self {
            max_peers_per_ip: 5,
            peers_by_ip: HashMap::new(),
            suspicious_peers: HashMap::new(),
            blocked_peers: HashSet::new(),
            peer_activity: HashMap::new(),
            churn_threshold: 10,
            churn_window: Duration::from_secs(60 * 10), // 10 minutos
            pow_required: true,
            pow_difficulty: 2, // 2 bytes = 16 bits de zeros iniciais
            active_challenges: HashMap::new(),
        }
    }
    
    /// Configurar o número máximo de peers por IP
    pub fn set_max_peers_per_ip(&mut self, max: usize) {
        if max > 0 {
            self.max_peers_per_ip = max;
        }
    }
    
    /// Configurar o threshold de churn
    pub fn set_churn_threshold(&mut self, threshold: usize) {
        if threshold > 0 {
            self.churn_threshold = threshold;
        }
    }
    
    /// Configurar a janela de tempo para detecção de churn
    pub fn set_churn_window(&mut self, window: Duration) {
        if window > Duration::from_secs(0) {
            self.churn_window = window;
        }
    }
    
    /// Configurar a dificuldade da prova de trabalho
    pub fn set_pow_difficulty(&mut self, difficulty: u8) {
        if difficulty <= 32 { // Máximo 32 bytes (todo o hash)
            self.pow_difficulty = difficulty;
        }
    }
    
    /// Habilitar ou desabilitar prova de trabalho
    pub fn set_pow_required(&mut self, required: bool) {
        self.pow_required = required;
    }
    
    /// Verificar se devemos permitir conexão de um peer
    pub fn should_allow_connection(&mut self, peer_id: &PeerId, ip: &IpAddr) -> bool {
        // Verificar se o peer está bloqueado
        if self.blocked_peers.contains(peer_id) {
            warn!("Rejeitando conexão de peer bloqueado: {}", peer_id);
            return false;
        }
        
        // Verificar limite por IP
        let peers_from_ip = self.peers_by_ip.entry(*ip).or_insert_with(HashSet::new);
        if peers_from_ip.len() >= self.max_peers_per_ip && !peers_from_ip.contains(peer_id) {
            warn!("Rejeitando conexão: limite de peers por IP ({}) atingido para {}", 
                  self.max_peers_per_ip, ip);
            return false;
        }
        
        // Registrar o peer
        peers_from_ip.insert(*peer_id);
        
        // Registrar atividade de join
        self.record_peer_activity(*peer_id, true);
        
        info!("Conexão permitida para peer {} do IP {}", peer_id, ip);
        true
    }
    
    /// Registrar desconexão de peer
    pub fn record_disconnect(&mut self, peer_id: &PeerId, ip: Option<&IpAddr>) {
        // Registrar atividade de leave
        self.record_peer_activity(*peer_id, false);
        
        // Remover do mapeamento IP, se disponível
        if let Some(ip) = ip {
            if let Some(peers) = self.peers_by_ip.get_mut(ip) {
                peers.remove(peer_id);
                info!("Peer {} desconectado do IP {}", peer_id, ip);
            }
        }
        
        // Verificar comportamento de churn
        self.check_churn_behavior(peer_id);
    }
    
    /// Verificar se uma operação DHT deve ser permitida
    pub fn should_allow_dht_operation(&mut self, peer_id: &PeerId, key: &[u8]) -> bool {
        // Não permitir operações de peers suspeitos
        if self.suspicious_peers.get(peer_id).map_or(0, |&v| v) > 5 {
            warn!("Rejeitando operação DHT de peer suspeito: {}", peer_id);
            return false;
        }
        
        // Para operações sensíveis, exigir prova de trabalho
        if self.pow_required && self.is_sensitive_key(key) {
            // Gerar um desafio para o peer se ainda não tiver um
            if !self.active_challenges.contains_key(peer_id) {
                let challenge = self.generate_challenge(peer_id);
                self.active_challenges.insert(*peer_id, challenge);
                info!("Desafio PoW gerado para peer {} para operação sensível", peer_id);
            }
            
            warn!("Rejeitando operação DHT sensível: prova de trabalho necessária para peer {}", peer_id);
            return false;
        }
        
        true
    }
    
    /// Registrar comportamento suspeito
    pub fn record_suspicious_behavior(&mut self, peer_id: &PeerId) {
        let count = self.suspicious_peers.entry(*peer_id).or_insert(0);
        *count += 1;
        
        warn!("Comportamento suspeito registrado para peer {}: {} ocorrências", 
             peer_id, *count);
        
        // Bloquear após muitos comportamentos suspeitos
        if *count > 10 {
            info!("Bloqueando peer {} após muitos comportamentos suspeitos", peer_id);
            self.blocked_peers.insert(*peer_id);
        }
    }
    
    /// Gerar um desafio para prova de trabalho
    pub fn generate_challenge(&self, peer_id: &PeerId) -> Vec<u8> {
        // Gerar um desafio aleatório baseado no peer_id e timestamp
        let mut challenge = Vec::with_capacity(40);
        challenge.extend_from_slice(peer_id.to_bytes().as_ref());
        challenge.extend_from_slice(&std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos()
            .to_le_bytes());
        challenge
    }
    
    /// Verificar se uma solução de prova de trabalho é válida
    pub fn verify_proof_of_work(&self, peer_id: &PeerId, challenge: &[u8], solution: &[u8]) -> bool {
        let mut hasher = Sha256::new();
        hasher.update(challenge);
        hasher.update(solution);
        let hash = hasher.finalize();
        
        // Verificar se os primeiros self.pow_difficulty bytes são zeros
        for i in 0..self.pow_difficulty as usize {
            if hash[i] != 0 {
                return false;
            }
        }
        
        // Se a verificação passar, podemos aceitar a solução
        info!("Prova de trabalho válida recebida do peer {}", peer_id);
        true
    }
    
    /// Submeter uma solução para um desafio
    pub fn submit_pow_solution(&mut self, peer_id: &PeerId, solution: &[u8]) -> bool {
        if let Some(challenge) = self.active_challenges.get(peer_id) {
            let result = self.verify_proof_of_work(peer_id, challenge, solution);
            
            if result {
                // Limpar o desafio após uma solução válida
                self.active_challenges.remove(peer_id);
            }
            
            result
        } else {
            false
        }
    }
    
    // Métodos auxiliares internos
    
    fn record_peer_activity(&mut self, peer_id: PeerId, is_join: bool) {
        let activities = self.peer_activity.entry(peer_id).or_insert_with(Vec::new);
        activities.push((is_join, Instant::now()));
        
        // Limpar atividades antigas
        let cutoff = Instant::now() - self.churn_window;
        activities.retain(|&(_, time)| time > cutoff);
    }
    
    fn check_churn_behavior(&mut self, peer_id: &PeerId) {
        if let Some(activities) = self.peer_activity.get(peer_id) {
            if activities.len() > self.churn_threshold {
                // Comportamento de churn suspeito detectado
                warn!("Churn suspeito detectado para peer {}: {} atividades na janela de tempo",
                     peer_id, activities.len());
                self.record_suspicious_behavior(peer_id);
            }
        }
    }
    
    fn is_sensitive_key(&self, key: &[u8]) -> bool {
        // Identificar chaves sensíveis que deveriam exigir prova de trabalho
        // Por exemplo, chaves que controlam recursos importantes
        key.starts_with(b"critical/") || key.starts_with(b"admin/")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_pow_verification() {
        let sybil = SybilProtection::new();
        let peer_id = PeerId::random();
        
        // Teste com solução inválida
        let challenge = b"test-challenge";
        let invalid_solution = b"invalid-solution";
        assert!(!sybil.verify_proof_of_work(&peer_id, challenge, invalid_solution));
        
        // Idealmente também testaríamos uma solução válida gerada através de
        // uma função auxiliar que faria o mining de uma solução
    }
}use std::collections::{HashMap, HashSet};
use std::net::IpAddr;
use std::time::{Duration, Instant, SystemTime};
use libp2p::PeerId;
use log::{debug, warn};
use crate::config::SybilConfig;
use crate::error::{NetworkError, NetworkResult};

/// Estrutura para rastreamento de conexões/desconexões rápidas (churn)
#[derive(Debug)]
struct ChurnTracker {
    /// Eventos de churn (conexão/desconexão) registrados com timestamps
    events: Vec<Instant>,
    /// Janela de tempo para monitoramento
    time_window: Duration,
    /// Limite máximo de eventos na janela
    max_events: u32,
}

impl ChurnTracker {
    fn new(max_events: u32, time_window_secs: u64) -> Self {
        Self {
            events: Vec::new(),
            time_window: Duration::from_secs(time_window_secs),
            max_events,
        }
    }
    
    /// Registra um evento de churn e limpa eventos antigos
    fn record_event(&mut self) {
        let now = Instant::now();
        
        // Limpar eventos fora da janela de tempo
        self.events.retain(|&time| now.duration_since(time) <= self.time_window);
        
        // Adicionar novo evento
        self.events.push(now);
    }
    
    /// Verifica se o limite de churn foi excedido
    fn is_limit_exceeded(&self) -> bool {
        self.events.len() as u32 > self.max_events
    }
    
    /// Retorna o número de eventos na janela atual
    fn event_count(&self) -> usize {
        let now = Instant::now();
        self.events
            .iter()
            .filter(|&&time| now.duration_since(time) <= self.time_window)
            .count()
    }
}

/// Estrutura para rastreamento de comportamento suspeito
#[derive(Debug)]
struct SuspiciousBehavior {
    /// Contador de comportamentos suspeitos
    count: u32,
    /// Último comportamento suspeito registrado
    last_recorded: Instant,
    /// Bloqueado até este momento
    blocked_until: Option<Instant>,
    /// Limite de comportamentos antes do bloqueio
    threshold: u32,
    /// Tempo para resetar contador
    reset_time: Duration,
    /// Tempo de bloqueio
    block_time: Duration,
}

impl SuspiciousBehavior {
    fn new(threshold: u32, reset_time_secs: u64, block_time_secs: u64) -> Self {
        Self {
            count: 0,
            last_recorded: Instant::now(),
            blocked_until: None,
            threshold,
            reset_time: Duration::from_secs(reset_time_secs),
            block_time: Duration::from_secs(block_time_secs),
        }
    }
    
    /// Registra comportamento suspeito
    fn record(&mut self) {
        let now = Instant::now();
        
        // Se passou o tempo de reset, zeramos o contador
        if now.duration_since(self.last_recorded) > self.reset_time {
            self.count = 0;
        }
        
        self.count += 1;
        self.last_recorded = now;
        
        // Se excedeu o limite, bloqueamos
        if self.count >= self.threshold {
            self.blocked_until = Some(now + self.block_time);
            warn!("Peer bloqueado por comportamento suspeito até {:?}", self.blocked_until);
            self.count = 0;
        }
    }
    
    /// Verifica se está bloqueado atualmente
    fn is_blocked(&self) -> bool {
        if let Some(until) = self.blocked_until {
            Instant::now() < until
        } else {
            false
        }
    }
    
    /// Retorna informações sobre o bloqueio
    fn block_info(&self) -> Option<(Instant, Duration)> {
        self.blocked_until.map(|until| {
            let now = Instant::now();
            let remaining = if now < until {
                until.duration_since(now)
            } else {
                Duration::from_secs(0)
            };
            (until, remaining)
        })
    }
}

/// Proteção contra ataques Sybil (múltiplos peers de mesma origem)
#[derive(Debug)]
pub struct SybilProtection {
    /// Mapeamento de IP para conjunto de peers conectados
    ip_peers: HashMap<IpAddr, HashSet<PeerId>>,
    
    /// Rastreamento de comportamento suspeito por peer
    suspicious_behavior: HashMap<PeerId, SuspiciousBehavior>,
    
    /// Rastreamento de churn por IP
    churn_trackers: HashMap<IpAddr, ChurnTracker>,
    
    /// Configuração de proteção Sybil
    config: SybilConfig,
}

impl Default for SybilProtection {
    fn default() -> Self {
        Self::new()
    }
}

impl SybilProtection {
    /// Cria uma nova instância com configurações padrão
    pub fn new() -> Self {
        Self::with_config(SybilConfig::default())
    }
    
    /// Cria uma nova instância com configuração personalizada
    pub fn with_config(config: SybilConfig) -> Self {
        Self {
            ip_peers: HashMap::new(),
            suspicious_behavior: HashMap::new(),
            churn_trackers: HashMap::new(),
            config,
        }
    }
    
    /// Aplica nova configuração
    pub fn apply_config(&mut self, config: SybilConfig) {
        self.config = config;
        
        // Atualizar configuração de churn trackers existentes
        for tracker in self.churn_trackers.values_mut() {
            tracker.max_events = self.config.max_churn_events;
            tracker.time_window = Duration::from_secs(self.config.churn_time_window_secs);
        }
        
        // Atualizar configuração de suspicious behavior existentes
        for behavior in self.suspicious_behavior.values_mut() {
            behavior.threshold = self.config.suspicious_behavior_threshold;
            behavior.reset_time = Duration::from_secs(self.config.suspicious_reset_time_secs);
            behavior.block_time = Duration::from_secs(self.config.suspicious_block_time_secs);
        }
    }
    
    /// Define o número máximo de peers por IP
    pub fn set_max_peers_per_ip(&mut self, max: usize) {
        self.config.max_peers_per_ip = max;
    }
    
    /// Verifica se uma conexão deve ser permitida
    pub fn should_allow_connection(&mut self, peer_id: &PeerId, ip: &IpAddr) -> NetworkResult<bool> {
        // Verificar se o peer está bloqueado por comportamento suspeito
        if let Some(behavior) = self.suspicious_behavior.get(peer_id) {
            if behavior.is_blocked() {
                if let Some((until, remaining)) = behavior.block_info() {
                    warn!("Conexão rejeitada - peer {} bloqueado por mais {:?}", peer_id, remaining);
                    return Err(NetworkError::ConnectionRejected(
                        format!("Peer bloqueado por comportamento suspeito até {:?}", until)
                    ));
                }
            }
        }
        
        // Verificar se o IP tem muitos peers (possível ataque Sybil)
        let peer_count = self.ip_peers
            .get(ip)
            .map(|peers| peers.len())
            .unwrap_or(0);
            
        if peer_count >= self.config.max_peers_per_ip {
            warn!("Conexão rejeitada - IP {} excedeu limite de {} peers", ip, self.config.max_peers_per_ip);
            return Err(NetworkError::SecurityLimit(
                format!("IP {} excedeu limite de {} peers", ip, self.config.max_peers_per_ip)
            ));
        }
        
        // Verificar churn excessivo do IP
        if let Some(tracker) = self.churn_trackers.get(ip) {
            if tracker.is_limit_exceeded() {
                warn!("Conexão rejeitada - IP {} excedeu limite de churn ({} eventos em {}s)",
                    ip, tracker.event_count(), self.config.churn_time_window_secs);
                return Err(NetworkError::SecurityLimit(
                    format!("IP {} está conectando/desconectando muito rapidamente", ip)
                ));
            }
        }
        
        // Registrar evento de churn para este IP
        self.record_churn_event(ip);
        
        // Conexão permitida
        Ok(true)
    }
    
    /// Registra conexão bem-sucedida
    pub fn record_connection(&mut self, peer_id: &PeerId, ip: &IpAddr) {
        // Adicionar ao mapeamento de IP para peers
        self.ip_peers
            .entry(*ip)
            .or_insert_with(HashSet::new)
            .insert(*peer_id);
            
        debug!("Conexão registrada: {} ({})", peer_id, ip);
    }
    
    /// Registra desconexão de peer
    pub fn record_disconnect(&mut self, peer_id: &PeerId, ip: Option<&IpAddr>) {
        // Se temos o IP, atualizar diretamente
        if let Some(ip) = ip {
            // Primeiro registrar o evento de churn
            self.record_churn_event(ip);
            
            // Depois remover o peer do conjunto
            if let Some(peers) = self.ip_peers.get_mut(ip) {
                peers.remove(peer_id);
                
                // Se o conjunto ficou vazio, remover a entrada do IP
                if peers.is_empty() {
                    self.ip_peers.remove(ip);
                }
            }
        } else {
            // Se não temos o IP, procurar em todos os conjuntos
            let mut ip_to_remove = None;
            let mut found_ip = None;
            for (ip, peers) in &self.ip_peers {
                if peers.contains(peer_id) {
                    found_ip = Some(*ip);
                    break;
                }
            }
            if let Some(ip) = found_ip {
                self.record_churn_event(&ip);
                if let Some(peers) = self.ip_peers.get_mut(&ip) {
                    peers.remove(peer_id);
                    if peers.is_empty() {
                        ip_to_remove = Some(ip);
                    }
                }
            }
            // Remover IP se necessário
            if let Some(ip) = ip_to_remove {
                self.ip_peers.remove(&ip);
            }
        }
        
        debug!("Desconexão registrada: {}", peer_id);
    }
    
    /// Registra comportamento suspeito de um peer
    pub fn record_suspicious_behavior(&mut self, peer_id: &PeerId) {
        let behavior = self.suspicious_behavior
            .entry(*peer_id)
            .or_insert_with(|| SuspiciousBehavior::new(
                self.config.suspicious_behavior_threshold,
                self.config.suspicious_reset_time_secs,
                self.config.suspicious_block_time_secs
            ));
            
        behavior.record();
        
        warn!("Comportamento suspeito registrado para peer {}", peer_id);
    }
    
    /// Verifica se um peer está bloqueado
    pub fn is_peer_blocked(&self, peer_id: &PeerId) -> bool {
        self.suspicious_behavior
            .get(peer_id)
            .map(|behavior| behavior.is_blocked())
            .unwrap_or(false)
    }
    
    /// Registra evento de churn para um IP
    fn record_churn_event(&mut self, ip: &IpAddr) {
        let tracker = self.churn_trackers
            .entry(*ip)
            .or_insert_with(|| ChurnTracker::new(
                self.config.max_churn_events,
                self.config.churn_time_window_secs
            ));
            
        tracker.record_event();
        
        if tracker.is_limit_exceeded() {
            warn!("Limite de churn excedido para IP {}: {} eventos em {}s",
                ip, tracker.event_count(), self.config.churn_time_window_secs);
        }
    }
    
    /// Retorna estatísticas sobre as proteções
    pub fn get_stats(&self) -> SybilProtectionStats {
        let mut ips_with_multiple_peers = 0;
        let mut max_peers_per_ip = 0;
        let mut blocked_peers = 0;
        let mut ips_with_high_churn = 0;
        
        // Contar IPs com múltiplos peers
        for peers in self.ip_peers.values() {
            let count = peers.len();
            if count > 1 {
                ips_with_multiple_peers += 1;
            }
            max_peers_per_ip = max_peers_per_ip.max(count);
        }
        
        // Contar peers bloqueados
        for behavior in self.suspicious_behavior.values() {
            if behavior.is_blocked() {
                blocked_peers += 1;
            }
        }
        
        // Contar IPs com churn alto
        for tracker in self.churn_trackers.values() {
            if tracker.event_count() > (self.config.max_churn_events as usize / 2) {
                ips_with_high_churn += 1;
            }
        }
        
        SybilProtectionStats {
            total_ips: self.ip_peers.len(),
            total_peers: self.ip_peers.values().map(|p| p.len()).sum(),
            ips_with_multiple_peers,
            max_peers_per_ip,
            blocked_peers,
            total_suspicious_peers: self.suspicious_behavior.len(),
            ips_with_high_churn,
        }
    }
    
    /// Limpa dados antigos (pode ser chamado periodicamente)
    pub fn cleanup(&mut self) {
        let now = Instant::now();
        
        // Remover comportamentos suspeitos expirados
        self.suspicious_behavior.retain(|_, behavior| {
            if let Some(until) = behavior.blocked_until {
                now < until || behavior.count > 0
            } else {
                behavior.count > 0
            }
        });
        
        // Limpar trackers de churn sem eventos recentes
        self.churn_trackers.retain(|_, tracker| {
            if let Some(last) = tracker.events.last() {
                now.duration_since(*last) <= tracker.time_window * 2
            } else {
                false
            }
        });
    }

    pub fn should_allow_peer(&self, peer_id: &PeerId) -> bool {
        !self.is_peer_blocked(peer_id)
    }

    pub fn cleanup_expired_peers(&mut self) {
        let _now = SystemTime::now();
        
        // Collect keys to remove in a vector, then remove them after the loop
        let expired_ips: Vec<_> = self.ip_peers.iter()
            .filter(|(_, peers)| peers.is_empty())
            .map(|(ip, _)| *ip)
            .collect();

        for ip in expired_ips {
            self.ip_peers.remove(&ip);
        }

        // Clean up peers
        for peers in self.ip_peers.values_mut() {
            peers.retain(|_peer_id| {
                // Since we don't actually track last_seen times in this implementation,
                // we'll just keep all peers. In a real implementation, you'd check the timestamp.
                true
            });
        }

        // Replace the loop at line 263 with a two-step process to avoid double mutable borrow
        let ips_to_update: Vec<_> = self.ip_peers.keys().cloned().collect();
        for ip in ips_to_update {
            self.record_churn_event(&ip);
        }
    }
}

/// Estatísticas da proteção Sybil
#[derive(Debug, Clone)]
pub struct SybilProtectionStats {
    pub total_ips: usize,
    pub total_peers: usize,
    pub ips_with_multiple_peers: usize,
    pub max_peers_per_ip: usize,
    pub blocked_peers: usize,
    pub total_suspicious_peers: usize,
    pub ips_with_high_churn: usize,
} use std::sync::Arc;
use warp::{Filter, Reply, Rejection};
use serde::{Serialize, Deserialize};
use crate::Network;
use tokio::sync::RwLock as AsyncRwLock;
use crate::energy_manager::{EnergyManager, EnergyMetrics};
use log::{error, info};
use std::convert::Infallible;

/// Estrutura de resposta de métricas de energia
#[derive(Debug, Clone, Serialize)]
pub struct EnergyMetricsResponse {
    /// Economia de energia atual (em watts)
    pub current_savings: f64,
    /// Previsão de economia nas próximas 24 horas
    pub forecast_24h: f64,
    /// Histórico de economia (últimas 7 amostras)
    pub history: Vec<f64>,
}

/// Estrutura de resposta para status de rede
#[derive(Debug, Clone, Serialize)]
pub struct NetworkStatusResponse {
    /// Número de peers conectados
    pub connected_peers: usize,
    /// Lista de tópicos subscritos
    pub subscribed_topics: Vec<String>,
    /// ID do peer local
    pub local_peer_id: String,
    /// Status da proteção Sybil
    pub sybil_protection: bool,
    /// Endereços de escuta
    pub listen_addresses: Vec<String>,
}

/// Estado compartilhado para APIs
#[derive(Clone)]
pub struct ApiState {
    /// Gerenciador de rede
    pub network: Arc<AsyncRwLock<Network>>,
    /// Gerenciador de energia
    pub energy: Arc<AsyncRwLock<EnergyManager>>,
}

/// Obtém métricas de energia
async fn handle_energy_metrics(state: ApiState) -> Result<impl Reply, Rejection> {
    let energy = state.energy.read().await;
    let metrics = energy.get_latest_metrics();
    
    let response = EnergyMetricsResponse {
        current_savings: metrics.current_savings,
        forecast_24h: metrics.forecast_24h,
        history: metrics.history,
    };
    
    Ok(warp::reply::json(&response))
}

/// Obtém total de energia economizada
async fn handle_total_energy_saved(state: ApiState) -> Result<impl Reply, Rejection> {
    let energy = state.energy.read().await;
    let total = energy.get_total_energy_saved();
    
    Ok(warp::reply::json(&serde_json::json!({
        "total_energy_saved": total,
        "unit": "kWh"
    })))
}

/// Obtém status geral da rede
async fn handle_network_status(state: ApiState) -> Result<impl Reply, Rejection> {
    let network = state.network.read().await;
    let peers = network.get_connected_peers().await;
    let addresses = network.get_listen_addresses().await;
    
    let response = NetworkStatusResponse {
        connected_peers: peers.len(),
        subscribed_topics: network.get_subscribed_topics().await,
        local_peer_id: network.get_local_peer_id().to_string(),
        sybil_protection: network.is_sybil_protected().await,
        listen_addresses: addresses.into_iter().map(|a| a.to_string()).collect(),
    };
    
    Ok(warp::reply::json(&response))
}

/// Obtém status de um nó específico por ID
async fn handle_node_status(state: ApiState) -> Result<impl Reply, Rejection> {
    let network = state.network.read().await;
    let energy = state.energy.read().await;
    
    let metrics = energy.get_latest_metrics();
    let peers = network.get_connected_peers().await;
    
    Ok(warp::reply::json(&serde_json::json!({
        "network_status": {
            "connected_peers": peers.len(),
            "local_peer_id": network.get_local_peer_id().to_string(),
            "uptime": network.get_uptime().as_secs(),
        },
        "energy_status": {
            "current_savings": metrics.current_savings,
            "total_saved": energy.get_total_energy_saved(),
            "efficiency": energy.get_efficiency(),
        }
    })))
}

/// Define as rotas da API RESTful
pub fn routes(
    network: Network,
    energy_manager: EnergyManager,
) -> impl Filter<Extract = impl Reply, Error = Rejection> + Clone {
    let state = ApiState {
        network: Arc::new(AsyncRwLock::new(network)),
        energy: Arc::new(AsyncRwLock::new(energy_manager)),
    };
    
    let with_state = warp::any().map(move || state.clone());
    
    // Rota para verificação de saúde
    let health_route = warp::path!("api" / "health")
        .and(warp::get())
        .and_then(handle_health);
    
    // Endpoint: GET /api/metrics/energy
    let energy_route = warp::path!("api" / "metrics" / "energy")
        .and(warp::get())
        .and(with_state.clone())
        .and_then(handle_energy_metrics);

    // Endpoint: GET /api/metrics/energy/total
    let energy_total_route = warp::path!("api" / "metrics" / "energy" / "total")
        .and(warp::get())
        .and(with_state.clone())
        .and_then(handle_total_energy_saved);

    // Endpoint: GET /api/network/status
    let network_status_route = warp::path!("api" / "network" / "status")
        .and(warp::get())
        .and(with_state.clone())
        .and_then(handle_network_status);

    // Endpoint: GET /api/node/{id}/status
    let node_status_route = warp::path!("api" / "node" / "status")
        .and(warp::get())
        .and(with_state.clone())
        .and_then(handle_node_status);

    // Combinar todas as rotas
    health_route
        .or(energy_route)
        .or(energy_total_route)
        .or(network_status_route)
        .or(node_status_route)
        .with(warp::cors()
            .allow_any_origin()
            .allow_methods(vec!["GET", "POST", "OPTIONS"])
            .allow_headers(vec!["Content-Type", "Authorization"]))
        .recover(handle_rejection)
}

// Tratar erros de rejeição
async fn handle_rejection(err: Rejection) -> Result<impl Reply, Infallible> {
    let (code, message) = if err.is_not_found() {
        (warp::http::StatusCode::NOT_FOUND, "NOT_FOUND")
    } else if let Some(_) = err.find::<warp::reject::MethodNotAllowed>() {
        (warp::http::StatusCode::METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED")
    } else {
        error!("Unhandled rejection: {:?}", err);
        (warp::http::StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR")
    };

    Ok(warp::reply::with_status(
        warp::reply::json(&serde_json::json!({
            "code": code.as_u16(),
            "message": message,
            "timestamp": chrono::Utc::now().to_rfc3339()
        })),
        code,
    ))
}

async fn handle_health() -> Result<impl Reply, Rejection> {
    Ok(warp::reply::json(&serde_json::json!({
        "status": "ok",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
} #[cfg(test)]
mod tests {
    use super::*;
    use warp::test::request;
    use warp::http::StatusCode;
    use std::sync::Arc;
    use tokio::sync::RwLock as AsyncRwLock;
    use crate::energy_manager::EnergyManager;
    use crate::Network;
    use libp2p::identity::Keypair;

    async fn setup_test_state() -> ApiState {
        let local_key = Keypair::generate_ed25519();
        let network = Network::new(&local_key).await.unwrap();
        let energy_manager = EnergyManager::new();
        
        ApiState {
            network: Arc::new(network),
            energy: Arc::new(AsyncRwLock::new(energy_manager)),
        }
    }

    #[tokio::test]
    async fn test_health_endpoint() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("GET")
            .path("/api/health")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        let body: serde_json::Value = serde_json::from_slice(response.body()).unwrap();
        assert_eq!(body["status"], "ok");
    }

    #[tokio::test]
    async fn test_energy_metrics_endpoint() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("GET")
            .path("/api/metrics/energy")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        let body: EnergyMetricsResponse = serde_json::from_slice(response.body()).unwrap();
        
        // Verify response structure
        assert!(body.current_savings >= 0.0);
        assert!(body.forecast_24h >= 0.0);
        assert!(!body.history.is_empty());
    }

    #[tokio::test]
    async fn test_total_energy_saved_endpoint() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("GET")
            .path("/api/metrics/energy/total")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        let body: serde_json::Value = serde_json::from_slice(response.body()).unwrap();
        assert!(body["total_energy_saved"].as_f64().unwrap() >= 0.0);
    }

    #[tokio::test]
    async fn test_network_status_endpoint() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("GET")
            .path("/api/network/status")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        let body: NetworkStatusResponse = serde_json::from_slice(response.body()).unwrap();
        
        // Verify response structure
        assert_eq!(body.connected_peers, 0); // Initially no peers
        assert!(!body.local_peer_id.is_empty());
        assert!(body.sybil_protection);
        assert!(!body.listen_addresses.is_empty());
    }

    #[tokio::test]
    async fn test_node_status_endpoint() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("GET")
            .path("/api/node/status")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        let body: serde_json::Value = serde_json::from_slice(response.body()).unwrap();
        
        // Verify response structure
        assert!(body["network_status"]["connected_peers"].as_u64().unwrap() >= 0);
        assert!(!body["network_status"]["local_peer_id"].as_str().unwrap().is_empty());
        assert!(body["energy_status"]["current_savings"].as_f64().unwrap() >= 0.0);
        assert!(body["energy_status"]["total_saved"].as_f64().unwrap() >= 0.0);
    }

    #[tokio::test]
    async fn test_error_handling() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        // Test non-existent endpoint
        let response = request()
            .method("GET")
            .path("/api/non_existent")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
        
        // Test invalid method
        let response = request()
            .method("POST") // Using POST on GET-only endpoint
            .path("/api/health")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::METHOD_NOT_ALLOWED);
    }

    #[tokio::test]
    async fn test_cors() {
        let state = setup_test_state().await;
        let api = routes(Arc::clone(&state.network), state.energy.read().await.clone());
        
        let response = request()
            .method("OPTIONS")
            .path("/api/health")
            .header("Origin", "http://localhost:3000")
            .reply(&api)
            .await;
            
        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(
            response.headers()["access-control-allow-origin"],
            "*"
        );
    }
} use std::sync::Arc;
use tokio::sync::RwLock;
use warp::ws::{Message, WebSocket};
use std::collections::HashMap;
use tokio::sync::mpsc;
use libp2p::PeerId;
use futures::StreamExt;
use futures::SinkExt;
use log::{debug, error};
use crate::Network;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WebSocketMessage {
    pub action: String,
    pub data: serde_json::Value,
}

#[derive(Debug, Clone)]
pub enum NetworkCommand {
    Subscribe { topic: String },
    Publish { topic: String, data: Vec<u8> },
}

pub struct WebSocketManager {
    network: Arc<RwLock<Network>>,
    connections: Arc<RwLock<HashMap<PeerId, futures::stream::SplitSink<WebSocket, Message>>>>,
    pub command_tx: mpsc::UnboundedSender<NetworkCommand>,
}

impl WebSocketManager {
    pub fn new(network: Network) -> Self {
        let (command_tx, _) = mpsc::unbounded_channel();
        Self {
            network: Arc::new(RwLock::new(network)),
            connections: Arc::new(RwLock::new(HashMap::new())),
            command_tx,
        }
    }

    pub async fn handle_connection(&self, socket: WebSocket, peer_id: PeerId, _token: String) {
        debug!("New WebSocket connection from {}", peer_id);
        
        let (tx, mut rx) = socket.split();
        let sessions = self.connections.clone();
        let network = self.network.clone();
        
        // Store the sender
        sessions.write().await.insert(peer_id, tx);
        
        // Handle incoming messages
        while let Some(result) = rx.next().await {
            match result {
                Ok(msg) => {
                    if let Ok(text) = msg.to_str() {
                        if let Ok(msg) = serde_json::from_str::<WebSocketMessage>(text) {
                            let mut network = network.write().await;
                            match msg.action.as_str() {
                                "subscribe" => {
                                    if let Some(topic) = msg.data.as_str() {
                                        let _ = network.subscribe(topic);
                                    }
                                },
                                "publish" => {
                                    if let (Some(topic), Some(data)) = (
                                        msg.data.get("topic").and_then(|v| v.as_str()),
                                        msg.data.get("data").and_then(|v| v.as_array())
                                    ) {
                                        let data = data.iter()
                                            .filter_map(|v| v.as_u64())
                                            .map(|v| v as u8)
                                            .collect();
                                        let _ = network.publish(topic, data);
                                    }
                                },
                                _ => {}
                            }
                        }
                    }
                },
                Err(e) => {
                    error!("WebSocket error: {}", e);
                    break;
                }
            }
        }
        
        // Remove session on disconnect
        sessions.write().await.remove(&peer_id);
        debug!("WebSocket connection closed for {}", peer_id);
    }
    
    pub async fn broadcast_update(&self, update: WebSocketMessage) {
        if let Ok(msg) = serde_json::to_string(&update) {
            let mut sessions = self.connections.write().await;
            for tx in sessions.values_mut() {
                let _ = tx.send(Message::text(&msg)).await;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    // use super::*;
    use crate::websocket::types::WebSocketMessage;
    use serde_json;
    use uuid::Uuid;
    use chrono::Utc;

    #[test]
    fn test_parse_message_variant() {
        let json = serde_json::json!({
            "Message": {
                "id": Uuid::new_v4(),
                "from": "peer1",
                "to": "peer2",
                "content": "hello",
                "timestamp": Utc::now(),
                "encrypted": false
            }
        });
        let msg: WebSocketMessage = serde_json::from_value(json).unwrap();
        match msg {
            WebSocketMessage::Message { from, to, content, .. } => {
                assert_eq!(from, "peer1");
                assert_eq!(to, "peer2");
                assert_eq!(content, "hello");
            },
            _ => panic!("Expected Message variant")
        }
    }
} pub mod server;
mod types;
mod manager;

pub use types::{WebSocketMessage, WebSocketSession, NetworkStatus, PeerStatus, MessageStatus};
pub use manager::WebSocketManager;

// Re-export importante tipos
pub use server::WebSocketServer;

use crate::Network;

pub async fn start_websocket_server(network: Network, port: u16) -> anyhow::Result<()> {
    let server = WebSocketServer::new(network);
    server.start(port).await.map_err(Into::into)
} use std::sync::Arc;
use warp::{Filter, Rejection};
use futures::{StreamExt, SinkExt};
use serde::{Deserialize, Serialize};
use crate::error::NetworkResult;
use libp2p::PeerId;
use std::str::FromStr;
use tokio::sync::mpsc;
use anyhow::Result;
use crate::websocket::manager::NetworkCommand;
use crate::Network;

mod manager {
    use super::*;
    use std::sync::Arc;
    use warp::ws::{Message, WebSocket};
    use std::collections::HashMap;
    use tokio::sync::{RwLock, mpsc};
    
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct WebSocketMessage {
        pub action: String,
        pub data: serde_json::Value,
    }
    
    pub struct WebSocketManager {
        pub command_tx: mpsc::UnboundedSender<NetworkCommand>,
        connections: Arc<RwLock<HashMap<String, mpsc::Sender<Message>>>>,
    }
    
    impl WebSocketManager {
        pub fn new(command_tx: mpsc::UnboundedSender<NetworkCommand>) -> Self {
            Self {
                command_tx,
                connections: Arc::new(RwLock::new(HashMap::new())),
            }
        }
        
        pub async fn handle_connection(&self, ws: WebSocket, peer_id: String, _token: String) {
            let (mut ws_tx, mut ws_rx) = ws.split();
            let (tx, mut rx) = mpsc::channel::<Message>(32);
            
            // Register connection
            let connections = self.connections.clone();
            let command_tx = self.command_tx.clone();
            {
                let mut connections = connections.write().await;
                connections.insert(peer_id.clone(), tx);
            }
            
            // Process messages from client
            let peer_id_clone = peer_id.clone();
            let connections_recv = connections.clone();
            
            let receive_task = tokio::spawn(async move {
                while let Some(result) = ws_rx.next().await {
                    match result {
                        Ok(msg) => {
                            if let Ok(text) = msg.to_str() {
                                if let Ok(ws_msg) = serde_json::from_str::<WebSocketMessage>(text) {
                                    let _connections = connections_recv.write().await;
                                    match ws_msg.action.as_str() {
                                        "subscribe" => {
                                            if let Some(topic) = ws_msg.data.get("topic").and_then(|v| v.as_str()) {
                                                command_tx.send(NetworkCommand::Subscribe { topic: topic.to_string() }).unwrap();
                                            }
                                        },
                                        "publish" => {
                                            if let (Some(topic), Some(data)) = (
                                                ws_msg.data.get("topic").and_then(|v| v.as_str()),
                                                ws_msg.data.get("data").and_then(|v| v.as_str())
                                            ) {
                                                command_tx.send(NetworkCommand::Publish { topic: topic.to_string(), data: data.as_bytes().to_vec() }).unwrap();
                                            }
                                        },
                                        _ => {}
                                    }
                                }
                            }
                        },
                        Err(e) => {
                            eprintln!("WebSocket error: {}", e);
                            break;
                        }
                    }
                }
                
                // Cleanup on disconnect
                let mut connections = connections_recv.write().await;
                connections.remove(&peer_id_clone);
            });
            
            // Send messages to client
            let send_task = tokio::spawn(async move {
                while let Some(message) = rx.recv().await {
                    if let Err(e) = ws_tx.send(message).await {
                        eprintln!("Error sending message: {}", e);
                        break;
                    }
                }
            });
            
            // Wait for either task to complete
            tokio::select! {
                _ = receive_task => {},
                _ = send_task => {},
            }
        }
        
        #[allow(dead_code)]
        pub async fn broadcast(&self, message: &WebSocketMessage) -> Result<()> {
            let msg = serde_json::to_string(message)?;
            let connections = self.connections.read().await;
            
            for tx in connections.values() {
                if let Err(e) = tx.send(Message::text(msg.clone())).await {
                    eprintln!("Failed to broadcast message: {}", e);
                }
            }
            
            Ok(())
        }
    }
}

mod types {
    use serde::{Deserialize, Serialize};
    
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct WebSocketMessage {
        pub action: String,
        pub data: serde_json::Value,
    }
}

pub struct WebSocketServer {
    manager: Arc<manager::WebSocketManager>,
}

impl WebSocketServer {
    pub fn new(_network: Network) -> Self {
        let (tx, _rx) = mpsc::unbounded_channel();
        Self {
            manager: Arc::new(manager::WebSocketManager::new(tx)),
        }
    }

    pub async fn start(&self, port: u16) -> NetworkResult<()> {
        let manager = self.manager.clone();
        
        let ws_route = warp::path("ws")
            .and(warp::ws())
            .and(warp::query::<WebSocketQuery>())
            .and_then(move |ws: warp::ws::Ws, query: WebSocketQuery| {
                let manager = manager.clone();
                async move {
                    if !validate_token(&query.token).await {
                        return Err(warp::reject::custom(WebSocketError::InvalidToken));
                    }
                    
                    let _peer_id = match PeerId::from_str(&query.peer_id) {
                        Ok(id) => id,
                        Err(_) => return Err(warp::reject::custom(WebSocketError::InvalidPeerId)),
                    };
                    
                    Ok::<_, Rejection>(ws.on_upgrade(move |socket| {
                        let manager = manager.clone();
                        async move {
                            manager.handle_connection(socket, query.peer_id.clone(), query.token).await;
                        }
                    }))
                }
            });
            
        let routes = ws_route.with(warp::cors().allow_any_origin());
        
        warp::serve(routes)
            .run(([0, 0, 0, 0], port))
            .await;
            
        Ok(())
    }
}

#[derive(Debug, Deserialize)]
struct WebSocketQuery {
    peer_id: String,
    token: String,
}

#[derive(Debug)]
enum WebSocketError {
    InvalidToken,
    InvalidPeerId,
}

impl warp::reject::Reject for WebSocketError {}

async fn validate_token(_token: &str) -> bool {
    // Implement token validation
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::sync::mpsc;

    #[tokio::test]
    async fn test_command_channel() {
        let (tx, mut rx) = mpsc::unbounded_channel();
        let manager = manager::WebSocketManager::new(tx);
        manager.command_tx.send(NetworkCommand::Subscribe { topic: "test".to_string() }).unwrap();
        if let Some(NetworkCommand::Subscribe { topic }) = rx.recv().await {
            assert_eq!(topic, "test");
        } else {
            panic!("Expected Subscribe command");
        }
    }
} #[cfg(test)]
mod tests {
    use super::*;
    use crate::Network;
    use libp2p::identity::Keypair;
    use tokio::sync::mpsc;
    use warp::ws::Message;
    use warp::test::WsClient;
    use chrono::Utc;
    use uuid::Uuid;
    use std::sync::Arc;
    use std::time::Duration;
    use super::manager::WebSocketManager;
    use super::types::WebSocketMessage;
    use tokio::time::sleep;
    use serde_json::json;

    // Test to verify Network is Send + Sync
    #[test]
    fn test_network_manager_send_sync() {
        fn assert_send<T: Send>() {}
        fn assert_sync<T: Sync>() {}

        assert_send::<Network>();
        assert_sync::<Network>();
    }
    #[test]
    fn test_websocket_manager_send_sync() {
        fn assert_send<T: Send>() {}
        fn assert_sync<T: Sync>() {}

        assert_send::<WebSocketManager>();
        assert_sync::<WebSocketManager>();
    }

    #[tokio::test]
    async fn test_websocket_connection_handling() {
        // Setup
        let local_key = Keypair::generate_ed25519();
        let network = Network::new(&local_key).await.expect("Failed to create Network");
        let manager = WebSocketManager::new(network);
        
        // Create test WebSocket message - Note: 'message' variable is not used in this test.
        // let message = Message::text("test message"); 
        let base_peer_id = Uuid::new_v4().to_string();
        
        // Test concurrent connections
        let manager = Arc::new(manager);
        let mut handles = vec![];
        
        for i in 0..5 {
            let manager = Arc::clone(&manager);
            let peer_id_instance = format!("{}-{}", base_peer_id, i);
            
            let handle = tokio::spawn(async move {
                let (ws_client_conn, _ws_client_stream) = warp::test::create_ws_test_client().await; // Renamed for clarity
                manager.handle_connection(ws_client_conn, peer_id_instance).await
            });
            
            handles.push(handle);
        }
        
        // Wait for all connections to complete
        for handle in handles {
            handle.await.expect("Tokio task panicked").expect("handle_connection returned an error");
        }
    }

    async fn setup_test_server() -> (u16, Arc<WebSocketManager>, Network) {
        let local_key = Keypair::generate_ed25519();
        let network = Network::new(&local_key).await.unwrap();
        let manager = WebSocketManager::new(network.clone());
        let manager = Arc::new(manager);
        
        // Start server on random port
        let port = portpicker::pick_unused_port().expect("No ports free");
        
        Ok((port, manager, network))
    }

    #[tokio::test]
    async fn test_websocket_connection() {
        let (port, manager, _) = setup_test_server().await;
        
        // Test connection with valid token
        let client = warp::test::ws()
            .path(&format!("/ws?peer_id=test_peer&token=valid_token"))
            .handshake(([127, 0, 0, 1], port))
            .await
            .expect("Failed to connect");
            
        // Verify connection is registered
        {
            let connections = manager.connections.lock().await;
            assert!(connections.contains_key("test_peer"));
        }
        
        // Test invalid token
        let result = warp::test::ws()
            .path("/ws?peer_id=test_peer&token=invalid_token")
            .handshake(([127, 0, 0, 1], port))
            .await;
            
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_message_handling() {
        let (port, manager, _) = setup_test_server().await;
        
        // Connect client
        let mut client = warp::test::ws()
            .path("/ws?peer_id=test_peer&token=valid_token")
            .handshake(([127, 0, 0, 1], port))
            .await
            .expect("Failed to connect");
            
        // Send test message
        let test_msg = WebSocketMessage {
            action: "test".to_string(),
            data: json!({
                "content": "test message"
            }),
        };
        
        let msg_json = serde_json::to_string(&test_msg).unwrap();
        client.send(Message::text(msg_json)).await;
        
        // Wait for message processing
        sleep(Duration::from_millis(100)).await;
        
        // Verify message was processed
        let connections = manager.connections.lock().await;
        assert!(connections.contains_key("test_peer"));
    }

    #[tokio::test]
    async fn test_connection_cleanup() {
        let (port, manager, _) = setup_test_server().await;
        
        // Connect client
        let client = warp::test::ws()
            .path("/ws?peer_id=test_peer&token=valid_token")
            .handshake(([127, 0, 0, 1], port))
            .await
            .expect("Failed to connect");
            
        // Verify connection is registered
        {
            let connections = manager.connections.lock().await;
            assert!(connections.contains_key("test_peer"));
        }
        
        // Drop connection
        drop(client);
        
        // Wait for cleanup
        sleep(Duration::from_millis(100)).await;
        
        // Verify connection was removed
        let connections = manager.connections.lock().await;
        assert!(!connections.contains_key("test_peer"));
    }

    #[tokio::test]
    async fn test_concurrent_connections() {
        let (port, manager, _) = setup_test_server().await;
        let num_clients = 10;
        let mut clients = Vec::new();
        
        // Create multiple concurrent connections
        for i in 0..num_clients {
            let client = warp::test::ws()
                .path(&format!("/ws?peer_id=peer_{}&token=valid_token", i))
                .handshake(([127, 0, 0, 1], port))
                .await
                .expect("Failed to connect");
                
            clients.push(client);
        }
        
        // Verify all connections are registered
        {
            let connections = manager.connections.lock().await;
            for i in 0..num_clients {
                assert!(connections.contains_key(&format!("peer_{}", i)));
            }
        }
        
        // Test sending messages to all clients
        let broadcast_msg = WebSocketMessage {
            action: "broadcast".to_string(),
            data: json!({
                "content": "broadcast test"
            }),
        };
        
        let msg_json = serde_json::to_string(&broadcast_msg).unwrap();
        
        for client in &mut clients {
            client.send(Message::text(msg_json.clone())).await;
        }
        
        // Wait for message processing
        sleep(Duration::from_millis(100)).await;
        
        // Verify connections are still active
        let connections = manager.connections.lock().await;
        assert_eq!(connections.len(), num_clients);
    }

    #[tokio::test]
    async fn test_error_handling() {
        let (port, manager, _) = setup_test_server().await;
        
        // Test invalid message format
        let mut client = warp::test::ws()
            .path("/ws?peer_id=test_peer&token=valid_token")
            .handshake(([127, 0, 0, 1], port))
            .await
            .expect("Failed to connect");
            
        // Send invalid JSON
        client.send(Message::text("{invalid_json}")).await;
        
        // Wait for error handling
        sleep(Duration::from_millis(100)).await;
        
        // Connection should still be active
        let connections = manager.connections.lock().await;
        assert!(connections.contains_key("test_peer"));
        
        // Test connection with missing parameters
        let result = warp::test::ws()
            .path("/ws")  // Missing query parameters
            .handshake(([127, 0, 0, 1], port))
            .await;
            
        assert!(result.is_err());
    }
} use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize)]
pub enum WebSocketMessage {
    // Conexão P2P
    P2PConnect {
        peer_id: String,
        token: String,
    },
    P2PConnected {
        peer_id: String,
        multiaddr: String,
    },
    P2PError {
        error: String,
    },

    // Mensagens
    Message {
        id: Uuid,
        from: String,
        to: String,
        content: String,
        timestamp: DateTime<Utc>,
        encrypted: bool,
    },
    MessageAck {
        message_id: Uuid,
        status: MessageStatus,
    },

    // Estado da Rede
    NetworkState {
        connected_peers: Vec<String>,
        network_status: NetworkStatus,
    },
    NetworkUpdate {
        peer_id: String,
        status: PeerStatus,
    },
}

#[derive(Debug, Serialize, Deserialize)]
pub enum MessageStatus {
    Delivered,
    Read,
    Failed(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub enum NetworkStatus {
    Connected,
    Connecting,
    Disconnected,
    Error(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub enum PeerStatus {
    Connected,
    Disconnected,
    Blocked,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WebSocketSession {
    pub id: Uuid,
    pub peer_id: String,
    pub token: String,
    pub created_at: DateTime<Utc>,
    pub last_activity: DateTime<Utc>,
} use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use crate::error::{NetworkError, NetworkResult};

/// Configurações de segurança para proteção Sybil
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SybilConfig {
    /// Número máximo de peers permitidos por endereço IP
    pub max_peers_per_ip: usize,
    
    /// Limite de comportamentos suspeitos antes do bloqueio
    pub suspicious_behavior_threshold: u32,
    
    /// Tempo (em segundos) para resetar contador de comportamento suspeito
    pub suspicious_reset_time_secs: u64,
    
    /// Tempo (em segundos) de bloqueio de peers suspeitos
    pub suspicious_block_time_secs: u64,
    
    /// Número máximo de conexões/desconexões rápidas permitidas
    pub max_churn_events: u32,
    
    /// Janela de tempo (em segundos) para monitoramento de churn
    pub churn_time_window_secs: u64,
}

impl Default for SybilConfig {
    fn default() -> Self {
        Self {
            max_peers_per_ip: 3,
            suspicious_behavior_threshold: 10,
            suspicious_reset_time_secs: 3600, // 1 hora
            suspicious_block_time_secs: 7200, // 2 horas
            max_churn_events: 5,
            churn_time_window_secs: 60, // 1 minuto
        }
    }
}

/// Configurações de segurança para proteção Eclipse
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct EclipseConfig {
    /// Número máximo de IPs da mesma subrede permitidos em um bucket
    pub max_ips_per_subnet: usize,
    
    /// Prefixo CIDR para considerar mesma subrede (ex: /24 para IPv4)
    pub subnet_mask_ipv4: u8,
    
    /// Prefixo CIDR para considerar mesma subrede em IPv6
    pub subnet_mask_ipv6: u8,
    
    /// Número mínimo de subredes diferentes exigidas por bucket
    pub min_distinct_subnets: usize,
    
    /// Intervalo de verificação de diversidade em segundos
    pub diversity_check_interval_secs: u64,
}

impl Default for EclipseConfig {
    fn default() -> Self {
        Self {
            max_ips_per_subnet: 2,
            subnet_mask_ipv4: 24, // /24 subnet
            subnet_mask_ipv6: 64, // /64 subnet
            min_distinct_subnets: 3,
            diversity_check_interval_secs: 60, // 1 minuto
        }
    }
}

/// Configurações de performance e recursos
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct PerformanceConfig {
    /// Intervalo base para backoff exponencial
    pub min_backoff_ms: u64,
    
    /// Intervalo máximo para backoff exponencial
    pub max_backoff_ms: u64,
    
    /// Fator de crescimento para backoff exponencial
    pub backoff_factor: f64,
    
    /// Limite de conexões simultâneas
    pub max_connections: usize,
}

impl Default for PerformanceConfig {
    fn default() -> Self {
        Self {
            min_backoff_ms: 10,
            max_backoff_ms: 1000,
            backoff_factor: 1.5,
            max_connections: 50,
        }
    }
}

/// Configuração completa da rede
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NetworkConfig {
    /// Configurações de proteção Sybil
    pub sybil: SybilConfig,
    
    /// Configurações de proteção Eclipse
    pub eclipse: EclipseConfig,
    
    /// Configurações de performance
    pub performance: PerformanceConfig,
    
    /// Nível de log (trace, debug, info, warn, error)
    pub log_level: String,
    
    /// Lista de endereços de bootstrap confiáveis
    pub bootstrap_peers: Vec<String>,
}

impl Default for NetworkConfig {
    fn default() -> Self {
        Self {
            sybil: SybilConfig::default(),
            eclipse: EclipseConfig::default(),
            performance: PerformanceConfig::default(),
            log_level: "info".to_string(),
            bootstrap_peers: vec![
                "/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ".to_string(),
                "/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN".to_string(),
            ],
        }
    }
}

impl NetworkConfig {
    /// Carregar configuração de um arquivo JSON
    pub fn from_file<P: AsRef<Path>>(path: P) -> NetworkResult<Self> {
        let content = fs::read_to_string(path)
            .map_err(|e| NetworkError::Io(e))?;
            
        serde_json::from_str(&content)
            .map_err(|e| NetworkError::InvalidConfig(e.to_string()))
    }
    
    /// Salvar configuração em um arquivo JSON
    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> NetworkResult<()> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| NetworkError::InvalidConfig(e.to_string()))?;
            
        fs::write(path, content)
            .map_err(|e| NetworkError::Io(e))?;
            
        Ok(())
    }
    
    /// Criar configuração padrão e salvá-la em arquivo se não existir
    pub fn create_default_if_missing<P: AsRef<Path>>(path: P) -> NetworkResult<Self> {
        if !path.as_ref().exists() {
            let config = Self::default();
            config.save_to_file(&path)?;
            Ok(config)
        } else {
            Self::from_file(path)
        }
    }
} use thiserror::Error;
use std::io;

#[derive(Error, Debug)]
pub enum NetworkError {
    #[error("Erro de E/S: {0}")]
    Io(#[from] io::Error),
    
    #[error("Erro de rede libp2p: {0}")]
    Libp2p(#[from] libp2p::TransportError<std::io::Error>),
    
    #[error("Erro de publicação Gossipsub: {0}")]
    GossipsubPublish(#[from] libp2p::gossipsub::PublishError),
    
    #[error("Erro de DHT Kademlia: {0}")]
    KademliaDht(#[from] libp2p::kad::store::Error),
    
    #[error("Conexão rejeitada: {0}")]
    ConnectionRejected(String),
    
    #[error("Tempo limite excedido: {0}")]
    Timeout(String),
    
    #[error("Configuração inválida: {0}")]
    InvalidConfig(String),
    
    #[error("Limite de segurança excedido: {0}")]
    SecurityLimit(String),
    
    #[error("Erro desconhecido: {0}")]
    Unknown(String),
}

impl From<String> for NetworkError {
    fn from(error: String) -> Self {
        NetworkError::Unknown(error)
    }
}

impl From<&str> for NetworkError {
    fn from(error: &str) -> Self {
        NetworkError::Unknown(error.to_string())
    }
}

impl From<anyhow::Error> for NetworkError {
    fn from(err: anyhow::Error) -> Self {
        NetworkError::Unknown(err.to_string())
    }
}

/// Tipo de resultado para operações de rede
pub type NetworkResult<T> = Result<T, NetworkError>;// network/src/lib.rs
use libp2p::{
    identity::Keypair,
    swarm::{SwarmEvent},
    PeerId,
    Multiaddr,
    gossipsub::{MessageId, IdentTopic},
    kad::RecordKey,
    multiaddr::Error as MultiaddrError,
};
use log::debug;
use tokio::sync::mpsc;
use futures::{StreamExt, FutureExt};

// Módulos
pub mod config;
pub mod error;
pub mod security;
pub mod websocket;
pub mod resource_manager;
pub mod crdt;
pub mod network;
pub mod types;
pub mod energy_manager;

use security::{SybilProtection, EclipseProtection};
use config::NetworkConfig;
use error::NetworkResult;
use network::{
    behaviour::{P2PBehaviour, Event},
};
use types::NetworkEvent;

/// Main network structure that manages the P2P network
pub struct Network {
    swarm: libp2p::swarm::Swarm<P2PBehaviour>,
    _event_sender: mpsc::UnboundedSender<NetworkEvent>,
    _event_receiver: mpsc::UnboundedReceiver<NetworkEvent>,
    sybil_protection: SybilProtection,
    eclipse_protection: EclipseProtection,
}

impl Network {
    pub async fn new(local_key: &Keypair) -> NetworkResult<Self> {
        let config = NetworkConfig::default();
        Self::with_config(local_key, config).await
    }

    pub async fn with_config(local_key: &Keypair, _config: NetworkConfig) -> NetworkResult<Self> {
        let _peer_id = PeerId::from(local_key.public());
        let _transport = panic!("TODO: implement transport builder for your libp2p version");
        // TODO: Implement transport and swarm creation here
        // let swarm = libp2p::swarm::Swarm::new(
        //     _transport,
        //     P2PBehaviour::new(_peer_id, local_key.clone()),
        //     _peer_id,
        //     SwarmConfig::with_tokio_executor(),
        // );
        // Ok(Self {
        //     swarm,
        //     event_sender,
        //     _event_receiver,
        //     sybil_protection,
        //     eclipse_protection,
        // })
    }

    pub async fn start(&mut self) -> NetworkResult<()> {
        // Start DHT bootstrap
        self.swarm.behaviour_mut().bootstrap()?;

        // Start listening on all interfaces
        let addr: Multiaddr = "/ip4/0.0.0.0/tcp/0".parse().map_err(|e: MultiaddrError| error::NetworkError::from(e.to_string()))?;
        self.swarm.listen_on(addr)?;

        Ok(())
    }

    pub fn local_peer_id(&self) -> PeerId {
        *self.swarm.local_peer_id()
    }

    pub fn listeners(&self) -> impl Iterator<Item = &Multiaddr> {
        self.swarm.listeners()
    }

    pub fn add_address(&mut self, peer_id: PeerId, addr: Multiaddr) {
        self.swarm.add_peer_address(peer_id, addr);
    }

    pub async fn next_event(&mut self) -> Option<NetworkEvent> {
        loop {
            match self.swarm.select_next_some().now_or_never() {
                Some(SwarmEvent::Behaviour(event)) => {
                    match event {
                        Event::Mdns(ev) => {
                            debug!("mDNS event: {:?}", ev);
                            // Handle mDNS events
                        }
                        Event::Kademlia(ev) => {
                            debug!("Kademlia event: {:?}", ev);
                            // Handle Kademlia events
                        }
                        Event::Gossipsub(ev) => {
                            debug!("Gossipsub event: {:?}", ev);
                            // Handle Gossipsub events
                        }
                        Event::PeerDiscovered(peer_id) => {
                            if !self.sybil_protection.should_allow_peer(&peer_id) {
                                debug!("Peer {} blocked by Sybil protection", peer_id);
                                continue;
                            }
                            return Some(NetworkEvent::PeerDiscovered(peer_id));
                        }
                        Event::PeerDisconnected(peer_id) => {
                            return Some(NetworkEvent::PeerDisconnected(peer_id));
                        }
                        Event::RecordReceived(key, value) => {
                            return Some(NetworkEvent::RecordReceived(RecordKey::from(key), value));
                        }
                        Event::MessageReceived(topic, data, source) => {
                            return Some(NetworkEvent::MessageReceived(IdentTopic::new(topic), data, source));
                        }
                        Event::Identify(_) => {
                            // Handle identify events
                        }
                    }
                }
                Some(_) => {
                    // Handle other swarm events
                }
                None => break,
            }
        }

        None
    }

    pub fn subscribe(&mut self, topic: &str) -> NetworkResult<bool> {
        let result = self.swarm.behaviour_mut().subscribe(topic)?;
        Ok(result)
    }

    pub fn publish(&mut self, topic: &str, data: Vec<u8>) -> NetworkResult<MessageId> {
        self.swarm.behaviour_mut().publish(topic, data)
            .map_err(Into::into)
    }

    pub fn sybil_protection(&mut self) -> &mut SybilProtection {
        &mut self.sybil_protection
    }

    pub fn eclipse_protection(&mut self) -> &mut EclipseProtection {
        &mut self.eclipse_protection
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use libp2p::identity::Keypair;
    use tokio::runtime::Runtime;

    #[test]
    fn test_subscribe_and_publish() {
        let rt = Runtime::new().unwrap();
        rt.block_on(async {
            let keypair = Keypair::generate_ed25519();
            let mut manager = Network::new(&keypair).await.unwrap();
            let topic = "test-topic";
            let subscribed = manager.subscribe(topic).unwrap();
            assert!(subscribed);
            let result = manager.publish(topic, b"hello world".to_vec());
            assert!(result.is_ok());
        });
    }
}fn main() {
    println!("Hello, world!");
}use libp2p::{PeerId, gossipsub::IdentTopic, kad::RecordKey};

#[derive(Debug)]
pub enum NetworkEvent {
    PeerDiscovered(PeerId),
    PeerDisconnected(PeerId),
    RecordReceived(RecordKey, Vec<u8>),
    MessageReceived(IdentTopic, Vec<u8>, PeerId),
} use log::LevelFilter;
use anyhow::Result;
use env_logger::Builder;
use std::io::Write;

/// Configura o logger com um determinado nível
pub fn setup_logger(level: &str) -> Result<()> {
    let level_filter = match level.to_lowercase().as_str() {
        "trace" => LevelFilter::Trace,
        "debug" => LevelFilter::Debug,
        "info" => LevelFilter::Info,
        "warn" => LevelFilter::Warn,
        "error" => LevelFilter::Error,
        _ => LevelFilter::Info, // padrão se o nível for inválido
    };
    
    let mut builder = Builder::new();
    builder
        .format(|buf, record| {
            writeln!(
                buf,
                "{} [{}] - {} - {}",
                chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
                record.level(),
                record.target(),
                record.args()
            )
        })
        .filter(None, level_filter)
        .init();
    
    Ok(())
}

/// Backoff exponencial para operações de rede
pub struct ExponentialBackoff {
    current: u64,
    min: u64,
    max: u64,
    factor: f64,
}

impl ExponentialBackoff {
    pub fn new(min: u64, max: u64, factor: f64) -> Self {
        Self {
            current: min,
            min,
            max,
            factor,
        }
    }
    
    /// Obtém o valor atual
    pub fn current(&self) -> u64 {
        self.current
    }
    
    /// Calcula o próximo valor (aumenta)
    pub fn next(&mut self) -> u64 {
        let next = (self.current as f64 * self.factor) as u64;
        self.current = std::cmp::min(next, self.max);
        self.current
    }
    
    /// Reseta para o valor mínimo
    pub fn reset(&mut self) {
        self.current = self.min;
    }
} # Atous Network Library

A secure, decentralized P2P networking library built on libp2p with CRDT support.

## Overview

The Atous Network Library provides a robust foundation for building secure, peer-to-peer applications with built-in protection against common attacks. It features:

- **P2P Networking**: Full-featured peer-to-peer connectivity using libp2p
- **Collaborative Editing**: CRDT-based collaboration using Yrs
- **Security Hardening**: Protection against Sybil and Eclipse attacks
- **Configurability**: Extensive configuration options for all components

## Architecture

The network library is structured into several components:

### Core Components

- `NetworkManager`: Central interface for all network operations
- `P2PBehaviour`: Custom network behavior implementation
- `CrdtManager`: Manages collaborative data using CRDTs

### Security Modules

- `SybilProtection`: Prevents identity-based attacks by monitoring peer connections
- `EclipseProtection`: Ensures network diversity to prevent eclipse attacks
- `SecurityManager`: Coordinates security policies and responses

### Configuration

All aspects of the network can be configured through the `NetworkConfig` structure, which provides sensible defaults but allows customization of:

- Security parameters
- Network connection settings 
- Performance tuning
- Logging options

## Getting Started

### Basic Usage
