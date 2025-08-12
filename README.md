# Ansible Automation Platform - Integração ServiceNow e Google Chat

## Visão Geral

Este projeto implementa automações com Ansible Automation Platform (AAP) para integração com ServiceNow e notificações via Google Chat, focando em:

- Monitoramento de tickets de incidentes e changes no ServiceNow
- Notificações automáticas para Google Chat
- Checklist técnico baseado no tipo de incidente
- Controle de SLA e atualizações

## Casos de Uso

### 1. Monitoramento de Tickets ServiceNow
- Verificação de tickets novos
- Monitoramento de SLA próximo de violação
- Identificação de tickets com SLA violado
- Alertas para tickets sem atualização há mais de 24h

### 2. Notificações Google Chat
- Envio de mensagens estruturadas
- Diferentes tipos de alerta por prioridade
- Inclusão de links diretos para tickets
- Formatação rica com cards e botões

### 3. Checklist Técnico
- Playbooks específicos por tipo de incidente
- Progresso de ações automatizadas
- Documentação de resolução

## Estrutura do Projeto

```
ansible-sec-mvp/
├── collections/                    # Coleções customizadas
│   ├── ansible_collections/
│   │   ├── servicenow/
│   │   └── google_chat/
├── playbooks/                     # Playbooks principais
│   ├── servicenow_monitor.yml
│   ├── google_chat_notify.yml
│   └── incident_checklist.yml
├── inventories/                   # Inventários
│   ├── production/
│   └── staging/
├── group_vars/                    # Variáveis de grupo
├── host_vars/                     # Variáveis de host
├── roles/                         # Roles customizadas
├── templates/                     # Templates
├── files/                         # Arquivos estáticos
└── docs/                          # Documentação
```

## Pré-requisitos

### ServiceNow
- API credentials (username/password ou OAuth)
- Endpoint da instância ServiceNow
- Permissões para acessar incidentes e changes

### Google Chat
- Webhook URL do espaço/room
- Permissões para enviar mensagens

### Ansible Automation Platform
- AAP 2.x ou superior
- Credentials configuradas
- Collections instaladas

## Instalação

1. Clone o repositório
2. Instale as dependências:
   ```bash
   ansible-galaxy collection install servicenow.itsm
   ansible-galaxy collection install community.google
   ```

3. Configure as variáveis em `group_vars/all.yml`

4. Execute o playbook principal:
   ```bash
   ansible-playbook playbooks/servicenow_monitor.yml
   ```

## Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` ou configure no AAP:

```bash
SERVICENOW_INSTANCE=your-instance.service-now.com
SERVICENOW_USERNAME=your-username
SERVICENOW_PASSWORD=your-password
GOOGLE_CHAT_WEBHOOK=https://chat.googleapis.com/v1/spaces/...
```

### Credentials no AAP

1. **ServiceNow Credentials**
   - Tipo: Machine
   - Username: ServiceNow API user
   - Password: ServiceNow API password

2. **Google Chat Webhook**
   - Tipo: Machine
   - Username: webhook
   - Password: webhook URL

## Uso

### Monitoramento Contínuo

Para monitoramento contínuo, configure um job template no AAP com:

- Playbook: `playbooks/servicenow_monitor.yml`
- Schedule: A cada 15 minutos
- Inventory: `inventories/production`

### Execução Manual

```bash
# Monitoramento completo
ansible-playbook playbooks/servicenow_monitor.yml

# Apenas notificações
ansible-playbook playbooks/google_chat_notify.yml

# Checklist específico
ansible-playbook playbooks/incident_checklist.yml -e "incident_type=network"
```

## Monitoramento e Logs

- Logs são salvos em `/var/log/ansible/`
- Métricas disponíveis via AAP
- Alertas configuráveis para falhas

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT.
