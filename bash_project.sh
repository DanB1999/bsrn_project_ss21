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
	echo $1 $2
}

function deleteProcess()	{
	echo $1
}

function showMemoryUsage()	{
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
	if [ "$option" = "First_Fit" ]; then
		concept="ff"
		break
	elif [ "$option" = "Best_Fit" ]; then
		concept="bf"
		break
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
		echo $(tput rev)$(tput setaf 2)Created!$(tput sgr0)
		showMemoryUsage
	elif [ $command = "delete" ]; then
		echo 
		echo $(tput rev)$(tput setaf 2)Deleted!$(tput sgr0)
		showMemoryUsage
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

