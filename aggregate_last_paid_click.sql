with all_marketing as (
	select 
		utm_source, 
		utm_medium, 
		utm_campaign, 
		sum(daily_spent) as total_daily, 
		to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
	from ya_ads
	where utm_medium <> 'organic'
	group by utm_source, utm_medium, utm_campaign, campaign_date
	union all
	select 
		utm_source, 
		utm_medium, 
		utm_campaign, 
		sum(daily_spent) as total_daily,
		to_char(campaign_date, 'YYYY-MM-DD') as campaign_date 
	from vk_ads
	where utm_medium <> 'organic'
	group by utm_source, utm_medium, utm_campaign, campaign_date
),
last_clicks as (
    select
        to_char(s.visit_date, 'YYYY-MM-DD') as visit_date,
        s.visitor_id,
        lower(s.source) as source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.status_id,
        l.amount,
        row_number() over (partition by s.visitor_id order by s.visit_date desc) as rn
    from
        sessions s
    left join leads l
    	on l.visitor_id = s.visitor_id and s.visit_date <= l.created_at
    where
        s.medium <> 'organic'
		)
select 
	 s.visit_date,
	 count(s.visitor_id) as visitors_count,
	 s.source as utm_source,
     s.medium as utm_medium,
     s.campaign as utm_campaign,
     am.total_daily as total_cost,
     count(s.lead_id) as leads_count,
     count(case when s.status_id = 142 then 1 else null end) as purchases_count,
     sum(s.amount) as revenue
from (
	select 
		lc.visit_date,
        lc.visitor_id,
        lc.source,
        lc.medium,
        lc.campaign,
        lc.lead_id,
        lc.status_id,
        lc.amount
    from
        last_clicks as lc
    where
        rn = 1
   		) as s
    left join
        all_marketing am 
        on am.utm_source = s.source 
        and am.utm_medium = s.medium and am.utm_campaign = s.campaign
        and am.campaign_date = s.visit_date
group by
    s.visit_date, s.source, s.medium, s.campaign, am.total_daily
order by revenue desc nulls last, visit_date, visitors_count desc, utm_source, utm_medium, utm_campaign
limit 15;