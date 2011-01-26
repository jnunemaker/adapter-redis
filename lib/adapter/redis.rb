require 'adapter'
require 'redis'

module Adapter
  module Redis
    def read(key)
      decode(client.get(key_for(key)))
    end

    def write(key, value)
      client.set(key_for(key), encode(value))
    end

    def delete(key)
      read(key).tap { client.del(key_for(key)) }
    end

    def clear
      client.flushdb
    end

    # Pretty much stolen from redis objects
    # http://github.com/nateware/redis-objects/blob/master/lib/redis/lock.rb
    def lock(name, options={}, &block)
      key           = name.to_s
      start         = Time.now
      acquired_lock = false
      expiration    = nil
      expires_in    = options.fetch(:expiration, 1)
      timeout       = options.fetch(:timeout, 5)

      while (Time.now - start) < timeout
        expiration    = generate_expiration(expires_in)
        acquired_lock = client.setnx(key, expiration)
        break if acquired_lock

        old_expiration = client.get(key).to_f

        if old_expiration < Time.now.to_f
          expiration     = generate_expiration(expires_in)
          old_expiration = client.getset(key, expiration).to_f

          if old_expiration < Time.now.to_f
            acquired_lock = true
            break
          end
        end

        sleep 0.1
      end

      raise(LockTimeout.new(name, timeout)) unless acquired_lock

      begin
        yield
      ensure
        client.del(key) if expiration > Time.now.to_f
      end
    end

    # Defaults expiration to 1
    def generate_expiration(expiration)
      (Time.now + (expiration || 1).to_f).to_f
    end
  end
end

Adapter.define(:redis, Adapter::Redis)