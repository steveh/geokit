module Geokit
  module Geocoders


    # -------------------------------------------------------------------------------------------
    # Geocoder Base class -- every geocoder should inherit from this
    # -------------------------------------------------------------------------------------------

    # The Geocoder base class which defines the interface to be used by all
    # other geocoders.
    class Geocoder
      # Main method which calls the do_geocode template method which subclasses
      # are responsible for implementing.  Returns a populated GeoLoc or an
      # empty one with a failed success code.
      def self.geocode(address, options = {})
        res = do_geocode(address, options)
        return res.nil? ? GeoLoc.new : res
      end
      # Main method which calls the do_reverse_geocode template method which subclasses
      # are responsible for implementing.  Returns a populated GeoLoc or an
      # empty one with a failed success code.
      def self.reverse_geocode(latlng)
        res = do_reverse_geocode(latlng)
        return res.success? ? res : GeoLoc.new
      end

      # Call the geocoder service using the timeout if configured.
      def self.call_geocoder_service(url)
        Timeout::timeout(Geokit::Geocoders::request_timeout) { return self.do_get(url) } if Geokit::Geocoders::request_timeout
        return self.do_get(url)
      rescue TimeoutError
        return nil
      end

      # Not all geocoders can do reverse geocoding. So, unless the subclass explicitly overrides this method,
      # a call to reverse_geocode will return an empty GeoLoc. If you happen to be using MultiGeocoder,
      # this will cause it to failover to the next geocoder, which will hopefully be one which supports reverse geocoding.
      def self.do_reverse_geocode(latlng)
        return GeoLoc.new
      end

      protected

      def self.logger()
        Geokit::Geocoders::logger
      end

      private

      # Wraps the geocoder call around a proxy if necessary.
      def self.do_get(url)
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(url)
        req.basic_auth(uri.user, uri.password) if uri.userinfo
        res = Net::HTTP::Proxy(GeoKit::Geocoders::proxy_addr,
                GeoKit::Geocoders::proxy_port,
                GeoKit::Geocoders::proxy_user,
                GeoKit::Geocoders::proxy_pass).start(uri.host, uri.port) { |http| http.get(uri.path + "?" + uri.query) }
        return res
      end

      # Adds subclass' geocode method making it conveniently available through
      # the base class.
      def self.inherited(clazz)
        class_name = clazz.name.split('::').last
        src = <<-END_SRC
          def self.#{Geokit::Inflector.underscore(class_name)}(address, options = {})
            #{class_name}.geocode(address, options)
          end
        END_SRC
        class_eval(src)
      end
    end
  end
end