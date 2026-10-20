-- leakage rule: every feature only uses events with an event_date strictly before the
-- current row's event_date. RANGE frames on a DATE ending at "1 day preceding" exclude
-- the current row and every other event on the same day (incl. the same company).

with events as (

    select * from {{ ref('int_layoff_events') }}

),

windowed as (

    select
        event_id,
        company,
        event_date,
        industry_grouped,
        stage_grouped,
        country,
        funds_raised,
        funds_raised_missing,

        -- no leak: frame ends the day before event_date, so only the company's earlier events are counted
        count(*) over (
            partition by company
            order by event_date
            range between unbounded preceding and interval 1 day preceding
        )                                              as prior_layoff_count,

        -- no leak: same frame as above, so the latest date it can return is event_date - 1 day
        max(event_date) over (
            partition by company
            order by event_date
            range between unbounded preceding and interval 1 day preceding
        )                                              as last_prior_event_date,

        -- no leak: trailing window [event_date - 90d, event_date - 1d] across the whole industry,
        -- partitioned on the ungrouped industry so 'Other' does not pool unrelated sectors
        count(*) over (
            partition by industry
            order by event_date
            range between interval 90 day preceding and interval 1 day preceding
        )                                              as industry_events_prior_90d,

        extract(year from event_date)                  as event_year,
        extract(month from event_date)                 as event_month

    from events

)

select
    *,
    -- null for a company's first recorded event
    event_date - last_prior_event_date                 as days_since_last_layoff
from windowed
