CREATE MIGRATION m1ubvamklirsdncfa4delyrq7h7blijyycybtbud2j42e7unvhgu6a
    ONTO m12bi2uxbraa4docb2s3ajj5eodgcc2gbno6cf2jrwudhz6mhhdvta
{
  CREATE TYPE v1::Internal {
      CREATE PROPERTY value: std::int64 {
          CREATE CONSTRAINT std::exclusive;
      };
  };
};
