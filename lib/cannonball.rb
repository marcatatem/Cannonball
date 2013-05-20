require 'cannonball/version'
require 'cannonball/rule'
require 'addressable/uri'
require 'public_suffix'
require 'yaml'
require 'ethon'
require 'ostruct'
require 'digest/md5'
require 'redis'
require 'redis/namespace'

module Cannonball

  @@config = OpenStruct.new({
    should_test_possible_duplicate_uri: false,
    useragent: 'Cannonball/1.0',
    should_cache: true,
    redis: nil,
    redis_namespace: 'Cannonball'
  })

  @@curl_options = {
    followlocation: false,
    ssl_verifyhost: 0,
    ssl_verifypeer: false,
    timeout: 10,
    useragent: @@config.useragent
  }

  # load canonicalization rules
  C14N = YAML.load_file(File.join(File.dirname(__FILE__), 'cannonball', 'c14n.yml'))

  # load default rules
  Dir[File.join(File.dirname(__FILE__), 'rules', '*.rb')].each{ |x| require x }

  # configuration block
  def self.configure
    yield @@config
  end

  def self.configuration
    @@config
  end

  def self.curl_options
    @@curl_options
  end

  def self.redis
    @@redis ||= if (@@config.redis).is_a?(Redis)
      Redis::Namespace.new(@@config.redis_namespace, @@config.redis)
    else
      Redis::Namespace.new(@@config.redis_namespace, Redis.new)
    end
  end

  class URI
    
    attr_accessor :_uri, :_domain, :_subdomain

    def initialize uri, base_uri = nil
      @_uri = Addressable::URI.parse(uri.to_s)
      @_uri = Addressable::URI.join(base_uri.to_s, @_uri.to_s.gsub(/^\/\//, '/')) unless base_uri.nil?
      canonicalize
    end

    def inspect
      "<##{self.class.name} id:0x#{__id__.to_s(16)} url=\"#{@_uri.to_s}\">"
    end

    def to_s
      @_uri.to_s
    end

    def root suffix = nil
      address = Addressable::URI.parse(@_uri.to_s)
      address.path = suffix
      self.class.new(address.normalize)
    end

    def robots_path
      root('/robots.txt')
    end

    def domain
      @_domain ||= @_uri.host.nil? ? nil : PublicSuffix.parse(Addressable::IDNA.to_unicode(@_uri.host)).domain
    end

    def subdomain
      @_subdomain ||= @_uri.host.nil? ? nil : PublicSuffix.parse(Addressable::IDNA.to_unicode(@_uri.host)).subdomain
    end

    def display_url
      address = @_uri.clone
      address.host = Addressable::IDNA.to_unicode(address.host)
      address.to_s
    end

    def may_contain_useless_params?
      return false if @_uri.query_values.nil?
      ( @_uri.query_values.keys & C14N['suspicious_params'] ).length > 0
    end

    protected

      def canonicalize

        # apply rules
        unless ( rule = Cannonball::Rule.all[domain] ).nil?
          @_uri = rule.process(@_uri)
        end

        # default to http if no protocol is specified and the domain looks valid
        if @_uri.scheme.nil? && !@_uri.path.nil?
          if PublicSuffix.valid?(@_uri.path.split('/').first)
            @_uri = Addressable::URI.parse("http://#{@_uri}")
          else
            raise ArgumentError, 'Scheme can neither be identified nor assumed as http.'
          end
        end

        # turn hashbang fragments into _escaped_fragment_
        if (!@_uri.fragment.nil? && @_uri.fragment[0] == '!')
          @_uri.query_values = {} if @_uri.query_values.nil?
          @_uri.query_values = @_uri.query_values.merge({ _escaped_fragment_: @_uri.fragment.match(/\!(.+)/)[1] }) rescue @_uri.query_values
        end

        # normalize url
        @_uri = @_uri.normalize

        # remove directory index
        @_uri.path = @_uri.path.gsub(/\/(#{C14N['directory_index'].join('|')})/i, '/')

        # remove duplicate slashes
        @_uri.path = @_uri.path.squeeze('/')

        unless @_uri.query_values.nil?
          @_uri.query_values = @_uri.query_values.sort # sort query parameters
          @_uri.query_values = @_uri.query_values.delete_if{ |k,v| C14N['useless_params'].include?(k) } # remove useless query parameters
        end        

        # remove fragments altogether
        @_uri.fragment = nil

        # perform a quick check if uri contains possible useless params
        if ( parent_module = Module.nesting.last ).configuration.should_test_possible_duplicate_uri && may_contain_useless_params?
          if !parent_module.redis.nil? && parent_module.redis.exists("quarantine:#{subdomain}")
            @_uri
          elsif parent_module.configuration.should_cache && !parent_module.redis.nil? && parent_module.redis.sismember("domains", subdomain)
            @_uri.query_values = @_uri.query_values.delete_if{ |k,v| C14N['suspicious_params'].include?(k) } # remove useless query parameters
          else
            easy = Ethon::Easy.new
            easy.http_request @_uri.to_s, :get, parent_module.curl_options
            easy.perform
            if easy.response_code == 200 && response_is_text?(easy.response_headers)
              original = easy.response_body
              easy.http_request ( current_uri = possible_useless_params_striped_uri ).to_s, :get, parent_module.curl_options
              easy.perform
              if easy.response_code == 200 && response_is_text?(easy.response_headers)
                current = easy.response_body
                if Digest::MD5.hexdigest(original) == Digest::MD5.hexdigest(current) # contents are similar
                  @_uri.query = ( current_uri.query.nil? || current_uri.query.empty? ) ? nil : current_uri.query # change query string
                  if parent_module.configuration.should_cache && !parent_module.redis.nil?
                    parent_module.redis.sadd "domains", subdomain # cache
                  end
                end
              end
            else # we had an error fetching the original page (or one or multiple redirects)
              parent_module.redis.setex "quarantine:#{subdomain}", 86_400, @_uri.to_s
            end
          end
        end

        # remove ? of empty query strings
        @_uri.query = nil if (!@_uri.query.nil? && @_uri.query.empty?)

      end

      def possible_useless_params_striped_uri
        return @_uri if @_uri.query_values.nil? # shouldn't happen but hey
        uri = @_uri.clone
        uri.query_values = uri.query_values.delete_if{ |k,v| C14N['suspicious_params'].include?(k) }
        uri
      end

      def mime_type_from_headers headers
        return nil if ( matches = headers.match(/Content-Type:\s*([^\/]+\/[^\s]+).+/i) ).nil?
        (*mime = MIME::Types[matches[1].strip]).first rescue nil
      end

      def response_is_text? response_headers
        !( r = mime_type_from_headers(response_headers) ).nil? && r.media_type == 'text'
      end

  end

end