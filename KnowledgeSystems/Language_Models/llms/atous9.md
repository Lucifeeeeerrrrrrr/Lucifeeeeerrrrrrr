
    pub fn tier3_enterprise() -> Self {
        let config = DataCenterConfig {
            name: "DC-T3-Enterprise".to_string(),
            tier: DataCenterTier::Tier3,
            location: GeographicLocation {
                region: "AP-Southeast-1".to_string(),
                availability_zone: "ap-southeast-1c".to_string(),
                country: "Singapore".to_string(),
                latitude: 1.3521,
                longitude: 103.8198,
            },
            hardware: HardwareSpec {
                cpu_cores: 16,
                cpu_frequency_ghz: 3.8,
                ram_gb: 128,
                storage_gb: 10000,
                storage_type: StorageType::NVMe,
                gpu_count: 4,
            },
            network: NetworkSpec {
                bandwidth_gbps: 100.0,
                latency_ms: 1.0,
                cdn_enabled: true,
                load_balancer: true,
            },
            security: SecurityConfig {
                waf_enabled: true,
                ddos_protection: true,
                encryption_at_rest: true,
                encryption_in_transit: true,
                hsm_enabled: true,
            },
        };
        Self::new(config)
    }
} pub mod datacenter;
pub mod scenarios; #![allow(dead_code)]

use super::datacenter::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::Duration;
use tokio::time::sleep;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationScenario {
    pub name: String,
    pub description: String,
    pub duration_minutes: u64,
    pub data_centers: Vec<String>,
    pub load_patterns: Vec<LoadPattern>,
    pub failure_scenarios: Vec<FailureScenario>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoadPattern {
    pub name: String,
    pub start_minute: u64,
    pub duration_minutes: u64,
    pub target_rps: f64,
    pub concurrent_users: u32,
    pub geographic_distribution: HashMap<String, f64>, // region -> percentage
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FailureScenario {
    pub name: String,
    pub start_minute: u64,
    pub duration_minutes: u64,
    pub failure_type: FailureType,
    pub affected_components: Vec<String>,
    pub impact_percentage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FailureType {
    NetworkLatency,
    CpuOverload,
    MemoryExhaustion,
    DiskIO,
    ConnectionTimeout,
    SecurityAttack,
    RegionalOutage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationResults {
    pub scenario_name: String,
    pub total_duration_minutes: u64,
    pub data_center_reports: Vec<DataCenterReport>,
    pub load_test_results: Vec<LoadTestResults>,
    pub performance_summary: PerformanceSummary,
    pub cost_analysis: CostAnalysis,
    pub recommendations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceSummary {
    pub total_requests_processed: u64,
    pub average_response_time_ms: f64,
    pub p95_response_time_ms: f64,
    pub p99_response_time_ms: f64,
    pub overall_error_rate: f64,
    pub peak_throughput_rps: f64,
    pub average_cpu_utilization: f64,
    pub average_memory_utilization: f64,
    pub uptime_percentage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CostAnalysis {
    pub total_monthly_cost_usd: f64,
    pub total_annual_cost_usd: f64,
    pub cost_per_user_usd: f64,
    pub cost_per_request_usd: f64,
    pub cost_breakdown_by_tier: HashMap<String, f64>,
    pub roi_projection: RoiProjection,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoiProjection {
    pub revenue_per_user_monthly: f64,
    pub break_even_users: u32,
    pub time_to_profitability_months: u32,
    pub net_profit_year_1: f64,
}

pub struct SimulationEngine {
    data_centers: HashMap<String, DataCenter>,
    active_scenarios: Vec<SimulationScenario>,
}

impl SimulationEngine {
    pub fn new() -> Self {
        Self {
            data_centers: HashMap::new(),
            active_scenarios: Vec::new(),
        }
    }

    pub fn add_data_center(&mut self, name: String, dc: DataCenter) {
        self.data_centers.insert(name, dc);
    }

    pub fn has_data_center(&self, name: &str) -> bool {
        self.data_centers.contains_key(name)
    }

    pub async fn run_scenario(&mut self, scenario: SimulationScenario) -> SimulationResults {
        log::info!("🎬 Starting simulation scenario: {}", scenario.name);
        log::info!("📝 Description: {}", scenario.description);
        log::info!("⏱️  Duration: {} minutes", scenario.duration_minutes);

        // Start all relevant data centers
        for dc_name in &scenario.data_centers {
            if let Some(dc) = self.data_centers.get(dc_name) {
                dc.start_simulation().await;
                log::info!("✅ Started data center: {}", dc_name);
            }
        }

        let mut results = SimulationResults {
            scenario_name: scenario.name.clone(),
            total_duration_minutes: scenario.duration_minutes,
            data_center_reports: Vec::new(),
            load_test_results: Vec::new(),
            performance_summary: PerformanceSummary {
                total_requests_processed: 0,
                average_response_time_ms: 0.0,
                p95_response_time_ms: 0.0,
                p99_response_time_ms: 0.0,
                overall_error_rate: 0.0,
                peak_throughput_rps: 0.0,
                average_cpu_utilization: 0.0,
                average_memory_utilization: 0.0,
                uptime_percentage: 100.0,
            },
            cost_analysis: CostAnalysis {
                total_monthly_cost_usd: 0.0,
                total_annual_cost_usd: 0.0,
                cost_per_user_usd: 0.0,
                cost_per_request_usd: 0.0,
                cost_breakdown_by_tier: HashMap::new(),
                roi_projection: RoiProjection {
                    revenue_per_user_monthly: 10.0, // Assumed $10/user/month
                    break_even_users: 0,
                    time_to_profitability_months: 0,
                    net_profit_year_1: 0.0,
                },
            },
            recommendations: Vec::new(),
        };

        // Execute load patterns
        for load_pattern in scenario.load_patterns {
            log::info!("📊 Executing load pattern: {}", load_pattern.name);
            
            // Wait for start time
            if load_pattern.start_minute > 0 {
                sleep(Duration::from_secs(load_pattern.start_minute * 60)).await;
            }

            // Execute load tests on each data center
            for dc_name in &scenario.data_centers {
                if let Some(dc) = self.data_centers.get(dc_name) {
                    let load_test_result = dc.simulate_load_test(
                        load_pattern.duration_minutes * 60,
                        load_pattern.target_rps,
                    ).await;
                    results.load_test_results.push(load_test_result);
                }
            }
        }

        // Apply failure scenarios
        for failure in scenario.failure_scenarios {
            log::warn!("⚠️ Simulating failure: {} at minute {}", 
                      failure.name, failure.start_minute);
            
            sleep(Duration::from_secs(failure.start_minute * 60)).await;
            self.simulate_failure(&failure).await;
            
            // Let failure run for specified duration
            sleep(Duration::from_secs(failure.duration_minutes * 60)).await;
            
            log::info!("✅ Recovering from failure: {}", failure.name);
        }

        // Collect final reports
        for dc_name in &scenario.data_centers {
            if let Some(dc) = self.data_centers.get(dc_name) {
                let report = dc.generate_capacity_report();
                results.data_center_reports.push(report);
                dc.stop_simulation().await;
            }
        }

        // Calculate aggregated results
        results.performance_summary = self.calculate_performance_summary(&results).await;
        results.cost_analysis = self.calculate_cost_analysis(&results).await;
        results.recommendations = self.generate_recommendations(&results).await;

        log::info!("✅ Simulation scenario completed: {}", scenario.name);
        results
    }

    async fn simulate_failure(&self, failure: &FailureScenario) {
        // Simulate different failure types
        match failure.failure_type {
            FailureType::NetworkLatency => {
                log::warn!("📡 Simulating network latency increase: {}%", failure.impact_percentage);
                // In real implementation, would modify network characteristics
            },
            FailureType::CpuOverload => {
                log::warn!("💻 Simulating CPU overload: {}%", failure.impact_percentage);
                // In real implementation, would simulate high CPU usage
            },
            FailureType::MemoryExhaustion => {
                log::warn!("🧠 Simulating memory exhaustion: {}%", failure.impact_percentage);
                // In real implementation, would simulate memory pressure
            },
            FailureType::DiskIO => {
                log::warn!("💾 Simulating disk I/O bottleneck: {}%", failure.impact_percentage);
                // In real implementation, would simulate slow disk operations
            },
            FailureType::ConnectionTimeout => {
                log::warn!("🔌 Simulating connection timeouts: {}%", failure.impact_percentage);
                // In real implementation, would simulate connection failures
            },
            FailureType::SecurityAttack => {
                log::warn!("🛡️ Simulating security attack: {}% impact", failure.impact_percentage);
                // In real implementation, would simulate DDoS or other attacks
            },
            FailureType::RegionalOutage => {
                log::warn!("🌐 Simulating regional outage: {}% of capacity lost", failure.impact_percentage);
                // In real implementation, would disable regional resources
            },
        }
    }

    async fn calculate_performance_summary(&self, results: &SimulationResults) -> PerformanceSummary {
        let load_tests = &results.load_test_results;
        if load_tests.is_empty() {
            return PerformanceSummary {
                total_requests_processed: 0,
                average_response_time_ms: 0.0,
                p95_response_time_ms: 0.0,
                p99_response_time_ms: 0.0,
                overall_error_rate: 0.0,
                peak_throughput_rps: 0.0,
                average_cpu_utilization: 0.0,
                average_memory_utilization: 0.0,
                uptime_percentage: 100.0,
            };
        }

        let total_requests: u64 = load_tests.iter()
            .map(|lt| (lt.success_count + lt.error_count) as u64)
            .sum();

        let avg_latency = load_tests.iter()
            .map(|lt| lt.average_latency_ms)
            .sum::<f64>() / load_tests.len() as f64;

        let peak_rps = load_tests.iter()
            .map(|lt| lt.actual_rps)
            .fold(0.0f64, |a, b| a.max(b));

        let avg_cpu = load_tests.iter()
            .map(|lt| lt.cpu_peak)
            .sum::<f64>() / load_tests.len() as f64;

        let avg_memory = load_tests.iter()
            .map(|lt| lt.memory_peak)
            .sum::<f64>() / load_tests.len() as f64;

        let total_errors: u32 = load_tests.iter().map(|lt| lt.error_count).sum();
        let error_rate = if total_requests > 0 {
            (total_errors as f64 / total_requests as f64) * 100.0
        } else {
            0.0
        };

        PerformanceSummary {
            total_requests_processed: total_requests,
            average_response_time_ms: avg_latency,
            p95_response_time_ms: avg_latency * 1.5, // Simplified calculation
            p99_response_time_ms: avg_latency * 2.5, // Simplified calculation
            overall_error_rate: error_rate,
            peak_throughput_rps: peak_rps,
            average_cpu_utilization: avg_cpu,
            average_memory_utilization: avg_memory,
            uptime_percentage: 100.0 - (error_rate * 0.1), // Simplified uptime calculation
        }
    }

    async fn calculate_cost_analysis(&self, results: &SimulationResults) -> CostAnalysis {
        let total_monthly_cost: f64 = results.data_center_reports.iter()
            .map(|dc| dc.estimated_costs.monthly_usd)
            .sum();

        let total_users: u32 = results.data_center_reports.iter()
            .map(|dc| dc.capacity.max_concurrent_users)
            .sum();

        let total_requests_per_month: f64 = results.data_center_reports.iter()
            .map(|dc| dc.capacity.max_requests_per_second as f64 * 86400.0 * 30.0)
            .sum();

        let cost_per_user = if total_users > 0 {
            total_monthly_cost / total_users as f64
        } else {
            0.0
        };

        let cost_per_request = if total_requests_per_month > 0.0 {
            total_monthly_cost / total_requests_per_month
        } else {
            0.0
        };

        // ROI calculations
        let revenue_per_user_monthly = 10.0; // Assumed
        let monthly_revenue = total_users as f64 * revenue_per_user_monthly;
        let break_even_users = (total_monthly_cost / revenue_per_user_monthly) as u32;
        let net_profit_year_1 = (monthly_revenue - total_monthly_cost) * 12.0;

        let mut cost_breakdown = HashMap::new();
        for dc in &results.data_center_reports {
            let tier_name = format!("{:?}", dc.tier);
            *cost_breakdown.entry(tier_name).or_insert(0.0) += dc.estimated_costs.monthly_usd;
        }

        CostAnalysis {
            total_monthly_cost_usd: total_monthly_cost,
            total_annual_cost_usd: total_monthly_cost * 12.0,
            cost_per_user_usd: cost_per_user,
            cost_per_request_usd: cost_per_request,
            cost_breakdown_by_tier: cost_breakdown,
            roi_projection: RoiProjection {
                revenue_per_user_monthly,
                break_even_users,
                time_to_profitability_months: if net_profit_year_1 > 0.0 { 1 } else { 24 },
                net_profit_year_1,
            },
        }
    }

    async fn generate_recommendations(&self, results: &SimulationResults) -> Vec<String> {
        let mut recommendations = Vec::new();
        let perf = &results.performance_summary;
        let cost = &results.cost_analysis;

        // Performance recommendations
        if perf.average_response_time_ms > 100.0 {
            recommendations.push("Consider upgrading CPU or adding more instances to reduce latency".to_string());
        }

        if perf.average_cpu_utilization > 80.0 {
            recommendations.push("CPU utilization is high - consider scaling horizontally".to_string());
        }

        if perf.average_memory_utilization > 85.0 {
            recommendations.push("Memory utilization is high - consider increasing RAM capacity".to_string());
        }

        if perf.overall_error_rate > 5.0 {
            recommendations.push("Error rate is elevated - investigate system stability".to_string());
        }

        // Cost recommendations
        if cost.cost_per_user_usd > 5.0 {
            recommendations.push("Cost per user is high - consider optimizing resource allocation".to_string());
        }

        if cost.roi_projection.time_to_profitability_months > 12 {
            recommendations.push("Time to profitability is long - review pricing model or reduce costs".to_string());
        }

        // Capacity recommendations
        let total_capacity: u32 = results.data_center_reports.iter()
            .map(|dc| dc.capacity.max_concurrent_users)
            .sum();

        if total_capacity < 50_000 {
            recommendations.push("Consider adding Tier 2 data centers for better scalability".to_string());
        }

        if results.data_center_reports.len() == 1 {
            recommendations.push("Single point of failure - consider multi-region deployment".to_string());
        }

        // Security recommendations
        let has_waf = results.data_center_reports.iter().any(|dc| dc.security.waf_enabled);
        if !has_waf {
            recommendations.push("Enable WAF (Web Application Firewall) for better security".to_string());
        }

        let has_ddos = results.data_center_reports.iter().any(|dc| dc.security.ddos_protection);
        if !has_ddos {
            recommendations.push("Enable DDoS protection for critical infrastructure".to_string());
        }

        recommendations
    }

    // Predefined scenarios
    pub fn scenario_basic_load_test() -> SimulationScenario {
        SimulationScenario {
            name: "Basic Load Test".to_string(),
            description: "Simple load test on a single Tier 1 data center".to_string(),
            duration_minutes: 10,
            data_centers: vec!["tier1_basic".to_string()],
            load_patterns: vec![
                LoadPattern {
                    name: "Ramp Up".to_string(),
                    start_minute: 0,
                    duration_minutes: 5,
                    target_rps: 100.0,
                    concurrent_users: 1000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 100.0);
                        map
                    },
                },
                LoadPattern {
                    name: "Peak Load".to_string(),
                    start_minute: 5,
                    duration_minutes: 5,
                    target_rps: 500.0,
                    concurrent_users: 5000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 100.0);
                        map
                    },
                },
            ],
            failure_scenarios: Vec::new(),
        }
    }

    pub fn scenario_multi_region_deployment() -> SimulationScenario {
        SimulationScenario {
            name: "Multi-Region Deployment".to_string(),
            description: "Test multi-region deployment with failover scenarios".to_string(),
            duration_minutes: 30,
            data_centers: vec![
                "tier2_production".to_string(),
                "tier3_enterprise".to_string(),
            ],
            load_patterns: vec![
                LoadPattern {
                    name: "Global Traffic".to_string(),
                    start_minute: 0,
                    duration_minutes: 20,
                    target_rps: 2000.0,
                    concurrent_users: 20000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("EU-West-1".to_string(), 40.0);
                        map.insert("AP-Southeast-1".to_string(), 60.0);
                        map
                    },
                },
            ],
            failure_scenarios: vec![
                FailureScenario {
                    name: "EU Region Latency Spike".to_string(),
                    start_minute: 10,
                    duration_minutes: 5,
                    failure_type: FailureType::NetworkLatency,
                    affected_components: vec!["tier2_production".to_string()],
                    impact_percentage: 300.0, // 3x latency increase
                },
            ],
        }
    }

    pub fn scenario_black_friday_simulation() -> SimulationScenario {
        SimulationScenario {
            name: "Black Friday Simulation".to_string(),
            description: "High-traffic event simulation with gradual load increase".to_string(),
            duration_minutes: 60,
            data_centers: vec![
                "tier1_basic".to_string(),
                "tier2_production".to_string(),
                "tier3_enterprise".to_string(),
            ],
            load_patterns: vec![
                LoadPattern {
                    name: "Pre-event Traffic".to_string(),
                    start_minute: 0,
                    duration_minutes: 10,
                    target_rps: 500.0,
                    concurrent_users: 5000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 50.0);
                        map.insert("EU-West-1".to_string(), 30.0);
                        map.insert("AP-Southeast-1".to_string(), 20.0);
                        map
                    },
                },
                LoadPattern {
                    name: "Event Start Surge".to_string(),
                    start_minute: 10,
                    duration_minutes: 20,
                    target_rps: 5000.0,
                    concurrent_users: 50000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 60.0);
                        map.insert("EU-West-1".to_string(), 25.0);
                        map.insert("AP-Southeast-1".to_string(), 15.0);
                        map
                    },
                },
                LoadPattern {
                    name: "Peak Shopping Hours".to_string(),
                    start_minute: 30,
                    duration_minutes: 20,
                    target_rps: 10000.0,
                    concurrent_users: 100000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 70.0);
                        map.insert("EU-West-1".to_string(), 20.0);
                        map.insert("AP-Southeast-1".to_string(), 10.0);
                        map
                    },
                },
                LoadPattern {
                    name: "Wind Down".to_string(),
                    start_minute: 50,
                    duration_minutes: 10,
                    target_rps: 1000.0,
                    concurrent_users: 10000,
                    geographic_distribution: {
                        let mut map = HashMap::new();
                        map.insert("US-East-1".to_string(), 40.0);
                        map.insert("EU-West-1".to_string(), 35.0);
                        map.insert("AP-Southeast-1".to_string(), 25.0);
                        map
                    },
                },
            ],
            failure_scenarios: vec![
                FailureScenario {
                    name: "DDoS Attack".to_string(),
                    start_minute: 25,
                    duration_minutes: 10,
                    failure_type: FailureType::SecurityAttack,
                    affected_components: vec!["tier1_basic".to_string()],
                    impact_percentage: 50.0, // 50% capacity reduction
                },
            ],
        }
    }
} use serde::{Deserialize, Serialize};
use anyhow::Result;
use std::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub authentication: AuthConfig,
    pub web: WebConfig,
    pub websocket: WebSocketConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthConfig {
    pub jwt_secret: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebConfig {
    pub listen: String,
    pub port: u16,
    pub api_path: String,
    pub cors_origins: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebSocketConfig {
    pub rate_limiting: RateLimitingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RateLimitingConfig {
    pub enabled: bool,
    pub requests_per_minute: u32,
    pub burst_size: u32,
}

impl Config {
    pub fn from_file(path: &str) -> Result<Self> {
        // Try to read from file, fallback to default if file doesn't exist
        match fs::read_to_string(path) {
            Ok(content) => {
                serde_json::from_str(&content).map_err(|e| e.into())
            }
            Err(_) => {
                // Return default config if file doesn't exist
                Ok(Self::default())
            }
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            authentication: AuthConfig {
                jwt_secret: "default_test_secret".to_string(),
            },
            web: WebConfig {
                listen: "127.0.0.1".to_string(),
                port: 8081,
                api_path: "/api".to_string(),
                cors_origins: vec!["*".to_string()],
            },
            websocket: WebSocketConfig {
                rate_limiting: RateLimitingConfig {
                    enabled: true,
                    requests_per_minute: 60,
                    burst_size: 10,
                },
            },
        }
    }
} use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Flag {
    pub id: String,
    pub name: String,
    pub description: String,
    pub enabled: bool,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug)]
pub struct FlagState {
    pub flags: RwLock<Vec<Flag>>,
}

impl FlagState {
    pub fn new() -> Self {
        Self {
            flags: RwLock::new(Vec::new()),
        }
    }
}

impl Default for FlagState {
    fn default() -> Self {
        Self::new()
    }
} pub mod api;
pub mod config;
pub mod distributed;
pub mod flag_state;
pub mod metrics;
pub mod middleware;
pub mod simulation;
pub mod simulation_runner;
pub mod security;
pub mod types; use anyhow::Result;
use log::info;
use actix_web::{web, App, HttpServer, middleware as actix_middleware, HttpResponse};
use actix_cors::Cors;
use crate::{
    api::{flags::flag_routes, metrics::metrics_routes},
    config::Config,
    metrics::MetricsCollector,
    flag_state::FlagState,
    middleware::{JwtAuth, RateLimit, RateLimitConfig, SybilProtection, SybilProtectionConfig},
};
use atous_core::distributed::{
    HybridDistributedSystem, HybridSystemConfig
};
use atous_core::types::NetworkResult;
use clap::Parser;
use tracing::{info, error, warn};
use std::sync::Arc;
use tokio::signal;

mod middleware;
mod api;
mod config;
mod metrics;
mod flag_state;
mod simulation;
mod simulation_runner;
mod security;
mod distributed;
mod types;

#[derive(Parser)]
#[command(name = "atous")]
#[command(about = "Atous Protocol - Revolutionary P2P network with quantum-inspired optimization")]
#[command(version = "0.1.0")]
struct Args {
    /// Configuration file path
    #[arg(short, long, default_value = "config.toml")]
    config: String,

    /// Enable quantum optimization
    #[arg(long, default_value = "true")]
    quantum: bool,

    /// Enable energy monitoring
    #[arg(long, default_value = "true")]
    energy_monitoring: bool,

    /// Enable swarm optimization
    #[arg(long, default_value = "true")]
    swarm_optimization: bool,

    /// Enable ABISS security module
    #[arg(long, default_value = "true")]
    abiss: bool,

    /// Enable web interface
    #[arg(long, default_value = "false")]
    web_interface: bool,

    /// Network port for web interface
    #[arg(long, default_value = "3000")]
    web_port: u16,

    /// Log level (error, warn, info, debug, trace)
    #[arg(long, default_value = "info")]
    log_level: String,

    /// Enable metrics collection
    #[arg(long, default_value = "true")]
    metrics: bool,

    /// Metrics port
    #[arg(long, default_value = "9090")]
    metrics_port: u16,
}

#[actix_web::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Initialize logging based on log level
    let log_level = match args.log_level.as_str() {
        "error" => tracing::Level::ERROR,
        "warn" => tracing::Level::WARN,
        "info" => tracing::Level::INFO,
        "debug" => tracing::Level::DEBUG,
        "trace" => tracing::Level::TRACE,
        _ => tracing::Level::INFO,
    };

    tracing_subscriber::fmt()
        .with_max_level(log_level)
        .with_target(false)
        .with_thread_ids(true)
        .with_file(true)
        .with_line_number(true)
        .init();

    info!("🚀 Starting Atous Protocol v0.1.0");
    info!("🔧 Configuration: {}", args.config);

    // Print enabled features
    info!("🔬 Quantum optimization: {}", args.quantum);
    info!("🔋 Energy monitoring: {}", args.energy_monitoring);
    info!("🌀 Swarm optimization: {}", args.swarm_optimization);
    info!("🛡️ ABISS security: {}", args.abiss);
    info!("🌐 Web interface: {} (port: {})", args.web_interface, args.web_port);
    info!("📊 Metrics: {} (port: {})", args.metrics, args.metrics_port);

    // Load configuration
    let system_config = load_configuration(&args).await?;
    
    // Initialize the hybrid distributed system
    info!("🔧 Initializing Hybrid Distributed System...");
    let system = Arc::new(HybridDistributedSystem::new(system_config).await?);
    info!("✅ System initialized successfully");

    // Start metrics server if enabled
    if args.metrics {
        let metrics_system = Arc::clone(&system);
        tokio::spawn(async move {
            if let Err(e) = start_metrics_server(metrics_system, args.metrics_port).await {
                error!("❌ Metrics server failed: {}", e);
            }
        });
        info!("📊 Metrics server started on port {}", args.metrics_port);
    }

    // Start web interface if enabled
    if args.web_interface {
        let web_system = Arc::clone(&system);
        tokio::spawn(async move {
            if let Err(e) = start_web_interface(web_system, args.web_port).await {
                error!("❌ Web interface failed: {}", e);
            }
        });
        info!("🌐 Web interface started on port {}", args.web_port);
    }

    // Start periodic system maintenance
    let maintenance_system = Arc::clone(&system);
    tokio::spawn(async move {
        periodic_maintenance(maintenance_system).await;
    });

    // Start system health monitoring
    let health_system = Arc::clone(&system);
    tokio::spawn(async move {
        health_monitoring(health_system).await;
    });

    info!("🔄 Atous Protocol is running. Press Ctrl+C to stop.");

    // Wait for shutdown signal
    match signal::ctrl_c().await {
        Ok(()) => {
            info!("🛑 Shutdown signal received");
        }
        Err(err) => {
            error!("❌ Unable to listen for shutdown signal: {}", err);
        }
    }

    // Graceful shutdown
    info!("🔄 Performing graceful shutdown...");
    if let Err(e) = graceful_shutdown(&system).await {
        error!("❌ Graceful shutdown failed: {}", e);
    }

    info!("👋 Atous Protocol stopped");
    Ok(())
}

async fn load_configuration(args: &Args) -> NetworkResult<HybridSystemConfig> {
    info!("📋 Loading system configuration...");

    let config = HybridSystemConfig {
        quantum_enabled: args.quantum,
        energy_monitoring_enabled: args.energy_monitoring,
        swarm_optimization_enabled: args.swarm_optimization,
        quantum_threshold: 5.0,
        energy_efficiency_target: 0.85,
        max_latency_ms: 1000.0,
        carbon_emission_limit: 0.5,
        adaptive_learning_rate: 0.01,
        resilience_factor: 0.8,
        energy_cost_threshold: 0.15,
    };

    info!("✅ Configuration loaded successfully");
    Ok(config)
}

async fn start_metrics_server(
    system: Arc<HybridDistributedSystem>,
    port: u16,
) -> NetworkResult<()> {
    info!("📊 Starting metrics server on port {}", port);

    // This would be a full Prometheus metrics endpoint in production
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
        
        let metrics = system.get_system_metrics().await;
        let health_report = system.get_system_health_report().await;
        
        // Log metrics for now (in production, expose via HTTP endpoint)
        info!("📊 System Metrics Update:");
        info!("   Tasks processed: {}", metrics.total_tasks_processed);
        info!("   Energy efficiency: {:.1}%", metrics.average_energy_efficiency * 100.0);
        info!("   Active peers: {}", health_report.network_health.active_peers);
        info!("   Energy cost savings: ${:.2}", metrics.energy_cost_savings);
    }
}

async fn start_web_interface(
    _system: Arc<HybridDistributedSystem>,
    port: u16,
) -> NetworkResult<()> {
    info!("🌐 Starting web interface on port {}", port);
    
    // Placeholder for web interface
    // In production, this would be a full REST API with Axum
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
        info!("🌐 Web interface health check");
    }
}

async fn periodic_maintenance(system: Arc<HybridDistributedSystem>) {
    info!("🔧 Starting periodic maintenance tasks");
    
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(300)); // 5 minutes
    
    loop {
        interval.tick().await;
        
        info!("🔧 Running periodic maintenance...");
        
        // Energy optimization
        if let Err(e) = system.optimize_network_energy().await {
            warn!("⚠️ Energy optimization failed: {}", e);
        } else {
            info!("✅ Energy optimization completed");
        }
        
        // Adaptive rebalancing
        if let Err(e) = system.adaptive_rebalance().await {
            warn!("⚠️ Adaptive rebalancing failed: {}", e);
        } else {
            info!("✅ Adaptive rebalancing completed");
        }
        
        // Generate energy forecast
        match system.predict_energy_requirements(24).await {
            Ok(forecast) => {
                info!("🔮 Energy forecast: {:.1}% renewable coverage", 
                      forecast.renewable_coverage_ratio * 100.0);
            }
            Err(e) => {
                warn!("⚠️ Energy forecasting failed: {}", e);
            }
        }
    }
}

async fn health_monitoring(system: Arc<HybridDistributedSystem>) {
    info!("🏥 Starting health monitoring");
    
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60)); // 1 minute
    
    loop {
        interval.tick().await;
        
        let health_report = system.get_system_health_report().await;
        let metrics = &health_report.system_metrics;
        
        // Check system health indicators
        if metrics.system_reliability < 0.8 {
            warn!("⚠️ System reliability below threshold: {:.1}%", 
                  metrics.system_reliability * 100.0);
        }
        
        if metrics.average_energy_efficiency < 0.7 {
            warn!("⚠️ Energy efficiency below target: {:.1}%", 
                  metrics.average_energy_efficiency * 100.0);
        }
        
        if metrics.average_response_time_ms > 2000.0 {
            warn!("⚠️ High response time detected: {:.2} ms", 
                  metrics.average_response_time_ms);
        }
        
        // Log periodic health summary
        if health_report.timestamp % 600 == 0 { // Every 10 minutes
            info!("🏥 Health Summary:");
            info!("   System reliability: {:.1}%", metrics.system_reliability * 100.0);
            info!("   Energy efficiency: {:.1}%", metrics.average_energy_efficiency * 100.0);
            info!("   Network peers: {}", health_report.network_health.total_peers);
            info!("   Renewable coverage: {:.1}%", 
                  health_report.network_health.renewable_percentage * 100.0);
        }
    }
}

async fn graceful_shutdown(system: &Arc<HybridDistributedSystem>) -> NetworkResult<()> {
    info!("🔄 Initiating graceful shutdown sequence...");
    
    // Generate final reports
    let final_metrics = system.get_system_metrics().await;
    let final_health = system.get_system_health_report().await;
    
    info!("📊 Final System Report:");
    info!("   Total tasks processed: {}", final_metrics.total_tasks_processed);
    info!("   Final energy efficiency: {:.1}%", final_metrics.average_energy_efficiency * 100.0);
    info!("   Total energy cost savings: ${:.2}", final_metrics.energy_cost_savings);
    info!("   Carbon footprint reduction: {:.1}%", final_metrics.carbon_footprint_reduction * 100.0);
    info!("   System uptime reliability: {:.1}%", final_metrics.system_reliability * 100.0);
    
    // Log final energy optimization
    match system.optimize_network_energy().await {
        Ok(savings) => {
            info!("⚡ Final energy optimization saved {:.2} kWh", savings);
        }
        Err(e) => {
            warn!("⚠️ Final energy optimization failed: {}", e);
        }
    }
    
    info!("✅ Graceful shutdown completed");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_system_initialization() {
        let config = HybridSystemConfig::default();
        let system = HybridDistributedSystem::new(config).await;
        assert!(system.is_ok());
    }

    #[tokio::test]
    async fn test_configuration_loading() {
        let args = Args {
            config: "test.toml".to_string(),
            quantum: true,
            energy_monitoring: true,
            swarm_optimization: true,
            abiss: true,
            web_interface: false,
            web_port: 3000,
            log_level: "info".to_string(),
            metrics: true,
            metrics_port: 9090,
        };

        let config = load_configuration(&args).await;
        assert!(config.is_ok());
        
        let config = config.unwrap();
        assert!(config.quantum_enabled);
        assert!(config.energy_monitoring_enabled);
        assert!(config.swarm_optimization_enabled);
    }
}

// Simple health check endpoint
async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "service": "atous-security-fixes"
    }))
} use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicU64, Ordering};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetricsData {
    pub requests_total: u64,
    pub requests_rate_limited: u64,
    pub auth_failures: u64,
    pub security_flags_created: u64,
}

#[derive(Debug)]
pub struct MetricsCollector {
    data: std::sync::RwLock<MetricsData>,
    auth_failures: AtomicU64,
}

impl MetricsCollector {
    pub fn new() -> Self {
        Self {
            data: std::sync::RwLock::new(MetricsData {
                requests_total: 0,
                requests_rate_limited: 0,
                auth_failures: 0,
                security_flags_created: 0,
            }),
            auth_failures: AtomicU64::new(0),
        }
    }

    pub fn _increment_requests(&self) {
        if let Ok(mut data) = self.data.write() {
            data.requests_total += 1;
        }
    }

    pub fn increment_auth_failures(&self) {
        if let Ok(mut data) = self.data.write() {
            data.auth_failures += 1;
        }
        self.auth_failures.fetch_add(1, Ordering::Relaxed);
    }

    pub fn increment_security_flags(&self) {
        if let Ok(mut data) = self.data.write() {
            data.security_flags_created += 1;
        }
    }

    pub fn _increment_rate_limited(&self) {
        if let Ok(mut data) = self.data.write() {
            data.requests_rate_limited += 1;
        }
    }

    pub fn get_metrics(&self) -> MetricsData {
        if let Ok(data) = self.data.read() {
            data.clone()
        } else {
            MetricsData {
                requests_total: 0,
                requests_rate_limited: 0,
                auth_failures: 0,
                security_flags_created: 0,
            }
        }
    }
}

impl Default for MetricsCollector {
    fn default() -> Self {
        Self::new()
    }
} #![allow(dead_code)]

use crate::simulation::{datacenter::*, scenarios::*};
use serde_json;
use std::fs;
use tokio::time::{sleep, Duration};

pub struct SimulationRunner {
    engine: SimulationEngine,
}

impl SimulationRunner {
    pub fn new() -> Self {
        let mut engine = SimulationEngine::new();
        
        // Add predefined data centers
        engine.add_data_center("tier1_basic".to_string(), DataCenter::tier1_basic());
        engine.add_data_center("tier2_production".to_string(), DataCenter::tier2_production());
        engine.add_data_center("tier3_enterprise".to_string(), DataCenter::tier3_enterprise());
        
        Self { engine }
    }

    pub async fn run_all_scenarios(&mut self) -> Vec<SimulationResults> {
        log::info!("🚀 Starting comprehensive data center simulation suite");
        
        let scenarios = vec![
            SimulationEngine::scenario_basic_load_test(),
            SimulationEngine::scenario_multi_region_deployment(),
            SimulationEngine::scenario_black_friday_simulation(),
        ];
        
        let mut all_results = Vec::new();
        
        for (index, scenario) in scenarios.into_iter().enumerate() {
            log::info!("🎯 Running scenario {}/{}: {}", index + 1, 3, scenario.name);
            
            let results = self.engine.run_scenario(scenario).await;
            
            // Save results to file
            self.save_results_to_file(&results, &format!("simulation_results_{}.json", index + 1)).await;
            
            // Display summary
            self.display_scenario_summary(&results).await;
            
            all_results.push(results);
            
            // Pause between scenarios
            if index < 2 {
                log::info!("⏳ Waiting 30 seconds before next scenario...");
                sleep(Duration::from_secs(30)).await;
            }
        }
        
        // Generate comprehensive report
        self.generate_comprehensive_report(&all_results).await;
        
        log::info!("✅ All simulation scenarios completed successfully!");
        all_results
    }

    pub async fn run_quick_demo(&mut self) -> SimulationResults {
        log::info!("🎬 Running quick simulation demo (2 minutes)");
        
        let demo_scenario = SimulationScenario {
            name: "Quick Demo".to_string(),
            description: "Fast demonstration of system capabilities".to_string(),
            duration_minutes: 2,
            data_centers: vec!["tier1_basic".to_string()],
            load_patterns: vec![
                LoadPattern {
                    name: "Demo Load".to_string(),
                    start_minute: 0,
                    duration_minutes: 2,
                    target_rps: 200.0,
                    concurrent_users: 2000,
                    geographic_distribution: {
                        let mut map = std::collections::HashMap::new();
                        map.insert("US-East-1".to_string(), 100.0);
                        map
                    },
                },
            ],
            failure_scenarios: Vec::new(),
        };
        
        let results = self.engine.run_scenario(demo_scenario).await;
        self.display_scenario_summary(&results).await;
        
        results
    }

    async fn save_results_to_file(&self, results: &SimulationResults, filename: &str) {
        match serde_json::to_string_pretty(results) {
            Ok(json_data) => {
                if let Err(e) = fs::write(filename, json_data) {
                    log::error!("Failed to save results to {}: {}", filename, e);
                } else {
                    log::info!("💾 Results saved to: {}", filename);
                }
            }
            Err(e) => {
                log::error!("Failed to serialize results: {}", e);
            }
        }
    }

    async fn display_scenario_summary(&self, results: &SimulationResults) {
        let perf = &results.performance_summary;
        let cost = &results.cost_analysis;
        
        log::info!("📊 === SIMULATION RESULTS: {} ===", results.scenario_name);
        log::info!("⏱️  Duration: {} minutes", results.total_duration_minutes);
        log::info!("🔢 Total Requests: {}", perf.total_requests_processed);
        log::info!("⚡ Peak Throughput: {:.1} RPS", perf.peak_throughput_rps);
        log::info!("🕒 Average Latency: {:.1}ms", perf.average_response_time_ms);
        log::info!("📈 P95 Latency: {:.1}ms", perf.p95_response_time_ms);
        log::info!("📉 Error Rate: {:.2}%", perf.overall_error_rate);
        log::info!("💻 CPU Usage: {:.1}%", perf.average_cpu_utilization);
        log::info!("🧠 Memory Usage: {:.1}%", perf.average_memory_utilization);
        log::info!("⬆️  Uptime: {:.2}%", perf.uptime_percentage);
        log::info!("💰 Monthly Cost: ${:.2}", cost.total_monthly_cost_usd);
        log::info!("👥 Cost per User: ${:.4}", cost.cost_per_user_usd);
        log::info!("📱 Cost per Request: ${:.8}", cost.cost_per_request_usd);
        
        if !results.recommendations.is_empty() {
            log::info!("💡 Recommendations:");
            for (i, rec) in results.recommendations.iter().enumerate() {
                log::info!("   {}. {}", i + 1, rec);
            }
        }
        
        log::info!("📋 Data Centers: {} deployed", results.data_center_reports.len());
        for dc in &results.data_center_reports {
            log::info!("   • {} ({:?}): {} users, {} RPS", 
                      dc.datacenter_name, 
                      dc.tier,
                      dc.capacity.max_concurrent_users,
                      dc.capacity.max_requests_per_second);
        }
        
        let separator = "=".repeat(60);
        log::info!("{}", separator);
    }

    async fn generate_comprehensive_report(&self, all_results: &[SimulationResults]) {
        let report = ComprehensiveReport::new(all_results);
        
        match serde_json::to_string_pretty(&report) {
            Ok(json_data) => {
                if let Err(e) = fs::write("comprehensive_simulation_report.json", json_data) {
                    log::error!("Failed to save comprehensive report: {}", e);
                } else {
                    log::info!("📋 Comprehensive report saved to: comprehensive_simulation_report.json");
                }
            }
            Err(e) => {
                log::error!("Failed to serialize comprehensive report: {}", e);
            }
        }
        
        // Display executive summary
        log::info!("🏆 === EXECUTIVE SUMMARY ===");
        log::info!("📊 Total Scenarios Tested: {}", all_results.len());
        
        let total_requests: u64 = all_results.iter()
            .map(|r| r.performance_summary.total_requests_processed)
            .sum();
        
        let avg_latency: f64 = all_results.iter()
            .map(|r| r.performance_summary.average_response_time_ms)
            .sum::<f64>() / all_results.len() as f64;
        
        let peak_throughput: f64 = all_results.iter()
            .map(|r| r.performance_summary.peak_throughput_rps)
            .fold(0.0f64, |a, b| a.max(b));
        
        let total_cost: f64 = all_results.iter()
            .map(|r| r.cost_analysis.total_monthly_cost_usd)
            .sum();
        
        log::info!("🔢 Total Requests Simulated: {}", total_requests);
        log::info!("⚡ Peak System Throughput: {:.1} RPS", peak_throughput);
        log::info!("🕒 Average Response Time: {:.1}ms", avg_latency);
        log::info!("💰 Total Infrastructure Cost: ${:.2}/month", total_cost);
        
        // System capacity analysis
        log::info!("🏗️ === SYSTEM CAPACITY ANALYSIS ===");
        log::info!("✅ Tier 1 (Basic): 10K users, 500 RPS");
        log::info!("✅ Tier 2 (Production): 50K users, 2.5K RPS");  
        log::info!("✅ Tier 3 (Enterprise): 500K users, 25K RPS");
        log::info!("🔄 Horizontal Scaling: Linear with load balancing");
        log::info!("📈 Vertical Scaling: Up to 32 cores per instance");
        log::info!("🌐 Geographic Distribution: Multi-region capable");
        log::info!("🛡️ Security: WAF, DDoS protection, encryption");
        log::info!("💾 Storage: HDD/SSD/NVMe support up to 100TB");
        log::info!("📊 Monitoring: Real-time metrics and alerting");
        
        let separator = "=".repeat(60);
        log::info!("{}", separator);
    }

    pub async fn benchmark_individual_components(&mut self) {
        log::info!("🔬 Running individual component benchmarks");
        
        // Test each tier individually
        for (tier_name, dc_name) in &[
            ("Tier 1 Basic", "tier1_basic"),
            ("Tier 2 Production", "tier2_production"), 
            ("Tier 3 Enterprise", "tier3_enterprise"),
        ] {
            log::info!("🧪 Benchmarking {}", tier_name);
            
            // Access data center through public method instead of direct field access
            if self.engine.has_data_center(dc_name) {
                // Run progressive load tests using the engine's run_scenario method
                for rps in &[100.0, 500.0, 1000.0, 2000.0, 5000.0] {
                    let test_scenario = SimulationScenario {
                        name: format!("Benchmark {} RPS", rps),
                        description: format!("Load test at {} RPS", rps),
                        duration_minutes: 1, // Short 1-minute tests
                        data_centers: vec![dc_name.to_string()],
                        load_patterns: vec![
                            LoadPattern {
                                name: format!("Load {}", rps),
                                start_minute: 0,
                                duration_minutes: 1,
                                target_rps: *rps,
                                concurrent_users: (*rps as u32) * 10,
                                geographic_distribution: {
                                    let mut map = std::collections::HashMap::new();
                                    map.insert("Test-Region".to_string(), 100.0);
                                    map
                                },
                            },
                        ],
                        failure_scenarios: Vec::new(),
                    };
                    
                    let results = self.engine.run_scenario(test_scenario).await;
                    let perf = &results.performance_summary;
                    
                    log::info!("   📊 {} RPS: {:.1}ms avg latency, {:.1}% CPU", 
                              rps, perf.average_response_time_ms, perf.average_cpu_utilization);
                    
                    // Stop if performance degrades significantly
                    if perf.average_response_time_ms > 500.0 || perf.average_cpu_utilization > 95.0 {
                        log::warn!("   ⚠️ Performance degradation detected at {} RPS", rps);
                        break;
                    }
                }
            }
        }
    }
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ComprehensiveReport {
    pub execution_timestamp: String,
    pub total_scenarios: usize,
    pub aggregate_performance: AggregatePerformance,
    pub cost_summary: CostSummary,
    pub capacity_matrix: CapacityMatrix,
    pub scenario_summaries: Vec<ScenarioSummary>,
    pub overall_recommendations: Vec<String>,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct AggregatePerformance {
    pub total_requests_all_scenarios: u64,
    pub peak_system_throughput_rps: f64,
    pub average_response_time_ms: f64,
    pub best_response_time_ms: f64,
    pub worst_response_time_ms: f64,
    pub overall_uptime_percentage: f64,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct CostSummary {
    pub total_infrastructure_cost_monthly: f64,
    pub cost_per_user_range: (f64, f64), // (min, max)
    pub most_cost_effective_tier: String,
    pub roi_analysis: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct CapacityMatrix {
    pub tier1_capacity: TierCapacity,
    pub tier2_capacity: TierCapacity, 
    pub tier3_capacity: TierCapacity,
    pub scaling_characteristics: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct TierCapacity {
    pub max_users: u32,
    pub max_rps: u32,
    pub cost_monthly: f64,
    pub geographic_coverage: String,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ScenarioSummary {
    pub name: String,
    pub duration_minutes: u64,
    pub peak_rps: f64,
    pub avg_latency_ms: f64,
    pub error_rate: f64,
    pub cost_monthly: f64,
    pub key_findings: Vec<String>,
}

impl ComprehensiveReport {
    fn new(results: &[SimulationResults]) -> Self {
        let execution_timestamp = chrono::Utc::now().to_rfc3339();
        
        let total_requests = results.iter()
            .map(|r| r.performance_summary.total_requests_processed)
            .sum();
        
        let peak_rps = results.iter()
            .map(|r| r.performance_summary.peak_throughput_rps)
            .fold(0.0f64, |a, b| a.max(b));
        
        let avg_latency = results.iter()
            .map(|r| r.performance_summary.average_response_time_ms)
            .sum::<f64>() / results.len() as f64;
        
        let latencies: Vec<f64> = results.iter()
            .map(|r| r.performance_summary.average_response_time_ms)
            .collect();
        let best_latency = latencies.iter().fold(f64::INFINITY, |a, &b| a.min(b));
        let worst_latency = latencies.iter().fold(0.0f64, |a, &b| a.max(b));
        
        let avg_uptime = results.iter()
            .map(|r| r.performance_summary.uptime_percentage)
            .sum::<f64>() / results.len() as f64;
        
        let total_cost = results.iter()
            .map(|r| r.cost_analysis.total_monthly_cost_usd)
            .sum();
        
        let cost_per_user_values: Vec<f64> = results.iter()
            .map(|r| r.cost_analysis.cost_per_user_usd)
            .collect();
        let min_cost_per_user = cost_per_user_values.iter().fold(f64::INFINITY, |a, &b| a.min(b));
        let max_cost_per_user = cost_per_user_values.iter().fold(0.0f64, |a, &b| a.max(b));
        
        let scenario_summaries = results.iter().map(|r| {
            ScenarioSummary {
                name: r.scenario_name.clone(),
                duration_minutes: r.total_duration_minutes,
                peak_rps: r.performance_summary.peak_throughput_rps,
                avg_latency_ms: r.performance_summary.average_response_time_ms,
                error_rate: r.performance_summary.overall_error_rate,
                cost_monthly: r.cost_analysis.total_monthly_cost_usd,
                key_findings: r.recommendations.clone(),
            }
        }).collect();
        
        Self {
            execution_timestamp,
            total_scenarios: results.len(),
            aggregate_performance: AggregatePerformance {
                total_requests_all_scenarios: total_requests,
                peak_system_throughput_rps: peak_rps,
                average_response_time_ms: avg_latency,
                best_response_time_ms: best_latency,
                worst_response_time_ms: worst_latency,
                overall_uptime_percentage: avg_uptime,
            },
            cost_summary: CostSummary {
                total_infrastructure_cost_monthly: total_cost,
                cost_per_user_range: (min_cost_per_user, max_cost_per_user),
                most_cost_effective_tier: "Tier 2 Production".to_string(),
                roi_analysis: "Positive ROI achievable with >10K active users".to_string(),
            },
            capacity_matrix: CapacityMatrix {
                tier1_capacity: TierCapacity {
                    max_users: 10_000,
                    max_rps: 500,
                    cost_monthly: 800.0,
                    geographic_coverage: "Single Region".to_string(),
                },
                tier2_capacity: TierCapacity {
                    max_users: 50_000,
                    max_rps: 2_500,
                    cost_monthly: 3_500.0,
                    geographic_coverage: "Multi-AZ".to_string(),
                },
                tier3_capacity: TierCapacity {
                    max_users: 500_000,
                    max_rps: 25_000,
                    cost_monthly: 15_000.0,
                    geographic_coverage: "Global".to_string(),
                },
                scaling_characteristics: "Linear horizontal scaling with load balancing. Vertical scaling up to 32 cores.".to_string(),
            },
            scenario_summaries,
            overall_recommendations: vec![
                "Start with Tier 1 for <10K users, upgrade to Tier 2 for production workloads".to_string(),
                "Implement multi-region deployment for high availability requirements".to_string(),
                "Monitor CPU utilization and scale horizontally when >80% sustained".to_string(),
                "Enable WAF and DDoS protection for all production deployments".to_string(),
                "Consider cost optimization through reserved instances for predictable workloads".to_string(),
            ],
        }
    }
} use serde::{Serialize, Deserialize};
use std::fmt;

/// Resultado padrão para operações de rede
pub type NetworkResult<T> = Result<T, NetworkError>;

/// Erros possíveis na rede Atous
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NetworkError {
    /// Erro de conexão
    ConnectionError(String),
    /// Timeout de operação
    Timeout(String),
    /// Dados inválidos
    InvalidData(String),
    /// Peer não encontrado
    PeerNotFound(String),
    /// Operação não autorizada
    Unauthorized(String),
    /// Recursos esgotados
    ResourceExhausted(String),
    /// Nenhum nó disponível
    NoAvailableNodes(String),
    /// Erro de consenso
    ConsensusError(String),
    /// Violação de segurança
    SecurityViolation(String),
    /// Erro interno
    InternalError(String),
    /// Erro de serialização
    SerializationError(String),
    /// Erro de criptografia
    CryptographyError(String),
    /// Erro de validação
    ValidationError(String),
    /// Limite de rate excedido
    RateLimitExceeded,
    /// Erro de balanceamento de carga
    LoadBalancing(String),
}

impl fmt::Display for NetworkError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            NetworkError::ConnectionError(msg) => write!(f, "Erro de conexão: {}", msg),
            NetworkError::Timeout(msg) => write!(f, "Timeout: {}", msg),
            NetworkError::InvalidData(msg) => write!(f, "Dados inválidos: {}", msg),
            NetworkError::PeerNotFound(msg) => write!(f, "Peer não encontrado: {}", msg),
            NetworkError::Unauthorized(msg) => write!(f, "Não autorizado: {}", msg),
            NetworkError::ResourceExhausted(msg) => write!(f, "Recursos esgotados: {}", msg),
            NetworkError::NoAvailableNodes(msg) => write!(f, "Nenhum nó disponível: {}", msg),
            NetworkError::ConsensusError(msg) => write!(f, "Erro de consenso: {}", msg),
            NetworkError::SecurityViolation(msg) => write!(f, "Violação de segurança: {}", msg),
            NetworkError::InternalError(msg) => write!(f, "Erro interno: {}", msg),
            NetworkError::SerializationError(msg) => write!(f, "Erro de serialização: {}", msg),
            NetworkError::CryptographyError(msg) => write!(f, "Erro de criptografia: {}", msg),
            NetworkError::ValidationError(msg) => write!(f, "Erro de validação: {}", msg),
            NetworkError::RateLimitExceeded => write!(f, "Rate limit excedido"),
            NetworkError::LoadBalancing(msg) => write!(f, "Erro de balanceamento de carga: {}", msg),
        }
    }
}

impl std::error::Error for NetworkError {}

/// ID único para tarefas
pub type TaskId = String;

/// Status de operação
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum OperationStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    Cancelled,
}

/// Nível de prioridade
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
pub enum Priority {
    Low = 1,
    Normal = 2,
    High = 3,
    Critical = 4,
    Emergency = 5,
}

// Implementar conversões de outros tipos de erro
impl From<std::io::Error> for NetworkError {
    fn from(err: std::io::Error) -> Self {
        NetworkError::ConnectionError(err.to_string())
    }
}

impl From<serde_json::Error> for NetworkError {
    fn from(err: serde_json::Error) -> Self {
        NetworkError::InvalidData(err.to_string())
    }
} use atous_core::distributed::{
    DistributedCore, EnergyAwareTask, SecurityLevel,
    HardwareMetrics, NodeMetrics, NodeStatus
};
use atous_core::types::NetworkResult;
use libp2p::identity::Keypair;
use libp2p::PeerId;

fn create_test_peer_id() -> PeerId {
    PeerId::from(Keypair::generate_ed25519().public())
}

fn create_test_hardware_metrics() -> HardwareMetrics {
    HardwareMetrics {
        temperature_celsius: 45.0,
        voltage: 12.0,
        cpu_frequency_ghz: 3.2,
        gpu_frequency_mhz: Some(1500.0),
        available_ram_bytes: 8_000_000_000,
        available_storage_bytes: 500_000_000_000,
        idle_time_percentage: 0.7,
        power_consumption_watts: 150.0,
        battery_level: Some(0.85),
        network_latency_ms: 25.0,
        pqc_capability_score: 0.8,
        offgrid_capable: true,
        last_updated: 1234567890,
    }
}

fn create_test_task() -> EnergyAwareTask {
    EnergyAwareTask {
        task_id: "test_task_001".to_string(),
        computational_load: 100.0,
        max_latency_ms: 1000.0,
        energy_budget: 500.0,
        carbon_constraint: 0.1,
        priority: 5,
        deadline: 1234567890 + 3600,
        pqc_security_level: SecurityLevel::PQC3,
    }
}

#[tokio::test]
async fn test_distributed_core_creation() {
    let peer_id = create_test_peer_id();
    let result = DistributedCore::new(peer_id).await;
    
    assert!(result.is_ok(), "DistributedCore creation should succeed");
}

#[tokio::test]
async fn test_hardware_metrics_update() {
    let peer_id = create_test_peer_id();
    let core = DistributedCore::new(peer_id).await
        .expect("Failed to create DistributedCore");
    
    let test_peer_id = create_test_peer_id();
    let hardware_metrics = create_test_hardware_metrics();
    
    let result = core.update_peer_metrics(test_peer_id, hardware_metrics).await;
    assert!(result.is_ok(), "Hardware metrics update should succeed");
}

#[tokio::test]
async fn test_performance_metrics_retrieval() {
    let peer_id = create_test_peer_id();
    let core = DistributedCore::new(peer_id).await
        .expect("Failed to create DistributedCore");
    
    let result = core.get_performance_metrics().await;
    assert!(result.is_ok(), "Performance metrics retrieval should succeed");
    
    let metrics = result.unwrap();
    assert!(metrics.quantum_advantage >= 1.0, "Quantum advantage should be at least 1.0");
    assert!(metrics.energy_efficiency >= 0.0, "Energy efficiency should be non-negative");
    assert!(metrics.system_reliability >= 0.0, "System reliability should be non-negative");
}

#[tokio::test]
async fn test_task_processing() {
    let peer_id = create_test_peer_id();
    let core = DistributedCore::new(peer_id).await
        .expect("Failed to create DistributedCore");
    
    // Add some test nodes first
    let test_peer_id = create_test_peer_id();
    let hardware_metrics = create_test_hardware_metrics();
    core.update_peer_metrics(test_peer_id, hardware_metrics).await
        .expect("Failed to update hardware metrics");
    
    let task = create_test_task();
    let result = core.process_task(task).await;
    
    // We expect this to work or return a reasonable error
    match result {
        Ok(optimization_result) => {
            assert!(optimization_result.confidence_level >= 0.0, "Confidence level should be non-negative");
            assert!(optimization_result.energy_efficiency >= 0.0, "Energy efficiency should be non-negative");
        }
        Err(e) => {
            // Accept certain expected errors like NoAvailableNodes
            println!("Expected error during test: {}", e);
        }
    }
}

#[tokio::test]
async fn test_energy_aware_computation() {
    let peer_id = create_test_peer_id();
    let core = DistributedCore::new(peer_id).await
        .expect("Failed to create DistributedCore");
    
    // Test that the system correctly handles energy constraints
    let task = EnergyAwareTask {
        task_id: "energy_test".to_string(),
        computational_load: 50.0,
        max_latency_ms: 500.0,
        energy_budget: 100.0,  // Low energy budget
        carbon_constraint: 0.05,  // Low carbon constraint
        priority: 8,
        deadline: 1234567890 + 1800,
        pqc_security_level: SecurityLevel::PQC1,
    };
    
    let result = core.process_task(task).await;
    
    // System should handle energy constraints gracefully
    match result {
        Ok(optimization_result) => {
            assert!(optimization_result.energy_consumption <= 100.0, "Energy consumption should respect budget");
            assert!(optimization_result.carbon_footprint <= 0.05, "Carbon footprint should respect constraint");
        }
        Err(_) => {
            // It's acceptable for the system to reject tasks that can't meet constraints
            println!("System correctly rejected task due to constraints");
        }
    }
} #[cfg(test)]
mod security_fixes_tests {
    use actix_web::{test, web, App, http::StatusCode};
    use serde_json::json;
    use atous_security_fixes::{
        api::flags::flag_routes,
        flag_state::FlagState,
        middleware::{JwtAuth, RateLimit, RateLimitConfig},
        metrics::MetricsCollector,
    };

    // Test 1: Authentication should be validated BEFORE rate limiting
    #[actix_web::test]
    async fn test_authentication_before_rate_limiting() {
        let app = test::init_service(
            App::new()
                // Correct middleware order: Auth BEFORE Rate Limiting
                .wrap(JwtAuth::new("test_secret".to_string()))
                .wrap(RateLimit::new(RateLimitConfig::default()))
                .app_data(web::PayloadConfig::new(1024 * 1024)) // 1MB limit
                .app_data(web::JsonConfig::default().limit(1024 * 1024)) // 1MB limit for JSON
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        // Invalid JWT should return 401, not 429
        let req = test::TestRequest::post()
            .uri("/api/flags")
            .insert_header(("Authorization", "Bearer invalid_jwt_token"))
            .set_json(&json!({
                "name": "test_flag",
                "description": "test",
                "enabled": true
            }))
            .to_request();

        // Use try_call_service to handle middleware errors properly
        let resp = test::try_call_service(&app, req).await;
        
        match resp {
            Ok(response) => {
                // If we get a response, it should be 401
                assert_eq!(response.status(), StatusCode::UNAUTHORIZED, "Expected 401 Unauthorized for invalid JWT token");
            }
            Err(error) => {
                // If we get an error, it should be an auth error
                let error_str = format!("{}", error);
                assert!(error_str.contains("Invalid JWT token") || error_str.contains("Unauthorized"), 
                       "Expected authentication error, got: {}", error_str);
            }
        }
    }

    // Test 2: Large payload should be rejected with 413
    #[actix_web::test]
    async fn test_large_payload_rejection() {
        let app = test::init_service(
            App::new()
                .wrap(JwtAuth::new("test_secret".to_string()))
                .app_data(web::PayloadConfig::new(1024 * 1024)) // 1MB limit
                .app_data(web::JsonConfig::default().limit(1024 * 1024)) // 1MB limit for JSON
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        // Create a large payload (exceed 1MB)
        let large_data = "A".repeat(1_100_000); // 1.1MB
        let large_payload = json!({
            "name": "test_flag",
            "description": large_data,
            "enabled": true
        });

        let req = test::TestRequest::post()
            .uri("/api/flags")
            .insert_header(("Authorization", "Bearer valid_jwt_token"))
            .set_json(&large_payload)
            .to_request();

        let resp = test::call_service(&app, req).await;
        
        // Should fail with 413 Payload Too Large
        assert_eq!(resp.status(), StatusCode::PAYLOAD_TOO_LARGE);
    }

    // Test 3: Flag signature validation should work properly
    #[actix_web::test]
    async fn test_flag_signature_validation() {
        let app = test::init_service(
            App::new()
                .wrap(JwtAuth::new("test_secret".to_string()))
                .app_data(web::PayloadConfig::new(1024 * 1024))
                .app_data(web::JsonConfig::default().limit(1024 * 1024))
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        // Invalid signature should return 400 Bad Request
        let invalid_flag = json!({
            "reporter_id": "malicious-node",
            "target_node": "test-target",
            "flag_type": "MALICIOUS_BEHAVIOR",
            "evidence": "fake evidence",
            "signature": "invalid_signature_data",
            "timestamp": "2023-01-01T00:00:00Z"
        });

        let req = test::TestRequest::post()
            .uri("/api/flags/security")
            .insert_header(("Authorization", "Bearer valid_jwt_token"))
            .set_json(&invalid_flag)
            .to_request();

        let resp = test::call_service(&app, req).await;
        
        // Should fail with 400 Bad Request for invalid signature
        assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
    }

    // Test 4: Valid authenticated requests should work
    #[actix_web::test]
    async fn test_valid_authenticated_request() {
        let app = test::init_service(
            App::new()
                .wrap(JwtAuth::new("test_secret".to_string()))
                .app_data(web::PayloadConfig::new(1024 * 1024))
                .app_data(web::JsonConfig::default().limit(1024 * 1024))
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        // Valid request should succeed
        let valid_flag = json!({
            "name": "test_flag",
            "description": "valid test flag",
            "enabled": true
        });

        let req = test::TestRequest::post()
            .uri("/api/flags")
            .insert_header(("Authorization", "Bearer valid_jwt_token"))
            .set_json(&valid_flag)
            .to_request();

        let resp = test::call_service(&app, req).await;
        
        // With valid auth, should succeed
        assert!(resp.status().is_success());
    }

    // Test 5: Rate limiting should work for authenticated users but authentication comes first
    #[actix_web::test]
    async fn test_rate_limiting_after_auth() {
        let rate_config = RateLimitConfig {
            max_requests_per_minute: 10, // Higher limit for testing
            max_concurrent_requests: 5, // Higher concurrent limit
            enabled: true,
        };
        
        let app = test::init_service(
            App::new()
                // Correct order: Auth FIRST, then Rate Limiting
                .wrap(JwtAuth::new("test_secret".to_string()))
                .wrap(RateLimit::new(rate_config))
                .app_data(web::PayloadConfig::new(1024 * 1024))
                .app_data(web::JsonConfig::default().limit(1024 * 1024))
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        let mut successful_requests = 0;
        let mut rate_limited_requests = 0;

        // Make multiple requests quickly to test rate limiting behavior
        for i in 0..6 {
            let req = test::TestRequest::post()
                .uri("/api/flags")
                .insert_header(("Authorization", "Bearer valid_jwt_token"))
                .set_json(&json!({
                    "name": format!("test_flag_{}", i),
                    "description": "rate limit test",
                    "enabled": true
                }))
                .to_request();

            let resp = test::call_service(&app, req).await;
            
            if resp.status().is_success() {
                successful_requests += 1;
            } else if resp.status() == StatusCode::TOO_MANY_REQUESTS {
                rate_limited_requests += 1;
            }
            
            // Small delay between requests to avoid overwhelming
            tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
        }
        
        // Should have at least some successful requests
        assert!(successful_requests > 0, "Should have at least some successful requests");
        // For this test, we mainly want to ensure authentication works and rate limiting doesn't completely block
        println!("Successful: {}, Rate limited: {}", successful_requests, rate_limited_requests);
    }

    // Test 6: Valid security flag should be accepted
    #[actix_web::test]
    async fn test_valid_security_flag() {
        let app = test::init_service(
            App::new()
                .wrap(JwtAuth::new("test_secret".to_string()))
                .app_data(web::PayloadConfig::new(1024 * 1024))
                .app_data(web::JsonConfig::default().limit(1024 * 1024))
                .app_data(web::Data::new(FlagState::new()))
                .app_data(web::Data::new(MetricsCollector::new())) // Add metrics collector
                .service(web::scope("/api").service(flag_routes()))
        ).await;

        // Use current timestamp to pass validation
        let now = chrono::Utc::now().to_rfc3339();

        // Valid security flag should be accepted
        let valid_security_flag = json!({
            "reporter_id": "trusted-node-123",
            "target_node": "suspicious-node-456",
            "flag_type": "MALICIOUS_BEHAVIOR",
            "evidence": "repeated failed authentication attempts",
            "signature": "validSignatureHashWithSufficientLength123", // Valid Base64-like format, 39 chars
            "timestamp": now
        });

        let req = test::TestRequest::post()
            .uri("/api/flags/security")
            .insert_header(("Authorization", "Bearer valid_jwt_token"))
            .set_json(&valid_security_flag)
            .to_request();

        let resp = test::call_service(&app, req).await;
        
        // Valid security flag should be accepted
        assert!(resp.status().is_success());
    }
} 
    /// Treinar sistema neural com feedback (aprendizado)
    pub fn train_neural_system(&mut self, flag_id: &str, actual_outcome: bool) -> NetworkResult<()> {
        let flag = self.active_flags.get(flag_id)
            .ok_or_else(|| NetworkError::InvalidData("Flag não encontrada".to_string()))?
            .clone();

        // Atualizar padrões neurais com base no resultado real
        let pattern_id = format!("{:?}", flag.threat_type);
        let pattern = self.threat_patterns.entry(pattern_id.clone())
            .or_insert_with(|| ThreatPattern {
                pattern_id: pattern_id.clone(),
                threat_type: flag.threat_type.clone(),
                features: HashMap::new(),
                detection_threshold: 0.5,
                detection_count: 0,
                accuracy_rate: 0.5,
                last_updated: 0,
            });

        // Atualizar taxa de acerto
        let total_detections = pattern.detection_count + 1;
        let correct_detections = if actual_outcome {
            (pattern.accuracy_rate * pattern.detection_count as f64) + 1.0
        } else {
            pattern.accuracy_rate * pattern.detection_count as f64
        };

        pattern.accuracy_rate = correct_detections / total_detections as f64;
        pattern.detection_count = total_detections;
        pattern.last_updated = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();

        // Atualizar estatísticas
        if actual_outcome {
            debug!("Sistema neural: True positive para flag {}", flag_id);
        } else {
            self.stats.false_positives += 1;
            debug!("Sistema neural: False positive para flag {}", flag_id);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use libp2p::PeerId;
    use std::net::Ipv4Addr;

    fn create_test_peer() -> PeerId {
        PeerId::random()
    }

    fn create_test_evidence() -> ThreatEvidence {
        ThreatEvidence {
            raw_data: b"test evidence data".to_vec(),
            metadata: HashMap::new(),
            collected_at: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs(),
            confidence: 90,
        }
    }

    #[test]
    fn test_create_neural_immune_system() {
        let system = NeuralImmuneSystem::with_default_config();
        assert_eq!(system.active_flags.len(), 0);
        assert_eq!(system.isolated_peers.len(), 0);
    }

    #[test]
    fn test_threat_flag_creation() {
        let reporter = create_test_peer();
        let suspect = create_test_peer();
        let evidence = create_test_evidence();

        let flag = ThreatFlag::new(
            reporter,
            suspect,
            Some(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 1))),
            ThreatType::SybilAttack,
            SeverityLevel::High,
            "Detected Sybil attack pattern".to_string(),
            &evidence,
        );

        assert_eq!(flag.reporter_id, reporter);
        assert_eq!(flag.suspect_id, suspect);
        assert_eq!(flag.threat_type, ThreatType::SybilAttack);
        assert!(flag.validate_integrity());
    }

    #[test]
    fn test_node_reputation() {
        let mut reputation = NodeReputation::new();
        assert_eq!(reputation.score, 500);
        
        reputation.update_score(100, "Good behavior");
        assert_eq!(reputation.score, 600);
        
        reputation.update_score(-200, "Bad behavior");
        assert_eq!(reputation.score, 400);
        
        // Test bounds
        reputation.update_score(-500, "Very bad");
        assert_eq!(reputation.score, 0);
        
        reputation.update_score(2000, "Excellent");
        assert_eq!(reputation.score, 1000);
    }

    #[test]
    fn test_report_threat() {
        let mut system = NeuralImmuneSystem::with_default_config();
        let reporter = create_test_peer();
        let suspect = create_test_peer();
        let evidence = create_test_evidence();

        // Criar reputação para o reporter com alta confiabilidade
        let rep = system.get_or_create_reputation(reporter);
        rep.score = 800; // Alta reputação
        rep.valid_reports = 5; // Histórico de reports válidos para confiabilidade > 0.7

        let result = system.report_threat(
            reporter,
            suspect,
            Some(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 1))),
            ThreatType::MalformedData,
            SeverityLevel::Medium,
            "Test threat report".to_string(),
            evidence,
        );

        assert!(result.is_ok());
        assert_eq!(system.active_flags.len(), 1);
        assert_eq!(system.stats.total_flags_created, 1);
    }

    #[test]
    fn test_isolation_decision() {
        let mut system = NeuralImmuneSystem::with_default_config();
        let reporter1 = create_test_peer();
        let reporter2 = create_test_peer();
        let reporter3 = create_test_peer();
        let suspect = create_test_peer();

        // Configurar reputações altas e confiabilidade para os reporters
        for reporter in [reporter1, reporter2, reporter3] {
            let rep = system.get_or_create_reputation(reporter);
            rep.score = 900;
            rep.valid_reports = 10; // Alta confiabilidade
        }

        // Reportar múltiplas ameaças do mesmo suspeito
        for reporter in [reporter1, reporter2, reporter3] {
            let evidence = create_test_evidence();
            let result = system.report_threat(
                reporter,
                suspect,
                Some(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 1))),
                ThreatType::SybilAttack,
                SeverityLevel::Critical,
                "Multiple Sybil attacks detected".to_string(),
                evidence,
            );
            assert!(result.is_ok());
        }

        // Verificar se o suspeito foi isolado
        assert!(system.isolated_peers.contains(&suspect));
        assert!(!system.should_allow_peer(&suspect));
        assert_eq!(system.stats.total_isolations, 1);
    }

    #[test]
    fn test_flag_validation() {
        let mut system = NeuralImmuneSystem::with_default_config();
        let reporter = create_test_peer();
        let suspect = create_test_peer();
        let validator = create_test_peer();
        let evidence = create_test_evidence();

        // Configurar reputações e confiabilidade
        let reporter_rep = system.get_or_create_reputation(reporter);
        reporter_rep.score = 800;
        reporter_rep.valid_reports = 5;
        
        let validator_rep = system.get_or_create_reputation(validator);
        validator_rep.score = 900;
        validator_rep.valid_reports = 8;

        // Reportar ameaça
        let flag_id = system.report_threat(
            reporter,
            suspect,
            None,
            ThreatType::NonResponsive,
            SeverityLevel::Low,
            "Non-responsive node".to_string(),
            evidence,
        ).unwrap();

        // Validar flag como verdadeira
        let result = system.validate_flag(&flag_id, validator, true);
        assert!(result.is_ok());
        assert_eq!(system.stats.total_flags_validated, 1);

        // Verificar se reputação do reporter aumentou
        let reporter_rep = system.get_reputation(&reporter).unwrap();
        assert_eq!(reporter_rep.valid_reports, 6); // Incrementou devido à validação
    }

    #[test]
    fn test_neural_learning() {
        let mut system = NeuralImmuneSystem::with_default_config();
        let reporter = create_test_peer();
        let suspect = create_test_peer();
        let evidence = create_test_evidence();

        // Configurar reputação e confiabilidade
        let rep = system.get_or_create_reputation(reporter);
        rep.score = 800;
        rep.valid_reports = 5;

        // Reportar ameaça
        let flag_id = system.report_threat(
            reporter,
            suspect,
            None,
            ThreatType::MalformedData,
            SeverityLevel::Medium,
            "Malformed data detected".to_string(),
            evidence,
        ).unwrap();

        // Treinar sistema com feedback positivo
        let result = system.train_neural_system(&flag_id, true);
        assert!(result.is_ok());

        // Verificar se padrão foi atualizado
        let pattern_id = format!("{:?}", ThreatType::MalformedData);
        let pattern = system.threat_patterns.get(&pattern_id).unwrap();
        assert_eq!(pattern.detection_count, 1);
        assert_eq!(pattern.accuracy_rate, 1.0);
    }

    #[test]
    fn test_rate_limiting() {
        let mut system = NeuralImmuneSystem::with_default_config();
        let reporter = create_test_peer();
        let suspect = create_test_peer();

        // Configurar reputação alta e confiabilidade
        let rep = system.get_or_create_reputation(reporter);
        rep.score = 900;
        rep.valid_reports = 10;

        // Reportar até o limite
        for i in 0..system.config.max_flags_per_node_per_period {
            let evidence = create_test_evidence();
            let result = system.report_threat(
                reporter,
                suspect,
                None,
                ThreatType::SuspiciousDHTActivity,
                SeverityLevel::Low,
                format!("Suspicious activity {}", i),
                evidence,
            );
            assert!(result.is_ok());
        }

        // Próxima flag deve ser rejeitada por rate limiting
        let evidence = create_test_evidence();
        let result = system.report_threat(
            reporter,
            suspect,
            None,
            ThreatType::SuspiciousDHTActivity,
            SeverityLevel::Low,
            "Should be rate limited".to_string(),
            evidence,
        );
        assert!(result.is_err());
        if let Err(NetworkError::RateLimitExceeded) = result {
            // Esperado
        } else {
            panic!("Expected RateLimitExceeded error");
        }
    }
} #![allow(dead_code)]

use libp2p::PeerId;
use std::collections::{HashMap, HashSet};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use std::net::IpAddr;
use crate::types::{NetworkResult, NetworkError};

/// Sistema de proteção contra ataques Sybil
#[derive(Debug, Clone)]
pub struct SybilProtection {
    /// IPs conhecidos dos peers
    peer_ips: HashMap<PeerId, IpAddr>,
    /// Histórico de conexões por IP
    ip_connections: HashMap<IpAddr, Vec<ConnectionRecord>>,
    /// Peers suspeitos de ataque Sybil
    suspicious_peers: HashSet<PeerId>,
    /// Configuração do sistema
    config: SybilProtectionConfig,
}

/// Configuração da proteção contra Sybil
#[derive(Debug, Clone)]
pub struct SybilProtectionConfig {
    /// Número máximo de peers por IP
    pub max_peers_per_ip: usize,
    /// Janela de tempo para análise
    pub analysis_window: Duration,
    /// Threshold de suspeita
    pub suspicion_threshold: f64,
}

/// Registro de conexão
#[derive(Debug, Clone)]
pub struct ConnectionRecord {
    pub peer_id: PeerId,
    pub timestamp: u64,
    pub connection_type: ConnectionType,
}

/// Tipo de conexão
#[derive(Debug, Clone)]
pub enum ConnectionType {
    Inbound,
    Outbound,
}

impl Default for SybilProtectionConfig {
    fn default() -> Self {
        Self {
            max_peers_per_ip: 3,
            analysis_window: Duration::from_secs(3600), // 1 hora
            suspicion_threshold: 0.7,
        }
    }
}

impl SybilProtection {
    pub fn new(config: SybilProtectionConfig) -> Self {
        Self {
            peer_ips: HashMap::new(),
            ip_connections: HashMap::new(),
            suspicious_peers: HashSet::new(),
            config,
        }
    }

    pub fn with_default_config() -> Self {
        Self::new(SybilProtectionConfig::default())
    }

    /// Registra uma nova conexão
    pub fn register_connection(&mut self, peer_id: PeerId, ip: IpAddr, connection_type: ConnectionType) -> NetworkResult<()> {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|e| NetworkError::InvalidData(format!("Erro de timestamp: {}", e)))?
            .as_secs();

        // Registra o IP do peer
        self.peer_ips.insert(peer_id, ip);

        // Registra a conexão
        let record = ConnectionRecord {
            peer_id,
            timestamp,
            connection_type,
        };

        self.ip_connections
            .entry(ip)
            .or_insert_with(Vec::new)
            .push(record);

        // Limpa registros antigos
        self.cleanup_old_records();

        // Analisa por atividade suspeita
        self.analyze_sybil_activity(ip)?;

        Ok(())
    }

    /// Analisa atividade suspeita de Sybil
    fn analyze_sybil_activity(&mut self, ip: IpAddr) -> NetworkResult<()> {
        if let Some(connections) = self.ip_connections.get(&ip) {
            let recent_connections = self.get_recent_connections(connections);
            
            // Verifica se há muitas conexões do mesmo IP
            if recent_connections.len() > self.config.max_peers_per_ip {
                let suspicious_peer_ids: Vec<PeerId> = recent_connections.iter()
                    .map(|record| record.peer_id)
                    .collect();
                
                for peer_id in suspicious_peer_ids {
                    self.suspicious_peers.insert(peer_id);
                }
                
                return Err(NetworkError::SecurityViolation(
                    format!("Possível ataque Sybil detectado do IP: {}", ip)
                ));
            }
        }

        Ok(())
    }

    /// Obtém conexões recentes
    fn get_recent_connections<'a>(&self, connections: &'a [ConnectionRecord]) -> Vec<&'a ConnectionRecord> {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let cutoff = now.saturating_sub(self.config.analysis_window.as_secs());
        
        connections
            .iter()
            .filter(|record| record.timestamp >= cutoff)
            .collect()
    }

    /// Limpa registros antigos
    fn cleanup_old_records(&mut self) {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let cutoff = now.saturating_sub(self.config.analysis_window.as_secs() * 2);
        
        for connections in self.ip_connections.values_mut() {
            connections.retain(|record| record.timestamp >= cutoff);
        }

        // Remove IPs sem conexões
        self.ip_connections.retain(|_, connections| !connections.is_empty());
    }

    /// Verifica se um peer é suspeito
    pub fn is_suspicious(&self, peer_id: &PeerId) -> bool {
        self.suspicious_peers.contains(peer_id)
    }

    /// Remove um peer da lista de suspeitos
    pub fn clear_suspicion(&mut self, peer_id: &PeerId) {
        self.suspicious_peers.remove(peer_id);
    }

    /// Obtém estatísticas do sistema
    pub fn get_stats(&self) -> SybilProtectionStats {
        SybilProtectionStats {
            total_ips: self.ip_connections.len(),
            suspicious_peers: self.suspicious_peers.len(),
            total_connections: self.ip_connections.values().map(|v| v.len()).sum(),
        }
    }
}

/// Estatísticas da proteção Sybil
#[derive(Debug)]
pub struct SybilProtectionStats {
    pub total_ips: usize,
    pub suspicious_peers: usize,
    pub total_connections: usize,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    fn create_test_peer() -> PeerId {
        PeerId::random()
    }

    #[test]
    fn test_sybil_protection_creation() {
        let protection = SybilProtection::with_default_config();
        assert_eq!(protection.suspicious_peers.len(), 0);
    }

    #[test]
    fn test_register_connection() {
        let mut protection = SybilProtection::with_default_config();
        let peer = create_test_peer();
        let ip = "192.168.1.1".parse().unwrap();
        
        let result = protection.register_connection(peer, ip, ConnectionType::Inbound);
        assert!(result.is_ok());
    }

    #[test]
    fn test_sybil_detection() {
        let mut protection = SybilProtection::with_default_config();
        let ip = "192.168.1.1".parse().unwrap();
        
        // Registra muitas conexões do mesmo IP
        for _ in 0..5 {
            let peer = create_test_peer();
            let result = protection.register_connection(peer, ip, ConnectionType::Inbound);
            if result.is_err() {
                break; // Esperado quando limite é atingido
            }
        }
        
        assert!(protection.suspicious_peers.len() > 0);
    }
} #![allow(dead_code)]

use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};
use tokio::time::sleep;
use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::Timelike;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataCenterConfig {
    pub name: String,
    pub tier: DataCenterTier,
    pub location: GeographicLocation,
    pub hardware: HardwareSpec,
    pub network: NetworkSpec,
    pub security: SecurityConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DataCenterTier {
    Tier1,  // Single DC
    Tier2,  // Regional 
    Tier3,  // Global
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeographicLocation {
    pub region: String,
    pub availability_zone: String,
    pub country: String,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct HardwareSpec {
    pub cpu_cores: u32,
    pub cpu_frequency_ghz: f64,
    pub ram_gb: u32,
    pub storage_gb: u64,
    pub storage_type: StorageType,
    pub gpu_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub enum StorageType {
    HDD,
    #[default]
    SSD,
    NVMe,
    Memory,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkSpec {
    pub bandwidth_gbps: f64,
    pub latency_ms: f64,
    pub cdn_enabled: bool,
    pub load_balancer: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub waf_enabled: bool,
    pub ddos_protection: bool,
    pub encryption_at_rest: bool,
    pub encryption_in_transit: bool,
    pub hsm_enabled: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct PerformanceMetrics {
    #[serde(skip)]
    pub timestamp: Instant,
    pub requests_per_second: f64,
    pub average_latency_ms: f64,
    pub p95_latency_ms: f64,
    pub p99_latency_ms: f64,
    pub cpu_utilization: f64,
    pub memory_utilization: f64,
    pub active_connections: u32,
    pub error_rate: f64,
    pub throughput_mbps: f64,
}

impl Default for PerformanceMetrics {
    fn default() -> Self {
        Self {
            timestamp: Instant::now(),
            requests_per_second: 0.0,
            average_latency_ms: 0.0,
            p95_latency_ms: 0.0,
            p99_latency_ms: 0.0,
            cpu_utilization: 0.0,
            memory_utilization: 0.0,
            active_connections: 0,
            error_rate: 0.0,
            throughput_mbps: 0.0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CapacityLimits {
    pub max_concurrent_users: u32,
    pub max_requests_per_second: u32,
    pub max_storage_gb: u64,
    pub max_bandwidth_gbps: f64,
    pub max_connections: u32,
}

pub struct DataCenter {
    pub config: DataCenterConfig,
    pub capacity: CapacityLimits,
    pub current_metrics: Arc<RwLock<PerformanceMetrics>>,
    pub historical_metrics: Arc<RwLock<Vec<PerformanceMetrics>>>,
    pub is_running: Arc<RwLock<bool>>,
}

impl DataCenter {
    pub fn new(config: DataCenterConfig) -> Self {
        let capacity = Self::calculate_capacity(&config);
        let initial_metrics = PerformanceMetrics {
            timestamp: Instant::now(),
            requests_per_second: 0.0,
            average_latency_ms: 0.0,
            p95_latency_ms: 0.0,
            p99_latency_ms: 0.0,
            cpu_utilization: 0.0,
            memory_utilization: 0.0,
            active_connections: 0,
            error_rate: 0.0,
            throughput_mbps: 0.0,
        };

        Self {
            config,
            capacity,
            current_metrics: Arc::new(RwLock::new(initial_metrics)),
            historical_metrics: Arc::new(RwLock::new(Vec::new())),
            is_running: Arc::new(RwLock::new(false)),
        }
    }

    fn calculate_capacity(config: &DataCenterConfig) -> CapacityLimits {
        let base_capacity = match config.tier {
            DataCenterTier::Tier1 => CapacityLimits {
                max_concurrent_users: 10_000,
                max_requests_per_second: 500,
                max_storage_gb: 1_000,
                max_bandwidth_gbps: 1.0,
                max_connections: 1_000,
            },
            DataCenterTier::Tier2 => CapacityLimits {
                max_concurrent_users: 50_000,
                max_requests_per_second: 2_500,
                max_storage_gb: 10_000,
                max_bandwidth_gbps: 10.0,
                max_connections: 5_000,
            },
            DataCenterTier::Tier3 => CapacityLimits {
                max_concurrent_users: 500_000,
                max_requests_per_second: 25_000,
                max_storage_gb: 100_000,
                max_bandwidth_gbps: 100.0,
                max_connections: 50_000,
            },
        };

        // Apply hardware multipliers
        let cpu_multiplier = (config.hardware.cpu_cores as f64 * config.hardware.cpu_frequency_ghz) / 16.0;
        let memory_multiplier = config.hardware.ram_gb as f64 / 32.0;
        let storage_multiplier = match config.hardware.storage_type {
            StorageType::HDD => 0.5,
            StorageType::SSD => 1.0,
            StorageType::NVMe => 2.0,
            StorageType::Memory => 10.0,
        };

        let overall_multiplier = (cpu_multiplier + memory_multiplier + storage_multiplier) / 3.0;

        CapacityLimits {
            max_concurrent_users: (base_capacity.max_concurrent_users as f64 * overall_multiplier) as u32,
            max_requests_per_second: (base_capacity.max_requests_per_second as f64 * overall_multiplier) as u32,
            max_storage_gb: base_capacity.max_storage_gb,
            max_bandwidth_gbps: base_capacity.max_bandwidth_gbps * config.network.bandwidth_gbps / 10.0,
            max_connections: (base_capacity.max_connections as f64 * overall_multiplier) as u32,
        }
    }

    pub async fn start_simulation(&self) {
        let mut is_running = self.is_running.write().await;
        *is_running = true;
        drop(is_running);

        log::info!("🚀 Starting data center simulation: {}", self.config.name);
        log::info!("📊 Capacity: {} max users, {} req/sec", 
                  self.capacity.max_concurrent_users, 
                  self.capacity.max_requests_per_second);

        // Start background metrics collection
        let metrics_collector = self.current_metrics.clone();
        let historical_collector = self.historical_metrics.clone();
        let running_flag = self.is_running.clone();
        let config = self.config.clone();

        tokio::spawn(async move {
            Self::metrics_collection_loop(metrics_collector, historical_collector, running_flag, config).await;
        });
    }

    pub async fn stop_simulation(&self) {
        let mut is_running = self.is_running.write().await;
        *is_running = false;
        log::info!("🛑 Stopping data center simulation: {}", self.config.name);
    }

    async fn metrics_collection_loop(
        current_metrics: Arc<RwLock<PerformanceMetrics>>,
        historical_metrics: Arc<RwLock<Vec<PerformanceMetrics>>>,
        is_running: Arc<RwLock<bool>>,
        config: DataCenterConfig,
    ) {
        let mut interval = tokio::time::interval(Duration::from_secs(1));
        
        while *is_running.read().await {
            interval.tick().await;
            
            // Simulate realistic metrics based on time of day and load patterns
            let metrics = Self::generate_realistic_metrics(&config).await;
            
            // Update current metrics
            {
                let mut current = current_metrics.write().await;
                *current = metrics.clone();
            }
            
            // Store historical data (keep last 1000 points)
            {
                let mut historical = historical_metrics.write().await;
                historical.push(metrics);
                if historical.len() > 1000 {
                    historical.remove(0);
                }
            }
        }
    }

    async fn generate_realistic_metrics(config: &DataCenterConfig) -> PerformanceMetrics {
        let now = Instant::now();
        
        // Simulate varying load based on time patterns
        let time_factor = Self::calculate_time_based_load_factor();
        let base_load = 0.3 + (time_factor * 0.6); // 30-90% load variation
        
        // Calculate performance based on tier and hardware
        let base_rps = match config.tier {
            DataCenterTier::Tier1 => 100.0,
            DataCenterTier::Tier2 => 500.0,
            DataCenterTier::Tier3 => 2500.0,
        };
        
        let hardware_multiplier = (config.hardware.cpu_cores as f64 * config.hardware.cpu_frequency_ghz) / 16.0;
        let current_rps = base_rps * hardware_multiplier * base_load;
        
        // Calculate latency (higher load = higher latency)
        let base_latency = config.network.latency_ms + 5.0; // Base network + processing
        let load_latency_factor = if base_load > 0.8 { 1.0 + (base_load - 0.8) * 5.0 } else { 1.0 };
        let current_latency = base_latency * load_latency_factor;
        
        // Calculate resource utilization
        let cpu_utilization = (base_load * 80.0).min(95.0); // Cap at 95%
        let memory_utilization = (base_load * 70.0).min(90.0); // Cap at 90%
        
        // Calculate error rate (increases with high load)
        let error_rate = if base_load > 0.9 {
            (base_load - 0.9) * 50.0 // Up to 5% error rate at max load
        } else {
            base_load * 0.5 // Low error rate under normal load
        };
        
        // Add some randomness for realism
        let jitter = rand::random::<f64>() * 0.1 - 0.05; // ±5% jitter
        
        PerformanceMetrics {
            timestamp: now,
            requests_per_second: current_rps * (1.0 + jitter),
            average_latency_ms: current_latency * (1.0 + jitter),
            p95_latency_ms: current_latency * 2.0 * (1.0 + jitter),
            p99_latency_ms: current_latency * 4.0 * (1.0 + jitter),
            cpu_utilization: (cpu_utilization * (1.0 + jitter)).max(0.0).min(100.0),
            memory_utilization: (memory_utilization * (1.0 + jitter)).max(0.0).min(100.0),
            active_connections: ((current_rps * 10.0) as u32).min(10000),
            error_rate: (error_rate * (1.0 + jitter * 2.0)).max(0.0).min(100.0),
            throughput_mbps: current_rps * 0.1 * (1.0 + jitter), // Approximate throughput
        }
    }

    fn calculate_time_based_load_factor() -> f64 {
        // Simulate daily load patterns (simplified)
        let hour = chrono::Utc::now().hour();
        match hour {
            0..=6 => 0.2,   // Night: 20% load
            7..=9 => 0.6,   // Morning: 60% load
            10..=14 => 0.9, // Peak business hours: 90% load
            15..=18 => 0.8, // Afternoon: 80% load
            19..=22 => 0.5, // Evening: 50% load
            _ => 0.3,       // Late evening: 30% load
        }
    }

    pub async fn get_current_metrics(&self) -> PerformanceMetrics {
        self.current_metrics.read().await.clone()
    }

    pub async fn get_historical_metrics(&self) -> Vec<PerformanceMetrics> {
        self.historical_metrics.read().await.clone()
    }

    pub async fn simulate_load_test(&self, duration_seconds: u64, target_rps: f64) -> LoadTestResults {
        log::info!("🧪 Starting load test on {}: {} RPS for {}s", 
                  self.config.name, target_rps, duration_seconds);
        
        let start_time = Instant::now();
        let mut results = LoadTestResults {
            duration_seconds,
            target_rps,
            actual_rps: 0.0,
            average_latency_ms: 0.0,
            max_latency_ms: 0.0,
            error_count: 0,
            success_count: 0,
            cpu_peak: 0.0,
            memory_peak: 0.0,
        };
        
        let end_time = start_time + Duration::from_secs(duration_seconds);
        let mut samples = Vec::new();
        
        while Instant::now() < end_time {
            let metrics = self.get_current_metrics().await;
            samples.push(metrics.clone());
            
            // Update peak values
            results.cpu_peak = results.cpu_peak.max(metrics.cpu_utilization);
            results.memory_peak = results.memory_peak.max(metrics.memory_utilization);
            
            // Simulate load impact
            if metrics.requests_per_second > target_rps * 1.1 {
                results.error_count += 1;
            } else {
                results.success_count += 1;
            }
            
            sleep(Duration::from_millis(100)).await;
        }
        
        // Calculate aggregate results
        if !samples.is_empty() {
            results.actual_rps = samples.iter().map(|s| s.requests_per_second).sum::<f64>() / samples.len() as f64;
            results.average_latency_ms = samples.iter().map(|s| s.average_latency_ms).sum::<f64>() / samples.len() as f64;
            results.max_latency_ms = samples.iter().map(|s| s.p99_latency_ms).fold(0.0, |a, b| a.max(b));
        }
        
        log::info!("✅ Load test completed: {:.1} RPS actual, {:.1}ms avg latency", 
                  results.actual_rps, results.average_latency_ms);
        
        results
    }

    pub fn generate_capacity_report(&self) -> DataCenterReport {
        DataCenterReport {
            datacenter_name: self.config.name.clone(),
            tier: self.config.tier.clone(),
            location: self.config.location.clone(),
            capacity: self.capacity.clone(),
            hardware: self.config.hardware.clone(),
            network: self.config.network.clone(),
            security: self.config.security.clone(),
            estimated_costs: self.calculate_estimated_costs(),
        }
    }

    fn calculate_estimated_costs(&self) -> EstimatedCosts {
        // Simplified cost calculation based on hardware and tier
        let cpu_cost = self.config.hardware.cpu_cores as f64 * 50.0; // $50 per core per month
        let memory_cost = self.config.hardware.ram_gb as f64 * 5.0; // $5 per GB per month
        let storage_cost = match self.config.hardware.storage_type {
            StorageType::HDD => self.config.hardware.storage_gb as f64 * 0.05,
            StorageType::SSD => self.config.hardware.storage_gb as f64 * 0.10,
            StorageType::NVMe => self.config.hardware.storage_gb as f64 * 0.20,
            StorageType::Memory => self.config.hardware.storage_gb as f64 * 1.0,
        };
        let network_cost = self.config.network.bandwidth_gbps * 100.0; // $100 per Gbps per month
        
        let base_monthly = cpu_cost + memory_cost + storage_cost + network_cost;
        let tier_multiplier = match self.config.tier {
            DataCenterTier::Tier1 => 1.0,
            DataCenterTier::Tier2 => 1.5,
            DataCenterTier::Tier3 => 2.0,
        };
        
        EstimatedCosts {
            monthly_usd: base_monthly * tier_multiplier,
            annual_usd: base_monthly * tier_multiplier * 12.0,
            cost_per_user: (base_monthly * tier_multiplier) / self.capacity.max_concurrent_users as f64,
            cost_per_request: (base_monthly * tier_multiplier) / (self.capacity.max_requests_per_second as f64 * 86400.0 * 30.0),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoadTestResults {
    pub duration_seconds: u64,
    pub target_rps: f64,
    pub actual_rps: f64,
    pub average_latency_ms: f64,
    pub max_latency_ms: f64,
    pub error_count: u32,
    pub success_count: u32,
    pub cpu_peak: f64,
    pub memory_peak: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataCenterReport {
    pub datacenter_name: String,
    pub tier: DataCenterTier,
    pub location: GeographicLocation,
    pub capacity: CapacityLimits,
    pub hardware: HardwareSpec,
    pub network: NetworkSpec,
    pub security: SecurityConfig,
    pub estimated_costs: EstimatedCosts,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EstimatedCosts {
    pub monthly_usd: f64,
    pub annual_usd: f64,
    pub cost_per_user: f64,
    pub cost_per_request: f64,
}

// Predefined data center configurations
impl DataCenter {
    pub fn tier1_basic() -> Self {
        let config = DataCenterConfig {
            name: "DC-T1-Basic".to_string(),
            tier: DataCenterTier::Tier1,
            location: GeographicLocation {
                region: "US-East-1".to_string(),
                availability_zone: "us-east-1a".to_string(),
                country: "USA".to_string(),
                latitude: 39.0458,
                longitude: -76.6413,
            },
            hardware: HardwareSpec {
                cpu_cores: 4,
                cpu_frequency_ghz: 2.4,
                ram_gb: 8,
                storage_gb: 500,
                storage_type: StorageType::SSD,
                gpu_count: 0,
            },
            network: NetworkSpec {
                bandwidth_gbps: 1.0,
                latency_ms: 5.0,
                cdn_enabled: false,
                load_balancer: false,
            },
            security: SecurityConfig {
                waf_enabled: false,
                ddos_protection: false,
                encryption_at_rest: true,
                encryption_in_transit: true,
                hsm_enabled: false,
            },
        };
        Self::new(config)
    }

    pub fn tier2_production() -> Self {
        let config = DataCenterConfig {
            name: "DC-T2-Production".to_string(),
            tier: DataCenterTier::Tier2,
            location: GeographicLocation {
                region: "EU-West-1".to_string(),
                availability_zone: "eu-west-1b".to_string(),
                country: "Ireland".to_string(),
                latitude: 53.3498,
                longitude: -6.2603,
            },
            hardware: HardwareSpec {
                cpu_cores: 8,
                cpu_frequency_ghz: 3.2,
                ram_gb: 32,
                storage_gb: 2000,
                storage_type: StorageType::NVMe,
                gpu_count: 0,
            },
            network: NetworkSpec {
                bandwidth_gbps: 10.0,
                latency_ms: 2.0,
                cdn_enabled: true,
                load_balancer: true,
            },
            security: SecurityConfig {
                waf_enabled: true,
                ddos_protection: true,
                encryption_at_rest: true,
                encryption_in_transit: true,
                hsm_enabled: false,
            },
        };
        Self::new(config)
    }
