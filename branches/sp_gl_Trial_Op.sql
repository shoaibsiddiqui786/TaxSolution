/*
CREATE PROCEDURE sp_gl_Trial_Op
	@pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10)
AS 
*/
--/*
DECLARE @pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10)

SET @pDoc_Fiscal_ID = 1
SET @pFromDate = '2013-01-01'
SET @pToDate = '2013-06-15'
--*/
/*
CREATE TABLE #tmpTable
(
	doc_vt_id INT, 
	doc_fiscal_id int, 
	doc_id int, 
	doc_strid VARCHAR(20),
	doc_date DATETIME, 
    doc_remarks VARCHAR(20),
    doc_status int,  
    AC_ID bigint, 
    ac_strid VARCHAR(20),
    ac_title VARCHAR(60),
    NARRATION VARCHAR(200),
    Op_DEBIT MONEY, 
    Op_CREDIT MONEY, 
    DEBIT MONEY, 
    CREDIT MONEY, 
    Balance MONEY, 
    SERIAL_NO BIGINT
)

DECLARE @doc_vt_id INT, @doc_fiscal_id int, @doc_id int, @doc_strid VARCHAR(20),
	@doc_date DATETIME, @doc_remarks VARCHAR(20), @doc_status int, @AC_ID bigint, 
    @ac_strid VARCHAR(20), @ac_title VARCHAR(60), @NARRATION VARCHAR(200),
    @Op_DEBIT MONEY, @Op_CREDIT MONEY, 
    @DEBIT MONEY, @CREDIT MONEY, @Balance MONEY, @SERIAL_NO BIGINT,
    @RunBalance MONEY, @OpRunBal MONEY 

DECLARE cur_Ledger CURSOR FOR
*/ 
SELECT x.ac_id, x.ac_strid, x.Ac_Title,
	CASE WHEN SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0)) >=0 THEN  
		 SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0)) ELSE 0 END AS Op_Debit,
	CASE WHEN SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0)) <=0 THEN  
		 ABS(SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0))) ELSE 0 END AS Op_Credit,
		 
	CASE WHEN SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0)) >=0 THEN  
		 SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0)) ELSE 0 END AS Debit,
	CASE WHEN SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0)) <=0 THEN  
		 ABS(SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0))) ELSE 0 END AS Credit, 

	CASE WHEN (SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0))) 
		+ (SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0))) >=0 THEN 
		(SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0))) 
		+ (SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0))) ELSE 0 END AS Clos_Debit,
		
	CASE WHEN (SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0))) 
		+ (SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0))) <=0 THEN 
		ABS( (SUM(isNull(x.Op_Debit,0)) - SUM(isNull(x.Op_Credit,0))) 
		+ (SUM(isNull(x.Debit,0)) - SUM(isNull(x.Credit,0)))) ELSE 0 END AS Clos_Credit

FROM (
	SELECT 0 as doc_vt_id, 0 as doc_fiscal_id, 0 AS doc_id, 'Opening Balance' AS Doc_StrID,
		@pFromDate AS Doc_date, --t.doc_date, 
		'Opening Balance' AS doc_remarks, 0 AS doc_status, td.ac_id, ga.ac_strid, 
		ga.ac_title, 'Opening Balance' AS narration,
		SUM(isNull(td.debit,0)) AS Op_Debit, SUM(isNull(td.credit,0)) AS Op_Credit, 
		0 as DEBIT, 0 as CREDIT, 0 AS Balance, 0 as SERIAL_NO 
	FROM 
		gl_tran t INNER JOIN gl_trandtl td ON t.doc_vt_id=td.doc_vt_id
		AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
		INNER JOIN gl_ac ga ON td.AC_ID=ga.ac_id
		INNER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
	WHERE  t.doc_fiscal_id=@pDoc_Fiscal_ID
		AND t.doc_date < @pFromDate 
	GROUP BY td.ac_id, ga.ac_strid, ga.ac_title

UNION

	SELECT t.doc_vt_id, t.doc_fiscal_id, t.doc_id, ga.ac_title + '-' + t.doc_strid AS Doc_StrID, 
		t.doc_date, t.doc_remarks, t.doc_status, td.ac_id, ga.ac_strid, ga.ac_title, 
		td.narration, 0 AS Op_Debit, 0 AS Op_Credit, td.DEBIT, td.CREDIT, 0 AS Balance, 
		td.SERIAL_NO 
	FROM 
		gl_tran t INNER JOIN gl_trandtl td ON t.doc_vt_id=td.doc_vt_id
		AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
		INNER JOIN gl_ac ga ON td.AC_ID=ga.ac_id
		INNER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
	WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID
		AND t.doc_date BETWEEN @pFromDate AND @pToDate  
	--ORDER BY t.doc_date, td.SERIAL_NO
)x GROUP BY x.ac_id, x.ac_strid, x.Ac_Title
/*	
OPEN cur_Ledger

FETCH NEXT FROM cur_Ledger INTO @doc_vt_id, @doc_fiscal_id, @doc_id, @doc_strid, 
	@doc_date, @doc_remarks, @doc_status, @AC_ID, @ac_strid, @ac_title, @NARRATION,
    @Op_DEBIT, @Op_CREDIT, @DEBIT, @CREDIT, @Balance, @SERIAL_NO

SET @OpRunBal=0
SELECT @OpRunBal = (SELECT Sum(isNull(td.DEBIT,0)- ISNULL(td.CREDIT,0)) 
FROM gl_tran t INNER JOIN gl_trandtl td ON t.loc_id=td.loc_id AND t.grp_id=td.grp_id
	AND t.co_id=td.co_id AND t.year_id=td.year_id AND t.doc_fiscal_id=td.doc_fiscal_id
	and t.doc_vt_id=td.doc_vt_id AND t.doc_id=td.doc_id
WHERE t.loc_id=@pLoc_id AND t.grp_id=@pGrp_id AND t.co_id=@pCo_id AND t.year_id=@pYear_id 
	AND td.doc_ac_id=@pAc_ID --AND t.doc_fiscal_id=@pDoc_Fiscal_ID
	AND t.doc_date < @pFromDate) 

SET @Balance=0
SET @RunBalance=0

IF @OpRunBal<>0
	BEGIN 
		INSERT INTO #tmpTable (doc_vt_id, doc_fiscal_id, doc_id, doc_strid, doc_date, 
			doc_remarks, doc_status, AC_ID, ac_strid, ac_title, NARRATION,
			Op_DEBIT, Op_CREDIT, DEBIT, CREDIT, Balance, SERIAL_NO)
		VALUES (@doc_vt_id, @doc_fiscal_id, 1, 'OPN-1', @pFromDate, 
		'Opening Balance', 1, 0, @ac_strid, @ac_title, 'Opening Balance',
		Case when @OpRunBal>0 THEN @OpRunBal ELSE 0 END, 
		Case when @OpRunBal<0 THEN @OpRunBal ELSE 0 END, 
		Case when @OpRunBal>0 THEN @OpRunBal ELSE 0 END, 
		Case when @OpRunBal<0 THEN abs(@OpRunBal) ELSE 0 END, 
		@OpRunBal + @RunBalance, @SERIAL_NO)
	END 

WHILE @@FETCH_STATUS=0
	BEGIN
		IF isNull(@DEBIT,0)>0 
			BEGIN
				--SET @Balance=@Balance+isNull(@DEBIT,0)
				SET @RunBalance=@RunBalance+isNull(@DEBIT,0)
			END
		ELSE --IF isNull(@CREDIT,0)>0
			BEGIN
				SET @RunBalance=@RunBalance-isNull(@CREDIT,0)
				--SET @Balance=@Balance-isNull(@CREDIT,0)
			END
					
		INSERT INTO #tmpTable (doc_vt_id, doc_fiscal_id, doc_id, doc_strid, doc_date, 
			doc_remarks, doc_status, AC_ID, ac_strid, ac_title, NARRATION,
			Op_DEBIT, Op_CREDIT, DEBIT, CREDIT, Balance, SERIAL_NO)
		VALUES (@doc_vt_id, @doc_fiscal_id, @doc_id, @doc_strid, @doc_date, 
		@doc_remarks, @doc_status, @AC_ID, @ac_strid, @ac_title, @NARRATION,
		Case when @OpRunBal>0 THEN @OpRunBal ELSE 0 END, 
		Case when @OpRunBal<0 THEN @OpRunBal ELSE 0 END, 
		@DEBIT, @CREDIT, isNull(@OpRunBal,0) + @RunBalance, @SERIAL_NO)

		FETCH NEXT FROM cur_Ledger INTO @doc_vt_id, @doc_fiscal_id, @doc_id, @doc_strid, 
			@doc_date, @doc_remarks, @doc_status, @AC_ID, @ac_strid, @ac_title, @NARRATION,
			@Op_DEBIT, @Op_CREDIT, @DEBIT, @CREDIT, @Balance, @SERIAL_NO
	END  

CLOSE cur_Ledger
DEALLOCATE cur_Ledger
SELECT * FROM #tmpTable
DROP TABLE #tmpTable
*/
--Second Image Table Get
select ID, Name, Photo from Photos where id=28;
	
/*	
	SELECT * FROM gl_tran
	SELECT * FROM gl_trandtl
*/	
	
	
	
	
	
	


