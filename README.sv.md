# Kommunalt datalager

[English README](README.md)

Ett reproducerbart Analytics Engineering-projekt som integrerar svensk kommunstatistik från SCB, Kolada och Valmyndigheten i ett testat PostgreSQL-baserat datalager.

## Snabbstart

Du behöver Docker Desktop, Docker Compose v2 och Make.

```bash
cp .env.example .env
make demo
make dashboard
```

Öppna därefter [http://localhost:8501](http://localhost:8501). Demokörningen använder versionsstyrda fixtures och gör inga API-anrop. Live-läget använder som standard Valmyndighetens officiella distriktsfil för kommunvalet 2022, separerar parti- och summeringsrader, aggregerar till kommun- och partinivå och körs med `make refresh`. Filen saknar mandatdata, så `seats` är `NULL` i live-läget.

## Vad projektet visar

- Pythonbaserad ingestion med typvalidering, retries, batch lineage och idempotenta laddningar.
- PostgreSQL med fyra lager: `raw`, `staging`, `warehouse` och `analytics`.
- dbt-modeller, tester, dokumentation och SCD Type 2 för kommunhistorik.
- Stjärnschema med befolkning, kommunala nyckeltal och valresultat.
- Avancerad SQL för verkliga kommunfrågor, datakvalitet och jämförelser.
- Index, materialiserade vyer och reproducerbara `EXPLAIN ANALYZE`-mätningar.
- Streamlit-dashboard som endast läser kvalitetssäkrade analytics-modeller.
- GitHub Actions som bygger hela lagret från grunden.

## Datamodell

Facts har olika och explicit dokumenterad granularitet:

- `fact_population`: kommun × år × kön × åldersgrupp.
- `fact_municipal_kpi`: kommun × år × nyckeltal × demografisk variant.
- `fact_election_result`: kommun × valår × parti.

Gemensamma dimensioner gör att data kan analyseras över källgränser utan att blanda mått med olika innebörd. Se [arkitekturen](docs/architecture.md), [ER-diagrammet](docs/erd.md) och [dataordlistan](docs/data_dictionary.md).

## Viktigt om data

Fixture-värdena är kompakta och syntetiska. De finns för reproducerbar CI och ska inte användas för sakpolitiska slutsatser. Live-läget hämtar offentlig data och sparar källmetadata för varje laddning. Licenser och attribuering finns i [NOTICE.md](NOTICE.md).
