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
                    ~CExpertWithTelegram(void) {EventKillTimer();};
   CCustomBot        m_bot;
   void              SendMessages(bool val) {m_send_messages=val;};
   void              Token(string val) {m_token=val;};
   void              ChatID(string val) {m_chat_id=val;};
   bool              InitMessenger(bool send_messages, string token, string chat_id,int interval_sec=3600);
   void              OnTimer(void);
   void              OnTrade(void);

protected:
   bool              m_send_messages;
   string            m_token;
   string            m_chat_id;

   string            m_trade_even_message;
   long              m_last_position_id;

   bool              TradeEventPositionStopTake(void);
   bool              TradeEventOrderTriggered(void);
   bool              TradeEventPositionOpened(void);
   bool              TradeEventPositionVolumeChanged(void);
   bool              TradeEventPositionModified(void);
   bool              TradeEventPositionClosed(void);
   bool              TradeEventOrderPlaced(void);
   bool              TradeEventOrderModified(void);
   bool              TradeEventOrderDeleted(void);
   bool              TradeEventNotIdentified(void);
   void              FormatClosedPosition(void);
  };


//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
CExpertWithTelegram::CExpertWithTelegram(void)
  {
   m_send_messages=false;
   m_token=NULL;
   m_chat_id=NULL;
   m_trade_even_message=NULL;
   m_last_position_id=NULL;
  }

//+------------------------------------------------------------------+
//| Init Messenger                                                   |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::InitMessenger(bool send_messages,string token,string chat_id,int interval_sec=3600)
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
      EventSetTimer(interval_sec);
     }
   CheckTradeState();
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
      message = StringFormat("@@@@ Opened position: %s\nCurrent profit: %s", position_info, DoubleToString(m_position.Profit()));
     }

   if(message !=NULL)
     {
      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, message);
      else
         printf(message);
     }
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventPositionModified(void)
  {
   m_trade_even_message = "Position modified";
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventOrderPlaced(void)
  {
   m_trade_even_message = "TradeEventOrderPlaced";
   return(true);
  }


//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventPositionVolumeChanged(void)
  {
   m_trade_even_message = "TradeEventPositionVolumeChanged";
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventPositionOpened(void)
  {
   SelectPosition();
   string position_info;
   m_position.FormatPosition(position_info);
   m_trade_even_message = StringFormat("Opened position: %s", position_info);
   m_last_position_id=m_position.Identifier();
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventPositionClosed(void)
  {
   FormatClosedPosition();
   m_last_position_id = NULL;
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventPositionStopTake(void)
  {
   FormatClosedPosition();
   m_trade_even_message = "[TradeEventPositionStopTake] "+m_trade_even_message;
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventOrderDeleted(void)
  {
   m_trade_even_message = "TradeEventOrderDeleted";
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventOrderModified(void)
  {
   m_trade_even_message = "TradeEventOrderModified";
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CExpertWithTelegram::FormatClosedPosition(void)
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
      m_trade_even_message = StringFormat("Closed position #%s on %s %s\nProfit: %s, swap: %s, comission: %s, fee: %s, volume: %s, deal time: %s",
                                          IntegerToString(m_last_position_id), m_symbol.Name(), StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period),7),
                                          DoubleToString(profit), DoubleToString(swap), DoubleToString(comission), DoubleToString(fee), DoubleToString(volume),
                                          TimeToString(transaction_time));
     }
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventOrderTriggered(void)
  {
   m_trade_even_message = "TradeEventOrderTriggered";
   return(true);
  }

//+------------------------------------------------------------------+
//|                                            |
//+------------------------------------------------------------------+
bool CExpertWithTelegram::TradeEventNotIdentified(void)
  {
   m_trade_even_message = "TradeEventNotIdentified";
   return(true);
  }

//+------------------------------------------------------------------+
//| Custom OnTrade handler                                           |
//+------------------------------------------------------------------+
void CExpertWithTelegram::OnTrade(void)
  {
   CheckTradeState();
   if(m_trade_even_message!=NULL)
     {
      if(m_send_messages)
         m_bot.SendMessage(m_chat_id, m_trade_even_message);
      else
         printf("@@@@@      " + m_trade_even_message);
     }
   m_trade_even_message=NULL;
  }
//+------------------------------------------------------------------+
