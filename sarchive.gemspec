# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sarchive/version'

Gem::Specification.new do |spec|
  spec.name          = "sarchive"
  spec.version       = Sarchive::VERSION
  spec.licenses      = ["MIT"]
  spec.authors       = ["hogesuke"]
  spec.email         = ["miyado@gmail.com"]

  spec.summary       = "「さくらのクラウド」のアーカイブ作成を簡単にコンソールから実行するためのgemです"
  spec.description   = "このgemを使用することにより、コンソールから簡単に複数のディスクのアーカイブを作成できます。また、アーカイブ作成時に古いアーカイブの削除を同時に行うことも可能です。cronで定期的に実行するように設定することで、面倒なバックアップ作業を自動化できます。"
  spec.homepage      = "https://github.com/hogesuke/sarchive"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org/"
  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "thor"
  spec.add_dependency "saklient", "~> 0.0.2.8"
end
