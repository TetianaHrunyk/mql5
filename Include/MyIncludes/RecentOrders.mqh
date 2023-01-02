//+------------------------------------------------------------------+
//|                                                 RecentOrders.mqh |
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

datetime CSampleExpert::LastOutDealTime(void)
  {
   datetime deal_time;
   HistorySelect(0,TimeCurrent());
   int orders=HistoryDealsTotal();  // total history deals
   bool isSL = false;
   CDealInfo deal;
   COrderInfo order;

   for(int i=orders-1; i>=0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket()==0)
        {
         Print("No trade history");
         break;
        }

      if(deal.Symbol()!=m_symbol.Name() || deal.Magic() != EXPERT_MAGIC_NUMBER)
         continue;
      // TODO: only closed on stop loss
      if(deal.Entry() == DEAL_ENTRY_OUT)
        {
         long order_id = deal.Order();
         order.Select(order_id);
         double open = order.PriceOpen();
         double close = deal.Price();
         double stop_loss = order.StopLoss();
         isSL = MathAbs(close - stop_loss) < 0.00005;
         if(isSL)
           {
            deal_time = deal.Time();
            break;
           }
        }
     }
   return(deal_time);
  }

bool isSL = MathAbs( OrderClosePrice() - OrderStopLoss() ) < MathAbs( OrderClosePrice() - OrderTakeProfit() );

datetime CSampleExpert::LastOutDealTime(void)
  {
   datetime deal_time;
   HistorySelect(0,TimeCurrent());
   int orders=HistoryDealsTotal();  // total history deals
   CDealInfo deal;

   for(int i=orders-1; i>=0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket()==0)
        {
         Print("No trade history");
         break;
        }

      if(deal.Symbol()!=m_symbol.Name())
         continue;
      // TODO: only closed on stop loss
      if(deal.Entry() == DEAL_ENTRY_OUT)
        {
         deal_time = deal.Time();
         break;
        }
     }
   return(deal_time);
  }
  