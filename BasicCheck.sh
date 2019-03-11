#!/bin/bash
fail_bit=0
echo "The second argument is: $2"
first_arg=$1
second_arg=$2
shift
shift

#CHECK DIRECTORY FOR Makefile
filename=$(find "$first_arg" -maxdepth 1 -name 'Makefile*' -not -name 'Makefile~') #finds the file, returns an empty string if not found
if [[ $filename != "" ]]; then
	echo "The file: $filename exists"
else
	echo "The file doesn't exist"
	exit $fail_bit
fi

#if file FOUND, then compilation failed
maker=$(make --directory=$first_arg "$@" >/dev/null; echo $?)
if (( maker == 0 ))
then
	compiled="SUCCESS"
else
	compiled="FAILURE"
	fail_bit=$(( $fail_bit + 7 ))
	exit $fail_bit
fi
echo "COMPILATION IS: $compiled"

echo "trying to execute ./main"
./main

#VALGRIND RUN, WILL THROW AN ERROR CODE 55
leak=$(valgrind --leak-check=full --error-exitcode=254 $first_arg$second_arg "$@" >/dev/null; echo $?)
if (( $leak == 254 ));then
	mem_leak="FAIL"
	fail_bit=$(( $fail_bit + 2 ))
else
	mem_leak="SUCCESS"
fi

valgrind --error-exitcode=245 --tool=helgrind $first_arg$second_arg "$@"; return_code=$?;
if (( $return_code == 245 ));then
	thread_leak="FAIL"
	fail_bit=$(( $fail_bit + 1 ))
else
	thread_leak="SUCCESS"
fi

echo "Compilation|Memory leaks|Thread race"
echo "$compiled|$mem_leak|$thread_leak"


exit $fail_bit
