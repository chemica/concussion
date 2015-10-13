# Concussion

Sucker Punch is an awesome gem which allows in-process background jobs. If you want to run jobs at a particular time,
however, there is a downside. Jobs are only held in memory, so restarting the process will kill any pending jobs.

Most web apps will be using some kind of data store however, so Concussion allows them to be persisted.

## WARNING

Concussion is currently untested code. It has not been used in production and has no automated test suite. Use at your 
own risk. I cannot be held responsible for any loss of data, sanity or clients that may result from use of this code.

The interface may also change radically in the following versions.

Currently only Redis can be used as a data store.

The gem has been published mainly as a placeholder.

You have been warned.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'concussion'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install concussion

## Usage

Concussion won't do much on its own. It needs to connect to a persistent storage, and for that it needs an adapter. For
now it comes bundled with a Redis adapter, but that will be extracted into its own gem in due course.

The adapter is a class with a simple interface, described in the redis adapter class comments.

To use Concussion in a Rails project, add an initializer containing something along the lines of the following code:

```ruby
# after_initialize is used to allow Redis to initialise first
Rails.application.config.after_initialize do
  namespace = "concussion-persistence"
  redis = Redis.new(:host => "localhost", :port => 6379)
  Concussion.store = Concussion::RedisAdapter.new(redis: redis, namespace: namespace)
  Concussion.init
end
```
 
Any jobs which are set to run while the server is offline will run immediately on the initializer being run. For 
this reason the initializer must be wrapped in an 'after_initialize' block to ensure all other components of the 
application are ready for use.

You can use the namespace to target a particular server. If you have a two server set-up, for example, the following 
initializer will ensure that jobs are only run by the server that created them:

```ruby
require "socket"

Rails.application.config.after_initialize do

  namespace = "concussion-#{Socket.gethostname}"
  redis = Redis.new(:host => "localhost", :port => 6379)
  Concussion.store = Concussion::RedisAdapter.new(redis: redis, namespace: namespace)
  Concussion.init
end
```

By adding the host name to the namespace, jobs are linked to the particular server.


When defining a job, use the following form:

```ruby
class DoSomethingJob
  include SuckerPunch::Job
  prepend Concussion::Persist

  def perform(opts = {})
    MyThingDoer.new(opts).do_thing
  end

end
```

And call it with:

```ruby
run_at = Time.now + 5.hours
DoSomethingJob.new.async.later run_at, opts
```

All done.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chemica/concussion. This project is 
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the 
[Contributor Covenant](contributor-covenant.org) code of conduct. Or something. These words were automatically
added to this gem, but they are good words so they can stay.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
