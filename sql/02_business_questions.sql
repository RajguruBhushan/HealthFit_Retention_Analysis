-- ============================================================
-- FILE 02: BUSINESS_QUESTIONS.sql
-- PROJECT: DARK PATTERN UX PROJECT
-- DESCRIPTION: 10 core business questions answered via SQL
-- ============================================================

USE UX_PROJECT;

-- -----------------BUSINESS QUESTIONS-----------------

-- Q1 — Did the UX update cause the conversion drop?

SELECT
CASE WHEN session_date < '2024-03-15'
THEN 'Pre-Update' ELSE 'Post-Update' END AS period,
COUNT(DISTINCT s.user_id) AS total_users,
COUNT(DISTINCT sub.user_id) AS converted,
ROUND(100.0 * COUNT(DISTINCT sub.user_id) /
COUNT(DISTINCT s.user_id), 2) AS conversion_rate_pct
FROM sessions s
LEFT JOIN subscriptions sub ON s.user_id = sub.user_id
GROUP BY period;

/*
	ANSWER :
			 Yes, total conversions percentage dropped after the UX update.
             This confirms that the UX redesign directly led to conversion drop!
             
	RECOMMENDATION:
			 Immediately investigate what changed on March 15.
             Rollback the pricing page UI to old version
             till the team investigates the root cause.
*/

-- --------------------------------------------------------

-- Q2 — At which funnel screen do users drop off most?

SELECT
screen_name, funnel_stage, COUNT(DISTINCT(user_id)) total_users_reached,
COUNT(CASE WHEN action_taken = 'dropped' THEN 1 END) users_dropped
FROM sessions
Group BY screen_name, funnel_stage
ORDER BY users_dropped DESC;

/*
	ANSWER:
			 Most users dropped at the Pricing Page screen.
             Most users who reach the Pricing Page leaves without proceeding to Plan Selection!
             This indicated that Pricing Page UI is confusing the users!
	
    RECOMMENDATION:
			 Simplify the Pricing Page layout and make the options more clearer.
             Options must be clearly visible to the users.
*/

-- --------------------------------------------------------

-- Q3. How much revenue was lost?

WITH daily_conv AS (
SELECT session_date,
COUNT(DISTINCT s.user_id) AS visitors,
COUNT(DISTINCT sub.user_id) AS conversions,
1.0 * COUNT(DISTINCT sub.user_id) /
NULLIF(COUNT(DISTINCT s.user_id),0) AS conv_rate
FROM sessions s
LEFT JOIN subscriptions sub ON s.user_id = sub.user_id
GROUP BY session_date
),
pre AS (SELECT AVG(conv_rate) AS r FROM daily_conv WHERE session_date < '2024-03-15'),
post AS (SELECT AVG(conv_rate) AS r FROM daily_conv WHERE session_date >= '2024-03-15')
SELECT
ROUND((pre.r - post.r) * 100, 2) AS conversion_drop_pct,
ROUND((pre.r - post.r) * 500 * 499, 0) AS est_monthly_revenue_lost_inr
FROM pre, post;

/*
	ANSWER:
			 Around 2203 INR monthly revenue was lost!
	
    RECOMMENDATION:
			 Immediately present this revenue amount to the leadership team!
             The revenue loss amount due to a UX problem will get more attention.
*/

-- --------------------------------------------------------

-- Q4. Which device type was most affected?

SELECT u.device_type,
CASE WHEN s.session_date < '2024-03-15' THEN 'pre_update' ELSE 'post_update' END AS period,
COUNT(DISTINCT(sub.user_id)) subscribed_users,
COUNT(DISTINCT(s.user_id)) total_users,
ROUND(100 * COUNT(DISTINCT(sub.user_id))/COUNT(DISTINCT(s.user_id)),2) conversion_rate
FROM users u, sessions s
LEFT JOIN subscriptions sub ON s.user_id = sub.user_id
WHERE u.user_id = s.user_id
GROUP BY u.device_type, period
ORDER BY conversion_rate DESC;

/*
	ANSWER:
			 Web users are affected the most!
             Their conversion rate dropped significantly as compared to Android and iOS.
             This indicates that the cancel/next button is likely hidden below the fold
             on desktop/web screens.
             Mobile layout handeled the change better than the desktop layout.

	RECOMMENDATION:
			 Prioritize fixing the web version of Pricing Page first.
             Ensure all important buttons are visible without scrolling.
             Test on all types of devices before commiting the final update/
*/

-- --------------------------------------------------------

-- Q5. Is the cancel flow a dark pattern?

SELECT
CASE WHEN start_date < '2024-03-15'
THEN 'Pre-update' ELSE 'Post-update' END AS period,
cancellation_reason,
COUNT(*) AS total_cancels,
ROUND(100.0 * COUNT(*) / 
SUM(COUNT(*)) OVER(PARTITION BY
CASE WHEN start_date < '2024-03-15'
THEN 'Pre-Update' ELSE 'Post-Update' END), 1) AS pct
FROM subscriptions
WHERE churn_flag = 1
GROUP BY period, cancellation_reason
ORDER BY total_cancels DESC;

/*
	ANSWER
			 Yes, 'Hard to Cancel' cancellation reason effected the most!
			 About 45 cancelations before update jumps to 251 cancelations after update. Nearly 5X increase!

	RECOMMENDATION:
			 Fix the cancel flow immediately!
             This issue can attract consumer complaints.
             Make the 'Cancel' button clearly visible on all types of devices.
*/

-- --------------------------------------------------------

-- Q6. Which acquisition channel retains best?

SELECT u.acquisition_channel,
COUNT(DISTINCT(s.user_id)) AS total_users,
SUM(s.churn_flag) total_chrurned,
ROUND(100.0 * (1 - AVG(s.churn_flag)), 1) AS retention_rate_pct,
ROUND(AVG(s.churn_flag)*100,2) retention_percent
FROM subscriptions s, users u
WHERE s.user_id = u.user_id
GROUP BY u.acquisition_channel
ORDER BY retention_percent DESC;

/*
	ANSWER:
			 Instagram users churns fastest!
			 Youtube users have the highest retention.
             Youtube brings guininely interested users who stay long-term, shile instagram doesn't.

	RECOMMENDATION:
			 As the lifetime value of a YouTube acquired users is the longest among all channels,
             switch the marketting budget to youtbe.
             For the youtube users who visited but did not convert, run the YouTube specific advertisements.
*/

-- --------------------------------------------------------

-- Q7.  Does time on Pricing Page predict conversion or signal confusion?

SELECT
CASE
	WHEN s.time_spent_seconds < 30 THEN '<30s'
	WHEN s.time_spent_seconds < 60 THEN '30s-60s'
	WHEN s.time_spent_seconds < 90 THEN '60s-90s'
ELSE '90+s'
END time_spent_range,
		CASE WHEN s.session_date < '2024-03-15'
		THEN 'pre-update' ELSE 'post-update' END period,
COUNT(DISTINCT s.user_id) total_users,
COUNT(DISTINCT sub.user_id) total_converted
FROM sessions s LEFT JOIN subscriptions sub ON s.user_id = sub.user_id
WHERE screen_name = 'Pricing Page'
GROUP BY time_spent_range, period;

/*
	ANSWER:
			 Post-Update users spend more time on Pricing Page, but converts less.
			 This indicates that the users are getting confused on Pricing Page and finally not getting converted.
			 Spending more time should mean the page is interesting. But users are getting confused and stucked on same page!
    
    RECOMMENDATION:
			Re-design the Pricing Page and make it clear for users.
            Remove the unnecessary text/animations from the screen.
            Show the plan comparison in a 3-column table (Monthly/Quarterly/Yearly).
            Add a FAQ section, so the users may ask the questions if stuck.
            These chenges will lead to more conversions along with more time spent on the screen.
*/
-- --------------------------------------------------------

-- Q8. Which plan type do churned users prefer, and does it shift post-update?

SELECT s.plan_type,
CASE WHEN s.start_date < '2024-03-15' THEN 'pre-update' ELSE 'post-update' END period,
COUNT(DISTINCT s.user_id) total_users
FROM subscriptions s
WHERE s.churn_flag = 1
GROUP BY s.plan_type, period
ORDER BY total_users DESC;

/*
	ANSWER:
			 Churned users usually prefers the Monthly @499 plan durinf pre-update as well as post-update!
             Users who forcefully subscribed due to the confusing Pricing Page tends to buy the cheapest plan.
             Annual subscribers users are the least

	RECOMMENDATION:
			 Offer small discounts on Quarterly and Annual plans, so that users may attract towards those plans.
             Highlight Annual plan as 'Best Value' plan on Pricing Page.
			 Offer one month free trial for the Annual plans, so that users will get more attract.
*/

-- --------------------------------------------------------

-- Q9. Are repeat visitors more or less likely to convert after the UX change?

WITH visit_count AS (
		SELECT s.user_id, COUNT(*) total_sessions,
        MIN(session_date) first_visit,
		CASE WHEN MIN(s.session_date) < '2024-03-15' THEN 'pre-update' ELSE 'post-update' END period
		FROM sessions s
		GROUP BY user_id
	),
	classify AS (
		SELECT v.user_id, v.period,
		CASE WHEN total_sessions = 1 THEN 'Single Visitor' ELSE 'Repeat Visitor' END visitor_type
		FROM visit_count v
	)
	SELECT c.period, c.visitor_type,
	COUNT(DISTINCT c.user_id) total_users,
	COUNT(DISTINCT s.user_id) converted_users,
	ROUND(100.0 * COUNT(DISTINCT s.user_id) /
	COUNT(DISTINCT c.user_id), 2) AS conversion_rate_percent
	FROM classify c LEFT JOIN subscriptions s ON c.user_id = s.user_id
    GROUP BY c.period, c.visitor_type
    ORDER BY c.period, c.visitor_type;

/*
	ANSWER:
			 Repeat visitors jumped sightly from 44.52% to 45.34% Post-Update!
             Single visitors dropped sharply from 55.56% to 32.73% Post-Update!
             Single visitors(First time visitors) were hit the hardest by the new UX design!
             New users could not understand the new Pricing Page on their first visit and hence they left without subscribing!
             Even the Repeat visitors(Regular users) are not able to navigate the new UX changed Pricing Page.

	RECOMMENDATION:
			 First impression matters the most.
             Optimize the Pricing Page for first time visitors.
             Add some social proofs/numbers against each plan(eg. "1000+ users already buyed this plan.")
             Show all the comparisons for each plans.
             Dont involve any hidden steps, make a one-click plan selection step only.
*/

-- --------------------------------------------------------

-- Q10. Is the conversion difference statistically significant?

SELECT a.variant, count(DISTINCT a.user_id) total_users, SUM(a.converted) total_converted,
    ROUND(100.0 * SUM(converted) / COUNT(DISTINCT user_id), 1) AS conversion_rate_pct
FROM ab_test a
GROUP BY a.variant;

/*
	ANSWER:
			 ab_test table is roughly split 50/50 between variant A and variant B.
			 Variant A conversion rate ~22%.
             Variant B conversion rate ~12%.
             This ~10% gap shows that the new update is the reason for less conversion!

	RECOMMENDATION:
			 Always perform A/B test before deploying the Pricing Page change now onwards.
             Also perform A/B test for any other updates too, so that users will not get frustated!
*/


-- Q11 — Which A/B variant retains subscribers longer?

SELECT
    ab.variant,
    COUNT(DISTINCT ab.user_id) AS total_tested,
    SUM(ab.converted) AS total_converted,
    ROUND(100.0 * SUM(ab.converted) / COUNT(DISTINCT ab.user_id), 1) AS conversion_rate_pct,
    SUM(CASE WHEN ab.converted = 1 THEN sub.churn_flag ELSE 0 END) AS churned_among_converted,
    ROUND(100.0 * SUM(CASE WHEN ab.converted = 1 THEN sub.churn_flag ELSE 0 END)
          / NULLIF(SUM(ab.converted), 0), 1) AS churn_rate_pct_of_converted,
    ROUND(AVG(ab.time_on_page_seconds), 1) AS avg_time_on_page_sec
FROM ab_test ab
LEFT JOIN subscriptions sub
       ON ab.user_id = sub.user_id
      AND sub.start_date >= ab.assigned_date
GROUP BY ab.variant
ORDER BY ab.variant;

/*
	ANSWER:
			 Variant A → 845 tested | 191 converted | Conversion rate: 22.6% | Churned among converted: 20/191 (10.5%) | Avg time: 49.5s
             Variant B → 871 tested |  103 converted | Conversion rate: 11.8% | Churned among converted: 10/103 (9.7%) | Avg time: 57.4s
             Variant B users spends about 8 seconds more than variant A users, still convert less! This is a sign of users getting confused!

	RECOMMENDATION:
			Don't deploy variant B for all the users. As the Pricing Page update is confusing, many users may leave without converting.
            Roll back to variant A immediately, perform A/B test multiple times with different scenarios before commiting variant B,
            if all scenarios gets passed, then only deploy variant B.
/*

================================================================================================================================================