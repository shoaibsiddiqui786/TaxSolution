/*
ALTER PROCEDURE sp_ItemSaleRpt 
	@pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10),
	@pItemID INT,
	@pItemGroupID INT,
	@pGL_ID INT,
	@pCountry INT,
	@pProvince INT,
	@pCity int
AS 
*/
--/*
DECLARE @pDoc_Fiscal_ID int,
	@pFromDate Varchar(10), 
	@pToDate Varchar(10), 
	@pItemID INT,
	@pItemGroupID INT,
	@pGL_ID INT,
	@pCountry INT,
	@pProvince INT,
	@pCity int
	 
set @pDoc_Fiscal_ID=1
set @pFromDate='2013-05-04'
set @pToDate = '2013-12-04'
SET @pItemID =0
SET @pItemGroupID=0
SET @pGL_ID=0
SET @pCountry=0
SET @pProvince=1
SET @pCity =20
--*/

SELECT  x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_title, x.Group_st,
	x.Godown_title, x.Rate, Sum(x.Qty_Out) AS Qty_Out,
	CASE WHEN x.isMesh=1 THEN  x.Rate * Sum(x.MeshTotal)
	WHEN x.isBundle=1 THEN x.Rate * Sum(x.Bundle)
	WHEN x.isMesh=0 AND x.isBundle=0 THEN x.Rate* Sum(x.Qty_Out) END AS Amount, 
	x.goodsuom_st, Sum(x.MeshTotal) AS MeshTotal, Sum(x.Bundle) AS Bundle

FROM (
	SELECT td.ItemID, gi.goodsitem_title, gi.goodsitem_st, gg.Group_title, gg.Group_st,
	g.Godown_title + ' ' + gc.city_title AS Godown_Title, td.Rate, 
	--0 AS OpBalance, isNull(td.Qty_In,0) AS Qty_In,
	ISNULL(td.Qty_Out,0) AS Qty_Out, --0 AS Balance, 
	u.goodsuom_st, 
	--Sum(isNull(td.MeshTotal,0)) AS MeshTotal, 
		CASE WHEN (isNull(td.Qty_In,0)>0 AND isNull(td.MeshTotal,0)>0) 
			or (isNull(td.Qty_In,0)=0 AND isNull(td.Qty_Out,0)=0 AND isNull(td.MeshTotal,0)>0) 
		THEN isNull(td.MeshTotal,0) * -1 ELSE isNull(td.MeshTotal,0) END AS MeshTotal, 
		ISNULL(td.Bundle,0) AS Bundle, td.SERIAL_NO, td.isMesh, td.isBundle
	FROM inv_tran t INNER JOIN inv_trandtl td ON t.doc_vt_id=td.doc_vt_id
		AND t.doc_fiscal_id=td.doc_fiscal_id AND t.doc_id=td.doc_id
		INNER JOIN gds_item gi ON gi.goodsitem_id=td.ItemID
		INNER JOIN gds_Group gg ON gg.Group_id=gi.Group_id
		INNER JOIN gds_uom u ON td.UOMID=u.goodsuom_id
		INNER JOIN cmn_Godown g ON td.GodownID=g.Godown_id
		INNER JOIN gl_ac a ON t.GLID=a.ac_id -- g.Godown_ac_id=a.ac_id 
		INNER JOIN geo_city gc ON a.ac_city_id=gc.city_id
		INNER JOIN geo_province p ON gc.city_pid = p.province_id
		INNER JOIN geo_country c ON p.province_pid=c.country_id
	WHERE t.doc_fiscal_id=@pDoc_Fiscal_ID 
		AND t.doc_date BETWEEN @pFromDate AND @pToDate 
		AND (@pItemID>0 AND td.ItemID=@pItemID OR @pItemID=0)
		AND (@pItemGroupID>0 AND gi.Group_id=@pItemGroupID OR @pItemGroupID=0)
		--AND (@pItemGroupID>0 AND gg.Group_id=@pItemGroupID OR @pItemGroupID=0) 
		AND (@pGL_ID>0 AND t.GLID=@pGL_ID OR @pGL_ID=0)
		--AND (@pGL_ID>0 AND  a.ac_id=@pGL_ID OR @pGL_ID=0)
		AND (@pCity>0 AND gc.city_id=@pCity OR @pCity=0)
		AND (@pProvince>0 AND p.province_id=@pProvince OR @pProvince=0)
		AND (@pCountry>0 AND c.country_id=@pCountry OR @pCountry=0)
		AND (td.Rate>0)
		AND (td.doc_vt_id IN (272,274,283,286,287))
)x 	
GROUP BY  x.ItemID, x.goodsitem_title, x.goodsitem_st, x.Group_title, x.Group_st,
	x.Godown_title, x.Rate, x.goodsuom_st, x.isMesh, x.isBundle --, x.MeshTotal, x.Bundle

select ID, Name, Photo from Photos where id=28;

--SET NOCOUNT OFF
