select {
    # string
    cp_str := <str>$0,
    cp_str_type := <codegen::StrType>$1,

    cp_bool := <bool>$2,
    cp_bool_type := <codegen::BoolType>$3,

    cp_int16 := <int16>$4,
    cp_int16_type := <codegen::Int16Type>$5,

    cp_int32 := <int32>$6,
    cp_int32_type := <codegen::Int32Type>$7,

    cp_int64 := <int64>$8,
    cp_int64_type := <codegen::Int64Type>$9,

    cp_float32 := <float32>$10,
    cp_float32_type := <codegen::Float32Type>$11,

    cp_float64 := <float64>$12,
    cp_float64_type := <codegen::Float64Type>$13,

    cp_decimal := <decimal>$14,
    cp_decimal_type := <codegen::DecimalType>$15,

    # json

    cp_json := <json>$16,
    cp_json_type := <codegen::JsonType>$17,

    # uuid

    cp_uuid := <uuid>$18,
    cp_uuid_type := <codegen::UuidType>$19,

    # enum

    cp_enum := <codegen::EnumType>$20,

    # date/time

    cp_datetime := <datetime>$21,
    cp_datetime_type := <codegen::DatetimeType>$22,

    cp_duration := <duration>$23,
    cp_duration_type := <codegen::DurationType>$24,

    cp_cal_local_datetime := <cal::local_datetime>$25,
    cp_cal_local_datetime_type := <codegen::CalLocalDatetimeType>$26,

    cp_cal_local_date := <cal::local_date>$27,
    cp_cal_local_date_type := <codegen::CalLocalDateType>$28,

    cp_cal_local_time := <cal::local_time>$29,
    cp_cal_local_time_type := <codegen::CalLocalTimeType>$30,

    cp_cal_relative_duration := <cal::relative_duration>$31,
    cp_cal_relative_duration_type := <codegen::CalRelativeDurationType>$32,

    cp_cal_date_duration := <cal::date_duration>$33,
    cp_cal_date_duration_type := <codegen::CalDateDurationType>$34,

    # array

    cp_array_int64 := <array<int64>>$35,

    # range

    cp_range_int32 := <range<int32>>$36,

    cp_range_int64 := <range<int64>>$37,

    cp_range_float32 := <range<float32>>$38,

    cp_range_float64 := <range<float64>>$39,

    cp_range_decimal := <range<decimal>>$40,

    cp_range_datetime := <range<datetime>>$41,

    cp_range_cal_local_datetime := <range<cal::local_datetime>>$42,

    cp_range_cal_local_date := <range<cal::local_date>>$43,

    # bytes

    cp_bytes := <bytes>$44,
    cp_bytes_type := <codegen::BytesType>$45,

    # config

    cp_cfg_memory := <cfg::memory>$46,
    cp_cfg_memory_type := <codegen::CfgMemoryType>$47,
}
