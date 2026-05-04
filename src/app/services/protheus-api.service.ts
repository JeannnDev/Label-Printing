import { Injectable, inject, PLATFORM_ID, TransferState } from '@angular/core';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { isPlatformBrowser } from '@angular/common';
import { Observable, map, catchError, of } from 'rxjs';
import { ENV_CONFIG_KEY } from '../utils/env.utils';

@Injectable({
  providedIn: 'root'
})
export class ProtheusApiService {
  private http = inject(HttpClient);
  private transferState = inject(TransferState);
  private platformId = inject(PLATFORM_ID);
  
  private config: Record<string, string> = {};

  constructor() {
    if (isPlatformBrowser(this.platformId)) {
      // No navegador, recupera o que o servidor injetou no HTML ou via TransferState
      this.config = (window as any).__ENV__ || this.transferState.get(ENV_CONFIG_KEY, {});
    } else {
      // No servidor, lê do processo e guarda para enviar ao navegador
      this.config = {
        NEXT_PUBLIC_API_BASE_URL: process.env['NEXT_PUBLIC_API_BASE_URL'] || '/api',
        NEXT_PUBLIC_API_EMPRESA: process.env['NEXT_PUBLIC_API_EMPRESA'] || '01',
        NEXT_PUBLIC_API_FILIAL: process.env['NEXT_PUBLIC_API_FILIAL'] || '0101',
        NEXT_PUBLIC_API_AUTHORIZATION: process.env['NEXT_PUBLIC_API_AUTHORIZATION'] || '',
      };
      this.transferState.set(ENV_CONFIG_KEY, this.config);
    }
  }

  /**
   * Orchestrates reading environment variables with SSR TransferState compatibility.
   */
  getEnv(key: string): string {
    return this.config[key] || '';
  }

  getHeaders(): HttpHeaders {
    let headers = new HttpHeaders({
      'Accept': 'application/json'
    });

    const empresa = this.getEnv('NEXT_PUBLIC_API_EMPRESA');
    const filial = this.getEnv('NEXT_PUBLIC_API_FILIAL');
    const auth = this.getEnv('NEXT_PUBLIC_API_AUTHORIZATION');

    if (empresa) headers = headers.set('EMPRESA', empresa);
    if (filial) headers = headers.set('FILIAL', filial);
    if (auth) headers = headers.set('Authorization', auth);

    return headers;
  }

  /**
   * Defensive GET request that handles raw text responses from Protheus.
   */
  get<T>(url: string): Observable<T> {
    const baseUrl = this.getEnv('NEXT_PUBLIC_API_BASE_URL') || '/api';
    const fullUrl = `${baseUrl}${url}`;
    const headers = this.getHeaders();
    
    console.log(`[DEBUG] GET Request: ${fullUrl}`);
    
    return this.http.get(fullUrl, { 
      headers,
      responseType: 'text' 
    }).pipe(
      map(response => {
        console.log(`[DEBUG] Raw Response for ${url}:`, response);
        try {
          return JSON.parse(response) as T;
        } catch (e) {
          return response as unknown as T;
        }
      }),
      catchError((error: HttpErrorResponse) => {
        console.error(`[DEBUG] Error Response for ${url}:`, error);
        
        let errorMsg = 'Erro na comunicação com o Protheus';
        if (error.error) {
          console.log(`[DEBUG] Error Body:`, error.error);
          // Se o corpo do erro for a string da mensagem, usamos ela
          errorMsg = typeof error.error === 'string' ? error.error : (error.error.response || errorMsg);
        }
        
        return of({ success: false, error: errorMsg, response: errorMsg } as unknown as T);
      })
    );
  }

  /**
   * Defensive POST request.
   */
  post<T>(url: string, body: any): Observable<T> {
    const baseUrl = this.getEnv('NEXT_PUBLIC_API_BASE_URL') || '/api';
    const fullUrl = `${baseUrl}${url}`;
    const headers = this.getHeaders();

    console.log(`[DEBUG] POST Request: ${fullUrl}`);

    return this.http.post(fullUrl, body, { 
      headers,
      responseType: 'text' 
    }).pipe(
      map(response => {
        console.log(`[DEBUG] Raw Response for ${url}:`, response);
        try {
          return JSON.parse(response) as T;
        } catch (e) {
          return response as unknown as T;
        }
      }),
      catchError((error: HttpErrorResponse) => {
        console.error(`[DEBUG] Error Response for ${url}:`, error);
        return of({ success: false, error: 'Erro na comunicação com o Protheus' } as unknown as T);
      })
    );
  }
}
