using extension pgvector;

module default {
    global current_user -> str;

    abstract type HasImage {
        # just a URL to the image
        required property image -> str;
        index on (.image);
    }

    type User extending HasImage {
        required property name -> str;
    }

    type Review {
        required property body -> str;
        required property rating -> int64 {
            constraint min_value(0);
            constraint max_value(5);
        }
        required property flag -> bool {
            default := false;
        }

        required link author -> User;
        required link movie -> Movie;

        required property creation_time -> datetime {
            default := datetime_current();
        }
    }

    type Person extending HasImage {
        required property first_name -> str {
            default := '';
        }
        required property middle_name -> str {
            default := '';
        }
        required property last_name -> str;
        property full_name :=
            (
                (
                    (.first_name ++ ' ')
                    if .first_name != '' else
                    ''
                ) ++
                (
                    (.middle_name ++ ' ')
                    if .middle_name != '' else
                    ''
                ) ++
                .last_name
            );
        property bio -> str;
    }

    abstract link crew {
        # Provide a way to specify some "natural"
        # ordering, as relevant to the movie. This
        # may be order of importance, appearance, etc.
        property list_order -> int64;
    }

    abstract link directors extending crew;

    abstract link actors extending crew;

    type Movie extending HasImage {
        required property title -> str;
        required property year -> int64;

        # Add an index for accessing movies by title and year,
        # separately and in combination.
        index on (.title);
        index on (.year);
        index on ((.title, .year));

        property description -> str;

        multi link directors extending crew -> Person;
        multi link actors extending crew -> Person;

        property avg_rating := math::mean(.<movie[is Review].rating);
    }

    scalar type TicketNo extending sequence;

    scalar type short_str extending str {
        constraint max_len_value(5);
    };

    type Ticket {
        property number -> TicketNo {
            constraint exclusive;
        }
    }

    alias ReviewAlias := Review {
        # It will already have all the Review
        # properties and links.
        author_name := .author.name,
        movie_title := .movie.title,
    };

    alias MovieAlias := Movie {
        # A computable link for accessing all the
        # reviews for this movie.
        reviews := .<movie[is Review]
    };

    scalar type Color extending enum<Red, Green, Blue>;

    scalar type ExVector extending ext::pgvector::vector<1602>;
};
