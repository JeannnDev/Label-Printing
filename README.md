# 🏷️ Label-Printing: Totem de Impressão de Etiquetas (Angular SSR + Protheus)

![Angular](https://img.shields.io/badge/Angular-21-DD0031?style=for-the-badge&logo=angular)
![Node.js](https://img.shields.io/badge/Node.js-20-339933?style=for-the-badge&logo=nodedotjs)
![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC2927?style=for-the-badge&logo=microsoftsqlserver)
![PO UI](https://img.shields.io/badge/PO_UI-v21-0072C6?style=for-the-badge)

Este projeto é uma solução para chão de fábrica, desenvolvida para simplificar a impressão de etiquetas de Ordens de Produção (OP) integradas ao **ERP TOTVS Protheus**.

A aplicação utiliza uma arquitetura híbrida moderna, consumindo APIs REST e realizando operações diretas no banco de dados SQL Server para garantir agilidade e precisão no processo produtivo.

---

## ✨ Principais Funcionalidades

- 🖥️ **Interface**: Desenvolvida com **PO UI**, otimizada para telas sensíveis ao toque em ambientes industriais.
- ⌨️ **Teclado Numérico Virtual**: Teclado customizado integrado para entrada de dados (OP, Quantidade, NF), eliminando a necessidade de periféricos físicos no totem.
- 🔍 **Validação de OP em Tempo Real**: Consulta instantânea via REST API ao Protheus para verificar status da OP, produto, armazém e roteiro.
- 💾 **Atualização Direta via SQL**: Ao alterar a Nota Fiscal (NF) na tela, o sistema realiza um `UPDATE` direto na tabela **SC2** do Protheus através de uma ponte segura em Node.js.
- 🚀 **Renderização no Servidor (SSR)**: Segurança total para credenciais de banco e melhor performance de carregamento inicial.

---

## 🛠️ Tecnologias Utilizadas

- **Frontend**: Angular 21, PO UI, RxJS.
- **Backend (SSR)**: Node.js, Express.
- **Banco de Dados**: SQL Server (Driver `mssql`).
- **Integração**: Protheus REST API (WsFuncApontamento / WsPrinter).

---

## 🚀 Como Executar o Projeto

### 1. Pré-requisitos
- Node.js (v20 ou superior)
- Acesso à API REST do Protheus
- Acesso ao Banco de Dados SQL Server do Protheus

### 2. Configuração de Ambiente
Crie um arquivo `.env` na raiz do projeto seguindo o modelo:

```env
# Configurações do Protheus REST
NEXT_PUBLIC_API_BASE_URL="http://ip-seu-servidor:porta/Rest"
NEXT_PUBLIC_API_EMPRESA="01"
NEXT_PUBLIC_API_FILIAL="0101"
NEXT_PUBLIC_API_AUTHORIZATION="Basic SEU_TOKEN_AQUI"
NEXT_PUBLIC_API_OPERADOR="000001"

# Configurações do SQL Server
MSSQL_USER="sa"
MSSQL_PASSWORD="sua_senha"
MSSQL_HOST="ip_do_banco"
MSSQL_DB="protheus_producao"
```

### 3. Instalação e Execução
```bash
# Instalar dependências
npm install --legacy-peer-deps

# Iniciar em modo de desenvolvimento
npm start
```

O estará disponível em: `http://localhost:4200`

---

## 🔒 Segurança (LGPD & Proteção de Dados)
Este projeto foi construído seguindo as melhores práticas de segurança:
- **Zero Hardcoded Credentials**: Nenhuma senha ou IP está fixo no código. Tudo é gerenciado via variáveis de ambiente.
- **SSR Bridge**: A conexão com o banco de dados SQL Server é feita exclusivamente pelo servidor, nunca expondo credenciais ao navegador do usuário.

---

## 👨‍💻 Desenvolvido por [JeannnDev](https://github.com/JeannnDev)