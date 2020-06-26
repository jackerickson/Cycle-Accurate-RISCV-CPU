
if [ $# -eq 0 ]; then
    if iverilog -g2005 -o testbench testbench.v -I components/; then
        ./testbench
    fi
else

    if iverilog -g2005 -o `basename $1 .v` $1 -I components/; then
        ./`basename $1 .v`
    fi
fi