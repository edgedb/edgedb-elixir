using extension pgvector;

module v4::codegen {
    # enum

    scalar type EnumType extending enum<A, B, C>;

    # sequence

    scalar type SequenceType extending sequence;

    # vector

    scalar type VectorType extending ext::pgvector::vector<1>;

    # custom scalars

    scalar type StrType extending str;
    scalar type BoolType extending bool;
    scalar type Int16Type extending int16;
    scalar type Int32Type extending int32;
    scalar type Int64Type extending int64;
    scalar type Float32Type extending float32;
    scalar type Float64Type extending float64;
    scalar type BigintType extending bigint;
    scalar type DecimalType extending decimal;
    scalar type JsonType extending json;
    scalar type UuidType extending uuid;
    scalar type BytesType extending bytes;
    scalar type DatetimeType extending datetime;
    scalar type DurationType extending duration;
    scalar type CalLocalDatetimeType extending cal::local_datetime;
    scalar type CalLocalDateType extending cal::local_date;
    scalar type CalLocalTimeType extending cal::local_time;
    scalar type CalRelativeDurationType extending cal::relative_duration;
    scalar type CalDateDurationType extending cal::date_duration;
    scalar type CfgMemoryType extending cfg::memory;

    type StrPropertiesType {
        required rp_str: str;
        op_str: str;
        multi mp_str: str;

        required rp_str_type: StrType;
        op_str_type: StrType;
        multi mp_str_type: StrType;
    }

    type BoolPropertiesType {
        required rp_bool: bool;
        op_bool: bool;
        multi mp_bool: bool;

        required rp_bool_type: BoolType;
        op_bool_type: BoolType;
        multi mp_bool_type: BoolType;
    }

    type NumberPropertiesType {
        required rl_int16: Int16PropertiesType;
        ol_int16: Int16PropertiesType;
        multi ml_int16: Int16PropertiesType;

        required rl_int32: Int32PropertiesType;
        ol_int32: Int32PropertiesType;
        multi ml_int32: Int32PropertiesType;

        required rl_int64: Int64PropertiesType;
        ol_int64: Int64PropertiesType;
        multi ml_int64: Int64PropertiesType;

        required rl_float32: Float32PropertiesType;
        ol_float32: Float32PropertiesType;
        multi ml_float32: Float32PropertiesType;

        required rl_float64: Float64PropertiesType;
        ol_float64: Float64PropertiesType;
        multi ml_float64: Float64PropertiesType;

        required rl_decimal: DecimalPropertiesType;
        ol_decimal: DecimalPropertiesType;
        multi ml_decimal: DecimalPropertiesType;

        required rl_bigint: BigintPropertiesType;
        ol_bigint: BigintPropertiesType;
        multi ml_bigint: BigintPropertiesType;
    }

    type Int16PropertiesType {
        required rp_int16: int16;
        op_int16: int16;
        multi mp_int16: int16;

        required rp_int16_type: Int16Type;
        op_int16_type: Int16Type;
        multi mp_int16_type: Int16Type;
    }

    type Int32PropertiesType {
        required rp_int32: int32;
        op_int32: int32;
        multi mp_int32: int32;

        required rp_int32_type: Int32Type;
        op_int32_type: Int32Type;
        multi mp_int32_type: Int32Type;
    }

    type Int64PropertiesType {
        required rp_int64: int64;
        op_int64: int64;
        multi mp_int64: int64;

        required rp_int64_type: Int64Type;
        op_int64_type: Int64Type;
        multi mp_int64_type: Int64Type;
    }

    type Float32PropertiesType {
        required rp_float32: float32;
        op_float32: float32;
        multi mp_float32: float32;

        required rp_float32_type: Float32Type;
        op_float32_type: Float32Type;
        multi mp_float32_type: Float32Type;
    }

    type Float64PropertiesType {
        required rp_float64: float64;
        op_float64: float64;
        multi mp_float64: float64;

        required rp_float64_type: Float64Type;
        op_float64_type: Float64Type;
        multi mp_float64_type: Float64Type;
    }

    type DecimalPropertiesType {
        required rp_decimal: decimal;
        op_decimal: decimal;
        multi mp_decimal: decimal;

        required rp_decimal_type: DecimalType;
        op_decimal_type: DecimalType;
        multi mp_decimal_type: DecimalType;
    }

    type BigintPropertiesType {
        required rp_bigint: bigint;
        op_bigint: bigint;
        multi mp_bigint: bigint;

        required rp_bigint_type: BigintType;
        op_bigint_type: BigintType;
        multi mp_bigint_type: BigintType;
    }

    type JsonPropertiesType {
        required rp_json: json;
        op_json: json;
        multi mp_json: json;

        required rp_json_type: JsonType;
        op_json_type: JsonType;
        multi mp_json_type: JsonType;
    }

    type UuidPropertiesType {
        required rp_uuid: uuid;
        op_uuid: uuid;
        multi mp_uuid: uuid;

        required rp_uuid_type: UuidType;
        op_uuid_type: UuidType;
        multi mp_uuid_type: UuidType;
    }

    type DateAndTimePropertiesType {
        required rl_datetime: DatetimePropertiesType;
        ol_datetime: DatetimePropertiesType;
        multi ml_datetime: DatetimePropertiesType;

        required rl_duration: DurationPropertiesType;
        ol_duration: DurationPropertiesType;
        multi ml_duration: DurationPropertiesType;

        required rl_cal: CalPropertiesType;
        ol_cal: CalPropertiesType;
        multi ml_cal: CalPropertiesType;
    }

    type DatetimePropertiesType {
        required rp_datetime: datetime;
        op_datetime: datetime;
        multi mp_datetime: datetime;

        required rp_datetime_type: DatetimeType;
        op_datetime_type: DatetimeType;
        multi mp_datetime_type: DatetimeType;
    }

    type DurationPropertiesType {
        required rp_duration: duration;
        op_duration: duration;
        multi mp_duration: duration;

        required rp_duration_type: DurationType;
        op_duration_type: DurationType;
        multi mp_duration_type: DurationType;
    }

    type CalPropertiesType {
        required rl_cal_local_datetime: CalLocalDatetimePropertiesType;
        ol_cal_local_datetime: CalLocalDatetimePropertiesType;
        multi ml_cal_local_datetime: CalLocalDatetimePropertiesType;

        required rl_cal_local_date: CalLocalDatePropertiesType;
        ol_cal_local_date: CalLocalDatePropertiesType;
        multi ml_cal_local_date: CalLocalDatePropertiesType;

        required rl_cal_local_time: CalLocalTimePropertiesType;
        ol_cal_local_time: CalLocalTimePropertiesType;
        multi ml_cal_local_time: CalLocalTimePropertiesType;

        required rl_cal_relative_duration: CalRelativeDurationPropertiesType;
        ol_cal_relative_duration: CalRelativeDurationPropertiesType;
        multi ml_cal_relative_duration: CalRelativeDurationPropertiesType;

        required rl_cal_date_duration: CalDateDurationPropertiesType;
        ol_cal_date_duration: CalDateDurationPropertiesType;
        multi ml_cal_date_duration: CalDateDurationPropertiesType;
    }

    type CalLocalDatetimePropertiesType {
        required rp_cal_local_datetime: cal::local_datetime;
        op_cal_local_datetime: cal::local_datetime;
        multi mp_cal_local_datetime: cal::local_datetime;

        required rp_cal_local_datetime_type: CalLocalDatetimeType;
        op_cal_local_datetime_type: CalLocalDatetimeType;
        multi mp_cal_local_datetime_type: CalLocalDatetimeType;
    }

    type CalLocalDatePropertiesType {
        required rp_cal_local_date: cal::local_date;
        op_cal_local_date: cal::local_date;
        multi mp_cal_local_date: cal::local_date;

        required rp_cal_local_date_type: CalLocalDateType;
        op_cal_local_date_type: CalLocalDateType;
        multi mp_cal_local_date_type: CalLocalDateType;
    }

    type CalLocalTimePropertiesType {
        required rp_cal_local_time: cal::local_time;
        op_cal_local_time: cal::local_time;
        multi mp_cal_local_time: cal::local_time;

        required rp_cal_local_time_type: CalLocalTimeType;
        op_cal_local_time_type: CalLocalTimeType;
        multi mp_cal_local_time_type: CalLocalTimeType;
    }

    type CalRelativeDurationPropertiesType {
        required rp_cal_relative_duration: cal::relative_duration;
        op_cal_relative_duration: cal::relative_duration;
        multi mp_cal_relative_duration: cal::relative_duration;

        required rp_cal_relative_duration_type: CalRelativeDurationType;
        op_cal_relative_duration_type: CalRelativeDurationType;
        multi mp_cal_relative_duration_type: CalRelativeDurationType;
    }

    type CalDateDurationPropertiesType {
        required rp_cal_date_duration: cal::date_duration;
        op_cal_date_duration: cal::date_duration;
        multi mp_cal_date_duration: cal::date_duration;

        required rp_cal_date_duration_type: CalDateDurationType;
        op_cal_date_duration_type: CalDateDurationType;
        multi mp_cal_date_duration_type: CalDateDurationType;
    }

    type CfgPropertiesType {
        required rl_cfg_memory: CfgMemoryPropertiesType;
        ol_cfg_memory: CfgMemoryPropertiesType;
        multi ml_cfg_memory: CfgMemoryPropertiesType;
    }

    type CfgMemoryPropertiesType {
        required rp_cfg_memory: cfg::memory;
        op_cfg_memory: cfg::memory;
        multi mp_cfg_memory: cfg::memory;

        required rp_cfg_memory_type: CfgMemoryType;
        op_cfg_memory_type: CfgMemoryType;
        multi mp_cfg_memory_type: CfgMemoryType;
    }

    type SequencePropertiesType {
        required rp_sequence_type: SequenceType;
        op_sequence_type: SequenceType;
        multi mp_sequence_type: SequenceType;
    }

    type EnumPropertiesType {
        required rp_enum_type: EnumType;
        op_enum_type: EnumType;
        multi mp_enum_type: EnumType;
    }

    type VectorPropertiesType {
        required rp_vector_type: VectorType;
        op_vector_type: VectorType;
        multi mp_vector_type: VectorType;
    }

    type ArrayPropertiesType {
        required rp_array: array<str>;
        op_array: array<str>;
        multi mp_array: array<str>;
    }

    type TuplePropertiesType {
        required rl_unnamed_tuple: UnnamedTuplePropertiesType;
        ol_unnamed_tuple: UnnamedTuplePropertiesType;
        multi ml_unnamed_tuple: UnnamedTuplePropertiesType;

        required rl_named_tuple: NamedTuplePropertiesType;
        ol_named_tuple: NamedTuplePropertiesType;
        multi ml_named_tuple: NamedTuplePropertiesType;
    }

    type UnnamedTuplePropertiesType {
        required rp_unnamed_tuple: tuple<str, bool, tuple<str, bool, EnumType>>;
        op_unnamed_tuple: tuple<str, bool, tuple<str, bool, EnumType>>;
        multi mp_unnamed_tuple: tuple<str, bool, tuple<str, bool, EnumType>>;
    }

    type NamedTuplePropertiesType {
        required rp_named_tuple: tuple<a: str, b: bool, c: tuple<a: str, b: bool, c: EnumType>>;
        op_named_tuple: tuple<a: str, b: bool, c: tuple<a: str, b: bool, c: EnumType>>;
        multi mp_named_tuple: tuple<a: str, b: bool, c: tuple<a: str, b: bool, c: EnumType>>;
    }

    type RangePropertiesType {
        required rl_range_int32: RangeInt32PropertiesType;
        ol_range_int32: RangeInt32PropertiesType;
        multi ml_range_int32: RangeInt32PropertiesType;

        required rl_range_int64: RangeInt64PropertiesType;
        ol_range_int64: RangeInt64PropertiesType;
        multi ml_range_int64: RangeInt64PropertiesType;

        required rl_range_float32: RangeFloat32PropertiesType;
        ol_range_float32: RangeFloat32PropertiesType;
        multi ml_range_float32: RangeFloat32PropertiesType;

        required rl_range_float64: RangeFloat64PropertiesType;
        ol_range_float64: RangeFloat64PropertiesType;
        multi ml_range_float64: RangeFloat64PropertiesType;

        required rl_range_decimal: RangeDecimalPropertiesType;
        ol_range_decimal: RangeDecimalPropertiesType;
        multi ml_range_decimal: RangeDecimalPropertiesType;

        required rl_range_datetime: RangeDatetimePropertiesType;
        ol_range_datetime: RangeDatetimePropertiesType;
        multi ml_range_datetime: RangeDatetimePropertiesType;

        required rl_range_cal_local_datetime: RangeCalLocalDatetimePropertiesType;
        ol_range_cal_local_datetime: RangeCalLocalDatetimePropertiesType;
        multi ml_range_cal_local_datetime: RangeCalLocalDatetimePropertiesType;

        required rl_range_cal_local_date: RangeCalLocalDatePropertiesType;
        ol_range_cal_local_date: RangeCalLocalDatePropertiesType;
        multi ml_range_cal_local_date: RangeCalLocalDatePropertiesType;
    }

    type RangeInt32PropertiesType {
        required rl_single_range_int32: SingleRangeInt32PropertiesType;
        ol_single_range_int32: SingleRangeInt32PropertiesType;
        multi ml_single_range_int32: SingleRangeInt32PropertiesType;

        required rl_multi_range_int32: MultiRangeInt32PropertiesType;
        ol_multi_range_int32: MultiRangeInt32PropertiesType;
        multi ml_multi_range_int32: MultiRangeInt32PropertiesType;
    }

    type SingleRangeInt32PropertiesType {
        required rp_range_int32: range<int32>;
        op_range_int32: range<int32>;
        multi mp_range_int32: range<int32>;
    }

    type MultiRangeInt32PropertiesType {
        required rp_multi_range_int32: multirange<int32>;
        op_multi_range_int32: multirange<int32>;
        multi mp_multi_range_int32: multirange<int32>;
    }

    type RangeInt64PropertiesType {
        required rl_single_range_int64: SingleRangeInt64PropertiesType;
        ol_single_range_int64: SingleRangeInt64PropertiesType;
        multi ml_single_range_int64: SingleRangeInt64PropertiesType;

        required rl_multi_range_int64: MultiRangeInt64PropertiesType;
        ol_multi_range_int64: MultiRangeInt64PropertiesType;
        multi ml_multi_range_int64: MultiRangeInt64PropertiesType;
    }

    type SingleRangeInt64PropertiesType {
        required rp_range_int64: range<int64>;
        op_range_int64: range<int64>;
        multi mp_range_int64: range<int64>;
    }

    type MultiRangeInt64PropertiesType {
        required rp_multi_range_int64: multirange<int64>;
        op_multi_range_int64: multirange<int64>;
        multi mp_multi_range_int64: multirange<int64>;
    }

    type RangeFloat32PropertiesType {
        required rl_single_range_float32: SingleRangeFloat32PropertiesType;
        ol_single_range_float32: SingleRangeFloat32PropertiesType;
        multi ml_single_range_float32: SingleRangeFloat32PropertiesType;

        required rl_multi_range_float32: MultiRangeFloat32PropertiesType;
        ol_multi_range_float32: MultiRangeFloat32PropertiesType;
        multi ml_multi_range_float32: MultiRangeFloat32PropertiesType;
    }

    type SingleRangeFloat32PropertiesType {
        required rp_range_float32: range<float32>;
        op_range_float32: range<float32>;
        multi mp_range_float32: range<float32>;
    }

    type MultiRangeFloat32PropertiesType {
        required rp_multirange_float32: multirange<float32>;
        op_multirange_float32: multirange<float32>;
        multi mp_multirange_float32: multirange<float32>;
    }

    type RangeFloat64PropertiesType {
        required rl_single_range_float64: SingleRangeFloat64PropertiesType;
        ol_single_range_float64: SingleRangeFloat64PropertiesType;
        multi ml_single_range_float64: SingleRangeFloat64PropertiesType;

        required rl_multi_range_float64: MultiRangeFloat64PropertiesType;
        ol_multi_range_float64: MultiRangeFloat64PropertiesType;
        multi ml_multi_range_float64: MultiRangeFloat64PropertiesType;
    }

    type SingleRangeFloat64PropertiesType {
        required rp_range_float64: range<float64>;
        op_range_float64: range<float64>;
        multi mp_range_float64: range<float64>;
    }

    type MultiRangeFloat64PropertiesType {
        required rp_multirange_float64: multirange<float64>;
        op_multirange_float64: multirange<float64>;
        multi mp_multirange_float64: multirange<float64>;
    }

    type RangeDecimalPropertiesType {
        required rl_single_range_decimal: SingleRangeDecimalPropertiesType;
        ol_single_range_decimal: SingleRangeDecimalPropertiesType;
        multi ml_single_range_decimal: SingleRangeDecimalPropertiesType;

        required rl_multi_range_decimal: MultiRangeDecimalPropertiesType;
        ol_multi_range_decimal: MultiRangeDecimalPropertiesType;
        multi ml_multi_range_decimal: MultiRangeDecimalPropertiesType;
    }

    type SingleRangeDecimalPropertiesType {
        required rp_range_decimal: range<decimal>;
        op_range_decimal: range<decimal>;
        multi mp_range_decimal: range<decimal>;
    }

    type MultiRangeDecimalPropertiesType {
        required rp_multirange_decimal: multirange<decimal>;
        op_multirange_decimal: multirange<decimal>;
        multi mp_multirange_decimal: multirange<decimal>;
    }

    type RangeDatetimePropertiesType {
        required rl_single_range_datetime: SingleRangeDatetimePropertiesType;
        ol_single_range_datetime: SingleRangeDatetimePropertiesType;
        multi ml_single_range_datetime: SingleRangeDatetimePropertiesType;

        required rl_multi_range_datetime: MultiRangeDatetimePropertiesType;
        ol_multi_range_datetime: MultiRangeDatetimePropertiesType;
        multi ml_multi_range_datetime: MultiRangeDatetimePropertiesType;
    }

    type SingleRangeDatetimePropertiesType {
        required rp_range_datetime: range<datetime>;
        op_range_datetime: range<datetime>;
        multi mp_range_datetime: range<datetime>;
    }

    type MultiRangeDatetimePropertiesType {
        required rp_multirange_datetime: multirange<datetime>;
        op_multirange_datetime: multirange<datetime>;
        multi mp_multirange_datetime: multirange<datetime>;
    }

    type RangeCalLocalDatetimePropertiesType {
        required rl_single_range_cal_local_datetime: SingleRangeCalLocalDatetimePropertiesType;
        ol_single_range_cal_local_datetime: SingleRangeCalLocalDatetimePropertiesType;
        multi ml_single_range_cal_local_datetime: SingleRangeCalLocalDatetimePropertiesType;

        required rl_multi_range_cal_local_datetime: MultiRangeCalLocalDatetimePropertiesType;
        ol_multi_range_cal_local_datetime: MultiRangeCalLocalDatetimePropertiesType;
        multi ml_multi_range_cal_local_datetime: MultiRangeCalLocalDatetimePropertiesType;
    }

    type SingleRangeCalLocalDatetimePropertiesType {
        required rp_range_cal_local_datetime: range<cal::local_datetime>;
        op_range_cal_local_datetime: range<cal::local_datetime>;
        multi mp_range_cal_local_datetime: range<cal::local_datetime>;
    }

    type MultiRangeCalLocalDatetimePropertiesType {
        required rp_multirange_cal_local_datetime: multirange<cal::local_datetime>;
        op_multirange_cal_local_datetime: multirange<cal::local_datetime>;
        multi mp_multirange_cal_local_datetime: multirange<cal::local_datetime>;
    }

    type RangeCalLocalDatePropertiesType {
        required rl_single_range_cal_local_date: SingleRangeCalLocalDatePropertiesType;
        ol_single_range_cal_local_date: SingleRangeCalLocalDatePropertiesType;
        multi ml_single_range_cal_local_date: SingleRangeCalLocalDatePropertiesType;

        required rl_multi_range_cal_local_date: MultiRangeCalLocalDatePropertiesType;
        ol_multi_range_cal_local_date: MultiRangeCalLocalDatePropertiesType;
        multi ml_multi_range_cal_local_date: MultiRangeCalLocalDatePropertiesType;
    }

    type SingleRangeCalLocalDatePropertiesType {
        required rp_range_cal_local_date: range<cal::local_date>;
        op_range_cal_local_date: range<cal::local_date>;
        multi mp_range_cal_local_date: range<cal::local_date>;
    }

    type MultiRangeCalLocalDatePropertiesType {
        required rp_multirange_cal_local_date: multirange<cal::local_date>;
        op_multirange_cal_local_date: multirange<cal::local_date>;
        multi mp_multirange_cal_local_date: multirange<cal::local_date>;
    }

    type Aggregate {
        required rl_str: StrPropertiesType;
        ol_str: StrPropertiesType;
        multi ml_str: StrPropertiesType;

        required rl_bool: BoolPropertiesType;
        ol_bool: BoolPropertiesType;
        multi ml_bool: BoolPropertiesType;

        required rl_number: NumberPropertiesType;
        ol_number: NumberPropertiesType;
        multi ml_number: NumberPropertiesType;

        required rl_json: JsonPropertiesType;
        ol_json: JsonPropertiesType;
        multi ml_json: JsonPropertiesType;

        required rl_uuid: UuidPropertiesType;
        ol_uuid: UuidPropertiesType;
        multi ml_uuid: UuidPropertiesType;

        required rl_date_and_time: DateAndTimePropertiesType;
        ol_date_and_time: DateAndTimePropertiesType;
        multi ml_date_and_time: DateAndTimePropertiesType;

        required rl_cfg: CfgPropertiesType;
        ol_cfg: CfgPropertiesType;
        multi ml_cfg: CfgPropertiesType;

        required rl_sequence: SequencePropertiesType;
        ol_sequence: SequencePropertiesType;
        multi ml_sequence: SequencePropertiesType;

        required rl_enum: EnumPropertiesType;
        ol_enum: EnumPropertiesType;
        multi ml_enum: EnumPropertiesType;

        required rl_vector: VectorPropertiesType;
        ol_vector: VectorPropertiesType;
        multi ml_vector: VectorPropertiesType;

        required rl_array: ArrayPropertiesType;
        ol_array: ArrayPropertiesType;
        multi ml_array: ArrayPropertiesType;

        required rl_tuple: TuplePropertiesType;
        ol_tuple: TuplePropertiesType;
        multi ml_tuple: TuplePropertiesType;

        required rl_range: RangePropertiesType;
        ol_range: RangePropertiesType;
        multi ml_range: RangePropertiesType;
    }
};
