# rm output.txt

rm -rf out
mkdir out
mkdir out/vcd
mkdir out/txt
for file in ../rv32-benchmarks/simple-programs/*.x
do
	filename=$(basename -- "$file")
	if [ $filename != "fact.x" ]; then
		echo "$file"
		cat $file > temp.x
		outfile=out/txt/${filename%.*}-output.txt
		iverilog -g2005 -o testbench testbench.v -y components -I components/
		echo "Start: ${file##*/}" >> $outfile
		./testbench >> $outfile
		echo -e "\nEnd:  ${file##*/}" >> $outfile
		mv testbench.vcd out/vcd/${filename%.*}.vcd
	fi
done

rm temp.x

