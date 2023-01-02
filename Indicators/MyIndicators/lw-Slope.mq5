//+------------------------------------------------------------------+
//|                                                     MA-Slope.mq5 |
//|                                       Oleg Fedorov (aka certain) |
//|                                   mailto:coder.fedorov@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Oleg Fedorov (aka certain)"
#property link      "mailto:coder.fedorov@gmail.com"
#property version   "1.00"
//#property indicator_chart_window
#property indicator_separate_window
//#property indicator_height 100
#property indicator_buffers 2
#property indicator_plots   2

//--- plot ArrowUp
#property indicator_label1  "ArrowUp"
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ArrowDown
#property indicator_label2  "ArrowDown"
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int                 Lookback=1;
input int                 MABars=10;
input int                 SlopeShift=1;
input ENUM_MA_METHOD      MAMethod=MODE_SMA;
input ENUM_APPLIED_PRICE  MAAppliedPrice=PRICE_CLOSE;
//--- indicator buffers
double         SlopeUpBuffer[];
double         SlopeDownBuffer[];

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


  PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
  PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);


  extStartPosition = MABars;
  PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,extStartPosition);
  PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,extStartPosition);

  extMAHandle=iMA(NULL,0,MABars,0,MAMethod,PRICE_CLOSE);

  PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
  PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

  IndicatorSetString(INDICATOR_SHORTNAME,"MA-Slope("+(string)MABars+")");

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
  int i;
  double slopeIndex;
  if(rates_total<extStartPosition)
    return(0);
//--- not all data may be calculated
  if(CheckIndicatorsCalculated(rates_total)==0)
   {
    return(0);
   }
//--- we can copy not all data
  int to_copy;
  if(prev_calculated>rates_total || prev_calculated<0)
    to_copy=rates_total;
  else
   {
    to_copy=rates_total-prev_calculated;
    if(prev_calculated>0)
      to_copy++;
   }
//--- get Fast EMA buffer
  if(IsStopped()) // checking for stop flag
    return(0);
  if(CopyBuffer(extMAHandle,0,0,to_copy,extMAData)<=0)
   {
    Print("Getting high EMA is failed! Error ",GetLastError());
    return(0);
   }
//---
  int start;
  if(prev_calculated==0)
    start=0;
  else
    start=prev_calculated-1;

//--- main cycle
  for(i=start+SlopeShift*2; i<rates_total && !IsStopped(); i++)
   {
    SlopeDownBuffer[i]=0;
    SlopeUpBuffer[i]=0;
    slopeIndex=(extMAData[i-1]-extMAData[i-1-SlopeShift]);
    //---

    if(
      slopeIndex<0
    )
     {
      SlopeDownBuffer[i]=slopeIndex;
     }
    else
      if(
        slopeIndex>0
      )
       {
        SlopeUpBuffer[i]=slopeIndex;
       }
   }

//--- return value of prev_calculated for next call
  return(rates_total);
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CheckIndicatorsCalculated(int rates_total)
 {
  int calculated=BarsCalculated(extMAHandle);
  if(calculated<rates_total)
   {
    Print("Not all data of extMAHandle is calculated (",calculated," bars). Error ",GetLastError());
    return(0);
   }
//---
  return(1);
 }
//+------------------------------------------------------------------+
