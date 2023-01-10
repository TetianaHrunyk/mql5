//+------------------------------------------------------------------+
//|                                              CSampleStrategy.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <Object.mqh>

#define POSITION_NEUTRAL   0     // no position
#define POSITION_LONG      1     // long position
#define POSITION_SHORT    -1     // short position

#define SIGNAL_OPEN_LONG    10   // signal to open a long position
#define SIGNAL_OPEN_SHORT  -10   // signal to open a short position
#define SIGNAL_CLOSE_LONG   -1   // signal to close a long position
#define SIGNAL_CLOSE_SHORT   1   // signal to close a short position
//+------------------------------------------------------------------+
//| Structure for storing the parameters of virtual position         |
//+------------------------------------------------------------------+
struct virtual_position
  {
   string            symbol;            // symbol
   int               direction;         // direction of the virtual position (0-no open position,+1 long,-1 short)
   double            volume;            // volume of the position in lots
   double            profit;            // current profit of the virtual position on points
   double            stop_loss;         // Stop Loss of the virtual position
   double            take_profit;       // Take Profit of the virtual position
   datetime          time_open;         // date and time of opening the virtual position
   datetime          time_close;        // date and time of closing the virtual position
   double            price_open;        // open price of the virtual position
   double            price_close;       // close price of the virtual position
   double            price_highest;     // maximum price during the life of the position
   double            price_lowest;      // minimal price during the lift of the position
   double            entry_eff;         // effectiveness of entering
   double            exit_eff;          // effectiveness of exiting
   double            trade_eff;         // effectiveness of deal
  };
//+------------------------------------------------------------------+
//| Class CSampleStrategy                                            |
//+------------------------------------------------------------------+
class CSampleStrategy: public CObject
  {
protected:
   int               m_strategy_id;            // Strategy ID
   string            m_strategy_symbol;        // Symbol 
   string            m_strategy_name;          // Strategy name
   string            m_strategy_comment;       // Comment

   MqlTick           m_price_last;             // Last price
   MqlRates          m_rates[];                // Array for current quotes
   bool              m_virtual_trade_allowed;  // Flag of allowing virtual trading 
   int               m_current_signal_state;   // Current state of strategy
   double            m_current_trade_volume;   // Number of lots for trading
   double            m_initial_balance;        // Initial balance (set in the constructor, default value is 10000)
   int               m_sl_points;              // Stop Loss
   int               m_tp_points;              // Take Profit

   virtual_position  m_position;               // Virtual position
   virtual_position  m_deals_history[];        // Array of deals
   int               m_virtual_deals_total;    // Total number of deals

   double            m_virtual_balance;           // "Virtual" balance
   double            m_virtual_equity;            // "Virtual" equity
   double            m_virtual_cumulative_profit; // cumulative "virtual" profit
   double            m_virtual_profit;            // profit of the current open "virtual" position

   //checks and closes the virtual position by stop levels if it is necessary
   bool              CheckVirtual_Stops(virtual_position &position);
   // recalculation of position and balance
   void              RecalcPositionProperties(virtual_position &position);
   // recalculation of open virtual position in accordance with the current prices 
   void              Position_RefreshInfo(virtual_position &position);
   // open virtual short position
   void              Position_OpenShort(virtual_position &position);
   // closes virtual short position  
   void              Position_CloseShort(virtual_position &position);
   // opens virtual long position
   void              Position_OpenLong(virtual_position &position);
   // closes the virtual long position
   void              Position_CloseLong(virtual_position &position);
   // closes open virtual position  
   void              Position_CloseOpenedPosition(virtual_position &position);
   // adds closed position to the m_deals_history[] array (history of deals)
   void              AddDealToHistory(virtual_position &position);
   //calculates and returns the recommended volume that will be used in trading
   virtual double    MoneyManagement_CalculateLots(double trade_volume);
public:
   // constructor
   void              CSampleStrategy();
   // destructor
   void             ~CSampleStrategy();

   //returns the current size of virtual balance
   double            GetVirtualBalance() { return(m_virtual_balance); }
   //returns the current size of virtual equity
   double            GetVirtualEquity() { return(m_virtual_equity); }
   //returns the current size of virtual profit of open position
   double            GetVirtualProfit() { return(m_virtual_profit); }

   //sets Stop Loss and Take Profit in points
   void              Set_Stops(int tp,int sl) {m_tp_points=tp; m_sl_points=sl;};
   //sets the current volume in lots
   void              SetLots(double trade_volume) {m_current_trade_volume=trade_volume;};
   //returns the current volume in lots
   double            GetCurrentLots() { return(m_current_trade_volume); }

   // returns strategy name
   string            StrategyName() { return(m_strategy_name); }
   // returns strategy ID
   int               StrategyID() { return(m_strategy_id); }
   // returns the comment of strategy
   string            StrategyComment() { return(m_strategy_comment); }
   // sets the details of strategy (symbol, name and ID of strategy)
   void              SetStrategyInfo(string symbol,string name,int id,string comment);

   // set the flag of virtual trading (allowed or not)
   void              SetVirtualTradeFlag(bool pFlag) { m_virtual_trade_allowed=pFlag; };
   // returns flag of allowing virtual trading
   bool              IsVirtualTradeAllowed() { return(m_virtual_trade_allowed); };

   // returns the current state of strategy
   int               GetSignalState();
   // sets the current state of strategy (changes virtual position if necessary)
   void              SetSignalState(int state);
   // changes virtual position in accordance with the current state 
   void              ProceedSignalState(virtual_position &position);

   // sets the value of cumulative "virtual" profit
   void              SetVirtualCumulativeProfit(double cumulative_profit) { m_virtual_cumulative_profit=cumulative_profit; };

   //returns the effectiveness of strategy ()
   double            StrategyPerformance();

   //updates position data
   void              UpdatePositionData();
   //closes open virtual position
   void              CloseVirtualPosition();
   //returns the direction of the current virtual position
   int               PositionDirection();
   //virtual function of initialization
   virtual int       Initialization() {return(0);};
   //virtual function of checking trade conditions
   virtual bool      CheckTradeConditions() {return(false);};
   //virtual function of deinitialization
   virtual int       Deinitialization() {return(0);};

   //saves virtual deals to a file
   void              SaveVirtualDeals(string file_name);
  };
//+------------------------------------------------------------------+
//| Constructor of the CSampleStrategy class                         |
//+------------------------------------------------------------------+
void CSampleStrategy::CSampleStrategy()
  {
   ZeroMemory(m_position);              // clear m_position
   m_virtual_cumulative_profit=0;       // cumulative virtual profit
   m_virtual_profit=0;                  // virtual profit
   m_current_trade_volume=0.1;          // default volume in lots
   m_strategy_id=0;                     // default ID=0
   m_strategy_name="Sample Strategy";   // default is "Sample Strategy"
   m_current_signal_state=0;            // current state of strategy
   m_virtual_trade_allowed=true;        // virtual trading is allowed on default
   m_initial_balance=10000;             // initial virtual balance
   m_virtual_balance=m_initial_balance; // current virtual balance
   m_virtual_equity=m_initial_balance;  // current virtual equity
   m_sl_points=0;                       // default Stop Loss value (in points)
   m_tp_points=0;                       // default Take Profit value (in points)
  }
//+------------------------------------------------------------------+
//| Destructor of the CSampleStrategy class                          |
//+------------------------------------------------------------------+ 
void CSampleStrategy::~CSampleStrategy()
  {
//zeroize array sizes
   ArrayResize(m_rates,0);
   ArrayResize(m_deals_history,0);
  }
//+------------------------------------------------------------------+
//| Function of updating position data                               |
//+------------------------------------------------------------------+
void CSampleStrategy::UpdatePositionData()
  {
   RecalcPositionProperties(m_position);
  }
//+------------------------------------------------------------------+
//| Function of closing virtual position                             |
//+------------------------------------------------------------------+
void CSampleStrategy::CloseVirtualPosition()
  {
   Position_CloseOpenedPosition(m_position);
  }
//+------------------------------------------------------------------+
//| Returns current direction of position                            |
//+------------------------------------------------------------------+
int CSampleStrategy::PositionDirection()
  {
   return(m_position.direction);
  }
//+------------------------------------------------------------------+
//| Function returns the recommended volume for strategy in lots     |
//| The current volume is passed to it a a parameter                 |
//| Volume can be set depending on:                                  |
//| current m_virtual_balance and m_virtual_equity                   |
//| current statistics of deals (that is stored in m_deals_history)  |
//| or any other thing you want                                      |
//| If the change of volume is not required in the strategy          |
//| we can  return the passed volume:  return(trade_volume);         |
//+------------------------------------------------------------------+ 
double CSampleStrategy::MoneyManagement_CalculateLots(double trade_volume)
  {
//return what has been obtained 
   return(trade_volume);
  }
//+------------------------------------------------------------------+
//| The StrategyPerformance function of effectiveness of strategy    |
//+------------------------------------------------------------------+ 
double CSampleStrategy::StrategyPerformance()
  {
//returns the effectiveness of strategy
//in this case it's the difference between the amount 
//of equity at the moment and the initial balance 
//i.e. how much money the strategy has earned
   double performance=(m_virtual_equity-m_initial_balance);
   return(performance);
/*
  //if there were deals performed,  then multiple the result of three next deals by this value
   if(m_virtual_deals_total>0)
     {
      int avdeals=MathRound(MathMin(3,m_virtual_deals_total));
      double sumprofit=0;
      for(int j=0; j<avdeals; j++)
        {
         sumprofit+=m_deals_history[m_virtual_deals_total-1-j].profit;
        }
      sumprofit=sumprofit/avdeals;
      performance=performance*sumprofit;
     }
     return(performance);
*/
  }
//+------------------------------------------------------------------+
//| Set the details of strategy (name, ID, comment)                  |
//+------------------------------------------------------------------+
void  CSampleStrategy::SetStrategyInfo(string symbol,string name,int id,string comment)
  {
   //symbols
   m_strategy_symbol=symbol;
   //ID
   m_strategy_id=id;
   //name
   m_strategy_name=name;
   //comment
   m_strategy_comment=comment;
  //symbol of position
   m_position.symbol=m_strategy_symbol;
  }
//+------------------------------------------------------------------+
//| "Closes" the current open virtual position,                      |
//| copies its parameters and adds                                   |
//| it to the array of virtual deals m_deals_history                 |
//+------------------------------------------------------------------+
void  CSampleStrategy::AddDealToHistory(virtual_position &position)
  {
   //request the size of the array of virtual deals
   m_virtual_deals_total=ArraySize(m_deals_history);
   //increase it by 1
   m_virtual_deals_total++;
   //increase the size of array m_deals_history by 1
   ArrayResize(m_deals_history,m_virtual_deals_total);
   //copy the position properties to the last element of the array
   m_deals_history[m_virtual_deals_total-1].symbol=position.symbol;
   m_deals_history[m_virtual_deals_total-1].direction=position.direction;
   m_deals_history[m_virtual_deals_total-1].volume=position.volume;
   m_deals_history[m_virtual_deals_total-1].stop_loss=position.stop_loss;
   m_deals_history[m_virtual_deals_total-1].take_profit=position.take_profit;
   m_deals_history[m_virtual_deals_total-1].profit = position.profit;
   m_deals_history[m_virtual_deals_total-1].volume = position.volume;
   m_deals_history[m_virtual_deals_total-1].time_open=position.time_open;
   m_deals_history[m_virtual_deals_total-1].time_close = position.time_close;
   m_deals_history[m_virtual_deals_total-1].price_open = position.price_open;
   m_deals_history[m_virtual_deals_total-1].price_close= position.price_close;
   m_deals_history[m_virtual_deals_total-1].price_highest= position.price_highest;
   m_deals_history[m_virtual_deals_total-1].price_lowest = position.price_lowest;
   m_deals_history[m_virtual_deals_total-1].entry_eff= position.entry_eff;
   m_deals_history[m_virtual_deals_total-1].exit_eff = position.exit_eff;
   m_deals_history[m_virtual_deals_total-1].trade_eff= position.trade_eff;
   //current profit of position
   m_virtual_profit=position.profit;
   //increase the cumulative profit by the size of the position that is cosed
   m_virtual_cumulative_profit=m_virtual_cumulative_profit+m_virtual_profit;
   //zeroize the direction of position (no position)
   position.direction=0;
   //zeroize the profit of position
   position.profit=0;
  }
//+----------------------------------------------------------------------+
//| Checks and closes virtual position by stop levels if it is necessary |
//+----------------------------------------------------------------------+
bool CSampleStrategy::CheckVirtual_Stops(virtual_position &position)
  {
   if(position.direction==0) {return(false);}
   //if there is a position, check if it should be closed by stop levels
   if(position.direction==POSITION_LONG)
     {
      if((position.stop_loss>0.0) && (position.price_close<=position.stop_loss))
        {
         //Print("Close LONG: Stop Loss: ",position.stop_loss," Price:",position.price_close);
         Position_CloseLong(position);
         return(true);
        }
      if((position.take_profit>0.0) && (position.price_close>=position.take_profit))
        {
         //Print("Close LONG: Take Profit: ",position.take_profit," Price:",position.price_close);
         Position_CloseLong(position);
         return(true);
        };
     }
   if(position.direction==POSITION_SHORT)
     {
      if((position.stop_loss>0.0) && (position.price_close>=position.stop_loss))
        {
         //Print("Close SHORT: Stop Loss: ",position.stop_loss," Price:",position.price_close);
         Position_CloseShort(position);
         return(true);
        }
      if((position.take_profit>0.0) && (position.price_close<=position.take_profit))
        {
         //Print("Close SHORT: ",position.take_profit," Price:",position.price_close);
         Position_CloseShort(position);
         return(true);
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Recalculates parameters of open virtual position                 |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_RefreshInfo(virtual_position &position)
  {
   //request the last quotes by the symbols of position
   SymbolInfoTick(position.symbol,m_price_last);

   //if there is a position, recalculate its parameters
   if(position.direction!=0)
     {
      position.time_close=0;
      position.price_highest=MathMax(position.price_highest,m_price_last.ask);
      position.price_lowest=MathMin(position.price_lowest,m_price_last.bid);

      double xfactor;
      if((position.price_highest-position.price_lowest)==0)
        {
         //Print("BID=ASK?","Bid=",m_price_last.bid," Ask=",m_price_last.ask);
         return;
        }
      xfactor=1.0/(position.price_highest-position.price_lowest);

      //for a long position
      if(position.direction==POSITION_LONG)
        {
         position.price_close=m_price_last.bid;
         position.entry_eff=(position.price_highest-position.price_open)*xfactor;
         position.exit_eff=(position.price_close-position.price_lowest)*xfactor;
         position.trade_eff=(position.price_close-position.price_open)*xfactor;
         position.profit=position.volume*(position.price_close-position.price_open)/_Point;
        }
      //for a short position
      if(position.direction==POSITION_SHORT)
        {
         position.price_close=m_price_last.ask;
         position.entry_eff=(position.price_open-position.price_lowest)*xfactor;
         position.exit_eff=(position.price_highest-position.price_close)*xfactor;
         position.trade_eff=(position.price_open-position.price_close)*xfactor;
         position.profit=position.volume*(position.price_open-position.price_close)/_Point;
        }
      CheckVirtual_Stops(position);
     }
  }
//+------------------------------------------------------------------------+
//| Recalculation of the properties of position and of the current balance |
//+------------------------------------------------------------------------+
void CSampleStrategy::RecalcPositionProperties(virtual_position &position)
  {
   //Refresh the parameters of open position
   Position_RefreshInfo(m_position);
   // if the position is open, refresh the profit
   if(m_position.direction!=0)
     {
      m_virtual_profit=m_position.profit;
     }
   //string s1="RecalcPositionProperties:"+StrategyName()+" "+m_virtual_equity+" Balance="+m_virtual_balance+" m_virtual_cumulative_profit="+m_virtual_cumulative_profit+" "+m_virtual_profit;

   //refresh the values of equity and balance
   m_virtual_equity=m_initial_balance+m_virtual_cumulative_profit+m_virtual_profit;
   m_virtual_balance=m_initial_balance+m_virtual_cumulative_profit;

   //   s1=s1+" new value="+m_virtual_equity+" new balance="+m_virtual_balance;  
   //   Print(s1);
  }
//+------------------------------------------------------------------+
//| Closes open short position                                       |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_CloseShort(virtual_position &position)
  {
   //exit if the virtual trading is prohibited
   if(!m_virtual_trade_allowed) {return;}
   //exit if the direction of virtual position doesn't correspond with POSITION_SHORT
   if(position.direction!=POSITION_SHORT){return;}
   //fix the time of closing the virtual position
   position.time_close=TimeCurrent();
   //add the deal to the history and close the virtual position
   AddDealToHistory(position);
  }
//+------------------------------------------------------------------+
//| Opens virtual long position                                      |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_OpenLong(virtual_position &position)
  {
   //exit if the virtual trading is prohibited
   if(!m_virtual_trade_allowed) {return;}
   //set the direction of the virtual position
   position.direction=POSITION_LONG;

   // calculate the volume according to Money Management
   m_current_trade_volume=MoneyManagement_CalculateLots(m_current_trade_volume);
   //set volume of the virtual position
   position.volume=m_current_trade_volume;

   //set the time of opening the virtual position
   position.time_open=TimeCurrent();
   //set the price of opening the virtual position   
   position.price_open=m_price_last.ask;

   //set Stop Loss of the virtual sell position
   if(m_sl_points>0) position.stop_loss=position.price_open+m_sl_points*_Point; else position.stop_loss=0;
   //set Take Profit of the virtual sell position
   if(m_tp_points>0) position.take_profit=position.price_open-m_tp_points*_Point; else position.take_profit=0;

   //Print("Position_OpenLong: SL=",position.stop_loss," TP=",position.take_profit);

   //set the current price of closing the virtual position (for the convenience of calculation)  
   position.price_close=m_price_last.bid;
   //set the time of closing the virtual position
   position.time_close=0;
   //calculate profit
   position.profit=position.volume*(position.price_close-position.price_open)/_Point;
   //set the maximum price
   position.price_highest=m_price_last.ask;
   //set the minimum price
   position.price_lowest=m_price_last.bid;
   //update the properties of position in correspondence with the prices
   RecalcPositionProperties(position);
  }
//+------------------------------------------------------------------+
//| Close the virtual buy position                                   |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_CloseLong(virtual_position &position)
  {
   //exit if the virtual trading is prohibited
   if(!m_virtual_trade_allowed) {return;}
   //exit if the direction of virtual position doesn't correspond with POSITION_LONG
   if(position.direction!=POSITION_LONG){return;}
   //fix the time of closing the virtual position
   position.time_close=TimeCurrent();
   //add the deal to the history and close the virtual position
   AddDealToHistory(position);
  }
//+------------------------------------------------------------------+
//| Opens virtual sell position                                      |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_OpenShort(virtual_position &position)
  {
   //exit if the virtual trading is prohibited
   if(!m_virtual_trade_allowed) {return;}
   //set the direction of the virtual position
   position.direction=POSITION_SHORT;

   // calculate the volume according to Money Management
   m_current_trade_volume=MoneyManagement_CalculateLots(m_current_trade_volume);
   //set volume of the virtual position
   position.volume=m_current_trade_volume;

   //set the time of opening the virtual position
   position.time_open=TimeCurrent();
   //set the price of opening the virtual position
   position.price_open=m_price_last.bid;
   //set the current price of closing the virtual position (for the convenience of calculation)  
   position.price_close=m_price_last.ask;

   //set Stop Loss of the virtual sell position
   if(m_sl_points>0) position.stop_loss=position.price_open+m_sl_points*_Point; else position.stop_loss=0;
   //set Take Profit of the virtual sell position
   if(m_tp_points>0) position.take_profit=position.price_open-m_tp_points*_Point; else position.take_profit=0;

   //Print("Position_OpenShort: SL=",position.stop_loss," TP=",position.take_profit);

   //set the time of closing the virtual position
   position.time_close=0;
   //calculate profit
   position.profit=position.volume*(position.price_open-position.price_close)/_Point;
   //set the maximum price
   position.price_highest=m_price_last.ask;
   //set the minimum price
   position.price_lowest=m_price_last.bid;
   //update the properties of position in correspondence with the prices
   RecalcPositionProperties(position);
  }
//+------------------------------------------------------------------+
//| Closes open virtual position                                     |
//+------------------------------------------------------------------+
void CSampleStrategy::Position_CloseOpenedPosition(virtual_position &position)
  {
   if(position.direction!=POSITION_NEUTRAL)
     {
      if(position.direction==POSITION_SHORT) Position_CloseShort(position);
      if(position.direction==POSITION_LONG)  Position_CloseLong(position);
     }
  }
//+------------------------------------------------------------------+
//| Changes the "position" position in accordance with               |
//| the value of m_current_signal_state                              |
//+------------------------------------------------------------------+
void  CSampleStrategy::ProceedSignalState(virtual_position &position)
  {
   if(position.direction!=POSITION_NEUTRAL) // these is an open virtual position
     {
      switch(m_current_signal_state)
        {
         case SIGNAL_CLOSE_SHORT:   { Position_CloseShort(position); break; }
         case SIGNAL_CLOSE_LONG:    { Position_CloseLong(position); break;}
        }
     }
   else                             // no open virtual position
     {
      switch(m_current_signal_state)
        {
         case SIGNAL_OPEN_LONG:   { Position_OpenLong(position); break; }
         case SIGNAL_OPEN_SHORT:  { Position_OpenShort(position); break;}
        }
     }
  }
//+------------------------------------------------------------------+
//| Returns the current state of strategy                            |
//+------------------------------------------------------------------+
int CSampleStrategy::GetSignalState()
  { return(m_current_signal_state); }
//+------------------------------------------------------------------+
//| Sets the current state of strategy                               |
//| changes the virtual position if necessary                        |
//+------------------------------------------------------------------+
void  CSampleStrategy::SetSignalState(int state)
  {
   if(m_current_signal_state!=state)
     {
      m_current_signal_state=state;
      ProceedSignalState(m_position);
     }
  };
//+------------------------------------------------------------------+
//| Save all performed  virtual deals to a file                      |
//+------------------------------------------------------------------+
void CSampleStrategy::SaveVirtualDeals(string file_name)
  {
   //exit if there has been no trades
   if(m_virtual_deals_total==0) {return;};
   //open a file for writing
   int filehandle=FileOpen(file_name,FILE_WRITE|FILE_CSV);
   //write headers of columns
   FileWrite(filehandle,
             "Symbol",
             "Direction",
             "Profit",
             "Volume",
             "OpenTime",
             "CloseTime",
             "OpenPrice",
             "ClosePrice",
             "HighestPrice",
             "LowestPrice",
             "Entry_Eff",
             "Exit_Eff",
             "Trade_Eff");
   //save all deals
   for(int i=0; i<m_virtual_deals_total; i++)
     {
      FileWrite(filehandle,
                m_deals_history[i].symbol,
                m_deals_history[i].direction,
                m_deals_history[i].profit,
                m_deals_history[i].volume,
                m_deals_history[i].time_open,
                m_deals_history[i].time_close,
                m_deals_history[i].price_open,
                m_deals_history[i].price_close,
                m_deals_history[i].price_highest,
                m_deals_history[i].price_lowest,
                m_deals_history[i].entry_eff,
                m_deals_history[i].exit_eff,
                m_deals_history[i].trade_eff);
     }
   FileClose(filehandle);
  }
//+------------------------------------------------------------------+
//|Function of checking if a new bar has appeared                    |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime old_time;
   datetime new_time[1];
   int copied=CopyTime(_Symbol,_Period,0,1,new_time);
   if(copied>0)
     {
      if(old_time!=new_time[0])
        {
         old_time=new_time[0];
         return(true);
        }
     }
   else
     {
      Alert("Error of copying the time, error number =",GetLastError());
      ResetLastError();
     }
   return(false);
  }
//+------------------------------------------------------------------+