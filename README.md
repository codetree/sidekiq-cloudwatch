# Sidekiq-CloudWatch

Upload metrics to Cloudwatch using threads running inside your Sidekiq processes.  Enables general monitoring of Sidekiq through Cloudwatch and autoscaling of your containers based on queue activity.

Can be utilized with Sidekiq Enterprise as it natively recognizes leader election, otherwise it assigns a leader role.

## Installation

Add this gem to your application’s Gemfile near sidekiq and then run `bundle install`:

```ruby
gem "sidekiq"
gem "sidekiq-cloudwatch"
```

## Usage

Add near your Sidekiq configuration, like in `config/initializers/sidekiq.rb` in Rails:

```ruby
require "sidekiq"
require "sidekiq/cloudwatchmetrics"

Sidekiq::CloudWatchMetrics.configure do |config|
  config.aws_region_name = ENV.fetch('AWS_REGION_NAME')
  config.aws_access_key_id = ENV.fetch('AWS_ACCESS_KEY_ID')
  config.aws_secret_access_key = ENV.fetch('AWS_SECRET_ACCESS_KEY')
  config.select_leader = true # defaults to true; can be boolean
  config.use_mock = true # defaults to false; set true for deterministic results and no AWS traffic'
end

Sidekiq::CloudWatchMetrics.enable!
```

This requires explicit AWS credentials that can publish CloudWatch metrics

## Development

After checking out the repo, run `bundle setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/sidekiq/cloudwatch.rb` and the gemspec, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub @ [sidekiq-cloudwatch](https://github.com/codetree/sidekiq-cloudwatch).

## Thanks

This was heavily inspired by [@sj](https://github.com/sj26) and his [Sidekiq-cloudwatchmetrics](https://github.com/sj26/sidekiq-cloudwatchmetrics).  We looked to improve upon his work by extracting key configuration details, creating a defacto leader approach to cut down on noise, and making it compatible with ruby 2.2.2 and higher (same as sidekiq)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

