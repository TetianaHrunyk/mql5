//+------------------------------------------------------------------+
//|                                                   MADistance.mq5 |
//|                                                   Tetiana Hrunyk |
//|                                                                  |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>

#property copyright "Tetiana Hrunyk"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "MA"
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Distance"
#property indicator_color2  clrLightSalmon
#property indicator_style2  STYLE_DASHDOTDOT
#property indicator_width2  1

//--- input parameters
input int                 Lookback=1;
input int                 MAPeriod=50;
input int                 MAShift=0;
input ENUM_MA_METHOD      MAMethod=MODE_EMA;
input ENUM_APPLIED_PRICE  MAAppliedPrice=PRICE_CLOSE;

//--- indicator buffers
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
   SetIndexBuffer(0,SlopeMABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SlopeMainBuffer,INDICATOR_DATA);


   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);


   extStartPosition = MAPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,extStartPosition);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,extStartPosition);


   extMAHandle=iMA(NULL,0,MAPeriod,MAShift,MAMethod,MAAppliedPrice);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

   IndicatorSetString(INDICATOR_SHORTNAME,"MA Distance("+(string)MAPeriod+")");

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
      for(int i=0; i<rates_total && !IsStopped(); i++)
        {
         SlopeMainBuffer[i] = ((close[i] - extMAData[i]) + (open[i] - extMAData[i]))/2;
         SlopeMABuffer[i]=0.0;

         if(i<Lookback)
            continue;

         if(i==Lookback)
            SlopeMABuffer[i]=SlopeMainBuffer[i];
         if(i>Lookback)
           {
            SlopeMABuffer[i] = ExponentialMA(i-Lookback,Lookback,SlopeMainBuffer[i-1],SlopeMainBuffer);
           }

        }
     }
   else
     {
      int i = prev_calculated+1;
      SlopeMainBuffer[i] = ((close[i] - extMAData[i]) + (open[i] - extMAData[i]))/2;
      SlopeMABuffer[i] = ExponentialMA(i-Lookback,Lookback,SlopeMainBuffer[i-1],SlopeMainBuffer);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
