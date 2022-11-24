package nfec.frontend.framework.utils;

import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collector;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import nfec.backend.architecture.config.ServiceLoggingHandler;
import nfec.core.baseclasses.utils.BaseConstants;
import nfec.core.baseclasses.utils.FacesUtils;
import nfec.core.baseclasses.utils.StringUtils;
import nfec.crosscutting.logging.LogSystemFactory;
import nfec.crosscutting.logging.LogSystemInterface;
import nfec.frontend.pojo.audit.AuditManager;
import nfec.frontend.pojo.contoInProprio.ClienteBusinessAnag;
import nfec.frontend.pojo.contoInProprio.variazioneRappresentanza.DelegaFotografiaTypeDTO;
import nfec.frontend.pojo.contoInProprio.variazioneRappresentanza.DelegaFotografiaTypeDTO.TabDto;
import nfec.frontend.pojo.contoInProprio.variazioneRappresentanza.FotografiaDelegaEnum;
import nfec.frontend.pojo.contoInProprio.variazioneRappresentanza.VariazioneRappresentanzaDTOOutput;
import nfec.frontend.pojo.models.ClienteBeanBusinessVariazioneRappresentanzaCondomini;
import nfec.frontend.pojo.models.FiguraCollegata;
import nfec.frontend.pojo.models.InfoBaseCliente;
import nfec.frontend.pojo.models.RapportoCondominioVariazioneRappresentanza;
import nfec.frontend.pojo.models.UserInfoBean;
import nfec.frontend.pojo.models.business.ClienteSpallaSinistraVariazioneRappresentanzaBean;
import nfec.frontend.pojo.models.business.TipologiaClienteSpallaSinistraEnum;
import nfec.frontend.pojo.models.cliente.ListaRapportiOutput;
import nfec.frontend.pojo.models.organizzazioni.DatiRicercaOrganizzazioneBean;
import nfec.frontend.pojo.models.schedacliente.SchedaClienteBusinessBean;

public class VariazioneRappresentanzaCondominiUtils{
	
	static LogSystemInterface logger = LogSystemFactory.getLogger(ServiceLoggingHandler.class);
	
	public static ArrayList<FiguraCollegata> recuperaListaFigureCollegateDelegati(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaFigureCollegateDelegati >>>");
		ArrayList<FiguraCollegata> listaFigureCollegate = new ArrayList<>();
		String cfAmministratore = getAmministratoreCondominio(logger).getClienteBeanAnag().getCodiceFiscale();
		for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
			for (String cf : rapporto.getListaCFDelegatiInEssere()) {
				if(!cfAmministratore.equalsIgnoreCase(cf)){
					listaFigureCollegate.add(retriveFiguraCollegataByCF(cf,logger));
				}
			}
		}


		return listaFigureCollegate;
	}

	public static FiguraCollegata retriveFiguraCollegataByCF(String cf,LogSystemInterface logger) {
		logger.LogDebug("retriveFiguraCollegataByCF "+cf+" >>>");
		if (getAmministratoreCondominio(logger).getClienteBeanAnag().getCodiceFiscale().equalsIgnoreCase(cf))
			return getAmministratoreCondominio(logger);

		Optional<FiguraCollegata> res = getListaFigureCollegateRapporti(logger).stream().filter(x -> x.getClienteBeanAnag().getCodiceFiscale().equalsIgnoreCase(cf)).findFirst();

		if (res.isPresent()) {
			return res.get();
		}

		return null;
	}

	public static FiguraCollegata retriveFiguraCollegataByBp(String bp,LogSystemInterface logger) {
		logger.LogDebug("retriveFiguraCollegataByBp "+bp+" >>>");
		if (getAmministratoreCondominio(logger).getClienteBeanAnag().getCodiceBP().equalsIgnoreCase(bp))
			return getAmministratoreCondominio(logger);

		Optional<FiguraCollegata> res = getListaFigureCollegateRapporti(logger).stream()
				.filter(x -> Objects.nonNull(x.getClienteBeanAnag()))
				.filter(x -> StringUtils.isNotEmpty(x.getClienteBeanAnag().getCodiceBP()))
				.filter(x -> x.getClienteBeanAnag().getCodiceBP().equalsIgnoreCase(bp))
				.findFirst();

		if (res.isPresent()) {
			return res.get();
		}

		return null;
	}

	public static void addClienteBeanAnagIfAbsent(FiguraCollegata cliente,LogSystemInterface logger) {
		logger.LogDebug("addClienteBeanAnagIfAbsent "+cliente+" >>>");
		Optional<FiguraCollegata> res = getListaFigureCollegateRapporti(logger).stream().filter(x -> x.getClienteBeanAnag().getCodiceFiscale().equalsIgnoreCase(cliente.getClienteBeanAnag().getCodiceFiscale())).findFirst();

		if (!res.isPresent()) {
			getListaFigureCollegateRapporti(logger).add(cliente);
		}
	}

	private static ArrayList<FiguraCollegata> getListaFigureCollegateRapporti(LogSystemInterface logger) {
		logger.LogDebug("getListaFigureCollegateRapporti >>>");
		return getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getListaFigureCollegateRapporti();

	}

	public static ArrayList<RapportoCondominioVariazioneRappresentanza> getListaRapportiVariazioneRappresentanza(LogSystemInterface logger) {
		logger.LogDebug("getListaRapportiVariazioneRappresentanza >>>");
		return getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getListaRapportiVariazioneRappresentanza();
	}

	public static ArrayList<FiguraCollegata> recuperaListaFigureCollegateCompleta(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaFigureCollegateCompleta >>>");
		ArrayList<FiguraCollegata> listaFigureCollegate = new ArrayList<>();

		listaFigureCollegate.add(getAmministratoreCondominio(logger));
		listaFigureCollegate.addAll(recuperaListaFigureCollegateDelegati(logger));

		return listaFigureCollegate;
	}

	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> recuperaListaUtenzeSpallaCompilaDati(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaUtenzeSpallaCompilaDati >>>");
		ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> listaUtenze = new ArrayList<>();

		try {
			ClienteBusinessAnag amministratore = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio().getClienteBeanAnag();
			listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(amministratore.getCodiceFiscale(), BaseConstants.figura_amministratore_condominio, "", TipologiaClienteSpallaSinistraEnum.PF, true, false, 0));

			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
				listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(String.valueOf(rapporto.getDatiParticolariRapporto().getNumero()), "Conto " + rapporto.getDatiParticolariRapporto().getNumero(), "",
						TipologiaClienteSpallaSinistraEnum.RAPPORTO, false, false, rapporto.getDatiParticolariRapporto().getNumero()));
				for (String cf : rapporto.getListaCFDelegatiInEssere()) {
					if(!cf.equalsIgnoreCase(amministratore.getCodiceFiscale())){
						ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(cf,logger).getClienteBeanAnag();
						boolean deletable = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso() || !delegatoPresenteFraIPreesistenti(rapporto, cf,logger);
						String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
						listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(cf, BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, deletable, true, rapporto.getDatiParticolariRapporto().getNumero()));
					}
				}
			}
			
		} catch (Throwable t) {
			listaUtenze = new ArrayList<>();
		}

		return listaUtenze;
	}

	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> recuperaListaUtenzeSpallaCompletaDati(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaUtenzeSpallaCompletaDati >>>");

		ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> listaUtenze = new ArrayList<>();

		ClienteBusinessAnag pg = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getCondominioPG().getClienteBusinessAnag();
		listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(pg.getCodiceFiscale(), BaseConstants.tipo_figura_condominio.toUpperCase(), "", TipologiaClienteSpallaSinistraEnum.PG, false, false, 0));

		try {
			ClienteBusinessAnag amministratore = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio().getClienteBeanAnag();
			listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(amministratore.getCodiceFiscale(), BaseConstants.figura_amministratore_condominio, "", TipologiaClienteSpallaSinistraEnum.PF, false, false, 0));

			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {

				if (getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso() || modificataComposizioneDelegati(rapporto,logger)) {

					listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(String.valueOf(rapporto.getDatiParticolariRapporto().getNumero()), "Conto " + rapporto.getDatiParticolariRapporto().getNumero(), "",
							TipologiaClienteSpallaSinistraEnum.RAPPORTO, false, false, rapporto.getDatiParticolariRapporto().getNumero()));
					for (String cf : rapporto.getListaCFDelegatiInEssere()) {
						if(!cf.equalsIgnoreCase(amministratore.getCodiceFiscale())){
							ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(cf,logger).getClienteBeanAnag();
							String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
							listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(cf, BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
						}
					}
				}
			}
			
		} catch (Throwable t) {
			listaUtenze = new ArrayList<>();
		}

		return listaUtenze;
	}

	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> recuperaListaRapportiSpallaSxCH7(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaRapportiSpallaSxCH7 >>>");
		ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> res = (ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean>) recuperaListaUtenzeSpallaCompletaDati(logger).stream().filter(x -> x.isRapporto()).collect(Collectors.toList());

		return res;
	}

	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> recuperaListaRapportiSpallaSxQAV(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaRapportiSpallaSxQAV >>>");
		ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> res = (ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean>) recuperaListaUtenzeSpallaCompletaDati(logger).stream()
				.filter(x -> (x.isRapporto() && recuperaRapportoBeanDaNumeroRapporto(x.getNumeroRapporto(),logger).getListaCFDelegatiInEssere().size()>0)).collect(Collectors.toList());

		return res;
	}

	public static boolean delegatoPresenteFraIPreesistenti(RapportoCondominioVariazioneRappresentanza rapporto, String cf,LogSystemInterface logger) {
		logger.LogDebug("delegatoPresenteFraIPreesistenti "+rapporto+", "+cf+" >>>");
		Optional<InfoBaseCliente> resOrig = rapporto.getListaDelegatiOriginali().stream().filter(x -> x.getCodiceFiscale().equalsIgnoreCase(cf)).findFirst();
		return resOrig.isPresent();

	}

	public static nfec.frontend.pojo.models.FiguraCollegata getAmministratoreCondominio(LogSystemInterface logger) {
		logger.LogDebug("getAmministratoreCondominio >>>");
		return getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio();
	}

	public static ClienteBeanBusinessVariazioneRappresentanzaCondomini getClienteBeanBusinessVariazioneRappresentanzaCondomini(LogSystemInterface logger) {
		logger.LogDebug("getClienteBeanBusinessVariazioneRappresentanzaCondomini >>>");
		return FacesUtils.getManagedBean(ClienteBeanBusinessVariazioneRappresentanzaCondomini.class);
	}

	public static boolean sonoPresentiDelegati(LogSystemInterface logger) {
		logger.LogDebug("sonoPresentiDelegati >>>");
		boolean result = false;
		for (RapportoCondominioVariazioneRappresentanza rapporto : getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getListaRapportiVariazioneRappresentanza()) {
			
			if (rapporto.getListaCFDelegatiInEssere().size() > 0) {
				result = true;
				break;
			}
		}

		return result;
	}

	public static boolean amministratoreNonValorizzato(LogSystemInterface logger) {
		logger.LogDebug("amministratoreNonValorizzato >>>");
		return StringUtils.isEmpty(getAmministratoreCondominio(logger).getClienteBeanAnag().getCodiceFiscale());
	}

	public static void rimuoviClientiNonNecessariDaSessioneDeleteFigura(LogSystemInterface logger) {
		rimuoviClientiNonNecessariDaSessione(logger, true);
	}

	public static void rimuoviClientiNonNecessariDaSessione(LogSystemInterface logger) {
		rimuoviClientiNonNecessariDaSessione(logger, false);
	}
	
	private static void rimuoviClientiNonNecessariDaSessione(LogSystemInterface logger, boolean isDeleteFigura) {
		logger.LogDebug("rimuoviClientiNonNecessariDaSessione >>>");

		Iterator<FiguraCollegata> iterator = getListaFigureCollegateRapporti(logger).iterator();
		
		while (iterator.hasNext()) {
			FiguraCollegata cliente = iterator.next();

			if (!isDeleteFigura 
					&& (cliente.getClienteBeanAnag() == null || StringUtils.isEmpty(cliente.getClienteBeanAnag().getCodiceFiscale()))) {
				iterator.remove();
				continue;
			}

			boolean trovato = false;

			String cf = cliente.getClienteBeanAnag().getCodiceFiscale();

			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {

				Optional<String> res = rapporto.getListaCFDelegatiInEssere().stream().filter(x -> x.equalsIgnoreCase(cf)).findFirst();

				trovato |= res.isPresent();

			}

			if (!trovato)
				iterator.remove();

		}
	}

	public static boolean nessunaModificaEffettuataCompilaDati(LogSystemInterface logger) {
		logger.LogDebug("nessunaModificaEffettuataCompilaDati >>>");
		boolean res = true;

		if (getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso())
			res = false;
		else {
			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
				if (modificataComposizioneDelegati(rapporto,logger)) {
					res = false;
					break;
				}
			}
		}
		
		return res;
	}

	public static void rimuoviDaListaFigureVisualizzate(String key,LogSystemInterface logger) {
		logger.LogDebug("rimuoviDaListaFigureVisualizzate "+key+",  >>>");
		if (getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().containsKey(key)) {
			getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().remove(key);
		}
	}

	public static void aggiungiAListaFigureVisualizzate(String key, boolean disabled,LogSystemInterface logger) {
		logger.LogDebug("aggiungiAListaFigureVisualizzate "+key+", "+disabled+" >>>");
		if (!getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().containsKey(key) || getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().get(key)) {
			getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().put(key, disabled);
		} else if (!getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().containsKey(key)) {
			getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().put(key, disabled);
		}
	}

	public static void aggiungiAListaFigureVisualizzateCompletaDati(int index,LogSystemInterface logger) {
		logger.LogDebug("aggiungiAListaFigureVisualizzateCompletaDati "+index+" >>>");
		String key = recuperaListaUtenzeSpallaCompletaDati(logger).get(index).getKey();
		boolean disabled = false;

		aggiungiAListaFigureVisualizzate(key, disabled,logger);
	}

	public static void aggiungiAListaFigureVisualizzateCH7(int index,LogSystemInterface logger) {
		logger.LogDebug("aggiungiAListaFigureVisualizzateCH7 "+index+" >>>");
		String key = recuperaListaRapportiSpallaSxCH7(logger).get(index).getKey();
		boolean disabled = false;

		aggiungiAListaFigureVisualizzate(key, disabled,logger);
	}

	public static void aggiungiAListaFigureVisualizzateQAV(int index,LogSystemInterface logger) {
		logger.LogDebug("aggiungiAListaFigureVisualizzateQAV "+index+" >>>");
		String key = recuperaListaRapportiSpallaSxQAV(logger).get(index).getKey();
		boolean disabled = false;

		aggiungiAListaFigureVisualizzate(key, disabled,logger);
	}

	public static boolean tuttePersoneFisicheVisualizzateCompilaDati(LogSystemInterface logger) {
		logger.LogDebug("tuttePersoneFisicheVisualizzateCompilaDati >>>");
		return tutteFigureVisualizzate(TipologiaClienteSpallaSinistraEnum.PF, recuperaListaUtenzeSpallaCompilaDati(logger),logger);
	}

	public static boolean tutteFigureVisualizzateCompletaDati(LogSystemInterface logger) {
		logger.LogDebug("tutteFigureVisualizzateCompletaDati >>>");
		return tutteFigureVisualizzate(null, recuperaListaUtenzeSpallaCompletaDati(logger),logger);
	}

	public static boolean tutteFigureVisualizzateCh7(LogSystemInterface logger) {
		logger.LogDebug("tutteFigureVisualizzateCh7 >>>");
		return tutteFigureVisualizzate(TipologiaClienteSpallaSinistraEnum.RAPPORTO, recuperaListaRapportiSpallaSxCH7(logger),logger);
	}

	public static boolean tutteFigureVisualizzateQAV(LogSystemInterface logger) {
		logger.LogDebug("tutteFigureVisualizzateQAV >>>");
		return tutteFigureVisualizzate(TipologiaClienteSpallaSinistraEnum.RAPPORTO, recuperaListaRapportiSpallaSxQAV(logger),logger);
	}

	public static boolean tutteFigureVisualizzate(TipologiaClienteSpallaSinistraEnum tipofigura, ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> listaFigureSpallaSx,LogSystemInterface logger) {
		logger.LogDebug("tutteFigureVisualizzate "+tipofigura+", "+listaFigureSpallaSx+">>>");
		
		boolean res = true;

		for (ClienteSpallaSinistraVariazioneRappresentanzaBean item : listaFigureSpallaSx) {
			if (item.getTipologia().equals(tipofigura) || (tipofigura == null)) {
				if (!getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().keySet().contains(item.getKey())) {
					res = false;
					break;
				} else if (modificataComposizioneDelegati(recuperaRapportoBeanDaNumeroRapporto(item.getNumeroRapporto(),logger),logger) && getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().get(item.getKey())) {
					res = false;
					break;
				}
			}
		}

		return res;
	}

	public static RapportoCondominioVariazioneRappresentanza recuperaRapportoBeanDaNumeroRapporto(long numeroRapporto,LogSystemInterface logger) {
		logger.LogDebug("recuperaRapportoBeanDaNumeroRapporto "+numeroRapporto+" >>>");
		RapportoCondominioVariazioneRappresentanza rapporto = null;
		
		if (numeroRapporto>0){
			ArrayList<RapportoCondominioVariazioneRappresentanza> listaRapportiVariazioneRappresentanza = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getListaRapportiVariazioneRappresentanza();
			if (listaRapportiVariazioneRappresentanza != null) {
				Optional<RapportoCondominioVariazioneRappresentanza> resOrig = listaRapportiVariazioneRappresentanza.stream().filter(x -> x.getDatiParticolariRapporto().getNumero() == numeroRapporto).findFirst();
				if (resOrig.isPresent())
					rapporto = resOrig.get();
			}
		}
		return rapporto;
	}

	public static RapportoCondominioVariazioneRappresentanza recuperaRapportoBeanDaNumeroPratica(String numeroPratica,LogSystemInterface logger) {
		logger.LogDebug("recuperaRapportoBeanDaNumeroPratica "+numeroPratica+" >>>");
		RapportoCondominioVariazioneRappresentanza rapporto = null;
		if (StringUtils.isNotEmpty(numeroPratica)){
			ArrayList<RapportoCondominioVariazioneRappresentanza> listaRapportiVariazioneRappresentanza = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getListaRapportiVariazioneRappresentanza();
			if (listaRapportiVariazioneRappresentanza != null) {
				Optional<RapportoCondominioVariazioneRappresentanza> resOrig = listaRapportiVariazioneRappresentanza.stream().filter(x -> x.getInfoPraticaVariazioneRappresentanza() != null 
						&&  numeroPratica.equalsIgnoreCase(x.getInfoPraticaVariazioneRappresentanza().getNumeroPratica())).findFirst();
				if (resOrig.isPresent())
					rapporto = resOrig.get();
			}
		}
		return rapporto;
	}

	
	public static boolean modificataComposizioneDelegati(RapportoCondominioVariazioneRappresentanza rapporto,LogSystemInterface logger) {
		logger.LogDebug("modificataComposizioneDelegati "+rapporto+" >>>");
		boolean res = false;

		if (rapporto != null) {
			for (String cf : rapporto.getListaCFDelegatiInEssere()) {
				Optional<InfoBaseCliente> resOrig = rapporto.getListaDelegatiOriginali().stream().filter(x -> x.getCodiceFiscale().equalsIgnoreCase(cf)).findFirst();
				if (!resOrig.isPresent()) {
					res = true;
					break;
				}
			}
		}

		return res;
	}

	public static void cleanListaFigureVisualizzate(LogSystemInterface logger) {
		logger.LogDebug("cleanListaFigureVisualizzate >>>");
		getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getIndiciFigureVisitate().clear();
	}

	public static ArrayList<FiguraCollegata> recuperaListaClienteBusinessAnagPFModificabili(LogSystemInterface logger) {
		logger.LogDebug("recuperaListaClienteBusinessAnagPFModificabili >>>");
		ArrayList<FiguraCollegata> listafigureCollegate = recuperaListaFigureCollegateCompleta(logger);
		ArrayList<FiguraCollegata> listafigureCollegateModificabili = new ArrayList<>();

		for (FiguraCollegata figura : listafigureCollegate) {
			String cf = figura.getClienteBeanAnag().getCodiceFiscale();
			Optional<ClienteSpallaSinistraVariazioneRappresentanzaBean> res = recuperaListaUtenzeSpallaCompletaDati(logger).stream().filter(x -> x.isPF() && x.getCodiceFiscale().equalsIgnoreCase(cf)).findFirst();
			if (res.isPresent() ) {
				Optional<FiguraCollegata> res2 = listafigureCollegateModificabili.stream().filter(x -> x.getClienteBeanAnag().getCodiceFiscale().equalsIgnoreCase(cf)).findFirst();
				if (!res2.isPresent())
					listafigureCollegateModificabili.add(figura);
			}
		}

		return listafigureCollegateModificabili;
	}

	public static void creaProcessoVariazioneRappresentanza(LogSystemInterface logger){
		logger.LogDebug("creaProcessoVariazioneRappresentanza >>>");
		UserInfoBean userInfo = FacesUtils.getManagedBean(UserInfoBean.class);
		UUID idProcesso = AuditManager.CreaProcesso(userInfo,FacesUtils.getManagedBean(DatiRicercaOrganizzazioneBean.class).getRagioneSociale(),BaseConstants.audit_tipoProcesso_variazioneRappresentanza);		
		userInfo.setProcessoAudit(idProcesso.toString());
		
	}
	
	
	private static void insertAttivitaAudit(int tipoOperazione,LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAudit "+tipoOperazione+" >>>");
		DatiRicercaOrganizzazioneBean organizzazioneBean = FacesUtils.getManagedBean(DatiRicercaOrganizzazioneBean.class);
		
		String bp = organizzazioneBean.getCodiceBp();
		String cf = organizzazioneBean.getCodiceFiscale();
		
		AuditManager.CreaAttivita(bp, tipoOperazione, cf);
	}
	
	public static void insertAttivitaAuditVariazioneRappresentanzaCompleta(LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAuditVariazioneAmministratoreEdeleghe >>>");
		insertAttivitaAudit(BaseConstants.audit_tipoAttivita_variazioneAmministratoreEdeleghe,logger);
	}
	
	public static void insertAttivitaAuditAvvioDaSchedaCliente(LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAuditAvvioVariazioneRappresentanza >>>");
		insertAttivitaAudit(BaseConstants.audit_tipoAttivita_avvioVariazioneRappresentanza,logger);
	}

	
	public static void insertAttivitaAuditAvvioDaPostVendita(LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAuditAvvioVariazioneRappresentanzaDaPostVendita >>>");
		insertAttivitaAudit(BaseConstants.audit_tipoAttivita_avvioVariazioneRappresentanzaDaPostVendita,logger);
	}
	
	public static void insertAttivitaAuditVariazioneAmministratore(LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAuditVariazioneAmministratore >>>");
		insertAttivitaAudit(BaseConstants.audit_tipoAttivita_variazioneAmministratore,logger);
	}
	
	public static void insertAttivitaAuditAggiuntaDelegato(LogSystemInterface logger){
		logger.LogDebug("insertAttivitaAuditAggiuntaDelegato >>>");
		insertAttivitaAudit(BaseConstants.audit_tipoAttivita_aggiuntaDelegato,logger);
	}
	
	
	public static FotografiaDelegaEnum calcolaTipologiaDelega(LogSystemInterface logger,VariazioneRappresentanzaDTOOutput orchResult,String ndg, long numeroRapporto) {
		logger.LogDebug("calcolaTipologiaDelega >>>");
		DelegaFotografiaTypeDTO delegaFotografia = delegaFotografiaByCf(ndg,numeroRapporto, orchResult.getFotografiaDelega().getDelega());
		if (delegaFotografia == null){
			logger.LogDebug("Stato delegato non trovato: ndg delegato: " + ndg + " ,Numero rapporto: " + numeroRapporto);
			return null;
		}
		Optional<TabDto> delegatoOptional = delegaFotografia.getTabDto().stream().filter(del -> ndg.equals(del.getNdgDto())).findFirst();
		if(delegatoOptional.isPresent()){
			TabDto delegato = delegatoOptional.get();
			logger.LogDebug("Stato delegato: " + delegato.getStatoDelegato() + " ,ndg delegato: " + ndg + " ,Numero rapporto: " + delegaFotografia.getNumeroRapporto());
			return FotografiaDelegaEnum.getEnumByCodiceFotografia(delegato.getStatoDelegato());			
		} else{
			return null;
		}
	}
	
	public static FotografiaDelegaEnum calcolaFotografiaDelega(LogSystemInterface logger,VariazioneRappresentanzaDTOOutput orchResult,String ndg, long numeroRapporto) {
		logger.LogDebug("calcolaTipologiaDelega >>>");
		TabDto tab = delegaFotografiaByNdg(ndg,numeroRapporto, orchResult.getFotografiaDelega().getDelega());
		if (tab == null){
			logger.LogDebug("Stato delegato non trovato: ndg delegato: " + ndg + " ,Numero rapporto: " + numeroRapporto);
			return null;
		}
		
		logger.LogDebug("Stato delegato: " + tab.getStatoDelegato() + " ,ndg delegato: " + ndg + " ,Numero rapporto: " + numeroRapporto);
		return FotografiaDelegaEnum.getEnumByCodiceFotografia(tab.getStatoDelegato());			
		
	}
	
	private static TabDto delegaFotografiaByNdg(String ndg, long numeroRapporto, List<DelegaFotografiaTypeDTO> listaDelegheFotografie) {
		
		TabDto tabRiepilogo = null;
		
		for(DelegaFotografiaTypeDTO delega : listaDelegheFotografie){
			
			for(TabDto tabDto : delega.getTabDto()){
				
				if(delega.getNumeroRapporto().equals(String.valueOf(numeroRapporto)) && tabDto.getNdgDto().equals(ndg)){
					
					tabRiepilogo = tabDto;
					
				}
			}
		}
		
		return tabRiepilogo ;
		
	}
	
	private static DelegaFotografiaTypeDTO delegaFotografiaByCf(String ndg, long numeroRapporto, List<DelegaFotografiaTypeDTO> listaDelegheFotografie) {	
		return listaDelegheFotografie.stream().filter(foto -> (foto.getTabDto().stream().filter(del -> ndg.equals(del.getNdgDto())).findFirst() != null) && (StringUtils.toPrimitiveLong(foto.getNumeroRapporto()) == numeroRapporto)).findFirst().orElse(null);
	}
	
	public static String recuperaNdgFiguraVR(String codiceCRM, LogSystemInterface logger) {

		String ndg = null;

		if(Objects.nonNull(codiceCRM)) {
			
			ClienteBusinessAnag pg = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getCondominioPG().getClienteBusinessAnag();
			
			if(codiceCRM.equals(pg.getCodiceBP())) {
				ndg = String.valueOf(pg.getNdg());
			}
			
			ArrayList<FiguraCollegata> listaFigure = recuperaListaFigureCollegateCompleta(logger);
			Optional<FiguraCollegata> item = listaFigure.stream()
				.filter(figura -> Objects.nonNull(figura.getClienteBeanAnag()))
				.filter(figura -> codiceCRM.equals(figura.getClienteBeanAnag().getCodiceBP()))
				.findFirst();
			
			if(item.isPresent()) {
				ndg = String.valueOf(item.get().getClienteBeanAnag().getNdg());
			}
		}
		
		return ndg;
	}
	
	public static String recuperaNumeroRapportoDaIdPratica(String idPratica, LogSystemInterface logger) {
		RapportoCondominioVariazioneRappresentanza rapporto = recuperaRapportoBeanDaNumeroPratica(idPratica, logger);
		if(Objects.nonNull(rapporto)) {
			return String.valueOf(rapporto.getDatiParticolariRapporto().getNumero());
		}
		
		return null;
	}
	
	public static boolean cfPresenteDelegatiOriginali(ArrayList<InfoBaseCliente> delegatiOriginali,String cfDelegato) {
		Optional<InfoBaseCliente> delegatoPresente = delegatiOriginali.stream().filter(infoCliente -> infoCliente.getCodiceFiscale().equals(cfDelegato)).findFirst();
		return delegatoPresente.isPresent();
	}
	
	public static List<nfec.frontend.pojo.models.cliente.RapportoBean> recuperaElencoLibrettiAttivi(LogSystemInterface logger) {

		SchedaClienteBusinessBean schedaClienteBusinessBean = FacesUtils.getManagedBean(SchedaClienteBusinessBean.class);
		ListaRapportiOutput listaRapportiOutput = schedaClienteBusinessBean.getListaRapportiOutput();
		ArrayList<nfec.frontend.pojo.models.cliente.RapportoBean> elencoLibrettiAttivi = new ArrayList<>();
		if (!(listaRapportiOutput == null || listaRapportiOutput.getRapporti() == null || listaRapportiOutput.getRapporti().size() == 0)) {

			for (nfec.frontend.pojo.models.cliente.RapportoBean item : listaRapportiOutput.getRapporti()) {

				if ("DR".equalsIgnoreCase(item.getServizio()) && item.getNumeroRapporto() > 0 && (item.getDataEstinsione() == null || item.getDataEstinsione().after(new Date()))) {
					elencoLibrettiAttivi.add(item);
				}
			}
		}

		return elencoLibrettiAttivi;
	}
	
	public static List<FiguraCollegata> recuperaFigureAggiunte(LogSystemInterface logger){
		logger.LogDebug("recuperaFigureAggiunte >>>");
		ArrayList<FiguraCollegata> retValue = new ArrayList<>();
		ArrayList<String> tmpInEssere = new ArrayList<>();
		ArrayList<String> tmpOriginale = new ArrayList<>();
		ClienteBusinessAnag amministratore = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio().getClienteBeanAnag();
		if(getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso()){
			retValue.add(retriveFiguraCollegataByCF(amministratore.getCodiceFiscale(), logger));
		}
		for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
			for (String cf : rapporto.getListaCFDelegatiInEssere()) {
				tmpInEssere.add(cf);
			}
			for (InfoBaseCliente cliente : rapporto.getListaDelegatiOriginali()) {
				tmpOriginale.add(cliente.getCodiceFiscale());
			}
		}
		List<String> result = tmpInEssere.stream().filter(fig -> !tmpOriginale.contains(fig)).collect(Collectors.toList());
		for(String cf : result){
			retValue.add(retriveFiguraCollegataByCF(cf, logger));
		}
		return retValue;
	}

	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> recuperaListaUtenzeSpallaPoteriDiFirma(LogSystemInterface logger) {
			logger.LogDebug("recuperaListaUtenzeSpallaPoteriDiFirma >>>");
			ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> listaUtenze = new ArrayList<>();
			try {
				ClienteBusinessAnag amministratore = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio().getClienteBeanAnag();
				if(getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso()){
					listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(amministratore.getCodiceFiscale(), BaseConstants.figura_amministratore_condominio, "", TipologiaClienteSpallaSinistraEnum.PF, false, false, 0));
				}

				for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {

					if (/*getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso() ||*/ modificataComposizioneDelegati(rapporto,logger)) {

						listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(String.valueOf(rapporto.getDatiParticolariRapporto().getNumero()), "Conto " + rapporto.getDatiParticolariRapporto().getNumero(), "",
								TipologiaClienteSpallaSinistraEnum.RAPPORTO, false, false, rapporto.getDatiParticolariRapporto().getNumero()));
						for (String cf : rapporto.getListaCFDelegatiInEssere()) {
							if(rapporto.getListaDelegatiOriginali().size() >= 0 &&
									(
										(!rapporto.getListaDelegatiOriginali().stream().map(del -> del.getCodiceFiscale()).collect(Collectors.toList()).contains(cf)) ||
										(rapporto.getListaDelegatiOriginali().stream().map(del -> del.getCodiceFiscale()).collect(Collectors.toList()).contains(cf)
												&& getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso())
									)
								){
								ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(cf,logger).getClienteBeanAnag();
								String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
								listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(cf, BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
							}
						}
					}
				}
				
			} catch (Throwable t) {
				listaUtenze = new ArrayList<>();
			}

			return listaUtenze;
		
	}
	
	public static ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> getAllFigure(LogSystemInterface logger) {
		logger.LogDebug("getAllFigure >>>");
		ArrayList<ClienteSpallaSinistraVariazioneRappresentanzaBean> listaUtenze = new ArrayList<>();
		try {
			ClienteBusinessAnag amministratore = getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).getAmministratoreCondominio().getClienteBeanAnag();
				listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(amministratore.getCodiceFiscale(), BaseConstants.figura_amministratore_condominio, "", TipologiaClienteSpallaSinistraEnum.PF, false, false, 0));
			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
					listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(String.valueOf(rapporto.getDatiParticolariRapporto().getNumero()), "Conto " + rapporto.getDatiParticolariRapporto().getNumero(), "",
							TipologiaClienteSpallaSinistraEnum.RAPPORTO, false, false, rapporto.getDatiParticolariRapporto().getNumero()));
					for (String cf : rapporto.getListaCFDelegatiInEssere()) {
						if(rapporto.getListaDelegatiOriginali().size() > 0 && !rapporto.getListaDelegatiOriginali().stream().map(del -> del.getCodiceFiscale()).collect(Collectors.toList()).contains(cf)){
							ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(cf,logger).getClienteBeanAnag();
							String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
							listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(cf, BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
						} else{
							ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(cf,logger).getClienteBeanAnag();
							String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
							listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(cf, BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
						}
					}
					for (InfoBaseCliente infoCliente : rapporto.getListaDelegatiOriginali()) {
						if(rapporto.getListaDelegatiOriginali().size() > 0 && !rapporto.getListaDelegatiOriginali().stream().map(del -> del.getCodiceFiscale()).collect(Collectors.toList()).contains(infoCliente.getCodiceFiscale())){
							ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(infoCliente.getCodiceFiscale(),logger).getClienteBeanAnag();
							String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
							listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(infoCliente.getCodiceFiscale(), BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
						} else{
							ClienteBusinessAnag cliente = retriveFiguraCollegataByCF(infoCliente.getCodiceFiscale(),logger).getClienteBeanAnag();
							String nomeCognomeEsteso = cliente != null ? cliente.getCognomeNome() : "";
							listaUtenze.add(new ClienteSpallaSinistraVariazioneRappresentanzaBean(infoCliente.getCodiceFiscale(), BaseConstants.figura_delegato_capitalized+" ", nomeCognomeEsteso, TipologiaClienteSpallaSinistraEnum.PF, true, true, rapporto.getDatiParticolariRapporto().getNumero()));
						}
					}
				
			}
			
		} catch (Throwable t) {
			listaUtenze = new ArrayList<>();
		}

		return listaUtenze;
	
}
	public static ArrayList<RapportoCondominioVariazioneRappresentanza> recuperaRapportiNuoveFigure(LogSystemInterface logger){
		logger.LogDebug("recuperaRapportiNuoveFigure >>>");
		ArrayList<RapportoCondominioVariazioneRappresentanza> retValue = new ArrayList<>();
		if(getClienteBeanBusinessVariazioneRappresentanzaCondomini(logger).isAmministratoreRimosso()){
			retValue = getListaRapportiVariazioneRappresentanza(logger);
		} else{
			for (RapportoCondominioVariazioneRappresentanza rapporto : getListaRapportiVariazioneRappresentanza(logger)) {
				if(rapporto.getListaCFDelegatiInEssere().size() > 0 && modificataComposizioneDelegati(rapporto, logger)) {
					retValue.add(rapporto);
				}
			}
		}
		return retValue;
	}
}

