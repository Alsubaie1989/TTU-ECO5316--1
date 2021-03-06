
library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(ggfortify)
library(egg)
library(tsibble)
library(timetk)
library(lubridate)
library(zoo)
library(forecast)
library(broom)
library(sweep)
library(tidyquant)
library(tsibble)
library(knitr)

# set default theme for ggplot2
theme_set(theme_bw() + 
            theme(strip.background = element_blank()))


B) 

# import the data on All Employees: Total Nonfarm Payrolls,
# then construct log, change, log-change, seasonal log change
jnj_tbl_all <-
  tq_get("PAYNSA",
         get = "economic.data",
         from = "1975-01-01",
         to = "2018-12-01") %>%
  rename(y = price) %>%
  ts(start = c(1975,1), frequency = 12) %>%
  tk_tbl(rename_index = "yearm") %>%
  mutate(yearm = yearmonth(yearm),
         ly = log(y),
         dy = y - lag(y),
         dly1 = ly - lag(ly),
         dly12 = ly - lag(ly, 12),
         d2ly12_1 = dly12 - lag(dly12))


# plot time series: levels, logs, differences


jnj_tbl_all %>%
  gather(variable, value, -yearm) %>%
  mutate(variable_label = factor(variable, ordered = TRUE,
                                 levels = c("y", "ly", "dy", "dly1", "dly12", "d2ly12_1"),
                                 labels = c("y", "log(y)",
                                            expression(paste(Delta,"y")),
                                            expression(paste(Delta,"log(y)")),
                                            expression(paste(Delta[12],"log(y)")),
                                            expression(paste(Delta,Delta[12],"log(y)"))))) %>%
  ggplot(aes(x = yearm, y = value)) +
  geom_hline(aes(yintercept = 0), linetype = "dotted") +
  geom_line() +
  labs(x = "", y = "") +
  facet_wrap(~variable_label, ncol = 3, scales = "free", labeller = label_parsed) +
  theme(strip.text = element_text(hjust = 0),
        strip.background = element_blank())

# y and log y is non  stationary. becuase it  shows trending. Moreover dy 
# is not because vairiance is not constant. otheres look like stationary .delta log shows sesonal pattern

C) 

data_dy <- ts(jnj_tbl_all[, "dy"], frequency = 12, start = c(1975, 1))

ggseasonplot(data_dy)

data_dly1 <- ts(jnj_tbl_all[, "dly1"], frequency = 12, start = c(1975, 1))

ggseasonplot(data_dly1)


# yes there is a seasonal pattren tend to be at the beak on sep and at the minimum at july 


D) 

# plot ACF and PACF
maxlag <-24

g1 <- jnj_tbl_all %>% pull(ly) %>% ggAcf(lag.max = maxlag, ylab = "", main = expression(paste("ACF for log(y)")))
g2 <- jnj_tbl_all %>% pull(dly1) %>% ggAcf(lag.max = maxlag, ylab = "", main = expression(paste("ACF for ", Delta,"log(y)")))
g3 <- jnj_tbl_all %>% pull(dly12) %>% ggAcf(lag.max = maxlag, ylab = "", main = expression(paste("ACF for ", Delta[12], "log(y)")))
g4 <- jnj_tbl_all %>% pull(d2ly12_1) %>% ggAcf(lag.max = maxlag, ylab = "", main = expression(paste("ACF for ", Delta, Delta[12], "log(y)")))
g5 <- jnj_tbl_all %>% pull(ly) %>% ggPacf(lag.max = maxlag, ylab = "", main = expression(paste("PACF for log(y)")))
g6 <- jnj_tbl_all %>% pull(dly1) %>% ggPacf(lag.max = maxlag, ylab = "", main = expression(paste("PACF for ", Delta, "log(y)")))
g7 <- jnj_tbl_all %>% pull(dly12) %>% ggPacf(lag.max = maxlag, ylab = "", main = expression(paste("PACF for ", Delta[12], "log(y)")))
g8 <- jnj_tbl_all %>% pull(d2ly12_1) %>% ggPacf(lag.max = maxlag, ylab = "", main = expression(paste("PACF for ", Delta,Delta[12], "log(y)")))
ggarrange(g1, g2, g3, g4, g5, g6, g7, g8, ncol = 4)

# for log y, acf is showing tails off and pacf is cut off at lag 1, but seasonal every six month
# for delta log y, acf and pacf is showing tails off , but seasonal every six month
# for delat 12 log y, acf and pacf is showing tails off and  seasonal every 12 month
# for delat delat 12 log y, acf and pacf is showing tails off and  seasonal every 12 month


E) 

#  the rule for ADF , if we reject, it is not unit root test, which means it is  stationary,
#the data is stationary and doesn’t need to be differenced
# if fail to reject , it is not stationary (the data needs to be differenced to make it stationary)



# the rule for KPSS , if we reject, it is unit root test which it is not stationary, if not , it is not stationary



afd1<- jnj_tbl_all %>%
  filter( !is.na(ly))%$% 
  ur.df(ly, type="drift", selectlags="AIC")
summary(afd1)


# we fail to reject , not stationary

afds2 <- jnj_tbl_all %>%
  filter( !is.na(dly12))%$% 
  ur.df(dly12, type="none", selectlags="AIC")
summary(afds2)

# at 5% and 10% we reject, it is stationary,  at 1% we fail to reject , not stationary

dfd3<-jnj_tbl_all %>%
  filter( !is.na(d2ly12_1))%$% 
  ur.df(d2ly12_1, type="none", selectlags="AIC")
summary(dfd3)

# we reject, it is stationary

__________________
# now  lets check kpss



kpssdly<- jnj_tbl_all %>%
  filter( !is.na(ly))%$% 
  ur.kpss(ly, type="mu", lags="short")
summary(kpssdly)

# we reject, it is unit root test which it is not stationary. SAME AS ADF


kpssddly12<- jnj_tbl_all %>%
  filter( !is.na(dly12))%$% 
  ur.kpss(dly12, type="mu", lags="short")
summary(kpssddly12)

# we reject, it is unit root test which it is not stationary.

kpssddd2ly12_1<- jnj_tbl_all %>%
  filter( !is.na(d2ly12_1))%$% 
  ur.kpss(d2ly12_1, type="mu", lags="short")
summary(kpssddd2ly12_1)

# we fail to reject it is unit root test. SAME AS ADF

F) 


train.start<-"1975-01-01"
train.start.n<-1975
train.end<-"2014-12-01"
train.end.n <- 2014.916
test.start<-"2015-01-01"
test.start.n<-2015
test.end<-"2018-12-01"

freq<-12

train1<-jnj_tbl_all %>%
  filter( !is.na(d2ly12_1), date<=date(train.end)) %$%
  ts(d2ly12_1, start=train.start.n, frequency=freq)

test1<-jnj_tbl_all %>%
  filter( !is.na(d2ly12_1), date>=date(test.start)) %$%
  ts(d2ly12_1, start=test.start.n, frequency=freq)


Acf(train1, lag.max=48, main=expression(paste("ACF of ", Delta, Delta[12], "d2ly12_1")))
Pacf(train1, lag.max=48, main=expression(paste("PACF of ", Delta, Delta[12], "d2ly12_1")))


# ACF is tail off and pacf is cut off after lag 3 . AR(3), and sessonal will be aram because both of them were tailing off

m1<-Arima(train1, order = c(3,0,0), seasonal=c(1,0,1))
ggtsdiag(m1, gof.lag=48)

autoplot(m1)

G) 
m1<-Arima(train1, order = c(3,0,0), seasonal=c(1,0,1))
ggtsdiag(m1, gof.lag=48)

autoplot(m1)

H) 

jnj_tbl_1 <- jnj_tbl_all %>%
  filter(yearm <= yearmonth(train.start.n))

# window length for rolling SARIMA
data.ts.1 <- jnj_tbl_all %>%
  tk_ts(select = d2ly12_1, start = train.start.n, end = test.start.n , frequency = 12)
window.length <- length(data.ts.1)


# estimate rolling SARIMA model, create 1 step ahead forecasts
results <-
  jnj_tbl_all %>%
  as_tsibble(index = yearm) %>%    
  mutate(sarima.model = slide(d2ly12_1, ~Arima(.x, order = c(3,0,0), seasonal = list(order = c(1,0,1), period = 12)),.size = window.length)) %>%            
  filter(!is.na(sarima.model)) %>%                                                               # remove periods at the beginning of sample where model could not be estimated due to lack of data,
  mutate(sarima.coefs = map(sarima.model, tidy, conf.int = TRUE),
         sarima.fcst = map(sarima.model, (. %>% forecast(1) %>% sw_sweep())))


# extract coefficients
coefs_tbl <- results %>%
  select(yearm, sarima.coefs) %>%
  as_tibble() %>%
  unnest(sarima.coefs) %>%
  as_tsibble(key = id("term"), index = yearm) 

# plot estimated coefficients with confidence intervals
coefs_tbl %>%
  ggplot(aes(x = yearm, y = estimate, group = term)) +
  geom_line(color = "royalblue") +
  geom_ribbon(aes(x = yearm, ymin = conf.low, ymax = conf.high), alpha = 0.5, fill = "lightblue") +
  geom_hline(yintercept = 0, color = "black")+
  labs(x = "", y = "",
       title = "Coefficient estimates",
       subtitle = paste(window.length, "month rolling window model"))+
  facet_wrap(~term, nrow = 1) 


m1_f_1_rol <-
  results %>%
  select(yearm, sarima.fcst) %>%
  as_tibble() %>%
  unnest(sarima.fcst) %>%
  filter(key == "forecast") %>%
  mutate(yearm = yearm %m+% months(1) %>% yearmonth()) %>%
  mutate_at(vars(value, lo.80, lo.95, hi.80, hi.95), list(exp)) %>%
  rename(y = value) %>%
  select(yearm, key, y, lo.80, lo.95, hi.80, hi.95)

jnj_tbl_f_1_rol <- 
  bind_rows(jnj_tbl_all %>%
              mutate(key = "actual") %>%
              select(yearm, key, y),
            m1_f_1_rol) %>%
  mutate(yearm = yearmonth(yearm))


m1_f_1_rol %>%
  filter(yearm >= yearmonth(1975)) %>%
  ggplot(aes(x = yearm, y = y, col = key)) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), linetype = "blank", fill = "blue", alpha = 0.1) +
  geom_ribbon(aes(ymin = lo.80, ymax = hi.80), linetype = "blank", fill = "blue", alpha = 0.2) +
  geom_line() +
  geom_line(data = jnj_tbl_all %>% mutate(key = "actual") %>% filter(yearm > yearmonth(1975)), aes(x = yearm, y = y)) +
  geom_point() +
  scale_color_manual(values = c("gray40","darkblue")) +
  labs(x = "", y = "",
       title = "Earnings per share for Johnson and Johnson: 1-Step Ahead Rolling Forecast") +
  theme(legend.position = "none")
