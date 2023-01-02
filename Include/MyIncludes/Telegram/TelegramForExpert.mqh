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
   bool              InitMessenger(bool send_messages, string token, string chat_id);
   void              OnTimer(void);
   void              OnTrade(void);
protected:
   bool              m_send_messages;
   string            m_token;
   string            m_chat_id;

   int               m_positions_prev;
   long              m_last_position_id;
  };
//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
CExpertWithTelegram::CExpertWithTelegram(void)
  {
   m_send_messages=false;
   m_token=NULL;
   m_chat_id=NULL;

   m_positions_prev=0;
   m_last_position_id=0;
  }

//+------------------------------------------------------------------+
//| Init Messenger                                                   |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::InitMessenger(bool send_messages,string token,string chat_id)
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
   return res;
  }
//+------------------------------------------------------------------+
//| Custom OnTimer handler                                           |
//+------------------------------------------------------------------+
void CExpertWithTelegram::OnTimer(void)
  {
   if(m_send_messages && SelectPosition())
     {
      string position_info = "";
      m_position.FormatPosition(position_info);
      string message = StringFormat("Open position: %s\nCurrent profit: %s", position_info, DoubleToString(m_position.Profit()));

      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, message);
      else
         printf(message);
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

   if(positions_total > m_positions_prev)
     {
      SelectPosition();
      string position_info = "";
      m_position.FormatPosition(position_info);
      message = StringFormat("Opened position: %s\n", position_info);
      m_last_position_id=m_position.Identifier();
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
         string symbol = m_symbol.Name();
         message = StringFormat("Closed position on %s %s\nProfit: %s, swap: %s, comission: %s, fee: %s, volume: %s, deal time",
                                symbol, StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7),
                                DoubleToString(profit), DoubleToString(swap), DoubleToString(comission), DoubleToString(fee), DoubleToString(volume),
                                TimeToString(transaction_time));
        }
     }
   m_positions_prev = positions_total;

   if(message!=NULL)
     {
      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, message);
      else
         printf(message);
     }
  }
//+------------------------------------------------------------------+
