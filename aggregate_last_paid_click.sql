--- затраты на рекламную кампанию
with last_paid_click as (
    select
        s.visitor_id,
        date(s.visit_date) as visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number() over (
            partition by s.visitor_id
            order by s.visit_date desc
        ) as rn
    from sessions s
    where s.medium != 'organic'  -- вместо перечисления всех платных
),
daily_metrics as (
    select
        lpc.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        count(distinct lpc.visitor_id) as visitors_count,
        count(distinct l.lead_id) as leads_count,
        count(distinct case
            when l.closing_reason = 'Успешно реализовано' or l.status_id = 142
            then l.lead_id
        end) as purchases_count,
        sum(case
            when l.closing_reason = 'Успешно реализовано' or l.status_id = 142
            then l.amount
        end) as revenue
    from last_paid_click lpc
    left join leads l on lpc.visitor_id = l.visitor_id
        and l.created_at >= (select min(s.visit_date)
                           from sessions s
                           where s.visitor_id = lpc.visitor_id
                           and date(s.visit_date) = lpc.visit_date)
    where lpc.rn = 1
    group by
        lpc.visit_date,
        lpc.utm_source, lpc.utm_medium, lpc.utm_campaign
),
ad_costs as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from (
        select campaign_date, utm_source, utm_medium, utm_campaign, daily_spent
        from vk_ads
        union all
        select campaign_date, utm_source, utm_medium, utm_campaign, daily_spent
        from ya_ads
    ) ads
    group by campaign_date, utm_source, utm_medium, utm_campaign
)
select
    dm.visit_date,
    dm.visitors_count,
    dm.utm_source,
    dm.utm_medium,
    dm.utm_campaign,
    coalesce(ac.total_cost, 0) as total_cost,
    dm.leads_count,
    dm.purchases_count,
    dm.revenue
from daily_metrics dm
left join ad_costs ac on dm.visit_date = ac.visit_date
    and dm.utm_source = ac.utm_source
    and dm.utm_medium = ac.utm_medium
    and dm.utm_campaign = ac.utm_campaign
order by
    dm.visit_date asc,
    dm.visitors_count desc,
    dm.utm_source asc,
    dm.utm_medium asc,
    dm.utm_campaign asc,
    dm.revenue desc nulls last
--limit 15;
