
CREATE FUNCTION [Data].[GetRendicontazioniByOdl]
(@IdOdl AS UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
     RETURN
(
    SELECT rendatto.Id,
           rendatto.DataAttivita,
           rendatto.CodiceAttivita,
           codatt.Descrizione AS DescrizioneAttivita,
           rendatto.DataDeposito,
           rendatto.DataAffissione,
           rendatto.DataRitiroCasaComunale,
           NULL AS DataInvio139140,
           NULL AS CodiceRaccomandata139140,
           Data.GetMessoStatoFinale(@IdOdl, storico.Stato, tteventinotifica.MSID) AS CodiceMesso,
           Data.GetStatoFunzionale(storico.Stato, storico.NumeroTentativiNotifica) AS Stato,
           rend.DataInvio AS DataStato,
           rendatto.TentativoNotifica AS TentativoNotifica,
           rendatto.CentroLavorazione AS CentroLavorazione
    FROM [RendicontazioneMilano].RendicontazioneAtto rendatto
         JOIN [RendicontazioneMilano].Rendicontazione rend ON rendatto.IdRendicontazione = rend.Id
         LEFT JOIN Rendicontazione.CodiceAttivita codatt ON(rendatto.CodiceAttivita = codatt.Codice
                                                            AND rend.IdTenant = codatt.IdTenant)
         LEFT JOIN Messo.OdlStoricoStati storico ON rendatto.IdStato = storico.ID
         LEFT JOIN Messo.TTEventiNotifica tteventinotifica ON storico.IdEvento = tteventinotifica.IdEvento
    WHERE rendatto.IdOdl = @IdOdl
);