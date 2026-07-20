# Source catalog

| Source | Interface | Dataset | Refresh behavior | Ownership |
|---|---|---|---|---|
| SCB | PxWeb API v2 | Stable table `TAB638`, measure `BE0101N1` | Requested year by year | SCB |
| Kolada | REST API v3 | Configured KPI IDs and municipality metadata | Requested KPI by year | RKA/Kolada |
| Valmyndigheten | XLSX or normalized CSV | Official district-level 2022 municipal result | Explicit versioned URL | Valmyndigheten |

Source URLs and selected identifiers are configuration, not hidden constants. A weekly workflow checks the three public contracts without changing repository data. Live payloads are ignored by Git; compact synthetic fixtures keep CI deterministic.

The published Valmyndigheten district-vote workbook does not contain mandates. Live rows therefore store `seats` as `NULL`; the fixture includes synthetic seat counts solely to exercise the optional field. Eligible and valid voter totals repeat for every party and must not be summed across parties.

Before using live KPI values, review the metadata returned by `/kpi/{kpi_id}`. Kolada may revise values without a separate change notification, which is why batch time and selected identifiers are preserved.
