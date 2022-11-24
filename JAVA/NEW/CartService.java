package it.poste.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.jayway.jsonpath.JsonPath;
import com.jayway.jsonpath.spi.json.JsonProvider;
import it.poste.adapters.crmu.common.dto.v2.MetadataMap;
import it.poste.adapters.crmu.contract.dto.v2.ContractNumberFullResponse;
import it.poste.common.logging.LoggerWrapper;
import it.poste.common.microservices.framework.exception.ApplicationException;
import it.poste.common.model.data.v5.*;
import it.poste.configurations.CodesProperties;
import it.poste.configurations.CondizioniereProductProperties;
import it.poste.configurations.TechnicalDataConfiguration;
import it.poste.crmu.adapters.recupero.listini.dto.ListiniResponseDto;
import it.poste.crmu.common.adapter.exception.AdapterException;
import it.poste.crmu.orchestrator.dto.CartsFDI;
import it.poste.crmu.orchestrator.dto.CartsFDIS;
import it.poste.exceptions.CondizioniereException;
import it.poste.exceptions.GenericCartException;
import it.poste.models.InputInfo;
import it.poste.models.amex.DatiFiscali;
import it.poste.models.bankAccounts.Rendicontazione;
import it.poste.models.bankAccounts.RendicontazioneFDI;
import it.poste.models.cpq.CpqResponse;
import it.poste.models.crmu.CustomData;
import it.poste.models.funnel.*;
import it.poste.models.inputmodel.Model;
import it.poste.models.listini.TermCondition;
import it.poste.models.properties.CondizioniereProperties;
import it.poste.models.properties.TechnicalDataProperties;
import it.poste.utilities.FdiUtility;
import lombok.RequiredArgsConstructor;
import lombok.val;
import lombok.var;
import org.apache.logging.log4j.Level;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

import static it.poste.constants.Constants.*;
import static it.poste.utilities.FdiUtility.splitConfigArrayToList;

@Service
@RequiredArgsConstructor
public class CartService {
    private final LoggerWrapper log = new LoggerWrapper(this.getClass());
    private final FunnelService funnelService;
    private final ObjectMapper objectMapper;
    private final JsonProvider jsonProvider;
    private final RecuperoListiniService recuperoListiniService;
    private final TechnicalDataConfiguration technicalDataConfiguration;
    private final CrmuService crmuService;
    private final CPQService cpqService;
    private final CodesProperties codes;
    private final CondizioniereProductProperties condizioniereProductProperties;
    private final TypologicalService typologicalService;

    @Value("${config.constants.suite}")
    private String NEWSALES;
    @Value("${config.amex.blacklist-products}")
    private String AMEX_BLACKLIST_PRODUCTS;

    public void updateCart(final String cart, final Fdi fdi, final String productCode, Model model, EntityPricing posEntityPricing,
                           EntityPricing codiceEntityPricing, InputInfo modelInfo)
            throws IOException, ApplicationException, AdapterException {
        log.logMessage(Level.INFO, "updateCart -start");

        JsonNode input = objectMapper.convertValue(model, JsonNode.class);
        Object document = jsonProvider.parse(input.get(CONTAINER).get(SUB_CONTAINERS).toString());
        List<String> products = JsonPath.read(document, "$.[?(@.id)].id");
        var listiniResponseDto = new ListiniResponseDto();
        String[] promotion = {""};
        if (products.contains(codes.ofposfisPosfis) || products.contains(codes.ofposmobPosmob)) {
            modelInfo.getPromotions().forEach((k,v) -> {
                if (k.contains("POS")) {
                    promotion[0] = v;
                }
            });
            listiniResponseDto = recuperoListiniService.recuperoListini(posEntityPricing.getExternalKey(), posEntityPricing.getAcronym(), promotion[0]);
        }

        final JsonNode items = objectMapper.readTree(cart).get("product");
        String cartId = UUID.randomUUID().toString();
        CartsFDI cartFdi = new CartsFDI();
        Map<String, ContoContrattuale> customDataOffering = new HashMap<>();
        ((ObjectNode) items).put("operationReason", "0001");
        ((ObjectNode) items).put("assetStartDate", LocalDate.now().toString());
        ((ObjectNode) items).put("action", "ACTIVATE");
        ((ObjectNode) items).put("suite", NEWSALES);
        addIdsToCart(items, productCode);
        Product offering = buildOffering(items, productCode, input, posEntityPricing, codiceEntityPricing, listiniResponseDto, modelInfo);
        generateContractNumbers(fdi, offering);
        ContoContrattuale contoContrattuale = new ContoContrattuale();
        contoContrattuale.setIndirizzoEmailDiInvioContratto(funnelService.getContraentePec(fdi));
        customDataOffering.put("contoContrattuale", contoContrattuale);
        offering.setCustomData(customDataOffering);
        offering.setId(UUID.randomUUID().toString());
        cartFdi.setOffering(offering);
        cartFdi.setId(cartId);
        cartFdi.setWishlistId(fdi.getData().getWishlist().getItems().entrySet().iterator().next().getKey());
        HashMap<String, CartsFDI> cartMap = new HashMap<>();
        cartMap.put(cartId, cartFdi);

        CartsFDIS cartsFDIS = new CartsFDIS();
        cartsFDIS.setItems(cartMap);

        fdi.getData().setCarts(cartsFDIS);
        log.logMessage(Level.INFO, "updateCart -end");
    }

    protected void removeAmexSubProduct(Fdi fdi) {
        Objects.requireNonNull(FdiUtility.getPosCartsSubProduct(funnelService.getCartsItem(fdi).getOffering())).getSubProducts()
                .remove(FdiUtility.getAmexCartsSubProduct(funnelService.getCartsItem(fdi).getOffering()));
    }

    protected void addIdToAmexSubProduct(Fdi fdi) {
        Objects.requireNonNull(FdiUtility.getAmexCartsSubProduct(funnelService.getCartsItem(fdi).getOffering())).setId(UUID.randomUUID().toString());
    }

    private void generateContractNumbers(Fdi fdi, Product offering) {
        for (AdditionalData additionalData : offering.getAdditionalData()) {
            if ("GENERATESCONTR".equalsIgnoreCase(additionalData.getAcronym())
                    && "T".equalsIgnoreCase(additionalData.getValues().get(0).getValue())) {
                offering.setContractNumber(generateContractNumber(fdi));
            }
        }
        generateContractNumbers(fdi, offering.getSubProducts());
    }

    private void generateContractNumbers(Fdi fdi, List<Product> subProducts) {
        for (Product product : subProducts) {
            for (AdditionalData additionalData : product.getAdditionalData()) {
                if ("GENERATESCONTR".equalsIgnoreCase(additionalData.getAcronym())
                        && "T".equalsIgnoreCase(additionalData.getValues().get(0).getValue())) {
                    product.setContractNumber(generateContractNumber(fdi));
                }
            }
            generateContractNumbers(fdi, product.getSubProducts());
        }
    }

    private String generateContractNumber(Fdi fdi) {
        MetadataMap metadataMap = new MetadataMap();
        String operatorId = fdi.getInfo().getOperatorId();
        String frazionario = fdi.getInfo().getFrazionario();
        metadataMap.setOfficeFractionalCode(frazionario);
        metadataMap.setUserId(operatorId);
        ContractNumberFullResponse response = null;
        try {
            response = crmuService.generateContractNumber(metadataMap);
        } catch (ApplicationException ex) {
            // TODO
        }
        if (response == null || response.getContract() == null) {
            throw new RuntimeException(); // TODO
        }
        return response.getContract().getNumber();
    }

    public CartsFDIS getCart(final Fdi fdi) {
        final CartsFDIS cart = fdi.getData().getCarts();
        if (cart.getItems().isEmpty()) throw new GenericCartException("CartsFDIS not valid");
        return cart;
    }

    private void addIdsToCart(JsonNode items, String productCode) {
        if (productCode.equals(codes.posfisicoProductCode) || productCode.equals(codes.posmobileProductCode) ||
                productCode.equals(codes.codiceProductCode)) {
            ((ObjectNode) items.get(SUB_PRODUCTS).get(0)).put("id", UUID.randomUUID().toString());
        } else {
            for (JsonNode subProduct : items.get(SUB_PRODUCTS)) {
                ((ObjectNode) subProduct).put("id", UUID.randomUUID().toString());
                ((ObjectNode) subProduct.get(SUB_PRODUCTS).get(0)).put("id", UUID.randomUUID().toString());
            }
        }
    }

    private void addOfferingToCart(ArrayNode completeMatrix, JsonNode cpqProduct, String productCode, ArrayNode posCompleteMatrix,
                                   ArrayNode codiceCompleteMatrix, EntityPricing posEntityPricing, EntityPricing codiceEntityPricing,
                                   ListiniResponseDto listiniResponseDto, InputInfo infoModel) {
        RendicontazioneFDI rendicontazioneFDI = infoModel.getRendicontazioneFDI();
        ReferenteTecnico referenteTecnico = infoModel.getReferenteTecnico();

        if (productCode.equals(codes.posfisicoCodiceProductCode) || productCode.equals(codes.posmobileCodiceProductCode)) {
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0)).set(ADDITIONAL_DATA, posCompleteMatrix);
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(1).get(SUB_PRODUCTS).get(0)).set(ADDITIONAL_DATA, codiceCompleteMatrix);

            List<EntityPricing> posEntityPricings = new ArrayList<>();
            List<EntityPricing> codiceEntityPricings = new ArrayList<>();
            posEntityPricings.add(posEntityPricing);
            codiceEntityPricings.add(codiceEntityPricing);
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0)).set(ENTITY_PRICINGS, objectMapper.valueToTree(posEntityPricings));
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(1).get(SUB_PRODUCTS).get(0)).set(ENTITY_PRICINGS, objectMapper.valueToTree(codiceEntityPricings));

            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0)).set("technicalData", buildTechnicalData(listiniResponseDto, productCode));
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0)).set("attributes",
                    objectMapper.valueToTree(getRTAttributesFromFdi(referenteTecnico)));

            addPosDataToOfferingComposition((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA),
                    infoModel, referenteTecnico);
            addRendicontazioneToOfferingComposition((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA),
                    rendicontazioneFDI.getReport().get(0));
            addRendicontazioneToOfferingComposition((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(1).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA),
                    rendicontazioneFDI.getReport().get(1));
            if (productCode.equals(codes.posmobileCodiceProductCode)) {
                addPosMobShippingAddressToAdditionalData((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA),
                        infoModel);
            }
        } else {
            ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0)).set(ADDITIONAL_DATA, completeMatrix);
            if (productCode.equals(codes.codiceProductCode)) {
                List<EntityPricing> codiceEntityPricings = new ArrayList<>();
                codiceEntityPricings.add(codiceEntityPricing);
                ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0)).set(ENTITY_PRICINGS, objectMapper.valueToTree(codiceEntityPricings));
            } else {
                ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0)).set("technicalData", buildTechnicalData(listiniResponseDto, productCode));
                ((ObjectNode) cpqProduct.get(SUB_PRODUCTS).get(0)).set("attributes",
                        objectMapper.valueToTree(getRTAttributesFromFdi(referenteTecnico)));

                addPosDataToOfferingComposition((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA), infoModel, referenteTecnico);
                if (productCode.equals(codes.posmobileProductCode)) {
                    addPosMobShippingAddressToAdditionalData((ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA), infoModel);
                }
            }
            addRendicontazioneToOfferingComposition(
                    (ArrayNode) cpqProduct.get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA), rendicontazioneFDI.getReport().get(0)
            );
        }
    }

    private Product buildOffering(JsonNode cpqProduct, String productCode, JsonNode input, EntityPricing posEntityPricing,
                                  EntityPricing codiceEntityPricing, ListiniResponseDto listiniResponseDto, InputInfo inputInfo) {
        log.logMessage(Level.INFO, "call buildOffering -start");
        ArrayNode completeMatrix;
        ArrayNode posCompleteMatrix = objectMapper.createArrayNode();
        ArrayNode codiceCompleteMatrix = objectMapper.createArrayNode();
        if (productCode.equals(codes.posfisicoCodiceProductCode) || productCode.equals(codes.posmobileCodiceProductCode)) {
            JsonNode posAdditionalData = cpqProduct.get(SUB_PRODUCTS).get(0).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA);
            JsonNode codiceAdditionalData = cpqProduct.get(SUB_PRODUCTS).get(1).get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA);
            ArrayNode posBaseMatrix = getBaseMatrix(posAdditionalData, objectMapper);
            ArrayNode codiceBaseMatrix = getBaseMatrix(codiceAdditionalData, objectMapper);
            ArrayNode baseMatrix = objectMapper.createArrayNode();
            baseMatrix.insert(0, posBaseMatrix);
            baseMatrix.insert(1, codiceBaseMatrix);
            completeMatrix = getCompleteMatrix(baseMatrix, input.get(CONTAINER).get(SUB_CONTAINERS), objectMapper, posCompleteMatrix,
                    codiceCompleteMatrix, cpqProduct);
        } else {
            JsonNode additionalData = cpqProduct.get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA);
            ArrayNode productBaseMatrix = getBaseMatrix(additionalData, objectMapper);
            ArrayNode baseMatrix = objectMapper.createArrayNode();
            baseMatrix.insert(0, productBaseMatrix);
            completeMatrix = getCompleteMatrix(baseMatrix, input.get(CONTAINER).get(SUB_CONTAINERS), objectMapper,
                    objectMapper.createArrayNode(), objectMapper.createArrayNode(), cpqProduct);
        }
        addOfferingToCart(completeMatrix, cpqProduct, productCode, posCompleteMatrix, codiceCompleteMatrix, posEntityPricing,
                codiceEntityPricing, listiniResponseDto, inputInfo);
        log.logMessage(Level.INFO, "call buildOffering -end");
        return this.objectMapper.convertValue(cpqProduct, Product.class);
    }

    private ArrayNode getBaseMatrix(JsonNode additionalData, ObjectMapper mapper) {
        ArrayNode baseMatrix = mapper.createArrayNode();
        for (JsonNode additionalDatum : additionalData) {
            if (additionalDatum.get(ADDITIONAL_DATA_CODE).asInt() == 203 && additionalDatum.get(ATTRIBUTE_CODE).asInt() == 196)
                baseMatrix.insert(0, additionalDatum);
            else if (additionalDatum.get(ADDITIONAL_DATA_CODE).asInt() == 203 && additionalDatum.get(ATTRIBUTE_CODE).asInt() == 202)
                baseMatrix.insert(1, additionalDatum);
        }
        return baseMatrix;
    }

    private ArrayNode getCompleteMatrix(ArrayNode baseMatrix, JsonNode subContainers, ObjectMapper mapper, ArrayNode posCompleteMatrix,
                                        ArrayNode codiceCompleteMatrix, JsonNode cpqProduct) {
        if (baseMatrix.size() == 2) {
            Object posContainer = jsonProvider.parse(subContainers.get(0).toString());
            List<List<String>> posIbans = JsonPath.read(posContainer, IBAN_JSON_PATH);
            Object codiceContainer = jsonProvider.parse(subContainers.get(1).toString());
            List<List<String>> codiceIbans = JsonPath.read(codiceContainer, IBAN_JSON_PATH);
            return scanIbansDoubleProduct(baseMatrix, mapper, posIbans, codiceIbans, posCompleteMatrix, codiceCompleteMatrix, cpqProduct);
        } else {
            Object container = jsonProvider.parse(subContainers.get(0).toString());
            List<List<String>> ibans = JsonPath.read(container, IBAN_JSON_PATH);
            return scanIbansSingleProduct(baseMatrix, mapper, ibans, cpqProduct);
        }
    }

    private ArrayNode scanIbansDoubleProduct(ArrayNode baseMatrix, ObjectMapper mapper, List<List<String>> posIbans,
                                             List<List<String>> codiceIbans, ArrayNode posCompleteMatrix, ArrayNode codiceCompleteMatrix,
                                             JsonNode cpqProduct) {
        JsonNode posPvMatrix = baseMatrix.get(0).get(0);
        JsonNode posIbanMatrix = baseMatrix.get(0).get(1);
        JsonNode codicePvMatrix = baseMatrix.get(1).get(0);
        JsonNode codiceIbanMatrix = baseMatrix.get(1).get(1);
        int posPvNumber = 0;
        ArrayNode additionalData = mapper.createArrayNode();
        List<String> salesPoints = new ArrayList<>();

        for (List<String> ibansArray : posIbans) {
            if (ibansArray != null) {
                posPvNumber = ibansArray.size();
                salesPoints.addAll(ibansArray);
            }
        }
        for (List<String> ibansArray : codiceIbans) {
            if (ibansArray != null) {
                salesPoints.addAll(ibansArray);
            }
        }
        Integer index = 1;
        for (String iban : salesPoints) {
            JsonNode posPvMatrixCopy = posPvMatrix.deepCopy();
            JsonNode posIbanMatrixCopy = posIbanMatrix.deepCopy();
            JsonNode codicePvMatrixCopy = codicePvMatrix.deepCopy();
            JsonNode codiceIbanMatrixCopy = codiceIbanMatrix.deepCopy();
            if (index < posPvNumber + 1) {
                index = fillAdditionalData(posPvMatrixCopy, posIbanMatrixCopy, index, additionalData, iban);
            } else {
                index = fillAdditionalData(codicePvMatrixCopy, codiceIbanMatrixCopy, index, additionalData, iban);
            }
        }

        for (int i = 0; i < additionalData.size(); i++) {
            if (i < posPvNumber * 2)
                posCompleteMatrix.add(additionalData.get(i));
            else codiceCompleteMatrix.add(additionalData.get(i));
        }
        String posProductCode = cpqProduct.get("code").textValue().contains("POSMOB") ? codes.posmobileProductCode : codes.posfisicoProductCode;
        addAllCpqNodes(posCompleteMatrix, true, posProductCode, cpqProduct);
        addAllCpqNodes(codiceCompleteMatrix, true, codes.codiceProductCode, cpqProduct);
        return additionalData;
    }

    private ArrayNode scanIbansSingleProduct(ArrayNode baseMatrix, ObjectMapper mapper, List<List<String>> ibans, JsonNode cpqProduct) {
        JsonNode pvMatrix = baseMatrix.get(0).get(0);
        JsonNode ibanMatrix = baseMatrix.get(0).get(1);
        ArrayNode additionalData = mapper.createArrayNode();
        List<String> salesPoints = new ArrayList<>();

        for (List<String> ibansArray : ibans) {
            if (ibansArray != null) {
                salesPoints.addAll(ibansArray);
            }
        }
        Integer index = 1;
        for (String iban : salesPoints) {
            JsonNode pvMatrixCopy = pvMatrix.deepCopy();
            JsonNode ibanMatrixCopy = ibanMatrix.deepCopy();
            index = fillAdditionalData(pvMatrixCopy, ibanMatrixCopy, index, additionalData, iban);
        }
        addAllCpqNodes(additionalData, false, "", cpqProduct);
        return additionalData;
    }

    private void addAllCpqNodes(ArrayNode additionalData, Boolean isDoubleProduct, String productCode, JsonNode cpqProduct) {
        if (isDoubleProduct) {
            for (JsonNode subProduct : cpqProduct.get(SUB_PRODUCTS)) {
                if (subProduct.get("primaryCode").textValue().equals(productCode)) {
                    addAllCpqNodesGeneric(additionalData, subProduct);
                }
            }
        } else {
            addAllCpqNodesGeneric(additionalData, cpqProduct);
        }
    }

    private void addAllCpqNodesGeneric(ArrayNode additionalData, JsonNode product) {
        for (JsonNode additionalDataNode : product.get(SUB_PRODUCTS).get(0).get(ADDITIONAL_DATA)) {
            if ((additionalDataNode.get(ADDITIONAL_DATA_CODE).asInt() != 203 ||
                    additionalDataNode.get(ATTRIBUTE_CODE).asInt() != 196) &&
                    (additionalDataNode.get(ADDITIONAL_DATA_CODE).asInt() != 203 ||
                            additionalDataNode.get(ATTRIBUTE_CODE).asInt() != 202)) {
                additionalData.add(additionalDataNode);
            }
        }
    }

    private Integer fillAdditionalData(JsonNode pvMatrixCopy, JsonNode ibanMatrixCopy, Integer index, ArrayNode additionalData, String iban) {
        ((ObjectNode) pvMatrixCopy).put(ATTRIBUTE_VALUE, index.toString());
        ((ObjectNode) pvMatrixCopy).put(LIST_REF_NUMBER, index);
        ((ObjectNode) pvMatrixCopy).put(ATTRIBUTE_ORDER, 0);
        additionalData.add(pvMatrixCopy);
        ((ObjectNode) ibanMatrixCopy).put(ATTRIBUTE_VALUE, iban.equals("") ? "conto in attivazione" : iban);
        ((ObjectNode) ibanMatrixCopy).put(LIST_REF_NUMBER, index++);
        ((ObjectNode) ibanMatrixCopy).put(ATTRIBUTE_ORDER, 1);
        additionalData.add(ibanMatrixCopy);
        return index;
    }

    protected void updatePvIbanMap(Map<String, Long> duplicatePvMap, Fdi fdi) {
        List<AdditionalData> codiceAdditionalData = funnelService.getCartsItem(fdi)
                .getOffering().getSubProducts().get(1).getSubProducts().get(0).getAdditionalData();
        for (AdditionalData codiceAdditionalDatum : codiceAdditionalData) {
            if (codiceAdditionalDatum.getAdditionalDataCode() == 203 && codiceAdditionalDatum.getAttributeCode() == 196 &&
                    duplicatePvMap.containsKey(codiceAdditionalDatum.getListRefNumber().toString())) {
                codiceAdditionalDatum.setAttributeValue(duplicatePvMap.get(codiceAdditionalDatum.getListRefNumber().toString()).toString());
                codiceAdditionalDatum.setListRefNumber(duplicatePvMap.get(codiceAdditionalDatum.getListRefNumber().toString()));
            } else if (codiceAdditionalDatum.getAdditionalDataCode() == 203 && codiceAdditionalDatum.getAttributeCode() == 202 &&
                    duplicatePvMap.containsKey(codiceAdditionalDatum.getListRefNumber().toString())) {
                codiceAdditionalDatum.setListRefNumber(duplicatePvMap.get(codiceAdditionalDatum.getListRefNumber().toString()));
            }
        }
    }

    private ObjectNode buildTechnicalData(ListiniResponseDto listiniResponseDto, String productCode) {
        ObjectNode technicalData = objectMapper.createObjectNode();
        ArrayNode termConditions = objectMapper.createArrayNode();
        val technicalDataMap = technicalDataConfiguration.getTechnicalDataMap();
        DateFormat formatter = new SimpleDateFormat("dd/MM/yyyy");
        for (Map.Entry<String, TechnicalDataProperties> entry : technicalDataMap.entrySet()) {
            TermCondition termCondition = new TermCondition();
            List<ListiniResponseDto.RicorsivaValori> valoriList = new ArrayList<>();
            termCondition.setKey(entry.getKey());
            termCondition.setDiscountUnit(entry.getValue().getDiscountUnit());
            if (!entry.getValue().getCodCondEsterno().equals("")) {
                scanAndWriteListinoValues(listiniResponseDto, entry, valoriList, termCondition, termConditions, formatter);
            }
        }
        technicalData.set("termConditions", objectMapper.valueToTree(termConditions));
        if (codes.posmobileProductCode.equals(productCode) || codes.posmobileCodiceProductCode.equals(productCode)) {
            val condizionierePropertiesMap = condizioniereProductProperties.getProductMap();
            val condizioniereProperties = condizionierePropertiesMap.get("POSMOB");
            val posMobilePrice = this.getCanone(listiniResponseDto, condizioniereProperties).toString();
            technicalData.set("posMobilePrice", objectMapper.valueToTree(posMobilePrice));
        }
        return technicalData;
    }

    private void scanAndWriteListinoValues(ListiniResponseDto listiniResponseDto, Map.Entry<String, TechnicalDataProperties> entry,
                                           List<ListiniResponseDto.RicorsivaValori> valoriList, TermCondition termCondition,
                                           ArrayNode termConditions, DateFormat formatter) {
        for (ListiniResponseDto.RicorsivaValori valore : listiniResponseDto.getListaValori()) {
            if (valore.getCodCondEsterno().contains(entry.getValue().getCodCondEsterno()) &&
                    valore.getCodCompEsterno().contains(entry.getValue().getCodCompEsterno())) {
                valoriList.add(valore);
            }
        }
        if (valoriList.size() == 1) {
            populateTermConditions(termCondition, valoriList.get(0), termConditions);
        } else {
            for (int i = 0; i < valoriList.size(); i++) {
                if (i == 0) {
                    termCondition.setDiscountUnit("euro + IVA fino al " + formatter.format(valoriList.get(i).getDataFineValid()));
                } else {
                    termCondition.setDiscountUnit("euro + IVA a partire dal " + formatter.format(valoriList.get(i).getDataInizValid()));
                }
                populateTermConditions(termCondition, valoriList.get(i), termConditions);
            }
        }
    }

    private void populateTermConditions(TermCondition termCondition, ListiniResponseDto.RicorsivaValori valore, ArrayNode termConditions) {
        double divider = Math.pow(10, valore.getNumeroDecimaliValore());
        BigDecimal price = BigDecimal.valueOf(valore.getValoreCompNumerica() / divider).setScale(2);
        termCondition.setDiscountValue(String.valueOf(price));
        termConditions.add(objectMapper.valueToTree(termCondition));
    }

    private ArrayNode getRTAttributesFromFdi(ReferenteTecnico referenteTecnico) {

        ArrayNode extendedAttributeList = objectMapper.createArrayNode();

        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefFirstName", referenteTecnico.getName(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefLastName", referenteTecnico.getSurname(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefEmail", referenteTecnico.getEmail(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefPhoneNumber", referenteTecnico.getFullNumber(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefFullAddress", referenteTecnico.toStringAddress(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefAddress", referenteTecnico.getAddress().getDug() + " " + referenteTecnico.getAddress().getToponym() + " " + referenteTecnico.getAddress().getNumber(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefCity", referenteTecnico.getAddress().getCity().getValue(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefCityCode", referenteTecnico.getAddress().getCity().getCode(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefZipCode", referenteTecnico.getAddress().getZipCode().getValue(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefProvince", referenteTecnico.getAddress().getProvince().getValue(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefProvinceCode", referenteTecnico.getAddress().getProvince().getCode(), true, true, false)));
        extendedAttributeList.add(objectMapper.valueToTree(setExtendedAttribute("technicalRefAt", referenteTecnico.getPresso(), true, true, false)));

        return extendedAttributeList;
    }

    private ExtendedAttribute setExtendedAttribute(String key, String value, Boolean includeInAsset,
                                                   Boolean includeInRootHeader, Boolean searchable) {
        ExtendedAttribute attribute = new ExtendedAttribute();
        attribute.setKey(key);
        attribute.setValue(value);
        ExtendedAttrOptions extendedAttrOptions = new ExtendedAttrOptions();
        extendedAttrOptions.setIncludeInAsset(includeInAsset);
        extendedAttrOptions.setIncludeInRootHeader(includeInRootHeader);
        extendedAttrOptions.setSearchable(searchable);
        attribute.setOptions(extendedAttrOptions);
        return attribute;
    }

    private void addPosDataToOfferingComposition(ArrayNode cpqAdditionalData, InputInfo info, ReferenteTecnico referenteTecnico) {
        final Fatturazione fatturazione = info.getFatturazione();
        final Circuiti circuiti = info.getCircuiti();

        for (int i = 0; i < cpqAdditionalData.size(); i++) {
            switch (cpqAdditionalData.get(i).get(ATTRIBUTE_ACRONYM).textValue()) {
                case "attorneyCheck":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAttorneyCheck());
                    break;
                case "nameTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getName());
                    break;
                case "surnameTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getSurname());
                    break;
                case "emailTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getEmail());
                    break;
                case "nrMobileTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getFullNumber());
                    break;
                case "dugTechReferent":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getDug());
                    break;
                case "topTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getToponym());
                    break;
                case "streetNrTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getNumber());
                    break;
                case "zipCodeTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getZipCode().getValue());
                    break;
                case "cityTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getCity().getValue());
                    break;
                case "provinceTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getProvince().getCode());
                    break;
                case "nationTechRef":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, referenteTecnico.getAddress().getCountry().getValue());
                    break;
                case "recCodeBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getReceiverCode()));
                    break;
                case "emailPecBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getPec()));
                    break;
                case "emailBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getEmail()));
                    break;
                case "flagSplitPay":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getSplitPayment()));
                    break;
                case "dugBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getAddress().getDug()));
                    break;
                case "toponymBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getAddress().getToponym()));
                    break;
                case "streetNrBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(fatturazione.getAddress().getNumber()));
                    break;
                case "cityBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, fatturazione.getAddress().getCity() == null ? "" : fatturazione.getAddress().getCity().getValue());
                    break;
                case "provinceBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, fatturazione.getAddress().getProvince() == null ? "" : fatturazione.getAddress().getProvince().getCode());
                    break;
                case "zipCodeBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, fatturazione.getAddress().getZipCode() == null ? "" : fatturazione.getAddress().getZipCode().getValue());
                    break;
                case "nationBilling":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, fatturazione.getAddress().getCountry() == null ? "" : fatturazione.getAddress().getCountry().getValue());
                    break;
                case "pmatPayCircuits":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, circuiti.getPmatPayCircuits());
                    break;
                case "cardPayCirc":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, circuiti.getCardPayCirc());
                    break;
                case "bancomatPayCirc":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, circuiti.getBancomatPayCirc());
                    break;
                case "amexPayCirc":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, circuiti.getAmexPayCirc());
                    break;
                default:
            }
        }
    }

    private void addPosMobShippingAddressToAdditionalData(ArrayNode cpqAdditionalData, InputInfo modelInfo) {
        final Address posShippingAddress = modelInfo.getPosShippingAddress();
        for (int i = 0; i < cpqAdditionalData.size(); i++) {
            switch (cpqAdditionalData.get(i).get(ATTRIBUTE_ACRONYM).textValue()) {
                case "posShipCheck":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, modelInfo.getTipologiaIndirizzoSpedizionePosMob());
                    break;
                case "posShippingDug":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getDug());
                    break;
                case "posShipToponym":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getToponym());
                    break;
                case "posShipNumber":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getNumber());
                    break;
                case "posShipCity":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getCity().getValue());
                    break;
                case "posShipProvince":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getProvince().getCode());
                    break;
                case "posShipZipcode":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getZipCode().getValue());
                    break;
                case "posShipNation":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, posShippingAddress.getCountry().getCode());
                    break;
                default:
            }
        }
    }

    private void addRendicontazioneToOfferingComposition(ArrayNode cpqAdditionalData, Rendicontazione rendicontazione) {
        for (int i = 0; i < cpqAdditionalData.size(); i++) {
            switch (cpqAdditionalData.get(i).get(ATTRIBUTE_ACRONYM).textValue()) {
                case "pReportingReq":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, rendicontazione.getFlagCartaceo() ? "Y" : "N");
                    break;
                case "careOfReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(rendicontazione.getRagioneSociale()));
                    break;
                case "dugReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(rendicontazione.getAddress().getDug()));
                    break;
                case "toponymReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(rendicontazione.getAddress().getToponym()));
                    break;
                case "streetNrReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, returnEmptyStringIfNull(rendicontazione.getAddress().getNumber()));
                    break;
                case "provinceReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, rendicontazione.getAddress().getProvince() == null ? "" : rendicontazione.getAddress().getProvince().getCode());
                    break;
                case "cityReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, rendicontazione.getAddress().getCity() == null ? "" : rendicontazione.getAddress().getCity().getValue());
                    break;
                case "zipCodeReport":
                    ((ObjectNode) cpqAdditionalData.get(i)).put(ATTRIBUTE_VALUE, rendicontazione.getAddress().getZipCode() == null ? "" : rendicontazione.getAddress().getZipCode().getValue());
                    break;
                default:
            }
        }
    }

    private String returnEmptyStringIfNull(String string) {
        if (string == null) return "";
        return string;
    }

    protected void addFirmatarioToSubProductsAttributes(Fdi fdi, List<String> idFirmatariList) {
        List<Product> subProducts = funnelService.getCartsItem(fdi).getOffering().getSubProducts();
        if (funnelService.getProductCode(fdi).equals(codes.posfisicoCodiceProductCode) ||
                funnelService.getProductCode(fdi).equals(codes.posmobileCodiceProductCode)) {
            ExtendedAttribute extendedAttributePos = setExtendedAttribute(SIGNER, idFirmatariList.get(0), true, true, false);
            ExtendedAttribute extendedAttributeCodice = setExtendedAttribute(SIGNER, idFirmatariList.get(1), true, true, false);
            subProducts.get(0).getSubProducts().get(0).getAttributes().add(extendedAttributePos);
            subProducts.get(1).getSubProducts().get(0).getAttributes().add(extendedAttributeCodice);
        } else {
            ExtendedAttribute extendedAttributeSingleProduct = setExtendedAttribute(SIGNER, idFirmatariList.get(0), true, true, false);
            subProducts.get(0).getAttributes().add(extendedAttributeSingleProduct);
        }
    }

    protected void addCategoryToSubProductsAttribute(Fdi fdi, CpqResponse cpqResponse) {
        String tpValue = null;

        List<AdditionalData> additionalDataList = cpqResponse.getProduct().getAdditionalData();
        for (AdditionalData additionalData : additionalDataList) {
            if (additionalData.getAcronym().equals("CATEGORY")) {
                for (AdditionalDataValue additionalDataValue : additionalData.getValues()) {
                    tpValue = additionalDataValue.getValue();
                }
                break;
            }
        }

        ExtendedAttribute extendedAttribute = setExtendedAttribute("category", tpValue, true, true, true);
        List<Product> subProducts = funnelService.getCartsItem(fdi).getOffering().getSubProducts();
        for (Product subProduct : subProducts) {
            if (subProduct.getPrimaryCode().equals(POSFIS) || subProduct.getPrimaryCode().equals("POSMOB") ||
                    subProduct.getPrimaryCode().equals("CODICE")) {
                subProduct.getAttributes().add(extendedAttribute);
            } else {
                for (Product subSubProduct : subProduct.getSubProducts()) {
                    if (subSubProduct.getPrimaryCode().equals(POSFIS) || subSubProduct.getPrimaryCode().equals("POSMOB") ||
                            subSubProduct.getPrimaryCode().equals("CODICE")) {
                        subSubProduct.getAttributes().add(extendedAttribute);
                    }
                }
            }
        }
    }

    protected void addModalitaAccreditoToSubProductsAttribute(Fdi fdi, String productCode, List<List<String>> ibansPerProduct) {
        String key = "modalitaAccredito";
        List<Product> subProducts = funnelService.getCartsItem(fdi).getOffering().getSubProducts();

        if (productCode.equals(codes.posfisicoCodiceProductCode) || productCode.equals(codes.posmobileCodiceProductCode)) {
            String posModalitaAccredito = getModalitaAccredito(ibansPerProduct.get(0));
            String codiceModalitaAccredito = getModalitaAccredito(ibansPerProduct.get(1));
            ExtendedAttribute extendedAttributePos = setExtendedAttribute(key, posModalitaAccredito,
                    false, false, false);
            ExtendedAttribute extendedAttributeCodice = setExtendedAttribute(key, codiceModalitaAccredito,
                    false, false, false);
            subProducts.get(0).getSubProducts().get(0).getAttributes().add(extendedAttributePos);
            subProducts.get(1).getSubProducts().get(0).getAttributes().add(extendedAttributeCodice);
        } else {
            ExtendedAttribute extendedAttributeSingleProduct = setExtendedAttribute(key, getModalitaAccredito(ibansPerProduct.get(0)),
                    false, false, false);
            subProducts.get(0).getAttributes().add(extendedAttributeSingleProduct);
        }
    }

    private String getModalitaAccredito(List<String> ibansList) {
//        if (ibansList.size() != 1) {
//            String firstIban = ibansList.get(0);
//            for (String iban : ibansList) {
//                if (!iban.equals(firstIban))
//                    return "DISTINTO";
//            }
//        }
//        return "UNICO";
        return "DISTINTO";
    }

    protected void addPosShippingAddressToSubProductsAttributes(Fdi fdi, Address shippingAddress, String productCode) {
        if (productCode.equals(codes.posmobileProductCode) || productCode.equals(codes.posmobileCodiceProductCode)) {
            val extendedAttributeList = new ArrayList<ExtendedAttribute>();
            extendedAttributeList.add(setExtendedAttribute("SDAAddressDug", shippingAddress.getDug(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressToponym", shippingAddress.getToponym(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAShortAddress", shippingAddress.getDug() + " " + shippingAddress.getToponym(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressNumber", shippingAddress.getNumber(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressCity", shippingAddress.getCity().getValue(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressProvince", shippingAddress.getProvince().getCode(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressZIPCode", shippingAddress.getZipCode().getValue(), true, true, false));
            extendedAttributeList.add(setExtendedAttribute("SDAAddressNation", shippingAddress.getCountry().getCode(), true, true, false));

            val posMobileSubProduct = getPosMobileCartsSubProduct(funnelService.getCartsItem(fdi).getOffering());
            if (posMobileSubProduct != null) {
                posMobileSubProduct.getAttributes().addAll(extendedAttributeList);
            }
        }
    }

    protected void addAmexAttributes(Fdi fdi, DatiFiscali datiFiscali, String isAmex) {
        if (Boolean.parseBoolean(isAmex)) {
            val amexProduct = FdiUtility.getAmexCartsSubProduct(funnelService.getCartsItem(fdi).getOffering());
            assert amexProduct != null;
            for (val additionalDatum : amexProduct.getAdditionalData()) {
                if ("ibanAmex".equals(additionalDatum.getAttributeAcronym())) {
                    additionalDatum.setAttributeValue(datiFiscali.getIban());
                } else if ("acntHolderAmex".equals(additionalDatum.getAttributeAcronym())) {
                    additionalDatum.setAttributeValue(datiFiscali.getIntestazione());
                }
            }
        }
    }

    protected Product getPosMobileCartsSubProduct(Product product) {
        if ("POSMOB".equals(product.getPrimaryCode())) {
            return product;
        }
        for (val subProduct : product.getSubProducts()) {
            if ("POSMOB".equals(subProduct.getPrimaryCode()))
                return subProduct;
            else {
                Product product1 = getPosMobileCartsSubProduct(subProduct);
                if (product1 != null)
                    return product1;
            }
        }
        return null;
    }

    protected Product getPosFisicoCartsSubProduct(Product product) {
        if (POSFIS.equals(product.getPrimaryCode())) {
            return product;
        }
        for (val subProduct : product.getSubProducts()) {
            if (POSFIS.equals(subProduct.getPrimaryCode()))
                return subProduct;
            else {
                Product product1 = getPosFisicoCartsSubProduct(subProduct);
                if (product1 != null)
                    return product1;
            }
        }
        return null;
    }

    protected void removeUnusedPromos(Product product, Map<String, String> promotions, String productCode) {

        Product posProduct = null;
        if (productCode.contains("POS")) {
            posProduct = FdiUtility.getPosCartsSubProduct(product);
        }

        Product codiceProduct = null;
        if (productCode.contains("CODICE")) {
            codiceProduct = FdiUtility.getCodiceCartsSubProduct(product);
        }

        if (posProduct != null) {
            iteratorRemovePromo(posProduct, promotions);
        }

        if (codiceProduct != null) {
            iteratorRemovePromo(codiceProduct, promotions);
        }
    }

    private void iteratorRemovePromo(Product codiceProduct, Map<String, String> promotions) {
        Iterator iterator = codiceProduct.getSubProducts().iterator();
        while (iterator.hasNext()) {
            Product p = (Product) iterator.next();
            if (Product.Type.D.equals(p.getType()) && !promotions.containsValue(p.getPrimaryCode())) {
                iterator.remove();
            }
        }
    }

    protected Product getPosCartsOffering(Product product) {
        if ("OFPOSFIS".equals(product.getPrimaryCode()) || "OFPOSMOB".equals(product.getPrimaryCode())) {
            return product;
        }
        for (val subProduct : product.getSubProducts()) {
            if ("OFPOSFIS".equals(subProduct.getPrimaryCode()) || "OFPOSMOB".equals(product.getPrimaryCode()))
                return subProduct;
            else {
                Product product1 = getPosCartsOffering(subProduct);
                if (product1 != null)
                    return product1;
            }
        }
        return null;
    }

    protected Product getCodiceCartsOffering(Product product) {
        if ("OFCODICE".equals(product.getPrimaryCode())) {
            return product;
        }
        for (val subProduct : product.getSubProducts()) {
            if ("OFCODICE".equals(subProduct.getPrimaryCode()))
                return subProduct;
            else {
                Product product1 = getCodiceCartsOffering(subProduct);
                if (product1 != null)
                    return product1;
            }
        }
        return null;
    }

    public void mergeCrmuAndNewPv(Fdi fdi) throws ApplicationException {
        val crmuInfo = crmuService.assetInfoByAuc(funnelService.getIdAuc(fdi), fdi);
        val crmuSalesPoints = crmuInfo.getSalesPointSet();
        val customersSalesPoints = funnelService.getContraente(fdi).getLegalInfo().getSalesPoints().stream()
                .filter(salesPoint -> (objectMapper.convertValue(salesPoint.getCustomData(), it.poste.models.CustomData.class))
                        .getProduct().equals("pos"))
                .collect(Collectors.toSet());
        val mergedSalesPoints = new HashSet<SalesPoint>();
        val cartsSalesPoints = new HashSet<SalesPoint>();

        for (Iterator<SalesPoint> iteratorCrmu = crmuSalesPoints.iterator(); iteratorCrmu.hasNext(); ) {
            SalesPoint crmuSalesPoint = iteratorCrmu.next();
            for (Iterator<SalesPoint> iteratorNew = customersSalesPoints.iterator(); iteratorNew.hasNext(); ) {
                SalesPoint newPosSalesPoint = iteratorNew.next();
                if (isSameSalesPointLight(crmuSalesPoint, newPosSalesPoint)) {
                    mergedSalesPoints.add(crmuSalesPoint);
                    iteratorCrmu.remove();
                    iteratorNew.remove();
                }
            }
        }
        if (crmuInfo.isAmexActive()) {
            crmuSalesPoints.clear();
            for (SalesPoint salesPoint : mergedSalesPoints)
                ((CustomData) salesPoint.getCustomData()).setProductInfo(null);
        } else {
            removeNotPosProducts(mergedSalesPoints);
            removeNotPosProducts(crmuSalesPoints);
        }

        addSalesPointsToCartsList(customersSalesPoints, cartsSalesPoints, 1);
        addSalesPointsToCartsList(mergedSalesPoints, cartsSalesPoints, 2);
        addSalesPointsToCartsList(crmuSalesPoints, cartsSalesPoints, 3);

        //TODO aggiungere controllo per rimuovere i PV con ateco in blacklist

        val amexSubProduct = FdiUtility.getAmexCartsSubProduct(funnelService.getCartsItem(fdi).getOffering());
        if (amexSubProduct != null) {
            val salesPointsHashMap = new HashMap<String, HashSet<SalesPoint>>();
            salesPointsHashMap.put("salesPoints", cartsSalesPoints);
            amexSubProduct.setCustomData(salesPointsHashMap);
        }
    }

    private boolean isSameSalesPointLight(SalesPoint salesPoint1, SalesPoint salesPoint2) {
        return isSameAddress(salesPoint1, salesPoint2) &&
                isSameAteco(salesPoint1, salesPoint2) &&
                salesPoint1.getSignboard().equals(salesPoint2.getSignboard());
    }

    private boolean isSameAddress(SalesPoint salesPoint1, SalesPoint salesPoint2) {
        return salesPoint1.getAddress().getCity().equals(salesPoint2.getAddress().getCity())
                && salesPoint1.getAddress().getCountry().equals(salesPoint2.getAddress().getCountry())
                && salesPoint1.getAddress().getDug().equals(salesPoint2.getAddress().getDug())
                && salesPoint1.getAddress().getNumber().equals(salesPoint2.getAddress().getNumber())
                && salesPoint1.getAddress().getProvince().equals(salesPoint2.getAddress().getProvince())
                && salesPoint1.getAddress().getToponym().equals(salesPoint2.getAddress().getToponym())
                && salesPoint1.getAddress().getZipCode().equals(salesPoint2.getAddress().getZipCode());
    }

    private boolean isSameAteco(SalesPoint salesPoint1, SalesPoint salesPoint2) {
        return getAtecoBA(salesPoint1).getType().equals(getAtecoBA(salesPoint2).getType())
                && getAtecoBA(salesPoint1).getCode().equals(getAtecoBA(salesPoint2).getCode());
    }

    private BusinessActivity getAtecoBA(SalesPoint salesPoint) {
        for (BusinessActivity businessActivity : salesPoint.getBusinessActivities()) {
            if ("ATECO".equals(businessActivity.getType()))
                return businessActivity;
        }
        return new BusinessActivity();
    }

    private void removeNotPosProducts(Set<SalesPoint> salesPoints) {
        List<String> amexBlacklistProducts = splitConfigArrayToList(AMEX_BLACKLIST_PRODUCTS);
        for (SalesPoint salesPoint : salesPoints) {
            val customData = (CustomData) salesPoint.getCustomData();
            customData.getProductInfo()
                    .removeIf(productInfoItem -> amexBlacklistProducts.contains(productInfoItem.getProductCode().toUpperCase()));
        }
    }

    protected void addSalesPointsToCartsList(Set<SalesPoint> salesPoints, Set<SalesPoint> cartsSalesPoints, Integer salesPointCase) {
        for (SalesPoint salesPoint : salesPoints) {
            if (salesPointCase != 3) {
                val newSalesPoint = new SalesPoint();
                newSalesPoint.setId(salesPoint.getId());
                if (salesPointCase == 2)
                    newSalesPoint.setCustomData(salesPoint.getCustomData());
                cartsSalesPoints.add(newSalesPoint);
            } else {
                salesPoint.setEmails(getPrimaEmailNoPEC(salesPoint));
                salesPoint.setPhoneNumbers(getPrimoNumeroCellulare(salesPoint));
                cartsSalesPoints.add(salesPoint);
            }
        }
    }

    private List<Email> getPrimaEmailNoPEC(SalesPoint salesPoint) {
        List<Email> emailList = new ArrayList<>();
        for (Email email : salesPoint.getEmails()) {
            if (!email.getEmail().contains("pec")) {
                emailList.add(email);
                return emailList;
            }
        }
        if (!salesPoint.getEmails().isEmpty()) {
            emailList.add(salesPoint.getEmails().get(0));
        }
        return emailList;
    }

    private List<PhoneNumber> getPrimoNumeroCellulare(SalesPoint salesPoint) {
        List<PhoneNumber> phoneNumberList = new ArrayList<>();
        for (PhoneNumber numero : salesPoint.getPhoneNumbers()) {
            if (numero.getType().getValue().equals("CELLULARE")) {
                phoneNumberList.add(numero);
                return phoneNumberList;
            }
        }
        if (!salesPoint.getPhoneNumbers().isEmpty()) {
            phoneNumberList.add(salesPoint.getPhoneNumbers().get(0));
        }
        return phoneNumberList;
    }

    protected BigDecimal getCanone(ListiniResponseDto listiniResponseDto, CondizioniereProperties condizioniereProperties) {
        for (ListiniResponseDto.RicorsivaValori valore : listiniResponseDto.getListaValori()) {
            if (valore.getCodCondEsterno().startsWith(condizioniereProperties.getCondizioniereCodDscdzbr()) &&
                    valore.getCodCompEsterno().startsWith(condizioniereProperties.getCondizioniereCodDslegbr()) &&
                    valore.getFormatoValore().equals("N")) {
                double divider = Math.pow(10, valore.getNumeroDecimaliValore());
                return BigDecimal.valueOf(valore.getValoreCompNumerica() / divider).setScale(2);
            }
        }
        throw new CondizioniereException("No condition found");
    }

    protected void addSalesPointsSectionToAmexSubProduct(Fdi fdi, HashSet<SalesPoint> cartsSalesPoints) {
        val amexSubProduct = FdiUtility.getAmexCartsSubProduct(funnelService.getCartsItem(fdi).getOffering());
        if (amexSubProduct != null) {
            val salesPointsHashMap = new HashMap<String, HashSet<SalesPoint>>();
            salesPointsHashMap.put("salesPoints", cartsSalesPoints);
            amexSubProduct.setCustomData(salesPointsHashMap);
        }
    }

}