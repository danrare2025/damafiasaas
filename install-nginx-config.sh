#!/bin/bash

# Script para instalar configuração nginx e resolver 404 no damafiarevenda.shop
# Execute como root: sudo bash install-nginx-config.sh

set -e

echo "🚀 Instalando configuração nginx para damafiarevenda.shop..."

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script deve ser executado como root (use sudo)"
    exit 1
fi

# Backup da configuração atual (se existir)
if [ -f "/etc/nginx/sites-available/damafiarevenda.shop" ]; then
    echo "📦 Fazendo backup da configuração atual..."
    cp /etc/nginx/sites-available/damafiarevenda.shop /etc/nginx/sites-available/damafiarevenda.shop.backup.$(date +%Y%m%d_%H%M%S)
fi

# Copiar nova configuração
echo "📝 Copiando nova configuração nginx..."
cp nginx.conf /etc/nginx/sites-available/damafiarevenda.shop

# Criar link simbólico
echo "🔗 Criando link simbólico..."
ln -sf /etc/nginx/sites-available/damafiarevenda.shop /etc/nginx/sites-enabled/

# Remover configuração padrão se existir
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    echo "🗑️ Removendo configuração padrão..."
    rm -f /etc/nginx/sites-enabled/default
fi

# Testar configuração nginx
echo "🧪 Testando configuração nginx..."
if nginx -t; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ Erro na configuração nginx!"
    echo "Restaurando backup..."
    if [ -f "/etc/nginx/sites-available/damafiarevenda.shop.backup.$(date +%Y%m%d_%H%M%S)" ]; then
        cp /etc/nginx/sites-available/damafiarevenda.shop.backup.* /etc/nginx/sites-available/damafiarevenda.shop
    fi
    exit 1
fi

# Recarregar nginx
echo "🔄 Recarregando nginx..."
systemctl reload nginx

# Verificar status
echo "📊 Verificando status do nginx..."
systemctl status nginx --no-pager -l

echo ""
echo "✅ Configuração instalada com sucesso!"
echo ""
echo "🔍 Testes recomendados:"
echo "1. curl -I https://damafiarevenda.shop/admin"
echo "2. curl -I https://damafiarevenda.shop/login"
echo "3. curl -I https://damafiarevenda.shop/catalog"
echo ""
echo "📝 Logs para monitoramento:"
echo "- Acesso: tail -f /var/log/nginx/access.log"
echo "- Erro: tail -f /var/log/nginx/error.log"
echo ""
echo "🎉 O problema de 404 deve estar resolvido!"
echo "Teste acessando as páginas e pressionando F5."