rm output.txt
for file in simple_programs/*.x
do
	cat $file > program.x
	echo "${file##*/}" >> output.txt
	./Testbench_fetch_decode >> output.txt
	echo "$file"
done

rm program.x

