#!/usr/bin/env python3
"""
Create interactive HTML dashboard for Phone Test Analysis
"""

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px
from pathlib import Path

# Paths
EXCEL_FILE = Path('/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis/DI-1297_Phone_Test_Results_Combined.xlsx')
OUTPUT_FILE = Path('/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis/DI-1297_Dashboard.html')

def load_data():
    """Load all sheets from Excel"""
    print("Loading data from Excel...")
    return {
        'daily': pd.read_excel(EXCEL_FILE, sheet_name='Daily Group Size'),
        'cohort': pd.read_excel(EXCEL_FILE, sheet_name='Cure Rate Cohort'),
        'monthly': pd.read_excel(EXCEL_FILE, sheet_name='Cure Rate Monthly'),
        'roll': pd.read_excel(EXCEL_FILE, sheet_name='Roll Rate')
    }

def create_daily_group_size_chart(df_daily):
    """Chart 1: Daily Group Size Trends - 8 lines (Test/Control x 4 DPD buckets)"""
    # Create combined group identifier for legend
    df_daily['GROUP_LABEL'] = df_daily['DPD_BUCKET'] + ' - ' + df_daily['TEST_GROUP']

    fig = px.line(df_daily, x='LOAD_DATE', y='ACCOUNT_COUNT',
                  color='GROUP_LABEL',
                  title='Daily Group Size Trends by DPD Bucket and Test Group',
                  labels={'LOAD_DATE': 'Load Date', 'ACCOUNT_COUNT': 'Account Count', 'GROUP_LABEL': 'Group'},
                  markers=False)
    fig.update_layout(height=500, hovermode='x unified')
    fig.update_xaxes(tickangle=45)
    return fig

def create_cure_rate_by_cohort_chart(df_cohort):
    """Chart 2: Cure Rate vs Entry Cohort Month - 8 lines (Test/Control x 4 DPD buckets)"""
    # Calculate cure rate: CURED_COUNT / COHORT_SIZE
    df_cohort['CURE_RATE'] = (df_cohort['CURED_COUNT'] / df_cohort['COHORT_SIZE']) * 100

    # Create combined group identifier for legend
    df_cohort['GROUP_LABEL'] = df_cohort['DPD_BUCKET'] + ' - ' + df_cohort['TEST_GROUP']

    fig = px.line(df_cohort, x='ENTRY_COHORT_MONTH', y='CURE_RATE',
                  color='GROUP_LABEL',
                  title='Cure Rate by Entry Cohort Month',
                  labels={'ENTRY_COHORT_MONTH': 'Entry Cohort Month', 'CURE_RATE': 'Cure Rate (%)', 'GROUP_LABEL': 'Group'},
                  markers=True)
    fig.update_layout(height=500, hovermode='x unified')
    fig.update_xaxes(tickangle=45)
    return fig

def create_kpi_cards(df_monthly, df_roll):
    """Create summary KPI metrics"""
    # Overall averages
    test_cure = df_monthly[df_monthly['TEST_GROUP'] == 'Test (Low Intensity)']['CURE_RATE_PCT'].mean()
    control_cure = df_monthly[df_monthly['TEST_GROUP'] == 'Control (High Intensity)']['CURE_RATE_PCT'].mean()

    test_roll = df_roll[df_roll['TEST_GROUP'] == 'Test (Low Intensity)']['ROLL_RATE_PCT'].mean()
    control_roll = df_roll[df_roll['TEST_GROUP'] == 'Control (High Intensity)']['ROLL_RATE_PCT'].mean()

    total_accounts = df_monthly['TOTAL_ACCOUNTS'].sum()

    kpis = {
        'Test Cure Rate': f"{test_cure:.1f}%",
        'Control Cure Rate': f"{control_cure:.1f}%",
        'Cure Rate Difference': f"{test_cure - control_cure:.1f}%",
        'Test Roll Rate': f"{test_roll:.1f}%",
        'Control Roll Rate': f"{control_roll:.1f}%",
        'Total Accounts Analyzed': f"{total_accounts:,}"
    }
    return kpis

def create_dashboard():
    """Generate complete dashboard"""
    print("=" * 70)
    print("Creating Phone Test Analysis Dashboard")
    print("=" * 70)

    # Load data
    data = load_data()

    # Generate KPIs
    print("\nCalculating KPIs...")
    kpis = create_kpi_cards(data['monthly'], data['roll'])

    # Create visualizations
    print("Creating visualizations...")
    fig1 = create_daily_group_size_chart(data['daily'])
    fig2 = create_cure_rate_by_cohort_chart(data['cohort'])

    # Build HTML dashboard
    print("Building HTML dashboard...")
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>DI-1297 Phone Test Analysis Dashboard</title>
        <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
        <style>
            body {{
                font-family: Arial, sans-serif;
                margin: 20px;
                background-color: #f5f5f5;
            }}
            .header {{
                background-color: #2E86AB;
                color: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
            }}
            .kpi-container {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                margin-bottom: 20px;
            }}
            .kpi-card {{
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }}
            .kpi-label {{
                font-size: 14px;
                color: #666;
                margin-bottom: 5px;
            }}
            .kpi-value {{
                font-size: 28px;
                font-weight: bold;
                color: #2E86AB;
            }}
            .chart {{
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }}
            .footer {{
                text-align: center;
                color: #666;
                margin-top: 40px;
                padding: 20px;
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>DI-1297: Phone Test Results Analysis</h1>
            <p>A/B Test Analysis: Low Intensity vs High Intensity Calling (April 2024 - Present)</p>
        </div>

        <div class="kpi-container">
            <div class="kpi-card">
                <div class="kpi-label">Test Cure Rate</div>
                <div class="kpi-value">{kpis['Test Cure Rate']}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Control Cure Rate</div>
                <div class="kpi-value">{kpis['Control Cure Rate']}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Difference</div>
                <div class="kpi-value">{kpis['Cure Rate Difference']}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Test Roll Rate</div>
                <div class="kpi-value">{kpis['Test Roll Rate']}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Control Roll Rate</div>
                <div class="kpi-value">{kpis['Control Roll Rate']}</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Total Accounts</div>
                <div class="kpi-value">{kpis['Total Accounts Analyzed']}</div>
            </div>
        </div>

        <div class="chart" id="chart1"></div>
        <div class="chart" id="chart2"></div>

        <div class="footer">
            <p>Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Data Source: DI-1297_Phone_Test_Results_Combined.xlsx</p>
        </div>

        <script>
            {fig1.to_html(include_plotlyjs=False, div_id='chart1')}
            {fig2.to_html(include_plotlyjs=False, div_id='chart2')}
        </script>
    </body>
    </html>
    """

    # Save dashboard
    with open(OUTPUT_FILE, 'w') as f:
        f.write(html_content)

    print(f"\n✓ Dashboard created: {OUTPUT_FILE}")
    print(f"  File size: {OUTPUT_FILE.stat().st_size / 1024:.1f} KB")
    print("\n" + "=" * 70)
    print("Open the HTML file in your browser to view the dashboard!")
    print("=" * 70)

if __name__ == '__main__':
    create_dashboard()
