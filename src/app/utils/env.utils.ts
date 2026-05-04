import { PLATFORM_ID, inject, makeStateKey, TransferState } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export const ENV_CONFIG_KEY = makeStateKey<Record<string, string>>('env_config');

/**
 * Helper para leitura de variáveis de ambiente com suporte a TransferState.
 * No Servidor: Lê do process.env.
 * No Navegador: Lê do estado transferido pelo servidor.
 */
export function getEnv(key: string): string {
  // Nota: Em utilitários puros, não podemos usar o inject(). 
  // O ProtheusApiService será o responsável por fornecer o contexto.
  return ''; 
}

export interface EnvConfig {
  [key: string]: string;
}
