-- percentage_laid_off is stored as a fraction, so anything outside [0, 1] is bad data
select *
from {{ ref('stg_layoffs') }}
where percentage_laid_off < 0
   or percentage_laid_off > 1
