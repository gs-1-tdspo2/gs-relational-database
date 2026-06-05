# Amanajé — Banco de Dados Relacional

> **Serviço de monitoramento climático e ambiental local** — estações IoT, dados climáticos externos, avaliação de riscos, alertas e indicadores regionais para apoio à decisão em áreas vulneráveis.

---

## Sobre o Projeto

**Amanajé** é um serviço de monitoramento climático e ambiental local voltado a organizações públicas e privadas que precisam acompanhar áreas vulneráveis, validar sinais ambientais e priorizar respostas operacionais.
O sistema combina leituras locais de estações IoT com observações climáticas externas, permitindo registrar telemetria, calcular avaliações de risco, gerar alertas e disponibilizar indicadores regionais agregados.

O Amanajé contempla cenários de uso para Governo / Defesa Civil, ONGs, cooperativas, fazendas, instituições de pesquisa e regiões remotas, preservando dados sensíveis por cliente e oferecendo uma visão consolidada para análise de riscos como enchente, deslizamento, tempestade e qualidade do ar.

### Disciplina
**Mastering Relational and Non-Relational Database**
Turma: `2TDSPO` · FIAP - Unidade Paulista · 2026

### Equipe

| RM | Nome |
|:---|:-----|
| RM561408 | Gustavo Crevelari Monteiro Porto |
| RM561996 | Lucca de Araujo Gomes |
| RM561671 | Rafaela Ferreira Santos |
| RM566224 | Victor Sabelli Rocha Batista |

---

## Links do Projeto

### Repositório

> [GitHub — Relational Data Base](https://github.com/gs-1-tdspo2/gs-relational-database.git)

### Vídeo demonstrativo

> A definir.

---

## Estrutura do Repositório

```
AMANAJE/
├── Docs/
│    ├── AMANAJE_Documentacao_BD.pdf (Documentação técnica completa)
│    ├── AMANAJE_Logical.pdf (Modelo Lógico do AMANAJÉ)
│    └── AMANAJE_Relational.pdf (Modelo Físico do AMANAJÉ)
├── Models/
│    ├── AMANAJE_models/ (Arquivos de referência do DMD)
│    └── AMANAJE_models.dmd (Construtor do modelo Oracle DM)
├── Scripts/
│    ├── AMANAJE_boot-setup_DDL_v3.sql (Scripts DDL — criação do schema)
│    ├── AMANAJE_seed_DML_v3.sql (Scripts DML — procedures de carga e dados de teste)
│    └── AMANAJE_tests_DQL_v1.sql (Scripts DQL — relatórios e testes de consulta)
└── README.md (Este arquivo)
```

---

## Visão Geral do Banco de Dados

### Tecnologia

- **SGBD:** Oracle Database 12c
- **Modelagem:** Oracle Data Modeler 23.1
- **Notação:** Barker (Modelo Lógico / DER)
- **Normalização:** 3ª Forma Normal (3FN)

### Sumário do Schema

| Objeto | Quantidade |
|:-------|:----------:|
| Tabelas | 13 |
| Índices implícitos (PK + UNIQUE) | 21 |
| Índices explícitos não-únicos (IX_AMANAJE_*) | 35 |
| Índices únicos explícitos | 0 |
| Procedures de carga (PR_AMANAJE_INS_*) | 13 |
| Procedure auxiliar de log | 1 |
| Blocos anônimos de exibição | 2 |
| Bloco LAG / LEAD | 1 |
| Blocos com cursor explícito | 4 |

---

## Agrupamentos Funcionais

```
┌─────────────────────────────────────┐
│  CLIENTES E ACESSO                  │
│  ├─ TB_AMANAJE_CLI                  │
│  └─ TB_AMANAJE_USU                  │
│                                     │
│  REGIÕES E ESTAÇÕES                 │
│  ├─ TB_AMANAJE_REGIAO_MONIT         │
│  ├─ TB_AMANAJE_EST_IOT              │
│  └─ TB_AMANAJE_LOG_STATUS_EST       │
│                                     │
│  TELEMETRIA E CLIMA                 │
│  ├─ TB_AMANAJE_LEIT_IOT             │
│  └─ TB_AMANAJE_OBS_CLIM             │
│                                     │
│  RISCO E ALERTAS                    │
│  ├─ TB_AMANAJE_AVAL_RISCO           │
│  ├─ TB_AMANAJE_ALERTA               │
│  └─ TB_AMANAJE_IND_REG              │
│                                     │
│  AUDITORIA E PROCESSAMENTO          │
│  ├─ TB_AMANAJE_HIST_EVENTO          │
│  ├─ TB_AMANAJE_PROCESS              │
│  └─ TB_AMANAJE_LOG_ERRO             │
└─────────────────────────────────────┘
```

---

## Como Executar

### Pré-requisitos

- Oracle Database 12c (ou superior)
- Oracle SQL Developer ou SQL*Plus
- Usuário com permissões de DDL no schema de destino

### Ordem de Execução

Execute os scripts **nesta ordem**:

```sql
-- 1. Cria toda a estrutura relacional do banco (DROP + CREATE de todas as tabelas e índices)
@AMANAJE_boot-setup_DDL_v3.sql

-- 2. Cria as procedures de carga e insere os dados de teste
@AMANAJE_seed_DML_v3.sql

-- 3. Executa os relatórios e blocos de consulta
@AMANAJE_tests_DQL_v1.sql
```

> **IMPORTANTE:**
> O script DDL remove automaticamente todos os objetos TB_AMANAJE_* utilizando CASCADE CONSTRAINTS PURGE antes da recriação da estrutura. Não execute em ambientes produtivos.

### Configurações de Sessão

Os scripts DML e DQL configuram automaticamente:

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
```

---

## Detalhamento dos Scripts

### `AMANAJE_boot-setup_DDL_v3.sql`

| Seção | Conteúdo |
|:------|:---------|
| `# 0` | Bloco PL/SQL de limpeza — DROP de todas as tabelas, views, procedures, funções e sequences com `AMANAJE` no nome |
| `# 1` | 13 `CREATE TABLE` com constraints (PK, FK, UQ, CHECK) e `COMMENT ON TABLE / COLUMN` |
| `# 2` | 35 `CREATE INDEX` explícitos não-únicos |

### `AMANAJE_seed_DML_v3.sql`

| Seção | Conteúdo |
|:------|:---------|
| `# 0` | Configuração de ambiente (SET, ALTER SESSION) |
| `# 1` | `PR_AMANAJE_REG_ERRO` — procedure auxiliar com `AUTONOMOUS_TRANSACTION` para log de erros |
| `# 2` | 13 procedures `PR_AMANAJE_INS_*` — uma por tabela, com parâmetros e tratamento de exceções |
| `# 3` | 13 blocos anônimos de chamada — inserção de 166 registros de teste via procedures |

### `AMANAJE_tests_DQL_v1.sql`

| Seção | Bloco | Conteúdo |
|:------|:------|:---------|
| `# 1` | 1.1 | Bloco anônimo: 3 consultas com JOIN + GROUP BY + ORDER BY (base operacional por cliente, risco médio por cidade/categoria, alertas por cliente/tipo/nível/status) |
| `# 1` | 1.2 | Bloco anônimo: 3 consultas com JOIN + GROUP BY + ORDER BY (última leitura por estação, observações climáticas por localidade, leituras inválidas para auditoria) |
| `# 2` | 2   | Bloco com cursor `LAG`/`LEAD` sobre `TB_AMANAJE_AVAL_RISCO` — exibe score anterior, atual e próximo; "Vazio" quando não existe |
| `# 3` | 3.1 | Cursor explícito: priorização de regiões monitoradas com classificação de prioridade operacional |
| `# 3` | 3.2 | Cursor explícito: relatório operacional de alertas com `CASE` para tradução de status e recomendação de ação |
| `# 3` | 3.3 | Cursor explícito: processamentos e logs técnicos com classificação de resultado operacional |
| `# 3` | 3.4 | Cursor explícito: indicadores regionais agregados com classificação por faixa de risco |
| `# 4` | 4.1 | Bloco anônimo: simulação controlada de `UPDATE` com variável, `SAVEPOINT` e `ROLLBACK` para preservar a carga oficial |

---

## Convenções de Nomenclatura

| Prefixo | Tipo de Objeto |
|:--------|:--------------|
| `TB_AMANAJE_*` | Tabelas |
| `PK_AMANAJE_*` | Constraints Primary Key |
| `FK_*` | Constraints Foreign Key |
| `UQ_AMANAJE_*` | Constraints Unique |
| `CK_AMANAJE_*` | Constraints Check |
| `IX_AMANAJE_*` | Índices explícitos não-únicos |
| `PR_AMANAJE_*` | Procedures PL/SQL |
| `ID_*` | Chaves primárias e estrangeiras (NUMBER / NUMBER IDENTITY) |
| `ST_*` | Flags ou status com domínio restrito por CHECK |
| `TP_*` | Tipo/categoria com domínio restrito por CHECK |
| `DT_*` | Data/hora (DATE) |
| `DS_*` | Descrição textual (VARCHAR2 ou CLOB) |
| `NM_*` | Nome de entidade (VARCHAR2) |
| `NR_*` | Valor numérico, medida ou indicador quantitativo (NUMBER) |
| `QT_*` | Quantidade agregada ou contabilizada (NUMBER) |
| `CD_*` | Código operacional ou técnico (VARCHAR2) |
| `SG_*` | Sigla ou abreviação territorial (CHAR/VARCHAR2) |

---

*Junho de 2026 · FIAP 2TDSPO*
