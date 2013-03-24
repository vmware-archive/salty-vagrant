require "pathname"
require "i18n"
require "vagrant-salt/plugin"

module VagrantPlugins
  module Salt

    lib_path = Pathname.new(File.expand_path("../vagrant-salt", __FILE__))
    autoload :Errors, lib_path.join("errors")

    @source_root = Pathname.new(File.expand_path("../../", __FILE__))

    I18n.load_path << File.expand_path("templates/locales/en.yml", @source_root)
    I18n.reload!

  end
end