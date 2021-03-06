--/*
ALTER PROCEDURE [dbo].[sp_Item_StockSmryGod] 
	@pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10),
	@pGodown INT,
	@pUOMID INT, 
	@pShowZero INT
AS 
--*/
/*
DECLARE @pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10), 
	@pGodown INT, 
	@pUOMID int
 
set @pDoc_Fiscal_ID=1
set @pFromDate='2012-10-01'
set @pToDate = '2012-10-31'
SET @pGodown=4
SET @pUOMID=0
*/
SELECT * FROM (
SELECT --x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_Title, x.Group_st,
x.Godown_title, Sum(x.OpBalance) AS OpBalance, 
Sum(x.Qty_In) AS Qty_In, Sum(x.Qty_Out) AS Qty_Out, 
--Sum(x.OpBalance) + 
Sum(x.OpBalance)+ (Sum(x.Qty_In) - Sum(x.Qty_Out)) AS Balance, 
--x.goodsuom_st, 
Sum(x.MeshTotal) AS MeshTotal, Sum(x.Bundle) AS Bundle
--x.Group_st + '' + x.goodsitem_st AS ItemName
FROM (
	
SELECT td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st,
g.Godown_title, Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0)) AS OpBalance, 
0 AS Qty_In, 0 AS Qty_Out, 0 AS Balance, u.goodsuom_st, 
0 AS MeshTotal, 0 AS Bundle
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID AND t.doc_date < @pFromDate  
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
	AND (@pUOMID>0 AND td.UOMID=@pUOMID OR @pUOMID=0)
GROUP BY td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title,gg.Group_st,
	g.Godown_title,u.goodsuom_st
	
UNION 

SELECT td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st,
	g.Godown_title, 0 AS OpBalance, Sum(isNull(td.Qty_In,0)) AS Qty_In,
	Sum(ISNULL(td.Qty_Out,0)) AS Qty_Out, 0 AS Balance, u.goodsuom_st, 
	Sum(isNull(td.MeshTotal,0)) AS MeshTotal, Sum(ISNULL(td.Bundle,0)) AS Bundle
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
	AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
	INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
	INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
	INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
	INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
	AND t.doc_date BETWEEN @pFromDate AND @pToDate 
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
	AND (@pUOMID>0 AND td.UOMID=@pUOMID OR @pUOMID=0)
GROUP BY td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title,gg.Group_st,
g.Godown_title,u.goodsuom_st
)x 
GROUP BY --x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_title, x.Group_st, 
	x.Godown_title --, x.goodsuom_st
)j WHERE (@pShowZero=0 OR @pShowZero>0 AND j.Balance>0)
	
--SET NOCOUNT ON
/*
DECLARE @WhereClause NVARCHAR(2000), @WhereClauseOP NVARCHAR(2000), @SqlQuery NVARCHAR(2000), @OrderBy NVARCHAR(1000) 
DECLARE @OpRunBal FLOAT, @RunBalance FLOAT

SET @WhereClauseOP = N' WHERE td.Doc_Fiscal_ID = ' + Cast(@pDoc_Fiscal_ID AS VARCHAR(5)) 
	+ N' AND td.ItemID=' + CAST(@pItem_ID AS VARCHAR(5))
	+ N' AND t.Doc_Date < ''' + @pFromDate + '''' + CHAR(13)

SET @WhereClause = N' WHERE td.Doc_Fiscal_ID = ' + Cast(@pDoc_Fiscal_ID AS VARCHAR(5)) 
	+ N' AND td.ItemID=' + CAST(@pItem_ID AS VARCHAR(5))
	+ N' AND t.Doc_Date BETWEEN ''' + @pFromDate + N''' AND ''' + @pToDate + '''' + CHAR(13)
	
IF @pUOMID>0 
BEGIN
	SET @WhereClause += ' AND td.UOMID=' + Cast(@pUOMID AS VARCHAR(6)) + CHAR(13)
	SET @WhereClauseOp += ' AND td.UOMID=' + Cast(@pUOMID AS VARCHAR(6)) + CHAR(13)
END
	
IF @pGodown>0 
BEGIN
	SET @WhereClause += ' AND td.GodownID=' + Cast(@pGodown AS VARCHAR(6)) + CHAR(13)
	SET @WhereClauseOp += ' AND td.GodownID=' + Cast(@pGodown AS VARCHAR(6)) + CHAR(13)
END

set @OrderBy=' Order by t.Doc_Date, td.SERIAL_NO'

--SELECT * FROM inv_trandtl 

CREATE TABLE #tmpTable
(
	doc_date DATETIME, 
	Doc_StrID VARCHAR(20), 
	ItemID BIGINT, 
	goodsitem_title VARCHAR(50), 
	goodsitem_st VARCHAR(30), 
	Group_st VARCHAR(30),
	NARRATION VARCHAR(200), 
	Godown_title VARCHAR(60), 
	Rate MONEY,
	Qty_In Float, 
	Qty_Out Float, 
	Balance Float, 
	goodsuom_st VARCHAR(30), 
	MeshTotal Float,
	Bundle Float, 
	Length Float, 
	LenDec Float, 
	Width FLOAT, 
	WidDec FLOAT, 
	SERIAL_NO bigint
)
*/
/*
DECLARE @doc_vt_id INT, @doc_fiscal_id int, @doc_id int, @doc_strid VARCHAR(20),
	@doc_date DATETIME, @doc_remarks VARCHAR(20), @doc_status int, @AC_ID bigint, 
    @ac_strid VARCHAR(20), @ac_title VARCHAR(60), @NARRATION VARCHAR(200),
    @Op_DEBIT MONEY, @Op_CREDIT MONEY, 
    @DEBIT MONEY, @CREDIT MONEY, @Balance MONEY, @SERIAL_NO BIGINT,
    @RunBalance MONEY, @OpRunBal MONEY 
*/
/*
SET @OpRunBal=0
SELECT @OpRunBal = (SELECT Sum(isNull(td.Qty_In,0)- ISNULL(td.Qty_Out,0)) 
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
	AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID
	AND td.ItemID=@pItem_ID
	AND t.doc_date < @pFromDate
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0) 
	AND (@pUOMID>0 AND td.UOMID=@pUOMID OR @pUOMID=0)
)
*/	
--	PRINT @OpRunBal 
--/*
--SET @Balance=0
--SET @RunBalance=0
--*/
/*
DECLARE @doc_date DATETIME, @Doc_StrID VARCHAR(20), 
	@ItemID BIGINT, @goodsitem_title VARCHAR(50), @goodsitem_st VARCHAR(30), @Group_st VARCHAR(30),
	@NARRATION VARCHAR(200), @Godown_title VARCHAR(60), @Rate MONEY,
	@Qty_In Float, @Qty_Out Float, @Balance Float, @goodsuom_st VARCHAR(30), 
	@MeshTotal Float,@Bundle Float, @Length Float, @LenDec Float, 
	@Width FLOAT, @WidDec FLOAT, @SERIAL_NO int
*/
--SET @SqlQuery = N'
/*
SELECT t.doc_date, avd.Name + '-' + t.doc_strid AS Doc_StrID, 
td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_st,
td.NARRATION, g.Godown_title, td.Rate,
td.Qty_In, td.Qty_Out, 0 AS Balance, u.goodsuom_st, td.MeshTotal,
td.Bundle, td.Length, td.LenDec, td.Width, td.WidDec, td.SERIAL_NO
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
INNER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
*/

/*
SET @SqlQuery= N'DECLARE cur_Ledger CURSOR FOR ' + @SqlQuery + @WhereClause + @OrderBy
--PRINT @SqlQuery
--DECLARE cur_Ledger CURSOR FOR 
EXEC sp_executesql @SqlQuery
--exec sp_executesql @SqlQuery

OPEN cur_Ledger

FETCH NEXT FROM cur_Ledger INTO @doc_date, @Doc_StrID, 
	@ItemID, @goodsitem_title, @goodsitem_st, @Group_st,
	@NARRATION, @Godown_title, @Rate, @Qty_In, @Qty_Out, @Balance, @goodsuom_st, 
	@MeshTotal,@Bundle, @Length, @LenDec, @Width, @WidDec, @SERIAL_NO

IF @OpRunBal<>0
	BEGIN
		INSERT INTO #tmpTable (doc_date, Doc_StrID, ItemID, goodsitem_title,
			goodsitem_st, Group_st, NARRATION, Godown_title, Rate, Qty_In,
			Qty_Out, Balance, goodsuom_st, MeshTotal, Bundle, Length, LenDec,
			Width, WidDec, SERIAL_NO) 
		VALUES (@pFromDate, 'OPN-1', @ItemID, @goodsitem_title, @goodsitem_st, @Group_st,
			'Opening Balance', @Godown_title, 0, 
			Case when @OpRunBal>0 THEN @OpRunBal ELSE 0 END, 
			Case when @OpRunBal<0 THEN abs(@OpRunBal) ELSE 0 END, 
			ISNULL(@OpRunBal,0) + @RunBalance, @goodsuom_st,
			0,0,0,0,0,0,0) 
	END 
	
SET @RunBalance=0
WHILE @@FETCH_STATUS=0
BEGIN
	IF isNull(@Qty_In,0)>0 
		BEGIN
			--SET @Balance=@Balance+isNull(@DEBIT,0)
			SET @RunBalance=@RunBalance+isNull(@Qty_In,0)
		END
	ELSE --IF isNull(@CREDIT,0)>0
		BEGIN
			SET @RunBalance=@RunBalance-isNull(@Qty_Out,0)
			--SET @Balance=@Balance-isNull(@CREDIT,0)
		END

	INSERT INTO #tmpTable (doc_date, Doc_StrID, ItemID, goodsitem_title,
        goodsitem_st, Group_st, NARRATION, Godown_title, Rate, Qty_In,
        Qty_Out, Balance, goodsuom_st, MeshTotal, Bundle, Length, LenDec,
        Width, WidDec, SERIAL_NO) 
	VALUES (@doc_date, @Doc_StrID, @ItemID, @goodsitem_title, @goodsitem_st, @Group_st,
		@NARRATION, @Godown_title, @Rate, @Qty_In, @Qty_Out, 
		ISNULL(@OpRunBal,0) + @RunBalance, @goodsuom_st, 
		@MeshTotal,@Bundle, @Length, @LenDec, @Width, @WidDec, @SERIAL_NO)
	
	FETCH NEXT FROM cur_Ledger INTO @doc_date, @Doc_StrID, 
		@ItemID, @goodsitem_title, @goodsitem_st, @Group_st,
		@NARRATION, @Godown_title, @Rate, @Qty_In, @Qty_Out, @Balance, @goodsuom_st, 
		@MeshTotal,@Bundle, @Length, @LenDec, @Width, @WidDec, @SERIAL_NO
END

CLOSE cur_Ledger
DEALLOCATE cur_Ledger
SELECT * FROM #tmpTable
DROP TABLE #tmpTable
*/
select ID, Name, Photo from Photos where id=28;

--SET NOCOUNT OFF
