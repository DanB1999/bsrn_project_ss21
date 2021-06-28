#!/bin/bash

#prüft, ob die Eingabe ein Zweierexponent ist 
function check2expn() {
	re='^[0-9]+$'
	if [[ $1 = "" ]]; then
		echo "$(tput bold)$(tput setaf 1)Fehler: Eingabe erwartet!$(tput sgr0)"
		check=1
		return
	elif ! [[ $1 =~ $re ]]; then
		echo "$(tput bold)$(tput setaf 1)Fehler: Eingabe ist keine Zahl!$(tput sgr0)"
		check=1
		return
	fi
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
			echo "$(tput bold)$(tput setaf 1)Speicher ist keine 2er Potenz$(tput sgr0)"
			break
			return 1
		fi

		# nächstes bit wird überprüft
		n=$((n >> 1))
	done

	if ((w == 1)); then
		#setzt "check" auf true, wenn n 2er-Potenz ist
		check=0
	fi
}

#verweist auf die jeweiligen Funktionen des gewählten Realisierungskonzeptes | Fehlerbehandlung
function createProcess() {
	#dursucht Prozess-Array nach existierenden Prozessen 
	exists=false
	for process in ${!processArr[*]}; do
		if [[ $1 == ${processArr[$process]:3} ]]; then
			exists=true
			echo "$(tput bold)$(tput setaf 1)Fehler: Prozess $1 existiert schon!$(tput sgr0)"
		fi
	done
	
	if [ $exists != "true" ]; then				#wenn der zu erstellenden Prozess noch nicht exstiert
		re='^[0-9]+$'
		if [[ $2 != "" ]]; then					#wenn zweites Argument vorhanden
			if [[ $2 =~ $re ]]; then			#wenn Speichergröße eine Zahl ist 
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
			else
				echo "$(tput bold)$(tput setaf 1)Fehler: Speichergröße ist keine Zahl!$(tput sgr0)"
			fi
		else
			echo "$(tput bold)$(tput setaf 1)Fehler: 2. Argument nicht vorhanden!$(tput sgr0)"
		fi
	fi
}

#zufällige Zuweisung der Prozesse 
function randomFit {
	diff=-1
	while [ $allocated -eq 0 ]; do
		randomBlock=${memArr[$RANDOM % ${#memArr[@]}]}
		if [ ${randomBlock:0:1} -eq 1 ] && [ ${randomBlock:5} -ge $2 ]; then
			diff=$((${randomBlock:5} - $2))
			blockId=${randomBlock:2:2}
			blockCounter=$(($blockCounter - 1))

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

#findet den nöchsten freien Speicherblock nach dem letzten Prozess
function nextFit()	{
	for index in ${!memArr[*]}; do
		found=0
		diff=-1
		if [ ${#processArr[*]} -ne 0 ]; then 	#falls bereits Prozesse existieren
			#speichert Index von letztem Prozess
			if [[ ${processArr[$((${#processArr[*]}-1))]:0:2} -eq ${memArr[$index]:2:2} ]]; then
				ProcessIndex=$index
			fi
			#dursucht Array ab letztem Prozess
			if [ $index -ne 0 ] && [ $index -gt $ProcessIndex ]; then
				if [ ${memArr[$index]:5} -ge $2 ] && [ ${memArr[$index]:0:1} -eq 1 ]; then
					splitBlock ${memArr[$index]:2:2} $2 $blockCounter
					found=1
					diff=0
					if [ ${memArr[$index]:5} -gt $2 ]; then
						processArr[${#processArr[*]}]="$blockCounter|$1"
					elif [ ${memArr[$index]:5} -eq $2 ]; then
						processArr[${#processArr[*]}]="${memArr[$index]:2:2}|$1"
					fi
					break
				fi			
			fi
		else									#noch keine Prozesse vorhanden
			if [ ${memArr[$index]:5} -ge $2 ] && [ ${memArr[$index]:0:1} -eq 1 ]; then
				splitBlock ${memArr[$index]:2:2} $2 $blockCounter
				found=1
				diff=0
				if [ ${memArr[$index]:5} -gt $2 ]; then
					processArr[${#processArr[*]}]="$blockCounter|$1"
				elif [ ${memArr[$index]:5} -eq $2 ]; then
					processArr[${#processArr[*]}]="${memArr[$index]:2:2}|$1"
				fi
				break
			fi		
		fi
	done
	#Durchsucht das Array von "vorne", falls kein passender Block hinter letztem Prozess gefunden wurde
	if [ $found -ne 1 ]; then
		for index2 in ${!memArr[*]}; do
			if [ $index2 -lt $ProcessIndex ]; then
				if [ ${memArr[$index2]:5} -ge $2 ] && [ ${memArr[$index2]:0:1} -eq 1 ]; then
					echo ${memArr[$index2]:2:2} $2 $blockCounter
					splitBlock ${memArr[$index2]:2:2} $2 $blockCounter
					diff=0
					if [ ${memArr[$index2]:5} -gt $2 ]; then
						processArr[${#processArr[*]}]="$blockCounter|$1"
					elif [ ${memArr[$index2]:5} -eq $2 ]; then
						processArr[${#processArr[*]}]="${memArr[$index2]:2:2}|$1"
					fi
					break
				fi
			fi
		done
	fi 
	if [ $diff -lt 0 ]; then
		echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"
	fi
	blockCounter=$(($blockCounter - 1))
	showMemoryUsage

}

#weist den ersten freien Block im Speicher dem Prozess zu
function firstFit() {
	diff=-1
	for block in ${memArr[*]}; do
		#durchsucht memArr und weist Prozess dem ersten freien Block zu
		if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then
			blockCounter=$(($blockCounter - 1))
			splitBlock ${block:2:2} $2 $blockCounter
			diff=0

			if [ ${block:5} -gt $2 ]; then
				processArr[${#processArr[*]}]="$blockCounter|$1"
				break
			elif [ ${block:5} -eq $2 ]; then
				processArr[${#processArr[*]}]="${block:2:2}|$1"
				break
			fi
		fi
	done
	if [ $diff -lt 0 ]; then
		echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"
	fi
	showMemoryUsage
}

#findet den freien Block mit der geringsten Speicher-Differenz zum Prozess
function bestFit() {
	diff=-1 		#diff bleibt '-1' wenn kein ausreichend großer, freier Block gefunden wird
	
	#dursucht Array nach erstem freien Block mit entsprechender Differenz von Block und Prozess
	for block in ${memArr[*]}; do
		if [ ${block:0:1} -eq 1 ] && [ ${block:5} -ge $2 ]; then
			diff=$((${block:5} - $2))
			blockId=${block:2:2}
			break
		fi
	done
	
	#vergleicht alle Differenzen mit erster Differenz , wenn kleiner, dann wird diese überschrieben
	for process in ${memArr[*]}; do
		if [ ${process:0:1} -eq 1 ] && [ ${process:5} -ge $2 ]; then
			if [ $((${process:5} - $2)) -lt $diff ]; then
				diff=$((${process:5} - $2))
				blockId=${process:2:2}
			fi
		else
			continue
		fi
	done
	blockCounter=$(($blockCounter - 1))

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
function putTogetherFreeBlocks() {
	zaehler1=0
	zaehler2=0
	sum=0
	for index in ${!memArr[*]}; do

		if [ ${memArr[$index]:2:2} -eq $1 ] && [ ${memArr[$index]:0:1} -eq 1 ]; then
			if [ $index -gt 0 ]; then
				
				#Block hinter gelöschtem Prozess ist frei
				if [ ${memArr[$(($index - 1))]:0:1} -eq 1 ]; then
					
					# und Block vor gelöschtem Prozess ist frei
					if [ ${memArr[$(($index + 1))]:0:1} -eq 1 ]; then
						zaehler1=$index
						sum=$((${memArr[$(($index - 1))]:5} + ${memArr[$index]:5} + ${memArr[$(($index + 1))]:5}))
						memArr[$(($index - 1))]="1|$1|$sum"

					else
						zaehler2=$index
						sum=$((${memArr[$(($index - 1))]:5} + ${memArr[$(($index))]:5}))
						memArr[$(($index - 1))]="1|$1|$sum"
					fi
					
				#nur Block vor gelöschtem Prozess ist frei
				elif [ ${memArr[$(($index + 1))]:0:1} -eq 1 ] && [ ${memArr[$(($index - 1))]:0:1} -ne 1 ]; then
					zaehler2=$(($index + 1))
					sum=$((${memArr[$index]:5} + ${memArr[$(($index + 1))]:5}))
					memArr[$index]="1|$1|$sum"
				fi
				
			#Block vor gelöschtem Prozess ist frei, da er der erste im memArr ist
			elif [ ${memArr[$(($index + 1))]:0:1} -eq 1 ]; then
				zaehler2=$(($index + 1))
				sum=$((${memArr[$index]:5} + ${memArr[$(($index + 1))]:5}))
				memArr[$index]="1|$1|$sum"
			fi
		fi
		
		#Verschiebung des memArr entweder um eine oder um zwei Stellen
		if [ $zaehler1 -ne 0 ] && [ $zaehler1 -lt $((${#memArr[*]} - 2)) ]; then
			memArr[$zaehler1]=${memArr[$(($zaehler1 + 2))]}
			zaehler1=$(($zaehler1 + 1))
		elif [ $zaehler2 -ne 0 ] && [ $zaehler2 -lt $((${#memArr[*]} - 1)) ]; then
			memArr[$zaehler2]=${memArr[$(($zaehler2 + 1))]}
			zaehler2=$(($zaehler2 + 1))
		else
			continue
		fi
	done
	#Löschen des/der letzten Einträgs/e, da das Array "verkleinert wurde"
	if [ $zaehler1 -ne 0 ]; then
		unset 'memArr[$((${#memArr[*]}-1))]'
		unset 'memArr[$((${#memArr[*]}-1))]'
	elif [ $zaehler2 -ne 0 ]; then
		unset 'memArr[$((${#memArr[*]}-1))]'
	fi

}

#löscht Eintrag aus Prozess-Array, setzt entspr. Block auf FREI
function deleteProcess() {
	counter5=-1
	
	for process in ${!processArr[*]}; do
		
		#sucht einsprechenden Eintrag im Prozess-Array
		if [[ "${processArr[$process]:3}" == "$1" ]]; then
			for block in ${!memArr[*]}; do
				
				#Zuweisung zu entsprechendem Eintrag im Block-Array
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
		
		#Verschiebung des Prozess-Array ab der Stelle des gelöschten Prozesses um 1 nach hinten 
		if [ $counter5 -ne -1 ] && [ $counter5 -lt $((${#processArr[*]} - 1)) ]; then
			processArr[$counter5]=${processArr[$(($counter5 + 1))]}
			counter5=$(($counter5 + 1))

		fi
	done
	
	#Löschen des letzten Eintrags im Prozess-Array 
	if [ $counter5 -ne -1 ]; then
		if [ $counter5 -lt $((${#processArr[*]} - 1)) ]; then
			unset 'processArr[$((${#processArr[*]}-1))]'
		else
			unset 'processArr[$counter5]'
		fi
		showMemoryUsage $index10
	else
		echo "$(tput bold)$(tput setaf 1)Fehler: Prozess $1 existiert nicht $(tput sgr0)"
	fi

}

#belegt freien Block mit Prozess: Übergabeparameter: $BlockId $Prozessgröße $neue BlockId
function splitBlock() {
	counter=0
	for index in ${!memArr[*]}; do
		if [ ${memArr[$index]:2:2} -eq $1 ]; then
			
			#Blockspeicher größer als Prozessspeicher, entspr. Differenz wird in neuen Block gefasst
			if [ ${memArr[$index]:5} -gt $2 ]; then
				counter=${#memArr[*]}
				for index2 in ${!memArr[*]}; do
					if [ $index2 -gt $index ] && [ $counter -ne $(($index + 1)) ]; then
						memArr[$counter]=${memArr[$(($counter - 1))]}
						counter=$(($counter - 1))
					fi
				done
				diffr=$((${memArr[$index]:5} - $2))
				memArr[$(($index + 1))]="1|$1|$diffr"
				memArr[$index]="0|$3|$2"
				echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
				break
				
			#Blockspeicher gleich Prozessspeicher, bestehender Block wird nur überschrieben
			elif [ ${memArr[$index]:5} -eq $2 ]; then
				memArr[$index]="0|$1|$2"
				echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
				break
			
			else
				echo "$(tput bold)$(tput setaf 1)Fehler: Kein ausreichend großer freier Block vorhanden!$(tput sgr0)"
			fi
		else
			continue
		fi
	done
}

#verknüpft Block-Array mit Prozess-Array und gibt belegte/freie Blöcke aus
function showMemoryUsage() {
	for block in ${!memArr[*]}; do
		
		#alle belegten Blöcke werden angesprochen
		if [ ${memArr[$block]:0:1} -eq 0 ]; then
			for process in ${!processArr[*]}; do
				if [ ${memArr[$block]:2:2} -eq ${processArr[$process]:0:2} ]; then
					if [ $process -ne $((${#processArr[*]} - 1)) ]; then
						echo -e "\033[47mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m"
					elif [[ $1 == "" ]]; then
						echo -e "\033[47;1mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m"
					else
						echo -e "\033[47mbelegt: ${processArr[$process]:3}\t${memArr[$block]:5} KB \033[0m"
					fi
				fi
				#echo §process ${processArr[$process]}

			done
			
		#deleteProcess() gibt bei Aufruf von showMemory Usage die BlockId des gelöschten Prozesses mit, 
		#sodass diese in der Ausgabe angezeigt werden kann
		elif [[ $1 != "" ]]; then
			if [ ${memArr[$block]:2:2} -eq $1 ]; then
				echo -e "\033[1mfrei:\t---\t${memArr[$block]:5} KB \033[0m"
			else
				echo -e "frei:\t---\t${memArr[$block]:5} KB"
			fi
		else
			echo -e "frei:\t---\t${memArr[$block]:5} KB"
		fi
	done
}

#liest Block-Array aus, um Inforamtionen zum Grad d. externen Fragementierung, etc auszugeben
function showInfo() {
	# 100/1024 = ca. 10%
	sum=0
	free=0
	belegt=0
	gIndex=0
	for index in ${!memArr[*]}; do
		if [ ${memArr[$index]:0:1} -eq 1 ]; then
			free=$(($free + 1)) 					#addiert die Anzahl der freien Blöcke
			
			if [ $index -ne $((${#memArr[*]} - 1)) ]; then
				sum=$(($sum + ${memArr[$index]:5}))	#summiert den Speicher der freien Blöcke, ohne den letzten Block
			fi
			if [ ${memArr[$index]:5} -gt ${memArr[$gIndex]:5} ]; then
				gIndex=$index						#Index des freien Blocks mit dem größten Speicher
			fi
		elif [ ${memArr[$index]:0:1} -eq 0 ]; then
			belegt=$(($belegt + 1))					#addiert die Anzahl der belegten Blöcke
		fi
	done
	
	#kleinster Block ist zu Beginn gleich groß wie der größte Block
	sIndex=$gIndex					
	for index2 in ${!memArr[*]}; do
		
		#wenn entsprechender Block kleiner als der kleinste Block zuvor, dann neuer kleinster Block
		if [ ${memArr[$index2]:0:1} -eq 1 ] && [ ${memArr[$index2]:5} -lt ${memArr[$sIndex]:5} ]; then
			sIndex=$index2
		fi
	done

	a=$(python -c "print($sum+0.0)")
	b=$(python -c "print($memory+0.0)")
	result=$(python -c "print(($a/$b)*100.0)") 	#berechnte den Grad der externen Fragmentierung
	echo -e "Realisierungskonzept: $(tput bold)$(tput setaf 4)$option $(tput sgr0)\t\tSpeichergröße: $(tput bold)$(tput setaf 4)$memory KB $(tput sgr0)"
	echo
	echo -e "Grad der externen Fragmentierung:\t\t\t$result %"
	echo -e "Größter/Kleinster freier Speicherblock:\t\t\t${memArr[$gIndex]:5} ${memArr[$sIndex]:5}"
	echo -e "Gesamtzahl belegter/freier Blöcke im Adressraum:\t$belegt $free"
	showMemoryUsage
}

#-----------------------------------------Main-Part------------------------------------------

echo "$(tput bold)$(tput setaf 5)Hallo, das ist ein Simulator zur Visualisierung einer dynamischen Partitionierung!"
echo -e "$(tput bold)$(tput setaf 2)Geben Sie die Größe des gewünschten Speicher ein:\n(in KB; Die Größe muss eine Zweierpotenz sein)$(tput sgr0)"
read memory

#prüft, ob der eingebene Speicher einer Zweierpotenz entspricht
check2expn $memory
while (($check != 0)); do
	read memory
	check2expn $memory
done
echo -e "Sie haben $(tput bold)$(tput setaf 4)$memory KB$(tput sgr0) reserviert"

#legt die Id für neue Blöcke fest, wird runtergezählt, wenn neuer Block erstellt
blockCounter=99

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
		echo "$(tput bold)$(tput setaf 1)Fehler: ungültige Eingabe! Bitte wiederholen:$(tput sgr0)"
	fi
done

#Menü
echo
echo -e "$(tput bold)$(tput setaf 2)$(tput smul)Liste der möglichen Befehle:$(tput sgr0)\t\tRealisierungskonzept: $(tput bold)$(tput setaf 4)$option $(tput sgr0)"
echo
echo -e "Prozess anlegen: \t\t\t$(tput rev)create [Prozessbezeichnung] [Größe in KB]$(tput sgr0)"
echo -e "Prozess beenden: \t\t\t$(tput rev)delete [Prozessbezeichnung] $(tput sgr0)"
echo -e "Informationen zur Speicherbelegung: \t$(tput rev)info $(tput sgr0)"
echo -e "Anwendung beenden: \t\t\t$(tput rev)end $(tput sgr0)"
echo
i=0
while [ $i -eq 0 ]; do
	read command name size
	if [[ $command != "" ]]; then
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
			echo "$(tput bold)$(tput setaf 1)Fehler: Kommando nicht bekannt!$(tput sgr0)"
		fi
	else
		echo "$(tput bold)$(tput setaf 1)Fehler: Eingabe erwartet!$(tput sgr0)"
	fi

done
