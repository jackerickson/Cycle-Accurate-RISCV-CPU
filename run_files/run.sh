

if [ $# -eq 0 ]; then
    if iverilog -g2005 -o testbench testbench.v -y  components -I components; then
        ./testbench
    fi
else

    if iverilog -g2005 -o `basename $1 .v` $1 -y components -I components; then
        ./`basename $1 .v`
    fi
fi