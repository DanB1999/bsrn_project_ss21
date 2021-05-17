#!/bin/bash
arr=(memArr)
#memArr[0]="1|01|30"
arr=(processArr)
#processArr[0]="00|a|30"


function check2expn() {
    local w=0
    local n=$1

    # zählt alle 1, bis n>0
    while ((n > 0)); do
        if (((n & 1) == 1)); then
            
            w=$((w + 1))
        fi

        if ((w > 1)); then
            # wenn w > 1, ist n keine 2er-Potenz
            check=1
            break
        fi

        # nächstes bit wird überprüft
        n=$((n >> 1))
    done

    if ((w == 1)); then
        #setzt "check" auf true, wenn n 2er-Potenz ist  
        check=0
    fi
}

function createProcess()	{
	if [ $concept = "ff" ]; then
		firstFit
	elif [ $concept = "bf" ]; then
		bestFit $1 $2
	elif [ $concept = "nf" ]; then
		nextFit
	else 
		echo "FALSE"
	fi
		
		
		
}
function bestFit() {
	diff=00 #diff bleibt '00' wenn kein ausreichend großer, freier Block gefunden wird 
	#dursucht Array nach erstem freien Block mit entsprechender Differenz von Block und Prozess
	for block in ${memArr[*]}
	do
		if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then 
			diff=$((${block:5}-$2))
			blockId=${block:2:2}
			break
		fi
	done
	sum=0
	#summiert die Größe aller Prozesse auf 
	#vergleicht alle Differenzen mit erster Differenz , wenn kleiner, dann wird diese überschrieben
	for process in ${memArr[*]}
	do
		sum=$((sum+${process:5}))
		free=${process:0:1}
		
		if [ ${process:0:1} -eq 1 ] && [ ${process:5} -ge $2 ]; then
				if [ $((${process:5}-$2)) -lt $diff ]; then
					diff=$((${process:5}-$2))
					blockId=${process:2:2}
				fi		
		else
			continue 
		fi 				
	done
	echo beste Differenz: $diff im Block $blockId
	if [ $diff -ne "00" ]; then
		splitBlock $blockId $2 $1
		showMemoryUsage
	else
		if [ $(($memory-$sum)) -ge $2 ]; then
			num=${#memArr[*]}
			memArr[$num]="0|$1|$2"
			echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
			showMemoryUsage
		else 
			echo "Fehler: nicht genügend Speicher vorhanden, Prozesse löschen"
		fi
	fi
	
}


function deleteProcess()	{
	for index in ${!memArr[*]}
	do
		 if [ ${memArr[$index]:2:2} -eq $1 ]; then
			
			 memArr[$index]="1|$1|${memArr[$index]:5}"
			 echo $(tput rev)$(tput setaf 2)Deleted!$(tput sgr0)
			 showMemoryUsage
			
		 fi
		
	done
	
}

#belegt freien Block mit Prozess: Übergabeparameter: $BlockId $Prozessgröße $ProzessId
function splitBlock()	{
	for index in ${!memArr[*]}
	do
		if [ ${memArr[$index]:2:2} -eq $1 ]; then
			counter=${#memArr[*]}
			for index2 in ${!memArr[*]}
			do
				if [ $index2 -gt $index ] && [ $counter -ne $(($index+1)) ]; then
					memArr[$counter]=${memArr[$(($counter-1))]}
					counter=$(($counter-1))
				fi
				
			done
		fi
	done
	
	for index3 in ${!memArr[*]}
	do
		if [ ${memArr[$index3]:2:2} -eq $1 ]; then
			diffr=$((${memArr[$index3]:5}-$2))
			memArr[$(($index3+1))]="1|$1|$diffr"
			memArr[$index3]="0|$3|$2"
			break
		fi
			
	done
}


function showMemoryUsage()	{
	sum=0
	for index in ${!memArr[*]}
	do			
		echo $index ${memArr[$index]}
		sum=$(($sum+${memArr[$index]:5}))
	done
	echo $(($memory-$sum)) KB verbleibend
	
	echo "$(tput rev)$(tput setaf 7)|									$memory KB									|$(tput sgr0)"
}

function showInfo()		{
	echo Grad der externen Fragmentierung:
	echo Größter/Kleinster freier Speicherblock: 
	echo Gesamtzahl belegter/freier Blöcke im Adressraum:
	showMemoryUsage
}


#Main-Part
echo "$(tput bold)$(tput setaf 5)Hallo, das ist eine Simulator zur Visualisierung einer dynamischen Pationierung!"
echo "$(tput bold)$(tput setaf 2)Geben Sie die Größe des gewünschten Speicher ein:\n(in KB; Die Größe muss eine Zweierpotenz sein)$(tput sgr0)"
read memory

check2expn $memory
while (($check != 0)); do
    echo "$(tput bold)$(tput setaf 1)Speicher ist keine 2er Potenz$(tput sgr0)"
    echo "$(tput bold)$(tput setaf 2)Geben Sie den gewünschten Speicher ein:\n(in KB; Die Größe muss eine Zweierpotenz sein)$(tput sgr0)"
    read memory
    check2expn $memory
done
echo Sie haben $memory KB reserviert

#Auswahl der Realisierungskonzepte
echo
echo $(tput bold)$(tput setaf 2)$(tput smul)Wählen Sie ein Realisierungskozept aus:$(tput sgr0)
echo
options="First_Fit Best_Fit Next_Fit Random"
select option in $options; do
	# Suche beginnend mit Speicheranfang bis ausreichend großer Block gefunden
	if [ "$option" = "First_Fit" ]; then
		concept="ff"
		createProcess
		break
	# sucht ab dem Anfang des Speicheradressraums Suche kleinsten Block, der ausreicht
	elif [ "$option" = "Best_Fit" ]; then
		concept="bf"
		break
	# Suche beginnend mit der Stelle der letzten Speicherzuweisung
	elif [ "$option" = "Next_Fit" ]; then
		concept="nf"
		break
	elif [ "$option" = "Random" ]; then
		concept="r"
		break
	else 
		echo Ungültige Eingabe! Bitte Wiederholen 
	fi
done

#Menü 
echo
echo $(tput bold)$(tput setaf 2)$(tput smul)Liste der möglichen Befehle:$(tput sgr0)
echo
echo -e "Prozess anlegen: \t\t\t$(tput rev)create [Prozessbezeichnung] [Größe in KB]$(tput sgr0)"
echo -e "Prozess beenden: \t\t\t$(tput rev)delete [Prozessbezeichnung] $(tput sgr0)"
echo -e "Informationen zur Speicherbelegung: \t$(tput rev)info $(tput sgr0)"
echo -e "Anwendung beenden: \t\t\t$(tput rev)end $(tput sgr0)"

i=0
while [ $i -eq 0 ]; do
	echo
	read command name size
	if [ $command = "create" ]; then
		createProcess $name $size
		echo 
	elif [ $command = "delete" ]; then
		deleteProcess $name $size
		echo 
	elif [ $command = "info" ]; then
		echo
		showInfo
	elif [ $command = "end" ]; then
		echo Auf Wiedersehen!
		exit
	else
		echo Kommando nicht bekannt!
	fi
done

