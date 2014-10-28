function sample = discretesample(probs)

sample = find(cumsum(probs) > rand(), 1);
