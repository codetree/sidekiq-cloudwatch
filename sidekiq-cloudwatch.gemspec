Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-cloudwatch'
  spec.version       = '0.4.0'
  spec.author        = 'Andrew Conrad'
  spec.email         = 'andrew@codetree.com'

  spec.summary       = 'Publish Sidekiq metrics to AWS CloudWatch'
  spec.description   = <<-DESCRIPTION
    Upload metrics to Cloudwatch using a thread running inside your Sidekiq processes
    Enables general monitoring and autoscaling based on queue activity.
    Can utilize Sidekiq Enterprise leader election capabilities
  DESCRIPTION
  spec.homepage      = 'https://github.com/sj26/sidekiq-cloudwatchmetrics'
  spec.license       = 'MIT'

  spec.files         = Dir['README.md', 'LICENSE', 'lib/**/*.rb']

  spec.required_ruby_version = '>= 2.2.2'

  spec.add_dependency 'rake', '~> 10'

  spec.add_runtime_dependency 'aws-sdk-cloudwatch', '~> 1.6'
  spec.add_runtime_dependency 'sidekiq', '~> 5.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rubocop', '~> 0.63'
end
