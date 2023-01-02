//+------------------------------------------------------------------+
//|                                         ProhibitConseqLosses.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

double Optimize(double lots)
  {
   double lot=lots;
//--- calculate number of losses orders without a break
   if(m_decrease_factor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int       orders=HistoryDealsTotal();  // total history deals
      int       losses=0;                    // number of consequent losing orders
      CDealInfo deal;
      //---
      for(int i=orders-1;i>=0;i--)
        {
         deal.Ticket(HistoryDealGetTicket(i));
         if(deal.Ticket()==0)
           {
            Print("CMoneySizeOptimized::Optimize: HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(deal.Symbol()!=m_symbol.Name())
            continue;
         //--- check profit
         double profit=deal.Profit();
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/m_decrease_factor,2);
     }
//--- normalize and check limits
   double stepvol=m_symbol.LotsStep();
   lot=stepvol*NormalizeDouble(lot/stepvol,0);
//---
   double minvol=m_symbol.LotsMin();
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//---
   return(lot);
  }