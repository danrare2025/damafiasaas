# 🚀 Instruções para Deploy e Correção do Erro 404

## Problema Identificado
O erro **404 Not Found** no nginx quando você atualiza (F5) ou acessa diretamente URLs como `/admin` ou `/login` no domínio `damafiarevenda.shop` acontece porque:

1. **SPA (Single Page Application)**: O React Router gerencia as rotas no lado do cliente
2. **Servidor não configurado**: O nginx não sabe que deve servir o `index.html` para todas as rotas
3. **Falta de configuração de fallback**: Quando o servidor não encontra um arquivo físico para `/admin`, retorna 404

## ✅ Soluções Disponíveis

### Opção 1: Configuração Nginx (Recomendada)

1. **Faça backup da configuração atual**:
   ```bash
   sudo cp /etc/nginx/sites-available/damafiarevenda.shop /etc/nginx/sites-available/damafiarevenda.shop.backup
   ```

2. **Substitua a configuração** pelo arquivo `nginx.conf` fornecido:
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/damafiarevenda.shop
   ```

3. **Ajuste os caminhos no arquivo**:
   - Edite `/etc/nginx/sites-available/damafiarevenda.shop`
   - Altere `root /var/www/damafiarevenda.shop/frontend/dist;` para o caminho correto dos seus arquivos
   - Ajuste os caminhos dos certificados SSL

4. **Teste a configuração**:
   ```bash
   sudo nginx -t
   ```

5. **Recarregue o nginx**:
   ```bash
   sudo systemctl reload nginx
   ```

### Opção 2: Configuração Apache (.htaccess)

Se você estiver usando Apache em vez de nginx:

1. **Copie o arquivo `.htaccess`** para a pasta raiz do seu site:
   ```bash
   cp .htaccess /var/www/damafiarevenda.shop/
   ```

2. **Certifique-se que mod_rewrite está habilitado**:
   ```bash
   sudo a2enmod rewrite
   sudo systemctl restart apache2
   ```

### Opção 3: Deploy via Vercel (Mais Simples)

1. **Conecte seu repositório ao Vercel**:
   - Acesse [vercel.com](https://vercel.com)
   - Importe o repositório `danrare2025/damafiasaas`
   - O `vercel.json` já está configurado corretamente

2. **Configure o domínio customizado**:
   - No dashboard do Vercel, vá em Settings > Domains
   - Adicione `damafiarevenda.shop`
   - Configure os DNS conforme instruções do Vercel

## 🔧 Configurações Importantes

### A linha mais importante para SPAs:
```nginx
# Nginx
try_files $uri $uri/ /index.html;
```

```apache
# Apache
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

Esta configuração diz ao servidor: "Se não encontrar o arquivo solicitado, sirva o index.html"

### Estrutura de Arquivos Esperada:
```
/var/www/damafiarevenda.shop/
├── index.html          # Arquivo principal do React
├── assets/            # CSS, JS, imagens
│   ├── index-xxx.js
│   ├── index-xxx.css
│   └── ...
└── .htaccess          # Se usando Apache
```

## 🚀 Processo de Build e Deploy

### 1. Build do Frontend:
```bash
cd frontend
npm run build
```

### 2. Upload dos Arquivos:
```bash
# Copiar arquivos buildados para o servidor
scp -r frontend/dist/* user@damafiarevenda.shop:/var/www/damafiarevenda.shop/
```

### 3. Configurar Permissões:
```bash
sudo chown -R www-data:www-data /var/www/damafiarevenda.shop/
sudo chmod -R 755 /var/www/damafiarevenda.shop/
```

## 🔍 Teste da Configuração

Após aplicar as configurações, teste:

1. **Acesso direto às rotas**:
   - `https://damafiarevenda.shop/admin` ✅
   - `https://damafiarevenda.shop/login` ✅
   - `https://damafiarevenda.shop/reseller` ✅

2. **Atualização da página (F5)** em qualquer rota ✅

3. **Navegação pelo histórico do browser** ✅

## 🆘 Troubleshooting

### Se ainda der 404:

1. **Verifique os logs do nginx**:
   ```bash
   sudo tail -f /var/log/nginx/damafiarevenda.shop.error.log
   ```

2. **Confirme o caminho dos arquivos**:
   ```bash
   ls -la /var/www/damafiarevenda.shop/
   ```

3. **Teste a configuração do nginx**:
   ```bash
   sudo nginx -t
   ```

4. **Verifique se o index.html existe**:
   ```bash
   curl -I https://damafiarevenda.shop/index.html
   ```

### Se der erro de permissão:
```bash
sudo chown -R www-data:www-data /var/www/damafiarevenda.shop/
sudo chmod -R 755 /var/www/damafiarevenda.shop/
```

## 📝 Resumo

O problema é que SPAs como React precisam que o servidor sempre sirva o `index.html` para rotas que não existem fisicamente. A configuração correta do nginx ou Apache resolve isso completamente.

**Arquivos criados para você**:
- `nginx.conf` - Configuração completa para nginx
- `.htaccess` - Configuração para Apache
- `DEPLOY_INSTRUCTIONS.md` - Este guia

Escolha a opção que corresponde ao seu servidor e siga as instruções. O erro 404 será resolvido! 🎉