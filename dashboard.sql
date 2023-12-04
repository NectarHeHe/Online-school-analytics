select 'visitors' AS stage ,COUNT(DISTINCT visitor_id) as all_count
from sessions s 
union
select 'leads' AS stage, count(distinct lead_id) as leads_count
from leads l
union
select 'Purchases' AS stage, count(case when status_id = 142 then 1 else null end) as pokupka_count
from leads l
order by all_count desc


SELECT COUNT(DISTINCT visitor_id) as visitors, TO_CHAR(visit_date, 'YYYY-MM-DD') as date
from sessions
GROUP BY TO_CHAR(visit_date, 'YYYY-MM-DD')


select count(distinct lead_id), TO_CHAR(created_at, 'YYYY-MM-DD')
from leads l 
group by TO_CHAR(created_at, 'YYYY-MM-DD')

select count(case when status_id = 142 then 1 else null end) as pokupka_count, TO_CHAR(created_at, 'YYYY-MM-DD') as date
from leads l 
group by TO_CHAR(created_at, 'YYYY-MM-DD')
order by TO_CHAR(created_at, 'YYYY-MM-DD')


select  "source"  as utm_source, count(distinct visitor_id) as visitors_count 
from sessions s 
group by utm_source
order by  count(visitor_id) desc

	select 
		utm_source as utm_source , 
		sum(daily_spent) as total_daily, 
		to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
	from ya_ads
	where utm_medium <> 'organic'
	group by utm_source, campaign_date
	union all 
	select 
		utm_source as utm_source , 
		sum(daily_spent) as total_daily,
		to_char(campaign_date, 'YYYY-MM-DD') as campaign_date 
	from vk_ads
	group by utm_source, campaign_date
	order by utm_source, campaign_date asc
	
with all_marketing as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_daily,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from ya_ads
    where utm_medium != 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_daily,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from vk_ads
    where utm_medium != 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date
),

last_clicks as (
    select
        s.visitor_id,
        s.medium,
        s.campaign,
        l.lead_id,
        l.status_id,
        l.amount,
        to_char(s.visit_date, 'YYYY-MM-DD') as visit_date,
        lower(s.source) as source,
        row_number()
            over (partition by s.visitor_id order by s.visit_date desc)
        as rn
    from
        sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where
        s.medium != 'organic'
),

tabley as (
    select
        s.visit_date as visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        am.total_daily as total_cost,
        count(s.visitor_id) as visitors_count,
        count(s.lead_id) as leads_count,
        count(case when s.status_id = 142 then 1 end) as purchases_count,
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
        all_marketing as am
        on
            s.source = am.utm_source
            and s.medium = am.utm_medium and s.campaign = am.utm_campaign
            and s.visit_date = am.campaign_date
    group by
        s.visit_date, s.source, s.medium, s.campaign, am.total_daily
    order by
        revenue desc nulls last,
        visit_date asc,
        visitors_count desc,
        utm_source asc,
        utm_medium asc,
        utm_campaign asc
),

supertab as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(visitors_count) as visitors_count,
        sum(total_cost) as total_cost,
        sum(leads_count) as leads_count,
        sum(purchases_count) as purchases_count,
        case when sum(revenue) is null then 0 else sum(revenue) end as revenue
    from tabley
    where
        (utm_source = 'yandex' or utm_source = 'vk') and total_cost is not null
    group by utm_source, utm_medium, utm_campaign
    order by
        revenue desc nulls last,
        visitors_count desc,
        utm_source asc,
        utm_medium asc,
        utm_campaign asc
    limit 26
)

select
    utm_source,
    utm_medium,
    utm_campaign,
    round(total_cost / visitors_count) as cpc,
    round(
        case when leads_count = 0 then '0' else total_cost / leads_count end
    ) as cpl,
    round(
        case
            when purchases_count = 0 then '0' else total_cost / purchases_count
        end
    ) as cppu,
    round((revenue - total_cost) / total_cost * 100, 2) as roi
from supertab


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
		),
tabley as (select 
	 s.visit_date as visit_date,
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
order by revenue desc nulls last, visit_date, visitors_count desc, utm_source, utm_medium, utm_campaign),
supertab as (select 
	 sum(visitors_count) as visitors_count,
	 utm_source,
     sum(total_cost) as total_cost,
     sum(leads_count) as leads_count,
     sum(purchases_count) as purchases_count,
     case when sum(revenue) is null then 0 else sum(revenue) end  as revenue
from tabley 
where (utm_source = 'yandex' or utm_source = 'vk') and total_cost is not null
group by utm_source
order by revenue desc nulls last, visitors_count desc, utm_source)
select 
	 utm_source,
     round(total_cost / visitors_count) as cpc,
     round(case when leads_count = 0 then '0' else total_cost / leads_count end) as cpl,
     round(case when purchases_count = 0 then '0' else total_cost / purchases_count end) as cppu,
     round((revenue - total_cost) / total_cost * 100,2) as roi
from supertab


select sum(revenue) as revenue, sum(total_cost) as total_cost
from supertab
	
