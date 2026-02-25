/**
 * Google Apps Script para Movel Tracker
 * Permite escrita direta de fotos na planilha Google Sheets
 *
 * INSTALAÇÃO:
 * 1. Vá em https://script.google.com/
 * 2. Clique em "Novo projeto"
 * 3. Cole este código em "Código.gs"
 * 4. Salve o projeto
 * 5. Clique em "Implantação" → "Nova implantação"
 * 6. Selecione "Aplicativo Web"
 * 7. Configurações:
 *    - Descrição: Movel Tracker Image Upload
 *    - Executar como: Minha conta
 *    - Quem tem acesso: Qualquer pessoa
 * 8. Clique em "Implantar"
 * 9. Copie a URL do aplicativo Web (termina com /exec)
 * 10. Cole a URL no arquivo cloudinary_config.dart do Flutter
 *
 * URL do script será algo como:
 * https://script.google.com/macros/s/XXXXXXXXXXXXXXXXXXXXXXXX/exec
 *
 * TESTES:
 * - testConfiguration(): Verifica se planilha e colunas estão corretas
 * - testDoPost(): Simula uma requisição POST de teste
 * - doGet(): Acesse a URL no navegador para ver os dados da planilha
 */

// ID da planilha (substitua pelo ID da sua planilha)
const SPREADSHEET_ID = '1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc';

// Nome da aba da planilha
const SHEET_NAME = 'DIVISÃO DE SITES MARANHÃO FEV 2026.CSV';

// Lista de colunas de fotos
const PHOTO_COLUMNS = [
  'foto_1',
  'foto_2',
  'foto_3',
  'foto_4',
  'foto_5'
];

/**
 * Handler para requisição POST do aplicativo Flutter
 * Recebe dados no formato JSON:
 * {
 *   "site_id": "SLZ001",
 *   "imageUrls": ["url1", "url2", "url3"]
 * }
 */
function doPost(e) {
  Logger.log('=== doPost chamada ===');
  Logger.log('Evento e: ' + JSON.stringify(e));

  // Verifica se e está definido
  if (!e) {
    Logger.log('ERRO: Evento e é undefined/null');
    return ContentService.createTextOutput(
      JSON.stringify({
        success: false,
        message: 'Erro: Evento não recebido. Use requisição HTTP POST.'
      })
    ).setMimeType(ContentService.MimeType.JSON);
  }

  // Verifica se postData existe
  if (!e.postData) {
    Logger.log('ERRO: e.postData é undefined/null');
    Logger.log('Conteúdo completo do evento: ' + JSON.stringify(e));
    return ContentService.createTextOutput(
      JSON.stringify({
        success: false,
        message: 'Erro: postData não encontrado. Verifique Content-Type: application/json'
      })
    ).setMimeType(ContentService.MimeType.JSON);
  }

  // Log dos dados recebidos
  Logger.log('postData.contents: ' + e.postData.contents);

  try {
    const data = JSON.parse(e.postData.contents);
    const siteId = data.site_id;
    const imageUrls = data.imageUrls || [];

    Logger.log('site_id recebido: ' + siteId);
    Logger.log('imageUrls recebidas: ' + JSON.stringify(imageUrls));

    // Atualiza as fotos na planilha
    updateSitePhotos(siteId, imageUrls);

    Logger.log('=== doPost finalizada com sucesso ===');
    return ContentService.createTextOutput(
      JSON.stringify({
        success: true,
        message: 'Fotos atualizadas com sucesso',
        updated_image_count: imageUrls.length
      })
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    Logger.log('ERRO ao processar requisição: ' + error);
    Logger.log('Stack trace: ' + error.stack);
    return ContentService.createTextOutput(
      JSON.stringify({
        success: false,
        message: 'Erro: ' + error.message
      })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Função para TESTAR o doPost manualmente
 * Execute esta função no editor do Apps Script clicando em "Executar"
 */
function testDoPost() {
  // Simula uma requisição POST
  const mockEvent = {
    postData: {
      contents: JSON.stringify({
        site_id: 'SLZ001',
        imageUrls: [
          'https://res.cloudinary.com/dz9mdzht8/image/upload/test1.jpg',
          'https://res.cloudinary.com/dz9mdzht8/image/upload/test2.jpg'
        ]
      })
    }
  };

  // Chama a função doPost com o evento simulado
  const result = doPost(mockEvent);
  Logger.log('Resultado do teste: ' + result.getContent());
}

/**
 * Função para verificar a configuração do script
 * Execute esta função no editor do Apps Script para verificar se tudo está correto
 */
function testConfiguration() {
  Logger.log('=== Verificando configuração ===');

  // Verifica se a planilha existe
  try {
    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    Logger.log('✓ Planilha encontrada: ' + ss.getName());

    // Verifica se a aba existe
    const sheet = ss.getSheetByName(SHEET_NAME);
    if (sheet) {
      Logger.log('✓ Aba encontrada: ' + SHEET_NAME);
      Logger.log('  - Linhas: ' + sheet.getLastRow());
      Logger.log('  - Colunas: ' + sheet.getLastColumn());
    } else {
      Logger.log('✗ Aba NÃO encontrada: ' + SHEET_NAME);
      Logger.log('  Abas disponíveis: ' + ss.getSheets().map(s => s.getName()).join(', '));
    }

    // Verifica as colunas de foto
    if (sheet) {
      const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
      Logger.log('=== Colunas encontradas ===');
      PHOTO_COLUMNS.forEach(colName => {
        const index = headers.indexOf(colName);
        if (index >= 0) {
          Logger.log('✓ ' + colName + ' está na coluna ' + (index + 1));
        } else {
          Logger.log('✗ ' + colName + ' NÃO encontrada!');
        }
      });
    }

    // Verifica se existe algum site para testar
    if (sheet && sheet.getLastRow() > 1) {
      const firstSiteId = sheet.getRange(2, 1).getValue();
      Logger.log('✓ Site para teste encontrado: ' + firstSiteId);
    } else {
      Logger.log('✗ Nenhum site encontrado na planilha');
    }

  } catch (error) {
    Logger.log('✗ ERRO ao acessar planilha: ' + error);
  }

  Logger.log('=== Configuração finalizada ===');
}

/**
 * Atualiza as URLs de fotos de um site na planilha
 */
function updateSitePhotos(siteId, imageUrls) {
  Logger.log('=== updateSitePhotos iniciada ===');
  Logger.log('Procurando site_id: "' + siteId + '"');

  const ss = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);

  if (!ss) {
    throw new Error('Aba não encontrada: ' + SHEET_NAME);
  }

  // Encontra a linha do site pelo site_id
  const data = ss.getDataRange().getValues();
  const headers = data[0]; // Primeira linha contém os cabeçalhos

  Logger.log('Total de linhas na planilha: ' + data.length);
  Logger.log('Cabeçalho da primeira coluna: "' + headers[0] + '"');

  let rowIndex = -1;
  const siteIdColumnIndex = 0; // site_id é a primeira coluna

  // Lista todos os site_ids encontrados para debug
  const foundSiteIds = [];
  for (let i = 1; i < data.length; i++) { // Começa de 1 para pular cabeçalho
    const currentSiteId = data[i][siteIdColumnIndex];
    foundSiteIds.push('Linha ' + (i+1) + ': "' + currentSiteId + '"');

    // Compara de forma mais flexível (remove espaços, case-insensitive)
    const searchId = String(siteId).trim().toLowerCase();
    const currentId = String(currentSiteId || '').trim().toLowerCase();

    if (currentId === searchId) {
      rowIndex = i + 1; // +1 porque getRange usa índice 1-based
      Logger.log('✓ Site encontrado na linha ' + rowIndex + ' (original: "' + currentSiteId + '")');
      break;
    }
  }

  if (rowIndex === -1) {
    Logger.log('✗ Site NÃO encontrado: "' + siteId + '"');
    Logger.log('Site_ids encontrados na planilha:');
    foundSiteIds.forEach(id => Logger.log('  - ' + id));
    throw new Error('Site não encontrado: ' + siteId);
  }

  // Encontra os índices das colunas de foto
  const photoColumnIndices = PHOTO_COLUMNS.map(colName => {
    const index = headers.indexOf(colName);
    if (index === -1) {
      Logger.log('Aviso: Coluna "' + colName + '" não encontrada na planilha');
    } else {
      Logger.log('Coluna "' + colName + '" encontrada no índice ' + index);
    }
    return index + 1; // +1 porque getRange usa índice 1-based
  });

  // Atualiza as colunas de foto
  for (let i = 0; i < PHOTO_COLUMNS.length; i++) {
    const colIndex = photoColumnIndices[i];
    if (colIndex > 0) { // Coluna existe
      const range = ss.getRange(rowIndex, colIndex);
      if (imageUrls[i] !== undefined && imageUrls[i] !== '') {
        range.setValue(imageUrls[i]);
        Logger.log('Atualizado: Linha ' + rowIndex + ', Coluna ' + colIndex + ' = ' + imageUrls[i]);
      } else {
        range.setValue(''); // Remove foto se não houver URL
      }
    } else {
      Logger.log('Pulando coluna não encontrada: ' + PHOTO_COLUMNS[i]);
    }
  }

  // Força atualização imediata da planilha
  SpreadsheetApp.flush();
  Logger.log('=== updateSitePhotos finalizada com sucesso ===');
}

/**
 * Lista todos os site_ids da planilha
 * Execute esta função para ver quais sites existem na planilha
 */
function listAllSiteIds() {
  Logger.log('=== Listando todos os site_ids ===');

  try {
    const ss = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);
    if (!ss) {
      Logger.log('✗ Aba não encontrada: ' + SHEET_NAME);
      return;
    }

    const data = ss.getDataRange().getValues();
    Logger.log('Total de linhas: ' + data.length);

    for (let i = 1; i < data.length; i++) {
      const siteId = data[i][0];
      const sigla = data[i][1];
      const nome = data[i][2];
      Logger.log('Linha ' + (i+1) + ': site_id="' + siteId + '", sigla="' + sigla + '", nome="' + nome + '"');
    }

    Logger.log('=== Total de sites: ' + (data.length - 1) + ' ===');
  } catch (error) {
    Logger.log('✗ ERRO: ' + error);
  }
}

/**
 * Endpoint para testes - retorna dados da planilha
 * Teste acessando: https://script.google.com/macros/s/SEU_ID/exec?site_id=SLZ001
 */
function doGet(e) {
  Logger.log('=== doGet chamada ===');

  try {
    const ss = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);
    const data = ss.getDataRange().getValues();

    // Se tiver parâmetro site_id, retorna apenas esse site
    if (e && e.parameter && e.parameter.site_id) {
      const requestedSiteId = e.parameter.site_id;

      for (let i = 1; i < data.length; i++) {
        if (data[i][0] == requestedSiteId) {
          const row = data[i];
          const site = {
            site_id: row[0],
            sigla: row[1],
            nome: row[2],
            endereco: row[3],
            municipio: row[4],
            tecnico: row[5],
            latitude: row[6],
            longitude: row[7],
            detentora: row[8],
            uc: row[9],
            status: row[10],
            foto_1: row[11] || '',
            foto_2: row[12] || '',
            foto_3: row[13] || '',
            foto_4: row[14] || '',
            foto_5: row[15] || '',
          };
          Logger.log('Site encontrado: ' + requestedSiteId);
          return ContentService.createTextOutput(JSON.stringify({
            success: true,
            site: site
          })).setMimeType(ContentService.MimeType.JSON);
        }
      }

      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        message: 'Site não encontrado: ' + requestedSiteId
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Se não tiver parâmetro, retorna todos os sites
    const sites = [];
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      if (row[0] === '') continue; // Ignora linhas vazias

      const site = {
        site_id: row[0],
        sigla: row[1],
        nome: row[2],
        endereco: row[3],
        municipio: row[4],
        tecnico: row[5],
        latitude: row[6],
        longitude: row[7],
        detentora: row[8],
        uc: row[9],
        status: row[10],
        foto_1: row[11] || '',
        foto_2: row[12] || '',
        foto_3: row[13] || '',
        foto_4: row[14] || '',
        foto_5: row[15] || '',
      };
      sites.push(site);
    }

    Logger.log('=== doGet retornando ' + sites.length + ' sites ===');
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      sites: sites,
      total: sites.length
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    Logger.log('ERRO no doGet: ' + error);
    Logger.log('Stack trace: ' + error.stack);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Erro: ' + error.message
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Handler para requisição OPTIONS (necessário para CORS)
 * Nota: Google Apps Script lida com CORS automaticamente para requisições
 * que não verificam CORS preflight (como POST simples sem headers customizados)
 */
function doOptions(e) {
  Logger.log('=== doOptions chamada ===');
  return ContentService.createTextOutput(
    JSON.stringify({ success: true })
  ).setMimeType(ContentService.MimeType.JSON);
}
