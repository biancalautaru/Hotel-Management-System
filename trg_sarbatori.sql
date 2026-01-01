-- Să se creeze un trigger care nu permite modificarea rezervărilor pe 25 decembrie și 1 ianuarie.

CREATE OR REPLACE TRIGGER trg_sarbatori
BEFORE UPDATE ON rezervari
DECLARE
    zi NUMBER := EXTRACT(DAY FROM SYSDATE);
    luna NUMBER := EXTRACT(MONTH FROM SYSDATE);
BEGIN
    IF (zi = 25 AND luna = 12) OR (zi = 1 AND luna = 1) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ast�zi nu se pot modifica rezerv�ri. Este zi liber�.');
    END IF;
END;

-- declansare trigger (data de azi este 1 ianuarie)
UPDATE rezervari
SET stare = 'CONFIRMATA'
WHERE id_rezervare = 60000002;