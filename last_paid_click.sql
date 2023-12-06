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
        on s.visitor_id = l.visitor_id and s.visit_date < l.created_at
    order by s.visitor_id asc, s.visit_date desc
),

tab_2 as (
    select distinct on (visitor_id) *
    from tab
    where medium != 'organic'
)

select
    t2.visitor_id,
    t2.visit_date,
    t2.source as utm_source,
    t2.medium as utm_medium,
    t2.campaign as utm_campaign,
    t2.lead_id,
    t2.created_at,
    t2.amount,
    t2.closing_reason,
    t2.status_id
from tab_2 as t2
order by
    t2.amount desc nulls last,
    t2.visit_date asc,
    t2.utm_source asc,
    t2.utm_medium asc,
    t2.utm_campaign asc
limit 10;
