# R-project 장이빈 

## 09-14
패키지 다운로드 후 sigun_code.csv 연결
```
install.packages("rstudioapi")
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
getwd()


loc <- read.csv("./sigun_code.csv", fileEncoding="UTF-8")
loc$code <- as.character(loc$code)   
head(loc, 2)



datelist <- seq(from = as.Date('2021-01-01'),
                to   = as.Date('2021-12-31'), 
                by    = '1 month')           
datelist <- format(datelist, format = '%Y%m') 
datelist[1:3]  
```
