/*
Să se afișeze pentru fiecare hotel, angajații care au lucrat în acel hotel, joburile pe care le-au ocupat și perioadele, în ordine crescătoare a datelor la care au început să lucreze.
*/

CREATE OR REPLACE PROCEDURE angajati_joburi_perioade
IS
    CURSOR c_hoteluri
    IS
        SELECT id_hotel, denumire
        FROM hoteluri;
        
    CURSOR c_angajati (
        p_id_hotel hoteluri.id_hotel%TYPE
    ) IS
        SELECT a.nume, a.prenume, j.denumire AS denumire_job, ij.data_inceput, ij.data_sfarsit
        FROM angajati a JOIN istoric_joburi ij ON a.id_angajat = ij.id_angajat
                        JOIN joburi j ON ij.id_job = j.id_job
        WHERE ij.id_hotel = p_id_hotel
        ORDER BY ij.data_inceput;
        
    v_hotel c_hoteluri%ROWTYPE;
    v_angajat c_angajati%ROWTYPE;
    v_gasit BOOLEAN;
BEGIN
    OPEN c_hoteluri;
    LOOP
        FETCH c_hoteluri INTO v_hotel;
        EXIT WHEN c_hoteluri%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Hotel: ' || v_hotel.denumire);
        
        v_gasit := false;
        OPEN c_angajati(v_hotel.id_hotel);
        LOOP
            FETCH c_angajati INTO v_angajat;
            EXIT WHEN c_angajati%NOTFOUND;
            
            v_gasit := true;
            DBMS_OUTPUT.PUT_LINE('  ' || v_angajat.nume || ' ' || v_angajat.prenume || ', ' || v_angajat.denumire_job || ', ' || TO_CHAR(v_angajat.data_inceput, 'DD-MM-YYYY') ||
                                 ' - ' || NVL(TO_CHAR(v_angajat.data_sfarsit, 'DD-MM-YYYY'), 'prezent'));
        END LOOP;
        CLOSE c_angajati;
        
        IF NOT v_gasit THEN
            DBMS_OUTPUT.PUT_LINE('  Nu exista angajati pentru acest hotel.');
        END IF;
        DBMS_OUTPUT.PUT_LINE(' ');
    END LOOP;
    CLOSE c_hoteluri;
END;
/

-- apel subprogram
BEGIN
    angajati_joburi_perioade;
END;
/