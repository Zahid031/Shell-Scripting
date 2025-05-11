my_function(){
	local local_var="I am local"
	echo $local_var
}

my_function


add(){
	local sum=$(($1+$2))
	echo $sum
}

add 2 3


fun_even(){
	if (($1%$2==0));then
		return 1
	else
		return 0
	fi
}

fun_even 2


if (( $?==0 )); then
       echo "the number is even"
else 
 echo "the number is odd"
fi


