//+------------------------------------------------------------------+
//|                                             High Low Channel.mq5 |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+
#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot Upper
#property indicator_label1  "Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Lower
#property indicator_label2  "Lower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      HighLowBars=8;
//--- indicator buffers
double         UpperBuffer[];
double         LowerBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowerBuffer,INDICATOR_DATA);
   
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//---
   
   ArraySetAsSeries(UpperBuffer,true);
   ArraySetAsSeries(LowerBuffer,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   
   int bars = rates_total - 1;
   if(prev_calculated > 0) bars = rates_total - prev_calculated;
   
   for(int i = bars; i >= 0; i--)   
   {
   	UpperBuffer[i] = High[ArrayMaximum(High,i,HighLowBars)];
   	LowerBuffer[i] = Low[ArrayMinimum(Low,i,HighLowBars)];
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

