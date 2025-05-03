//+------------------------------------------------------------------+
//|                                                         VWAP.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "YOLO Ltd"
#property version     "1.47"
#property description "Contact for EA development on Telegram: @deathstroke_1995"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

//--- plot VWAP
#property indicator_label1  "VWAP"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_DASH
#property indicator_width1  2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum DATE_TYPE
  {
   DAILY,
   WEEKLY,
   MONTHLY
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum PRICE_TYPE
  {
   OPEN,
   CLOSE,
   HIGH,
   LOW,
   OPEN_CLOSE,
   HIGH_LOW,
   CLOSE_HIGH_LOW,
   OPEN_CLOSE_HIGH_LOW
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CreateDateTime(DATE_TYPE nReturnType=DAILY,datetime dtDay=D'2000.01.01 00:00:00',int pHour=0,int pMinute=0,int pSecond=0)
  {
   datetime    dtReturnDate;
   MqlDateTime timeStruct;

   TimeToStruct(dtDay,timeStruct);
   timeStruct.hour = pHour;
   timeStruct.min  = pMinute;
   timeStruct.sec  = pSecond;
   dtReturnDate=(StructToTime(timeStruct));

   if(nReturnType==WEEKLY)
     {
      while(timeStruct.day_of_week!=0)
        {
         dtReturnDate=(dtReturnDate-86400);
         TimeToStruct(dtReturnDate,timeStruct);
        }
     }

   if(nReturnType==MONTHLY)
     {
      timeStruct.day=1;
      dtReturnDate=(StructToTime(timeStruct));
     }

   return dtReturnDate;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input   PRICE_TYPE          Price_Type              = CLOSE;
input   bool                Enable_Daily            = true;

bool        Show_Daily_Value    = true;
bool        Show_Weekly_Value   = true;
bool        Show_Monthly_Value  = true;

double      VWAP_Buffer_Daily[];
double      VWAP_Buffer_Weekly[];
double      VWAP_Buffer_Monthly[];
double      VWAP_Buffer_01[];
double      VWAP_Buffer_02[];
double      VWAP_Buffer_03[];
double      VWAP_Buffer_04[];
double      VWAP_Buffer_05[];

double      nPriceArr[];
double      nTotalTPV[];
double      nTotalVol[];
double      nSumDailyTPV = 0, nSumWeeklyTPV = 0, nSumMonthlyTPV = 0;
double      nSumDailyVol = 0, nSumWeeklyVol = 0, nSumMonthlyVol = 0;

int         nIdxDaily=0,nIdxWeekly=0,nIdxMonthly=0,nIdx=0;

bool        bIsFirstRun=true;

ENUM_TIMEFRAMES LastTimePeriod=PERIOD_MN1;

string      sDailyStr   = "";
string      sWeeklyStr  = "";
string      sMonthlyStr = "";
string      sLevel01Str = "";
string      sLevel02Str = "";
string      sLevel03Str = "";
string      sLevel04Str = "";
string      sLevel05Str = "";
datetime    dtLastDay=CreateDateTime(DAILY),dtLastWeek=CreateDateTime(WEEKLY),dtLastMonth=CreateDateTime(MONTHLY);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   SetIndexBuffer(0,VWAP_Buffer_Daily,INDICATOR_DATA);

   ObjectCreate(0,"VWAP_Daily",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_CORNER,3);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_XDISTANCE,180);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_YDISTANCE,40);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_COLOR,indicator_color1);
   ObjectSetInteger(0,"VWAP_Daily",OBJPROP_FONTSIZE,7);
   ObjectSetString(0,"VWAP_Daily",OBJPROP_FONT,"Verdana");
   ObjectSetString(0,"VWAP_Daily",OBJPROP_TEXT," ");

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int pReason)
  {
   ObjectDelete(0,"VWAP_Daily");
   ObjectDelete(0,"VWAP_Weekly");
   ObjectDelete(0,"VWAP_Monthly");
   ObjectDelete(0,"VWAP_Level_01");
   ObjectDelete(0,"VWAP_Level_02");
   ObjectDelete(0,"VWAP_Level_03");
   ObjectDelete(0,"VWAP_Level_04");
   ObjectDelete(0,"VWAP_Level_05");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime  &time[],
                const double    &open[],
                const double    &high[],
                const double    &low[],
                const double    &close[],
                const long      &tick_volume[],
                const long      &volume[],
                const int       &spread[])
  {

   if(PERIOD_CURRENT!=LastTimePeriod)
     {
      bIsFirstRun=true;
      LastTimePeriod=PERIOD_CURRENT;
     }

   if(rates_total>prev_calculated || bIsFirstRun)
     {
      ArrayResize(nPriceArr,rates_total);
      ArrayResize(nTotalTPV,rates_total);
      ArrayResize(nTotalVol,rates_total);

      if(Enable_Daily)
        {
         nIdx = nIdxDaily;
         nSumDailyTPV = 0;
         nSumDailyVol = 0;
        }

      for(; nIdx<rates_total; nIdx++)
        {
         if(CreateDateTime(DAILY,time[nIdx])!=dtLastDay)
           {
            nIdxDaily=nIdx;
            nSumDailyTPV = 0;
            nSumDailyVol = 0;
           }
         if(CreateDateTime(WEEKLY,time[nIdx])!=dtLastWeek)
           {
            nIdxWeekly=nIdx;
            nSumWeeklyTPV = 0;
            nSumWeeklyVol = 0;
           }
         if(CreateDateTime(MONTHLY,time[nIdx])!=dtLastMonth)
           {
            nIdxMonthly=nIdx;
            nSumMonthlyTPV = 0;
            nSumMonthlyVol = 0;
           }

         nPriceArr[nIdx] = 0;
         nTotalTPV[nIdx] = 0;
         nTotalVol[nIdx] = 0;

         switch(Price_Type)
           {
            case OPEN:
               nPriceArr[nIdx]=open[nIdx];
               break;
            case CLOSE:
               nPriceArr[nIdx]=close[nIdx];
               break;
            case HIGH:
               nPriceArr[nIdx]=high[nIdx];
               break;
            case LOW:
               nPriceArr[nIdx]=low[nIdx];
               break;
            case HIGH_LOW:
               nPriceArr[nIdx]=(high[nIdx]+low[nIdx])/2;
               break;
            case OPEN_CLOSE:
               nPriceArr[nIdx]=(open[nIdx]+close[nIdx])/2;
               break;
            case CLOSE_HIGH_LOW:
               nPriceArr[nIdx]=(close[nIdx]+high[nIdx]+low[nIdx])/3;
               break;
            case OPEN_CLOSE_HIGH_LOW:
               nPriceArr[nIdx]=(open[nIdx]+close[nIdx]+high[nIdx]+low[nIdx])/4;
               break;
            default:
               nPriceArr[nIdx]=(close[nIdx]+high[nIdx]+low[nIdx])/3;
               break;
           }

         if(tick_volume[nIdx])
           {
            nTotalTPV[nIdx] = (nPriceArr[nIdx] * tick_volume[nIdx]);
            nTotalVol[nIdx] = (double)tick_volume[nIdx];
           }
         else
            if(volume[nIdx])
              {
               nTotalTPV[nIdx] = (nPriceArr[nIdx] * volume[nIdx]);
               nTotalVol[nIdx] = (double)volume[nIdx];
              }

         if(Enable_Daily && (nIdx>=nIdxDaily))
           {
            nSumDailyTPV += nTotalTPV[nIdx];
            nSumDailyVol += nTotalVol[nIdx];

            if(nSumDailyVol)
               VWAP_Buffer_Daily[nIdx]=(nSumDailyTPV/nSumDailyVol);

            if((sDailyStr!="VWAP: "+(string)NormalizeDouble(VWAP_Buffer_Daily[nIdx],_Digits)) && Show_Daily_Value)
              {
               sDailyStr="VWAP: "+(string)NormalizeDouble(VWAP_Buffer_Daily[nIdx],_Digits);
               ObjectSetString(0,"VWAP_Daily",OBJPROP_TEXT,sDailyStr);
              }
           }

         dtLastDay=CreateDateTime(DAILY,time[nIdx]);
         dtLastWeek=CreateDateTime(WEEKLY,time[nIdx]);
         dtLastMonth=CreateDateTime(MONTHLY,time[nIdx]);
        }

      bIsFirstRun=false;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
