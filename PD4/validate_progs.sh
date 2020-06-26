

BIN_PATH=../rv32-benchmarks/simple-programs
TB_PATH=testbench.v

function run_TB {
    iverilog -g2005 -o `basename $TB_PATH .v` $TB_PATH -I components/
    ./`basename $TB_PATH .v`
}

if [ $# -eq 0 ]; then
    rm prog_output.txt &>/dev/null
    echo    "_________________________________"
    echo -e "|Instruction\t|Pass\t|Fail\t|"
    for file in $BIN_PATH/*.x
    do
        filename=$(basename -- "$file")
        if [ $filename != "fact.x" ] && [ $filename != "gcd.x" ]; then
            #echo "|_______________________________|"
            cat $file > temp.x
            echo "${file##*/}" >> prog_output.txt

            # echo -e -n "|$(echo -n ${file##*/} | cut -d"-" -f4 | sed 's/\.[^.]*$//')\t"

            echo -e -n "|$(echo -n $filename | sed -n 's/\(.*\)\.x/\1/p')\t"

            if [[ ${#filename} -le 6 ]]; then 
                echo -n -e "\t"
            fi

            PASS_ECALL_ADDR=$(cat $BIN_PATH/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)
            if run_TB | tee -a prog_output.txt | grep -q -i $PASS_ECALL_ADDR; then
                echo -e "|X\t| \t|"
            else
                echo -e "| \t|X\t|"
            fi
        
        fi
        

    done
    echo    "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
    

else

    
    for file in $BIN_PATH/*.x
    do
        filename=$(basename -- "$file")
        if [ "$filename" == "$1.x" ]; then
            #echo "|_______________________________|"
            cat $file > temp.x
            PASS_ECALL_ADDR=$(cat $BIN_PATH/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)

            

            echo "$1 "
            if run_TB | tee /dev/stderr |  grep -q -i $PASS_ECALL_ADDR; then
                echo -e "\n$1 Pass\t"
                echo "pass branch $PASS_ECALL_ADDR reached"
            else
                echo -e "\n$1 Fail\t"
                echo "Test pass branch $PASS_ECALL_ADDR NOT reached"
            fi

        fi

    done
fi
rm temp.x &> /dev/null