
rm output.txt

for file in components/individual-instructions/*.x
do
	cat $file > program.x
	echo "${file##*/}" >> output.txt
	./testbench >> output.txt
	echo "$file"
done

rm program.x

