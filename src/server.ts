import {
  AngularNodeAppEngine,
  createNodeRequestHandler,
  isMainModule,
  writeResponseToNodeResponse,
} from '@angular/ssr/node';
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import { join } from 'node:path';
import sql from 'mssql';
import cors from 'cors';

// Mock do localStorage e browser globals para compatibilidade com PO UI no SSR
if (typeof global !== 'undefined') {
  Object.defineProperty(global, 'window', { value: global, writable: true });
  Object.defineProperty(global, 'document', {
    value: {
      documentElement: {
        style: {},
        getAttribute: () => null,
        setAttribute: () => { }
      },
      querySelector: () => null,
      querySelectorAll: () => [],
      createElement: () => ({ style: {}, appendChild: () => { }, setAttribute: () => { } }),
      body: { style: {} },
      addEventListener: () => { },
      removeEventListener: () => { }
    },
    writable: true
  });

  Object.defineProperty(global, 'localStorage', {
    value: {
      getItem: () => null,
      setItem: () => { },
      removeItem: () => { },
      clear: () => { },
      length: 0,
      key: () => null
    },
    writable: true,
    configurable: true
  });

  if (!('navigator' in global)) {
    Object.defineProperty(global, 'navigator', {
      value: {
        language: 'pt-BR',
        languages: ['pt-BR', 'en-US']
      },
      writable: true,
      configurable: true
    });
  }
}

const browserDistFolder = join(import.meta.dirname, '../browser');
const app = express();
app.use(cors()); // Ativar CORS para todas as rotas
app.use(express.json());

const angularApp = new AngularNodeAppEngine();

// Configuração do SQL Server
const sqlConfig: sql.config = {
  user: process.env['MSSQL_USER'],
  password: process.env['MSSQL_PASSWORD'],
  database: process.env['MSSQL_DB'],
  server: process.env['MSSQL_HOST'] || '',
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  },
  options: {
    encrypt: false,
    trustServerCertificate: true
  }
};

// Gerenciamento do Pool de Conexão SQL
let pool: sql.ConnectionPool | null = null;

async function getSqlPool() {
  if (pool && pool.connected) {
    return pool;
  }
  try {
    pool = await new sql.ConnectionPool(sqlConfig).connect();
    console.log('[SQL] Conectado ao servidor:', sqlConfig.server);
    return pool;
  } catch (err) {
    console.error('[SQL CONNECTION ERROR]', err);
    pool = null;
    throw err;
  }
}

// API para atualizar a NF no Banco SQL
app.post('/local-sql/update-nf', async (req: Request, res: Response): Promise<any> => {
  const { op, nf, filial } = req.body;

  if (!op || op.length < 11) {
    return res.status(400).json({ success: false, message: 'OP inválida para atualização' });
  }

  try {
    const num = op.substring(0, 6);
    const item = op.substring(6, 8);
    const sequen = op.substring(8, 11);

    const connection = await getSqlPool();
    const result = await connection.request()
      .input('nf', sql.VarChar, nf)
      .input('filial', sql.VarChar, filial || process.env['NEXT_PUBLIC_API_FILIAL'])
      .input('num', sql.VarChar, num)
      .input('item', sql.VarChar, item)
      .input('sequen', sql.VarChar, sequen)
      .query(`
        UPDATE SC2010
        SET C2_XNFISC = @nf
        WHERE C2_FILIAL = @filial 
          AND C2_NUM = @num 
          AND C2_ITEM = @item 
          AND C2_SEQUEN = @sequen 
          AND D_E_L_E_T_ = ''
      `);

    return res.json({ success: true, message: 'NF atualizada no Protheus', rowsAffected: result.rowsAffected });
  } catch (err: any) {
    console.error('[SQL ERROR]', err);
    return res.status(500).json({ success: false, message: 'Erro ao gravar no banco', error: err.message });
  }
});

/**
 * Serve static files from /browser
 */
app.use(
  express.static(browserDistFolder, {
    maxAge: '1y',
    index: false,
    redirect: false,
  }),
);

/**
 * Handle all other requests by rendering the Angular application.
 */
app.use((req: Request, res: Response, next: NextFunction) => {
  angularApp
    .handle(req)
    .then((response) => {
      if (response) {
        // Injetamos as variáveis de ambiente no HTML para o navegador ler
        const envConfig = JSON.stringify({
          NEXT_PUBLIC_API_BASE_URL: process.env['NEXT_PUBLIC_API_BASE_URL'] || '/api',
          NEXT_PUBLIC_API_EMPRESA: process.env['NEXT_PUBLIC_API_EMPRESA'] || '01',
          NEXT_PUBLIC_API_FILIAL: process.env['NEXT_PUBLIC_API_FILIAL'] || '0101',
          NEXT_PUBLIC_API_AUTHORIZATION: process.env['NEXT_PUBLIC_API_AUTHORIZATION'] || '',
          NEXT_PUBLIC_API_OPERADOR: process.env['NEXT_PUBLIC_API_OPERADOR'] || '000001',
          NEXT_PUBLIC_SQL_API_URL: process.env['NEXT_PUBLIC_SQL_API_URL'] || '',
        });

        response.text().then(html => {
          const injectedHtml = html.replace(
            '</head>',
            `<script>window.__ENV__ = ${envConfig};</script></head>`
          );
          res.send(injectedHtml);
        });
      } else {
        next();
      }
    })
    .catch(next);
});

/**
 * Start the server if this module is the main entry point, or it is ran via PM2.
 */
if (isMainModule(import.meta.url) || process.env['pm_id']) {
  const port = process.env['PORT'] || 4000;
  app.listen(port, (error?: any) => {
    if (error) {
      throw error;
    }
    console.log(`Node Express server listening on http://localhost:${port}`);
  });
}

/**
 * Request handler used by the Angular CLI (for dev-server and during build).
 */
export const reqHandler = createNodeRequestHandler(app);
