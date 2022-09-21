# R-project 장이빈 

## 09-21
> 요청목록 생성
> 요청목록 채우기
> 요청목록 갯수 확인
> 임시 저장 리스트 생성
```
url_list <- list() # 빈 리스트 만들기
cnt <-0	           # 반복문의 제어 변수 초깃값 설정

#---# [2단계: 요청목록 채우기]

for(i in 1:nrow(loc)){           # 외부반복: 25개 자치구
  for(j in 1:length(datelist)){  # 내부반복: 12개월
    cnt <- cnt + 1               # 반복누적 카운팅
    #---# 요청 목록 채우기 (25 X 12= 300)
    url_list[cnt] <- paste0("http://openapi.molit.go.kr:8081/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTrade",
                            "LAWD_CD=", loc[i,1],         # 지역코드
                            "&DEAL_YMD=", datelist[j],    # 수집월
                            "&numOfRows=", 100,           # 한번에 가져올 최대 자료 수
                            "&serviceKey=", service_key)  # 인증키
  } 
  Sys.sleep(0.1)   # 0.1초간 멈춤
  msg <- paste0("[", i,"/",nrow(loc), "]  ", loc[i,3], " 의 크롤링 목록이 생성됨 => 총 [", cnt,"] 건") # 알림 메시지
  cat(msg, "\n\n") 
}

length(url_list)                # 요청목록 갯수 확인
browseURL(paste0(url_list[1]))  # 정상작동 확인(웹브라우저 실행)

#---# [1단계: 임시 저장 리스트 생성]
# install.packages("XML")
# install.packages("data.table")
# install.packages("stringr")

library(XML)        
library(data.table)
library(stringr)

raw_data <- list()        # xml 임시 저장소
root_Node <- list()       # 거래내역 추출 임시 저장소
total <- list()           # 거래내역 정리 임시 저장소
dir.create("02_raw_data") # 새로운 폴더 만들기

```

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
