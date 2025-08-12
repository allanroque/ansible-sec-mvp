#!/bin/bash

# Script para testar o playbook otimizado de tickets novos
# Uso: ./test_new_tickets.sh

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Testando Playbook Otimizado - Tickets Novos ServiceNow${NC}"
echo "=================================================="

# Verificar se as variáveis estão configuradas
if [ -z "$SNOW_USERNAME" ] || [ -z "$SNOW_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Variáveis de ambiente não configuradas${NC}"
    echo "Configure as seguintes variáveis:"
    echo "export SNOW_USERNAME='seu-usuario'"
    echo "export SNOW_PASSWORD='sua-senha'"
    echo ""
    echo "Ou edite o arquivo group_vars/all.yml"
    exit 1
fi

echo -e "${GREEN}✅ Variáveis de ambiente configuradas${NC}"

# Testar conectividade
echo -e "${BLUE}🔍 Testando conectividade com ServiceNow...${NC}"
ansible-playbook playbooks/servicenow_new_tickets.yml --check

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Conectividade OK${NC}"
    
    # Executar playbook real
    echo -e "${BLUE}🚀 Executando playbook otimizado...${NC}"
    ansible-playbook playbooks/servicenow_new_tickets.yml
    
    echo -e "${GREEN}✅ Playbook executado com sucesso!${NC}"
else
    echo -e "${YELLOW}⚠️  Problema de conectividade detectado${NC}"
    echo "Verifique suas credenciais e conectividade de rede"
    exit 1
fi

echo ""
echo -e "${BLUE}📊 Resumo da Execução:${NC}"
echo "• Playbook: servicenow_new_tickets.yml"
echo "• Otimização: Apenas tickets das últimas 24h"
echo "• Performance: Limitado a 50 resultados por tipo"
echo "• Filtros: Prioridades 1,2,3 para incidentes e 1,2 para changes"
