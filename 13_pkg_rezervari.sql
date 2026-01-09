/*
Să se creeze un pachet pentru gestionarea rezervărilor, care să includă următoarele:
- Tipuri de date:
    - un tip de date RECORD care stochează toate informațiile aferente unei rezervări
    - un tip de date colecție VARRAY care conține procentele reducerilor aplicate unei rezervări
- Funcții:
    - o funcție care verifică dacă o rezervare este validă (primind ca parametru rezervarea sub forma unui RECORD) din punct de vedere al regulilor de validare și integritate impuse de baza de date
    - o funcție care calculează numărul de nopți dintr-o rezervare validă
    - o funcție care calculează procentul total al reducerilor aplicate (având ca parametru un VARRAY cu valori care trebuie însumate)
    - o funcție care determină dacă o rezervare validă este activă (dacă nu este anulată și data curentă se află în perioada sejurului)
- Proceduri:
    - o procedură care calculează și salvează (în parametrul RECORD transmis ca referință) totalul de plată pentru o rezervare validă (pe baza numărului de nopți și tarifului camerei pe noapte, fără serviciile suplimentare)
    - o procedură care primește o rezervare validă și colecția de reduceri și aplică toate reducerile la totalul de plată al rezervării
    - o procedură care permite schimbarea camerei cu o cameră din același hotel pentru o rezervare validă și activă, ce primește ca parametri rezervarea, reducerile și  numărul camerei noi (dacă acea cameră este liberă și poate caza numărul dat de persoane, se recalculează totalul de plată aplicând noul tarif de noapte pentru restul sejurului, începând cu noaptea următoare)
    - o procedură care încarcă o rezervare din baza de date într-un RECORD
    - o procedură care inserează o rezervare validă primită ca parametru în baza de date sau îi actualizează datele dacă ea există deja
    - o procedură care afișează pe ecran toate informațiile unei rezervări din baza de date
*/

CREATE OR REPLACE PACKAGE pkg_rezervari
IS
    TYPE rezervare_rec IS RECORD (
        id_rezervare rezervari.id_rezervare%TYPE,
        data_inceput rezervari.data_inceput%TYPE,
        data_sfarsit rezervari.data_sfarsit%TYPE,
        numar_persoane rezervari.numar_persoane%TYPE,
        data_rezervare rezervari.data_rezervare%TYPE,
        total_plata rezervari.total_plata%TYPE,
        stare rezervari.stare%TYPE,
        id_client rezervari.id_client%TYPE,
        id_camera rezervari.id_camera%TYPE
    );
    
    TYPE reduceri_varray IS VARRAY(10) OF NUMBER;
    
    c_err_rezervare_invalida CONSTANT NUMBER := -20006;
    c_msg_rezervare_invalida CONSTANT VARCHAR2(30) := 'Rezervarea este invalida.';
    
    FUNCTION este_valida (
        p_rezervare IN rezervare_rec
    ) RETURN BOOLEAN;
    
    FUNCTION calculeaza_numar_nopti (
        p_rezervare IN rezervare_rec
    ) RETURN NUMBER;
    
    FUNCTION calculeaza_reducere_totala (
        p_reduceri IN reduceri_varray
    ) RETURN NUMBER;
    
    FUNCTION este_activa (
        p_rezervare IN rezervare_rec
    ) RETURN BOOLEAN;
    
    PROCEDURE calculeaza_total_plata (
        p_rezervare IN OUT rezervare_rec
    );
    
    PROCEDURE aplica_reduceri (
        p_rezervare IN OUT rezervare_rec,
        p_reduceri IN reduceri_varray
    );
    
    PROCEDURE schimba_camera (
        p_rezervare IN OUT rezervare_rec,
        p_reduceri IN reduceri_varray,
        p_numar_camera IN camere.numar_camera%TYPE
    );
    
    PROCEDURE select_rezervare (
        p_id_rezervare IN rezervari.id_rezervare%TYPE,
        p_rezervare OUT rezervare_rec
    );
    
    PROCEDURE insert_sau_update_rezervare (
        p_rezervare IN rezervare_rec
    );
    
    PROCEDURE afisare_rezervare (
        p_id_rezervare rezervari.id_rezervare%TYPE
    );
END pkg_rezervari;
/

CREATE OR REPLACE PACKAGE BODY pkg_rezervari
IS
    FUNCTION este_valida (
        p_rezervare IN rezervare_rec
    ) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        IF p_rezervare.id_rezervare IS NULL
           OR p_rezervare.data_inceput IS NULL
           OR p_rezervare.data_sfarsit IS NULL
           OR p_rezervare.numar_persoane IS NULL
           OR p_rezervare.data_rezervare IS NULL
           OR p_rezervare.stare IS NULL
           OR p_rezervare.id_client IS NULL
           OR p_rezervare.id_camera IS NULL THEN
            RETURN FALSE;
        END IF;
        
        IF p_rezervare.data_inceput >= p_rezervare.data_sfarsit THEN
            RETURN FALSE;
        END IF;
            
        IF p_rezervare.numar_persoane <= 0 THEN
            RETURN FALSE;
        END IF;
            
        IF p_rezervare.data_rezervare > p_rezervare.data_inceput THEN
            RETURN FALSE;
        END IF;
        
        IF UPPER(p_rezervare.stare) NOT IN ('CREATA', 'CONFIRMATA', 'ANULATA', 'FINALIZATA') THEN
            RETURN FALSE;
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM clienti
        WHERE id_client = p_rezervare.id_client;
        
        IF v_count = 0 THEN
            RETURN FALSE;
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM camere
        WHERE id_camera = p_rezervare.id_camera;
                
        IF v_count = 0 THEN
            RETURN FALSE;
        END IF;
        
        RETURN TRUE;
    END este_valida;

    FUNCTION calculeaza_numar_nopti (
        p_rezervare IN rezervare_rec
    ) RETURN NUMBER
    IS
    BEGIN
        IF NOT este_valida(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(c_err_rezervare_invalida, c_msg_rezervare_invalida);
        END IF;
    
        RETURN TRUNC(p_rezervare.data_sfarsit) - TRUNC(p_rezervare.data_inceput);
    END calculeaza_numar_nopti;
    
    FUNCTION calculeaza_reducere_totala (
        p_reduceri IN reduceri_varray
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        IF p_reduceri IS NULL THEN
            RETURN 0;
        END IF;
        
        v_total := 0;
        FOR i IN 1..p_reduceri.COUNT LOOP
            IF p_reduceri(i) < 0 OR p_reduceri(i) > 100 THEN
                RAISE_APPLICATION_ERROR(-20007, 'Procent de reducere invalid: valoarile trebuie sa fie intre 0 si 100.');
            END IF;
        
            v_total := v_total + p_reduceri(i);
        END LOOP;
        
        IF v_total > 100 THEN
            v_total := 100;
        END IF;
        
        RETURN v_total;
    END calculeaza_reducere_totala;
    
    FUNCTION este_activa (
        p_rezervare IN rezervare_rec
    ) RETURN BOOLEAN
    IS
    BEGIN
        IF NOT este_valida(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(c_err_rezervare_invalida, c_msg_rezervare_invalida);
        END IF;
    
        IF TRUNC(SYSDATE) >= p_rezervare.data_inceput AND TRUNC(SYSDATE) <= p_rezervare.data_sfarsit AND UPPER(p_rezervare.stare) <> 'ANULATA' THEN
            RETURN TRUE;
        END IF;
        
        RETURN FALSE;
    END este_activa;
    
    PROCEDURE calculeaza_total_plata (
        p_rezervare IN OUT rezervare_rec
    )
    IS
        v_pret_noapte camere.pret_noapte%TYPE;
    BEGIN
        IF NOT este_valida(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(c_err_rezervare_invalida, c_msg_rezervare_invalida);
        END IF;
    
        SELECT pret_noapte INTO v_pret_noapte
        FROM camere
        WHERE id_camera = p_rezervare.id_camera;
        
        p_rezervare.total_plata := calculeaza_numar_nopti(p_rezervare) * v_pret_noapte;
    END calculeaza_total_plata;
    
    PROCEDURE aplica_reduceri (
        p_rezervare IN OUT rezervare_rec,
        p_reduceri IN reduceri_varray
    )
    IS
    BEGIN
        IF NOT este_valida(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(c_err_rezervare_invalida, c_msg_rezervare_invalida);
        END IF;
    
        IF p_rezervare.total_plata IS NULL THEN
            RAISE_APPLICATION_ERROR(-20008, 'Reducerile nu se pot aplica inaintea calculului pretului de baza.');
        END IF;
    
        p_rezervare.total_plata := p_rezervare.total_plata * (1 - calculeaza_reducere_totala(p_reduceri) / 100);
    END aplica_reduceri;
    
    PROCEDURE schimba_camera (
        p_rezervare IN OUT rezervare_rec,
        p_reduceri IN reduceri_varray,
        p_numar_camera IN camere.numar_camera%TYPE
    )
    IS
        v_id_hotel hoteluri.id_hotel%TYPE;
        v_id_camera camere.id_camera%TYPE;
        v_nopti_inainte NUMBER;
        v_nopti_dupa NUMBER;
        v_pret_inainte camere.pret_noapte%TYPE;
        v_pret_dupa camere.pret_noapte%TYPE;
        v_numar_maxim_persoane camere.numar_maxim_persoane%TYPE;
        v_count NUMBER;
        v_data_noua DATE;
    BEGIN
        IF NOT este_activa(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(-20009, 'Rezervarea nu este activa.');
        END IF;
        
        v_data_noua := TRUNC(SYSDATE) + 1;
    
        SELECT id_hotel, pret_noapte INTO v_id_hotel, v_pret_inainte
        FROM camere
        WHERE id_camera = p_rezervare.id_camera;
    
        SELECT id_camera, pret_noapte, numar_maxim_persoane INTO v_id_camera, v_pret_dupa, v_numar_maxim_persoane
        FROM camere
        WHERE id_hotel = v_id_hotel AND numar_camera = p_numar_camera;
        
        IF p_rezervare.numar_persoane > v_numar_maxim_persoane THEN
            RAISE_APPLICATION_ERROR(-20010, 'Numarul de persoane este mai mare decat capacitatea camerei.');
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM rezervari r
        WHERE r.id_camera = v_id_camera
          AND r.stare <> 'ANULATA'
          AND r.id_rezervare <> p_rezervare.id_rezervare
          AND r.data_inceput < p_rezervare.data_sfarsit
          AND r.data_sfarsit > v_data_noua;
        
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Camera selectata nu este libera in perioada ramasa.');
        END IF;
        
        v_nopti_inainte := v_data_noua - p_rezervare.data_inceput;
        v_nopti_dupa := p_rezervare.data_sfarsit - v_data_noua;
        
        p_rezervare.id_camera := v_id_camera;
        
        p_rezervare.total_plata := v_nopti_inainte * v_pret_inainte + v_nopti_dupa * v_pret_dupa;
        
        aplica_reduceri(p_rezervare, p_reduceri);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Camera nu exista.');
    END schimba_camera;
    
    PROCEDURE select_rezervare (
        p_id_rezervare IN rezervari.id_rezervare%TYPE,
        p_rezervare OUT rezervare_rec
    )
    IS
    BEGIN
        IF p_id_rezervare IS NULL THEN
            RAISE_APPLICATION_ERROR(-20012, 'ID rezervare invalid.');
        END IF;
        
        SELECT id_rezervare, data_inceput, data_sfarsit, numar_persoane, data_rezervare, total_plata, stare, id_client, id_camera
        INTO p_rezervare.id_rezervare, p_rezervare.data_inceput, p_rezervare.data_sfarsit, p_rezervare.numar_persoane, p_rezervare.data_rezervare,
             p_rezervare.total_plata, p_rezervare.stare, p_rezervare.id_client, p_rezervare.id_camera
        FROM rezervari
        WHERE id_rezervare = p_id_rezervare;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20013, 'Rezervarea nu exista.');
    END select_rezervare;
    
    PROCEDURE insert_sau_update_rezervare (
        p_rezervare IN rezervare_rec
    )
    IS
        v_count NUMBER;
    BEGIN
        IF NOT este_valida(p_rezervare) THEN
            RAISE_APPLICATION_ERROR(c_err_rezervare_invalida, c_msg_rezervare_invalida);
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM rezervari
        WHERE id_rezervare = p_rezervare.id_rezervare;
        
        IF v_count = 0 THEN
            INSERT INTO rezervari(id_rezervare, data_inceput, data_sfarsit, numar_persoane, data_rezervare, total_plata, stare, id_client, id_camera)
            VALUES(p_rezervare.id_rezervare, p_rezervare.data_inceput, p_rezervare.data_sfarsit, p_rezervare.numar_persoane,
                   p_rezervare.data_rezervare, p_rezervare.total_plata, p_rezervare.stare, p_rezervare.id_client, p_rezervare.id_camera);
        ELSE
            UPDATE rezervari
            SET data_inceput = p_rezervare.data_inceput,
                data_sfarsit = p_rezervare.data_sfarsit,
                numar_persoane = p_rezervare.numar_persoane,
                data_rezervare = p_rezervare.data_rezervare,
                total_plata = p_rezervare.total_plata,
                stare = p_rezervare.stare,
                id_client = p_rezervare.id_client,
                id_camera = p_rezervare.id_camera
            WHERE id_rezervare = p_rezervare.id_rezervare;
        END IF;
    END insert_sau_update_rezervare;
    
    PROCEDURE afisare_rezervare (
        p_id_rezervare rezervari.id_rezervare%TYPE
    )
    IS
        v_rezervare rezervare_rec;
    BEGIN
        select_rezervare(p_id_rezervare, v_rezervare);
    
        DBMS_OUTPUT.PUT_LINE('ID rezervare: ' || v_rezervare.id_rezervare);
        DBMS_OUTPUT.PUT_LINE('Data inceput: ' || TO_CHAR(v_rezervare.data_inceput, 'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Data sfarsit: ' || TO_CHAR(v_rezervare.data_sfarsit, 'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Numar persoane: ' || v_rezervare.numar_persoane);
        DBMS_OUTPUT.PUT_LINE('Data rezervare: ' || TO_CHAR(v_rezervare.data_rezervare, 'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Stare: ' || v_rezervare.stare);
        DBMS_OUTPUT.PUT_LINE('ID client: ' || v_rezervare.id_client);
        DBMS_OUTPUT.PUT_LINE('ID camera: ' || v_rezervare.id_camera);
    END;
END pkg_rezervari;
/

-- creare rezervare noua + insert
DECLARE
    v_rezervare pkg_rezervari.rezervare_rec;
    v_reduceri pkg_rezervari.reduceri_varray := pkg_rezervari.reduceri_varray(10, 5);
BEGIN
    v_rezervare.id_rezervare := 60000008;
    v_rezervare.data_inceput := TRUNC(SYSDATE) - 1;
    v_rezervare.data_sfarsit := TRUNC(SYSDATE) + 8;
    v_rezervare.numar_persoane := 2;
    v_rezervare.data_rezervare := TRUNC(SYSDATE) - 10;
    v_rezervare.stare := 'CREATA';
    v_rezervare.id_client := 50001;
    v_rezervare.id_camera := 40005;
    
    pkg_rezervari.calculeaza_total_plata(v_rezervare);
    pkg_rezervari.aplica_reduceri(v_rezervare, v_reduceri);
    
    pkg_rezervari.insert_sau_update_rezervare(v_rezervare);
    
    pkg_rezervari.afisare_rezervare(60000008);
END;
/

-- modificare rezervare existenta + update
DECLARE
    v_rezervare pkg_rezervari.rezervare_rec;
BEGIN
    pkg_rezervari.select_rezervare(60000008, v_rezervare);
    
    v_rezervare.numar_persoane := 1;
    v_rezervare.stare := 'CONFIRMATA';
    
    pkg_rezervari.calculeaza_total_plata(v_rezervare);
    
    pkg_rezervari.insert_sau_update_rezervare(v_rezervare);
    
    pkg_rezervari.afisare_rezervare(60000008);
END;
/

-- schimbare camera
DECLARE
    v_rezervare pkg_rezervari.rezervare_rec;
    v_reduceri pkg_rezervari.reduceri_varray := pkg_rezervari.reduceri_varray(5, 2, 2);
BEGIN
    pkg_rezervari.select_rezervare(60000008, v_rezervare);
    
    pkg_rezervari.schimba_camera(v_rezervare, v_reduceri, 101);
    
    pkg_rezervari.insert_sau_update_rezervare(v_rezervare);
    
    pkg_rezervari.afisare_rezervare(60000008);
END;
/

-- schimbare in camera ocupata (eroare)
DECLARE
    v_rezervare pkg_rezervari.rezervare_rec;
BEGIN
    pkg_rezervari.select_rezervare(60000008, v_rezervare);
    
    pkg_rezervari.schimba_camera(v_rezervare, NULL, 102);
END;
/

-- rezervare invalida (eroare)
DECLARE
    v_rezervare pkg_rezervari.rezervare_rec;
BEGIN
    pkg_rezervari.select_rezervare(60000008, v_rezervare);
    v_rezervare.data_sfarsit := v_rezervare.data_inceput;
    
    pkg_rezervari.insert_sau_update_rezervare(v_rezervare);
END;
/

COMMIT;