//+------------------------------------------------------------------+
//|                                                 AverageForce.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  Red
#property indicator_width1  2
#property indicator_label1  "Average Force"

//--- input parameters
input int InpPeriod = 30;                   // Period
input int Smooth    = 18;                    // Smooth

double    AFBuffer[];
double    hhBuffer[];
double    llBuffer[];
double    hhMinusLL[];
double    af[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,AFBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,hhBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,llBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,hhMinusLL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,af,INDICATOR_CALCULATIONS);

//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total<InpPeriod)
      return(0);
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;
   for(int i=start; i<rates_total; i++)
     {
      hhBuffer[i]  = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, InpPeriod, rates_total - 1 - i));
      llBuffer[i]  = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, InpPeriod, rates_total - 1 - i));

      hhMinusLL[i] = hhBuffer[i] - llBuffer[i];
      if(hhMinusLL[i] == 0)
         af[i]=0;
      else
         af[i] = (close[i] - llBuffer[i])/hhMinusLL[i] - 0.5;
     }
      
   SimpleMAOnBuffer(rates_total,prev_calculated,0,Smooth,af,AFBuffer);


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
