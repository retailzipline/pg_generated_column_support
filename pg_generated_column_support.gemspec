require_relative "lib/pg_generated_column_support/version"

Gem::Specification.new do |spec|
  spec.name        = "pg_generated_column_support"
  spec.version     = PgGeneratedColumnSupport::VERSION
  spec.authors     = ["Jeremy Baker"]
  spec.email       = ["jeremy@retailzipline.com"]
  spec.homepage    = "https://github.com/retailzipline/pg_generated_column_support"
  spec.summary     = "Adds support for postgresql generated columns in ActiveRecord 6.1.5"
  spec.description = "Rails 6.1.5 backport for the Rails 7 generated column support"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/retailzipline/pg_generated_column_support"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "activerecord", "~> 6.1.5"
end
