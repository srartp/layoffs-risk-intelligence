-- fails if any feature uses information from on/after the event date: recomputes the
-- window features with a plain self-join on strictly earlier dates and compares
with features as (

    select * from {{ ref('int_layoff_features') }}

),

events as (

    select event_id, company, industry, event_date from {{ ref('int_layoff_events') }}

),

recount as (

    select
        e.event_id,
        -- strict "<" on dates is the reference definition of "before the event"
        count(distinct c.event_id)                                  as expected_prior_layoff_count,
        max(c.event_date)                                           as expected_last_prior_event_date,
        (
            select count(*)
            from events i
            where i.industry = e.industry
              and i.event_date <  e.event_date
              and i.event_date >= e.event_date - interval 90 day
        )                                                           as expected_industry_events_prior_90d
    from events e
    left join events c
        on c.company = e.company
       and c.event_date < e.event_date
    group by e.event_id, e.industry, e.event_date

)

select
    f.event_id,
    f.event_date,
    f.last_prior_event_date,
    f.days_since_last_layoff,
    f.prior_layoff_count,
    r.expected_prior_layoff_count,
    f.industry_events_prior_90d,
    r.expected_industry_events_prior_90d
from features f
inner join recount r on f.event_id = r.event_id
where f.last_prior_event_date >= f.event_date
   or f.days_since_last_layoff <= 0
   or f.prior_layoff_count != r.expected_prior_layoff_count
   or f.last_prior_event_date is distinct from r.expected_last_prior_event_date
   or f.industry_events_prior_90d != r.expected_industry_events_prior_90d
