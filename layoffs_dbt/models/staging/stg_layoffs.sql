WITH source AS (
    SELECT *
    FROM {{ source('layoffs', 'raw_layoffs') }}
),

cleaned as (

    select
        trim(company)                              as company,
        -- strip the ", Non-U.S." suffix; a bare "Non-U.S." means no city was recorded
        nullif(regexp_replace(trim(location), '(^|,\s*)Non-U\.S\.$', ''), '') as location,
        trim(country)                              as country,
        coalesce(trim(industry), 'Unknown')        as industry,
        coalesce(trim(stage), 'Unknown')           as stage,

        cast(total_laid_off as integer)            as total_laid_off,
        percentage_laid_off,
        funds_raised,

        cast(date as date)                         as event_date,
        date_added,
        source                                     as source_url

    from source

),

-- some events were re-entered later (new source article, updated funds/stage);
-- keep the earliest version so company details reflect what was known at the event
deduplicated as (

    select *
    from cleaned
    qualify row_number() over (
        partition by company, location, event_date, total_laid_off, percentage_laid_off
        order by date_added asc
    ) = 1

)

select
    -- event key: same columns as the dedup partition, so it is unique by construction
    md5(concat_ws('|',
        company,
        coalesce(location, ''),
        event_date,
        coalesce(total_laid_off::varchar, ''),
        coalesce(percentage_laid_off::varchar, '')
    ))                                             as event_id,
    *
from deduplicated
