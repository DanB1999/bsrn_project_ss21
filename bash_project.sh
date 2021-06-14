#!/bin/bash
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
		firstFit $1 $2
	elif [ $concept = "bf" ]; then
		bestFit $1 $2
	elif [ $concept = "nf" ]; then
		nextFit $1 $2
	
	elif [ $concept = "rf" ]; then
		randomFit $1 $2

	else 
		echo "FALSE"
	fi
}

function showProcesses {
	echo "prozesse: "
	for process in ${processArr[*]}
	do
		echo "$process"
	done
}

function randomFit {
	allocated=0
	diff=-1
	while [ $allocated -eq 0 ];
	do
		randomBlock=${memArr[$RANDOM % ${#memArr[@]} ]}
		echo $randomBlock
		if [ ${randomBlock:0:1} -eq 1 ] && [ ${randomBlock:5} -ge $2 ]; then 
				diff=$((${randomBlock:5}-$2))
				blockId=${randomBlock:2:2}
				blockCounter=$(($blockCounter-1))
				
			if [ $diff -ge 0 ]; then
				if [ $diff -eq 0 ]; then 
					processArr[${#processArr[*]}]="$blockId|$1"
					
				elif [ $diff -gt 0 ]; then 
					processArr[${#processArr[*]}]="$blockCounter|$1"
					
				fi
				allocated=1
				splitBlock $blockId $2 $blockCounter 
				showMemoryUsage
			else
				echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"	
			fi
		fi	
	done		
}

function nextFit() {
	diff=-1
	if [ $lastBlock -eq 0 ]; then
		for block in ${memArr[*]}
		do
			if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then 
				diff=$((${block:5}-$2))
				blockId=${block:2:2}
				blockCounter=$(($blockCounter-1))
				break
			fi
		done
		
	else 
		while [ $lastBlock -le  ${#memArr[*]} ]
		do
			block= ${memArr[lastBlock]}
			if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then 
				diff=$((${block:5}-$2))
				blockId=${block:2:2}
				break
			fi
			$((lastBlock++))
		done
		blockCounter=$(($blockCounter-1))
	fi	
		#wenn die Blockgröße gleich der Prozessgröße ist, wird dessen Id dem Prozess zugeordnet
		#ansonsten absteigender Wert von 99
		if [ $diff -ge 0 ]; then
			if [ $diff -eq 0 ]; then 
				processArr[${#processArr[*]}]="$blockId|$1"
			elif [ $diff -gt 0 ]; then 
				processArr[${#processArr[*]}]="$blockCounter|$1"
			fi
			splitBlock $blockId $2 $blockCounter 
			showMemoryUsage
		else
			echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"	
		fi	
		

}

#weist den ersten freien Block im Speicher dem Prozess zu
function firstFit()	{
	for block in ${memArr[*]}
	do
		if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then
			blockCounter=$(($blockCounter-1))
			splitBlock ${block:2:2} $2 $blockCounter
			if [ ${block:5} -gt $2 ]; then 
				processArr[${#processArr[*]}]="$blockCounter|$1"
				break
			elif [ ${block:5} -eq $2 ]; then
				processArr[${#processArr[*]}]="${block:2:2}|$1"
				break
			fi
		fi
	done
	showMemoryUsage			
}

#findet den freien Block mit der geringsten Speicher-Differenz zum Prozess
function bestFit() {
	diff=-1 #diff bleibt '-1' wenn kein ausreichend großer, freier Block gefunden wird 
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
		sum=$(($sum+${process:5}))
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
	blockCounter=$(($blockCounter-1))
	
	#wenn die Blockgröße gleich der Prozessgröße ist, wird dessen Id dem Prozess zugeordnet
	#ansonsten absteigender Wert von 99
	if [ $diff -ge 0 ]; then
		if [ $diff -eq 0 ]; then 
			processArr[${#processArr[*]}]="$blockId|$1"
		elif [ $diff -gt 0 ]; then 
			processArr[${#processArr[*]}]="$blockCounter|$1"
		fi
		splitBlock $blockId $2 $blockCounter 
		showMemoryUsage
	else
		echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"	
	fi			
}

#prüft, ob vor oder hinter betreffendem freien Block noch freie Blöcke liegen, wenn ja, verbindet er sie 
function putTogetherFreeBlocks()	{
	zaehler1=0
	zaehler2=0
	sum=0
	for index in ${!memArr[*]}
	do
		
		 if [ ${memArr[$index]:2:2} -eq $1 ] && [ ${memArr[$index]:0:1} -eq 1 ]; then
	 		if [ $index -gt 0 ]; then 
			 	if [ ${memArr[$(($index-1))]:0:1} -eq 1 ]; then
				 	if [ ${memArr[$(($index+1))]:0:1} -eq 1 ]; then
					 	zaehler1=$index
					 	sum=$((${memArr[$(($index-1))]:5}+${memArr[$index]:5}+${memArr[$(($index+1))]:5}))
					 	memArr[$(($index-1))]="1|$1|$sum"
					 
				 	else 
					 	zaehler2=$index
					 	sum=$((${memArr[$(($index-1))]:5}+${memArr[$(($index))]:5}))
					 	memArr[$(($index-1))]="1|$1|$sum"					 
				 	fi
			 	elif [ ${memArr[$(($index+1))]:0:1} -eq 1 ] && [ ${memArr[$(($index-1))]:0:1} -ne 1 ]; then
				 	zaehler2=$(($index+1))
				 	sum=$((${memArr[$index]:5}+${memArr[$(($index+1))]:5}))
				 	memArr[$index]="1|$1|$sum"
			 	fi
		 	elif [ ${memArr[$(($index+1))]:0:1} -eq 1 ]; then
			 	zaehler2=$(($index+1))
			 	sum=$((${memArr[$index]:5}+${memArr[$(($index+1))]:5}))
			 	memArr[$index]="1|$1|$sum"
			fi
		fi
	 	
		if [ $zaehler1 -ne 0 ] && [ $zaehler1 -lt $((${#memArr[*]}-2)) ]; then 
			memArr[$zaehler1]=${memArr[$(($zaehler1+2))]}
			zaehler1=$(($zaehler1+1))
		elif [ $zaehler2 -ne 0 ] && [ $zaehler2 -lt $((${#memArr[*]}-1)) ]; then
			memArr[$zaehler2]=${memArr[$(($zaehler2+1))]}
			zaehler2=$(($zaehler2+1))
		else
			continue
		fi
	done
	if [ $zaehler1 -ne 0 ];then
		unset 'memArr[$((${#memArr[*]}-1))]'
		unset 'memArr[$((${#memArr[*]}-1))]'
	elif [ $zaehler2 -ne 0 ];then
		unset 'memArr[$((${#memArr[*]}-1))]'
	fi
		

}

#löscht Eintrag aus Prozess-Array, setzt entspr. Block auf FREI
function deleteProcess()	{
	counter5=-1
	for process in ${!processArr[*]}
	do
		if [[ "${processArr[$process]:3}" == "$1" ]]; then
			for block in ${!memArr[*]}
			do
				if [ ${processArr[$process]:0:2} -eq ${memArr[$block]:2:2} ]; then
					counter5=$process
					memArr[$block]="1|${memArr[$block]:2:2}|${memArr[$block]:5}"
					index10=${memArr[$block]:2:2}
					echo $(tput rev)$(tput setaf 2)Deleted!$(tput sgr0)	
					putTogetherFreeBlocks ${memArr[$block]:2:2}
					break
				fi
			done 	 
		fi
		if [ $counter5 -ne -1 ] && [ $counter5 -lt $((${#processArr[*]}-1)) ]; then
			processArr[$counter5]=${processArr[$(($counter5+1))]}
			counter5=$(($counter5+1))
			
		fi
	done
	if [ $counter5 -lt $((${#processArr[*]}-1)) ]; then
		unset 'processArr[$((${#processArr[*]}-1))]'
	else
		unset 'processArr[$counter5]'
	fi
	showMemoryUsage $index10
}

#belegt freien Block mit Prozess: Übergabeparameter: $BlockId $Prozessgröße $neue BlockId
function splitBlock()	{
	counter=0
	for index in ${!memArr[*]}
	do
		if [ ${memArr[$index]:2:2} -eq $1 ]; then
			if [ ${memArr[$index]:5} -gt $2 ]; then
				counter=${#memArr[*]}
				for index2 in ${!memArr[*]}
				do
					if [ $index2 -gt $index ] && [ $counter -ne $(($index+1)) ]; then
						memArr[$counter]=${memArr[$(($counter-1))]}
						counter=$(($counter-1))
					fi
				
				done
			elif [ ${memArr[$index]:5} -eq $2 ]; then
				memArr[$index]="0|$1|$2"
				echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
			else
				echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"
			fi
		else
			continue
		fi	
	done
	
	for index3 in ${!memArr[*]}
	do
		if [ ${memArr[$index3]:2:2} -eq $1 ] && [ $counter -ne 0 ]; then
			diffr=$((${memArr[$index3]:5}-$2))
			memArr[$(($index3+1))]="1|$1|$diffr"
			#putTogetherFreeBlocks ${memArr[$(($index3+1))]}
			memArr[$index3]="0|$3|$2"
			echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
			break
		else
			continue	
		fi
			
	done
}

#verknüpft Block-Array mit Prozess-Array und gibt belegte/freie Blöcke aus 
function showMemoryUsage()	{
	for block in ${!memArr[*]}
	do
		if [ ${memArr[$block]:0:1} -eq 0 ]; then
			for process in ${!processArr[*]}
			do
				if [ ${memArr[$block]:2:2} -eq ${processArr[$process]:0:2} ]; then
					if [ $process -ne $((${#processArr[*]}-1)) ]; then 
						echo -e "\033[47mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m" 
					elif [[ $1 == "" ]]; then
						echo -e "\033[47;1mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m"
					else 
						echo -e "\033[47mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m"
					fi 
				fi
				#echo §process ${processArr[$process]}
				
			done
		elif [[ $1 != "" ]]; then
			if [ ${memArr[$block]:2:2} -eq $1 ]; then
				echo -e "\033[1mfrei:\t---\t${memArr[$block]:5} KB \033[0m"
			else
			echo -e "frei:\t---\t${memArr[$block]:5} KB"	 
			fi
		else
			echo -e "frei:\t---\t${memArr[$block]:5} KB"
		fi
		#echo $block ${memArr[$block]}
	done
	#echo "$(tput rev)$(tput setaf 7)|									$memory KB									|$(tput sgr0)"
}

#liest Block-Array aus, um Inforamtionen zum Grad d. externen Fragementierung, etc auszugeben
function showInfo()		{
	# 100/1024 = ca. 10%
	sum=0
	free=0
	belegt=0
	gIndex=0
	for index in ${!memArr[*]}
	do
		if [ ${memArr[$index]:0:1} -eq 1 ]; then
			free=$(($free+1))
			if [ $index -ne $((${#memArr[*]}-1)) ]; then
				sum=$(($sum+${memArr[$index]:5}))
			fi
			if [ ${memArr[$index]:5} -gt ${memArr[$gIndex]:5} ]; then
				gIndex=$index
			fi
		elif [ ${memArr[$index]:0:1} -eq 0 ]; then
			belegt=$(($belegt+1))
		fi
	done
	sIndex=$gIndex
	for index2 in ${!memArr[*]}
	do
		if [ ${memArr[$index2]:0:1} -eq 1 ] && [ ${memArr[$index2]:5} -lt ${memArr[$sIndex]:5} ]; then
			sIndex=$index2
		fi
	done
	
	a=$(python -c "print($sum+0.0)")
	b=$(python -c "print($memory+0.0)")
	result=$(python -c "print(($a/$b)*100.0)")
	echo -e "Grad der externen Fragmentierung:\t\t\t$result %"
	echo -e "Größter/Kleinster freier Speicherblock:\t\t\t${memArr[$gIndex]:5} ${memArr[$sIndex]:5}"
	echo -e "Gesamtzahl belegter/freier Blöcke im Adressraum:\t$belegt $free"
	showMemoryUsage
}

#-----------------------------------------Main-Part------------------------------------------

echo "$(tput bold)$(tput setaf 5)Hallo, das ist eine Simulator zur Visualisierung einer dynamischen Pationierung!"
echo -e "$(tput bold)$(tput setaf 2)Geben Sie die Größe des gewünschten Speicher ein:\n(in KB; Die Größe muss eine Zweierpotenz sein)$(tput sgr0)"
read memory

#prüft, ob der eingebene Speicher einer Zweierpotenz entspricht
check2expn $memory
while (($check != 0)); do
    echo "$(tput bold)$(tput setaf 1)Speicher ist keine 2er Potenz$(tput sgr0)"
    echo -e "$(tput bold)$(tput setaf 2)Geben Sie den gewünschten Speicher ein:\n(in KB; Die Größe muss eine Zweierpotenz sein)$(tput sgr0)"
    read memory
    check2expn $memory
done
echo Sie haben $memory KB reserviert

#legt die Id für neue Blöcke fest, wird runtergezählt, wenn neuer Block erstellt 
blockCounter=99
lastBlock=0

#Array für Speicherblöcke
arr=(memArr)
#erster "Block" repräsentiert gesamten freien Speicher zu Beginn 
memArr[0]="1|00|$memory"	
	   #1-frei 0-belegt		BlockId		Größe in KB

#Array für Prozesse, die gerade den Speicher belegen, verweist auf einen Speicherblock
arr=(processArr)
#processArr[0]="99|a"


#Auswahl der Realisierungskonzepte
echo
echo $(tput bold)$(tput setaf 2)$(tput smul)Wählen Sie ein Realisierungskozept aus:$(tput sgr0)
echo 
options="First_Fit Best_Fit Next_Fit Random"
select option in $options; do
	# Suche beginnend mit Speicheranfang bis ausreichend großer Block gefunden
	if [ "$option" = "First_Fit" ]; then
		concept="ff"
		break
	# sucht ab dem Anfang des Speicheradressraums Suche kleinsten Block, der ausreicht
	elif [ "$option" = "Best_Fit" ]; then
		concept="bf"
		break
	# Suche beginnend mit der Stelle der letzten Speicherzuweisung
	elif [ "$option" = "Next_Fit" ]; then
		concept="nf"
		break
	# Suche eines zufällig ausgewählten, ausreichend großen Blocks
	elif [ "$option" = "Random" ]; then
		concept="rf"
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

