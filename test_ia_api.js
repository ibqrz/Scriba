const https = require('https');

const credentials = {
  username: 'isaias1',
  password: 'isaias1',
  sistemaId: '64b511cc-1392-4d37-85af-9c581961de40'
};

// Função para fazer requisição HTTPS
function httpsRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', chunk => {
        responseData += chunk;
      });

      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: responseData
        });
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function testIAAPI() {
  try {
    console.log('🔐 [TEST] Fazendo login...\n');

    // 1. Login para obter token
    const loginOptions = {
      hostname: 'mobile-ios-login.zani0x03.eti.br',
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const loginResponse = await httpsRequest(loginOptions, credentials);
    
    if (loginResponse.status !== 200) {
      console.error('❌ Erro no login:', loginResponse.status);
      console.error('Body:', loginResponse.body);
      return;
    }

    const loginData = JSON.parse(loginResponse.body);
    const token = loginData.access_token;

    if (!token) {
      console.error('❌ Token não obtido na resposta de login');
      console.error('Response:', loginData);
      return;
    }

    console.log('✅ Login bem-sucedido!');
    console.log(`📍 Token obtido: ${token.substring(0, 50)}...\n`);

    // 2. Testar requisição para IA
    console.log('🤖 [TEST] Enviando requisição para IA...\n');

    const prompt = 'Oi, qual é 1 + 1?';
    const iaPayload = {
      prompt: prompt,
      historia: [
        {
          role: 'user',
          content: 'Olá'
        }
      ],
      titulo: 'Teste'
    };

    const iaOptions = {
      hostname: 'mobile-ios-ia.zani0x03.eti.br',
      path: '/api/ai/chat',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      timeout: 120000 // 120 segundos
    };

    console.log(`📤 Enviando: ${prompt}`);
    console.log(`⏱️  Timeout: 120 segundos\n`);

    const startTime = Date.now();
    const iaResponse = await httpsRequest(iaOptions, iaPayload);
    const elapsedTime = Date.now() - startTime;

    console.log(`⏱️  Tempo de resposta: ${elapsedTime}ms (${(elapsedTime / 1000).toFixed(2)}s)\n`);

    if (iaResponse.status !== 200) {
      console.error(`❌ Erro na requisição (status ${iaResponse.status})`);
      console.error('Response:', iaResponse.body);
      return;
    }

    const iaData = JSON.parse(iaResponse.body);
    console.log('✅ Resposta recebida!');
    console.log('📦 Response completo:');
    console.log(JSON.stringify(iaData, null, 2));

    // Extrair resposta
    const possibleFields = ['message', 'response', 'answer', 'text', 'resultado'];
    let answer = null;

    for (const field of possibleFields) {
      if (iaData[field]) {
        answer = iaData[field];
        break;
      }
    }

    if (answer) {
      console.log('\n💬 Resposta da IA:');
      console.log(`"${answer}"`);
    } else {
      console.log('\n⚠️  Nenhuma resposta encontrada nos campos esperados');
    }

  } catch (error) {
    console.error('❌ Erro ao testar API:', error.message);
    if (error.code === 'ETIMEDOUT') {
      console.error('⚠️  Timeout na requisição (API muito lenta ou indisponível)');
    }
  }
}

testIAAPI();
