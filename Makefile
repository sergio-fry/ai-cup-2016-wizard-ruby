run:
	cd ../local-runner-ru/ && ./local-runner.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 current &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 current

compare:
	cd ../local-runner-ru/ && ./local-runner-console.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 current
	echo "Current `./result.sh`"
	cd ../local-runner-ru/ && ./local-runner-console.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new
	echo "New `./result.sh`"
