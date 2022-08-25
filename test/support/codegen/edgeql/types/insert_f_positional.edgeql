with l_e := (insert codegen::E{ rp_a_str := <str>$0, rp_e_str := <str>$4 })
insert codegen::F {
    rp_a_str := <str>$0,
    rp_b_str := <str>$1,
    rp_c_str := <str>$2,
    rp_d_str := <str>$3,
    rp_f_str := <str>$5,

    ol_a_b := l_e,
    ml_a_b := {l_e},
}
