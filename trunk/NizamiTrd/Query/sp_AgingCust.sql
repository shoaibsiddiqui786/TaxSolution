--/*
create Procedure [dbo].[sp_AgingCust]
	@Code Varchar(14), 
	@CreditDay int,
	@PDebit numeric OUTPUT,
	@PLessDays numeric OUTPUT,
	@PLess10 numeric OUTPUT,
	@PLess20 numeric OUTPUT,
	@PLess30 numeric OUTPUT,
	@PAbove numeric OUTPUT,
	@PDate char(10)
AS
--*/

/*
Declare @Code Varchar(14), @CreditDay int
	SET @Code = '1-3-02-01-0016' 
	--SET @Code = '1-3-02-01-0001' 
	SET @CreditDay = 60
	@PDebit numeric OUTPUT,
	@PLessDays numeric OUTPUT,
	@PLess10 numeric OUTPUT,
	@PLess20 numeric OUTPUT,
	@PLess30 numeric OUTPUT,
	@PAbove numeric OUTPUT,
	@PDate char(10)

*/

Declare @RunRecNo int, @CashRecovery Float, @RunAmount Float
SET @RunRecNo = 0
SET @CashRecovery = 0
SET @RunAmount = 0
--/*
CREATE TABLE #tmpTable(
	Date DateTime, 
	Voucher Varchar(20), 
	Des Varchar(250), 
	Des2 Varchar(250), 
	Debit Float, 
	DueDate DateTime, 
	DayDue Varchar(10), 
	Remaining Float, 
	Balance Float, 
	Status Varchar(10), 
	RecNo int,
	Cheq_No Varchar(12),
	Type Varchar(3) 
)
--*/
SET NoCount On
/*
Select @CashRecovery = Sum(isNull(Credit,0)) From Ledger 
Where Code = @Code AND isNull(Credit,0)>0
		AND isNull(Cheq_No,'') NOT IN (Select Cheq_No From Ledger 
				Where Code=@Code AND Type='RBR' 
				AND isNull(Cheq_No,'')<>'')
*/
Select @CashRecovery = Sum(isNull(Credit,0)) From Ledger 
	Where Code = @Code AND isNull(Credit,0)>0
	AND isNull(Cheq_No,'') NOT IN (Select Cheq_No From Ledger 
	Where Code=@Code AND Type='RBR' 
	AND isNull(Cheq_No,'') IN (Select Cheq_No From Ledger 
	Where Code=@Code AND Type='BRV' AND isNull(Cheq_No,'')<>''))

--Print @CashRecovery 
--SET @CashRecovery = @CashRecovery + 5

DECLARE cur_Aging CURSOR FOR
	Select Date, Voucher, Des, Des2, Debit, DateAdd(day, @CreditDay,Date) AS DueDate, 
	--DateDiff(Day, DateAdd(day, @CreditDay, Date), GetDate()) AS DayDue, 
	DateDiff(Day, Date, @PDate) AS DayDue, 
	0 As Remaining, 0 AS Balance, 1 AS Status, 0 AS RecNo, Cheq_No, Type
	--INTO #TmpTable 
	From Ledger 
	Where Code = @Code AND isNull(Debit,0)>0 --AND Type<>'RBR'
		AND isNull(Cheq_No,'') NOT IN (Select Cheq_No From Ledger 
			Where Code=@Code AND Type='RBR' 
			AND isNull(Cheq_No,'') IN (Select Cheq_No From Ledger 
			Where Code=@Code AND Type='BRV' AND isNull(Cheq_No,'')<>''))
	Order by Date

	Open cur_Aging

	Declare @mDate DateTime, @mVoucher Varchar(20), 
		@mDes Varchar(100), @mDes2 Varchar(100), @mDebit Float, 
		@mDueDate DateTime, @mDayDue Varchar(10), @mRemaining Float, 
		@mBalance Float, @mStatus Varchar(10), @mRecNo int, 
		@mCheq_No Varchar(12), @mType Varchar(3)
	
	FETCH NEXT FROM cur_Aging INTO @mDate, @mVoucher, @mDes, @mDes2, @mDebit, 
		@mDueDate, @mDayDue, @mRemaining, @mBalance, @mStatus, @mRecNo, 
		@mCheq_No, @mType

	While @@Fetch_Status = 0
	Begin
		SET @RunRecNo = @RunRecNo + 1
		SET @RunAmount = @CashRecovery - @mDebit
		IF @RunAmount>0 AND @CashRecovery > @mDebit
			BEGIN 
				SET @CashRecovery = @CashRecovery - @mDebit
				SET @mRemaining = @mDebit --@CashRecovery
				SET @mStatus = ''
			END 
		ELSE
			BEGIN
				IF @RunAmount <= 0 
					BEGIN 
						--IF @mBalance > 0 AND @mDayDue>=@CreditDay --@CashRecovery <= @mDebit --
						IF @CashRecovery > 0 AND @mDayDue>=@CreditDay --@CashRecovery <= @mDebit
							BEGIN
								SET @mRemaining = @CashRecovery
								SET @CashRecovery = 0
								SET @mStatus = 'Due'
							END
						ELSE
							BEGIN
								SET @CashRecovery = 0
								SET @mRemaining = 0	
								IF @mDayDue>=@CreditDay 
									BEGIN
										SET @mStatus = 'Due'
									END
								ELSE
									BEGIN
										SET @mStatus = ''
									END
								
							END 
					END
			END

		Insert INTO #TmpTable 
			Values (@mDate, @mVoucher, @mDes, @mDes2, @mDebit, @mDueDate, 
			Case WHEN @mDebit-@mRemaining=0 THEN '' ELSE @mDayDue END, 
			@mRemaining, @mDebit-@mRemaining, 
			@mStatus, @RunRecNo, @mCheq_No, @mType)
		
		FETCH NEXT FROM cur_Aging INTO @mDate, @mVoucher, @mDes, @mDes2, @mDebit, 
			@mDueDate, @mDayDue, @mRemaining, @mBalance, @mStatus, @mRecNo, 
			@mCheq_No, @mType
	End

Close cur_Aging
Deallocate cur_Aging

--DECLARE @DueBal Money, @Day10Bal Money, @Day20Bal Money, @Day30Bal Money, @DayAbove Money
/*
Select Voucher, Date, Debit, Remaining, Balance, Status, DueDate, DayDue, Des, 
	RecNo, Cheq_No, Type from #TmpTable
*/
DECLARE @CreditDayLess10 int, @CreditDayLess20 int, @CreditDayLess30 int
SET @CreditDayLess10 = @CreditDay-10
SET @CreditDayLess20 = @CreditDay-20
SET @CreditDayLess30 = @CreditDay-30

PRINT @CreditDayLess10
PRINT @CreditDayLess20
PRINT @CreditDayLess30

-- Process for Summery 
DECLARE curAgingSmry CURSOR FOR 
Select Voucher, Date, Debit, Remaining, Balance, Status, DueDate, DayDue, Des, 
	RecNo, Cheq_No, Type from #TmpTable

OPEN curAgingSmry

SET @mVoucher=''
SET @mDate= NULL
SET @mDebit=0 
SET @mRemaining=0 
SET @mBalance=0
SET @mStatus=0
SET @mDueDate=NULL
SET @mDayDue=''
SET @mDes=''
SET @mRecNo=0
SET @mCheq_No=''
SET @mType =''
	
FETCH next FROM curAgingSmry INTO @mVoucher , @mDate, @mDebit, @mRemaining, 
	@mBalance, @mStatus, @mDueDate, @mDayDue, @mDes, 
	@mRecNo, @mCheq_No, @mType 

SET @PLessDays =0
SET @PLess10 =0
SET @PLess20 =0
SET @PLess30 =0
SET @PAbove=0
WHILE @@FETCH_STATUS=0
	BEGIN
		
--PRINT @mDayDue
		IF @mDayDue>=@CreditDay SET @PLessDays = @PLessDays + @mBalance
		IF @mDayDue>=@CreditDayLess10 AND @mDayDue<@CreditDay SET @PLess10 = @PLess10 + @mBalance
		IF @mDayDue>=@CreditDayLess20 AND @mDayDue<@CreditDayLess10 SET @PLess20 = @PLess20 + @mBalance
		IF @mDayDue>=@CreditDayLess30 AND @mDayDue<@CreditDayLess20 SET @PLess30 = @PLess30 + @mBalance
		IF @mDayDue>=0 AND @mDayDue<@CreditDayLess30 SET @PAbove = @PAbove + @mBalance
/*
		IF @mDayDue>=@CreditDay SET @PLessDays = @PLessDays + @mBalance
		IF @mDayDue>34 AND @mDayDue<@CreditDay SET @PLess10 = @PLess10 + @mBalance
		IF @mDayDue>24 AND @mDayDue<35 SET @PLess20 = @PLess20 + @mBalance
		IF @mDayDue>14 AND @mDayDue<25 SET @PLess30 = @PLess30 + @mBalance
		IF @mDayDue>0 AND @mDayDue<15 SET @PAbove = @PAbove + @mBalance
*/		
		FETCH next FROM curAgingSmry INTO @mVoucher, @mDate, @mDebit, 
			@mRemaining, @mBalance, @mStatus, @mDueDate, @mDayDue, @mDes, 
			@mRecNo, @mCheq_No, @mType 

	END

--PRINT 'Due Bal : ' + cast(isnull(@PLessDays,0) AS varchar(15)) + ' Day 10 Bal : ' + Cast(isNull(@PLess10,0) AS varchar(15)) + ' Day 20 Bal : ' + cast(isNull(@PLess20,0) AS varchar(15)) + ' Day 30 Bal : ' + cast(isNull(@PLess30,0) AS varchar(15)) + ' Day <45 Bal : ' + cast(isNull(@PAbove,0) AS varchar(15))
--PRINT 'Due Bal : ' + cast(isnull(@DueBal,0) AS varchar(15)) + ' Day 10 Bal : ' + Cast(isNull(@Day10Bal,0) AS varchar(15)) + ' Day 20 Bal : ' + cast(isNull(@Day20Bal,0) AS varchar(15)) + ' Day 30 Bal : ' + cast(isNull(@Day30Bal,0) AS varchar(15)) + ' Day <45 Bal : ' + cast(isNull(@DayAbove,0) AS varchar(15))

CLOSE curAgingSmry
DEALLOCATE curAgingSmry

Drop Table #TmpTable

