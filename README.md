# 🛡️ Ubuntu Server Initial Security Setup

Script automatizado para configuração inicial de segurança em servidores Ubuntu recém-instalados. Este script implementa as melhores práticas de segurança e automatiza tarefas repetitivas de hardening.

## 📋 Índice

- [Recursos](#-recursos)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Uso](#-uso)
- [Configurações Aplicadas](#-configurações-aplicadas)
- [Verificação Pós-Instalação](#-verificação-pós-instalação)
- [Solução de Problemas](#-solução-de-problemas)
- [Personalização](#-personalização)
- [Segurança](#-segurança)
- [Contribuição](#-contribuição)

## 🚀 Recursos

### Segurança Básica
- ✅ Atualização completa do sistema
- ✅ Criação de usuário administrativo
- ✅ Desabilitação do login root via SSH
- ✅ Alteração da porta padrão SSH
- ✅ Configuração do firewall UFW
- ✅ Instalação e configuração do Fail2Ban

### Segurança Avançada
- ✅ Updates automáticos de segurança
- ✅ Configurações seguras de rede (sysctl)
- ✅ Limites de recursos do sistema
- ✅ Banner de aviso SSH
- ✅ Configurações otimizadas SSH

### Recursos Extras
- ✅ Logs coloridos e informativos
- ✅ Backups automáticos de configurações
- ✅ Script de informações do sistema
- ✅ Validação de entrada interativa
- ✅ Verificações de pré-requisitos

## 📋 Pré-requisitos

- **Sistema Operacional**: Ubuntu Server 18.04+ (testado em 20.04 e 22.04)
- **Privilégios**: Acesso root ou sudo
- **Conexão**: Internet ativa para downloads
- **SSH**: Acesso SSH atual funcionando

## 📥 Instalação

### Método 1: Download Direto
```bash
# Baixar o script
wget https://raw.githubusercontent.com/seu-usuario/ubuntu-setup/main/ubuntu-setup.sh

# Tornar executável
chmod +x ubuntu-setup.sh
```

### Método 2: Git Clone
```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/ubuntu-setup.git
cd ubuntu-setup

# Tornar executável
chmod +x ubuntu-setup.sh
```

### Método 3: Criação Manual
```bash
# Criar arquivo
nano ubuntu-setup.sh

# Colar o conteúdo do script
# Salvar e tornar executável
chmod +x ubuntu-setup.sh
```

## 🎯 Uso

### Execução Básica
```bash
sudo ./ubuntu-setup.sh
```

### Processo Interativo

O script solicitará as seguintes informações:

1. **Nome do usuário administrativo**
   ```
   Digite o nome do novo usuário administrativo: meuadmin
   ```

2. **Senha do usuário** (digitação oculta)
   ```
   Digite a senha para o usuário meuadmin: ********
   Confirme a senha: ********
   ```

3. **Chave SSH pública** (opcional)
   ```
   Deseja adicionar uma chave SSH pública? (s/n): s
   Cole sua chave SSH pública: ssh-rsa AAAAB3NzaC1yc2E...
   ```

4. **Confirmação final**
   ```
   Deseja continuar? (s/n): s
   ```

### Exemplo Completo
```bash
$ sudo ./ubuntu-setup.sh

============================================================================
        CONFIGURAÇÃO INICIAL DE SEGURANÇA - UBUNTU SERVER
============================================================================

Digite o nome do novo usuário administrativo: admin
Digite a senha para o usuário admin: 
Confirme a senha: 
Deseja adicionar uma chave SSH pública? (s/n): n

ATENÇÃO: Este script irá fazer as seguintes alterações:
  - Atualizar sistema completamente
  - Criar usuário: admin
  - Configurar firewall UFW
  - Alterar porta SSH para: 2222
  - Desabilitar login root via SSH
  - Configurar fail2ban
  - Instalar pacotes essenciais de segurança

Deseja continuar? (s/n): s

[2024-01-15 10:30:00] Iniciando configuração de segurança...
[2024-01-15 10:30:05] Atualizando sistema...
[...]
```

## ⚙️ Configurações Aplicadas

### SSH Security
- **Nova porta**: 2222 (configurável)
- **Root login**: Desabilitado
- **Tentativas máximas**: 3
- **Timeout de login**: 60 segundos
- **Keep alive**: 300 segundos
- **Banner de aviso**: Habilitado

### Firewall (UFW)
- **Política padrão**: Deny incoming, Allow outgoing
- **Portas liberadas**: Apenas SSH (porta configurada)
- **Logging**: Habilitado
- **Status**: Ativo

### Fail2Ban
- **Tempo de ban**: 1 hora
- **Tentativas máximas**: 3
- **Janela de tempo**: 10 minutos
- **Backend**: systemd
- **Proteção**: SSH

### Usuário Administrativo
- **Shell**: /bin/bash
- **Grupos**: sudo
- **Diretório SSH**: ~/.ssh configurado
- **Chaves SSH**: Suporte opcional

### Updates Automáticos
- **Updates de segurança**: Diários
- **Limpeza automática**: Semanal
- **Pacotes órfãos**: Remoção automática
- **Reinicialização**: Manual (por segurança)

### Configurações de Sistema
- **Limites de arquivo**: 65536
- **Limites de processo**: 65536
- **TCP SYN cookies**: Habilitado
- **IP forwarding**: Configurado conforme necessário

## ✅ Verificação Pós-Instalação

### 1. Testar Nova Conexão SSH
**⚠️ IMPORTANTE**: Teste em um novo terminal antes de fechar a sessão atual!

```bash
# Testar conexão (substitua pelos seus dados)
ssh -p 2222 admin@SEU_IP_SERVIDOR

# Exemplo
ssh -p 2222 admin@192.168.1.100
```

### 2. Verificar Serviços
```bash
# Status dos serviços de segurança
sudo systemctl status ssh
sudo systemctl status ufw
sudo systemctl status fail2ban

# Verificar portas abertas
sudo ufw status numbered
sudo netstat -tulpn | grep :2222
```

### 3. Executar Script de Informações
```bash
# Script criado automaticamente
./sistema-info.sh
```

Saída esperada:
```
=========================================
        INFORMAÇÕES DO SISTEMA
=========================================
Hostname: ubuntu-server
IP: 192.168.1.100
OS: Ubuntu 22.04.3 LTS
Kernel: 5.15.0-88-generic
Uptime: up 5 minutes
Usuários logados: 1

Status dos serviços:
SSH: active
UFW: active
Fail2Ban: active

Portas abertas:
     To                         Action      From
     --                         ------      ----
[ 1] 2222/tcp                   ALLOW IN    Anywhere
```

### 4. Verificar Logs
```bash
# Logs SSH
sudo tail -f /var/log/auth.log

# Logs Fail2Ban
sudo fail2ban-client status sshd

# Logs UFW
sudo tail -f /var/log/ufw.log
```

## 🔧 Solução de Problemas

### Não Consigo Conectar via SSH

**Problema**: Conexão SSH recusada na nova porta

**Soluções**:
```bash
# 1. Verificar se SSH está rodando
sudo systemctl status ssh

# 2. Verificar se a porta está aberta
sudo netstat -tulpn | grep :2222

# 3. Verificar firewall
sudo ufw status

# 4. Verificar configuração SSH
sudo sshd -t
```

**Emergência**: Use a sessão atual para reverter:
```bash
# Restaurar configuração SSH original
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Esqueci a Senha do Usuário

**Solução** (via console local ou sessão root existente):
```bash
# Redefinir senha
sudo passwd NOME_USUARIO

# Exemplo
sudo passwd admin
```

### Fail2Ban Bloqueou Meu IP

**Soluções**:
```bash
# Verificar IPs bloqueados
sudo fail2ban-client status sshd

# Desbloquear seu IP
sudo fail2ban-client set sshd unbanip SEU_IP

# Exemplo
sudo fail2ban-client set sshd unbanip 192.168.1.50
```

### UFW Bloqueou Acesso

**Soluções**:
```bash
# Verificar regras
sudo ufw status numbered

# Adicionar regra temporária
sudo ufw allow from SEU_IP to any port 2222

# Desabilitar UFW temporariamente (último recurso)
sudo ufw disable
```

### Sistema Não Atualiza

**Soluções**:
```bash
# Verificar repositórios
sudo apt update

# Corrigir dependências
sudo apt --fix-broken install

# Limpar cache
sudo apt clean && sudo apt autoclean
```

## 🎨 Personalização

### Alterar Porta SSH
Edite a variável no script:
```bash
# Nova porta SSH (padrão: 22)
NEW_SSH_PORT=2222  # Altere para a porta desejada
```

### Adicionar Portas no Firewall
Descomente ou adicione no script:
```bash
# Permitir HTTP
ufw allow 80/tcp comment 'HTTP'

# Permitir HTTPS  
ufw allow 443/tcp comment 'HTTPS'

# Permitir porta personalizada
ufw allow 3000/tcp comment 'App Custom'
```

### Personalizar Fail2Ban
Edite a seção do Fail2Ban:
```bash
bantime = 2h     # Tempo de banimento
findtime = 15m   # Janela de detecção
maxretry = 5     # Tentativas máximas
```

### Adicionar Mais Usuários
Adicione ao final do script:
```bash
# Criar usuário adicional
useradd -m -s /bin/bash "outro_usuario"
echo "outro_usuario:senha123" | chpasswd
usermod -aG sudo "outro_usuario"
```

### Instalar Pacotes Adicionais
Adicione à lista de pacotes:
```bash
apt install -y \
    ufw \
    fail2ban \
    # ... pacotes existentes
    docker.io \
    nginx \
    nodejs \
    # seus pacotes personalizados
```

## 🔐 Segurança

### Boas Práticas Implementadas

1. **Princípio do Menor Privilégio**
   - Root desabilitado via SSH
   - Usuários limitados específicos
   - Sudo configurado adequadamente

2. **Defesa em Profundidade**
   - Firewall (UFW)
   - Detecção de intrusão (Fail2Ban)
   - Configurações SSH hardened
   - Updates automáticos

3. **Monitoramento e Logs**
   - Logs centralizados
   - Alertas de segurança
   - Auditoria de acesso

### Considerações de Segurança

- **Senhas Fortes**: Use senhas complexas de 12+ caracteres
- **Chaves SSH**: Prefira autenticação por chave
- **Updates**: Monitore updates críticos
- **Backup**: Mantenha backups das configurações
- **Monitoramento**: Implemente monitoramento contínuo

### Próximos Passos Recomendados

1. **Configurar SSL/TLS** para aplicações web
2. **Implementar IDS/IPS** adicional
3. **Configurar backup automático**
4. **Monitoramento de recursos**
5. **Hardening adicional** específico da aplicação

## 🤝 Contribuição

### Como Contribuir

1. **Fork** o repositório
2. **Crie** uma branch para sua feature
3. **Commit** suas mudanças
4. **Push** para a branch
5. **Abra** um Pull Request

### Reportar Problemas

Use as [Issues do GitHub](https://github.com/seu-usuario/ubuntu-setup/issues) para:
- 🐛 Reportar bugs
- 💡 Sugerir melhorias
- ❓ Fazer perguntas
- 📖 Melhorar documentação

### Diretrizes

- Siga as convenções de código bash
- Teste em múltiplas versões Ubuntu
- Documente mudanças significativas
- Mantenha compatibilidade retroativa

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## ⚠️ Disclaimer

Este script modifica configurações críticas do sistema. Use por sua própria conta e risco. Sempre teste em ambiente de desenvolvimento antes de aplicar em produção.
