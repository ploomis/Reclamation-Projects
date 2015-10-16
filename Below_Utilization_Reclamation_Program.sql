WITH pns AS (
	SELECT
		DISTINCT phone_number,
		account_sid,
		date_created
	FROM phone_numbers
	WHERE inbound = 1 AND active = 1
		AND phone_number IN (SELECT did FROM inventory_dids WHERE status = 3 AND type = 1 AND iso_country = 'US')
),

accts AS (
	SELECT
		DISTINCT sid,
		friendly_name,
		pricing_model_sid,
		CASE
			WHEN parent_account_sid IS NULL THEN sid
			ELSE parent_account_sid
		END as master_account_sid

	FROM accounts

	WHERE
		status = 'ACTIVE'
		AND flag_trial = 0
		AND sid IN (SELECT DISTINCT account_sid FROM pns GROUP BY 1 HAVING count(phone_number) >= 100)
		AND DATEDIFF(day, date_created, CURRENT_DATE) >= 90
),

acct_manager AS (
	SELECT
		DISTINCT account_sid,
		owner_email as acct_manager_email,
		owner_name as acct_manager_name
	FROM (
		SELECT DISTINCT account_sid, created_date, owner_email, owner_name,
		row_number() over (
			partition by account_sid
			order by created_date desc) as rn
		FROM sfdc_contacts m)
	m2
	WHERE m2.rn =1 AND m2.account_sid IN (SELECT master_account_sid FROM accts)
),

pm_pricing AS (
	SELECT
		pricing_model_sid,
		price_per_unit
	FROM billable_item_pricing
	WHERE billable_item_sid = 'BI4f3bd1468a39c80452b81b64b80cf3d6'
		AND pricing_model_sid IN (SELECT pricing_model_sid FROM accts)
		AND trigger_type = 0
),

pns_not_utilized_90_days AS (
	SELECT
		a.sid as account_sid,
		count(DISTINCT p.phone_number) as count_pn_90_days_not_utilized

	FROM pns p JOIN accts a ON p.account_sid = a.sid

	WHERE DATEDIFF(day, p.date_created, CURRENT_DATE) >= 90 AND
		NOT EXISTS (
			SELECT 1
			FROM phone_number_utilization
			WHERE p.phone_number = phone_number
				AND date_created >= CURRENT_DATE - INTERVAL '90 days'
		)

	GROUP BY 1
),

pns_90_days AS (
	SELECT
		a.sid as account_sid,
		count(DISTINCT p.phone_number) as count_pn_90_days
	FROM pns p JOIN accts a ON p.account_sid = a.sid
	WHERE DATEDIFF(day, p.date_created, CURRENT_DATE) >= 90
	GROUP BY 1
),

total_pns AS (
	SELECT
		a.sid as account_sid,
		a.friendly_name,
		a.pricing_model_sid,
		a.master_account_sid,
		count(DISTINCT p.phone_number) as total_count_pn
	FROM pns p JOIN accts a ON p.account_sid = a.sid
	GROUP BY 1,2,3,4
)

SELECT
	tp.account_sid as account_sid,
	tp.friendly_name as account_friendly_name,
	tp.master_account_sid as master_account_sid,
	am.acct_manager_name,
	CASE WHEN pm.price_per_unit IS NULL THEN 1 ELSE pm.price_per_unit END as price_per_unit,
	tp.total_count_pn,
	p9.count_pn_90_days,
	pnu9.count_pn_90_days_not_utilized

FROM total_pns tp LEFT JOIN pns_90_days p9 ON tp.account_sid = p9.account_sid
	LEFT JOIN pns_not_utilized_90_days pnu9 ON tp.account_sid = pnu9.account_sid
	LEFT JOIN pm_pricing pm ON tp.pricing_model_sid = pm.pricing_model_sid
	LEFT JOIN acct_manager am ON tp.master_account_sid = am.account_sid

ORDER BY 6 DESC
