# layoffs_dbt

- Run `dbt build` from this folder to build all models and run their tests.
- The models read from and write to `data/layoffs.duckdb`, through the `layoffs_dbt` profile in `~/.dbt/profiles.yml`. Load `raw_layoffs` first with `sql/load_data.sql`.
- Layer order: `raw_layoffs` (source) -> `stg_layoffs` -> `int_layoff_events` -> `int_layoff_features` -> `mart_model_training` / `mart_industry_trends`.
