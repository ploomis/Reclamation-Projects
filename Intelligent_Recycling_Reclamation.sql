/*
Create a base query that shows
Buy and Release in of a Phone Number
In recycling with *NO* Utilization
By time held and Recycling time
*/

SELECT
	DISTINCT i.did as "did",
	i.sid as "inv_sid",
	nwk.nku as "nku",
	i.flag_capabilities_sms as "sms_capable",
	i.flag_capabilities_voice as "voice_capable",
	DATEDIFF(day, trunc(i.locked_until - INTERVAL '60 days'),CURRENT_DATE) as "days_in_recycling",
	DATEDIFF(minute, p.date_created, p.date_updated) as "PN_Hold_Time",
	i.phone_number_sid as pn_sid,
	p.account_sid

FROM inventory_dids i
	JOIN phone_numbers p ON i.phone_number_sid = p.sid
	LEFT JOIN numbers_with_nku nwk ON i.did = nwk.friendly_name

WHERE p.active = 0
	AND p.inbound = 1
	AND i.status = 4

	-- Group plans together
	AND (((DATEDIFF(minute, p.date_created, p.date_updated) < 1440 OR p.account_sid = 'AC064fb4f432694a6491973855c4566c49')
		AND DATEDIFF(day, trunc(i.locked_until - INTERVAL '60 days'),CURRENT_DATE) >= 10)
	  OR (DATEDIFF(minute, p.date_created, p.date_updated) < 10080
		AND DATEDIFF(day, trunc(i.locked_until - INTERVAL '60 days'),CURRENT_DATE) >= 30)
	  OR (DATEDIFF(minute, p.date_created, p.date_updated) < 43829
		AND DATEDIFF(day, trunc(i.locked_until - INTERVAL '60 days'),CURRENT_DATE) >= 40)
	  OR (DATEDIFF(minute, p.date_created, p.date_updated) >= 43829
		AND DATEDIFF(day, trunc(i.locked_until - INTERVAL '60 days'),CURRENT_DATE) >= 50))

	-- Select all DIDs That DO NOT appear in Phone Number Utilization Table (SMS & Call)
	AND NOT EXISTS (
	  SELECT 1
	  FROM phone_number_utilization pnu
	  WHERE pnu.phone_number = i.did AND pnu.date_created >= p.date_created::date
	)
