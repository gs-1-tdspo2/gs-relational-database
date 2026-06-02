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
   # 1 ─  Procedure de carga + registro de erros;
   # 2 ─  Procedures de carga para demais tabelas (13 tabelas = 13 subseções);
   # 3 ─  Chamadas de carga via procedures (13 procedures = 13 subseções);
  ──────────────────────────────────────────────────────────────────────────────
   PADRÃO DE EXCEÇÕES ADOTADO EM TODAS AS PROCEDURES:
  ──────────────────────────────────────────────────────────────────────────────
    1. WHEN DUP_VAL_ON_INDEX = violação de UNIQUE ou PRIMARY KEY   (ORA-00001)
    2. WHEN e_check_violado  = violação de constraint CHECK        (ORA-02290)
    3. WHEN OTHERS           = captura genérica

   *Nota: Ao ocorrer qualquer exceção, 'origem', 'objeto', 'código do erro',
   'mensagem do erro' e 'comando/etapa' são gravados em "TB_AMANAJE_LOG_ERRO"
   (via AUTONOMOUS_TRANSACTION).
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

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 1 ─ REGISTRO COM PR_AMANAJE_REG_ERRO + CARGA EM TB_AMANAJE_LOG_ERRO;
  ──────────────────────────────────────────────────────────────────────────────
*/
CREATE OR REPLACE PROCEDURE
    PR_AMANAJE_REG_ERRO (p_nm_objeto IN VARCHAR2, p_cd_erro IN NUMBER, p_ds_erro IN VARCHAR2)
        IS PRAGMA AUTONOMOUS_TRANSACTION;

    e_dup_log EXCEPTION;
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dup_log, -1);
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);

BEGIN
    INSERT INTO TB_AMANAJE_LOG_ERRO (NM_ORIGEM, NM_OBJETO, CD_ERRO, DS_ERRO, DS_COMANDO, DT_ERRO)
        VALUES ('DML', SUBSTR(p_nm_objeto, 1, 120), p_cd_erro, SUBSTR(p_ds_erro, 1, 1000), 'Carga via procedure DML', SYSTIMESTAMP);
    COMMIT;

EXCEPTION
    WHEN e_dup_log THEN NULL;
    WHEN e_check_violado THEN NULL;
    WHEN OTHERS THEN NULL;
END PR_AMANAJE_REG_ERRO;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 2 — PROCEDURES DE CARGA DE DADOS (uma por tabela — 13 tabelas)
  ──────────────────────────────────────────────────────────────────────────────
*/
  -- ## 2.01 — TB_AMANAJE_CLI
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_CLIENTE (
    p_nm_cliente IN TB_AMANAJE_CLI.NM_CLI%TYPE,
    p_tp_cliente IN TB_AMANAJE_CLI.TP_CLI%TYPE,
    p_nr_documento IN TB_AMANAJE_CLI.NR_DOCUMENTO%TYPE,
    p_ds_email_contato IN TB_AMANAJE_CLI.DS_EMAIL_CONTATO%TYPE,
    p_nr_telefone IN TB_AMANAJE_CLI.NR_TELEFONE%TYPE,
    p_st_ativo IN TB_AMANAJE_CLI.ST_ATIVO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_CLIENTE';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_CLI (
        NM_CLI, TP_CLI, NR_DOCUMENTO, DS_EMAIL_CONTATO, NR_TELEFONE, ST_ATIVO
    ) VALUES (
        p_nm_cliente, p_tp_cliente, p_nr_documento, p_ds_email_contato, p_nr_telefone, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Cliente duplicado [' || p_nm_cliente || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em cliente: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_CLIENTE;
/

  -- ## 2.02 — TB_AMANAJE_USU
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_USUARIO (
    p_id_cliente IN TB_AMANAJE_USU.ID_CLIENTE%TYPE,
    p_nm_usuario IN TB_AMANAJE_USU.NM_USU%TYPE,
    p_ds_email IN TB_AMANAJE_USU.DS_EMAIL%TYPE,
    p_ds_senha_hash IN TB_AMANAJE_USU.DS_SENHA_HASH%TYPE,
    p_tp_perfil IN TB_AMANAJE_USU.TP_PERFIL%TYPE,
    p_st_usuario IN TB_AMANAJE_USU.ST_USU%TYPE,
    p_st_ativo IN TB_AMANAJE_USU.ST_ATIVO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_USUARIO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_USU (
        ID_CLIENTE, NM_USU, DS_EMAIL, DS_SENHA_HASH, TP_PERFIL, ST_USU, ST_ATIVO
    ) VALUES (
        p_id_cliente, p_nm_usuario, p_ds_email, p_ds_senha_hash, p_tp_perfil, NVL(p_st_usuario, 'ATIVO'), NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Usuário duplicado [' || p_ds_email || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em usuário: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_USUARIO;
/

  -- ## 2.03 — TB_AMANAJE_REGIAO_MONIT
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_REGIAO (
    p_id_cliente IN TB_AMANAJE_REGIAO_MONIT.ID_CLIENTE%TYPE,
    p_nm_regiao IN TB_AMANAJE_REGIAO_MONIT.NM_REGIAO%TYPE,
    p_nm_cidade IN TB_AMANAJE_REGIAO_MONIT.NM_CIDADE%TYPE,
    p_sg_estado IN TB_AMANAJE_REGIAO_MONIT.SG_ESTADO%TYPE,
    p_nr_latitude IN TB_AMANAJE_REGIAO_MONIT.NR_LATITUDE%TYPE,
    p_nr_longitude IN TB_AMANAJE_REGIAO_MONIT.NR_LONGITUDE%TYPE,
    p_tp_area IN TB_AMANAJE_REGIAO_MONIT.TP_AREA%TYPE,
    p_nr_nivel_vulnerabilidade IN TB_AMANAJE_REGIAO_MONIT.NR_NIVEL_VULN%TYPE,
    p_tp_visibilidade IN TB_AMANAJE_REGIAO_MONIT.TP_VISIB%TYPE,
    p_st_ativo IN TB_AMANAJE_REGIAO_MONIT.ST_ATIVO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_REGIAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_REGIAO_MONIT (
        ID_CLIENTE, NM_REGIAO, NM_CIDADE, SG_ESTADO, NR_LATITUDE, NR_LONGITUDE,
        TP_AREA, NR_NIVEL_VULN, TP_VISIB, ST_ATIVO
    ) VALUES (
        p_id_cliente, p_nm_regiao, p_nm_cidade, UPPER(p_sg_estado), p_nr_latitude, p_nr_longitude,
        p_tp_area, p_nr_nivel_vulnerabilidade, NVL(p_tp_visibilidade, 'PRIVADA'), NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Região duplicada [' || p_nm_regiao || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em região: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_REGIAO;
/

  -- ## 2.04 — TB_AMANAJE_EST_IOT
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_ESTACAO (
    p_id_regiao IN TB_AMANAJE_EST_IOT.ID_REGIAO%TYPE,
    p_cd_estacao IN TB_AMANAJE_EST_IOT.CD_EST%TYPE,
    p_nm_estacao IN TB_AMANAJE_EST_IOT.NM_EST%TYPE,
    p_tp_estacao IN TB_AMANAJE_EST_IOT.TP_EST%TYPE,
    p_st_estacao IN TB_AMANAJE_EST_IOT.ST_EST%TYPE,
    p_nr_latitude IN TB_AMANAJE_EST_IOT.NR_LATITUDE%TYPE,
    p_nr_longitude IN TB_AMANAJE_EST_IOT.NR_LONGITUDE%TYPE,
    p_dt_ultima_comunicacao IN TB_AMANAJE_EST_IOT.DT_ULTIMA_COM%TYPE,
    p_st_ativo IN TB_AMANAJE_EST_IOT.ST_ATIVO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_ESTACAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_EST_IOT (
        ID_REGIAO, CD_EST, NM_EST, TP_EST, ST_EST,
        NR_LATITUDE, NR_LONGITUDE, DT_ULTIMA_COM, ST_ATIVO
    ) VALUES (
        p_id_regiao, p_cd_estacao, p_nm_estacao, p_tp_estacao, NVL(p_st_estacao, 'ATIVA'),
        p_nr_latitude, p_nr_longitude, p_dt_ultima_comunicacao, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Estação duplicada [' || p_cd_estacao || ']: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em estação: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_ESTACAO;
/

  -- ## 2.05 — TB_AMANAJE_LEIT_IOT
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_LEITURA (
    p_id_estacao IN TB_AMANAJE_LEIT_IOT.ID_ESTACAO%TYPE,
    p_id_regiao IN TB_AMANAJE_LEIT_IOT.ID_REGIAO%TYPE,
    p_nr_distancia_agua_cm IN TB_AMANAJE_LEIT_IOT.NR_DISTANCIA_AGUA_CM%TYPE,
    p_nr_nivel_agua_pct IN TB_AMANAJE_LEIT_IOT.NR_NIVEL_AGUA_PCT%TYPE,
    p_nr_inclinacao_graus IN TB_AMANAJE_LEIT_IOT.NR_INCL_GRAUS%TYPE,
    p_nr_vibracao IN TB_AMANAJE_LEIT_IOT.NR_VIBRACAO%TYPE,
    p_nr_pressao_hpa IN TB_AMANAJE_LEIT_IOT.NR_PRESSAO_HPA%TYPE,
    p_nr_pm25 IN TB_AMANAJE_LEIT_IOT.NR_PM25%TYPE,
    p_nr_pm10 IN TB_AMANAJE_LEIT_IOT.NR_PM10%TYPE,
    p_dt_leitura IN TB_AMANAJE_LEIT_IOT.DT_LEIT%TYPE,
    p_st_valida IN TB_AMANAJE_LEIT_IOT.ST_VALIDA%TYPE,
    p_ds_motivo_invalidacao IN TB_AMANAJE_LEIT_IOT.DS_MOTIVO_INVAL%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_LEITURA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_LEIT_IOT (
        ID_ESTACAO, ID_REGIAO, NR_DISTANCIA_AGUA_CM, NR_NIVEL_AGUA_PCT,
        NR_INCL_GRAUS, NR_VIBRACAO, NR_PRESSAO_HPA, NR_PM25, NR_PM10,
        DT_LEIT, ST_VALIDA, DS_MOTIVO_INVAL
    ) VALUES (
        p_id_estacao, p_id_regiao, p_nr_distancia_agua_cm, p_nr_nivel_agua_pct,
        p_nr_inclinacao_graus, p_nr_vibracao, p_nr_pressao_hpa, p_nr_pm25, p_nr_pm10,
        p_dt_leitura, NVL(p_st_valida, 'S'), p_ds_motivo_invalidacao
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_LEIT_IOT: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em leitura: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_LEITURA;
/

  -- ## 2.06 — TB_AMANAJE_OBS_CLIM
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_OBSERVACAO (
    p_id_regiao IN TB_AMANAJE_OBS_CLIM.ID_REGIAO%TYPE,
    p_nm_fonte IN TB_AMANAJE_OBS_CLIM.NM_FONTE%TYPE,
    p_nr_temperatura_c IN TB_AMANAJE_OBS_CLIM.NR_TEMPERATURA_C%TYPE,
    p_nr_umidade_pct IN TB_AMANAJE_OBS_CLIM.NR_UMIDADE_PCT%TYPE,
    p_nr_precipitacao_mm IN TB_AMANAJE_OBS_CLIM.NR_PRECIP_MM%TYPE,
    p_nr_vento_kmh IN TB_AMANAJE_OBS_CLIM.NR_VENTO_KMH%TYPE,
    p_nr_pressao_hpa IN TB_AMANAJE_OBS_CLIM.NR_PRESSAO_HPA%TYPE,
    p_nr_radiacao_solar IN TB_AMANAJE_OBS_CLIM.NR_RADIACAO_SOLAR%TYPE,
    p_nr_indice_uv IN TB_AMANAJE_OBS_CLIM.NR_INDICE_UV%TYPE,
    p_dt_observacao IN TB_AMANAJE_OBS_CLIM.DT_OBS%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_OBSERVACAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_OBS_CLIM (
        ID_REGIAO, NM_FONTE, NR_TEMPERATURA_C, NR_UMIDADE_PCT, NR_PRECIP_MM,
        NR_VENTO_KMH, NR_PRESSAO_HPA, NR_RADIACAO_SOLAR, NR_INDICE_UV, DT_OBS
    ) VALUES (
        p_id_regiao, p_nm_fonte, p_nr_temperatura_c, p_nr_umidade_pct, p_nr_precipitacao_mm,
        p_nr_vento_kmh, p_nr_pressao_hpa, p_nr_radiacao_solar, p_nr_indice_uv, p_dt_observacao
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_OBS_CLIM: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em observação climática: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_OBSERVACAO;
/

  -- ## 2.07 — TB_AMANAJE_AVAL_RISCO
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_AVALIACAO (
    p_id_regiao IN TB_AMANAJE_AVAL_RISCO.ID_REGIAO%TYPE,
    p_id_leitura IN TB_AMANAJE_AVAL_RISCO.ID_LEITURA%TYPE,
    p_id_observacao IN TB_AMANAJE_AVAL_RISCO.ID_OBSERVACAO%TYPE,
    p_tp_risco IN TB_AMANAJE_AVAL_RISCO.TP_RISCO%TYPE,
    p_nr_score_risco IN TB_AMANAJE_AVAL_RISCO.NR_SCORE_RISCO%TYPE,
    p_tp_nivel_risco IN TB_AMANAJE_AVAL_RISCO.TP_NIVEL_RISCO%TYPE,
    p_ds_motivo IN TB_AMANAJE_AVAL_RISCO.DS_MOTIVO%TYPE,
    p_dt_avaliacao IN TB_AMANAJE_AVAL_RISCO.DT_AVAL%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_AVALIACAO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_AVAL_RISCO (
        ID_REGIAO, ID_LEITURA, ID_OBSERVACAO, TP_RISCO, NR_SCORE_RISCO,
        TP_NIVEL_RISCO, DS_MOTIVO, DT_AVAL
    ) VALUES (
        p_id_regiao, p_id_leitura, p_id_observacao, p_tp_risco, p_nr_score_risco,
        p_tp_nivel_risco, p_ds_motivo, NVL(p_dt_avaliacao, CAST(SYSTIMESTAMP AS TIMESTAMP))
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_AVAL_RISCO: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em avaliação de risco: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_AVALIACAO;
/

  -- ## 2.08 — TB_AMANAJE_ALERTA
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_ALERTA (
    p_id_regiao IN TB_AMANAJE_ALERTA.ID_REGIAO%TYPE,
    p_id_avaliacao IN TB_AMANAJE_ALERTA.ID_AVALIACAO%TYPE,
    p_tp_alerta IN TB_AMANAJE_ALERTA.TP_ALERTA%TYPE,
    p_tp_nivel IN TB_AMANAJE_ALERTA.TP_NIVEL%TYPE,
    p_ds_titulo IN TB_AMANAJE_ALERTA.DS_TITULO%TYPE,
    p_ds_alerta IN TB_AMANAJE_ALERTA.DS_ALERTA%TYPE,
    p_ds_recomendacao IN TB_AMANAJE_ALERTA.DS_RECOM%TYPE,
    p_st_alerta IN TB_AMANAJE_ALERTA.ST_ALERTA%TYPE,
    p_dt_alerta IN TB_AMANAJE_ALERTA.DT_ALERTA%TYPE,
    p_dt_resolvido_em IN TB_AMANAJE_ALERTA.DT_RESOLVIDO_EM%TYPE,
    p_st_ativo IN TB_AMANAJE_ALERTA.ST_ATIVO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_ALERTA';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_ALERTA (
        ID_REGIAO, ID_AVALIACAO, TP_ALERTA, TP_NIVEL, DS_TITULO, DS_ALERTA,
        DS_RECOM, ST_ALERTA, DT_ALERTA, DT_RESOLVIDO_EM, ST_ATIVO
    ) VALUES (
        p_id_regiao, p_id_avaliacao, p_tp_alerta, p_tp_nivel, p_ds_titulo, p_ds_alerta,
        p_ds_recomendacao, NVL(p_st_alerta, 'ABERTO'), NVL(p_dt_alerta, CAST(SYSTIMESTAMP AS TIMESTAMP)), p_dt_resolvido_em, NVL(p_st_ativo, 'S')
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_ALERTA: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em alerta: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_ALERTA;
/

  -- ## 2.09 — TB_AMANAJE_IND_REG
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_INDICADOR (
    p_id_regiao IN TB_AMANAJE_IND_REG.ID_REGIAO%TYPE,
    p_sg_estado IN TB_AMANAJE_IND_REG.SG_ESTADO%TYPE,
    p_nm_cidade IN TB_AMANAJE_IND_REG.NM_CIDADE%TYPE,
    p_nm_regiao IN TB_AMANAJE_IND_REG.NM_REGIAO%TYPE,
    p_tp_risco IN TB_AMANAJE_IND_REG.TP_RISCO%TYPE,
    p_nr_score_medio IN TB_AMANAJE_IND_REG.NR_SCORE_MEDIO%TYPE,
    p_tp_nivel_risco_medio IN TB_AMANAJE_IND_REG.TP_NIVEL_RISCO_MEDIO%TYPE,
    p_qt_estacoes IN TB_AMANAJE_IND_REG.QT_ESTACOES%TYPE,
    p_qt_alertas_ativos IN TB_AMANAJE_IND_REG.QT_ALERTAS_ATIVOS%TYPE,
    p_nm_fonte_calculo IN TB_AMANAJE_IND_REG.NM_FONTE_CALCULO%TYPE,
    p_dt_calculo IN TB_AMANAJE_IND_REG.DT_CALCULO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_INDICADOR';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_IND_REG (
        ID_REGIAO, SG_ESTADO, NM_CIDADE, NM_REGIAO, TP_RISCO, NR_SCORE_MEDIO,
        TP_NIVEL_RISCO_MEDIO, QT_ESTACOES, QT_ALERTAS_ATIVOS, NM_FONTE_CALCULO, DT_CALCULO
    ) VALUES (
        p_id_regiao, UPPER(p_sg_estado), p_nm_cidade, p_nm_regiao, p_tp_risco, p_nr_score_medio,
        p_tp_nivel_risco_medio, NVL(p_qt_estacoes, 0), NVL(p_qt_alertas_ativos, 0), p_nm_fonte_calculo, NVL(p_dt_calculo, CAST(SYSTIMESTAMP AS TIMESTAMP))
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_IND_REG: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em indicador: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_INDICADOR;
/

  -- ## 2.10 — TB_AMANAJE_HIST_EVENTO
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_HIST_EVENTO (
    p_id_usuario IN TB_AMANAJE_HIST_EVENTO.ID_USUARIO%TYPE,
    p_nm_entidade IN TB_AMANAJE_HIST_EVENTO.NM_ENTIDADE%TYPE,
    p_id_entidade IN TB_AMANAJE_HIST_EVENTO.ID_ENTIDADE%TYPE,
    p_tp_acao IN TB_AMANAJE_HIST_EVENTO.TP_ACAO%TYPE,
    p_ds_evento IN TB_AMANAJE_HIST_EVENTO.DS_EVENTO%TYPE,
    p_dt_evento IN TB_AMANAJE_HIST_EVENTO.DT_EVENTO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_HIST_EVENTO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_HIST_EVENTO (
        ID_USUARIO, NM_ENTIDADE, ID_ENTIDADE, TP_ACAO, DS_EVENTO, DT_EVENTO
    ) VALUES (
        p_id_usuario, p_nm_entidade, p_id_entidade, p_tp_acao, p_ds_evento, NVL(p_dt_evento, CAST(SYSTIMESTAMP AS TIMESTAMP))
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_HIST_EVENTO: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em histórico: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_HIST_EVENTO;
/

  -- ## 2.11 — TB_AMANAJE_LOG_STATUS_EST
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_LOG_STATUS (
    p_id_estacao IN TB_AMANAJE_LOG_STATUS_EST.ID_ESTACAO%TYPE,
    p_nr_uptime_seg IN TB_AMANAJE_LOG_STATUS_EST.NR_UPTIME_SEG%TYPE,
    p_nr_rssi IN TB_AMANAJE_LOG_STATUS_EST.NR_RSSI%TYPE,
    p_ds_ip_address IN TB_AMANAJE_LOG_STATUS_EST.DS_IP_ADDRESS%TYPE,
    p_ds_versao_firmware IN TB_AMANAJE_LOG_STATUS_EST.DS_VERSAO_FIRMWARE%TYPE,
    p_dt_registro IN TB_AMANAJE_LOG_STATUS_EST.DT_REGISTRO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_LOG_STATUS';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_LOG_STATUS_EST (
        ID_ESTACAO, NR_UPTIME_SEG, NR_RSSI, DS_IP_ADDRESS, DS_VERSAO_FIRMWARE, DT_REGISTRO
    ) VALUES (
        p_id_estacao, p_nr_uptime_seg, p_nr_rssi, p_ds_ip_address, p_ds_versao_firmware, NVL(p_dt_registro, CAST(SYSTIMESTAMP AS TIMESTAMP))
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_LOG_STATUS_EST: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em log de estação: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_LOG_STATUS;
/

  -- ## 2.12 — TB_AMANAJE_PROCESS
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_PROCESSAMENTO (
    p_id_regiao IN TB_AMANAJE_PROCESS.ID_REGIAO%TYPE,
    p_id_usuario IN TB_AMANAJE_PROCESS.ID_USUARIO%TYPE,
    p_tp_processamento IN TB_AMANAJE_PROCESS.TP_PROCESS%TYPE,
    p_st_processamento IN TB_AMANAJE_PROCESS.ST_PROCESS%TYPE,
    p_ds_origem IN TB_AMANAJE_PROCESS.DS_ORIGEM%TYPE,
    p_ds_parametros IN TB_AMANAJE_PROCESS.DS_PARAM%TYPE,
    p_ds_resultado IN TB_AMANAJE_PROCESS.DS_RESULT%TYPE,
    p_dt_inicio IN TB_AMANAJE_PROCESS.DT_INICIO%TYPE,
    p_dt_fim IN TB_AMANAJE_PROCESS.DT_FIM%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_PROCESSAMENTO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_PROCESS (
        ID_REGIAO, ID_USUARIO, TP_PROCESS, ST_PROCESS, DS_ORIGEM,
        DS_PARAM, DS_RESULT, DT_INICIO, DT_FIM
    ) VALUES (
        p_id_regiao, p_id_usuario, p_tp_processamento, NVL(p_st_processamento, 'INICIADO'), p_ds_origem,
        p_ds_parametros, p_ds_resultado, NVL(p_dt_inicio, CAST(SYSTIMESTAMP AS TIMESTAMP)), p_dt_fim
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_PROCESS: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em processamento: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_PROCESSAMENTO;
/

  -- ## 2.13 — TB_AMANAJE_LOG_ERRO
CREATE OR REPLACE PROCEDURE PR_AMANAJE_INS_LOG_ERRO (
    p_id_processamento IN TB_AMANAJE_LOG_ERRO.ID_PROCESSAMENTO%TYPE,
    p_id_usuario IN TB_AMANAJE_LOG_ERRO.ID_USUARIO%TYPE,
    p_nm_origem IN TB_AMANAJE_LOG_ERRO.NM_ORIGEM%TYPE,
    p_nm_objeto IN TB_AMANAJE_LOG_ERRO.NM_OBJETO%TYPE,
    p_cd_erro IN TB_AMANAJE_LOG_ERRO.CD_ERRO%TYPE,
    p_ds_erro IN TB_AMANAJE_LOG_ERRO.DS_ERRO%TYPE,
    p_ds_comando IN TB_AMANAJE_LOG_ERRO.DS_COMANDO%TYPE,
    p_dt_erro IN TB_AMANAJE_LOG_ERRO.DT_ERRO%TYPE
) IS
    c_nm_proc CONSTANT VARCHAR2(100) := 'PR_AMANAJE_INS_LOG_ERRO';
    e_check_violado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_violado, -2290);
BEGIN
    INSERT INTO TB_AMANAJE_LOG_ERRO (
        ID_PROCESSAMENTO, ID_USUARIO, NM_ORIGEM, NM_OBJETO, CD_ERRO, DS_ERRO, DS_COMANDO, DT_ERRO
    ) VALUES (
        p_id_processamento, p_id_usuario, p_nm_origem, p_nm_objeto, p_cd_erro, p_ds_erro, p_ds_comando, NVL(p_dt_erro, CAST(SYSTIMESTAMP AS TIMESTAMP))
    );
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Registro duplicado em TB_AMANAJE_LOG_ERRO: ' || SQLERRM);
    WHEN e_check_violado THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE,
            'Violação de CHECK em log de erro: ' || SQLERRM);
    WHEN OTHERS THEN
        PR_AMANAJE_REG_ERRO(c_nm_proc, SQLCODE, SQLERRM);
END PR_AMANAJE_INS_LOG_ERRO;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================
   # 3 — CHAMADAS DE CARGA DE DADOS (uma por procedure — 13 blocos)
  ──────────────────────────────────────────────────────────────────────────────
*/
  -- ## 3.01 — TB_AMANAJE_CLI
BEGIN
    PR_AMANAJE_INS_CLIENTE('Prefeitura Municipal de Porto Alegre', 'GOVERNO_DEFESA_CIVIL', '92796354000140', 'defesacivil@portoalegre.rs.gov.br', '5132889000', 'S');
    PR_AMANAJE_INS_CLIENTE('Defesa Civil Municipal de Manaus', 'GOVERNO_DEFESA_CIVIL', '04427530000151', 'monitoramento@manaus.am.gov.br', '9232126000', 'S');
    PR_AMANAJE_INS_CLIENTE('Instituto Amazônia Resiliente', 'ONG', '18264092000187', 'contato@amazoniaresiliente.org.br', '9335221100', 'S');
    PR_AMANAJE_INS_CLIENTE('Cooperativa Agroclima Cerrado', 'COOPERATIVA', '30188765000113', 'operacoes@agroclimacerrado.coop.br', '6635442100', 'S');
    PR_AMANAJE_INS_CLIENTE('Fazenda Santa Helena Monitorada', 'FAZENDA_PRIVADO', '11784055000190', 'gestao@santahelenaagro.com.br', '7436114500', 'S');
    PR_AMANAJE_INS_CLIENTE('Universidade de Pesquisa Climática do Brasil', 'PESQUISA_UNIVERSIDADE', '70542166000108', 'labclima@upcb.edu.br', '1636027700', 'S');
    COMMIT;
END;
/

  -- ## 3.02 — TB_AMANAJE_USU
BEGIN
    PR_AMANAJE_INS_USUARIO(1, 'Ana Paula Rocha', 'ana.rocha@portoalegre.rs.gov.br', '$2a$10$amanaje-demo-ana', 'OPERADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(1, 'Bruno Siqueira', 'bruno.siqueira@portoalegre.rs.gov.br', '$2a$10$amanaje-demo-bruno', 'ANALISTA', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(2, 'Camila Nogueira', 'camila.nogueira@manaus.am.gov.br', '$2a$10$amanaje-demo-camila', 'OPERADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(3, 'Diego Araújo', 'diego.araujo@amazoniaresiliente.org.br', '$2a$10$amanaje-demo-diego', 'ADMINISTRADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(3, 'Eliane Costa', 'eliane.costa@amazoniaresiliente.org.br', '$2a$10$amanaje-demo-eliane', 'VISUALIZADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(4, 'Fábio Ribeiro', 'fabio.ribeiro@agroclimacerrado.coop.br', '$2a$10$amanaje-demo-fabio', 'OPERADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(5, 'Gabriela Martins', 'gabriela.martins@santahelenaagro.com.br', '$2a$10$amanaje-demo-gabriela', 'OPERADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(6, 'Henrique Vidal', 'henrique.vidal@upcb.edu.br', '$2a$10$amanaje-demo-henrique', 'ANALISTA', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(2, 'Íris Lacerda', 'iris.lacerda@manaus.am.gov.br', '$2a$10$amanaje-demo-iris', 'VISUALIZADOR', 'ATIVO', 'S');
    PR_AMANAJE_INS_USUARIO(4, 'João Pedro Almeida', 'joao.almeida@agroclimacerrado.coop.br', '$2a$10$amanaje-demo-joao', 'ADMINISTRADOR', 'ATIVO', 'S');
    COMMIT;
END;
/

  -- ## 3.03 — TB_AMANAJE_REGIAO_MONIT
BEGIN
    PR_AMANAJE_INS_REGIAO(1, 'Cais Mauá - Porto Alegre', 'Porto Alegre', 'RS', -30.0277, -51.2287, 'AREA_URBANA', 88, 'INSTITUCIONAL', 'S');
    PR_AMANAJE_INS_REGIAO(1, 'Arroio Dilúvio - Ponte Ipiranga', 'Porto Alegre', 'RS', -30.0507, -51.1834, 'PONTE', 81, 'INSTITUCIONAL', 'S');
    PR_AMANAJE_INS_REGIAO(2, 'Comunidade Ribeirinha Educandos', 'Manaus', 'AM', -3.1333, -60.0151, 'REGIAO_RIBEIRINHA', 76, 'INSTITUCIONAL', 'S');
    PR_AMANAJE_INS_REGIAO(3, 'Projeto Santarém Ribeirinho', 'Santarém', 'PA', -2.4385, -54.6996, 'REGIAO_RIBEIRINHA', 69, 'AGREGADA_PUBLICA', 'S');
    PR_AMANAJE_INS_REGIAO(3, 'Encosta Vila Nova Esperança', 'Manaus', 'AM', -3.1024, -60.0254, 'ENCOSTA', 72, 'INSTITUCIONAL', 'S');
    PR_AMANAJE_INS_REGIAO(4, 'Talhão Sorriso Norte', 'Sorriso', 'MT', -12.5424, -55.721, 'AREA_RURAL', 55, 'PRIVADA', 'S');
    PR_AMANAJE_INS_REGIAO(5, 'Fazenda Santa Helena - Juazeiro', 'Juazeiro', 'BA', -9.416, -40.503, 'PROPRIEDADE_PRIVADA', 63, 'PRIVADA', 'S');
    PR_AMANAJE_INS_REGIAO(6, 'Campus Climático Ribeirão Preto', 'Ribeirão Preto', 'SP', -21.1775, -47.8103, 'AREA_URBANA', 48, 'AGREGADA_PUBLICA', 'S');
    COMMIT;
END;
/

  -- ## 3.04 — TB_AMANAJE_EST_IOT
BEGIN
    PR_AMANAJE_INS_ESTACAO(1, 'AMANAJE-RS-POA-001', 'Estação Cais Mauá Nível do Guaíba', 'SIMULADA', 'ATIVA', -30.0277, -51.2287, TO_TIMESTAMP('2026-05-31 08:50:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(2, 'AMANAJE-RS-POA-002', 'Estação Ponte Ipiranga Arroio Dilúvio', 'REAL', 'ATIVA', -30.0507, -51.1834, TO_TIMESTAMP('2026-05-31 08:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(3, 'AMANAJE-AM-MAO-001', 'Estação Ribeirinha Educandos', 'SIMULADA', 'ATIVA', -3.1333, -60.0151, TO_TIMESTAMP('2026-05-31 08:42:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(4, 'AMANAJE-PA-STM-001', 'Estação Referência Santarém Tapajós', 'REFERENCIA', 'ATIVA', -2.4385, -54.6996, TO_TIMESTAMP('2026-05-31 08:35:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(5, 'AMANAJE-AM-MAO-002', 'Estação Encosta Vila Nova Esperança', 'SIMULADA', 'SEM_COM', -3.1024, -60.0254, TO_TIMESTAMP('2026-05-30 21:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(6, 'AMANAJE-MT-SOR-001', 'Estação Talhão Sorriso Norte A', 'REAL', 'ATIVA', -12.5424, -55.721, TO_TIMESTAMP('2026-05-31 08:40:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(6, 'AMANAJE-MT-SOR-002', 'Estação Referência Sorriso B', 'REFERENCIA', 'ATIVA', -12.5601, -55.7042, TO_TIMESTAMP('2026-05-31 08:38:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(7, 'AMANAJE-BA-JUA-001', 'Estação Fazenda Santa Helena Canal', 'REAL', 'ATIVA', -9.416, -40.503, TO_TIMESTAMP('2026-05-31 08:33:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(8, 'AMANAJE-SP-RP-001', 'Estação Referência Ribeirão Preto Centro', 'REFERENCIA', 'ATIVA', -21.1775, -47.8103, TO_TIMESTAMP('2026-05-31 08:36:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    PR_AMANAJE_INS_ESTACAO(8, 'AMANAJE-SP-RP-002', 'Estação Simulada Ribeirão Preto PM2.5', 'SIMULADA', 'FALHA', -21.1892, -47.8019, TO_TIMESTAMP('2026-05-31 06:25:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    COMMIT;
END;
/

  -- ## 3.05 — TB_AMANAJE_LEIT_IOT
BEGIN
    PR_AMANAJE_INS_LEITURA(1, 1, 38, 86, 4.5, 0.13, 997.6, 22, 45, TO_TIMESTAMP('2026-05-31 06:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(1, 1, 34, 90, 4.9, 0.16, 996.8, 25, 48, TO_TIMESTAMP('2026-05-31 07:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(1, 1, 31, 93, 5.2, 0.18, 996.2, 28, 52, TO_TIMESTAMP('2026-05-31 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(2, 2, 44, 79, 7.5, 0.22, 998.1, 18, 33, TO_TIMESTAMP('2026-05-31 06:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(2, 2, 41, 82, 8.4, 0.26, 997.2, 20, 35, TO_TIMESTAMP('2026-05-31 07:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(2, 2, 39, 84, 8.9, 0.29, 996.9, 21, 36, TO_TIMESTAMP('2026-05-31 08:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(3, 3, 42, 88, 3.5, 0.11, 1001.3, 30, 54, TO_TIMESTAMP('2026-05-31 06:20:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(3, 3, 40, 91, 3.8, 0.12, 1000.8, 34, 60, TO_TIMESTAMP('2026-05-31 07:20:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(3, 3, 39, 93, 4.1, 0.14, 1000.2, 38, 66, TO_TIMESTAMP('2026-05-31 08:20:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(4, 4, 62, 58, 2.1, 0.08, 1005.4, 19, 31, TO_TIMESTAMP('2026-05-31 06:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(4, 4, 58, 63, 2.4, 0.09, 1004.9, 22, 34, TO_TIMESTAMP('2026-05-31 07:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(4, 4, 57, 65, 2.7, 0.1, 1004.5, 24, 37, TO_TIMESTAMP('2026-05-31 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(5, 5, 95, 24, 24.8, 0.78, 999.4, 35, 58, TO_TIMESTAMP('2026-05-31 06:40:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(5, 5, 92, 27, 26.3, 0.85, 998.7, 39, 63, TO_TIMESTAMP('2026-05-31 07:40:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(5, 5, 90, 30, 27.1, 0.91, 998.1, 42, 69, TO_TIMESTAMP('2026-05-31 08:40:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(6, 6, 145, 18, 1.5, 0.05, 1009.1, 51, 88, TO_TIMESTAMP('2026-05-31 06:50:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(6, 6, 144, 19, 1.6, 0.06, 1008.7, 63, 104, TO_TIMESTAMP('2026-05-31 07:50:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(7, 6, 150, 15, 1.3, 0.04, 1008.4, 58, 96, TO_TIMESTAMP('2026-05-31 08:50:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(8, 7, 170, 12, 1.1, 0.04, 1011.2, 72, 128, TO_TIMESTAMP('2026-05-31 06:55:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(8, 7, 172, 10, 1.2, 0.05, 1010.9, 78, 140, TO_TIMESTAMP('2026-05-31 07:55:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(8, 7, 174, 9, 1.3, 0.05, 1010.3, 83, 148, TO_TIMESTAMP('2026-05-31 08:55:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(9, 8, 130, 21, 1.4, 0.05, 1007.8, 118, 180, TO_TIMESTAMP('2026-05-31 06:05:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(9, 8, 131, 20, 1.5, 0.05, 1007.2, 126, 193, TO_TIMESTAMP('2026-05-31 07:05:00', 'YYYY-MM-DD HH24:MI:SS'), 'S', NULL);
    PR_AMANAJE_INS_LEITURA(10, 8, 128, 22, 1.6, 0.06, 1006.9, 135, 205, TO_TIMESTAMP('2026-05-31 08:05:00', 'YYYY-MM-DD HH24:MI:SS'), 'N', 'Pico de PM10 acima da faixa simulada; mantido para teste de invalidação lógica');
    COMMIT;
END;
/

  -- ## 3.06 — TB_AMANAJE_OBS_CLIM
BEGIN
    PR_AMANAJE_INS_OBSERVACAO(1, 'Open-Meteo MVP', 18.7, 94, 42.5, 38, 997.1, 180, 2.0, TO_TIMESTAMP('2026-05-31 06:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(1, 'Open-Meteo MVP', 19.1, 96, 48.2, 42, 996.4, 160, 2.1, TO_TIMESTAMP('2026-05-31 08:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(2, 'Open-Meteo MVP', 18.9, 93, 35.1, 36, 997.9, 190, 2.0, TO_TIMESTAMP('2026-05-31 06:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(2, 'Open-Meteo MVP', 19.3, 95, 39.4, 40, 997.0, 170, 2.2, TO_TIMESTAMP('2026-05-31 08:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(3, 'Open-Meteo MVP', 27.4, 91, 31.2, 24, 1001.1, 520, 8.5, TO_TIMESTAMP('2026-05-31 06:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(3, 'Open-Meteo MVP', 28.1, 88, 28.8, 27, 1000.4, 640, 9.2, TO_TIMESTAMP('2026-05-31 08:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(4, 'Open-Meteo MVP', 29.2, 84, 18.6, 22, 1005.0, 710, 10.5, TO_TIMESTAMP('2026-05-31 06:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(4, 'Open-Meteo MVP', 30.0, 81, 14.3, 25, 1004.3, 790, 11.4, TO_TIMESTAMP('2026-05-31 08:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(5, 'Open-Meteo MVP', 28.5, 89, 22.9, 30, 999.0, 560, 8.9, TO_TIMESTAMP('2026-05-31 06:40:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(5, 'Open-Meteo MVP', 29.0, 87, 19.7, 33, 998.3, 610, 9.4, TO_TIMESTAMP('2026-05-31 08:40:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(6, 'Open-Meteo MVP', 31.8, 42, 0.0, 18, 1009.5, 900, 12.7, TO_TIMESTAMP('2026-05-31 06:50:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(6, 'Open-Meteo MVP', 33.1, 38, 0.0, 21, 1008.8, 980, 13.6, TO_TIMESTAMP('2026-05-31 08:50:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(7, 'Open-Meteo MVP', 35.2, 31, 0.0, 14, 1011.0, 1030, 14.2, TO_TIMESTAMP('2026-05-31 06:55:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(7, 'Open-Meteo MVP', 36.0, 29, 0.0, 16, 1010.5, 1100, 15.1, TO_TIMESTAMP('2026-05-31 08:55:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(8, 'Open-Meteo MVP', 32.7, 35, 0.0, 12, 1007.7, 980, 13.9, TO_TIMESTAMP('2026-05-31 06:05:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_OBSERVACAO(8, 'Open-Meteo MVP', 33.5, 33, 0.0, 15, 1007.0, 1050, 14.6, TO_TIMESTAMP('2026-05-31 08:05:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.07 — TB_AMANAJE_AVAL_RISCO
BEGIN
    PR_AMANAJE_INS_AVALIACAO(1, 1, 1, 'ENCHENTE', 86, 'CRITICO', 'Nível de água acima de 85% no Cais Mauá e chuva acumulada elevada.', TO_TIMESTAMP('2026-05-31 08:05:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(1, 2, 2, 'TEMPESTADE', 68, 'ALTO', 'Queda de pressão, rajadas fortes e precipitação persistente.', TO_TIMESTAMP('2026-05-31 08:06:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(1, 1, 1, 'QUALIDADE_AR', 42, 'MODERADO', 'Material particulado em atenção, sem ultrapassar limite crítico.', TO_TIMESTAMP('2026-05-31 08:07:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(2, 4, 3, 'ENCHENTE', 74, 'ALTO', 'Arroio Dilúvio em elevação rápida próximo à ponte monitorada.', TO_TIMESTAMP('2026-05-31 08:12:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(2, 5, 4, 'TEMPESTADE', 51, 'ALTO', 'Chuva e vento exigem acompanhamento operacional da travessia.', TO_TIMESTAMP('2026-05-31 08:13:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(2, 4, 3, 'DESLIZAMENTO', 33, 'MODERADO', 'Inclinação em atenção, sem vibração crítica.', TO_TIMESTAMP('2026-05-31 08:14:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(3, 7, 5, 'ENCHENTE', 82, 'CRITICO', 'Comunidade ribeirinha com nível de água acima de 85% e chuva recente.', TO_TIMESTAMP('2026-05-31 08:25:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(3, 8, 6, 'TEMPESTADE', 62, 'ALTO', 'Umidade elevada e pressão em queda indicam instabilidade atmosférica.', TO_TIMESTAMP('2026-05-31 08:26:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(3, 7, 5, 'QUALIDADE_AR', 28, 'MODERADO', 'PM2.5 em elevação moderada para região urbana ribeirinha.', TO_TIMESTAMP('2026-05-31 08:27:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(4, 10, 7, 'ENCHENTE', 55, 'ALTO', 'Elevação do Tapajós exige alerta institucional preventivo.', TO_TIMESTAMP('2026-05-31 08:35:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(4, 11, 8, 'TEMPESTADE', 46, 'MODERADO', 'Instabilidade moderada com vento e precipitação local.', TO_TIMESTAMP('2026-05-31 08:36:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(4, 12, 7, 'QUALIDADE_AR', 31, 'MODERADO', 'Particulados em atenção por variação regional de fumaça.', TO_TIMESTAMP('2026-05-31 08:37:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(5, 13, 9, 'DESLIZAMENTO', 90, 'CRITICO', 'Inclinação e vibração altas em encosta com vulnerabilidade elevada.', TO_TIMESTAMP('2026-05-31 08:45:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(5, 14, 10, 'TEMPESTADE', 58, 'ALTO', 'Chuva e pressão baixa elevam risco operacional na encosta.', TO_TIMESTAMP('2026-05-31 08:46:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(5, 13, 9, 'ENCHENTE', 39, 'MODERADO', 'Baixo nível de água, mas precipitação recente mantém atenção.', TO_TIMESTAMP('2026-05-31 08:47:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(6, 16, 11, 'TEMPESTADE', 44, 'MODERADO', 'Calor e baixa umidade com vento moderado no talhão.', TO_TIMESTAMP('2026-05-31 08:55:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(6, 17, 12, 'QUALIDADE_AR', 65, 'ALTO', 'Material particulado elevado em área agrícola durante período seco.', TO_TIMESTAMP('2026-05-31 08:56:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(6, 18, 11, 'ENCHENTE', 21, 'BAIXO', 'Sem precipitação e nível hídrico baixo para a área rural.', TO_TIMESTAMP('2026-05-31 08:57:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(7, 19, 13, 'QUALIDADE_AR', 73, 'ALTO', 'Calor, seca e PM10 alto indicam risco à saúde e operação.', TO_TIMESTAMP('2026-05-31 09:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(7, 20, 14, 'TEMPESTADE', 26, 'MODERADO', 'Condição seca reduz tempestade, mas vento mantém acompanhamento.', TO_TIMESTAMP('2026-05-31 09:01:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(7, 21, 14, 'ENCHENTE', 16, 'BAIXO', 'Sem chuva e nível de água baixo no canal monitorado.', TO_TIMESTAMP('2026-05-31 09:02:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(8, 22, 15, 'QUALIDADE_AR', 76, 'CRITICO', 'PM2.5 e PM10 elevados em indicador de referência urbano.', TO_TIMESTAMP('2026-05-31 08:15:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(8, 23, 16, 'TEMPESTADE', 34, 'MODERADO', 'Pressão estável e baixa chuva, com calor em atenção.', TO_TIMESTAMP('2026-05-31 08:16:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_AVALIACAO(8, 24, 15, 'ENCHENTE', 12, 'BAIXO', 'Sem precipitação e sem indicação de nível hídrico crítico.', TO_TIMESTAMP('2026-05-31 08:17:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.08 — TB_AMANAJE_ALERTA
BEGIN
    PR_AMANAJE_INS_ALERTA(1, 1, 'ENCHENTE', 'CRITICO', 'Risco crítico de enchente no Cais Mauá', 'Nível de água e chuva acumulada indicam risco crítico para área urbana vulnerável.', 'Acionar protocolo de monitoramento contínuo, equipes de campo e comunicação institucional.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:10:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(1, 2, 'TEMPESTADE', 'ALTO', 'Instabilidade atmosférica em Porto Alegre', 'Pressão em queda e vento forte podem afetar a operação próxima ao Guaíba.', 'Acompanhar boletins e preparar equipe para chuva intensa nas próximas horas.', 'EM_ANALISE', TO_TIMESTAMP('2026-05-31 08:12:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(2, 4, 'ENCHENTE', 'ALTO', 'Elevação no Arroio Dilúvio', 'Leitura de nível de água alta na ponte Ipiranga.', 'Monitorar tráfego local e avaliar interdição preventiva se o nível continuar subindo.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:18:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(3, 7, 'ENCHENTE', 'CRITICO', 'Alerta crítico em comunidade ribeirinha', 'Comunidade Educandos registra nível hídrico crítico e chuva recente.', 'Priorizar contato com liderança local e preparar rota de apoio.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(3, 8, 'TEMPESTADE', 'ALTO', 'Instabilidade em Manaus', 'Umidade, pressão e precipitação elevam risco operacional.', 'Manter equipe de plantão e revisar pontos de abrigo próximos.', 'EM_ANALISE', TO_TIMESTAMP('2026-05-31 08:31:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(4, 10, 'ENCHENTE', 'ALTO', 'Risco hidrológico em Santarém', 'Elevação do nível de água em região ribeirinha acompanhada pela ONG.', 'Notificar coordenação do projeto e reforçar acompanhamento comunitário.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:40:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(5, 13, 'DESLIZAMENTO', 'CRITICO', 'Deslizamento crítico na encosta monitorada', 'Inclinação e vibração acima do limite operacional seguro.', 'Acionar vistoria imediata e orientar afastamento preventivo da área.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:50:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(5, 14, 'TEMPESTADE', 'ALTO', 'Chuva aumenta risco na encosta', 'Condição atmosférica amplia instabilidade em talude vulnerável.', 'Evitar permanência na área e acompanhar evolução da vibração.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:52:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(6, 17, 'QUALIDADE_AR', 'ALTO', 'Material particulado alto em Sorriso', 'PM2.5 e PM10 indicam atenção para operação agrícola.', 'Recomendar EPIs, reduzir exposição e avaliar origem da fumaça/poeira.', 'ABERTO', TO_TIMESTAMP('2026-05-31 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(7, 19, 'QUALIDADE_AR', 'ALTO', 'Qualidade do ar ruim em Juazeiro', 'Calor e partículas elevadas aumentam risco para trabalhadores em campo.', 'Orientar pausas, hidratação e restrição de atividades externas em pico de calor.', 'EM_ANALISE', TO_TIMESTAMP('2026-05-31 09:05:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(8, 22, 'QUALIDADE_AR', 'CRITICO', 'PM crítico em Ribeirão Preto', 'Indicador urbano de referência aponta material particulado crítico.', 'Emitir alerta de saúde pública e reforçar acompanhamento regional.', 'ABERTO', TO_TIMESTAMP('2026-05-31 08:20:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 'S');
    PR_AMANAJE_INS_ALERTA(8, 23, 'TEMPESTADE', 'MODERADO', 'Risco moderado resolvido em Ribeirão Preto', 'Instabilidade moderada sem evolução nas últimas leituras.', 'Manter histórico e sem necessidade de ação imediata.', 'RESOLVIDO', TO_TIMESTAMP('2026-05-31 08:22:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'S');
    COMMIT;
END;
/

  -- ## 3.09 — TB_AMANAJE_IND_REG
BEGIN
    PR_AMANAJE_INS_INDICADOR(1, 'RS', 'Porto Alegre', 'Cais Mauá - Porto Alegre', 'ENCHENTE', 86, 'CRITICO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(1, 'RS', 'Porto Alegre', 'Cais Mauá - Porto Alegre', 'TEMPESTADE', 68, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:11:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(2, 'RS', 'Porto Alegre', 'Arroio Dilúvio - Ponte Ipiranga', 'ENCHENTE', 74, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:12:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(2, 'RS', 'Porto Alegre', 'Arroio Dilúvio - Ponte Ipiranga', 'DESLIZAMENTO', 33, 'MODERADO', 1, 0, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:13:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(3, 'AM', 'Manaus', 'Comunidade Ribeirinha Educandos', 'ENCHENTE', 82, 'CRITICO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:14:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(3, 'AM', 'Manaus', 'Comunidade Ribeirinha Educandos', 'TEMPESTADE', 62, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:15:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(4, 'PA', 'Santarém', 'Projeto Santarém Ribeirinho', 'ENCHENTE', 55, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:16:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(4, 'PA', 'Santarém', 'Projeto Santarém Ribeirinho', 'QUALIDADE_AR', 31, 'MODERADO', 1, 0, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:17:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(5, 'AM', 'Manaus', 'Encosta Vila Nova Esperança', 'DESLIZAMENTO', 90, 'CRITICO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:18:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(5, 'AM', 'Manaus', 'Encosta Vila Nova Esperança', 'TEMPESTADE', 58, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:19:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(6, 'MT', 'Sorriso', 'Talhão Sorriso Norte', 'QUALIDADE_AR', 65, 'ALTO', 2, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(6, 'MT', 'Sorriso', 'Talhão Sorriso Norte', 'ENCHENTE', 21, 'BAIXO', 2, 0, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:21:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(7, 'BA', 'Juazeiro', 'Fazenda Santa Helena - Juazeiro', 'QUALIDADE_AR', 73, 'ALTO', 1, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:22:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(7, 'BA', 'Juazeiro', 'Fazenda Santa Helena - Juazeiro', 'ENCHENTE', 16, 'BAIXO', 1, 0, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:23:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(8, 'SP', 'Ribeirão Preto', 'Campus Climático Ribeirão Preto', 'QUALIDADE_AR', 76, 'CRITICO', 2, 1, 'DML Seed Amanajé', TO_TIMESTAMP('2026-05-31 09:24:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_INDICADOR(NULL, 'BR', 'Indicadores Regionais Agregados', NULL, 'TEMPESTADE', 46, 'MODERADO', 10, 4, 'DML Seed Amanajé - agregado público', TO_TIMESTAMP('2026-05-31 09:25:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.10 — TB_AMANAJE_HIST_EVENTO
BEGIN
    PR_AMANAJE_INS_HIST_EVENTO(1, 'TB_AMANAJE_CLI', 1, 'CRIACAO', 'Cliente Prefeitura Municipal de Porto Alegre criado por carga DML.', TO_TIMESTAMP('2026-05-31 07:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(3, 'TB_AMANAJE_CLI', 2, 'CRIACAO', 'Cliente Defesa Civil Municipal de Manaus criado por carga DML.', TO_TIMESTAMP('2026-05-31 07:01:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(4, 'TB_AMANAJE_CLI', 3, 'CRIACAO', 'Cliente ONG criado por carga DML.', TO_TIMESTAMP('2026-05-31 07:02:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(1, 'TB_AMANAJE_REGIAO_MONIT', 1, 'CRIACAO', 'Região Cais Mauá cadastrada para dashboard Governo.', TO_TIMESTAMP('2026-05-31 07:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(1, 'TB_AMANAJE_EST_IOT', 1, 'CRIACAO', 'Estação simulada do Cais Mauá cadastrada.', TO_TIMESTAMP('2026-05-31 07:12:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(2, 'TB_AMANAJE_LEIT_IOT', 1, 'CRIACAO', 'Leitura IoT de nível da água recebida por carga de teste.', TO_TIMESTAMP('2026-05-31 08:01:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(2, 'TB_AMANAJE_AVAL_RISCO', 1, 'AVAL_RISCO', 'Avaliação crítica de enchente calculada para Porto Alegre.', TO_TIMESTAMP('2026-05-31 08:06:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(1, 'TB_AMANAJE_ALERTA', 1, 'GERACAO_ALERTA', 'Alerta crítico de enchente gerado para o Cais Mauá.', TO_TIMESTAMP('2026-05-31 08:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(3, 'TB_AMANAJE_REGIAO_MONIT', 3, 'CRIACAO', 'Região ribeirinha de Manaus cadastrada.', TO_TIMESTAMP('2026-05-31 07:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(3, 'TB_AMANAJE_ALERTA', 4, 'GERACAO_ALERTA', 'Alerta crítico gerado para comunidade ribeirinha.', TO_TIMESTAMP('2026-05-31 08:32:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(4, 'TB_AMANAJE_REGIAO_MONIT', 4, 'CRIACAO', 'Projeto de Santarém cadastrado para visão ONG.', TO_TIMESTAMP('2026-05-31 07:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(4, 'TB_AMANAJE_IND_REG', 7, 'CRIACAO', 'Indicador regional agregado criado para Santarém.', TO_TIMESTAMP('2026-05-31 09:16:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(6, 'TB_AMANAJE_AVAL_RISCO', 17, 'AVAL_RISCO', 'Avaliação de qualidade do ar em Sorriso gerada.', TO_TIMESTAMP('2026-05-31 08:56:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(7, 'TB_AMANAJE_ALERTA', 10, 'GERACAO_ALERTA', 'Alerta de qualidade do ar emitido para fazenda privada.', TO_TIMESTAMP('2026-05-31 09:05:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(8, 'TB_AMANAJE_LEIT_IOT', 24, 'INVAL', 'Leitura de PM10 em Ribeirão Preto invalidada logicamente para teste.', TO_TIMESTAMP('2026-05-31 09:06:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_HIST_EVENTO(8, 'TB_AMANAJE_ALERTA', 12, 'RESOLUCAO_ALERTA', 'Alerta moderado de tempestade resolvido após estabilização.', TO_TIMESTAMP('2026-05-31 10:15:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.11 — TB_AMANAJE_LOG_STATUS_EST
BEGIN
    PR_AMANAJE_INS_LOG_STATUS(1, 91200, -54, '10.10.1.21', 'AMJ-1.0.0', TO_TIMESTAMP('2026-05-31 08:50:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(2, 88000, -61, '10.10.1.22', 'AMJ-1.0.0', TO_TIMESTAMP('2026-05-31 08:45:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(3, 76000, -58, '10.10.2.31', 'AMJ-1.0.1', TO_TIMESTAMP('2026-05-31 08:42:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(4, 121000, -49, '10.10.3.41', 'AMJ-REF-1.0', TO_TIMESTAMP('2026-05-31 08:35:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(5, 34000, -89, '10.10.2.52', 'AMJ-1.0.1', TO_TIMESTAMP('2026-05-30 21:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(6, 96000, -57, '10.10.4.61', 'AMJ-AGRO-1.0', TO_TIMESTAMP('2026-05-31 08:40:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(7, 95000, -63, '10.10.4.62', 'AMJ-REF-1.0', TO_TIMESTAMP('2026-05-31 08:38:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(8, 85000, -60, '10.10.5.71', 'AMJ-AGRO-1.0', TO_TIMESTAMP('2026-05-31 08:33:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(9, 124000, -52, '10.10.6.81', 'AMJ-REF-1.0', TO_TIMESTAMP('2026-05-31 08:36:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_STATUS(10, 4500, -92, '10.10.6.82', 'AMJ-1.0.0', TO_TIMESTAMP('2026-05-31 06:25:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.12 — TB_AMANAJE_PROCESS
BEGIN
    PR_AMANAJE_INS_PROCESSAMENTO(1, 1, 'CARGA_DADOS', 'CONCLUIDO', 'SQL Developer DML', 'tabela=TB_AMANAJE_CLI', 'Clientes, usuários e regiões carregados com sucesso.', TO_TIMESTAMP('2026-05-31 07:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 07:05:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(1, 2, 'SINCRONIZACAO_CLIM', 'CONCLUIDO', 'Serviço C# simulado', 'idRegiao=1; fonte=Open-Meteo MVP', '2 observações climáticas normalizadas.', TO_TIMESTAMP('2026-05-31 07:55:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 07:56:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(3, 3, 'SINCRONIZACAO_CLIM', 'CONCLUIDO', 'Serviço C# simulado', 'idRegiao=3; fonte=Open-Meteo MVP', '2 observações climáticas normalizadas.', TO_TIMESTAMP('2026-05-31 08:15:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 08:16:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(5, 4, 'CALCULO_RISCO', 'CONCLUIDO', 'API Java simulada', 'idRegiao=5; categorias=DESLIZAMENTO,TEMPESTADE', 'Avaliações críticas e altas geradas.', TO_TIMESTAMP('2026-05-31 08:44:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 08:46:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(8, 8, 'GERACAO_ALERTA', 'CONCLUIDO', 'API Java simulada', 'idRegiao=8; tipo=QUALIDADE_AR', 'Alerta crítico de qualidade do ar gerado.', TO_TIMESTAMP('2026-05-31 08:18:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 08:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(6, 6, 'GERACAO_IND', 'CONCLUIDO', 'Rotina PL/SQL futura', 'idRegiao=6', 'Indicadores de Sorriso atualizados.', TO_TIMESTAMP('2026-05-31 09:19:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 09:20:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(7, 7, 'GERACAO_IND', 'CONCLUIDO', 'Rotina PL/SQL futura', 'idRegiao=7', 'Indicadores de Juazeiro atualizados.', TO_TIMESTAMP('2026-05-31 09:21:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 09:22:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(NULL, 8, 'ROTINA_PL_SQL', 'CONCLUIDO', 'Banco Oracle', 'rotina=resumo_indicadores', 'Resumo agregado nacional calculado para DQL.', TO_TIMESTAMP('2026-05-31 09:24:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 09:25:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(8, 8, 'CALCULO_RISCO', 'FALHOU', 'API Java simulada', 'idRegiao=8; leitura=24', 'Leitura inválida rejeitada para cálculo produtivo.', TO_TIMESTAMP('2026-05-31 09:05:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 09:06:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_PROCESSAMENTO(NULL, 1, 'OUTRO', 'CANCELADO', 'Operação manual', 'motivo=teste cancelamento', 'Processamento cancelado para compor massa de status.', TO_TIMESTAMP('2026-05-31 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2026-05-31 10:02:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/

  -- ## 3.13 — TB_AMANAJE_LOG_ERRO
BEGIN
    PR_AMANAJE_INS_LOG_ERRO(9, 8, 'API Java simulada', 'CalculoRiscoService', -20001, 'Leitura IoT marcada como inválida; cálculo descartado.', 'CALL avaliar_risco(8, 24)', TO_TIMESTAMP('2026-05-31 09:06:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_ERRO(9, 8, 'DML Seed Amanajé', 'PR_AMANAJE_INS_AVALIACAO', -2290, 'Registro mantido apenas como log técnico de simulação; score não foi gravado para leitura inválida.', 'Leitura 24 com ST_VALIDA = N', TO_TIMESTAMP('2026-05-31 09:07:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_ERRO(10, 1, 'Operação manual', 'Processamento ad hoc', -20999, 'Processamento cancelado pelo operador antes da execução.', 'Processamento OUTRO cancelado', TO_TIMESTAMP('2026-05-31 10:02:00', 'YYYY-MM-DD HH24:MI:SS'));
    PR_AMANAJE_INS_LOG_ERRO(NULL, NULL, 'Serviço C# simulado', 'SincronizacaoClimatica', -1, 'Exemplo controlado de falha anterior de comunicação externa, sem impacto na carga válida.', 'GET /api/clima/fontes', TO_TIMESTAMP('2026-05-31 06:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
END;
/
/*
  ──────────────────────────────────────────────────────────────────────────────
==================================================================================

FIM DO SCRIPT

  Total de objetos criados:
  ──────────────────────────────────────────────────────────────────────────────
    1 Procedure auxiliar             (PR_AMANAJE_REG_ERRO)
   13 Procedures de carga            (PR_AMANAJE_INS_*)
   13 Blocos de chamada de carga     (Seção # 3)

  Massa de dados planejada:
  ──────────────────────────────────────────────────────────────────────────────
  166 Registros de teste             (13 tabelas TB_AMANAJE_*)
*/
