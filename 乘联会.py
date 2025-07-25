import requests
import pandas as pd

# API 地址（厂商排行），模拟访问
url = "https://data.cpcadata.com/api/chartlist?charttype=2"
headers = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://data.cpcadata.com/FuelMarket"
}

# 请求数据
res = requests.get(url, headers=headers)
if res.status_code == 200:
    data = res.json()  # 定义data是Json解析为 Python 对象
else:
    print("请求失败，状态码:", res.status_code)
    exit()

# 解析 JSON(意思是搞一个对应的词典取数？）
result_list = []
for item in data:
    category = item.get("category", "")
    for d in item.get("dataList", []):
        row = {
            "分类": category,
            "厂商": d.get("厂商", ""),
            "2025年1-6月": d.get("2025年 1-6月", [None, None])[0],
            "2024年1-6月": d.get("2024年 1-6月", [None, None])[0],
            "同比增长(%)": d.get("同比", [None, None])[0],
	    "2025年6月":d.get("2025年6月",[None,None])[0],
	    "2024年6月":d.get("2024年6月",[None,None])[0],
        }
        result_list.append(row)

# 转为 DataFrame二维表格（pandas)
df = pd.DataFrame(result_list)	

# 保存 Excel
excel_name = "厂商销量数据.xlsx"
df.to_excel(excel_name, index=False)
print(f"数据已保存到 {excel_name}")
