package it.poste.onebooking.services;

import java.util.Enumeration;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import javax.annotation.PostConstruct;
import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import com.google.common.collect.ImmutableMap;
import com.google.common.util.concurrent.RateLimiter;

import it.poste.ngav.AppData;
import it.poste.onebooking.exceptions.OBWsAppException;
import it.poste.onebooking.exceptions.OBWsAppException.ErrorCode;
import lombok.extern.log4j.Log4j;

@Service
@Log4j
public class NewWsRateLimiter {

	
	@Autowired
	AppData appData;
	
	public enum EndPointKey {
		ROOT, PLANT, REGION, STAT, TICKET
	};

	protected static Map<EndPointKey, Double> endPointRates;
	protected static Double ipRates;
	protected static Double salaRates;
	protected Integer defaultTimeoutMs;
	protected Integer rateLimitEnabled;

	protected LoadingCache<EndPointKey, RateLimiter> endPointCacheLimits;
	protected LoadingCache<String, RateLimiter> ipAddressCacheLimits;
	protected LoadingCache<Long, RateLimiter> salaCacheLimits;
	
	private static final int IP_ADDRESS_CACHE_MAX_ENTRIES = 65536;
	private static final int SALA_MAX_ENTRIES = 4096;
	private static final int ENDPOINT_MAX_ENTRIES = 64;
	
	@PostConstruct
	protected void init() {
		log.debug("WS: init WsRateLimiter");
		endPointRates = new ImmutableMap.Builder<EndPointKey, Double>().put(EndPointKey.ROOT, appData.getPropertyValueDouble("ratelimit.endpoint.root", 10.0))
				.put(EndPointKey.PLANT, appData.getPropertyValueDouble("ratelimit.endpoint.plant", 10.0)).put(EndPointKey.REGION, appData.getPropertyValueDouble("ratelimit.endpoint.region", 10.0))
				.put(EndPointKey.STAT, appData.getPropertyValueDouble("ratelimit.endpoint.stat", 10.0)).put(EndPointKey.TICKET, appData.getPropertyValueDouble("ratelimit.endpoint.ticket", 5.0))
				.build();

		ipRates = appData.getPropertyValueDouble("ratelimit.ipaddress", 10.0);
		salaRates = appData.getPropertyValueDouble("ratelimit.sala", 12.0/60.0);
		defaultTimeoutMs = appData.getPropertyValueInteger("ratelimit.default_timeout_ms", 500);
		rateLimitEnabled = appData.getPropertyValueInteger("ratelimit.enabled", 1);

		if (rateLimitEnabled.equals(1)) {
			log.info("Rate Limit enabled");
		} else {
			log.info("Rate Limit disabled");			
		}
		
		endPointCacheLimits = CacheBuilder.newBuilder().maximumSize(ENDPOINT_MAX_ENTRIES).build(new EndPointCacheLoader());
		ipAddressCacheLimits = CacheBuilder.newBuilder().maximumSize(IP_ADDRESS_CACHE_MAX_ENTRIES).build(new IpAddressCacheLoader());
		salaCacheLimits = CacheBuilder.newBuilder().maximumSize(SALA_MAX_ENTRIES).build(new SalaCacheLoader());
	}

	private final static class IpAddressCacheLoader extends CacheLoader<String, RateLimiter> {
		@Override
		public RateLimiter load(String key) {
			return RateLimiter.create(ipRates);
		}
	}

	private final static class SalaCacheLoader extends CacheLoader<Long, RateLimiter> {
		@Override
		public RateLimiter load(Long key) {
			return RateLimiter.create(salaRates);
		}
	}

	private final static class EndPointCacheLoader extends CacheLoader<EndPointKey, RateLimiter> {
		@Override
		public RateLimiter load(EndPointKey key) {
			return RateLimiter.create(endPointRates.get(key));
		}
	}

	public void isRequestPermitted(HttpServletRequest request, EndPointKey endPointKey, Long salaId) throws OBWsAppException {
		
		// for testing purposes
		if (request == null) {
			return;
		}
		
		if (!rateLimitEnabled.equals(1)) {
			return;
		}

		boolean pass = true;
		String message="";
		
		// check endpoint limit
		if (pass && endPointKey != null && endPointRates.get(endPointKey) > 0) {
			pass &= endPointCacheLimits.getUnchecked(endPointKey).tryAcquire(defaultTimeoutMs, TimeUnit.MILLISECONDS);
		}
		// check ipAddress limit
		if (pass && request != null && ipRates > 0) {
			pass &= ipAddressCacheLimits.getUnchecked(remoteIp(request)).tryAcquire(defaultTimeoutMs, TimeUnit.MILLISECONDS);
		}
		// check sala limit
		if (pass && salaId != null && salaRates > 0) {
			pass &= salaCacheLimits.getUnchecked(salaId).tryAcquire(defaultTimeoutMs, TimeUnit.MILLISECONDS);
		}
		if (pass == false) {
			throw new OBWsAppException(ErrorCode.ERR_LIMIT_REACHED);
		}
	}

	public String remoteIp(final HttpServletRequest request) {
		final Enumeration<String> headers = request.getHeaders("X-FORWARDED-FOR");
		if (headers == null) {
		} else {
			while (headers.hasMoreElements()) {
				final String[] ips = headers.nextElement().split(",");
				for (int i = 0; i < (ips != null ? ips.length : 0); i++) {
					final String proxy = (ips[i] != null ? ips[i].trim() : "");
					if (!"unknown".equals(proxy) && !proxy.isEmpty()) {
						return proxy;
					}
				}
			}
		}
		return request.getRemoteAddr();
	}


}
