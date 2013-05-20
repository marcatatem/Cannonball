module Cannonball

  class Rule

    # load rules
    Dir[File.join(File.dirname(__FILE__), 'rules', '*.rb')].each{ |x| require x }

    # rule container
    @@rules = []

    def self.domain name
      @@rules << name
    end

  end

end
