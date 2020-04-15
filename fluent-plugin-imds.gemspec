lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-imds"
  spec.version = "0.1.0"
  spec.authors       = ["Matt Juel "]
  spec.email         = ["v-majuel@microsoft"]

  spec.summary       = %q{Filter plugin to add Azure IMDS metadata to logs emitted}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/juelm/fluent-plugin-imds"
  spec.license       = "MIT"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
