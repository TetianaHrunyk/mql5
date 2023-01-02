//+------------------------------------------------------------------+
//|                                                     MA-Slope.mq5 |
//|                                       Oleg Fedorov (aka certain) |
//|                                   mailto:coder.fedorov@gmail.com |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>

#property copyright "Oleg Fedorov (aka certain)"
#property link      "mailto:coder.fedorov@gmail.com"
#property version   "1.00"
//#property indicator_chart_window
#property indicator_separate_window
//#property indicator_height 100
#property indicator_buffers 4
#property indicator_plots   3

//--- plot ArrowUp
#property indicator_label1  "Rising"
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ArrowDown
#property indicator_label2  "Falling"
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input int                 Lookback=1;
input int                 MAPeriod=50;
input int                 MAShift=0;
input ENUM_MA_METHOD      MAMethod=MODE_SMA;
input ENUM_APPLIED_PRICE  MAAppliedPrice=PRICE_CLOSE;
int DeltaMAPeriod = 3;
//--- indicator buffers
double         SlopeUpBuffer[];
double         SlopeDownBuffer[];
double         SlopeMainBuffer[];
double         SlopeMABuffer[];

//--- handles
int extMAHandle;

//---
int extStartPosition;
double extMAData[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SlopeUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SlopeDownBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SlopeMABuffer,INDICATOR_DATA);
   SetIndexBuffer(3,SlopeMainBuffer,INDICATOR_DATA);


   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);


   extStartPosition = MAPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,extStartPosition);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,extStartPosition);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,extStartPosition);

   extMAHandle=iMA(NULL,0,MAPeriod,MAShift,MAMethod,MAAppliedPrice);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

   IndicatorSetString(INDICATOR_SHORTNAME,"MA-Slope("+(string)MAPeriod+")");

   ChartRedraw();
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
   double slopeIndex;
   if(rates_total<extStartPosition)
      return(0);
//--- not all data may be calculated
   if(BarsCalculated(extMAHandle)<rates_total)
      return(0);

//--- get Fast EMA buffer
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(extMAHandle,0,0,rates_total,extMAData)!=rates_total)
     {
      Print("Getting EMA is failed! Error ",GetLastError());
      return(0);
     }

//--- main cycle
   if(prev_calculated == 0)
     {
      for(int i=1; i<rates_total && !IsStopped(); i++)
        {
         SlopeDownBuffer[i]=0.0;
         SlopeUpBuffer[i]=0.0;
         SlopeMABuffer[i]=0.0;

         if(i<Lookback)
            continue;

         slopeIndex=NormalizeDouble((extMAData[i]-extMAData[i-Lookback])*100/extMAData[i], 4);

         if(slopeIndex<0)
            SlopeDownBuffer[i]=slopeIndex;
         else
            SlopeUpBuffer[i]=slopeIndex;

         SlopeMainBuffer[i] = slopeIndex;

         if(i==DeltaMAPeriod)
            SlopeMABuffer[i]=slopeIndex;
         if(i>DeltaMAPeriod)
           {
            SlopeMABuffer[i] = ExponentialMA(i-DeltaMAPeriod,DeltaMAPeriod,SlopeMainBuffer[i-1],SlopeMainBuffer);
           }

        }
     }
   else
     {
      int i = prev_calculated-1;
      SlopeDownBuffer[i]=0.0;
      SlopeUpBuffer[i]=0.0;

      slopeIndex=NormalizeDouble((extMAData[i]-extMAData[i-Lookback])*100/extMAData[i], 4);

      if(slopeIndex<0)
         SlopeDownBuffer[i]=slopeIndex;
      else
         SlopeUpBuffer[i]=slopeIndex;

      SlopeMainBuffer[i] = slopeIndex;

      if(i>DeltaMAPeriod)
        {
         SlopeMABuffer[i] = ExponentialMA(i-DeltaMAPeriod,DeltaMAPeriod,SlopeMainBuffer[i-1],SlopeMainBuffer);
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
