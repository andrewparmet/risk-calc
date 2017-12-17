function [win_pcts, avg_att_lefts, avg_def_lefts, att_devs, def_devs] = run_risk_a_lot(n_att, n_def, count, enabled, matrices)
  if nargin < 5
    matrices = { get_dynamic_roll_mat();
 		 ones(6, 6) * 2;
		 ones(6, 6) };
  end
  if nargin < 4
    enabled = ones(size(matrices));
  end
  if nargin < 3
    count = 100;
  end

  attack_wins = zeros(size(matrices));
  avg_att_lefts = zeros(size(matrices));
  avg_def_lefts = zeros(size(matrices));
  att_devs = zeros(size(matrices));
  def_devs = zeros(size(matrices));

  for i = 1:size(matrices)(1)
    if enabled(i)
      [att_wins, att_left, def_left] = run_with(n_att, n_def, count, matrices{i});
      attack_wins(i) = att_wins;
      avg_att_lefts(i) = mean(att_left);
      att_devs(i) = std(att_left);
      if size(def_left) ~= 0
	avg_def_lefts(i) = mean(def_left);
	def_devs(i) = std(def_left);
      end
    end
  end

  win_pcts = attack_wins / count;
end

function [attack_wins, remaining_for_attack, remaining_for_defense] = run_with(n_att, n_def, count, mat)
  attack_wins = 0;
  remaining_for_attack = [];
  remaining_for_defense = [];
  for runs = 1:count
    [result, remaining_for_victor] = run_risk(n_att, n_def, mat);
    if result == 1
      attack_wins = attack_wins + 1;
      remaining_for_attack = [remaining_for_attack; remaining_for_victor];
    else
      remaining_for_defense = [remaining_for_defense; remaining_for_victor];
    end
  end
end

function mat = get_dynamic_roll_mat()
  f = fopen('should_roll.txt');
  c = textscan(f, '%d %d %f', 'CollectOutput', 1);
  fclose(f);
  mat = accumarray(c{1}, c{2});
end

function [result, remaining_for_victor] = run_risk(attack_count, defense_count, roll_mat)
  while attack_count > 1 && defense_count > 0
    if attack_count >= 4
      if defense_count >= 2
	[a_diff, d_diff] = battle_vs_2(3, roll_mat);
      else
        [a_diff, d_diff] = battle(3, 1);
      end
    elseif attack_count == 3
      if defense_count >= 2
        [a_diff, d_diff] = battle_vs_2(2, roll_mat);
      else
        [a_diff, d_diff] = battle(2, 1);
      end
    else # attack_count == 2
      if defense_count >= 2
        [a_diff, d_diff] = battle(1, 2);
      else
        [a_diff, b_diff] = battle(1, 1);
      end
    end
    attack_count = attack_count + a_diff;
    defense_count = defense_count + d_diff;
  end

  result = defense_count == 0;
  if defense_count == 0
    remaining_for_victor = attack_count;
  else
    remaining_for_victor = defense_count;
  end
end

function [a_diff, d_diff] = battle(n_att, n_def)
  smaller = min(n_att, n_def);
  att = roll(n_att)(1:smaller);
  def = roll(n_def)(1:smaller);
  [a_diff, d_diff] = fight(att, def);
end

function [a_diff, d_diff] = battle_vs_2(n_att, roll_mat)
  att = roll(n_att)(1:2);
  def_num = roll_mat(att(1), att(2));
  def = roll(def_num);
  [a_diff, d_diff] = fight(att(1:def_num), def);
end

function arr = roll(n)
  assert(n <= 3)
  arr = sort(randi(6, n, 1), 'descend');
end

function [a_diff, d_diff] = fight(att, def)
  assert(size(att) == size(def))
  res = att > def;
  a_diff = 0;
  d_diff = 0;
  for i = 1:size(res)(1)
    if res(i)
      d_diff = d_diff - 1;
    else
      a_diff = a_diff - 1;
    end
  end
end