module v1 {
    scalar type Color extending enum<Red, Green, Blue>;
    scalar type TicketNo extending sequence;

    scalar type short_str extending str {
        constraint max_len_value(5);
    };

    type User {
        required property name -> str;
    }

    type Person {
        required property first_name -> str;
        required property middle_name -> str;
        required property last_name -> str;
    }

    abstract link crew {
        property list_order -> int64;
    }

    type Movie {
        required property title -> str;
        required property year -> int64;
        property description -> str;

        multi link directors extending crew -> Person;
        multi link actors extending crew -> Person;
    }

    type Ticket {
        property number -> TicketNo {
            constraint exclusive;
        }
    }

    type Internal {
        property value -> int64 {
            constraint exclusive;
        }
    }
}
