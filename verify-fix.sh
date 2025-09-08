#!/bin/bash

# Script para verificar se a correção do nginx funcionou
# Execute este script após aplicar fix-nginx-production.sh

echo "🔍 Verificando se a correção do nginx funcionou..."
echo "================================================"

# Função para testar endpoint
test_endpoint() {
    local url=$1
    local name=$2
    
    echo -n "Testando $name: "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ] || [ "$response" = "404" ] && [[ "$url" == *"/api/"* ]]; then
        if [[ "$url" == *"/api/"* ]] && [ "$response" = "404" ]; then
            echo "❌ FALHOU ($response) - API ainda retorna 404"
            return 1
        else
            echo "✅ OK ($response)"
            return 0
        fi
    else
        echo "❌ FALHOU ($response)"
        return 1
    fi
}

# Testes locais (no servidor)
echo "\n📍 TESTES LOCAIS (no servidor):"
test_endpoint "http://localhost" "Site principal (HTTP)"
test_endpoint "http://localhost/api/health" "API Health (HTTP)"
test_endpoint "http://localhost/api/products" "API Products (HTTP)"

# Testes externos
echo "\n🌐 TESTES EXTERNOS:"
test_endpoint "https://damafiarevenda.shop" "Site principal (HTTPS)"
test_endpoint "https://damafiarevenda.shop/api/health" "API Health (HTTPS)"
test_endpoint "https://damafiarevenda.shop/api/products" "API Products (HTTPS)"

# Verificar se backend está rodando
echo "\n🔧 VERIFICAÇÕES DO SISTEMA:"
echo -n "Backend na porta 3002: "
if netstat -tlnp | grep :3002 > /dev/null 2>&1; then
    echo "✅ Rodando"
else
    echo "❌ NÃO está rodando!"
    echo "   Execute: cd /path/to/backend && npm start"
fi

# Verificar nginx
echo -n "Status do Nginx: "
if systemctl is-active --quiet nginx; then
    echo "✅ Ativo"
else
    echo "❌ Inativo"
fi

# Verificar configuração do nginx
echo -n "Configuração do Nginx: "
if nginx -t > /dev/null 2>&1; then
    echo "✅ Válida"
else
    echo "❌ Inválida"
fi

# Verificar logs recentes
echo "\n📋 LOGS RECENTES DO NGINX:"
echo "Últimas 5 linhas do error.log:"
tail -5 /var/log/nginx/error.log 2>/dev/null || echo "Arquivo de log não encontrado"

# Teste específico de upload
echo "\n📤 TESTE DE UPLOAD (simulação):"
echo "Testando endpoint de upload..."
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://damafiarevenda.shop/api/upload/files" 2>/dev/null)
if [ "$response" = "401" ] || [ "$response" = "403" ]; then
    echo "✅ Endpoint de upload acessível (retornou $response - esperado sem token)"
elif [ "$response" = "404" ]; then
    echo "❌ Endpoint de upload ainda retorna 404 - nginx não configurado corretamente"
else
    echo "⚠️ Endpoint de upload retornou $response - verificar implementação"
fi

# Resumo final
echo "\n📊 RESUMO:"
echo "================================================"

# Contar sucessos
api_working=0
if curl -s -o /dev/null -w "%{http_code}" "https://damafiarevenda.shop/api/health" 2>/dev/null | grep -q "200\|401\|403"; then
    api_working=1
fi

site_working=0
if curl -s -o /dev/null -w "%{http_code}" "https://damafiarevenda.shop" 2>/dev/null | grep -q "200"; then
    site_working=1
fi

if [ $api_working -eq 1 ] && [ $site_working -eq 1 ]; then
    echo "🎉 SUCESSO! A correção funcionou!"
    echo "✅ Site principal: Funcionando"
    echo "✅ API: Funcionando"
    echo "✅ Upload deve estar funcionando agora"
    echo ""
    echo "🎯 Próximos passos:"
    echo "1. Teste o upload de imagens no sistema"
    echo "2. Verifique se o erro 'Upload error: Error: Erro no upload' desapareceu"
    echo "3. Monitore os logs por alguns minutos"
elif [ $site_working -eq 1 ] && [ $api_working -eq 0 ]; then
    echo "⚠️ PARCIALMENTE CORRIGIDO"
    echo "✅ Site principal: Funcionando"
    echo "❌ API: Ainda com problema"
    echo ""
    echo "🔧 Ações necessárias:"
    echo "1. Verificar se o backend está rodando: netstat -tlnp | grep :3002"
    echo "2. Verificar logs do nginx: tail -f /var/log/nginx/error.log"
    echo "3. Reiniciar nginx: sudo systemctl restart nginx"
    echo "4. Verificar configuração: nginx -t"
else
    echo "❌ PROBLEMA PERSISTE"
    echo "❌ Site e/ou API ainda não funcionam"
    echo ""
    echo "🆘 Ações de emergência:"
    echo "1. Verificar se o servidor web está rodando"
    echo "2. Verificar DNS: nslookup damafiarevenda.shop"
    echo "3. Verificar firewall e portas"
    echo "4. Contatar administrador do servidor"
fi

echo "\n📞 Para suporte, envie os logs acima junto com:"
echo "- Saída de: nginx -t"
echo "- Saída de: systemctl status nginx"
echo "- Saída de: netstat -tlnp | grep -E ':(80|443|3002)'"
echo "- Conteúdo de: /var/log/nginx/error.log (últimas 20 linhas)"