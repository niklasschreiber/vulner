package it.reply.postecom.db.model;

import java.io.Serializable;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.persistence.Transient;

@Entity
@Table(name ="OFFERTA")
@NamedQueries(
{
	@NamedQuery(name="Offerta.findByTipoCliente",query="SELECT distinct o from OffertaModel o, OffertaListino ol " +
		"where o.idOfferta=ol.offerta.idOfferta and o.tipoUtente.idTipoUtente=:tipoCliente and o.dataInizioValidita <=:now and o.dataFineValidita >=:now " +
		"and o.flag_crm=:f_crm and o.flag_coupon=:f_coupon and o.flag_offerta_base=:f_offerta_base and o.idStatoOfferta=:stato_offerta " +
		"and  ol.dataInizioValidita <=:now and ol.dataFineValidita >=:now"),
	@NamedQuery(name="Offerta.findByID",query="SELECT o from OffertaModel o where o.idOfferta=:idOfferta and o.dataInizioValidita <=:now and o.dataFineValidita >=:now"),
	@NamedQuery(name="Offerta.findByID_TipoCliente",query="SELECT o from OffertaModel o where o.idOfferta=:idOfferta and o.tipoUtente.idTipoUtente=:tipoCliente and o.dataInizioValidita <=:now and o.dataFineValidita >=:now"),
	@NamedQuery(name="Offerta.findAll",query="SELECT distinct o from OffertaModel o , OffertaListino ol  where o.idOfferta=ol.offerta.idOfferta and o.dataInizioValidita <=:now " +
		"and o.dataFineValidita >=:now and o.flag_crm=:f_crm and o.flag_coupon=:f_coupon and o.flag_offerta_base=:f_offerta_base " +
		"and o.idStatoOfferta=:stato_offerta and  ol.dataInizioValidita <=:now and ol.dataFineValidita >=:now"),
	@NamedQuery(name="Offerta.findbaseattivo",query="SELECT o from OffertaModel o   where o.flag_offerta_base=:flagOB and o.flag_crm=:flagA and o.flag_coupon=:flagC and o.dataFineValidita is not null and (o.dataFineValidita>=:now  or o.dataInizioValidita>:now ) and " +
		"o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and o1.dataInizioValidita<=:now) " +
		"order by o.dataInizioValidita desc"),
	@NamedQuery(name="Offerta.findattive",query="SELECT o from OffertaModel o where o.flag_offerta_base=:flagOB and o.flag_coupon=:flagC and o.dataFineValidita>=:now  and o.dataFineValidita is not null and " +
		"o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and (o1.dataInizioValidita<=:now or o1.dataInizioValidita>=:now)) order by o.dataInizioValidita desc"),
	@NamedQuery(name="Offerta.findattive2",query="SELECT o from OffertaModel o where o.flag_offerta_base=:flagOB and o.flag_coupon=:flagC and o.flagAdHoc=:flagH and o.flagEvento=:flagE and o.dataFineValidita>=:now  and o.dataFineValidita is not null and " +
		"o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and (o1.dataInizioValidita<=:now or o1.dataInizioValidita>=:now)) order by o.dataInizioValidita desc"),
	@NamedQuery(name="Offerta.findattiveByModSconto",query="SELECT o from OffertaModel o where o.modalitaSconto=:modSconto and o.flag_offerta_base=:flagOB and o.flag_coupon=:flagC and o.flagAdHoc=:flagH and o.flagEvento=:flagE and o.flag_crm=:flagCRM and o.dataFineValidita>=:now  and o.dataFineValidita is not null and " +
		"o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and (o1.dataInizioValidita<=:now or o1.dataInizioValidita>=:now)) order by o.dataInizioValidita desc"),
	@NamedQuery(name="Offerta.findPromoAttiveByModSconto",query="SELECT o from OffertaModel o where o.modalitaSconto=:modSconto and o.flag_offerta_base='0' and o.flag_crm='0' and "
		+ " (o.flag_coupon='1' or o.flagAdHoc='1' or o.flagEvento='1') and o.dataFineValidita is not null and " 
		+ " o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and (o1.dataInizioValidita<=:now or o1.dataInizioValidita>=:now)) and "
		+ " o not in (select o2 from OffertaModel o2 where o2.nuovaOfferta is not null and o2.dataFineValidita<:now and (o2.dataInizioValidita<=:now or o2.dataInizioValidita>=:now)) "
		+ " order by o.dataInizioValidita desc"),
	@NamedQuery(name="Offerta.findOffertaDaAggiornareSostiutuzioneBase",query="SELECT o from OffertaModel o join fetch o.offertaListini ol join fetch ol.listino where o.nuovaOfferta.idOfferta=:idNuovaOfferta"),
	@NamedQuery(name="Offerta.findOverlappingPromoAdHoc",query="SELECT o from OffertaModel o where o.dataFineValidita is not null and o.flagAdHoc=:flagAdHoc and o.idCliente=:idCliente and "
			+ " ((:dataInizio between o.dataInizioValidita and o.dataFineValidita) or (:dataFine between o.dataInizioValidita and o.dataFineValidita) or "
			+ " (o.dataInizioValidita between :dataInizio and :dataFine) or (o.dataFineValidita between :dataInizio and :dataFine)) "),
	@NamedQuery(name="Offerta.findOverlappingPromoEvento",query="SELECT o from OffertaModel o where o.dataFineValidita is not null and o.flagEvento=:flagEvento and "
			+ " ((:dataInizio between o.dataInizioValidita and o.dataFineValidita) or (:dataFine between o.dataInizioValidita and o.dataFineValidita) or "
			+ " (o.dataInizioValidita between :dataInizio and :dataFine) or (o.dataFineValidita between :dataInizio and :dataFine)) "),
	@NamedQuery(name="Offerta.findOfferteBaseAttive",query="SELECT o from OffertaModel o where o.flag_offerta_base=:flagOB and o.dataFineValidita>=:now  and o.dataFineValidita is not null and o.idStatoOfferta=1 and " +
			"o not in (select o1.nuovaOfferta from OffertaModel o1 where o1.dataFineValidita>=:now and (o1.dataInizioValidita<=:now or o1.dataInizioValidita>=:now)) order by o.dataInizioValidita desc"),
		
})
public class OffertaModel extends AbstractEntity implements Serializable {

	private static final long serialVersionUID = 1448853252678714472L;

	@Id
	@Column(name="ID_OFFERTA")
	@GeneratedValue(strategy=GenerationType.SEQUENCE, generator="SEQ_ID_OFFERTA")
    @SequenceGenerator(name="SEQ_ID_OFFERTA", sequenceName="SEQ_ID_OFFERTA", allocationSize=1)
	private long idOfferta;
	
	@Column(name="DESCRIZIONE")
	private String descrizione;
	
	@Column(name="FLAG_OFFERTA_BASE")
	private String flag_offerta_base;
	
	@Column(name="FLAG_CRM")
	private String flag_crm;
	 
	@Column(name="FLAG_COUPON")
	private String flag_coupon;
		
	@Column(name="FLAG_EVENTO")
	private String flagEvento;
		
	@Column(name="FLAG_AD_HOC")
	private String flagAdHoc;
		
    @ManyToOne
    @JoinColumn(name="ID_MODALITA_SCONTO")
	private ModalitaSconto modalitaSconto;
 
	@Column(name="PERCENTUALE_SCONTO")
	private Integer percentualeSconto;

	@Column(name="ID_CLIENTE")
	private String idCliente;
		
	@Transient
	private String descrStato;
	
	@Transient
	private boolean sostituibile;
	
	@Transient
	private boolean online;
	
	@Transient
	private boolean deleted;
	
	@Transient
	private boolean expired;
	
	@Transient
	private boolean crm;
	
	@Temporal( TemporalType.TIMESTAMP)
	@Column(name="DATA_FINE_VALIDITA")
	private Date dataFineValidita;

    @Temporal( TemporalType.TIMESTAMP)
	@Column(name="DATA_INIZIO_VALIDITA")
	private Date dataInizioValidita;
    
    @ManyToOne
   	@JoinColumn(name="ID_TIPO_UTENTE")
   	private TipoUtente tipoUtente;
    
    @ManyToOne
    @JoinColumn(name="ID_TIPO_OFFERTA")
   	private TipologiaOfferta tipologiaOfferta;
    
    @OneToOne
    @JoinColumn(name="ID_ELABORAZIONE")
   	private Elaborazione elaborazione;
    
	@Column(name="id_stato_offerta")
    private Integer idStatoOfferta;
    
	@Column(name="VOLUME_MINIMO_PROMESSO")
    private Integer volumeAnnualeMinimo;
	
	@Column(name="VOLUME_MASSIMO_PROMESSO")
    private Integer volumeAnnualeMassimo;
	
    @Column(name="MAX_SPEDIZIONI_ORDINE")
    private Integer maxSpedizioniOrdine;

    @Column(name="MAX_ORDINI_CLIENTE")
    private Integer maxOrdiniCliente;

    @ManyToOne
   	@JoinColumn(name="ID_TIPO_CANALE")
   	private TipologiaCanale tipologiaCanale;
    
    @ManyToOne
   	@JoinColumn(name="USERNAME")
   	private User user;
    
	public String getFlag_offerta_base() {
		return flag_offerta_base;
	}

	public void setFlag_offerta_base(String flag_offerta_base) {
		this.flag_offerta_base = flag_offerta_base;
	}

	public String getFlag_attiva() {
		return flag_crm;
	}

	public void setFlag_attiva(String flag_attiva) {
		this.flag_crm = flag_attiva;
	}

	public String getFlag_coupon() {
		return flag_coupon;
	}

	public void setFlag_coupon(String flag_coupon) {
		this.flag_coupon = flag_coupon;
	}
    
    public Integer getIdStatoOfferta() {
		return idStatoOfferta;
	}

	public void setIdStatoOfferta(Integer idStatoOfferta) {
		this.idStatoOfferta = idStatoOfferta;
	}

	public Elaborazione getElaborazione() {
		return elaborazione;
	}

	public void setElaborazione(Elaborazione elaborazione) {
		this.elaborazione = elaborazione;
	}

	//bi-directional many-to-one association to ListinoCoupon
  	@OneToMany(mappedBy="offerta")
  	private List<OffertaListino> offertaListini;
  	
  	@OneToMany(mappedBy="offerta")
  	private List<EventoOfferta> eventiOfferta;
  	
	@OneToMany(mappedBy="offerta")
  	private List<ContrattoOfferta> contrattiOfferta;
  	
 	@OneToMany(mappedBy="offerta")//,cascade = { CascadeType.ALL })
  	private List<CouponOfferta> couponOfferta;
  	
    public List<CouponOfferta> getCouponOfferta() {
		return couponOfferta;
	}


	public void setCouponOfferta(List<CouponOfferta> couponOfferta) {
		this.couponOfferta = couponOfferta;
	}

	@ManyToOne
	@JoinColumn(name="ID_NUOVA_OFFERTA")
  	private OffertaModel nuovaOfferta;
    

	public OffertaModel getNuovaOfferta() {
		return nuovaOfferta;
	}


	public void setNuovaOfferta(OffertaModel nuovaOfferta) {
		this.nuovaOfferta = nuovaOfferta;
	}


	public List<OffertaListino> getListiniOfferta() {
		return offertaListini;
	}

	public void setListiniOfferta(List<OffertaListino> listiniOfferta) {
		this.offertaListini = listiniOfferta;
	}

	public TipoUtente getTipoUtente() {
		return tipoUtente;
	}

	public void setTipoUtente(TipoUtente tipoUtente) {
		this.tipoUtente = tipoUtente;
	}

	public long getIdOfferta() {
		return idOfferta;
	}

	public void setIdOfferta(long idOfferta) {
		this.idOfferta = idOfferta;
	}

	public String getDescrizione() {
		return descrizione;
	}

	public void setDescrizione(String descrizione) {
		this.descrizione = descrizione;
	}

	public Date getDataFineValidita() {
		return dataFineValidita;
	}

	public void setDataFineValidita(Date dataFineValidita) {
		this.dataFineValidita = dataFineValidita;
	}

	public Date getDataInizioValidita() {
		return dataInizioValidita;
	}

	public void setDataInizioValidita(Date dataInizioValidita) {
		this.dataInizioValidita = dataInizioValidita;
	}

  	public List<EventoOfferta> getEventiOfferta() {
		return eventiOfferta;
	}

	public void setEventiOfferta(List<EventoOfferta> eventiOfferta) {
		this.eventiOfferta = eventiOfferta;
	}

	public List<ContrattoOfferta> getContrattiOfferta() {
		return contrattiOfferta;
	}

	public void setContrattiOfferta(List<ContrattoOfferta> contrattiOfferta) {
		this.contrattiOfferta = contrattiOfferta;
	}

	public List<OffertaListino> getOffertaListini() {
		return offertaListini;
	}

	public void setOffertaListini(List<OffertaListino> offertaListini) {
		this.offertaListini = offertaListini;
	}

	public String getFlag_crm() {
		return flag_crm;
	}

	public void setFlag_crm(String flag_crm) {
		this.flag_crm = flag_crm;
	}

	public TipologiaOfferta getTipologiaOfferta() {
		return tipologiaOfferta;
	}

	public void setTipologiaOfferta(TipologiaOfferta tipologiaOfferta) {
		this.tipologiaOfferta = tipologiaOfferta;
	}

	public Integer getMaxSpedizioniOrdine() {
		return maxSpedizioniOrdine;
	}

	public void setMaxSpedizioniOrdine(Integer maxSpedizioniOrdine) {
		this.maxSpedizioniOrdine = maxSpedizioniOrdine;
	}

	public Integer getMaxOrdiniCliente() {
		return maxOrdiniCliente;
	}

	public void setMaxOrdiniCliente(Integer maxSpedizioniCliente) {
		this.maxOrdiniCliente = maxSpedizioniCliente;
	}

	public Integer getVolumeAnnualeMinimo() {
		return volumeAnnualeMinimo;
	}

	public void setVolumeAnnualeMinimo(Integer volumeAnnualeMinimo) {
		this.volumeAnnualeMinimo = volumeAnnualeMinimo;
	}

	public Integer getVolumeAnnualeMassimo() {
		return volumeAnnualeMassimo;
	}

	public void setVolumeAnnualeMassimo(Integer volumeAnnualeMassimo) {
		this.volumeAnnualeMassimo = volumeAnnualeMassimo;
	}

	@Override
	public String toString() {
		return "OffertaModel [idOfferta=" + idOfferta + ", descrizione=" + descrizione + ", flag_offerta_base="
				+ flag_offerta_base + ", flag_crm=" + flag_crm + ", flag_coupon=" + flag_coupon + ", flagEvento="
				+ flagEvento + ", flagAdHoc=" + flagAdHoc + ", modalitaSconto=" + modalitaSconto
				+ ", percentualeSconto=" + percentualeSconto + ", idCliente=" + idCliente + ", descrStato=" + descrStato
				+ ", sostituibile=" + sostituibile + ", online=" + online + ", crm=" + crm + ", dataFineValidita="
				+ dataFineValidita + ", dataInizioValidita=" + dataInizioValidita + ", tipoUtente=" + tipoUtente
				+ ", tipologiaOfferta=" + tipologiaOfferta + ", elaborazione=" + elaborazione + ", idStatoOfferta="
				+ idStatoOfferta + ", volumeAnnualeMinimo=" + volumeAnnualeMinimo + ", volumeAnnualeMassimo="
				+ volumeAnnualeMassimo + ", maxSpedizioniOrdine=" + maxSpedizioniOrdine + ", maxSpedizioniCliente="
				+ maxOrdiniCliente + ", tipologiaCanale=" + tipologiaCanale + ", user=" + user + ", offertaListini="
				+ offertaListini + ", eventiOfferta=" + eventiOfferta + ", contrattiOfferta=" + contrattiOfferta
				+ ", couponOfferta=" + couponOfferta + ", nuovaOfferta=" + nuovaOfferta + "]";
	}

	public String getDescrStato() {
		
		Calendar now = GregorianCalendar.getInstance();
		Calendar from = GregorianCalendar.getInstance();
		from.setTime(dataInizioValidita);
		Calendar to = null;
		if (null != dataFineValidita) {
			to = GregorianCalendar.getInstance();
			to.setTime(dataFineValidita);
		}
		
		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
		
		descrStato = "";
		if (1 == idStatoOfferta) {
			if (null != to && now.after(from) && now.before(to) ) {
				descrStato = "ON-LINE";
			} 
			if (null != to && now.before(from)) {
				descrStato = "On-line dal "+ sdf.format(dataInizioValidita);
				
			}
			if (null != to && now.after(to)) {
				descrStato = "Scaduta il " + sdf.format(dataFineValidita);
			}
		} else if (0 == idStatoOfferta || 1 == idStatoOfferta ) {
			descrStato = "In Elaborazione";
		} else if (2 == idStatoOfferta) {
			descrStato = "Errore Elaborazione";
		}
		
		return descrStato;
	}

	public void setDescrStato(String descrStato) {
		this.descrStato = descrStato;
	}

	public String getFlagEvento() {
		return flagEvento;
	}


	public void setFlagEvento(String flagEvento) {
		this.flagEvento = flagEvento;
	}


	public String getFlagAdHoc() {
		return flagAdHoc;
	}


	public void setFlagAdHoc(String flagAdHoc) {
		this.flagAdHoc = flagAdHoc;
	}


	public String getIdCliente() {
		return idCliente;
	}


	public void setIdCliente(String idCliente) {
		this.idCliente = idCliente;
	}

	public TipologiaCanale getTipologiaCanale() {
		return tipologiaCanale;
	}

	public void setTipologiaCanale(TipologiaCanale tipologiaCanale) {
		this.tipologiaCanale = tipologiaCanale;
	}

	public User getUser() {
		return user;
	}

	public void setUser(User user) {
		this.user = user;
	}

	public Integer getPercentualeSconto() {
		return percentualeSconto;
	}

	public void setPercentualeSconto(Integer percentualeSconto) {
		this.percentualeSconto = percentualeSconto;
	}

	public ModalitaSconto getModalitaSconto() {
		return modalitaSconto;
	}

	public void setModalitaSconto(ModalitaSconto modalitaSconto) {
		this.modalitaSconto = modalitaSconto;
	}

	public boolean isSostituibile() {
		
		sostituibile = (nuovaOfferta == null && idStatoOfferta == 1 && !isExpired());
		
		return sostituibile;
	}

	public void setSostituibile(boolean sostituibile) {
		this.sostituibile = sostituibile;
	}

	public boolean isCrm() {
		
		if (flag_crm.equals("1"))
			crm=true;
		return crm;
	}

	public void setCrm(boolean crm) {
		this.crm = crm;
	}

	public boolean isOnline() {
		Date d = new Date();
		
		online = (null != dataFineValidita && 1 == idStatoOfferta && d.before(dataFineValidita) && d.after(dataInizioValidita));
		
		return online;
	}

	public void setOnline(boolean online) {
		this.online = online;
	}

	public boolean isDeleted() {
		deleted = (null == dataFineValidita);
		return deleted;
	}

	public void setDeleted(boolean deleted) {
		this.deleted = deleted;
	}

	public boolean isExpired() {
		Date d = new Date();
		
		expired = (null != dataFineValidita && 1 == idStatoOfferta && d.after(dataFineValidita) && d.after(dataInizioValidita));
		
		return expired;
	}

	public void setExpired(boolean expired) {
		this.expired = expired;
	}

}
