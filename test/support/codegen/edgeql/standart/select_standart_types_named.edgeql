select {
    # string
    cp_str := <str>$cp_str,
    cp_str_type := <codegen::StrType>$cp_str_type,

    cp_bool := <bool>$cp_bool,
    cp_bool_type := <codegen::BoolType>$cp_bool_type,

    cp_int16 := <int16>$cp_int16,
    cp_int16_type := <codegen::Int16Type>$cp_int16_type,

    cp_int32 := <int32>$cp_int32,
    cp_int32_type := <codegen::Int32Type>$cp_int32_type,

    cp_int64 := <int64>$cp_int64,
    cp_int64_type := <codegen::Int64Type>$cp_int64_type,

    cp_float32 := <float32>$cp_float32,
    cp_float32_type := <codegen::Float32Type>$cp_float32_type,

    cp_float64 := <float64>$cp_float64,
    cp_float64_type := <codegen::Float64Type>$cp_float64_type,

    cp_decimal := <decimal>$cp_decimal,
    cp_decimal_type := <codegen::DecimalType>$cp_decimal_type,

    # json

    cp_json := <json>$cp_json,
    cp_json_type := <codegen::JsonType>$cp_json_type,

    # uuid

    cp_uuid := <uuid>$cp_uuid,
    cp_uuid_type := <codegen::UuidType>$cp_uuid_type,

    # enum

    cp_enum := <codegen::EnumType>$cp_enum,

    # date/time

    cp_datetime := <datetime>$cp_datetime,
    cp_datetime_type := <codegen::DatetimeType>$cp_datetime_type,

    cp_duration := <duration>$cp_duration,
    cp_duration_type := <codegen::DurationType>$cp_duration_type,

    cp_cal_local_datetime := <cal::local_datetime>$cp_cal_local_datetime,
    cp_cal_local_datetime_type := <codegen::CalLocalDatetimeType>$cp_cal_local_datetime_type,

    cp_cal_local_date := <cal::local_date>$cp_cal_local_date,
    cp_cal_local_date_type := <codegen::CalLocalDateType>$cp_cal_local_date_type,

    cp_cal_local_time := <cal::local_time>$cp_cal_local_time,
    cp_cal_local_time_type := <codegen::CalLocalTimeType>$cp_cal_local_time_type,

    cp_cal_relative_duration := <cal::relative_duration>$cp_cal_relative_duration,
    cp_cal_relative_duration_type := <codegen::CalRelativeDurationType>$cp_cal_relative_duration_type,

    cp_cal_date_duration := <cal::date_duration>$cp_cal_date_duration,
    cp_cal_date_duration_type := <codegen::CalDateDurationType>$cp_cal_date_duration_type,

    # array

    cp_array_int64 := <array<int64>>$cp_array_int64,

    # range

    cp_range_int32 := <range<int32>>$cp_range_int32,

    cp_range_int64 := <range<int64>>$cp_range_int64,

    cp_range_float32 := <range<float32>>$cp_range_float32,

    cp_range_float64 := <range<float64>>$cp_range_float64,

    cp_range_decimal := <range<decimal>>$cp_range_decimal,

    cp_range_datetime := <range<datetime>>$cp_range_datetime,

    cp_range_cal_local_datetime := <range<cal::local_datetime>>$cp_range_cal_local_datetime,

    cp_range_cal_local_date := <range<cal::local_date>>$cp_range_cal_local_date,

    # bytes

    cp_bytes := <bytes>$cp_bytes,
    cp_bytes_type := <codegen::BytesType>$cp_bytes_type,

    # config

    cp_cfg_memory := <cfg::memory>$cp_cfg_memory,
    cp_cfg_memory_type := <codegen::CfgMemoryType>$cp_cfg_memory_type,
}
