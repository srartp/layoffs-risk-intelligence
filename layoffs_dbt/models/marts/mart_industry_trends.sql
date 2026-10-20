select
    industry_grouped,
    date_trunc('quarter', event_date)::date        as quarter_start,
    count(*)                                       as n_events,
    -- avg ignores nulls, so n_with_percentage shows how many events the average is based on
    avg(percentage_laid_off)                       as avg_percentage_laid_off,
    count(percentage_laid_off)                     as n_with_percentage

from {{ ref('int_layoff_events') }}
group by 1, 2
