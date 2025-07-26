-- STRUKTURA DATABÁZE
-- 1) JAKÉ JSOU PRIMÁRNÍ KLÍČE? - CLIENT: client_id, CARD: card_id, DISP: disp_id, ACOUNT: accout_id, DISTRICT: district_id, TRANS: trans_id, ORDER: order_id, LOAN: loan_id
-- 2) 1:N

-- HYSTORIE POSKYTNUTÝCH ÚVĚRŮ
                -- Napište dotaz, který připraví souhrn poskytnutých půjček v následujících dimenzích:
                    -- rok, čtvrtletí, měsíc,
                    -- rok, čtvrtletí,
                    -- rok
                    -- totální.
-- Jako výsledek přehledu zobrazte následující informace:
                    -- celková výše úvěrů,
                    -- průměrná výše úvěru,
                    -- celkový počet poskytnutých půjček.

select year(date) as rok,
       quarter(date) as kvartal,
       month(date) as mesic,
        sum(amount) as celkova_vyse_uveru,
        round(avg(amount),2) as prumerna_vyse_uveru,
        count(amount) as pocet_uveru
from loan
group by rok, kvartal, mesic
order by rok, kvartal, mesic;

-- STAV UVERU
                -- 682 posyktnutych pujcek, 606 splaceno, 76 nesplaceno

select status,
    count(status) as pocet_uveru
from loan
group by status
order by status; -- z vysledne tabulky muzeme zjistit, že statusy A a C označují splacené půjčky a B a D nesplacené

-- ANALÝZA ÚČETNICTVÍ
                 -- pouze splacené uvery
                 -- počet poskytnutých úvěrů (klesá),
                    -- výše poskytnutých úvěrů (klesající),
                     -- průměrná výše úvěru


with CTE_splacene_platby as
         (select *
          from loan
          where status in ('A', 'C')
          )

select account_id,
    sum(amount) as celkova_vyse_uveru,
    dense_rank() over (order by (sum(amount))desc) as poradi_sumy,
    dense_rank() over (order by (count(amount))desc) as poradi_poctu,
    count(amount) as pocet_uveru,
    round(avg(amount),2) as prumerna_vyse_uveru
from CTE_splacene_platby
group by account_id;

-- PLNĚ SPLACENÉ ÚVĚRY
    -- ZŮSTAtEK SPLacenych ÚVĚRŮ. ROZDĚLENÝ PODLE POHLAVÍ KLIENTA  + KONTROLA SPRÁVNOSTI

WITH CTE_splacene_platby AS (
    SELECT *
    FROM loan
    WHERE status IN ('A', 'C')
),
CTE_DISP_OWNER AS (
    SELECT *
    FROM disp
    WHERE type IN ('OWNER')
)

SELECT c.gender,
       sum(CTE_splacene_platby.amount)
FROM CTE_splacene_platby
JOIN CTE_DISP_OWNER ON CTE_DISP_OWNER.account_id = CTE_splacene_platby.account_id
JOIN client c on  c.client_id = CTE_DISP_OWNER.client_id
GROUP BY c.gender ;


-- kontrola
WITH CTE_splacene_platby AS (
    SELECT *
    FROM loan
    WHERE status IN ('A', 'C'))
select sum(CTE_splacene_platby.amount)
from CTE_splacene_platby;

-- ANALÝZA KLIENTA PRVNÍ ČÁST
 -- Úpravou dotazů z cvičení na splácené půjčky odpovězte na následující otázky:
 -- Kdo má více splácených půjček – ženy nebo muži?
-- Jaký je průměrný věk dlužníka NA pohlaví?

-- kdo má více pujcek muzi nebo zeny?

WITH CTE_splacene_platby AS (
    SELECT *
    FROM loan
    WHERE status IN ('A', 'C')
),
CTE_DISP_OWNER AS (
    SELECT *
    FROM disp
    WHERE type IN ('OWNER')
)

SELECT c.gender,
       count(CTE_splacene_platby.amount)
FROM CTE_splacene_platby
JOIN CTE_DISP_OWNER ON CTE_DISP_OWNER.account_id = CTE_splacene_platby.account_id
JOIN client c on  c.client_id = CTE_DISP_OWNER.client_id
GROUP BY c.gender ; -- vice splacenych pujcek maji zeny

-- prumerny vek dle pohlavi

WITH CTE_splacene_platby AS
         (SELECT *
          FROM loan
          WHERE status IN ('A', 'C')),
     CTE_DISP_OWNER AS (SELECT *
                        FROM disp
                        WHERE type IN ('OWNER'))
SELECT gender,
    round(avg(2025 - year(birth_date)),2) as prumerny_věk_klienta
  FROM CTE_splacene_platby l
  JOIN CTE_DISP_OWNER d ON d.account_id = l.account_id
  JOIN client c ON c.client_id = d.client_id
group by gender; -- vetsi prumerny vek u splacenych pujcek maji muzi - 67,87



-- ANALÝZA KLIENTA ČÁST 2

-- která oblast má nejvíce klientů,
-- v jaké oblasti bylo splaceno nejvíce úvěrů,
-- v jaké oblasti byla splacena nejvyšší částka úvěrů,

SELECT dis.district_id as oblast,
       dis.a2 as nazev_oblasti,
        (count(a.district_id)) as pocet
from account a
join disp d on a.account_id = d.account_id
join district dis on a.district_id = dis.district_id
where type = 'OWNER'
group by oblast
order by pocet desc; -- nejvíc klientů má Praha

-- v jaké oblasti bylo splaceno nejvíce úvěrů,

select d.district_id as oblast,
       d.a2 as nazev_oblasti,
        (count(loan_id)) as pocet_uveru
from loan l
join account a on l.account_id = a.account_id
join district d on a.district_id = d.district_id
group by d.district_id, d.a2
order by pocet_uveru desc; -- nejvíce uveru ma Praha

-- v jaké oblasti byla splacena nejvyšší částka úvěrů,

select d.district_id as oblast,
       d.a2 as nazev_oblasti,
        sum(amount) as castka_uveru
from loan l
join account a on l.account_id = a.account_id
join district d on a.district_id = d.district_id
group by d.district_id, d.a2
order by castka_uveru desc; -- nejvyssí častka byla splacena v Praze

-- ANALÝZA KLIENTA ČÁST 3

-- Použijte dotaz vytvořený v předchozí úloze a upravte jej tak, abyste určili procento každého okresu z celkové částky poskytnutých půjček.

select  d.district_id as oblast,
        d.a2 as nazev_oblasti,
        sum(l.amount) as castka_uveru,
        round(sum(l.amount) / (select SUM(amount) from loan) * 100, 2) as procento_z_celku
from loan l
join account a ON l.account_id = a.account_id
join district d ON a.district_id = d.district_id
group by d.district_id, d.a2;

-- VÝBĚR ČÁST 1

 --  vyberte databázi klientu kteri splnuji:


-- jejich zůstatek na účtu je vyšší než 1000

with CTE_splacene_platby as
         (
            select *
            from loan
            where status in ('A', 'C')
        ),
        CTE_DISP_OWNER as
        (
            select *
            from disp
            where type in ('OWNER')
        )

select l.account_id
from CTE_splacene_platby l
join CTE_DISP_OWNER d ON d.account_id = l.account_id
join client c on  c.client_id = d.client_id
group by account_id
having sum(l.amount - l.payments) > 1000;

-- mají více než pět půjček,

with CTE_splacene_platby as
         (
            select *
            from loan
            where status in ('A', 'C')
        ),
        CTE_DISP_OWNER as
        (
            select *
            from disp
            where type in ('OWNER')
        )

 select l.account_id
from CTE_splacene_platby l
join CTE_DISP_OWNER d ON d.account_id = l.account_id
join client c on  c.client_id = d.client_id
group by account_id
having count(loan_id) > 5; -- žádní nemají více než 5 půjček


-- Narodili se po roce 1990.

with CTE_splacene_platby as
         (
            select *
            from loan
            where status in ('A', 'C')
        ),
        CTE_DISP_OWNER as
        (
            select *
            from disp
            where type in ('OWNER')
        )

select l.account_id
from CTE_splacene_platby l
join CTE_DISP_OWNER d ON d.account_id = l.account_id
join client c on  c.client_id = d.client_id
where (c.birth_date) >1990
group by account_id;

-- VÝBĚR ČÁST 2

-- již v předchozím příkladu jsem vyřešila, že se jedná o podmínku s výběrem klientů, kteří mají více než 5 půjček


-- KARTY S KONČÍCÍ PLATNOSTÍ

-- Napište postup pro AKTUALIZACI vámi vytvořené tabulky (můžete ji nazvat např. cards_at_expiration ) obsahující následující sloupce:
-- ID klienta, ID karty, datum expirace předpokládejte, že karta může být aktivní po dobu 3 let od data vydání), adresa klienta (stačí sloupec).A3


delimiter //
create procedure cards_at_expiration (in in_datum_expirace date)
    begin
        select d.client_id,
                card_id,
                issued as datum_vydani,
                date_add(issued, interval 3 year) as datum_expirace,
                A3
        from card c
        join disp d on c.disp_id = d.disp_id
        join account a on d.account_id = a.account_id
        join client cl on d.client_id = cl.client_id
        join district dis on cl.district_id = dis.district_id
        where date_add(issued, interval 3 year) < in_datum_expirace;
end; //


call cards_at_expiration ('2001-7-1');

-- nevim zda jsem pochopila zadani, ale kod vraci po zadani data všechny již expirované karty
