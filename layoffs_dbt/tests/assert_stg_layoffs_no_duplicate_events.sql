-- each layoff event (same company, place, date and counts) should appear once,
-- even when it was reported by several sources
select
    company,
    location,
    event_date,
    total_laid_off,
    percentage_laid_off,
    count(*) as n_rows
from {{ ref('stg_layoffs') }}
group by all
having count(*) > 1
