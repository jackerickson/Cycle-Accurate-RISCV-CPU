
rm output_insns.txt &> /dev/null

BIN_PATH=../rv32-benchmarks/individual-instructions
# BIN_PATH=components/individual-instructions
TB_PATH=testbench.v

function run_TB {
    iverilog -g2005 -o `basename $TB_PATH .v` $TB_PATH -I components/
    ./`basename $TB_PATH .v`
}

if [ $# -eq 0 ]; then
    echo    "_________________________________"
    echo -e "|Instruction\t|Pass\t|Fail\t|"
    for file in $BIN_PATH/*.x
    do
        filename=$(basename -- "$file")
        if [ "$filename" != "rv32ui-p-simple.x" ]; then
            #echo "|_______________________________|"
            cat $file > temp.x
            echo "${file##*/}" >> output.txt
            # echo -e -n "|$(echo -n $file | cut -d"-" -f5 | sed 's/\.[^.]*$//')\t\t"
            echo -e -n "|$(echo -n $file | sed -n 's/.*-\(.*\)\..*/\1/p')\t\t"
            PASS_ECALL_ADDR=$(cat $BIN_PATH/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)
            if run_TB | tee -a output.txt | grep -q -i $PASS_ECALL_ADDR; then
                echo -e "|X\t| \t|"
            else
                echo -e "| \t|X\t|"
            fi
        fi

    done
    echo    "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
    rm temp.x

else

    
    for file in $BIN_PATH/*.x
    do
        filename=$(basename -- "$file")
        if [ "$filename" == "rv32ui-p-$1.x" ]; then
            #echo "|_______________________________|"
            cat $file > temp.x
            PASS_ECALL_ADDR=$(cat $BIN_PATH/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)

            

            echo "$1 "
            if run_TB | tee /dev/stderr |  grep -q -i $PASS_ECALL_ADDR; then
                echo -e "$1 Pass\t"
                echo "pass branch $PASS_ECALL_ADDR reached"
            else
                echo -e "$1 Fail\t"
                echo "Test pass branch $PASS_ECALL_ADDR NOT reached"
            fi

        fi
        
    done
    rm temp.x
fi