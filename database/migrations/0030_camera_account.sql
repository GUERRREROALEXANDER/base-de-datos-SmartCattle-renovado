-- 0030: cada camara pertenece a una cuenta, y su dueno le pone nombre.
--
-- account_id es el id en users del dueno de la cuenta: un trabajador comparte el
-- de su dueno, y por eso no se llama user_id. Son las columnas de la migracion
-- 0018_accounts del backend; da igual cual corra primero.
--
-- cameras.name sigue con su UNIQUE global: es el identificador que usan la API
-- y la IA, y el backend crea camaras con ON CONFLICT (name) DO NOTHING. Quitarlo
-- rompe esa ingesta. El nombre que elige la persona va en display_name.
--
-- account_id admite NULL: una camara que la IA reporta y nadie guardo no es de
-- nadie, y nadie la ve.

ALTER TABLE cameras ADD COLUMN IF NOT EXISTS account_id bigint;
ALTER TABLE cameras ADD COLUMN IF NOT EXISTS display_name text;

-- 0018_accounts la crea sin clave ajena. SET NULL: una cuenta borrada a mano deja
-- la camara sin dueno y conserva su historial.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cameras_account_id_fkey') THEN
        ALTER TABLE cameras
            ADD CONSTRAINT cameras_account_id_fkey
            FOREIGN KEY (account_id) REFERENCES users (id) ON DELETE SET NULL;
    END IF;
END $$;

-- Consulta: las camaras de una cuenta, en cada pagina y en cada reporte.
--     SELECT ... FROM cameras WHERE account_id = $1
-- El nombre es el de 0018_accounts, para no dejar dos indices iguales.
