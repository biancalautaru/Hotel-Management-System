CREATE OR REPLACE PROCEDURE hotel_incasari_max_perioada (
    p_data_inceput IN DATE,
    p_data_sfarsit IN DATE
)
IS
    TYPE t_incasari_hotel IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_sume IS TABLE OF facturi.suma%TYPE;
    TYPE t_metode_plata IS VARRAY(2) OF facturi.metoda_plata%TYPE;
    
    v_incasari t_incasari_hotel;
    v_sume t_sume := t_sume();
    v_metode_acceptate t_metode_plata := t_metode_plata('CARD', 'NUMERAR');
    
    v_acceptata BOOLEAN;
    i PLS_INTEGER;
    v_suma_max facturi.suma%TYPE := 0;
    v_id_hotel_max hoteluri.id_hotel%TYPE;
    v_denumire_hotel_max hoteluri.denumire%TYPE;
    
    v_numar_facturi NUMBER;
    v_suma_totala NUMBER;
    v_medie NUMBER;
BEGIN
    FOR x IN (
        SELECT h.id_hotel, f.suma, f.metoda_plata
        FROM hoteluri h JOIN camere c ON h.id_hotel = c.id_hotel
                        JOIN rezervari r ON c.id_camera = r.id_camera
                        JOIN facturi f ON r.id_rezervare = f.id_rezervare
        WHERE f.stare_plata = 'PLATITA'
          AND f.data_plata BETWEEN p_data_inceput AND p_data_sfarsit
    )
    LOOP
        v_acceptata := FALSE;
        FOR j IN 1..v_metode_acceptate.COUNT LOOP
            IF UPPER(x.metoda_plata) = UPPER(v_metode_acceptate(j)) THEN
                v_acceptata := TRUE;
                EXIT;
            END IF;
        END LOOP;
        
        IF v_acceptata THEN
            IF NOT v_incasari.EXISTS(x.id_hotel) THEN
                v_incasari(x.id_hotel) := 0;
            END IF;
            v_incasari(x.id_hotel) := v_incasari(x.id_hotel) + x.suma;
            
            v_sume.EXTEND;
            v_sume(v_sume.LAST) := x.suma;
        END IF;
    END LOOP;
    
    IF v_incasari.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista incasari cu metodele acceptate in perioada data.');
        RETURN;
    END IF;
    
    i := v_incasari.FIRST;
    WHILE i IS NOT NULL LOOP
        IF v_incasari(i) > v_suma_max THEN
            v_suma_max := v_incasari(i);
            v_id_hotel_max := i;
        END IF;
        i := v_incasari.NEXT(i);
    END LOOP;
    
    SELECT denumire INTO v_denumire_hotel_max
    FROM hoteluri
    WHERE id_hotel = v_id_hotel_max;
    
    DBMS_OUTPUT.PUT_LINE('Hotelul cu cele mai mari incasari in perioada ' || p_data_inceput || ' - ' || p_data_sfarsit || ' este ' || v_denumire_hotel_max);
    
    v_numar_facturi := v_sume.COUNT; 
    v_suma_totala := 0;
    FOR j IN 1..v_numar_facturi LOOP
        v_suma_totala := v_suma_totala + v_sume(j);
    END LOOP;
    v_medie := ROUND(v_suma_totala / v_numar_facturi, 2);      
    
    DBMS_OUTPUT.PUT_LINE('Statistici facturi platite in perioada ' || p_data_inceput || ' - ' || p_data_sfarsit || ':');
    DBMS_OUTPUT.PUT_LINE('  Numar facturi: ' || v_numar_facturi);
    DBMS_OUTPUT.PUT_LINE('  Suma totala: '  || v_suma_totala);
    DBMS_OUTPUT.PUT_LINE('  Media: ' || v_medie);
END;

-- apel subprogram
BEGIN
    hotel_incasari_max_perioada(TO_DATE('01-07-2025' , 'DD-MM-YYYY'), TO_DATE('31-12-2025', 'DD-MM-YYYY'));
END;