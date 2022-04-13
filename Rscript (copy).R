##### Task break down #####
# 1) create variables to load different data files in the future
# 2) manipulate file to create required DB table structure
# 3) push data to SQL DB


## assumptions
# - new files will be of the same format and layout, i.e use Grid-ref
# - No duplicates within the file provided
# - [SQL side] no duplicates across different files
# - using local mySQL database


## improvements
# - issue with SQL sometimes "Loading local data is disabled"
# - Obviously password in file isn't great!



####### load required packages ########
install.packages("RMySQL", dependencies=TRUE)
library(RMySQL)
install.packages('data.table')
library(data.table)
install.packages('dplyr')
library(dplyr)

###### Set variables ######
# Variables for file name, SQL connection etc.
filename <- 'cru-ts-2-10.1991-2000-cutdown.pre' 
fileLoc <- './data'
fileToRead <- paste(fileLoc,"/", filename, sep="")



##### Import Data ##########
#raw data
#data <- read.table(fileToRead, sep=",", as.is=FALSE, header=FALSE, fill=TRUE)
data2 <- read.table(text = gsub(",", "\t", readLines(fileToRead)), fill=TRUE) #this loads the data in a better format

#head information from file
data2Header <- data.frame(data2)[c(1,2,3,4,5),]
#remove head information leaving just data.
data <- data.frame(data2)[-c(1,2,3,4,5),]

##Using year within the loop - I don't like how I have specified a specific cell for years. 
years <-substring(data2Header[5,3],8,16)
years <- data.frame(strsplit(years,"-"))

####final data frame that will be pushed to SQL
#df <- data.frame(matrix(ncol = 4, nrow = 0))

## prepopulate with approx rows to try to speed up loop
df <- data.frame(matrix(ncol = 4, nrow = nrow(data)*12)) #approx length
cols <- c("xref", "yref", "date", "value")
colnames(df) <- cols

#progress bar
pb = txtProgressBar(min = 0, max = nrow(data), initial = 0, style = 3) 
#pb = txtProgressBar(min = 0, max = 100, initial = 0, style = 3) 


# populate df
currRow <- 1
start_time <- Sys.time()
for (i in 1:nrow(data)){
#for (i in 1:100){
  setTxtProgressBar(pb,i)
  if (substr(data[i,1], 1, 8) == 'Grid-ref'){
    curryear <- as.numeric(years[1,])
    xref <- as.character(data[i,2])
    yref <- as.character(data[i,3])
    next
  }
  for (k in 1:12){
    date <- paste(k,"/1/",curryear,sep="")
    value <- data[i,k]
    dfRow <- c(xref, yref, date, value)
    df[currRow,] <- dfRow
    currRow <- currRow + 1
  }
  curryear <- curryear+1
  if ( i %% 1000 == 0) {
    print(paste("Number of records processed ", i))
  }  
}

close(pb)

end_time <- Sys.time()
end_time - start_time
## 1.5 hours.... not great but still a lot better than before! 

## remove empty rows due to over estimating data frame size
df2 <- df[rowSums(is.na(df)) != ncol(df),]
#62K difference

##### MySQL DB connection #####

mydb = dbConnect(MySQL(), user='root', password='P@55w0rD', dbname='codeChallenge', host='craig-HP-Compaq-Elite-8300-CMT')
dbListTables(mydb)
dbWriteTable(mydb, "rainfall",data.frame(df2),row.names = FALSE, append = TRUE) #getting the occasional message about loading local data must be enabled.
dbReadTable(mydb, "rainfall")




##### Clear environment #####
rm(list = ls())


