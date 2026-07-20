# Entity relationship diagram

```mermaid
erDiagram
    DIM_REGION ||--o{ DIM_MUNICIPALITY : contains
    DIM_MUNICIPALITY ||--o{ FACT_POPULATION : describes
    DIM_TIME ||--o{ FACT_POPULATION : dates
    DIM_DEMOGRAPHIC ||--o{ FACT_POPULATION : segments
    DIM_MUNICIPALITY ||--o{ FACT_MUNICIPAL_KPI : describes
    DIM_TIME ||--o{ FACT_MUNICIPAL_KPI : dates
    DIM_METRIC ||--o{ FACT_MUNICIPAL_KPI : defines
    DIM_DEMOGRAPHIC ||--o{ FACT_MUNICIPAL_KPI : segments
    DIM_MUNICIPALITY ||--o{ FACT_ELECTION_RESULT : describes
    DIM_TIME ||--o{ FACT_ELECTION_RESULT : dates
    DIM_PARTY ||--o{ FACT_ELECTION_RESULT : receives
```

Surrogate keys are 32-character deterministic hashes. Natural identifiers such as SCB municipality code and Kolada KPI ID remain visible for lineage and interoperability.

