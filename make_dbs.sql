DROP TABLE IF EXISTS travel_times;
DROP TABLE IF EXISTS locations;

CREATE TABLE locations( id SERIAL PRIMARY KEY,
                        name TEXT,
                        type TEXT,
                        latitude NUMERIC,
                        longitude NUMERIC);
INSERT INTO locations (name, type, latitude, longitude)  VALUES ('Park Place Olde Town', 'apartment', 39.8012167, -105.0796034);
INSERT INTO locations (name, type, latitude, longitude)  VALUES ('Water Tower Flats', 'apartment', 39.797182, -105.0856092);
INSERT INTO locations (name, type, latitude, longitude)  VALUES ('Arvada Station', 'apartment', 39.791344, -105.1134387);
INSERT INTO locations (name, type, latitude, longitude)  VALUES ('Ecocion', 'workplace', 39.5705252, -104.8583055);
INSERT INTO locations (name, type, latitude, longitude)  VALUES ('LogRhythm', 'workplace', 40.0211783, -105.2419871);

CREATE TABLE travel_times(  id SERIAL PRIMARY KEY,
                            day_of_week TEXT,
                            leave_timestamp TIMESTAMP DEFAULT now(),
                            origin_id INTEGER,
                            destination_id INTEGER,
                            travel_time NUMERIC,
                            FOREIGN KEY (origin_id) REFERENCES locations(id),
                            FOREIGN KEY (destination_id) REFERENCES locations(id));
