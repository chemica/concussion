require "concussion/version"
require "concussion/redis_adapter"
require "concussion/persist"

module Concussion

  class << self
    attr_accessor :store
  end

  def self.persist(klass, guid, time, *args)
    store.set guid, {klass: klass.name, time: time, args: args}
  end

  def self.retire(guid)
    store.del guid
  end

  def self.init
    store.find_each do |guid, data|
      retire guid
      Object.const_get(data[:klass]).new.later data[:time], *(data[:args])
    end
  end

end
