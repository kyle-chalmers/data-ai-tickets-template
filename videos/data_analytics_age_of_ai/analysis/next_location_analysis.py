import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# Load data
df = pd.read_csv("../sample_data/coffee_chain_locations.csv")

# --- Core Metrics ---
# Revenue per competitor: how much revenue the market supports per existing shop
df["revenue_per_competitor"] = df["monthly_revenue"] / df["competitors_within_3mi"]
# Revenue per foot traffic visitor (conversion quality)
df["revenue_per_visitor"] = df["monthly_revenue"] / df["monthly_foot_traffic"]
# Foot traffic per competitor (demand saturation)
df["traffic_per_competitor"] = df["monthly_foot_traffic"] / df["competitors_within_3mi"]
# Rent efficiency: revenue generated per dollar of rent
df["revenue_per_rent"] = df["monthly_revenue"] / df["avg_rent_sqft"]
# Population per competitor (market room)
df["population_per_competitor"] = df["population"] / df["competitors_within_3mi"]

print("=== City Comparison ===\n")
print(df[["city", "state", "monthly_revenue", "competitors_within_3mi",
          "revenue_per_competitor", "traffic_per_competitor",
          "avg_rent_sqft", "population_per_competitor"]].to_string(index=False))

print("\n=== Ranked by Revenue per Competitor ===")
ranked = df.sort_values("revenue_per_competitor", ascending=False)
for i, row in ranked.iterrows():
    print(f"  {row['city']}, {row['state']}: ${row['revenue_per_competitor']:,.0f}/competitor "
          f"({row['competitors_within_3mi']} competitors, ${row['monthly_revenue']:,} revenue)")

print("\n=== Ranked by Population per Competitor (Market Room) ===")
ranked2 = df.sort_values("population_per_competitor", ascending=False)
for i, row in ranked2.iterrows():
    print(f"  {row['city']}, {row['state']}: {row['population_per_competitor']:,.0f} people/competitor "
          f"(pop {row['population']:,}, {row['competitors_within_3mi']} competitors)")

# --- Visualization: Revenue per Competitor ---
fig, ax = plt.subplots(figsize=(10, 6))

colors = ["#2d2d2d"] * len(df)
boise_idx = df.sort_values("revenue_per_competitor", ascending=True).index.tolist()
boise_sorted_pos = df.sort_values("revenue_per_competitor", ascending=True).reset_index()
boise_row = boise_sorted_pos[boise_sorted_pos["city"] == "Boise"].index[0]
sorted_df = df.sort_values("revenue_per_competitor", ascending=True).reset_index(drop=True)
colors_sorted = ["#a0a0a0"] * len(sorted_df)
boise_pos = sorted_df[sorted_df["city"] == "Boise"].index[0]
colors_sorted[boise_pos] = "#1a6b3c"

bars = ax.barh(
    sorted_df["city"] + ", " + sorted_df["state"],
    sorted_df["revenue_per_competitor"],
    color=colors_sorted,
    edgecolor="white",
    height=0.6,
)

for bar, val in zip(bars, sorted_df["revenue_per_competitor"]):
    ax.text(bar.get_width() + 200, bar.get_y() + bar.get_height() / 2,
            f"${val:,.0f}", va="center", fontsize=11, fontweight="bold")

ax.set_xlabel("Monthly Revenue per Competitor", fontsize=12, labelpad=10)
ax.set_title("Which Market Has the Least Competition\nfor the Most Revenue?",
             fontsize=15, fontweight="bold", pad=15)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
ax.set_xlim(0, sorted_df["revenue_per_competitor"].max() * 1.2)
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

# Annotation for Boise
ax.annotate(
    "Fewest competitors (4) + lowest rent ($28/sqft)\n= highest revenue per competitor",
    xy=(sorted_df.loc[boise_pos, "revenue_per_competitor"], boise_pos),
    xytext=(sorted_df["revenue_per_competitor"].max() * 0.65, boise_pos + 2.2),
    fontsize=10, fontstyle="italic", color="#1a6b3c",
    arrowprops=dict(arrowstyle="->", color="#1a6b3c", lw=1.5),
)

plt.tight_layout()
plt.savefig("revenue_per_competitor.png", dpi=150, bbox_inches="tight")
print("\nChart saved to: analysis/revenue_per_competitor.png")
