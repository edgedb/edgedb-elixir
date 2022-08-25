with l_e := (insert codegen::E{ rp_a_str := <str>$rp_a_str, rp_e_str := <str>$rp_e_str })
insert codegen::F {
    rp_a_str := <str>$rp_a_str,
    rp_b_str := <str>$rp_b_str,
    rp_c_str := <str>$rp_c_str,
    rp_d_str := <str>$rp_d_str,
    rp_f_str := <str>$rp_f_str,

    ol_a_b := l_e,
    ml_a_b := {l_e},
}
