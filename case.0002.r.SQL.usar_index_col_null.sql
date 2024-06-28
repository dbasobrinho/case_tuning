--case.0002.r.SCR.sql
set echo off tab off lines 188 pages 300 timing off feedback off
SET TERMOUT OFF;
ALTER SESSION SET statistics_level = ALL;
begin execute immediate 'drop table CASE_0002_R_SCR'; exception when others then null; end;
/
SET TERMOUT ON;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 01: Criar a tabela de teste [table: CASE_0002_R_SCR]
CREATE TABLE CASE_0002_R_SCR AS SELECT * FROM dba_objects;
INSERT INTO CASE_0002_R_SCR SELECT * FROM CASE_0002_R_SCR;
INSERT INTO CASE_0002_R_SCR SELECT * FROM CASE_0002_R_SCR;
INSERT INTO CASE_0002_R_SCR SELECT * FROM CASE_0002_R_SCR;
UPDATE CASE_0002_R_SCR SET OWNER = NULL WHERE ROWNUM < 501;
UPDATE CASE_0002_R_SCR SET OWNER = NULL WHERE OBJECT_TYPE = 'INDEX' and ROWNUM < 101;
commit;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 02: Criar Index na Coluna OWNER da Tabela CASE_0002_R_SCR [index: IDX01_CASE_0002_R_SCR]
CREATE INDEX idx01_CASE_0002_R_SCR ON CASE_0002_R_SCR(owner);
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 03: Coleta Estatistica da Tabela CASE_0002_R_SCR
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => user, 
        tabname => 'CASE_0002_R_SCR', 
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, 
        method_opt => 'FOR ALL COLUMNS SIZE AUTO', 
        cascade => TRUE
    );
end;
/
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 04: Contar Registros e Agrupando pelo OWNER 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
col owner  format a25
PROMPT 
set echo on;
SELECT COUNT(*), owner FROM CASE_0002_R_SCR group by owner order by owner NULLS FIRST;
set echo off;
PROMPT 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 05: Executar a Consulta Referente a Analise de Desempenho [case.0002.r.SCR.sql]
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT 
set echo on;
SELECT /* case.0002.r.SCR.sql#ANTES */ 
       COUNT(1), OBJECT_TYPE 
  FROM CASE_0002_R_SCR 
 WHERE OWNER is null
 GROUP BY OBJECT_TYPE 
/
set echo OFF;
PROMPT 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 06: Exibir Plano de Acesso Completo
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT
SET TERMOUT OFF;
column sql_id new_value m_sql_id
column child_number new_value m_child_no
SELECT sql_id, child_number
  FROM v$sql
 WHERE sql_text LIKE '%case.0002.r.SCR.sql#ANTES%'
   AND sql_text NOT LIKE '%v$sql%';
SET TERMOUT ON;
set head off
SELECT *
  FROM TABLE (dbms_xplan.display_cursor ('&m_sql_id',&m_child_no,'TYPICAL allstats last -Predicate'));
set head ON
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 07: Vericar INDEX da tabela CASE_0002_R_SCR
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set echo off;
col IDX_OWNER       for a10
col IDX_NAME        for a30 
col TABLESPACE_NAME for a20
col index_type      for a10
col size_mb         for 9999999
col column_name     for a28
col col_pos         for 9999999
undef tab_owner
undef tab_name
undef 1
undef 2
break on owner on segment_name on uniqueness on partitioned on index_type on status on tablespace_name on size_mb 
select a.OWNER       IDX_OWNER,
       SEGMENT_NAME  IDX_NAME,
	   c.column_name,
	   c.column_position col_pos,
	   sum(BYTES / 1024 / 1024) tot_size_mb,
       b.uniqueness,
       b.partitioned,
       b.index_type,
       b.status,
       TABLESPACE_NAME,
       b.last_analyzed,
       decode(VISIBILITY, 'VISIBLE', 'V', 'INVISIBLE', 'I') v
  from dba_segments a,
       (select owner,
               index_name,
               index_type,
               status,
               last_analyzed,
               uniqueness,
               partitioned,
               VISIBILITY
          from dba_indexes
         where table_name = upper('CASE_0002_R_SCR')
           and table_owner = nvl(upper(NULL),table_owner)
		   ) b,
       dba_ind_columns c
 where segment_name = b.index_name
   and a.owner = b.owner
   and b.index_name = c.index_name
   and b.owner = c.index_owner
 group by a.OWNER,
          SEGMENT_NAME,
          b.uniqueness,
          b.partitioned,
          b.index_type,
          b.status,
          TABLESPACE_NAME,
          c.column_name,
          c.column_position,
          b.last_analyzed,
          VISIBILITY
 order by b.partitioned, a.segment_name, col_pos asc;
PROMPT
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | Passo 08: Recriar o INDEX na tabela CASE_0002_R_SCR com o Truque #BóBó                           
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | +-+-+-+-+-+ Partindo da premissa que um valor nulo nao pode ser indexado, vamos indexar a coluna em conjunto      +-+-+-+-+-+ |
PROMPT | |A|C|A|O| | com um valor fixo, com isso mesmo o valor da coluna sendo nulo sera indexado pelo fato de estar       |A|C|A|O| | |
PROMPT | +-+-+-+-+-+ composto com um valor estatico. No exemplo a coluna OWNER foi indexada em conjunto co o numero 0      +-+-+-+-+-+ |
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT 
set feedback on;
set echo on;
DROP INDEX idx01_CASE_0002_R_SCR;
CREATE INDEX idx01_CASE_0002_R_SCR ON CASE_0002_R_SCR(owner,0) COMPUTE STATISTICS;
set echo OFF;
set feedback off;
PROMPT 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 09: Executar a Consulta Referente a Analise de Desempenho [case.0002.r.SCR.sql]
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT 
set echo on;
SELECT /* case.0002.r.SCR.sql#DEPOIS */ 
       COUNT(1), OBJECT_TYPE 
  FROM CASE_0002_R_SCR 
 WHERE OWNER is null
 GROUP BY OBJECT_TYPE 
/
set echo OFF;
PROMPT
PROMPT
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | Passo 10: Comparar: Exibir Plano de Acesso ANTES a Alteracao                       
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | +-+-+-+-+-+ Esse plano de acesso representa a execucao da consulta ANTES da alteracao do index                    +-+-+-+-+-+ |
PROMPT | |A|N|T|E|S| Podemos observar que o acesso a tabela CASE_0002_R_SCR esta sendo realizado por uma operacao          |A|N|T|E|S| |
PROMPT | +-+-+-+-+-+ TABLE ACCESS FULL, mesmo o coluna OWNER sendo indexada                                                +-+-+-+-+-+ |
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT
set head off 
SELECT *
  FROM TABLE (dbms_xplan.display_cursor ('&m_sql_id',&m_child_no,'TYPICAL allstats last -Predicate')); 
PROMPT 

SET TERMOUT OFF;
column sql_id new_value m_sql_id
column child_number new_value m_child_no
SELECT sql_id, child_number
  FROM v$sql
 WHERE sql_text LIKE '%case.0002.r.SCR.sql#DEPOIS%'
   AND sql_text NOT LIKE '%v$sql%';
SET TERMOUT ON;
PROMPT
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | Passo 11: Comparar: Exibir Plano de Acesso APOS a Alteracao                           
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT | +-+-+-+-+-+ Esse plano de acesso representa a execucao da consulta APOS da alteracao do index                     +-+-+-+-+-+ |
PROMPT | |A|P|O|S| | Podemos observar que o acesso a tabela CASE_0002_R_SCR foi alterado para INDEX RANGE SCAN             |A|P|O|S| | |
PROMPT | +-+-+-+-+-+ isso indica que o index foi utilizado, indicadores de Cost e Buffers diminuiram                       +-+-+-+-+-+ |
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT
SELECT *
  FROM TABLE (dbms_xplan.display_cursor ('&m_sql_id',&m_child_no,'TYPICAL allstats last -Predicate'));
SET TERMOUT OFF;
column sql_id new_value m_sql_id
column child_number new_value m_child_no
SELECT sql_id, child_number
  FROM v$sql
 WHERE sql_text LIKE '%case.0002.r.SCR.sql#ANTES%'
   AND sql_text NOT LIKE '%v$sql%';
SET TERMOUT ON;

SET TERMOUT OFF;
begin execute immediate 'drop table CASE_0002_R_SCR'; exception when others then null; end;
/
SET TERMOUT ON;
  

