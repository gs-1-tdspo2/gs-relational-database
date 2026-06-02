/*
==================================================================================
   PROJETO AMANAJE - MASTERING RELATIONAL AND NON-RELATIONAL DATABASE
  ──────────────────────────────────────────────────────────────────────────────
   Turma: 2TDSPO (Unidade Paulista)
   Equipe:
    - RM561408 — Gustavo Crevelari Monteiro Porto
    - RM561996 — Lucca de Araujo Gomes
    - RM561671 — Rafaela Ferreira Santos
    - RM566224 — Victor Sabelli Rocha Batista
  ──────────────────────────────────────────────────────────────────────────────
   ÍNDICE
  ──────────────────────────────────────────────────────────────────────────────
   # 0 ─  Preparação do ambiente - 'SETs' para interface;
   # 1 ─  Dois blocos anônimos de exibição com 'JOINs';
   # 2 ─  Bloco com 'LAG' / 'LEAD' (anterior, atual e próxima);
   # 3 ─  Quatro blocos com cursor explícito, decisão e manipulação de variáveis;
   # 4 ─  Bloco controlado de atualização com variável, SAVEPOINT e ROLLBACK.
  ──────────────────────────────────────────────────────────────────────────────
   REQUISITOS COBERTOS NESTE SCRIPT:
  ──────────────────────────────────────────────────────────────────────────────
    1. 7 blocos anônimos PL/SQL com tratamento de exceções;
    2. 5+ relatórios SQL com JOIN, GROUP BY e ORDER BY;
    3. 4+ estruturas condicionais com IF/ELSIF/ELSE e CASE;
    4. 4+ estruturas de repetição com FOR, LOOP e WHILE;
    5. 4+ cursores explícitos;
    6. SELECT INTO para transferência de dados de tabelas para variáveis;
    7. UPDATE controlado por variáveis com ROLLBACK para não alterar a carga oficial.
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
*/

/*
==================================================================================
   # 0 — PREPARAÇÃO DO AMBIENTE
  ──────────────────────────────────────────────────────────────────────────────
*/

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK ON;
SET LINESIZE 220;
SET PAGESIZE 200;

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

/*
==================================================================================
   # 1 — TESTE DE BLOCOS ANÔNIMOS DE EXIBIÇÃO COM JOINS, GROUP BY E ORDER BY
  ──────────────────────────────────────────────────────────────────────────────
*/

   -- ## 1.1 — Visão institucional:
   --         clientes, regiões, estações, alertas e perfil de risco por cidade.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_total NUMBER;
BEGIN

    -- ### CONSULTA A: Base operacional por cliente
    --                (JOIN: CLIENTE ⟶ REGIAO ⟶ ESTACAO / ALERTA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-A: Base Operacional por Cliente');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('CLIENTE', 42) || RPAD('TIPO', 24) || LPAD('REG', 6) || LPAD('EST', 6) || LPAD('ALERTAS', 9) || LPAD('CRIT', 7) || LPAD('ABERTOS', 9));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            c.NM_CLI,
            c.TP_CLI,
            COUNT(DISTINCT rm.ID_REGIAO) AS QTD_REG,
            COUNT(DISTINCT ei.ID_ESTACAO) AS QTD_EST,
            COUNT(DISTINCT al.ID_ALERTA) AS QTD_ALERTAS,
            COUNT(DISTINCT CASE WHEN al.TP_NIVEL = 'CRITICO' THEN al.ID_ALERTA END) AS QTD_CRIT,
            COUNT(DISTINCT CASE WHEN al.ST_ALERTA = 'ABERTO' THEN al.ID_ALERTA END) AS QTD_ABERTOS
        FROM TB_AMANAJE_CLI c
            LEFT JOIN TB_AMANAJE_REGIAO_MONIT rm ON c.ID_CLIENTE = rm.ID_CLIENTE
            LEFT JOIN TB_AMANAJE_EST_IOT ei ON rm.ID_REGIAO = ei.ID_REGIAO
            LEFT JOIN TB_AMANAJE_ALERTA al ON rm.ID_REGIAO = al.ID_REGIAO
        GROUP BY c.NM_CLI, c.TP_CLI
        ORDER BY QTD_CRIT DESC, QTD_ALERTAS DESC, c.NM_CLI
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.NM_CLI, 1, 40), 42) || RPAD(r.TP_CLI, 24) || LPAD(r.QTD_REG, 6) || LPAD(r.QTD_EST, 6) || LPAD(r.QTD_ALERTAS, 9) || LPAD(r.QTD_CRIT, 7) || LPAD(r.QTD_ABERTOS, 9));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA B: Risco médio por cidade e categoria
    --                (JOIN: REGIAO ⟶ AVALIACAO)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-B: Risco Médio por Cidade e Categoria');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('UF/CIDADE', 28) || RPAD('RISCO', 16) || LPAD('AVALS', 7) || LPAD('MÉDIA', 8) || LPAD('MÁX', 6) || LPAD('CRIT', 7));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            rm.SG_ESTADO || '/' || rm.NM_CIDADE AS LOCALIDADE,
            ar.TP_RISCO,
            COUNT(ar.ID_AVALIACAO) AS QTD_AVAL,
            ROUND(AVG(ar.NR_SCORE_RISCO), 2) AS MEDIA_SCORE,
            MAX(ar.NR_SCORE_RISCO) AS MAX_SCORE,
            SUM(CASE WHEN ar.TP_NIVEL_RISCO = 'CRITICO' THEN 1 ELSE 0 END) AS QTD_CRIT
        FROM TB_AMANAJE_REGIAO_MONIT rm
            JOIN TB_AMANAJE_AVAL_RISCO ar ON rm.ID_REGIAO = ar.ID_REGIAO
        GROUP BY rm.SG_ESTADO, rm.NM_CIDADE, ar.TP_RISCO
        ORDER BY MAX_SCORE DESC, MEDIA_SCORE DESC, LOCALIDADE
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.LOCALIDADE, 1, 26), 28) || RPAD(r.TP_RISCO, 16) || LPAD(r.QTD_AVAL, 7) || LPAD(TO_CHAR(r.MEDIA_SCORE, 'FM990.00'), 8) || LPAD(r.MAX_SCORE, 6) || LPAD(r.QTD_CRIT, 7));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA C: Alertas por cliente, tipo, nível e status
    --                (JOIN: CLIENTE ⟶ REGIAO ⟶ ALERTA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.1-C: Alertas por Cliente, Tipo, Nível e Status');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('CLIENTE', 35) || RPAD('TIPO ALERTA', 16) || RPAD('NÍVEL', 11) || RPAD('STATUS', 13) || LPAD('QTD', 5));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            c.NM_CLI,
            al.TP_ALERTA,
            al.TP_NIVEL,
            al.ST_ALERTA,
            COUNT(*) AS QTD
        FROM TB_AMANAJE_CLI c
            JOIN TB_AMANAJE_REGIAO_MONIT rm ON c.ID_CLIENTE = rm.ID_CLIENTE
            JOIN TB_AMANAJE_ALERTA al ON rm.ID_REGIAO = al.ID_REGIAO
        GROUP BY c.NM_CLI, al.TP_ALERTA, al.TP_NIVEL, al.ST_ALERTA
        ORDER BY c.NM_CLI, al.TP_NIVEL, al.TP_ALERTA
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.NM_CLI, 1, 33), 35) || RPAD(r.TP_ALERTA, 16) || RPAD(r.TP_NIVEL, 11) || RPAD(r.ST_ALERTA, 13) || LPAD(r.QTD, 5));
    END LOOP;

    SELECT COUNT(*) INTO v_total FROM TB_AMANAJE_ALERTA;
    IF v_total = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Nenhum alerta encontrado na base.');
    ELSIF v_total < 5 THEN
        DBMS_OUTPUT.PUT_LINE('  Base com poucos alertas para demonstração: ' || v_total);
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Total de alertas avaliados no bloco: ' || v_total);
    END IF;

    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum dado encontrado no bloco 1.1.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 1.1 falhou: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

   -- ## 1.2 — Telemetria, clima externo e qualidade da carga.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_invalidas NUMBER;
BEGIN

    -- ### CONSULTA A: Última leitura por estação
    --                (JOIN: CLIENTE ⟶ REGIAO ⟶ ESTACAO ⟶ LEITURA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.2-A: Última Leitura por Estação');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('REGIÃO', 32) || RPAD('ESTAÇÃO', 30) || RPAD('DATA', 18) || LPAD('ÁGUA%', 7) || LPAD('INCL', 7) || LPAD('PM25', 7) || LPAD('PM10', 7) || LPAD('OK', 4));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            x.NM_REGIAO,
            x.NM_EST,
            TO_CHAR(x.DT_LEIT, 'DD/MM HH24:MI') AS DT_REF,
            x.NR_NIVEL_AGUA_PCT,
            x.NR_INCL_GRAUS,
            x.NR_PM25,
            x.NR_PM10,
            x.ST_VALIDA
        FROM (
            SELECT
                rm.NM_REGIAO,
                ei.NM_EST,
                li.DT_LEIT,
                li.NR_NIVEL_AGUA_PCT,
                li.NR_INCL_GRAUS,
                li.NR_PM25,
                li.NR_PM10,
                li.ST_VALIDA,
                ROW_NUMBER() OVER (PARTITION BY ei.ID_ESTACAO ORDER BY li.DT_LEIT DESC) AS RN
            FROM TB_AMANAJE_REGIAO_MONIT rm
                JOIN TB_AMANAJE_EST_IOT ei ON rm.ID_REGIAO = ei.ID_REGIAO
                JOIN TB_AMANAJE_LEIT_IOT li ON ei.ID_ESTACAO = li.ID_ESTACAO
        ) x
        WHERE x.RN = 1
        ORDER BY x.NM_REGIAO
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.NM_REGIAO, 1, 30), 32) || RPAD(SUBSTR(r.NM_EST, 1, 28), 30) || RPAD(r.DT_REF, 18) || LPAD(NVL(TO_CHAR(r.NR_NIVEL_AGUA_PCT), 'N/D'), 7) || LPAD(NVL(TO_CHAR(r.NR_INCL_GRAUS, 'FM990.0'), 'N/D'), 7) || LPAD(NVL(TO_CHAR(r.NR_PM25), 'N/D'), 7) || LPAD(NVL(TO_CHAR(r.NR_PM10), 'N/D'), 7) || LPAD(r.ST_VALIDA, 4));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA B: Observações climáticas externas por localidade
    --                (JOIN: REGIAO ⟶ OBS_CLIM)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.2-B: Observações Climáticas Externas por Localidade');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('UF/CIDADE', 28) || LPAD('OBS', 5) || LPAD('TEMP', 8) || LPAD('UMID', 8) || LPAD('PRECIP', 9) || LPAD('VENTO', 8) || LPAD('UV MÁX', 8));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            rm.SG_ESTADO || '/' || rm.NM_CIDADE AS LOCALIDADE,
            COUNT(oc.ID_OBSERVACAO) AS QTD_OBS,
            ROUND(AVG(oc.NR_TEMPERATURA_C), 1) AS TEMP_MED,
            ROUND(AVG(oc.NR_UMIDADE_PCT), 1) AS UMID_MED,
            ROUND(SUM(oc.NR_PRECIP_MM), 1) AS PRECIP_TOTAL,
            ROUND(AVG(oc.NR_VENTO_KMH), 1) AS VENTO_MED,
            MAX(oc.NR_INDICE_UV) AS UV_MAX
        FROM TB_AMANAJE_REGIAO_MONIT rm
            JOIN TB_AMANAJE_OBS_CLIM oc ON rm.ID_REGIAO = oc.ID_REGIAO
        GROUP BY rm.SG_ESTADO, rm.NM_CIDADE
        ORDER BY PRECIP_TOTAL DESC, TEMP_MED DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.LOCALIDADE, 1, 26), 28) || LPAD(r.QTD_OBS, 5) || LPAD(TO_CHAR(r.TEMP_MED, 'FM990.0'), 8) || LPAD(TO_CHAR(r.UMID_MED, 'FM990.0'), 8) || LPAD(TO_CHAR(r.PRECIP_TOTAL, 'FM990.0'), 9) || LPAD(TO_CHAR(r.VENTO_MED, 'FM990.0'), 8) || LPAD(TO_CHAR(r.UV_MAX, 'FM990.0'), 8));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ### CONSULTA C: Leituras inválidas para auditoria
    --                (JOIN: REGIAO ⟶ ESTACAO ⟶ LEITURA)
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 1.2-C: Leituras Inválidas para Auditoria');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('REGIÃO', 32) || RPAD('ESTAÇÃO', 30) || RPAD('DATA', 18) || RPAD('MOTIVO', 40));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN (
        SELECT
            rm.NM_REGIAO,
            ei.NM_EST,
            TO_CHAR(li.DT_LEIT, 'DD/MM/YYYY HH24:MI') AS DT_REF,
            li.DS_MOTIVO_INVAL
        FROM TB_AMANAJE_REGIAO_MONIT rm
            JOIN TB_AMANAJE_EST_IOT ei ON rm.ID_REGIAO = ei.ID_REGIAO
            JOIN TB_AMANAJE_LEIT_IOT li ON ei.ID_ESTACAO = li.ID_ESTACAO
        WHERE li.ST_VALIDA = 'N'
        ORDER BY li.DT_LEIT DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.NM_REGIAO, 1, 30), 32) || RPAD(SUBSTR(r.NM_EST, 1, 28), 30) || RPAD(r.DT_REF, 18) || RPAD(SUBSTR(r.DS_MOTIVO_INVAL, 1, 38), 40));
    END LOOP;

    SELECT COUNT(*) INTO v_invalidas FROM TB_AMANAJE_LEIT_IOT WHERE ST_VALIDA = 'N';
    IF v_invalidas = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Nenhuma leitura inválida encontrada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Total de leituras inválidas: ' || v_invalidas);
    END IF;

    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum dado encontrado no bloco 1.2.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 1.2 falhou: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 2 — TESTE DE BLOCO COM LAG / LEAD
  ──────────────────────────────────────────────────────────────────────────────
*/

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_ant_str VARCHAR2(12);
    v_prx_str VARCHAR2(12);
    v_tend VARCHAR2(20);

    CURSOR c_evol_risco IS
        SELECT
            rm.NM_REGIAO,
            ar.TP_RISCO,
            TO_CHAR(ar.DT_AVAL, 'DD/MM HH24:MI') AS DT_AVAL_FMT,
            ar.NR_SCORE_RISCO AS SCORE_ATUAL,
            LAG(ar.NR_SCORE_RISCO) OVER (PARTITION BY ar.ID_REGIAO, ar.TP_RISCO ORDER BY ar.DT_AVAL) AS SCORE_ANT,
            LEAD(ar.NR_SCORE_RISCO) OVER (PARTITION BY ar.ID_REGIAO, ar.TP_RISCO ORDER BY ar.DT_AVAL) AS SCORE_PRX,
            ar.TP_NIVEL_RISCO
        FROM TB_AMANAJE_AVAL_RISCO ar
            JOIN TB_AMANAJE_REGIAO_MONIT rm ON ar.ID_REGIAO = rm.ID_REGIAO
        ORDER BY rm.NM_REGIAO, ar.TP_RISCO, ar.DT_AVAL;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  RELATÓRIO 2: Evolução de Score — Linha Anterior / Atual / Próxima');
    DBMS_OUTPUT.PUT_LINE('  Tabela: TB_AMANAJE_AVAL_RISCO  |  Coluna: NR_SCORE_RISCO');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('REGIÃO', 30) || RPAD('RISCO', 15) || RPAD('DATA', 13) || LPAD('ANT', 7) || LPAD('ATUAL', 8) || LPAD('PRÓX', 7) || RPAD(' NÍVEL', 12) || RPAD('TENDÊNCIA', 18));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    FOR r IN c_evol_risco LOOP
        IF r.SCORE_ANT IS NULL THEN
            v_ant_str := 'Vazio';
            v_tend := 'Inicial';
        ELSE
            v_ant_str := TO_CHAR(r.SCORE_ANT);
            IF r.SCORE_ATUAL > r.SCORE_ANT THEN
                v_tend := 'Subiu';
            ELSIF r.SCORE_ATUAL < r.SCORE_ANT THEN
                v_tend := 'Caiu';
            ELSE
                v_tend := 'Estável';
            END IF;
        END IF;

        IF r.SCORE_PRX IS NULL THEN
            v_prx_str := 'Vazio';
        ELSE
            v_prx_str := TO_CHAR(r.SCORE_PRX);
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(r.NM_REGIAO, 1, 28), 30) || RPAD(r.TP_RISCO, 15) || RPAD(r.DT_AVAL_FMT, 13) || LPAD(v_ant_str, 7) || LPAD(r.SCORE_ATUAL, 8) || LPAD(v_prx_str, 7) || RPAD(' ' || r.TP_NIVEL_RISCO, 12) || RPAD(v_tend, 18));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  Observação: "Vazio" indica ausência de avaliação anterior ou seguinte no mesmo risco/região.');
    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhuma avaliação encontrada no bloco 2.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 2 falhou: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 3 — TESTE DE BLOCOS ANÔNIMOS COM CURSOR EXPLÍCITO E TOMADA DE DECISÃO
  ──────────────────────────────────────────────────────────────────────────────
*/

   -- ## 3.1 — RELATÓRIO DE PRIORIZAÇÃO DE REGIÕES
   --         Lista regiões, calcula dados auxiliares com SELECT INTO e classifica prioridade.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_qtd_est NUMBER;
    v_qtd_abertos NUMBER;
    v_score_max NUMBER;
    v_prioridade VARCHAR2(20);

    CURSOR c_regioes IS
        SELECT
            rm.ID_REGIAO,
            c.NM_CLI,
            c.TP_CLI,
            rm.NM_REGIAO,
            rm.SG_ESTADO,
            rm.NM_CIDADE,
            rm.NR_NIVEL_VULN,
            rm.TP_VISIB
        FROM TB_AMANAJE_REGIAO_MONIT rm
            JOIN TB_AMANAJE_CLI c ON rm.ID_CLIENTE = c.ID_CLIENTE
        WHERE rm.ST_ATIVO = 'S'
        ORDER BY rm.NR_NIVEL_VULN DESC, rm.NM_REGIAO;

    v_reg c_regioes%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.1: PRIORIZAÇÃO DE REGIÕES MONITORADAS');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(RPAD('REGIÃO', 31) || RPAD('CLIENTE', 34) || LPAD('VULN', 6) || LPAD('EST', 5) || LPAD('ABERTOS', 9) || LPAD('MAX', 6) || RPAD(' PRIORIDADE', 18));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_regioes;
    LOOP
        FETCH c_regioes INTO v_reg;
        EXIT WHEN c_regioes%NOTFOUND;

        SELECT COUNT(*)
        INTO v_qtd_est
        FROM TB_AMANAJE_EST_IOT
        WHERE ID_REGIAO = v_reg.ID_REGIAO;

        SELECT COUNT(*)
        INTO v_qtd_abertos
        FROM TB_AMANAJE_ALERTA
        WHERE ID_REGIAO = v_reg.ID_REGIAO
          AND ST_ALERTA IN ('ABERTO', 'EM_ANALISE');

        SELECT NVL(MAX(NR_SCORE_RISCO), 0)
        INTO v_score_max
        FROM TB_AMANAJE_AVAL_RISCO
        WHERE ID_REGIAO = v_reg.ID_REGIAO;

        IF v_score_max >= 75 OR v_qtd_abertos >= 2 THEN
            v_prioridade := 'Imediata';
        ELSIF v_score_max >= 50 OR v_reg.NR_NIVEL_VULN >= 70 THEN
            v_prioridade := 'Alta';
        ELSIF v_score_max >= 25 THEN
            v_prioridade := 'Acompanhamento';
        ELSE
            v_prioridade := 'Rotina';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(v_reg.NM_REGIAO, 1, 29), 31) || RPAD(SUBSTR(v_reg.NM_CLI, 1, 32), 34) || LPAD(v_reg.NR_NIVEL_VULN, 6) || LPAD(v_qtd_est, 5) || LPAD(v_qtd_abertos, 9) || LPAD(v_score_max, 6) || RPAD(' ' || v_prioridade, 18));
    END LOOP;
    CLOSE c_regioes;

    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Dados insuficientes para priorização de regiões.');
        IF c_regioes%ISOPEN THEN CLOSE c_regioes; END IF;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 3.1 falhou: ' || SQLCODE || ' - ' || SQLERRM);
        IF c_regioes%ISOPEN THEN CLOSE c_regioes; END IF;
END;
/

   -- ## 3.2 — RELATÓRIO OPERACIONAL DE ALERTAS
   --         Lista alertas, traduz status e calcula estatísticas de resposta.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_status_desc VARCHAR2(30);
    v_acao_desc VARCHAR2(30);
    v_total NUMBER := 0;
    v_abertos NUMBER := 0;
    v_analise NUMBER := 0;
    v_resolvidos NUMBER := 0;
    v_criticos NUMBER := 0;

    CURSOR c_alertas IS
        SELECT
            al.ID_ALERTA,
            al.TP_ALERTA,
            al.TP_NIVEL,
            al.ST_ALERTA,
            al.DT_ALERTA,
            al.DT_RESOLVIDO_EM,
            rm.NM_REGIAO,
            c.NM_CLI
        FROM TB_AMANAJE_ALERTA al
            JOIN TB_AMANAJE_REGIAO_MONIT rm ON al.ID_REGIAO = rm.ID_REGIAO
            JOIN TB_AMANAJE_CLI c ON rm.ID_CLIENTE = c.ID_CLIENTE
        ORDER BY al.TP_NIVEL DESC, al.DT_ALERTA;

    v_alerta c_alertas%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.2: RELATÓRIO OPERACIONAL DE ALERTAS');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('REGIÃO', 28) || RPAD('TIPO', 15) || RPAD('NÍVEL', 11) || RPAD('STATUS', 24) || RPAD('AÇÃO', 28));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_alertas;
    LOOP
        FETCH c_alertas INTO v_alerta;
        EXIT WHEN c_alertas%NOTFOUND;

        v_total := v_total + 1;

        CASE v_alerta.ST_ALERTA
            WHEN 'ABERTO' THEN
                v_status_desc := 'Aberto';
                v_abertos := v_abertos + 1;
            WHEN 'EM_ANALISE' THEN
                v_status_desc := 'Em análise';
                v_analise := v_analise + 1;
            WHEN 'RESOLVIDO' THEN
                v_status_desc := 'Resolvido';
                v_resolvidos := v_resolvidos + 1;
            WHEN 'CANCELADO' THEN
                v_status_desc := 'Cancelado';
            ELSE
                v_status_desc := '[?] ' || v_alerta.ST_ALERTA;
        END CASE;

        IF v_alerta.TP_NIVEL = 'CRITICO' THEN
            v_criticos := v_criticos + 1;
            v_acao_desc := 'Acionar resposta imediata';
        ELSIF v_alerta.TP_NIVEL = 'ALTO' THEN
            v_acao_desc := 'Priorizar acompanhamento';
        ELSIF v_alerta.TP_NIVEL = 'MODERADO' THEN
            v_acao_desc := 'Monitorar evolução';
        ELSE
            v_acao_desc := 'Registrar histórico';
        END IF;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_alerta.ID_ALERTA, 4) || '  ' || RPAD(SUBSTR(v_alerta.NM_REGIAO, 1, 26), 28) || RPAD(v_alerta.TP_ALERTA, 15) || RPAD(v_alerta.TP_NIVEL, 11) || RPAD(v_status_desc, 24) || RPAD(v_acao_desc, 28));
    END LOOP;
    CLOSE c_alertas;

    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  RESUMO DOS ALERTAS');
    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Total              : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('  Abertos            : ' || v_abertos);
    DBMS_OUTPUT.PUT_LINE('  Em análise         : ' || v_analise);
    DBMS_OUTPUT.PUT_LINE('  Resolvidos         : ' || v_resolvidos);
    DBMS_OUTPUT.PUT_LINE('  Críticos           : ' || v_criticos);
    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum alerta encontrado.');
        IF c_alertas%ISOPEN THEN CLOSE c_alertas; END IF;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 3.2 falhou: ' || SQLCODE || ' - ' || SQLERRM);
        IF c_alertas%ISOPEN THEN CLOSE c_alertas; END IF;
END;
/

   -- ## 3.3 — RELATÓRIO DE PROCESSAMENTOS E LOGS TÉCNICOS
   --         Usa cursor explícito com WHILE para avaliar status de rotinas.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_status_desc VARCHAR2(30);
    v_resultado VARCHAR2(28);
    v_total NUMBER := 0;
    v_falhas NUMBER := 0;

    CURSOR c_process IS
        SELECT
            pr.ID_PROCESSAMENTO,
            pr.TP_PROCESS,
            pr.ST_PROCESS,
            pr.DS_ORIGEM,
            ROUND((CAST(NVL(pr.DT_FIM, SYSTIMESTAMP) AS DATE) - CAST(pr.DT_INICIO AS DATE)) * 1440, 1) AS MINUTOS,
            NVL(rm.NM_REGIAO, 'Processo geral') AS NM_REGIAO,
            NVL(u.NM_USU, 'Sem usuário') AS NM_USU,
            COUNT(le.ID_LOG_ERRO) AS QTD_ERROS
        FROM TB_AMANAJE_PROCESS pr
            LEFT JOIN TB_AMANAJE_REGIAO_MONIT rm ON pr.ID_REGIAO = rm.ID_REGIAO
            LEFT JOIN TB_AMANAJE_USU u ON pr.ID_USUARIO = u.ID_USUARIO
            LEFT JOIN TB_AMANAJE_LOG_ERRO le ON pr.ID_PROCESSAMENTO = le.ID_PROCESSAMENTO
        GROUP BY pr.ID_PROCESSAMENTO, pr.TP_PROCESS, pr.ST_PROCESS, pr.DS_ORIGEM, pr.DT_INICIO, pr.DT_FIM, rm.NM_REGIAO, u.NM_USU
        ORDER BY pr.DT_INICIO;

    v_proc c_process%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.3: PROCESSAMENTOS E LOGS TÉCNICOS');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('TIPO', 19) || RPAD('STATUS', 22) || LPAD('MIN', 7) || LPAD('ERROS', 7) || RPAD(' RESULTADO', 28) || RPAD('ORIGEM', 26));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_process;
    FETCH c_process INTO v_proc;
    WHILE c_process%FOUND LOOP
        v_total := v_total + 1;

        CASE v_proc.ST_PROCESS
            WHEN 'CONCLUIDO' THEN
                v_status_desc := 'Concluído';
            WHEN 'FALHOU' THEN
                v_status_desc := 'Falhou';
                v_falhas := v_falhas + 1;
            WHEN 'CANCELADO' THEN
                v_status_desc := 'Cancelado';
            WHEN 'EM_EXECUCAO' THEN
                v_status_desc := 'Em execução';
            WHEN 'INICIADO' THEN
                v_status_desc := 'Iniciado';
            ELSE
                v_status_desc := '[?] ' || v_proc.ST_PROCESS;
        END CASE;

        IF v_proc.QTD_ERROS > 0 THEN
            v_resultado := 'Revisar log técnico';
        ELSIF v_proc.ST_PROCESS = 'CONCLUIDO' THEN
            v_resultado := 'Evidência válida';
        ELSIF v_proc.ST_PROCESS = 'CANCELADO' THEN
            v_resultado := 'Sem efeito operacional';
        ELSE
            v_resultado := 'Acompanhar execução';
        END IF;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_proc.ID_PROCESSAMENTO, 4) || '  ' || RPAD(v_proc.TP_PROCESS, 19) || RPAD(v_status_desc, 22) || LPAD(TO_CHAR(v_proc.MINUTOS, 'FM990.0'), 7) || LPAD(v_proc.QTD_ERROS, 7) || RPAD(' ' || v_resultado, 28) || RPAD(SUBSTR(v_proc.DS_ORIGEM, 1, 24), 26));

        FETCH c_process INTO v_proc;
    END LOOP;
    CLOSE c_process;

    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Total de processamentos: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('  Processamentos com falha: ' || v_falhas);
    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum processamento encontrado.');
        IF c_process%ISOPEN THEN CLOSE c_process; END IF;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 3.3 falhou: ' || SQLCODE || ' - ' || SQLERRM);
        IF c_process%ISOPEN THEN CLOSE c_process; END IF;
END;
/

   -- ## 3.4 — RELATÓRIO DE INDICADORES REGIONAIS
   --         Cursor explícito, decisão por faixa de score e consolidação por nível.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_faixa VARCHAR2(24);
    v_baixo NUMBER := 0;
    v_moderado NUMBER := 0;
    v_alto NUMBER := 0;
    v_critico NUMBER := 0;

    CURSOR c_ind IS
        SELECT
            ir.ID_INDICADOR,
            NVL(ir.NM_REGIAO, 'Agregado público') AS NM_REGIAO,
            ir.SG_ESTADO,
            ir.NM_CIDADE,
            ir.TP_RISCO,
            ir.NR_SCORE_MEDIO,
            ir.TP_NIVEL_RISCO_MEDIO,
            ir.QT_ESTACOES,
            ir.QT_ALERTAS_ATIVOS
        FROM TB_AMANAJE_IND_REG ir
        ORDER BY ir.NR_SCORE_MEDIO DESC, ir.SG_ESTADO, ir.NM_CIDADE;

    v_ind c_ind%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 3.4: INDICADORES REGIONAIS AGREGADOS');
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE(LPAD('ID', 4) || '  ' || RPAD('LOCAL', 30) || RPAD('RISCO', 16) || LPAD('SCORE', 8) || RPAD(' NÍVEL', 12) || LPAD('EST', 5) || LPAD('ALT', 5) || RPAD(' FAIXA', 24));
    DBMS_OUTPUT.PUT_LINE(v_lin);

    OPEN c_ind;
    LOOP
        FETCH c_ind INTO v_ind;
        EXIT WHEN c_ind%NOTFOUND;

        IF v_ind.TP_NIVEL_RISCO_MEDIO = 'CRITICO' THEN
            v_faixa := 'Ação imediata';
            v_critico := v_critico + 1;
        ELSIF v_ind.TP_NIVEL_RISCO_MEDIO = 'ALTO' THEN
            v_faixa := 'Prioridade alta';
            v_alto := v_alto + 1;
        ELSIF v_ind.TP_NIVEL_RISCO_MEDIO = 'MODERADO' THEN
            v_faixa := 'Monitoramento';
            v_moderado := v_moderado + 1;
        ELSE
            v_faixa := 'Normalidade';
            v_baixo := v_baixo + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_ind.ID_INDICADOR, 4) || '  ' || RPAD(SUBSTR(NVL(v_ind.NM_CIDADE, 'BR') || '/' || NVL(v_ind.SG_ESTADO, 'BR'), 1, 28), 30) || RPAD(v_ind.TP_RISCO, 16) || LPAD(v_ind.NR_SCORE_MEDIO, 8) || RPAD(' ' || v_ind.TP_NIVEL_RISCO_MEDIO, 12) || LPAD(v_ind.QT_ESTACOES, 5) || LPAD(v_ind.QT_ALERTAS_ATIVOS, 5) || RPAD(' ' || v_faixa, 24));
    END LOOP;
    CLOSE c_ind;

    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Indicadores por nível: BAIXO=' || v_baixo || ' | MODERADO=' || v_moderado || ' | ALTO=' || v_alto || ' | CRITICO=' || v_critico);
    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum indicador regional encontrado.');
        IF c_ind%ISOPEN THEN CLOSE c_ind; END IF;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 3.4 falhou: ' || SQLCODE || ' - ' || SQLERRM);
        IF c_ind%ISOPEN THEN CLOSE c_ind; END IF;
END;
/

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 4 — TESTE CONTROLADO DE MANIPULAÇÃO DE DADOS COM VARIÁVEIS
  ──────────────────────────────────────────────────────────────────────────────
*/

   -- ## 4.1 — Simulação de avanço de status de alerta
   --         Demonstra SELECT INTO, UPDATE com variável e ROLLBACK para preservar a carga.

DECLARE
    v_sep VARCHAR2(120) := RPAD('=', 120, '=');
    v_lin VARCHAR2(120) := RPAD('-', 120, '-');
    v_id_alerta TB_AMANAJE_ALERTA.ID_ALERTA%TYPE;
    v_status_ant TB_AMANAJE_ALERTA.ST_ALERTA%TYPE;
    v_status_novo TB_AMANAJE_ALERTA.ST_ALERTA%TYPE := 'EM_ANALISE';
    v_status_grav TB_AMANAJE_ALERTA.ST_ALERTA%TYPE;
    v_status_final TB_AMANAJE_ALERTA.ST_ALERTA%TYPE;
    v_titulo TB_AMANAJE_ALERTA.DS_TITULO%TYPE;
    v_linhas NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_sep);
    DBMS_OUTPUT.PUT_LINE('  CONSULTA 4.1: SIMULAÇÃO CONTROLADA DE UPDATE EM ALERTA');
    DBMS_OUTPUT.PUT_LINE(v_sep);

    SAVEPOINT SP_AMANAJE_DQL;

    SELECT ID_ALERTA, ST_ALERTA, DS_TITULO
    INTO v_id_alerta, v_status_ant, v_titulo
    FROM (
        SELECT ID_ALERTA, ST_ALERTA, DS_TITULO
        FROM TB_AMANAJE_ALERTA
        WHERE ST_ALERTA = 'ABERTO'
          AND TP_NIVEL IN ('CRITICO', 'ALTO')
        ORDER BY CASE TP_NIVEL WHEN 'CRITICO' THEN 1 ELSE 2 END, DT_ALERTA
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('  Alerta selecionado : ' || v_id_alerta || ' - ' || v_titulo);
    DBMS_OUTPUT.PUT_LINE('  Status original    : ' || v_status_ant);

    UPDATE TB_AMANAJE_ALERTA
    SET ST_ALERTA = v_status_novo,
        DT_ATUALIZADO_EM = SYSTIMESTAMP
    WHERE ID_ALERTA = v_id_alerta;

    v_linhas := SQL%ROWCOUNT;

    SELECT ST_ALERTA
    INTO v_status_grav
    FROM TB_AMANAJE_ALERTA
    WHERE ID_ALERTA = v_id_alerta;

    IF v_linhas = 1 AND v_status_grav = v_status_novo THEN
        DBMS_OUTPUT.PUT_LINE('  Update simulado    : OK, status temporário = ' || v_status_grav);
    ELSIF v_linhas = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Update simulado    : nenhum registro alterado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Update simulado    : revisar resultado.');
    END IF;

    ROLLBACK TO SP_AMANAJE_DQL;

    SELECT ST_ALERTA
    INTO v_status_final
    FROM TB_AMANAJE_ALERTA
    WHERE ID_ALERTA = v_id_alerta;

    DBMS_OUTPUT.PUT_LINE(v_lin);
    DBMS_OUTPUT.PUT_LINE('  Status após rollback: ' || v_status_final);
    DBMS_OUTPUT.PUT_LINE('  Carga oficial preservada: ' || CASE WHEN v_status_final = v_status_ant THEN 'SIM' ELSE 'NÃO' END);
    DBMS_OUTPUT.PUT_LINE(v_sep);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Nenhum alerta aberto ALTO/CRITICO encontrado para simulação.');
        ROLLBACK TO SP_AMANAJE_DQL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  [ERRO] Bloco 4.1 falhou: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK TO SP_AMANAJE_DQL;
END;
/

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================

FIM DO SCRIPT

  Total de blocos executados:
  ──────────────────────────────────────────────────────────────────────────────
   2 Blocos anônimos de exibição com JOINs     (Teste 1)
   1 Bloco com LAG / LEAD                      (Teste 2)
   4 Blocos com cursor explícito e decisão     (Teste 3)
   1 Bloco controlado com UPDATE + ROLLBACK    (Teste 4)
  ──────────────────────────────────────────────────────────────────────────────
   Total geral: 8 blocos anônimos PL/SQL;
   Todos os blocos possuem tratamento de exceções!
*/
