# Concussion

[Sucker Punch](https://github.com/brandonhilkert/sucker_punch) is an awesome gem which allows in-process background jobs. If you want to run jobs at a particular time,
however, there is a downside. Jobs are only held in memory, so restarting the process will kill any pending jobs.

Most web apps will be using some kind of data store however, so Concussion allows them to be persisted.

## WARNING

Concussion is currently untested, proof-of-concept code. It has not been used in production and has no automated test suite. Use at your own risk. I cannot be held responsible for any loss of data, sanity or clients that may result from use of this code.

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
 
Any jobs which were set to run while the server was offline will be immediately run by the initializer. For 
this reason the initializer must be wrapped in an 'after_initialize' block to ensure all other components of the 
application are ready for use.

You can use the namespace to target a particular server. If you have a multiple (dedicated) server set-up, for example, the following initializer will ensure that jobs are only run by the server that created them:

```ruby
require "socket"

Rails.application.config.after_initialize do

  namespace = "concussion-#{Socket.gethostname}"
  redis = Redis.new(:host => "localhost", :port => 6379)
  Concussion.store = Concussion::RedisAdapter.new(redis: redis, namespace: namespace)
  Concussion.init
end
```

By adding the host name to the namespace, jobs are linked to that particular server. For scaling with Heroku see below.


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

## Use of ActiveRecord models and other complex data types

Because jobs need to be persisted as marshalled objects, you must be careful with the parameters you pass to 
them. Passing an ActiveRecord object model instance, for example, will quite likely cause errors - especially
in development when you can't be sure that all constants have been loaded. They are also bulky items which
could clog up your persistent storage if you create a lot of jobs and space is limited.

It is better to pass an ID for the model and find it again from within the job. Try to think in a similar way
when it comes to other complex objects and avoid passing lambdas or Procs.

## Scaling with Heroku

It wasn't the reason for creating the gem, but Sucker Punch is popular at least partly because it allows background jobs within a single web dyno on Heroku.

Although Concussion will 'just work' to an extent, you will have to be happy in the knowledge that jobs could be run by more than one server if you scale up. This may not be a problem if you're only doing light database tasks, or if you know that you'll only ever have one dyno, but if you're sending out emails and you want to be able to scale at will, it could be a bit of a problem.

All-round amazing person Myst from Stack Overflow came up with the following (untested) strategy for handling scaling on Heroku:

You can use a runtime flag set in the Procfile which will tell a specific Dyno to process tasks or not process tasks. During runtime you can check the ARGV array for the flag.

Here is an experimental example Procfile with this distinction for a Rails application:

```
web: bundle exec rails server -p $PORT run_tasks
onlyweb: bundle exec rails server -p $PORT
```

When scaling, make sure you only scale the non task running Dynos:

```
heroku ps:scale web=1 onlyweb=4
```

In your initializer, do this:

```ruby
Rails.application.config.after_initialize do

  namespace = "concussion-jobs"
  redis = Redis.new(:host => "localhost", :port => 6379)
  Concussion.store = Concussion::RedisAdapter.new(redis: redis, namespace: namespace)
  if ARGV.include? 'run_tasks'
    Concussion.init
  end
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chemica/concussion. This project is 
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the 
[Contributor Covenant](https://github.com/chemica/concussion/blob/master/CODE_OF_CONDUCT.md) code of conduct. 

Or something. These words were automatically added to this gem, but they are good words so they can stay.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
