#!/bin/bash

#для корректной работы
#скрипта parser.sh и считываемости файл source_file.csv
#добавим их в директорию $HOME и запускать всё отсюда,
#иначе может возникнуть неожиданное поведение программы


#для безопасной работы скрипта parser.sh 
set -euo pipefail

#вывод в терминал зелёным цветом
GREEN='\033[0;32m'

#создаем директории, куда будем сохранять:
#-временные файлы, используемые для сравнения  
mkdir -p $HOME/in_data
#-собственно, результат работы скрипта будет здесь
mkdir -p $HOME/out_data

#директория исходных данных
IN_DIR="$HOME/in_data"

#директория выходных данных
OUT_DIR="$HOME/out_data"


#список ВСЕХ регионов:
#уникальных и с дублями (включая повторы в перичисляемом списке).
#по сути, НЕИСПОЛЬЗУЕМЫЙ в скрипте, но для проверки не помешает, 
#поэтому можно закомментить
cut -d, -f4 source_file.csv |sort > $IN_DIR/allreg.txt

#список повторяющихся регионов 
#(БЕЗ повторов, указан единичный повторяемый регион)
cut -d, -f4 source_file.csv |sort | uniq -d > $IN_DIR/double.txt
 
#список НЕповторяющихся регионов
cut -d, -f4 source_file.csv| sort | uniq -u  > $IN_DIR/nondouble.txt


#создаем корневой каталог и переходим в него
mkdir -p $OUT_DIR/result
cd $OUT_DIR/result


#Создадим директории и yaml с повторяющимися регионами

COUNT_PERSON=1

while IFS=',' read -r NAME PHONE POSTAL_ZIP REGION COUNTRY CURRENCY COMPANY ADDRESS; do

    while IFS=',' read -r st; do

#сравниваем список ВСЕХ регионов (с дублями и без)
#со списком регионов, где есть только дубли (указаны единично, без повторов)
        if [[ "$REGION" == "$st" ]]; then

#создаем директорию для сохранения файлов с раширением yaml
            mkdir -p "$OUT_DIR/result/$COUNTRY/$REGION"

#создаем yaml'ы и сохраняем в соответствующие директории

            envPerson="person_$COUNT_PERSON"\
 envName="$NAME"\
 envAddress="$ADDRESS"\
 envCurr="$CURRENCY" yq e -n '(.[env(envPerson)]) |='\
' ((.name = (env(envName))) |'\
' (.address = (env(envAddress))) |'\
' (.curr = (env(envCurr))))'\
> "$OUT_DIR/result/$COUNTRY/$REGION/$POSTAL_ZIP.yaml"

#вывод в терминал уведомления о том, что файл был создан успешно по соответсвующему адресу
            echo -e  "$GREEN $OUT_DIR/result/$COUNTRY/$REGION/$POSTAL_ZIP.yaml was created successfully!" 

            (( COUNT_PERSON++ ))
 
	fi

done < $IN_DIR/double.txt
 
done < $HOME/source_file.csv




#Теперь будем создавать директории и yaml с НЕповторяющимися регионами

#Делаем всё то же самое, что и в парсинге дублирующихся регионов.
#Разница лишь в добавлении окончания _N ко всем переменным  и т.д.

COUNT_PERSON_N=1

while IFS=',' read -r NAME_N PHONE_N POSTAL_ZIP_N REGION_N COUNTRY_N CURRENCY_N COMPANY_N ADDRESS_N; do

    while IFS=',' read -r st_N; do

#сравниваем список ВСЕХ регионов (с дублями и без)
#со списком регионов, где только цникальные регионы
#(в люлм случаем тоже указаны единично, без повторов
        if [[ "$REGION_N" == "$st_N" ]]; then

            envPerson_N="person_$COUNT_PERSON_N"\
 envName_N="$NAME_N"\
 envAddress_N="$ADDRESS_N"\
 envCurr_N="$CURRENCY_N" yq e -n '(.[env(envPerson_N)]) |='\
' ((.name = (env(envName_N))) |'\
' (.address = (env(envAddress_N))) |'\
' (.curr = (env(envCurr_N))))'\
> "$OUT_DIR/result/$COUNTRY_N/$POSTAL_ZIP_N.yaml"

	    echo -e  "$GREEN $OUT_DIR/result/$COUNTRY_N/$POSTAL_ZIP_N.yaml was created successfully!"

	    (( COUNT_PERSON_N++ ))
	fi

done < $IN_DIR/nondouble.txt
 
done < $HOME/source_file.csv

#удаляем временные файлы вместе с директорией
rm -rf $IN_DIR

#перейдем в директорию КУДА будет создаваться архив
# и тут же создаём архив, указав его 
#и что подлежит упаковке
cd $OUT_DIR && tar -cJvf out_archive.tar.xz $OUT_DIR
