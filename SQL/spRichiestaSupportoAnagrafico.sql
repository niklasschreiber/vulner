CREATE  PROCEDURE [Application].[spRichiestaSupportoAnagrafico]
    @IdTenant                                        AS   INT,
	@UsernameRichiedente  		                     AS   NVARCHAR(20),
	@StatoCompatibileConSupportoAnagrafico           AS VARCHAR(50) =  'ConstatataIrreperibilitaAssoluta',
	@GuidList										 AS VARCHAR(MAX) =''
	AS

BEGIN
	DECLARE @GuidListSize	            AS INT;
	DECLARE @IdUtenteRichiedente	    AS BIGINT;
	DECLARE @IdStrutturaLogisticaRichiedente AS INT;
	DECLARE @ErrorString	    AS VARCHAR(MAX)='';
	DECLARE @ReturnTable AS TABLE(
			[OdlEsportati] INT NOT NULL,
			[IdFile] BIGINT NULL,
			[Filename] VARCHAR(MAX) NULL,
			[IsSucceded] BIT NOT NULL DEFAULT 1,
			[ErrorMessage] VARCHAR(MAX) NULL
            );
	DECLARE @IndividualOdl VARCHAR(50);
    DECLARE @OdlTable AS TABLE(
			[IdOdl] UNIQUEIDENTIFIER NOT NULL
     );

	 -- split "|" della lista di guid
	WHILE LEN(@GuidList) > 0
	BEGIN
		IF PATINDEX('%|%', @GuidList) > 0
		BEGIN
			SET @IndividualOdl = SUBSTRING(@GuidList,
										0,
										PATINDEX('%|%', @GuidList))
			INSERT INTO @OdlTable (IdOdl) VALUES( CONVERT(Uniqueidentifier,@IndividualOdl))

			SET @GuidList = SUBSTRING(@GuidList,
									  LEN(@IndividualOdl + '|') + 1,
									  LEN(@GuidList))
		END
		ELSE
		BEGIN
			SET @IndividualOdl = @GuidList
			SET @GuidList = NULL
			INSERT INTO @OdlTable (IdOdl) VALUES( @IndividualOdl)
		END
    END
	SELECT TOP (1) @GuidListSize=Count(*) FROM @OdlTable




	--Check Input Section
	IF(@IdTenant IS NULL) BEGIN
		SET @ErrorString= 'IdTenant non valorizzato;';
	END
	IF(@UsernameRichiedente IS NULL OR @UsernameRichiedente ='') BEGIN
		SET @ErrorString= @ErrorString + 'Username richiedente non valorizzato;';
	END
    IF(@StatoCompatibileConSupportoAnagrafico IS NULL OR @StatoCompatibileConSupportoAnagrafico ='') BEGIN
		SET @ErrorString=@ErrorString+ 'StatoCompatibileConSupportoAnagrafico non valorizzato;';
	END


	--Retrieve UserId
	SELECT TOP (1) @IdUtenteRichiedente=U.IdUtente, @IdStrutturaLogisticaRichiedente=U.IdStrutturaLogistica FROM [Profiling].[Utenti] U  WITH (NOLOCK)
	 WHERE U.UserName=@UsernameRichiedente


	IF(@IdUtenteRichiedente IS NULL) BEGIN
		SET @ErrorString=@ErrorString+ 'Username richiedente non riconosciuto dal sistema;';
	END

	IF(@IdStrutturaLogisticaRichiedente IS NULL) BEGIN
		SET @ErrorString=@ErrorString+ 'La struttura logistica non esiste;';
	END


	IF(@ErrorString <> '') 
	BEGIN
		INSERT INTO @ReturnTable ([OdlEsportati],[IsSucceded],[ErrorMessage]) VALUES(0,0,@ErrorString);
		SELECT * FROM @ReturnTable
		RETURN;
	
	END

	DECLARE @IdOdl													AS UNIQUEIDENTIFIER=NULL;
	DECLARE @IdEvento												AS UNIQUEIDENTIFIER=NULL;
	DECLARE @OdlCount												AS INT=0;
	DECLARE @TransactionName										AS VARCHAR(50) = 'RichiestaSupportoAnagrafico';
	DECLARE @InsertedId												AS BIGINT;
	DECLARE @Filename												AS VARCHAR(MAX);
	DECLARE @Inserted												AS TABLE (IdFile BIGINT);
	DECLARE @IsFileEsportatiInserted								AS BIT = 0;
	DECLARE @CodiceAmbito											AS VARCHAR(50);
	DECLARE @ProgressivoFile										AS VARCHAR(2);
    DECLARE @CurrentISODate											AS VARCHAR(8);
	DECLARE @CodiceAtto												AS VARCHAR(20);
	DECLARE @IdCommessa												AS VARCHAR(10);
    DECLARE @CodiceFiscale											AS CHAR(16);
	DECLARE @PartitaIva												AS VARCHAR(13);
	DECLARE @FlagStatoLavorazione_RichiestaSupportoEffettuata		AS TINYINT = 0x00;
	DECLARE @FlagStatoLavorazione_EsitoCaricato						AS TINYINT = 0x01;
	DECLARE @FlagStatoLavorazione_EsitoApplicato					AS TINYINT = 0x02;
	DECLARE @FlagStatoLavorazione_ApplicazioneEsitoFallita			AS TINYINT = 0x03;
	DECLARE @FlagStatoLavorazione_RichiestaSupportoFallita			AS TINYINT = 0x04;
	DECLARE @FlagStatoLavorazione_Inizializzato						AS TINYINT = 0x05;
	DECLARE @FlagStatoLavorazione_RichiestaSovrascritta				AS TINYINT = 0x06;
	DECLARE @result_lock											AS INT;
	DECLARE @LockResourceString										AS VARCHAR = CAST(@IdTenant AS VARCHAR(10));
   
    
	 DECLARE CursorOdl CURSOR FOR
		 SELECT O.IdOdl AS IdOdl, O.CodiceAmbito AS CodiceAmbito, O.CodiceAtto AS CodiceAtto, O.IdCommessa AS IdCommessa, O.CodiceFiscale AS CodiceFiscale, O.PartitaIva AS PartitaIva , OSS.IdEvento AS IdEvento
		 FROM [Messo].[Odl] O WITH (NOLOCK) LEFT JOIN [Messo].[OdlStoricoStati] OSS WITH (NOLOCK) ON O.IdOdl=OSS.IdOdl
		 WHERE OSS.StatoCorrente=1 AND O.[IdTenant]=@IdTenant
		 AND ( @GuidListSize=0 OR O.[IdOdl] IN (SELECT IdOdl FROM @OdlTable))
		 AND O.[Stato]=@StatoCompatibileConSupportoAnagrafico AND (O.[NumeroTentativiNotifica]=1 OR O.[NumeroTentativiNotifica]=2)
		 AND NOT EXISTS (
			SELECT SUB.[IdOdl] FROM [Data].[SupportoAnagraficoAttiEsportati] SUB  WITH (NOLOCK)
			WHERE SUB.[IdOdl] = O.[IdOdl] AND 
			(	SUB.[FlagStatoLavorazione] <>  @FlagStatoLavorazione_EsitoApplicato 
			AND 
				SUB.[FlagStatoLavorazione] <>  @FlagStatoLavorazione_RichiestaSupportoFallita
			AND 
                SUB.[FlagStatoLavorazione] <>  @FlagStatoLavorazione_RichiestaSovrascritta

			)
		 )
		 AND O.CentroDiDistribuzione IN
			(
				SELECT DISTINCT F.CodiceFrazionario
				FROM Logistic.Frazionari F INNER JOIN Logistic.StruttureLogistiche S WITH(NOLOCK) ON F.Id=S.Id
				INNER JOIN Logistic.TipoStruttura TS WITH (NOLOCK) ON S.TipoStruttura=TS.Id
							 ,
					(
						-- Cd messo di un tenant
						SELECT SLT.IdStrutturaLogistica From Logistic.Frazionari F WITH (NOLOCK) 
						INNER JOIN Logistic.StruttureLogisticheTenants SLT WITH (NOLOCK)	ON F.Id=SLT.IdStrutturaLogistica
						INNER JOIN Logistic.StruttureLogistiche SL WITH (NOLOCK) ON SLT.IdStrutturaLogistica = SL.Id
						INNER JOIN Logistic.TipoStruttura TS WITH (NOLOCK) ON SL.TipoStruttura=TS.Id

						WHERE  SLT.IdTenant=@IdTenant AND TS.Descrizione='CD'

						) CDMessoTable
	
					WHERE S.Id= CDMessoTable.IdStrutturaLogistica
					OR (S.CDMesso=CDMessoTable.IdStrutturaLogistica AND TS.Descrizione IN ('CPD','CDM','CSD','PDD'))
			);

  	BEGIN TRANSACTION @TransactionName
	BEGIN TRY
	EXEC @result_lock = sp_getapplock @Resource = @LockResourceString, @LockMode = 'Exclusive', @LockOwner='Transaction',@LockTimeout=5000; 
	IF @result_lock = -3  
	BEGIN  
		ROLLBACK TRANSACTION @TransactionName; 
		SET @ErrorString= 'Richiesta Supporto Anagrafico fallita a causa di altri accessi concorrenti'
		INSERT INTO @ReturnTable ([OdlEsportati],[IsSucceded],[ErrorMessage]) VALUES(0,0,@ErrorString);
		SELECT * FROM @ReturnTable
		RETURN;  
	END
	
	
	  
	SET @CurrentISODate = FORMAT(getdate(),'yyyyMMdd')

	 OPEN CursorOdl

	 FETCH Next FROM CursorOdl INTO @IdOdl, @CodiceAmbito, @CodiceAtto,@IdCommessa,@CodiceFiscale,@PartitaIva,@IdEvento

	 WHILE @@FETCH_STATUS = 0 BEGIN
			SET @OdlCount=@OdlCount+1;
			                    
						 
						 IF ( @IsFileEsportatiInserted =0 )BEGIN
				
							 SELECT 
								@ProgressivoFile= format (Count(*)+1 , '0#') FROM [Data].[SupportoAnagraficoFileEsportati] AS S  WITH (NOLOCK)
							 WHERE 
								S.[IdTenant]=@IdTenant AND S.[IdStrutturaLogisticaRichiedente]=@IdStrutturaLogisticaRichiedente 				 
								AND FORMAT(S.[DataEsportazione],'yyyyMMdd') = @CurrentISODate
							 SET @Filename = CONCAT('SCA_',@CodiceAmbito,'_',@CurrentISODate,'_',@ProgressivoFile,'.txt');

							 INSERT INTO [Data].[SupportoAnagraficoFileEsportati](IdStrutturaLogisticaRichiedente,IdTenant,IdUtenteRichiedente,NomeFile)
							 OUTPUT Inserted.IdFile INTO @Inserted
							 VALUES(@IdStrutturaLogisticaRichiedente,@IdTenant,@IdUtenteRichiedente,@Filename);

							 SELECT TOP (1) @InsertedId = I.IdFile FROM @Inserted AS I
							 SET @IsFileEsportatiInserted = 1;
						END
						 -- Le richieste di supporto anagrafico pre-esistenti vanno sovrascritte
						UPDATE 
						    [Data].[SupportoAnagraficoAttiEsportati]
						SET 
							FlagStatoLavorazione=@FlagStatoLavorazione_RichiestaSovrascritta
						WHERE 
						     IdOdl=@IdOdl

							-- inserimento della richiesta supporto anagrafico corrente
						 INSERT INTO 
								[Data].[SupportoAnagraficoAttiEsportati] (IdFileEsportato,IdOdl,IdTenant,CodiceAmbito,CodiceAtto,IdCommessa,CodiceFiscale,PartitaIva,FlagStatoLavorazione,IdEventoMN8)
						 VALUES   
						        (@InsertedId,@IdOdl,@IdTenant,@CodiceAmbito,@CodiceAtto,@IdCommessa,@CodiceFiscale,@PartitaIva,@FlagStatoLavorazione_Inizializzato,@IdEvento) 
			       

	 FETCH Next FROM CursorOdl INTO @IdOdl, @CodiceAmbito, @CodiceAtto,@IdCommessa,@CodiceFiscale,@PartitaIva,@IdEvento
	 
	 END

	 CLOSE CursorOdl
	 DEALLOCATE CursorOdl
	
	COMMIT TRANSACTION @TransactionName

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION @TransactionName
		SET @ErrorString= ERROR_MESSAGE()
		INSERT INTO @ReturnTable ([OdlEsportati],[IsSucceded],[ErrorMessage]) VALUES(0,0,@ErrorString);
		SELECT * FROM @ReturnTable
		RETURN;
	END CATCH;


	INSERT INTO @ReturnTable ([OdlEsportati],[Filename],[IdFile]) VALUES(@OdlCount,@Filename,@InsertedId);
    SELECT * FROM @ReturnTable

END

GO


