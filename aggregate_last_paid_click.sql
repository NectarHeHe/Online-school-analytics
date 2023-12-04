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
)

select
    s.visit_date,
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
limit 15;
