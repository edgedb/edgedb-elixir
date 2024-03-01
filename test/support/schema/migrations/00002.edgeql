CREATE MIGRATION m1s4rwuphzakukj3i6wqbwi534ctcmaulpn4a4wfclpejyowtxkloq
    ONTO m1c65s2cgnjqbm4zvuyv6saeqpi5c446bceydxxr35zmjbf2ndymsq
{
  CREATE MODULE v2 IF NOT EXISTS;
  CREATE GLOBAL v2::current_user -> std::str;
};
