#!/usr/bin/ruby

require 'open-uri'
require 'json'
require 'uri'
require 'pg'
require 'date'

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
        distance_data["routes"][0]["legs"][0]["duration_in_traffic"]["value"]
    end

end

class Location
    attr_reader :id, :name, :latitude, :longitude

    def initialize(args)
        @id = args[:id]
        @name = args[:name]
        @latitude = args[:latitude]
        @longitude = args[:longitude]
    end

    def coordinates
        latitude.to_s + "," + longitude.to_s
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

module LocationPersistence
    def LocationPersistence.createLocationFromRow(row)
        Location.new(:id => row["id"],
                     :name => row["name"],
                     :latitude => row["latitude"],
                     :longitude => row["longitude"])
    end
end

apartments = []
work_places = []

conn = PG.connect(:host => '192.168.1.102', :dbname => 'ApartmentTravelTimes', :user => 'chris')
results = conn.exec('SELECT * FROM locations')
results.each{ |row|
    if row["type"] == "apartment"
        apartments.push(LocationPersistence.createLocationFromRow(row))
    elsif row["type"] == "workplace"
        work_places.push(LocationPersistence.createLocationFromRow(row))
    end
}

dayname = Date.parse(Time.now.to_s).strftime("%A")
leave_time = Time.now.strftime("%H:%M")
apartments.each{ |apartment|
    work_places.each{ |work_place|
        travel_timer = TravelTimer.new()
        travel_time = travel_timer.getTravelTime(apartment, work_place)
        # puts "#{apartment.name} (#{apartment.id}) to #{work_place.name} (#{work_place.id}) takes #{travel_time} seconds"

        conn.exec("INSERT INTO travel_times (day_of_week, leave_time, origin_id, destination_id, travel_time) VALUES ('#{dayname}', '#{leave_time}', #{apartment.id}, #{work_place.id}, #{travel_time})")

    }
}
