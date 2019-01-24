# frozen_string_literal: true

# rspec configuration
rspec_opts = {
  cmd: 'rspec --format documentation',
  all_on_start: true,
  run_all: { cmd: 'rspec --format progress --profile 5' }
}

rubocop_opts = {
  all_on_start: true,
  cli: ['--display-cop-names']
}

group :gem, halt_on_fail: true do
  guard :rspec, rspec_opts do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  end

  guard :rubocop, rubocop_opts do
    watch(%r{^spec/.+\.rb$})
    watch(%r{^lib/(.+)\.rb$})
  end
end
