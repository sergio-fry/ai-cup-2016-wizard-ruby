new:
	cd ./local-runner-ru/ && ./local-runner.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new

current:
	cd ./local-runner-ru/ && ./local-runner.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 current

compare:
	cd ./local-runner-ru/ && ./local-runner-console.sh &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 current &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 current &
	sleep 1
	ruby runner.rb 127.0.0.1 31003 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31004 0000000000000000 new
	ruby compare_results.rb
