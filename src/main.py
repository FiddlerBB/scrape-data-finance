from __future__ import annotations
from sessions import RandomUserAgentSession
import polars as pl
import logging
import requests
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from selectolax.parser import HTMLParser
import boto3
logger = logging.basicConfig(
    # filename="debug.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

class GoldCrawler:
    __slots__ = ("headers", "session", "proxy", "timeout")

    def __init__(self, proxy=None, timeout=10, random_user_agent=True):
        self.session = RandomUserAgentSession() if random_user_agent else requests.Session()
        self.proxy = proxy
        self.timeout = timeout

        retries = Retry(
            total=5,
            backoff_factor=2,  # Exponential backoff
            status_forcelist=[429, 500, 502, 503, 504],
        )

        self.session.mount("https://", HTTPAdapter(max_retries=retries))

    def get_html_data(self, url):
        try:
            response = self.session.get(url, timeout=self.timeout)
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching HTML data: {e}")
            return None
        
    def parse_table(self, html_data: HTMLParser):
        table = html_data.css_first("table[class='gia-vang-search-data-table']")
        rows = table.css("tr")
        out = []
        for row in rows:
            cells = row.css("td")
            gold_idx = cells[0].text().strip().lower().replace(' ', '_')
            buy_price = list(cells[1].text().strip().split())[0].replace(',', '')
            sell_price = list(cells[2].text().strip().split())[0].replace(',', '')
            yesterday_buy_price = cells[3].text().strip().replace(',', '')
            yesterday_sell_price = cells[4].text().strip().replace(',', '')
            # print(f"Gold Index: {gold_idx}")
            # print(f"Buy Price: {buy_price}")
            # print(f"Sell Price: {sell_price}")
            # print(f"Yesterday Buy Price: {yesterday_buy_price}")
            # print(f"Yesterday Sell Price: {yesterday_sell_price}")
            out.append({
                "gold_idx": gold_idx,
                "buy_price": buy_price,
                "sell_price": sell_price,
                "yesterday_buy_price": yesterday_buy_price,
                "yesterday_sell_price": yesterday_sell_price
            })
        df = pl.DataFrame(out, schema={
            "gold_idx": pl.String,
            "buy_price": pl.Int64,
            "sell_price": pl.Int64,
            "yesterday_buy_price": pl.Int64,
            "yesterday_sell_price": pl.Int64
        })
        out = out[0]
        return {'gold_idx': out['gold_idx'], 
                'buy_price': out['buy_price'],
                'sell_price': out['sell_price'],
                'yesterday_buy_price': out['yesterday_buy_price'],
                'yesterday_sell_price': out['yesterday_sell_price']}

    def parse_chart(self, html: HTMLParser):
        chart = html.css_first("div[class='cate-24h-gold-pri-chart'] > script[type='text/javascript']")
        dates = chart.text().split('categories: [')[1].split(']')[0].replace("'", "").split(',')
        buy_in = chart.text().split('data: [')[1].split(']')[0].split(',')
        sell_out = chart.text().split('data: [')[2].split(']')[0].split(',')
        df = pl.DataFrame({
            "date": dates,
            "buy_in": buy_in,
            "sell_out": sell_out
        })
        df = df.with_columns([
            pl.col("buy_in").cast(pl.Int64),
            pl.col("sell_out").cast(pl.Int64)
        ])
        print(df.head())

def lambda_handler(event= None, context=None):
    crawler = GoldCrawler()
    # url = "https://www.24h.com.vn/gia-vang-hom-nay-c425.html?ngaythang=2025-02-27"
    url = "https://www.24h.com.vn/gia-vang-hom-nay-c425.html"
    html_data = crawler.get_html_data(url)
    html_data =HTMLParser(html_data)
    out = crawler.parse_table(html_data)
    sns_arn = 'arn:aws:sns:us-east-1:174227742216:gold-scrape-topic'
    sns_client = boto3.client('sns', 'us-east-1')
    message = f"Gold data for today: {out['buy_price']} - {out['sell_price']}"
    sns_client.publish(
        TargetArn=sns_arn,
        Message=message,
        Subject='Gold Data'
    )
    crawler.parse_chart(html_data)

if __name__=='__main__':
    lambda_handler()