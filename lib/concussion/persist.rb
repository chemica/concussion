module Concussion
  module Persist
    def perform(*args)
      Concussion.retire @guid
      super *args
    end

    def later(time, *args)
      time = Time.now if time < Time.now
      seconds = (time - Time.now).to_i
      @guid = SecureRandom.uuid
      Concussion.persist(self.class, @guid, time, *args)

      after(seconds) { perform(*args) }
    end
  end
end