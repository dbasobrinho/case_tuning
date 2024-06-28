--case.0003.r.PL_SQL_delete_bulk_collect_forall.sql
set echo off tab off lines 188 pages 300 timing off feedback off
SET TERMOUT OFF;
ALTER SESSION SET statistics_level = ALL;
begin execute immediate 'drop table CASE_0003_R_SCR'; exception when others then null; end;
/
SET TERMOUT ON;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 01: Criar a estrutura para o teste [table: CASE_0003_R_SCR]
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create table CASE_0003_R_SCR as 
SELECT
  rownum AS ID_X,
  d.object_id,
  d.object_name,
  d.owner,
  d.object_type,
  d.status,
  d.created
FROM dba_objects d
CROSS JOIN (SELECT LEVEL FROM dual CONNECT BY LEVEL <= 10)
WHERE rownum <= 1500000;
commit;
ALTER TABLE CASE_0003_R_SCR ADD CONSTRAINT pk_CASE_0003_R_SCR PRIMARY KEY (ID_X);
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'CASE_0003_R_SCR');
PROMPT
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 02: Contar Registros [table: CASE_0003_R_SCR]
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
col owner  format a25
PROMPT 
set echo on;
SELECT COUNT(*)  FROM CASE_0003_R_SCR;
set echo off;
PROMPT 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 03: Executar Bloco PL/SQL usando bulk collect e forall para delete 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT 
set echo off;
SET SERVEROUTPUT ON;
DECLARE
  cursor c1 is
    select x.rowid as rw
      from CASE_0003_R_SCR x
     where OBJECT_TYPE in ('JAVA CLASS', 'SYNONYM', 'VIEW', 'JAVA RESOURCE', 'JAVA DATA', 'TABLE', 'INDEX', 'PACKAGE', 'PACKAGE BODY');
  type t_rowid is table of rowid index by pls_integer;
  row_t_rowid t_rowid;
  v_inicio    NUMBER;
  v_conta     INTEGER := 0;
BEGIN
  v_inicio := dbms_utility.get_time;
  open c1;
  loop
    fetch c1 bulk collect
      into row_t_rowid limit 1000;
    exit when row_t_rowid.count = 0;
	v_conta := v_conta + row_t_rowid.count;
  
    forall i in row_t_rowid.first .. row_t_rowid.last
      delete CASE_0003_R_SCR where rowid = row_t_rowid(i);
  --
  ROLLBACK;
  end loop;
  close c1;
  --/
  ROLLBACK;
  --/
  dbms_output.put_line('=======================================================================');
  dbms_output.put_line('TOTAL DE LINHAS DE DELETE    :    ' || v_conta);
  dbms_output.put_line('TEMPO COM BULK COLLECT/FORALL:    ' || trim(TO_CHAR(ROUND((dbms_utility.get_time - v_inicio) / 100, 2), '999900.99') || ' Segundos'));
  dbms_output.put_line('=======================================================================');
  --/
exception
  when others then
      raise_application_error(-20010,'Backtrace: ' ||dbms_utility.format_error_backtrace ||' Sqlerrm: ' || substr(sqlerrm, 1, 300));
end;
/
PROMPT 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Passo 04: Executar Bloco PL/SQL sem bulk collect e forall para delete 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT 
set echo off;
SET TERMOUT OFF;
ALTER TABLE CASE_0003_R_SCR MOVE;
ALTER INDEX pk_CASE_0003_R_SCR REBUILD;
SET TERMOUT ON;
SET SERVEROUTPUT ON;

DECLARE
  cursor c1 is
    select x.rowid as rw
      from CASE_0003_R_SCR x
    where OBJECT_TYPE in ('JAVA CLASS', 'SYNONYM', 'VIEW', 'JAVA RESOURCE', 'JAVA DATA', 'TABLE', 'INDEX', 'PACKAGE', 'PACKAGE BODY');
  v_del    c1%ROWTYPE;
  v_inicio    NUMBER;
  v_conta     INTEGER := 0; 
  v_save      INTEGER := 0;
BEGIN
  v_inicio := dbms_utility.get_time;
  OPEN c1;
  LOOP
    FETCH c1
      INTO v_del;
    EXIT WHEN c1%NOTFOUND;
    delete CASE_0003_R_SCR where rowid = v_del.rw;
	v_conta := v_conta +1;
	v_save  := v_save  +1;
	if v_save >= 1000 
	then
	    ROLLBACK;
		v_save := 0;
    end if;
  end loop;
  close c1;
  ROLLBACK;
  --/
  dbms_output.put_line('=============================================================================================');
  dbms_output.put_line('TOTAL DE LINHAS DE DELETE    :    ' || v_conta);
  dbms_output.put_line('TEMPO SEM BULK COLLECT/FORALL:    ' || trim(TO_CHAR(ROUND((dbms_utility.get_time - v_inicio) / 100, 2), '999900.99') || ' Segundos'));
  dbms_output.put_line('=============================================================================================');
  --/
exception
  when others then
      raise_application_error(-20010,'Backtrace: ' ||dbms_utility.format_error_backtrace ||' Sqlerrm: ' || substr(sqlerrm, 1, 300));
end;
/
SET TERMOUT OFF;
ALTER SESSION SET statistics_level = ALL;
begin execute immediate 'drop table CASE_0003_R_SCR'; exception when others then null; end;
/
SET TERMOUT ON;




