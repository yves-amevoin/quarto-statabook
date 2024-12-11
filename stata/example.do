/*------------------------------------------------------------------------------
Exemple de génération de tableaux et de figures à partir du processus
effectue pour Fexi
------------------------------------------------------------------------------*/

/*
Avant de lancer le projet, assurez-vous d'avoir les  prés-requis suivants 
installés sur votre ordinateur: 
- pandoc >= 2.14.2. Disponible ici: https://pandoc.org/installing.html
- Stata >= 15
- Le package Stata "sxpose2".
Vous pouvez l'installer via le ssc: ssc install sxpose2
*/


*ssc install sxpose2
version 15
clear

**# Définissez vos répertoires avant de commencer

//Répertoire vers les donnees: ici on n'utilise que trois bases de donnees:
// la base de donnees auto, lifeexp.

global dir_project "/Users/komlaviamevoin/Unsync-Working-Folders/quarto-statabook"
global dir_datasets "$dir_project/input_datasets" 

*------------------------------------------------
global dir_tables "$dir_project/output_datasets" // Où les tables seront stockees
global dir_figures "$dir_project/output_figures" // où les figures seront stockees

// Ajout des programes
quietly adopath + "$dir_project/stata/programs"

// Chemins vers les fichiers:


**# Creation d'un tableau avec des qualitatifs, ici on va faire des tabulations
*sur 

use "$dir_datasets/auto.dta", clear
*je vais tabuler le nombre de voitures foreigns vs domestic

// je commence par générer des variables dichotomiques correspondants aux 
// valeurs que je veux representer en pourcentage:

gen dom = (foreign == 0) // Les voitures domestiques
gen etr = (foreign == 1) // Les voitures etrangeres

//La fonction qual de mes programmes, calcule le pourcentage pour ces individus
// précédent, en utilisant comme dénominateur le nombre de personnes dans la base
// de donnees. Vous pouvez aussi mettre des conditions pour réduire l'effectif de la 
//population utilisée au dénominateur. On pourrait par exemple mettre un if

quietly count if rep78 > 3
label variable dom "Domestique"
label variable etr "Etrangere"

qual dom etr if rep78 > 3, output("$dir_tables/test_quali.dta") // On effectue la tabulation sur les individus qui ont un repair record > 3

//A ce niveau j'ai une base de donnees que je peux directement mettre dans 
// le document word, avec les labels qui correspondent aux labels des variables. Les
// variables seront ajoutés dans l'ordre qu'on les mets ici dans le code. Et on 
// pourrait directement changer ici dans le code le label des variables, sans passer
// par un fichier excel. Il n'y a plus besoin de générer les variables tab_* et
// de retourner après la base de données.

preserve

use "$dir_tables/test_quali.dta", clear
//affichage du tableau (vous verrez que l'odre a changé, en comparaison a l'odre dans la feuille excel)

//A ce niveau on a une table qui peut rentrer dans le document. La fonction 
//precedente ecrase la table. On peut tester a quoi ressemblera  la table dans le markdown,
// mais cette fonction n'est plus utile.
kable

restore

// Je peux supposer ici faire des tabulations de certaines variables suivant 
// variable categorielle precise

gen high_price = (price > 10000)
label variable high_price "High Prices"
gen low_mpg = (mpg < 15)
label variable low_mpg "Low mpg"

// je peux utiliser ici mon qual, avec un output et même y ajouter des donnees successivement
qual high_price, output("$dir_tables/test_quali2.dta") by(foreign)

preserve

use "$dir_tables/test_quali2.dta", clear
kable

restore

// On peut aussi coller d'anciennes donnees a des nouvelles grace a append
qual low_mpg, output("$dir_tables/test_quali2.dta") append by(foreign)

preserve

use "$dir_tables/test_quali2.dta", clear
kable

restore

// On peut aussi décider d'y aller directement en mettant une liste de variables

qual low_mpg high_price dom etr, output("$dir_tables/test_quali3.dta") by(foreign)

preserve

use "$dir_tables/test_quali3.dta", clear
kable

restore

**# Creation de tableau avec les quantitatifs

//On va illuster ici en utilisant la base auto et en calculant des donnees sur mpg et weight

use "$dir_datasets/auto.dta", clear

//Dans mes programmes, la fonction quant permet de faire des tabulations sur 
// une variable quantitative. Voici la signification des options:

* - mxsep: un charactère qui est le séparateur des valeurs minimales / maximales
* - mxbrack: Ce qu'il faut utiliser pour entoure les valeurs min/max ici, c'est deux options: b pour bracket [] et p pour parenthesis ()
*- medsep : ce qu'il faut utiliser pour séparer les quantiles Q1 - Q3
*-medbrack: les valeurs qu'il faut utiliser pour entourer les quantiles b pour bracket et p pour parenthesis

*- C'est possible de n'avoir que la moyenne seulement avec l'option meanonly 
*- C'est possible de n'avoir que la mediane seulement avec l'option medianonly

*- Il faut s'attendre donc a un output de la forme: N, Mediane [Q1 ; Q3] (Min / Max). Vous pouvez ne rien mettre, les valeurs par defaut sont utilisees.

quant mpg, output("$dir_tables/test_quanti1.dta") mxsep("/") medsep(";") 
quant weight, meanonly output("$dir_tables/test_quanti2.dta")
quant length, medianonly output("$dir_tables/test_quanti3.dta")
quant length turn displacement if rep78 > 3, meanonly output("$dir_tables/test_quanti4.dta")

// comme précédemment, on peut présenter les résultats par une variable
quant length turn displacement, meanonly output("$dir_tables/test_quanti5.dta") by(foreign) 

// ou bien meme ajouter des resultats a une table existante
quant weight, output("$dir_tables/test_quanti1.dta") mxsep("/") medsep(";") append

// meanonly presente la moyenne puis l'ecart-type entre parentheses.
// medianonly presente la mediane puis l'interval interquatile, et le min/max


preserve

use "$dir_tables/test_quanti1.dta", clear
kable

use "$dir_tables/test_quanti2.dta", clear
kable


use "$dir_tables/test_quanti3.dta", clear
kable

use "$dir_tables/test_quanti4.dta", clear
kable

use "$dir_tables/test_quanti5.dta", clear
kable

restore

