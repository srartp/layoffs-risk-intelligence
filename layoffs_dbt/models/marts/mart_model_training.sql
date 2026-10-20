-- one row per labelled event; total_laid_off, percentage_laid_off and is_shutdown are
-- deliberately left out because they define the target
select
    f.event_id,
    f.company,
    -- kept for a time-based train/test split, not as a feature
    f.event_date,
    f.event_year,
    f.event_month,
    f.industry_grouped,
    f.stage_grouped,
    f.country,
    f.funds_raised,
    f.funds_raised_missing,
    f.prior_layoff_count,
    f.days_since_last_layoff,
    f.industry_events_prior_90d,
    e.is_significant_layoff

from {{ ref('int_layoff_features') }} as f
inner join {{ ref('int_layoff_events') }} as e
    on f.event_id = e.event_id

-- events with neither severity signal have no label
where e.is_significant_layoff is not null
