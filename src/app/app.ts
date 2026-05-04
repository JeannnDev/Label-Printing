import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PrintLabelComponent } from './components/print-label/print-label.component';
import { PoMenuModule, PoPageModule, PoToolbarModule, PoModule } from '@po-ui/ng-components';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, PrintLabelComponent, PoModule, PoMenuModule, PoPageModule, PoToolbarModule],
  template: `
    <div class="po-wrapper">
      <main class="po-main-container">
        <app-print-label></app-print-label>
      </main>
    </div>
  `,
  styles: [`
    .po-main-container {
      background-color: var(--color-gray-05);
      padding: 0;
      margin: 0;
    }
  `],
})
export class App {
  readonly menus = [
    { label: 'Home', link: '/' },
    { label: 'Impressão', link: '/print' }
  ];
}
