# 🚨 INSTRUÇÕES URGENTES PARA SERVIDOR DE PRODUÇÃO

## ❌ PROBLEMA ATUAL
Os erros `net::ERR_ABORTED` e `Error: 请求超时: /api/webviewClick` continuam porque:
- O nginx no servidor de produção **NÃO está configurado** para fazer proxy da API
- Todas as requisições `/api/*` retornam 404 Not Found

## 🎯 SOLUÇÃO IMEDIATA

### 1. ACESSE O SERVIDOR DE PRODUÇÃO
```bash
# SSH para o servidor onde está hospedado damafiarevenda.shop
ssh usuario@212.85.21.129
# ou use o painel de controle da hospedagem
```

### 2. APLICAR CONFIGURAÇÃO DO NGINX

**Opção A - Usar o script automatizado:**
```bash
# Baixar o script
wget https://raw.githubusercontent.com/danrare2025/damafiasaas/main/fix-nginx-production.sh

# Dar permissão
chmod +x fix-nginx-production.sh

# Executar
sudo ./fix-nginx-production.sh
```

**Opção B - Configuração manual:**
```bash
# 1. Backup da configuração atual
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# 2. Editar configuração
sudo nano /etc/nginx/sites-available/default
```

**Cole esta configuração:**
```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name damafiarevenda.shop www.damafiarevenda.shop;
    
    # Certificados SSL (ajustar conforme necessário)
    ssl_certificate /etc/ssl/certs/damafiarevenda.shop.crt;
    ssl_certificate_key /etc/ssl/private/damafiarevenda.shop.key;
    
    # Frontend - arquivos estáticos
    location / {
        root /var/www/damafiarevenda;
        try_files $uri $uri/ /index.html;
    }
    
    # ⭐ CONFIGURAÇÃO CRÍTICA - PROXY PARA API
    location /api/ {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    }
    
    # Uploads
    location /uploads/ {
        root /var/www/damafiarevenda/backend;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 3. APLICAR CONFIGURAÇÃO
```bash
# Testar configuração
sudo nginx -t

# Se OK, recarregar
sudo systemctl reload nginx

# Verificar status
sudo systemctl status nginx
```

### 4. VERIFICAR BACKEND
```bash
# Verificar se backend está rodando na porta 3002
sudo netstat -tlnp | grep :3002

# Se não estiver rodando:
cd /caminho/para/backend
npm start

# Ou usar PM2 (recomendado):
pm2 start npm --name "damafia-backend" -- start
pm2 save
```

### 5. TESTAR CORREÇÃO
```bash
# Testar API localmente no servidor
curl http://localhost/api/health

# Testar externamente
curl https://damafiarevenda.shop/api/health
```

## 🔍 VERIFICAÇÃO RÁPIDA

**Execute no servidor:**
```bash
# Verificar se nginx está configurado corretamente
grep -n "location /api/" /etc/nginx/sites-available/default

# Deve retornar algo como:
# 25:    location /api/ {

# Se não retornar nada, a configuração não foi aplicada!
```

## 📱 PARA PAINÉIS DE CONTROLE (cPanel, Plesk, etc.)

Se você usa painel de controle:

1. **Acesse as configurações do nginx/Apache**
2. **Adicione regra de proxy reverso:**
   - Origem: `/api/`
   - Destino: `http://localhost:3002`
3. **Salve e recarregue o servidor web**

## 🚨 URGENTE - CHECKLIST

- [ ] Acessei o servidor de produção
- [ ] Configurei nginx com proxy para `/api/` → `localhost:3002`
- [ ] Testei: `nginx -t` (sem erros)
- [ ] Recarreguei: `systemctl reload nginx`
- [ ] Backend rodando na porta 3002
- [ ] Testei: `curl https://damafiarevenda.shop/api/health`
- [ ] API retorna resposta (não 404)

## ✅ RESULTADO ESPERADO

Após aplicar a configuração:
- ✅ `https://damafiarevenda.shop/api/health` funcionará
- ✅ Upload de imagens funcionará
- ✅ Erros `net::ERR_ABORTED` desaparecerão
- ✅ Erro `请求超时: /api/webviewClick` será resolvido

## 🆘 SE AINDA NÃO FUNCIONAR

1. **Verificar logs:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Verificar portas:**
   ```bash
   sudo netstat -tlnp | grep -E ':(80|443|3002)'
   ```

3. **Reiniciar serviços:**
   ```bash
   sudo systemctl restart nginx
   sudo systemctl restart backend-service  # se usando systemd
   ```

---

**⚠️ IMPORTANTE:** Esta configuração deve ser aplicada **NO SERVIDOR DE PRODUÇÃO** onde está hospedado `damafiarevenda.shop`, não no seu computador local!

**📞 Precisa de ajuda?** Envie:
- Saída de: `nginx -t`
- Saída de: `systemctl status nginx`
- Conteúdo de: `/var/log/nginx/error.log`