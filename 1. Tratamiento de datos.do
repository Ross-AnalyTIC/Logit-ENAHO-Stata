*====================================================================
* CARGA, ACONDICIONAMIENTO DE DATOS Y GENERACIÓN DE VARIABLES (2020)
*====================================================================

cls        
clear all
set more off

global inputs "D:\DATA_RURAL\1_Inputs"

cd "$inputs"

*---------------------------------------------------------
* 1. CONVERSIÓN DE DATOS A CÓDIGO LATINO
*---------------------------------------------------------

unicode analyze *
unicode encoding set ISO-8859-1
unicode translate *

*---------------------------------------------------------
* 2. LIMPIEZA DE BASES DE DATOS
*---------------------------------------------------------


// EDUCACIÓN - 300 (3 a más años)

use "$inputs\enaho01-2020-300", clear

*  Generamos identificador único
isid conglome vivienda hogar codperso
gl id_persona "conglome vivienda hogar codperso"

* Removemos datos vacíos, missing date y otros items
drop if codinfo=="00" // quita valores vacios
drop if p301a==. // borra missing date
drop if p301a==12 // borra educacion especial
keep if p204==1 // solo miembros del hogar
count 

save "$outputs\Educacion-2020",replace


// EMPLEO - 500 (14 a más años)

use "$inputs\enaho01-2020-500", clear

isid conglome vivienda hogar codperso
gl id_persona "conglome vivienda hogar codperso"

drop if codinfor=="00" 
keep if p204==1 
count 

save "$outputs\Empleo-2020",replace


// SUMARIA 

use "$inputs\sumaria-2020",clear 

* Generamos identificador único de hogar
isid conglome vivienda hogar
gl id_hogar "conglome vivienda hogar"
count 

save "$outputs\Sumaria-2020",replace

//  HOGARES - 100

use "$inputs\enaho01-2020-100", clear

* Generamos identificador único de hogar
isid conglome vivienda hogar
gl id_hogar "conglome vivienda hogar"
count 

save "$outputs\Hogares-2020",replace


// MIEMBROS DEL HOGAR - 200

use "$inputs\enaho01-2020-200", clear

* Generamos identificador único
isid conglome vivienda hogar codperso
gl id_persona "conglome vivienda hogar codperso"
count 

save "$outputs\Poblacion-2020",replace

*---------------------------------------------------------
* 3. UNIÓN DE BASES DE DATOS
*---------------------------------------------------------

// Hogares-Sumaria

use "$outputs\Hogares-2020",clear  
merge 1:1 conglome vivienda hogar using "$outputs\Sumaria-2020"
keep if _merge==3 
drop _merge
count 


// Población - Hogares - Educación -Empleo

use "$outputs\Poblacion-2020",clear  
merge m:1 conglome vivienda hogar using "$outputs\Hogares-Sumaria-612-2020"
keep if _merge==3 
drop _merge
count 
 
merge 1:1 conglome vivienda hogar codperso using "$outputs\Educacion-2020"
drop _merge 
count 

merge 1:1 conglome vivienda hogar codperso using "$outputs\Empleo-2020"
drop _merge 
count 

save "$outputs\global-2020", replace


*---------------------------------------------------------
* 4. SELECCIÓN DE VARIABLES DE ESTUDIO
*---------------------------------------------------------

* Área rural
fre estrato
recode estrato (1/5=0 "Urbano") (6/8=1 "Rural"), gen(area)
keep if area==1 
count 

* Residente habitual
g resi=((p204==1 & p205==2) | (p204==2 & p206==1))
lab var resi "residente habitual del hogar"
keep if resi==1 
count 

* Selección de variables
keep conglome vivienda hogar codperso estrato dominio ubigeo pobreza p1121 p1144 p105a p208a p203 p204 p205 p207 p301a p301b p301c p300a p501 p507 p514 p506r4 p519 p524e1 i513t i518 i520 i524a1 d529t i530a d536 i538a1 d540t i541a d543 d544t ocu500 mieperho inghog1d

* Renombramos algunas variables
rename p1121 electricidad
rename p301a educacion
rename p501 trabajo
rename p524e1 ingreso

* Internet
gen internet=(p1144==1)
label define internet 1 "con acceso a internet" 0 "sin acceso a internet"
lab val internet internet

* Sexo del jefe de hogar
gen sexo=(p207==1)
label define sexo 1 "hombre" 0 "mujer"
lab val sexo sexo

* Edad
rename p208a edad
tab edad
keep if edad>=6

* región natural
gen regnat=1 if dominio>=1 & dominio<=3 
replace regnat=1 if dominio==8
replace regnat=2 if dominio>=4 & dominio<=6 
replace regnat=3 if dominio==7 
label define regnat 1 "Costa" 2 "Sierra" 3 "Selva"
lab val regnat regnat

tab regnat,gen(reg)

ren reg1 costa
ren reg2 sierra
ren reg3 selva

* Departamento
gen dpto=substr(ubigeo,1, 2)
destring dpto, replace

lab def dpto 1 "AMAZONAS" 2 "ANCASH" 3 "APURIMAC" 4 "AREQUIPA" 5 "AYACUCHO" 6 "CAJAMARCA" 7 "CALLAO" 8 "CUSCO" 9 "HUANCAVELICA" 10 "HUANUCO" 11 "ICA" 12 "JUNIN" 13 "LA LIBERTAD" 14 "LAMBAYEQUE" 15 "LIMA" 16 "LORETO" 17 "MADRE DE DIOS" 18 "MOQUEGUA" 19 "PASCO" 20 "PIURA" 21 "PUNO" 22 "SAN MARTIN" 23 "TACNA" 24 "TUMBES" 25 "UCAYALI"
lab value dpto dpto
fre dpto

* regiones politicas
decode dpto, gen(regpolx)
gen prov=substr(ubigeo,1,4)
replace regpolx="LIMA METROPOLITANA" if prov=="1501"
replace regpolx="LIMA REGIÓN" if regpol=="LIMA"
encode regpolx, gen(regpol)

* Idioma // Agrupamos en 0 (4 Castellano, 6 Portugués y 7 Otra lengua extranjera) y Agrupamos en 1 (1 Quechua, 2 Aimara, 3 Otra lengua nativa, Ashaninka, Awajun/Aguaruna, Shipibo-Konibo, Shawi/Chayahuita, Matsigenka/Machiguenga, Achuar)
recode p300a (4 6 7=0)
recode p300a (1 2 3 10 11 12 13 14 15=1)
recode p300a (1 2 3 10 11 12 13 14 15=1 "idioma nativo") (4 6 7=0 "idioma extranjero"), gen(idioma)

* pobreza
gen pobre=(pobreza==1 | pobreza==2) // dummy
lab def pobre 1 "Pobre monetario" 0 "No pobre monetario"
lab val pobre pobre

* Trabaja
replace trabajo = 0 if trabajo == 2

* Ocupado
gen ocupado=(ocu500==1)
lab def ocupado 1 "ocupado" 0 "no ocupado"
lab val ocupado ocupado

* Horas trabajadas a la semana
egen horas=rsum(i513t i518) if p519==1 
replace horas=i520 if p519==2

* Ingreso por trabajo
egen ingtrab_año=rsum(i524a1 d529t i530a d536 i538a1 d540t i541a d543 d544t)
gen ingtrab_mes=ingtrab_año/12
gen ingtrab_sem=ingtrab_año/52
gen inghor=ingtrab_sem/horas

* horas trabajadas a la semana
tabstat horas, s(mean min p5 p25 p50 p75 p95 max)
gen mas60horas=(horas>=60) if horas!=.
fre mas60horas

* Ramas de actividad
gen ciuu=p506r4
tostring ciuu,replace
gen tam=length(ciuu)
replace tam=. if tam==1
replace ciuu="0"+ ciuu if tam==3   
gen ciuu2dig=substr(ciuu,1,2)
destring ciuu2dig, replace

recode ciuu2dig (1/3 =1) (5/9 =2) (10/33 =3) (35=4) (36/39 =5) ///
(41/43 =6) (45/47 =7) (49/53 =8) (55/56 =9) (58/63 =10) (64/66 =11) ///
(68 =12) (69/75 =13) (77/82 =14) (84 =15) (85 =16)(86/88 =17) (90/93 =18) ///
(94/96 =19) (97/98 =20) (99 =21), gen(ciuu1dig)

* grandes ramas
recode ciuu1dig (1/2=1) (3=2) (4=6) (5=6) (6=3) (7=4) (8=5) (10=5) (9=6) (11/21=6), gen(ramas)

lab def ramas 
1 "Agricultura/Pesca/Minería" 
2 "Manufactura" 
3 "Construcción" 
4 "Comercio" 
5 "Transportes y Comunicaciones" 
6 "Otros Servicios"
lab val ramas ramas
tab ramas

* Ingreso percapita mensual
gen ingper=inghog1d/(mieperho*12)
gen log_ingper=ln(ingper)

* Años de educación
gen años_educ=0  if  educacion<=2
replace años_educ=p301b if  (educacion>=3  & educacion<=4) 
replace años_educ=p301c if  (educacion>=3  & educacion<=4) &  (p301b==0 | p301b==.)
replace años_educ=p301b+6 if  educacion>=5  & educacion<=6
replace años_educ=p301b+11 if  educacion>=7  & educacion<=10
replace años_educ=p301b+16 if  educacion==11
replace años_educ=p301b if  educacion==12
fre años_educ

* Nivel educativo
recode educacion (1/2=1) (12=1) (3/4=2) (5/6=3) (7/8=4) (9/11=5),gen (niveduc)
lab def niveduc 1 "Sin nivel" 2 "Primaria" 3 "Secundaria" 4 "Sup. no universitario" 5 "Sup. universitario"
lab val niveduc niveduc
tab niveduc, g(neduc) //generar dicotómicas para cada categoría

save "$outputs\rural-2020", replace

*******************************************************************
