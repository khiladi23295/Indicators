//+------------------------------------------------------------------+
//|                                                      VWAP_EMA.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.metaquotes.net/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

// Plot 1 - VWAP Line
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label1  "VWAP"

// Plot 2 - EMA of VWAP Line
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label2  "VWAP EMA"

// Price options enumeration
enum ENUM_VWAP_PRICE
{
   PRICE_TYPICAL_1,    // Typical (H+L+C)/3
   PRICE_MEDIAN_1,     // Median (H+L)/2
   PRICE_CLOSE_1,      // Close
   PRICE_OPEN_1,       // Open
   PRICE_HIGH_1,       // High
   PRICE_LOW_1,        // Low
   PRICE_WEIGHTED_1    // Weighted (H+L+C*2)/4
};

// Input parameters
input int               EMAPeriod = 20;           // EMA Period
input bool              ShowOriginalVWAP = true;  // Show Original VWAP
input ENUM_APPLIED_VOLUME VolumeType = VOLUME_TICK; // Volume type to use
input ENUM_VWAP_PRICE   VwapPriceSource = PRICE_CLOSE_1; // Price for VWAP calculation

// Buffers
double VWAPBuffer[];
double EMABuffer[];

// Variables
datetime currentDay = 0;
double dailyCumulativePV = 0;
double dailyCumulativeVolume = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize buffers
   ArraySetAsSeries(VWAPBuffer, true);
   ArraySetAsSeries(EMABuffer, true);
   
   // Set index buffers
   SetIndexBuffer(0, VWAPBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, EMABuffer, INDICATOR_DATA);
   
   // Set drawing settings
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, EMAPeriod);
   
   // Initialize current day
   MqlDateTime timeStruct;
   TimeCurrent(timeStruct);
   currentDay = timeStruct.year * 10000 + timeStruct.mon * 100 + timeStruct.day;
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Get price for VWAP calculation based on selected method          |
//+------------------------------------------------------------------+
double GetVwapPrice(const double &open[], const double &high[], const double &low[], const double &close[], int index)
{
   switch(VwapPriceSource)
   {
      case PRICE_TYPICAL_1:  return (high[index] + low[index] + close[index]) / 3.0;
      case PRICE_MEDIAN_1:   return (high[index] + low[index]) / 2.0;
      case PRICE_CLOSE_1:    return close[index];
      case PRICE_OPEN_1:     return open[index];
      case PRICE_HIGH_1:     return high[index];
      case PRICE_LOW_1:      return low[index];
      case PRICE_WEIGHTED_1: return (high[index] + low[index] + close[index] * 2) / 4.0;
      default:             return (high[index] + low[index] + close[index]) / 3.0;
   }
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
   // Set arrays as series
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   ArraySetAsSeries(volume, true);
   
   // Check if we have a new day
   MqlDateTime timeStruct;
   TimeCurrent(timeStruct);
   datetime today = timeStruct.year * 10000 + timeStruct.mon * 100 + timeStruct.day;
   
   if(today != currentDay)
   {
      currentDay = today;
      dailyCumulativePV = 0;
      dailyCumulativeVolume = 0;
   }
   
   // Calculate starting index
   int start = (prev_calculated < 1) ? 0 : prev_calculated - 1;
   
   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
      // Get price for VWAP calculation based on selected method
      double vwapPrice = GetVwapPrice(open, high, low, close, i);
      
      // Get volume for the bar
      double barVolume = (VolumeType == VOLUME_TICK) ? (double)tick_volume[i] : (double)volume[i];
      
      // Calculate cumulative price*volume and cumulative volume
      dailyCumulativePV += vwapPrice * barVolume;
      dailyCumulativeVolume += barVolume;
      
      // Calculate VWAP
      if(dailyCumulativeVolume > 0)
      {
         VWAPBuffer[i] = dailyCumulativePV / dailyCumulativeVolume;
      }
      else
      {
         VWAPBuffer[i] = 0;
      }
      
      // Calculate EMA on VWAP
      if(i == 0)
      {
         EMABuffer[i] = VWAPBuffer[i];
      }
      else
      {
         double alpha = 2.0 / (EMAPeriod + 1);
         EMABuffer[i] = VWAPBuffer[i] * alpha + EMABuffer[i-1] * (1 - alpha);
      }
      
      // Hide original VWAP if disabled
      if(!ShowOriginalVWAP)
      {
         VWAPBuffer[i] = EMPTY_VALUE;
      }
   }
   
   return(rates_total);
}