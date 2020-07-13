rm output.txt


for file in ../rv32-benchmarks/simple-programs/*.x
do
	filename=$(basename -- "$file")
	if [ $filename != "fact.x" ]; then
		cat $file > temp.x
		iverilog -g2005 -o testbench testbench.v -I components/
		echo "Start: ${file##*/}" >> output.txt
		./testbench >> output.txt
		echo -e "\nEnd:  ${file##*/}" >> output.txt
		echo "$file"
	fi
done

rm temp.x

