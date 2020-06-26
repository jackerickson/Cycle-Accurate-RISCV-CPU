


if iverilog -g2005 -o `basename $1 .v` $1; then
    ./`basename $1 .v`;
fi