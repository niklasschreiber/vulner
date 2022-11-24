package it.poste.onebooking.services;

import java.util.Date;
import java.util.List;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import it.poste.ngav.AppData;
import it.poste.onebooking.model.solariq.ValoreParametro;
import it.poste.onebooking.model.stat.StatCache;
import it.poste.onebooking.repositories.solariq.StatCacheRepository;
import it.poste.onebooking.repositories.solariq.ValoreParametroRepository;
import it.poste.onebooking.utils.WsParams;
import lombok.extern.log4j.Log4j;

@Service
@Log4j
public class NewWsService {

	protected static WsParams wsParams;
	protected static Date wsParamsLastUpd;

	protected Long statCacheTimeoutSec;


	@Autowired
	ValoreParametroRepository valoreParametroRep;

	@Autowired
	StatCacheRepository statCacheRep;

	@Autowired
	AppData appData;

	@PostConstruct
	protected void init() {
		log.info("WsService post-construct");
		statCacheTimeoutSec = new Long(appData.getPropertyValueInteger(AppData.wsStatExpireSec));
	}

	public WsParams getParamsCache() {

//		Date now = new Date();
//		if (wsParams != null && wsParamsLastUpd != null && (now.getTime() - wsParamsLastUpd.getTime()) < 60000) {
//			return wsParams;
//		}
//
//		WsParams wsp = new WsParams();
//		TypedQuery<ValoreParametro> queryValoreParametroByDescr = em.createNamedQuery("ValoreParametro.findByDescr",
//				ValoreParametro.class);
//		queryValoreParametroByDescr.setParameter(1, "Mob%");
//		if (queryValoreParametroByDescr.getResultList().size() > 0) {
//			for (ValoreParametro valoreParametro : queryValoreParametroByDescr.getResultList()) {
//				switch (valoreParametro.getCodiceParametro().toLowerCase()) {
//				case "mobvisticketservito":
//					wsp.setMobVisTicketServito(valoreParametro.isValBooleano());
//					break;
//				case "mobvisutentiincoda":
//					wsp.setMobVisUtentiInCoda(valoreParametro.isValBooleano());
//					break;
//				case "mobvistempomediostimato":
//					wsp.setMobVisTempoMedioStimato(valoreParametro.isValBooleano()); // totAttesa
//					break;
//				case "mobgestionesospesi":
//					wsp.setMobGestioneSospesi(valoreParametro.isValBooleano());
//					break;
//				case "mobchiamataautomaticasospesi":
//					wsp.setMobChiamataAutomaticaSospesi(valoreParametro.isValBooleano());
//					break;
//				case "mobmessaggioservito":
//					wsp.setMobMessaggioServito(valoreParametro.getValStringa());
//					break;
//				case "mobmessaggioservitominprima":
//					wsp.setMobMessaggioServitoMinPrima(valoreParametro.getValInteger());
//					break;
//				case "mobmessaggioservitomindopo":
//					wsp.setMobMessaggioServitoMinDopo(valoreParametro.getValInteger());
//					break;
//				// V2
//				case "mobcapprenotazione":
//					wsp.setMobCapPrenotazione(valoreParametro.getValInteger());
//					break;
//				case "mobcapannullamento":
//					wsp.setMobCapAnnullamento(valoreParametro.getValInteger());
//					break;
//				case "mobminutiscadenza":
//					wsp.setMobMinutiScadenza(valoreParametro.getValInteger());
//					break;
//				case "mobminutiinibizioneslot":
//					wsp.setMobMinutiInibizioneSlot(valoreParametro.getValInteger());
//					break;
//				case "mobdisabilitaprenotazionesenzatouchpoint":
//					wsp.setMobDisabilitaPrenotazioneSenzaTouchpoint(valoreParametro.isValBooleano());
//					break;
//				// V3
//				case "mobnumgiornifuturiprenotazione":
//					wsp.setMobNumGiorniFuturiPrenotazione(valoreParametro.getValInteger());
//					break;
//				case "moburlpan":
//					wsp.setMobUrlPan(valoreParametro.getValStringa());
//					break;
//				case "moboffseterrorpan":
//					wsp.setMobOffsetErrorPan(valoreParametro.getValInteger());
//					break;
//				}
//			}
//			wsParams = wsp;
//			wsParamsLastUpd = now;
//		}
//		return wsp;

		Date now = new Date();
		if (wsParams != null && wsParamsLastUpd != null && (now.getTime() - wsParamsLastUpd.getTime()) < 60000) {
			return wsParams;
		}

		WsParams wsp = new WsParams();

		List<ValoreParametro> list = valoreParametroRep.findByDescr("Mob%");

		if (!CollectionUtils.isEmpty(list)) {

			for (ValoreParametro valoreParametro : list) {
				switch (valoreParametro.getCodiceParametro().toLowerCase()) {
				case "mobvisticketservito":
					wsp.setMobVisTicketServito(valoreParametro.isValBooleano());
					break;
				case "mobvisutentiincoda":
					wsp.setMobVisUtentiInCoda(valoreParametro.isValBooleano());
					break;
				case "mobvistempomediostimato":
					wsp.setMobVisTempoMedioStimato(valoreParametro.isValBooleano()); // totAttesa
					break;
				case "mobgestionesospesi":
					wsp.setMobGestioneSospesi(valoreParametro.isValBooleano());
					break;
				case "mobchiamataautomaticasospesi":
					wsp.setMobChiamataAutomaticaSospesi(valoreParametro.isValBooleano());
					break;
				case "mobmessaggioservito":
					wsp.setMobMessaggioServito(valoreParametro.getValStringa());
					break;
				case "mobmessaggioservitominprima":
					wsp.setMobMessaggioServitoMinPrima(valoreParametro.getValInteger());
					break;
				case "mobmessaggioservitomindopo":
					wsp.setMobMessaggioServitoMinDopo(valoreParametro.getValInteger());
					break;
				// V2
				case "mobcapprenotazione":
					wsp.setMobCapPrenotazione(valoreParametro.getValInteger());
					break;
				case "mobcapannullamento":
					wsp.setMobCapAnnullamento(valoreParametro.getValInteger());
					break;
				case "mobminutiscadenza":
					wsp.setMobMinutiScadenza(valoreParametro.getValInteger());
					break;
				case "mobminutiinibizioneslot":
					wsp.setMobMinutiInibizioneSlot(valoreParametro.getValInteger());
					break;
				case "mobdisabilitaprenotazionesenzatouchpoint":
					wsp.setMobDisabilitaPrenotazioneSenzaTouchpoint(valoreParametro.isValBooleano());
					break;
				// V3
				case "mobnumgiornifuturiprenotazione":
					wsp.setMobNumGiorniFuturiPrenotazione(valoreParametro.getValInteger());
					break;
				case "moburlpan":
					wsp.setMobUrlPan(valoreParametro.getValStringa());
					break;
				case "moboffseterrorpan":
					wsp.setMobOffsetErrorPan(valoreParametro.getValInteger());
					break;
				}
			}
			wsParams = wsp;
			wsParamsLastUpd = now;

		}
		return wsp;

	}

	public StatCache getStatCache(Long salaId) {

//		Date now = new Date();
//		StatCache statCache = checkCacheTimeout(now, salaId);
//		if (statCache == null) {
//			Long timestamp = now.getTime() / 1000 - statCacheTimeoutSec;
//			TypedQuery<StatCache> queryStatCache = em.createNamedQuery("StatCache.findByIdAndTimestamp", StatCache.class).setParameter("id", salaId).setParameter("timestamp", timestamp);
//			statCache = getSingleResultOrNull(queryStatCache);
//			log.debug("getting stat cache for sala: " + salaId + " timestamp: " + timestamp + " null: " + (statCache == null ? "y" : "n"));
//			// if timestamp is too ahead in the future set it to now
//			if(statCache!=null && statCache.getTimestamp()>now.getTime() / 1000 + statCacheTimeoutSec){
//				log.warn("stat cache for sala: " + salaId + " is in the future, forcing timestamp: " + now.getTime()/1000);
//				statCache.setTimestamp(now.getTime()/1000);
//			}
//		}
//
//		return statCache;

		Date now = new Date();

		StatCache statCache = checkCacheTimeout(now, salaId);

		if (statCache == null) {
			Long timestamp = now.getTime() / 1000 - statCacheTimeoutSec;

			List<StatCache> queryStatCache = statCacheRep.findByIdAndTimestamp(salaId, timestamp);
			statCache = getSingleResultOrNull(queryStatCache);

			log.debug("getting stat cache for sala: " + salaId + " timestamp: " + timestamp + " null: "
					+ (statCache == null ? "y" : "n"));
			// if timestamp is too ahead in the future set it to now
			if (statCache != null && statCache.getTimestamp() > now.getTime() / 1000 + statCacheTimeoutSec) {
				log.warn("stat cache for sala: " + salaId + " is in the future, forcing timestamp: "
						+ now.getTime() / 1000);
				statCache.setTimestamp(now.getTime() / 1000);
			}
		}

		return statCache;
	}

	protected StatCache checkCacheTimeout(Date now, Long salaId) {

		// RICORDARSI DI VERIFICARE LA CACHE DI STATCACHE

//		StatCache statCache = (StatCache) ((JpaCache) emf.getCache()).getObject(StatCache.class, salaId);
//		log.debug("WS: salaId: " + salaId + " cached: " + (statCache != null));
//
//		if (statCache != null && ((now.getTime() / 1000 - statCache.getTimestamp())) > statCacheTimeoutSec) {
//			emf.getCache().evict(StatCache.class, statCache.getId());
//			log.debug("ES: Evicting cache for sala: " + statCache.getId());
//			statCache = null;
//		}
//		return statCache;

		return null;
	}

//	public static <T> T getSingleResultOrNull(TypedQuery<T> query) {
//		query.setMaxResults(1);
//		List<T> list = query.getResultList();
//		if (list.isEmpty()) {
//			return null;
//		}
//		return list.get(0);
//	
//	}

	public static <T> T getSingleResultOrNull(List<T> list) {

		return list.isEmpty() ? null : list.get(0);

	}

}
