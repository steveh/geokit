require 'net/http'
require 'ipaddr'
require 'rexml/document'
require 'yaml'
require 'timeout'
require 'logger'

module Geokit

  class TooManyQueriesError < StandardError; end

  module Inflector

    extend self

    def titleize(word)
      humanize(underscore(word)).gsub(/\b([a-z])/u) { $1.capitalize }
    end

    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/u,'\1_\2').
      gsub(/([a-z\d])([A-Z])/u,'\1_\2').
      tr("-", "_").
      downcase
    end

    def humanize(lower_case_and_underscored_word)
      lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end

    def snake_case(s)
      return s.downcase if s =~ /^[A-Z]+$/u
      s.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/u, '_\&') =~ /_*(.*)/
        return $+.downcase

    end

    def url_escape(s)
    s.gsub(/([^ a-zA-Z0-9_.-]+)/nu) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.tr(' ', '+')
    end

    def camelize(str)
      str.split('_').map {|w| w.capitalize}.join
    end
  end

  # Contains a range of geocoders:
  #
  # ### "regular" address geocoders
  # * Yahoo Geocoder - requires an API key.
  # * Geocoder.us - may require authentication if performing more than the free request limit.
  # * Geocoder.ca - for Canada; may require authentication as well.
  # * Geonames - a free geocoder
  #
  # ### address geocoders that also provide reverse geocoding
  # * Google Geocoder - requires an API key.
  #
  # ### IP address geocoders
  # * IP Geocoder - geocodes an IP address using hostip.info's web service.
  # * Geoplugin.net -- another IP address geocoder
  #
  # ### The Multigeocoder
  # * Multi Geocoder - provides failover for the physical location geocoders.
  #
  # Some of these geocoders require configuration. You don't have to provide it here. See the README.
  module Geocoders
    @@proxy_addr = nil
    @@proxy_port = nil
    @@proxy_user = nil
    @@proxy_pass = nil
    @@request_timeout = nil
    @@yahoo = 'REPLACE_WITH_YOUR_YAHOO_KEY'
    @@google = 'REPLACE_WITH_YOUR_GOOGLE_KEY'
    @@geocoder_us = false
    @@geocoder_ca = false
    @@geonames = false
    @@provider_order = [:google,:us]
    @@ip_provider_order = [:geo_plugin,:ip]
    @@logger=Logger.new(STDOUT)
    @@logger.level=Logger::INFO
    @@domain = nil

    def self.__define_accessors
      class_variables.each do |v|
        sym = v.to_s.delete("@").to_sym
        unless self.respond_to? sym
          module_eval <<-EOS, __FILE__, __LINE__
            def self.#{sym}
              value = if defined?(#{sym.to_s.upcase})
                #{sym.to_s.upcase}
              else
                @@#{sym}
              end
              if value.is_a?(Hash)
                value = (self.domain.nil? ? nil : value[self.domain]) || value.values.first
              end
              value
            end

            def self.#{sym}=(obj)
              @@#{sym} = obj
            end
          EOS
        end
      end
    end

    __define_accessors

    # Error which is thrown in the event a geocoding error occurs.
    class GeocodeError < StandardError; end

  end
end

require 'geokit/geocoders/geocoder'
require 'geokit/geocoders/ca_geocoder'
require 'geokit/geocoders/geo_plugin_geocoder'
require 'geokit/geocoders/geonames_geocoder'
require 'geokit/geocoders/google_geocoder'
require 'geokit/geocoders/ip_geocoder'
require 'geokit/geocoders/multi_geocoder'
require 'geokit/geocoders/us_geocoder'
require 'geokit/geocoders/yahoo_geocoder'