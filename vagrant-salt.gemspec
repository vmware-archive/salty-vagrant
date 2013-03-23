# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "vagrant-salt"
  s.version     = "0.4.0"
  s.authors     = ["Alec Koumjian", "Kiall Mac Innes", "Pedro Algarvio"]
  s.email       = ["akoumjian@gmail.com", "kiall@managedit.ie", "pedro@algarvio.me"]
  s.homepage    = "https://github.com/saltstack/salty-vagrant"
  s.summary     = %q{Vagrant Salt Stack provisioner plugin}
  s.description = %q{Vagrant Salt Stack provisioner plugin}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "templates"]

  s.add_runtime_dependency "vagrant"

  # get an array of submodule dirs by executing 'pwd' inside each submodule
  `git submodule --quiet foreach pwd`.split($\).each do |submodule_path|
    # for each submodule, change working directory to that submodule
    Dir.chdir(submodule_path) do

      # issue git ls-files in submodule's directory
      submodule_files = `git ls-files`.split("\n")

      # prepend the submodule path to create absolute file paths
      submodule_files_fullpaths = submodule_files.map do |filename|
        "#{submodule_path}/#{filename}"
      end

      # remove leading path parts to get paths relative to the gem's root dir
      submodule_files_paths = submodule_files_fullpaths.map do |filename|
        filename.gsub "#{File.dirname(File.expand_path(File.dirname(__FILE__)))}/", ""
      end

      # add relative paths to gem.files
      s.files += submodule_files_paths
    end
  end

end
