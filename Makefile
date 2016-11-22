new:
	java -Xms512m -Xmx2G -server -jar "local-runner.jar" local-runner-modes/render-1.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new

current:
	java -Xms512m -Xmx2G -server -jar "local-runner.jar" local-runner-modes/render-1.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 current

duel:
	java -Xms512m -Xmx2G -server -jar "local-runner.jar" ./local-runner-modes/render-duel.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 current

coop:
	java -Xms512m -Xmx2G -server -jar "local-runner.jar" ./local-runner-modes/render-coop.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 current

battle:
	java -Xms512m -Xmx2G -server -jar "local-runner.jar" ./local-runner-modes/render-battle.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31003 0000000000000000 current &
	sleep 1
	ruby runner.rb 127.0.0.1 31004 0000000000000000 current 


compare:
	java -Xms512m -Xmx1G -server -jar "local-runner.jar" ./local-runner-modes/console-battle.properties &
	sleep 1
	ruby runner.rb 127.0.0.1 31001 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31002 0000000000000000 new &
	sleep 1
	ruby runner.rb 127.0.0.1 31003 0000000000000000 current &
	sleep 1
	ruby runner.rb 127.0.0.1 31004 0000000000000000 current 
	ruby compare_results.rb
