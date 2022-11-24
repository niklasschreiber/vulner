UPDATE TBL_MAIL_CONFIG SET MESSAGE = 'Gentile [NOME] [COGNOME],<br/>ti informiamo che a causa di un problema tecnico non si &egrave; potuto dar seguito alla richiesta di emissione del Buono [BUONO] e di apertura del Libretto Smart effettuata in data [DATA_APERTURA] alle ore [ORA_APERTURA] ( Pratica n.[ID_PRATICA]).<br/>Ci scusiamo per il disguido e ti invitiamo a <a href="https://svm-rpol1.svil.poste.it/rpol/private/pages/acquisto-buono-e-libretto.html">ripetere la richiesta</a>.'
WHERE
LAYER_ID = 1 AND
(MOVEMENT_TYPE_ID, MOVEMENT_SUBTYPE_ID) IN (SELECT MOVEMENT_TYPE_ID, MOVEMENT_SUBTYPE_ID FROM TBL_TEMPLATE WHERE 
												TEMPLATE_ID = 'RICH_BUON_LIBR_SMART_KO_MAIL_4' AND
                                                LAYER_ID = 1);
												
COMMIT;