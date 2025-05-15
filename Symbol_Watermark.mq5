//+------------------------------------------------------------------+
//|                                             Symbol Watermark.mq5 |
//|                                                    Naguisa Unada |
//|                    https://www.mql5.com/en/users/unadajapon/news |
//+------------------------------------------------------------------+
#property copyright "Naguisa Unada"
#property link      "https://www.mql5.com/en/users/unadajapon/news"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
//--- input parameters
input color 	font_color 	= clrDarkBlue; 	// Font Color
input long 		font_size  	= 65; 				// Font Size

string 			main_label 	= "Ticker Symbol Name";
string 			sub_label 	= "Ticker Symbol Description";
long 				curr_width 	= 0;
long 				curr_height = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
	//--- indicator buffers mapping
	string symbol_name_period = StringFormat("%s:%s", _Symbol, periodToString(_Period));
	string symbol_subtitle    = SymbolInfoString(_Symbol, SYMBOL_DESCRIPTION);
	
	Create_LabelOnChart(main_label, symbol_name_period, font_color);
	Create_LabelOnChart(sub_label,  symbol_subtitle,    font_color);
	//---
	return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
	//----
	ObjectDelete(0, main_label);
	ObjectDelete(0, sub_label);
	ChartRedraw();
	//----
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
	
	//--- return value of prev_calculated for next call
	return(rates_total);
}
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
				  		const long &lparam,
				  		const double &dparam,
				  		const string &sparam)
{
	if (id == CHARTEVENT_CHART_CHANGE)
	{
		long chart_width  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS,  0);
		long chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);

		if (curr_width != chart_width || curr_height != chart_height)
		{
			curr_width  = chart_width;
			curr_height = chart_height;
			Place_LabelOnChart(main_label);
			Place_LabelOnChart(sub_label);
		}
	}
}
//+------------------------------------------------------------------+
void Create_LabelOnChart(string obj_name, string labelText, color colorName)
{
	ObjectCreate(0,     obj_name, OBJ_LABEL, 0, 0, 0);
	ObjectSetInteger(0, obj_name, OBJPROP_COLOR,  colorName);
	ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
	ObjectSetString(0,  obj_name, OBJPROP_TEXT,   labelText);
	ObjectSetString(0,  obj_name, OBJPROP_FONT,   "Arial Black");
	ObjectSetInteger(0, obj_name, OBJPROP_BACK,   true);
}
//+------------------------------------------------------------------+
void Place_LabelOnChart(string obj_name)
{
	long chart_width  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS,  0);
	long chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
	long fontSize     = (font_size * chart_width) / 850;
	long shiftDown    = 0;

	if (StringFind(obj_name, "Description") > 0)
	{
		shiftDown = fontSize + 5;
		fontSize  = fontSize / 2;
	}

	ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, chart_width  / 2);
	ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, chart_height / 2 + shiftDown);
	ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE,  fontSize);
	ChartRedraw();
}
//+------------------------------------------------------------------+
string periodToString(ENUM_TIMEFRAMES period)
{
	string result = EnumToString(period);
	return StringSubstr(result, 7);
}
//+------------------------------------------------------------------+
