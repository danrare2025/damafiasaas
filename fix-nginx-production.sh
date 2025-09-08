#!/bin/bash

# Script para corrigir configuração do nginx em produção
# Este script deve ser executado no servidor de produção

echo "🔧 Iniciando correção do nginx para damafiarevenda.shop..."

# 1. Backup da configuração atual
echo "📋 Fazendo backup da configuração atual..."
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)

# 2. Criar nova configuração
echo "⚙️ Criando nova configuração do nginx..."
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    listen 443 ssl http2;
    server_name damafiarevenda.shop www.damafiarevenda.shop;
    
    # Certificados SSL (ajustar paths conforme necessário)
    ssl_certificate /etc/ssl/certs/damafiarevenda.shop.crt;
    ssl_certificate_key /etc/ssl/private/damafiarevenda.shop.key;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Redirecionamento HTTP para HTTPS
    if (\$scheme != "https") {
        return 301 https://\$host\$request_uri;
    }
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Servir arquivos estáticos do frontend
    location / {
        root /var/www/damafiarevenda;
        try_files \$uri \$uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # PROXY PARA API DO BACKEND - CORREÇÃO PRINCIPAL
    location /api/ {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    
    # Servir uploads do backend
    location /uploads/ {
        root /var/www/damafiarevenda/backend;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # CORS para uploads
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
    
    # Logs
    access_log /var/log/nginx/damafiarevenda.access.log;
    error_log /var/log/nginx/damafiarevenda.error.log;
}
EOF

# 3. Testar configuração
echo "🧪 Testando configuração do nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida!"
else
    echo "❌ Erro na configuração! Restaurando backup..."
    sudo cp /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S) /etc/nginx/sites-available/default
    exit 1
fi

# 4. Verificar se backend está rodando
echo "🔍 Verificando se backend está rodando na porta 3002..."
if netstat -tlnp | grep :3002 > /dev/null; then
    echo "✅ Backend rodando na porta 3002"
else
    echo "⚠️ Backend NÃO está rodando na porta 3002!"
    echo "Execute: cd /path/to/backend && npm start"
    echo "Ou use PM2: pm2 start npm --name 'damafia-backend' -- start"
fi

# 5. Recarregar nginx
echo "🔄 Recarregando nginx..."
if sudo systemctl reload nginx; then
    echo "✅ Nginx recarregado com sucesso!"
else
    echo "❌ Erro ao recarregar nginx!"
    sudo systemctl status nginx
    exit 1
fi

# 6. Verificar status
echo "📊 Verificando status dos serviços..."
echo "Nginx:"
sudo systemctl status nginx --no-pager -l

echo "\nPortas abertas:"
sudo netstat -tlnp | grep -E ':(80|443|3002)'

# 7. Testar endpoints
echo "\n🧪 Testando endpoints..."
echo "Testando site principal:"
curl -I http://localhost 2>/dev/null | head -1

echo "Testando API health:"
curl -I http://localhost/api/health 2>/dev/null | head -1

echo "\n✅ Configuração aplicada!"
echo "\n📋 Próximos passos:"
echo "1. Teste no navegador: https://damafiarevenda.shop"
echo "2. Teste a API: https://damafiarevenda.shop/api/health"
echo "3. Teste upload de imagens no sistema"
echo "4. Monitore logs: sudo tail -f /var/log/nginx/damafiarevenda.error.log"

echo "\n🎯 Se tudo estiver funcionando, o erro de upload será resolvido!"