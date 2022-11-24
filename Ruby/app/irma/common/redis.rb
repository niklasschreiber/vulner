# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151208
#
require 'redis'
require 'uri'

#
class InvalidRedisLockValue < StandardError; end

#
class Redis
  DEFAULT_URL = "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}/0".freeze
  class <<self
    # connect like 3.0 gem style (using the normalize_options)
    def connect(hash = {})
      options = hash.dup
      options[:path] ||= ENV['REDIS_SOCKET'] if ENV['REDIS_SOCKET']

      unless options[:path]
        uri = URI.parse(options.delete(:url) || ENV['REDIS_URL'] || DEFAULT_URL)

        options[:host] = uri.host
        options[:port] = uri.port
        options[:db]   = File.basename(uri.path)
      end

      new(options)
    end

    def current
      @redis ||= connect
    end
  end

  def remove_all_keys
    k = keys
    del(*k) unless k.empty?
    k
  end

  # --- LOCK --------------------------------------------------
  DEFAULT_RETRIES = (ENV['REDIS_LOCK_RETRIES'] || '5').to_i
  DEFAULT_RETRY_DELAY = (ENV['REDIS_LOCK_RETRY_DELAY'] || '200').to_i # milliseconds
  CLOCK_DRIFT_FACTOR = 0.01

  UNLOCK_SCRIPT = '
       if redis.call("get",KEYS[1]) == ARGV[1] then
       return redis.call("del",KEYS[1])
       else
       return 0
       end'.freeze

  def m_lock(resource:, value:, expire_ms:, write: true, **opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    num_retries = opts[:num_retries] || DEFAULT_RETRIES
    retry_delay = opts[:retry_delay] || DEFAULT_RETRY_DELAY
    clock_drift_factor = opts[:clock_drift_factor] || CLOCK_DRIFT_FACTOR

    raise InvalidRedisLockValue, "Valore '#{value}' non valido per il lock di '#{resource}'" unless value.is_a?(Hash)
    val = value.to_json
    num_retries.times do |r|
      start_time = (Time.now.to_f * 1000).to_i
      lock_res = lock_instance(resource: resource, write: write, json_value: val, expire_ms: expire_ms, dont_print_exception: opts[:dont_print_exception])

      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 milliescond, plus 1 millisecond min drift
      # for small TTLs.
      drift = (expire_ms * clock_drift_factor).to_i + 2
      validity_time = expire_ms - ((Time.now.to_f * 1000).to_i - start_time) - drift
      if lock_res && validity_time > 0
        return { validity: validity_time, resource: lock_res, value: JSON.parse(val).symbolize_keys }
      end
      # Wait a random delay before to retry
      sleep(retry_delay / 1000.0) if num_retries > (r + 1)
    end
    false
  end

  def m_unlock(resource:, value:)
    client.call([:eval, UNLOCK_SCRIPT, 1, resource, value.to_json]) == 0 ? false : true
  rescue
    # Nothing to do, unlocking is just a best-effort attempt.
    nil
  end

  def lock_instance(resource:, json_value:, expire_ms:, write: true, dont_print_exception: false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    key = if write
            scan(0, match: "#{resource}:read*")[1].empty? ? resource : nil
          else
            get(resource) ? nil : "#{resource}:read#{rand}"
          end
    return false unless key
    client.call([:set, key, json_value, :nx, :px, expire_ms]) ? key : false
  rescue => e
    STDERR.puts "#{write ? 'Write' : 'Read'} lock per la risorsa #{resource} con value #{json_value} fallito (key = #{key}): #{e}, #{e.backtrace}" unless dont_print_exception
    return false
  end
  # -----------------------------------------------------------
end

#
module Irma
  SUBSCRIBE_EXIT = 'exit_'.freeze
  SubscribeMutex = Mutex.new

  def self.subscribe_exit_message
    @subscribe_exit_message ||= SUBSCRIBE_EXIT + "#{Irma.host_ip}_#{Process.pid}"
  end

  # rubocop:disable Style/GlobalVars, Style/RescueModifier
  def self._publish(queue, message)
    Redis.current.publish(queue, message)
  rescue => e
    logger.error("Pubblicazione sulla coda #{queue} di Redis del messaggio #{message} fallita: #{e}")
  end

  def self.publish(queue, message, opts = {})
    if opts[:delay]
      Thread.new do
        sleep opts[:delay]
        _publish(queue, message)
      end
    else
      _publish(queue, message)
    end
  end

  def self.subscribe_exit(queue)
    publish(queue, subscribe_exit_message)
  end

  def self.unsubscribe(redis)
    with_subscribed do |s|
      redis.unsubscribe rescue nil
      redis.client.disconnect rescue nil
      s.delete(redis)
    end
  end

  def self.unsubscribe_all(max_wait: nil) # rubocop:disable Metrics/AbcSize
    max_wait ||= 3
    logger.info("Unsubscribe all redis channels with max_wait=#{max_wait}")
    with_subscribed do |s|
      s.values.flatten.uniq.each do |channel|
        subscribe_exit(channel)
      end
    end
    return unless max_wait && max_wait > 0
    start_time = Time.now
    sleep(0.1) until @subscribed.empty? || (Time.now - start_time) > max_wait
  end

  def self.with_subscribed(&_block)
    SubscribeMutex.synchronize do
      @subscribed ||= {}
      yield(@subscribed)
    end
  end

  def self.subscribe(queue, opts = {}, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    ready = nil
    t = Thread.new do
      begin
        redis = Redis.connect
        channels = [queue].flatten.uniq
        with_subscribed do |s|
          s[redis] = channels
        end
        # puts "BEFORE SUBSCRIBE #{channels}"
        redis.subscribe(*channels) do |on|
          if opts[:subscribe]
            on.subscribe do |channel, subscriptions|
              opts[:subscribe].call(channel, subscriptions)
            end
          end
          if opts[:unsubscribe]
            on.unsubscribe do |channel, subscriptions|
              opts[:unsubscribe].call(channel, subscriptions)
            end
          end
          on.message do |channel, message|
            if message == subscribe_exit_message || (defined?($stop) && $stop)
              unsubscribe(redis)
            elsif !message.start_with?(SUBSCRIBE_EXIT)
              block.call(channel, message)
            end
          end
          ready = true
        end
      rescue Redis::BaseConnectionError
        unsubscribe(redis)
        sleep 1
        logger.warn("Redis connection problems, retry subscription for #{queue} thread")
        retry unless defined?($stop) && !$stop
      rescue => e
        logger.warn("Unexpected exception: #{e}")
      ensure
        unsubscribe(redis)
      end
      logger.info("Exiting from subscribe #{queue} thread")
    end
    sleep(0.01) while ready.nil?
    if ready
      opts[:blocking] ? t.join : t
    else
      ready
    end
  end
end
