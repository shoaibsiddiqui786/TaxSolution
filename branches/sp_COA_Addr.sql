--/*
ALTER PROCEDURE dbo.sp_COA_Addr
	@pDoc_Fiscal_ID INT,
	@pac_id INT 
AS 
--*/
/*
DECLARE @pDoc_Fiscal_ID INT, @pac_id INT
SET @pDoc_Fiscal_ID=1
SET @pac_id=226
*/
/*
CREATE TABLE #tmpCOA_Address(
	ac_id bigint,
	SpaceAc_StrID varchar(8000),
	ac_strid varchar(30),
	ac_title varchar(50),
	ac_st varchar(15),
	ac_level tinyint,
	istran bit,
	isTranDesc varchar(13),
	isdisabled bit,
	isDisableDesc varchar(8),
	addr_sqid int,
	addr_type_id int,
	addr_type_title varchar(20),
	addr_salute_id int,
	salute_title varchar(10),
	addr_contactperson varchar(50),
	addr_address1 varchar(50),
	addr_address2 varchar(50),
	addr_country_id int,
	country_title varchar(25),
	addr_province_id int,
	province_title varchar(30),
	addr_city_id int,
	city_title varchar(20),
	addr_zip varchar(10),
	addr_phone varchar(15),
	addr_ext varchar(15),
	addr_mobile varchar(15),
	addr_fax varchar(15),
	addr_email varchar(50),
	addr_web varchar(50),
	addr_ref varchar(50),
	addr_remarks varchar(50),
	Owner_ID int
) 
*/

DECLARE @strac_get AS VARCHAR(30)

DECLARE @ac_id INT, @ac_strid VARCHAR(30), @ac_strtruncated VARCHAR(30)
DECLARE @ac_title VARCHAR(200), @ac_st VARCHAR(15), @ac_level INT, 
	@ac_stridParent VARCHAR(30), @ac_titleParent VARCHAR(100)

SELECT @ac_id=ac_id, @ac_strid=ac_strid, @ac_stridParent=ac_strid, 
	@ac_titleParent=ac_title, @ac_level=ac_level
  FROM gl_ac WHERE ac_id=@pac_id

--@ac_strtruncated=ac_strtruncated,
SELECT @ac_strtruncated= CASE WHEN Right(@ac_strid,12)='0-00-00-0000' THEN Left(@ac_strid,1) 
	WHEN  Right(@ac_strid,10)='00-00-0000' THEN Left(@ac_strid,3) 
	WHEN  Right(@ac_strid,7)='00-0000' THEN Left(@ac_strid,6)
	WHEN  Right(@ac_strid,4)='0000' THEN Left(@ac_strid,9)
	ELSE '0' END 
	
--PRINT ' Str Truncated :' + isNull(@ac_strtruncated, '0')

SET @strac_get = ISNULL(LEFT(@ac_strid, LEN(@ac_strtruncated)),0)
--PRINT ' Str Account :' + isNull(@strac_get,'0')

SELECT a.ac_id, Space(a.ac_level*3) + a.ac_strid AS SpaceAc_StrID, a.ac_strid, 
	a.ac_title, a.ac_st, a.ac_level, --c.city_title,  
	a.istran, CASE WHEN a.istran=0 THEN 'Parent' ELSE 'Transactional' END AS isTranDesc, 
	a.isdisabled, CASE WHEN a.isdisabled =0  THEN 'Active' ELSE 'InActive' END AS isDisableDesc,
	ca.addr_sqid, ca.addr_type_id, cat.addr_type_title,
	ca.addr_salute_id, cs.salute_title, ca.addr_contactperson,
	ca.addr_address1, ca.addr_address2, ca.addr_country_id, gct.country_title, 
	ca.addr_province_id, gp.province_title,
	ca.addr_city_id, gc.city_title, ca.addr_zip, ca.addr_phone, ca.addr_ext, ca.addr_mobile,
	ca.addr_fax, ca.addr_email, ca.addr_web, ca.addr_ref, ca.addr_remarks,
	ca.Owner_ID
	--INTO tmpCOA_Address
FROM gl_ac a INNER JOIN geo_city c ON a.ac_city_id=c.city_id
	LEFT OUTER JOIN cmn_address ca ON a.Addr_UID=ca.addr_uid
	LEFT OUTER JOIN cmn_address_type cat ON ca.addr_type_id=cat.addr_type_id
	LEFT OUTER JOIN cmn_salute cs ON ca.addr_salute_id=cs.salute_id
	LEFT OUTER JOIN geo_city gc ON ca.addr_city_id=gc.city_id
	LEFT OUTER JOIN geo_province gp ON ca.addr_province_id=gp.province_id
	LEFT OUTER JOIN geo_country gct ON ca.addr_country_id=gct.country_id
WHERE (@strac_get='0'
	OR @strac_get<>'0' AND LEFT(a.ac_strid, LEN(@ac_strtruncated))=@strac_get)
	--AND a.istran=1
ORDER BY a.ac_strid

--select ID, Name, Photo from Photos where id=28;

--SELECT * FROM gl_ac ORDER BY ac_strid



