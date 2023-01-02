//+------------------------------------------------------------------+
//|                                                           ER.mq5 |
//+------------------------------------------------------------------+
#property version     "1.00"
#property description "MA Trend ER"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot ExtERBuffer
#property indicator_label1  "ER"
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- default applied price
#property indicator_applied_price PRICE_OPEN
//--- input parameters
input int InpPeriodER=10;      // ER period
//input int InpPeriodMA=20;      // MA period
//ENUM_MA_METHOD int InpMethodMA=MODE_EMA;// MA Method
//input int InpShiftMA=0;        // MA shift
//--- indicator buffer
double    ExtERBuffer[];

//double    ExtFastSC;
//double    ExtSlowSC;
//int       ExtPeriodAMA;
//int       ExtSlowPeriodEMA;
//int       ExtFastPeriodEMA;
//+------------------------------------------------------------------+
//|  initialization function                                      |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   //if(InpPeriodAMA<=0)
   //  {
   //   ExtPeriodAMA=10;
   //   PrintFormat("Input parameter InpPeriodAMA has incorrect value (%d). Indicator will use value %d for calculations.",
   //               InpPeriodAMA,ExtPeriodAMA);
   //  }
   //else
   //   ExtPeriodAMA=InpPeriodAMA;
   //if(InpSlowPeriodEMA<=0)
   //  {
   //   ExtSlowPeriodEMA=30;
   //   PrintFormat("Input parameter InpSlowPeriodEMA has incorrect value (%d). Indicator will use value %d for calculations.",
   //               InpSlowPeriodEMA,ExtSlowPeriodEMA);
   //  }
   //else
   //   ExtSlowPeriodEMA=InpSlowPeriodEMA;
   //if(InpFastPeriodEMA<=0)
   //  {
   //   ExtFastPeriodEMA=2;
   //   PrintFormat("Input parameter InpFastPeriodEMA has incorrect value (%d). Indicator will use value %d for calculations.",
   //               InpFastPeriodEMA,ExtFastPeriodEMA);
   //  }
   //else
   //   ExtFastPeriodEMA=InpFastPeriodEMA;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtERBuffer,INDICATOR_DATA);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriodER);

//--- set shortname and change label
   string short_name=StringFormat("ER %d", InpPeriodER);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetString(0,PLOT_LABEL,short_name);

  }
//+------------------------------------------------------------------+
//| AMA iteration function                                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int i;
//--- check for rates count
   if(rates_total<InpPeriodER+begin)
      return(0);
//--- draw begin may be corrected
   if(begin!=0)
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriodER+begin);
//--- detect position
   int pos=prev_calculated-1;
//--- first calculations
   if(pos<InpPeriodER+begin)
     {
      pos=InpPeriodER+begin;
      for(i=0; i<pos-1; i++)
         ExtERBuffer[i]=0.0;
      ExtERBuffer[pos-1]=price[pos-1];
     }
//--- main cycle
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      ExtERBuffer[i]=CalculateER(i,price);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate ER value                                               |
//+------------------------------------------------------------------+
double CalculateER(const int pos,const double& price[])
  {
   double signal=MathAbs(price[pos]-price[pos-InpPeriodER]);
   int direction = 1;
   if (price[pos]-price[pos-InpPeriodER] < 0) direction = -1;
   double noise=0.0;
   for(int delta=0; delta<InpPeriodER; delta++)
      noise+=MathAbs(price[pos-delta]-price[pos-delta-1]);
   if(noise!=0.0)
      return(signal/noise*direction);
   return(0.0);
  }
//+------------------------------------------------------------------+
