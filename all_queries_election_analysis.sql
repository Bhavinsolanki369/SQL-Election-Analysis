--** Election Data Analysis using PostgreSQL **--


-----Metric 1. vtr comapresion

SELECT state_2019 AS states,
	ROUND(AVG(vtr_2014),2) AS VTR_2014,
	ROUND(AVG(vtr_2019),2) AS VTR_2019
FROM  pc_total_electors_2019 AS el19
INNER JOIN pc_total_electors_2014 AS el14
ON el19.state_2019 = el14.state_2014
GROUP BY states
ORDER BY states;


----------Metric 2. change in Voter Turnout Ratio

SELECT ROUND(AVG(vtr_2019)/AVG(vtr_2014),2) AS rise
FROM  pc_total_electors_2019 AS el19
INNER JOIN pc_total_electors_2014 AS el14
ON el19.state_2019 = el14.state_2014


---GENDER ANALYSIS
---1. gender composition of 2014 lok sabha
WITH sex_ratio
AS
	(WITH vote_stat
	AS
	(SELECT state_pc,candidate,category,sex, total_votes AS w_votes_2014,
	DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2014)
	SELECT state_pc,candidate,category,sex,w_votes_2014
	FROM vote_stat
	WHERE dense_rank = 1)
SELECT sex, COUNT(*) AS f_participation_2014
FROM sex_ratio
GROUP BY sex

---2. gender composition of 2019 lok sabha
WITH sex_ratio
AS
	(WITH vote_stat
	AS
	(SELECT state_pc,candidate,category,sex, total_votes AS w_votes_2019,
	DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2019)
	SELECT state_pc,candidate,category,sex,w_votes_2019
	FROM vote_stat
	WHERE dense_rank = 1)
SELECT sex, COUNT(*) AS f_participation_2019
FROM sex_ratio
GROUP BY sex


----CATEGORICAL ANALYSIS

----1. Categorical representation in 2014 Lok Sabha
WITH cat_ratio
AS
	(WITH vote_stat
	AS
	(SELECT state_pc,candidate,category,sex, total_votes AS w_votes_2014,
	DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2014)
	SELECT state_pc,candidate,category,sex,w_votes_2014
	FROM vote_stat
	WHERE dense_rank = 1)
SELECT category, COUNT(*) AS SUM
FROM cat_ratio
GROUP BY category


-----2. Categorical representation in 2019 Lok Sabha
WITH cat_ratio
AS
	(WITH vote_stat
	AS
	(SELECT state_pc,candidate,category,sex, total_votes AS w_votes_2019,
	DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2019)
	SELECT state_pc,candidate,category,sex,w_votes_2019
	FROM vote_stat
	WHERE dense_rank = 1)
SELECT category, COUNT(*) AS SUM
FROM cat_ratio
GROUP BY category


---3. Constituencies where saem party is elected consecutively
--    in 2014 and again in 2019
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014,
		DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE dense_rank = 1),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019,
		DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE dense_rank = 1)
SELECT w19.state_pc,w14.party AS wins_2014,w19.party AS wins_2019,
		votes_2019*100/el19.total_votes_2019 AS percent_votes_2019
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party = w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
ORDER BY percent_votes_2019 DESC;


---4. Constituencies where Different party got elected 2014 and in 2019
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014,
		DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE dense_rank = 1),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019,
		DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE dense_rank = 1)
SELECT w19.state_pc,w14.party AS wins_2014,w19.party AS wins_2019,
		votes_2019*100/el19.total_votes_2019 AS percent_votes_2019
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party <> w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
ORDER BY percent_votes_2019 DESC
LIMIT 10;


--5. Top 5 candidates based on margin with runnerup in 2014
WITH rank1
AS
(WITH cte_winner
AS
(SELECT state_pc,candidate, total_votes,
DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
FROM constituency_wise_results_2014)
	SELECT state_pc,candidate, total_votes
	FROM cte_winner
	WHERE dense_rank = 1),
rank2
AS
(WITH cte_runner
AS
(SELECT state_pc,candidate, total_votes,
DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
FROM constituency_wise_results_2014)
	SELECT state_pc,candidate, total_votes
	FROM cte_runner
	WHERE dense_rank = 2)
SELECT rank1.state_pc AS pc_2014,rank1.candidate AS candidate_2014,
	(rank1.total_votes - rank2.total_votes) AS margin_difference_2014
FROM rank1
INNER JOIN rank2
ON rank1.state_pc = rank2.state_pc
ORDER BY margin_difference_2014 ASC
LIMIT 5;


---5. Top 5 candidates based on margin with runnerup in 2019
WITH rank1
AS
(WITH cte_winner
AS
(SELECT state_pc,candidate, total_votes,
DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
FROM constituency_wise_results_2019)
	SELECT state_pc,candidate, total_votes
	FROM cte_winner
	WHERE dense_rank = 1),
rank2
AS
(WITH cte_runner
AS
(SELECT state_pc,candidate, total_votes,
DENSE_RANK() OVER(PARTITION BY state_pc ORDER BY total_votes DESC)
FROM constituency_wise_results_2019)
	SELECT state_pc,candidate, total_votes
	FROM cte_runner
	WHERE dense_rank = 2)
SELECT rank1.state_pc AS pc_2019,rank1.candidate AS candidate_2019,
	(rank1.total_votes - rank2.total_votes) AS margin_difference_2019
FROM rank1
INNER JOIN rank2
ON rank1.state_pc = rank2.state_pc
ORDER BY margin_difference_2019 DESC
LIMIT 5;


--6. PartyWise vote shares 2014 vs 2019
WITH pvote_share_2014
AS
	(SELECT party,
	(SUM(total_votes)*100/(SELECT SUM(total_votes_2014) FROM pc_total_electors_2014))
	AS vote_share_2014
	FROM constituency_wise_results_2014
	GROUP BY party
	ORDER BY vote_share_2014 DESC),
pvote_share_2019
AS
	(SELECT party,
	(SUM(total_votes)*100/(SELECT SUM(total_votes_2019) FROM pc_total_electors_2019))
	AS vote_share_2019
	FROM constituency_wise_results_2019
	GROUP BY party
	ORDER BY vote_share_2019 DESC)
SELECT pv19.party, pv14.vote_share_2014,pv19.vote_share_2019
FROM pvote_share_2019 as pv19
INNER JOIN pvote_share_2014 as pv14
ON pv19.party = pv14.party
LIMIT 10;


---7.1 Top 5 pc where BJP gained vote share
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE party = 'BJP'),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE party = 'BJP')
SELECT w19.state_pc,w14.party,(votes_2014*100/el14.total_votes_2014 -
		votes_2019*100/el19.total_votes_2019) AS percent_rise_vote_share
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party = w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
INNER JOIN pc_total_electors_2014 AS el14
ON w14.state_pc = el14.state_pc_2014
ORDER BY percent_rise_vote_share DESC
LIMIT 5
 

---7.2 Top 5 pc where BJP lost vote share
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE party = 'BJP'),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE party = 'BJP')
SELECT w19.state_pc,w14.party,(votes_2014*100/el14.total_votes_2014 -
		votes_2019*100/el19.total_votes_2019) AS percent_rise_vote_share
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party = w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
INNER JOIN pc_total_electors_2014 AS el14
ON w14.state_pc = el14.state_pc_2014
ORDER BY percent_rise_vote_share ASC
LIMIT 5;


---8.1 Top 5 pc where INC gained vote share
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE party = 'INC'),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE party = 'INC')
SELECT w19.state_pc,w14.party,(votes_2014*100/el14.total_votes_2014 -
		votes_2019*100/el19.total_votes_2019) AS percent_rise_vote_share
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party = w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
INNER JOIN pc_total_electors_2014 AS el14
ON w14.state_pc = el14.state_pc_2014
ORDER BY percent_rise_vote_share DESC
LIMIT 5;


---8.2 Top 5 pc where INC lost vote share
WITH
winners_2014
AS 
	(WITH ranks_2014
	AS
	(SELECT state_pc,party,total_votes AS votes_2014
	FROM constituency_wise_results_2014)
	SELECT state_pc,party,votes_2014
	FROM ranks_2014
	WHERE party = 'INC'),
winners_2019
AS 
	(WITH ranks_2019
	AS
	(SELECT state_pc,party,total_votes AS votes_2019
	FROM constituency_wise_results_2019)
	SELECT state_pc,party,votes_2019
	FROM ranks_2019
	WHERE party = 'INC')
SELECT w19.state_pc,w14.party,(votes_2014*100/el14.total_votes_2014 -
		votes_2019*100/el19.total_votes_2019) AS percent_rise_vote_share
FROM winners_2019 AS w19
INNER JOIN winners_2014 AS w14
ON w14.state_pc = w19.state_pc
AND w14.party = w19.party
INNER JOIN pc_total_electors_2019 AS el19
ON w19.state_pc = el19.state_pc_2019
INNER JOIN pc_total_electors_2014 AS el14
ON w14.state_pc = el14.state_pc_2014
ORDER BY percent_rise_vote_share ASC
LIMIT 5;


-----9.1 Pc which voted most for NOTA in 2014
SELECT state_pc,SUM(total_votes) AS NOTA_votes_2014
FROM fact_table_all_data
WHERE party LIKE 'NOTA' AND year = 2014
GROUP BY state_pc,party
ORDER BY SUM(total_votes) DESC
LIMIT 2;


-----9.2 Pc which voted least for NOTA in 2014
SELECT state_pc, SUM(total_votes) AS NOTA_votes_2014
FROM fact_table_all_data
WHERE party LIKE 'NOTA' AND year = 2014
GROUP BY state_pc,party
ORDER BY SUM(total_votes) ASC
LIMIT 2


-----9.3 Pc which voted most for NOTA in 2019
SELECT state_pc, SUM(total_votes) AS NOTA_votes_2019
FROM fact_table_all_data
WHERE party LIKE 'NOTA' AND year = 2019
GROUP BY state_pc,party
ORDER BY SUM(total_votes) DESC
LIMIT 2


-----9.4 Pc which voted least for NOTA in 2019
SELECT state_pc, SUM(total_votes) AS NOTA_votes_2014
FROM fact_table_all_data
WHERE party LIKE 'NOTA' AND year = 2019
GROUP BY state_pc,party
ORDER BY SUM(total_votes) ASC
LIMIT 2;


-------FURTHER ANALYSIS

---10.1 literacy vs vtr 2014

SELECT state_name,
	ROUND(AVG(literacy_2011),2) AS literacy_2014,
	ROUND(AVG(vtr_2014),2) AS vtr_2014
FROM literacy_table AS literacy
INNER JOIN pc_total_electors_2014 AS el14
ON literacy.state_name = el14.state_2014
GROUP BY state_name
ORDER BY state_name;

---10.2 literacy vs vtr 2019

SELECT state_name,
	ROUND(AVG(literacy_2019),2) AS literacy_2019,
	ROUND(AVG(vtr_2019),2) AS vtr_2019
FROM literacy_table AS literacy
INNER JOIN pc_total_electors_2019 AS el19
ON literacy.state_name = el19.state_2019
GROUP BY state_name
ORDER BY state_name;



