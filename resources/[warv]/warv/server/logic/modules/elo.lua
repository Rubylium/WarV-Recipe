Elo = {}

function Elo.ExpectedScores (RatA, RatB)
	return 1 / (1 + 10 ^ ((RatB - RatA) / 400)), 1 / (1 + 10 ^ ((RatA - RatB) / 400))
end

function Elo.UpdateRating (Rat, Score, ExpScore)
	local K = 16
	
	if (Rat < 2100) then 		K = 32
	elseif (Rat < 2400) then 	K = 24
	end
	
	return math.floor(Rat + K * (Score - ExpScore))
end

function Elo.NewRating()
	return 1400
end

function Elo.Calculate (RatA, RatB, ScoreA, ScoreB)
	local ExpA, ExpB = Elo.ExpectedScores(RatA, RatB)
	return Elo.UpdateRating(RatA, ScoreA, ExpA), Elo.UpdateRating(RatB, ScoreB, ExpB)
end