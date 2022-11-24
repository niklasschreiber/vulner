package it.poste.aggregation;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import it.poste.api.dto.req.FOSaveAPIReqDTO;
import it.poste.model.BuoniDetails;
import it.poste.model.common.Product;
import it.poste.model.common.ProductAggregate;
import it.poste.model.femodel.RolesAggregation;
import it.poste.model.femodel.SelectedRole;
import it.poste.utility.Constants;
import it.poste.utility.fdi.Identification;
import it.poste.utility.fdi.Utils;
import it.poste.utility.fdi.WishlistAggregation;

@Component
public class AggregationUtils {

	private static String BFP_MINORE_CODE;

	private static String BFP_ESTRAZIONE_CODE;


	@Value("${bfpMinore}")
	public void setBfpMinoreCode(String bfpMinore) {
		AggregationUtils.BFP_MINORE_CODE = bfpMinore;
	}

	@Value("${bfpEstrazione}")
	public void setBfpEstrazioneCode(String bfpEstrazione) {
		AggregationUtils.BFP_ESTRAZIONE_CODE = bfpEstrazione;
	}

	public static List<Product> getProductListFromWishlist(JsonNode fdi) throws IOException {

		List<Product> result = new ArrayList<>();

		if (fdi != null) {

			JsonNode wishlistItems = fdi.get("data").get("wishlist").get("items");
			Iterator<String> fieldNames = wishlistItems.fieldNames();
			Product product = null;

			while (fieldNames.hasNext()) {

				String field = fieldNames.next();
				JsonNode item = wishlistItems.get(field);
				String family = item.get("product").get("family").asText();
				String forma = "";

				if (family.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI)
						|| family.equalsIgnoreCase(Constants.FAMILY_TYPE_PDR)) {

					String type = item.get("type").asText();
					String productCode = item.get("product").get("productCode").asText();
					Boolean afterSales = false;
					String afterSalesPhase = "";

					ArrayNode listOfTags = (ArrayNode) item.get("product").get("listOfTags");

					for(int i=0; i<listOfTags.size(); i++) {

						if(listOfTags.get(i).asText().equalsIgnoreCase("postvendita")) {
							afterSales = true;
							afterSalesPhase = item.has("name") ? item.get("name").asText() : "";
						}
					}

					JsonNode listOfAttributes = item.get("product").get("listOfAttributes");

					Iterator<JsonNode> listOfAttributesIterator = listOfAttributes.iterator();

					while (listOfAttributesIterator.hasNext()) {

						JsonNode listOfAttribute = listOfAttributesIterator.next();
						String name = listOfAttribute.get("name").asText();

						if (name.equals(Constants.FORMA_TYPE)) {

							String value = listOfAttribute.get("value").asText();
							Iterator<JsonNode> listOfValueIterator = listOfAttribute.get("listOfValue").elements();

							while (listOfValueIterator.hasNext()) {

								JsonNode listOfValue = listOfValueIterator.next();
								String listOfValueId = listOfValue.get("id").asText();

								if (value.equals(listOfValueId)) {
									forma = listOfValue.get("name").asText();
								}
							}
						}
					}

					product = new Product(field, type, productCode, Utils.getProductBic(productCode, family + " " + forma), family,
							forma);
					product.setAfterSales(afterSales);
					product.setAfterSalesPhase(afterSalesPhase);
					result.add(product);
				}
			}
		}

		return result;
	}

	public static List<Product> getFilteredProductListFromWishlist(JsonNode fdi, Boolean isReservedArea) throws IOException {

		List<Product> result = new ArrayList<>();

		String isReserved = isReservedArea.toString();

		if (fdi != null) {

			JsonNode wishlistItems = fdi.get("data").get("wishlist").get("items");
			Iterator<String> fieldNames = wishlistItems.fieldNames();
			Product product = null;

			while (fieldNames.hasNext()) {

				String field = fieldNames.next();
				JsonNode item = wishlistItems.get(field);
				if(isReservedArea == true){
					if(item.get("reservedArea") != null && item.get("reservedArea").asText().equalsIgnoreCase(isReserved)){
						String family = item.get("product").get("family").asText();
						String forma = "";

						if (family.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI)
								|| family.equalsIgnoreCase(Constants.FAMILY_TYPE_PDR)) {

							String type = item.get("type").asText();
							String productCode = item.get("product").get("productCode").asText();
							Boolean afterSales = false;
							String afterSalesPhase = "";

							ArrayNode listOfTags = (ArrayNode) item.get("product").get("listOfTags");

							for(int i=0; i<listOfTags.size(); i++) {

								if(listOfTags.get(i).asText().equalsIgnoreCase("postvendita")) {
									afterSales = true;
									afterSalesPhase = item.has("name") ? item.get("name").asText() : "";
								}
							}

							JsonNode listOfAttributes = item.get("product").get("listOfAttributes");

							Iterator<JsonNode> listOfAttributesIterator = listOfAttributes.iterator();

							while (listOfAttributesIterator.hasNext()) {

								JsonNode listOfAttribute = listOfAttributesIterator.next();
								String name = listOfAttribute.get("name").asText();

								if (name.equals(Constants.FORMA_TYPE)) {

									String value = listOfAttribute.get("value").asText();
									Iterator<JsonNode> listOfValueIterator = listOfAttribute.get("listOfValue").elements();

									while (listOfValueIterator.hasNext()) {

										JsonNode listOfValue = listOfValueIterator.next();
										String listOfValueId = listOfValue.get("id").asText();

										if (value.equals(listOfValueId)) {
											forma = listOfValue.get("name").asText();
										}
									}
								}
							}

							product = new Product(field, type, productCode, Utils.getProductBic(productCode, family + " " + forma), family,
									forma);
							product.setAfterSales(afterSales);
							product.setAfterSalesPhase(afterSalesPhase);

							result.add(product);
						}
					}
				} else if(item.get("reservedArea") != null && item.get("reservedArea").asText().equalsIgnoreCase(isReserved) || (item.get("reservedArea") == null)){
						String family = item.get("product").get("family").asText();
						String forma = "";

						if (family.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI)
								|| family.equalsIgnoreCase(Constants.FAMILY_TYPE_PDR)) {

							String type = item.get("type").asText();
							String productCode = item.get("product").get("productCode").asText();
							Boolean afterSales = false;
							String afterSalesPhase = "";

							ArrayNode listOfTags = (ArrayNode) item.get("product").get("listOfTags");

							for(int i=0; i<listOfTags.size(); i++) {

								if(listOfTags.get(i).asText().equalsIgnoreCase("postvendita")) {
									afterSales = true;
									afterSalesPhase = item.has("name") ? item.get("name").asText() : "";
								}
							}

							JsonNode listOfAttributes = item.get("product").get("listOfAttributes");

							Iterator<JsonNode> listOfAttributesIterator = listOfAttributes.iterator();

							while (listOfAttributesIterator.hasNext()) {

								JsonNode listOfAttribute = listOfAttributesIterator.next();
								String name = listOfAttribute.get("name").asText();

								if (name.equals(Constants.FORMA_TYPE)) {

									String value = listOfAttribute.get("value").asText();
									Iterator<JsonNode> listOfValueIterator = listOfAttribute.get("listOfValue").elements();

									while (listOfValueIterator.hasNext()) {

										JsonNode listOfValue = listOfValueIterator.next();
										String listOfValueId = listOfValue.get("id").asText();

										if (value.equals(listOfValueId)) {
											forma = listOfValue.get("name").asText();
										}
									}
								}
							}

							product = new Product(field, type, productCode, Utils.getProductBic(productCode, family + " " + forma), family,
									forma);
							product.setAfterSales(afterSales);
							product.setAfterSalesPhase(afterSalesPhase);

							result.add(product);
						}
					}
				}

			}

		return result;
	}

	public static Map<String, Object> checkSem(List<Product> products) throws JsonProcessingException, IOException {

		Map<String, List<Product>> productsCart = new HashMap<>();
		Map<String, List<Product>> productsDem = new HashMap<>();
		Map<String, List<Product>> productsPdr = new HashMap<>();

		Map<String, Object> map = new HashMap<>();

		Boolean isSemCart = false;
		Boolean isSemDem = false;

		Boolean itemsCart = false;
		Boolean itemsDem = false;
		Boolean itemsPdr = false;

		Boolean afterSales = false;
		String afterSalesPhase = "";
		
		for (Product product : products) {

			if (product.getProductForm().equalsIgnoreCase(Constants.FORMA_TYPE_CARTACEO)
					&& product.getProductFamily().equals(Constants.FAMILY_TYPE_BUONI)) {
				
				if (!productsCart.containsKey(product.getProductType())) {
					productsCart.put(product.getProductType(), new ArrayList<Product>());
				}

				productsCart.get(product.getProductType()).add(product);

				if (productsCart.get(product.getProductType()).size() > 1) {
					isSemCart = true;
				}

				itemsCart = true;

			} else if (product.getProductForm().equalsIgnoreCase(Constants.FORMA_TYPE_DEMATERIALIZZATO)
					&& product.getProductFamily().equals(Constants.FAMILY_TYPE_BUONI)) {

				itemsDem = true;

				Set<String> keys = productsDem.keySet();
				boolean productInCurrentAggregate = true;
				boolean productAggregated = false;

				for (String key : keys) {
					for (Product p : productsDem.get(key)) {
						if (p.getProductType().equalsIgnoreCase(product.getProductType())
								|| isSingleProduct(p.getProductCode()) 
								|| isSingleProduct(product.getProductCode())) {
							productInCurrentAggregate = false;
							break;
						}
					}
					
					if (productInCurrentAggregate) {
						productsDem.get(key).add(product);
						productAggregated = true;
						isSemDem = true;
						break;
					} else {
						productInCurrentAggregate = true;
					}
				}

				if (!productAggregated) {
					String currKey = Constants.FORMA_TYPE_DEMATERIALIZZATO.concat("_" + String.valueOf(keys.size()));
					productsDem.put(currKey, new ArrayList<Product>());
					productsDem.get(currKey).add(product);
				}

			} else if (product.getProductForm().equalsIgnoreCase(Constants.FORMA_TYPE_DEMATERIALIZZATO)
					&& product.getProductFamily().equalsIgnoreCase(Constants.FAMILY_TYPE_PDR)) {

				itemsPdr = true;

				Set<String> keys = productsPdr.keySet();
				String currKey = Constants.FAMILY_TYPE_PDR.concat("_" + String.valueOf(keys.size()));

				productsPdr.put(currKey, new ArrayList<Product>());
				productsPdr.get(currKey).add(product);

				if(product.getAfterSales()) {
					afterSales = true;
					afterSalesPhase = product.getAfterSalesPhase();
				}
			}
		}

		map.put("cartaceo", orderMap(productsCart));
		map.put("dematerializzato", orderMap(productsDem));
		map.put("pdr", productsPdr);
		map.put("semCar", isSemCart);
		map.put("semDem", isSemDem);
		map.put("itemsCar", itemsCart);
		map.put("itemsDem", itemsDem);
		map.put("itemsPdr", itemsPdr);
		map.put("afterSales", afterSales);
		map.put("afterSalesPhase", afterSalesPhase);

		return map;
	}

	public static Map<String, List<Product>> orderMap(Map<String, List<Product>> inputMap) {
		
		Map<String, List<Product>> outputMap = new HashMap<>();
		
		for (String key : inputMap.keySet()) {

			List<Product> list = inputMap.get(key);
			
			if (list.size() > 5) {
				
				Map<String, List<Product>> map = splitAggregation(key, list);
				
				for (String keyD : map.keySet()) {
					outputMap.put(keyD, map.get(keyD));
				}
			} else {
				outputMap.put(key, inputMap.get(key));
			}
		}

		return outputMap;
	}

	public static Map<String, List<Product>> splitAggregation(String key, List<Product> inputList) {

		Map<String, List<Product>> map = new HashMap<>();

		int size = inputList.size();
		String keyDub;
		int j = 0;
		
		for (int i = 0; i < size; i += 5) {
			
			if (i + 5 < size) {
				keyDub = key.concat("_" + String.valueOf(j));
				map.put(keyDub, inputList.subList(i, i + 5));
				j += 1;
			} else {
				keyDub = key.concat("_" + String.valueOf(j));
				map.put(keyDub, inputList.subList(i, size));
			}
		}

		return map;
	}

	public static Map<String, Object> riaggregateProducts(Map<String, List<ProductAggregate>> inProductsByHeading, String groupId) {
		
		Map<String, Object> result = new HashMap<>();
		//lista di prodotti riaggregata per intestazione/rapporto di regolamento
		Map<String, List<ProductAggregate>> outProductsByHeading = new HashMap<>();
		//wishlist aggregation del gruppo corrente riaggregata
		List<ProductAggregate> outWishlistAggregation = new ArrayList<>();
		//lista di prodotti riaggregati (utilizzata per autoSemDetails)
		List<ProductAggregate> outRiaggregationDetails = new ArrayList<>();

		for (String heading : inProductsByHeading.keySet()) {
			
			outProductsByHeading.put(heading, new ArrayList<>(inProductsByHeading.get(heading)));
			List<ProductAggregate> currentProductAggregatesList = outProductsByHeading.get(heading);
			
			for (int i = 0; i < currentProductAggregatesList.size()-1; i++) {
				
				ProductAggregate currentProductAggregate = currentProductAggregatesList.get(i);
				List<Product> currentProductAggregateProductList = currentProductAggregate.getProductList();
			
				if (currentProductAggregateProductList.size() < 5) {
					
					for (int j = i+1; j < currentProductAggregatesList.size(); j++) {
						
						ProductAggregate candidateProductAggregate = currentProductAggregatesList.get(j);
						List<Product> candidateProductAggregateProductList = candidateProductAggregate.getProductList();
						boolean riaggregationCondition = false;
						
						if (groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI + " " + Constants.FORMA_TYPE_CARTACEO)) {
							
							if (currentProductAggregate.getProductType().equalsIgnoreCase(candidateProductAggregate.getProductType()) && (currentProductAggregateProductList.size() + candidateProductAggregateProductList.size() <= 5)) {
								riaggregationCondition = true;
							}
							
						} else if (groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI + " " + Constants.FORMA_TYPE_DEMATERIALIZZATO)) {
							
							if (currentProductAggregateProductList.size() + candidateProductAggregateProductList.size() <= 5) {
								riaggregationCondition = true;
								
								for (Product p1 : candidateProductAggregateProductList) {
									
									for (Product p2 : currentProductAggregateProductList) {
										if (p1.getProductType().equalsIgnoreCase(p2.getProductType()) 
												|| isSingleProduct(p1.getProductCode()) 
												||  isSingleProduct(p2.getProductCode())
												) {
											riaggregationCondition = false;
											break;
										}
									}
									
									if (!riaggregationCondition)
										break;
								}
							}
						}
						
						if (riaggregationCondition) {
							
							currentProductAggregateProductList.addAll(candidateProductAggregateProductList);
							currentProductAggregatesList.remove(j);
							j -= 1;
							
							if(!outRiaggregationDetails.contains(currentProductAggregate))
								outRiaggregationDetails.add(currentProductAggregate);
						}
					}
				}
			}
		}

		for (List<ProductAggregate> l : outProductsByHeading.values()) {
			outWishlistAggregation.addAll(new ArrayList<>(l));
		}

		result.put("outProductsByHeading", outProductsByHeading);
		result.put("outWishlistAggregation", outWishlistAggregation);
		result.put("outRiaggregationDetails", outRiaggregationDetails);

		return result;
	}

	public static Map<String, List<ProductAggregate>> getProductAggregatesByHeadingFromRequest(FOSaveAPIReqDTO request, String groupId, JsonNode fdi) throws IOException {
		
		Map<String, List<ProductAggregate>> result = new HashMap<>();
		ObjectMapper mapper = new ObjectMapper();
		
		if (groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI + " " + Constants.FORMA_TYPE_CARTACEO)) {
			
			String key = "";
			
			for (RolesAggregation rolesAggregation : request.getRolesAggregation()) {

				List<String> ndgs = new ArrayList<>();
				String heading = "";
				
				for (SelectedRole selectedRole : rolesAggregation.getSelectedRoles()) {
					
					String fiscalIdNdg = selectedRole.getFiscalId() + "_" + selectedRole.getNdg();
					ndgs.add(fiscalIdNdg);
					
					if (selectedRole.getRoleId().equalsIgnoreCase("INTPF")
							|| selectedRole.getRoleId().equalsIgnoreCase("ALTINT"))
						heading = heading + (heading.isEmpty()? "" : " ") + selectedRole.getName() + " " + selectedRole.getSurname();
				}

				Collections.sort(ndgs);
				key = ndgs.toString();

				JsonNode wishlistAggregate = WishlistAggregation.getItemById(fdi, rolesAggregation.getProductId());
				String productForm = wishlistAggregate.findPath("productForm").asText();
				String productFamily = wishlistAggregate.findPath("productFamily").asText();
				Boolean reservedArea = wishlistAggregate.findPath("reservedArea").asBoolean();
				String mandato = wishlistAggregate.findPath("mandato").asText();
				
				ArrayNode wishlistIdsArray = (ArrayNode) wishlistAggregate.get("wishlist_ids");
				
				List<Product> productList = new ArrayList<>();
				String productType = "";
				
				for (int i = 0; i < wishlistIdsArray.size(); i++) {
					productType = wishlistIdsArray.get(i).findPath("productType").asText();
					String bfpSerie = wishlistIdsArray.get(i).findPath("serieBfp").asText();
					String descrizioneBreve = wishlistIdsArray.get(i).findPath("descrizioneBreve").asText();
					ArrayNode buoniDetails = wishlistIdsArray.get(i).has("buoniDetails") ? (ArrayNode) wishlistIdsArray.get(i).get("buoniDetails") : null;
					List<BuoniDetails> buoniDetailsList = new ArrayList<>();
					for(int k=0; buoniDetails != null && k < buoniDetails.size(); k++) {
						BuoniDetails buoniDetailsObj = mapper.treeToValue(buoniDetails.get(k), BuoniDetails.class);
						buoniDetailsList.add(buoniDetailsObj);
					}
					Product prod = new Product(wishlistIdsArray.get(i).findPath("id").asText(), wishlistIdsArray.get(i).findPath("productType").asText(), wishlistIdsArray.get(i).findPath("productCode").asText(), Utils.getProductBic(wishlistIdsArray.get(i).findPath("productCode").asText(), productFamily + " " + productForm ), wishlistIdsArray.get(i).findPath("nLiq").asBoolean(), descrizioneBreve, bfpSerie);
					prod.setBuoniDetails(buoniDetailsList);
					productList.add(prod);			
				}
				ProductAggregate productAggregate = new ProductAggregate(rolesAggregation.getProductId(), productForm, productFamily, productList, heading, productType, mandato, null, null,reservedArea);
				
				Boolean afterSales = wishlistAggregate.has("afterSales") ? wishlistAggregate.get("afterSales").asBoolean() : null;
				String afterSalesPhase = wishlistAggregate.has("afterSalesPhase") ? wishlistAggregate.get("afterSalesPhase").asText() : "";
				productAggregate.setAfterSales(afterSales);
				productAggregate.setAfterSalesPhase(afterSalesPhase);
				productAggregate.setReservedArea(reservedArea);

				if(!result.containsKey(key))
					result.put(key, new ArrayList<>());
				
				result.get(key).add(productAggregate);
			}

		} else if (groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_BUONI + " " + Constants.FORMA_TYPE_DEMATERIALIZZATO)
				|| groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_PDR + " " + Constants.FORMA_TYPE_DEMATERIALIZZATO)) {

			for (RolesAggregation rolesAggregation : request.getRolesAggregation()) {

				Map<String, String> identificationInfo = Identification.getIdentificationInfo(fdi, rolesAggregation.getProductId());
				String key = identificationInfo.get("identificationType") + "_" + identificationInfo.get("numero");

				JsonNode wishlistAggregate = WishlistAggregation.getItemById(fdi, rolesAggregation.getProductId());
				String productForm = wishlistAggregate.findPath("productForm").asText();
				String productFamily = wishlistAggregate.findPath("productFamily").asText();
				Boolean reservedArea = wishlistAggregate.findPath("reservedArea").asBoolean();

				ArrayNode wishlistIdsArray = (ArrayNode) wishlistAggregate.get("wishlist_ids");
				List<Product> productList = new ArrayList<>();
				String productType = "";
				
				for (int i = 0; i < wishlistIdsArray.size(); i++) {
					productType += (!productType.isEmpty() ? ", " : "") + wishlistIdsArray.get(i).findPath("productType").asText();
					String bfpSerie = wishlistIdsArray.get(i).findPath("serieBfp").asText();
					String descrizioneBreve = wishlistIdsArray.get(i).findPath("descrizioneBreve").asText();
					ArrayNode buoniDetails = wishlistIdsArray.get(i).has("buoniDetails") ? (ArrayNode) wishlistIdsArray.get(i).get("buoniDetails") : null;
					List<BuoniDetails> buoniDetailsList = new ArrayList<>();
					for(int k=0; buoniDetails != null && k < buoniDetails.size(); k++) {
						BuoniDetails buoniDetailsObj = mapper.treeToValue(buoniDetails.get(k), BuoniDetails.class);
						buoniDetailsList.add(buoniDetailsObj);
					}
					Product prod = new Product(wishlistIdsArray.get(i).findPath("id").asText(), wishlistIdsArray.get(i).findPath("productType").asText(), wishlistIdsArray.get(i).findPath("productCode").asText(), Utils.getProductBic(wishlistIdsArray.get(i).findPath("productCode").asText(), productFamily + " " + productForm ), wishlistIdsArray.get(i).findPath("nLiq").asBoolean(), descrizioneBreve, bfpSerie);
					prod.setBuoniDetails(buoniDetailsList);
					productList.add(prod);
				}

				ProductAggregate productAggregate = new ProductAggregate(rolesAggregation.getProductId(), productForm, productFamily, productList, identificationInfo.get("numero"), productType, null, null, null, reservedArea);
				
				Boolean afterSales = wishlistAggregate.has("afterSales") ? wishlistAggregate.get("afterSales").asBoolean() : null;
				String afterSalesPhase = wishlistAggregate.has("afterSalesPhase") ? wishlistAggregate.get("afterSalesPhase").asText() : "";
				productAggregate.setAfterSales(afterSales);
				productAggregate.setAfterSalesPhase(afterSalesPhase);
				productAggregate.setReservedArea(reservedArea);

				if(groupId.equalsIgnoreCase(Constants.FAMILY_TYPE_PDR + " " + Constants.FORMA_TYPE_DEMATERIALIZZATO)) {
					for(Product list: productAggregate.getProductList()) {
						list.setSerieBfp(null);
						list.setDescrizioneBreve(null);
					}
					productAggregate.setAfterSales(wishlistAggregate.findPath("afterSales").asBoolean());
					productAggregate.setAfterSalesPhase(wishlistAggregate.findPath("afterSalesPhase").asText());
				}
				
				if(!result.containsKey(key))
					result.put(key, new ArrayList<>());
				
				result.get(key).add(productAggregate);
			}
		}

		return result;
	}

	@SuppressWarnings("deprecation")
	public static JsonNode mergeWishlistAggregation(List<ProductAggregate> wishlistAggregationGroupNew, JsonNode wishlistAggregationItemsFdi, String group) {
		
		ObjectMapper mapper = new ObjectMapper();
		ObjectNode wishlistAggregationItems = mapper.createObjectNode();
		Iterator<String> wishlistAggregationFdiIt = wishlistAggregationItemsFdi.fieldNames();
		
		while(wishlistAggregationFdiIt != null && wishlistAggregationFdiIt.hasNext()) {
			
			String currentAggregateId = wishlistAggregationFdiIt.next();
			JsonNode currentNode = wishlistAggregationItemsFdi.get(currentAggregateId);
			String form = currentNode.findPath("productForm").asText();
			String family = currentNode.findPath("productFamily").asText();
			
			//if(!group.equalsIgnoreCase(family + " " + form)) {
				wishlistAggregationItems.put(currentAggregateId, currentNode);
			//}
		}
		
		for(ProductAggregate p: wishlistAggregationGroupNew) {

			wishlistAggregationItems.put(p.getProductAggregateId(), mapper.valueToTree(p));
		}
		
		ObjectNode result = mapper.createObjectNode();
		result.put("items", wishlistAggregationItems);
		
		return result;
	}
	
	private static Boolean isSingleProduct(String productCode) {
		
		if(productCode.equalsIgnoreCase(BFP_MINORE_CODE))
			return true;
		if(productCode.equalsIgnoreCase(BFP_ESTRAZIONE_CODE))
			return true;
		
		return false;
	}
}
