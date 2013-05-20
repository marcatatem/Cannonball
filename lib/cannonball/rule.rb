module Cannonball

  class Rule

    # rule container
    @@rules = {}

    def self.domain name
      @@rules[name.to_s] = Object.const_get( if RUBY_VERSION.to_f >= 2.0
        caller_locations(1,1)[0].label
      else
        caller[0][/`([^']*)'/, 1]
      end.gsub(/<class:([^>]+)>/, '\1') )
    end

    def self.all
      @@rules
    end

  end

end
