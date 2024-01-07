#!/bin/bash

intro()
{
    echo "This is a FunTrack parser for extracting API calls from functions...!"
    echo "Please provide the path of the file you would like to parse...!"
    echo "Eg:- bash ./funtrack_parse.sh path_to_Funtrack_output_file.txt path_to_parsed_output_file.txt"
    echo "-------------------------------------------------------------------"
}

#------------------------------------------------
file="$1"
output="$2"
malapi="malapi.txt"
malapi_sequencesList="malapi_sequencesList.txt"
temp="temporary_files.txt"
temp2="program_execution_flow.txt"
temp3="api_call_extraction.txt"

if [ -z "$file" ]
then
    clear
    echo "ERROR.... PLEASE PROVIDE FILE PATH"
    echo ""
    echo ""
    intro
    exit
elif [ -z "$output" ]; then
    clear
    echo "ERROR.... PLEASE PROVIDE OUTPUT FILE PATH"
    echo ""
    echo ""
    intro
    exit
else
    intro
    echo "FILE EXISTS"
    echo "Processing......."
fi
#----------------------------------------------------

#installing dependencies...
if ! command -v datamash &> /dev/null
then
    echo "datamash could not be found"
    echo "installing....."
    sudo apt install datamash
fi

#converting windows txt file to unix txt file
awk '{ sub("\r$", ""); print }' $file > $temp

#parsing important data
#patterns: 1) Function call: 2)Returning from call
cat $temp | grep -e "Function call:" -e "Real function called:" | sed -z 's/\n/ /Ig' | sed -z 's/ Function call:/\nFunction call:/Ig' |
 awk 'BEGIN{FS=" ";}
{
    if( (($7) ~ /Real/) )
    {
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$10,$6;
    }
    else
    {
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6;
    }
}
END {}' |
awk 'BEGIN{FS=" ";}
{
    if( (($3) ~ /\+/) )
    {
        sub(/\+.*/,"",$3);
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6;
    }
    else if( (($3) ~ /:loc/) )
    {
        sub(/:loc.*/,"",$3);
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6;
    }
    else
    {
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6;
    }
}
END {}' > $temp2

cat $temp2 | awk 'BEGIN{FS=" ";}
{
    if( !(($5) ~ /sub_/) )
    {
        printf "%s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6;
    }
}
END {}' > $temp

datamash -W groupby 3 collapse 5 < $temp | sed -z 's/\t/::/Ig'> $temp3



#For sequencing API calls
#awk 'FNR==NR {a[$1_$2];next} {for (i in a) if (i~$1) print i" "$2" "$3 }' testing_curl.txt Malicious_Api_call_sequences.txt
awk 'FNR==NR {a[$1];next} {for (i in a) if (i~$1) print i"\t"$2"\t"$3 }' $temp3 $malapi_sequencesList  > $output

#check if file is empty and searching individual malicious apis


echo "Completed... File saved in $output"