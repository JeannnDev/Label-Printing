import { Component, OnInit, inject, signal, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import {
  PoFieldModule,
  PoButtonModule,
  PoNotificationModule,
  PoContainerModule,
  PoDividerModule,
  PoInfoModule,
  PoWidgetModule,
  PoLoadingModule,
  PoModalModule,
  PoModalComponent,
  PoModule,
  PoNotificationService
} from '@po-ui/ng-components';
import { LabelService, Printer, Layout, PrintPayload, OPData } from '../../services/label.service';

@Component({
  selector: 'app-print-label',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoFieldModule,
    PoButtonModule,
    PoContainerModule,
    PoDividerModule,
    PoInfoModule,
    PoWidgetModule,
    PoLoadingModule,
    PoModalModule,
    PoNotificationModule,
    PoModule
  ],
  template: `
    <!-- Loading overlay PO UI durante consulta da OP -->
    <po-loading-overlay
      [p-screen-lock]="true"
      p-text="Consultando OP"
      *ngIf="isLoading()">
    </po-loading-overlay>

    <!-- Modal do Teclado Numérico -->
    <po-modal #keypadModal [p-title]="modalTitle" [p-hide-close]="true">
      <div class="modal-keypad-container">
        
        <div class="modal-visor-preview po-mb-2">
            <span class="preview-label">{{ modalTitle === 'Digitar OP' ? 'OP ATUAL' : (modalTitle === 'Definir Quantidade' ? 'QUANTIDADE' : 'NOTA FISCAL') }}</span>
            <span class="preview-value">{{ modalValue }}</span>
        </div>

        <div class="kiosk-keypad">
          <po-button *ngFor="let btn of keypadButtons" 
                      class="kiosk-key" 
                      [p-label]="btn.label" 
                      [p-kind]="btn.kind || 'secondary'"
                      [p-icon]="btn.icon || ''"
                      (p-click)="btn.action()">
          </po-button>
        </div>

        <div class="modal-actions po-mt-3">
          <po-button 
              class="modal-action-btn"
              p-label="FECHAR" 
              p-kind="danger"
              (p-click)="keypadModal.close()">
          </po-button>

          <po-button 
              class="modal-action-btn"
              p-label="CONFIRMAR" 
              p-kind="primary"
              (p-click)="confirmKeypad()">
          </po-button>
        </div>
      </div>
    </po-modal>

    <div class="page-container">
      <!-- Cabeçalho -->
      <div class="po-row po-align-items-center po-mb-1">
        <h1 class="po-md-6 po-font-title">Impressão de Etiqueta</h1>
        <div class="po-md-6">
          <div class="po-row">
            <div class="po-md-10">
              <po-input 
                name="op"
                p-label="Pesquisar Ordem de Produção"
                p-placeholder="Escaneie ou digite a OP"
                p-icon="po-icon-search"
                [(ngModel)]="opNumber"
                (p-blur)="validateAndFetch()"
                (keyup.enter)="validateAndFetch()"
                [p-disabled]="isValidated().toString()"
                p-clean>
              </po-input>
            </div>
            <div class="po-md-2 po-pt-4">
              <po-button 
                *ngIf="!isValidated()"
                p-label="TECLADO" 
                p-kind="secondary"
                p-tooltip="Abrir Teclado Numérico"
                (p-click)="openKeypad('op')">
              </po-button>
              
              <po-button 
                *ngIf="isValidated()"
                p-label="TROCAR OP" 
                p-kind="danger"
                p-tooltip="Limpar e consultar outra OP"
                (p-click)="resetOP()">
              </po-button>
            </div>
          </div>
        </div>
      </div>


      <!-- Informações da OP -->
      @if (opData(); as data) {
        <div class="op-info-card" [class.op-encerrada]="data.status === 'Enc. Total'">
          <div class="op-info-fields">
            <div class="op-field">
              <span class="op-field-label"><i class="po-icon po-icon-product"></i> Produto</span>
              <span class="op-field-value">{{ data.produto }}</span>
            </div>
            <div class="op-field op-field-grow">
              <span class="op-field-label"><i class="po-icon po-icon-document"></i> Descrição</span>
              <span class="op-field-value">{{ data.descProduto }}</span>
            </div>
            <div class="op-field">
              <span class="op-field-label"><i class="po-icon po-icon-settings"></i> Status OP</span>
              <span class="op-status-badge" [class.badge-encerrada]="data.status === 'Enc. Total'" [class.badge-ok]="data.status !== 'Enc. Total'">
                {{ data.status }}
              </span>
            </div>
          </div>
        </div>
      }

      <div class="po-row po-justify-center">
        <po-widget class="po-lg-12 po-md-12 po-sm-12 kiosk-card">
          
          <div class="section-label"><i class="po-icon po-icon-settings"></i> Configurações de Impressão</div>
          <div class="po-row kiosk-header">
            <po-select 
              class="po-md-6"
              name="printer"
              p-label="Impressora"
              [p-options]="printers()"
              [ngModel]="selectedPrinter"
              (ngModelChange)="selectedPrinter = $event"
              p-icon="po-icon-print"
              [p-disabled]="(!isValidated()).toString()">
            </po-select>

            <po-select 
              class="po-md-6"
              name="layout"
              p-label="Modelo de Etiqueta"
              [p-options]="layouts()"
              [ngModel]="selectedLayout"
              (ngModelChange)="selectedLayout = $event"
              p-icon="po-icon-list"
              [p-disabled]="(!isValidated()).toString()">
            </po-select>

            <!-- Campo NF com Botão Lateral -->
            <div class="po-md-12">
               <div class="po-row po-align-items-center">
                  <div class="po-md-10">
                    <po-input 
                      name="nf"
                      p-label="Nota Fiscal (NF)"
                      p-placeholder="Pressione ALTERAR para digitar"
                      [(ngModel)]="nfValue"
                      p-icon="po-icon-document"
                      [p-maxlength]="9"
                      [p-disabled]="(!isValidated()).toString()"
                      p-readonly="true">
                    </po-input>
                  </div>
                  <div class="po-md-2 po-pt-4">
                    <po-button 
                      p-label="ALTERAR" 
                      p-kind="secondary"
                      [p-disabled]="!isValidated()"
                      p-icon="po-icon-edit"
                      (p-click)="openKeypad('nf')">
                    </po-button>
                  </div>
               </div>
            </div>
          </div>

          <div class="po-row po-mt-2 po-mb-2 po-align-items-center">
            
            <!-- Visor de Quantidade -->
            <div class="po-md-12 po-text-center">
               <div class="section-label"><i class="po-icon po-icon-copy"></i> Quantidade de Cópias</div>
               <div class="kiosk-visor selectable" (click)="openKeypad('quantity')">
                  <div class="visor-label">TOTAL DE CÓPIAS (TOQUE PARA ALTERAR)</div>
                  <div class="visor-controls">
                    <po-button 
                      class="visor-btn" 
                      p-label="-"
                      (click)="$event.stopPropagation(); decrementQuantity()">
                    </po-button>
                    
                    <div class="visor-number">{{ quantity() }}</div>
                    
                    <po-button 
                      class="visor-btn" 
                      p-label="+"
                      (click)="$event.stopPropagation(); incrementQuantity()">
                    </po-button>
                  </div>
               </div>
               <po-button 
                class="po-mt-2 print-action-btn-full"
                p-label="INICIAR IMPRESSÃO" 
                p-kind="primary" 
                p-icon="po-icon-print"
                [p-disabled]="!isFormValid()"
                [p-loading]="isPrinting()"
                (p-click)="onPrint()">
              </po-button>
            </div>

          </div>
        </po-widget>
      </div>
    </div>
  `,
  styles: [`
    .op-info-card {
      display: flex;
      align-items: center;
      background: #fff;
      border-radius: 8px;
      border-left: 5px solid #0C6DB5;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      padding: 14px 20px;
      margin-bottom: 16px;
      gap: 16px;
      transition: border-color 0.3s;
    }
    .op-info-card.op-encerrada {
      border-left-color: #fbc02d;
      background: #fffde7;
    }
    .op-info-fields {
      display: flex;
      flex: 1;
      gap: 32px;
      flex-wrap: wrap;
      align-items: center;
    }
    .op-field {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .op-field-grow {
      flex: 1;
    }
    .op-field-label {
      font-size: 11px;
      font-weight: 600;
      color: #888;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .op-field-label i {
      margin-right: 4px;
    }
    .op-field-value {
      font-size: 15px;
      font-weight: 600;
      color: #333;
    }
    .op-status-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .badge-ok {
      background-color: #e8f5e9;
      color: #2e7d32;
    }
    .badge-encerrada {
      background-color: #fbc02d;
      color: #5d4037;
    }

    /* Header da Página */
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
      gap: 16px;
      flex-wrap: wrap;
    }
    .page-header-left {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .page-header-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      background: linear-gradient(135deg, #0C6DB5, #0a5a96);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
      color: white;
      box-shadow: 0 4px 12px rgba(12, 109, 181, 0.35);
    }
    .page-header-title {
      font-size: 22px;
      font-weight: 700;
      color: #1a2332;
      line-height: 1.2;
    }
    .page-header-subtitle {
      font-size: 12px;
      color: #0C6DB5;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .page-header-search {
      flex: 1;
      max-width: 420px;
    }

    /* Labels de Seção */
    .section-label {
      font-size: 11px;
      font-weight: 700;
      color: #0C6DB5;
      text-transform: uppercase;
      letter-spacing: 1px;
      padding: 8px 16px 4px;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    /* Botão de Impressão Largura Total */
    .print-action-btn-full {
      width: 100%;
      margin-top: 12px;
    }
    .print-action-btn-full ::ng-deep .po-button {
      width: 100% !important;
      height: 54px !important;
      font-size: 16px !important;
    }

    .selectable {
      cursor: pointer;
      transition: transform 0.2s;
    }
    .selectable:hover {
      transform: scale(1.02);
      filter: brightness(1.1);
    }

    .visor-controls {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 40px;
      margin-top: 5px;
    }

    .visor-btn ::ng-deep .po-button {
      background: rgba(255, 255, 255, 0.15) !important;
      border: 2px solid rgba(255, 255, 255, 0.3) !important;
      color: white !important;
      width: 64px !important;
      height: 64px !important;
      border-radius: 50% !important;
      font-size: 32px !important;
      font-weight: bold !important;
      transition: all 0.2s !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }

    .visor-btn ::ng-deep .po-button:hover {
      background: rgba(255, 255, 255, 0.3) !important;
      transform: scale(1.1);
    }

    .visor-btn ::ng-deep .po-button:active {
      transform: scale(0.9);
    }

    .modal-keypad-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 10px;
    }

    .page-container {
      padding: 10px;
    }

    .po-pt-4 {
      padding-top: 32px !important;
    }

    .modal-visor-preview {
      width: 100%;
      max-width: 480px;
      background: #f4f4f4;
      padding: 15px;
      border-radius: 12px;
      text-align: center;
      border: 2px solid #0C6DB5;
    }

    .preview-label {
      display: block;
      font-size: 10px;
      font-weight: bold;
      color: #666;
      text-transform: uppercase;
    }

    .preview-value {
      font-size: 32px;
      font-weight: bold;
      color: #0C6DB5;
    }

    .modal-actions {
      display: flex;
      gap: 12px;
      width: 100%;
      max-width: 480px;
    }

    .modal-action-btn {
      flex: 1;
    }

    .modal-action-btn ::ng-deep .po-button {
      width: 100% !important;
      height: 54px !important;
      font-size: 16px !important;
      font-weight: bold !important;
    }

    ::ng-deep .po-modal-footer {
      display: none !important;
    }

    ::ng-deep .po-field-container-content.po-disabled {
      background-color: #f0f0f0 !important;
      opacity: 0.8;
    }
  `]
})
export class PrintLabelComponent implements OnInit {
  @ViewChild('keypadModal') keypadModal!: PoModalComponent;
  
  private labelService = inject(LabelService);
  private notification = inject(PoNotificationService);

  // States
  protected printers = signal<any[]>([]);
  protected layouts = signal<any[]>([]);
  protected quantity = signal<string>('1');
  protected isPrinting = signal<boolean>(false);
  protected isValidated = signal<boolean>(false);
  protected isLoading = signal<boolean>(false);
  protected opData = signal<OPData | null>(null);

  // Keypad Modal Logic
  protected modalTitle: string = '';
  protected modalValue: string = '';
  protected editingField: 'op' | 'quantity' | 'nf' | null = null;

  // Model data - Busca do ambiente ou usa fallback seguro
  operatorCode: string = (window as any).__ENV__?.NEXT_PUBLIC_API_OPERADOR || '000001';
  selectedPrinter: string = '';
  selectedLayout: string = '';
  opNumber: string = '';
  nfValue: string = '';

  readonly keypadButtons = [
    { label: '1', action: () => this.addNumber('1') },
    { label: '2', action: () => this.addNumber('2') },
    { label: '3', action: () => this.addNumber('3') },
    { label: '4', action: () => this.addNumber('4') },
    { label: '5', action: () => this.addNumber('5') },
    { label: '6', action: () => this.addNumber('6') },
    { label: '7', action: () => this.addNumber('7') },
    { label: '8', action: () => this.addNumber('8') },
    { label: '9', action: () => this.addNumber('9') },
    { label: 'C', action: () => this.clearQuantity(), kind: 'danger' },
    { label: '0', action: () => this.addNumber('0') },
    { label: '', action: () => this.backspace(), icon: 'po-icon-delete' }
  ];

  openKeypad(field: 'op' | 'quantity' | 'nf') {
    this.editingField = field;
    if (field === 'op') this.modalTitle = 'Digitar OP';
    else if (field === 'quantity') this.modalTitle = 'Definir Quantidade';
    else this.modalTitle = 'Digitar Nota Fiscal';

    this.modalValue = field === 'op' ? this.opNumber : (field === 'quantity' ? this.quantity() : this.nfValue);
    this.keypadModal.open();
  }

  @HostListener('window:keydown', ['$event'])
  handleKeyboardEvent(event: KeyboardEvent) {
    if (!this.editingField) return;
    const key = event.key;
    if (/[0-9]/.test(key)) {
      this.addNumber(key);
    } else if (key === 'Backspace') {
      this.backspace();
    } else if (key === 'Enter') {
      this.confirmKeypad();
    } else if (key === 'Escape') {
      this.keypadModal.close();
      this.editingField = null;
    }
  }

  confirmKeypad() {
    if (this.editingField === 'op') {
      this.opNumber = this.modalValue;
      this.validateAndFetch();
    } else if (this.editingField === 'quantity') {
      this.quantity.set(this.modalValue || '1');
    } else if (this.editingField === 'nf') {
      this.nfValue = this.modalValue;
      this.saveNFToDatabase(); // Grava no SQL direto
    }
    this.editingField = null;
    this.keypadModal.close();
  }

  saveNFToDatabase() {
    if (!this.opNumber || !this.nfValue) return;

    this.labelService.updateLocalNF(this.opNumber, this.nfValue, '').subscribe({
      next: (res) => {
        this.notification.success('Nota Fiscal atualizada no Protheus!');
      },
      error: (err) => {
        console.error('Erro SQL:', err);
        this.notification.error('Erro ao atualizar NF no Banco de Dados');
      }
    });
  }

  resetOP() {
    this.opNumber = '';
    this.nfValue = '';
    this.isValidated.set(false);
    this.opData.set(null);
  }

  ngOnInit() {
    const prefs = this.labelService.loadSelection();
    if (prefs) {
      this.selectedPrinter = prefs.printerId;
      this.selectedLayout = prefs.layoutId;
    }
  }

  validateAndFetch() {
    if (!this.opNumber || !this.operatorCode) return;
    this.isLoading.set(true);
    this.isValidated.set(false);
    this.opData.set(null);

    this.labelService.validateOp(this.opNumber, this.operatorCode).subscribe({
      next: (data) => {
        if (data.success) {
          this.opData.set(data);
          this.nfValue = data.nf || '';
          this.isValidated.set(true);
          this.loadPrintersAndLayouts();
          this.notification.success('OP validada com sucesso!');
        } else {
          this.isLoading.set(false);
          this.notification.error(data.error || 'Erro ao validar OP');
        }
      },
      error: () => {
        this.isLoading.set(false);
        this.notification.error('Erro na comunicação com o servidor');
      }
    });
  }

  loadPrintersAndLayouts() {
    forkJoin({
      printers: this.labelService.getPrinters(),
      layouts: this.labelService.getLayouts()
    }).subscribe({
      next: ({ printers, layouts }) => {
        this.printers.set(printers);
        if (printers.length > 0 && !this.selectedPrinter) {
          this.selectedPrinter = printers[0].value;
        }
        this.layouts.set(layouts);
        if (layouts.length > 0 && !this.selectedLayout) {
          this.selectedLayout = layouts[0].value;
        }
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
        this.notification.error('Erro ao carregar impressoras/etiquetas');
      }
    });
  }

  addNumber(num: string) {
    if (this.modalValue === '0' || (this.editingField === 'quantity' && this.modalValue === '1' && this.modalValue.length === 1)) {
      this.modalValue = num;
    } else if (this.modalValue.length < (this.editingField === 'op' ? 14 : (this.editingField === 'nf' ? 9 : 4))) {
      this.modalValue += num;
    }
  }

  clearQuantity() {
    this.modalValue = '0';
  }

  backspace() {
    if (this.modalValue.length > 1) {
      this.modalValue = this.modalValue.slice(0, -1);
    } else {
      this.modalValue = '0';
    }
  }

  incrementQuantity() {
    let val = parseInt(this.quantity());
    if (val < 9999) {
      this.quantity.set((val + 1).toString());
    }
  }

  decrementQuantity() {
    let val = parseInt(this.quantity());
    if (val > 1) {
      this.quantity.set((val - 1).toString());
    }
  }

  isFormValid() {
    return this.isValidated() && this.selectedPrinter && this.selectedLayout && parseInt(this.quantity()) > 0;
  }

  onPrint() {
    if (!this.isFormValid()) return;
    this.isPrinting.set(true);
    const printerObj = this.printers().find(p => p.value === this.selectedPrinter);
    const layoutObj = this.layouts().find(l => l.value === this.selectedLayout);
    const payload: PrintPayload = {
      Op: this.opNumber,
      IdZpl: printerObj?.zplId || '',
      Quant: parseInt(this.quantity()),
      Layout: layoutObj?.origem || '',
      Nf: this.nfValue
    };
    this.labelService.saveSelection(this.selectedPrinter, this.selectedLayout);
    this.labelService.printLabel(payload).subscribe({
      next: (res: any) => {
        this.notification.success(res.message || 'Impressão enviada com sucesso!');
        this.isPrinting.set(false);
      },
      error: (err) => {
        this.notification.error('Erro ao enviar impressão: ' + (err.error?.message || err.message));
        this.isPrinting.set(false);
      }
    });
  }
}
