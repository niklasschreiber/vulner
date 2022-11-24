package it.posteitaliane.nga.service.impl;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.transaction.Transactional;

import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import it.posteitaliane.nga.converter.MacroServizioConverter;
import it.posteitaliane.nga.dto.MacroservizioDTO;
import it.posteitaliane.nga.dto.PreviewRequestDTO;
import it.posteitaliane.nga.dto.ProdottoCodice;
import it.posteitaliane.nga.dto.UserDTO;
import it.posteitaliane.nga.dto.preview.ServizioCatalogoDTO;
import it.posteitaliane.nga.ex.NgaException;
import it.posteitaliane.nga.ex.NgaException.NGAExceptionType;
import it.posteitaliane.nga.model.ObMacroservizio;
import it.posteitaliane.nga.model.ObServizioCanale;
import it.posteitaliane.nga.model.ObServizioCanaleId;
import it.posteitaliane.nga.model.ObServizioSfa;
import it.posteitaliane.nga.model.ServizioCanaleIdPK;
import it.posteitaliane.nga.repository.MacroservizioRepository;
import it.posteitaliane.nga.repository.ServiziCacheRepository;
import it.posteitaliane.nga.repository.ServiziCacheRepository.ServiziCacheTYPE;
import it.posteitaliane.nga.repository.ServizioCanaleIdRepository;
import it.posteitaliane.nga.repository.ServizioCanaleRepository;
import it.posteitaliane.nga.repository.SfaRepository;
import it.posteitaliane.nga.service.EntityService;
import it.posteitaliane.nga.specification.SpecificationUtils;
import it.posteitaliane.nga.utils.AppConsts;
import it.posteitaliane.nga.utils.MacroservizioUtils;
import it.posteitaliane.nga.utils.Utils;
import it.posteitaliane.nga.vo.UfficioCacheOB;

@Service
public class MacroServizioServiceImpl implements EntityService<ObMacroservizio> {

	@Autowired
	Logger logger;

	@Autowired
	MacroservizioRepository macroServizioRepo;

	@Autowired
	ServizioCanaleRepository canaleServizioRepo;
	
	@Autowired
	ServizioCanaleIdRepository servCanaleIdRep;

	@Autowired
	ServiziCacheRepository serviziCacheRepository;
	
	@Autowired
	SfaRepository sfaRepository;

	@Autowired
	CanaleServiceImpl canaleService;

	@Autowired
	CanaleIdServiceImpl canaleIdService;

	@Autowired
	MapperServiceImpl mapper;

	@Override
	public ObMacroservizio findOne(Long id) throws NgaException {

		if (id == null)
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);

		Optional<ObMacroservizio> macroServ = macroServizioRepo.findById(id);

		if (!macroServ.isPresent())
			throw new NgaException(NGAExceptionType.NOT_FOUND);

		return macroServ.get();

	}

	@Override
	@Transactional
	public ObMacroservizio save(ObMacroservizio entity) throws NgaException {

		if (entity == null || entity.getId() != null)
			throw new NgaException(NGAExceptionType.ERRORE_GENERICO);
		return macroServizioRepo.save(entity);

	}

	@Override
	public ObMacroservizio update(ObMacroservizio entity) throws NgaException {

		if (entity == null || entity.getId() == null)
			throw new NgaException(NGAExceptionType.ERRORE_GENERICO);

		Optional<ObMacroservizio> macroServ = macroServizioRepo.findById(entity.getId());

		if (!macroServ.isPresent())
			throw new NgaException(NGAExceptionType.NOT_FOUND);

		return macroServizioRepo.save(entity);

	}

	@Override
	@Transactional
	public void delete(Long id) throws NgaException {

		if (id == null)
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);

		Optional<ObMacroservizio> macroServ = macroServizioRepo.findById(id);

		if (!macroServ.isPresent())
			throw new NgaException(NGAExceptionType.NOT_FOUND);

		String codProd = macroServ.get().getCodProd();
		List<ObMacroservizio> findByCodProd = macroServizioRepo.findByCodProd(codProd);
		if (findByCodProd.stream().filter(el -> !el.getId().equals(id)).count() == 0) {

			servCanaleIdRep.deleteByCodProdotto(codProd);
			canaleServizioRepo.deleteByCodProdotto(codProd);

		}

		macroServizioRepo.deleteById(id);

	}

	@Override
	public List<ObMacroservizio> findAll(Specification<ObMacroservizio> specification) {
		return macroServizioRepo.findAll(SpecificationUtils.getMacroservizioSpecification(null, null, null));
	}

	@Override
	public Page<ObMacroservizio> findAll(int numPagina, int numElementiPerPagina) {
		Pageable pageable = PageRequest.of(numPagina, numElementiPerPagina, Direction.ASC, "codProd");
		return macroServizioRepo.findAll(SpecificationUtils.getMacroservizioSpecification(null, null, null), pageable);
	}

	@Override
	public List<ObMacroservizio> findAll() throws NgaException {
		return macroServizioRepo.findAll(SpecificationUtils.getMacroservizioSpecification(null, null, null));
	}

	public List<ObMacroservizio> findProdottiSchedulatiByCodProd(String codProd) {
		return macroServizioRepo.getProdottiSchedulatiByCodProd(codProd);
	}

	public ObMacroservizio findProdottiSfaAssociati(String id) {
		return macroServizioRepo.getServizioSfaCatalogoAssociati(id);
	}

	public ObMacroservizio findProdottoCatalogo(String id) {
		return macroServizioRepo.getServizioCatalogo(id);
	}

//	public ObMacroservizio findProdottoCatalogoByID(Long id) {
//		return macroServizioRepo.getServizioCatalogoByID(id);
//	}

	public ObMacroservizio getDescProdottoPadre(String codPadre) {
		return macroServizioRepo.getServizioDescPadre(codPadre);
	}

	public List<ObMacroservizio> findProdottoPadre() {
		return macroServizioRepo.getServiziPadre();
	}

	public List<ObMacroservizio> findProdottiFratelli(String codProd) {
		if (codProd != null) {
			return macroServizioRepo.getServiziFratelli(codProd);
		} else {
			return macroServizioRepo.getServiziFratelliPrimoLivello();
		}
	}

	public String[] findCanaleServizio(String id) {
		return canaleServizioRepo.getCanaleServizio(id);
	}

	public Page<ObMacroservizio> findAll(Integer numPagina, Integer numElementiPerPagina, String descrizione,
			String descrizionePadre, List<String> stati, String sortDirection, String sortElement) {

		Direction dir = Utils.isBlankOrNull(sortDirection) || sortDirection.equals(Direction.ASC.toString())
				? Direction.ASC
				: Direction.DESC;

		sortElement = !Utils.isBlankOrNull(sortDirection) && sortElement != null ? sortElement : "codProd";

		Pageable pageable = PageRequest.of(numPagina, numElementiPerPagina, dir, sortElement);

		return macroServizioRepo.findAll(
				SpecificationUtils.getMacroservizioSpecification(descrizione, descrizionePadre, stati), pageable);
	}

	public List<ObMacroservizio> findAll(String descrizione, String descrizionePadre, List<String> stati) {

		return macroServizioRepo
				.findAll(SpecificationUtils.getMacroservizioSpecification(descrizione, descrizionePadre, stati));
	}

	@Transactional
	public ObMacroservizio modificaProdotto(MacroservizioDTO dto, UserDTO user) throws NgaException {

		ObMacroservizio macroservizio = findOne(dto.getId());

		if (MacroservizioUtils.isClosed(macroservizio)) {
			throw new NgaException(NGAExceptionType.MODIFICA_SERVIZIO_CHIUSO);
		}

		if (MacroservizioUtils.isScheduled(macroservizio)) {

			macroservizio = modificaServizioSchedulato(dto, user, macroservizio);

		} else {

			macroservizio = modificaServizioAttivo(dto, user, macroservizio);

		}

		return macroservizio;

	}

	private ObMacroservizio modificaServizioAttivo(MacroservizioDTO dto, UserDTO user, ObMacroservizio macroservizio)
			throws NgaException {
		checkProdottiSchedulatiPresenti(macroservizio.getCodProd());

		LocalDate dateBefore = dto.getDataInizioValidita().minusDays(1);
		macroservizio.setDataFineValidita(dateBefore);

		macroservizio = update(macroservizio);

		ObMacroservizio scheduled = mapMacroservizio(dto, new ObMacroservizio());
		scheduled.setCodProd(macroservizio.getCodProd());
		scheduled.setOrdinamento(dto.getOrdinamento());
		scheduled.setTipoServizio(macroservizio.getTipoServizio());
		scheduled.setTsInserimento(Timestamp.from(Instant.now()));
		scheduled.setTsAggiornamento(Timestamp.from(Instant.now()));
		scheduled.setUserInserimento(user.getUserid());
		scheduled.setUserAggiornamento(user.getUserid());
		save(scheduled);
		ordinamentoProdottiFratelli(dto);
		return macroservizio;
	}

	private ObMacroservizio modificaServizioSchedulato(MacroservizioDTO dto, UserDTO user,
			ObMacroservizio macroservizio) throws NgaException {
		if (macroservizio == null) {
			throw new NgaException(NGAExceptionType.NOT_FOUND);
		}

		macroservizio = mapMacroservizio(dto, macroservizio);
		macroservizio.setUserAggiornamento(user.getUserid());

		macroservizio = update(macroservizio);

		ordinamentoProdottiFratelli(dto);
		return macroservizio;
	}

	private ObMacroservizio mapMacroservizio(MacroservizioDTO data, ObMacroservizio macroservizio) {

		macroservizio.setDescrizioneMain(data.getDescrizioneMain());
		macroservizio.setDescrizioneSub(data.getDescrizioneSub());
		macroservizio.setDescrizioneTicket(data.getDescrizioneTicket());
		macroservizio.setDataInizioValidita(data.getDataInizioValidita());
		macroservizio.setDataFineValidita(data.getDataFineValidita() != null ? data.getDataFineValidita() : LocalDate.of(9999, 12, 31));
		macroservizio.setCodProdPadre(data.getCodProdPadre());
		macroservizio.setCategoria(data.getCategoria());

		if (data.getModalita() != null) {
			macroservizio.setModalita(String.join(",", data.getModalita()));
		}

		if (data.getPrenota() != null) {
			macroservizio.setPrenota(String.join(",", data.getPrenota()));
		}

		if (data.getPrioritaLettera() != null) {
			macroservizio.setPrioritaLettera(String.join(",", data.getPrioritaLettera()));
		}

		macroservizio.setRadicamento(data.getRadicamento());
		macroservizio.setClienteDriven(data.getClienteDriven());

		Timestamp now = Timestamp.from(Instant.now());
		macroservizio.setTsAggiornamento(now);

		return macroservizio;

	}

	@Transactional
	public ObMacroservizio inserisciProdotto(MacroservizioDTO data, String codiceProd,
			ObMacroservizio macroservizioActive, UserDTO user) throws NgaException {

		// record insert
		ObMacroservizio mapEntityFromDto = mapper.mapToEntity(data, ObMacroservizio.class,
				MacroServizioConverter.toEntity());
		
		if (mapEntityFromDto.getDataFineValidita() == null) {
			mapEntityFromDto.setDataFineValidita(LocalDate.of(9999, 12, 31));
		}

		mapEntityFromDto.setCodProd(codiceProd);
		mapEntityFromDto.setId(null);

		if (data.getPrenota() != null) {
			mapEntityFromDto.setPrenota(String.join(",", data.getPrenota()));
		}
		if (macroservizioActive != null) {
			mapEntityFromDto.setTipoServizio(macroservizioActive.getTipoServizio());
			mapEntityFromDto.setOrdinamento(macroservizioActive.getOrdinamento());
			mapEntityFromDto.setProdottiSFA(macroservizioActive.getProdottiSFA());
		}

		Timestamp now = Timestamp.from(Instant.now());
		mapEntityFromDto.setTsAggiornamento(now);
		mapEntityFromDto.setTsInserimento(now);

		if (data.getModalita() != null) {
			mapEntityFromDto.setModalita(String.join(",", data.getModalita()));
		}

		if (data.getPrioritaLettera() != null) {
			mapEntityFromDto.setPrioritaLettera(String.join(",", data.getPrioritaLettera()));
		}

		mapEntityFromDto.setUserInserimento(user.getUserid());
		mapEntityFromDto.setUserAggiornamento(user.getUserid());

		mapEntityFromDto = save(mapEntityFromDto);

		inserisciCanale(data, mapEntityFromDto);

		for (MacroservizioDTO dto : data.getProdottiFratelliOrdinati()) {
			if (dto.getId() == null) {
				dto.setId(mapEntityFromDto.getId());
				logger.info(dto.toString());
				break;
			}
		}

		ordinamentoProdottiFratelli(data);

		return mapEntityFromDto;
	}

	public void ordinamentoProdottiFratelli(MacroservizioDTO data) throws NgaException {

		// aggiornamento del campo ordinamento su tutti i prodotti fratelli
		if (data.getProdottiFratelliOrdinati() != null) {

			for (MacroservizioDTO dto : data.getProdottiFratelliOrdinati()) {
				
				if(dto.getId() == null) {
					continue;
				}
				
				Optional<ObMacroservizio> ms = macroServizioRepo.findById(dto.getId());

				if (ms.isPresent()) {
					ObMacroservizio obMacroservizio = ms.get();
					obMacroservizio.setOrdinamento(dto.getOrdinamento());
					obMacroservizio.setTsAggiornamento(Timestamp.from(Instant.now()));
					update(obMacroservizio);
				}
			}
		}

	}

	public void inserisciCanale(MacroservizioDTO data, ObMacroservizio obMacroservizio) throws NgaException {

		if (data.getCanale() == null) {
			data.setCanale(new String[] { AppConsts.GRP });
		}

		int i = 1;

		for (String canale : data.getCanale()) {

			ObServizioCanale obServizioCanale = new ObServizioCanale(obMacroservizio.getCodProd(), canale, i++);
			canaleService.save(obServizioCanale);

			ServizioCanaleIdPK id1 = new ServizioCanaleIdPK(obMacroservizio.getCodProd(), canale);

			switch (canale) {
			case AppConsts.SCO:
				ObServizioSfa servizioSfa = sfaRepository.findById(data.getProdottiSFA()).orElseThrow(NgaException::new);
				canaleIdService.save(new ObServizioCanaleId(id1, Long.valueOf(servizioSfa.getIdProdotto())));
				break;

			case AppConsts.SPO:
			case AppConsts.GRP:

				canaleIdService.save(new ObServizioCanaleId(id1));
				break;

			default:
				break;

			}

		}

	}

	public void checkProdottiSchedulatiPresenti(String codProd) throws NgaException {

		List<ObMacroservizio> listObMacroservizi = findProdottiSchedulatiByCodProd(codProd);

		if (!listObMacroservizi.isEmpty())
			throw new NgaException(NGAExceptionType.SERVIZIO_SCHEDULATO_PRESENTE);

	}

	public List<ObMacroservizio> findProdottiByCod(List<String> codProdList) {

		return macroServizioRepo.getServiziByCodProd(codProdList);

	}

	public List<ProdottoCodice> findIdProdottoByCodProd(List<String> codProdList) {

		return macroServizioRepo.getIdProdottoByCodProd(codProdList).stream()
				.map(item -> new ProdottoCodice((String) item[0], (String) item[1], (BigDecimal) item[2], (String) item[3])).collect(Collectors.toList());

	}

	public List<ServizioCatalogoDTO> anteprimaCatalogo(LocalDate giorno, String frazionario) {

		// 1. recupero i servizi attivi per il giorno
		List<ObMacroservizio> serviziAttiviPerGiorno = macroServizioRepo.findServiziAttiviPerGiorno(giorno);

		// 2. se esiste il frazionario recupero i servizi per il frazionario
		if (frazionario != null && !frazionario.trim().isEmpty()) {
			List<Object[]> allResult = serviziCacheRepository.getAllResult(frazionario);
			UfficioCacheOB serviziUfficio = mapServizi(allResult);
			// 3. caratterizzo il catalogo per l'UP
			serviziAttiviPerGiorno = caratterizzaServiziPerUP(serviziUfficio, serviziAttiviPerGiorno);
		}
		// 4. creo alberatura catalogo
		List<ServizioCatalogoDTO> catalogo = generaCatalogo(giorno, serviziAttiviPerGiorno);

		// 5. elimino i padri senza figli e gli elementi a sinistra non significativi
		catalogo = pulisciLivelliNonSignificativi(catalogo);

		catalogo = pulisciPadriSenzaFigli(catalogo);

		return catalogo;

	}

	private List<ObMacroservizio> caratterizzaServiziPerUP(UfficioCacheOB serviziUfficio,
			List<ObMacroservizio> serviziAttiviPerGiorno) {

		if (serviziAttiviPerGiorno == null) {
			return new ArrayList<ObMacroservizio>(0);
		}

		if (serviziUfficio == null) {
			return serviziAttiviPerGiorno;
		}

		Boolean isNGA = serviziUfficio.getNga();

		List<ObMacroservizio> res = new LinkedList<>();

		for (ObMacroservizio ms : serviziAttiviPerGiorno) {

			// se è un elemento padre lo aggiungo senza altre logiche
			if (ms.getTipoServizio().equals("P")) {
				res.add(ms);
				continue;
			}

			// se è una foglia
			if (ms.getTipoServizio().equals("F")) {

				// controllo se è un servizio prenotabile per la tipologia di ufficio altrimenti
				// viene scartato
				// se prenotabile = P

				List<String> prenotabile = Arrays.asList(ms.getPrenota().split(","));

				if (!prenotabile.contains("P") && isNGA) {
					continue;
				}

				if (!prenotabile.contains("V") && !isNGA) {
					continue;
				}

				ms.setVisibile("N");

				setVisibility(serviziUfficio, ms);

				res.add(ms);
			}

		}

		return res;

	}

	private void setVisibility(UfficioCacheOB serviziUfficio, ObMacroservizio ms) {

		List<ObServizioCanaleId> canaliIds = canaleIdService.getCanaleServizioId(ms.getCodProd());

		for (ObServizioCanaleId obServizioCanale : canaliIds) {

			switch (obServizioCanale.getId().getCanale()) {

			case "SPO":

				String[] lettere = ms.getPrioritaLettera().split(",");

				for (String lettera : lettere) {
					if (serviziUfficio.findServizioByLettera(lettera) != null) {
						ms.setVisibile("S");
						break;
					}
				}

				break;

			case "SCO":
				ms.setVisibile(serviziUfficio.findServizioByIdProdotto(obServizioCanale.getIdProdotto()) != null ? "S"
						: ms.getVisibile());
				break;

			default:
				break;
			}

		}

	}

	private List<Object[]> caratterizzaExcelPerUP(List<Object[]> serviziAttiviPerGiorno,
			UfficioCacheOB serviziUfficio) {

		if (serviziAttiviPerGiorno == null) {
			return new ArrayList<Object[]>(0);
		}

		if (serviziUfficio == null) {
			return serviziAttiviPerGiorno;
		}

		Boolean isNGA = serviziUfficio.getNga();

		return serviziAttiviPerGiorno.stream().filter(item -> {

			if ("PADRE".equalsIgnoreCase(String.valueOf(item[4])))
				return true;

			if ("FOGLIA".equalsIgnoreCase((String) item[4])) {

				List<String> prenotabile = Arrays.asList(String.valueOf(item[15]).split(","));

				if (!prenotabile.contains("P") && isNGA) {
					return false;
				}

				if (!prenotabile.contains("V") && !isNGA) {
					return false;
				}

				return true;
			}

			return false;
		}).collect(Collectors.toList());

	}

	private UfficioCacheOB mapServizi(List<Object[]> result) {

		if (result == null || result.isEmpty()) {
			return null;
		}

		UfficioCacheOB servizioUP = new UfficioCacheOB();
		String frazionario = String.valueOf(result.get(0)[ServiziCacheTYPE.FRAZIONARIO.ordinal()]);
		servizioUP.setFrazionario(frazionario);
		servizioUP.setNga(result.get(0)[ServiziCacheTYPE.NGA.ordinal()] == null ? false
				: String.valueOf(result.get(0)[ServiziCacheTYPE.NGA.ordinal()]).equals("1"));
		for (Object[] obj : result) {
			if (obj[ServiziCacheTYPE.FRAZIONARIO.ordinal()] == null) {
				continue;
			}

			String lettera = obj[ServiziCacheTYPE.LETTERA.ordinal()] == null ? null
					: String.valueOf(obj[ServiziCacheTYPE.LETTERA.ordinal()]);
			Long idServizio = obj[ServiziCacheTYPE.ID_SERVIZIO.ordinal()] == null ? null
					: Long.valueOf(String.valueOf(obj[ServiziCacheTYPE.ID_SERVIZIO.ordinal()]));
			String canale = obj[ServiziCacheTYPE.CANALE.ordinal()] == null ? null
					: String.valueOf(obj[ServiziCacheTYPE.CANALE.ordinal()]);
			String idProdotto = obj[ServiziCacheTYPE.ID_PRODOTTO.ordinal()] == null ? null
					: String.valueOf(obj[ServiziCacheTYPE.ID_PRODOTTO.ordinal()]);

			servizioUP.addServizio(idServizio, lettera, canale, idProdotto);

		}

		return servizioUP;
	}

	private List<ServizioCatalogoDTO> pulisciLivelliNonSignificativi(List<ServizioCatalogoDTO> catalogo) {

		if (catalogo == null)
			return new ArrayList<>(0);

		if (catalogo.size() == 1 && catalogo.get(0).getTipologia().equals("P")) {
			return pulisciLivelliNonSignificativi(catalogo.get(0).getChildren());
		}

		return catalogo;

	}

	private List<ServizioCatalogoDTO> pulisciPadriSenzaFigli(List<ServizioCatalogoDTO> lista) {

		if (lista == null) {
			return new ArrayList<>(0);
		}

		List<ServizioCatalogoDTO> res = new ArrayList<>(0);

		for (ServizioCatalogoDTO s : lista) {
			if (s.getTipologia().equals("F")) {
				res.add(s);
			} else if (s.getTipologia().equals("P") && s.getChildren() != null && !s.getChildren().isEmpty()) {
				List<ServizioCatalogoDTO> figli = pulisciPadriSenzaFigli(s.getChildren());

				if (figli != null && !figli.isEmpty()) {
					s.setChildren(figli.stream().sorted((e1, e2) -> e1.getOrdinamento().compareTo(e2.getOrdinamento())).collect(Collectors.toList()));
					res.add(s);
				}
			}
		}

		return res;

	}

	private List<ServizioCatalogoDTO> generaCatalogo(LocalDate giorno, List<ObMacroservizio> lista) {

		if (lista == null || lista.isEmpty()) {
			return new ArrayList<>(0);
		}

//		List<ServizioCatalogoDTO> res = new ArrayList<>(0);

		List<ObMacroservizio> collect = lista.stream().filter(el -> el.getCodProdPadre() == null)
				.collect(Collectors.toList());

//		res = mapLevel(giorno, collect);
//		return res;

		return mapLevel(giorno, collect);

	}

	private List<ServizioCatalogoDTO> mapLevel(LocalDate giorno, Collection<ObMacroservizio> lista) {

		if (lista == null) {
			return new ArrayList<>(0);
		}

		List<ServizioCatalogoDTO> res = new ArrayList<>(0);

		lista.stream().filter(item -> item != null).forEach(ms -> {

			ServizioCatalogoDTO dto = mapToDTO(ms);

			if (ms.getTipoServizio() != null && ms.getTipoServizio().equals("P")) {
				List<ObMacroservizio> findServiziAttiviPerGiornoAndCodPadre = macroServizioRepo
						.findServiziAttiviPerGiornoAndCodPadre(giorno, ms.getCodProd());

				if (findServiziAttiviPerGiornoAndCodPadre != null && !findServiziAttiviPerGiornoAndCodPadre.isEmpty()) {
					dto.setChildren(mapLevel(giorno, findServiziAttiviPerGiornoAndCodPadre));
				}
			}

			res.add(dto);

		});

//		for (ObMacroservizio ms : lista) {
//			
//			ServizioCatalogoDTO dto = mapToDTO(ms);
//
//			if (ms.getTipoServizio() != null && ms.getTipoServizio().equals("P")) {
//				List<ObMacroservizio> findServiziAttiviPerGiornoAndCodPadre = macroServizioRepo
//						.findServiziAttiviPerGiornoAndCodPadre(giorno, ms.getCodProd());
//
//				if (findServiziAttiviPerGiornoAndCodPadre != null && !findServiziAttiviPerGiornoAndCodPadre.isEmpty()) {
//					dto.setChildren(mapLevel(giorno, findServiziAttiviPerGiornoAndCodPadre));
//				}
//			}
//
//			res.add(dto);
//		}

		return res;
	}

	private ServizioCatalogoDTO mapToDTO(ObMacroservizio ms) {
		if (ms == null) {
			return null;
		}

		ServizioCatalogoDTO dto = new ServizioCatalogoDTO();
		dto.setCodProd(ms.getCodProd());
		dto.setDescrizioneMain(ms.getDescrizioneMain());
		dto.setDisponibile(ms.getVisibile() != null ? ms.getVisibile() : "S");
		dto.setOrdinamento(ms.getOrdinamento());
		dto.setTipologia(ms.getTipoServizio());

		return dto;
	}

	public ObMacroservizio closeService(String idServizio, MacroservizioDTO dto, UserDTO user) throws NgaException {

		if (idServizio == null || dto == null) {
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);
		}

		Optional<ObMacroservizio> findById = macroServizioRepo.findById(Long.valueOf(idServizio));

		if (!findById.isPresent()) {
			throw new NgaException(NGAExceptionType.NOT_FOUND);
		}

		if (dto.getDataFineValidita() == null) {
			throw new NgaException(NGAExceptionType.DATA_FINE_NON_VALORIZZATA);
		}
		
		if(dataAntecedenteADomani(dto.getDataFineValidita())) {
			throw new NgaException(NGAExceptionType.DATA_FINE_MINORE_SYSDATE);
		}

		ObMacroservizio macroservizio = findById.get();

		List<ObMacroservizio> children = macroServizioRepo
				.getFigliAttiviESchedulatiByCodProdPadre(macroservizio.getCodProd(), dto.getDataFineValidita());

		if (children != null && !children.isEmpty()) {
			throw new NgaException(NGAExceptionType.FIGLI_ATTIVI);
		}

		macroservizio.setDataFineValidita(dto.getDataFineValidita());
		macroservizio.setTsAggiornamento(Timestamp.from(Instant.now()));
		macroservizio.setUserAggiornamento(user.getUserid());

		ObMacroservizio saved = macroServizioRepo.save(macroservizio);

		return saved;

	}

	public List<Object[]> findPreviewExcel(PreviewRequestDTO dto) throws NgaException {

		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
		LocalDate date = LocalDate.parse(dto.getData(), formatter);

		if (date.isBefore(LocalDate.now()))
			throw new NgaException(500, "La data deve essere maggiore o uguale ad oggi ");

		List<Object[]> objs = macroServizioRepo.findPreviewExcel(date);

		// 2. se esiste il frazionario recupero i servizi per il frazionario

		if (!Utils.isBlankOrNull(dto.getFrazionario())) {

			List<Object[]> allResult = serviziCacheRepository.getAllResult(dto.getFrazionario().trim());
			UfficioCacheOB serviziUfficio = mapServizi(allResult);
			// 3. caratterizzo il catalogo per l'UP
			objs = caratterizzaExcelPerUP(objs, serviziUfficio);

		}

		return objs;

	}

	private boolean dataAntecedenteADomani(LocalDate toCheck) {
		return toCheck.isBefore(LocalDate.now().plusDays(1));
	}
	
	public void validateMacroservizio(MacroservizioDTO data) throws NgaException {
		String regex = "[a-zA-Z0-9-', ]*";
		
		if(data.getDescrizioneMain() == null || data.getDescrizioneMain().trim().isEmpty()) {
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);
		}
		
		if((data.getDescrizioneTicket() == null || data.getDescrizioneTicket().trim().isEmpty()) && data.getTipoServizio().equals(AppConsts.FOGLIA)) {
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);
		}
		
		if(data.getDataInizioValidita() == null) {
			throw new NgaException(NGAExceptionType.CAMPI_OBBLIGATORI_MANCANTI);
		}
		
		if(!data.getDescrizioneMain().matches(regex)) {
			throw new NgaException(NGAExceptionType.VALORE_CAMPO_NON_VALIDO.getCode(), "Il campo Descrizione Principale contiene caratteri non ammessi.");
		}
		
		if(!data.getDescrizioneSub().matches(regex)) {
			throw new NgaException(NGAExceptionType.VALORE_CAMPO_NON_VALIDO.getCode(), "Il campo Descrizione Secondaria contiene caratteri non ammessi.");
		}
		
		if(!data.getDescrizioneTicket().matches(regex)) {
			throw new NgaException(NGAExceptionType.VALORE_CAMPO_NON_VALIDO.getCode(), "Il campo Descrizione Ticket contiene caratteri non ammessi.");
		}
		
	}
	
}
