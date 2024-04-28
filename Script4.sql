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
    PRIMARY KEY (Cislo_pojistovny, ID_leku),
    Cislo_pojistovny NUMBER NOT NULL,
    ID_leku          NUMBER NOT NULL,
    Castka           NUMBER NOT NULL,
    CHECK ( Castka >= 0),
    CONSTRAINT Hradi_Pojistovna FOREIGN KEY (Cislo_pojistovny) REFERENCES Pojistovna (Cislo_pojistovny),
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

-- Definice triggeru --
-- Trigger 1, ktery zajisti, ze neni vydano vetsi mnozstvi leku, nez je ho na sklade --
CREATE OR REPLACE TRIGGER KontrolaMnozstviNaSklade
    BEFORE INSERT
    ON Vydej
    FOR EACH ROW
DECLARE
    mnozstvi_na_sklade NUMBER;
BEGIN
    SELECT Mnozstvi
    INTO mnozstvi_na_sklade
    FROM Uskladnen
    WHERE Cislo_pobocky = :NEW.Cislo_pobocky
      AND ID_leku = :NEW.ID_leku;
    IF :NEW.Mnozstvi > mnozstvi_na_sklade THEN
        raise_application_error(-20001, 'Daného léku není dostatečné množství na skladě!');
    END IF;
END;
;

-- Trigger 2, ktery aktualizuje mnozstvi na sklade po vydani daneho leku --
CREATE OR REPLACE TRIGGER AktualizaceMnozstvi
    AFTER INSERT
    ON Vydej -- Po INSERTU zaznamu do tabulky Vydej --
    FOR EACH ROW
BEGIN
    UPDATE Uskladnen -- Aktualizuj zaznam v tabulce Uskladnen --
    SET Mnozstvi = Mnozstvi - :NEW.Mnozstvi -- Sniz mnozstvi o vydane a nastav jej za aktualni --
    WHERE Cislo_pobocky = :NEW.Cislo_pobocky
      AND ID_LEKU = :NEW.ID_Leku;
END;
;

-- Trigger 3, ktery kontroluje, zda pojistovna hradi castku nepresahujici cenu leku --
CREATE OR REPLACE TRIGGER KontrolaCenyHrazeni
    AFTER INSERT
    ON Hradi -- Po vlozeni zaznamu do tabulky Hradi --
    FOR EACH ROW
DECLARE
    cena_leku NUMBER;
BEGIN
    SELECT Cena INTO cena_leku FROM Lek WHERE ID_leku = :NEW.ID_leku; -- Zvol cenu leku z jiz existujiciho zaznamu v tabulce Lek --
    IF :NEW.Castka > cena_leku THEN
        RAISE_APPLICATION_ERROR(-20002, 'Pojišťovna nemůže hradit částku vyšší, než je částka léku!');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Daný lék, neexistuje v záznamech o lécích!');
END;

-- Definice procedur --
-- Procedura 1, ktera vraci informace o celkove trzbe skrze vystupni parametr --
CREATE OR REPLACE PROCEDURE UtrzenaTrzba(p_Trzba OUT NUMBER) -- Vytvoreni procedury s parametrem p_Trzba, ktery je vystupni, vracen volajicimu --
AS
    CURSOR cursor_prodeje IS -- Deklarace kurzoru a promennych --
        SELECT v.Mnozstvi, l.Cena -- cursor_prodeje ziskava mnozstvi kazdeho leku a jeho cenu --
        FROM Vydej v
                 JOIN Lek l ON v.ID_leku = l.ID_leku;
    v_mnozstvi Vydej.Mnozstvi%TYPE;
    v_cena     Lek.Cena%TYPE;
BEGIN
    p_Trzba := 0; -- Inicializace vystupniho parametru --
    OPEN cursor_prodeje;
    LOOP
        -- Dokud jsou data dostupna z kurzoru, bude se vyklus opakovat --
        FETCH cursor_prodeje INTO v_mnozstvi, v_cena; -- Nacteni aktualnich dat z kurzoru do promennych v_mnozstvi, v_cena --
        EXIT WHEN cursor_prodeje%NOTFOUND; -- ukonceni cyklu, pokud kurzor nema zadne dalsi radky --
        p_Trzba := p_Trzba + (v_mnozstvi * v_cena); -- aktualizace celkove trzby --
    END LOOP;
    CLOSE cursor_prodeje; -- uzavreni kurzoru --

EXCEPTION -- zachyceni vyjimek --
    WHEN NO_DATA_FOUND THEN -- pokud dotaz nevrati zadna data --
        p_Trzba := 0;
        DBMS_OUTPUT.PUT_LINE('Žádná data nebyla nalezena, celková tržba je 0,-');
    WHEN OTHERS THEN -- ostatni vyjimky --
        DBMS_OUTPUT.PUT_LINE('Nastala neočekávaná chyba: ' || SQLERRM);
        IF cursor_prodeje%ISOPEN THEN -- pokud je kurzor otevren, uzavreme jej --
            CLOSE cursor_prodeje;
        END IF;
END;
;

-- Procedura 2, ktera aktualizuje mnozstvi na sklade pro vybrany lek --
CREATE OR REPLACE PROCEDURE AktualizaceSkladu(p_cislo_pobocky NUMBER, p_ID_leku NUMBER, p_nove_mnozstvi NUMBER)
AS
    v_stare_mnozstvi Uskladnen.Mnozstvi%TYPE;
BEGIN
    SELECT Mnozstvi
    INTO v_stare_mnozstvi
    FROM Uskladnen
    WHERE ID_leku = p_ID_leku
      AND Cislo_pobocky = p_cislo_pobocky FOR UPDATE;
    -- vrati stare mnozstvi do promenne v_stare_mnozstvi --
    IF p_nove_mnozstvi > 0 THEN -- nesmi byt 0, protoze se predpoklada, ze tato procedura se pouziva pri prijeti zasilky od dodavatele --
        UPDATE Uskladnen
        SET Mnozstvi = Mnozstvi + p_nove_mnozstvi -- aktualizuje mnozstvi, Mnozstvi += p_nove_mnozstvi --
        WHERE ID_leku = p_ID_leku
          AND Cislo_pobocky = p_cislo_pobocky;
    ELSE
        RAISE_APPLICATION_ERROR(-20005, 'Nové množství nesmí být záporné nebo 0!'); -- Pokud je nove mnozstvi <= 0 --
    END IF;
EXCEPTION -- Osetreni chyb --
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Daný lék, neexistuje v záznamech o lécích!');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nastala neočekávaná chyba ' || SQLERRM);
END;
;


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
INSERT INTO Objednavka (Jmeno_zakaznika, Prijmeni_zakaznika, Datum, ID_leku, Cislo_pobocky)
VALUES ('Petra', 'Kovářová', TO_DATE('2024-03-05', 'YYYY-MM-DD'), 1, 1);

-- Insert data into Pojistovna table
INSERT INTO Pojistovna (Cislo_pojistovny, Nazev)
VALUES (123, 'Zdravotní Pojišťovna České republiky');
INSERT INTO Pojistovna (Cislo_pojistovny, Nazev)
VALUES (456, 'Všeobecná zdravotní pojišťovna');

-- Insert data into Uskladnen table
INSERT INTO Uskladnen (Cislo_pobocky, ID_leku, Mnozstvi)
VALUES (1, 1, 200);
INSERT INTO Uskladnen (Cislo_pobocky, ID_leku, Mnozstvi)
VALUES (2, 2, 150);

-- Insert data into Vydej table
INSERT INTO Vydej (Mnozstvi, Cislo_pobocky, ID_leku)
VALUES (20, 1, 1);
INSERT INTO Vydej (Mnozstvi, Cislo_pobocky, ID_leku)
VALUES (15, 2, 2);


-- Insert data into Hradi table
INSERT INTO Hradi (Cislo_pojistovny, ID_leku, Castka)
VALUES (123, 1, 1);
INSERT INTO Hradi (Cislo_pojistovny, ID_leku, Castka)
VALUES (456, 2, 1);

-- Insert data into Objednan table
INSERT INTO Objednan (ID_objednavky, ID_leku, Mnozstvi)
VALUES (1, 1, 30);
INSERT INTO Objednan (ID_objednavky, ID_leku, Mnozstvi)
VALUES (2, 2, 25);


-- Pouziti procedury 1 --
DECLARE
    vysledek_procedury_1 NUMBER; -- deklarace promenne --
BEGIN
    UtrzenaTrzba(vysledek_procedury_1); -- zavola proceduru a vrati vysledek skrze parametr --
    DBMS_OUTPUT.PUT_LINE('Celková tržba je: ' || vysledek_procedury_1); -- vypise celkovou trzbu --
END;
;


-- Pouziti procedury 2 --
BEGIN
    AktualizaceSkladu(p_cislo_pobocky => 1, p_ID_leku => 1, p_nove_mnozstvi => 100);
    -- zavola proceduru pro aktualizaci mnozstvi na sklade --
    -- parametry jsou specificke cisla, tedy pro lek na pobocce v tabulce Uskladnen s Cislo_pobocky = 1 a pro ID_leku = 1, zvysi mnozstvi na sklade o 100 --
END;
;


-- 1. Dotaz využívající spojení dvou tabulek - získání informací o objednávkách a názvu léku
SELECT O.Jmeno_zakaznika, O.Prijmeni_zakaznika, L.Nazev AS Nazev_leku
FROM Objednavka O
         JOIN Lek L ON O.ID_leku = L.ID_leku;

-- 2. Dotaz využívající spojení tří tabulek - získání informací o vydaných léčivech, názvu léku a názvu pobočky
SELECT V.Mnozstvi, L.Nazev AS Nazev_leku, P.Nazev AS Nazev_pobocky
FROM Vydej V
         JOIN Lek L ON V.ID_leku = L.ID_leku
         JOIN Pobocka P ON V.Cislo_pobocky = P.Cislo_pobocky;

-- 3. Dotaz s klauzulí GROUP BY a agregační funkcí - získání celkového množství vydaného léku
SELECT ID_leku, SUM(Mnozstvi) AS Celkove_mnozstvi
FROM Vydej
GROUP BY ID_leku;

-- 4. Dotaz s klauzulí GROUP BY a agregační funkcí - získání počtu objednávek na každou pobočku
SELECT Cislo_pobocky, COUNT(*) AS Pocet_objednavek
FROM Objednavka
GROUP BY Cislo_pobocky;

-- 5. Dotaz obsahující predikát EXISTS - zjištění, zda existuje objednávka pro konkrétní lék
SELECT ID_leku, Nazev
FROM Lek L
WHERE EXISTS (SELECT 1
              FROM Objednavka O
              WHERE O.ID_leku = L.ID_leku);

-- 6. Dotaz s predikátem IN s vnořeným selectem - získání informací o objednávkách pro vybrané léky
SELECT *
FROM Objednavka
WHERE ID_leku IN (SELECT ID_leku
                  FROM Lek
                  WHERE Cena > 20);

-- 7. Dotaz využívající spojení dvou tabulek - získání informací o léku, který má nejvyšší cenu
SELECT L.Nazev, L.Cena
FROM Lek L
         JOIN (SELECT MAX(Cena) AS Max_cena
               FROM Lek) MaxCena ON L.Cena = MaxCena.Max_cena;



-- Pristupova prava pro clena tymu
-- Pro clena tymu xmacha86 --
GRANT ALL ON Pobocka TO xmacha86;
GRANT ALL ON Lek TO xmacha86;
GRANT ALL ON Objednavka TO xmacha86;
GRANT ALL ON Pojistovna TO xmacha86;
GRANT ALL ON Vydej TO xmacha86;
GRANT ALL ON VydejPredpis TO xmacha86;
GRANT ALL ON Uskladnen TO xmacha86;
GRANT ALL ON Hradi TO xmacha86;
GRANT ALL ON Objednan TO xmacha86;

-- Pro clena tymu xkanad00 --
GRANT ALL ON Pobocka TO xkanad00;
GRANT ALL ON Lek TO xkanad00;
GRANT ALL ON Objednavka TO xkanad00;
GRANT ALL ON Pojistovna TO xkanad00;
GRANT ALL ON Vydej TO xkanad00;
GRANT ALL ON VydejPredpis TO xkanad00;
GRANT ALL ON Uskladnen TO xkanad00;
GRANT ALL ON Hradi TO xkanad00;
GRANT ALL ON Objednan TO xkanad00;


-- Tvorba pohledu --
-- Jednoduchy pohled, ktery umoznuje ziskat prehled o jendotlivych objednavkach provedenych na danych pobockach --
CREATE VIEW Objednavky AS
SELECT p.Nazev    AS Nazev_Pobocky,
       l.Nazev    AS Nazev_Leku,
       o.Mnozstvi AS ObjednaneMnozstvi
FROM Pobocka p
         JOIN
     Objednavka ob ON p.Cislo_pobocky = ob.Cislo_pobocky
         JOIN
     Objednan o ON ob.ID_objednavky = o.ID_objednavky
         JOIN
     Lek l ON o.ID_leku = l.ID_leku;

-- Materializovany pohled, ktery uklada data reprezentujici vypisy o prodejich (vhodne napriklad pro mesicni vypisy)  --
CREATE MATERIALIZED VIEW ProdejniZprava
            BUILD IMMEDIATE
    REFRESH COMPLETE ON DEMAND
AS
SELECT l.Nazev                  AS Nazev_Leku,
       SUM(v.Mnozstvi)          AS Celkove_Prodano,
       SUM(v.Mnozstvi * l.Cena) AS Trzba
FROM Lek l
         JOIN
     Vydej v ON l.ID_leku = v.ID_leku
GROUP BY l.Nazev;


-- Demonstrace pohledu pomoci SELECT dotazu --
-- Jednoduchy VIEW --
-- Zobrazi vsechna data o objednavkach (pobocky, leky, mnozstvi)
SELECT *
FROM Objednavky;
-- ORDER BY DESC/ASC (moznost zobrazeni stejnych dat serazenych dle poctu prodanych leku SESTUNE/VZESTUPNE) --

-- Dotaz pro zjisteni celkoveho mnozstvi objednaneho leku --
SELECT Nazev_Leku, SUM(ObjednaneMnozstvi) AS ObjednaneMnozstvi
FROM Objednavky
GROUP BY Nazev_Leku;

-- Informace o prodanych lecich na dane pobocce --
SELECT Nazev_Leku, SUM(ObjednaneMnozstvi) AS ObjednaneMnozstvi
FROM Objednavky
WHERE Nazev_Pobocky = 'Lékárna Na Růži'
group by Nazev_Leku;

-- Materialized view --
-- Zobrazi vsechny informace o prodanych lecich --
SELECT *
FROM ProdejniZprava;
-- ORDER BY Celkova_Trzba DESC/ASC (lze jeste seradit dle celkove trzby daneho leku SESTUPNE/VZESTUPNE) --

-- Informace o prodanych lecich, ktere byly prodany alespon 100 --
SELECT *
FROM ProdejniZprava
WHERE Celkove_Prodano > 100;

-- Informace o celkove trzbe (soucet jednotlivych trzeb leku) --
SELECT SUM(Trzba) AS Celkova_Trzba
FROM ProdejniZprava;

WITH CelkovoDorucene AS (SELECT ID_leku,
                                SUM(Mnozstvi) AS DoruceneMnozstvi
                         FROM Vydej
                         GROUP BY ID_leku)
SELECT l.Nazev             AS Lek,
       cd.DoruceneMnozstvi AS Vydané_množství,
       CASE
           WHEN cd.DoruceneMnozstvi >= 100 THEN 'Nad 100'
           ELSE 'Pod 100'
           END             AS Status_Prodeje
FROM Lek l
         JOIN
     CelkovoDorucene cd ON l.ID_leku = cd.ID_leku;


-- Základný dotaz
EXPLAIN PLAN FOR
SELECT o.Jmeno_zakaznika,
       o.Prijmeni_zakaznika,
       COUNT(*) AS Pocet_objednavek,
       SUM(l.Cena) AS Celkova_cena
FROM Objednavka o
         JOIN Lek l ON o.ID_leku = l.ID_leku
GROUP BY o.Jmeno_zakaznika, o.Prijmeni_zakaznika;

SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);


-- Optimalizace dotazu --
CREATE INDEX Jmeno_Prijmeni_Index ON Objednavka (Jmeno_zakaznika, Prijmeni_zakaznika);

-- Optimalizovany dotaz --
EXPLAIN PLAN FOR
SELECT o.Jmeno_zakaznika,
       o.Prijmeni_zakaznika,
       COUNT(*) AS Pocet_objednavek,
       SUM(l.Cena) AS Celkova_cena
FROM Objednavka o
         JOIN Lek l ON o.ID_leku = l.ID_leku
GROUP BY o.Jmeno_zakaznika, o.Prijmeni_zakaznika;

SELECT *
FROM TABLE (DBMS_XPLAN.DISPLAY);

DROP INDEX Jmeno_Prijmeni_Index;





/*
DROP TABLE Pobocka;
DROP TABLE Lek;
DROP TABLE Objednavka;
DROP TABLE Pojistovna;
DROP TABLE Vydej;
DROP TABLE Uskladnen;
DROP TABLE Hradi;
DROP TABLE Objednan;
DROP VIEW Objednavky;
DROP MATERIALIZED VIEW ProdejniZprava;
*/