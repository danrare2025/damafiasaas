# 🚨 SOLUÇÃO PARA PROBLEMA DE UPLOAD EM PRODUÇÃO

## ❌ PROBLEMA IDENTIFICADO

**Status:** O frontend está funcionando, mas a API não está acessível
- ✅ Site principal: `https://damafiarevenda.shop` - **FUNCIONANDO**
- ❌ API: `https://damafiarevenda.shop/api/*` - **404 Not Found (nginx)**

## 🔍 DIAGNÓSTICO COMPLETO

### Testes Realizados:
1. **Conectividade:** ✅ Servidor responde (212.85.21.129)
2. **Portas:** ✅ 80 e 443 abertas
3. **Frontend:** ✅ Carregando corretamente
4. **API:** ❌ Nginx retorna 404 para todas as rotas `/api/*`

### Causa Raiz:
**O nginx não está configurado para fazer proxy das requisições da API para o backend Node.js**

## 🛠️ SOLUÇÕES NECESSÁRIAS

### 1. CONFIGURAR NGINX (URGENTE)

O arquivo `nginx.conf` que criamos precisa ser aplicado no servidor:

```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name damafiarevenda.shop;
    
    # Certificados SSL (se aplicável)
    # ssl_certificate /path/to/certificate.crt;
    # ssl_certificate_key /path/to/private.key;
    
    # Servir arquivos estáticos do frontend
    location / {
        root /var/www/damafiarevenda;
        try_files $uri $uri/ /index.html;
    }
    
    # Proxy para API do backend
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
    }
    
    # Servir uploads
    location /uploads/ {
        root /var/www/damafiarevenda/backend;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 2. VERIFICAR BACKEND

Verificar se o backend está rodando na porta 3002:

```bash
# No servidor de produção
sudo netstat -tlnp | grep :3002
# ou
sudo ss -tlnp | grep :3002
```

### 3. COMANDOS PARA APLICAR NO SERVIDOR

```bash
# 1. Backup da configuração atual
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# 2. Aplicar nova configuração
sudo nano /etc/nginx/sites-available/default
# (colar a configuração acima)

# 3. Testar configuração
sudo nginx -t

# 4. Recarregar nginx
sudo systemctl reload nginx

# 5. Verificar status
sudo systemctl status nginx
```

### 4. VERIFICAR BACKEND RODANDO

```bash
# Verificar se o processo está rodando
ps aux | grep node

# Se não estiver rodando, iniciar:
cd /path/to/backend
npm start

# Ou usar PM2 (recomendado para produção):
pm2 start npm --name "damafia-backend" -- start
pm2 save
pm2 startup
```

## 🧪 TESTES APÓS CORREÇÃO

Após aplicar as correções, testar:

```bash
# 1. Testar API health
curl https://damafiarevenda.shop/api/health

# 2. Testar endpoint de produtos
curl https://damafiarevenda.shop/api/products

# 3. Testar upload (com token válido)
curl -X POST https://damafiarevenda.shop/api/upload/files \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-image.jpg"
```

## 📋 CHECKLIST DE VERIFICAÇÃO

- [ ] Nginx configurado com proxy para `/api/`
- [ ] Backend rodando na porta 3002
- [ ] Nginx recarregado (`sudo systemctl reload nginx`)
- [ ] API health respondendo: `https://damafiarevenda.shop/api/health`
- [ ] Endpoints de produtos funcionando
- [ ] Upload de arquivos funcionando
- [ ] Logs do nginx sem erros: `sudo tail -f /var/log/nginx/error.log`
- [ ] Logs do backend sem erros

## 🚀 RESULTADO ESPERADO

Após aplicar essas correções:
- ✅ Upload de imagens funcionará
- ✅ Todas as requisições da API funcionarão
- ✅ Erro "Upload error: Error: Erro no upload" será resolvido

## 📞 PRÓXIMOS PASSOS

1. **URGENTE:** Aplicar configuração do nginx no servidor
2. Verificar se backend está rodando
3. Testar upload de imagens
4. Monitorar logs para garantir estabilidade

---

**Nota:** O problema NÃO é no código frontend/backend, mas sim na configuração do servidor web (nginx) que não está fazendo o proxy das requisições da API.