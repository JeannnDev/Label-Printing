import { Injectable, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Observable, map, catchError, of } from 'rxjs';
import { ProtheusApiService } from './protheus-api.service';

export interface Printer {
  label: string;
  value: string;
  zplId: string;
}

export interface Layout {
  label: string;
  value: string;
  origem: string;
}

export interface PrintPayload {
  Op: string;
  IdZpl: string;
  Quant: number;
  Layout: string;
  Nf?: string; // Adicionado opcionalmente
}

export interface OPData {
  op: string;
  produto: string;
  descProduto: string;
  quantidade: number;
  status: string;
  nf: string; // Adicionado campo de NF
  armazem?: string;
  success: boolean;
  error?: string;
}

@Injectable({
  providedIn: 'root'
})
export class LabelService {
  private api = inject(ProtheusApiService);
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  getPrinters(): Observable<Printer[]> {
    return this.api.get<any>('/WsZPL').pipe(
      map((res: any) => {
        if (res.response && Array.isArray(res.response)) {
          return res.response.map((p: any) => ({
            label: p.descricao,
            value: p.codigo,
            zplId: p.Id_ZPL
          }));
        }
        return [];
      })
    );
  }

  getLayouts(): Observable<Layout[]> {
    return this.api.get<any>('/WsLabel?SEQ=ETQ').pipe(
      map((res: any) => {
        if (res.response && Array.isArray(res.response)) {
          return res.response.map((l: any) => ({
            label: l.nome,
            value: l.codigo,
            origem: l.origem
          }));
        }
        return [];
      })
    );
  }

  validateOp(op: string, operator: string): Observable<OPData> {
    return this.api.get<any>(`/WsFuncApontamento?OP=${op}&OPERADOR=${operator}`).pipe(
      map((res: any) => {
        if (res.success === false || res.status === false || res.error) {
           const errorMsg = res.error || (typeof res.response === 'string' ? res.response : (res.response?.errorMessage || 'OP inválida'));
           return { success: false, error: errorMsg, op: '', produto: '', descProduto: '', quantidade: 0, status: '', nf: '', armazem: '' };
        }
        return {
          success: true,
          op: res.op,
          produto: res.produto?.trim(),
          descProduto: res.descProduto,
          quantidade: res.quantidadeSolicitada,
          status: res.status,
          nf: res.nf || '', // Tenta pegar a NF do JSON ou inicializa vazio
          armazem: res.armazem
        };
      }),
      catchError((error) => {
        return of({
          success: false,
          error: 'Erro ao validar OP no servidor',
          op: '',
          produto: '',
          descProduto: '',
          quantidade: 0,
          status: '',
          nf: '',
          armazem: ''
        } as OPData);
      })
    );
  }

  printLabel(payload: PrintPayload): Observable<any> {
    return this.api.post('/WsPrinter', payload);
  }

  updateLocalNF(op: string, nf: string, filial: string): Observable<any> {
    return this.http.post('/local-sql/update-nf', { op, nf, filial });
  }

  saveSelection(printerId: string, layoutId: string) {
    if (isPlatformBrowser(this.platformId)) {
      const preferences = { printerId, layoutId };
      localStorage.setItem('print_preferences', JSON.stringify(preferences));
    }
  }

  loadSelection() {
    if (isPlatformBrowser(this.platformId)) {
      const data = localStorage.getItem('print_preferences');
      return data ? JSON.parse(data) : null;
    }
    return null;
  }
}
