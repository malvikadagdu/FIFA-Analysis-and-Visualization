---
title: "Fifa Dav"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```



##1. Player EDA


```{r include=FALSE}
library(ggrepel)

library(gghighlight)

library(fmsb)

library(reshape2)

library(colorspace)

library(purrr)

library(forcats)

library(dplyr)

library(plotly)

library(stringr)

library(leaflet)

library(ggmap)

library(ggplot2)

library(caTools)

Fifa <- read.csv("/Users/Laukik/Desktop/SPRING 2019 SEM/DAV/FIFA FINAL/data.csv",header = T, stringsAsFactors = F)

Fifa <- select(Fifa, -Club.Logo, -Photo, -Flag, -Real.Face, -Loaned.From)

Fifa$ValueLast <- sapply(strsplit(as.character(Fifa$Value), ""), tail, 1) #We split the Value which is given as  eg: €110M, so we separate the 'M' from the value.

Fifa$WageLast <- sapply(strsplit(as.character(Fifa$Wage), ""), tail, 1) #We split the Value which is given as  eg: €100K, so we separate the 'K' from the value.

Fifa$Release.Clause.Last <- sapply(strsplit(as.character(Fifa$Release.Clause), ""), tail, 1) #We split the Value which is given as  eg: €110M, so we separate the 'M' from the value.


extract <- function(x){
  regexp <- "[[:digit:]]+"
  str_extract(x, regexp)
}

temp1 <- sapply(Fifa$Value, extract)

Fifa$Value <- as.numeric(temp1)

temp2 <- sapply(Fifa$Wage, extract)

Fifa$Wage <- as.numeric(temp2)

temp3 <- sapply(Fifa$Release.Clause, extract)

Fifa$Release.Clause <- as.numeric(temp3)

Fifa$Wage <- ifelse(Fifa$WageLast == "M", Fifa$Wage * 1000000, Fifa$Wage * 1000)

Fifa$Value <- ifelse(Fifa$ValueLast == "M", Fifa$Value * 1000000, Fifa$Value * 1000)

Fifa$Release.Clause <- ifelse(Fifa$Release.Clause.Last == "M", Fifa$Release.Clause * 1000000, Fifa$Release.Clause * 1000)

Fifa$Contract.Valid.Until <- as.numeric(Fifa$Contract.Valid.Until)

Fifa$Remaining.Contract <- Fifa$Contract.Valid.Until - 2019

Fifa$Height.Inch <- str_split(Fifa$Height,"'") 

temp4 <- sapply(Fifa$Weight, extract)

Fifa$Weight <- as.numeric(temp4)

temp5 <- strsplit(Fifa$Height, "'")

for (i in 1:length(temp5)){
  temp5[[i]] <- as.numeric(temp5[[i]])
} 

for (i in 1:length(temp5)){
  temp5[[i]] <- (temp5[[i]][1] * 12 ) + temp5[[i]][2]
}

temp6 <- as.numeric(unlist(temp5))

Fifa$Height <- temp6

dff <- Fifa[,29:54]

def_fun <- function(x){
  a <- strsplit(x, '\\+')
  for (i in length(a)){
    b <- sum(as.numeric(a[[i]]))
  }
  return (b)
}

for (i in 1: ncol(dff)){
  dff[i] <- apply(dff[i], 1, FUN = def_fun)
}





Fifa[,29:54] <- NULL

Fifa <- cbind.data.frame(Fifa, dff)
```

#Finding the most valuable teams 

```{r echo=FALSE}
Fifa %>%
  group_by(Club)%>%
  summarise(Club.Squad.Value = round(sum(Value)/1000000))%>%
  arrange(-Club.Squad.Value)%>%
  head(10)%>%
  ggplot(aes(x = as.factor(Club) %>%
               fct_reorder(Club.Squad.Value), y = Club.Squad.Value, label = Club.Squad.Value))+
  geom_text(hjust = 0.01,inherit.aes = T, position = "identity")+
  geom_bar(stat = "identity", fill = "violetred1")+
  coord_flip()+
  xlab("Club")+
  ylab("Squad Value in Million")
```



#Top Wage Bills
```{r echo=FALSE}
Fifa %>%
  group_by(Club)%>%
  summarise(Total.Wage = round(sum(Wage)/1000000, digits =2))%>%
  arrange(-Total.Wage)%>%
  head(10)%>%
  ggplot(aes(x = as.factor(Club) %>%
               fct_reorder(Total.Wage), y = Total.Wage, label = Total.Wage))+
  geom_text(hjust = 0.01,inherit.aes = T, position = "identity")+
  geom_bar(stat = "identity", fill = "violetred1")+
  coord_flip()+
  xlab("Club")+
  ylab("Squad Wages in Million")
```



#Superstars in FIFA 
```{r echo=FALSE}
Fifa %>%
  mutate(Superstar = ifelse(Overall> 86, "Superstar","Non - Superstar"))%>%
  group_by(Club)%>%
  filter(Superstar=="Superstar")%>%
  summarise(Player.Count = n())%>%
  arrange(-Player.Count)%>%
  ggplot(aes(x = as.factor(Club) %>%
               fct_reorder(Player.Count), y = Player.Count, label = Player.Count))+
  geom_text(hjust = 0.01,inherit.aes = T, position = "identity")+
  geom_bar(stat = "identity", fill = "palegreen2")+
  coord_flip()+
  xlab("Club")+
  ylab("Number of Superstars")
```


#Age Distribution amongst the Top Valued Clubs

```{r echo=FALSE}
Most.Valued.Clubs <- Fifa %>%
  group_by(Club)%>%
  summarise(Club.Squad.Value = round(sum(Value)/1000000))%>%
  arrange(-Club.Squad.Value)%>%
  head(10)

Player.List <- list()

for (i in 1:nrow(Most.Valued.Clubs)){
temp.data <-  Fifa%>%
  filter(Club == Most.Valued.Clubs[[1]][i]) 

Player.List[[i]] <- temp.data
}

data <- lapply(Player.List, as.data.frame) %>% bind_rows()

data$Club <- as.factor(data$Club)

ggplot(data, aes(x = Club ,y = Age, fill = Club)) +
  geom_violin(trim = F)+
  geom_boxplot(width = 0.1)+
  theme(axis.text.x = element_text(angle = 90), legend.position = "none")+
  ylab("Age distribution amongst Clubs")
```



#Clubs with the youngest Squad
```{r echo=FALSE}
Fifa %>%
  group_by(Club)%>%
  summarise(Club.Avg.Age = round(sum(Age)/length(Age),digits = 2))%>%
  arrange(Club.Avg.Age)%>%
  head(10)%>%
  ggplot(aes(x = as.factor(Club) %>%
             fct_reorder(Club.Avg.Age), y = Club.Avg.Age, label = Club.Avg.Age))+
  geom_bar(stat = "identity", fill = "turquoise4")+
  geom_text(inherit.aes = T, nudge_y = 0.5)+
  xlab("Club")+
  theme(axis.text.x = element_text(angle = 90))+
  ylab("Average Squad Age")
```


#Is player jersey number related to Overall ?
```{r echo=FALSE, warning=FALSE}
Fifa %>%
  group_by(Jersey.Number) %>%
  summarise(Avg.Overall = sum(Overall)/length(Jersey.Number),
            Player.Count = sum(Jersey.Number))%>%
  arrange(-Avg.Overall)%>%
  ggplot(aes(x = Jersey.Number, y = Avg.Overall,col = ifelse(Avg.Overall < 70,"darkgrey", "Red")))+
  geom_point(position = "jitter")+
  theme(legend.position = "none")+
  geom_text_repel(aes(label = ifelse(Avg.Overall > 70, Jersey.Number, "")))
```





#Best free kick takers in the game
```{r echo=FALSE}
Fifa %>%
  arrange(-FKAccuracy, -Curve)%>%
  dplyr::select(Name, FKAccuracy, Curve, Age, Club)%>%
  head(10)
```


#Evaluating BMI to find most unfit players 
```{r echo=FALSE}

Fifa%>%
  group_by(Name)%>%
  mutate(BMI = (Weight*0.453592/(Height)^2))%>%
  arrange(-BMI)%>%
  select(Name, BMI)%>%
  head(10)
```




##3. Player Value Prediction 

```{r include=FALSE}

Fifa_Int <- Fifa[ , map_lgl(Fifa, is.numeric)]

mcor<- as.data.frame(cor(Fifa_Int, use = "complete.obs"))

temp7 <- mcor["Value"]

temp8 <- subset(temp7, Value > 0.30)

temp9 <- rownames(temp8)

library(caTools)
set.seed(101)

sample = sample.split(Fifa, SplitRatio = 0.6)

train <- subset(Fifa, sample == TRUE)

test <- subset(Fifa, sample == FALSE)

fit <- lm(Value ~ Overall + Potential + Wage + International.Reputation + Skill.Moves + Release.Clause, data = train, na.action = na.omit)

summary(fit)

test_fit <- predict(fit, newdata = test)

test_fit <- round(test_fit,0)

test$Predicted.Value <- test_fit

temp12 <- test[c("Name","Value","Predicted.Value")]

library(dplyr)
temp12 <- temp12 %>%
  mutate(Difference = Value - Predicted.Value )

temp12$Accuracy <- ifelse(temp12$Difference > 0.20 * temp12$Value , "No",ifelse(temp12$Difference < -(0.20 * temp12$Value),"No", "Yes"))

table(temp12$Accuracy)


```


```{r}

temp12%>%
  head(20)

```


CLUSTERING

```{r}
library(ISLR)
View(Fifa)
new_data=Fifa[c("Age")]
View(new_data)

kmfifa = kmeans(new_data,2,nstart = 20)
kmfifa$cluster
plot(new_data,col=(kmfifa$cluster+1), main="AGE RANGE", xlab ="COUNT", ylab="AGE", pch=20, cex=2)



new_data1=Fifa[,c("Age","Potential")]
View(new_data1)

kmfifa1 = kmeans(new_data1,2,nstart = 20)
kmfifa1$cluster

plot(new_data1,col=(kmfifa1$cluster+1), main="AGE vs POTENTIAL", xlab ="AGE", ylab="POTENTIAL", pch=20, cex=2)
```

```{r}
View(Fifa)
new_data1=Fifa[c("Wage")]
View(new_data1)

kmfifa1 = kmeans(new_data1,2,nstart = 20)
kmfifa1$cluster
plot(new_data,col=(kmfifa1$cluster+1), main="Wage Range", xlab ="COUNT", ylab="Wage", pch=20, cex=2)



new_data2=Fifa[,c("Age","Wage")]
View(new_data2)

kmfifa1 = kmeans(new_data2,2,nstart = 20)
kmfifa1$cluster

plot(new_data2,col=(kmfifa1$cluster+1), main="AGE vs WAGE", xlab ="AGE", ylab="WAGE", pch=20, cex=2)

```

```{r}
View(Fifa)
new_data=Fifa[c("Overall")]
View(new_data)

kmfifa = kmeans(new_data,2,nstart = 20)
kmfifa$cluster
plot(new_data,col=(kmfifa$cluster+1), main="Overall Rate Range", xlab ="COUNT", ylab="Overall Rate", pch=20, cex=2)


new_data1=Fifa[,c("Overall","Wage")]
View(new_data1)

kmfifa1 = kmeans(new_data1,2,nstart = 20)
kmfifa1$cluster

plot(new_data1,col=(kmfifa1$cluster+1), main="Overall Rate vs Wage", xlab ="Overall Rate", ylab="Wage", pch=20, cex=2)
```

```{r}
summary(Fifa)
```
