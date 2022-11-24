# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20160301

#
module Irma
  #
  IrmaException.define :LockException
  IrmaException.define :LockKeyInvalid,        message_key: :LOCK_CHIAVE_NON_VALIDA,               superclass: LockException
  IrmaException.define :LockModeInvalid,       message_key: :LOCK_MODO_NON_VALIDO,                 superclass: LockException
  IrmaException.define :LockKeyParamMissing,   message_key: :LOCK_PARAMETRI_DELLA_CHIAVE_MANCANTI, superclass: LockException
  IrmaException.define :LockAlreadyAcquired,   message_key: :LOCK_GIA_ACQUISITO,                   superclass: LockException
  IrmaException.define :LockRedisNotAvailable, message_key: :LOCK_REDIS_NON_DISPONIBILE,           superclass: LockException

  def self.lock_value(expire:, funzione:, account_id:, host: nil, attivita_id: nil)
    ts = Time.now
    { host: host || host_ip, process_pid: Process.pid, thread_id: Thread.current.object_id,
      funzione: funzione, account_id: account_id, attivita_id: attivita_id,
      start_date: ts.strftime('%Y%m%d%H%M%S'), expire: expire, end_date: (ts + expire).strftime('%Y%m%d%H%M%S')
    }
  end

  def self.lock_keys(pattern: nil, redis: nil, &block) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    r = (redis || Redis.connect)
    r.keys(LOCK_KEY_PREFIX + (pattern || '*')).select do |k|
      begin
        lv = r.get(k)
        if lv
          block ? block.call(r, k, JSON.parse(lv)) : true
        else
          false
        end
      rescue => e
        logger.warn("Ignoring error during lock check with key #{k}: #{e}")
      end
    end
  ensure
    r.client.disconnect if r && !redis
  end

  def self.rimuovi_locks_per_attivita(attivita_id, redis: nil, pattern: nil)
    lock_keys(redis: redis, pattern: pattern) do |r, k, lock_info|
      r.del(k) if lock_info['attivita_id'] == attivita_id
    end
  end

  def self.rimuovi_locks_per_host(skip_existing: true, redis: nil, pattern: nil)
    host = host_ip
    lock_keys(redis: redis, pattern: pattern) do |r, k, lock_info|
      r.del(k) unless (lock_info['host'] != host) || (skip_existing && Process.exists?(lock_info['process_pid']))
    end
  end

  def self.lock_full_keys(key:, **hash)
    # ---
    # se key e' un Array va interpretato come un array di full_keys
    return key if key.is_a?(Array)
    # ---
    raise LockKeyInvalid, key: key, allowed_values: Constant.values(:lock_key).join(', ') unless Constant.keys(:lock_key).include?(key)
    Constant.info(:lock_key, key)[:patterns].map do |key_pattern|
      begin
        format(key_pattern, hash)
      rescue => e
        raise LockKeyParamMissing, key_pattern: key_pattern, available_params: hash.inspect.to_s, exception: e.to_s
      end
    end
  end

  # rubocop:disable Style/RescueModifier
  def self.lock(key:, enable: true, expire: 3600, mode: LOCK_MODE_READ, **hash) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    redis = Redis.connect if enable
    e = nil
    crea_eventi = hash.fetch(:eventi, true)
    event_params = hash[:event_params] || {}
    locks = []
    if enable
      raise LockModeInvalid, mode: mode, allowed_values: Constant.values(:lock_mode).join(', ') unless Constant.values(:lock_mode).include?(mode)
      lock_full_keys(key: key, **hash).each do |full_key|
        locks << (lock = redis.m_lock(resource: full_key, expire_ms: expire * 1_000, write: (mode == LOCK_MODE_WRITE),
                                      value: lock_value(expire: expire, funzione: hash[:funzione], account_id: hash[:account_id], attivita_id: hash[:attivita_id]),
                                      host: hash[:host], dont_print_exception: hash[:dont_print_exception]))
        if lock
          Db::Evento.crea(TIPO_EVENTO_LOCK_ACQUISITO, event_params.merge(descr: "Acquisito #{mode} lock per la chiave '#{full_key}'", dettaglio: { lock_info: lock })) if crea_eventi
          next
        end
        begin
          redis.get(full_key)
        rescue => e
          raise LockRedisNotAvailable, full_key: full_key, exception: e.to_s
        end
        raise LockAlreadyAcquired, full_key: full_key, lock_value: (redis.get(full_key) || redis.keys("#{full_key}*").map { |k| redis.get(k) })
      end
    end
    hash[:logger].info("#{hash[:log_prefix]} lock acquisiti (#{locks})") if hash[:logger] && hash[:log_prefix] && enable
    yield(locks)
  rescue => e
    raise
  ensure
    begin
      locks.each do |lock|
        next unless lock
        hash[:logger].info("#{hash[:log_prefix]} lock rilasciato (#{lock})") if hash[:logger] && hash[:log_prefix]
        redis.m_unlock(resource: lock[:resource], value: lock[:value])
        if crea_eventi
          Db::Evento.crea(TIPO_EVENTO_LOCK_RILASCIATO, event_params.merge(descr: "Rilasciato #{mode} lock per la chiave '#{lock[:resource]}'#{e ? " per problemi (#{e})" : ''}",
                                                                          dettaglio: { lock_info: lock }))
        end
      end
    ensure
      redis.client.disconnect if enable rescue nil
    end
  end
end
