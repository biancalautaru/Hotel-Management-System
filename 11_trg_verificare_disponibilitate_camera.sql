/*
Să se creeze un trigger care nu permite inserarea unei rezervări dacă este deja ocupată camera în acea perioadă de o rezervare care nu este finalizată sau anulată.
*/

CREATE OR REPLACE TRIGGER trg_verificare_disponibilitate_camera
BEFORE INSERT ON rezervari
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM rezervari r
    WHERE r.id_camera = :NEW.id_camera
      AND r.stare <> 'FINALIZATA'
      AND r.stare <> 'ANULATA'
      AND :NEW.data_inceput < r.data_sfarsit
      AND :NEW.data_sfarsit > r.data_inceput;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Camera este ocupata in perioada selectata.');
    END IF;
END;
/

-- declansare trigger
INSERT INTO rezervari VALUES (60000001, TO_DATE('01-02-2026', 'DD-MM-YYYY'), TO_DATE('03-02-2026', 'DD-MM-YYYY'), 3, TO_DATE('12-01-2026', 'DD-MM-YYYY'), NULL, 'CREATA', 50002, 40015);