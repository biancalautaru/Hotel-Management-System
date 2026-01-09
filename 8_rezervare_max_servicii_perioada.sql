/*
Se dă un interval de timp (data de început și data de sfârșit). Să se găsească rezervarea inclusă în acest interval care are cele mai multe servicii suplimentare incluse.
*/

CREATE OR REPLACE FUNCTION rezervare_max_servicii_perioada (
    p_data_inceput IN DATE,
    p_data_sfarsit IN DATE
) RETURN rezervari.id_rezervare%TYPE
IS
    v_max_servicii NUMBER;
    v_id_rezervare rezervari.id_rezervare%TYPE;
BEGIN
    IF p_data_inceput > p_data_sfarsit OR p_data_inceput IS NULL OR p_data_sfarsit IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Perioadă invalidă.');
    END IF;

    SELECT MAX(cnt) INTO v_max_servicii
    FROM (SELECT COUNT(sr.id_serviciu) cnt
          FROM rezervari r JOIN servicii_rezervari sr ON (r.id_rezervare = sr.id_rezervare)
                           JOIN servicii s ON (sr.id_serviciu = s.id_serviciu)
          WHERE r.data_inceput >= p_data_inceput AND r.data_sfarsit <= p_data_sfarsit
          GROUP BY r.id_rezervare);
          
    IF v_max_servicii IS NULL THEN
        RAISE NO_DATA_FOUND;
    END IF;

    SELECT r.id_rezervare INTO v_id_rezervare
    FROM rezervari r JOIN servicii_rezervari sr ON (r.id_rezervare = sr.id_rezervare)
    WHERE r.data_inceput >= p_data_inceput AND r.data_sfarsit <= p_data_sfarsit
    GROUP BY r.id_rezervare
    HAVING COUNT(sr.id_serviciu) = v_max_servicii;
    
    RETURN v_id_rezervare;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu există rezervări cu servicii suplimentare incluse în perioada dată.');
    RETURN NULL;
    
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Există mai multe rezervări cu numărul maxim de servicii din perioada dată.');
    RETURN NULL;
    
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    RETURN NULL;
END;
/

-- apel caz valid
DECLARE
    v_id_rezervare rezervari.id_rezervare%TYPE;
    v_data_rezervare rezervari.data_rezervare%TYPE;
    v_data_inceput rezervari.data_inceput%TYPE;
    v_data_sfarsit rezervari.data_sfarsit%TYPE;
    v_numar_persoane rezervari.numar_persoane%TYPE;
BEGIN
    v_id_rezervare := rezervare_max_servicii_perioada(TO_DATE('12-01-2026', 'DD-MM-YYYY'), TO_DATE('11-02-2026', 'DD-MM-YYYY'));
    
    SELECT data_rezervare, data_inceput, data_sfarsit, numar_persoane
    INTO v_data_rezervare, v_data_inceput, v_data_sfarsit, v_numar_persoane
    FROM rezervari
    WHERE id_rezervare = v_id_rezervare;
    
    DBMS_OUTPUT.PUT_LINE('Rezervarea cu cele mai multe servicii din perioada 12.01.2026 - 11.02-2026: ');
    DBMS_OUTPUT.PUT_LINE('  ID rezervare: ' || v_id_rezervare);
    DBMS_OUTPUT.PUT_LINE('  Dată rezervare: ' || v_data_rezervare);
    DBMS_OUTPUT.PUT_LINE('  Perioadă: ' || v_data_inceput || ' - ' || v_data_sfarsit);
    DBMS_OUTPUT.PUT_LINE('  Număr persoane: ' || v_numar_persoane);
END;
/

-- apel pentru NO_DATA_FOUND
DECLARE
    v_id_rezervare rezervari.id_rezervare%TYPE;
BEGIN
    v_id_rezervare := rezervare_max_servicii_perioada(TO_DATE('01-09-2025', 'DD-MM-YYYY'), TO_DATE('15-09-2025', 'DD-MM-YYYY'));
END;
/

-- apel pentru TOO_MANY_ROWS
DECLARE
    v_id_rezervare rezervari.id_rezervare%TYPE;
BEGIN
    v_id_rezervare := rezervare_max_servicii_perioada(TO_DATE('01-08-2025', 'DD-MM-YYYY'), TO_DATE('31-12-2026', 'DD-MM-YYYY'));
END;
/

-- apel pentru OTHERS
DECLARE
    v_id_rezervare rezervari.id_rezervare%TYPE;
BEGIN
    v_id_rezervare := rezervare_max_servicii_perioada(TO_DATE('15-01-2026', 'DD-MM-YYYY'), TO_DATE('01-01-2026', 'DD-MM-YYYY'));
END;
/