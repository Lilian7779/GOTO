#!/usr/bin/env python3
"""
政企通 - 政策自动更新脚本
从9个主管部门网站抓取最新政策标题和链接，写入 Supabase policies 表
执行频率：每2小时 (GitHub Actions cron: 0 */2 * * *)
"""
import os, sys, hashlib, time, re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://rzmfqwsytwlmyfazwpmw.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

HEADERS_TEMPLATE = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9"
}

SOURCES = [
    {"name": "南通市开发区管委会", "url": "http://www.netda.gov.cn/", "category": "政策发布"},
    {"name": "南通市应急管理局", "url": "http://yjj.nantong.gov.cn/", "category": "安全生产"},
    {"name": "南通市市场监管局", "url": "http://scjgj.nantong.gov.cn/", "category": "市场监管"},
    {"name": "南通市行政审批局", "url": "http://xzsp.nantong.gov.cn/", "category": "行政审批"},
    {"name": "南通市工信局", "url": "http://gxj.nantong.gov.cn/", "category": "产业政策"},
    {"name": "南通市科技局", "url": "http://kjj.nantong.gov.cn/", "category": "科技创新"},
    {"name": "南通市人社局", "url": "http://rsj.nantong.gov.cn/", "category": "人才社保"},
    {"name": "南通市商务局", "url": "http://swj.nantong.gov.cn/", "category": "商务外贸"},
    {"name": "江苏省工信厅", "url": "http://gxt.jiangsu.gov.cn/", "category": "省级政策"},
]

def fetch_page(url, timeout=15):
    """抓取页面HTML"""
    try:
        r = requests.get(url, headers=HEADERS_TEMPLATE, timeout=timeout, verify=False)
        r.encoding = r.apparent_encoding or 'utf-8'
        return r.text
    except Exception as e:
        print(f"  [WARN] 抓取失败 {url}: {e}")
        return None

def extract_links(html, base_url):
    """从HTML中提取政策标题和链接"""
    results = []
    if not html:
        return results
    try:
        soup = BeautifulSoup(html, 'html.parser')
        # 常见政府网站的政策列表模式
        selectors = [
            'a[href*="content"]', 'a[href*="art"]', 'a[href*="detail"]',
            'a[href*="info"]', 'a[href*="news"]', 'a[href*="tzgg"]',
            'a[href*="zwgk"]', 'a[href*="zcfg"]', 'a[href*="gonggao"]',
            'ul.news_list a', 'ul.list a', 'div.news_list a',
            '.list-con a', '.news-con a', 'li a[title]'
        ]
        seen = set()
        for selector in selectors:
            for a in soup.select(selector):
                title = (a.get('title') or a.get_text(strip=True))[:200]
                href = a.get('href', '')
                if not title or not href or len(title) < 6:
                    continue
                full_url = urljoin(base_url, href)
                key = title[:50]
                if key in seen:
                    continue
                seen.add(key)
                results.append({"title": title, "url": full_url})
            if len(results) >= 20:
                break
    except Exception as e:
        print(f"  [WARN] 解析失败 {base_url}: {e}")
    return results[:20]

def supabase_request(method, path, data=None):
    """向 Supabase REST API 发送请求"""
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    if method == "GET":
        r = requests.get(url, headers=headers)
    elif method == "POST":
        headers["Prefer"] = "return=representation"
        r = requests.post(url, headers=headers, json=data)
    else:
        return None
    return r

def check_exists(title, url):
    """检查标题+链接是否已存在"""
    # 使用 title 精确匹配
    r = supabase_request("GET", f"policies?title=eq.{requests.utils.quote(title)}&select=id")
    if r and r.status_code == 200 and len(r.json()) > 0:
        return True
    # 也检查 doc_url
    r = supabase_request("GET", f"policies?doc_url=eq.{requests.utils.quote(url)}&select=id")
    if r and r.status_code == 200 and len(r.json()) > 0:
        return True
    return False

def insert_policy(item, source):
    """插入一条政策记录"""
    data = {
        "title": item["title"],
        "doc_url": item["url"],
        "region": "南通市",
        "industry": "通用",
        "policy_type": "资金补贴",
        "source_dept": source["name"],
        "description": f"来源：{source['name']}（{source['category']}）",
        "status": "pending_review",
        "is_active": True
    }
    r = supabase_request("POST", "policies", data)
    return r and r.status_code in [200, 201]

def main():
    # 禁用 SSL 警告（政府网站证书可能过期）
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    
    if not SUPABASE_KEY:
        print("ERROR: SUPABASE_SERVICE_KEY not set")
        sys.exit(1)
    
    total_new = 0
    for src in SOURCES:
        print(f"\n[{src['name']}] {src['url']}")
        html = fetch_page(src["url"])
        items = extract_links(html, src["url"])
        print(f"  提取到 {len(items)} 条链接")
        
        new_count = 0
        for item in items:
            if check_exists(item["title"], item["url"]):
                continue
            if insert_policy(item, src):
                new_count += 1
                print(f"  + {item['title'][:60]}")
            time.sleep(0.3)  # 避免请求过快
        
        total_new += new_count
        print(f"  新增 {new_count} 条")
        time.sleep(1)
    
    print(f"\n=== 完成：共新增 {total_new} 条政策 ===")

if __name__ == "__main__":
    main()
