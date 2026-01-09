/*
Se dau un hotel și un număr de persoane. Să se afișeze informații despre rezervare, client și suma totală de plată (suma tuturor facturilor asociate unei rezervări)
pentru toate rezervările de la acel hotel pentru numărul dat de persoane.
*/

CREATE OR REPLACE PROCEDURE rezervari_hotel_numar_persoane (
    p_id_hotel hoteluri.id_hotel%TYPE,
    p_numar_persoane rezervari.numar_persoane%TYPE
)
IS
    e_hotel_inexistent EXCEPTION;
    e_fara_rezervari EXCEPTION;
    
    v_count NUMBER;
BEGIN
    IF p_numar_persoane < 0 OR p_numar_persoane IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Număr persoane invalid.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM hoteluri
    WHERE id_hotel = p_id_hotel;
    
    IF v_count = 0 THEN
        RAISE e_hotel_inexistent;
    END IF;
    
    SELECT COUNT(*) INTO v_count
    FROM rezervari r JOIN camere c ON (r.id_camera = c.id_camera)
    WHERE c.id_hotel = p_id_hotel AND r.numar_persoane = p_numar_persoane;
    
    IF v_count = 0 THEN
        RAISE e_fara_rezervari;
    END IF;
    
    FOR x IN (
        SELECT r.id_rezervare, r.data_rezervare, r.data_inceput, r.data_sfarsit, cl.nume, cl.prenume, cl.email, NVL(SUM(f.suma), 0) AS suma_totala
        FROM hoteluri h JOIN camere c ON (h.id_hotel = c.id_hotel)
                        JOIN rezervari r ON (c.id_camera = r.id_camera)
                        JOIN clienti cl ON (r.id_client = cl.id_client)
                   LEFT JOIN facturi f ON (r.id_rezervare = f.id_rezervare)
        WHERE h.id_hotel = p_id_hotel AND r.numar_persoane = p_numar_persoane
        GROUP BY r.id_rezervare, r.data_rezervare, r.data_inceput, r.data_sfarsit, cl.nume, cl.prenume, cl.email
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('ID rezervare: ' || x.id_rezervare);
        DBMS_OUTPUT.PUT_LINE('Dată rezervare: ' || x.data_rezervare);
        DBMS_OUTPUT.PUT_LINE('Perioadă: ' || x.data_inceput || ' - ' || x.data_sfarsit);
        DBMS_OUTPUT.PUT_LINE('Nume client: ' || x.nume || ' ' || x.prenume);
        DBMS_OUTPUT.PUT_LINE('Email client: ' || x.email);
        DBMS_OUTPUT.PUT_LINE('Suma totală: ' || x.suma_totala);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
EXCEPTION
    WHEN e_hotel_inexistent THEN
        DBMS_OUTPUT.PUT_LINE('Hotelul nu există.');
        
    WHEN e_fara_rezervari THEN
        DBMS_OUTPUT.PUT_LINE('Nu există rezervări pentru hotelul dat cu numărul de persoane date.');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- apel caz valid
BEGIN
    rezervari_hotel_numar_persoane(10002, 3);
END;
/

-- apel pentru hotel inexistent
BEGIN
    rezervari_hotel_numar_persoane(10006, 2);
END;
/

-- apel pentru care nu există rezervări
BEGIN
    rezervari_hotel_numar_persoane(10001, 3);
END;
/