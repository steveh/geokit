module Geokit
  module Geocoders
    class GooglePremierGeocoder < Geocoder

      HOST = "maps.googleapis.com"
      ENDPOINT = "/maps/api/geocode/json"

      protected

        def self.do_reverse_geocode(latlng)
          latlng = LatLng.normalize(latlng)
          params = { :latlng => latlng.ll, :sensor => false }
          signed_url = signed_url_for_params(params)
          res = self.call_geocoder_service(signed_url)
          return GeoLoc.new unless (res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPOK))
          json = JSON.parse(res.body)
          logger.debug "Google reverse-geocoding. LL: #{latlng}. Result: #{json}"
          return self.json_to_geo_loc(json)
        end

        def self.do_geocode(address, options = {})
          address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
          params = { :address => address_str, :sensor => false }
          signed_url = signed_url_for_params(params)
          res = self.call_geocoder_service(signed_url)
          return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
          json = JSON.parse(res.body)
          logger.debug "Google geocoding. Address: #{address}. Result: #{json}"
          return self.json_to_geo_loc(json, address)
        end

        def self.json_to_geo_loc(json, address="")
          if json["status"] == "OK"
            geoloc = nil

            # iterate through each and extract as a geoloc
            json["results"].each do |result|
              extracted_geoloc = extract_result(result) # g is now an instance of GeoLoc
              if geoloc.nil?
                # first time through, geoloc is still nil, so we make it the geoloc we just extracted
                geoloc = extracted_geoloc
              else
                # second (and subsequent) iterations, we push additional
                # geolocs onto "geoloc.all"
                geoloc.all.push(extracted_geoloc)
              end
            end
            return geoloc
          elsif json["status"] == "ZERO_RESULTS"
            return GeoLoc.new
          elsif json["status"] == "OVER_QUERY_LIMIT"
            raise Geokit::TooManyQueriesError
          elsif json["status"] == "REQUEST_DENIED"
            logger.error "Google Premier request denied: "+$!
          elsif json["status"] == "INVALID_REQUEST"
            logger.error "Google Premier invalid request: "+$!
          else
            logger.info "Google was unable to geocode address: "+address
            return GeoLoc.new
          end
        rescue Geokit::TooManyQueriesError
          raise Geokit::TooManyQueriesError, "Google Premier returned a 620 status, too many queries. The given key has gone over the requests limit in the 24 hour period or has submitted too many requests in too short a period of time. If you're sending multiple requests in parallel or in a tight loop, use a timer or pause in your code to make sure you don't send the requests too quickly."
        rescue
          logger.error "Caught an error during Google Premier geocoding call: "+$!
          return GeoLoc.new
        end

        ACCURACY_MAP = {
          "ROOFTOP" => 8,
          "RANGE_INTERPOLATED" => 7,
          "GEOMETRIC_CENTER" => 6,
          "APPROXIMATE" => 5,
        }

        # extracts a single geoloc from a result in the google results json
        def self.extract_result(result)
          res = GeoLoc.new

          res.provider = "google_premier"

          geometry = result["geometry"] if result

          res.accuracy  = ACCURACY_MAP[geometry["location_type"]] if geometry
          res.precision = geometry["location_type"].underscore if geometry

          location = geometry["location"] if geometry
          res.lat = location["lat"] if location
          res.lng = location["lng"] if location

          res.full_address = result["formatted_address"]
          res.street_address = result["formatted_address"]

          address_components = result["address_components"] if result
          address_components.each do |component|
            res.zip = component["long_name"] if component["types"].include?("postal_code")
            res.country = component["long_name"] if component["types"].include?("country")
            res.country_code = component["short_name"] if component["types"].include?("country")
            res.city = component["long_name"] if component["types"].include?("locality")
            res.state = component["long_name"] if component["types"].include?("administrative_area_level_1")
            res.province = component["long_name"] if component["types"].include?("administrative_area_level_2")
            res.district = component["long_name"] if component["types"].include?("administrative_area_level_3")
          end if address_components

          bounds = geometry["bounds"]

          res.suggested_bounds = Bounds.normalize(
            [bounds["southwest"]["lat"], bounds["southwest"]["lng"]],
            [bounds["northeast"]["lat"], bounds["northeast"]["lng"]]
          ) if bounds

          res.success = true

          res
        end

      private

        def self.url_for_params(params)
          params_to_sign = params
          "http://" + HOST + string_to_sign
        end

        def self.signed_url_for_params(params)
          params_to_sign = params.merge({ :client => Geokit::Geocoders.google_client, :channel => Geokit::Geocoders.google_channel }).reject{ |key, value| value.nil? }
          string_to_sign = "#{ENDPOINT}?#{params_to_sign.to_query}"
          signature = signature_for_string(string_to_sign)
          "http://" + HOST + string_to_sign + "&signature=#{signature}"
        end

        def self.signature_for_string(string)
          raw_private_key = url_safe_base64_decode(Geokit::Geocoders.google)
          digest = OpenSSL::Digest::Digest.new("sha1")
          raw_signature = OpenSSL::HMAC.digest(digest, raw_private_key, string)
          url_safe_base64_encode(raw_signature)
        end

        def self.url_safe_base64_decode(base64_string)
          Base64.decode64(base64_string.tr("-_","+/"))
        end

        def self.url_safe_base64_encode(raw)
          Base64.encode64(raw).tr("+/","-_").strip
        end

    end
  end
end