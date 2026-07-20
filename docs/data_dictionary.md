# Data dictionary

## Conformed dimensions

| Model | Key | Important attributes | History |
|---|---|---|---|
| `dim_municipality` | `municipality_key` | code, name, region, valid dates, current flag | SCD Type 2 |
| `dim_region` | `region_key` | region code and name | current source values |
| `dim_time` | `year_key` | year boundaries and Swedish election-year flag | static |
| `dim_demographic` | `demographic_key` | sex and governed age band | static from observations |
| `dim_metric` | `metric_key` | Kolada ID, label, unit, category, additivity | current metadata |
| `dim_party` | `party_key` | normalized code and name | current source values |

## Facts

| Model | Grain | Measures | Additivity |
|---|---|---|---|
| `fact_population` | municipality/year/sex/age band | `population_count` | additive across all dimensions except care across snapshots |
| `fact_municipal_kpi` | municipality/year/metric/demographic variant | `value` | controlled by `dim_metric.additivity` |
| `fact_election_result` | municipality/election year/party | votes, vote share, optional seats | party votes additive; voter totals, share, and seats non-additive across parties |

## KPI definitions

- Population growth rate: `(current population - prior population) / prior population`.
- Growth percentile: `percent_rank` of growth within the same reference year.
- Eldercare cost per resident: Kolada `N20043`, gross cost of eldercare divided by total residents.
- Eldercare satisfaction: Kolada `N00533`, positive responses in SCB's citizen survey; this is public perception, not service-user satisfaction.
- Municipal tax rate: Kolada `N00901`, municipal component of the tax rate.
- Election vote share: party votes divided by valid votes at municipality-election grain.
