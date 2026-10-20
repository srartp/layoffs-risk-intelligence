with events as (

    select * from {{ ref('stg_layoffs') }}

),

-- category sizes are computed from the data, so the grouping adapts when new rows arrive
with_category_counts as (

    select
        *,
        count(*) over (partition by industry) as industry_n,
        count(*) over (partition by stage)    as stage_n
    from events

)

select
    event_id,
    company,
    location,
    country,
    industry,
    stage,
    total_laid_off,
    percentage_laid_off,
    funds_raised,
    event_date,
    date_added,
    source_url,

    -- target: 1 if either available signal meets its threshold, 0 if the available
    -- signal(s) are all below it, null when neither signal was reported
    case
        when percentage_laid_off >= 0.20 or total_laid_off >= 100 then 1
        when percentage_laid_off is not null or total_laid_off is not null then 0
    end                                                    as is_significant_layoff,

    -- 100% of staff laid off means the company shut down; unknown when pct is missing
    case
        when percentage_laid_off = 1.0 then 1
        when percentage_laid_off is not null then 0
    end                                                    as is_shutdown,

    -- rare categories (< 50 rows) fold into 'Other'; 'Unknown' is kept as its own signal
    case
        when industry = 'Unknown' then 'Unknown'
        when industry_n < 50 then 'Other'
        else industry
    end                                                    as industry_grouped,

    case
        when stage = 'Unknown' then 'Unknown'
        when stage_n < 50 then 'Other'
        else stage
    end                                                    as stage_grouped,

    -- funds_raised stays null; imputation is left to the modelling code
    case when funds_raised is null then 1 else 0 end       as funds_raised_missing

from with_category_counts
