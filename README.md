# IDS
Řešení projektu do předmětu databázové systémy

# Osobní hodnocení předmětu
Dle mého je předmět kvalitní a hodně povedený. Přednášky jsou trošku nudnější, ale koho to vyloženě zajímá, dobře pro něj.
Asi jeden z nejlehčích projektů, co je na bakaláři. Prakticky zadarmo. Jednoduché zadání, mírné hodnocení a dá to 
všechny důležité informace do dalších předmětů. Zkouška je potom jedna z náročnějších, kdo dával pozor na přednáškách by ale neměl mít žádný 
problém. Doporučuju projít zadání z minulých let a sám si to propočítat. Nepodceňte teorii.

## Hodnocení projektu *33b/34b*
Žádné výtky.

## Popis projektu

Tento projekt se zabývá vývojem informačního systému (IS) pro lékárnu. 
Cílem systému je správa a `evidence vydávání léků` občanům, a to jak `na předpis`, tak i `za hotové`. 
Některé léky jsou vydávány pouze na základě lékařského předpisu. 
`Část ceny léků hradí zdravotní pojišťovna`, a proto systém musí umožnit `evidenci těchto platů`. 
Dále musí být zajištěn `import příspěvků na léky` od zdravotních pojišťoven, které se `mohou čas od času měnit`. 
IS musí umožnit `export výkazů pro zdravotní pojišťovny` a musí být `propojen se skladovým systémem`, aby bylo možné `kontrolovat dostupnost léků na skladě`. 
Léky jsou identifikovány pomocí `číselného kódu` nebo `názvu`.

## Funkce systému

1. **Správa vydávání léků**: Systém umožňuje evidenci vydávaných léků občanům a zaznamenává, zda je vydávání na základě předpisu nebo za hotové.

2. **Evidence platů od pojišťoven**: Zajišťuje evidenci plateb od zdravotních pojišťoven za léky, které jsou hrazeny částečně nebo celkově.

3. **Import a export dat pro pojišťovny**: Systém umožňuje importovat aktualizace či změny příspěvků na léky od zdravotních pojišťoven a exportovat výkazy pro potřeby těchto institucí.

4. **Propojení se skladovým systémem**: Poskytuje informace o dostupnosti léků na skladě, aby bylo možné předejít situacím, kdy lék není k dispozici.

5. **Identifikace léků**: Systém umožňuje identifikaci léků pomocí jejich číselného kódu nebo názvu.
