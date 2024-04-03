CREATE TABLE Pobocka
(
    Cislo_pobocky    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Nazev            VARCHAR2(255) NOT NULL,
    Adresa           VARCHAR2(255) NOT NULL,
    Zodpovedna_osoba VARCHAR2(255)

);

CREATE TABLE Lek
(
    ID_leku  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Nazev    VARCHAR2(255) NOT NULL,
    Cena     NUMBER(10, 2) NOT NULL,
    Typ_leku NUMBER(1)     NOT NULL
);


CREATE TABLE Objednavka
(
    ID_objednavky      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Jmeno_zakaznika    VARCHAR2(255) NOT NULL,
    Prijmeni_zakaznika VARCHAR2(255) NOT NULL,
    Datum              DATE,
    ID_leku            NUMBER        NOT NULL,
    Cislo_pobocky      NUMBER        NOT NULL,
    CONSTRAINT Objednavka_Lek FOREIGN KEY (ID_leku) REFERENCES Lek (ID_leku),
    CONSTRAINT Objednavka_Pobocka FOREIGN KEY (Cislo_pobocky) REFERENCES Pobocka (Cislo_pobocky)
);



CREATE TABLE Pojistovna
(
    Cislo_pojistovny NUMBER PRIMARY KEY,
    Nazev            VARCHAR2(255) NOT NULL,
    CHECK ( LENGTH(Cislo_pojistovny) = 3)
);

CREATE TABLE Vydej
(
    ID_vydeje     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Mnozstvi      NUMBER NOT NULL,
    Cislo_pobocky NUMBER NOT NULL,
    ID_leku       NUMBER NOT NULL,
    CHECK ( Mnozstvi > 0 ),
    CONSTRAINT Vydej_lek FOREIGN KEY (ID_leku) REFERENCES Lek (ID_leku),
    CONSTRAINT Vydej_Pobocka FOREIGN KEY (Cislo_pobocky) REFERENCES Pobocka (Cislo_pobocky)
);

CREATE TABLE VydejPredpis
(
    ID_vydeje   NUMBER PRIMARY KEY,
    Rodne_cislo NUMBER(10),
    CHECK ( LENGTH(Rodne_cislo) = 10 ),
    FOREIGN KEY (ID_vydeje) REFERENCES Vydej (ID_vydeje)
);

CREATE TABLE Uskladnen
(
    PRIMARY KEY (Cislo_pobocky, ID_leku),
    Cislo_pobocky NUMBER NOT NULL,
    ID_leku       NUMBER NOT NULL,
    Mnozstvi      NUMBER NOT NULL,
    CHECK ( Mnozstvi >= 0 ),
    CONSTRAINT Uskladnen_Lek FOREIGN KEY (ID_leku) REFERENCES Lek (ID_leku),
    CONSTRAINT Uskladnen_Pobocka FOREIGN KEY (Cislo_pobocky) REFERENCES Pobocka (Cislo_pobocky)

);

CREATE TABLE Hradi
(
    PRIMARY KEY (Ciclo_pojistovny, ID_leku),
    Ciclo_pojistovny NUMBER NOT NULL,
    ID_leku          NUMBER NOT NULL,
    Castka           NUMBER NOT NULL,
    CHECK ( Castka >= 0),
    CONSTRAINT Hradi_Pojistovna FOREIGN KEY (Ciclo_pojistovny) REFERENCES Pojistovna (Cislo_pojistovny),
    CONSTRAINT Hradi_Lek FOREIGN KEY (ID_leku) REFERENCES Lek (ID_leku)

);

CREATE TABLE Objednan
(
    PRIMARY KEY (ID_objednavky, ID_leku),
    ID_objednavky NUMBER NOT NULL,
    ID_leku       NUMBER NOT NULL,
    Mnozstvi      NUMBER NOT NULL,
    CHECK ( Mnozstvi > 0 ),
    CONSTRAINT Objednano_Objednavka FOREIGN KEY (ID_objednavky) REFERENCES Objednavka (ID_objednavky),
    CONSTRAINT Objednano_Lek FOREIGN KEY (ID_leku) REFERENCES Lek (ID_leku)
);


-- Insert data into Pobocka table
INSERT INTO Pobocka (Nazev, Adresa, Zodpovedna_osoba)
VALUES ('Lékárna Na Růži', 'Hlavní 12, Praha 1', 'Kateřina Novotná');
INSERT INTO Pobocka (Nazev, Adresa, Zodpovedna_osoba)
VALUES ('Lékárna U Zvonu', 'Václavské náměstí 5, Brno', 'Martin Novák');

-- Insert data into Lek table
INSERT INTO Lek (Nazev, Cena, Typ_leku)
VALUES ('Paralen', 25.90, 1);
INSERT INTO Lek (Nazev, Cena, Typ_leku)
VALUES ('Ibalgin', 18.75, 2);

-- Insert data into Objednavka table
INSERT INTO Objednavka (Jmeno_zakaznika, Prijmeni_zakaznika, Datum, ID_leku, Cislo_pobocky)
VALUES ('Jan', 'Novák', TO_DATE('2024-03-20', 'YYYY-MM-DD'), 1, 1);
INSERT INTO Objednavka (Jmeno_zakaznika, Prijmeni_zakaznika, Datum, ID_leku, Cislo_pobocky)
VALUES ('Petra', 'Kovářová', TO_DATE('2024-03-21', 'YYYY-MM-DD'), 2, 2);

-- Insert data into Pojistovna table
INSERT INTO Pojistovna (Cislo_pojistovny, Nazev)
VALUES (123, 'Zdravotní Pojišťovna České republiky');
INSERT INTO Pojistovna (Cislo_pojistovny, Nazev)
VALUES (456, 'Všeobecná zdravotní pojišťovna');

-- Insert data into Vydej table
INSERT INTO Vydej (Mnozstvi, Rodne_cislo, Cislo_pobocky, ID_leku)
VALUES (20, 8903241234, 1, 1);
INSERT INTO Vydej (Mnozstvi, Rodne_cislo, Cislo_pobocky, ID_leku)
VALUES (15, 7856239876, 2, 2);

-- Insert data into Uskladnen table
INSERT INTO Uskladnen (Cislo_pobocky, ID_leku, Mnozstvi)
VALUES (1, 1, 200);
INSERT INTO Uskladnen (Cislo_pobocky, ID_leku, Mnozstvi)
VALUES (2, 2, 150);

-- Insert data into Hradi table
INSERT INTO Hradi (Ciclo_pojistovny, ID_leku, Castka)
VALUES (123, 1, 1500);
INSERT INTO Hradi (Ciclo_pojistovny, ID_leku, Castka)
VALUES (456, 2, 2000);

-- Insert data into Objednan table
INSERT INTO Objednan (ID_objednavky, ID_leku, Mnozstvi)
VALUES (1, 1, 30);
INSERT INTO Objednan (ID_objednavky, ID_leku, Mnozstvi)
VALUES (2, 2, 25);


/*
DROP TABLE Pobocka;
DROP TABLE Lek;
DROP TABLE Objednavka;
DROP TABLE Pojistovna;
DROP TABLE Vydej;
DROP TABLE Uskladnen;
DROP TABLE Hradi;
DROP TABLE Objednan;
*/