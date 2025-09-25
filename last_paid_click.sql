-- запрос для витрины last paid click
with ranked_sessions as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number() over (
            partition by s.visitor_id
            order by s.visit_date desc
        ) as session_rank
    from sessions s
    where s.medium not in ('organic')
)

select
    rs.visitor_id,
    rs.visit_date,
    rs.utm_source,
    rs.utm_medium,
    rs.utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from ranked_sessions as rs
left join leads as l on rs.visitor_id = l.visitor_id
    and l.created_at >= rs.visit_date
where rs.session_rank = 1
order by
    l.amount desc nulls last,
    rs.visit_date asc,
    rs.utm_source asc,
    rs.utm_medium asc,
    rs.utm_campaign asc;
--limit 10
