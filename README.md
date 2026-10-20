# Layoffs Risk Intelligence

Predicts how severe a layoff event is, and provides a grounded Q&A assistant
over layoff news. Built on the Layoffs.fyi dataset.

## Status: In progress

## Stack
DuckDB · dbt · Python · (RAG stack TBD)

## Structure
- `data/`: raw CSV and DuckDB database
- `sql/`: data loading scripts
- `layoffs_dbt/`: dbt project (staging, intermediate and mart models, tests)
- `notebooks/`: exploratory analysis

## Scope
The model predicts whether a recorded layoff event is significant
(`is_significant_layoff`). It does not predict which companies will lay off
next. The dataset contains only companies that had layoffs, so there is no
population of companies that did not.

## Data model
Built with dbt on DuckDB (`dbt build` from `layoffs_dbt/`).

- `raw_layoffs`: the CSV as loaded by `sql/load_data.sql`. One row per source
  record (4,540 rows), and some events appear more than once.
- `stg_layoffs`: cleaned and deduplicated. One row per layoff event (4,535),
  keyed by `event_id`.
- `int_layoff_events`: one row per event, with the target, shutdown flag and
  grouped categories.
- `int_layoff_features`: one row per event, with features built only from
  earlier events.
- `mart_model_training`: one row per labelled event (3,795), with features and
  the target.
- `mart_industry_trends`: one row per grouped industry and quarter, with event
  counts and the average share of staff laid off.

## Data decisions

| Decision | Why | Impact |
|---|---|---|
| `is_significant_layoff` = 1 if `percentage_laid_off >= 0.20` or `total_laid_off >= 100`, 0 if every reported value is below its threshold, null if neither is reported. A row with only one value, below its threshold, is labelled 0. | Neither severity column is complete on its own, and combining them labels far more rows than either alone | 3,795 labelled events: 2,376 positive (62.6%), 1,419 negative (37.4%). 845 of the negatives rest on a single below-threshold value. Thresholds are provisional. |
| Duplicate events (same company, location, date and counts) are collapsed, keeping the earliest-added copy | Some events were re-entered later with another source or updated company details | 5 events, 4,540 rows to 4,535. The copies disagree on `funds_raised` in 3 events and on `stage` in 1. |
| The `, Non-U.S.` suffix is stripped from `location`, and a bare `Non-U.S.` becomes null | The suffix repeats information already in `country` | 1,667 raw rows carry the suffix; 4 had no city and became null |
| Missing `industry` and `stage` become `Unknown`. Categories under 50 rows are grouped into `Other`, and `Unknown` stays separate. | Keeps "not recorded" distinct from the existing `Other` industry, and limits sparse categories | 2 industry and 8 stage values filled. 7 industries and 5 stages grouped into `Other`. |
| `funds_raised` stays null in dbt, with a `funds_raised_missing` flag | Imputation is a modelling choice and belongs with the model code | 537 events (11.8%) flagged |
| Features and the train/test split use `event_date` (when the layoff happened), not `date_added` (when it was recorded) | Features describe the history before each event | Window features count only events on strictly earlier dates, and a dbt test checks this |

## Known limitations
- **No negative examples of companies.** Every company in the data had at
  least one layoff, so the model cannot learn what separates companies that
  cut staff from those that do not.
- **Lag between `event_date` and `date_added`.** The median lag is 1 day and
  the maximum is 1,292 days:
  - 287 rows were added more than 30 days after the event
  - 18 rows were added more than 1 year after the event
  - 36 events were added to the tracker before their event date; cause not
    investigated.

  Two effects follow:
  - `funds_raised` and `stage` reflect the record date, so late rows can carry
    later company details; observed in at least one case, extent not
    measured.
  - Count features include earlier events that had not been recorded yet at
    the time.
- **Threshold bias.** The headcount threshold (100) favors large companies.
- **Partial severity data.** 740 of 4,535 events (16.3%) report neither the
  number nor the share of staff laid off, so they have no label and are
  excluded from training.
