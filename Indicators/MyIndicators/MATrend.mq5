//+------------------------------------------------------------------+
//|                                                      MATrend.mq5 |
//+------------------------------------------------------------------+
#property version   "1.00"
#property indicator_chart_window
//#property indicator_separate_window
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
//--- input parameters
input int                 Lookback=1;
input int                 ReversalLookback=2;
input int                 ReversalThreshold=2;
input int                 MAPeriod=50;
input int                 MAShift=0;
input ENUM_MA_METHOD      MAMethod=MODE_SMA;
input ENUM_APPLIED_PRICE  MAAppliedPrice=PRICE_CLOSE;


//--- indicator buffers
double         MABuffer[];

double         ArrowUpBuffer[];
double         ArrowDownBuffer[];

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

   SetIndexBuffer(0,ArrowUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ArrowDownBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);

   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);

   extStartPosition = MAPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,extStartPosition);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,extStartPosition);

   extMAHandle=iMA(NULL,0,MAPeriod,MAShift,MAMethod,MAAppliedPrice);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

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
   double points = 0.00001;
   double adjusted_threshold=points*ReversalThreshold;

   if(rates_total<extStartPosition)
      return(0);
//--- not all data may be calculated
   if(BarsCalculated(extMAHandle)<rates_total)
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
   if(IsStopped()) // checking for stop flag
      return(0);

//---
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;

//--- main cycle
   double slopeIndexCur;
   double slopeIndexPrev;
   for(int i=start+Lookback*2+1; i<rates_total && !IsStopped(); i++)
     {
      ArrowDownBuffer[i]=0;
      ArrowUpBuffer[i]=0;

      slopeIndexCur=(extMAData[i-1]-extMAData[i-1-Lookback]);
      slopeIndexPrev=(extMAData[i-2]-extMAData[i-2-Lookback]);

      if(slopeIndexCur > adjusted_threshold &&  slopeIndexPrev < -adjusted_threshold)
        {
         ArrowUpBuffer[i]=low[i];
        }
      else
         if(slopeIndexCur < -adjusted_threshold &&  slopeIndexPrev > adjusted_threshold )
           {
            ArrowDownBuffer[i]=high[i];
           }
     }



//--- return value of prev_calculated for next call
   return(rates_total);
  }


//+------------------------------------------------------------------+
