"""Offline checks that need no cloud login: every dbt model and test renders
(Jinja) and parses as valid BigQuery SQL, and the project's declared
dependencies/tests are internally consistent. This does NOT run the SQL --
that happens with `dbt build` against a real BigQuery project.
"""

import re
from pathlib import Path

import jinja2
import pytest
import sqlglot
import yaml

ROOT = Path(__file__).resolve().parent.parent
SQL_FILES = sorted(list((ROOT / "models").rglob("*.sql")) + list((ROOT / "tests").glob("*.sql")))
VARS = {"as_of_date": None, "health_active_days": 90, "health_cooling_days": 180, "health_at_risk_days": 365}




def render_with_macro(path: Path) -> str:
    env = jinja2.Environment()
    env.globals["var"] = lambda n, d=None: VARS.get(n, d)
    macro_src = (ROOT / "macros" / "as_of_date.sql").read_text()
    macro_mod = env.from_string(macro_src).module
    return env.from_string(path.read_text()).render(
        ref=lambda n: f"`bq-analytics-lab`.`analytics_dev`.`{n}`",
        source=lambda s, t: f"`bigquery-public-data`.`thelook_ecommerce`.`{t}`",
        var=lambda n, d=None: VARS.get(n, d),
        as_of_date=macro_mod.as_of_date,
    )


@pytest.mark.parametrize("path", SQL_FILES, ids=lambda p: str(p.relative_to(ROOT)))
def test_model_renders_and_parses_as_bigquery(path):
    sql = render_with_macro(path)
    assert "{{" not in sql and "{%" not in sql
    parsed = sqlglot.parse(sql, read="bigquery")
    assert parsed and all(p is not None for p in parsed)


def test_as_of_date_macro_both_modes():
    env = jinja2.Environment()
    env.globals["var"] = lambda n, d=None: VARS.get(n, d)
    mod = env.from_string((ROOT / "macros" / "as_of_date.sql").read_text()).module
    assert str(mod.as_of_date()).strip() == "current_date()"
    VARS["as_of_date"] = "2025-01-01"
    try:
        assert str(mod.as_of_date()).strip() == "date('2025-01-01')"
    finally:
        VARS["as_of_date"] = None


def test_every_ref_points_to_a_real_model():
    models = {p.stem for p in (ROOT / "models").rglob("*.sql")}
    for p in SQL_FILES:
        for name in re.findall(r"ref\('([^']+)'\)", p.read_text()):
            assert name in models, f"{p.name} refs unknown model {name}"


def test_every_model_has_a_unique_key_test():
    declared = set()
    for y in (ROOT / "models").rglob("*.yml"):
        doc = yaml.safe_load(y.read_text()) or {}
        for m in doc.get("models", []):
            for c in m.get("columns", []):
                if "unique" in (c.get("tests") or []):
                    declared.add(m["name"])
    # fct_cohort_retention has a composite grain, covered by a singular test.
    assert (ROOT / "tests" / "assert_cohort_grain_is_unique.sql").exists()
    expected = {p.stem for p in (ROOT / "models").rglob("*.sql")} - {"int_sessions", "fct_cohort_retention"}
    assert expected - declared == set(), f"models missing a unique-key test: {expected - declared}"
