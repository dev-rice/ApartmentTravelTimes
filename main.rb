require 'open-uri'
require 'json'
require 'uri'

class RequestBuilder
    attr_reader :api_url, :api_key, :data_type

    def initialize(args = {})
        args = defaults.merge(args)

        @api_url = args[:api_url]
        @api_key = args[:api_key]
        @data_type = args[:data_type]
    end

    def defaults
        {
            :api_url => "https://maps.googleapis.com/maps/api/directions",
            :api_key => "AIzaSyCfsW0TNaeXGo-pLS3AuVvr4ITkyRJ1e00",
            :data_type => "json"
        }
    end

    def buildRequestString(origin_coords, destination_coords, departure_time="now")
        request_string_dirty = "#{api_url}/#{data_type}?origin=#{origin_coords}&destination=#{destination_coords}&departure_time=#{departure_time}&key=#{api_key}"
        return URI.escape(request_string_dirty)
    end
end

class TrafficTimeDataGrabber
    def parseRequestAsJson(request_string)
        file = open(request_string)
        contents = file.read
        distance_data = JSON.parse(contents)
    end

    def getTravelTime(request_string)
        distance_data = parseRequestAsJson(request_string)
        distance_data["routes"][0]["legs"][0]["duration_in_traffic"]["text"]
    end

end

class Location
    attr_reader :name, :coordinates

    def initialize(name, coordinates)
        @name = name
        @coordinates = coordinates
    end

end

class TravelTimer
    attr_reader :request_builder, :traffic_time_data_grabber
    def initialize(args = {})
        args = defaults.merge(args)

        @request_builder = args[:request_builder]
        @traffic_time_data_grabber = args[:traffic_time_data_grabber]
    end

    def defaults
        {
            :request_builder => RequestBuilder.new(),
            :traffic_time_data_grabber => TrafficTimeDataGrabber.new()
        }
    end

    def getTravelTime(origin, destination)
        request_string = request_builder.buildRequestString(origin.coordinates, destination.coordinates)
        return traffic_time_data_grabber.getTravelTime(request_string)
    end

end

apartments = [
    park_place_olde_town = Location.new("Park Place Olde Town", "39.8012167,-105.0796034"),
    water_tower_flats = Location.new("Water Tower Flats", "39.797182,-105.0856092"),
    arvada_station = Location.new("Arvada Station", "39.791344,-105.1134387")
]

work_places = [
    ecocion = Location.new("Ecocion", "39.5705252,-104.8583055"),
    logrhythm = Location.new("LogRhythm", "40.0211783,-105.2419871")
]

apartments.each{ |apartment|
    work_places.each{ |work_place|
        travel_timer = TravelTimer.new()
        travel_time = travel_timer.getTravelTime(apartment, work_place)
        puts "#{apartment.name} to #{work_place.name} takes #{travel_time}"

    }
}
