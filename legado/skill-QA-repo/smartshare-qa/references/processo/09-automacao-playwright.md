# Etapa 09 — Automação de Regressão com Playwright (QA Automation Engineer)

**Objetivo:** transformar cenários recorrentes, estáveis e de alto valor em testes automatizados com Playwright, e manter a suíte saudável.

## Base de conhecimento a consultar
- `product-knowledge/11-testes-existentes.md` — padrões, fixtures e specs já existentes (seguir o padrão do repositório se divergir deste arquivo)
- `product-knowledge/05-apis.md` — setup e limpeza de dados via API
- `complementar/fluxos-criticos.md` e `historico-defeitos.md` — priorização de candidatos

## Priorização de candidatos
| Prioridade | Critérios |
|---|---|
| **Alta** | Cenário crítico, executado frequentemente, repetitivo, estável, alto custo manual, alto risco de regressão |
| **Média** | Executado regularmente, alguma variação, valor razoável |
| **Baixa / não automatizar** | Raramente executado, alta volatilidade da tela/regra, exige julgamento humano, baixo risco |

Justifique cada candidato: *"Este cenário é repetitivo, estável e possui alto valor de automação porque..."*

## Padrões de código (Playwright + TypeScript)
- **Page Object Model**: uma classe por página/componente; testes não acessam seletores diretamente.
- **Seletores resilientes**, nesta ordem: `getByRole`, `getByLabel`, `getByTestId` (`data-testid`), `getByText`. Evite XPath e CSS frágil. Se faltar `data-testid`, recomende ao Dev adicionar.
- **Sem `waitForTimeout`**: use auto-wait e asserções web-first (`await expect(locator).toBeVisible()`).
- **Independência**: cada teste cria/limpa seus próprios dados (preferir setup via API).
- **Autenticação**: `storageState` por perfil; credenciais via variáveis de ambiente, nunca no código.
- **Tags** no título para seleção na homologação: `@smoke`, `@regressao`, `@critico`, `@<modulo>`.
- **Evidências**: `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`.
- Rastreabilidade: referencie a US/CT no título ou anotação (`test.info().annotations`).

## Esqueleto de referência

```ts
// pages/DocumentoPage.ts
import { Page, Locator, expect } from '@playwright/test';

export class DocumentoPage {
  readonly campoX: Locator;
  readonly botaoSalvar: Locator;
  readonly mensagem: Locator;

  constructor(private page: Page) {
    this.campoX = page.getByLabel('Campo X');
    this.botaoSalvar = page.getByRole('button', { name: 'Salvar' });
    this.mensagem = page.getByRole('alert');
  }

  async abrir(id: string) {
    await this.page.goto(`/documentos/${id}`);
  }

  async alterarCampoX(valor: string) {
    await this.campoX.fill(valor);
    await this.botaoSalvar.click();
  }
}
```

```ts
// tests/documento-alteracao.spec.ts
import { test, expect } from '@playwright/test';
import { DocumentoPage } from '../pages/DocumentoPage';

test.describe('US-XXXX | Alteração do campo X', () => {
  test('CT-01 permite alterar campo X no status Y @regressao @critico', async ({ page }) => {
    const doc = new DocumentoPage(page);
    // Pré-condição: documento no status Y criado via API/fixture
    await doc.abrir('<id-do-documento>');
    await doc.alterarCampoX('novo valor');
    await expect(doc.mensagem).toContainText('sucesso');
  });
});
```

Adapte seletores, rotas e textos à aplicação real — **não invente** labels ou rotas do SmartShare; se não forem conhecidos, deixe marcadores `<a confirmar>` e sinalize.

## Manutenção e flakiness
Ao analisar falha de automação, classifique: **defeito do produto**, **teste desatualizado** (seletor/fluxo mudou), **flaky** (timing, dependência de dados, ordem) ou **ambiente**. Para flaky: identifique a causa antes de adicionar retry — retry sem diagnóstico esconde problema.

## Métricas a acompanhar
Cobertura de regressão automatizada, tempo de execução da suíte, taxa de flakiness, esforço de manutenção.
