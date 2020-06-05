


if iverilog -g2005 -o `basename $1 .v` $1 -I components/; then
    ./`basename $1 .v`;
fi