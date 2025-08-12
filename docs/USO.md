# Guia de Uso - Ansible ServiceNow Integration

## Visão Geral

Este guia descreve como usar a automação Ansible para integração com ServiceNow e notificações via Google Chat.

## Casos de Uso Principais

### 1. Monitoramento Automático de Tickets

O sistema monitora automaticamente:
- **Novos incidentes** criados nas últimas 24h
- **SLA próximo de violar** (60 minutos antes)
- **SLA violado** 
- **Tickets sem atualização** há mais de 24h
- **Novos changes** em progresso

### 2. Notificações Inteligentes

As notificações são enviadas para o Google Chat com:
- **Cores diferentes** por tipo de alerta
- **Links diretos** para os tickets
- **Informações resumidas** e detalhadas
- **Botões de ação** para acesso rápido

### 3. Checklist Técnico Automatizado

Baseado no tipo de incidente, executa verificações específicas:
- **Rede**: conectividade, DNS, roteamento
- **Hardware**: temperatura, CPU, memória, disco
- **Software**: processos, serviços, logs
- **Segurança**: tentativas de acesso, configurações

## Execução Manual

### Monitoramento Completo

```bash
# Executar monitoramento completo
ansible-playbook playbooks/servicenow_monitor.yml

# Executar com verbose
ansible-playbook playbooks/servicenow_monitor.yml -v

# Executar em modo dry-run
ansible-playbook playbooks/servicenow_monitor.yml --check
```

### Apenas Notificações

```bash
# Enviar apenas notificações
ansible-playbook playbooks/google_chat_notify.yml

# Com dados específicos
ansible-playbook playbooks/google_chat_notify.yml \
  -e "new_incidents=5" \
  -e "sla_warning_incidents=2"
```

### Checklist Técnico

```bash
# Executar checklist para incidentes específicos
ansible-playbook playbooks/incident_checklist.yml \
  -e "critical_incidents=[{'number':'INC001', 'category':'network'}]"

# Checklist por tipo
ansible-playbook playbooks/incident_checklist.yml \
  -e "incident_type=security"
```

## Configuração no AAP

### Job Templates

#### 1. ServiceNow Monitor (Principal)

**Configuração:**
- **Nome**: `ServiceNow Monitor`
- **Playbook**: `playbooks/servicenow_monitor.yml`
- **Inventory**: `inventories/production`
- **Credentials**: 
  - `servicenow-api`
  - `google-chat-webhook`
- **Schedule**: A cada 15 minutos

**Execução:**
```bash
# Via AAP CLI
awx job_template launch 1

# Via API
curl -X POST \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"check_interval": 15}}' \
  https://your-awx-instance/api/v2/job_templates/1/launch/
```

#### 2. Incident Checklist

**Configuração:**
- **Nome**: `Incident Checklist`
- **Playbook**: `playbooks/incident_checklist.yml`
- **Inventory**: `inventories/production`
- **Credentials**: `servicenow-api`
- **Schedule**: Manual (triggered by incidents)

### Workflows

#### Workflow de Incidente Crítico

1. **Trigger**: Novo incidente P1/P2
2. **Ação 1**: Executar checklist técnico
3. **Ação 2**: Enviar notificação para Google Chat
4. **Ação 3**: Atualizar incidente com progresso
5. **Ação 4**: Escalar se necessário

```yaml
# Exemplo de workflow
- name: Critical Incident Response
  hosts: localhost
  tasks:
    - name: Execute checklist
      include_tasks: playbooks/incident_checklist.yml
      when: incident.priority in ['1', '2']
    
    - name: Send notification
      include_tasks: playbooks/google_chat_notify.yml
    
    - name: Update incident
      uri:
        url: "{{ servicenow_url }}/api/now/table/incident/{{ incident.sys_id }}"
        method: PUT
        body:
          work_notes: "Checklist executado automaticamente"
```

## Monitoramento e Logs

### Verificar Status

```bash
# Verificar logs recentes
tail -f /var/log/ansible/servicenow_monitor.log

# Verificar execuções do AAP
awx job list --status running

# Verificar conectividade
ansible-playbook playbooks/servicenow_monitor.yml --check
```

### Métricas Importantes

- **Tempo de resposta**: < 30 segundos
- **Taxa de sucesso**: > 95%
- **Tickets processados**: por hora/dia
- **SLA violations**: tendências

### Alertas

Configure alertas para:
- Falhas de conectividade ServiceNow
- Falhas de notificação Google Chat
- Tempo de execução > 60 segundos
- Taxa de erro > 5%

## Personalização

### Configurar Filtros

Edite `group_vars/all.yml`:

```yaml
monitoring:
  incident_filters:
    state: "active"
    priority: ["1", "2", "3"]
    category: ["hardware", "software", "network", "security"]
    # Adicionar filtros personalizados
    assignment_group: ["SRE Team", "Infrastructure"]
```

### Personalizar Notificações

```yaml
notifications:
  templates:
    new_incident: "🚨 **Novo Incidente**: {{ incident.number }} - {{ incident.short_description }}"
    # Adicionar templates personalizados
    custom_alert: "🔔 **Alerta Customizado**: {{ message }}"
```

### Adicionar Checklists

```yaml
incident_checklists:
  custom_type:
    - name: "Verificação customizada"
      description: "Descrição da verificação"
      playbook: "roles/custom_check/tasks/main.yml"
```

## Troubleshooting

### Problemas Comuns

#### 1. Falha de Conectividade ServiceNow

**Sintomas:**
- Erro 401/403 na API
- Timeout nas requisições

**Solução:**
```bash
# Verificar credenciais
curl -u username:password \
  https://your-instance.service-now.com/api/now/table/incident

# Verificar permissões
# Acessar ServiceNow > System Definition > Access Control Lists
```

#### 2. Falha de Notificação Google Chat

**Sintomas:**
- Erro 404 no webhook
- Mensagens não aparecem

**Solução:**
```bash
# Testar webhook
curl -X POST -H "Content-Type: application/json" \
  -d '{"text":"test"}' \
  YOUR_WEBHOOK_URL

# Verificar URL do webhook
# Acessar Google Chat > Apps > Manage webhooks
```

#### 3. Checklist Não Executa

**Sintomas:**
- Checklist não aparece no incidente
- Erro de permissão

**Solução:**
```bash
# Verificar logs
tail -f /var/log/ansible/servicenow_monitor.log

# Verificar variáveis
ansible-playbook playbooks/incident_checklist.yml -v
```

### Logs Detalhados

```bash
# Habilitar debug
export ANSIBLE_LOG_LEVEL=DEBUG

# Executar com verbose máximo
ansible-playbook playbooks/servicenow_monitor.yml -vvv

# Verificar logs do AAP
tail -f /var/log/awx/awx.log
```

## Manutenção

### Backup

```bash
# Backup automático
./backup_servicenow_config.sh

# Backup manual
tar -czf backup_$(date +%Y%m%d).tar.gz \
  group_vars/ playbooks/ roles/ inventories/
```

### Atualizações

```bash
# Atualizar collections
ansible-galaxy collection install -r requirements.yml --force

# Atualizar roles
ansible-galaxy role install -r requirements.yml --force

# Verificar compatibilidade
ansible-playbook playbooks/servicenow_monitor.yml --check
```

### Limpeza

```bash
# Limpar logs antigos
find /var/log/ansible -name "*.log" -mtime +7 -delete

# Limpar cache do Ansible
rm -rf ~/.ansible/cp/
```

## Próximos Passos

1. **Integração com outros sistemas**:
   - PagerDuty para escalação
   - Slack para notificações alternativas
   - Grafana para dashboards

2. **Automação avançada**:
   - Auto-resolução de incidentes
   - Machine learning para priorização
   - Integração com CMDB

3. **Melhorias de performance**:
   - Cache de dados ServiceNow
   - Execução paralela de checklists
   - Otimização de queries
