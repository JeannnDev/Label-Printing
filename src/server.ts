import {
  AngularNodeAppEngine,
  createNodeRequestHandler,
  isMainModule,
  writeResponseToNodeResponse,
} from '@angular/ssr/node';
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import { join } from 'node:path';

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
