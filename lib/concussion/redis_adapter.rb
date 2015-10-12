# An adapter class must create an instance object which responds to:
#
# get([key])          # returns data as an object (any ruby construct that can be Marshaled)

# set([key], [data])  # sets data (a Marshalable object) against a text key.
#                       Returns data if successful, or raises an exception.

# del([key])          # Deletes data against [key] (String)

# find_each(opts)     # Returns an enumerator or can be passed a block.
#                       Enumerator iterates through all stored keys and yields the key
#                       and the associated data (as a Ruby object)
#                       find_each may take options as a hash (opts).
#                       Currently it should only expect one option: :batch_size
#                       which takes an integer.
#
# An adapter class instance must also provide a 'namespace' accessor, which can optionally be set to allow
# multiple stores on the same storage device. In the case of Redis, this is added to the hash key.

# An adapter class must allow 'namespace' to be set using the options on the 'initialize' method.
#

# This adapter uses a Redis hash, as providing a list of normal keys matching a pattern is problematic.
# We manage key/value expiration outside Redis, to avoid jobs disappearing while the server is inactive.

module Concussion
  class RedisAdapter

    attr_accessor :redis, :namespace

    KEY                = "--concussion-redis-adapter-store"
    DEFAULT_BATCH_SIZE = 1000

    def initialize(opts = {})
      self.redis = opts.fetch(:redis) { Redis.new }
      self.namespace = opts.fetch(:namespace) { "" }
    end

    def namespaced_key
      "#{namespace}#{KEY}"
    end

    def get(key)
      decode_from_redis redis.hget(namespaced_key, key)
    end

    def set(key, data)
      redis.hset(namespaced_key, key, encode_for_redis(data))
      data
    end

    def del(key)
      redis.hdel(namespaced_key, key)
    end

    def find_each(opts = {})
      return enum_for(:find_each, opts) unless block_given?
      batch_size = opts.fetch(:batch_size) { DEFAULT_BATCH_SIZE }
      keys = redis.hkeys namespaced_key

      keys.each_slice(batch_size).each do |key_slice|
          Hash[key_slice.zip(redis.hmget(namespaced_key, key_slice))].each do |key, data|
            yield key, decode_from_redis(data)
          end
      end
    end

    private

    def decode_from_redis(str)
      val = str.to_s.force_encoding('iso-8859-1')
      val.present? ? Marshal.restore(val) : nil
    end

    def encode_for_redis(data)
      Marshal.dump(data)
    end
  end
end