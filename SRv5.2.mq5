#property copyright "YOLO Ltd"
#property version "5.2"
#property description "Under Construction, more features will be added later"


#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   11

double               zone_fuzzfactor = 0.75;             // Zone ATR Factor
bool                 zone_merge = true;                  // Zone Merge
bool                 zone_extend = true;                 // Zone Extend
double               fractal_fast_factor = 3.0;          // Fractal Fast Factor
double               fractal_slow_factor = 6.0;          // Fractal slow Factor

input string               basic_settings = "=== Basic Settings ===";
input ENUM_TIMEFRAMES      Timeframe = PERIOD_CURRENT;         // Timeframe
input int                  BackLimit = 1000;                   // LookBack Bars

input string               zone_settings = "=== SR Zone Settings ===";
input bool                 zone_show_weak = false;             // Show S/R Weak Zones
input bool                 zone_show_untested = true;          // Show S/R Untested Zones
input bool                 zone_show_turncoat = true;          // Show S/R Broken Zones

input string               alert_settings= "=== Alert Settings ===";
input bool                 zone_show_alerts  = false;        // Trigger alert when entering a zone
input bool                 zone_alert_popups = true;         // Show alert window
input bool                 zone_alert_sounds = true;         // Play alert sound
input bool                 zone_send_notification = false;   // Send notification when entering a zone
input int                  zone_alert_waitseconds = 300;     // Delay between alerts (seconds)

string               string_prefix = "SRRR";             // Change prefix to add multiple indicators to chart
bool                 zone_solid = true;                  // Fill zone with color
int                  zone_linewidth = 1;                 // Zone border width
ENUM_LINE_STYLE      zone_style = STYLE_SOLID;           // Zone border style
bool                 zone_show_info = true;              // Show info labels
int                  zone_label_shift = 10;              // Info label shift
string               sup_name = "Support";                   // Support Name
string               res_name = "Resistance";                   // Resistance Name
string               test_name = "Retest Zone";              // Retest Name
int                  Text_size = 8;                      // Text Size
string               Text_font = "Courier New";          // Text Font
color                Text_color = clrBlack;              // Text Color
color color_support_weak     = clrDarkSlateGray;         // Color for weak support zone
color color_support_untested = clrSeaGreen;              // Color for untested support zone
color color_support_verified = clrGreen;                 // Color for verified support zone
color color_support_proven   = clrLimeGreen;             // Color for proven support zone
color color_support_turncoat = clrOliveDrab;             // Color for turncoat(broken) support zone
color color_resist_weak      = clrIndigo;                // Color for weak resistance zone
color color_resist_untested  = clrOrangeRed;                // Color for untested resistance zone
color color_resist_verified  = clrCrimson;               // Color for verified resistance zone
color color_resist_proven    = clrRed;                   // Color for proven resistance zone
color color_resist_turncoat  = clrDarkOrange;            // Color for broken resistance zone

ENUM_TIMEFRAMES timeframe;
double FastDnPts[],FastUpPts[];
double SlowDnPts[],SlowUpPts[];

double zone_hi[1000],zone_lo[1000];
int    zone_start[1000],zone_hits[1000],zone_type[1000],zone_strength[1000],zone_count=0;
bool   zone_turn[1000];

#define ZONE_SUPPORT 1
#define ZONE_RESIST  2

#define ZONE_WEAK      0
#define ZONE_TURNCOAT  1
#define ZONE_UNTESTED  2
#define ZONE_VERIFIED  3
#define ZONE_PROVEN    4

#define UP_POINT 1
#define DN_POINT -1

int time_offset=0;

double ner_lo_zone_P1[];
double ner_lo_zone_P2[];
double ner_hi_zone_P1[];
double ner_hi_zone_P2[];
double ner_hi_zone_strength[];
double ner_lo_zone_strength[];
double ner_price_inside_zone[];
int iATR_handle;
double ATR[];
int cnt=0;
bool try_again=false;
string comment="Updating Chart...";
string prefix;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   prefix=string_prefix+"#";
   if(Timeframe==PERIOD_CURRENT)
      timeframe=Period();
   else
      timeframe=Timeframe;
   iATR_handle=iATR(NULL,timeframe,7);
   SetIndexBuffer(0,SlowDnPts,INDICATOR_DATA);
   SetIndexBuffer(1,SlowUpPts,INDICATOR_DATA);
   SetIndexBuffer(2,FastDnPts,INDICATOR_DATA);
   SetIndexBuffer(3,FastUpPts,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
   SetIndexBuffer(4,ner_hi_zone_P1,INDICATOR_DATA);
   SetIndexBuffer(5,ner_hi_zone_P2,INDICATOR_DATA);
   SetIndexBuffer(6,ner_lo_zone_P1,INDICATOR_DATA);
   SetIndexBuffer(7,ner_lo_zone_P2,INDICATOR_DATA);
   SetIndexBuffer(8,ner_hi_zone_strength,INDICATOR_DATA);
   SetIndexBuffer(9,ner_lo_zone_strength,INDICATOR_DATA);
   SetIndexBuffer(10,ner_price_inside_zone,INDICATOR_DATA);
   PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(8,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(9,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(10,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetString(4,PLOT_LABEL,"Resistant Zone High");
   PlotIndexSetString(5,PLOT_LABEL,"Resistant Zone Low");
   PlotIndexSetString(6,PLOT_LABEL,"Support Zone High");
   PlotIndexSetString(7,PLOT_LABEL,"Support Zone Low");
   PlotIndexSetString(8,PLOT_LABEL,"Resistant Zone Strength");
   PlotIndexSetString(9,PLOT_LABEL,"Support Zone Strength");
   PlotIndexSetString(10,PLOT_LABEL,"Price Inside Zone");
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   ArraySetAsSeries(SlowDnPts,true);
   ArraySetAsSeries(SlowUpPts,true);
   ArraySetAsSeries(FastDnPts,true);
   ArraySetAsSeries(FastUpPts,true);
   ArraySetAsSeries(ner_hi_zone_P1,true);
   ArraySetAsSeries(ner_hi_zone_P2,true);
   ArraySetAsSeries(ner_lo_zone_P1,true);
   ArraySetAsSeries(ner_lo_zone_P2,true);
   ArraySetAsSeries(ner_hi_zone_strength,true);
   ArraySetAsSeries(ner_lo_zone_strength,true);
   ArraySetAsSeries(ner_price_inside_zone,true);
   
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteZones();
   if(StringFind(ChartGetString(0,CHART_COMMENT),comment)>=0)
      Comment("");
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   if(NewBar()==true || (timeframe!=PERIOD_CURRENT && try_again==true))
     {
      int old_zone_count=zone_count;
      FastFractals();
      SlowFractals();
      DeleteZones();
      FindZones();
      DrawZones();
      if(zone_show_info==true)
        {
         showLabels();
        }
     }
   CheckAlerts();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckAlerts()
  {
   if(zone_show_alerts==false && zone_send_notification==false)
      return;
   datetime Time[];
   if(CopyTime(Symbol(),timeframe,0,1,Time)==-1)
      return;
   ArraySetAsSeries(Time,true);
   static int lastalert;
   if(Time[0]-lastalert>zone_alert_waitseconds)
      if(CheckEntryAlerts()==true)
         lastalert=int(Time[0]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckEntryAlerts()
  {
   double Close[];
   ArraySetAsSeries(Close,true);
   CopyClose(Symbol(),timeframe,0,1,Close);
// check for entries
   for(int i=0; i<zone_count; i++)
     {
      if(zone_strength[i]==ZONE_WEAK && zone_show_weak==false)
         continue;
      if(zone_strength[i]==ZONE_UNTESTED && zone_show_untested==false)
         continue;
      if(zone_strength[i]==ZONE_TURNCOAT && zone_show_turncoat==false)
         continue;
      if(Close[0]>=zone_lo[i] && Close[0]<zone_hi[i])
        {
         if(zone_show_alerts==true)
           {
            if(zone_alert_popups==true)
              {
               if(zone_type[i]==ZONE_SUPPORT)
                  Alert(Symbol()+" "+TFTS(timeframe)+": Support Zone Entered.");
               else
                  Alert(Symbol()+" "+TFTS(timeframe)+": Resistance Zone Entered.");
              }
            if(zone_alert_sounds==true)
               PlaySound("alert.wav");
           }
         if(zone_send_notification==true)
           {
            if(zone_type[i]==ZONE_SUPPORT)
               SendNotification(Symbol()+" "+TFTS(timeframe)+": Support Zone Entered.");
            else
               SendNotification(Symbol()+" "+TFTS(timeframe)+": Resistance Zone Entered.");
           }
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindZones()
  {
   int i,j,shift,bustcount=0,testcount=0;
   double hival,loval;
   bool turned=false,hasturned=false;
   double temp_hi[1000],temp_lo[1000];
   int    temp_start[1000],temp_hits[1000],temp_strength[1000],temp_count=0;
   bool   temp_turn[1000],temp_merge[1000];
   int merge1[1000],merge2[1000],merge_count=0;
// iterate through zones from oldest to youngest (ignore recent 5 bars),
// finding those that have survived through to the present___
   shift=MathMin(Bars(Symbol(),timeframe)-1,BackLimit+cnt);
   shift=MathMin(shift,ArraySize(FastUpPts)-1);
   double Close[],High[],Low[];
   ArraySetAsSeries(Close,true);
   CopyClose(Symbol(),timeframe,0,shift+1,Close);
   ArraySetAsSeries(High,true);
   CopyHigh(Symbol(),timeframe,0,shift+1,High);
   ArraySetAsSeries(Low,true);
   CopyLow(Symbol(),timeframe,0,shift+1,Low);
   ArraySetAsSeries(ATR,true);
   if(CopyBuffer(iATR_handle,0,0,shift+1,ATR)==-1)
     {
      try_again=true;
      Comment(comment);
      return;
     }
   else
     {
      if(StringFind(ChartGetString(0,CHART_COMMENT),comment)>=0)
         Comment("");
      try_again=false;
     }
   for(int ii=shift; ii>cnt+5; ii--)
     {
      double atr= ATR[ii];
      double fu = atr/2 * zone_fuzzfactor;
      bool isWeak;
      bool touchOk= false;
      bool isBust = false;
      if(FastUpPts[ii]>0.001)
        {
         // a zigzag high point
         isWeak=true;
         if(SlowUpPts[ii]>0.001)
            isWeak=false;
         hival=High[ii];
         if(zone_extend==true)
            hival+=fu;
         loval=MathMax(MathMin(Close[ii],High[ii]-fu),High[ii]-fu*2);
         turned=false;
         hasturned=false;
         isBust=false;
         bustcount = 0;
         testcount = 0;
         for(i=ii-1; i>=cnt+0; i--)
           {
            if((turned==false && FastUpPts[i]>=loval && FastUpPts[i]<=hival) ||
               (turned==true && FastDnPts[i]<=hival && FastDnPts[i]>=loval))
              {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk=true;
               for(j=i+1; j<i+11; j++)
                 {
                  if((turned==false && FastUpPts[j]>=loval && FastUpPts[j]<=hival) ||
                     (turned==true && FastDnPts[j]<=hival && FastDnPts[j]>=loval))
                    {
                     touchOk=false;
                     break;
                    }
                 }
               if(touchOk==true)
                 {
                  // we have a touch_  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount=0;
                  testcount++;
                 }
              }
            if((turned==false && High[i]>hival) ||
               (turned==true && Low[i]<loval))
              {
               // this level has been busted at least once
               bustcount++;
               if(bustcount>1 || isWeak==true)
                 {
                  // busted twice or more
                  isBust=true;
                  break;
                 }
               if(turned == true)
                  turned = false;
               else
                  if(turned==false)
                     turned=true;
               hasturned=true;
               // forget previous hits
               testcount=0;
              }
           }
         if(isBust==false)
           {
            // level is still valid, add to our list
            temp_hi[temp_count] = hival;
            temp_lo[temp_count] = loval;
            temp_turn[temp_count] = hasturned;
            temp_hits[temp_count] = testcount;
            temp_start[temp_count] = ii;
            temp_merge[temp_count] = false;
            if(testcount>3)
               temp_strength[temp_count]=ZONE_PROVEN;
            else
               if(testcount>0)
                  temp_strength[temp_count]=ZONE_VERIFIED;
               else
                  if(hasturned==true)
                     temp_strength[temp_count]=ZONE_TURNCOAT;
                  else
                     if(isWeak==false)
                        temp_strength[temp_count]=ZONE_UNTESTED;
                     else
                        temp_strength[temp_count]=ZONE_WEAK;
            temp_count++;
           }
        }
      else
         if(FastDnPts[ii]>0.001)
           {
            // a zigzag low point
            isWeak=true;
            if(SlowDnPts[ii]>0.001)
               isWeak=false;
            loval=Low[ii];
            if(zone_extend==true)
               loval-=fu;
            hival=MathMin(MathMax(Close[ii],Low[ii]+fu),Low[ii]+fu*2);
            turned=false;
            hasturned=false;
            bustcount = 0;
            testcount = 0;
            isBust=false;
            for(i=ii-1; i>=cnt+0; i--)
              {
               if((turned==true && FastUpPts[i]>=loval && FastUpPts[i]<=hival) ||
                  (turned==false && FastDnPts[i]<=hival && FastDnPts[i]>=loval))
                 {
                  // Potential touch, just make sure its been 10+candles since the prev one
                  touchOk=true;
                  for(j=i+1; j<i+11; j++)
                    {
                     if((turned==true && FastUpPts[j]>=loval && FastUpPts[j]<=hival) ||
                        (turned==false && FastDnPts[j]<=hival && FastDnPts[j]>=loval))
                       {
                        touchOk=false;
                        break;
                       }
                    }
                  if(touchOk==true)
                    {
                     // we have a touch_  If its been busted once, remove bustcount
                     // as we know this level is still valid & has just switched sides
                     bustcount=0;
                     testcount++;
                    }
                 }
               if((turned==true && High[i]>hival) ||
                  (turned==false && Low[i]<loval))
                 {
                  // this level has been busted at least once
                  bustcount++;
                  if(bustcount>1 || isWeak==true)
                    {
                     // busted twice or more
                     isBust=true;
                     break;
                    }
                  if(turned == true)
                     turned = false;
                  else
                     if(turned==false)
                        turned=true;
                  hasturned=true;
                  // forget previous hits
                  testcount=0;
                 }
              }
            if(isBust==false)
              {
               // level is still valid, add to our list
               temp_hi[temp_count] = hival;
               temp_lo[temp_count] = loval;
               temp_turn[temp_count] = hasturned;
               temp_hits[temp_count] = testcount;
               temp_start[temp_count] = ii;
               temp_merge[temp_count] = false;
               if(testcount>3)
                  temp_strength[temp_count]=ZONE_PROVEN;
               else
                  if(testcount>0)
                     temp_strength[temp_count]=ZONE_VERIFIED;
                  else
                     if(hasturned==true)
                        temp_strength[temp_count]=ZONE_TURNCOAT;
                     else
                        if(isWeak==false)
                           temp_strength[temp_count]=ZONE_UNTESTED;
                        else
                           temp_strength[temp_count]=ZONE_WEAK;
               temp_count++;
              }
           }
     }
// look for overlapping zones___
   if(zone_merge==true)
     {
      merge_count=1;
      int iterations=0;
      while(merge_count>0 && iterations<3)
        {
         merge_count=0;
         iterations++;
         for(i=0; i<temp_count; i++)
            temp_merge[i]=false;
         for(i=0; i<temp_count-1; i++)
           {
            if(temp_hits[i]==-1 || temp_merge[i]==true)
               continue;
            for(j=i+1; j<temp_count; j++)
              {
               if(temp_hits[j]==-1 || temp_merge[j]==true)
                  continue;
               if((temp_hi[i]>=temp_lo[j] && temp_hi[i]<=temp_hi[j]) ||
                  (temp_lo[i] <= temp_hi[j] && temp_lo[i] >= temp_lo[j]) ||
                  (temp_hi[j] >= temp_lo[i] && temp_hi[j] <= temp_hi[i]) ||
                  (temp_lo[j] <= temp_hi[i] && temp_lo[j] >= temp_lo[i]))
                 {
                  merge1[merge_count] = i;
                  merge2[merge_count] = j;
                  temp_merge[i] = true;
                  temp_merge[j] = true;
                  merge_count++;
                 }
              }
           }
         // ___ and merge them ___
         for(i=0; i<merge_count; i++)
           {
            int target = merge1[i];
            int source = merge2[i];
            temp_hi[target] = MathMax(temp_hi[target], temp_hi[source]);
            temp_lo[target] = MathMin(temp_lo[target], temp_lo[source]);
            temp_hits[target] += temp_hits[source];
            temp_start[target] = MathMax(temp_start[target], temp_start[source]);
            temp_strength[target]=MathMax(temp_strength[target],temp_strength[source]);
            if(temp_hits[target]>3)
               temp_strength[target]=ZONE_PROVEN;
            if(temp_hits[target]==0 && temp_turn[target]==false)
              {
               temp_hits[target]=1;
               if(temp_strength[target]<ZONE_VERIFIED)
                  temp_strength[target]=ZONE_VERIFIED;
              }
            if(temp_turn[target] == false || temp_turn[source] == false)
               temp_turn[target] = false;
            if(temp_turn[target] == true)
               temp_hits[target] = 0;
            temp_hits[source]=-1;
           }
        }
     }
// copy the remaining list into our official zones arrays
   zone_count=0;
   for(i=0; i<temp_count; i++)
     {
      if(temp_hits[i]>=0 && zone_count<1000)
        {
         zone_hi[zone_count]       = temp_hi[i];
         zone_lo[zone_count]       = temp_lo[i];
         zone_hits[zone_count]     = temp_hits[i];
         zone_turn[zone_count]     = temp_turn[i];
         zone_start[zone_count]    = temp_start[i];
         zone_strength[zone_count] = temp_strength[i];
         if(zone_hi[zone_count]<Close[cnt+0])
            zone_type[zone_count]=ZONE_SUPPORT;
         else
            if(zone_lo[zone_count]>Close[cnt+0])
               zone_type[zone_count]=ZONE_RESIST;
            else
              {
               int  sh=MathMin(Bars(Symbol(),timeframe)-1,BackLimit+cnt);
               for(j=cnt+1; j<sh; j++)
                 {
                  if(Close[j]<zone_lo[zone_count])
                    {
                     zone_type[zone_count]=ZONE_RESIST;
                     break;
                    }
                  else
                     if(Close[j]>zone_hi[zone_count])
                       {
                        zone_type[zone_count]=ZONE_SUPPORT;
                        break;
                       }
                 }
               if(j==sh)
                  zone_type[zone_count]=ZONE_SUPPORT;
              }
         zone_count++;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawZones()
  {
   double lower_nerest_zone_P1=0;
   double lower_nerest_zone_P2=0;
   double higher_nerest_zone_P1=99999;
   double higher_nerest_zone_P2=99999;
   double higher_zone_type=0;
   double higher_zone_strength=0;
   double lower_zone_type=0;
   double lower_zone_strength=0;
   for(int i=0; i<zone_count; i++)
     {
      if(zone_strength[i]==ZONE_WEAK && zone_show_weak==false)
         continue;
      if(zone_strength[i]==ZONE_UNTESTED && zone_show_untested==false)
         continue;
      if(zone_strength[i]==ZONE_TURNCOAT && zone_show_turncoat==false)
         continue;
      //name sup
      string s;
      if(zone_type[i]==ZONE_SUPPORT)
         s=prefix+"S"+string(i)+" Strength=";
      else
         //name res
         s=prefix+"R"+string(i)+" Strength=";
      if(zone_strength[i]==ZONE_PROVEN)
         s=s+"Proven, Test Count="+string(zone_hits[i]);
      else
         if(zone_strength[i]==ZONE_VERIFIED)
            s=s+"Verified, Test Count="+string(zone_hits[i]);
         else
            if(zone_strength[i]==ZONE_UNTESTED)
               s=s+"Untested";
            else
               if(zone_strength[i]==ZONE_TURNCOAT)
                  s=s+"Turncoat";
               else
                  s=s+"Weak";
      datetime Time[];
      if(CopyTime(Symbol(),timeframe,0,zone_start[i]+1,Time)==-1)
        {
         Comment(comment);
         return;
        }
      else
        {
         if(StringFind(ChartGetString(0,CHART_COMMENT),comment)>=0)
            Comment("");
        }
      ArraySetAsSeries(Time,true);
      datetime current_time,start_time;
      if(cnt==0)
         current_time=iTime(NULL,0,0);
      else
         current_time=Time[cnt+0];
      if(iTime(NULL,0,TerminalInfoInteger(TERMINAL_MAXBARS)-1)>Time[zone_start[i]])
        {
         start_time=iTime(NULL,0,TerminalInfoInteger(TERMINAL_MAXBARS)-1);
        }
      else
         start_time=Time[zone_start[i]];
      ObjectCreate(0,s,OBJ_RECTANGLE,0,0,0,0,0);
      ObjectSetInteger(0,s,OBJPROP_TIME,0,start_time);
      ObjectSetInteger(0,s,OBJPROP_TIME,1,current_time);
      ObjectSetDouble(0,s,OBJPROP_PRICE,0,zone_hi[i]);
      ObjectSetDouble(0,s,OBJPROP_PRICE,1,zone_lo[i]);
      ObjectSetInteger(0,s,OBJPROP_BACK,true);
      ObjectSetInteger(0,s,OBJPROP_FILL,zone_solid);
      ObjectSetInteger(0,s,OBJPROP_WIDTH,zone_linewidth);
      ObjectSetInteger(0,s,OBJPROP_STYLE,zone_style);
      if(zone_type[i]==ZONE_SUPPORT)
        {
         // support zone
         if(zone_strength[i]==ZONE_TURNCOAT)
            ObjectSetInteger(0,s,OBJPROP_COLOR,color_support_turncoat);
         else
            if(zone_strength[i]==ZONE_PROVEN)
               ObjectSetInteger(0,s,OBJPROP_COLOR,color_support_proven);
            else
               if(zone_strength[i]==ZONE_VERIFIED)
                  ObjectSetInteger(0,s,OBJPROP_COLOR,color_support_verified);
               else
                  if(zone_strength[i]==ZONE_UNTESTED)
                     ObjectSetInteger(0,s,OBJPROP_COLOR,color_support_untested);
                  else
                     ObjectSetInteger(0,s,OBJPROP_COLOR,color_support_weak);
        }
      else
        {
         // resistance zone
         if(zone_strength[i]==ZONE_TURNCOAT)
            ObjectSetInteger(0,s,OBJPROP_COLOR,color_resist_turncoat);
         else
            if(zone_strength[i]==ZONE_PROVEN)
               ObjectSetInteger(0,s,OBJPROP_COLOR,color_resist_proven);
            else
               if(zone_strength[i]==ZONE_VERIFIED)
                  ObjectSetInteger(0,s,OBJPROP_COLOR,color_resist_verified);
               else
                  if(zone_strength[i]==ZONE_UNTESTED)
                     ObjectSetInteger(0,s,OBJPROP_COLOR,color_resist_untested);
                  else
                     ObjectSetInteger(0,s,OBJPROP_COLOR,color_resist_weak);
        }
      //nearest zones
      double price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
      if(zone_lo[i]>lower_nerest_zone_P2 && price>zone_lo[i])
        {
         lower_nerest_zone_P1=zone_hi[i];
         lower_nerest_zone_P2=zone_lo[i];
         higher_zone_type=zone_type[i];
         lower_zone_strength=zone_strength[i];
        }
      if(zone_hi[i]<higher_nerest_zone_P1 && price<zone_hi[i])
        {
         higher_nerest_zone_P1=zone_hi[i];
         higher_nerest_zone_P2=zone_lo[i];
         lower_zone_type=zone_type[i];
         higher_zone_strength=zone_strength[i];
        }
     }
   ner_hi_zone_P1[0]=higher_nerest_zone_P1;
   ner_hi_zone_P2[0]=higher_nerest_zone_P2;
   ner_lo_zone_P1[0]=lower_nerest_zone_P1;
   ner_lo_zone_P2[0]=lower_nerest_zone_P2;
   ner_hi_zone_strength[0]=higher_zone_strength;
   ner_lo_zone_strength[0]=lower_zone_strength;
   if(ner_hi_zone_P1[0]==ner_lo_zone_P1[0])
      ner_price_inside_zone[0]=higher_zone_type;
   else
      ner_price_inside_zone[0]=0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Fractal(int M,int P,int shift)
  {
   if(timeframe>P)
      P=timeframe;
   P=int(P/int(timeframe)*2+MathCeil(P/timeframe/2));
   if(shift<P)
      return(false);
   if(shift>Bars(Symbol(),timeframe)-P-1)
      return(false);
   double High[],Low[];
   ArraySetAsSeries(High,true);
   CopyHigh(Symbol(),timeframe,0,shift+P+1,High);
   ArraySetAsSeries(Low,true);
   CopyLow(Symbol(),timeframe,0,shift+P+1,Low);
   for(int i=1; i<=P; i++)
     {
      if(M==UP_POINT)
        {
         if(High[shift+i]>High[shift])
            return(false);
         if(High[shift-i]>=High[shift])
            return(false);
        }
      if(M==DN_POINT)
        {
         if(Low[shift+i]<Low[shift])
            return(false);
         if(Low[shift-i]<=Low[shift])
            return(false);
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime LastTime;
   if(iTime(Symbol(),timeframe,0)+time_offset!=LastTime)
     {
      LastTime=iTime(Symbol(),timeframe,0)+time_offset;
      return (true);
     }
   else
      return (false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteZones()
  {
   int len=StringLen(prefix);
   int i=0;
   while(i<ObjectsTotal(0,0,-1))
     {
      string objName=ObjectName(0,i,0,-1);
      if(StringSubstr(objName,0,len)!=prefix)
        {
         i++;
         continue;
        }
      ObjectDelete(0,objName);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TFTS(int tf) //--- Timeframe to string
  {
   string tfs;
   switch(tf)
     {
      case PERIOD_M1:
         tfs="M1";
         break;
      case PERIOD_M2:
         tfs="M2";
         break;
      case PERIOD_M3:
         tfs="M3";
         break;
      case PERIOD_M4:
         tfs="M4";
         break;
      case PERIOD_M5:
         tfs="M5";
         break;
      case PERIOD_M6:
         tfs="M6";
         break;
      case PERIOD_M10:
         tfs="M10";
         break;
      case PERIOD_M12:
         tfs="M12";
         break;
      case PERIOD_M15:
         tfs="M15";
         break;
      case PERIOD_M20:
         tfs="M20";
         break;
      case PERIOD_M30:
         tfs="M30";
         break;
      case PERIOD_H1:
         tfs="H1";
         break;
      case PERIOD_H2:
         tfs="H2";
         break;
      case PERIOD_H3:
         tfs="H3";
         break;
      case PERIOD_H4:
         tfs="H4";
         break;
      case PERIOD_H6:
         tfs="H6";
         break;
      case PERIOD_H8:
         tfs="H8";
         break;
      case PERIOD_H12:
         tfs="H12";
         break;
      case PERIOD_D1:
         tfs="D1";
         break;
      case PERIOD_W1:
         tfs="W1";
         break;
      case PERIOD_MN1:
         tfs="MN1";
         break;
     }
   return(tfs);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FastFractals()
  {
//--- FastFractals
   int shift;
   int limit=MathMin(Bars(Symbol(),timeframe)-1,BackLimit+cnt);
   limit=MathMin(limit,ArraySize(FastUpPts)-1);
   int P1=int(timeframe*fractal_fast_factor);
   double High[],Low[];
   ArraySetAsSeries(High,true);
   CopyHigh(Symbol(),timeframe,0,limit+1,High);
   ArraySetAsSeries(Low,true);
   CopyLow(Symbol(),timeframe,0,limit+1,Low);
   FastUpPts[0] = 0.0;
   FastUpPts[1] = 0.0;
   FastDnPts[0] = 0.0;
   FastDnPts[1] = 0.0;
   for(shift=limit; shift>cnt+1; shift--)
     {
      if(Fractal(UP_POINT,P1,shift)==true)
         FastUpPts[shift]=High[shift];
      else
         FastUpPts[shift]=0.0;
      if(Fractal(DN_POINT,P1,shift)==true)
         FastDnPts[shift]=Low[shift];
      else
         FastDnPts[shift]=0.0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SlowFractals()
  {
//--- SlowFractals
   int shift;
   int limit=MathMin(Bars(Symbol(),timeframe)-1,BackLimit+cnt);
   limit=MathMin(limit,ArraySize(SlowUpPts)-1);
   int P2=int(timeframe*fractal_slow_factor);
   double High[],Low[];
   ArraySetAsSeries(High,true);
   CopyHigh(Symbol(),timeframe,0,limit+1,High);
   ArraySetAsSeries(Low,true);
   CopyLow(Symbol(),timeframe,0,limit+1,Low);
   SlowUpPts[0] = 0.0;
   SlowUpPts[1] = 0.0;
   SlowDnPts[0] = 0.0;
   SlowDnPts[1] = 0.0;
   for(shift=limit; shift>cnt+1; shift--)
     {
      if(Fractal(UP_POINT,P2,shift)==true)
         SlowUpPts[shift]=High[shift];
      else
         SlowUpPts[shift]=0.0;
      if(Fractal(DN_POINT,P2,shift)==true)
         SlowDnPts[shift]=Low[shift];
      else
         SlowDnPts[shift]=0.0;
      ner_hi_zone_P1[shift]=0;
      ner_hi_zone_P2[shift]=0;
      ner_lo_zone_P1[shift]=0;
      ner_lo_zone_P2[shift]=0;
      ner_hi_zone_strength[shift]=0;
      ner_lo_zone_strength[shift]=0;
      ner_price_inside_zone[shift]=0;
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void showLabels()
  {
   datetime Time=iTime(NULL,timeframe,cnt);
//  CopyTime(Symbol(),timeframe,cnt,1,Time);
//  ArraySetAsSeries(Time,true);
   for(int i=0; i<zone_count; i++)
     {
      string lbl;
      if(zone_strength[i]==ZONE_PROVEN)
         lbl="Proven";
      else
         if(zone_strength[i]==ZONE_VERIFIED)
            lbl="Verified";
         else
            if(zone_strength[i]==ZONE_UNTESTED)
               lbl="Untested";
            else
               if(zone_strength[i]==ZONE_TURNCOAT)
                  lbl="Turncoat";
               else
                  lbl="Weak";
      if(zone_type[i]==ZONE_SUPPORT)
         lbl=lbl+" "+sup_name;
      else
         lbl=lbl+" "+res_name;
      if(zone_hits[i]>0 && zone_strength[i]>ZONE_UNTESTED)
        {
         if(zone_hits[i]==1)
            lbl=lbl+", "+test_name+"="+string(zone_hits[i]);
         else
            lbl=lbl+", "+test_name+"="+string(zone_hits[i]);
        }
      int adjust_hpos;
      long wbpc=ChartGetInteger(0,CHART_VISIBLE_BARS);
      int k=PeriodSeconds(timeframe)/10+(StringLen(lbl));
      if(wbpc<80)
         adjust_hpos=int(Time)+k*1;
      else
         if(wbpc<125)
            adjust_hpos=int(Time)+k*2;
         else
            if(wbpc<250)
               adjust_hpos=int(Time)+k*4;
            else
               if(wbpc<480)
                  adjust_hpos=int(Time)+k*8;
               else
                  if(wbpc<950)
                     adjust_hpos=int(Time)+k*16;
                  else
                     adjust_hpos=int(Time)+k*32;
      int shift=k*zone_label_shift;
      double vpos=zone_hi[i]-(zone_hi[i]-zone_lo[i])/3;
      if(zone_strength[i]==ZONE_WEAK && zone_show_weak==false)
         continue;
      if(zone_strength[i]==ZONE_UNTESTED && zone_show_untested==false)
         continue;
      if(zone_strength[i]==ZONE_TURNCOAT && zone_show_turncoat==false)
         continue;
      string s=prefix+string(i)+"LBL";
      ObjectCreate(0,s,OBJ_TEXT,0,0,0);
      ObjectSetInteger(0,s,OBJPROP_TIME,adjust_hpos+shift);
      ObjectSetDouble(0,s,OBJPROP_PRICE,vpos);
      ObjectSetString(0,s,OBJPROP_TEXT,lbl);
      ObjectSetString(0,s,OBJPROP_FONT,Text_font);
      ObjectSetInteger(0,s,OBJPROP_FONTSIZE,Text_size);
      ObjectSetInteger(0,s,OBJPROP_COLOR,Text_color);
     }
  }
//+------------------------------------------------------------------+
