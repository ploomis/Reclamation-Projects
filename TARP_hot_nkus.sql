WITH hot_nkus AS (
	SELECT DISTINCT friendly_name as phone_number, nku
	FROM numbers_with_nku
	WHERE nku IN ('+1205',
				'+1206',
				'+1207',
				'+1212',
				'+1214',
				'+1215',
				'+1228',
				'+1229',
				'+1239',
				'+1250',
				'+1251',
				'+1253',
				'+1256',
				'+1272',
				'+1301',
				'+1303',
				'+1305',
				'+1310',
				'+1334',
				'+1351',
				'+1352',
				'+1360',
				'+1401',
				'+1403',
				'+1404',
				'+1407',
				'+1416',
				'+1418',
				'+1425',
				'+1430',
				'+1431',
				'+1437',
				'+1479',
				'+1501',
				'+1519',
				'+1531',
				'+1534',
				'+1539',
				'+1603',
				'+1610',
				'+1615',
				'+1623',
				'+1628',
				'+1629',
				'+1681',
				'+1703',
				'+1713',
				'+1714',
				'+1718',
				'+1762',
				'+1770',
				'+1773',
				'+1779',
				'+1780',
				'+1787',
				'+1800',
				'+1804',
				'+1808',
				'+1844',
				'+1850',
				'+1854',
				'+1855',
				'+1866',
				'+1870',
				'+1877',
				'+1878',
				'+1888',
				'+1905',
				'+1907',
				'+1910',
				'+1917',
				'+1930',
				'+1938',
				'+1947',
				'+1952',
				'+1959',
				'+2787',
				'+3021',
				'+30231',
				'+30261',
				'+3246',
				'+3491',
				'+3493',
				'+3494',
				'+3498',
				'+35227',
				'+35386',
				'+35722',
				'+3670',
				'+3706',
				'+3725',
				'+40316',
				'+4121',
				'+4122',
				'+4131',
				'+4143',
				'+4161',
				'+417',
				'+4207',
				'+4212',
				'+4367',
				'+447',
				'+44800',
				'+4525',
				'+4541',
				'+4578',
				'+4589',
				'+4640',
				'+467',
				'+468',
				'+475',
				'+4822',
				'+4852',
				'+4858',
				'+4873',
				'+4879',
				'+4881',
				'+49157',
				'+5233',
				'+5255',
				'+5255499',
				'+5281',
				'+5511',
				'+5512',
				'+5513',
				'+5515',
				'+5516',
				'+5517',
				'+5518',
				'+5533',
				'+5535',
				'+5548',
				'+5561',
				'+5562',
				'+5571',
				'+5581',
				'+5585',
				'+5591',
				'+5598',
				'+6124',
				'+6126',
				'+6136',
				'+6138',
				'+6139',
				'+614',
				'+6173',
				'+6174',
				'+6186',
				'+6187',
				'+6189',
				'+6531',
				'+8526')
),

cool_nkus AS (
	SELECT DISTINCT friendly_name as phone_number, nku
	FROM numbers_with_nku
	WHERE NOT EXISTS (SELECT DISTINCT nku FROM hot_nkus)
)

SELECT
	p.phone_number as phone_number,
	p.date_created::date as pn_date_created,
	a.date_created::date as acct_date_created,
	a.sid as acct_sid,
	DATEDIFF(day,a.date_created, CURRENT_DATE) as acct_age,
	DATEDIFF(day,p.date_created, CURRENT_DATE) as pn_age,
	i.flag_capabilities_voice as voice_enabled,
	i.flag_capabilities_sms as sms_enabled

FROM phone_numbers p join accounts a on p.account_sid = a.sid
	LEFT JOIN inventory_dids i ON p.phone_number = i.did

WHERE a.flag_trial = 1
	AND p.active = 1
	AND p.inbound = 1

	-- account age over 90 days
	AND DATEDIFF(day,a.date_created, CURRENT_DATE) >= 75

	AND
	-- Logic to seperate HOT_NKUs versus COOL_NKUs
	((EXISTS (SELECT phone_number FROM hot_nkus)

		-- phone number age over 90 days
		AND DATEDIFF(day,p.date_created, CURRENT_DATE) >= 45
		-- phone number does not have any utilization in the past 90 days
		AND NOT EXISTS
			(SELECT 1
			FROM phone_number_utilization u
			WHERE p.phone_number = u.phone_number AND u.date_created::date >= CURRENT_DATE - INTERVAL '45 days'))

	OR (EXISTS (SELECT phone_number FROM cool_nkus)

		-- phone number age over 90 days
		AND DATEDIFF(day,p.date_created, CURRENT_DATE) >= 75)

		-- phone number does not have any utilization in the past 90 days
		AND NOT EXISTS
			(SELECT 1
			FROM phone_number_utilization u
			WHERE p.phone_number = u.phone_number AND u.date_created::date >= CURRENT_DATE - INTERVAL '75 days'))

	
