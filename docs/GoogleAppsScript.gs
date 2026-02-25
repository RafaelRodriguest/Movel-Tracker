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
 * 6. Clique em "Configurações" → "Adicionar gatilho"
 * 7. Copie a URL do aplicativo Web
 * 8. Cole a URL no arquivo cloudinary_config.dart do Flutter
 *
 * URL do script será algo como:
 * https://script.google.com/macros/s/XXXXXXXXXXXXXXXXXXXXXXXX/exec
 */

// ID da planilha (substitua pelo ID da sua planilha)
const SPREADSHEET_ID = '1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc';

// Nome da aba da planilha
const SHEET_NAME = 'Folha1';

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
  // Bloqueia requisições que não vieram do nosso domínio (segurança)
  // Em produção, use um token ou API key para validar
  // Para testes locais, você pode remover ou ajustar esta verificação

  // Apenas log para debug
  Logger.log('Tipo do evento: ' + e.eventType);

  try {
    // Verifica se há corpo na requisição
    if (!e.postData || !e.postData.contents) {
      Logger.log('Requisição sem corpo de dados');
      return ContentService.createTextOutput(
        JSON.stringify({
          success: false,
          message: 'Requisição sem dados'
        })
      ).setMimeType(ContentService.MimeType.JSON);
    }

    const data = JSON.parse(e.postData.contents);
    const siteId = data.site_id;
    const imageUrls = data.imageUrls || [];

    Logger.log('Dados recebidos - site_id: ' + siteId + ', imagens: ' + imageUrls.length);

    // Atualiza as fotos na planilha
    updateSitePhotos(siteId, imageUrls);

    return ContentService.createTextOutput(
      JSON.stringify({
        success: true,
        message: 'Fotos atualizadas com sucesso',
        updated_image_count: imageUrls.length
      })
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    Logger.log('Erro ao processar requisição: ' + error);
    return ContentService.createTextOutput(
      JSON.stringify({
        success: false,
        message: 'Erro: ' + error.message
      })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Atualiza as URLs de fotos de um site na planilha
 */
function updateSitePhotos(siteId, imageUrls) {
  const ss = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);

  // Encontra a linha do site pelo site_id
  const data = ss.getDataRange().getValues();

  let rowIndex = -1;
  const siteIdColumnIndex = 0; // site_id é a primeira coluna

  for (let i = 0; i < data.length; i++) {
    if (data[i][siteIdColumnIndex] == siteId) {
      rowIndex = i + 2; // +2 por causa do cabeçalho
      break;
    }
  }

  if (rowIndex === -1) {
    throw new Error('Site não encontrado: ' + siteId);
  }

  // Atualiza as colunas de foto
  for (let col = 0; col < PHOTO_COLUMNS.length; col++) {
    const range = ss.getRange(rowIndex, rowIndex + 1, col, col + 1);
    if (imageUrls[col] !== undefined) {
      range.setValue(imageUrls[col]);
    } else {
      range.setValue(''); // Remove foto se não houver URL para esta posição
    }
  }

  // Força atualização imediata da planilha
  SpreadsheetApp.flush();
}

/**
 * Endpoint para testes - retorna dados da planilha
 */
function doGet(e) {
  const ss = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);
  const data = ss.getDataRange().getValues();

  // Converte para array de objetos
  const sites = [];

  // Assumindo estrutura: site_id, sigla, nome, endereco, municipio, tecnico, latitude, longitude, detentora, uc, status, foto_1 a foto_5
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

  return ContentService.createTextOutput(JSON.stringify({
    success: true,
    sites: sites,
    total: sites.length
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Handler para requisição OPTIONS (necessário para CORS)
 */
function doOptions(e) {
  return ContentService.createTextOutput(
    JSON.stringify({ success: true })
  ).setMimeType(ContentService.MimeType.JSON);
}
