
class GameResults
  def initialize(data)
    @data = data
  end

  def pretty
    out = ""
    out << "Status: #{status}\n"

    return unless ok?

    out << <<-TEXT
New: #{new_avg.round}
Current: #{current_avg.round}
Smart: #{smart_avg.round}
    TEXT
    out
  end

  private

  def lines
    @data.split "\n"
  end

  def ok?
    status == 'OK'
  end

  def status
    lines[0]
  end

  def current_avg
    (player_score(0) + player_score(2)) / 2.0
  end

  def new_avg
    (player_score(5) + player_score(7)) / 2.0
  end

  def smart_avg
    (player_score(1) + player_score(3) + player_score(4) + player_score(6) + player_score(8) + player_score(9)) / 6.0
  end

  def player_score(n)
    lines[n + 2].split[1].to_i
  end
end

data = File.read './local-runner-ru/result.txt'
res = GameResults.new data

puts res.pretty
