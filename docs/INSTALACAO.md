# Guia de Instalação - Ansible ServiceNow Integration

## Pré-requisitos

### Sistema Operacional
- Linux (Ubuntu 20.04+, CentOS 8+, RHEL 8+)
- macOS 10.15+
- Windows 10+ (com WSL2)

### Software Necessário
- Python 3.8+
- Ansible 2.12+
- Git

### Credenciais Necessárias
- ServiceNow API credentials
- Google Chat Webhook URL
- Permissões de rede para acessar ServiceNow

## Instalação Passo a Passo

### 1. Clone do Repositório

```bash
git clone https://github.com/seu-usuario/ansible-sec-mvp.git
cd ansible-sec-mvp
```

### 2. Instalação do Python e Ansible

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
pip3 install ansible
```

#### CentOS/RHEL:
```bash
sudo yum install python3 python3-pip
pip3 install ansible
```

#### macOS:
```bash
brew install python3
pip3 install ansible
```

### 3. Instalação das Dependências

```bash
# Instalar collections do Ansible
ansible-galaxy collection install -r requirements.yml

# Instalar roles do Ansible
ansible-galaxy role install -r requirements.yml
```

### 4. Configuração das Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```bash
# ServiceNow Configuration
SERVICENOW_INSTANCE=your-instance.service-now.com
SERVICENOW_USERNAME=your-api-username
SERVICENOW_PASSWORD=your-api-password

# Google Chat Configuration
GOOGLE_CHAT_WEBHOOK=https://chat.googleapis.com/v1/spaces/...
GOOGLE_CHAT_SPACE=SRE Team

# Optional: Logging Configuration
ANSIBLE_LOG_LEVEL=INFO
ANSIBLE_LOG_FILE=/var/log/ansible/servicenow_monitor.log
```

### 5. Configuração do ServiceNow

#### 5.1 Criar Usuário API no ServiceNow

1. Acesse o ServiceNow como administrador
2. Vá para **System Definition > Users**
3. Crie um novo usuário para API
4. Atribua as seguintes roles:
   - `itil`
   - `incident_manager`
   - `change_manager`
   - `rest_api_explorer`

#### 5.2 Configurar Permissões de API

1. Vá para **System Definition > Access Control Lists**
2. Configure ACLs para as tabelas:
   - `incident`
   - `change_request`
   - `sys_user`

### 6. Configuração do Google Chat

#### 6.1 Criar Webhook

1. Acesse o Google Chat
2. Vá para o espaço onde deseja receber notificações
3. Clique em **Apps** > **Manage webhooks**
4. Crie um novo webhook
5. Copie a URL do webhook

#### 6.2 Testar Webhook

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"text":"Teste de integração ServiceNow"}' \
  https://chat.googleapis.com/v1/spaces/...
```

### 7. Configuração do Ansible Automation Platform (AAP)

#### 7.1 Criar Credentials no AAP

1. Acesse o AAP como administrador
2. Vá para **Settings > Credentials**
3. Crie as seguintes credentials:

**ServiceNow Credentials:**
- Tipo: Machine
- Nome: `servicenow-api`
- Username: `{{ SERVICENOW_USERNAME }}`
- Password: `{{ SERVICENOW_PASSWORD }}`

**Google Chat Webhook:**
- Tipo: Machine
- Nome: `google-chat-webhook`
- Username: `webhook`
- Password: `{{ GOOGLE_CHAT_WEBHOOK }}`

#### 7.2 Criar Job Templates

1. Vá para **Templates > Job Templates**
2. Crie os seguintes templates:

**ServiceNow Monitor:**
- Nome: `ServiceNow Monitor`
- Playbook: `playbooks/servicenow_monitor.yml`
- Inventory: `inventories/production`
- Credentials: `servicenow-api`, `google-chat-webhook`

**Incident Checklist:**
- Nome: `Incident Checklist`
- Playbook: `playbooks/incident_checklist.yml`
- Inventory: `inventories/production`
- Credentials: `servicenow-api`

#### 7.3 Configurar Schedules

1. Vá para **Templates > Job Templates**
2. Selecione o template `ServiceNow Monitor`
3. Clique em **Schedules**
4. Crie um schedule para execução a cada 15 minutos

### 8. Teste da Instalação

#### 8.1 Teste Manual

```bash
# Testar conectividade com ServiceNow
ansible-playbook playbooks/servicenow_monitor.yml --check

# Testar notificação do Google Chat
ansible-playbook playbooks/google_chat_notify.yml --check
```

#### 8.2 Teste Automatizado

```bash
# Executar monitoramento completo
ansible-playbook playbooks/servicenow_monitor.yml

# Verificar logs
tail -f /var/log/ansible/servicenow_monitor.log
```

### 9. Configuração de Logs

#### 9.1 Criar Diretório de Logs

```bash
sudo mkdir -p /var/log/ansible
sudo chown $USER:$USER /var/log/ansible
```

#### 9.2 Configurar Rotação de Logs

Crie o arquivo `/etc/logrotate.d/ansible-servicenow`:

```
/var/log/ansible/servicenow_monitor*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
```

### 10. Configuração de Monitoramento

#### 10.1 Configurar Alertas

1. Configure alertas no AAP para falhas de job
2. Configure notificações por email para o time SRE
3. Configure dashboards para visualizar métricas

#### 10.2 Configurar Backup

```bash
# Criar script de backup
cat > backup_servicenow_config.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/servicenow-config"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/servicenow_config_$DATE.tar.gz \
    group_vars/ \
    playbooks/ \
    roles/ \
    inventories/
EOF

chmod +x backup_servicenow_config.sh
```

## Troubleshooting

### Problemas Comuns

#### 1. Erro de Conectividade ServiceNow

```bash
# Verificar conectividade
curl -u username:password \
  https://your-instance.service-now.com/api/now/table/incident
```

#### 2. Erro de Webhook Google Chat

```bash
# Testar webhook
curl -X POST -H "Content-Type: application/json" \
  -d '{"text":"test"}' \
  YOUR_WEBHOOK_URL
```

#### 3. Erro de Permissões

```bash
# Verificar permissões
ls -la /var/log/ansible/
sudo chown -R $USER:$USER /var/log/ansible/
```

### Logs Importantes

- `/var/log/ansible/servicenow_monitor.log` - Logs do monitoramento
- `/var/log/ansible/ansible.log` - Logs gerais do Ansible
- `/var/log/ansible/awx.log` - Logs do AAP (se aplicável)

## Próximos Passos

1. Configure alertas personalizados
2. Implemente dashboards de métricas
3. Configure backup automático
4. Implemente testes automatizados
5. Configure CI/CD para atualizações
