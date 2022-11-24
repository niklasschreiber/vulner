package it.poste.utility;

import java.util.Iterator;
import java.util.List;

import com.fasterxml.jackson.databind.JsonNode;
import com.google.common.base.Strings;

import it.poste.camel.processors.mappers.FOGetAPIMapper;
import it.poste.model.common.MainCustomerType;
import it.poste.model.femodel.SelectedRole;

public class LastFlags {
	
	//productID -> id dell'aggregato 
	private static Boolean isBuonoMinori(JsonNode fdi, String productId) {
		
		Boolean isBuonoMinori = false;
		
		if(fdi!=null && !Strings.isNullOrEmpty(productId)) {
			
			JsonNode wishlistAggregation = fdi.get("data").has("wishlistAggregation") ? fdi.get("data").get("wishlistAggregation") : null;
			JsonNode wishlistAggregationItems = wishlistAggregation != null && !wishlistAggregation.isMissingNode() && wishlistAggregation.has("items") ? wishlistAggregation.get("items") : null;
			JsonNode wishlistAggregationItem = wishlistAggregationItems != null && !wishlistAggregationItems.isMissingNode() && wishlistAggregationItems.has(productId) ? wishlistAggregationItems.get(productId) : null;
			JsonNode wishlistIds = wishlistAggregationItem != null && !wishlistAggregationItem.isMissingNode() && wishlistAggregationItem.has("wishlist_ids") ? wishlistAggregationItem.get("wishlist_ids") : null;
			Iterator<JsonNode> wishlistIdsIt = wishlistIds != null && !wishlistIds.isMissingNode() ? wishlistIds.elements() : null;
			while(wishlistIdsIt != null && wishlistIdsIt.hasNext()) {
				JsonNode wishlistIdsItem = wishlistIdsIt.next();
				String productType = wishlistIdsItem.has("productType") ?wishlistIdsItem.get("productType").asText() : "";
				if(Constants.PRODUCT_BUONI_MINORI.equalsIgnoreCase(productType)) {
					return true;
				}
			}
		}
		
		return isBuonoMinori;
		
	}
	
	public static String getPrivacyFlag(List<SelectedRole> roles, String productId, JsonNode fdi, SelectedRole rol) throws Exception {
		String flagPrivacy = "Y";

		if (!Strings.isNullOrEmpty(productId) && !roles.isEmpty() && fdi != null) {
			Boolean isBuonoMinori = isBuonoMinori(fdi, productId);
			MainCustomerType mc = FOGetAPIMapper.INSTANCE.extractMainCustomerFromFDI(fdi);
			Boolean mcRichiedente = false;
			if (isBuonoMinori) {
				for (SelectedRole role : roles) {
					if (role.getFiscalId().equals(mc.getFiscalId()) && role.getRoleId().equalsIgnoreCase("RICHIEDENTE")) {
						mcRichiedente = true;	
					}
				}
				
				if(mcRichiedente && (rol.getRoleId().equalsIgnoreCase("INTPF") || rol.getRoleId().equalsIgnoreCase("RICHIEDENTE"))) {
					flagPrivacy = "N";
				}				
			} 
		}

		return flagPrivacy;
	}
	
	public static String getOtherDataFlag(SelectedRole roles, String productId, JsonNode fdi) {
		String flagOtherData = "Y";
		
		if(!Strings.isNullOrEmpty(productId) && roles != null && fdi != null) {
			Boolean isBuonoMinori = isBuonoMinori(fdi, productId);
			
			if(isBuonoMinori) {
				if(roles.getRoleId().equals("RICHIEDENTE") && !Strings.isNullOrEmpty(roles.getNdg()) && !roles.getNdg().equalsIgnoreCase("0")){
					flagOtherData = "N";
				}	
			}
		}
		
		return flagOtherData;
	}

}
