# install.packages("rstudioapi")
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
getwd()


loc <- read.csv("./sigun_code.csv", fileEncoding="UTF-8")
loc$code <- as.character(loc$code)   
head(loc, 2)



datelist <- seq(from = as.Date('2021-01-01'),
                to   = as.Date('2021-12-31'), 
                by    = '1 month')           
datelist <- format(datelist, format = '%Y%m') 
datelist[1:2]  

service_key <- "qDZOdMBw6HD7K4W9U4fy8YdSX6U%2B44%2FEWpqtbqFUEsWN%2Fd9caCiViPXK8iauzSSOuy32ju2M8AUtjtdwv3MPeA%3D%3D"

#--------------------------------------------------
# 3-2 요청목록 생성: 자료를 어떻게 요청할까?
#--------------------------------------------------

#---# [1단계: 요청목록 만들기]

url_list <- list() # 빈 리스트 만들기
cnt <-0	           # 반복문의 제어 변수 초깃값 설정

#---# [2단계: 요청목록 채우기]

for(i in 1:nrow(loc)){           # 외부반복: 25개 자치구
  for(j in 1:length(datelist)){  # 내부반복: 12개월
    cnt <- cnt + 1               # 반복누적 카운팅
    #---# 요청 목록 채우기 (25 X 12= 300)
    url_list[cnt] <- paste0("http://openapi.molit.go.kr:8081/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTrade?",
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



#---# [2단계: URL 요청 - XML 응답]
  
for(i in 1:length(url_list)){   # 요청목록(url_list) 반복
  raw_data[[i]] <- xmlTreeParse(url_list[i], useInternalNodes = TRUE,encoding = "utf-8") # 결과 저장
  root_Node[[i]] <- xmlRoot(raw_data[[i]])	# xmlRoot로 추출
    
  #---# [3단계: 전체 거래 건수 확인]
    
  items <- root_Node[[i]][[2]][['items']]  # 전체 거래내역(items) 추출
  size <- xmlSize(items)                   # 전체 거래 건수 확인    
    
  #---# [4단계: 거래 내역 추출]
    
  item <- list()  # 전체 거래내역(items) 저장 임시 리스트 생성
  item_temp_dt <- data.table()  # 세부 거래내역(item) 저장 임시 테이블 생성
  Sys.sleep(.1)  # 0.1초 멈춤
  for(m in 1:size){  # 전체 거래건수(size)만큼 반복
    #---# 세부 거래내역 분리   
    item_temp <- xmlSApply(items[[m]],xmlValue)
    item_temp_dt <- data.table(year = item_temp[4],     # 거래 년 
                                month = item_temp[7],    # 거래 월
                                day = item_temp[8],      # 거래 일
                                price = item_temp[1],    # 거래금액
                                code = item_temp[12],    # 지역코드
                                dong_nm = item_temp[5],  # 법정동
                                jibun = item_temp[11],   # 지번
                                con_year = item_temp[3], # 건축연도 
                                apt_nm = item_temp[6],   # 아파트 이름   
                                area = item_temp[9],     # 전용면적
                                floor = item_temp[13])   # 층수 
    item[[m]] <- item_temp_dt
  }    # 분리된 거래내역 순서대로 저장
  apt_bind <- rbindlist(item)     # 통합 저장
    
  #---# [5단계: 응답 내역 저장]
    
  region_nm <- subset(loc, code== str_sub(url_list[i],115, 119))$addr_1 # 지역명 추출
  month <- str_sub(url_list[i],130, 135)   # 연월(YYYYMM) 추출
  path <- as.character(paste0("./02_raw_data/", region_nm, "_", month,".csv")) # 저장위치 설정
  write.csv(apt_bind, path)     # csv 저장
  msg <- paste0("[", i,"/",length(url_list), "] 수집한 데이터를 [", path,"]에 저장 합니다.") # 알림 메시지
  cat(msg, "\n\n")
}   # 바깥쪽 반복문 종료


#----------
# 3-4 통합
#---------- 

#---# [1단계: csv 통합]

setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업폴더 설정
files <- dir("./02_raw_data")    # 폴더 내 모든 파일 이름 읽기
library(plyr)               # install.packages("plyr")
apt_price <- ldply(as.list(paste0("./02_raw_data/", files)), read.csv) # 모든 파일 하나로 결합
tail(apt_price, 2)  # 확인

#---# [2단계: 저장]

dir.create("./03_integrated")   # 새로운 폴더 생성
save(apt_price, file = "./03_integrated/03_apt_price.rdata") # 저장
write.csv(apt_price, "./03_integrated/03_apt_price.csv")   
