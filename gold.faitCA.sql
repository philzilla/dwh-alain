CREATE TABLE DimArticle
(
    ArticleNo   NVARCHAR(20) PRIMARY KEY,   -- la clé : le code de l'article
    Designation NVARCHAR(100),
    Marque      NVARCHAR(50)
);

INSERT INTO DimArticle (ArticleNo, Designation, Marque)
SELECT [No_], [Description], [Nom Marque]
FROM   STG_NAV.NAV.STG_Item;

/* ------------------- */
select * from STG_NAV.NAV.STG_Item;
select * from DimArticle;
/* -------------------------------------------------------- */



CREATE TABLE DimClient
(
    ClientNo  NVARCHAR(20) PRIMARY KEY,
    NomClient NVARCHAR(100),
    Ville     NVARCHAR(50)
);

INSERT INTO DimClient (ClientNo, NomClient, Ville)
SELECT [No_], [Name], [City]
FROM   STG_NAV.NAV.STG_Customer;

/* ------------------- */
select * from DimClient;



/* -------------------------------------------------------- */
CREATE TABLE DimDate
(
    DateVente DATE PRIMARY KEY,
    Annee     SMALLINT,
    Mois      TINYINT,
    NomMois   NVARCHAR(20),
    Trimestre TINYINT
);

INSERT INTO DimDate (DateVente, Annee, Mois, NomMois, Trimestre)
SELECT DISTINCT
       CAST([Posting Date] AS DATE),
       YEAR([Posting Date]),
       MONTH([Posting Date]),
       DATENAME(MONTH, [Posting Date]),
       DATEPART(QUARTER, [Posting Date])
FROM   STG_NAV.NAV.STG_ValueEntry
WHERE  [Posting Date] IS NOT NULL;

/* ------------------- */
select * from DimDate;



/* -------------------------------------------------------- */
CREATE TABLE FaitCA
(
    -- les trois clés, qui pointent vers les dimensions
    DateVente   DATE,
    ClientNo    NVARCHAR(20),
    ArticleNo   NVARCHAR(20),
    -- les trois mesures, celles qu'on additionnera
    Quantite    DECIMAL(19,4),
    MontantCA   DECIMAL(19,4),
    MontantCout DECIMAL(19,4)
);

INSERT INTO FaitCA (DateVente, ClientNo, ArticleNo, Quantite, MontantCA, MontantCout)
SELECT
    CAST([Posting Date] AS DATE), -- type en date
    [Source No_],
    [Item No_],
    [Invoiced Quantity],
    [Sales Amount (Actual)],
    [Cost Amount (Actual)]
FROM   STG_NAV.NAV.STG_ValueEntry
WHERE  [Item Ledger Entry Type] = 1;   -- uniquement les ventes ?

/* -------------------------------------------------------- */
/* ------------------- */
select * from STG_NAV.NAV.STG_ValueEntry;
select * from FaitCA;
/* ------------------- */



-- le chiffre d'affaires total, et la marge
SELECT   SUM(MontantCA)                    AS ChiffreAffaires,
         SUM(MontantCA) - SUM(MontantCout) AS Marge
FROM     FaitCA;
/* -------------------------------------------------------- */


-- le chiffre d'affaires par mois
SELECT   d.Annee, d.NomMois, SUM(f.MontantCA) AS ChiffreAffaires
FROM     FaitCA f
JOIN     DimDate d ON d.DateVente = f.DateVente
GROUP BY d.Annee, d.Mois, d.NomMois
ORDER BY d.Annee, d.Mois;


-- le chiffre d'affaires par marque
SELECT   a.Marque, SUM(f.MontantCA) AS ChiffreAffaires
FROM     FaitCA f
JOIN     DimArticle a ON a.ArticleNo = f.ArticleNo
GROUP BY a.Marque
ORDER BY ChiffreAffaires DESC;


-- le chiffre d'affaires par mois et par ville de client
SELECT   d.NomMois, c.Ville, SUM(f.MontantCA) AS ChiffreAffaires
FROM     FaitCA f
JOIN     DimDate   d ON d.DateVente = f.DateVente
JOIN     DimClient c ON c.ClientNo  = f.ClientNo
GROUP BY d.Annee, d.Mois, d.NomMois, c.Ville
ORDER BY d.Mois, ChiffreAffaires DESC;


-- le chiffre d'affaires par  client
SELECT   ClientNo, SUM(MontantCA) AS ChiffreAffaires
FROM     FaitCA
GROUP BY ClientNo
ORDER BY ChiffreAffaires DESC;



-- contenu de la source
SELECT  COUNT(*)                       AS NbLignes,
        SUM([Sales Amount (Actual)])   AS CA_Total,
        MIN([Entry No_])               AS PremiereLigne,
        MAX([Entry No_])               AS DerniereLigne
FROM    STG_NAV.NAV.STG_ValueEntry;
