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
# - for loop is extremely(!) slow, and I don't like looping for a number of years. It would be better to loop until the next Grid-ref
# - Obviously password in file isn't great!



####### load required packages ########
install.packages("RMySQL", dependencies=TRUE)
library(RMySQL)


###### Set variables ######
# Variables for file name, SQL connection etc.
filename <- 'cru-ts-2-10.1991-2000-cutdown.pre' 
fileLoc <- './data'
fileToRead <- paste(fileLoc,"/", filename, sep="")




##### Import Data ##########
#raw data
data <- read.table(fileToRead, sep=",", as.is=FALSE, header=FALSE, fill=TRUE)

#final data frame that will be pushed to SQL
df <- data.frame(matrix(ncol = 4, nrow = 0))
cols <- c("xref", "yref", "date", "value")
colnames(df) <- cols

#progress bar
pb = txtProgressBar(min = 0, max = nrow(data), initial = 0) 

# populate df
for (i in 1:nrow(data)){
  setTxtProgressBar(pb,i)
  if (substr(data[i,1], 1, 8) == 'Grid-ref'){
    xref <- scan(text = as.character(data[i,1]), what="=", quiet = TRUE)[2]
    yref <- as.character(data[i,2])
    
    #next 10 rows indicate year
    for (j in 1:10){
      #each row is a year, and space separated values are the values per month
      month <- data.frame()
      month <- scan(text = as.character(data[i+j, 1]), what = "", quiet = TRUE)
      #next loop for months
      for (k in 1:12){
        date <- paste(k,"/1/",1990+j,sep="")
        value <- month[k]
        dfRow <- cbind(xref, yref, date, value)
        df <- rbind(df, dfRow)
      }
    }
  }
}
close(pb)


##### MySQL DB connection #####

mydb = dbConnect(MySQL(), user='root', password='P@55w0rD', dbname='codeChallenge', host='craig-HP-Compaq-Elite-8300-CMT')
dbListTables(mydb)
dbWriteTable(mydb, "rainfall",data.frame(df),row.names = FALSE, append = TRUE)
dbReadTable(mydb, "rainfall")




##### Clear environment #####
rm(list = ls())