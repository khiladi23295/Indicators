//+------------------------------------------------------------------+
//|                                     SqueezeMomentumIndicator.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                               http://fxstill.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property description "Translate from Pine: Squeeze Momentum Indicator [LazyBear]"
/*********************************************************************************************************
This is a derivative of John Carter's 
"TTM Squeeze" volatility indicator, as discussed in his book "Mastering the Trade" (chapter 11).

Black crosses on the midline show that the market just entered a squeeze 
( Bollinger Bands are with in Keltner Channel).
This signifies low volatility , market preparing itself for an explosive move (up or down).
Gray crosses signify "Squeeze release".

Mr.Carter suggests waiting till the first gray after a black cross, and taking a position in the 
direction of the momentum (for ex., if momentum value is above zero, go long).
Exit the position when the momentum changes (increase or decrease - signified by a color change).

Mr.Carter uses simple momentum indicator , while I have used a different method (linreg based)
to plot the histogram.

More info:
- Book: Mastering The Trade by John F Carter 
*********************************************************************************************************/
#property link      "http://fxstill.com"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   2

#property indicator_label1  "SqueezeMomentum"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLimeGreen, clrGreen, clrRed, clrMaroon
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

#property indicator_label2  "SqueezeMomentumLine"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDodgerBlue, clrBlack, clrGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  5

//--- input parameters
input int      lengthBB                 = 20;          // Bollinger Bands Period
input double   multBB                   = 2.0;         // Bollinger Bands MultFactor
input int      lengthKC                 = 20;          // Keltner Channel Period
input double   multKC                   = 1.5;         // Keltner Channel MultFactor
input ENUM_APPLIED_PRICE  applied_price = PRICE_CLOSE; // type of price or handle 


double iB[], iC[], lB[], lC[];
double srce[];
int kc, bb;

static int MINBAR = MathMax(lengthBB, lengthKC) + 1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   SetIndexBuffer(0, iB,    INDICATOR_DATA);
   SetIndexBuffer(1, iC,    INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, lB,    INDICATOR_DATA);
   SetIndexBuffer(3, lC,    INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(4, srce,  INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(iB,    true);
   ArraySetAsSeries(iC,    true);
   ArraySetAsSeries(srce,   true);
   ArraySetAsSeries(lB, true);
   ArraySetAsSeries(lC,   true);   

   IndicatorSetString(INDICATOR_SHORTNAME,"SQZMOM");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
   kc = iCustom(NULL, 0, "KeltnerChannel", lengthKC, multKC, false, MODE_SMA, applied_price);
   if (kc == INVALID_HANDLE) {
      Print("Error while open KeltnerChannel");
      return(INIT_FAILED);
   }   
   bb = iBands(NULL, 0, lengthBB, 0, multBB, applied_price);
   if (bb == INVALID_HANDLE) {
      Print("Error while open BollingerBands");
      return(INIT_FAILED);
   }      
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason) {

   IndicatorRelease(kc);
   IndicatorRelease(bb);     
}

void GetValue(const double& h[], const double& l[], const double& c[], int shift) {
   
   double bbt[1], bbb[1], kct[1], kcb[1];
   if (CopyBuffer(bb, 1,  shift, 1, bbt) <= 0) return;
   if (CopyBuffer(bb, 2,  shift, 1, bbb) <= 0) return;
   if (CopyBuffer(kc, 0,  shift, 1, kct) <= 0) return; 
   if (CopyBuffer(kc, 2,  shift, 1, kcb) <= 0) return; 
  
   bool sqzOn  = (bbb[0] > kcb[0]) && (bbt[0] < kct[0]);
   bool sqzOff = (bbb[0] < kcb[0]) && (bbt[0] > kct[0]);
   bool noSqz  = (sqzOn == false)  && (sqzOff == false); 
   
   int indh = iHighest(NULL, 0, MODE_HIGH, lengthKC, shift); 
   if (indh == -1) return;
   int indl = iLowest(NULL, 0, MODE_LOW, lengthKC, shift);
   if (indl == -1) return;       
   double avg = (h[indh] + l[indl]) / 2;
          avg = (avg + (kct[0] + kcb[0]) / 2) / 2;
   srce[shift] = c[shift] - avg; 
     
   double error;
   iB[shift] = LinearRegression(srce, lengthKC, shift, error);
   
   if (iB[shift] > 0){
      if(iB[shift] < iB[shift + 1]) iC[shift] = 1;
   } else {
      if(iB[shift] < iB[shift + 1]) iC[shift] = 2;
      else iC[shift] = 3;
   }
   
   if (!noSqz) {
      lC[shift] = (sqzOn)? 1: 2;
   }
}

double LinearRegression(const double& array[], int period, int shift, double& error) {
  
   double sx = 0, sy = 0, sxy = 0, sxx = 0, syy = 0, y = 0;
   
   int param = (ArrayIsSeries(array) )? -1: 1;
   
   for (int x = 0; x < period; x++) {
      y    = array[shift + param * x];
      sx  += x;
      sy  += y;
      sxx += x * x;
      sxy += x * y;
      syy += y * y;
   }//for (int x = 1; x <= period; x++)
               
   double slope = (period * sxy - sx * sy) / (sx * sx - period * sxx);
   double intercept = (sy - slope * sx) / period;
   error = MathSqrt((period * syy - sy * sy - slope * slope * (period * sxx - sx*sx)) / 
                    (period * (period - 2)) );
                    
   return intercept + slope * period;
}//double LinearRegression(const double& array[], int shift)

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
      if(rates_total <= 4) return 0;
      ArraySetAsSeries(close,true);    
      ArraySetAsSeries(high,true); 
      ArraySetAsSeries(low,true); 
      int limit = rates_total - prev_calculated;
      if (limit == 0)        {   //A new tick has come
      } else if (limit == 1) {   // A new bar is formed
         GetValue(high, low, close, 1);      
      } else if (limit > 1)  {   // The first call of the indicator, changing the timeframe, loading data from history
         ArrayInitialize(iB,    EMPTY_VALUE);
         ArrayInitialize(iC,    0);
         ArrayInitialize(lB,    0);
         ArrayInitialize(lC,    0);         
         ArrayInitialize(srce,  0);
         limit = rates_total - MINBAR;
         for(int i = limit; i >= 1 && !IsStopped(); i--){
            GetValue(high, low, close, i);
         }//for(int i = limit + 1; i >= 0 && !IsStopped(); i--)
         return(rates_total);         
      }
//      GetValue(high, low, close, 0);          
   return(rates_total);
  
  
}
//+------------------------------------------------------------------+