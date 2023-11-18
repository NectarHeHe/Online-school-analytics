with tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and visit_date < created_at
    order by visitor_id asc, visit_date desc
),
tab_2 as (
    select distinct on (visitor_id) *
    from tab
    where medium != 'organic'
)
select
    visitor_id,
    visit_date,
    source as utm_source,
    medium as utm_medium,
    campaign as utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
from tab_2
order by
    amount desc nulls last,
    visit_date asc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 10