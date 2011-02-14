Geokit::Geocoders::google = '0xdeadbeef'
Geokit::Geocoders::google_client = 'gme-acme'
Geokit::Geocoders::google_channel = 'marketing'

class GooglePremierGeocoderTest < BaseGeocoderTest #:nodoc: all

  GOOGLE_PREMIER_FULL=<<-EOF
{
  "status": "OK",
  "results": [ {
    "types": [ "street_address" ],
    "formatted_address": "65 Upper Queen St, Auckland 1010, New Zealand",
    "address_components": [ {
      "long_name": "65",
      "short_name": "65",
      "types": [ "street_number" ]
    }, {
      "long_name": "Upper Queen St",
      "short_name": "Upper Queen St",
      "types": [ "route" ]
    }, {
      "long_name": "Auckland",
      "short_name": "Auckland",
      "types": [ "locality", "political" ]
    }, {
      "long_name": "Auckland",
      "short_name": "Auckland",
      "types": [ "administrative_area_level_3", "political" ]
    }, {
      "long_name": "Auckland",
      "short_name": "Auckland",
      "types": [ "administrative_area_level_1", "political" ]
    }, {
      "long_name": "New Zealand",
      "short_name": "NZ",
      "types": [ "country", "political" ]
    }, {
      "long_name": "1010",
      "short_name": "1010",
      "types": [ "postal_code" ]
    } ],
    "geometry": {
      "location": {
        "lat": -36.8624475,
        "lng": 174.7589730
      },
      "location_type": "RANGE_INTERPOLATED",
      "viewport": {
        "southwest": {
          "lat": -36.8656001,
          "lng": 174.7558353
        },
        "northeast": {
          "lat": -36.8593048,
          "lng": 174.7621306
        }
      },
      "bounds": {
        "southwest": {
          "lat": -36.8624574,
          "lng": 174.7589730
        },
        "northeast": {
          "lat": -36.8624475,
          "lng": 174.7589929
        }
      }
    }
  } ]
}
  EOF

  def setup
    @address = "65 Upper Queen Street, Auckland"
  end

  def test_google_full_address
    response = MockSuccess.new
    response.expects(:body).returns(GOOGLE_PREMIER_FULL)
    url = "http://maps.googleapis.com/maps/api/geocode/json?address=65+Upper+Queen+Street%2C+Auckland&channel=marketing&client=gme-acme&sensor=false&signature=AO3Ppgjdr7SoQBUcwSdvXFjwN5M="
    Geokit::Geocoders::GooglePremierGeocoder.expects(:call_geocoder_service).with(url).returns(response)
    res = Geokit::Geocoders::GooglePremierGeocoder.geocode(@address)

    assert_equal "Auckland", res.city
    assert_equal 174.7589730, res.lng
  end

end