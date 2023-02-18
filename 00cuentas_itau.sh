#! /bin/sh
# eliminamos la carpeta informe y los archivos journal para comenzar con datos limpios
rm -rf informe
rm 01nacional.journal
rm 02internacional.journal
rm 03corriente.journal

# Convertir el excel en csv
libreoffice --headless --convert-to csv cuenta_tarjeta.xls --outdir informe
libreoffice --headless --convert-to csv cuenta_corriente.xls --outdir informe
libreoffice --headless --convert-to csv cuenta_puntos.xls --outdir informe

# convertir a utf-8 
iconv -f latin1 -t UTF-8  informe/cuenta_tarjeta.csv > informe/00cuenta_tarjeta_utf8.csv 
iconv -f latin1 -t UTF-8  informe/cuenta_corriente.csv > informe/00cuenta_corriente_utf8.csv 
iconv -f latin1 -t UTF-8  informe/cuenta_puntos.csv > informe/00cuenta_puntos_utf8.csv 

# Extraer del csv la información relevante 
# Dividimos el archivo total de la tarjeta en cuenta nacional e internacional comenzando por
# la descripción "Movimientos no facturados"
csplit informe/00cuenta_tarjeta_utf8.csv '/Movimientos no/' '{*}'
# Movemos los archivos resultantes a la carpeta informe "Movimientos no facturados"
mv xx0* informe 

## Estado cuenta nacional 
# filtramos los campos necesarios   
awk 'BEGIN{OFS=FS=","} {print $1,$3,$6 ;}' informe/xx01 > informe/01input_nacional.csv
#hledger 
hledger -f informe/01input_nacional.csv --rules-file 01nacional.rules print > 01nacional.journal


## Estado cuenta internacional 
head -n-2 informe/xx02 | awk 'BEGIN{FPAT = "([^,]+)|(\"[^\"]+\")";OFS = "|"} {print $1,$3,$NF;}' | awk 'BEGIN{FS= "|";OFS=","} {gsub(/,/, ".", $3)} {gsub(/\.\./, ",", $3)} {gsub(/"/, "", $3)} {print $1,$2,$3;}' - > informe/02input_internacional.csv
hledger -f informe/02input_internacional.csv --rules-file 02internacional.rules print > 02internacional.journal

## Cuenta corriente
# Extraer del csv la información relevante 
csplit informe/00cuenta_corriente_utf8.csv '/Últimos Movimientos/' '{*}'
awk 'BEGIN{OFS=FS=","} {print $1,$3,$4,$5 ;}' xx01 > informe/03input_corriente.csv
rm xx0*
#hledger 
hledger -f informe/03input_corriente.csv --rules-file 03corriente.rules print > 03corriente.journal

## Puntos ITAU 
# Extraer del csv la información relevante 
csplit informe/00cuenta_puntos_utf8.csv '/Fecha carga de puntos/' '{*}'
awk 'BEGIN{OFS=FS=","} {print $1,$3,$NF ;}' xx01 | tr -s ' ' > informe/04input_puntos.csv
rm xx0*
#hledger 
hledger -f informe/04input_puntos.csv --rules-file 04puntos.rules print > 04puntos.journal 

