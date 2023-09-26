CREATE MIGRATION m147bo4znisjhp7ymyunkfc66a3hqctob7lq5jp2xy2m4gh5vkzzya
    ONTO m1qb4i57nhmluwtd7pbeornej7kthhw34aejzjwrdcr65fiekxe3nq
{
  ALTER TYPE default::User {
      CREATE PROPERTY avatar_url -> std::str;
      CREATE PROPERTY external_homepage_url -> std::str;
  };
};
