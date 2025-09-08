# Configurações de Produção - Resolver 404 no damafiarevenda.shop

## ✅ Configurações Aplicadas

As seguintes configurações foram implementadas para resolver o problema de 404 no nginx:

### 1. Vercel.json Atualizado
- ✅ Configuração de rewrites para SPA routing
- ✅ Headers de segurança adicionados
- ✅ Cache otimizado para assets estáticos

### 2. Vite.config.js Otimizado
- ✅ Base URL configurada para produção
- ✅ Manifest gerado para melhor cache
- ✅ Assets organizados corretamente

### 3. _redirects para Netlify
- ✅ Arquivo criado em `frontend/public/_redirects`
- ✅ Configuração completa para SPA routing
- ✅ Headers de segurança incluídos

## 🚀 Como Aplicar no Servidor

### Opção 1: Vercel (Recomendado)
```bash
# As configurações já estão no vercel.json
# O deploy automático aplicará as mudanças
```

### Opção 2: Nginx Manual
```bash
# Copiar configuração nginx
sudo cp nginx.conf /etc/nginx/sites-available/damafiarevenda.shop
sudo ln -sf /etc/nginx/sites-available/damafiarevenda.shop /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Recarregar nginx
sudo systemctl reload nginx
```

### Opção 3: Apache
```bash
# Copiar .htaccess para o diretório web
cp .htaccess /var/www/damafiarevenda.shop/

# Reiniciar Apache
sudo systemctl restart apache2
```

## 🔧 Verificações Pós-Deploy

1. **Teste de Roteamento SPA:**
   ```bash
   curl -I https://damafiarevenda.shop/admin
   curl -I https://damafiarevenda.shop/login
   curl -I https://damafiarevenda.shop/catalog
   ```

2. **Teste de API:**
   ```bash
   curl -I https://damafiarevenda.shop/api/public/brand
   ```

3. **Teste no Navegador:**
   - Acesse https://damafiarevenda.shop/admin
   - Pressione F5 (deve funcionar sem 404)
   - Navegue entre páginas
   - Use botões voltar/avançar do navegador

## 📋 Checklist de Verificação

- [ ] Deploy realizado com sucesso
- [ ] Rota `/admin` funciona
- [ ] Rota `/login` funciona
- [ ] Rota `/catalog` funciona
- [ ] F5 não gera 404
- [ ] Navegação por histórico funciona
- [ ] API `/api/*` funciona
- [ ] Assets estáticos carregam
- [ ] Headers de segurança aplicados

## 🆘 Troubleshooting

### Se ainda houver 404:
1. Verificar se o build foi feito corretamente
2. Confirmar se os arquivos estão no diretório correto
3. Verificar logs do servidor web
4. Testar configuração nginx: `sudo nginx -t`

### Comandos de Debug:
```bash
# Verificar status do nginx
sudo systemctl status nginx

# Ver logs de erro
sudo tail -f /var/log/nginx/error.log

# Verificar configuração ativa
sudo nginx -T
```

## 📞 Suporte

Se o problema persistir:
1. Verificar se o domínio está apontando corretamente
2. Confirmar se o SSL está configurado
3. Testar com `curl -v` para ver headers completos
4. Verificar se há cache do CDN interferindo

---

**Status:** ✅ Configurações aplicadas e commitadas
**Próximo passo:** Deploy automático via GitHub → Vercel