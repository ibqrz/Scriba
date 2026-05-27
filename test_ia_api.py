import requests
import json
import time
from datetime import datetime

# Credenciais
credentials = {
    "username": "isaias1",
    "password": "isaias1",
    "sistemaId": "64b511cc-1392-4d37-85af-9c581961de40"
}

print("🔐 [TEST] Fazendo login...\n")

try:
    # 1. Login para obter token
    login_url = "https://mobile-ios-login.zani0x03.eti.br/api/auth/login"
    login_response = requests.post(login_url, json=credentials, timeout=10)
    
    if login_response.status_code != 200:
        print(f"❌ Erro no login (status {login_response.status_code})")
        print(f"Response: {login_response.text}")
        exit(1)
    
    login_data = login_response.json()
    token = login_data.get("access_token")
    
    if not token:
        print("❌ Token não obtido na resposta de login")
        print(f"Response: {json.dumps(login_data, indent=2)}")
        exit(1)
    
    print("✅ Login bem-sucedido!")
    print(f"📍 Token obtido: {token[:50]}...\n")
    
    # 2. Testar requisição para IA
    print("🤖 [TEST] Enviando requisição para IA...\n")
    
    prompt = "Oi, qual é 1 + 1?"
    ia_payload = {
        "prompt": prompt,
        "history": [
            {
                "role": "user",
                "content": "Olá"
            }
        ],
        "titulo": "Teste"
    }
    
    ia_url = "https://mobile-ios-ia.zani0x03.eti.br/api/ai/chat"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    
    print(f"📤 Enviando: {prompt}")
    print(f"⏱️  Timeout: 120 segundos\n")
    
    start_time = time.time()
    ia_response = requests.post(ia_url, json=ia_payload, headers=headers, timeout=120)
    elapsed_time = time.time() - start_time
    
    print(f"⏱️  Tempo de resposta: {elapsed_time:.2f}s ({int(elapsed_time*1000)}ms)\n")
    
    if ia_response.status_code != 200:
        print(f"❌ Erro na requisição (status {ia_response.status_code})")
        print(f"Response: {ia_response.text}")
        exit(1)
    
    ia_data = ia_response.json()
    print("✅ Resposta recebida!")
    print("📦 Response completo:")
    print(json.dumps(ia_data, indent=2, ensure_ascii=False))
    
    # Extrair resposta
    possible_fields = ['message', 'response', 'answer', 'text', 'resultado']
    answer = None
    
    for field in possible_fields:
        if field in ia_data and ia_data[field]:
            answer = ia_data[field]
            break
    
    if answer:
        print("\n💬 Resposta da IA:")
        print(f'"{answer}"')
    else:
        print("\n⚠️  Nenhuma resposta encontrada nos campos esperados")
        print(f"Campos disponíveis: {list(ia_data.keys())}")

except requests.exceptions.Timeout:
    print("❌ Timeout na requisição (API muito lenta ou indisponível)")
    print("⏱️  Limite de 120 segundos excedido")
except requests.exceptions.ConnectionError as e:
    print(f"❌ Erro de conexão: {str(e)}")
except json.JSONDecodeError:
    print("❌ Erro ao decodificar resposta JSON")
except Exception as e:
    print(f"❌ Erro: {str(e)}")
