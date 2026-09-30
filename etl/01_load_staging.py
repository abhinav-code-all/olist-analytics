import pandas as pd
from pathlib import Path
from getpass import getpass
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

password = getpass("Postgres password: ")

url = URL.create(
    "postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="olist_dw",
)
engine = create_engine(url)

raw = Path(r"C:\Projects\olist-analytics\data\raw")

for f in sorted(raw.glob("*.csv")):
    table = f.stem.replace("olist_", "").replace("_dataset", "")
    df = pd.read_csv(f)
    df.to_sql(table, engine, schema="staging",
              if_exists="replace", index=False, chunksize=10000)
    print(f"Loaded staging.{table}: {len(df):,} rows")

print("Done.")