DROP DATABASE IF EXISTS [AmortizationSchedules]
GO


CREATE DATABASE [AmortizationSchedules]
GO


USE [AmortizationSchedules]
GO

/**
* Calculates the payment for a loan based on constant period and a constant interest rate.
*/
CREATE FUNCTION [dbo].[PMT]
	(@Rate FLOAT    -- The interest rate for the loan.
	,@Periods INT   -- The total number of months for the loan.
	,@Present FLOAT -- The present value, or the total amount that a series of future payments is worth now; also known as the principal.
	,@Future FLOAT  -- Optional. The future value, or a cash balance you want to attain after the last payment is made. If fv is omitted, it is assumed to be 0 (zero), that is, the future value of a loan is 0.
	,@Type INT)     -- Optional. The number 0 (zero) or 1 and indicates when payments are due. (0 = End of Period , 1 = Start of Period)
RETURNS FLOAT
    BEGIN   
	    SET @Type = ISNULL(@Type, 0);
		SET @Future = ISNULL(@Future, 0);
		DECLARE @Result AS FLOAT = 0;
		DECLARE @Term AS FLOAT = 0;

		IF @Rate=0
		BEGIN
			SET @Result=(@Present+@Future)/@Periods;
		END --IF @Rate=0
		ELSE
		BEGIN --IF @Rate <> 0
			SET @term = POWER(1+@rate, @periods);
			
			IF @Type=1
			BEGIN
				SET @Result = (@Future*@Rate / (@Term-1) + @Present*@Rate / (1-1/@Term)) / (1+@Rate)
			END
			
			ELSE
			BEGIN
				SET @Result = @Future*@Rate/(@term-1)+@Present*@Rate / (1-1/@Term)
			END

		END --IF @Rate <> 0

        RETURN -@Result  
    END;
GO


/**
* Calculates the future value of an investment based on a constant interest rate. You can use FV with either periodic, constant payments, or a single lump sum payment.
*/
CREATE FUNCTION [dbo].[FV]
	(@Rate FLOAT     -- The interest rate for the loan.
	,@Periods INT    -- The total number of months for the loan.
	,@Payment FLOAT  -- The payment made each month.
	,@Value FLOAT    -- Optional. The present value, or the lump-sum amount that a series of future payments is worth right now. If pv is omitted, it is assumed to be 0 (zero), and you must include the pmt argument.
	,@Type INT)      -- Optional. The number 0 (zero) or 1 and indicates when payments are due. (0 = End of Period , 1 = Start of Period)
RETURNS FLOAT
    BEGIN   
	    SET @Type = ISNULL(@Type,0);
		SET @Value = ISNULL(@Value,0);
		DECLARE @Result AS FLOAT=0;
		DECLARE @Term AS FLOAT = 0;

		IF @Rate=0
		BEGIN
			SET @Result=(@Value+@Payment)*@Periods;
		END --IF @Rate=0
		ELSE
		BEGIN --IF @Rate <> 0
			SET @term = POWER(1+@rate,@periods);
			
			IF @Type=1
			BEGIN
				SET @Result=@Value*@Term+@Payment*(1+@Rate)*(@Term-1.0)/@Rate
			END
			ELSE
			BEGIN
				SET @Result=@value*@term+@Payment*(@Term-1)/@Rate	
			END
		END --IF @Rate <> 0

        RETURN -@Result  
    END;
GO


/**
* Calculates the interest payment for a given period for an investment based on periodic, constant payments and a constant interest rate.
*/
CREATE FUNCTION [dbo].[IPMT]
	(@Rate FLOAT
	,@Period INT
	,@Periods INT
	,@Present FLOAT
	,@Future FLOAT  -- Optional.
	,@Type INT)     -- Optional.
RETURNS FLOAT
    BEGIN   
	    SET @Type = ISNULL(@Type,0);
		DECLARE @Payment AS FLOAT = (SELECT dbo.PMT(@Rate,@Periods,@Present,@Future,@Type))
		DECLARE @Interest AS FLOAT = 0.0;
		
		IF @Period=1
		BEGIN
			IF @Type=1
			BEGIN
				SET @Interest=0
			END --IF @Type=1
			ELSE
			BEGIN
				SET @Interest=-@Present
			END 
		END --IF @Period=1
		ELSE --IF @Period <> 1
		BEGIN
			IF @Type=1
			BEGIN
				SET @Interest=dbo.FV(@Rate,@Period-2,@Payment,@Present,1)-@Payment
			END --IF @Type=1
			ELSE --IF @Type<>1
			BEGIN
				SET @Interest = dbo.FV(@Rate,@Period-1,@Payment,@Present,0)
			END --IF @Type<>1
		END ----IF @Period <> 1
		
        RETURN @Interest*@Rate
    END;
GO


/**
* Calculates the payment on the principal for a given period for an investment based on periodic, constant payments and a constant interest rate.
*/
CREATE FUNCTION [dbo].[PPMT]
	(@Rate Float
	,@Period INT
	,@Periods INT
	,@Present Float
	,@Future Float  -- Optional.
	,@Type INT)     -- Optional.
RETURNS Float
    BEGIN   
        RETURN dbo.PMT(@Rate,@Periods,@Present,@Future,@Type) - dbo.IPMT(@Rate,@Period,@Periods,@Present,@Future,@Type)
    END;
GO

/**
* The amortization schedule show the period, the payment amount, the principal payment amount, and the interest payment amount.
*/
CREATE FUNCTION [dbo].AMORT
( @PV as Float,
 @Rate as Float,
 @Periods as Float,
 @FV as Float,      -- Optional.
 @Paytype as Float  -- Optional.
)
RETURNS TABLE
    AS
    RETURN
with mc as
(
    select cast(1 as float) as [Period]
    ,cast([dbo].PMT(@Rate/12,@Periods,-@PV,@FV,@Paytype) as float) as [Payment Amount]
    ,cast([dbo].PPMT(@Rate/12,1,@Periods,-@PV,@FV,@Paytype) as float) as [Principal Payment Amount]
    ,cast([dbo].IPMT(@Rate/12,1,@Periods,-@PV,@FV,@Paytype) as float) as [Interest Payment Amount]
    union all
    select Period + cast(1 as float)
    ,cast([dbo].PMT(@Rate/12,@Periods,-@PV,@FV,@Paytype) as float)
    ,cast([dbo].PPMT(@Rate/12,Period + cast(1 as float),@Periods,-@PV,@FV,@Paytype) as float)
    ,cast([dbo].IPMT(@Rate/12,Period + cast(1 as float),@Periods,-@PV,@FV,@Paytype) as float)
    from mc
    where Period < @Periods   
)     select *
    From mc
GO


CREATE PROCEDURE SelectSpitzerTable
(
@PV float,
@Rate float,
@Periods int,
@Top int
)
AS
BEGIN
SELECT TOP (@Top) * FROM [dbo].AMORT(@PV, @Rate, @Periods, NULL, NULL)
END