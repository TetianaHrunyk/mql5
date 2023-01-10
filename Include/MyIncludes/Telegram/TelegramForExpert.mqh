//+------------------------------------------------------------------+
//|                                            TelegramForExpert.mqh |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- Telegram bot
#include <MyIncludes/Telegram/Telegram.mqh>

//+------------------------------------------------------------------+
//| Create custom expert                                             |
//+------------------------------------------------------------------+
class CExpertWithTelegram : public CExpert
  {
public:
                     CExpertWithTelegram(void);
                    ~CExpertWithTelegram(void) {};
   CCustomBot        m_bot;
   void              SendMessages(bool val) {m_send_messages=val;};
   void              Token(string val) {m_token=val;};
   void              ChatID(string val) {m_chat_id=val;};
   bool              InitMessenger(bool send_messages, bool log_messages, string token, string chat_id,int interval_sec=3600);
   void              OnTimer(void);
   void              OnTrade(void);
protected:
   bool              m_send_messages;
   bool              m_log_messages;
   string            m_token;
   string            m_chat_id;

   int               m_positions_prev;
   long              m_last_position_id;
   string            m_account_currency;
  };
//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
CExpertWithTelegram::CExpertWithTelegram(void)
  {
   m_send_messages=false;
   m_log_messages=true;
   m_token=NULL;
   m_chat_id=NULL;

   m_positions_prev=0;
   m_last_position_id=0;
   m_account_currency=m_account.Currency();
  }

//+------------------------------------------------------------------+
//| Init Messenger                                                   |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::InitMessenger(bool send_messages,bool log_messages,string token,string chat_id,int interval_sec=3600)
  {
   bool res = true;
   m_send_messages=send_messages;
   if(m_send_messages)
     {
      if(token==NULL)
        {
         printf(__FUNCTION__+": cannot init messenger with empty token!");
         res=false;
        }
      else
        {
         m_token=token;
        }
      if(chat_id==NULL)
        {
         printf(__FUNCTION__+": cannot init messenger with empty chat_id!");
         res=false;
        }
      else
        {
         m_chat_id=chat_id;
        }
     }
   if(res && m_send_messages)
     {

      //--- Send init message
      m_bot.Token(m_token);
      string symbol = m_symbol.Name();
      string message = StringFormat(
                          "Bot is ready to notify you about open position on %s pair, %s timeframe", symbol,
                          StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7)
                       );
      m_bot.SendMessage(m_chat_id, message);
     }
   m_log_messages=log_messages;
   return res;
  }
//+------------------------------------------------------------------+
//| Custom OnTimer handler                                           |
//+------------------------------------------------------------------+
void CExpertWithTelegram::OnTimer(void)
  {
   string message;
   if(SelectPosition())
     {
      string position_info = "";
      m_position.FormatPosition(position_info);
      string sl = DoubleToString(NormalizeDouble(m_position.StopLoss(),4));
      string tp = DoubleToString(NormalizeDouble(m_position.TakeProfit(),4));
      string profit = DoubleToString(NormalizeDouble(m_position.Profit(),4));
      message = StringFormat("Open position: %s (sl: %s, tp: %s)\nCurrent profit: %s %s", position_info, sl, tp, profit, m_account_currency);
     }

   if(message !=NULL)
     {
      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, message);
      if(m_log_messages)
         printf(" ~~~~~~~~~~ " + message);
     }
  }

//+------------------------------------------------------------------+
//| Custom OnTrade handler                                           |
//+------------------------------------------------------------------+
void CExpertWithTelegram::OnTrade(void)
  {
// TODO: handle the reversing position case
   string message;
   int positions_total = PositionsTotal();
   long position_id = NULL;
   string symbol = m_symbol.Name();


   if(positions_total > m_positions_prev)
     {
      SelectPosition();
      string position_info = "";
      m_position.FormatPosition(position_info);
      string sl = DoubleToString(NormalizeDouble(m_position.StopLoss(),4));
      string tp = DoubleToString(NormalizeDouble(m_position.TakeProfit(),4));
      message = StringFormat("Opened position: %s (sl: %s, tp: %s)", position_info, sl, tp);
      
      position_id=m_position.Identifier();

     }
   if(positions_total < m_positions_prev)
     {
      HistorySelectByPosition(m_last_position_id);
      int deals_total = HistoryDealsTotal();
      for(int i=deals_total-1; i<deals_total; i++)
        {
         ulong deal_ticket          = HistoryDealGetTicket(i);
         double volume              = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
         double profit              = HistoryDealGetDouble(deal_ticket,DEAL_PROFIT);
         double swap                = HistoryDealGetDouble(deal_ticket,DEAL_SWAP);
         double comission           = HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION);
         double fee                 = HistoryDealGetDouble(deal_ticket,DEAL_FEE);
         datetime transaction_time  = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
         message = StringFormat("Closed position #%s on %s %s\nProfit: %s %s, swap: %s, comission: %s, fee: %s, volume: %s, deal time: %s",
                                IntegerToString(m_last_position_id), symbol, StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7),
                                DoubleToString(profit), m_account_currency, DoubleToString(swap),DoubleToString(comission), DoubleToString(fee),
                                DoubleToString(volume), TimeToString(transaction_time));
        }
      m_last_position_id=NULL;
     }
   
   if(positions_total > 0 && positions_total == m_positions_prev)
     {
      // Either nothing is going on, or the position is being reversed
     }
     
   if(position_id != NULL)
     {
      m_last_position_id = position_id;
     }
   m_positions_prev = positions_total;

   if(message!=NULL)
     {
      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, message);
      if(m_log_messages)
         printf(" ========= " + message);
     }
  }
//+------------------------------------------------------------------+
