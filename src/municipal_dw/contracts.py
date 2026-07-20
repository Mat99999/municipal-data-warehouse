from __future__ import annotations

from municipal_dw.config import Settings
from municipal_dw.sources.base import HttpSource


def main() -> None:
    settings = Settings()
    checks = [
        (HttpSource(settings.scb_base_url), f"/tables/{settings.scb_table_id}"),
        (HttpSource(settings.kolada_base_url), "/municipality/0180"),
        (
            HttpSource("https://www.val.se"),
            "/valresultat-och-statistik/statistik-och-data/radata-fran-val-2002-2022",
        ),
    ]
    for source, path in checks:
        source.get(path)
        print(f"ok {path}")

    scb = HttpSource(settings.scb_base_url)
    sample = scb.get(
        f"/tables/{settings.scb_table_id}/data",
        params={
            "lang": "sv",
            "valuecodes[Region]": "0180",
            "valuecodes[Alder]": "0,1",
            "valuecodes[Kon]": "1,2",
            "valuecodes[ContentsCode]": "BE0101N1",
            "valuecodes[Tid]": "2024",
            "outputFormat": "json-stat2",
        },
    ).json()
    if len(sample.get("value", [])) != 4:
        raise RuntimeError("SCB sample extraction returned an unexpected shape")
    print("ok SCB sample data")

    kolada = HttpSource(settings.kolada_base_url)
    for kpi_id in settings.csv_values(settings.kolada_kpi_ids):
        payload = kolada.get(f"/kpi/{kpi_id}").json()
        if payload.get("count") != 1:
            raise RuntimeError(f"Kolada KPI is missing or ambiguous: {kpi_id}")
        print(f"ok Kolada KPI {kpi_id}")


if __name__ == "__main__":
    main()
