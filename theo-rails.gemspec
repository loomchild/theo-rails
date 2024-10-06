Gem::Specification.new do |spec|
  spec.name        = "theo-rails"
  spec.version     = "0.3.1"
  spec.summary     = "Theo is HTML-like template language"
  spec.description = "HTML-like template language for Rails with natural partial syntax"
  spec.authors     = ["Jarek Lipski"]
  spec.email       = "jarek@jareklipski.com"
  spec.homepage    = "https://github.com/loomchild/theo-rails"
  spec.license     = "MIT"
  spec.files       = Dir['lib/**/*.rb'] + Dir['app/**/*']
  spec.metadata    = {
    "homepage_uri" => "https://github.com/loomchild/theo-rails",
    "source_code_uri" => "https://github.com/loomchild/theo-rails"
  }
  spec.required_ruby_version = ">= 3.2"
  spec.add_development_dependency "rspec", "~> 3"
end
