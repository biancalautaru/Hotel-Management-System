-- Să se creeze un trigger care nu permite ștergerea tabelelor.
CREATE OR REPLACE TRIGGER trg_drop_table
BEFORE DROP ON SCHEMA
BEGIN
    IF UPPER(ora_dict_obj_type) = 'TABLE' THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nu se pot sterge tabele.');
    END IF;
END;

-- declansare trigger
DROP TABLE hoteluri;