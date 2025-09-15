#!/bin/bash

# ============================================================================
# Script de Configuração Inicial de Segurança para Ubuntu Server
# ============================================================================
# Este script automatiza as configurações básicas de segurança em servidores
# Ubuntu recém-instalados.
#
# IMPORTANTE: Execute este script como root!
# Uso: sudo bash ubuntu-setup.sh
# ============================================================================

set -euo pipefail  # Sai em caso de erro, variável indefinida ou pipe failure

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

# Verificar se está executando como root
if [[ $EUID -ne 0 ]]; then
   error "Este script deve ser executado como root (use sudo)"
fi

# Banner
echo -e "${BLUE}"
echo "============================================================================"
echo "        CONFIGURAÇÃO INICIAL DE SEGURANÇA - UBUNTU SERVER"
echo "============================================================================"
echo -e "${NC}"

# ============================================================================
# CONFIGURAÇÕES (Modifique aqui conforme necessário)
# ============================================================================

# Nova porta SSH (padrão: 22)
NEW_SSH_PORT=2222

# Nome do novo usuário admin
read -p "Digite o nome do novo usuário administrativo: " NEW_USER

# Senha para o novo usuário
while true; do
    read -s -p "Digite a senha para o usuário $NEW_USER: " PASSWORD
    echo
    read -s -p "Confirme a senha: " PASSWORD_CONFIRM
    echo
    if [[ "$PASSWORD" = "$PASSWORD_CONFIRM" ]]; then
        break
    else
        warn "Senhas não coincidem. Tente novamente."
    fi
done

# Chave SSH pública (opcional)
echo
read -p "Deseja adicionar uma chave SSH pública? (s/n): " ADD_SSH_KEY
if [[ $ADD_SSH_KEY =~ ^[Ss]$ ]]; then
    echo "Cole sua chave SSH pública (geralmente o conteúdo do arquivo ~/.ssh/id_rsa.pub):"
    read SSH_PUBLIC_KEY
fi

echo
warn "ATENÇÃO: Este script irá fazer as seguintes alterações:"
echo "  - Atualizar sistema completamente"
echo "  - Criar usuário: $NEW_USER"
echo "  - Configurar firewall UFW"
echo "  - Alterar porta SSH para: $NEW_SSH_PORT"
echo "  - Desabilitar login root via SSH"
echo "  - Configurar fail2ban"
echo "  - Instalar pacotes essenciais de segurança"
echo
read -p "Deseja continuar? (s/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# INÍCIO DAS CONFIGURAÇÕES
# ============================================================================

log "Iniciando configuração de segurança..."

# 1. ATUALIZAÇÃO DO SISTEMA
log "Atualizando sistema..."
apt update && apt upgrade -y
apt autoremove -y
apt autoclean

# 2. INSTALAÇÃO DE PACOTES ESSENCIAIS
log "Instalando pacotes essenciais..."
apt install -y \
    ufw \
    fail2ban \
    unattended-upgrades \
    curl \
    wget \
    htop \
    vim \
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    tree

# 3. CRIAR NOVO USUÁRIO ADMINISTRATIVO
log "Criando usuário administrativo: $NEW_USER"
if id "$NEW_USER" &>/dev/null; then
    warn "Usuário $NEW_USER já existe, pulando criação..."
else
    useradd -m -s /bin/bash "$NEW_USER"
    echo "$NEW_USER:$PASSWORD" | chpasswd
    usermod -aG sudo "$NEW_USER"
    
    # Configurar diretório SSH
    USER_HOME="/home/$NEW_USER"
    mkdir -p "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    
    # Adicionar chave SSH se fornecida
    if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
        echo "$SSH_PUBLIC_KEY" > "$USER_HOME/.ssh/authorized_keys"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"
    fi
    
    chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh"
    log "Usuário $NEW_USER criado com sucesso!"
fi

# 4. CONFIGURAÇÃO DO SSH
log "Configurando SSH..."

# Backup da configuração original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar configurações de segurança SSH
cat > /etc/ssh/sshd_config << EOF
# Configurações de Segurança SSH - Gerado automaticamente
Port $NEW_SSH_PORT
Protocol 2

# Autenticação
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Configurações de conexão
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxStartups 10:30:60
LoginGraceTime 60

# Usuários permitidos
AllowUsers $NEW_USER

# Configurações de rede
AddressFamily inet
ListenAddress 0.0.0.0

# Configurações de segurança adiciais
HostbasedAuthentication no
IgnoreRhosts yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Banner de aviso
Banner /etc/ssh/banner
EOF

# Criar banner de aviso
cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                            AVISO DE SEGURANÇA
***************************************************************************
Este sistema é para uso autorizado apenas. Todas as atividades são
monitoradas e registradas. Uso não autorizado é estritamente proibido
e pode resultar em ação legal.
***************************************************************************
EOF

log "SSH configurado na porta $NEW_SSH_PORT"

# 5. CONFIGURAÇÃO DO FIREWALL (UFW)
log "Configurando firewall UFW..."

# Resetar UFW para configuração limpa
ufw --force reset

# Políticas padrão
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH na nova porta
ufw allow $NEW_SSH_PORT/tcp comment 'SSH'

# Permitir outras portas comuns se necessário (descomente conforme necessário)
# ufw allow 80/tcp comment 'HTTP'
# ufw allow 443/tcp comment 'HTTPS'

# Ativar UFW
ufw --force enable

log "Firewall configurado e ativado"

# 6. CONFIGURAÇÃO DO FAIL2BAN
log "Configurando Fail2Ban..."

# Configuração personalizada do Fail2Ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = $NEW_SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF

# Reiniciar Fail2Ban
systemctl enable fail2ban
systemctl restart fail2ban

log "Fail2Ban configurado e ativado"

# 7. CONFIGURAÇÃO DE UPDATES AUTOMÁTICOS
log "Configurando updates automáticos de segurança..."

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

systemctl enable unattended-upgrades

log "Updates automáticos de segurança configurados"

# 8. CONFIGURAÇÕES ADICIONAIS DE SEGURANÇA
log "Aplicando configurações adicionais de segurança..."

# Desabilitar IPv6 se não for usado (opcional)
# echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf

# Configurações de rede seguras
cat >> /etc/sysctl.conf << EOF

# Configurações de segurança de rede
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF

sysctl -p

# 9. CONFIGURAR LIMITES DE RECURSOS
log "Configurando limites de recursos..."

cat >> /etc/security/limits.conf << EOF

# Limites de recursos para segurança
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# 10. REMOVER PACOTES DESNECESSÁRIOS
log "Removendo pacotes desnecessários..."
apt autoremove --purge -y

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

log "Reiniciando serviços..."
systemctl restart ssh
systemctl restart fail2ban
systemctl restart ufw

# Mostrar status dos serviços
log "Status dos serviços de segurança:"
echo -e "${BLUE}SSH:${NC} $(systemctl is-active ssh)"
echo -e "${BLUE}UFW:${NC} $(systemctl is-active ufw)"
echo -e "${BLUE}Fail2Ban:${NC} $(systemctl is-active fail2ban)"

echo
echo -e "${GREEN}============================================================================"
echo "                    CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "============================================================================${NC}"
echo
echo -e "${YELLOW}INFORMAÇÕES IMPORTANTES:${NC}"
echo "• Nova porta SSH: $NEW_SSH_PORT"
echo "• Usuário administrativo: $NEW_USER"
echo "• Login root via SSH: DESABILITADO"
echo "• Firewall: ATIVADO (apenas porta $NEW_SSH_PORT permitida)"
echo "• Fail2Ban: ATIVADO"
echo "• Updates automáticos: ATIVADOS"
echo
echo -e "${RED}ATENÇÃO:${NC}"
echo "• Teste a nova conexão SSH ANTES de desconectar esta sessão!"
echo "• Comando de teste: ssh -p $NEW_SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
echo "• Backup da configuração SSH original salvo em: /etc/ssh/sshd_config.backup.*"
echo
echo -e "${YELLOW}Para conectar via SSH:${NC}"
echo "ssh -p $NEW_SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
echo
warn "Recomendamos reiniciar o servidor após testar a conexão SSH!"
echo

# Criar script de informações do sistema
cat > /home/$NEW_USER/sistema-info.sh << 'EOF'
#!/bin/bash
echo "========================================="
echo "        INFORMAÇÕES DO SISTEMA"
echo "========================================="
echo "Hostname: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Usuários logados: $(who | wc -l)"
echo
echo "Status dos serviços:"
echo "SSH: $(systemctl is-active ssh)"
echo "UFW: $(systemctl is-active ufw)"
echo "Fail2Ban: $(systemctl is-active fail2ban)"
echo
echo "Portas abertas:"
ufw status numbered
EOF

chmod +x /home/$NEW_USER/sistema-info.sh
chown $NEW_USER:$NEW_USER /home/$NEW_USER/sistema-info.sh

log "Script de informações criado em: /home/$NEW_USER/sistema-info.sh"
log "Configuração inicial concluída!"