
rm output.txt




if [ $# -eq 0 ]; then
    echo    "_________________________________"
    echo -e "|Instruction\t|Pass\t|Fail\t|"
    for file in components/individual-instructions/*.x
    do
        filename=$(basename -- "$file")
        if [ "$filename" != "rv32ui-p-simple.x" ]; then
            #echo "|_______________________________|"
            cat $file > program.x
            echo "${file##*/}" >> output.txt
            echo -e -n "|$(echo -n $file | cut -d"-" -f4 | sed 's/\.[^.]*$//')\t\t"
            PASS_ECALL_ADDR=$(cat components/individual-instructions/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)
            if ./run.sh testbench.v | tee -a output.txt | grep -q -i $PASS_ECALL_ADDR; then
                echo -e "|X\t| \t|"
            else
                echo -e "| \t|X\t|"
            fi
            #echo "|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|"
        fi

        #./testbench >> output.txt
    done
    echo    "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
    rm program.x

else

    
    for file in components/individual-instructions/*.x
    do
        filename=$(basename -- "$file")
        if [ "$filename" == "rv32ui-p-$1.x" ]; then
            #echo "|_______________________________|"
            cat $file > program.x
            PASS_ECALL_ADDR=$(cat components/individual-instructions/${filename%.*}.d | grep -o "^........ <pass>" | cut -d" " -f1)

            

            echo -n "$1 "
            if ./run.sh testbench.v | tee /dev/stderr |  grep -q -i $PASS_ECALL_ADDR; then
                echo -e "$1 Pass\t"
                echo "pass branch $PASS_ECALL_ADDR reached"
            else
                echo -e "$1 Fail\t"
                echo "Test pass branch $PASS_ECALL_ADDR NOT reached"
            fi

           
            #echo "|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|"
        fi

        #./testbench >> output.txt
    done
    rm program.x
fi