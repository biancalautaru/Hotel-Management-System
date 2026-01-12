/*
Să se creeze un trigger care nu permite inserarea unei rezervări dacă numărul de persoane este mai mare decât capacitatea camerei.
*/

CREATE OR REPLACE TRIGGER trg_verificare_capacitate_camera
BEFORE INSERT ON rezervari
FOR EACH ROW
DECLARE
    v_nr_max camere.numar_maxim_persoane%TYPE;
BEGIN
    SELECT numar_maxim_persoane INTO v_nr_max
    FROM camere
    WHERE id_camera = :NEW.id_camera;
    
    IF :NEW.numar_persoane > v_nr_max THEN
        RAISE_APPLICATION_ERROR(-20004, 'Numarul de persoane este mai mare decat capacitatea camerei.');
    END IF;
END;
/

INSERT INTO rezervari VALUES (60000009, TO_DATE('12-03-2026', 'DD-MM-YYYY'), TO_DATE('16-03-2026', 'DD-MM-YYYY'), 2, TO_DATE('12-01-2026', 'DD-MM-YYYY'), NULL, 'CREATA', 50001, 40001);