#!/bin/bash

# Script de execução para monitoramento ServiceNow
# Uso: ./scripts/run_monitor.sh [opção]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÃO]

OPÇÕES:
    monitor      Executar monitoramento completo (padrão)
    notify       Executar apenas notificações
    checklist    Executar checklist técnico
    test         Executar testes de conectividade
    install      Instalar dependências
    backup       Fazer backup da configuração
    logs         Mostrar logs recentes
    status       Verificar status do sistema
    help         Mostrar esta ajuda

EXEMPLOS:
    $0 monitor
    $0 notify
    $0 checklist --incident-type network
    $0 test
    $0 logs

EOF
}

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    if ! command -v ansible &> /dev/null; then
        error "Ansible não encontrado. Instale com: pip install ansible"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        error "Python3 não encontrado"
        exit 1
    fi
    
    success "Dependências verificadas"
}

# Função para verificar configuração
check_config() {
    log "Verificando configuração..."
    
    if [ ! -f "group_vars/all.yml" ]; then
        error "Arquivo group_vars/all.yml não encontrado"
        exit 1
    fi
    
    if [ ! -f "playbooks/servicenow_monitor.yml" ]; then
        error "Playbook servicenow_monitor.yml não encontrado"
        exit 1
    fi
    
    success "Configuração verificada"
}

# Função para executar monitoramento
run_monitor() {
    log "Executando monitoramento ServiceNow..."
    
    ansible-playbook playbooks/servicenow_monitor.yml \
        --inventory inventories/production/hosts \
        --extra-vars "execution_mode=production"
    
    success "Monitoramento concluído"
}

# Função para executar notificações
run_notify() {
    log "Executando notificações Google Chat..."
    
    ansible-playbook playbooks/google_chat_notify.yml \
        --inventory inventories/production/hosts
    
    success "Notificações enviadas"
}

# Função para executar checklist
run_checklist() {
    local incident_type=${1:-"all"}
    
    log "Executando checklist técnico para tipo: $incident_type"
    
    ansible-playbook playbooks/incident_checklist.yml \
        --inventory inventories/production/hosts \
        --extra-vars "incident_type=$incident_type"
    
    success "Checklist concluído"
}

# Função para executar testes
run_tests() {
    log "Executando testes de conectividade..."
    
    # Teste ServiceNow
    log "Testando conectividade ServiceNow..."
    ansible-playbook playbooks/servicenow_monitor.yml --check
    
    # Teste Google Chat
    log "Testando notificação Google Chat..."
    ansible-playbook playbooks/google_chat_notify.yml --check
    
    success "Testes concluídos"
}

# Função para instalar dependências
run_install() {
    log "Instalando dependências..."
    
    # Instalar collections
    ansible-galaxy collection install -r requirements.yml
    
    # Instalar roles
    ansible-galaxy role install -r requirements.yml
    
    # Criar diretório de logs
    sudo mkdir -p /var/log/ansible
    sudo chown $USER:$USER /var/log/ansible
    
    success "Dependências instaladas"
}

# Função para backup
run_backup() {
    local backup_dir="backup/$(date +%Y%m%d_%H%M%S)"
    
    log "Fazendo backup para $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    tar -czf "$backup_dir/config.tar.gz" \
        group_vars/ \
        playbooks/ \
        roles/ \
        inventories/ \
        ansible.cfg \
        requirements.yml
    
    success "Backup criado em $backup_dir"
}

# Função para mostrar logs
show_logs() {
    log "Mostrando logs recentes..."
    
    if [ -f "/var/log/ansible/servicenow_monitor.log" ]; then
        echo "=== Logs do Monitoramento ==="
        tail -20 /var/log/ansible/servicenow_monitor.log
    else
        warning "Arquivo de log não encontrado"
    fi
    
    if [ -f "/var/log/ansible/ansible.log" ]; then
        echo -e "\n=== Logs Gerais do Ansible ==="
        tail -10 /var/log/ansible/ansible.log
    fi
}

# Função para verificar status
check_status() {
    log "Verificando status do sistema..."
    
    # Verificar se o diretório de logs existe
    if [ -d "/var/log/ansible" ]; then
        success "Diretório de logs: OK"
    else
        warning "Diretório de logs: Não encontrado"
    fi
    
    # Verificar última execução
    if [ -f "/var/log/ansible/servicenow_monitor.log" ]; then
        local last_run=$(tail -1 /var/log/ansible/servicenow_monitor.log | grep -o '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]' || echo "Nunca")
        log "Última execução: $last_run"
    fi
    
    # Verificar conectividade ServiceNow
    log "Testando conectividade ServiceNow..."
    if ansible-playbook playbooks/servicenow_monitor.yml --check &> /dev/null; then
        success "ServiceNow: Conectivo"
    else
        error "ServiceNow: Erro de conectividade"
    fi
}

# Função principal
main() {
    local action=${1:-"monitor"}
    
    case $action in
        "monitor")
            check_dependencies
            check_config
            run_monitor
            ;;
        "notify")
            check_dependencies
            check_config
            run_notify
            ;;
        "checklist")
            check_dependencies
            check_config
            run_checklist "$2"
            ;;
        "test")
            check_dependencies
            check_config
            run_tests
            ;;
        "install")
            run_install
            ;;
        "backup")
            run_backup
            ;;
        "logs")
            show_logs
            ;;
        "status")
            check_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Opção inválida: $action"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
