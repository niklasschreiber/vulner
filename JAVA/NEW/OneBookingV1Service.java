package it.poste.onebooking.services;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.DateFormatUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import it.poste.ngav.dto.ProssimoTicketData;
import it.poste.ngav.dto.ProssimoTicketV2Data;
import it.poste.ngav.dto.WSTotemPTResponse;
import it.poste.ngav.dto.WsPmV4StatResponse;
import it.poste.ngav.exceptions.ProssimoTicketException;
import it.poste.ngav.exceptions.WsAppException;
import it.poste.ngav.mapper.ProssimoTicketMapper;
import it.poste.ngav.model.postgres.ProssimoTicket;
import it.poste.ngav.model.solariq.NgavOrario;
import it.poste.ngav.model.solariq.Sala;
import it.poste.ngav.model.solariq.SalaServizio;
import it.poste.ngav.model.solariq.Servizio;
import it.poste.ngav.repositories.postgres.ProssimoTicketRepository;
import it.poste.ngav.repositories.solariq.NgavFrazOrarioRepository;
import it.poste.ngav.services.ParameterService;
import it.poste.ngav.services.ProssimoTicketService;
import it.poste.ngav.utils.Costanti;
import it.poste.ngav.utils.Crypto;
import it.poste.ngav.utils.NgavUtils;
import it.poste.onebooking.dto.CfTrxIdQrCodeInfo;
import it.poste.onebooking.dto.DatiPrenotazione;
import it.poste.onebooking.dto.InfoTicketDispPTResponse;
import it.poste.onebooking.dto.InfoTicketResponse;
import it.poste.onebooking.dto.InfoUpResponse;
import it.poste.onebooking.dto.MacroservizioOBResponse;
import it.poste.onebooking.dto.OneBookingV1Response;
import it.poste.onebooking.dto.PrenotazioneTicketResponse;
import it.poste.onebooking.dto.ProssimoTicketV2OBResponse;
import it.poste.onebooking.dto.SlotsResponse;
import it.poste.onebooking.dto.WsPmV2SlotResponse;
import it.poste.onebooking.dto.WsPmV3StatResponse;
import it.poste.onebooking.exceptions.OBAppException;
import it.poste.onebooking.exceptions.OBAppException.ExCode;
import it.poste.onebooking.exceptions.OBWsAppException;
import it.poste.onebooking.exceptions.OBWsAppException.ErrorCode;
import it.poste.onebooking.model.solariq.ErrorMessageOB;
import it.poste.onebooking.model.solariq.Prenotazione;
import it.poste.onebooking.model.solariq.SalaOB;
import it.poste.onebooking.model.solariq.Slot;
import it.poste.onebooking.model.solariq.Touchpoint;
import it.poste.onebooking.services.MetricsService.MetricsTYPE;
import it.poste.onebooking.services.NewWsRateLimiter.EndPointKey;
import it.poste.onebooking.utils.MapUpGiorniAperti;
import it.poste.onebooking.utils.WsParams;
import lombok.extern.log4j.Log4j;

@Service
@Log4j
public class OneBookingV1Service {

	@Autowired
	SalaOBService salaOBService;

	@Autowired
	NewWsRateLimiter wsRateLimiter;

	@Autowired
	NewPmService pmService;

	@Autowired
	NewWsService wsService;

	@Autowired
	NewProxyService proxyService;

	@Autowired
	ErrorMessageOBService errorService;

	@Autowired
	TouchPointService tpServices;

	// Per prossimo ticket
	@Autowired
	ProssimoTicketService prossimoTicketService;

	@Autowired
	ParameterService paramsService;

	@Autowired
	TotemService totemService;

	@Autowired
	MetricsService metricsService;

	@Autowired
	MapUpGiorniAperti mapUpGiorniAperti;

	@Autowired
	ProssimoTicketRepository prossimoTicketRepository;

	@Autowired
	NgavFrazOrarioRepository ngavFrazOrarioRepository;

	///////////////////

	protected final String ORIGINE_MOBILE = "m";

	public SlotsResponse getSlots(String tpId, String userid, String fraz, Long idServizio, Date data, Long salaID,
			HttpServletRequest request) {
		log.info(
				"3.1 Called method /slots/tp/{tp_id}/user/{userid}/offices/{fraz}/servizio/{id_servizio}/date/{giorno} with tp_id: "
						+ tpId + " userid:" + userid + " frazionario: " + fraz + " id_servizio:" + idServizio
						+ " giorno:" + data.toString());

		// metricsService.getCounter(MetricsTYPE.SLOTS_COUNT_OB_NGA).increment();
//		metricsService.setDynamicMetrics(MetricsTYPE.SLOTS_COUNT_OB_NGA.getName(), null, "fraz", "tpId", "servOB", "userId", "giorno");
		metricsService.increment(MetricsTYPE.SLOTS_COUNT_OB_NGA, fraz, tpId, String.valueOf(idServizio), userid,
				data.toString());

		SlotsResponse response = null;
		ErrorMessageOB error = null;

		try {

			SalaOB salaOB = salaOBService.getSalaOB(salaID);
			wsRateLimiter.isRequestPermitted(request, NewWsRateLimiter.EndPointKey.TICKET, salaOB.getId());
			//////

			if (!mapUpGiorniAperti.GiornoPrenotabilePerUp(salaOB.getCodiceEsterno(), data)) {
				log.warn(String.format(
						"3.1 La cache dice Data prenotazione non valida per sala %1$s giorno %2$s ma ora si ricalcola la cache",
						salaOB.getCodiceEsterno(), data.toString()));
				getWsPmV3StatRespAndSetCacheGiorniUp(salaOB.getCodiceEsterno(), "xyz");
				if (!mapUpGiorniAperti.GiornoPrenotabilePerUp(salaOB.getCodiceEsterno(), data)) {
					error = errorService.findError(String.valueOf(ErrorCode.ERR_WRONG_DATE),
							Costanti.ServizioOneBooking);
					throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()),
							error.getMessaggio() + " " + data.toString());

					// throw new WsAppException(ErrorCode.ERR_WRONG_DATE, "Data prenotazione non
					// valida");
				}
			}

			WsPmV2SlotResponse wsPmResponseSlot = pmService.findSlotsBySalaServizioData(salaOB, idServizio, data, true);

			response = new SlotsResponse();

			response.setError(0);
			error = errorService.findError(String.valueOf(ErrorCode.OK), Costanti.ServizioOneBooking);
			response.setMessage(error.getMessaggio());
			if (wsPmResponseSlot != null) {
				response.setServiceLetter(wsPmResponseSlot.getServiceLetter());
				if (wsPmResponseSlot.getSlots() != null && wsPmResponseSlot.getSlots().size() > 0) {
					response.setSlots(wsPmResponseSlot.getSlots());
					// metricsService.getCounter(MetricsTYPE.SLOTS_COUNT_OB_NGA_OK).increment();
//					metricsService.setDynamicMetrics(MetricsTYPE.SLOTS_COUNT_OB_NGA_OK.getName(), null, "fraz", "tpId", "servOB", "userId", "giorno");
					metricsService.increment(MetricsTYPE.SLOTS_COUNT_OB_NGA_OK, fraz, tpId, String.valueOf(idServizio),
							userid, data.toString());
				} else {
					error = errorService.findError(String.valueOf(ErrorCode.ERR_SLOT_UNAVAILABLE),
							Costanti.ServizioOneBooking);
					throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()), error.getMessaggio());
				}
			}

		} catch (OBAppException ex) {
			// metricsService.getCounter(MetricsTYPE.SLOTS_COUNT_OB_NGA_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.SLOTS_COUNT_OB_NGA_KO.getName(), null, "fraz", "tpId", "servOB", "userId", "giorno");
			metricsService.increment(MetricsTYPE.SLOTS_COUNT_OB_NGA_KO, fraz, tpId, String.valueOf(idServizio), userid,
					data.toString());
			log.warn(String.format(
					"3.1 Called method /slots/tp/{tp_id}/user/{userid}/offices/{fraz}/servizio/{id_servizio}/date/{giorno} ERROR: %1$s",
					ex.getMessage()));
			if (ex instanceof OBWsAppException) {
				response = new SlotsResponse((OBWsAppException) ex);
			} else {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				response = new SlotsResponse(error.getId().getCodice(), error.getMessaggio());
				response.setMessage(ex.getMessage());
			}
		}

		return response;
	}

	public OneBookingV1Response getCancelTicket(String userId, Integer ticket_id, HttpServletRequest request) {
		ResponseEntity<OneBookingV1Response> responseEntiy = null;
		OneBookingV1Response wsPmResponse = null;
		Prenotazione prenotazione = null;
		String url = null;
		ErrorMessageOB error = null;

		log.info("6.1 Called method cancelTicket Nga with userid:" + userId + " ticketId: " + ticket_id);

		// metricsService.getCounter(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA).increment();
//		metricsService.setDynamicMetrics(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA.getName(), null, "userId", "univoco");
		metricsService.increment(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA, userId, String.valueOf(ticket_id));

		try {
			userId = md5UserId(userId);
			// pmService.checkUserAnnullamentoCap(ticket_id);
			prenotazione = pmService.getPrenotazioneByUnivoco(ticket_id);
			if (prenotazione == null) {
				String msg = "Prenotazione non trovata, codice: " + ticket_id;
				log.warn(msg);
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()), error.getMessaggio());
			}

			if (prenotazione.getDataAnnullamento() != null) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_PRENOTAZIONE_GIA_ANNULLATA),
						Costanti.ServizioOneBooking);
				throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()), error.getMessaggio());
			}

			wsRateLimiter.isRequestPermitted(request, EndPointKey.TICKET, prenotazione.getSala().getId());

			if (!StringUtils.equals(userId, prenotazione.getUtenteId())) {
				String msg = "Prenotazione non corrispondente all'utente: " + userId;
				log.error(msg);
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				throw new OBWsAppException(ErrorCode.ERR_GENERIC, msg);
			}

			url = prenotazione.getSala().getUrlMaster() + "/rpc/annullaprenotazione/" + prenotazione.getSala().getId()
					+ "/" + prenotazione.getServizio().getId() + "/" + prenotazione.getCodice() + "/" + ticket_id +
					// do not encode date, it causes strange double escape on the
					// receiver's side
					"/" + DateFormatUtils.ISO_DATETIME_TIME_ZONE_FORMAT.format(prenotazione.getDataInizio());

		} catch (OBAppException ex) {

			// metricsService.getCounter(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_KO.getName(), null, "userId", "univoco");
			metricsService.increment(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_KO, userId, String.valueOf(ticket_id));
			log.error(String.format("6.1 Called method cancelTicket Nga with userid:" + userId + " ticketId: "
					+ ticket_id + "ERROR: %1$s", ex.getMessage()));

			if (ex instanceof OBWsAppException) {
				wsPmResponse = new OneBookingV1Response((OBWsAppException) ex);
			} else if (ex.getExCode().equals(ExCode.exRateLimit)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_LIMIT_REACHED),
						Costanti.ServizioOneBooking);
				wsPmResponse = new OneBookingV1Response(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				wsPmResponse = new OneBookingV1Response(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
				log.error(ex.getMessage());
			}
		}

		if (wsPmResponse == null && url != null) {

			try {

				CompletableFuture<ResponseEntity<OneBookingV1Response>> doPostAsyncAnnullamento = proxyService
						.doPostAsyncAnnullamento(url, prenotazione.getId());
				responseEntiy = doPostAsyncAnnullamento.get();
				// metricsService.getCounter(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK).increment();
//				metricsService.setDynamicMetrics(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK.getName(), null, "userId", "univoco");
				metricsService.increment(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK, userId, String.valueOf(ticket_id));

			} catch (InterruptedException | ExecutionException e) {

				responseEntiy = new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
//				metricsService.setDynamicMetrics(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_KO.getName(), null, "userId", "univoco");
				metricsService.increment(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_KO, userId, String.valueOf(ticket_id));

			}

		} else {

			responseEntiy = new ResponseEntity<>(wsPmResponse, HttpStatus.OK);
			// metricsService.getCounter(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK.getName(), null, "userId", "univoco");
			metricsService.increment(MetricsTYPE.CANCEL_TICKET_COUNT_OB_NGA_OK, userId, String.valueOf(ticket_id));
		}

		return responseEntiy.getBody();
	}

	public PrenotazioneTicketResponse getTicketBySlot(String salaCodiceEsterno, String slotId, String userId,
			Date giornoPrenotazione, String touchpointId, String cf, String trxID, String qc,
			HttpServletRequest httpServletRequest) {

		PrenotazioneTicketResponse wsPmV4TicketResponse = null;
		DatiPrenotazione datiPrenotazione = null;
		ResponseEntity<PrenotazioneTicketResponse> responseEntiy = null;
		ErrorMessageOB error;
		String origine;
		String prefisso;

		// metricsService.getCounter(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA).increment();
//		metricsService.setDynamicMetrics(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA.getName(), null, "fraz", "tpId", "slotid", "userId", "ggprenotazione");
		metricsService.increment(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA, salaCodiceEsterno, touchpointId, slotId, userId,
				giornoPrenotazione.toString());

		try {

			userId = md5UserId(userId);

			// controllo sul giorno
			if (!mapUpGiorniAperti.GiornoPrenotabilePerUp(salaCodiceEsterno, giornoPrenotazione)) {
				log.warn(String.format(
						"4.1 La cache dice Data prenotazione non valida per sala %1$s giorno %2$s ma ora si ricalcola la cache",
						salaCodiceEsterno, giornoPrenotazione.toString()));

				getWsPmV3StatRespAndSetCacheGiorniUp(salaCodiceEsterno, "xyz");

				if (!mapUpGiorniAperti.GiornoPrenotabilePerUp(salaCodiceEsterno, giornoPrenotazione)) {
					error = errorService.findError(String.valueOf(ErrorCode.ERR_WRONG_DATE),
							Costanti.ServizioOneBooking);
					throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()),
							error.getMessaggio() + " " + giornoPrenotazione.toString());
				}

			}
			// check user cap
			// pmService.checkUserCap(userId, giornoPrenotazione);
			SalaOB sala = pmService.findSalaByCodiceEsterno(salaCodiceEsterno);
			wsRateLimiter.isRequestPermitted(httpServletRequest, EndPointKey.TICKET, sala.getId());
			Servizio servizio = pmService.getServizioForSlot(sala, slotId);
			Slot slot = pmService.getSlot(sala, servizio, slotId, giornoPrenotazione);

			if (slot == null) {
				// metricsService.getCounter(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO).increment();
//				metricsService.setDynamicMetrics(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO.getName(), null, "fraz", "tpId", "slotid", "userId", "ggprenotazione");
				metricsService.increment(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO, salaCodiceEsterno, touchpointId,
						slotId, userId, giornoPrenotazione.toString());
				error = errorService.findError(String.valueOf(ErrorCode.ERR_SLOT_UNAVAILABLE),
						Costanti.ServizioOneBooking);
				throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio() + " " + giornoPrenotazione.toString());
			}

			pmService.checkFasciaInibizione(sala, slot, giornoPrenotazione);

			if (touchpointId != null) {

				Touchpoint touchpoint = tpServices.checkTPValid(touchpointId);

				// non dovrebbe mai essere vuota, ma per sicurezza uso m per dafault
				origine = StringUtils.defaultIfEmpty(touchpoint.getOrigine(), ORIGINE_MOBILE);

				// non dovrebbe mai essere vuota, ma per sicurezza uso M per dafault
				prefisso = StringUtils.defaultIfEmpty(touchpoint.getPrefisso().getId(), NewPmService.PREFISSO_MOBILE);

			} else {

				WsParams wsParams = wsService.getParamsCache();

				if (true == wsParams.isMobDisabilitaPrenotazioneSenzaTouchpoint()) {
					error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
					throw new OBWsAppException(Integer.valueOf(error.getId().getCodice()),
							error.getMessaggio() + " " + giornoPrenotazione.toString());
				} else {
					origine = ORIGINE_MOBILE;
					prefisso = NewPmService.PREFISSO_MOBILE;
				}

			}

			datiPrenotazione = pmService.createPrenotazione(sala, servizio, slot, giornoPrenotazione, slotId, userId,
					origine, touchpointId, prefisso, "");

			if (datiPrenotazione != null && datiPrenotazione.getPrenotazione() != null) {

				CfTrxIdQrCodeInfo cfInfo = new CfTrxIdQrCodeInfo(cf, trxID, qc);

				CompletableFuture<ResponseEntity<PrenotazioneTicketResponse>> doPostAsyncAnnullamento = proxyService
						.doPostAsyncPrenotazioneWithCf(datiPrenotazione, cfInfo);

				responseEntiy = doPostAsyncAnnullamento.get();
				// metricsService.getCounter(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_OK).increment();
//				metricsService.setDynamicMetrics(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_OK.getName(), null, "fraz", "tpId", "slotid", "userId", "ggprenotazione");
				metricsService.increment(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_OK, salaCodiceEsterno, touchpointId,
						slotId, userId, giornoPrenotazione.toString());
			}

		} catch (InterruptedException | ExecutionException e) {
			// metricsService.getCounter(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO.getName(), null, "fraz", "tpId", "slotid", "userId", "ggprenotazione");
			metricsService.increment(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO, salaCodiceEsterno, touchpointId, slotId,
					userId, giornoPrenotazione.toString());
			log.error(e.getMessage(), e);
			responseEntiy = new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);

		} catch (OBWsAppException ex) {
			// metricsService.getCounter(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO.getName(), null, "fraz", "tpId", "slotid", "userId", "ggprenotazione");
			metricsService.increment(MetricsTYPE.PRENOTAZIONE_COUNT_OB_NGA_KO, salaCodiceEsterno, touchpointId, slotId,
					userId, giornoPrenotazione.toString());
			log.error("Errore: " + ex.getMessage());

			if (ex.getErrorCode().equals(ErrorCode.ERR_SLOT_UNAVAILABLE)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_SLOT_UNAVAILABLE),
						Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else if (ex.getErrorCode().equals(ErrorCode.ERR_LIMIT_REACHED)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_LIMIT_REACHED),
						Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else if (ex.getErrorCode().equals(ErrorCode.ERR_TOUCHPOINT_NOT_FOUND)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_TOUCHPOINT_NOT_FOUND),
						Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else if (ex.getErrorCode().equals(ErrorCode.ERR_TOUCHPOINT_DISABLED)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_TOUCHPOINT_DISABLED),
						Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else if (ex.getErrorCode().equals(ErrorCode.ERR_UP_DISABLED)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_UP_DISABLED), Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else if (ex.getErrorCode().equals(ErrorCode.ERR_WRONG_DATE)) {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_WRONG_DATE), Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			} else {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				wsPmV4TicketResponse = new PrenotazioneTicketResponse(Integer.valueOf(error.getId().getCodice()),
						error.getMessaggio());
			}

			responseEntiy = new ResponseEntity<>(wsPmV4TicketResponse, HttpStatus.OK);
		}

		return responseEntiy.getBody();

	}

	public ProssimoTicketV2OBResponse getProssimoTicket(String touchpoint_id, String user_id, Sala sala,
			String id_servizio, String cf, String trxID, String qc, String greenpass,
			MacroservizioOBResponse macroservizio) {

		log.info("Parametri input - frazionario: " + sala.getCodice_esterno() + ", user_id: " + user_id
				+ " , touchpoint_id: " + touchpoint_id + ", id_servizio: " + id_servizio);
		log.info("Parametri QueryString input - cf: " + cf + ", trxID: " + trxID + " , qc: " + qc + " , greenpass:"
				+ greenpass);

		ProssimoTicket prossimoTicket = null;
		ProssimoTicketData data = new ProssimoTicketData();
		ProssimoTicketV2Data dataV2 = new ProssimoTicketV2Data();

		try {

			log.info("Sala - id: " + sala.getId());
			log.info("Sala - url master: " + sala.getUrl_master());
			log.info("Sala - id servizio: " + sala.getIdServizio());
			log.info("Sala - descrizione servizio: " + sala.getDescrizioneServizio());
			log.info("Sala - lettera servizio: " + sala.getLetteraServizio());
			log.info("Sala - isLight: " + sala.getIs_light());

			// 2 CONTROLLO - id servizio -recuperare id_servizio dalla cache se non arriva
			// dal client, altrimenti invio messaggio errore
			// 55= Servizio non trovato
			SalaServizio salaServizio = null;
			String letteraServizio = null;
			String descrizioneServizio = null;
			Long idServizioLong = null;
			String sSeparatoreGUID = "";
			String guiID = "";
			boolean bInvitoALogin = false;

			if (id_servizio == null) {
				// altrimenti lo recupero
				int recuperaServizioInCache = paramsService.getRecuperaServizioInCache();
				if (1 == recuperaServizioInCache) {
					if (sala != null && sala.getIdServizio() != null && ((long) sala.getIdServizio() != (long) 0L)) {
						id_servizio = String.valueOf(sala.getIdServizio());
						letteraServizio = sala.getLetteraServizio();
						descrizioneServizio = sala.getDescrizioneServizio();
						idServizioLong = sala.getIdServizio();
					} else {
						log.error(
								"Impossibile recuperare l'id servizio per il frazionario: " + sala.getCodice_esterno());
						throw new ProssimoTicketException(Costanti.ServiceNotFound, errorService
								.findError(Costanti.ServiceNotFound, Costanti.ServizioOneBooking).getMessaggio());
					}
				} else {
					salaServizio = prossimoTicketService.calcoloIdServizio(sala.getId());
					if (salaServizio != null) {
						id_servizio = String.valueOf(salaServizio.getServizio_id());
						letteraServizio = salaServizio.getCodice();
						descrizioneServizio = salaServizio.getDescr();
						idServizioLong = salaServizio.getServizio_id();
					} else {
						log.error(
								"Impossibile recuperare l'id servizio per il frazionario: " + sala.getCodice_esterno());
						throw new ProssimoTicketException(Costanti.ServiceNotFound, errorService
								.findError(Costanti.ServiceNotFound, Costanti.ServizioOneBooking).getMessaggio());
					}

				}
			} else {
				salaServizio = prossimoTicketService.getInfoServizio(sala.getId(), Long.parseLong(id_servizio));
				id_servizio = String.valueOf(salaServizio.getServizio_id());
				letteraServizio = salaServizio.getCodice();
				descrizioneServizio = salaServizio.getDescr();
				idServizioLong = salaServizio.getServizio_id();

			}

			// 3 CONTROLLO ORARI APERTURA E CHIUSURA UFFICI POSTALI - verifica che l’orario
			// della data richiesta emissione ticket sia inferiore all’orario di chiusura
			// ufficio – offset (offset parametro espresso in secondi). Esempio se l’UP
			// presenta la chiusura alle 19 e l’offset è di 300 secondi, possiamo accettare
			// richieste di prossimo ticket provenienti prima delle 18:55.
			// 56= Impossibile richiedere la prenotazione ticket al di fuori dell’orario di
			// apertura ufficio
			controlloOrarioByFrazionario(sala.getCodice_esterno());

			// 4 CONTROLLO INPUT controllo num max richieste ticket per user_id
			// 52= Numero massimo di prenotazioni effettuate
			controlloCapUtente(user_id);

			// 5 MESSAGGIO ERRORE SE VA IN TIMEOUT LA CHIAMATA AL TOTEM

			// CHIAMATA TOTEM
			WSTotemPTResponse totemResponse = new WSTotemPTResponse();
			if (cf != null && trxID != null) {
				sSeparatoreGUID = paramsService.getSeparatoreGUID();
				cf = Crypto.encrypt(cf, paramsService.getCryptoIteration());
				guiID = sSeparatoreGUID + cf + sSeparatoreGUID + trxID + sSeparatoreGUID + "CP";
				// guiID = Crypto.encodeUrlString(guiID);
			}
			try {
				totemResponse = totemService.chiamataTotemCreaTicket(sala, id_servizio, touchpoint_id, guiID, qc,
						greenpass); // con nuovi parametri se il FW è a nuovo
				bInvitoALogin = true;
			} catch (Exception e) {
				if (e instanceof Exception && e.getMessage().equals(String.valueOf(HttpStatus.NOT_FOUND))) {
					log.info("Chiamo Prossimo Ticket su vecchio metodo.Probabilmente Totem Non aggiornato.");
					totemResponse = totemService.chiamataTotemProssimoTicket(sala, id_servizio, touchpoint_id); // senza
																												// nuovi
																												// parametri
																												// se il
																												// FW è
																												// a
																												// vecchio
				}
			}

			ProssimoTicketMapper prossimoTicketMapper = new ProssimoTicketMapper();

			data = prossimoTicketMapper.convertToProssimoTicketData(totemResponse, sala, idServizioLong,
					letteraServizio, descrizioneServizio);
			dataV2.mapOldBean(data);
			dataV2.setInvitoLogin(bInvitoALogin);

			prossimoTicket = new ProssimoTicket();
			prossimoTicket.setUser_id(user_id);
			prossimoTicket.setFrazionario(sala.getCodice_esterno());
			prossimoTicket.setNum_ticket(totemResponse.getCodice());
			prossimoTicket.setData_richiesta(new Date());
			prossimoTicket.setData_stampa(totemResponse.getDataStampa());
			prossimoTicket.setId_servizio(idServizioLong);
			prossimoTicket.setDesc_servizio(descrizioneServizio);
			prossimoTicket.setLettera_servizio(letteraServizio);
			prossimoTicket.setTouchpoint_id(touchpoint_id);

			log.info("ID SERVIZIO: " + prossimoTicket.getId_servizio());

			// SALVATAGGIO SULLA TABELLA PROSSIMO_TICKET
			prossimoTicket = prossimoTicketService.saveProssimoTicket(prossimoTicket);
			log.info("Prossimo ticket salvato correttamente");
//			metricsService.setDynamicMetrics(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_OK.getName(), null, "fraz", "tpId", "servOB", "userID");
			metricsService.increment(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_OK, sala.getCodice_esterno(), touchpoint_id,
					id_servizio, user_id);

		} catch (ProssimoTicketException e) {
			// metricsService.getCounter(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO.getName(), null, "fraz", "tpId", "servOB", "userID");
			metricsService.increment(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO, sala.getCodice_esterno(), touchpoint_id,
					id_servizio, user_id);
			log.error("{frazionario}:" + sala.getCodice_esterno() + " {user}:" + user_id + "  {touchpoint}:"
					+ touchpoint_id + "  {servizio}:" + id_servizio);
			return ProssimoTicketV2OBResponse.createResponse(e);
		} catch (Throwable t) {
			// 6 ERRORE
			// metricsService.getCounter(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO.getName(), null, "fraz", "tpId", "servOB", "userID");
			metricsService.increment(MetricsTYPE.PROSSIMO_TICKET_CREATICKET_KO, sala.getCodice_esterno(), touchpoint_id,
					id_servizio, user_id);
			log.error("{frazionario}:" + sala.getCodice_esterno() + " {user}:" + user_id + "  {touchpoint}:"
					+ touchpoint_id + "  {servizio}:" + id_servizio);
			log.error(t.getMessage());
			ErrorMessageOB error = errorService.findError(Costanti.UnknownError, Costanti.ServizioOneBooking);

			return ProssimoTicketV2OBResponse
					.createResponse(new ProssimoTicketException(error.getId().getCodice(), error.getMessaggio()));
		}

		ProssimoTicketV2OBResponse response = ProssimoTicketV2OBResponse.createResponse(dataV2);
		response.setDescrizioneTicket(macroservizio.getDescrizioneTicket());

		return response;
	}

	public InfoTicketResponse getInfoTickets(Sala sala, String idServizio, String userid, HttpServletRequest request,
			MacroservizioOBResponse macroservizio) {
		ErrorMessageOB error;
		String userId = Crypto.md5UserId(userid);
		log.info(String.format("2.1 Called method getInfoTickets: fraz:%1$s - idservizio:%2$s - userid:%3$s",
				sala.getCodice_esterno(), idServizio, userId));

		// metricsService.getCounter(MetricsTYPE.INFO_TICKET_NGA).increment();
//		metricsService.setDynamicMetrics(MetricsTYPE.INFO_TICKET_NGA.getName(), null, "fraz", "serv", "userId");
		metricsService.increment(MetricsTYPE.INFO_TICKET_NGA, sala.getCodice_esterno(), idServizio, userid);

		WsPmV4StatResponse response = new WsPmV4StatResponse();
		InfoTicketResponse responseAll = new InfoTicketResponse();

		Integer numGiorniFuturi = wsService.getParamsCache().getMobNumGiorniFuturiPrenotazione();
		SalaOB salaOB = null;
		DateTimeFormatter newSdf = DateTimeFormatter.ofPattern("yyyy-MM-dd");

		try {
			userId = md5UserId(userId);
			salaOB = salaOBService.getSalaOB(sala.getId());
			wsRateLimiter.isRequestPermitted(request, NewWsRateLimiter.EndPointKey.TICKET, salaOB.getId());

			response.setName(salaOB.getDescr());
			response.setNumGiorniFuturi(numGiorniFuturi);
			response.setCode(salaOB.getCodiceEsterno());
			log.debug(String.format("2.1 Called method getInfoTickets: Aggancio Ufficio: %1$s - user:%2$s ",
					salaOB.getCodiceEsterno() + "/" + salaOB.getDescr(), userId));

			List<it.poste.onebooking.dto.WsPmCapUtente> listCapUtente = pmService.calcCapUtenteList(salaOB, userid,
					numGiorniFuturi, null);
			log.debug(String.format("2.1 Called method getInfoTickets: Aggancio lista CapUtente: %1$s - user:%2$s ",
					"Count:" + (listCapUtente != null ? String.valueOf(listCapUtente.size()) : "0"), userId));

			responseAll.setFrazionario(response.getCode());
			responseAll.setDescrizione(response.getName());
			InfoUpResponse up = new InfoUpResponse();
			List<InfoTicketDispPTResponse> listTicketDisponibiliPT = new ArrayList<InfoTicketDispPTResponse>();

			listCapUtente.forEach(cap -> {
				InfoTicketDispPTResponse disp = new InfoTicketDispPTResponse();
				disp.setTktDisponibili(cap.getTktDisponibili());
				disp.setStatoUP(cap.getStatoUP());

				// controllo con data inizio e fine validita macroservizio
				macroservizio.getInizioValidita();

				if (LocalDate.parse(cap.getGiorno(), newSdf)
						.isAfter(LocalDate.parse(macroservizio.getInizioValidita().toString(), newSdf))
						&& LocalDate.parse(cap.getGiorno(), newSdf)
								.isBefore(LocalDate.parse(macroservizio.getFineValidita().toString(), newSdf))) {
					disp.setStatoServizio(1); // da verificare da configurazione di validità del servizio in OB
				} else {
					disp.setStatoServizio(0); // da verificare da configurazione di validità del servizio in OB
				}

				LocalDate nuovaData = LocalDate.parse(cap.getGiorno(), newSdf);
				disp.setGiorno(nuovaData);

				listTicketDisponibiliPT.add(disp);

			});
			up.setTktDisponibiliPT(listTicketDisponibiliPT);
			up.setTktDisponibiliMF(prossimoTicketService.controlloCapUtenteV2(userId));
			responseAll.setInfoUP(up);

			// metricsService.getCounter(MetricsTYPE.INFO_TICKET_NGA_OK).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.INFO_TICKET_NGA_OK.getName(), null, "fraz", "serv", "userId");
			metricsService.increment(MetricsTYPE.INFO_TICKET_NGA_OK, sala.getCodice_esterno(), idServizio, userid);

		} catch (Exception ex) {
			// metricsService.getCounter(MetricsTYPE.INFO_TICKET_NGAV_KO).increment();
//			metricsService.setDynamicMetrics(MetricsTYPE.INFO_TICKET_NGA_KO.getName(), null, "fraz", "serv", "userId");
			metricsService.increment(MetricsTYPE.INFO_TICKET_NGA_KO, sala.getCodice_esterno(), idServizio, userid);
			log.warn(String.format("2.1 Called method getInfoTickets ERROR: %1$s", ex.getMessage()));
			if (ex instanceof WsAppException) {
				responseAll = new InfoTicketResponse();
				// response = new InfoTicketResponse((WsAppException) ex);
			} else {
				error = errorService.findError(String.valueOf(ErrorCode.ERR_GENERIC), Costanti.ServizioOneBooking);
				responseAll = new InfoTicketResponse(Integer.valueOf(error.getId().getCodice()), error.getMessaggio());
			}
		}

		if (log.isDebugEnabled()) {
			try {
				ObjectMapper objectMapper = new ObjectMapper();
				log.debug(String.format("1.Called method Lista Servizi: %1$s - user:%2$s - JSON ==> %3$s",
						salaOB.getCodiceEsterno(), userId, objectMapper.writeValueAsString(response)));
			} catch (JsonProcessingException e) {
				log.debug("Errore nella stampa del json di risposta.");
			}
		}

		log.debug(String.format("1.Called method Lista Servizi: Response CapU: %1$s - user:%2$s ",
				"Count:" + response.getCapUtente().size(), userId));
		return responseAll;
	}

	public WsPmV3StatResponse getWsPmV3StatRespAndSetCacheGiorniUp(String salaCodiceEsterno, String userId)
			throws OBWsAppException {

		SalaOB sala = pmService.findSalaByCodiceEsterno(salaCodiceEsterno);
		WsPmV3StatResponse wsPmV3StatResp = new WsPmV3StatResponse(); // pmService.getWsPmV3Stat(sala.getId());
		// cap utente
		Integer numGiorniFuturi = wsService.getParamsCache().getMobNumGiorniFuturiPrenotazione();
		wsPmV3StatResp.setNumGiorniFuturi(numGiorniFuturi);
		wsPmV3StatResp.setCapUtente(pmService.calcCapUtenteList(sala, userId, numGiorniFuturi, null));
		// ALIMENTO LA CACHE DEI GIORNI UTILIZZABILI SULL'UP.
		mapUpGiorniAperti.ImpostaGiorniPerUp(salaCodiceEsterno, wsPmV3StatResp.getCapUtente());
		return wsPmV3StatResp;

	}

	private String md5UserId(String user_id) {
		return DigestUtils.md5Hex("POSTESOLARI$$%$$SOLARIPOSTE" + user_id).toUpperCase();
	}

	public int calcCapUtentePrenotazione(String userID, Date dataPrenotazione) throws OBWsAppException {
		int iCount = 0;
		String user = md5UserId(userID);
		iCount = pmService.checkUserCap(user, dataPrenotazione);

		return iCount;
	}

	public int calcCapUtenteAnnulloPrenotazione(String userID) throws OBWsAppException {
		int iCount = 0;
		String user = md5UserId(userID);
		iCount = pmService.checkUserAnnullamentoCap(user);

		return iCount;
	}

	private int controlloCapUtente(String user_id) throws ProssimoTicketException {
		List<ProssimoTicket> listaTicket = prossimoTicketRepository.findTicketsByUserId(user_id);
		log.info("Ticket richiesti : " + listaTicket.size());
		if (listaTicket.size() >= paramsService.getCacheNumMaxProssimoTicket().intValue()) {
			log.info("Numero massimo di prenotazioni effettuate - prenotazioni già effettuate: " + listaTicket.size());
			throw new ProssimoTicketException(Costanti.ErrorLimitReserve,
					errorService.findError(Costanti.ErrorLimitReserve, Costanti.ServizioOneBooking).getMessaggio());
		}

		return paramsService.getCacheNumMaxProssimoTicket().intValue() - listaTicket.size();
	}

	private void controlloOrarioByFrazionario(String frazionario) throws ProssimoTicketException {
		boolean prosegui = true;
		List<NgavOrario> frazOrario = null;
		try {
			LocalDate nuovaData = LocalDate.now();
			Date toDay = NgavUtils.convertToDate(nuovaData);
			frazOrario = ngavFrazOrarioRepository.findByFrazionarioGiornoPrenotazione(frazionario, toDay);
			if (frazOrario != null && frazOrario.size() > 0) {
				NgavOrario orario = frazOrario.get(0);
				Calendar calendarA = NgavUtils.setNow(orario.getOrario_ingresso());
				Calendar calendarC = NgavUtils.setNow(orario.getOrario_uscita());

				Integer offsetIngresso = paramsService.getOffsetOrarioIngresso();
				calendarA.add(Calendar.SECOND, -offsetIngresso);

				Integer offsetUscita = paramsService.getOffsetOrarioUscita();
				calendarC.add(Calendar.SECOND, -offsetUscita);

				Date now = Calendar.getInstance().getTime();

				// ORARIO APERURA
				if (now.before(calendarA.getTime())) {
					prosegui = false;
					log.error(
							"Impossibile richiedere la prenotazione ticket al di fuori dell’orario di apertura ufficio");
				}

				// ORARIO CHIUSURA
				if (now.after(calendarC.getTime())) {
					prosegui = false;
					log.error(
							"Impossibile richiedere la prenotazione ticket al di fuori dell’orario di apertura ufficio");
				}

			}
		} catch (Exception e) {
			log.error(e);
			throw new ProssimoTicketException(Costanti.UnknownError,
					errorService.findError(Costanti.UnknownError, Costanti.ServizioOneBooking).getMessaggio());
		}

		if (prosegui == false || frazOrario == null || (frazOrario != null && frazOrario.isEmpty())) {
			throw new ProssimoTicketException(Costanti.PostOfficeClose, errorService
					.findError(Costanti.PostOfficeClose, Costanti.ServizioOneBooking).getMessaggio());
		}
	}

}
