usage(){
        echo "USAGE: bash <script-name> <number of days>"
}
args=`echo $#`
if [ $args -eq 1 ]
then
	days=$1
	filename="/tmp/stats_for"$days"days.csv"
	if [ -f $filename ];then
		echo "CSV file exists. Replacing it with the new one"
		sudo rm $filename
	fi
	echo "Enter MySQL's Password"
	mysql -u user -p yourdatabase -e "select ((hour(createdOn) + 5) % 24), round(count(id)/"$days") from table_name where createdOn between date_sub(now(), interval "$days" day) and now() group by hour(createdOn) into outfile '$filename' fields terminated by ',' lines terminated by '\n';"	
	
	echo "Generating graph now..."
	outputFile="stats_for"$days"days.png"
	gnuplot <<- EOF
	reset
	set terminal png
	set output '$outputFile'
	set grid
	set pointsize 2
	set xlabel "Hour"
	set ylabel "Avg number of requests"
	set datafile sep ','
	set key box
	plot '$filename' using 1:2 smooth csplines lw 2 title 'stats of traffic', \
	'$filename' using 1:2 w p title '(Hr, SMS)';
	EOF
else
        usage
fi