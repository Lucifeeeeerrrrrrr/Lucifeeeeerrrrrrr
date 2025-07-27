#!/bin/bash

# ==============================================================================
# CONFIGURAÇÕES - ALTERE ESSES VALORES
# ==============================================================================
# --- Configs da Rede Local ---
INTERFACE_WIFI="wlan0"                 # Sua interface Wi-Fi (verifique com `ip a`)
SSID_AP="AtousNode-$(cat /sys/class/dmi/id/product_uuid | cut -c-6)" # SSID único
SENHA_AP="atous.network.123"           # Senha do ponto de acesso
IDLE_LIMIT=300000                      # 5 minutos de inatividade (em ms)
CHECK_INTERVAL=15                      # Intervalo de checagem em segundos

# --- Configs da Blockchain ---
# Endereço do contrato deployado. Altere para o seu.
CONTRACT_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3" 
# RPC da sua rede (Anvil local ou uma testnet como Sepolia)
RPC_URL="http://127.0.0.1:8545"
# Chave privada da carteira que vai pagar o gas.
# IMPORTANTE: Use uma chave de teste ou gerencie isso com um vault em produção!
PRIVATE_KEY="SUA_CHAVE_PRIVADA_AQUI"
# Identidade Descentralizada do Nó (DID)
# Usamos o UUID da máquina como base para um DID simples.
NODE_DID="did:atous:node:$(cat /sys/class/dmi/id/product_uuid)"

# ==============================================================================
# ESTADO INICIAL E DEPENDÊNCIAS
# ==============================================================================
ESTADO="NOTEBOOK_ATIVO"
DID_HASH=$(cast keccak $NODE_DID) # Gera o hash do DID para usar no contrato

# --- Verificação de dependências ---
if ! command -v cast &> /dev/null || ! command -v jq &> /dev/null; then
    echo "[ERRO] Dependências não encontradas. Instale 'foundry' e 'jq'."
    echo "         Foundry: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    echo "         jq: sudo pacman -Syu jq"
    exit 1
fi

# ==============================================================================
# FUNÇÕES DE FLAG (MONITORAMENTO DO AMBIENTE)
# ==============================================================================
function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')] [$1] $2"
}

function tela_esta_ligada() {
  [[ $(xprintidle) -lt $IDLE_LIMIT ]]
}

function esta_carregando() {
  # Funciona para a maioria dos notebooks
  [[ "$(cat /sys/class/power_supply/AC*/online 2>/dev/null)" == "1" ]]
}

function rede_estavel() {
  ping -q -c 1 -W 1 8.8.8.8 &>/dev/null
}

function wifi_conectado() {
  [[ "$(nmcli -t -f DEVICE,STATE d | grep "^${INTERFACE_WIFI}:" | cut -d: -f2)" == "connected" ]]
}

# ==============================================================================
# FUNÇÕES DE INTERAÇÃO COM BLOCKCHAIN E REDE
# ==============================================================================
function registrar_estado_na_blockchain() {
    local status_msg="$1"
    local metadata="$2"
    log "BLOCKCHAIN" "Registrando estado: $status_msg"
    
    # Usando 'cast' para enviar a transação
    local tx_hash=$(cast send "$CONTRACT_ADDRESS" "updateStatus(bytes32,string,string)" "$DID_HASH" "$status_msg" "$metadata" --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" | grep "transactionHash" | jq -r '.transactionHash')

    if [[ -n "$tx_hash" ]]; then
        log "BLOCKCHAIN" "Transação enviada com sucesso! Hash: $tx_hash"
    else
        log "ERRO" "Falha ao enviar transação para a blockchain."
    fi
}

function ativar_modo_repetidor() {
  log "FSM" "→ Ativando modo REPETIDOR_WIFI"
  
  # Usando nmcli para criar o Hotspot, que é mais robusto
  # O nmcli gerencia a criação da interface virtual por baixo dos panos.
  nmcli dev wifi hotspot ifname "$INTERFACE_WIFI" ssid "$SSID_AP" password "$SENHA_AP"
  
  if [[ $? -eq 0 ]]; then
    log "FSM" "Hotspot '$SSID_AP' ativado com sucesso."
    ESTADO="REPETIDOR_WIFI"
    registrar_estado_na_blockchain "REPEATER_ACTIVE" "$SSID_AP" &
  else
    log "ERRO" "Falha ao ativar o modo repetidor com NetworkManager."
  fi
}

function desativar_modo_repetidor() {
  log "FSM" "→ Restaurando modo NOTEBOOK_ATIVO"

  # O NetworkManager nomeia a conexão com o SSID do AP.
  nmcli connection down "$SSID_AP" &>/dev/null
  
  if [[ $? -eq 0 ]]; then
    log "FSM" "Hotspot desligado."
    ESTADO="NOTEBOOK_ATIVO"
    registrar_estado_na_blockchain "NODE_STANDBY" "N/A" &
  else
    log "ERRO" "Falha ao desligar o hotspot. Pode já estar inativo."
    # Força o estado para evitar loops de erro.
    ESTADO="NOTEBOOK_ATIVO"
  fi
}

# ==============================================================================
# LOOP PRINCIPAL DO AUTÔMATO FINITO
# ==============================================================================
log "INIT" "Autômato de Rede Iniciado. DID: $NODE_DID"
log "INIT" "Estado Inicial: $ESTADO"

while true; do
  case $ESTADO in
    NOTEBOOK_ATIVO)
      if ! tela_esta_ligada && esta_carregando && rede_estavel && wifi_conectado; then
        log "FSM" "Condições para MODO REPETIDOR atendidas."
        ativar_modo_repetidor
      fi
      ;;
    REPETIDOR_WIFI)
      if tela_esta_ligada; then
        log "FSM" "Condições para MODO NOTEBOOK atendidas (interação detectada)."
        desativar_modo_repetidor
      fi
      ;;
  esac
  sleep "$CHECK_INTERVAL"
done