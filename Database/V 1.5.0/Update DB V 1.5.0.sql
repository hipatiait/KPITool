/* 
	Updates de the KPIDB database to version 1.5.0 
*/

Use [Master]
GO 

IF  NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'KPIDB')
	RAISERROR('KPIDB database Doesn´t exists. Create the database first',16,127)
GO

PRINT 'Updating KPIDB database to version 1.5.0'

Use [KPIDB]
GO
PRINT 'Verifying database version'

/*
 * Verify that we are using the right database version
 */

IF  NOT ((EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_GetVersionMajor]') AND type in (N'P', N'PC'))) 
	AND 
	(EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_GetVersionMinor]') AND type in (N'P', N'PC'))))
		RAISERROR('KPIDB database has not been initialized.  Cant find version stored procedures',16,127)


declare @smiMajor smallint 
declare @smiMinor smallint

exec [dbo].[usp_GetVersionMajor] @smiMajor output
exec [dbo].[usp_GetVersionMinor] @smiMinor output

IF NOT (@smiMajor = 1 AND @smiMinor = 4) 
BEGIN
	RAISERROR('KPIDB database is not in version 1.4 This program only applies to version 1.4',16,127)
	RETURN;
END

PRINT 'KPIDB Database version OK'
GO

-----------------------------------------

/****** Object:  Table [dbo].[tbl_SEG_ObjectPublic]    Script Date: 05/12/2016 12:08:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_SEG_ObjectPublic]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[tbl_SEG_ObjectPublic](
	[objectTypeID] [varchar](20) NOT NULL,
	[objectID] [int] NOT NULL,
	[objectActionID] [varchar](20) NOT NULL,
 CONSTRAINT [PK_tbl_SEG_ObjectPublic] PRIMARY KEY CLUSTERED 
(
	[objectTypeID] ASC,
	[objectID] ASC,
	[objectActionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  ForeignKey [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectActions]    Script Date: 05/12/2016 12:08:44 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectActions]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_SEG_ObjectPublic]'))
ALTER TABLE [dbo].[tbl_SEG_ObjectPublic]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectActions] FOREIGN KEY([objectActionID])
REFERENCES [dbo].[tbl_SEG_ObjectActions] ([objectActionID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectActions]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_SEG_ObjectPublic]'))
ALTER TABLE [dbo].[tbl_SEG_ObjectPublic] CHECK CONSTRAINT [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectActions]
GO
/****** Object:  ForeignKey [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectTypes]    Script Date: 05/12/2016 12:08:44 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectTypes]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_SEG_ObjectPublic]'))
ALTER TABLE [dbo].[tbl_SEG_ObjectPublic]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectTypes] FOREIGN KEY([objectTypeID])
REFERENCES [dbo].[tbl_SEG_ObjectTypes] ([objectTypeID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectTypes]') AND parent_object_id = OBJECT_ID(N'[dbo].[tbl_SEG_ObjectPublic]'))
ALTER TABLE [dbo].[tbl_SEG_ObjectPublic] CHECK CONSTRAINT [FK_tbl_SEG_ObjectPublic_tbl_SEG_ObjectTypes]
GO

/****** Object:  UserDefinedFunction [dbo].[tvf_SplitStringInTable]    Script Date: 05/12/2016 12:14:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tvf_SplitStringInTable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[tvf_SplitStringInTable]
GO

/****** Object:  UserDefinedFunction [dbo].[tvf_SplitStringInTable]    Script Date: 05/12/2016 12:14:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--===========================================================================================================
-- Modified on May 28 2007
-- Modified by Ivan Krsul
-- Modification Description:  Made the string to split longer... from 500 to 1000 characters
CREATE FUNCTION [dbo].[tvf_SplitStringInTable]
(
    @varString VARCHAR(8000),
    @varDelimiter VARCHAR(5)
)
RETURNS @tblSplittedValues TABLE
(
  --OccurenceId SMALLINT IDENTITY(1,1),
  splitvalue VARCHAR(8000)
)
AS
BEGIN
	DECLARE @intSplitLength INT

	WHILE LEN(@varString) > 0
		BEGIN
			SELECT @intSplitLength = 
				(CASE CHARINDEX(@varDelimiter,@varString) 
				WHEN 0 THEN
					LEN(@varString) 
				ELSE CHARINDEX(@varDelimiter,@varString) -1  
				END)

			INSERT INTO @tblSplittedValues
			SELECT SUBSTRING(@varString,1,@intSplitLength)

			SELECT @varString = 
				(CASE (LEN(@varString) - @intSplitLength) 
					WHEN 0 THEN ''
					ELSE	
						RIGHT(@varString, LEN(@varString) - @intSplitLength - 1) 
				END)
		END
	RETURN
END



GO


/****** Object:  StoredProcedure [dbo].[usp_AUTOCOMPLETE_SearchUsers]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_AUTOCOMPLETE_SearchUsers]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_AUTOCOMPLETE_SearchUsers]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_DeleteObjectPermissions]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_DeleteObjectPermissions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_DeleteObjectPermissions]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_DeleteObjectPublic]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_DeleteObjectPublic]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_DeleteObjectPublic]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForActivity]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectActionsForActivity]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectActionsForActivity]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForKPI]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectActionsForKPI]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectActionsForKPI]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForOrganization]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectActionsForOrganization]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectActionsForOrganization]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForPeople]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectActionsForPeople]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectActionsForPeople]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForProject]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectActionsForProject]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectActionsForProject]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectPermissionsByObject]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectPermissionsByObject]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectPermissionsByObject]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectPermissionsByUser]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_GetObjectPermissionsByUser]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_GetObjectPermissionsByUser]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_InsertObjectPermissions]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_InsertObjectPermissions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_InsertObjectPermissions]
GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_InsertObjectPublic]    Script Date: 05/12/2016 12:11:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SEG_InsertObjectPublic]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_SEG_InsertObjectPublic]
GO

/****** Object:  StoredProcedure [dbo].[usp_AUTOCOMPLETE_SearchUsers]    Script Date: 05/12/2016 12:11:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	Get users for autocomplete
-- =============================================
CREATE PROCEDURE [dbo].[usp_AUTOCOMPLETE_SearchUsers]
	@varFilter AS VARCHAR(250)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	IF(@varFilter IS null)
		SELECT @varFilter = ''
	
	SELECT [userId]
		  ,[fullname]
		  ,[cellphone]
		  ,[address]
		  ,[phonenumber]
		  ,[phonearea]
		  ,[phonecode]
		  ,[username]
		  ,[email]
	FROM [dbo].[tbl_SEG_User] 
	WHERE [fullname] LIKE CASE @varFilter WHEN '' THEN [fullname] ELSE '%' + @varFilter + '%' END
	
END


GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_DeleteObjectPermissions]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 11/05/2016
-- Description:	Delete permissions for userName
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_DeleteObjectPermissions] 
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT,
	@varUserName AS VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;

    DELETE FROM [dbo].[tbl_SEG_ObjectPermissions] 
	WHERE [objectTypeID] = @varObjectTypeId
	AND [objectID] = @intObjectId 
	AND [username] = @varUserName
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_DeleteObjectPublic]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 11/05/2016
-- Description:	Delete permissions for userName
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_DeleteObjectPublic] 
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT
AS
BEGIN
	
	SET NOCOUNT ON;

    DELETE FROM [dbo].[tbl_SEG_ObjectPublic] 
	WHERE [objectTypeID] = @varObjectTypeId
	AND [objectID] = @intObjectId
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForActivity]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectActionsForActivity]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [objectActionID]
	FROM [dbo].[tbl_SEG_ObjectActions] 
	WHERE [objectActionID] IN ('OWN', 'MAN_KPI')
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForKPI]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectActionsForKPI]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [objectActionID]
	FROM [dbo].[tbl_SEG_ObjectActions] 
	WHERE [objectActionID] IN ('OWN', 'VIEW_KPI', 'ENTER_DATA')
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForOrganization]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectActionsForOrganization]
	@intOrganizationId AS INT
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [objectActionID]
	FROM [dbo].[tbl_SEG_ObjectActions] 
	WHERE [objectActionID] IN ('OWN', 'MAN_AREA', 'MAN_PROJECT', 'MAN_ACTIVITY', 'MAN_PEOPLE', 'MAN_KPI') 
	AND [objectActionID] NOT IN (SELECT [objectActionID] 
								 FROM [dbo].[tbl_SEG_ObjectPublic] 
								 WHERE [objectID] = @intOrganizationId 
								 AND [objectTypeID] = 'ORGANIZATION')
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForPeople]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectActionsForPeople]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [objectActionID]
	FROM [dbo].[tbl_SEG_ObjectActions] 
	WHERE [objectActionID] IN ('OWN', 'MAN_KPI')
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectActionsForProject]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectActionsForProject]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [objectActionID]
	FROM [dbo].[tbl_SEG_ObjectActions] 
	WHERE [objectActionID] IN ('OWN', 'MAN_ACTIVITY', 'MAN_KPI')
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectPermissionsByObject]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 06/05/2015
-- Description:	Get actions for the organization
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectPermissionsByObject]
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [op].[objectID]
		  ,[op].[objectTypeID]
		  ,[op].[objectActionID]
		  ,'' [username]
		  ,'' [fullname]
		  ,'' [email]
	FROM [dbo].[tbl_SEG_ObjectPublic] [op] 
	WHERE [op].[objectTypeID] = @varObjectTypeId 
	AND [op].[objectID] = @intObjectId
	
	UNION
	
	SELECT [op].[objectID]
		  ,[op].[objectTypeID]
		  ,[op].[objectActionID]
		  ,[op].[username]
		  ,[us].[fullname]
		  ,[us].[email]
	FROM [dbo].[tbl_SEG_ObjectPermissions] [op] 
	INNER JOIN [dbo].[tbl_SEG_User] [us] ON [op].[username] = [us].[username] 
	WHERE [op].[objectTypeID] = @varObjectTypeId 
	AND [op].[objectID] = @intObjectId
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_GetObjectPermissionsByUser]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marcela Martinez
-- Create date: 11/05/2016
-- Description:	Get objectPermissions by user
-- =============================================
CREATE PROCEDURE [dbo].[usp_SEG_GetObjectPermissionsByUser]
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT,
	@varUserName AS VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT [op].[objectID]
		  ,[op].[objectTypeID]
		  ,[op].[objectActionID]
		  ,[op].[username]
		  ,[us].[fullname]
		  ,[us].[email]
	FROM [dbo].[tbl_SEG_ObjectPermissions] [op] 
	INNER JOIN [dbo].[tbl_SEG_User] [us] ON [op].[username] = [us].[username] 
	WHERE [op].[objectTypeID] = @varObjectTypeId  
	AND [op].[objectID] = @intObjectId 
	AND [op].[username] = @varUserName
    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_InsertObjectPermissions]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================
-- Author:		Marcela Martinez
-- Create date: 11/05/2016
-- Description:	Insert objectActionList for userName
-- =================================================
CREATE PROCEDURE [dbo].[usp_SEG_InsertObjectPermissions] 
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT,
	@varUserName AS VARCHAR(50),
	@varObjectActionList AS VARCHAR(MAX) -- list of objectActionId separate by ;
AS
BEGIN
	
	SET NOCOUNT ON;
	
	-- We detect if the SP was called from an active transation and 
	-- we save it to use it later.  In the SP, @TranCounter = 0
	-- means that there are no active transations and that this SP
	-- started one. @TranCounter > 0 means that a transation was started
	-- before we started this SP
	DECLARE @TranCounter INT;
	SET @TranCounter = @@TRANCOUNT;
	IF @TranCounter > 0
		-- We called this SP when an active transaction already exists.
		-- We create a savepoint to be able to only roll back this 
		-- transaction if there is some error.
		SAVE TRANSACTION InsertObjectPermissionPS;     
	ELSE
		-- This SP starts its own transaction and there was no previous transaction
		BEGIN TRANSACTION;

	BEGIN TRY
		
		DELETE FROM [dbo].[tbl_SEG_ObjectPermissions] 
		WHERE [objectTypeID] = @varObjectTypeId
		AND [objectID] = @intObjectId 
		AND [username] = @varUserName
		
		
		INSERT INTO [dbo].[tbl_SEG_ObjectPermissions]
			   ([objectTypeID]
			   ,[objectID]
			   ,[username]
			   ,[objectActionID])
		SELECT @varObjectTypeId
			  ,@intObjectId
			  ,@varUserName
			  ,[oa].[objectActionID]
		FROM [dbo].[tbl_SEG_ObjectActions] [oa] 
		INNER JOIN [dbo].[tvf_SplitStringInTable] (@varObjectActionList,';') [d] ON [oa].[objectActionID] = [d].[splitvalue] 
	    
	    
	    -- We arrived here without errors; we should commit the transation we started
		-- but we should not commit if there was a previous transaction started
		IF @TranCounter = 0
			-- @TranCounter = 0 means that no other transaction was started before this transaction 
			-- and that we shouold hence commit this transaction
			COMMIT TRANSACTION;
		
	END TRY
	BEGIN CATCH

		-- There was an error.  We need to determine what type of rollback we must perform

		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT @ErrorMessage = ERROR_MESSAGE();
		SELECT @ErrorSeverity = ERROR_SEVERITY();
		SELECT @ErrorState = ERROR_STATE();

		IF @TranCounter = 0
			-- We have only the transaction that we started in this SP.  Rollback
			-- all the tranaction.
			ROLLBACK TRANSACTION;
		ELSE
			-- A transaction was started before this SP was called.  We must
			-- rollback only the changes we made in this SP.

			-- We see XACT_STATE and the possible results are 0, 1, or -1.
			-- If it is 1, the transaction is valid and we can do a commit. But since we are in the 
			-- CATCH we don't do the commit. We need to rollback to the savepoint
			-- If it is -1 the transaction is not valid and we must do a full rollback... we can't
			-- do a rollback to a savepoint
			-- XACT_STATE = 0 means that there is no transaciton and a rollback would cause an error
			-- See http://msdn.microsoft.com/en-us/library/ms189797(SQL.90).aspx
			IF XACT_STATE() = 1
				-- If the transaction is still valid then we rollback to the restore point defined before
				ROLLBACK TRANSACTION InsertObjectPermissionPS;

				-- If the transaction is not valid we cannot do a commit or a rollback to a savepoint
				-- because a rollback is not allowed. Hence, we must simply return to the caller and 
				-- they will be respnsible to rollback the transaction

				-- If there is no tranaction then there is nothing left to do

		-- After doing the correpsonding rollback, we must propagate the error information to the SP that called us 
		-- See http://msdn.microsoft.com/en-us/library/ms175976(SQL.90).aspx

		-- The database can return values from 0 to 256 but raise error
		-- will only allow us to use values from 1 to 127
		IF(@ErrorState < 1 OR @ErrorState > 127)
			SELECT @ErrorState = 1
			
		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH
	    
END

GO

/****** Object:  StoredProcedure [dbo].[usp_SEG_InsertObjectPublic]    Script Date: 05/12/2016 12:11:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================
-- Author:		Marcela Martinez
-- Create date: 11/05/2016
-- Description:	Insert objectActionList for everyone
-- =================================================
CREATE PROCEDURE [dbo].[usp_SEG_InsertObjectPublic] 
	@varObjectTypeId AS VARCHAR(20),
	@intObjectId AS INT,
	@varObjectActionList AS VARCHAR(MAX) -- list of objectActionId separate by ;
AS
BEGIN
	
	SET NOCOUNT ON;
	
	-- We detect if the SP was called from an active transation and 
	-- we save it to use it later.  In the SP, @TranCounter = 0
	-- means that there are no active transations and that this SP
	-- started one. @TranCounter > 0 means that a transation was started
	-- before we started this SP
	DECLARE @TranCounter INT;
	SET @TranCounter = @@TRANCOUNT;
	IF @TranCounter > 0
		-- We called this SP when an active transaction already exists.
		-- We create a savepoint to be able to only roll back this 
		-- transaction if there is some error.
		SAVE TRANSACTION InsertObjectPublicPS;     
	ELSE
		-- This SP starts its own transaction and there was no previous transaction
		BEGIN TRANSACTION;

	BEGIN TRY
		
		INSERT INTO [dbo].[tbl_SEG_ObjectPublic]
           ([objectTypeID]
           ,[objectID]
           ,[objectActionID])
		SELECT @varObjectTypeId
			  ,@intObjectId
			  ,[oa].[objectActionID]
		FROM [dbo].[tbl_SEG_ObjectActions] [oa] 
		INNER JOIN [dbo].[tvf_SplitStringInTable] (@varObjectActionList,';') [d] ON [oa].[objectActionID] = [d].[splitvalue] 
	    
	    
	    DELETE FROM [dbo].[tbl_SEG_ObjectPermissions] 
	    WHERE [objectTypeID] = @varObjectTypeId
		AND [objectID] = @intObjectId 
		AND [objectActionID] IN (SELECT [objectActionID] FROM [dbo].[tbl_SEG_ObjectPublic] 
								 WHERE [objectTypeID] = @varObjectTypeId
								 AND [objectID] = @intObjectId)
	    
	    
	    -- We arrived here without errors; we should commit the transation we started
		-- but we should not commit if there was a previous transaction started
		IF @TranCounter = 0
			-- @TranCounter = 0 means that no other transaction was started before this transaction 
			-- and that we shouold hence commit this transaction
			COMMIT TRANSACTION;
		
	END TRY
	BEGIN CATCH

		-- There was an error.  We need to determine what type of rollback we must perform

		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT @ErrorMessage = ERROR_MESSAGE();
		SELECT @ErrorSeverity = ERROR_SEVERITY();
		SELECT @ErrorState = ERROR_STATE();

		IF @TranCounter = 0
			-- We have only the transaction that we started in this SP.  Rollback
			-- all the tranaction.
			ROLLBACK TRANSACTION;
		ELSE
			-- A transaction was started before this SP was called.  We must
			-- rollback only the changes we made in this SP.

			-- We see XACT_STATE and the possible results are 0, 1, or -1.
			-- If it is 1, the transaction is valid and we can do a commit. But since we are in the 
			-- CATCH we don't do the commit. We need to rollback to the savepoint
			-- If it is -1 the transaction is not valid and we must do a full rollback... we can't
			-- do a rollback to a savepoint
			-- XACT_STATE = 0 means that there is no transaciton and a rollback would cause an error
			-- See http://msdn.microsoft.com/en-us/library/ms189797(SQL.90).aspx
			IF XACT_STATE() = 1
				-- If the transaction is still valid then we rollback to the restore point defined before
				ROLLBACK TRANSACTION InsertObjectPublicPS;

				-- If the transaction is not valid we cannot do a commit or a rollback to a savepoint
				-- because a rollback is not allowed. Hence, we must simply return to the caller and 
				-- they will be respnsible to rollback the transaction

				-- If there is no tranaction then there is nothing left to do

		-- After doing the correpsonding rollback, we must propagate the error information to the SP that called us 
		-- See http://msdn.microsoft.com/en-us/library/ms175976(SQL.90).aspx

		-- The database can return values from 0 to 256 but raise error
		-- will only allow us to use values from 1 to 127
		IF(@ErrorState < 1 OR @ErrorState > 127)
			SELECT @ErrorState = 1
			
		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
	END CATCH
	    
END

GO


--=============================================================================================================================

/*
 * We are done, mark the database as a 1.5.0 database.
 */

DELETE FROM [dbo].[tbl_DatabaseInfo] 
INSERT INTO [dbo].[tbl_DatabaseInfo] 
	([majorversion], [minorversion], [releaseversion])
	VALUES (1,5,0)
GO
