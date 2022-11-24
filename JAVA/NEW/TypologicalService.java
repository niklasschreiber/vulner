package it.poste.services;

import it.poste.common.logging.LoggerWrapper;
import it.poste.configurations.TypologicalProperties;
import it.poste.constants.CacheNames;
import it.poste.exceptions.MccException;
import it.poste.models.typological.TipAtecoResponseItem;
import it.poste.utilities.Utils;
import lombok.RequiredArgsConstructor;
import lombok.val;
import lombok.var;
import org.apache.commons.lang.StringUtils;
import org.apache.logging.log4j.Level;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@RequiredArgsConstructor
public class TypologicalService {

    private final LoggerWrapper log = new LoggerWrapper(this.getClass());
    private final TypologicalProperties properties;
    private final TypologicalRestService typologicalRestService;
    private final CacheManager cacheManager;

    @Scheduled(fixedRate = 30 * 60 * 1000)
    public void refreshData() {
        log.logMessage("Refreshing data from TypologicalService");
        Cache cache;
        if ((cache = cacheManager.getCache(CacheNames.ATECO_MAP)) != null) {
            cache.clear();
        }
        typologicalRestService.getAtecoToTipAteco();
    }

    public TipAtecoResponseItem tipByAteco(final String ateco) {
        Map<String, TipAtecoResponseItem> atecoToTip = typologicalRestService.getAtecoToTipAteco();
        val result = new TipAtecoResponseItem();
        var tip = atecoToTip.get(ateco);
        result.setAtecoCod(tip.getAtecoCod());
        result.setAtecoDescr(tip.getAtecoDescr());
        String parentAteco = ateco;
        while (StringUtils.isEmpty(result.getMccCircInt()) && StringUtils.isNotEmpty(parentAteco)) {
            var parentTip = atecoToTip.get(parentAteco);
            if (parentTip != null && StringUtils.isNotBlank(parentTip.getMccCircInt())) {
                result.setMccCircInt(parentTip.getMccCircInt());
                result.setMccCircPbt(parentTip.getMccCircPbt());
                result.setMccCricPbtUn(parentTip.getMccCricPbtUn());
                result.setMccIntUn(parentTip.getMccIntUn());
            }
            parentAteco = Utils.removeLastChar(parentAteco);
        }
        if (StringUtils.isEmpty(result.getMccCircInt())) {
            log.logMessage(Level.ERROR, "Impossibile trovare il codice MCC per l'ateco {}", ateco);
            throw new MccException("Impossibile trovare il codice MCC per l'ateco " + ateco);
        }
        return result;
    }

    public boolean isBlacklisted(String ateco) {
        val tip = this.tipByAteco(ateco);
        return properties.getMccBlackList().contains(tip.getMccCircInt());
    }


}

