-- Să se creeze un trigger care nu permite modificarea rezervărilor finalizate.

CREATE OR REPLACE TRIGGER trg_update_rezervari_finalizate
BEFORE UPDATE ON rezervari
FOR EACH ROW
BEGIN
    IF UPPER(:OLD.stare) = 'FINALIZATA' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Rezerv�rile finalizate nu pot fi modificate.');
    END IF;
END;

-- declansare trigger
UPDATE rezervari
SET numar_persoane = numar_persoane + 1
WHERE id_rezervare = 60000003;