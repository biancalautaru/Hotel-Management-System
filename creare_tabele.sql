DROP TABLE hoteluri CASCADE CONSTRAINTS;
DROP TABLE angajati CASCADE CONSTRAINTS;
DROP TABLE joburi CASCADE CONSTRAINTS;
DROP TABLE istoric_joburi CASCADE CONSTRAINTS;
DROP TABLE camere CASCADE CONSTRAINTS;
DROP TABLE clienti CASCADE CONSTRAINTS;
DROP TABLE rezervari CASCADE CONSTRAINTS;
DROP TABLE facturi CASCADE CONSTRAINTS;
DROP TABLE servicii CASCADE CONSTRAINTS;
DROP TABLE servicii_rezervari CASCADE CONSTRAINTS;

CREATE TABLE hoteluri (
    id_hotel NUMBER(5),
    denumire VARCHAR2(50) NOT NULL,
    stele NUMBER(1) NOT NULL,
    adresa VARCHAR2(100) NOT NULL,
    telefon VARCHAR2(20) NOT NULL,
    email VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_hoteluri PRIMARY KEY (id_hotel),
    CONSTRAINT chk_hoteluri_stele CHECK (stele BETWEEN 1 AND 5)
);

CREATE TABLE angajati (
    id_angajat NUMBER(5),
    nume VARCHAR2(30) NOT NULL,
    prenume VARCHAR2(30) NOT NULL,
    email VARCHAR2(50) NOT NULL,
    telefon VARCHAR2(20),
    salariu NUMBER(6),
    CONSTRAINT pk_angajati PRIMARY KEY (id_angajat),
    CONSTRAINT uq_angajati_email UNIQUE (email)
);

CREATE TABLE joburi (
    id_job NUMBER(5),
    denumire VARCHAR2(50) NOT NULL,
    salariu_minim NUMBER(6),
    salariu_maxim NUMBER(6),
    CONSTRAINT pk_joburi PRIMARY KEY (id_job),
    CONSTRAINT chk_joburi_salarii CHECK (salariu_maxim IS NULL OR salariu_minim IS NULL OR salariu_maxim >= salariu_minim)
);

CREATE TABLE istoric_joburi (
    data_inceput DATE,
    data_sfarsit DATE,
    id_angajat NUMBER(5),
    id_job NUMBER(5),
    id_hotel NUMBER(5),
    CONSTRAINT pk_istoric_joburi PRIMARY KEY (id_angajat, id_job, id_hotel, data_inceput),
    CONSTRAINT fk_ij_angajati FOREIGN KEY (id_angajat) REFERENCES angajati(id_angajat),
    CONSTRAINT fk_ij_joburi FOREIGN KEY (id_job) REFERENCES joburi(id_job),
    CONSTRAINT fk_ij_hoteluri FOREIGN KEY (id_hotel) REFERENCES hoteluri(id_hotel),
    CONSTRAINT chk_ij_perioada CHECK (data_sfarsit IS NULL OR data_inceput <= data_sfarsit)
);

CREATE TABLE camere (
    id_camera NUMBER(5),
    numar_camera NUMBER(4) NOT NULL,
    numar_maxim_persoane NUMBER(2) NOT NULL,
    pret_noapte NUMBER(6, 2) NOT NULL,
    id_hotel NUMBER(5) NOT NULL,
    CONSTRAINT pk_camere PRIMARY KEY (id_camera),
    CONSTRAINT fk_camere_hoteluri FOREIGN KEY (id_hotel) REFERENCES hoteluri(id_hotel),
    CONSTRAINT uq_camere_hotel_numar_camera UNIQUE (id_hotel, numar_camera),
    CONSTRAINT chk_camere_persoane CHECK (numar_maxim_persoane > 0),
    CONSTRAINT chk_camere_pret CHECK (pret_noapte > 0)
);

CREATE TABLE clienti (
    id_client NUMBER(5),
    nume VARCHAR2(30) NOT NULL,
    prenume VARCHAR2(30) NOT NULL,
    email VARCHAR2(50) NOT NULL,
    telefon VARCHAR2(20),
    adresa VARCHAR2(100),
    CONSTRAINT pk_clienti PRIMARY KEY (id_client),
    CONSTRAINT uq_clienti_email UNIQUE (email)
);

CREATE TABLE rezervari (
    id_rezervare NUMBER(8),
    data_inceput DATE NOT NULL,
    data_sfarsit DATE NOT NULL,
    numar_persoane NUMBER(2) NOT NULL,
    data_rezervare DATE NOT NULL,
    total_plata NUMBER(8, 2),
    stare VARCHAR2(10) DEFAULT 'CREATA' NOT NULL,
    id_client NUMBER(5) NOT NULL,
    id_camera NUMBER(5) NOT NULL,
    CONSTRAINT pk_rezervari PRIMARY KEY (id_rezervare),
    CONSTRAINT fk_rezervari_clienti FOREIGN KEY (id_client) REFERENCES clienti(id_client),
    CONSTRAINT fk_rezervari_camere FOREIGN KEY (id_camera) REFERENCES camere(id_camera),
    CONSTRAINT chk_rezervare_perioada CHECK (data_inceput < data_sfarsit),
    CONSTRAINT chk_rezervare_persoane CHECK (numar_persoane > 0),
    CONSTRAINT chk_rezervare_data CHECK (data_rezervare <= data_inceput),
    CONSTRAINT chk_rezervari_stare CHECK (UPPER(stare) IN ('CREATA', 'CONFIRMATA', 'ANULATA', 'FINALIZATA'))
);

CREATE TABLE facturi (
    id_factura NUMBER(8),
    suma NUMBER(8, 2) NOT NULL,
    data_emitere DATE NOT NULL,
    metoda_plata VARCHAR2(7),
    data_plata DATE,
    stare_plata VARCHAR2(9) DEFAULT 'NEPLATITA' NOT NULL,
    id_rezervare NUMBER(8) NOT NULL,
    CONSTRAINT pk_facturi PRIMARY KEY (id_factura),
    CONSTRAINT fk_facturi_rezervari FOREIGN KEY (id_rezervare) REFERENCES rezervari(id_rezervare),
    CONSTRAINT chk_factura_data CHECK (data_plata IS NULL OR data_plata >= data_emitere),
    CONSTRAINT chk_factura_metoda CHECK (UPPER(metoda_plata) IN ('CARD', 'NUMERAR', 'OP')),
    CONSTRAINT chk_factura_stare CHECK (UPPER(stare_plata) IN ('NEPLATITA', 'PARTIAL', 'PLATITA', 'ANULATA')),
    CONSTRAINT chk_factura_plata CHECK(UPPER(stare_plata) <> 'PLATITA' OR (UPPER(stare_plata) = 'PLATITA' AND data_plata IS NOT NULL))
);

CREATE TABLE servicii (
    id_serviciu NUMBER(5),
    denumire VARCHAR2(50) NOT NULL,
    descriere VARCHAR2(100),
    pret_standard NUMBER(8, 2) NOT NULL,
    CONSTRAINT pk_serviciu PRIMARY KEY (id_serviciu),
    CONSTRAINT uq_servicii_denumire UNIQUE (denumire),
    CONSTRAINT chk_servicii_pret CHECK (pret_standard >= 0)
);

CREATE TABLE servicii_rezervari (
    id_rezervare NUMBER(8),
    id_serviciu NUMBER(5),
    cantitate NUMBER(3) DEFAULT 1 NOT NULL,
    pret_aplicat NUMBER(8,2) NOT NULL,
    CONSTRAINT pk_servicii_rezervari PRIMARY KEY (id_rezervare, id_serviciu),
    CONSTRAINT fk_sr_rezervari FOREIGN KEY (id_rezervare) REFERENCES rezervari(id_rezervare),
    CONSTRAINT fk_sr_servicii FOREIGN KEY (id_serviciu) REFERENCES servicii(id_serviciu),
    CONSTRAINT chk_sr_cantitate CHECK (cantitate > 0),
    CONSTRAINT chk_sr_pret CHECK (pret_aplicat >=0)
);