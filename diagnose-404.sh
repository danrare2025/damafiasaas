#!/bin/bash

# Script de diagnóstico para problema 404 no damafiarevenda.shop
# Execute: bash diagnose-404.sh

echo "🔍 DIAGNÓSTICO - Problema 404 no damafiarevenda.shop"
echo "================================================="
echo ""

# Verificar se o domínio está acessível
echo "1. 🌐 Testando conectividade do domínio:"
echo "----------------------------------------"
if curl -s -I https://damafiarevenda.shop/ | head -1; then
    echo "✅ Domínio acessível"
else
    echo "❌ Domínio não acessível"
fi
echo ""

# Testar rotas específicas
echo "2. 🔗 Testando rotas SPA:"
echo "-------------------------"
routes=("admin" "login" "catalog" "dashboard" "products")
for route in "${routes[@]}"; do
    echo -n "Testing /$route: "
    status=$(curl -s -o /dev/null -w "%{http_code}" https://damafiarevenda.shop/$route)
    if [ "$status" = "200" ]; then
        echo "✅ $status"
    else
        echo "❌ $status"
    fi
done
echo ""

# Verificar servidor web
echo "3. 🖥️ Identificando servidor web:"
echo "----------------------------------"
server=$(curl -s -I https://damafiarevenda.shop/ | grep -i "server:" || echo "Server header não encontrado")
echo "$server"
echo ""

# Verificar se é Vercel
echo "4. ☁️ Verificando se é Vercel:"
echo "------------------------------"
vercel_headers=$(curl -s -I https://damafiarevenda.shop/ | grep -i "x-vercel\|vercel" || echo "Headers Vercel não encontrados")
if [[ $vercel_headers == *"vercel"* ]]; then
    echo "✅ Hospedado no Vercel"
    echo "$vercel_headers"
else
    echo "❌ Não parece ser Vercel"
fi
echo ""

# Verificar nginx local (se aplicável)
echo "5. 🔧 Verificando nginx local:"
echo "------------------------------"
if command -v nginx &> /dev/null; then
    echo "✅ Nginx instalado"
    echo "Versão: $(nginx -v 2>&1)"
    echo "Status: $(systemctl is-active nginx 2>/dev/null || echo 'não disponível')"
    
    if [ -f "/etc/nginx/sites-available/damafiarevenda.shop" ]; then
        echo "✅ Configuração damafiarevenda.shop encontrada"
    else
        echo "❌ Configuração damafiarevenda.shop não encontrada"
    fi
else
    echo "❌ Nginx não instalado localmente"
fi
echo ""

# Verificar DNS
echo "6. 🌍 Verificando DNS:"
echo "----------------------"
echo "IP do domínio:"
nslookup damafiarevenda.shop | grep "Address:" | tail -1
echo ""

# Verificar certificado SSL
echo "7. 🔒 Verificando SSL:"
echo "----------------------"
ssl_info=$(echo | openssl s_client -servername damafiarevenda.shop -connect damafiarevenda.shop:443 2>/dev/null | openssl x509 -noout -issuer -subject 2>/dev/null || echo "Erro ao verificar SSL")
echo "$ssl_info"
echo ""

# Testar com diferentes User-Agents
echo "8. 🤖 Testando com diferentes User-Agents:"
echo "------------------------------------------"
echo -n "Browser padrão: "
curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" https://damafiarevenda.shop/admin
echo ""
echo -n "Bot/Crawler: "
curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: Googlebot/2.1" https://damafiarevenda.shop/admin
echo ""
echo ""

# Verificar headers de resposta completos
echo "9. 📋 Headers de resposta completos:"
echo "------------------------------------"
curl -s -I https://damafiarevenda.shop/admin
echo ""

echo "🎯 RESUMO DO DIAGNÓSTICO:"
echo "========================="
echo "1. Se o servidor mostrar 'nginx' → Use a configuração nginx.conf"
echo "2. Se mostrar headers do Vercel → O vercel.json já foi simplificado"
echo "3. Se status for 404 em todas as rotas → Problema de configuração SPA"
echo "4. Se status for 200 → Problema pode estar no cache do browser"
echo ""
echo "💡 PRÓXIMOS PASSOS:"
echo "=================="
echo "- Se for nginx: execute 'sudo bash install-nginx-config.sh'"
echo "- Se for Vercel: aguarde o deploy automático do GitHub"
echo "- Limpe o cache do browser (Ctrl+Shift+R)"
echo "- Teste em modo incógnito"
echo ""
echo "📞 Se o problema persistir, compartilhe este diagnóstico!"