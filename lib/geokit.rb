module Geokit
  VERSION = '1.5.0'

  # These defaults are used in Geokit::Mappable.distance_to and in acts_as_mappable
  @@default_units = :miles
  @@default_formula = :sphere

  [:default_units, :default_formula].each do |sym|
    class_eval <<-EOS, __FILE__, __LINE__
      def self.#{sym}
        if defined?(#{sym.to_s.upcase})
          #{sym.to_s.upcase}
        else
          @@#{sym}
        end
      end

      def self.#{sym}=(obj)
        @@#{sym} = obj
      end
    EOS
  end
end

require 'net/http'
require 'ipaddr'
require 'rexml/document'
require 'yaml'
require 'timeout'
require 'logger'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/conversions'
require 'openssl'
require 'base64'
require 'json'

require 'geokit/too_many_queries_error'
require 'geokit/inflector'
require 'geokit/geocoders'
require 'geokit/mappable'
require 'geokit/lat_lng'
require 'geokit/geo_loc'
require 'geokit/bounds'
require 'geokit/geocoders/geocode_error'
require 'geokit/geocoders/geocoder'

require 'geokit/geocoders/ca_geocoder'
require 'geokit/geocoders/geo_plugin_geocoder'
require 'geokit/geocoders/geonames_geocoder'
require 'geokit/geocoders/google_geocoder'
require 'geokit/geocoders/google_premier_geocoder'
require 'geokit/geocoders/ip_geocoder'
require 'geokit/geocoders/multi_geocoder'
require 'geokit/geocoders/us_geocoder'
require 'geokit/geocoders/yahoo_geocoder'