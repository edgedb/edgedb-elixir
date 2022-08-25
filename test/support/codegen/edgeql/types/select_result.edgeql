select codegen::Result {
    # special
    id,

    # properties

    # string

    rp_str,
    op_str,
    mp_str,

    rp_str_type,
    op_str_type,
    mp_str_type,

    # boolean

    rp_bool,
    op_bool,
    mp_bool,

    rp_bool_type,
    op_bool_type,
    mp_bool_type,

    # number

    rp_int16,
    op_int16,
    mp_int16,

    rp_int16_type,
    op_int16_type,
    mp_int16_type,

    rp_int32,
    op_int32,
    mp_int32,

    rp_int32_type,
    op_int32_type,
    mp_int32_type,

    rp_int64,
    op_int64,
    mp_int64,

    rp_int64_type,
    op_int64_type,
    mp_int64_type,

    rp_float32,
    op_float32,
    mp_float32,

    rp_float32_type,
    op_float32_type,
    mp_float32_type,

    rp_float64,
    op_float64,
    mp_float64,

    rp_float64_type,
    op_float64_type,
    mp_float64_type,

    rp_decimal,
    op_decimal,
    mp_decimal,

    rp_decimal_type,
    op_decimal_type,
    mp_decimal_type,

    # json

    rp_json,
    op_json,
    mp_json,

    rp_json_type,
    op_json_type,
    mp_json_type,

    # uuid

    rp_uuid,
    op_uuid,
    mp_uuid,

    rp_uuid_type,
    op_uuid_type,
    mp_uuid_type,

    # enum

    rp_enum,
    op_enum,
    mp_enum,

    # date/time

    rp_datetime,
    op_datetime,
    mp_datetime,

    rp_datetime_type,
    op_datetime_type,
    mp_datetime_type,

    rp_duration,
    op_duration,
    mp_duration,

    rp_duration_type,
    op_duration_type,
    mp_duration_type,

    rp_cal_local_datetime,
    op_cal_local_datetime,
    mp_cal_local_datetime,

    rp_cal_local_datetime_type,
    op_cal_local_datetime_type,
    mp_cal_local_datetime_type,

    rp_cal_local_date,
    op_cal_local_date,
    mp_cal_local_date,

    rp_cal_local_date_type,
    op_cal_local_date_type,
    mp_cal_local_date_type,

    rp_cal_local_time,
    op_cal_local_time,
    mp_cal_local_time,

    rp_cal_local_time_type,
    op_cal_local_time_type,
    mp_cal_local_time_type,

    rp_cal_relative_duration,
    op_cal_relative_duration,
    mp_cal_relative_duration,

    rp_cal_relative_duration_type,
    op_cal_relative_duration_type,
    mp_cal_relative_duration_type,

    rp_cal_date_duration,
    op_cal_date_duration,
    mp_cal_date_duration,

    rp_cal_date_duration_type,
    op_cal_date_duration_type,
    mp_cal_date_duration_type,

    # array

    rp_array_int64,
    op_array_int64,
    mp_array_int64,

    # tuple

    rp_tuple_int64_int64,
    op_tuple_int64_int64,
    mp_tuple_int64_int64,

    rp_named_tuple_x_int64_y_int64,
    op_named_tuple_x_int64_y_int64,
    mp_named_tuple_x_int64_y_int64,

    # range

    rp_range_int32,
    op_range_int32,
    mp_range_int32,

    rp_range_int64,
    op_range_int64,
    mp_range_int64,

    rp_range_float32,
    op_range_float32,
    mp_range_float32,

    rp_range_float64,
    op_range_float64,
    mp_range_float64,

    rp_range_decimal,
    op_range_decimal,
    mp_range_decimal,

    rp_range_datetime,
    op_range_datetime,
    mp_range_datetime,

    rp_range_cal_local_datetime,
    op_range_cal_local_datetime,
    mp_range_cal_local_datetime,

    rp_range_cal_local_date,
    op_range_cal_local_date,
    mp_range_cal_local_date,

    # bytes

    rp_bytes,
    op_bytes,
    mp_bytes,

    rp_bytes_type,
    op_bytes_type,
    mp_bytes_type,

    # sequence

    rp_sequence,
    op_sequence,
    mp_sequence,

    # config

    rp_cfg_memory,
    op_cfg_memory,
    mp_cfg_memory,

    rp_cfg_memory_type,
    op_cfg_memory_type,
    mp_cfg_memory_type,

    # links

    rl_f: {
        # special

        id,

        # properties

        rp_a_str,
        rp_b_str,
        rp_c_str,
        rp_d_str,
        rp_f_str,

        # links

        ol_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ml_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ol_a_b: {
            id,
        },

        ml_a_b: {
            id,
        },
    },

    ol_f: {
        # special

        id,

        # properties

        rp_a_str,
        rp_b_str,
        rp_c_str,
        rp_d_str,
        rp_f_str,

        # links

        ol_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ml_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ol_a_b: {
            id,
        },

        ml_a_b: {
            id,
        },
    },

    ml_f: {
        # special

        id,

        # properties

        rp_a_str,
        rp_b_str,
        rp_c_str,
        rp_d_str,
        rp_f_str,

        # links

        ol_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ml_a: {
            id,
            rp_a_str,
            rp_e_str,
        },

        ol_a_b: {
            id,
        },

        ml_a_b: {
            id,
        },
    },

    rl_lp_f: {
        id,

        # link properties

        @olp_a,
    }
}
filter .id in array_unpack(<array<uuid>>$ids)
