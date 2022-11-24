package it.poste.oracolo.business;

import java.io.IOException;
import java.io.ObjectOutputStream;
import java.sql.Timestamp;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

public class Nservice implements java.io.Serializable {
	private static final long serialVersionUID = 1L;
	
	private Long idNservice;   									// Service
	private String fkUfficiopostale;							// Service
	private Ufficiopostale ufficiopostale;						// Service
	private String indIpalert;									// Alert
	private String nomeOperatoresportello;						// Alert
	private String nomeServizioChiamante;						// DatiContestoOra4DTO
	//private String nomeFaseSdp;									// DatiContestoOra4DTO
	private String idSessioneCarrelloSdp;						// DatiContestoOra4DTO
	private Date dataContabile;									// DatiContestoOra4DTO
	private String pdl;											// DatiContestoOra4DTO
	private Timestamp dataIns;										// Service
	private Integer fkTipoprodotto;								// Service
	private Tipoprodotto tipoprodotto;							// Service
	private Integer fkOperazione;								// ServiceDTO
	private TipoOperazioneOraService tipoOperazioneOraService;	// ServiceDTO
	private String numDocumento;								// Service
	private Integer fkTipodocumento;							// Service
	private Tipodocumento tipodocumento;						// Service
	private Long fkDocumento;									// Service
	private Documento documento;								// Service
	private String fkCodicefiscale;								// Service
	private Codicefiscale codicefiscale;						// Service
	private String fkNazione;									// Service
	private Nazione nazione;									// Service
	private String sdpNome;										// DatiIdentificativiClienteOra4DTO
	private String sdpCognome;									// DatiIdentificativiClienteOra4DTO
	private String sdpSesso;									// DatiIdentificativiClienteOra4DTO
	private Date sdpDatanascita;								// DatiIdentificativiClienteOra4DTO
	private String sdpLuogonascita;								// DatiIdentificativiClienteOra4DTO
	private String sdpIndirizzo;								// DatiIdentificativiClienteOra4DTO
	private String sdpCitta;									// DatiIdentificativiClienteOra4DTO
	private String sdpPaese;									// DatiIdentificativiClienteOra4DTO
	private String sdpCap;										// DatiIdentificativiClienteOra4DTO
	private Integer fkStatoattuale;								// AlertDTO
	private Stato stato;										// Alert
	private Integer fkEsito;										// AlertDTO
	private Esito esito;										// Alert
	private Integer valRiskscore;								// Alert
	private Integer fkRischiofrode;								// Alert
	private Rischiofrode rischiofrode;
	private String fkUtenteassegnatario;						// AlertDTO
	private Utente utente;										// Alert
	private Date dataValutazione;								// Caso
	private Double impFrodato;									// Alert
	private Double impPotenzialmfrodato;						// Alert
	private Double impSventato;									// Alert
	private String fkUtenteagg;									// Ufficio Postale
	private Utente utenteagg;									// Alert
	private Date dataAgg;										// Ufficio Postale
	private String sEsitocodicefiscale;							// Service
	private String sDatadecesso;								// Service
	private String sStatoserviziosogei;							// Service
//	private String sResponse;									// Service
	private String mEsitodocumento;								// Service
	private String mStatoservizioministero;						// Service
//	private String mResponse;									// Service
	private String bStatoservizioblacklist;						// Service
	private Short bEsitoblacklistcf;							// Service
	private Short bEsitoblacklistdoc;							// Service
	private Short bEsitogreylistcf;								// Service
	private Short bEsitogreylistdoc;							// Service
	private Short fkEsitocodicefiscale;							// Service
	private Short fkEsitodocumento;								// Service
	private String esecuzRegoleCasemanager;					
	private Integer tempoRispSogeiMs;
	private Integer tempoRispMinisteroMs;
	private Long fkTipointerrMinistero = Long.valueOf(0);		// Service
	private List<String> elencoServizi;							// ParamInvocazioneServiziOra4DTO
	
	private Set<Allegato> allegatos = new HashSet<Allegato>(0);
	private Set<Eventocaso> eventocasos = new HashSet<Eventocaso>(0);
	private Set<Esitoregola> esitoregolas = new HashSet<Esitoregola>(0);
	private Set<Annotazione> annotaziones = new HashSet<Annotazione>(0);
	private Set<Correlazione> correlazionesForFkAlertcorrelato = new HashSet<Correlazione>(0);

	private Set<Nservice> listaService = new HashSet<Nservice>(0);
	
	private String primafase;
	private String controdenuncia;
	private Integer progChiamata;
	private Long fkAzione;
	private String sdpEnteDocumento;
	private Timestamp sdpRilascioDocumento;
	private Timestamp sdpScadenzaDocumento;
	private String sdpNazionalita;
	private String sdpCassa;
	private Long sdpPrgOperazione;
	private Integer numeroFasiCarrello;
	private String idorac;
	
	private void writeObject(ObjectOutputStream out)
	         throws IOException, ClassNotFoundException {
	         out.defaultWriteObject();
	}

	
	public Set<Nservice> getListaService() {
		return listaService;
	}


	public void setListaService(Set<Nservice> listaService) {
		this.listaService = listaService;
	}


	public Nservice() {
		super();
	}


	public Long getIdNservice() {
		return idNservice;
	}


	public void setIdNservice(Long idNservice) {
		this.idNservice = idNservice;
	}


	public String getFkUfficiopostale() {
		return fkUfficiopostale;
	}


	public void setFkUfficiopostale(String fkUfficiopostale) {
		this.fkUfficiopostale = fkUfficiopostale;
	}


	public Ufficiopostale getUfficiopostale() {
		return ufficiopostale;
	}


	public void setUfficiopostale(Ufficiopostale ufficiopostale) {
		this.ufficiopostale = ufficiopostale;
	}


	public String getIndIpalert() {
		return indIpalert;
	}


	public void setIndIpalert(String indIpalert) {
		this.indIpalert = indIpalert;
	}


	public String getNomeOperatoresportello() {
		return nomeOperatoresportello;
	}


	public void setNomeOperatoresportello(String nomeOperatoresportello) {
		this.nomeOperatoresportello = nomeOperatoresportello;
	}


	public String getNomeServizioChiamante() {
		return nomeServizioChiamante;
	}


	public void setNomeServizioChiamante(String nomeServizioChiamante) {
		this.nomeServizioChiamante = nomeServizioChiamante;
	}


	/*public String getNomeFaseSdp() {
		return nomeFaseSdp;
	}


	public void setNomeFaseSdp(String nomeFaseSdp) {
		this.nomeFaseSdp = nomeFaseSdp;
	}*/


	public String getIdSessioneCarrelloSdp() {
		return idSessioneCarrelloSdp;
	}


	public void setIdSessioneCarrelloSdp(String idSessioneCarrelloSdp) {
		this.idSessioneCarrelloSdp = idSessioneCarrelloSdp;
	}


	public Date getDataContabile() {
		return dataContabile;
	}


	public void setDataContabile(Date dataContabile) {
		this.dataContabile = dataContabile;
	}


	public String getPdl() {
		return pdl;
	}


	public void setPdl(String pdl) {
		this.pdl = pdl;
	}


	public Timestamp getDataIns() {
		return dataIns;
	}


	public void setDataIns(Timestamp dataIns) {
		this.dataIns = dataIns;
	}


	public Integer getFkTipoprodotto() {
		return fkTipoprodotto;
	}


	public void setFkTipoprodotto(Integer fkTipoprodotto) {
		this.fkTipoprodotto = fkTipoprodotto;
	}


	public Tipoprodotto getTipoprodotto() {
		return tipoprodotto;
	}


	public void setTipoprodotto(Tipoprodotto tipoprodotto) {
		this.tipoprodotto = tipoprodotto;
	}

	public Integer getFkOperazione() {
		return fkOperazione;
	}


	public void setFkOperazione(Integer fkOperazione) {
		this.fkOperazione = fkOperazione;
	}


	public TipoOperazioneOraService getTipoOperazioneOraService() {
		return tipoOperazioneOraService;
	}


	public void setTipoOperazioneOraService(
			TipoOperazioneOraService tipoOperazioneOraService) {
		this.tipoOperazioneOraService = tipoOperazioneOraService;
	}


	public String getNumDocumento() {
		return numDocumento;
	}


	public void setNumDocumento(String numDocumento) {
		this.numDocumento = numDocumento;
	}


	public Integer getFkTipodocumento() {
		return fkTipodocumento;
	}


	public void setFkTipodocumento(Integer fkTipodocumento) {
		this.fkTipodocumento = fkTipodocumento;
	}


	public Tipodocumento getTipodocumento() {
		return tipodocumento;
	}


	public void setTipodocumento(Tipodocumento tipodocumento) {
		this.tipodocumento = tipodocumento;
	}


	public Long getFkDocumento() {
		return fkDocumento;
	}


	public void setFkDocumento(Long fkDocumento) {
		this.fkDocumento = fkDocumento;
	}


	public Documento getDocumento() {
		return documento;
	}


	public void setDocumento(Documento documento) {
		this.documento = documento;
	}


	public String getFkCodicefiscale() {
		return fkCodicefiscale;
	}


	public void setFkCodicefiscale(String fkCodicefiscale) {
		this.fkCodicefiscale = fkCodicefiscale;
	}


	public Codicefiscale getCodicefiscale() {
		return codicefiscale;
	}


	public void setCodicefiscale(Codicefiscale codicefiscale) {
		this.codicefiscale = codicefiscale;
	}


	public String getFkNazione() {
		return fkNazione;
	}


	public void setFkNazione(String fkNazione) {
		this.fkNazione = fkNazione;
	}


	public Nazione getNazione() {
		return nazione;
	}


	public void setNazione(Nazione nazione) {
		this.nazione = nazione;
	}


	public String getSdpNome() {
		return sdpNome;
	}


	public void setSdpNome(String sdpNome) {
		this.sdpNome = sdpNome;
	}


	public String getSdpCognome() {
		return sdpCognome;
	}


	public void setSdpCognome(String sdpCognome) {
		this.sdpCognome = sdpCognome;
	}


	public String getSdpSesso() {
		return sdpSesso;
	}


	public void setSdpSesso(String sdpSesso) {
		this.sdpSesso = sdpSesso;
	}


	public Date getSdpDatanascita() {
		return sdpDatanascita;
	}


	public void setSdpDatanascita(Date sdpDatanascita) {
		this.sdpDatanascita = sdpDatanascita;
	}


	public String getSdpLuogonascita() {
		return sdpLuogonascita;
	}


	public void setSdpLuogonascita(String sdpLuogonascita) {
		this.sdpLuogonascita = sdpLuogonascita;
	}


	public String getSdpIndirizzo() {
		return sdpIndirizzo;
	}


	public void setSdpIndirizzo(String sdpIndirizzo) {
		this.sdpIndirizzo = sdpIndirizzo;
	}


	public String getSdpCitta() {
		return sdpCitta;
	}


	public void setSdpCitta(String sdpCitta) {
		this.sdpCitta = sdpCitta;
	}


	public String getSdpPaese() {
		return sdpPaese;
	}


	public void setSdpPaese(String sdpPaese) {
		this.sdpPaese = sdpPaese;
	}


	public String getSdpCap() {
		return sdpCap;
	}


	public void setSdpCap(String sdpCap) {
		this.sdpCap = sdpCap;
	}


	public Stato getStato() {
		return stato;
	}


	public void setStato(Stato stato) {
		this.stato = stato;
	}


	public Integer getFkStatoattuale() {
		return fkStatoattuale;
	}


	public void setFkStatoattuale(Integer fkStatoattuale) {
		this.fkStatoattuale = fkStatoattuale;
	}


	public Integer getFkEsito() {
		return fkEsito;
	}


	public void setFkEsito(Integer fkEsito) {
		this.fkEsito = fkEsito;
	}


	public Esito getEsito() {
		return esito;
	}


	public void setEsito(Esito esito) {
		this.esito = esito;
	}


	public Integer getValRiskscore() {
		return valRiskscore;
	}


	public void setValRiskscore(Integer valRiskscore) {
		this.valRiskscore = valRiskscore;
	}


	public Integer getFkRischiofrode() {
		return fkRischiofrode;
	}


	public void setFkRischiofrode(Integer fkRischiofrode) {
		this.fkRischiofrode = fkRischiofrode;
	}


	public Rischiofrode getRischiofrode() {
		return rischiofrode;
	}


	public void setRischiofrode(Rischiofrode rischiofrode) {
		this.rischiofrode = rischiofrode;
	}


	public String getFkUtenteassegnatario() {
		return fkUtenteassegnatario;
	}


	public void setFkUtenteassegnatario(String fkUtenteassegnatario) {
		this.fkUtenteassegnatario = fkUtenteassegnatario;
	}


	public Utente getUtente() {
		return utente;
	}


	public void setUtente(Utente utente) {
		this.utente = utente;
	}


	public Date getDataValutazione() {
		return dataValutazione;
	}


	public void setDataValutazione(Date dataValutazione) {
		this.dataValutazione = dataValutazione;
	}


	public Double getImpFrodato() {
		return impFrodato;
	}


	public void setImpFrodato(Double impFrodato) {
		this.impFrodato = impFrodato;
	}


	public Double getImpPotenzialmfrodato() {
		return impPotenzialmfrodato;
	}


	public void setImpPotenzialmfrodato(Double impPotenzialmfrodato) {
		this.impPotenzialmfrodato = impPotenzialmfrodato;
	}


	public Double getImpSventato() {
		return impSventato;
	}


	public void setImpSventato(Double impSventato) {
		this.impSventato = impSventato;
	}


	public String getFkUtenteagg() {
		return fkUtenteagg;
	}


	public void setFkUtenteagg(String fkUtenteagg) {
		this.fkUtenteagg = fkUtenteagg;
	}


	public Utente getUtenteagg() {
		return utenteagg;
	}


	public void setUtenteagg(Utente utenteagg) {
		this.utenteagg = utenteagg;
	}


	public Date getDataAgg() {
		return dataAgg;
	}


	public void setDataAgg(Date dataAgg) {
		this.dataAgg = dataAgg;
	}


	public String getsEsitocodicefiscale() {
		return sEsitocodicefiscale;
	}


	public void setsEsitocodicefiscale(String sEsitocodicefiscale) {
		this.sEsitocodicefiscale = sEsitocodicefiscale;
	}


	public String getsDatadecesso() {
		return sDatadecesso;
	}


	public void setsDatadecesso(String sDatadecesso) {
		this.sDatadecesso = sDatadecesso;
	}


	public String getsStatoserviziosogei() {
		return sStatoserviziosogei;
	}


	public void setsStatoserviziosogei(String sStatoserviziosogei) {
		this.sStatoserviziosogei = sStatoserviziosogei;
	}


//	public String getsResponse() {
//		return sResponse;
//	}


//	public void setsResponse(String sResponse) {
//		this.sResponse = sResponse;
//	}


	public String getmEsitodocumento() {
		return mEsitodocumento;
	}


	public void setmEsitodocumento(String mEsitodocumento) {
		this.mEsitodocumento = mEsitodocumento;
	}


	public String getmStatoservizioministero() {
		return mStatoservizioministero;
	}


	public void setmStatoservizioministero(String mStatoservizioministero) {
		this.mStatoservizioministero = mStatoservizioministero;
	}


//	public String getmResponse() {
//		return mResponse;
//	}


//	public void setmResponse(String mResponse) {
//		this.mResponse = mResponse;
//	}


	public String getbStatoservizioblacklist() {
		return bStatoservizioblacklist;
	}


	public void setbStatoservizioblacklist(String bStatoservizioblacklist) {
		this.bStatoservizioblacklist = bStatoservizioblacklist;
	}


	public Short getbEsitoblacklistcf() {
		return bEsitoblacklistcf;
	}


	public void setbEsitoblacklistcf(Short bEsitoblacklistcf) {
		this.bEsitoblacklistcf = bEsitoblacklistcf;
	}


	public Short getbEsitoblacklistdoc() {
		return bEsitoblacklistdoc;
	}


	public void setbEsitoblacklistdoc(Short bEsitoblacklistdoc) {
		this.bEsitoblacklistdoc = bEsitoblacklistdoc;
	}


	public Short getbEsitogreylistcf() {
		return bEsitogreylistcf;
	}


	public void setbEsitogreylistcf(Short bEsitogreylistcf) {
		this.bEsitogreylistcf = bEsitogreylistcf;
	}


	public Short getbEsitogreylistdoc() {
		return bEsitogreylistdoc;
	}


	public void setbEsitogreylistdoc(Short bEsitogreylistdoc) {
		this.bEsitogreylistdoc = bEsitogreylistdoc;
	}


	public Short getFkEsitocodicefiscale() {
		return fkEsitocodicefiscale;
	}


	public void setFkEsitocodicefiscale(Short fkEsitocodicefiscale) {
		this.fkEsitocodicefiscale = fkEsitocodicefiscale;
	}


	public Short getFkEsitodocumento() {
		return fkEsitodocumento;
	}


	public void setFkEsitodocumento(Short fkEsitodocumento) {
		this.fkEsitodocumento = fkEsitodocumento;
	}


	public String getEsecuzRegoleCasemanager() {
		return esecuzRegoleCasemanager;
	}


	public void setEsecuzRegoleCasemanager(String esecuzRegoleCasemanager) {
		this.esecuzRegoleCasemanager = esecuzRegoleCasemanager;
	}


	public Integer getTempoRispSogeiMs() {
		return tempoRispSogeiMs;
	}


	public void setTempoRispSogeiMs(Integer tempoRispSogeiMs) {
		this.tempoRispSogeiMs = tempoRispSogeiMs;
	}


	public Integer getTempoRispMinisteroMs() {
		return tempoRispMinisteroMs;
	}


	public void setTempoRispMinisteroMs(Integer tempoRispMinisteroMs) {
		this.tempoRispMinisteroMs = tempoRispMinisteroMs;
	}


	public Long getFkTipointerrMinistero() {
		return fkTipointerrMinistero;
	}


	public void setFkTipointerrMinistero(Long fkTipointerrMinistero) {
		this.fkTipointerrMinistero = fkTipointerrMinistero;
	}


	public List<String> getElencoServizi() {
		return elencoServizi;
	}


	public void setElencoServizi(List<String> elencoServizi) {
		this.elencoServizi = elencoServizi;
	}


	public Set<Allegato> getAllegatos() {
		return allegatos;
	}


	public void setAllegatos(Set<Allegato> allegatos) {
		this.allegatos = allegatos;
	}


	public Set<Eventocaso> getEventocasos() {
		return eventocasos;
	}


	public void setEventocasos(Set<Eventocaso> eventocasos) {
		this.eventocasos = eventocasos;
	}


	public Set<Esitoregola> getEsitoregolas() {
		return esitoregolas;
	}


	public void setEsitoregolas(Set<Esitoregola> esitoregolas) {
		this.esitoregolas = esitoregolas;
	}


	public Set<Annotazione> getAnnotaziones() {
		return annotaziones;
	}


	public void setAnnotaziones(Set<Annotazione> annotaziones) {
		this.annotaziones = annotaziones;
	}


	public Set<Correlazione> getCorrelazionesForFkAlertcorrelato() {
		return correlazionesForFkAlertcorrelato;
	}


	public void setCorrelazionesForFkAlertcorrelato(
			Set<Correlazione> correlazionesForFkAlertcorrelato) {
		this.correlazionesForFkAlertcorrelato = correlazionesForFkAlertcorrelato;
	}

	 public synchronized Correlazione addCorrelazione(Nservice alert, String alertCorrelati, Caso caso, String casiCorrelati ) {
	    	Correlazione obj = new Correlazione( alert, alertCorrelati, caso, casiCorrelati );

	        Set<Correlazione> s = this.correlazionesForFkAlertcorrelato != null ? this.correlazionesForFkAlertcorrelato
	                                                  : new HashSet<Correlazione>();
	        s.add( obj );
	        this.correlazionesForFkAlertcorrelato = s;		        
	        return obj;
	    }

	 /**
		 * Create an association between an {@link Esitoregola} and this Alert.
		 * 
		 * @see Esitoregola#(Alert, String, Integer, String)
		 */
	    public synchronized Esitoregola aggiungiEsitoRegola( String  desc, Integer rank, String code ) {
	    	Esitoregola obj = new Esitoregola( this, code, rank, desc );

	        Set<Esitoregola> s = this.esitoregolas != null ? this.esitoregolas
	                                                  : new HashSet<Esitoregola>();
	        s.add( obj );
	        this.esitoregolas = s;		        
	        return obj;
	    }


	public String getPrimafase() {
		return primafase;
	}


	public void setPrimafase(String primaFase) {
		this.primafase = primaFase;
	}
	
	public Set<String> listanumdoc(){
		Set<Nservice> lista=this.listaService;
		Iterator<Nservice> iteratore= lista.iterator();

		Set<String> listaNumDoc=new HashSet<String>();

		while(iteratore.hasNext())
			listaNumDoc.add(iteratore.next().getNumDocumento());

		return listaNumDoc;
	}


	public String getControdenuncia() {
		return controdenuncia;
	}


	public void setControdenuncia(String controdenuncia) {
		this.controdenuncia = controdenuncia;
	}


	public Integer getProgChiamata() {
		return progChiamata;
	}


	public void setProgChiamata(Integer progChiamata) {
		this.progChiamata = progChiamata;
	}


	public Long getFkAzione() {
		return fkAzione;
	}


	public void setFkAzione(Long fkAzione) {
		this.fkAzione = fkAzione;
	}


	public String getSdpEnteDocumento() {
		return sdpEnteDocumento;
	}


	public void setSdpEnteDocumento(String sdpEnteDocumento) {
		this.sdpEnteDocumento = sdpEnteDocumento;
	}


	public Timestamp getSdpRilascioDocumento() {
		return sdpRilascioDocumento;
	}


	public void setSdpRilascioDocumento(Timestamp sdpRilascioDocumento) {
		this.sdpRilascioDocumento = sdpRilascioDocumento;
	}


	public Timestamp getSdpScadenzaDocumento() {
		return sdpScadenzaDocumento;
	}


	public void setSdpScadenzaDocumento(Timestamp sdpScadenzaDocumento) {
		this.sdpScadenzaDocumento = sdpScadenzaDocumento;
	}


	public String getSdpNazionalita() {
		return sdpNazionalita;
	}


	public void setSdpNazionalita(String sdpNazionalita) {
		this.sdpNazionalita = sdpNazionalita;
	}


	public String getSdpCassa() {
		return sdpCassa;
	}


	public void setSdpCassa(String sdpCassa) {
		this.sdpCassa = sdpCassa;
	}


	public Long getSdpPrgOperazione() {
		return sdpPrgOperazione;
	}


	public void setSdpPrgOperazione(Long sdpPrgOperazione) {
		this.sdpPrgOperazione = sdpPrgOperazione;
	}


	public Integer getNumeroFasiCarrello() {
		return numeroFasiCarrello;
	}


	public void setNumeroFasiCarrello(Integer numeroFasiCarrello) {
		this.numeroFasiCarrello = numeroFasiCarrello;
	}


	public String getIdorac() {
		return idorac;
	}


	public void setIdorac(String idorac) {
		this.idorac = idorac;
	}
}
