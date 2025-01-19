
CREATE TABLE airports (
  airport_code     CHAR(3)      PRIMARY KEY,
  airport_name     TEXT         NOT NULL,
  city             TEXT         NOT NULL,
  coordinates_lon  DOUBLE PRECISION NOT NULL,
  coordinates_lat  DOUBLE PRECISION NOT NULL,
  timezone         TEXT         NOT NULL
);

CREATE TABLE aircrafts (
  aircraft_code  CHAR(3)       PRIMARY KEY,
  model          JSONB         NOT NULL,
  range          INTEGER       NOT NULL
);

CREATE TABLE bookings (
  book_ref       CHAR(6)       PRIMARY KEY,
  book_date      TIMESTAMPTZ   NOT NULL,
  total_amount   NUMERIC(10,2) NOT NULL
);

CREATE TABLE tickets (
  ticket_no       CHAR(13)       PRIMARY KEY,
  book_ref        CHAR(6)        NOT NULL,
  passenger_id    VARCHAR(20)    NOT NULL,
  passenger_name  TEXT           NOT NULL,
  contact_data    JSONB          NULL,
  CONSTRAINT fk_ticket_booking
    FOREIGN KEY (book_ref)
    REFERENCES bookings (book_ref)
    ON DELETE CASCADE
);

CREATE TABLE flights (
  flight_id            SERIAL         PRIMARY KEY,
  flight_no            CHAR(6)        NOT NULL,
  scheduled_departure  TIMESTAMPTZ    NOT NULL,
  scheduled_arrival    TIMESTAMPTZ    NOT NULL,
  departure_airport    CHAR(3)        NOT NULL,
  arrival_airport      CHAR(3)        NOT NULL,
  status               VARCHAR(20)    NOT NULL,
  aircraft_code        CHAR(3)        NOT NULL,
  actual_departure     TIMESTAMPTZ    NULL,
  actual_arrival       TIMESTAMPTZ    NULL,
  CONSTRAINT fk_flight_departure_airport
    FOREIGN KEY (departure_airport)
    REFERENCES airports (airport_code),
  CONSTRAINT fk_flight_arrival_airport
    FOREIGN KEY (arrival_airport)
    REFERENCES airports (airport_code),
  CONSTRAINT fk_flight_aircraft
    FOREIGN KEY (aircraft_code)
    REFERENCES aircrafts (aircraft_code)
);

CREATE TABLE seats (
  aircraft_code   CHAR(3)       NOT NULL,
  seat_no         VARCHAR(4)    PRIMARY KEY,
  fare_conditions VARCHAR(10)   NOT NULL,
  CONSTRAINT fk_seats_aircraft
    FOREIGN KEY (aircraft_code)
    REFERENCES aircrafts (aircraft_code)
);

CREATE TABLE ticket_flights (
  ticket_no       CHAR(13)       NOT NULL,
  flight_id       INTEGER        NOT NULL,
  fare_conditions VARCHAR(10)    NOT NULL,
  amount          NUMERIC(10,2)  NOT NULL,
  PRIMARY KEY (ticket_no, flight_id),
  CONSTRAINT fk_ticket_no
    FOREIGN KEY (ticket_no)
    REFERENCES tickets (ticket_no)
    ON DELETE CASCADE,
  CONSTRAINT fk_flight_id
    FOREIGN KEY (flight_id)
    REFERENCES flights (flight_id)
    ON DELETE CASCADE
);

CREATE TABLE boarding_passes (
  ticket_no    CHAR(13)     NOT NULL,
  flight_id    INTEGER      NOT NULL,
  boarding_no  INTEGER      NOT NULL,
  seat_no      VARCHAR(4)   NOT NULL,
  PRIMARY KEY (ticket_no, flight_id),
  CONSTRAINT fk_bp_ticket_no
    FOREIGN KEY (ticket_no)
    REFERENCES tickets (ticket_no)
    ON DELETE CASCADE,
  CONSTRAINT fk_bp_flight_id
    FOREIGN KEY (flight_id)
    REFERENCES flights (flight_id)
    ON DELETE CASCADE
);
