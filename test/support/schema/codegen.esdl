using extension pgvector;

module codegen {
    # enum

    scalar type EnumType extending enum<A, B, C>;

    # sequence

    scalar type SequenceType extending sequence;

    # custom scalars

    scalar type StrType extending str;
    scalar type BoolType extending bool;
    scalar type Int16Type extending int16;
    scalar type Int32Type extending int32;
    scalar type Int64Type extending int64;
    scalar type Float32Type extending float32;
    scalar type Float64Type extending float64;
    scalar type DecimalType extending decimal;
    scalar type JsonType extending json;
    scalar type UuidType extending uuid;
    scalar type DatetimeType extending datetime;
    scalar type DurationType extending duration;
    scalar type CalLocalDatetimeType extending cal::local_datetime;
    scalar type CalLocalDateType extending cal::local_date;
    scalar type CalLocalTimeType extending cal::local_time;
    scalar type CalRelativeDurationType extending cal::relative_duration;
    scalar type CalDateDurationType extending cal::date_duration;
    scalar type BytesType extending bytes;
    scalar type CfgMemoryType extending cfg::memory;
    scalar type VectorType extending ext::pgvector::vector<1>;

    # types

    abstract type A {
        # properties

        required rp_a_str: str;

        # links

        ol_a: A;
        multi ml_a: A;
    }

    abstract type B {
        required rp_b_str: str;
    }

    abstract type C extending B {
        required rp_c_str: str;
    }

    abstract type D extending A, C {
        required rp_d_str: str;
    }

    type E extending A {
        required rp_e_str: str;
    };

    type F extending D {
        # properties

        overloaded rp_a_str: str;

        required rp_f_str: str;

        # links

        overloaded ol_a: E;
        overloaded multi ml_a: E;

        ol_a_b: A | B;
        multi ml_a_b: A | B;
    }

    # result

    type Result {
        # properties

        # string

        required rp_str: str;
        op_str: str;
        multi mp_str: str;

        required rp_str_type: StrType;
        op_str_type: StrType;
        multi mp_str_type: StrType;

        # boolean

        required rp_bool: bool;
        op_bool: bool;
        multi mp_bool: bool;

        required rp_bool_type: BoolType;
        op_bool_type: BoolType;
        multi mp_bool_type: BoolType;

        # number

        required rp_int16: int16;
        op_int16: int16;
        multi mp_int16: int16;

        required rp_int16_type: Int16Type;
        op_int16_type: Int16Type;
        multi mp_int16_type: Int16Type;

        required rp_int32: int32;
        op_int32: int32;
        multi mp_int32: int32;

        required rp_int32_type: Int32Type;
        op_int32_type: Int32Type;
        multi mp_int32_type: Int32Type;

        required rp_int64: int64;
        op_int64: int64;
        multi mp_int64: int64;

        required rp_int64_type: Int64Type;
        op_int64_type: Int64Type;
        multi mp_int64_type: Int64Type;

        required rp_float32: float32;
        op_float32: float32;
        multi mp_float32: float32;

        required rp_float32_type: Float32Type;
        op_float32_type: Float32Type;
        multi mp_float32_type: Float32Type;

        required rp_float64: float64;
        op_float64: float64;
        multi mp_float64: float64;

        required rp_float64_type: Float64Type;
        op_float64_type: Float64Type;
        multi mp_float64_type: Float64Type;

        required rp_decimal: decimal;
        op_decimal: decimal;
        multi mp_decimal: decimal;

        required rp_decimal_type: DecimalType;
        op_decimal_type: DecimalType;
        multi mp_decimal_type: DecimalType;

        # json

        required rp_json: json;
        op_json: json;
        multi mp_json: json;

        required rp_json_type: JsonType;
        op_json_type: JsonType;
        multi mp_json_type: JsonType;

        # uuid

        required rp_uuid: uuid;
        op_uuid: uuid;
        multi mp_uuid: uuid;

        required rp_uuid_type: UuidType;
        op_uuid_type: UuidType;
        multi mp_uuid_type: UuidType;

        # enum

        required rp_enum: EnumType;
        op_enum: EnumType;
        multi mp_enum: EnumType;

        # date/time

        required rp_datetime: datetime;
        op_datetime: datetime;
        multi mp_datetime: datetime;

        required rp_datetime_type: DatetimeType;
        op_datetime_type: DatetimeType;
        multi mp_datetime_type: DatetimeType;

        required rp_duration: duration;
        op_duration: duration;
        multi mp_duration: duration;

        required rp_duration_type: DurationType;
        op_duration_type: DurationType;
        multi mp_duration_type: DurationType;

        required rp_cal_local_datetime: cal::local_datetime;
        op_cal_local_datetime: cal::local_datetime;
        multi mp_cal_local_datetime: cal::local_datetime;

        required rp_cal_local_datetime_type: CalLocalDatetimeType;
        op_cal_local_datetime_type: CalLocalDatetimeType;
        multi mp_cal_local_datetime_type: CalLocalDatetimeType;

        required rp_cal_local_date: cal::local_date;
        op_cal_local_date: cal::local_date;
        multi mp_cal_local_date: cal::local_date;

        required rp_cal_local_date_type: CalLocalDateType;
        op_cal_local_date_type: CalLocalDateType;
        multi mp_cal_local_date_type: CalLocalDateType;

        required rp_cal_local_time: cal::local_time;
        op_cal_local_time: cal::local_time;
        multi mp_cal_local_time: cal::local_time;

        required rp_cal_local_time_type: CalLocalTimeType;
        op_cal_local_time_type: CalLocalTimeType;
        multi mp_cal_local_time_type: CalLocalTimeType;

        required rp_cal_relative_duration: cal::relative_duration;
        op_cal_relative_duration: cal::relative_duration;
        multi mp_cal_relative_duration: cal::relative_duration;

        required rp_cal_relative_duration_type: CalRelativeDurationType;
        op_cal_relative_duration_type: CalRelativeDurationType;
        multi mp_cal_relative_duration_type: CalRelativeDurationType;

        required rp_cal_date_duration: cal::date_duration;
        op_cal_date_duration: cal::date_duration;
        multi mp_cal_date_duration: cal::date_duration;

        required rp_cal_date_duration_type: CalDateDurationType;
        op_cal_date_duration_type: CalDateDurationType;
        multi mp_cal_date_duration_type: CalDateDurationType;

        # array

        required rp_array_int64: array<int64>;
        op_array_int64: array<int64>;
        multi mp_array_int64: array<int64>;

        # tuple

        required rp_tuple_int64_int64: tuple<int64, int64>;
        op_tuple_int64_int64: tuple<int64, int64>;
        multi mp_tuple_int64_int64: tuple<int64, int64>;

        required rp_named_tuple_x_int64_y_int64: tuple<x: int64, y: int64>;
        op_named_tuple_x_int64_y_int64: tuple<x: int64, y: int64>;
        multi mp_named_tuple_x_int64_y_int64: tuple<x: int64, y: int64>;

        # range

        required rp_range_int32: range<int32>;
        op_range_int32: range<int32>;
        multi mp_range_int32: range<int32>;

        required rp_range_int64: range<int64>;
        op_range_int64: range<int64>;
        multi mp_range_int64: range<int64>;

        required rp_range_float32: range<float32>;
        op_range_float32: range<float32>;
        multi mp_range_float32: range<float32>;

        required rp_range_float64: range<float64>;
        op_range_float64: range<float64>;
        multi mp_range_float64: range<float64>;

        required rp_range_decimal: range<decimal>;
        op_range_decimal: range<decimal>;
        multi mp_range_decimal: range<decimal>;

        required rp_range_datetime: range<datetime>;
        op_range_datetime: range<datetime>;
        multi mp_range_datetime: range<datetime>;

        required rp_range_cal_local_datetime: range<cal::local_datetime>;
        op_range_cal_local_datetime: range<cal::local_datetime>;
        multi mp_range_cal_local_datetime: range<cal::local_datetime>;

        required rp_range_cal_local_date: range<cal::local_date>;
        op_range_cal_local_date: range<cal::local_date>;
        multi mp_range_cal_local_date: range<cal::local_date>;

        # bytes

        required rp_bytes: bytes;
        op_bytes: bytes;
        multi mp_bytes: bytes;

        required rp_bytes_type: BytesType;
        op_bytes_type: BytesType;
        multi mp_bytes_type: BytesType;

        # sequence

        required rp_sequence: SequenceType;
        op_sequence: SequenceType;
        multi mp_sequence: SequenceType;

        # config

        required rp_cfg_memory: cfg::memory;
        op_cfg_memory: cfg::memory;
        multi mp_cfg_memory: cfg::memory;

        required rp_cfg_memory_type: CfgMemoryType;
        op_cfg_memory_type: CfgMemoryType;
        multi mp_cfg_memory_type: CfgMemoryType;

        # vector

        required rp_vector_type: VectorType;
        op_vector_type: VectorType;
        multi mp_vector_type: VectorType;

        # links

        required rl_f: F;
        ol_f: F;
        multi ml_f: F;

        # link properties

        required rl_lp_f: F {
            olp_a: int64;
        }
    }
};
