clear
*数据路径
cd "C:\Users\ouyan\OneDrive - 163.sufe.edu.cn\毕业论文\案例资料"

*                     基础数据整理


*= 导入事件日期数据
import delimited "C:\Users\ouyan\OneDrive - 163.sufe.edu.cn\毕业论文\案例资料\事件日期.csv"
rename v1 事件日期
rename v2 交易日期
save 事件日期.dta, replace

*= 导入日个股回报率数据
* 数据分别命名成 TRD_Dalyr1  TRD_Dalyr2 TRD_Dalyr3 ....
forvalues i=1/2 {
	import delimited 个股日收益率`i'.csv, encoding(utf-8) clear
	save 个股日收益率`i'.dta, replace
}

* 合并数据
* 使用append 纵向合并
forvalues i=1/2 {
   append using 个股日收益率`i'.dta
}
* 重命名变量
rename trddt 交易日期
rename dretwd 个股回报率
save 个股日收益率.dta, replace

*= 导入市场回报率数据（上证综指）
import excel 市场回报率.xlsx, firstrow clear
save 市场回报率.dta, replace

*日期处理，文字型变量转变为日期变量
*合并日个股回报率和市场回报率
use 个股日收益率.dta, clear
gen date_num = date(交易日期, "YMD")   // 转成 Stata 内部日期
format date_num %td                    // 格式化为日期显示
drop 交易日期
rename date_num 交易日期


* 使用m:1多对一匹配
* nogen就是不生成 _merge 变量
* keep(1 3) 就是等同于 keep if _merge==1 | _merge==3
* keepusing() 里面放入想要匹配进去的变量，默认是全部变量

merge m:1 交易日期 using "市场回报率.dta", nogen keep(1 3) keepusing(市场回报率)
save 收益率数据.dta, replace


*计算异常收益率
*日期处理成距离事件发生日的天数
gen date_new = 交易日期 - event_date //事件日归零
keep if date_new <=2 
keep if abs(date_new) < 10
keep if abs(date_new) > -130

*划分窗口期和估计期
gen event_window = 0
replace event_window = 1 if date_new <= (10) & date_new >= (-10)

gen event_estimate = 1
replace event_estimate = 0 if date_new <= (10) & date_new >= (-10)

*回归运算
*分组生成变量
egen id = group(stkcd)
egen max_id = max(id)
*循环回归(n家公司-但此处不适用，因为每个公司公告的日期不一样)
*把所有观测值初始化为缺失值
gen predicet_return = .
forvalues i=1/3 {
	reg market_earn share_earn if id == "i" 
	& event_estimate == 1 
predict p if id  == "i"
replace predicet_return = p if id == "i"
drop p///便于循环
}

*计算超额收益AR
gen AR = .
replace AR = share_earn - predicet_return

*计算累计超额收益CAR（按照stkcd排序，再按照交易日升序）；是很多只股票的话可以egen一个最大的CAR 再table一下观测最终的累计收益率哪个最明显
bysort stkcd(交易日期): gen CAR_1 = sum(AR)
bysort stkcd(交易日期): egen CAR_final = Max(CAR_1)

*对事件前后检验每只股票的 AR 是否显著为 0,做t检验,原假设是 AR 的均值 = 0
gen group = (date_new >= 0)
bysort stkcd: ttest AR, by(group)
