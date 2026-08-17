


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."get_email_by_login"("p_login" "text") RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    select email from profiles where login = p_login limit 1;
  $$;


ALTER FUNCTION "public"."get_email_by_login"("p_login" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "site_id" "text",
    "action" "text" NOT NULL,
    "detail" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."audit_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."audit_log_id_seq" OWNED BY "public"."audit_log"."id";



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "login" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "email" "text" NOT NULL,
    "role" "text" DEFAULT 'geral'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sites" (
    "id" bigint NOT NULL,
    "site_id" "text" NOT NULL,
    "sigla" "text",
    "nome" "text",
    "endereco" "text",
    "municipio" "text",
    "tecnico" "text",
    "latitude" double precision,
    "longitude" double precision,
    "detentora" "text",
    "uc" "text",
    "status" "text" DEFAULT 'Ativo'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "foto_1" "text",
    "foto_2" "text",
    "foto_3" "text",
    "foto_4" "text",
    "foto_5" "text",
    "chave_portao" "text",
    "chave_gradil_01" "text",
    "chave_gradil_02" "text",
    "fonte_01" "text",
    "fonte_02" "text",
    "consumo_fonte_01" "text",
    "consumo_fonte_02" "text",
    "baterias_fonte_01" "text",
    "baterias_fonte_02" "text",
    "uf" "text"
);


ALTER TABLE "public"."sites" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."sites_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."sites_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."sites_id_seq" OWNED BY "public"."sites"."id";



CREATE TABLE IF NOT EXISTS "public"."sites_import" (
    "site_id" "text",
    "uf" "text",
    "sigla" "text",
    "nome" "text",
    "endereco" "text",
    "municipio" "text",
    "tecnico" "text",
    "latitude" "text",
    "longitude" "text",
    "detentora" "text",
    "uc" "text",
    "status" "text"
);


ALTER TABLE "public"."sites_import" OWNER TO "postgres";


ALTER TABLE ONLY "public"."audit_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."audit_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."sites" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sites_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_login_key" UNIQUE ("login");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sites"
    ADD CONSTRAINT "sites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sites"
    ADD CONSTRAINT "sites_site_id_key" UNIQUE ("site_id");



CREATE INDEX "sites_uf_idx" ON "public"."sites" USING "btree" ("uf");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("site_id");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Autenticados leem audit" ON "public"."audit_log" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Autenticados leem sites" ON "public"."sites" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Escrita autenticada" ON "public"."sites" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Leitura pública de sites" ON "public"."sites" FOR SELECT USING (true);



CREATE POLICY "Usuário lê próprio profile" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cell_owner atualiza sites" ON "public"."sites" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'cell_owner'::"text")))));



CREATE POLICY "cell_owner insere audit" ON "public"."audit_log" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sites_import" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."get_email_by_login"("p_login" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_email_by_login"("p_login" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_email_by_login"("p_login" "text") TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "anon";
GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."sites" TO "anon";
GRANT ALL ON TABLE "public"."sites" TO "authenticated";
GRANT ALL ON TABLE "public"."sites" TO "service_role";



GRANT ALL ON SEQUENCE "public"."sites_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sites_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."sites_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."sites_import" TO "anon";
GRANT ALL ON TABLE "public"."sites_import" TO "authenticated";
GRANT ALL ON TABLE "public"."sites_import" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







