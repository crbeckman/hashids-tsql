﻿CREATE FUNCTION [hashids].[encodeId]
(
	@number int
)
RETURNS varchar(255)
WITH SCHEMABINDING
AS
BEGIN
	-- Options Data
	DECLARE
		@salt varchar(255) = 'CE6E160F053C41518582EA36CE9383D5',
		@alphabet varchar(255) = 'NxBvP0nK7QgWmejLzwdA6apRV25lkOqo8MX1ZrbyGDE3',
		@seps varchar(255) = 'CuHciSFTtIfUhs',
		@guards varchar(255) = '49JY',
		@minHashLength int = 4;

	-- Working Data
	DECLARE
		@numbersHashInt int = @number % 100,
		@lottery char(1),
		@buffer varchar(255),
		@last varchar(255),
		@ret varchar(255);

	SELECT
		@lottery = SUBSTRING(@alphabet, (@numbersHashInt % LEN(@alphabet)) + 1, 1),
		@ret = @lottery,
		@buffer = @lottery + @salt + @alphabet;

	SELECT
		@alphabet = [hashids].[consistentShuffle](@alphabet, SUBSTRING(@buffer, 1, LEN(@alphabet)));

	SELECT
		@last = [hashids].[hash](@number, @alphabet),
		@ret = @ret + @last;
	----------------------------------------------------------------------------
	-- Enforce minHashLength
	----------------------------------------------------------------------------
	IF LEN(@ret) < @minHashLength BEGIN
		DECLARE
			@guardIndex int,
			@guard char(1);

		SELECT
			@guardIndex = (@numbersHashInt + ASCII(SUBSTRING(@ret, 1, 1))) % LEN(@guards),
			@guard = SUBSTRING(@guards, @guardIndex + 1, 1),
			@ret = @guard + @ret;

		IF LEN(@ret) < @minHashLength BEGIN
			SELECT
				@guardIndex = (@numbersHashInt + ASCII(SUBSTRING(@ret, 3, 1))) % LEN(@guards),
				@guard = SUBSTRING(@guards, @guardIndex + 1, 1),
				@ret = @ret + @guard;
		END
	END
	RETURN @ret;
END
