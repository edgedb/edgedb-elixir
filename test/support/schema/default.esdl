using extension pgvector;

module default {
    global current_user: str;

    abstract type HasImage {
        # just a URL to the image
        required image: str;
        index on (.image);
    }

    type User extending HasImage {
        required  name: str;
    }

    type Review {
        required body: str;
        required rating: int64 {
            constraint min_value(0);
            constraint max_value(5);
        }
        required flag: bool {
            default := false;
        }

        required author: User;
        required movie: Movie;

        required creation_time: datetime {
            default := datetime_current();
        }
    }

    type Person extending HasImage {
        required first_name: str {
            default := '';
        }
        required middle_name: str {
            default := '';
        }

        required last_name: str;

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
        bio: str;
    }

    abstract link crew {
        # Provide a way to specify some "natural"
        # ordering, as relevant to the movie. This
        # may be order of importance, appearance, etc.
        list_order: int64;
    }

    abstract link directors extending crew;

    abstract link actors extending crew;

    type Movie extending HasImage {
        required title: str;
        required year: int64;

        # Add an index for accessing movies by title and year,
        # separately and in combination.
        index on (.title);
        index on (.year);
        index on ((.title, .year));

        description: str;

        multi directors extending crew: Person;
        multi actors extending crew: Person;

        property avg_rating := math::mean(.<movie[is Review].rating);
    }

    scalar type TicketNo extending sequence;

    scalar type short_str extending str {
        constraint max_len_value(5);
    };

    type Ticket {
        number: TicketNo {
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
        # A computable for accessing all the
        # reviews for this movie.
        reviews := .<movie[is Review]
    };

    scalar type Color extending enum<Red, Green, Blue>;

    scalar type ExVector extending ext::pgvector::vector<1602>;
};
