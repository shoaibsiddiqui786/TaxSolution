--/*
ALTER PROCEDURE [dbo].[sp_ItemUnitLedGodItem]
	@pDoc_Fiscal_ID int,
	@pItem_ID INT,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10),
	@pUOMID INT,
	@pGodown INT 
AS 
--*/
/*
DECLARE @pDoc_Fiscal_ID int,
	@pItem_ID INT,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10),
	@pUOMID INT, 
	@pGodown INT
 
set @pDoc_Fiscal_ID=1
set @pFromDate='2012-07-01'
set @pToDate = '2013-12-30'
SET @pGodown=0
SET @pItem_ID=151
SET @pUOMID=0
*/

EXEC sp_ItemUnitLedgerShopItem @pDoc_Fiscal_ID, @pFromDate, @pToDate, @pGodown, @pItem_ID;
--SELECT * FROM tmpItemUnitLedgerShop

SELECT m.doc_date, m.Doc_StrID,m.ItemID, m.goodsitem_title, m.goodsitem_st, 
	m.Group_title, m.Group_st,
	m.Godown_title, m.Godown_ac_strID, m.OpBalance, m.Qty_In, m.Qty_Out,  m.Qty_In - m.Qty_Out as Balance, 
	m.goodsuom_st, m.MeshTotal, m.Bundle, m.Narration, m.SERIAL_NO, 
	m.ItemNameDetail, m.ItemQtyDetail, m.ItemDescription
FROM (

SELECT @pFromDate AS doc_date, 'Opening Balance' as doc_strid, 
	0 as ItemID, 'Opening Balance' as goodsitem_title, '' as goodsitem_st, 
	'Opening Balance' as Group_Title, '' AS Group_St,
	--gg.Group_title, gg.Group_st,
	g.Godown_title, ga.ac_strid AS Godown_ac_strID, Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0)) AS OpBalance, 
	Case when Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0))>=0 
		THEN Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0)) ELSE 0 END Qty_In,
	Case when Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0))<0 
		THEN Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0)) ELSE 0 END Qty_Out,
	--0 AS Qty_In, 0 AS Qty_Out, 
	0 AS Balance, u.goodsuom_st, 
	0 AS MeshTotal, 0 AS Bundle, 'Opening Balance' AS Narration, 0 AS SERIAL_NO, 
	'' as ItemNameDetail, '' as ItemQtyDetail, '' as ItemDescription
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
	AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
	INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
	INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
	INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
	INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
	INNER JOIN gl_ac ga ON g.Godown_ac_id=ga.ac_id
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
	AND t.doc_date < @pFromDate  
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
	AND (@pItem_ID>0 AND td.ItemID=@pItem_ID OR @pItem_ID=0)
GROUP BY --td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st, OR @pGodown=0
	ga.ac_strid, g.Godown_title,u.goodsuom_st

UNION 

SELECT x.doc_date, x.Doc_StrID,x.ItemID, x.goodsitem_title, x.goodsitem_st, 
	x.Group_title, x.Group_st, x.Godown_title, x.Godown_ac_strID, x.OpBalance, x.Qty_In, x.Qty_Out, x.Balance, 
	x.goodsuom_st, x.MeshTotal, x.Bundle,
	x.Narration, -- + ' ' + x.Group_st + ' ' + x.goodsitem_st AS Narration, 
	x.SERIAL_NO, 
	x.ItemNameDetail, x.ItemQtyDetail, x.ItemDescription
FROM (

	SELECT t.doc_date, avd.Name + '-' + t.doc_strid AS Doc_StrID, 
	td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, 
	gg.Group_st + ' ' + gi.goodsitem_st as Group_st,
	g.Godown_title, ga.ac_strid AS Godown_ac_strID, 0 AS OpBalance, td.Qty_In, td.Qty_Out, 0 AS Balance, 
	--isNull(td.Qty_In,0)- ISNULL(td.Qty_Out,0) AS Balance, 
	--Sum(isNull(td.Qty_In,0)) AS Qty_In,
	--Sum(ISNULL(td.Qty_Out,0)) AS Qty_Out, 0 AS Balance, 
	u.goodsuom_st, td.MeshTotal, td.Bundle, 
	CASE WHEN isNull(t.GLID,0)=0 AND isNull(t.GLID_Cr,0)=0 THEN td.Narration
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)=0 THEN a.ac_title + ' ' + c.city_title
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_In,0)>0 
			THEN a.ac_title + ' ' + c.city_title
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_Out,0)>0 
			THEN a2.ac_title + ' ' + c2.city_title 
	END AS Narration, td.SERIAL_NO,
	 
	gg.Group_st + '' + gi.goodsitem_st as ItemNameDetail, 

	CASE WHEN td.isBundle=1 THEN ' Q=' + Cast(td.Bundle AS VARCHAR(12)) + u.goodsuom_st
	WHEN td.isMesh=1 THEN ' B=' + Cast(td.Bundle AS VARCHAR(12))
		+ ' x L=' + Cast((td.Length + (td.LenDec*0.0833)) AS VARCHAR(15)) 
		+ ' x W=' + CAST((td.Width + (td.WidDec*0.0833)) AS VARCHAR(15))
		+ ' Q= ' + CAST(td.Bundle * ((td.Width + (td.WidDec*0.0833)) * (td.Length + (td.LenDec*0.0833)))  
		AS VARCHAR(15)) + u.goodsuom_st
	ELSE CASE WHEN isNull(td.Bundle,0)>0 THEN ' B=' + Cast(td.Bundle AS VARCHAR(12)) ELSE '' END  
		+ ' Q=' + Cast(isNull(td.Qty_Out,0) AS VARCHAR(12)) + u.goodsuom_st
	END as ItemQtyDetail, 

	CASE WHEN td.isBundle=1 THEN gg.Group_st + '' + gi.goodsitem_st 
		--+ ' Q=' + Cast(td.Bundle AS VARCHAR(8)) + u.goodsuom_st
	WHEN td.isMesh=1 THEN  gg.Group_st + ' ' + gi.goodsitem_st + ' B=' + Cast(td.Bundle AS VARCHAR(12))
		+ ' x L=' + Cast((td.Length + (td.LenDec*0.0833)) AS VARCHAR(15)) 
		+ ' x W=' + CAST((td.Width + (td.WidDec*0.0833)) AS VARCHAR(15))
		+ ' = ' + CAST(td.Bundle * ((td.Width + (td.WidDec*0.0833)) * (td.Length + (td.LenDec*0.0833)))  
		AS VARCHAR(15)) + u.goodsuom_st
	ELSE gg.Group_st + ' ' + gi.goodsitem_st 
		--+ CASE WHEN isNull(td.Bundle,0)>0 THEN ' B=' + Cast(td.Bundle AS VARCHAR(8)) ELSE '' END  
		--+ ' Q=' + Cast(isNull(td.Qty_Out,0) AS VARCHAR(8)) + u.goodsuom_st
	END as ItemDescription 
	--Sum(isNull(td.MeshTotal,0)) AS MeshTotal, Sum(ISNULL(td.Bundle,0)) AS Bundle
	FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
		AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
		INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
		INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
		INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
		INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
		INNER JOIN gl_ac ga ON g.Godown_ac_id=ga.ac_id
		left outer join gl_ac a on t.GLID=a.ac_id
		left outer join gl_ac a2 on t.GLID_Cr=a2.ac_id
		LEFT OUTER JOIN geo_city c ON c.city_id=a.ac_city_id
		LEFT OUTER JOIN geo_city c2 ON c2.city_id=a2.ac_city_id
		LEFT OUTER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
	WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
		AND t.doc_date BETWEEN @pFromDate AND @pToDate 
		AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
		AND (@pItem_ID>0 AND td.ItemID=@pItem_ID OR @pItem_ID=0)
		AND t.doc_vt_id<>283 
		and (t.doc_vt_id=285 AND td.GodownID=1 OR t.doc_vt_id<>285)

UNION
--*******************************
	SELECT t.doc_date, avd.Name + '-' + t.doc_strid AS Doc_StrID, 
	td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, 
	gg.Group_st + ' ' + gi.goodsitem_st as Group_st,
	g.Godown_title, ga.ac_strid AS Godown_ac_strID, 0 AS OpBalance, td.Qty_In, td.Qty_Out, 0 AS Balance, 
	--isNull(td.Qty_In,0)- ISNULL(td.Qty_Out,0) AS Balance, 
	--Sum(isNull(td.Qty_In,0)) AS Qty_In,
	--Sum(ISNULL(td.Qty_Out,0)) AS Qty_Out, 0 AS Balance, 
	u.goodsuom_st, td.MeshTotal, td.Bundle, 
	CASE WHEN isNull(t.GLID,0)=0 AND isNull(t.GLID_Cr,0)=0 THEN td.Narration
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)=0 THEN a.ac_title + ' ' + c.city_title
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_In,0)>0 
			THEN a.ac_title + ' ' + c.city_title
		WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_Out,0)>0 
			THEN a2.ac_title + ' ' + c2.city_title 
	END AS Narration, td.SERIAL_NO,
	 
	gg.Group_st + '' + gi.goodsitem_st as ItemNameDetail, 

	CASE WHEN td.isBundle=1 THEN ' Q=' + Cast(td.Bundle AS VARCHAR(12)) + u.goodsuom_st
	WHEN td.isMesh=1 THEN ' B=' + Cast(td.Bundle AS VARCHAR(12))
		+ ' x L=' + Cast((td.Length + (td.LenDec*0.0833)) AS VARCHAR(15)) 
		+ ' x W=' + CAST((td.Width + (td.WidDec*0.0833)) AS VARCHAR(15))
		+ ' Q= ' + CAST(td.Bundle * ((td.Width + (td.WidDec*0.0833)) * (td.Length + (td.LenDec*0.0833)))  
		AS VARCHAR(15)) + u.goodsuom_st
	ELSE CASE WHEN isNull(td.Bundle,0)>0 THEN ' B=' + Cast(td.Bundle AS VARCHAR(12)) ELSE '' END  
		+ ' Q=' + Cast(isNull(td.Qty_Out,0) AS VARCHAR(12)) + u.goodsuom_st
	END as ItemQtyDetail, 

	CASE WHEN td.isBundle=1 THEN gg.Group_st + '' + gi.goodsitem_st 
		--+ ' Q=' + Cast(td.Bundle AS VARCHAR(8)) + u.goodsuom_st
	WHEN td.isMesh=1 THEN  gg.Group_st + ' ' + gi.goodsitem_st + ' B=' + Cast(td.Bundle AS VARCHAR(12))
		+ ' x L=' + Cast((td.Length + (td.LenDec*0.0833)) AS VARCHAR(15)) 
		+ ' x W=' + CAST((td.Width + (td.WidDec*0.0833)) AS VARCHAR(15))
		+ ' = ' + CAST(td.Bundle * ((td.Width + (td.WidDec*0.0833)) * (td.Length + (td.LenDec*0.0833)))  
		AS VARCHAR(15)) + u.goodsuom_st
	ELSE gg.Group_st + ' ' + gi.goodsitem_st 
		--+ CASE WHEN isNull(td.Bundle,0)>0 THEN ' B=' + Cast(td.Bundle AS VARCHAR(8)) ELSE '' END  
		--+ ' Q=' + Cast(isNull(td.Qty_Out,0) AS VARCHAR(8)) + u.goodsuom_st
	END as ItemDescription 
	--Sum(isNull(td.MeshTotal,0)) AS MeshTotal, Sum(ISNULL(td.Bundle,0)) AS Bundle
	FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
		AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
		INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
		INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
		INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
		INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
		INNER JOIN gl_ac ga ON g.Godown_ac_id=ga.ac_id
		left outer join gl_ac a on t.GLID=a.ac_id
		left outer join gl_ac a2 on t.GLID_Cr=a2.ac_id
		LEFT OUTER JOIN geo_city c ON c.city_id=a.ac_city_id
		LEFT OUTER JOIN geo_city c2 ON c2.city_id=a2.ac_city_id
		LEFT OUTER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
	WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
		AND t.doc_date BETWEEN @pFromDate AND @pToDate 
		AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
		AND (@pItem_ID>0 AND td.ItemID=@pItem_ID OR @pItem_ID=0)
		AND t.doc_vt_id<>283 
		and (t.doc_vt_id=279 AND td.GodownID=1 OR t.doc_vt_id<>279)

--*******************************		

UNION
	SELECT doc_date, Doc_StrID, ItemID, goodsitem_title, goodsitem_st, Group_title,
	       Group_st, Godown_title, Godown_ac_strID,  OpBalance, Qty_In, Qty_Out, Balance,  
	       goodsuom_st, MeshTotal, Bundle, NARRATION, Serial_No, 
	       ItemNameDetail, ItemQtyDetail, ItemDescription
	  FROM tmpItemUnitLedgerShop
)x

)m ORDER BY m.doc_date, m.SERIAL_NO

/*
CREATE TABLE #tmpTable
(
	doc_date DATETIME, 
	Doc_StrID VARCHAR(20), 
	ItemID BIGINT, 
	goodsitem_title VARCHAR(50), 
	goodsitem_st VARCHAR(30), 
	Group_title VARCHAR(50),
	Group_st VARCHAR(30),
	NARRATION VARCHAR(200), 
	Godown_title VARCHAR(60), 
	Rate MONEY,
	OpBalance Float, 
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
DECLARE @doc_date DATETIME, @doc_strid VARCHAR(20), @Itemid int, @goodsitem_title VARCHAR(60),
	@goodsitem_st VARCHAR(30), @Group_Title VARCHAR(50), @Group_st VARCHAR(30), @NARRATION VARCHAR(200), 
	@Godown_title VARCHAR(60), @Rate MONEY, @OpBalance Float, @Qty_In Float, @Qty_Out Float, @Balance Float, 
	@goodsuom_st VARCHAR(30), @MeshTotal Float, @Bundle Float, @Length Float, 
	@LenDec Float, @Width FLOAT, @WidDec FLOAT, @SERIAL_NO BIGINT
*/	
/*
@doc_vt_id INT, @doc_fiscal_id int, 
	@doc_remarks VARCHAR(20), @doc_status int, @AC_ID bigint, 
    @ac_strid VARCHAR(20), @ac_title VARCHAR(60), @NARRATION VARCHAR(200),
    @Op_DEBIT MONEY, @Op_CREDIT MONEY, 
    @DEBIT MONEY, @CREDIT MONEY, @Balance MONEY, @SERIAL_NO BIGINT,
    @RunBalance MONEY, @OpRunBal MONEY 
*/
/*
SELECT x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_Title, x.Group_st,
x.Godown_title, Sum(x.OpBalance) AS OpBalance, 
Sum(x.Qty_In) AS Qty_In, Sum(x.Qty_Out) AS Qty_Out, 
Sum(x.OpBalance) + Sum(x.Qty_In) - Sum(x.Qty_Out) AS Balance, 
x.goodsuom_st, Sum(x.MeshTotal) AS MeshTotal, Sum(x.Bundle) AS Bundle, 
x.Group_st + '' + x.goodsitem_st AS ItemName
FROM (
	
DECLARE cur_ItemLedger CURSOR FOR 
SELECT @pFromDate AS doc_date, 'Opening Balance' as doc_strid, 
td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st,
g.Godown_title, Sum(isNull(td.Qty_In,0))-Sum(ISNULL(td.Qty_Out,0)) AS OpBalance, 
0 AS Qty_In, 0 AS Qty_Out, 0 AS Balance, u.goodsuom_st, 
0 AS MeshTotal, 0 AS Bundle, 'Opening Balance' AS Narration, 0 AS SERIAL_NO
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
	AND t.doc_date < @pFromDate  
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
GROUP BY td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title,gg.Group_st,
g.Godown_title,u.goodsuom_st
UNION 

SELECT t.doc_date, avd.Name + '-' + t.doc_strid AS Doc_StrID, 
td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st,
g.Godown_title, 0 AS OpBalance, td.Qty_In, td.Qty_Out, 
isNull(td.Qty_In,0)- ISNULL(td.Qty_Out,0) AS Balance, 
--Sum(isNull(td.Qty_In,0)) AS Qty_In,
--Sum(ISNULL(td.Qty_Out,0)) AS Qty_Out, 0 AS Balance, 
u.goodsuom_st, td.MeshTotal, td.Bundle,
CASE WHEN isNull(t.GLID,0)=0 AND isNull(t.GLID_Cr,0)=0 THEN td.Narration
	WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)=0 THEN a.ac_title
	WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_In,0)>0 THEN a.ac_title
	WHEN  isNull(t.GLID,0)>0 AND isNull(t.GLID_Cr,0)>0 AND isNull(td.Qty_Out,0)>0 THEN a2.ac_title 
END AS Narration, td.SERIAL_NO
--Sum(isNull(td.MeshTotal,0)) AS MeshTotal, Sum(ISNULL(td.Bundle,0)) AS Bundle
FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
	AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
	INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
	INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
	INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
	INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
	left outer join gl_ac a on t.GLID=a.ac_id
	left outer join gl_ac a2 on t.GLID_Cr=a2.ac_id
	LEFT OUTER JOIN ALCP_ValidationDescription avd ON t.doc_vt_id=avd.DescID AND avd.ValidationId=69
WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
	AND t.doc_date BETWEEN @pFromDate AND @pToDate 
	AND (@pGodown>0 AND td.GodownID=@pGodown OR @pGodown=0)
	
OPEN cur_ItemLedger

FETCH NEXT FROM cur_ItemLedger INTO @doc_date, @doc_strid,@Itemid, @goodsitem_title,
	@goodsitem_st, @Group_Title, @Group_st, @Godown_title, 
	@OpBalance, @Qty_In, @Qty_Out, @Balance,
	@goodsuom_st, @MeshTotal, @Bundle, @NARRATION, @SERIAL_NO

WHILE @@FETCH_STATUS=0
BEGIN
	
	
	FETCH NEXT FROM cur_ItemLedger INTO @doc_date, @doc_strid,@Itemid, @goodsitem_title,
		@goodsitem_st, @Group_Title, @Group_st, @Godown_title, 
		@OpBalance, @Qty_In, @Qty_Out, @Balance,
		@goodsuom_st, @MeshTotal, @Bundle, @NARRATION, @SERIAL_NO

END
*/
--	@MeshTotal,@Bundle, @Length, @LenDec, @Width, @WidDec, @SERIAL_NO

--GROUP BY td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title,gg.Group_st,
--g.Godown_title,u.goodsuom_st

/*
)x 
GROUP BY x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_title, x.Group_st,
x.Godown_title, x.goodsuom_st
*/	
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
